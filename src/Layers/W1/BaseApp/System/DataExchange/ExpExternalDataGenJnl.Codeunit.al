namespace System.IO;

using System.Utilities;

codeunit 1277 "Exp. External Data Gen. Jnl."
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        Rec.CalcFields("File Content");
        if not Rec."File Content".HasValue() then
            Error(ExternalContentErr, Rec.FieldCaption("File Content"));

        TempBlob.FromRecord(Rec, Rec.FieldNo("File Content"));
        ExportToFile(Rec, TempBlob, Rec."Data Exch. Def Code" + ' ' + Rec."Data Exch. Line Def Code" + TxtExtTok);
    end;

    var
#pragma warning disable AA0470
        ExternalContentErr: Label '%1 is empty.';
#pragma warning restore AA0470
        DownloadFromStreamErr: Label 'The file has not been saved.';
        TxtExtTok: Label '.txt', Locked = true;

    local procedure ExportToFile(DataExch: Record "Data Exch."; var TempBlob: Codeunit "Temp Blob"; FileName: Text)
    var
        FileMgt: Codeunit "File Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportToFile(DataExch, FileName, IsHandled);
        if IsHandled then
            exit;

        if FileMgt.BLOBExport(TempBlob, FileName, true) = '' then
            Error(DownloadFromStreamErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportToFile(DataExch: Record "Data Exch."; var FileName: Text; var Handled: Boolean)
    begin
    end;
}

