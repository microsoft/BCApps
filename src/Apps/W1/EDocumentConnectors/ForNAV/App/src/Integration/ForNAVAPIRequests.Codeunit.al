// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using Microsoft.eServices.EDocument.Service.Participant;
using System.Utilities;
using System.Xml;

codeunit 6414 "ForNAV API Requests"
{
    Access = Internal;

    internal procedure SendDocumentsDeleteRequest(Http: Codeunit "Http Message State"; RecKeys: JsonArray): Boolean
    var
        Setup: Codeunit "ForNAV Peppol Setup";
        Payload: Text;
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        PayloadObject: JsonObject;
    begin
        ResetRequest('Inbox', 'DELETE', Http);
        HttpContent.GetHeaders(HttpHeaders);

        PayloadObject.Add('ids', RecKeys);
        PayloadObject.WriteTo(Payload);
        HttpContent.WriteFrom(Payload);
        Http.GetHttpRequestMessage().Content := HttpContent;
        if HttpHeaders.Contains('Content-Type') then
            HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/json');
        Setup.Send(HttpClient, Http);
    end;

    internal procedure SendDocumentsGetRequest(): Boolean
    var
        Http: Codeunit "Http Message State";
        Setup: Codeunit "ForNAV Peppol Setup";
        Inbox: Codeunit "ForNAV Inbox";
        HttpClient: HttpClient;
        Response: Text;
        ResponseObject: JsonObject;
        RecKeys: JsonArray;
        More: Boolean;
    begin
        repeat
            ResetRequest('Inbox', 'GET', Http);

            if Setup.Send(HttpClient, Http) = 200 then begin
                Http.GetHttpResponseMessage().Content.ReadAs(Response);
                ResponseObject.ReadFrom(Response);
                More := Inbox.GetDocsFromJson(RecKeys, ResponseObject);
                SendDocumentsDeleteRequest(Http, RecKeys);
            end;
        until not More;

        // Use a dummy label because the URL is mandatory but we don't use it
        Http.GetHttpRequestMessage().SetRequestUri('https://SendDocumentsGetRequest');
        exit(Http.GetHttpResponseMessage().IsSuccessStatusCode);
    end;

    internal procedure SendFilePostRequest(var EDocument: Record "E-Document"; SendContext: Codeunit SendContext): Boolean
    var
        EDocumentService: Record "E-Document Service";
        ServiceParticipant: Record "Service Participant";
        PeppolSetup: Record "ForNAV Peppol Setup";
        Setup: Codeunit "ForNAV Peppol Setup";
        Payload: Text;
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
    begin
        Payload := TempBlobToTxt(SendContext.GetTempBlob());
        if Payload = '' then
            exit(false);

        ResetRequest('Outgoing', 'POST', SendContext.Http());
        SendContext.Http().GetHttpRequestMessage().GetHeaders(HttpHeaders);
        HttpHeaders.Add('Accept', '*/*');

        if PeppolSetup.GetEDocumentService(EDocumentService) then
            case EDocument."Source Type" of
                EDocument."Source Type"::Customer:
                    if ServiceParticipant.Get(EDocumentService.Code, "E-Document Source Type"::Customer, EDocument."Bill-to/Pay-to No.") then
                        HttpHeaders.Add('receiver-peppolid', ServiceParticipant."Participant Identifier");
                EDocument."Source Type"::Vendor:
                    if ServiceParticipant.Get(EDocumentService.Code, "E-Document Source Type"::Vendor, EDocument."Bill-to/Pay-to No.") then
                        HttpHeaders.Add('receiver-peppolid', ServiceParticipant."Participant Identifier");
            end;

        SendContext.Http().GetHttpRequestMessage().Method('POST');

        HttpContent.WriteFrom(Payload);
        HttpContent.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains('Content-Type') then
            HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/xml');

        SendContext.Http().GetHttpRequestMessage().Content := HttpContent;

        Setup.Send(HttpClient, SendContext.Http());

        // Use a dummy label because the URL is mandatory but we don't use it
        SendContext.Http().GetHttpRequestMessage().SetRequestUri('https://SendFilePostRequest');
        exit(SendContext.Http().GetHttpResponseMessage().IsSuccessStatusCode);
    end;

    internal procedure SendActionPostRequest(EDocument: Record "E-Document"; ActionName: Text; SendContext: Codeunit SendContext): Boolean
    var
        Log: Record "E-Document Integration Log";
        Processing: Codeunit "ForNAV Processing";
    begin
        // Use a dummy label because the URL is mandatory but we don't use it
        ClearRequest(SendContext.Http(), 'https://SendActionPostRequest');
        if ActionName = 'Restart' then begin
            Log := EDocument.DocumentLog();
            if Log."Request Blob".HasValue then begin
                SendContext.GetTempBlob().FromRecord(Log, Log.FieldNo("Request Blob"));
                Processing.SendEDocument(EDocument, SendContext);
                exit(SendContext.Http().GetHttpResponseMessage().IsSuccessStatusCode);
            end;
        end;
        exit(false);
    end;

    internal procedure GetReceivedDocumentsRequest(ReceiveContext: Codeunit ReceiveContext; DocumentsMetadata: Codeunit "Temp Blob List"): Boolean
    var
        ForNAVIncomingEDocument: Codeunit "ForNAV Inbox";
    begin
        // Use a dummy label because the URL is mandatory but we don't use it
        ClearRequest(ReceiveContext.Http(), 'https://GetReceivedDocumentsRequest');
        exit(ForNAVIncomingEDocument.GetIncomingBussinessDocs(DocumentsMetadata));
    end;

    internal procedure GetTargetDocumentRequest(DocumentId: Text; ReceiveContext: Codeunit ReceiveContext): Boolean
    var
        ForNAVIncomingEDocument: Codeunit "ForNAV Inbox";
    begin
        // Use a dummy label because the URL is mandatory but we don't use it
        ClearRequest(ReceiveContext.Http(), 'https://GetTargetDocumentRequest');
        exit(ForNAVIncomingEDocument.GetForNAVIncomingEDocument(DocumentId, ReceiveContext));
    end;

    internal procedure SendFetchDocumentRequest(DocumentId: JsonArray; SendContext: Codeunit SendContext): Boolean
    var
        ForNAVIncomingEDocument: Codeunit "ForNAV Inbox";
    begin
        // Use a dummy label because the URL is mandatory but we don't use it
        ClearRequest(SendContext.Http(), 'https://SendFetchDocumentRequest');
        exit(ForNAVIncomingEDocument.DeleteDocs(DocumentId, SendContext));
    end;

    local procedure ClearRequest(Http: Codeunit "Http Message State"; Url: Text)
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
    begin
        Clear(HttpRequestMessage);
        HttpRequestMessage.SetRequestUri(Url);
        Http.SetHttpRequestMessage(HttpRequestMessage);
        Clear(HttpResponseMessage);
        Http.SetHttpResponseMessage(HttpResponseMessage);
    end;

    local procedure ResetRequest(Endpoint: Text; Method: Text; Http: Codeunit "Http Message State")
    var
        PeppolSetup: Codeunit "ForNAV Peppol Setup";
        Url: Text;
    begin
        Url := PeppolSetup.GetBaseUrl(Endpoint);
        ClearRequest(Http, Url);
        Http.GetHttpRequestMessage().Method(Method);
    end;

    local procedure TempBlobToTxt(TempBlob: Codeunit "Temp Blob"): Text
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        InStr: InStream;
        Content: Text;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XMLDOMManagement.TryGetXMLAsText(InStr, Content);
        exit(Content);
    end;
}