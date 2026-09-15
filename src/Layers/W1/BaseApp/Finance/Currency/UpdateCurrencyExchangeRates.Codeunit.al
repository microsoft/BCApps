// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Utilities;
using System;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.IO;
using System.Telemetry;
using System.Utilities;
using System.Xml;

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
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
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
        ResponseTooLargeErr: Label 'The response from the currency exchange rate service exceeded the maximum allowed size and was rejected.';
        ResponseTooLargeTxt: Label 'The currency exchange rate update failed. The response exceeded the maximum allowed size.', Locked = true;
        SecurityAuditResponseTooLargeTxt: Label 'The currency exchange rate service returned a response that exceeded the maximum allowed size.', Locked = true;
        BlockedEndpointErr: Label 'The currency exchange rate service web service URL must be an external address. Internal, private, loopback, or link-local addresses are not allowed.';
        BlockedEndpointTitleTxt: Label 'Web service URL not allowed';
        BlockedEndpointDetailTxt: Label 'Open the currency exchange rate service setup and change the Web Service URL to a valid external address before updating exchange rates.';
        OpenCurrExchRateServiceSetupTxt: Label 'Open the currency exchange rate service setup';
        BlockedEndpointMsg: Label 'The currency exchange rate update failed. The configured web service URL targets an internal address and was rejected.', Locked = true;
        SecurityAuditBlockedEndpointTxt: Label 'The currency exchange rate service web service URL was rejected because it targets an internal address.', Locked = true;

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
        // ResponseInStream is created from TempBlobResponse above, so ExecuteWebServiceRequest (via
        // Http Web Request Mgt.GetResponse -> CopyTo) writes the downloaded payload into TempBlobResponse's
        // backing blob. TempBlobResponse.Length() therefore reflects the actual response on the default HTTP path
        // (same Temp Blob pattern as Http Web Request Mgt.SendRequestAndReadResponse), and drives the size check.
        CheckResponseSize();
        CurrExchRateUpdateSetup.GetWebServiceURL(ServiceUrl);
        SourceName := ServiceUrl;
    end;

    local procedure CheckResponseSize()
    var
        AuditLog: Codeunit "Audit Log";
    begin
        if TempBlobResponse.Length() <= GetMaxResponseSize() then
            exit;

        AuditLog.LogAuditMessage(SecurityAuditResponseTooLargeTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0); // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
        Session.LogMessage('0000VEP', ResponseTooLargeTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTok);
        Clear(TempBlobResponse);
        Error(ResponseTooLargeErr);
    end;

    local procedure GetMaxResponseSize(): Integer
    begin
        exit(10485760); // 10 MB - exchange rate feeds are small; larger responses are rejected as potentially malicious.
    end;

    local procedure CheckServiceEndpointAllowed(CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; ServiceUrl: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AuditLog: Codeunit "Audit Log";
        Uri: Codeunit Uri;
        BlockedEndpointErrInfo: ErrorInfo;
        Host: Text;
    begin
        // SSRF mitigation: the web service URL is an admin-configurable setup value. Online (SaaS), reject internal/
        // private/loopback targets so the setup cannot redirect this server-side call to an internal address. On-prem
        // admins control their own network egress (e.g. internal proxies), so no restriction is applied there.
        if not EnvironmentInformation.IsSaaS() then
            exit;
        if not TryInitUri(Uri, ServiceUrl) then
            exit; // a malformed URL is handled by the existing request/error path
        Host := LowerCase(Uri.GetHost());
        if Host = '' then
            exit;
        if not IsInternalHost(Host) then
            exit;

        AuditLog.LogAuditMessage(SecurityAuditBlockedEndpointTxt, SecurityOperationResult::Failure, AuditCategory::Authorization, 4, 0); // 4, 0 = AuditMessageOperation / AuditMessageOperationResult (standard security-audit codes; also routes the entry to Purview).
        Session.LogMessage('', BlockedEndpointMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTok);
        // Rejecting the configured URL is a recoverable setup problem, so make the error navigate to the specific
        // service setup record whose URL was rejected (the setup table holds one row per exchange-rate service).
        BlockedEndpointErrInfo.Title := BlockedEndpointTitleTxt;
        BlockedEndpointErrInfo.Message := BlockedEndpointErr;
        BlockedEndpointErrInfo.DetailedMessage := BlockedEndpointDetailTxt;
        BlockedEndpointErrInfo.DataClassification := DataClassification::SystemMetadata;
        BlockedEndpointErrInfo.PageNo := Page::"Curr. Exch. Rate Service Card";
        BlockedEndpointErrInfo.RecordId := CurrExchRateUpdateSetup.RecordId();
        BlockedEndpointErrInfo.AddNavigationAction(OpenCurrExchRateServiceSetupTxt);
        Error(BlockedEndpointErrInfo);
    end;

    [TryFunction]
    local procedure TryInitUri(var Uri: Codeunit Uri; Url: Text)
    begin
        Uri.Init(Url);
    end;

    local procedure IsInternalHost(Host: Text): Boolean
    begin
        // Strip IPv6 literal brackets so bracketed forms (e.g. [::ffff:127.0.0.1]) are checked the same as bare hosts.
        Host := DelChr(Host, '=', '[]');
        if Host in ['localhost', '127.0.0.1', '::1'] then
            exit(true);

        if Host.Contains(':') then begin
            // IPv4-mapped IPv6 literal (::ffff:127.0.0.1): re-check the embedded IPv4 address.
            if Host.StartsWith('::ffff:') then
                exit(IsInternalHost(CopyStr(Host, 8)));
            // IPv6 literal: unique-local (fc00::/7 -> fc/fd) and link-local (fe80::/10 -> fe8/fe9/fea/feb).
            if Host.StartsWith('fc') or Host.StartsWith('fd') then
                exit(true);
            if Host.StartsWith('fe8') or Host.StartsWith('fe9') or Host.StartsWith('fea') or Host.StartsWith('feb') then
                exit(true);
            exit(false);
        end;

        // IPv4 loopback (127.0.0.0/8), link-local incl. cloud IMDS (169.254.0.0/16), and RFC1918 private ranges.
        if Host.StartsWith('127.') then
            exit(true);
        if Host.StartsWith('169.254.') then
            exit(true);
        if Host.StartsWith('10.') then
            exit(true);
        if Host.StartsWith('192.168.') then
            exit(true);
        exit(IsPrivate172Range(Host));
    end;

    local procedure IsPrivate172Range(Host: Text): Boolean
    var
        Octets: List of [Text];
        SecondOctet: Integer;
    begin
        // Private range 172.16.0.0 - 172.31.255.255.
        if not Host.StartsWith('172.') then
            exit(false);
        Octets := Host.Split('.');
        if Octets.Count() < 2 then
            exit(false);
        if not Evaluate(SecondOctet, Octets.Get(2)) then
            exit(false);
        exit((SecondOctet >= 16) and (SecondOctet <= 31));
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
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        URL: Text;
    begin
        CurrExchRateUpdateSetup.GetWebServiceURL(URL);
        CheckServiceEndpointAllowed(CurrExchRateUpdateSetup, URL);
        HttpWebRequestMgt.Initialize(URL);
        HttpWebRequestMgt.SetReturnType('application/xml,text/xml');

        if not GuiAllowed then
            HttpWebRequestMgt.DisableUI();

        HttpWebRequestMgt.SetTraceLogEnabled(CurrExchRateUpdateSetup."Log Web Requests");

        if not HttpWebRequestMgt.GetResponse(ResponseInStream, HttpStatusCode, ResponseHeaders) then
            ShowHttpError(CurrExchRateUpdateSetup, URL);
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

    local procedure ShowHttpError(CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; WebServiceURL: Text)
    var
        ActivityLog: Record "Activity Log";
        WebRequestHelper: Codeunit "Web Request Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        WebException: DotNet WebException;
        XmlNode: DotNet XmlNode;
        ResponseInputStream: InStream;
        ErrorText: Text;
    begin
        ErrorText := WebRequestHelper.GetWebResponseError(WebException, WebServiceURL);

        ActivityLog.LogActivity(
          CurrExchRateUpdateSetup, ActivityLog.Status::Failed, CurrExchRateUpdateSetup."Service Provider",
          CurrExchRateUpdateSetup.Description, ErrorText);

        if IsNull(WebException.Response) then
            Error(ErrorText);

        ResponseInputStream := WebException.Response.GetResponseStream();

        XMLDOMMgt.LoadXMLNodeFromInStream(ResponseInputStream, XmlNode);

        ErrorText := WebException.Message;

        Error(ErrorText);
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

