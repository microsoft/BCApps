// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.EServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 3353 "MX Interfactura Impl." implements IDocumentSender, IDocumentReceiver, IDocumentResponseHandler, IDocumentAction, ISentDocumentActions, IMessageSender, IMessageResponseHandler
{
    Access = Internal;

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        MXConnectionSetup: Record "MX Connection Setup";
        TempBlob: Codeunit "Temp Blob";
    begin
        if not MXConnectionSetup.Get() then
            Error(MissingSetupErr);

        if not MXConnectionSetup.Enabled then
            Error(DisabledSetupErr);

        TempBlob := SendContext.GetTempBlob();
        InterfacturaProcessing.SendEDocument(TempBlob, EDocument, EDocumentService, SendContext);

    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
        // Not implemented for Interfactura
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
        // Not implemented for Interfactura
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
    var
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Success: Boolean;
    begin
        Success := InterfacturaProcessing.GetDocumentResponse(EDocument, EDocumentService, HttpRequest, HttpResponse);
        SendContext.Http().SetHttpRequestMessage(HttpRequest);
        SendContext.Http().SetHttpResponseMessage(HttpResponse);
        exit(Success);
    end;

    procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext) Success: Boolean
    var
        Status: Enum "E-Document Service Status";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
    begin
        Success := InterfacturaProcessing.GetDocumentApproval(EDocument, EDocumentService, HttpRequest, HttpResponse, Status);
        ActionContext.Status().SetStatus(Status);
        ActionContext.Http().SetHttpRequestMessage(HttpRequest);
        ActionContext.Http().SetHttpResponseMessage(HttpResponse);
    end;

    procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext) Success: Boolean
    var
        Status: Enum "E-Document Service Status";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
    begin
        if EDocument."CFDI Cancellation ID" <> '' then
            Success := InterfacturaProcessing.CheckCancellationStatus(EDocument, EDocumentService, HttpRequest, HttpResponse, Status)
        else
            Success := InterfacturaProcessing.CancelEDocument(EDocument, EDocumentService, HttpRequest, HttpResponse, Status);
        ActionContext.Status().SetStatus(Status);
        ActionContext.Http().SetHttpRequestMessage(HttpRequest);
        ActionContext.Http().SetHttpResponseMessage(HttpResponse);
    end;

    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    begin
        exit(false);
    end;

    procedure SendMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        if MessageContext.GetMessageType() <> "E-Document Message Type"::"MX CFDI Payment Complement" then
            Error(UnsupportedMessageErr, Format(MessageContext.GetMessageType()));
        TempBlob := MessageContext.GetTempBlob();
        InterfacturaProcessing.SendPaymentComplement(TempBlob, MessageContext);
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context"): Boolean
    begin
        // Interfactura returns the stamped CFDI synchronously for payment complements.
        MessageContext.Status().SetStatus("E-Document Service Status"::Sent);
        exit(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"E-Document Service", OnBeforeOpenServiceIntegrationSetupPage, '', false, false)]
    local procedure OnBeforeOpenServiceIntegrationSetupPage(EDocumentService: Record "E-Document Service"; var IsServiceIntegrationSetupRun: Boolean)
    var
        MXConnectionSetupCard: Page "Interfactura Connection Setup";
    begin
        if EDocumentService."Service Integration V2" <> EDocumentService."Service Integration V2"::"Interfactura Service" then
            exit;

        MXConnectionSetupCard.RunModal();
        IsServiceIntegrationSetupRun := true;
    end;


    var
        InterfacturaProcessing: Codeunit "Interfactura Processing";
        MissingSetupErr: Label 'Interfactura Connection Setup must be configured before sending.';
        DisabledSetupErr: Label 'Interfactura Connection Setup must be enabled before sending.';
        UnsupportedMessageErr: Label 'Interfactura does not support E-Document message type %1.', Comment = '%1 = message type';

}
