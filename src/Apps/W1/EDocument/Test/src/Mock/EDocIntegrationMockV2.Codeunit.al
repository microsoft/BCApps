// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 139658 "E-Doc. Integration Mock V2" implements IDocumentSender, IDocumentReceiver, IDocumentResponseHandler, ISentDocumentActions, IConsentManager, IMessageSender, IMessageResponseHandler
{

    Access = Internal;

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        TempBlob: codeunit "Temp Blob";
        IsAsync: Boolean;
    begin
        TempBlob := SendContext.GetTempBlob();
        OnSend(EDocument, EDocumentService, TempBlob, IsAsync, SendContext.Http().GetHttpRequestMessage(), SendContext.Http().GetHttpResponseMessage());
    end;

    procedure SendBatch(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    begin

    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
    var
        Success: Boolean;
    begin
        OnGetResponse(EDocument, SendContext.Http().GetHttpRequestMessage(), SendContext.Http().GetHttpResponseMessage(), Success);
        exit(Success);
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context"): Boolean
    var
        ResponseReceived: Boolean;
    begin
        OnGetResponse(EDocument, MessageContext.Http().GetHttpRequestMessage(), MessageContext.Http().GetHttpResponseMessage(), ResponseReceived);
        if ResponseReceived then
            MessageContext.Status().SetStatus("E-Document Service Status"::Sent)
        else
            MessageContext.Status().SetStatus("E-Document Service Status"::"Pending Response");
        exit(ResponseReceived);
    end;

    procedure SendMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    var
        TempBlob: Codeunit "Temp Blob";
        IsAsync: Boolean;
    begin
        TempBlob := MessageContext.GetTempBlob();
        OnSend(EDocument, EDocumentService, TempBlob, IsAsync, MessageContext.Http().GetHttpRequestMessage(), MessageContext.Http().GetHttpResponseMessage());
        if IsAsync then
            MessageContext.Status().SetStatus("E-Document Service Status"::"Pending Response")
        else
            MessageContext.Status().SetStatus("E-Document Service Status"::Sent);
    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
        OnReceiveDocuments(DocumentsMetadata, ReceiveContext.Http().GetHttpRequestMessage(), ReceiveContext.Http().GetHttpResponseMessage());
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    var
        DocumentDownloadBlob: Codeunit "Temp Blob";
    begin
        OnDownloadDocument(EDocument, EDocumentService, DocumentMetadata, DocumentDownloadBlob, ReceiveContext.Http().GetHttpRequestMessage(), ReceiveContext.Http().GetHttpResponseMessage());
        ReceiveContext.SetTempBlob(DocumentDownloadBlob);
    end;

    procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    var
        Status: Enum "E-Document Service Status";
        Update: Boolean;
    begin
        OnGetApproval(EDocument, EDocumentService, ActionContext.Http().GetHttpRequestMessage(), ActionContext.Http().GetHttpResponseMessage(), Status, Update);
        ActionContext.Status().SetStatus(Status);
        exit(Update);
    end;

    procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    var
        Status: Enum "E-Document Service Status";
        Update: Boolean;
    begin
        OnGetCancellation(EDocument, EDocumentService, ActionContext.Http().GetHttpRequestMessage(), ActionContext.Http().GetHttpResponseMessage(), Status, Update);
        ActionContext.Status().SetStatus(Status);
        exit(Update);
    end;

    procedure OpenServiceIntegrationSetupPage(var EDocumentService: Record "E-Document Service"): Boolean
    begin
    end;

    procedure ObtainPrivacyConsent(): Boolean
    begin
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSend(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var TempBlob: Codeunit "Temp Blob"; var IsAsync: Boolean; HttpRequest: HttpRequestMessage; HttpResponse: HttpResponseMessage)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReceiveDocuments(ReceivedEDocuments: Codeunit "Temp Blob List"; HttpRequestMessage: HttpRequestMessage; HttpResponseMessage: HttpResponseMessage);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; var DocumentDownloadBlob: Codeunit "Temp Blob"; HttpRequest: HttpRequestMessage; HttpResponse: HttpResponseMessage);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResponse(var EDocument: Record "E-Document"; HttpRequest: HttpRequestMessage; HttpResponse: HttpResponseMessage; var Success: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetApproval(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; HttpRequest: HttpRequestMessage; HttpResponse: HttpResponseMessage; var Status: Enum "E-Document Service Status"; var Update: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCancellation(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; HttpRequest: HttpRequestMessage; HttpResponse: HttpResponseMessage; var Status: Enum "E-Document Service Status"; var Update: Boolean);
    begin
    end;


}
