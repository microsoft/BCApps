namespace System.IO;

using System.Utilities;

codeunit 1240 "Read Data Exch. from File"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        RecordRef: RecordRef;
    begin
        OnBeforeFileImport(TempBlob, Rec."File Name");

        if not TempBlob.HasValue() then
            Rec."File Name" := CopyStr(
                FileMgt.BLOBImportWithFilter(TempBlob, ImportBankStmtTxt, '', FileFilterTxt, FileFilterExtensionTxt), 1, 250);

        if Rec."File Name" <> '' then begin
            OnRunOnBeforeGetTable(TempBlob, Rec);
            RecordRef.GetTable(Rec);
            TempBlob.ToRecordRef(RecordRef, Rec.FieldNo("File Content"));
            RecordRef.SetTable(Rec);
        end;
    end;

    var
        ImportBankStmtTxt: Label 'Select a file to import';
        FileFilterTxt: Label 'All Files(*.*)|*.*|XML Files(*.xml)|*.xml|Text Files(*.txt;*.csv;*.asc)|*.txt;*.csv;*.asc;*.nda';
        FileFilterExtensionTxt: Label 'txt,csv,asc,xml,nda', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFileImport(var TempBlob: Codeunit "Temp Blob"; var FileName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGetTable(var TempBlob: Codeunit "Temp Blob"; DataExch: Record "Data Exch.")
    begin
    end;
}

