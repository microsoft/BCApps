#pragma warning disable AA0247
codeunit 6233 "Sust. Preview Post Instance"
{
    SingleInstance = true;

    procedure InsertDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    var
    begin
        if HasSustainabilityEntry then
            InsertDocumentEntryForSustLedgerEntry(TempDocumentEntry);

        if HasSustainabilityValueEntry then
            InsertDocumentEntryForSustValueEntry(TempDocumentEntry);
    end;

    local procedure InsertDocumentEntryForSustLedgerEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempSustLedgEntry);

        if RecRef.IsEmpty() then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := RecRef.Number;
        TempDocumentEntry."Table ID" := RecRef.Number;
        TempDocumentEntry."Table Name" := CopyStr(RecRef.Caption, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecRef.Count();
        TempDocumentEntry.Insert();
    end;

    local procedure InsertDocumentEntryForSustValueEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempSustValueEntry);

        if RecRef.IsEmpty() then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := RecRef.Number;
        TempDocumentEntry."Table ID" := RecRef.Number;
        TempDocumentEntry."Table Name" := CopyStr(RecRef.Caption, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecRef.Count();
        TempDocumentEntry.Insert();
    end;

    procedure InsertSustLedgEntry(var SustLedgEntry: Record "Sustainability Ledger Entry"; RunTrigger: Boolean)
    begin
        if SustLedgEntry.IsTemporary() then
            exit;

        if NextSustLedgerPreviewEntryNo = 0 then
            NextSustLedgerPreviewEntryNo := -2000000000;

        TempSustLedgEntry := SustLedgEntry;
        TempSustLedgEntry."Entry No." := NextSustLedgerPreviewEntryNo;
        TempSustLedgEntry."Document No." := '***';
        TempSustLedgEntry.Insert();
        NextSustLedgerPreviewEntryNo += 1;
        HasSustainabilityEntry := true;
    end;

    procedure InsertSustValueEntry(var SustValueEntry: Record "Sustainability Value Entry"; RunTrigger: Boolean)
    begin
        if SustValueEntry.IsTemporary() then
            exit;

        TempSustValueEntry := SustValueEntry;
        TempSustValueEntry."Document No." := '***';
        TempSustValueEntry.Insert();
        HasSustainabilityValueEntry := true;
    end;

    procedure ShowEntries()
    begin
        Page.Run(Page::"Sustainability Ledger Entries", TempSustLedgEntry);
    end;

    procedure ShowSustValueEntries()
    begin
        Page.Run(Page::"Sustainability Value Entries", TempSustValueEntry);
    end;

    procedure Initialize()
    begin
        ClearAll();
        TempSustLedgEntry.Reset();
        TempSustLedgEntry.DeleteAll();

        TempSustValueEntry.Reset();
        TempSustValueEntry.DeleteAll();

        NextSustLedgerPreviewEntryNo := -2000000000;
    end;

    var
        TempSustLedgEntry: Record "Sustainability Ledger Entry" temporary;
        TempSustValueEntry: Record "Sustainability Value Entry" temporary;
        NextSustLedgerPreviewEntryNo: Integer;
        HasSustainabilityEntry: Boolean;
        HasSustainabilityValueEntry: Boolean;
}
