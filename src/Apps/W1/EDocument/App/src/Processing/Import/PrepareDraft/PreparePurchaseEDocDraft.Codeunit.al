// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.VAT.Setup;
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

    local procedure ResolveVATProductPostingGroups(EDocumentEntryNo: Integer; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        VATRate: Decimal;
        LineCount: Integer;
    begin
        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then
            exit;
        if not Vendor.Get(EDocumentPurchaseHeader."[BC] Vendor No.") then
            exit;
        if Vendor."VAT Bus. Posting Group" = '' then
            exit;

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        LineCount := EDocumentPurchaseLine.Count();
        if LineCount = 0 then
            exit;

        if EDocumentPurchaseLine.FindSet() then
            repeat
                VATRate := EDocumentPurchaseLine."VAT Rate";

                // Single-line fallback: compute from header Total VAT
                if (VATRate = 0) and (LineCount = 1) and
                   (EDocumentPurchaseHeader."Total VAT" > 0) and (EDocumentPurchaseHeader."Sub Total" > 0)
                then
                    VATRate := Round((EDocumentPurchaseHeader."Total VAT" / EDocumentPurchaseHeader."Sub Total") * 100, 0.01);

                if VATRate > 0 then begin
                    EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" :=
                        FindVATProductPostingGroup(Vendor."VAT Bus. Posting Group", VATRate);
                    EDocumentPurchaseLine."[BC] VAT Rate Mismatch" :=
                        EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" = '';
                    EDocumentPurchaseLine.Modify();
                end;
            until EDocumentPurchaseLine.Next() = 0;
    end;

    local procedure FindVATProductPostingGroup(VATBusPostingGroup: Code[20]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT Calculation Type", '%1|%2',
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.SetRange("VAT %", VATRate);
        if VATPostingSetup.Count() = 1 then begin
            VATPostingSetup.FindFirst();
            exit(VATPostingSetup."VAT Prod. Posting Group");
        end;
        exit('');
    end;
}