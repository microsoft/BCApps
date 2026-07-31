// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;

codeunit 28010 "WHT Purch. Post Invoice"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPrepareLineOnBeforeSetInvoiceDiscountPosting', '', true, false)]
    local procedure OnPrepareLineOnBeforeSetInvoiceDiscountPosting(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        PrepmtPurchInvHeader: Record "Purch. Inv. Header";
        PrepmtWHTEntry: Record "WHT Entry";
        TotalWHTAmountToBeDeductedLCY: Decimal;
        TotalWHTAmtTobeDeducted: Decimal;
        TotalWHTAmountToBeDeductedACY: Decimal;
    begin
        PrepmtPurchInvHeader.Reset();
        PrepmtPurchInvHeader.SetRange("Prepayment Order No.", PurchLine."Document No.");
        PrepmtPurchInvHeader.SetRange("Prepayment Invoice", true);
        if PrepmtPurchInvHeader.FindSet() then
            repeat
                PrepmtWHTEntry.SetRange("Document Type", PrepmtWHTEntry."Document Type"::Invoice);
                PrepmtWHTEntry.SetRange("Document No.", PrepmtPurchInvHeader."No.");
                PrepmtWHTEntry.SetRange("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
                PrepmtWHTEntry.SetRange("Gen. Prod. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
                if PrepmtWHTEntry.FindSet() then
                    repeat
                        TotalWHTAmountToBeDeductedLCY := TotalWHTAmountToBeDeductedLCY + PrepmtWHTEntry."Unrealized Amount (LCY)";
                        TotalWHTAmtTobeDeducted := TotalWHTAmtTobeDeducted + PrepmtWHTEntry."Unrealized Amount";
                    until PrepmtWHTEntry.Next() = 0;
            until PrepmtPurchInvHeader.Next() = 0;

        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then
            TotalWHTAmountToBeDeductedACY :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                PurchHeader."Posting Date", GLSetup."Additional Reporting Currency",
                TotalWHTAmtTobeDeducted, 0);

        if PurchLine."Prepayment Line" then begin
            TotalAmount := TotalAmount + TotalWHTAmountToBeDeductedLCY;
            TotalAmountACY := TotalAmountACY + TotalWHTAmountToBeDeductedACY;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnAfterPrepareGenJnlLine', '', true, false)]
    local procedure OnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        GenJnlLine."WHT Business Posting Group" := InvoicePostingBuffer."WHT Business Posting Group";
        GenJnlLine."WHT Product Posting Group" := InvoicePostingBuffer."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnAfterPrepareInvoicePostingBuffer', '', true, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        InvoicePostingBuffer."WHT Business Posting Group" := PurchaseLine."WHT Business Posting Group";
        InvoicePostingBuffer."WHT Product Posting Group" := PurchaseLine."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', true, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header")
    begin
        GenJnlLine."WHT Business Posting Group" := PurchHeader."WHT Business Posting Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPostBalancingEntryOnAfterInitNewLine', '', true, false)]
    local procedure OnPostBalancingEntryOnAfterInitNewLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header")
    begin
        GenJnlLine."WHT Business Posting Group" := PurchHeader."WHT Business Posting Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnAfterInitGenJnlLineAmountFieldsFromTotalLines', '', true, false)]
    local procedure OnAfterInitGenJnlLineAmountFieldsFromTotalLines(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GenJnlLine.Amount += PurchHeader."WHT Amount";
        GenJnlLine."Source Currency Amount" += PurchHeader."WHT Amount";
        if (PurchHeader."WHT Amount" <> 0) and (PurchHeader."Currency Code" <> '') then
            GenJnlLine."Amount (LCY)" +=
                Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        PurchHeader."Posting Date", PurchHeader."Currency Code", PurchHeader."WHT Amount", PurchHeader."Currency Factor"))
        else
            GenJnlLine."Amount (LCY)" += PurchHeader."WHT Amount";
    end;

}