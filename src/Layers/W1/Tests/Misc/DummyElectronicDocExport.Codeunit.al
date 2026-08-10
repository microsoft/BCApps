codeunit 139190 "Dummy Electronic Doc. Export"
{
    Access = Internal;
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<DummyElectronicDocument/>');
        Rec.SetFileContent(TempBlob);
        Rec.Modify(false);
    end;
}
