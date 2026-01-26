// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Reserved codeunit for implementing country-specific exchange rate adjustment logic.
/// Provides a placeholder for localization-specific event subscribers and customizations
/// related to exchange rate adjustment processing.
/// </summary>
/// <remarks>
/// Intended for use by localization partners to implement region-specific requirements
/// for exchange rate adjustments without modifying core adjustment procedures.
/// Event subscribers can be added to handle local compliance and calculation rules.
/// </remarks>
codeunit 597 "Exch. Rate Adjmt. Subscribers"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterAdjustCustomerLedgerEntryOnAfterCalcAdjmtAmount', '', false, false)]
    local procedure OnAfterAdjustCustomerLedgerEntryOnAfterCalcAdjmtAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"; AdjmtAmount: Decimal; Application: Boolean; var ShouldExit: Boolean)
    begin
        case ExchRateAdjmtParameters."Valuation Method" of
            1: // ValuationMethod::"Lowest Value":
                if (AdjmtAmount >= 0) and (not Application) then
                    ShouldExit := true;
            2: // ValuationMethod::"BilMoG (Germany)":
                if not Application then
                    if not CalculateBilMoG(
                        AdjmtAmount, CustLedgerEntry."Remaining Amt. (LCY)",
                        CustCalcRemOrigAmtLCY(CustLedgerEntry, ExchRateAdjmtParameters."Posting Date"),
                        CustLedgerEntry."Due Date", ExchRateAdjmtParameters."Due Date To")
                    then
                        ShouldExit := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterAdjustVendorLedgerEntryOnAfterCalcAdjmtAmount', '', false, false)]
    local procedure OnAfterAdjustVendorLedgerEntryOnAfterCalcAdjmtAmount(VendLedgerEntry: Record "Vendor Ledger Entry"; ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"; AdjmtAmount: Decimal; Application: Boolean; var ShouldExit: Boolean)
    begin
        case ExchRateAdjmtParameters."Valuation Method" of
            1: // ValuationMethod::"Lowest Value":
                if (AdjmtAmount >= 0) and (not Application) then
                    ShouldExit := true;
            2: // ValuationMethod::"BilMoG (Germany)":
                if not Application then
                    if not CalculateBilMoG(
                        AdjmtAmount, VendLedgerEntry."Remaining Amt. (LCY)",
                        VendCalcRemOrigAmtLCY(VendLedgerEntry, ExchRateAdjmtParameters."Posting Date"),
                        VendLedgerEntry."Due Date", ExchRateAdjmtParameters."Due Date To")
                    then
                        ShouldExit := true;
        end;
    end;

    local procedure CalculateBilMoG(var AdjAmt2: Decimal; RemAmtLCY: Decimal; OrigRemAmtLCY: Decimal; DueDate: Date; DueDateTo: Date): Boolean
    begin
        if (DueDateTo < DueDate) or (DueDate = 0D) then begin
            if (RemAmtLCY = OrigRemAmtLCY) and (AdjAmt2 >= 0) then
                exit(false);
            if (AdjAmt2 + RemAmtLCY) > OrigRemAmtLCY then
                AdjAmt2 := OrigRemAmtLCY - RemAmtLCY;
        end;
        exit(true);
    end;

    local procedure CustCalcRemOrigAmtLCY(CustLedgEntry2: Record "Cust. Ledger Entry"; PostingDate: Date): Decimal
    var
        DtldCustEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustEntry2.SetRange("Cust. Ledger Entry No.", CustLedgEntry2."Entry No.");
        DtldCustEntry2.SetRange(
          "Entry Type", DtldCustEntry2."Entry Type"::"Initial Entry", DtldCustEntry2."Entry Type"::Application);
        DtldCustEntry2.SetRange("Posting Date", CustLedgEntry2."Posting Date", PostingDate);
        DtldCustEntry2.CalcSums("Amount (LCY)");
        exit(DtldCustEntry2."Amount (LCY)");
    end;

    local procedure VendCalcRemOrigAmtLCY(VendLedgEntry2: Record "Vendor Ledger Entry"; PostingDate: Date): Decimal
    var
        DtldVendEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DtldVendEntry2.SetRange("Vendor Ledger Entry No.", VendLedgEntry2."Entry No.");
        DtldVendEntry2.SetRange(
          "Entry Type", DtldVendEntry2."Entry Type"::"Initial Entry", DtldVendEntry2."Entry Type"::Application);
        DtldVendEntry2.SetRange("Posting Date", VendLedgEntry2."Posting Date", PostingDate);
        DtldVendEntry2.CalcSums("Amount (LCY)");
        exit(DtldVendEntry2."Amount (LCY)");
    end;
}