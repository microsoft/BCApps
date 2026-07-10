// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 28014 "WHT Gen. Jnl.-Post Batch"
{
    var
        GLSetup: Record "General Ledger Setup";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnPostGenJournalLineOnAfterPrepareGenJnlLineAddCurr', '', true, false)]
    local procedure OnPostGenJournalLineOnAfterPrepareGenJnlLineAddCurr(GenJnlLine5: Record "Gen. Journal Line"; CurrGenJnlLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        GLSetup.Get();
        if GLSetup."Enable WHT" and (not GLSetup."Enable GST (Australia)") and (not GenJnlLine5."Skip WHT") then
            if GenJnlLine5."Applies-to Doc. No." <> '' then begin
                WHTEntry.SetCurrentKey("Document Type", "Document No.");
                WHTEntry.SetRange("Document No.", GenJnlLine5."Applies-to Doc. No.");
                WHTEntry.SetRange("Document Type", GenJnlLine5."Applies-to Doc. Type");
                if WHTEntry.FindFirst() then
                    if WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group") then begin
                        WHTEntry.CalcSums("Unrealized Base (LCY)");
                        CheckWHTCalculationRule(WHTEntry."Unrealized Base (LCY)", WHTPostingSetup, GenJnlLine5);
                    end;
                if GenJnlLine5."Applies-to Doc. Type" = GenJnlLine5."Applies-to Doc. Type"::Invoice then begin
                    PurchInvLine.SetRange("Document No.", GenJnlLine5."Applies-to Doc. No.");
                    if PurchInvLine.FindFirst() then
                        if PurchInvLine."Blanket Order No." <> '' then
                            GenJnlLine5."Skip WHT" := false;
                end;
            end else
                if GenJnlLine5."Applies-to ID" <> '' then
                    case GenJnlLine5."Account Type" of
                        GenJnlLine5."Account Type"::Customer:
                            begin
                                CustLedgEntry.SetRange("Applies-to ID", CurrGenJnlLine."Document No.");
                                CustLedgEntry.SetRange("Customer No.", CurrGenJnlLine."Account No.");
                                if CustLedgEntry.FindFirst() then
                                    CustomerMinWHT(CustLedgEntry, GenJnlLine5);
                            end;
                        GenJnlLine5."Account Type"::Vendor:
                            begin
                                VendLedgEntry.SetRange("Applies-to ID", CurrGenJnlLine."Document No.");
                                VendLedgEntry.SetRange("Vendor No.", CurrGenJnlLine."Account No.");
                                if VendLedgEntry.FindFirst() then
                                    VendorMinWHT(VendLedgEntry, GenJnlLine5);
                            end;
                    end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnAfterCheckIfForceDocumentBalance', '', true, false)]
    local procedure OnAfterCheckIfForceDocumentBalance(var GenJnlLine: Record "Gen. Journal Line"; var Result: Boolean)
    begin
        Result := Result or IsWHTPaymentPosting(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CheckWHTCalculationRule(TotalInvoiceAmountLCY: Decimal; WHTPostingSetup2: Record "WHT Posting Setup"; var GenJnlLine5: Record "Gen. Journal Line")
    begin
        GenJnlLine5."Skip WHT" :=
          not CompareAmounts(TotalInvoiceAmountLCY, WHTPostingSetup2) and
          (CompareAmounts(GenJnlLine5."Amount (LCY)", WHTPostingSetup2) or GLSetup."Min. WHT Calc only on Inv. Amt");
    end;

    [Scope('OnPrem')]
    procedure VendorMinWHT(var VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine5: Record "Gen. Journal Line")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        TotWHT: Decimal;
    begin
        repeat
            WHTEntry.Reset();
            WHTPostingSetup.Reset();
            TotWHT := 0;
            WHTEntry.SetCurrentKey("Document Type", "Document No.");
            WHTEntry.SetRange("Document Type", VendLedgEntry."Document Type");
            WHTEntry.SetRange("Document No.", VendLedgEntry."Document No.");
            if WHTEntry.FindFirst() then begin
                WHTEntry.CalcSums("Unrealized Base (LCY)");
                TotWHT := TotWHT + WHTEntry."Unrealized Base (LCY)";
            end;
            if WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group") then
                CheckWHTCalculationRule(TotWHT, WHTPostingSetup, GenJnlLine5);

            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice then begin
                PurchInvLine.SetRange("Document No.", VendLedgEntry."Applies-to Doc. No.");
                if PurchInvLine.FindFirst() and (PurchInvLine."Blanket Order No." <> '') then
                    GenJnlLine5."Skip WHT" := false;
            end;
        // if (NOT GenJnlLine5."Skip WHT") THEN
        // EXIT;
        until VendLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CustomerMinWHT(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine5: Record "Gen. Journal Line")
    var
        SalesInvLine: Record "Sales Invoice Line";
        TotWHT: Decimal;
    begin
        repeat
            WHTEntry.Reset();
            WHTPostingSetup.Reset();
            TotWHT := 0;
            WHTEntry.SetCurrentKey("Document Type", "Document No.");
            WHTEntry.SetRange("Document Type", CustLedgEntry."Document Type");
            WHTEntry.SetRange("Document No.", CustLedgEntry."Document No.");
            if WHTEntry.FindFirst() then begin
                WHTEntry.CalcSums("Unrealized Base (LCY)");
                TotWHT := TotWHT + WHTEntry."Unrealized Base (LCY)";
            end;
            if WHTPostingSetup.Get(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group") then
                CheckWHTCalculationRule(TotWHT, WHTPostingSetup, GenJnlLine5);

            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice then begin
                SalesInvLine.SetRange("Document No.", CustLedgEntry."Applies-to Doc. No.");
                if SalesInvLine.FindFirst() and (SalesInvLine."Blanket Order No." <> '') then
                    GenJnlLine5."Skip WHT" := false;
            end;
            if not GenJnlLine5."Skip WHT" then
                exit;
        until CustLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CompareAmounts(AmountLCY: Decimal; WHTPostSetup: Record "WHT Posting Setup"): Boolean
    begin
        AmountLCY := Abs(AmountLCY);
        case WHTPostSetup."WHT Calculation Rule" of
            WHTPostSetup."WHT Calculation Rule"::"Less than":
                exit(AmountLCY >= WHTPostSetup."WHT Minimum Invoice Amount");
            WHTPostSetup."WHT Calculation Rule"::"Less than or equal to":
                exit(AmountLCY > WHTPostSetup."WHT Minimum Invoice Amount");
            WHTPostSetup."WHT Calculation Rule"::"Equal to":
                exit(AmountLCY <> WHTPostSetup."WHT Minimum Invoice Amount");
            WHTPostSetup."WHT Calculation Rule"::"Greater than":
                exit(AmountLCY <= WHTPostSetup."WHT Minimum Invoice Amount");
            WHTPostSetup."WHT Calculation Rule"::"Greater than or equal to":
                exit(AmountLCY < WHTPostSetup."WHT Minimum Invoice Amount");
        end;
    end;

    local procedure IsWHTPaymentPosting(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        GenJournalLineWHT: Record "Gen. Journal Line";
    begin
        if not GLSetup."Enable WHT" then
            exit(false);

        GenJournalLineWHT.Copy(GenJournalLine);
        GenJournalLineWHT.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLineWHT.SetRange("Skip WHT", false);
        GenJournalLineWHT.SetFilter("Applies-to Doc. No.", '<>%1', '');
        if GenJournalLineWHT.FindSet() then
            repeat
                if WHTPostingSetup.Get(GenJournalLineWHT."WHT Business Posting Group", GenJournalLineWHT."WHT Product Posting Group") and
                   (WHTPostingSetup."Realized WHT Type" = WHTPostingSetup."Realized WHT Type"::Payment)
                then
                    exit(true);
            until GenJournalLineWHT.Next() = 0;

        exit(false);
    end;
}