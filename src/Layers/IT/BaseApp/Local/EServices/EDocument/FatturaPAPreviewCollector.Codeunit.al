namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;

codeunit 12280 "FatturaPA Preview Collector"
{
    procedure Collect(
        SalesHeader: Record "Sales Header";
        var TempVATEntry: Record "VAT Entry" temporary;
        var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary)
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PreviewHandler: Codeunit "Posting Preview Event Handler";
    begin
        TempVATEntry.DeleteAll();
        TempCustLedgEntry.DeleteAll();
        TempDtldCustLedgEntry.DeleteAll();

        BindSubscription(SalesPostYesNo);
        GenJnlPostPreview.SetContext(SalesPostYesNo, SalesHeader);

        ClearLastError();
        if GenJnlPostPreview.Run() then;
        UnbindSubscription(SalesPostYesNo);

        if not GenJnlPostPreview.IsSuccess() then
            Error(PostingPreviewFailedErr, GetLastErrorText());

        GenJnlPostPreview.GetPreviewHandler(PreviewHandler);

        CopyEntries(Database::"VAT Entry", PreviewHandler, TempVATEntry);
        CopyEntries(Database::"Cust. Ledger Entry", PreviewHandler, TempCustLedgEntry);
        CopyEntries(Database::"Detailed Cust. Ledg. Entry", PreviewHandler, TempDtldCustLedgEntry);
    end;

    local procedure CopyEntries(
        TableNo: Integer;
        var PreviewHandler: Codeunit "Posting Preview Event Handler";
        var TempVATEntry: Record "VAT Entry" temporary)
    var
        EntryRef: RecordRef;
        VATEntry: Record "VAT Entry";
    begin
        PreviewHandler.GetEntries(TableNo, EntryRef);
        if EntryRef.FindSet() then
            repeat
                EntryRef.SetTable(VATEntry);
                TempVATEntry := VATEntry;
                if TempVATEntry.Insert() then;
            until EntryRef.Next() = 0;
    end;

    local procedure CopyEntries(
        TableNo: Integer;
        var PreviewHandler: Codeunit "Posting Preview Event Handler";
        var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    var
        EntryRef: RecordRef;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        PreviewHandler.GetEntries(TableNo, EntryRef);
        if EntryRef.FindSet() then
            repeat
                EntryRef.SetTable(CustLedgEntry);
                TempCustLedgEntry := CustLedgEntry;
                if TempCustLedgEntry.Insert() then;
            until EntryRef.Next() = 0;
    end;

    local procedure CopyEntries(
        TableNo: Integer;
        var PreviewHandler: Codeunit "Posting Preview Event Handler";
        var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary)
    var
        EntryRef: RecordRef;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        PreviewHandler.GetEntries(TableNo, EntryRef);
        if EntryRef.FindSet() then
            repeat
                EntryRef.SetTable(DtldCustLedgEntry);
                TempDtldCustLedgEntry := DtldCustLedgEntry;
                if TempDtldCustLedgEntry.Insert() then;
            until EntryRef.Next() = 0;
    end;

    var
        PostingPreviewFailedErr: Label 'Standard posting preview failed. %1';
}
