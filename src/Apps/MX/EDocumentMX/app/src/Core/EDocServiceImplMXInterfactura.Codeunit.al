// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.EServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using System.Utilities;

codeunit 3314 "MX Interfactura Impl." implements IDocumentSender, IDocumentReceiver, IDocumentResponseHandler, IDocumentAction, ISentDocumentActions
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
        InterfacturaProcessing.SendEDocument(TempBlob, EDocument, SendContext);

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
        Success := InterfacturaProcessing.CancelEDocument(EDocument, EDocumentService, HttpRequest, HttpResponse, Status);
        ActionContext.Status().SetStatus(Status);
        ActionContext.Http().SetHttpRequestMessage(HttpRequest);
        ActionContext.Http().SetHttpResponseMessage(HttpResponse);
    end;

    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    begin
        exit(false);
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

}