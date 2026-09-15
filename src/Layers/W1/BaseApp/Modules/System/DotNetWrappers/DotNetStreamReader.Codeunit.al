namespace System.IO;

using System;
using System.Text;

codeunit 3027 DotNet_StreamReader
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetStreamReader: DotNet StreamReader;

    procedure StreamReader(var InputStream: InStream; DotNet_Encoding: Codeunit DotNet_Encoding)
    var
        DotNetEncoding: DotNet Encoding;
    begin
        DotNet_Encoding.GetEncoding(DotNetEncoding);
        DotNetStreamReader := DotNetStreamReader.StreamReader(InputStream, DotNetEncoding);
    end;

    procedure StreamReader(var InputStream: InStream; DetectEncodingFromByteOrderMarks: Boolean)
    begin
        DotNetStreamReader := DotNetStreamReader.StreamReader(InputStream, DetectEncodingFromByteOrderMarks);
    end;

    procedure Close()
    begin
        DotNetStreamReader.Close();
    end;

    procedure Dispose()
    begin
        DotNetStreamReader.Dispose();
    end;

    procedure EndOfStream(): Boolean
    begin
        exit(DotNetStreamReader.EndOfStream);
    end;

    procedure CurrentEncoding(var DotNet_Encoding: Codeunit DotNet_Encoding)
    begin
        DotNet_Encoding.SetEncoding(DotNetStreamReader.CurrentEncoding);
    end;

    procedure ReadLine(): Text
    begin
        exit(DotNetStreamReader.ReadLine());
    end;

    procedure ReadToEnd(): Text
    begin
        exit(DotNetStreamReader.ReadToEnd());
    end;
}

