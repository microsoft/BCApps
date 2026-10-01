// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Utilities;
using System.Environment.Configuration;
using System.IO;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Manages automatic updates of currency exchange rates from external services.
/// Provides functionality to synchronize exchange rates, handle data transformations,
/// and maintain currency rate accuracy through automated scheduled updates.
/// </summary>
/// <remarks>
/// Integrates with Data Exchange Framework for rate import processing.
/// Supports multiple currency exchange rate services and includes error handling
/// and telemetry logging for monitoring service reliability.
/// </remarks>
codeunit 1281 "Update Currency Exchange Rates"
{
    Permissions = TableData "Data Exch." = rimd;

    trigger OnRun()
    begin
        SyncCurrencyExchangeRates();
    end;

    var
        TempBlobResponse: Codeunit "Temp Blob";
        NoSyncCurrencyExchangeRatesSetupErr: Label 'There are no active Currency Exchange Rate Sync. Setup records.';
        MissingExchRateNotificationNameTxt: Label 'Missing Exchange Rates';
        MissingExchRateNotificationDescriptionTxt: Label 'Show warning to enter exchange rates when a new currency is created.';
        NotificationActionDisableTxt: Label 'Don''t show me again';
        NotificationActionOpenPageTxt: Label 'Do it now';
#pragma warning disable AA0470
        NotificationMessageMsg: Label 'Exchange rates for %1 need to be configured.', Comment = 'Currency Code';
#pragma warning restore AA0470
        ExchRatesUpdatedTxt: Label 'The user updated currency exchange rates via a currency exchange rate service.', Locked = true;
        TelemetryCategoryTok: Label 'AL Exchange Rate Service', Locked = true;
        WebRequestTxt: Label 'Web service request sent.', Locked = true;
        WebResponseTxt: Label 'Web service response status: %1', Locked = true, Comment = '%1 = HTTP status code';
        WebServiceCallFailedErr: Label 'A web service call to the currency exchange rate service failed. See the Activity Log for details.';
#pragma warning disable AA0470
        ActivityLogDetailTxt: Label '%1 %2: %3', Locked = true, Comment = '%1 = HTTP status code, %2 = reason phrase, %3 = response body';
#pragma warning restore AA0470
        ResponseTooLargeErr: Label 'The response from the currency exchange rate service exceeded the maximum allowed size and was rejected.';
        ResponseTooLargeTxt: Label 'The currency exchange rate update failed. The response exceeded the maximum allowed size.', Locked = true;
        SecurityAuditResponseTooLargeTxt: Label 'The currency exchange rate service returned a response that         exceeded the maximum allowed size.', Locked = true;

            local procedure SyncCurrencyExchangeRates()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        ResponseInStream: InStream;
        SourceName: Text;
    begin
        CurrExchRateUpdateSetup.SetRange(Enabled, true);
        OnSyncCurrencyExchangeRatesOnBeforeFindCurrExchRateUpdateSetup(CurrExchRateUpdateSetup);

        if CurrExchRateUpdateSetup.FindSet() then
            repeat
                OnBeforeSyncCurrencyExchangeRatesLoop(CurrExchRateUpdateSetup);
                GetCurrencyExchangeData(CurrExchRateUpdateSetup, ResponseInStream, SourceName);
                UpdateCurrencyExchangeRates(CurrExchRateUpdateSetup, ResponseInStream, SourceName);
                LogTelemetryWhenExchangeRateUpdated();
            until CurrExchRateUpdateSetup.Next() = 0
        else
            Error(NoSyncCurrencyExchangeRatesSetupErr);
    end;

    [Scope('OnPrem')]
    procedure UpdateCurrencyExchangeRates(CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; CurrencyExchRatesDataInStream: InStream; SourceName: Text)
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get(CurrExchRateUpdateSetup."Data Exch. Def Code");
        CreateDataExchange(DataExch, DataExchDef, CurrencyExchRatesDataInStream, CopyStr(SourceName, 1, 250));
        DataExchDef.ProcessDataExchange(DataExch);
        DataExch.Delete(true);
    end;

    local procedure GetCurrencyExchangeData(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; var ResponseInStream: InStream; var SourceName: Text)
    var
        ServiceUrl: Text;
        Handled: Boolean;
    begin
        Clear(TempBlobResponse);
        OnBeforeGetCurrencyExchangeData(CurrExchRateUpdateSetup, ResponseInStream, SourceName, Handled, TempBlobResponse);
        TempBlobResponse.CreateInStream(ResponseInStream);
        if Handled then
            exit;

        ExecuteWebServiceRequest(CurrExchRateUpdateSetup, ResponseInStream);
        // ExecuteWebServiceRequest copies the downloaded payload into TempBlobResponse and re-creates
        // ResponseInStream from it, so TempBlobResponse.Length() reflects the actual response and drives the size check.
        CheckResponseSize(TempBlobResponse);
        CurrExchRateUpdateSetup.GetWebServiceURL(ServiceUrl);
        SourceName := ServiceUrl;
    end;

    internal procedure CheckResponseSize(var TempBlob: Codeunit "Temp Blob")
    var
        AuditLog: Codeunit "Audit Log";
    begin
        if TempBlob.Length() <= GetMaxResponseSize() then
            exit;

        AuditLog.LogAuditMessage(SecurityAuditResponseTooLargeTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0); // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
        Session.LogMessage('0000VEP', ResponseTooLargeTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTok);
        Clear(TempBlob);
        Error(ResponseTooLargeErr);
    end;

    local procedure GetMaxResponseSize(): Integer
    begin
        exit(10485760); // 10 MB - exchange rate feeds are small; larger responses are rejected as potentially malicious.
    end;

    local procedure CreateDataExchange(var DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; ResponseInStream: InStream; SourceName: Text[250])
    var
        TempBlob: Codeunit "Temp Blob";
        GetJsonStructure: Codeunit "Get Json Structure";
        OutStream: OutStream;
        BlankInStream: InStream;
    begin
        if DataExchDef."File Type" = DataExchDef."File Type"::Json then begin
            TempBlob.CreateInStream(BlankInStream);

            DataExch.InsertRec(SourceName, BlankInStream, DataExchDef.Code);
            DataExch."File Content".CreateOutStream(OutStream);
            if not GetJsonStructure.JsonToXML(ResponseInStream, OutStream) then
                GetJsonStructure.JsonToXMLCreateDefaultRoot(ResponseInStream, OutStream);
            DataExch.Modify(true);
        end else
            DataExch.InsertRec(SourceName, ResponseInStream, DataExchDef.Code);

        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);
    end;

    local procedure ExecuteWebServiceRequest(CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; var ResponseInStream: InStream)
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        CustomDimensions: Dictionary of [Text, Text];
        HttpResponseInStream: InStream;
        ResponseOutStream: OutStream;
        ResponseErrorText: Text;
        URL: Text;
    begin
        CurrExchRateUpdateSetup.GetWebServiceURL(URL);
        HttpRequestMessage.Method('GET');
        HttpRequestMessage.SetRequestUri(URL);
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Accept', 'application/xml,text/xml');

        if CurrExchRateUpdateSetup."Log Web Requests" then begin
            CustomDimensions.Add('Category', TelemetryCategoryTok);
            CustomDimensions.Add('Url', URL);
            Session.LogMessage('0000VSQ', WebRequestTxt, Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, CustomDimensions);
        end;

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            ShowHttpError(CurrExchRateUpdateSetup, GetLastErrorText());

        if CurrExchRateUpdateSetup."Log Web Requests" then
            if HttpResponseMessage.IsSuccessStatusCode() then
                Session.LogMessage('0000VSR', StrSubstNo(WebResponseTxt, HttpResponseMessage.HttpStatusCode()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok)
            else
                Session.LogMessage('0000VSS', StrSubstNo(WebResponseTxt, HttpResponseMessage.HttpStatusCode()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);

        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            HttpResponseMessage.Content.ReadAs(ResponseErrorText);
            ShowHttpError(CurrExchRateUpdateSetup,
              StrSubstNo(ActivityLogDetailTxt, HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase(), ResponseErrorText));
        end;

        HttpResponseMessage.Content.ReadAs(HttpResponseInStream);
        TempBlobResponse.CreateOutStream(ResponseOutStream);
        CopyStream(ResponseOutStream, HttpResponseInStream);
        TempBlobResponse.CreateInStream(ResponseInStream);
    end;

    procedure GenerateTempDataFromService(var TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary; CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        MapCurrencyExchangeRate: Codeunit "Map Currency Exchange Rate";
        ResponseInStream: InStream;
        SourceName: Text;
    begin
        GetCurrencyExchangeData(CurrExchRateUpdateSetup, ResponseInStream, SourceName);
        DataExchDef.Get(CurrExchRateUpdateSetup."Data Exch. Def Code");
        CreateDataExchange(DataExch, DataExchDef, ResponseInStream, CopyStr(SourceName, 1, 250));

        MapCurrencyExchangeRate.MapCurrencyExchangeRates(DataExch, TempCurrencyExchangeRate);
        DataExch.Delete(true);
    end;

    local procedure ShowHttpError(CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; LogDetailText: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(
          CurrExchRateUpdateSetup, ActivityLog.Status::Failed, CurrExchRateUpdateSetup."Service Provider",
          CurrExchRateUpdateSetup.Description, LogDetailText);

        Error(WebServiceCallFailedErr);
    end;

    /// <summary>
    /// Event is raised before getting currency exchange data from web service.
    /// </summary>
    /// <param name="ResponseInStream">Do not use - InStream is empty and not writable. Use TempBlobResponse parameter instead.</param>
    /// <param name="TempBlobResponse">TempBlob to write the currency exchange data to. Use CreateOutStream() to get OutStream for writing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCurrencyExchangeData(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; var ResponseInStream: InStream; var SourceName: Text; var Handled: Boolean; var TempBlobResponse: Codeunit "Temp Blob")
    begin
    end;

    procedure OpenCurrencyExchangeRatesPageFromNotification(Notification: Notification)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
    begin
        CurrencyCode := Notification.GetData('Currency Code');
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        PAGE.RunModal(PAGE::"Currency Exchange Rates", CurrencyExchangeRate);
    end;

    procedure DisableMissingExchangeRatesNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(Notification.Id) then
            MyNotifications.InsertDefault(
              Notification.Id,
              MissingExchRateNotificationNameTxt,
              MissingExchRateNotificationDescriptionTxt,
              false);
    end;

    procedure ShowMissingExchangeRatesNotification(CurrencyCode: Code[10])
    var
        MyNotifications: Record "My Notifications";
        Notification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetMissingExchangeRatesNotificationID()) then
            exit;
        Notification.Id := GetMissingExchangeRatesNotificationID();
        Notification.Message := StrSubstNo(NotificationMessageMsg, CurrencyCode);
        Notification.SetData('Currency Code', CurrencyCode);
        Notification.AddAction(NotificationActionOpenPageTxt, 1281, 'OpenCurrencyExchangeRatesPageFromNotification');
        Notification.AddAction(NotificationActionDisableTxt, 1281, 'DisableMissingExchangeRatesNotification');
        Notification.Send();
    end;

    procedure ExchangeRatesForCurrencyExist(Date: Date; CurrencyCode: Code[10]): Boolean
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if Date = 0D then
            Date := WorkDate();
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetRange("Starting Date", 0D, Date);
        exit(CurrencyExchangeRate.FindLast());
    end;

    procedure OpenExchangeRatesPage(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        PAGE.RunModal(PAGE::"Currency Exchange Rates", CurrencyExchangeRate);
    end;

    procedure GetMissingExchangeRatesNotificationID(): Guid
    begin
        exit('911e69ab-73a1-4e08-931b-cf21f0d118f2');
    end;

    local procedure LogTelemetryWhenExchangeRateUpdated()
    begin
        Session.LogMessage('000089F', ExchRatesUpdatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSyncCurrencyExchangeRatesLoop(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    begin
    end;

    /// <summary>
    /// Integration event raised after the enabled filter is applied to the currency exchange rate update setup and before the setup records are read.
    /// Enables subscribers to apply additional filters to the setup before the synchronization loop runs.
    /// </summary>
    /// <param name="CurrExchRateUpdateSetup">Currency exchange rate update setup, passed by reference so subscribers can apply additional filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSyncCurrencyExchangeRatesOnBeforeFindCurrExchRateUpdateSetup(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    begin
    end;
}
