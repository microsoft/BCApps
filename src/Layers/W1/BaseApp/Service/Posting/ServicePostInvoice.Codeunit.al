// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using System.Environment.Configuration;

codeunit 817 "Service Post Invoice" implements "Invoice Posting"
{
    var
        SalesSetup: Record "Sales & Receivables Setup";
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
        TotalServiceLine: Record "Service Line";
        TotalServiceLineLCY: Record "Service Line";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ServicePostInvoiceEvents: Codeunit "Service Post Invoice Events";
        FALineNo: Integer;
        HideProgressWindow: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        IncorrectInterfaceErr: Label 'This implementation designed to post Service Header table only.';

    procedure Check(TableID: Integer)
    begin
        if TableID <> Database::"Service Header" then
            error(IncorrectInterfaceErr);
    end;

    procedure ClearBuffers()
    begin
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
        TotalServiceLine := TotalDocumentLine;
        TotalServiceLineLCY := TotalDocumentLineLCY;
    end;

    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineACY: Record "Service Line";
        GenPostingSetup: Record "General Posting Setup";
        InvoicePostingBuffer: Record "Invoice Posting Buffer";
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
        SalesAccountNo: Code[20];
        IsHandled: Boolean;
    begin
        ServiceHeader := DocumentHeaderVar;
        ServiceLine := DocumentLineVar;
        ServiceLineACY := DocumentLineACYVar;

        IsHandled := false;
        ServicePostInvoiceEvents.RunOnBeforePrepareLine(ServiceHeader, ServiceLine, ServiceLineACY, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
            if (ServiceLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
               (ServiceLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
            then begin
                GenPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");
                GenPostingSetup.TestField(Blocked, false);
                ServicePostInvoiceEvents.RunOnPrepareLineAfterGetGenPostingSetup(GenPostingSetup, ServiceHeader, ServiceLine, ServiceLineACY);
            end;

        PrepareInvoicePostingBuffer(ServiceLine, InvoicePostingBuffer);

        TotalVAT := ServiceLine."Amount Including VAT" - ServiceLine.Amount;
        TotalVATACY := ServiceLineACY."Amount Including VAT" - ServiceLineACY.Amount;
        TotalAmount := ServiceLine.Amount;
        TotalAmountACY := ServiceLineACY.Amount;
        TotalVATBase := ServiceLine."VAT Base Amount";
        TotalVATBaseACY := ServiceLineACY."VAT Base Amount";

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            CalcInvoiceDiscountPosting(InvoicePostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader);
            if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostingBuffer.SetAccount(
                  GenPostingSetup.GetSalesInvDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                if ServiceLine."Line Discount %" = 100 then begin
                    InvoicePostingBuffer."VAT Base Amount" := 0;
                    InvoicePostingBuffer."VAT Base Amount (ACY)" := 0;
                    InvoicePostingBuffer."VAT Amount" := 0;
                    InvoicePostingBuffer."VAT Amount (ACY)" := 0;
                end;
                UpdateInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine);
            end;
        end;

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            CalcLineDiscountPosting(InvoicePostingBuffer, ServiceLine, ServiceLineACY, ServiceHeader);
            if (InvoicePostingBuffer.Amount <> 0) or (InvoicePostingBuffer."Amount (ACY)" <> 0) then begin
                InvoicePostingBuffer.SetAccount(
                  GenPostingSetup.GetSalesLineDiscAccount(), TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                ServicePostInvoiceEvents.RunOnPrepareLineOnBeforeUpdateInvoicePostingBufferLineDiscounts(InvoicePostingBuffer, ServiceLine);
                UpdateInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine);
            end;
        end;

        IsHandled := false;
        ServicePostInvoiceEvents.RunOnPrepareLineOnBeforeSetAmounts(
            ServiceLine, ServiceLineACY, InvoicePostingBuffer,
            TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
        if not IsHandled then
            InvoicePostingBuffer.SetAmounts(
              TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, ServiceLine."VAT Difference", TotalVATBase, TotalVATBaseACY);
        ServicePostInvoiceEvents.RunOnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, ServiceLine);

        SalesAccountNo := GetSalesAccount(ServiceLine, GenPostingSetup);
        ServicePostInvoiceEvents.RunOnPrepareLineOnBeforeSetAccount(ServiceHeader, ServiceLine, SalesAccountNo);
        InvoicePostingBuffer.SetAccount(SalesAccountNo, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        InvoicePostingBuffer.UpdateVATBase(TotalVATBase, TotalVATBaseACY);

        ServicePostInvoiceEvents.RunOnPrepareLineOnAfterFillInvoicePostingBuffer(
            InvoicePostingBuffer, ServiceLine, ServiceLineACY, SuppressCommit, TempInvoicePostingBuffer);

        UpdateInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine);
    end;

    local procedure GetSalesAccount(ServiceLine: Record "Service Line"; GenPostingSetup: Record "General Posting Setup") SalesAccountNo: Code[20]
    var
        ServCost: Record "Service Cost";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ServicePostInvoiceEvents.RunOnBeforeGetSalesAccount(ServiceLine, GenPostingSetup, SalesAccountNo, IsHandled);
        if not IsHandled then
            case ServiceLine.Type of
                ServiceLine.Type::"G/L Account":
                    SalesAccountNo := ServiceLine."No.";
                ServiceLine.Type::Cost:
                    begin
                        ServCost.Get(ServiceLine."No.");
                        SalesAccountNo := ServCost."Account No.";
                    end;
                else
                    if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                        SalesAccountNo := GenPostingSetup.GetSalesCrMemoAccount()
                    else
                        SalesAccountNo := GenPostingSetup.GetSalesAccount();
            end;

        ServicePostInvoiceEvents.RunOnAfterGetSalesAccount(ServiceLine, GenPostingSetup, SalesAccountNo);
    end;

    local procedure CalcInvoiceDiscountPosting(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ServicePostInvoiceEvents.RunOnBeforeCalcInvoiceDiscountPosting(ServiceHeader, ServiceLine, ServiceLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
              -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
              ServiceHeader."Prices Including VAT", -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount");
    end;

    local procedure CalcLineDiscountPosting(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ServicePostInvoiceEvents.RunOnBeforeCalcLineDiscountPosting(ServiceHeader, ServiceLine, ServiceLineACY, InvoicePostingBuffer, IsHandled);
        if IsHandled then
            exit;

        if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
            InvoicePostingBuffer.CalcDiscountNoVAT(
              -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount")
        else
            InvoicePostingBuffer.CalcDiscount(
              ServiceHeader."Prices Including VAT", -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount");
    end;

    procedure PrepareInvoicePostingBuffer(var ServiceLine: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        ServicePostInvoiceEvents.RunOnBeforePrepareInvoicePostingBuffer(ServiceLine, InvoicePostingBuffer);

        Clear(InvoicePostingBuffer);
        case ServiceLine.Type of
            ServiceLine.Type::Item:
                InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::Item;
            ServiceLine.Type::Resource:
                InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::Resource;
            ServiceLine.Type::"G/L Account":
                InvoicePostingBuffer.Type := InvoicePostingBuffer.Type::"G/L Account";
        end;
        InvoicePostingBuffer."System-Created Entry" := true;
        InvoicePostingBuffer."Gen. Bus. Posting Group" := ServiceLine."Gen. Bus. Posting Group";
        InvoicePostingBuffer."Gen. Prod. Posting Group" := ServiceLine."Gen. Prod. Posting Group";
        InvoicePostingBuffer."VAT Bus. Posting Group" := ServiceLine."VAT Bus. Posting Group";
        InvoicePostingBuffer."VAT Prod. Posting Group" := ServiceLine."VAT Prod. Posting Group";
        InvoicePostingBuffer."VAT Calculation Type" := ServiceLine."VAT Calculation Type";
        InvoicePostingBuffer."Global Dimension 1 Code" := ServiceLine."Shortcut Dimension 1 Code";
        InvoicePostingBuffer."Global Dimension 2 Code" := ServiceLine."Shortcut Dimension 2 Code";
        InvoicePostingBuffer."Dimension Set ID" := ServiceLine."Dimension Set ID";
        InvoicePostingBuffer."Job No." := ServiceLine."Job No.";
        InvoicePostingBuffer."VAT %" := ServiceLine.GetVATPct();
        InvoicePostingBuffer."VAT Difference" := ServiceLine."VAT Difference";
        if InvoicePostingBuffer."VAT Calculation Type" = InvoicePostingBuffer."VAT Calculation Type"::"Sales Tax" then begin
            InvoicePostingBuffer."Tax Area Code" := ServiceLine."Tax Area Code";
            InvoicePostingBuffer."Tax Group Code" := ServiceLine."Tax Group Code";
            InvoicePostingBuffer."Tax Liable" := ServiceLine."Tax Liable";
            InvoicePostingBuffer."Use Tax" := false;
            InvoicePostingBuffer.Quantity := ServiceLine."Qty. to Invoice (Base)";
        end;

        UpdateEntryDescriptionFromServiceLine(ServiceLine, InvoicePostingBuffer);

#if not CLEAN25
        InvoicePostingBuffer.RunOnAfterPrepareService(ServiceLine, InvoicePostingBuffer);
#endif
        ServicePostInvoiceEvents.RunOnAfterPrepareInvoicePostingBuffer(ServiceLine, InvoicePostingBuffer);
    end;

    local procedure UpdateEntryDescriptionFromServiceLine(ServiceLine: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    var
        ServiceHeader: Record "Service Header";
        ServiceSetup: Record "Service Mgt. Setup";
    begin
        ServiceSetup.Get();
        ServiceHeader.get(ServiceLine."Document Type", ServiceLine."Document No.");
        InvoicePostingBuffer.UpdateEntryDescription(
            ServiceSetup."Copy Line Descr. to G/L Entry",
            ServiceLine."Line No.",
            ServiceLine.Description,
            ServiceHeader."Posting Description");
    end;

    local procedure UpdateInvoicePostingBuffer(InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line")
    begin
        InvoicePostingBuffer."Dimension Set ID" := ServiceLine."Dimension Set ID";
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvoicePostingBuffer."Fixed Asset Line No." := FALineNo;
        end;

        ServicePostInvoiceEvents.RunOnUpdateInvoicePostingBufferOnBeforeUpdate(InvoicePostingBuffer);
        TempInvoicePostingBuffer.Update(InvoicePostingBuffer);
        ServicePostInvoiceEvents.RunOnAfterUpdateInvoicePostingBuffer(InvoicePostingBuffer);
    end;

    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)
    var
        ServiceHeader: Record "Service Header";
        GenJnlLine: Record "Gen. Journal Line";
        GLEntryNo: Integer;
        LineCount: Integer;
    begin
        ServiceHeader := DocumentHeaderVar;

        ServicePostInvoiceEvents.RunOnBeforePostLines(ServiceHeader, TempInvoicePostingBuffer);

        LineCount := 0;
        if TempInvoicePostingBuffer.Find('+') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed and not HideProgressWindow then
                    Window.Update(3, LineCount);

                PrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader, TempInvoicePostingBuffer, GenJnlLine);

                ServicePostInvoiceEvents.RunOnPostLinesOnBeforeGenJnlLinePost(
                    GenJnlLine, ServiceHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
                GLEntryNo := GenJnlPostLine.RunWithCheck(GenJnlLine);
                ServicePostInvoiceEvents.RunOnPostLinesOnAfterGenJnlLinePost(
                    GenJnlLine, ServiceHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);
            until TempInvoicePostingBuffer.Next(-1) = 0;

        TempInvoicePostingBuffer.CalcSums(Amount);
        TotalAmount := TempInvoicePostingBuffer.Amount;
    end;

    local procedure PrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader: Record "Service Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.InitNewLine(
            ServiceHeader."Posting Date", ServiceHeader."Document Date", ServiceHeader."VAT Reporting Date", InvoicePostingBuffer."Entry Description",
            InvoicePostingBuffer."Global Dimension 1 Code", InvoicePostingBuffer."Global Dimension 2 Code",
            InvoicePostingBuffer."Dimension Set ID", ServiceHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        ServiceHeader.CopyToGenJournalLine(GenJnlLine);

        InvoicePostingBuffer.CopyToGenJnlLine(GenJnlLine);
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
        ServicePostInvoiceEvents.RunOnAfterPrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader, InvoicePostingBuffer, GenJnlLine);
    end;

    procedure CheckCreditLine(SalesHeaderVar: Variant; SalesLineVar: Variant)
    begin
    end;

    procedure PostLedgerEntry(ServiceHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        ServiceHeader: Record "Service Header";
        GenJnlLine: Record "Gen. Journal Line";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        ServiceHeader := ServiceHeaderVar;

        GenJnlLine.InitNewLine(
            ServiceHeader."Posting Date", ServiceHeader."Document Date", ServiceHeader."VAT Reporting Date", ServiceHeader."Posting Description",
            ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
            ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(
            InvoicePostingParameters."Document Type", InvoicePostingParameters."Document No.",
            InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := ServiceHeader."Bill-to Customer No.";
        ServiceHeader.CopyToGenJournalLine(GenJnlLine);
        GenJnlLine.SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

        ServiceHeader.CopyToGenJournalLineApplyTo(GenJnlLine);
        ServiceHeader.CopyToGenJournalLinePayment(GenJnlLine);

        GenJnlLine.Amount := -TotalServiceLine."Amount Including VAT";
        GenJnlLine."Source Currency Amount" := -TotalServiceLine."Amount Including VAT";
        GenJnlLine."Amount (LCY)" := -TotalServiceLineLCY."Amount Including VAT";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalServiceLineLCY.Amount;
        GenJnlLine."Profit (LCY)" := -(TotalServiceLineLCY.Amount - TotalServiceLineLCY."Unit Cost (LCY)");
        GenJnlLine."Inv. Discount (LCY)" := -TotalServiceLineLCY."Inv. Discount Amount";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Orig. Pmt. Disc. Possible" := -TotalServiceLine."Pmt. Discount Amount";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            ServiceHeader."Posting Date", ServiceHeader."Currency Code", -TotalServiceLine."Pmt. Discount Amount", ServiceHeader."Currency Factor");

        ServicePostInvoiceEvents.RunOnPostLedgerEntryOnBeforeGenJnlPostLine(
            GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine, InvoicePostingParameters);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        ServicePostInvoiceEvents.RunOnPostLedgerEntryOnAfterGenJnlPostLine(
            GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    procedure PostBalancingEntry(ServiceHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        ServiceHeader := ServiceHeaderVar;

        IsHandled := false;
        ServicePostInvoiceEvents.RunOnPostBalancingEntryOnBeforeFindCustLedgerEntry(ServiceHeader, CustLedgerEntry, IsHandled);
        if not IsHandled then
            FindCustLedgerEntry(CustLedgerEntry);

        GenJnlLine.InitNewLine(
            ServiceHeader."Posting Date", ServiceHeader."Document Date", ServiceHeader."VAT Reporting Date", ServiceHeader."Posting Description",
            ServiceHeader."Shortcut Dimension 1 Code", ServiceHeader."Shortcut Dimension 2 Code",
            ServiceHeader."Dimension Set ID", ServiceHeader."Reason Code");

        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
            GenJnlLine.CopyDocumentFields(
                GenJnlLine."Document Type"::Refund, InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '')
        else
            GenJnlLine.CopyDocumentFields(
                GenJnlLine."Document Type"::Payment, InvoicePostingParameters."Document No.",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Source Code", '');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := ServiceHeader."Bill-to Customer No.";
        ServiceHeader.CopyToGenJournalLine(GenJnlLine);
        GenJnlLine.SetCurrencyFactor(ServiceHeader."Currency Code", ServiceHeader."Currency Factor");

        SetApplyToDocNo(ServiceHeader, GenJnlLine);

        GenJnlLine.Amount := TotalServiceLine."Amount Including VAT" + CustLedgerEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        CustLedgerEntry.CalcFields(Amount);
        if CustLedgerEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalServiceLineLCY."Amount Including VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalServiceLineLCY."Amount Including VAT" +
              Round(CustLedgerEntry."Remaining Pmt. Disc. Possible" / CustLedgerEntry."Adjusted Currency Factor");
        GenJnlLine."Allow Zero-Amount Posting" := true;

        ServicePostInvoiceEvents.RunOnPostBalancingEntryOnBeforeGenJnlPostLine(
            GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        ServicePostInvoiceEvents.RunOnPostBalancingEntryOnAfterGenJnlPostLine(
            GenJnlLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    local procedure SetApplyToDocNo(ServiceHeader: Record "Service Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        if ServiceHeader."Bal. Account Type" = ServiceHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := ServiceHeader."Bal. Account No.";
        GenJnlLine."Applies-to Doc. Type" := InvoicePostingParameters."Document Type";
        GenJnlLine."Applies-to Doc. No." := InvoicePostingParameters."Document No.";
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Document Type", InvoicePostingParameters."Document Type");
        CustLedgerEntry.SetRange("Document No.", InvoicePostingParameters."Document No.");
        CustLedgerEntry.FindLast();
    end;

    procedure PrepareJobLine(SalesHeaderVar: Variant; SalesLineVar: Variant; SalesLineACYVar: Variant)
    begin
    end;

    procedure CalcDeferralAmounts(ServiceHeaderVar: Variant; ServiceLineVar: Variant; OriginalDeferralAmount: Decimal)
    begin
    end;

    procedure CreatePostedDeferralSchedule(ServiceLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    begin
    end;
}
