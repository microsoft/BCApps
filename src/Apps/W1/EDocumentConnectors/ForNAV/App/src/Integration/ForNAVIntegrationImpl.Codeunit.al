// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using System.Privacy;
using System.Utilities;

codeunit 6418 "ForNAV Integration Impl." implements IDocumentSender, IDocumentResponseHandler, IDocumentReceiver, ISentDocumentActions, IConsentManager
{
    Access = Internal;

    var
        ForNAVProcessing: Codeunit "ForNAV Processing";

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    begin
        ForNAVProcessing.SendDocument(EDocument, SendContext);
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
    begin
        // Use a dummy label because the URL is mandatory but we don't use it
        SendContext.Http().GetHttpRequestMessage().SetRequestUri('https://GetResponse');
        exit(ForNAVProcessing.GetResponse(EDocument, SendContext));
    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
        ForNAVProcessing.ReceiveDocuments(ReceiveContext, DocumentsMetadata);
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
        ForNAVProcessing.GetDocument(EDocument, EDocumentService, DocumentMetadata, ReceiveContext);
    end;

    [EventSubscriber(ObjectType::Page, Page::"E-Document Service", OnBeforeOpenServiceIntegrationSetupPage, '', false, false)]
    local procedure OnBeforeOpenServiceIntegrationSetupPage(EDocumentService: Record "E-Document Service"; var IsServiceIntegrationSetupRun: Boolean)
    var
        ConnectionSetupCard: Page "ForNAV Peppol Setup";
    begin
        if not EDocumentService.ForNAVIsServiceIntegration() then
            exit;
        ConnectionSetupCard.RunModal();
        IsServiceIntegrationSetupRun := true;
    end;

    procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    begin
        ActionContext.Http().GetHttpRequestMessage().SetRequestUri('https://GetApprovalStatus');
        // Use a dummy label because the URL is mandatory but we don't use it
        exit(ForNAVProcessing.GetDocumentApproval(EDocument) = "ForNAV Incoming E-Doc Status"::Approved);
    end;

    procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    begin
        // Use a dummy label because the URL is mandatory but we don't use it
        ActionContext.Http().GetHttpRequestMessage().SetRequestUri('https://GetCancellationStatus');
        exit(ForNAVProcessing.GetDocumentApproval(EDocument) = "ForNAV Incoming E-Doc Status"::Rejected);
    end;

    procedure ObtainPrivacyConsent(): Boolean
    var
        CustConsentMgt: Codeunit "Customer Consent Mgt.";
        CustomConsentMessageLbl: Label 'Please agree to the ForNAV EULA: https://www.fornav.com/documents/EULA.pdf';
    begin
        exit(CustConsentMgt.ConfirmCustomConsent(CustomConsentMessageLbl));
    end;
}
