// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.Vendor;

codeunit 6403 "EDoc Prepare Cr. Memo Draft" implements IProcessStructuredData
{
    Access = Internal;

    var
        PrepareDraftHelper: Codeunit "EDoc Prepare Purch. Draft";

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    begin
        PrepareDraftHelper.PrepareDraft(EDocument, EDocImportParameters);
        ResolveInvoiceToApplyTo(EDocument);
        exit("E-Document Type"::"Purchase Credit Memo");
    end;

    local procedure ResolveInvoiceToApplyTo(EDocument: Record "E-Document")
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
        SeveralInvoicesReferencedMsg: Label 'The credit note refers to several invoices (%1). The credit memo is created without applying it; apply it to the invoices after posting.', Comment = '%1 = list of invoice numbers';
    begin
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        if (EDocumentPurchaseHeader."E-Document Entry No." = 0) or (EDocumentPurchaseHeader."[BC] Vendor No." = '') then
            exit;
        if (EDocumentPurchaseHeader."Applies-to Doc. No." <> '') or (EDocumentPurchaseHeader."Vendor Invoice No." = '') then
            exit;
        if EDocPurchaseDraftUtility.ReferencesSeveralInvoices(EDocumentPurchaseHeader."Vendor Invoice No.") then begin
            EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Applies-to Doc. No."),
                StrSubstNo(SeveralInvoicesReferencedMsg, EDocumentPurchaseHeader."Vendor Invoice No."));
            exit;
        end;

        if EDocPurchDocHelper.TryResolveOpenInvoice(
            EDocPurchDocHelper.GetPayToVendorNo(EDocumentPurchaseHeader."[BC] Vendor No."), EDocumentPurchaseHeader."Currency Code",
            EDocumentPurchaseHeader."Vendor Invoice No.", PostedInvoiceNo, FailureReason)
        then begin
            EDocumentPurchaseHeader."Applies-to Doc. No." := PostedInvoiceNo;
            EDocumentPurchaseHeader.Modify();
        end else
            EDocumentErrorHelper.LogWarningMessage(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseHeader.FieldNo("Applies-to Doc. No."), FailureReason);
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
}
