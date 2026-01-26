// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Projects.Project.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

codeunit 815 "Sales Post Invoice" implements "Invoice Posting"
{
    Permissions = TableData "Invoice Posting Buffer" = rimd;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        TempDeferralHeader: Record "Deferral Header" temporary;
        TempDeferralLine: Record "Deferral Line" temporary;
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
        TempInvoicePostingBufferGST: Record "Invoice Posting Buffer" temporary;
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        DeferralUtilities: Codeunit "Deferral Utilities";
        DimensionManagement: Codeunit DimensionManagement;
        JobPostLine: Codeunit "Job Post-Line";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        SalesPostInvoiceEvents: Codeunit "Sales Post Invoice Events";
        DeferralLineNo: Integer;
        InvDefLineNo: Integer;
        FALineNo: Integer;
        HideProgressWindow: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        IncorrectInterfaceErr: Label 'This implementation designed to post Sales Header table only.';
        TotalToDeferErr: Label 'The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.';

    procedure Check(TableID: Integer)
    begin
        if TableID <> Database::"Sales Header" then
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
        TotalSalesLine := TotalDocumentLine;
        TotalSalesLineLCY := TotalDocumentLineLCY;
    end;

    procedure ClearBuffers()
    begin
        TempDeferralHeader.DeleteAll();
        TempDeferralLine.DeleteAll();
        TempInvoicePostingBuffer.DeleteAll();
    end;

    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineACY: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        AdjAmount: Decimal;
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        AmtToDefer: Decimal;
        AmtToDeferACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        DeferralAccount: Code[20];
        SalesAccount: Code[20];
        InvDiscAccount: code[20];
        LineDiscAccount: code[20];
        IsHandled: Boolean;
        InvoiceDiscountPosting: Boolean;
        LineDiscountPosting: Boolean;
    begin
        SalesHeader := DocumentHeaderVar;
        SalesLine := DocumentLineVar;
        SalesLineACY := DocumentLineACYVar;

        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforePrepareLine(SalesHeader, SalesLine, SalesLineACY, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        SalesSetup.Get();
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GenPostingSetup.TestField(Blocked, false);

        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforePrepareSales(SalesHeader, SalesLine, GenPostingSetup);
        PrepareInvoicePostingBuffer(SalesLine, InvoicePostingBuffer);

        InitTotalAmounts(
            SalesLine, SalesLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY,
            TotalVATBase, TotalVATBaseACY);

        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterAssignAmounts(SalesLine, SalesLineACY, TotalAmount, TotalAmountACY);

        if SalesLine."Deferral Code" <> '' then
            GetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount);

        InvoiceDiscountPosting := SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"];
        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader, SalesLine, InvoiceDiscountPosting);
        if InvoiceDiscountPosting then begin
            IsHandled := false;
            SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeCalcInvoiceDiscountPosting(
                TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine,
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                CalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    InvDiscAccount := '';
                    SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvDiscAccount, IsHandled);
                    if not IsHandled then
                        InvDiscAccount := GenPostingSetup.GetSalesInvDiscAccount();
                    InvoicePostingBuffer.SetAccount(InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    UpdateInvoicePostingBuffer(InvoicePostingBuffer, true);
                    SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                end;
            end;
        end;

        LineDiscountPosting := SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"];
        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader, SalesLine, LineDiscountPosting);
        if LineDiscountPosting then begin
            IsHandled := false;
            SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeCalcLineDiscountPosting(
               TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
            if not IsHandled then begin
                if SalesLine."Allocation Account No." = '' then
                    CalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
                if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                    IsHandled := false;
                    LineDiscAccount := '';
                    SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetLineDiscAccount(SalesLine, GenPostingSetup, LineDiscAccount, IsHandled);
                    if not IsHandled then
                        LineDiscAccount := GenPostingSetup.GetSalesLineDiscAccount();
                    IsHandled := false;
                    SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeInvoicePostingBufferSetAccount(InvoicePostingBuffer, SalesLine, GenPostingSetup, LineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
                    if not IsHandled then
                        InvoicePostingBuffer.SetAccount(LineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                    UpdateInvoicePostingBuffer(InvoicePostingBuffer, true);
                    SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetLineDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
                end;
            end;
        end;

        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine, TotalAmount, TotalAmountACY, SalesHeader.GetUseDate());
        DeferralUtilities.AdjustTotalAmountForDeferrals(
            SalesLine."Deferral Code", AmtToDefer, AmtToDeferACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, SalesLine."Inv. Discount Amount" + SalesLine."Line Discount Amount", SalesLineACY."Inv. Discount Amount" + SalesLineACY."Line Discount Amount");

        IsHandled := false;
        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetAmounts(
            SalesLine, SalesLineACY, InvoicePostingBuffer,
            TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
        if not IsHandled then
            InvoicePostingBuffer.SetAmounts(
                TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, SalesLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then
            SetSalesTax(SalesLine, InvoicePostingBuffer);

        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, SalesLine);

        SalesAccount := GetSalesAccount(SalesLine, GenPostingSetup);

        SalesPostInvoiceEvents.RunOnPrepareLineOnBeforeSetAccount(SalesHeader, SalesLine, SalesAccount);
        InvoicePostingBuffer.SetAccount(SalesAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
        InvoicePostingBuffer."Deferral Code" := SalesLine."Deferral Code";
        if SalesLine."Prepayment Line" and (SalesLine."Prepayment %" <> 100) then
            if GLSetup.CheckFullGSTonPrepayment(
                 SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group")
            then begin
                InvoicePostingBuffer."VAT Base Amount" := Round(SalesLine."VAT Base Amount", Currency."Amount Rounding Precision");
                InvoicePostingBuffer."VAT Base Amount (ACY)" := Round(SalesLineACY."VAT Base Amount", Currency."Amount Rounding Precision");
            end;
        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, SalesLine);
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeUpdateInvoicePostingBuffer(TempInvoicePostingBuffer, InvoicePostingBuffer, false, InvDefLineNo, DeferralLineNo, FALineNo, SalesLine, IsHandled);
        if not IsHandled then
            UpdateInvoicePostingBuffer(InvoicePostingBuffer, false);

        SalesPostInvoiceEvents.RunOnPrepareLineOnAfterUpdateInvoicePostingBuffer(
            SalesHeader, SalesLine, InvoicePostingBuffer, TempInvoicePostingBuffer);

        if SalesLine."Deferral Code" <> '' then begin
            SalesPostInvoiceEvents.RunOnPrepareLineOnBeforePrepareDeferralLine(
                SalesLine, InvoicePostingBuffer, SalesHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit, DeferralAccount, SalesAccount);
            PrepareDeferralLine(
                SalesHeader, SalesLine, InvoicePostingBuffer.Amount, InvoicePostingBuffer."Amount (ACY)",
                AmtToDefer, AmtToDeferACY, DeferralAccount, SalesAccount, SalesLine."Inv. Discount Amount" + SalesLine."Line Discount Amount", SalesLineACY."Inv. Discount Amount" + SalesLineACY."Line Discount Amount");
            SalesPostInvoiceEvents.RunOnPrepareLineOnAfterPrepareDeferralLine(
                SalesLine, InvoicePostingBuffer, SalesHeader.GetUseDate(), InvDefLineNo, DeferralLineNo, SuppressCommit);
        end;

        if SalesLine."Prepayment Line" then
            if SalesLine."Prepmt. Amount Inv. (LCY)" <> 0 then begin
                AdjAmount := -SalesLine."Prepmt. Amount Inv. (LCY)";
                TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostingBuffer, SalesLine."No.", AdjAmount, SalesHeader."Currency Code" = '');
                TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                    InvoicePostingBuffer, SalesPostPrepayments.GetCorrBalAccNo(SalesHeader, AdjAmount > 0),
                    -AdjAmount, SalesHeader."Currency Code" = '');
            end else
                if (SalesLine."Prepayment %" = 100) and (SalesLine."Prepmt. VAT Amount Inv. (LCY)" <> 0) then
                    TempInvoicePostingBuffer.PreparePrepmtAdjBuffer(
                        InvoicePostingBuffer, SalesPostPrepayments.GetInvRoundingAccNo(SalesHeader."Customer Posting Group"),
                        SalesLine."Prepmt. VAT Amount Inv. (LCY)", SalesHeader."Currency Code" = '');

        PrepareLineGST(SalesHeader, SalesLine, SalesLineACY);
    end;

    internal procedure SetSalesTax(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        InvoicePostingBuffer."Tax Area Code" := SalesLine."Tax Area Code";
        InvoicePostingBuffer."Tax Liable" := SalesLine."Tax Liable";
        InvoicePostingBuffer."Tax Group Code" := SalesLine."Tax Group Code";
        InvoicePostingBuffer."Use Tax" := false;
        InvoicePostingBuffer.Quantity := SalesLine."Qty. to Invoice (Base)";
    end;

    local procedure GetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup") SalesAccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, IsHandled);
        if not IsHandled then
            if (SalesLine.Type = SalesLine.Type::"G/L Account") or (SalesLine.Type = SalesLine.Type::"Fixed Asset") then
                SalesAccountNo := SalesLine."No."
            else
                if SalesLine.IsCreditDocType() then
                    SalesAccountNo := GenPostingSetup.GetSalesCrMemoAccount()
                else
                    SalesAccountNo := GenPostingSetup.GetSalesAccount();

        SalesPostInvoiceEvents.RunOnAfterGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo);
    end;

    local procedure CalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
                -SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
                SalesHeader."Prices Including VAT", -SalesLine."Inv. Discount Amount", -SalesLineACY."Inv. Discount Amount");

        SalesPostInvoiceEvents.RunOnAfterCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    local procedure CalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
                -SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
                SalesHeader."Prices Including VAT", -SalesLine."Line Discount Amount", -SalesLineACY."Line Discount Amount");

        SalesPostInvoiceEvents.RunOnAfterCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    local procedure InitTotalAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        TotalVAT := SalesLine."Amount Including VAT" - SalesLine.Amount;
        TotalVATACY := SalesLineACY."Amount Including VAT" - SalesLineACY.Amount;
        TotalAmount := SalesLine.Amount;
        TotalAmountACY := SalesLineACY.Amount;
        TotalVATBase := SalesLine."VAT Base Amount";
        TotalVATBaseACY := SalesLineACY."VAT Base Amount";

        SalesPostInvoiceEvents.RunOnAfterInitTotalAmounts(SalesLine, SalesLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
    end;

    procedure PrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesPostInvoiceEvents.RunOnBeforePrepareInvoicePostingBuffer(SalesLine, InvoicePostingBuffer);

        Clear(InvoicePostingBuffer);
        InvoicePostingBuffer.Type := SalesLine.Type;
        InvoicePostingBuffer."System-Created Entry" := true;
        InvoicePostingBuffer."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        InvoicePostingBuffer."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        InvoicePostingBuffer."VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        InvoicePostingBuffer."VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
        InvoicePostingBuffer."VAT Calculation Type" := SalesLine."VAT Calculation Type";
        InvoicePostingBuffer."Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        InvoicePostingBuffer."Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        InvoicePostingBuffer."Dimension Set ID" := SalesLine."Dimension Set ID";
        InvoicePostingBuffer."Job No." := SalesLine."Job No.";
        InvoicePostingBuffer."VAT %" := SalesLine.GetVATPct();
        InvoicePostingBuffer."VAT Difference" := SalesLine."VAT Difference";
        InvoicePostingBuffer."VAT Base (ACY)" := SalesLine."VAT Base (ACY)";
        InvoicePostingBuffer."VAT Difference (ACY)" := SalesLine."VAT Difference (ACY)";
        InvoicePostingBuffer."Amount Including VAT (ACY)" := SalesLine."Amount Including VAT (ACY)";
        InvoicePostingBuffer."VAT Amount(ACY)" := SalesLine."Amount Including VAT (ACY)" - SalesLine."VAT Base (ACY)";
        if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then begin
            InvoicePostingBuffer.Adjustment := SalesHeader.Adjustment;
            InvoicePostingBuffer."BAS Adjustment" := SalesHeader."BAS Adjustment";
            InvoicePostingBuffer."Adjustment Applies-to" := SalesHeader."Adjustment Applies-to";
        end;
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            InvoicePostingBuffer."FA Posting Date" := SalesLine."FA Posting Date";
            InvoicePostingBuffer."Depreciation Book Code" := SalesLine."Depreciation Book Code";
            InvoicePostingBuffer."Depr. until FA Posting Date" := SalesLine."Depr. until FA Posting Date";
            InvoicePostingBuffer."Duplicate in Depreciation Book" := SalesLine."Duplicate in Depreciation Book";
            InvoicePostingBuffer."Use Duplication List" := SalesLine."Use Duplication List";
        end;

        UpdateEntryDescriptionFromSalesLine(SalesLine, InvoicePostingBuffer);

        if InvoicePostingBuffer."VAT Calculation Type" = InvoicePostingBuffer."VAT Calculation Type"::"Sales Tax" then
            SetSalesTax(SalesLine, InvoicePostingBuffer);

        DimensionManagement.UpdateGlobalDimFromDimSetID(
            InvoicePostingBuffer."Dimension Set ID", InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code");

        if SalesLine."Line Discount %" = 100 then begin
            InvoicePostingBuffer."VAT Base Amount" := 0;
            InvoicePostingBuffer."VAT Base Amount (ACY)" := 0;
            InvoicePostingBuffer."VAT Amount" := 0;
            InvoicePostingBuffer."VAT Amount (ACY)" := 0;
            NonDeductibleVAT.ClearNonDeductibleVAT(InvoicePostingBuffer);
        end;

        InvoicePostingBuffer."Journal Templ. Name" := SalesLine.GetJnlTemplateName();
        SalesPostInvoiceEvents.RunOnAfterPrepareInvoicePostingBuffer(SalesLine, InvoicePostingBuffer);
    end;

    local procedure UpdateEntryDescriptionFromSalesLine(SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        SalesSetup.Get();
        InvoicePostingBuffer.UpdateEntryDescription(
            SalesSetup."Copy Line Descr. to G/L Entry",
            SalesLine."Line No.",
            SalesLine.Description,
            SalesLine.GetSalesHeader()."Posting Description");
    end;

    local procedure UpdateInvoicePostingBuffer(InvoicePostingBuffer: Record "Invoice Posting Buffer"; ForceGLAccountType: Boolean)
    var
        RestoreFAType: Boolean;
    begin
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostingBuffer."Fixed Asset Line No." := FALineNo;
            if ForceGLAccountType then begin
                RestoreFAType := true;
                InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
            end;
        end;

        TempInvoicePostingBuffer.Update(InvoicePostingBuffer, InvDefLineNo, DeferralLineNo);

        if RestoreFAType then
            TempInvoicePostingBuffer.Type := TempInvoicePostingBuffer.Type::"Fixed Asset";
    end;

    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
        JobSalesLine: Record "Sales Line";
        GLEntryNo: Integer;
        LineCount: Integer;
    begin
        SalesHeader := DocumentHeaderVar;

        SalesPostInvoiceEvents.RunOnBeforePostLines(SalesHeader, TempInvoicePostingBuffer);

        LineCount := 0;
        if TempInvoicePostingBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed() and not HideProgressWindow then
                    Window.Update(3, LineCount);

                TempInvoicePostingBuffer.ApplyRoundingForFinalPosting();
                PrepareGenJnlLine(SalesHeader, TempInvoicePostingBuffer, GenJnlLine);

                SalesPostInvoiceEvents.RunOnPostLinesOnBeforeGenJnlLinePost(
                    GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
                GLEntryNo := RunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
                SalesPostInvoiceEvents.RunOnPostLinesOnAfterGenJnlLinePost(
                    GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);

                if (TempInvoicePostingBuffer."Job No." <> '') and
                   (TempInvoicePostingBuffer.Type = TempInvoicePostingBuffer.Type::"G/L Account")
                then begin
                    SetJobLineFilters(JobSalesLine, TempInvoicePostingBuffer);
                    JobPostLine.PostJobSalesLines(JobSalesLine.GetView(), GLEntryNo);
                    SalesPostInvoiceEvents.RunOnPostLinesOnAfterPostJobSalesLines(
                      SalesHeader, TempInvoicePostingBuffer, TotalSalesLine, TotalSalesLineLCY, GLEntryNo, InvoicePostingParameters);
                end;

                InsertGST(SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine.GetVATEntryNo());
            until TempInvoicePostingBuffer.Next(-1) = 0;

        TempInvoicePostingBuffer.CalcSums(Amount);
        TotalAmount := -TempInvoicePostingBuffer.Amount;

        SalesPostInvoiceEvents.RunOnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(
            SalesHeader, GenJnlPostLine, TotalSalesLine, TotalSalesLineLCY, InvoicePostingParameters);
        TempInvoicePostingBuffer.DeleteAll();
    end;

    local procedure PrepareGenJnlLine(var SalesHeader: Record "Sales Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        InitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine.CopyFromSalesHeader(SalesHeader);
        GenJnlLine.Adjustment := SalesHeader.Adjustment;
        GenJnlLine."BAS Adjustment" := SalesHeader."BAS Adjustment";
        GenJnlLine."Adjustment Applies-to" := SalesHeader."Adjustment Applies-to";

        InvoicePostingBuffer.CopyToGenJnlLine(GenJnlLine);
        GenJnlLine."VAT Base (ACY)" := InvoicePostingBuffer."VAT Base (ACY)";
        GenJnlLine."VAT Amount (ACY)" := InvoicePostingBuffer."VAT Amount(ACY)";
        GenJnlLine."VAT Difference (ACY)" := InvoicePostingBuffer."VAT Difference (ACY)";
        GenJnlLine."Amount Including VAT (ACY)" := InvoicePostingBuffer."Amount Including VAT (ACY)";
        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := InvoicePostingBuffer."Journal Templ. Name";
        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalSalesLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                SalesHeader.GetUseDate(), SalesHeader."Currency Code", TotalSalesLine."Pmt. Discount Amount", SalesHeader."Currency Factor");
        SalesPostInvoiceEvents.RunOnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);

        if InvoicePostingBuffer.Type <> InvoicePostingBuffer.Type::"Prepmt. Exch. Rate Difference" then
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Disposal;
            InvoicePostingBuffer.CopyToGenJnlLineFA(GenJnlLine);
        end;

        SalesPostInvoiceEvents.RunOnAfterPrepareGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeInitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", InvoicePostingBuffer."Entry Description",
            InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code",
            InvoicePostingBuffer."Dimension Set ID", SalesHeader."Reason Code");
    end;

    procedure PrepareJobLine(SalesHeaderVar: Variant; SalesLineVar: Variant; SalesLineACYVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineACY: Record "Sales Line";
    begin
        SalesHeader := SalesHeaderVar;
        SalesLine := SalesLineVar;
        SalesLineACY := SalesLineACYVar;

        JobPostLine.PostInvoiceContractLine(SalesHeader, SalesLine);
    end;

    local procedure SetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        JobSalesLine.Reset();
        JobSalesLine.SetRange("Job No.", InvoicePostingBuffer."Job No.");
        JobSalesLine.SetRange("No.", InvoicePostingBuffer."G/L Account");
        JobSalesLine.SetRange("Gen. Bus. Posting Group", InvoicePostingBuffer."Gen. Bus. Posting Group");
        JobSalesLine.SetRange("Gen. Prod. Posting Group", InvoicePostingBuffer."Gen. Prod. Posting Group");
        JobSalesLine.SetRange("VAT Bus. Posting Group", InvoicePostingBuffer."VAT Bus. Posting Group");
        JobSalesLine.SetRange("VAT Prod. Posting Group", InvoicePostingBuffer."VAT Prod. Posting Group");
        JobSalesLine.SetRange("Dimension Set ID", InvoicePostingBuffer."Dimension Set ID");

        if InvoicePostingBuffer."Fixed Asset Line No." <> 0 then begin
            SalesSetup.Get();
            if SalesSetup."Copy Line Descr. to G/L Entry" then
                JobSalesLine.SetRange("Line No.", InvoicePostingBuffer."Fixed Asset Line No.");
        end;

        SalesPostInvoiceEvents.RunOnAfterSetJobLineFilters(JobSalesLine, InvoicePostingBuffer);
    end;

    procedure CheckCreditLine(SalesHeaderVar: Variant; SalesLineVar: Variant)
    begin
    end;

    procedure InsertGST(SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; VATEntryNo: Integer)
    var
        GSTSalesEntry: Record "GST Sales Entry";
        SalesLine3: Record "Sales Line";
        SalesInvLine3: Record "Sales Invoice Line";
        SalesCrMemoLine3: Record "Sales Cr.Memo Line";
        EntryNo: Integer;
    begin
        if not GLSetup."GST Report" then
            exit;
        if VATEntryNo = 0 then
            exit;
        if GSTSalesEntry.FindLast() then
            EntryNo := GSTSalesEntry."Entry No." + 1
        else
            EntryNo := 1;

        TempInvoicePostingBufferGST.Reset();
        if InvoicePostingBuffer."Fixed Asset Line No." <> 0 then
            TempInvoicePostingBufferGST.SetRange("Fixed Asset Line No.", InvoicePostingBuffer."Fixed Asset Line No.");
        TempInvoicePostingBufferGST.SetRange(Type, InvoicePostingBuffer.Type);
        TempInvoicePostingBufferGST.SetRange("G/L Account", InvoicePostingBuffer."G/L Account");
        TempInvoicePostingBufferGST.SetRange("Gen. Bus. Posting Group", InvoicePostingBuffer."Gen. Bus. Posting Group");
        TempInvoicePostingBufferGST.SetRange("Gen. Prod. Posting Group", InvoicePostingBuffer."Gen. Prod. Posting Group");
        TempInvoicePostingBufferGST.SetRange("VAT Bus. Posting Group", InvoicePostingBuffer."VAT Bus. Posting Group");
        TempInvoicePostingBufferGST.SetRange("VAT Prod. Posting Group", InvoicePostingBuffer."VAT Prod. Posting Group");
        TempInvoicePostingBufferGST.SetRange("Tax Area Code", InvoicePostingBuffer."Tax Area Code");
        TempInvoicePostingBufferGST.SetRange("Tax Group Code", InvoicePostingBuffer."Tax Group Code");
        TempInvoicePostingBufferGST.SetRange("Tax Liable", InvoicePostingBuffer."Tax Liable");
        TempInvoicePostingBufferGST.SetRange("Use Tax", InvoicePostingBuffer."Use Tax");
        TempInvoicePostingBufferGST.SetRange("Dimension Set ID", InvoicePostingBuffer."Dimension Set ID");
        TempInvoicePostingBufferGST.SetRange("Job No.", InvoicePostingBuffer."Job No.");
        TempInvoicePostingBufferGST.SetRange("Deferral Code", InvoicePostingBuffer."Deferral Code");
        if TempInvoicePostingBufferGST.FindSet() then
            repeat
                GSTSalesEntry.Init();
                GSTSalesEntry."Entry No." := EntryNo;
                GSTSalesEntry."GST Entry No." := VATEntryNo;
                GSTSalesEntry."Posting Date" := SalesHeader."Posting Date";
                case SalesHeader."Document Type" of
                    SalesHeader."Document Type"::Order,
                    SalesHeader."Document Type"::Invoice:
                        begin
                            GSTSalesEntry."Document Type" := GSTSalesEntry."Document Type"::Invoice;
                            GSTSalesEntry."Document No." := InvoicePostingParameters."Document No.";
                            if SalesLine3.Get(SalesHeader."Document Type", SalesHeader."No.", TempInvoicePostingBufferGST."Fixed Asset Line No.") then begin
                                GSTSalesEntry."Document Line Code" := SalesLine3."No.";
                                GSTSalesEntry."Document Line Description" := SalesLine3.Description;
                            end else
                                if SalesInvLine3.Get(InvoicePostingParameters."Document No.", TempInvoicePostingBufferGST."Fixed Asset Line No.") then begin
                                    GSTSalesEntry."Document Line Code" := SalesInvLine3."No.";
                                    GSTSalesEntry."Document Line Description" := SalesInvLine3.Description;
                                end;
                        end;
                    SalesHeader."Document Type"::"Return Order",
                    SalesHeader."Document Type"::"Credit Memo":
                        begin
                            GSTSalesEntry."Document Type" := GSTSalesEntry."Document Type"::"Credit Memo";
                            GSTSalesEntry."Document No." := InvoicePostingParameters."Document No.";
                            if SalesLine3.Get(SalesHeader."Document Type", SalesHeader."No.", TempInvoicePostingBufferGST."Fixed Asset Line No.") then begin
                                GSTSalesEntry."Document Line Code" := SalesLine3."No.";
                                GSTSalesEntry."Document Line Description" := SalesLine3.Description;
                            end else
                                if SalesCrMemoLine3.Get(InvoicePostingParameters."Document No.", TempInvoicePostingBufferGST."Fixed Asset Line No.") then begin
                                    GSTSalesEntry."Document Line Code" := SalesCrMemoLine3."No.";
                                    GSTSalesEntry."Document Line Description" := SalesCrMemoLine3.Description;
                                end;
                        end;
                end;
                GSTSalesEntry."Document Line No." := TempInvoicePostingBufferGST."Fixed Asset Line No.";
                GSTSalesEntry."Document Line Type" := TempInvoicePostingBufferGST.Type;
                GSTSalesEntry."Customer No." := SalesHeader."Sell-to Customer No.";
                GSTSalesEntry."Customer Name" := SalesHeader."Sell-to Customer Name";
                GSTSalesEntry."GST Entry Type" := GSTSalesEntry."GST Entry Type"::Sale;
                GSTSalesEntry."GST Base" := TempInvoicePostingBufferGST."VAT Base Amount";
                GSTSalesEntry.Amount := TempInvoicePostingBufferGST."VAT Amount";
                GSTSalesEntry."VAT Calculation Type" := TempInvoicePostingBufferGST."VAT Calculation Type";
                GSTSalesEntry."VAT Bus. Posting Group" := TempInvoicePostingBufferGST."VAT Bus. Posting Group";
                GSTSalesEntry."VAT Prod. Posting Group" := TempInvoicePostingBufferGST."VAT Prod. Posting Group";
                GSTSalesEntry.Insert();
                EntryNo += 1;
            until TempInvoicePostingBufferGST.Next() = 0;
    end;

    local procedure PrepareLineGST(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
    begin
        if not GLSetup."GST Report" then
            exit;

        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        Clear(InvoicePostingBuffer);
        if SalesLine."Qty. to Invoice" <> 0 then begin
            InvoicePostingBuffer.Type := SalesLine.Type;
            InvoicePostingBuffer."Fixed Asset Line No." := SalesLine."Line No.";
            if (SalesLine.Type = SalesLine.Type::"G/L Account") or (SalesLine.Type = SalesLine.Type::"Fixed Asset") then begin
                InvoicePostingBuffer."Entry Description" := SalesLine.Description;
                InvoicePostingBuffer."G/L Account" := SalesLine."No.";
            end else begin
                if SalesLine."Document Type" in [SalesLine."Document Type"::"Return Order", SalesLine."Document Type"::"Credit Memo"] then begin
                    GenPostingSetup.TestField("Sales Credit Memo Account");
                    InvoicePostingBuffer."G/L Account" := GenPostingSetup."Sales Credit Memo Account";
                end else begin
                    GenPostingSetup.TestField("Sales Account");
                    InvoicePostingBuffer."G/L Account" := GenPostingSetup."Sales Account";
                end;
                InvoicePostingBuffer."Entry Description" := SalesHeader."Posting Description";
            end;
            InvoicePostingBuffer."System-Created Entry" := true;
            InvoicePostingBuffer."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
            InvoicePostingBuffer."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
            InvoicePostingBuffer."VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
            InvoicePostingBuffer."VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
            InvoicePostingBuffer."VAT Calculation Type" := SalesLine."VAT Calculation Type";
            InvoicePostingBuffer."Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
            InvoicePostingBuffer."Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
            InvoicePostingBuffer."Job No." := SalesLine."Job No.";
            InvoicePostingBuffer.Amount := SalesLine.Amount;
            InvoicePostingBuffer."VAT Base Amount" := SalesLine.Amount;
            if SalesLine."Prepayment Line" and (SalesLine."Prepayment %" <> 100) then begin
                InvoicePostingBuffer.Amount := Round(SalesLine."Line Amount", Currency."Amount Rounding Precision");
                InvoicePostingBuffer."VAT Base Amount" := Round(SalesLine."VAT Base Amount", Currency."Amount Rounding Precision");
            end;
            InvoicePostingBuffer."Amount (ACY)" := SalesLineACY.Amount;
            InvoicePostingBuffer."VAT Base Amount (ACY)" := SalesLineACY.Amount;
            InvoicePostingBuffer."VAT Amount (ACY)" := SalesLineACY."Amount Including VAT" - SalesLineACY.Amount;
            InvoicePostingBuffer."VAT Difference" := SalesLine."VAT Difference";
            InvoicePostingBuffer."VAT Base (ACY)" := SalesLine."VAT Base (ACY)";
            InvoicePostingBuffer."VAT Difference (ACY)" := SalesLine."VAT Difference (ACY)";
            InvoicePostingBuffer."Amount Including VAT (ACY)" := SalesLine."Amount Including VAT (ACY)";
            InvoicePostingBuffer."VAT %" := SalesLine."VAT %";
            InvoicePostingBuffer.Adjustment := SalesHeader.Adjustment;
            InvoicePostingBuffer."Deferral Code" := SalesLine."Deferral Code";
            InvoicePostingBuffer."BAS Adjustment" := SalesHeader."BAS Adjustment";
            InvoicePostingBuffer."Adjustment Applies-to" := SalesHeader."Adjustment Applies-to";
            if SalesLine.Type = SalesLine.Type::"Fixed Asset" then begin
                InvoicePostingBuffer."FA Posting Date" := SalesLine."FA Posting Date";
                InvoicePostingBuffer."Depreciation Book Code" := SalesLine."Depreciation Book Code";
                InvoicePostingBuffer."Depr. until FA Posting Date" := SalesLine."Depr. until FA Posting Date";
                InvoicePostingBuffer."Duplicate in Depreciation Book" := SalesLine."Duplicate in Depreciation Book";
                InvoicePostingBuffer."Use Duplication List" := SalesLine."Use Duplication List";
            end;

            if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then begin
                InvoicePostingBuffer."Tax Area Code" := SalesLine."Tax Area Code";
                InvoicePostingBuffer."Tax Group Code" := SalesLine."Tax Group Code";
                InvoicePostingBuffer."Tax Liable" := SalesLine."Tax Liable";
                InvoicePostingBuffer."Use Tax" := false;
                InvoicePostingBuffer.Quantity := SalesLine."Qty. to Invoice (Base)";
            end;

            case SalesLine."VAT Calculation Type" of
                SalesLine."VAT Calculation Type"::"Normal VAT", SalesLine."VAT Calculation Type"::"Full VAT":
                    if GLSetup.CheckFullGSTonPrepayment(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") and
                       SalesHeader."Prices Including VAT" and (SalesLine."Prepayment %" <> 0) and not SalesLine."Prepayment Line"
                    then begin
                        if SalesLine."Amount Including VAT" < SalesLine.Amount then begin
                            InvoicePostingBuffer."VAT Amount" :=
                              Round(SalesLine."Amount Including VAT" - InvoicePostingBuffer."VAT Base Amount", Currency."Amount Rounding Precision");
                            InvoicePostingBuffer."VAT Amount" := InvoicePostingBuffer."VAT Amount" -
                              (InvoicePostingBuffer."VAT Amount" * (SalesHeader."VAT Base Discount %" / 100));
                            InvoicePostingBuffer."VAT Amount (ACY)" :=
                              -Round(InvoicePostingBuffer."VAT Base Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
                            InvoicePostingBuffer."VAT Amount(ACY)" :=
                              -Round(InvoicePostingBuffer."VAT Base Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
                        end;
                        if SalesLine."Amount Including VAT" > SalesLine.Amount then begin
                            InvoicePostingBuffer."VAT Amount" :=
                              Round(SalesLine."Amount Including VAT" - InvoicePostingBuffer."VAT Base Amount", Currency."Amount Rounding Precision");
                            InvoicePostingBuffer."VAT Amount" := InvoicePostingBuffer."VAT Amount" -
                              (InvoicePostingBuffer."VAT Amount" * (SalesHeader."VAT Base Discount %" / 100));
                            InvoicePostingBuffer."VAT Amount (ACY)" :=
                              Round(InvoicePostingBuffer."VAT Base Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
                            InvoicePostingBuffer."VAT Amount(ACY)" :=
                              Round(InvoicePostingBuffer."VAT Base Amount" * SalesLine."VAT %" / 100, Currency."Amount Rounding Precision");
                        end;
                    end else begin
                        InvoicePostingBuffer."VAT Amount" :=
                          Round(SalesLine."Amount Including VAT" - SalesLine.Amount, Currency."Amount Rounding Precision");
                        InvoicePostingBuffer."VAT Amount (ACY)" := SalesLineACY."Amount Including VAT" - SalesLineACY.Amount;
                    end;
            end;

            case SalesSetup."Discount Posting" of
                SalesSetup."Discount Posting"::"Invoice Discounts":
                    begin
                        InvoicePostingBuffer.Amount += SalesLine."Inv. Discount Amount";
                        InvoicePostingBuffer."Amount (ACY)" += SalesLineACY."Inv. Discount Amount";
                        if (SalesLine."Inv. Discount Amount" <> 0) or (SalesLineACY."Inv. Discount Amount" <> 0) then
                            GenPostingSetup.TestField("Sales Inv. Disc. Account");
                    end;
                SalesSetup."Discount Posting"::"Line Discounts":
                    begin
                        InvoicePostingBuffer.Amount += SalesLine."Line Discount Amount";
                        InvoicePostingBuffer."Amount (ACY)" += SalesLineACY."Line Discount Amount";
                        if (SalesLine."Line Discount Amount" <> 0) or (SalesLineACY."Line Discount Amount" <> 0) then
                            GenPostingSetup.TestField("Sales Line Disc. Account");
                    end;
                SalesSetup."Discount Posting"::"All Discounts":
                    begin
                        InvoicePostingBuffer.Amount += SalesLine."Line Discount Amount" + SalesLine."Inv. Discount Amount";
                        InvoicePostingBuffer."Amount (ACY)" += SalesLineACY."Line Discount Amount" + SalesLineACY."Inv. Discount Amount";
                        if (SalesLine."Line Discount Amount" <> 0) or (SalesLineACY."Line Discount Amount" <> 0) then
                            GenPostingSetup.TestField("Sales Line Disc. Account");
                        if (SalesLine."Inv. Discount Amount" <> 0) or (SalesLineACY."Inv. Discount Amount" <> 0) then
                            GenPostingSetup.TestField("Sales Inv. Disc. Account");
                    end;
            end;
            UpdateInvoicePostingBufferGST(SalesLine, InvoicePostingBuffer);
        end;
    end;

    local procedure UpdateInvoicePostingBufferGST(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        if not GLSetup."GST Report" then
            exit;

        InvoicePostingBuffer."Dimension Set ID" := SalesLine."Dimension Set ID";

        DimMgt.UpdateGlobalDimFromDimSetID(InvoicePostingBuffer."Dimension Set ID",
          InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code");

        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then
            InvoicePostingBuffer."Fixed Asset Line No." := FALineNo;

        TempInvoicePostingBufferGST.Update(InvoicePostingBuffer);
    end;

    procedure PostLedgerEntry(SalesHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        SalesHeader := SalesHeaderVar;

        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforePostLedgerEntry(
            SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, InvoicePostingParameters, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", SalesHeader."Posting Description",
            SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
            SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := SalesHeader."Bill-to Customer No.";
        GenJnlLine.CopyFromSalesHeader(SalesHeader);
        GenJnlLine.SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");
        GenJnlLine."WHT Business Posting Group" := SalesHeader."WHT Business Posting Group";

        GenJnlLine."System-Created Entry" := true;

        GenJnlLine.CopyFromSalesHeaderApplyTo(SalesHeader);
        GenJnlLine.CopyFromSalesHeaderPayment(SalesHeader);
        GenJnlLine.Adjustment := SalesHeader.Adjustment;
        GenJnlLine."BAS Adjustment" := SalesHeader."BAS Adjustment";
        GenJnlLine."Adjustment Applies-to" := SalesHeader."Adjustment Applies-to";

        InitGenJnlLineAmountFieldsFromTotalSalesLine(GenJnlLine, SalesHeader);

        SalesPostInvoiceEvents.RunOnPostLedgerEntryOnBeforeGenJnlPostLine(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        SalesPostInvoiceEvents.RunOnPostLedgerEntryOnAfterGenJnlPostLine(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    local procedure InitGenJnlLineAmountFieldsFromTotalSalesLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeInitGenJnlLineAmountFieldsFromTotalLines(
            GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Amount := -TotalSalesLine."Amount Including VAT" + SalesHeader."WHT Amount";
        GenJnlLine."Source Currency Amount" := -TotalSalesLine."Amount Including VAT" + SalesHeader."WHT Amount";
        if (SalesHeader."WHT Amount" <> 0) and (SalesHeader."Currency Code" <> '') then
            GenJnlLine."Amount (LCY)" :=
              -(TotalSalesLineLCY."Amount Including VAT" -
                Round(
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    SalesHeader."Posting Date", SalesHeader."Currency Code", SalesHeader."WHT Amount", SalesHeader."Currency Factor")))
        else
            GenJnlLine."Amount (LCY)" := -(TotalSalesLineLCY."Amount Including VAT" - SalesHeader."WHT Amount");
        GenJnlLine."Sales/Purch. (LCY)" := -TotalSalesLineLCY.Amount;
        GenJnlLine."Profit (LCY)" := -(TotalSalesLineLCY.Amount - TotalSalesLineLCY."Unit Cost (LCY)");
        GenJnlLine."Inv. Discount (LCY)" := -TotalSalesLineLCY."Inv. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible" := -TotalSalesLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                SalesHeader.GetUseDate(), SalesHeader."Currency Code", -TotalSalesLine."Pmt. Discount Amount", SalesHeader."Currency Factor");
    end;

    procedure PostBalancingEntry(SalesHeaderVariant: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        EntryFound: Boolean;
        IsHandled: Boolean;
    begin
        SalesHeader := SalesHeaderVariant;

        EntryFound := false;
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnBeforeFindCustLedgEntry(
           SalesHeader, TotalSalesLine, InvoicePostingParameters, CustLedgerEntry2, EntryFound, IsHandled);
        if IsHandled then
            exit;

        if not EntryFound then
            FindCustLedgEntry(CustLedgerEntry2);

        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnAfterFindCustLedgEntry(CustLedgerEntry2);

        GenJournalLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", SalesHeader."Posting Description",
            SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
            SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnAfterInitNewLine(SalesHeader, GenJournalLine);

        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Sales);
        if GenJnlTemplate.FindFirst() then begin
            GenJournalLine.Validate("Journal Template Name", GenJnlTemplate.Name);
            GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
            if GenJnlBatch.FindFirst() then
                GenJournalLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        end;
        GenJournalLine."WHT Business Posting Group" := SalesHeader."WHT Business Posting Group";

        GenJournalLine.CopyDocumentFields(
            GenJournalLine."Document Type"::" ", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := SalesHeader."Bill-to Customer No.";
        GenJournalLine.CopyFromSalesHeader(SalesHeader);
        GenJournalLine.SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");

        if SalesHeader.IsCreditDocType() then
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Refund
        else
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;

        SetApplyToDocNo(SalesHeader, GenJournalLine);

        SetAmountsForBalancingEntry(SalesHeader, CustLedgerEntry2, GenJournalLine);
        GenJournalLine.Adjustment := SalesHeader.Adjustment;
        GenJournalLine."BAS Adjustment" := SalesHeader."BAS Adjustment";
        GenJournalLine."Adjustment Applies-to" := SalesHeader."Adjustment Applies-to";

        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnBeforeGenJnlPostLine(
            GenJournalLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJournalLine);
        SalesPostInvoiceEvents.RunOnPostBalancingEntryOnAfterGenJnlPostLine(
            GenJournalLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    local procedure SetAmountsForBalancingEntry(SalesHeader: Record "Sales Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeSetAmountsForBalancingEntry(CustLedgerEntry, GenJnlLine, TotalSalesLine, TotalSalesLineLCY, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Amount := TotalSalesLine."Amount Including VAT" + CustLedgerEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        CustLedgerEntry.CalcFields(Amount);
        if CustLedgerEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalSalesLineLCY."Amount Including VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalSalesLineLCY."Amount Including VAT" +
              Round(CustLedgerEntry."Remaining Pmt. Disc. Possible" / CustLedgerEntry."Adjusted Currency Factor");
        GenJnlLine."Allow Zero-Amount Posting" := true;

        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalSalesLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
            CurrExchRate.ExchangeAmtFCYToLCY(
                SalesHeader.GetUseDate(), SalesHeader."Currency Code", TotalSalesLine."Pmt. Discount Amount", SalesHeader."Currency Factor");
    end;

    local procedure SetApplyToDocNo(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        if SalesHeader."Bal. Account Type" = SalesHeader."Bal. Account Type"::"Bank Account" then
            GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := SalesHeader."Bal. Account No.";
        GenJournalLine."Applies-to Doc. Type" := InvoicePostingParameters."Document Type";
        GenJournalLine."Applies-to Doc. No." := InvoicePostingParameters."Document No.";

        SalesPostInvoiceEvents.RunOnAfterSetApplyToDocNo(GenJournalLine, SalesHeader);
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange("Document Type", InvoicePostingParameters."Document Type");
        CustLedgEntry.SetRange("Document No.", InvoicePostingParameters."Document No.");
        CustLedgEntry.FindLast();
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"): Integer
    begin
        SalesPostInvoiceEvents.RunOnBeforeRunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure GetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20])
    var
        DeferralTemplate: Record "Deferral Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SalesPostInvoiceEvents.RunOnBeforeGetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount, IsHandled);
        if IsHandled then
            exit;

        DeferralTemplate.Get(SalesLine."Deferral Code");
        DeferralTemplate.TestField("Deferral Account");
        DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
            Enum::"Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            AmtToDeferACY := TempDeferralHeader."Amount to Defer";
            AmtToDefer := TempDeferralHeader."Amount to Defer (LCY)";
        end;

        if not SalesLine.IsCreditDocType() then begin
            AmtToDefer := -AmtToDefer;
            AmtToDeferACY := -AmtToDeferACY;
        end;
    end;

    local procedure PrepareDeferralLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; SalesAccount: Code[20]; DiscountAmount: Decimal; DiscountAmountACY: Decimal)
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralPostingBuffer: Record "Deferral Posting Buffer";
        IsDeferralAmountCheck: Boolean;
    begin
        DeferralTemplate.Get(SalesLine."Deferral Code");

        if TempDeferralHeader.Get(
            Enum::"Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            if TempDeferralHeader."Amount to Defer" <> 0 then begin
                DeferralUtilities.FilterDeferralLines(
                  TempDeferralLine, Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
                  SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

                DeferralPostingBuffer.PrepareSales(SalesLine, InvoicePostingParameters."Document No.");
                DeferralPostingBuffer."Posting Date" := SalesHeader."Posting Date";
                DeferralPostingBuffer.Description := SalesHeader."Posting Description";
                DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                SalesPostInvoiceEvents.RunOnPrepareDeferralLineOnBeforePrepareInitialAmounts(
                    DeferralPostingBuffer, SalesHeader, SalesLine, AmountLCY, AmountACY,
                    RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, SalesAccount);
                DeferralPostingBuffer.PrepareInitialAmounts(
                  AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, SalesAccount, DeferralAccount, DiscountAmount, DiscountAmountACY);
                DeferralPostingBuffer.Update(DeferralPostingBuffer);
                if (RemainAmtToDefer <> 0) or (RemainAmtToDeferACY <> 0) then begin
                    DeferralPostingBuffer.PrepareRemainderSales(
                      SalesLine, RemainAmtToDefer, RemainAmtToDeferACY, SalesAccount, DeferralAccount, InvDefLineNo);
                    DeferralPostingBuffer.Update(DeferralPostingBuffer);
                end;

                if TempDeferralLine.FindSet() then
                    repeat
                        if (TempDeferralLine."Amount (LCY)" <> 0) or (TempDeferralLine.Amount <> 0) then begin
                            if not IsDeferralAmountCheck then begin
                                CheckDeferralAmount(TempDeferralLine);
                                IsDeferralAmountCheck := true;
                            end;

                            DeferralPostingBuffer.PrepareSales(SalesLine, InvoicePostingParameters."Document No.");
                            DeferralPostingBuffer.InitFromDeferralLine(TempDeferralLine);
                            if not SalesLine.IsCreditDocType() then
                                DeferralPostingBuffer.ReverseAmounts();
                            DeferralPostingBuffer."G/L Account" := SalesAccount;
                            DeferralPostingBuffer."Deferral Account" := DeferralAccount;
                            DeferralPostingBuffer."Period Description" := DeferralTemplate."Period Description";
                            DeferralPostingBuffer."Deferral Line No." := InvDefLineNo;
                            SalesPostInvoiceEvents.RunOnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate(DeferralPostingBuffer, TempDeferralLine, RemainAmtToDefer);
                            DeferralPostingBuffer.Update(DeferralPostingBuffer);
                        end else
                            Error(ZeroDeferralAmtErr, SalesLine."No.", SalesLine."Deferral Code");

                    until TempDeferralLine.Next() = 0

                else
                    Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code");
            end else
                Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code")
        end else
            Error(NoDeferralScheduleErr, SalesLine."No.", SalesLine."Deferral Code");
        SalesPostInvoiceEvents.RunOnAfterPrepareDeferralLine(DeferralPostingBuffer, SalesHeader, SalesLine, InvoicePostingParameters."Document No.", DeferralAccount, SalesAccount, InvDefLineNo, DeferralLineNo, RemainAmtToDefer);
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

    procedure CalcDeferralAmounts(SalesHeaderVar: Variant; SalesLineVar: Variant; OriginalDeferralAmount: Decimal)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalDeferralCount: Integer;
        DeferralCount: Integer;
    begin
        SalesHeader := SalesHeaderVar;
        SalesLine := SalesLineVar;

        if DeferralHeader.Get(
             Enum::"Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            Currency.Initialize(SalesHeader."Currency Code", true);
            TempDeferralHeader := DeferralHeader;
            if SalesLine.Quantity <> SalesLine."Qty. to Invoice" then
                TempDeferralHeader."Amount to Defer" :=
                  Round(TempDeferralHeader."Amount to Defer" *
                    SalesLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");
            TempDeferralHeader."Amount to Defer (LCY)" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  SalesHeader.GetUseDate(), SalesHeader."Currency Code",
                  TempDeferralHeader."Amount to Defer", SalesHeader."Currency Factor"));
            SalesPostInvoiceEvents.RunOnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(TempDeferralHeader, DeferralHeader, SalesLine);
            TempDeferralHeader.Insert();

            DeferralUtilities.FilterDeferralLines(
                DeferralLine, DeferralHeader."Deferral Doc. Type".AsInteger(),
                DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
                DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.");
            TotalAmount := 0;
            TotalAmountLCY := 0;
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
                        if SalesLine.Quantity <> SalesLine."Qty. to Invoice" then
                            TempDeferralLine.Amount :=
                                Round(TempDeferralLine.Amount *
                                    SalesLine.GetDeferralAmount() / OriginalDeferralAmount, Currency."Amount Rounding Precision");
                        TempDeferralLine."Amount (LCY)" :=
                            Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  SalesHeader.GetUseDate(), SalesHeader."Currency Code",
                                  TempDeferralLine.Amount, SalesHeader."Currency Factor"));
                        TotalAmount := TotalAmount + TempDeferralLine.Amount;
                        TotalAmountLCY := TotalAmountLCY + TempDeferralLine."Amount (LCY)";
                    end;
                    SalesPostInvoiceEvents.RunOnBeforeTempDeferralLineInsert(
                        TempDeferralLine, DeferralLine, SalesLine, DeferralCount, TotalDeferralCount);
                    TempDeferralLine.Insert();
                until DeferralLine.Next() = 0;
            end;
        end;
    end;

    procedure CreatePostedDeferralSchedule(SalesLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralAccount: Code[20];
        IsHandled: Boolean;
    begin
        SalesLine := SalesLineVar;

        if SalesLine."Deferral Code" = '' then
            exit;

        SalesPostInvoiceEvents.RunOnBeforeCreatePostedDeferralSchedule(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if DeferralTemplate.Get(SalesLine."Deferral Code") then
            DeferralAccount := DeferralTemplate."Deferral Account";

        if TempDeferralHeader.Get(
             Enum::"Deferral Document Type"::Sales, '', '', SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
        then begin
            PostedDeferralHeader.InitFromDeferralHeader(TempDeferralHeader, '', '',
                NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount, SalesLine."Sell-to Customer No.", PostingDate);
            DeferralUtilities.FilterDeferralLines(
                TempDeferralLine, Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
                SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
            if TempDeferralLine.FindSet() then
                repeat
                    PostedDeferralLine.InitFromDeferralLine(
                        TempDeferralLine, '', '', NewDocumentType, NewDocumentNo, NewLineNo, DeferralAccount);
                until TempDeferralLine.Next() = 0;
        end;

        SalesPostInvoiceEvents.RunOnAfterCreatePostedDeferralSchedule(SalesLine, PostedDeferralHeader);
    end;
}