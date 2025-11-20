// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Projects.Project.Posting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;

codeunit 816 "Purch. Post Invoice" implements "Invoice Posting"
{
    Permissions = TableData "Invoice Posting Buffer" = rimd;

    var
        GLSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
        TempInvoicePostingBufferReverseCharge: Record "Invoice Posting Buffer" temporary;
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        DeferralUtilities: Codeunit "Deferral Utilities";
        DimensionManagement: Codeunit DimensionManagement;
        JobPostLine: Codeunit "Job Post-Line";
        PurchPostInvoiceEvents: Codeunit "Purch. Post Invoice Events";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        DeferralLineNo: Integer;
        InvDefLineNo: Integer;
        FALineNo: Integer;
        HideProgressWindow: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        SplitByFA: Boolean;
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        IncorrectInterfaceErr: Label 'This implementation designed to post Purchase Header table only.';
        TotalToDeferErr: Label 'The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.';

    procedure Check(TableID: Integer)
    begin
        if TableID <> Database::"Purchase Header" then
            error(IncorrectInterfaceErr);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetHideProgressWindow(NewHideProgressWindow: Boolean)
    begin
        HideProgressWindow := NewHideProgressWindow;
    end;

    procedure SetParameters(NewInvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        InvoicePostingParameters := NewInvoicePostingParameters;
    end;

    procedure SetTotalLines(TotalDocumentLine: Variant; TotalDocumentLineLCY: Variant)
    begin
        TotalPurchLine := TotalDocumentLine;
        TotalPurchLineLCY := TotalDocumentLineLCY;
    end;

    procedure ClearBuffers()
    begin
        TempDeferralHeader.DeleteAll();
        TempDeferralLine.DeleteAll();
        TempInvoicePostingBuffer.DeleteAll();
        TempInvoicePostingBufferReverseCharge.DeleteAll();
    end;

    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLineACY: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        AdjAmount: Decimal;
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        TotalNonDedVATBase: Decimal;
        TotalNonDedVATAmount: Decimal;
        TotalNonDedVATBaseACY: Decimal;
        TotalNonDedVATAmountACY: Decimal;
        TotalNonDedVATDiff: Decimal;
        DeferralAccount: Code[20];
        PurchAccount: Code[20];
        InvDiscAccount: code[20];
        LineDiscAccount: code[20];
        IsHandled: Boolean;
        InvoiceDiscountPosting: Boolean;
        LineDiscountPosting: Boolean;
    begin
        PurchHeader := DocumentHeaderVar;
        PurchLine := DocumentLineVar;
        PurchLineACY := DocumentLineACYVar;

        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforePrepareLine(PurchHeader, PurchLine, PurchLineACY, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        PurchSetup.Get();
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        GenPostingSetup.TestField(Blocked, false);

        PurchPostInvoiceEvents.RunOnPrepareLineOnBeforePreparePurchase(PurchHeader, PurchLine, GenPostingSetup);
        PrepareInvoicePostingBuffer(PurchLine, InvoicePostingBuffer);

        InitTotalAmounts(
            PurchLine, PurchLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY,
            TotalVATBase, TotalVATBaseACY, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff);

        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterAssignAmounts(PurchLine, PurchLineACY, TotalAmount, TotalAmountACY);

        if PurchLine."Deferral Code" <> '' then
            GetAmountsForDeferral(PurchLine, AmtToDefer, AmtToDeferACY, DeferralAccount);

        InvoiceDiscountPosting := PurchSetup."Discount Posting" in
           [PurchSetup."Discount Posting"::"Invoice Discounts", PurchSetup."Discount Posting"::"All Discounts"];
        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterSetInvoiceDiscountPosting(PurchHeader, PurchLine, InvoiceDiscountPosting);
        if InvoiceDiscountPosting then begin
            IsHandled := false;
            PurchPostInvoiceEvents.RunOnPrepareLineOnBeforeCalcInvoiceDiscountPosting(
                TempInvoicePostingBuffer, InvoicePostingBuffer, PurchHeader, PurchLine,
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
                if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
                    SetSalesTax(PurchLine, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    GenPostingSetup.TestField("Purch. Inv. Disc. Account");
                    if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
                        PrepareLineFADiscount(
                          InvoicePostingBuffer, GenPostingSetup, PurchLine."No.",
                          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff);
                        InvoicePostingBuffer.SetAccount(
                          GenPostingSetup.GetPurchInvDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, InvoicePostingBuffer);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"Fixed Asset";
                    end else begin
                        IsHandled := false;
                        InvDiscAccount := '';
                        PurchPostInvoiceEvents.RunOnPrepareLineOnBeforeSetInvoiceDiscAccount(
                            PurchLine, GenPostingSetup, InvDiscAccount, IsHandled);
                        if not IsHandled then
                            InvDiscAccount := GenPostingSetup.GetPurchInvDiscAccount();
                        InvoicePostingBuffer.SetAccount(InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, InvoicePostingBuffer);
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterSetInvoiceDiscAccount(
                            PurchLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                    end;
                end;
            end;
        end;

        LineDiscountPosting := PurchSetup."Discount Posting" in
           [PurchSetup."Discount Posting"::"Line Discounts", PurchSetup."Discount Posting"::"All Discounts"];
        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterSetLineDiscountPosting(PurchHeader, PurchLine, LineDiscountPosting);
        if LineDiscountPosting then begin
            IsHandled := false;
            PurchPostInvoiceEvents.RunOnPrepareLineOnBeforeCalcLineDiscountPosting(
               TempInvoicePostingBuffer, InvoicePostingBuffer, PurchHeader, PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                if PurchLine."Allocation Account No." = '' then
                    CalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
                if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
                    SetSalesTax(PurchLine, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    GenPostingSetup.TestField("Purch. Line Disc. Account");
                    if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
                        PrepareLineFADiscount(
                          InvoicePostingBuffer, GenPostingSetup, PurchLine."No.",
                          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff);
                        InvoicePostingBuffer.SetAccount(
                          GenPostingSetup.GetPurchLineDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, InvoicePostingBuffer);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"Fixed Asset";
                    end else begin
                        IsHandled := false;
                        LineDiscAccount := '';
                        PurchPostInvoiceEvents.RunOnPrepareLineOnBeforeSetLineDiscAccount(PurchLine, GenPostingSetup, LineDiscAccount, IsHandled);
                        if not IsHandled then
                            LineDiscAccount := GenPostingSetup.GetPurchLineDiscAccount();
                        InvoicePostingBuffer.SetAccount(LineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                        NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, InvoicePostingBuffer);
                        UpdateInvoicePostingBuffer(InvoicePostingBuffer);
                        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterSetLineDiscAccount(PurchLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                    end;
                end;
            end;
        end;

        PurchPostInvoiceEvents.RunOnPrepareLineOnBeforeAdjustTotalAmounts(PurchLine, TotalAmount, TotalAmountACY, PurchHeader.GetUseDate());
        if PurchSetup."Discount Posting" = PurchSetup."Discount Posting"::"No Discounts" then
            DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
          PurchLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, 0, 0)
        else
            DeferralUtilities.AdjustTotalAmountForDeferralsNoBase(
              PurchLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, PurchLine."Inv. Discount Amount" + PurchLine."Line Discount Amount", PurchLineACY."Inv. Discount Amount" + PurchLineACY."Line Discount Amount");

        IsHandled := false;
        PurchPostInvoiceEvents.RunOnPrepareLineOnBeforeSetAmounts(
            PurchLine, PurchLineACY, InvoicePostingBuffer,
            TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
        if not IsHandled then
            if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
                if PurchLine."Deferral Code" <> '' then
                    InvoicePostingBuffer.SetAmounts(
                        TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, PurchLine."VAT Difference", TotalVATBase, TotalVATBaseACY)
                else
                    InvoicePostingBuffer.SetAmountsNoVAT(TotalAmount, TotalAmountACY, PurchLine."VAT Difference")
            end else
                if (not PurchLine."Use Tax") or (PurchLine."VAT Calculation Type" <> PurchLine."VAT Calculation Type"::"Sales Tax") then
                    InvoicePostingBuffer.SetAmounts(
                        TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, PurchLine."VAT Difference", TotalVATBase, TotalVATBaseACY)
                else
                    InvoicePostingBuffer.SetAmountsNoVAT(TotalAmount, TotalAmountACY, PurchLine."VAT Difference");

        if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Sales Tax" then
            SetSalesTax(PurchLine, InvoicePostingBuffer);

        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, PurchLine);

        PurchAccount := GetPurchAccount(PurchLine, GenPostingSetup);

        PurchPostInvoiceEvents.RunOnPrepareLineOnBeforeSetAccount(PurchHeader, PurchLine, PurchAccount);
        InvoicePostingBuffer.SetAccount(PurchAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        NonDeductibleVAT.SetNonDeductibleVAT(InvoicePostingBuffer, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff);
        InvoicePostingBuffer."Deferral Code" := PurchLine."Deferral Code";
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, PurchLine, TempInvoicePostingBuffer, FALineNo, InvDefLineNo, DeferralLineNo, IsHandled);
        if not IsHandled then
            UpdateInvoicePostingBuffer(InvoicePostingBuffer);

        PurchPostInvoiceEvents.RunOnPrepareLineOnAfterUpdateInvoicePostingBuffer(
            PurchHeader, PurchLine, InvoicePostingBuffer, TempInvoicePostingBuffer);

        if PurchLine."Deferral Code" <> '' then begin
            PurchPostInvoiceEvents.RunOnPrepareLineOnBeforePrepareDeferralLine(
                PurchLine, InvoicePostingBuffer, PurchHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
            if PurchSetup."Discount Posting" = PurchSetup."Discount Posting"::"No Discounts" then
                PrepareDeferralLine(
                    PurchHeader, PurchLine, InvoicePostingBuffer.Amount, InvoicePostingBuffer."Amount (ACY)",
                    AmtToDefer, AmtToDeferACY, DeferralAccount, PurchAccount, 0, 0)
            else
                PrepareDeferralLine(
                    PurchHeader, PurchLine, InvoicePostingBuffer.Amount, InvoicePostingBuffer."Amount (ACY)",
                    AmtToDefer, AmtToDeferACY, DeferralAccount, PurchAccount, PurchLine."Inv. Discount Amount" + PurchLine."Line Discount Amount", PurchLineACY."Inv. Discount Amount" + PurchLineACY."Line Discount Amount");
            PurchPostInvoiceEvents.RunOnPrepareLineOnAfterPrepareDeferralLine(
                PurchLine, InvoicePostingBuffer, PurchHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
        end;

        if PurchLine."Prepayment Line" then
            if PurchLine."Prepmt. Amount Inv. (LCY)" <> 0 then begin
                AdjAmount := -PurchLine."Prepmt. Amount Inv. (LCY)";
                TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostingBuffer, PurchLine."No.", AdjAmount, PurchHeader."Currency Code" = '');
                TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostingBuffer, PurchPostPrepayments.GetCorrBalAccNo(PurchHeader, AdjAmount > 0),
                    -AdjAmount, PurchHeader."Currency Code" = '');
            end else
                if (PurchLine."Prepayment %" = 100) and (PurchLine."Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                    TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostingBuffer, PurchPostPrepayments.GetInvRoundingAccNo(PurchHeader."Vendor Posting Group"),
                        PurchLine."Prepmt. VAT Amount Inv. (LCY)", PurchHeader."Currency Code" = '');

        InsertTempInvoicePostingBufferReverseCharge(TempInvoicePostingBuffer);
    end;

    local procedure InsertTempInvoicePostingBufferReverseCharge(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        TempInvoicePostingBufferReverseCharge := TempInvoicePostingBuffer;
        if not TempInvoicePostingBufferReverseCharge.Insert() then
            TempInvoicePostingBufferReverseCharge.Modify();
    end;

    procedure PrepareInvoicePostingBuffer(var PurchLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        PurchPostInvoiceEvents.RunOnBeforePrepareInvoicePostingBuffer(PurchLine, InvoicePostingBuffer);

        Clear(InvoicePostingBuffer);
        InvoicePostingBuffer.Type := PurchLine.Type;
        InvoicePostingBuffer."System-Created Entry" := true;
        InvoicePostingBuffer."Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
        InvoicePostingBuffer."Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        InvoicePostingBuffer."VAT Bus. Posting Group" := PurchLine."VAT Bus. Posting Group";
        InvoicePostingBuffer."VAT Prod. Posting Group" := PurchLine."VAT Prod. Posting Group";
        InvoicePostingBuffer."VAT Calculation Type" := PurchLine."VAT Calculation Type";
        InvoicePostingBuffer."Global Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        InvoicePostingBuffer."Global Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        InvoicePostingBuffer."Dimension Set ID" := PurchLine."Dimension Set ID";
        InvoicePostingBuffer."Job No." := PurchLine."Job No.";
        InvoicePostingBuffer."VAT %" := PurchLine.GetVATPct();
        NonDeductibleVAT.Copy(InvoicePostingBuffer, PurchLine);
        InvoicePostingBuffer."VAT Difference" := PurchLine."VAT Difference";
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            InvoicePostingBuffer."FA Posting Date" := PurchLine."FA Posting Date";
            InvoicePostingBuffer."Depreciation Book Code" := PurchLine."Depreciation Book Code";
            InvoicePostingBuffer."Depr. until FA Posting Date" := PurchLine."Depr. until FA Posting Date";
            InvoicePostingBuffer."Duplicate in Depreciation Book" := PurchLine."Duplicate in Depreciation Book";
            InvoicePostingBuffer."Use Duplication List" := PurchLine."Use Duplication List";
            InvoicePostingBuffer."FA Posting Type" := PurchLine."FA Posting Type";
            InvoicePostingBuffer."Depreciation Book Code" := PurchLine."Depreciation Book Code";
            InvoicePostingBuffer."Salvage Value" := PurchLine."Salvage Value";
            InvoicePostingBuffer."Depr. Acquisition Cost" := PurchLine."Depr. Acquisition Cost";
            InvoicePostingBuffer."Maintenance Code" := PurchLine."Maintenance Code";
            InvoicePostingBuffer."Insurance No." := PurchLine."Insurance No.";
            InvoicePostingBuffer."Budgeted FA No." := PurchLine."Budgeted FA No.";
            InvoicePostingBuffer."No. of Fixed Asset Cards" := PurchLine."No. of Fixed Asset Cards";
        end;

        UpdateEntryDescriptionFromPurchaseLine(PurchLine, InvoicePostingBuffer);

        if InvoicePostingBuffer."VAT Calculation Type" = InvoicePostingBuffer."VAT Calculation Type"::"Sales Tax" then
            SetSalesTax(PurchLine, InvoicePostingBuffer);

        DimensionManagement.UpdateGlobalDimFromDimSetID(
            InvoicePostingBuffer."Dimension Set ID", InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code");

        if PurchLine."Line Discount %" = 100 then begin
            InvoicePostingBuffer."VAT Base Amount" := 0;
            InvoicePostingBuffer."VAT Base Amount (ACY)" := 0;
            InvoicePostingBuffer."VAT Amount" := 0;
            InvoicePostingBuffer."VAT Amount (ACY)" := 0;
            NonDeductibleVAT.ClearNonDeductibleVAT(InvoicePostingBuffer);
        end;

        InvoicePostingBuffer."Journal Templ. Name" := PurchLine.GetJnlTemplateName();

#if not CLEAN25
        InvoicePostingBuffer.RunOnAfterPreparePurchase(PurchLine, InvoicePostingBuffer);
#endif
        PurchPostInvoiceEvents.RunOnAfterPrepareInvoicePostingBuffer(PurchLine, InvoicePostingBuffer);
    end;

    local procedure UpdateEntryDescriptionFromPurchaseLine(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        PurchSetup.Get();
        InvoicePostingBuffer.UpdateEntryDescription(
            PurchSetup."Copy Line Descr. to G/L Entry",
            PurchaseLine."Line No.",
            PurchaseLine.Description,
            PurchaseLine.GetPurchHeader()."Posting Description");
    end;

    procedure SetSalesTax(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        InvoicePostingBuffer."Tax Area Code" := PurchaseLine."Tax Area Code";
        InvoicePostingBuffer."Tax Liable" := PurchaseLine."Tax Liable";
        InvoicePostingBuffer."Tax Group Code" := PurchaseLine."Tax Group Code";
        InvoicePostingBuffer."Use Tax" := PurchaseLine."Use Tax";
        InvoicePostingBuffer.Quantity := PurchaseLine."Qty. to Invoice (Base)";
    end;

    local procedure GetPurchAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup") PurchAccountNo: Code[20]
    begin
        if (PurchLine.Type = PurchLine.Type::"G/L Account") or (PurchLine.Type = PurchLine.Type::"Fixed Asset") then
            PurchAccountNo := PurchLine."No."
        else
            if PurchLine.IsCreditDocType() then
                PurchAccountNo := GenPostingSetup.GetPurchCrMemoAccount()
            else
                PurchAccountNo := GenPostingSetup.GetPurchAccount();

        PurchPostInvoiceEvents.RunOnAfterGetPurchAccount(PurchLine, GenPostingSetup, PurchAccountNo);
    end;

    local procedure CalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeCalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        case PurchLine."VAT Calculation Type" of
            PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                InvoicePostingBuffer.CalcDiscount(
                  PurchHeader."Prices Including VAT", -PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
            PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
            PurchLine."VAT Calculation Type"::"Sales Tax":
                if not PurchLine."Use Tax" then
                    InvoicePostingBuffer.CalcDiscount(
                      PurchHeader."Prices Including VAT", -PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount")
                else
                    InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Inv. Discount Amount", -PurchLineACY."Inv. Discount Amount");
        end;

        PurchPostInvoiceEvents.RunOnAfterCalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
    end;

    local procedure CalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeCalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        case PurchLine."VAT Calculation Type" of
            PurchLine."VAT Calculation Type"::"Normal VAT", PurchLine."VAT Calculation Type"::"Full VAT":
                InvoicePostingBuffer.CalcDiscount(
                  PurchHeader."Prices Including VAT", -PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
            PurchLine."VAT Calculation Type"::"Reverse Charge VAT":
                InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
            PurchLine."VAT Calculation Type"::"Sales Tax":
                if not PurchLine."Use Tax" then
                    InvoicePostingBuffer.CalcDiscount(
                      PurchHeader."Prices Including VAT", -PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount")
                else
                    InvoicePostingBuffer.CalcDiscountNoVAT(-PurchLine."Line Discount Amount", -PurchLineACY."Line Discount Amount");
        end;

        PurchPostInvoiceEvents.RunOnAfterCalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
    end;

    local procedure InitTotalAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var TotalNonDedVATBase: Decimal; var TotalNonDedVATAmount: Decimal; var TotalNonDedVATBaseACY: Decimal; var TotalNonDedVATAmountACY: Decimal; var TotalNonDedVATDiff: Decimal)
    begin
        TotalVAT := PurchLine."Amount Including VAT" - PurchLine.Amount;
        TotalVATACY := PurchLineACY."Amount Including VAT" - PurchLineACY.Amount;
        TotalAmount := PurchLine.Amount;
        TotalAmountACY := PurchLineACY.Amount;
        TotalVATBase := PurchLine."VAT Base Amount";
        TotalVATBaseACY := PurchLineACY."VAT Base Amount";
        NonDeductibleVAT.Init(
            TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, PurchLine, PurchLineACY);

        PurchPostInvoiceEvents.RunOnAfterInitTotalAmounts(PurchLine, PurchLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
    end;

    local procedure PrepareLineFADiscount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; GenPostingSetup: Record "General Posting Setup"; AccountNo: Code[20]; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; TotalVATBase: Decimal; TotalVATBaseACY: Decimal; TotalNonDedVATBase: Decimal; TotalNonDedVATAmount: Decimal; TotalNonDedVATBaseACY: Decimal; TotalNonDedVATAmountACY: Decimal; TotalNonDedVATDiff: Decimal)
    var
        DeprBook: Record "Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforePrepareLineFADiscount(InvoicePostingBuffer, GenPostingSetup, AccountNo, IsHandled);
        if IsHandled then
            exit;

        DeprBook.Get(InvoicePostingBuffer."Depreciation Book Code");
        if DeprBook."Subtract Disc. in Purch. Inv." then begin
            InvoicePostingBuffer.SetAccount(AccountNo, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
            NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, InvoicePostingBuffer);
            UpdateInvoicePostingBuffer(InvoicePostingBuffer);
            InvoicePostingBuffer.ReverseAmounts();
            InvoicePostingBuffer.SetAccount(
              GenPostingSetup.GetPurchFADiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
            NonDeductibleVAT.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, InvoicePostingBuffer);
            InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
            UpdateInvoicePostingBuffer(InvoicePostingBuffer);
            InvoicePostingBuffer.ReverseAmounts();
        end;
    end;

    local procedure UpdateInvoicePostingBuffer(InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostingBuffer."Fixed Asset Line No." := FALineNo;
        end;

        TempInvoicePostingBuffer.Update(InvoicePostingBuffer, InvDefLineNo, DeferralLineNo);
    end;

    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        JobPurchLine: Record "Purchase Line";
        GLEntryNo: Integer;
        LineCount: Integer;
    begin
        PurchHeader := DocumentHeaderVar;

        PurchPostInvoiceEvents.RunOnBeforePostLines(PurchHeader, TempInvoicePostingBuffer);

        LineCount := 0;

        CalculateVATAmounts(PurchHeader, TempInvoicePostingBuffer);

        if TempInvoicePostingBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed() and not HideProgressWindow then
                    Window.Update(3, LineCount);

                TempInvoicePostingBuffer.ApplyRoundingForFinalPosting();
                PrepareGenJnlLine(PurchHeader, TempInvoicePostingBuffer, GenJnlLine);

                PurchPostInvoiceEvents.RunOnPostLinesOnBeforeGenJnlLinePost(
                    GenJnlLine, PurchHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);

                if SplitByFA then
                    SplitFA(GenJnlLine, TempInvoicePostingBuffer."No. of Fixed Asset Cards", GenJnlPostLine)
                else
                    GLEntryNo := RunGenJnlPostLine(GenJnlLine, GenJnlPostLine);

                PurchPostInvoiceEvents.RunOnPostLinesOnAfterGenJnlLinePost(
                    GenJnlLine, PurchHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);

                if (TempInvoicePostingBuffer."Job No." <> '') and
                   (TempInvoicePostingBuffer.Type = TempInvoicePostingBuffer.Type::"G/L Account")
                then begin
                    SetJobLineFilters(JobPurchLine, TempInvoicePostingBuffer);
                    JobPostLine.PostJobPurchaseLines(JobPurchLine.GetView(), GLEntryNo);
                end;
            until TempInvoicePostingBuffer.Next(-1) = 0;

        TempInvoicePostingBuffer.CalcSums(Amount);
        TotalAmount := TempInvoicePostingBuffer.Amount;

        TempInvoicePostingBuffer.DeleteAll();
    end;

    local procedure PrepareGenJnlLine(var PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        InitGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine.CopyFromPurchHeader(PurchHeader);

        InvoicePostingBuffer.CopyToGenJnlLine(GenJnlLine);
        PurchPostInvoiceEvents.RunOnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);
        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := InvoicePostingBuffer."Journal Templ. Name";
        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalPurchLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                PurchHeader.GetUseDate(), PurchHeader."Currency Code", TotalPurchLine."Pmt. Discount Amount", PurchHeader."Currency Factor");

        if InvoicePostingBuffer.Type <> InvoicePostingBuffer.Type::"Prepmt. Exch. Rate Difference" then
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            case InvoicePostingBuffer."FA Posting Type" of
                InvoicePostingBuffer."FA Posting Type"::"Acquisition Cost":
                    GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::"Acquisition Cost";
                InvoicePostingBuffer."FA Posting Type"::Maintenance:
                    GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Maintenance;
                InvoicePostingBuffer."FA Posting Type"::Appreciation:
                    GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Appreciation;
            end;
            InvoicePostingBuffer.CopyToGenJnlLineFA(GenJnlLine);
            SplitByFA := CalcSplitFA(GenJnlLine, InvoicePostingBuffer."No. of Fixed Asset Cards");
        end;

        PurchPostInvoiceEvents.RunOnAfterPrepareGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeInitGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", InvoicePostingBuffer."Entry Description",
            InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code",
            InvoicePostingBuffer."Dimension Set ID", PurchHeader."Reason Code");
    end;

    procedure PrepareJobLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLineACY: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchHeader := DocumentHeaderVar;
        PurchLine := DocumentLineVar;
        PurchLineACY := DocumentLineACYVar;

        if PurchHeader.IsCreditDocType() then
            PurchCrMemoHdr.Get(InvoicePostingParameters."Document No.")
        else
            PurchInvHeader.Get(InvoicePostingParameters."Document No.");

        JobPostLine.PostJobOnPurchaseLine(
            PurchHeader, PurchInvHeader, PurchCrMemoHdr, PurchLine, InvoicePostingParameters."Source Code");
    end;

    local procedure SetJobLineFilters(var JobPurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        JobPurchLine.Reset();
        JobPurchLine.SetRange("Job No.", InvoicePostingBuffer."Job No.");
        JobPurchLine.SetRange("No.", InvoicePostingBuffer."G/L Account");
        JobPurchLine.SetRange("Gen. Bus. Posting Group", InvoicePostingBuffer."Gen. Bus. Posting Group");
        JobPurchLine.SetRange("Gen. Prod. Posting Group", InvoicePostingBuffer."Gen. Prod. Posting Group");
        JobPurchLine.SetRange("VAT Bus. Posting Group", InvoicePostingBuffer."VAT Bus. Posting Group");
        JobPurchLine.SetRange("VAT Prod. Posting Group", InvoicePostingBuffer."VAT Prod. Posting Group");
        JobPurchLine.SetRange("Dimension Set ID", InvoicePostingBuffer."Dimension Set ID");

        if InvoicePostingBuffer."Fixed Asset Line No." <> 0 then begin
            PurchSetup.Get();
            if PurchSetup."Copy Line Descr. to G/L Entry" then
                JobPurchLine.SetRange("Line No.", InvoicePostingBuffer."Fixed Asset Line No.");
        end;

        PurchPostInvoiceEvents.RunOnAfterSetJobLineFilters(JobPurchLine, InvoicePostingBuffer);
    end;

    procedure CheckCreditLine(PurchHeaderVar: Variant; PurchLineVar: Variant)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        PurchHeader := PurchHeaderVar;
        PurchLine := PurchLineVar;

        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeCheckItemQuantityPurchCredit(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        if PurchLine.IsCreditDocType() then
            if (PurchLine."Job No." <> '') and (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."Qty. to Invoice" <> 0) then
                JobPostLine.CheckItemQuantityPurchCredit(PurchHeader, PurchLine);
    end;

    procedure PostLedgerEntry(PurchHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        PurchHeader := PurchHeaderVar;

        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforePostLedgerEntry(
            PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, InvoicePostingParameters, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PurchHeader."Posting Description",
            PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
            PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := PurchHeader."Pay-to Vendor No.";
        GenJnlLine.CopyFromPurchHeader(PurchHeader);
        GenJnlLine.SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");
        GenJnlLine."System-Created Entry" := true;

        GenJnlLine.CopyFromPurchHeaderApplyTo(PurchHeader);
        GenJnlLine.CopyFromPurchHeaderPayment(PurchHeader);

        InitGenJnlLineAmountFieldsFromTotalLines(GenJnlLine, PurchHeader);

        PurchPostInvoiceEvents.RunOnPostLedgerEntryOnBeforeGenJnlPostLine(
            GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        PurchPostInvoiceEvents.RunOnPostLedgerEntryOnAfterGenJnlPostLine(
            GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    local procedure InitGenJnlLineAmountFieldsFromTotalLines(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeInitGenJnlLineAmountFieldsFromTotalLines(
            GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Amount := -TotalPurchLine."Amount Including VAT";
        GenJnlLine."Source Currency Amount" := -TotalPurchLine."Amount Including VAT";
        GenJnlLine."Amount (LCY)" := -TotalPurchLineLCY."Amount Including VAT";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalPurchLineLCY.Amount;
        GenJnlLine."Inv. Discount (LCY)" := -TotalPurchLineLCY."Inv. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible" := -TotalPurchLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                PurchHeader.GetUseDate(), PurchHeader."Currency Code", -TotalPurchLine."Pmt. Discount Amount", PurchHeader."Currency Factor");
    end;

    procedure PostBalancingEntry(PurchHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        EntryFound: Boolean;
        IsHandled: Boolean;
    begin
        PurchHeader := PurchHeaderVar;

        EntryFound := false;
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnPostBalancingEntryOnBeforeFindVendLedgEntry(
           PurchHeader, TotalPurchLine, InvoicePostingParameters, VendLedgEntry2, EntryFound, IsHandled);
        if IsHandled then
            exit;

        if not EntryFound then
            FindVendorLedgerEntry(VendLedgEntry2);

        PurchPostInvoiceEvents.RunOnPostBalancingEntryOnAfterFindVendLedgEntry(VendLedgEntry2);

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PurchHeader."Posting Description",
            PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
            PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

        PurchPostInvoiceEvents.RunOnPostBalancingEntryOnAfterInitNewLine(GenJnlLine, PurchHeader);

        GenJnlLine.CopyDocumentFields(
            GenJnlLine."Document Type"::" ", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := PurchHeader."Pay-to Vendor No.";
        GenJnlLine.CopyFromPurchHeader(PurchHeader);
        GenJnlLine.SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");

        if PurchHeader.IsCreditDocType() then
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund
        else
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;

        SetApplyToDocNo(PurchHeader, GenJnlLine);

        SetAmountsForBalancingEntry(PurchHeader, VendLedgEntry2, GenJnlLine, VendLedgEntry2."Remaining Pmt. Disc. Possible");

        PurchPostInvoiceEvents.RunOnPostBalancingEntryOnBeforeGenJnlPostLine(
            GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        PurchPostInvoiceEvents.RunOnPostBalancingEntryOnAfterGenJnlPostLine(
            GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    local procedure SetAmountsForBalancingEntry(PurchHeader: Record "Purchase Header"; var VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; RemainingPmtDiscPossible: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeSetAmountsForBalancingEntry(VendLedgEntry, GenJnlLine, TotalPurchLine, TotalPurchLineLCY, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Amount := TotalPurchLine."Amount Including VAT" + RemainingPmtDiscPossible;
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        VendLedgEntry.CalcFields(Amount);
        if VendLedgEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalPurchLineLCY."Amount Including VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalPurchLineLCY."Amount Including VAT" +
              Round(VendLedgEntry."Remaining Pmt. Disc. Possible" / VendLedgEntry."Adjusted Currency Factor");
        GenJnlLine."Allow Zero-Amount Posting" := true;

        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalPurchLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                PurchHeader.GetUseDate(), PurchHeader."Currency Code", TotalPurchLine."Pmt. Discount Amount", PurchHeader."Currency Factor");
    end;

    local procedure SetApplyToDocNo(PurchHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        if PurchHeader."Bal. Account Type" = PurchHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := PurchHeader."Bal. Account No.";
        GenJnlLine."Applies-to Doc. Type" := InvoicePostingParameters."Document Type";
        GenJnlLine."Applies-to Doc. No." := InvoicePostingParameters."Document No.";

        PurchPostInvoiceEvents.RunOnAfterSetApplyToDocNo(GenJnlLine, PurchHeader);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Document Type", InvoicePostingParameters."Document Type");
        VendorLedgerEntry.SetRange("Document No.", InvoicePostingParameters."Document No.");
        VendorLedgerEntry.FindLast();
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"): Integer
    begin
        PurchPostInvoiceEvents.RunOnBeforeRunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure GetAmountsForDeferral(PurchLine: Record "Purchase Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeGetAmountsForDeferral(PurchLine, AmtToDefer, AmtToDeferACY, DeferralAccount, IsHandled);
        if IsHandled then
            exit;

        DeferralTemplate.Get(PurchLine."Deferral Code");
        DeferralTemplate.TestField("Deferral Account");
        DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
            "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            AmtToDeferACY := TempDeferralHeader."Amount to Defer";
            AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
        end;

        if PurchLine.IsCreditDocType() then begin
            AmtToDefer := -AmtToDefer;
            AmtToDeferACY := -AmtToDeferACY;
        end;
    end;

    local procedure CalculateVATAmounts(PurchHeader: Record "Purchase Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        CurrencyDocument: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        RemainderInvoicePostingBuffer: Record "Invoice Posting Buffer";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        VATBaseAmount: Decimal;
        VATBaseAmountACY: Decimal;
        VATAmount: Decimal;
        VATAmountACY: Decimal;
        VATAmountRemainder: Decimal;
        VATAmountACYRemainder: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforeCalculateVATAmounts(PurchHeader, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        VATAmountRemainder := 0;
        VATAmountACYRemainder := 0;

        CurrencyDocument.Initialize(PurchHeader."Currency Code");

        if InvoicePostingBuffer.FindSet() then
            repeat
                case InvoicePostingBuffer."VAT Calculation Type" of
                    InvoicePostingBuffer."VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            VATPostingSetup.Get(InvoicePostingBuffer."VAT Bus. Posting Group", InvoicePostingBuffer."VAT Prod. Posting Group");
                            PurchPostInvoiceEvents.RunOnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(VATPostingSetup, PurchHeader, TempInvoicePostingBuffer);

                            VATBaseAmount := InvoicePostingBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100);
                            VATBaseAmountACY := InvoicePostingBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100);

                            if PurchHeader."Currency Code" <> '' then
                                VATBaseAmount := CurrExchRate.ExchangeAmtLCYToFCY(
                                    PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                                    VATBaseAmount, PurchHeader."Currency Factor");

                            VATAmount := VATBaseAmount * VATPostingSetup."VAT %" / 100;
                            VATAmountACY := VATBaseAmountACY * VATPostingSetup."VAT %" / 100;

                            PurchPostInvoiceEvents.RunOnCalculateVATAmountInBufferOnBeforeTempInvoicePostingBufferAssign(VATAmount, VATAmountACY, TempInvoicePostingBuffer);
                            TempInvoicePostingBufferReverseCharge := InvoicePostingBuffer;
                            if TempInvoicePostingBufferReverseCharge.Find() then begin
                                if VATPostingSetup."VAT %" = 0 then begin
                                    VATAmountRemainder := VATAmount;
                                    VATAmountACYRemainder := VATAmountACY;
                                end;

                                VATAmountRemainder += VATAmount;
                                InvoicePostingBuffer."VAT Amount" := Round(VATAmountRemainder, CurrencyDocument."Amount Rounding Precision");
                                VATAmountRemainder -= InvoicePostingBuffer."VAT Amount";

                                if PurchHeader."Currency Code" <> '' then
                                    InvoicePostingBuffer."VAT Amount" := Round(CurrExchRate.ExchangeAmtFCYToLCY(
                                            PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                                            InvoicePostingBuffer."VAT Amount", PurchHeader."Currency Factor"));

                                VATAmountACYRemainder += VATAmountACY;
                                InvoicePostingBuffer."VAT Amount (ACY)" := Round(VATAmountACYRemainder, Currency."Amount Rounding Precision");
                                VATAmountACYRemainder -= InvoicePostingBuffer."VAT Amount (ACY)";

                                InvoicePostingBuffer."VAT Base Amount" := Round(InvoicePostingBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                InvoicePostingBuffer."VAT Base Amount (ACY)" := Round(InvoicePostingBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100));
                            end else begin
                                if PurchHeader."Currency Code" <> '' then
                                    VATAmount := Round(
                                        CurrExchRate.ExchangeAmtFCYToLCY(PurchHeader.GetUseDate(), PurchHeader."Currency Code", VATAmount, PurchHeader."Currency Factor"))
                                else
                                    VATAmount := Round(VATAmount);

                                InvoicePostingBuffer."VAT Amount" := VATAmount;
                                InvoicePostingBuffer."VAT Amount (ACY)" := Round(VATAmountACY, Currency."Amount Rounding Precision");

                                InvoicePostingBuffer."VAT Base Amount" := Round(InvoicePostingBuffer."VAT Base Amount" * (1 - PurchHeader."VAT Base Discount %" / 100));
                                InvoicePostingBuffer."VAT Base Amount (ACY)" := Round(InvoicePostingBuffer."VAT Base Amount (ACY)" * (1 - PurchHeader."VAT Base Discount %" / 100));
                            end;
                            NonDeductibleVAT.Update(InvoicePostingBuffer, RemainderInvoicePostingBuffer, GetGeneralLedgerSetupAmountRoundingPrecision(CurrencyDocument."Amount Rounding Precision"));
                            PurchPostInvoiceEvents.RunOnCalculateVATAmountsOnReverseChargeVATOnBeforeModify(PurchHeader, CurrencyDocument, VATPostingSetup, InvoicePostingBuffer);
                            InvoicePostingBuffer.Modify();
                        end;
                    InvoicePostingBuffer."VAT Calculation Type"::"Sales Tax":
                        if InvoicePostingBuffer."Use Tax" then begin
                            InvoicePostingBuffer."VAT Amount" :=
                                Round(
                                    SalesTaxCalculate.CalculateTax(
                                        InvoicePostingBuffer."Tax Area Code", InvoicePostingBuffer."Tax Group Code",
                                        InvoicePostingBuffer."Tax Liable", PurchHeader."Posting Date",
                                        InvoicePostingBuffer.Amount, InvoicePostingBuffer.Quantity, 0));
                            GLSetup.Get();
                            if GLSetup."Additional Reporting Currency" <> '' then
                                InvoicePostingBuffer."VAT Amount (ACY)" :=
                                    CurrExchRate.ExchangeAmtLCYToFCY(
                                        PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                                        InvoicePostingBuffer."VAT Amount", 0);
                            InvoicePostingBuffer.Modify();
                        end;
                    else
                        PurchPostInvoiceEvents.RunOnCalculateVATAmountsOnAfterVatCalculationType(TempInvoicePostingBuffer, PurchHeader, VATPostingSetup);
                end;
            until InvoicePostingBuffer.Next() = 0;
    end;

    local procedure PrepareDeferralLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20]; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralPostingBuffer: Record "Deferral Posting Buffer";
        IsDeferralAmountCheck: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PurchPostInvoiceEvents.RunOnBeforePrepareDeferralLine(TempDeferralHeader, TempDeferralLine, PurchHeader, PurchLine, AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, PurchAccount, InvoicePostingParameters."Document No.", InvDefLineNo, IsHandled);
        if IsHandled then
            exit;

        DeferralTemplate.Get(PurchLine."Deferral Code");

        if TempDeferralHeader.Get(
            "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            if TempDeferralHeader."Amount to Defer" <> 0 then begin
                DeferralUtilities.FilterDeferralLines(
                  TempDeferralLine, "Deferral Document Type"::Purchase.AsInteger(), '', '',
                  PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");

                DeferralPostingBuffer.PreparePurch(PurchLine, InvoicePostingParameters."Document No.");
                DeferralPostingBuffer."Posting Date" := PurchHeader."Posting Date";
                DeferralPostingBuffer.Description := PurchHeader."Posting Description";
                DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                PurchPostInvoiceEvents.RunOnPrepareDeferralLineOnBeforePrepareInitialAmounts(
                    DeferralPostingBuffer, PurchHeader, PurchLine, AmountLCY, AmountACY,
                    RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, PurchAccount);
                DeferralPostingBuffer.PrepareInitialAmounts(
                  AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, PurchAccount, DeferralAccount, DiscountAmount, DiscountAmountACY);
                DeferralPostingBuffer.Update(DeferralPostingBuffer);
                if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
                    DeferralPostingBuffer.PrepareRemainderPurchase(
                      PurchLine, RemainAmtToDefer, RemainAmtToDeferACY, PurchAccount, DeferralAccount, InvDefLineNo);
                    DeferralPostingBuffer.Update(DeferralPostingBuffer);
                end;

                if TempDeferralLine.FindSet() then
                    repeat
                        if (TempDeferralLine."Amount (LCY)" <> 0) or (TempDeferralLine.Amount <> 0) then begin
                            if not IsDeferralAmountCheck then begin
                                CheckDeferralAmount(TempDeferralLine);
                                IsDeferralAmountCheck := true;
                            end;

                            DeferralPostingBuffer.PreparePurch(PurchLine, InvoicePostingParameters."Document No.");
                            DeferralPostingBuffer.InitFromDeferralLine(TempDeferralLine);
                            if PurchLine.IsCreditDocType() then
                                DeferralPostingBuffer.ReverseAmounts();
                            DeferralPostingBuffer."G/L Account" := PurchAccount;
                            DeferralPostingBuffer."Deferral Account" := DeferralAccount;
                            DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                            DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                            PurchPostInvoiceEvents.RunOnPrepareDeferralLineOnAfterInitFromDeferralLine(DeferralPostingBuffer, TempDeferralLine, PurchLine, DeferralTemplate);
                            DeferralPostingBuffer.Update(DeferralPostingBuffer);
                        end else
                            Error(ZeroDeferralAmtErr, PurchLine."No.", PurchLine."Deferral Code");

                    until TempDeferralLine.Next() = 0

                else
                    Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code");
            end else
                Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
        end else
            Error(NoDeferralScheduleErr, PurchLine."No.", PurchLine."Deferral Code")
    end;

    local procedure GetGeneralLedgerSetupAmountRoundingPrecision(CurrencyAmountRoundingPrecision: Decimal): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Amount Rounding Precision" <> 0 then
            exit(GeneralLedgerSetup."Amount Rounding Precision");

        exit(CurrencyAmountRoundingPrecision);
    end;

    local procedure CheckDeferralAmount(DeferralLine: Record "Deferral Line")
    var
        DeferralHeader: Record "Deferral Header";
    begin
        DeferralHeader.SetLoadFields("Amount to Defer", "Schedule Line Total");
        if not DeferralHeader.Get(
            DeferralLine."Deferral Doc. Type",
            DeferralLine."Gen. Jnl. Template Name",
            DeferralLine."Gen. Jnl. Batch Name",
            DeferralLine."Document Type",
            DeferralLine."Document No.",
            DeferralLine."Line No.")
        then
            exit;

        DeferralHeader.CalcFields("Schedule Line Total");
        if DeferralHeader."Schedule Line Total" <> DeferralHeader."Amount to Defer" then
            Error(TotalToDeferErr);
    end;

    procedure CalcDeferralAmounts(PurchHeaderVar: Variant; PurchLineVar: Variant; OriginalDeferralAmount: Decimal)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TotalAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalDeferralCount: Integer;
        DeferralCount: Integer;
    begin
        PurchHeader := PurchHeaderVar;
        PurchLine := PurchLineVar;

        if DeferralHeader.Get(
             "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            Currency.Initialize(PurchHeader."Currency Code", true);
            TempDeferralHeader := DeferralHeader;
            if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                TempDeferralHeader."Amount to Defer" :=
                  Round(TempDeferralHeader."Amount to Defer" *
                    PurchLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");
            TempDeferralHeader."Amount to Defer (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                  TempDeferralHeader."Amount to Defer", PurchHeader."Currency Factor"));
            PurchPostInvoiceEvents.RunOnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(TempDeferralHeader, DeferralHeader, PurchLine);
            TempDeferralHeader.Insert();

            DeferralUtilities.FilterDeferralLines(
                DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
            if DeferralLine.FindSet() then begin
                TotalDeferralCount := DeferralLine.Count();
                repeat
                    DeferralCount := DeferralCount + 1;
                    TempDeferralLine.Init();
                    TempDeferralLine := DeferralLine;

                    if DeferralCount = TotalDeferralCount then begin
                        TempDeferralLine.Amount := TempDeferralHeader."Amount to Defer" - TotalAmount;
                        TempDeferralLine."Amount (LCY)" := TempDeferralHeader."Amount to Defer (LCY)" - TotalAmountLCY;
                    end else begin
                        if PurchLine.Quantity <> PurchLine."Qty. to Invoice" then
                            TempDeferralLine.Amount :=
                                Round(TempDeferralLine.Amount *
                                    PurchLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");

                        TempDeferralLine."Amount (LCY)" :=
                            Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  PurchHeader.GetUseDate(), PurchHeader."Currency Code",
                                  TempDeferralLine.Amount, PurchHeader."Currency Factor"));
                        TotalAmount := TotalAmount + TempDeferralLine.Amount;
                        TotalAmountLCY := TotalAmountLCY + TempDeferralLine."Amount (LCY)";
                    end;
                    PurchPostInvoiceEvents.RunOnBeforeTempDeferralLineInsert(
                        TempDeferralLine, DeferralLine, PurchLine, DeferralCount, TotalDeferralCount);
                    TempDeferralLine.Insert();
                until DeferralLine.Next() = 0;
            end;
        end;
    end;

    procedure CreatePostedDeferralSchedule(PurchLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        PurchLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralAccount: Code[20];
        IsHandled: Boolean;
    begin
        PurchLine := PurchLineVar;

        if PurchLine."Deferral Code" = '' then
            exit;

        PurchPostInvoiceEvents.RunOnBeforeCreatePostedDeferralSchedule(PurchLine, IsHandled);

        if IsHandled then
            exit;

        if DeferralTemplate.Get(PurchLine."Deferral Code") then
            DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
             "Deferral Document Type"::Purchase, '', '', PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.")
        then begin
            PostedDeferralHeader.InitFromDeferralHeader(TempDeferralHeader, '', '',
                NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount, PurchLine."Buy-from Vendor No.", PostingDate);
            DeferralUtilities.FilterDeferralLines(
                TempDeferralLine, "Deferral Document Type"::Purchase.AsInteger(), '', '',
                PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.");
            if TempDeferralLine.FindSet() then
                repeat
                    PostedDeferralLine.InitFromDeferralLine(
                      TempDeferralLine, '', '', NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount);
                until TempDeferralLine.Next() = 0;
        end;

        PurchPostInvoiceEvents.RunOnAfterCreatePostedDeferralSchedule(PurchLine, PostedDeferralHeader);
    end;

    local procedure CalcSplitFA(GenJnlLine: Record "Gen. Journal Line"; SplitNo: Integer) SplitEnabled: Boolean
    begin
        SplitEnabled :=
          (SplitNo >= 2) and
          (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::"Acquisition Cost");
        PurchPostInvoiceEvents.RunOnCalcSplitFA(GenJnlLine, SplitNo, SplitEnabled);
    end;

    local procedure SplitFA(GenJnlLine: Record "Gen. Journal Line"; SplitNo: Integer; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        GenJnlLine2: Record "Gen. Journal Line";
        TotalGenJnlLine: Record "Gen. Journal Line";
        TempFA: Record "Fixed Asset" temporary;
        I: Integer;
    begin
        CreateTempFA(GenJnlLine, SplitNo, TempFA);
        TotalGenJnlLine := GenJnlLine;
        Clear(GenJnlLine2);
        Clear(TempFA);
        TempFA."No." := '';
        for I := 1 to SplitNo do begin
            TempFA.Next();
            GenJnlLine."Account No." := TempFA."No.";
            CalcSplitAmount(
                GenJnlLine.Amount, GenJnlLine2.Amount, TotalGenJnlLine.Amount, I, SplitNo);
            CalcSplitAmount(
                GenJnlLine."Source Currency Amount", GenJnlLine2."Source Currency Amount",
                TotalGenJnlLine."Source Currency Amount", I, SplitNo);
            CalcSplitAmount(
                GenJnlLine.Quantity, GenJnlLine2.Quantity, TotalGenJnlLine.Quantity, I, SplitNo);
            CalcSplitAmount(
                GenJnlLine."VAT Base Amount", GenJnlLine2."VAT Base Amount", TotalGenJnlLine."VAT Base Amount", I, SplitNo);
            CalcSplitAmount(
                GenJnlLine."Source Curr. VAT Amount",
                GenJnlLine2."Source Curr. VAT Amount", TotalGenJnlLine."Source Curr. VAT Amount", I, SplitNo);
            CalcSplitAmount(
                GenJnlLine."VAT Amount", GenJnlLine2."VAT Amount", TotalGenJnlLine."VAT Amount", I, SplitNo);
            CalcSplitAmount(
                GenJnlLine."Source Curr. VAT Amount",
                GenJnlLine2."Source Curr. VAT Amount", TotalGenJnlLine."Source Curr. VAT Amount", I, SplitNo);
            CalcSplitAmount(
                GenJnlLine."VAT Difference", GenJnlLine2."VAT Difference", TotalGenJnlLine."VAT Difference", I, SplitNo);
            CalcSplitAmount(
                GenJnlLine."Salvage Value", GenJnlLine2."Salvage Value", TotalGenJnlLine."Salvage Value", I, SplitNo);

            RunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
        end;
    end;

    procedure CreateTempFA(GenJnlLine: Record "Gen. Journal Line"; SplitNo: Integer; var TempFA: Record "Fixed Asset" temporary): Boolean
    var
        FASetup: Record "FA Setup";
        FA: Record "Fixed Asset";
        FA2: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        I: Integer;
    begin
        FASetup.Get();
        FASetup.TestField("Fixed Asset Nos.");
        TempFA.DeleteAll();
        FA.Get(GenJnlLine."Account No.");
        TempFA := FA;
        TempFA.Insert();
        SplitNo := SplitNo - 1;
        for I := 1 to SplitNo do begin
            FA2 := FA;
            FA2."No." := '';
            FA2.Insert(true);

            AddDefaultDimensionsToFA(FA, FA2);

            TempFA := FA2;
            TempFA.Insert();
            Clear(FADeprBook);
            FADeprBook.SetRange("FA No.", FA."No.");
            if FADeprBook.FindSet() then
                repeat
                    FADeprBook2 := FADeprBook;
                    FADeprBook2."FA No." := FA2."No.";
                    FADeprBook2.Insert(true);
                until FADeprBook.Next() = 0;
        end;
    end;

    local procedure AddDefaultDimensionsToFA(FA: Record "Fixed Asset"; var FA2: Record "Fixed Asset")
    var
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::"Fixed Asset");
        DefaultDimension.SetRange("No.", FA."No.");
        if DefaultDimension.FindSet() then
            repeat
                DefaultDimension2 := DefaultDimension;
                DefaultDimension2."No." := FA2."No.";
                DefaultDimension2.Insert();
            until DefaultDimension.Next() = 0;
        FA2."Global Dimension 1 Code" := FA."Global Dimension 1 Code";
        FA2."Global Dimension 2 Code" := FA."Global Dimension 2 Code";
        FA2.Modify(true);
    end;

    local procedure CalcSplitAmount(var Amount: Decimal; var Amount2: Decimal; TotalAmount: Decimal; I: Integer; SplitNo: Integer)
    begin
        if I < SplitNo then
            Amount := Round(TotalAmount * I / SplitNo - Amount2)
        else
            Amount := TotalAmount - Amount2;
        Amount2 += Amount;
    end;
}
