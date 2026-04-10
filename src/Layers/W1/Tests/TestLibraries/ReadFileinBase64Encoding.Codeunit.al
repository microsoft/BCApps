codeunit 132564 "Read File in Base64 Encoding"
{

    trigger OnRun()
    begin
        ReadContentAsBase64(TempBlob);
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure GetFileName(): Text
    begin
        exit(FileName);
    end;

    [Scope('OnPrem')]
    procedure ReadContentAsBase64(var TempBlob2: Codeunit "Temp Blob")
    var
        OutputStream: OutStream;
        Convert: DotNet Convert;
        File: DotNet File;
    begin
        TempBlob2.CreateOutStream(OutputStream);
        OutputStream.Write(Convert.ToBase64String(File.ReadAllBytes(FileName)));
    end;

    [Scope('OnPrem')]
    procedure GetTempBlob(var TempBlob2: Codeunit "Temp Blob")
    begin
        TempBlob2 := TempBlob
    end;
}

