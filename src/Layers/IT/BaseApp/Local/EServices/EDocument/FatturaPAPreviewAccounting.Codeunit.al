namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Receivables;

codeunit 12281 "FatturaPA Preview Accounting"
{
    Access = Internal;

    procedure AddVATRows(
        var TempFatturaLine: Record "Fattura Line" temporary;
        var TempVATEntry: Record "VAT Entry" temporary;
        CustomerNo: Code[20];
        IsInvoice: Boolean)
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        AggregatedVATEntries: Record "VAT Entry" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        IsSplitPayment: Boolean;
        VATEntryCount: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange(Type, TempVATEntry.Type::Sale);
        if TempVATEntry.FindSet() then
            repeat
                if not TempVATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group") then begin
                    VATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group");
                    TempVATPostingSetup := VATPostingSetup;
                    TempVATPostingSetup.Insert();
                end;
                if FatturaDocHelper.IsSplitVATSetup(TempVATPostingSetup) then
                    IsSplitPayment := true;
            until TempVATEntry.Next() = 0;

        FatturaDocHelper.AggregateFatturaVATEntries(TempVATEntry, AggregatedVATEntries);
        VATEntryCount := AggregatedVATEntries.Count();
        if AggregatedVATEntries.FindSet() then
            repeat
                // Preserve unrealized VAT metadata for the standard VAT-type logic.
                FatturaDocHelper.InsertPreviewVATFatturaLine(
                    TempFatturaLine, AggregatedVATEntries, CustomerNo,
                    IsInvoice, IsSplitPayment, VATEntryCount);
            until AggregatedVATEntries.Next() = 0;
    end;

    procedure AddPaymentRows(
        var TempFatturaLine: Record "Fattura Line" temporary;
        var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary)
    var
        InitialEntryAmounts: Dictionary of [Integer, Decimal];
        Amount: Decimal;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // Aggregate the initial detailed entries once; a separate scan for each
        // customer ledger entry repeats work for multi-installment documents.
        TempDtldCustLedgEntry.Reset();
        TempDtldCustLedgEntry.SetRange(
            "Entry Type",
            TempDtldCustLedgEntry."Entry Type"::"Initial Entry");
        if TempDtldCustLedgEntry.FindSet() then
            repeat
                if not InitialEntryAmounts.Get(TempDtldCustLedgEntry."Cust. Ledger Entry No.", Amount) then
                    Amount := 0;
                InitialEntryAmounts.Set(
                    TempDtldCustLedgEntry."Cust. Ledger Entry No.",
                    Amount + TempDtldCustLedgEntry.Amount);
            until TempDtldCustLedgEntry.Next() = 0;

        TempCustLedgEntry.Reset();
        if TempCustLedgEntry.FindSet() then
            repeat
                if not InitialEntryAmounts.Get(TempCustLedgEntry."Entry No.", Amount) then
                    Amount := 0;
                FatturaDocHelper.InsertPaymentFatturaLine(
                    TempFatturaLine, TempCustLedgEntry."Due Date", Amount);
            until TempCustLedgEntry.Next() = 0;
    end;
}
