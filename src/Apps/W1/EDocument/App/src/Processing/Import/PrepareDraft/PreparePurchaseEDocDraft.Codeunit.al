// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;
using System.Config;

codeunit 6125 "Prepare Purchase E-Doc. Draft" implements IProcessStructuredData
{
    Access = Internal;

    var
        PrepareDraftHelper: Codeunit "EDoc Prepare Purch. Draft";

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    var
        FeatureConfiguration: Codeunit "Feature Configuration";
    begin
        WarnIfNegativeTotal(EDocument);

        if FeatureConfiguration.GetConfiguration(AgentDrivenLineMatchingTok) = AgentDrivenTreatmentTok then
            exit("E-Document Type"::"Purchase Invoice");

        PrepareDraftHelper.PrepareDraft(EDocument, EDocImportParameters);
        exit("E-Document Type"::"Purchase Invoice");
    end;

    local procedure WarnIfNegativeTotal(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if EDocumentPurchaseHeader."E-Document Entry No." = 0 then
            exit;
        if EDocumentPurchaseHeader.Total >= 0 then
            exit;
        EDocImpSessionTelemetry.SetBool('Invoice With Negative Total', true);
        EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo(Total), NegativeInvoiceTotalMsg);
    end;

    procedure OpenDraftPage(var EDocument: Record "E-Document")
    begin
        PrepareDraftHelper.OpenDraftPage(EDocument);
    end;

    procedure CleanUpDraft(EDocument: Record "E-Document")
    begin
        PrepareDraftHelper.CleanUpDraft(EDocument);
    end;

    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations") Vendor: Record Vendor
    begin
        Vendor := PrepareDraftHelper.GetVendor(EDocument, Customizations);
    end;

    var
        AgentDrivenLineMatchingTok: Label 'PAAgentDrivenLineMatching', Locked = true;
        AgentDrivenTreatmentTok: Label 'agent_driven', Locked = true;
        NegativeInvoiceTotalMsg: Label 'The document total is negative, but the document was not identified as a credit note, so it is processed as a purchase invoice. If the document is a credit note, do not finalize this draft.';
}
