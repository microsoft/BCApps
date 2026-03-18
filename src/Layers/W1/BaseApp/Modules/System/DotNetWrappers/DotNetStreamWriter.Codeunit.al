namespace System.IO;

using System;
using System.Text;

codeunit 3025 DotNet_StreamWriter
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetStreamWriter: DotNet StreamWriter;

    procedure Write(Text: Text)
    begin
        DotNetStreamWriter.Write(Text);
    end;

    procedure WriteLine(LineText: Text)
    begin
        DotNetStreamWriter.WriteLine(LineText);
    end;

    procedure StreamWriter(var OutStream: OutStream; DotNet_Encoding: Codeunit DotNet_Encoding)
    var
        DotNetEncoding: DotNet Encoding;
    begin
        DotNet_Encoding.GetEncoding(DotNetEncoding);
        DotNetStreamWriter := DotNetStreamWriter.StreamWriter(OutStream, DotNetEncoding);
    end;

    procedure StreamWriter(var OutStream: OutStream)
    begin
        DotNetStreamWriter := DotNetStreamWriter.StreamWriter(OutStream);
    end;

    procedure Flush()
    begin
        DotNetStreamWriter.Flush();
    end;

    procedure Close()
    begin
        DotNetStreamWriter.Close();
    end;

    procedure Dispose()
    begin
        DotNetStreamWriter.Dispose();
    end;
}

