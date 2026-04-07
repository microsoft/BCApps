// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

codeunit 6125 "Prepare Purchase E-Doc. Draft" implements IProcessStructuredData
{
    Access = Internal;

    var
        PrepareDraftHelper: Codeunit "EDoc Prepare Purch. Draft";

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    begin
        PrepareDraftHelper.PrepareDraft(EDocument, EDocImportParameters);
        exit("E-Document Type"::"Purchase Invoice");
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

    local procedure ComputeAndApplyVATAmountDifference(EDocumentPurchaseHeader: Record "E-Document Purchase Header"; TotalLineVATAmount: Decimal)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ActivityLog: Codeunit "Activity Log Builder";
        VATAmountDiff: Decimal;
        Reasoning: Text[250];
        VATDiffAppliedLbl: Label 'Applied VAT amount difference of %1 to reconcile document Total VAT %2 with computed Total Line VAT Amount %3.', Comment = '%1 = VAT difference, %2 = Total VAT, %3 = Total Line VAT Amount';
        VATDiffSkippedSetupLbl: Label 'VAT amount difference of %1 was not applied because Apply VAT Diff. For Purch. E-Doc. is disabled in Purchases & Payables Setup.', Comment = '%1 = VAT difference';
        VATDiffSkippedAllowLbl: Label 'VAT amount difference of %1 was not applied because Allow VAT Difference is disabled in Purchases & Payables Setup.', Comment = '%1 = VAT difference';
        VATDiffSkippedMaxLbl: Label 'VAT amount difference of %1 was not applied because it exceeds the Max. VAT Difference Allowed of %2 in General Ledger Setup.', Comment = '%1 = VAT difference, %2 = Max. VAT Difference Allowed';
    begin
        if (EDocumentPurchaseHeader."Total VAT" = 0) or (TotalLineVATAmount = EDocumentPurchaseHeader."Total VAT") then
            exit;

        VATAmountDiff := EDocumentPurchaseHeader."Total VAT" - TotalLineVATAmount;

        if not PurchasesPayablesSetup.Get() then
            exit;

        if not PurchasesPayablesSetup."Apply VAT Diff. For Purch EDoc" then begin
            Reasoning := CopyStr(StrSubstNo(VATDiffSkippedSetupLbl, VATAmountDiff), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
            exit;
        end;

        if not PurchasesPayablesSetup."Allow VAT Difference" then begin
            Reasoning := CopyStr(StrSubstNo(VATDiffSkippedAllowLbl, VATAmountDiff), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
            exit;
        end;

        if not GeneralLedgerSetup.Get() then
            exit;
        if Abs(VATAmountDiff) > GeneralLedgerSetup."Max. VAT Difference Allowed" then begin
            Reasoning := CopyStr(StrSubstNo(VATDiffSkippedMaxLbl, VATAmountDiff, GeneralLedgerSetup."Max. VAT Difference Allowed"), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
            exit;
        end;

        Reasoning := CopyStr(StrSubstNo(VATDiffAppliedLbl, VATAmountDiff, EDocumentPurchaseHeader."Total VAT", TotalLineVATAmount), 1, MaxStrLen(Reasoning));
        ActivityLog
            .Init(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.FieldNo("Total VAT"), EDocumentPurchaseHeader.SystemId)
            .SetExplanation(Reasoning)
            .SetType(Enum::"Activity Log Type"::"AL")
            .Log();
    end;
}
