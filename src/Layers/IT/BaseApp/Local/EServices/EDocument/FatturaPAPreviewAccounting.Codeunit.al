namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Receivables;

codeunit 12281 "FatturaPA Preview Accounting"
{
    procedure AddVATRows(
        var TempFatturaLine: Record "Fattura Line" temporary;
        var TempVATEntry: Record "VAT Entry" temporary;
        CustomerNo: Code[20];
        IsInvoice: Boolean)
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        AggregatedVATEntries: Record "VAT Entry" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        IsSplitPayment: Boolean;
        VATEntryCount: Integer;
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange(Type, TempVATEntry.Type::Sale);
        if TempVATEntry.FindSet() then
            repeat
                VATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group");
                if FatturaDocHelper.IsSplitVATSetup(VATPostingSetup) then
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
        Amount: Decimal;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        TempCustLedgEntry.Reset();
        if TempCustLedgEntry.FindSet() then
            repeat
                Amount := GetInitialEntryAmount(
                    TempCustLedgEntry."Entry No.",
                    TempDtldCustLedgEntry);

                FatturaDocHelper.InsertPaymentFatturaLine(
                    TempFatturaLine, TempCustLedgEntry."Due Date", Amount);
            until TempCustLedgEntry.Next() = 0;
    end;

    local procedure GetInitialEntryAmount(
        CustLedgEntryNo: Integer;
        var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary): Decimal
    var
        Total: Decimal;
    begin
        TempDtldCustLedgEntry.Reset();
        TempDtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        TempDtldCustLedgEntry.SetRange(
            "Entry Type",
            TempDtldCustLedgEntry."Entry Type"::"Initial Entry");

        if TempDtldCustLedgEntry.FindSet() then
            repeat
                Total += TempDtldCustLedgEntry.Amount;
            until TempDtldCustLedgEntry.Next() = 0;

        exit(Total);
    end;

}
