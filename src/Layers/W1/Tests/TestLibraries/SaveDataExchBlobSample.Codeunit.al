codeunit 134661 "Save Data Exch. Blob Sample"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        Filename: Text;
    begin
        CalcFields("File Content");
        if not "File Content".HasValue() then
            Error(ExternalContentErr, FieldCaption("File Content"));

        TempBlob.FromRecord(Rec, FieldNo("File Content"));
        Filename := FileMgt.ServerTempFileName('txt');
        FileMgt.BLOBExportToServerFile(TempBlob, Filename);

        Find();
        "File Name" := CopyStr(Filename, 1, MaxStrLen("File Name"));
        Modify();
    end;

    var
        ExternalContentErr: Label '%1 is empty.';
}

