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

codeunit 3353 "MX Interfactura Impl." implements IDocumentSender, IDocumentReceiver, IDocumentResponseHandler, IDocumentAction, ISentDocumentActions, IMessageSender, IMessageResponseHandler, IConsentManager
{
    Access = Internal;

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        MXConnectionSetup: Record "MX Connection Setup";
        TempBlob: Codeunit "Temp Blob";
    begin
        MXEDocumentFeature.CheckEnabled();
        if not MXConnectionSetup.Get() then
            Error(MissingSetupErr);

        if not MXConnectionSetup.Enabled then
            Error(DisabledSetupErr);

        TempBlob := SendContext.GetTempBlob();
        InterfacturaProcessing.SendEDocument(TempBlob, EDocument, EDocumentService, SendContext);

    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
    var
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Success: Boolean;
    begin
        MXEDocumentFeature.CheckEnabled();
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
        MXEDocumentFeature.CheckEnabled();
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
        MXEDocumentFeature.CheckEnabled();
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
        MXEDocumentFeature.CheckEnabled();
        if MessageContext.GetMessageType() <> "E-Document Message Type"::"MX CFDI Payment Complement" then
            Error(UnsupportedMessageErr, Format(MessageContext.GetMessageType()));
        TempBlob := MessageContext.GetTempBlob();
        InterfacturaProcessing.SendPaymentComplement(TempBlob, MessageContext);
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context"): Boolean
    begin
        MXEDocumentFeature.CheckEnabled();
        MessageContext.Status().SetStatus("E-Document Service Status"::Sent);
        exit(true);
    end;

    procedure ObtainPrivacyConsent(): Boolean
    var
        ConsentManagerDefaultImpl: Codeunit "Consent Manager Default Impl.";
    begin
        if not ConsentManagerDefaultImpl.ObtainPrivacyConsent() then
            exit(false);

        Session.LogAuditMessage(StrSubstNo(CFDIConsentProvidedLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
        exit(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"E-Document Service", OnBeforeOpenServiceIntegrationSetupPage, '', false, false)]
    local procedure OnBeforeOpenServiceIntegrationSetupPage(EDocumentService: Record "E-Document Service"; var IsServiceIntegrationSetupRun: Boolean)
    var
        MXConnectionSetupCard: Page "Interfactura Connection Setup";
    begin
        if EDocumentService."Service Integration V2" <> EDocumentService."Service Integration V2"::"Interfactura Service" then
            exit;

        MXEDocumentFeature.CheckEnabled();

        MXConnectionSetupCard.RunModal();
        IsServiceIntegrationSetupRun := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document Service", 'OnAfterValidateEvent', 'Service Integration V2', false, false)]
    local procedure OnAfterValidateServiceIntegration(var Rec: Record "E-Document Service"; var xRec: Record "E-Document Service"; CurrFieldNo: Integer)
    begin
        if Rec."Service Integration V2" = Rec."Service Integration V2"::"Interfactura Service" then
            MXEDocumentFeature.CheckEnabled();
    end;

    var
        InterfacturaProcessing: Codeunit "Interfactura Processing";
        MXEDocumentFeature: Codeunit "MX E-Document Feature";
        MissingSetupErr: Label 'Interfactura Connection Setup must be configured before sending.';
        DisabledSetupErr: Label 'Interfactura Connection Setup must be enabled before sending.';
        UnsupportedMessageErr: Label 'Interfactura does not support E-Document message type %1.', Comment = '%1 = message type';
        CFDIConsentProvidedLbl: Label 'CFDI - consent provided by UserSecurityId %1.', Locked = true;

}
