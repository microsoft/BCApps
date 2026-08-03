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

    var

    [TryFunction]
    procedure TryGetFormUrl(Content: XmlDocument; var FormUrl: Text)
    var
        HttpContent: Codeunit "Http Content";
        ResponseHttpContent: Codeunit "Http Content";
        UrlXmlNode: XmlNode;
    begin
        GetOrInitEPOServiceSetup();

        HttpContent := HttpContent.Create(Content);
        TrySend(EPOServiceSetupCZL."Open Form Endpoint", EPOServiceSetupCZL."Limit Response Time", HttpContent, ResponseHttpContent);
        ResponseHttpContent.AsXmlDocument().SelectSingleNode(UrlXPathTok, UrlXmlNode);
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
        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetErrorMessage());
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
        GetOrInitEPOServiceSetup();
        if not EPOServiceSetupCZL.Enabled then
            Error(CreateEPOServiceNotEnabledErrorInfo());
    end;

    local procedure GetOrInitEPOServiceSetup()
    begin
        if not EPOServiceSetupCZL.Get() then begin
            EPOServiceSetupCZL.Init();
            EPOServiceSetupCZL.Insert();
        end;
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
        EPOServiceSetupRecordRef: RecordRef;
    begin
        GetOrInitEPOServiceSetup();
        EPOServiceSetupRecordRef.GetTable(EPOServiceSetupCZL);

        if EPOServiceSetupCZL.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        ServiceConnection.InsertServiceConnection(
              ServiceConnection, EPOServiceSetupRecordRef.RecordId, EPOServiceSetupCZL.TableCaption(), EPOServiceSetupCZL."Open Form Endpoint", Page::"EPO Service Setup CZL");
    end;
}