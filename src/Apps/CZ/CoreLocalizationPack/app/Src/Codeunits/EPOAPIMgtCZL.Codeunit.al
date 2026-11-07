// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Utilities;
using System.RestClient;

codeunit 31175 "EPO API Mgt. CZL"
{
    Access = Internal;

    var
        EPOServiceSetupCZL: Record "EPO Service Setup CZL";
        HttpResponseMessage: Codeunit "Http Response Message";
        UrlXPathTok: Label 'URL', Locked = true;
        BaseUrlTok: Label 'https://mojedane.gov.cz/dpr/', Locked = true;
        EPOServiceNotEnabledErr: Label 'The EPO service is not enabled. Enable it in the EPO Service Setup page.';
        OpenFormUriTok: Label 'epo_podani?otevriFormular=1', Locked = true;
        ShowEPOServiceSetupLbl: Label 'Show EPO Service Setup';
        EPOAPICallFailedTelemetryTxt: Label 'EPO API call failed. Endpoint: %1, HTTP Status Code: %2, Error: %3', Locked = true;
        EPOAPICallFailedErr: Label 'Communication with the EPO service failed. Please try again later or contact your administrator.';
        UnexpectedResponseErr: Label 'The EPO service endpoint returned an unexpected response. The response does not contain the expected URL element.';
        TelemetryCategoryTok: Label 'EPO API CZL', Locked = true;

    [TryFunction]
    procedure TryGetFormUrl(Content: XmlDocument; var FormUrl: Text)
    var
        HttpContent: Codeunit "Http Content";
        ResponseHttpContent: Codeunit "Http Content";
        ResponseXmlDocument: XmlDocument;
        UrlXmlNode: XmlNode;
        ResponseText: Text;
    begin
        EPOServiceSetupCZL.GetOrInit();

        HttpContent := HttpContent.Create(Content);
        TrySend(EPOServiceSetupCZL."Open Form Endpoint", EPOServiceSetupCZL."Limit Response Time", HttpContent, ResponseHttpContent);
        ResponseText := ResponseHttpContent.AsText();
        if not XmlDocument.ReadFrom(ResponseText, ResponseXmlDocument) then
            Error(UnexpectedResponseErr);
        if not ResponseXmlDocument.SelectSingleNode(UrlXPathTok, UrlXmlNode) then
            Error(UnexpectedResponseErr);
        FormUrl := UrlXmlNode.AsXmlElement().InnerText();
    end;

    [TryFunction]
    local procedure TrySend(RequestUri: Text; Timeout: Duration; RequestHttpContent: Codeunit "Http Content"; var ResponseHttpContent: Codeunit "Http Content")
    var
        RestClient: Codeunit "Rest Client";
    begin
        CheckEPOServiceEnabled();

        RestClient.Initialize();
        RestClient.SetTimeOut(Timeout);
        HttpResponseMessage := RestClient.Post(RequestUri, RequestHttpContent);
        if not HttpResponseMessage.GetIsSuccessStatusCode() then begin
            Session.LogMessage('0000UX4', StrSubstNo(EPOAPICallFailedTelemetryTxt, RequestUri, HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetErrorMessage()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(EPOAPICallFailedErr);
        end;
        ResponseHttpContent := HttpResponseMessage.GetContent();
    end;

    procedure GetHttpResponse(): Codeunit "Http Response Message"
    begin
        exit(HttpResponseMessage);
    end;

    procedure GetDefaultOpenFormUrl(): Text
    begin
        exit(BaseUrlTok + OpenFormUriTok);
    end;

    local procedure CheckEPOServiceEnabled()
    begin
        EPOServiceSetupCZL.GetOrInit();
        if not EPOServiceSetupCZL.Enabled then
            Error(CreateEPOServiceNotEnabledErrorInfo());
    end;

    local procedure CreateEPOServiceNotEnabledErrorInfo(): ErrorInfo
    var
        EPOServiceNotEnabledErrorInfo: ErrorInfo;
    begin
        EPOServiceNotEnabledErrorInfo.Message := EPOServiceNotEnabledErr;
        EPOServiceNotEnabledErrorInfo.PageNo := Page::"EPO Service Setup CZL";
        EPOServiceNotEnabledErrorInfo.AddNavigationAction(ShowEPOServiceSetupLbl);
        exit(EPOServiceNotEnabledErrorInfo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure HandleEPOServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        LocalEPOServiceSetupCZL: Record "EPO Service Setup CZL";
        EPOServiceSetupRecordRef: RecordRef;
    begin
        if not LocalEPOServiceSetupCZL.Get() then
            exit;

        EPOServiceSetupRecordRef.GetTable(LocalEPOServiceSetupCZL);

        if LocalEPOServiceSetupCZL.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        ServiceConnection.InsertServiceConnection(
              ServiceConnection, EPOServiceSetupRecordRef.RecordId, LocalEPOServiceSetupCZL.TableCaption(), LocalEPOServiceSetupCZL."Open Form Endpoint", Page::"EPO Service Setup CZL");
    end;
}
