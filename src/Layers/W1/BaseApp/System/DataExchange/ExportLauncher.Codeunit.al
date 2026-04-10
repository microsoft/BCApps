namespace System.IO;

codeunit 1268 "Export Launcher"
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch. Mapping";

    trigger OnRun()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
    begin
        if not SourceRecordIsInitialized then
            Error(UnknownSourceRecordErr);

        DataExchDef.Get(Rec."Data Exch. Def Code");

        CreateDataExch(DataExch, Rec."Data Exch. Def Code", Rec."Data Exch. Line Def Code", SourceRecRef.GetView());

        if DataExchDef."Data Handling Codeunit" > 0 then
            CODEUNIT.Run(DataExchDef."Data Handling Codeunit", Rec);

        if DataExchDef."Validation Codeunit" > 0 then
            CODEUNIT.Run(DataExchDef."Validation Codeunit", Rec);

        DataExch.ExportFromDataExch(Rec);
    end;

    var
        SourceRecRef: RecordRef;
        SourceRecordIsInitialized: Boolean;
        UnknownSourceRecordErr: Label 'The source record is unknown. Exporting functionality cannot proceed without defining a source record to work on.';
        UnsupportedSourceRecordTypeErr: Label 'Only Record, RecordID or RecordRef are supported for initializing the source record. Exporting functionality cannot proceed without defining a source record to work on.';

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableFilters: Text)
    var
        TableFiltersOutStream: OutStream;
    begin
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchDefCode;
        DataExch."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExch."Table Filters".CreateOutStream(TableFiltersOutStream);
        TableFiltersOutStream.WriteText(TableFilters);
        DataExch.Insert();
    end;

    procedure SetSourceRecord(var Source: Variant)
    var
        SourceRecordID: RecordID;
    begin
        case true of
            Source.IsRecord:
                SourceRecRef.GetTable(Source);
            Source.IsRecordId:
                begin
                    SourceRecordID := Source;
                    SourceRecRef := SourceRecordID.GetRecord();
                end;
            Source.IsRecordRef:
                SourceRecRef := Source;
            else
                Error(UnsupportedSourceRecordTypeErr);
        end;

        SourceRecordIsInitialized := true;
    end;
}

