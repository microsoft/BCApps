codeunit 50102 "SFTP Operation Response"
{

    internal procedure GetResponseStream(var ResultInstream: InStream)
    begin
        ResultInstream := TempBlob.CreateInStream();
    end;

    internal procedure SetTempBlob(NewTempBlob: Codeunit "Temp Blob")
    begin
        TempBlob := NewTempBlob;
    end;

    var
        TempBlob: Codeunit "Temp Blob";
}