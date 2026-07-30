// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Utilities;
using System.RestClient;

codeunit 31175 "EPO API Submission CZL"
{
    Access = Internal;

    var
        EPOServiceSetupCZL: Record "EPO Service Setup CZL";
        HttpResponseMessage: Codeunit "Http Response Message";
        FormUrl: Text;
        UrlXPathTok: Label 'URL', Locked = true;

    [TryFunction]
    procedure TrySend(Content: XmlDocument)
    var
        HttpContent: Codeunit "Http Content";
        RestClient: Codeunit "Rest Client";
        ResponseXmlDocument: XmlDocument;
        UrlXmlNode: XmlNode;
    begin
        EPOServiceSetupCZL.Get();
        EPOServiceSetupCZL.TestField(Enabled, true);

        HttpContent := HttpContent.Create(Content);
        RestClient.Initialize();
        RestClient.SetTimeOut(EPOServiceSetupCZL."Limit Response Time");
        HttpResponseMessage := RestClient.Post(EPOServiceSetupCZL."Open Form Endpoint", HttpContent);
        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetErrorMessage());

        ResponseXmlDocument := HttpResponseMessage.GetContent().AsXmlDocument();
        ResponseXmlDocument.SelectSingleNode(UrlXPathTok, UrlXmlNode);
        FormUrl := UrlXmlNode.AsXmlElement().InnerText;
    end;

    procedure GetFormUrl(): Text
    begin
        exit(FormUrl);
    end;

    procedure GetHttpResponse(): Codeunit "Http Response Message"
    begin
        exit(HttpResponseMessage);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure HandleEPOServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        EPOServiceSetupRecordRef: RecordRef;
    begin
        if not EPOServiceSetupCZL.Get() then begin
            EPOServiceSetupCZL.Init();
            EPOServiceSetupCZL.Insert();
        end;
        EPOServiceSetupRecordRef.GetTable(EPOServiceSetupCZL);

        if EPOServiceSetupCZL.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        ServiceConnection.InsertServiceConnection(
              ServiceConnection, EPOServiceSetupRecordRef.RecordId, EPOServiceSetupCZL.TableCaption(), EPOServiceSetupCZL."Open Form Endpoint", Page::"EPO Service Setup CZL");
    end;
}