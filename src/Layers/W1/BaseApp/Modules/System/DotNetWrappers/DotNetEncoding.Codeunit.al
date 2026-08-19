namespace System.Text;

using System;
using System.Utilities;

codeunit 3026 DotNet_Encoding
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetEncoding: DotNet Encoding;

    procedure ASCII()
    begin
        DotNetEncoding := DotNetEncoding.ASCII;
    end;

    procedure UTF8()
    begin
        DotNetEncoding := DotNetEncoding.UTF8;
    end;

    procedure UTF32()
    begin
        DotNetEncoding := DotNetEncoding.UTF32;
    end;

    procedure Unicode()
    begin
        DotNetEncoding := DotNetEncoding.Unicode;
    end;

    procedure ISO88591()
    begin
        DotNetEncoding := DotNetEncoding.GetEncoding('iso-8859-1');
    end;

    procedure Encoding(codePage: Integer)
    begin
        DotNetEncoding := DotNetEncoding.GetEncoding(codePage);
    end;

    procedure Codepage(): Integer
    begin
        exit(DotNetEncoding.CodePage);
    end;

    [Scope('OnPrem')]
    procedure GetEncoding(var DotNetEncoding2: DotNet Encoding)
    begin
        DotNetEncoding2 := DotNetEncoding;
    end;

    [Scope('OnPrem')]
    procedure SetEncoding(DotNetEncoding2: DotNet Encoding)
    begin
        DotNetEncoding := DotNetEncoding2;
    end;

    procedure GetChars(DotNet_ArrayBytes: Codeunit DotNet_Array; Index: Integer; "Count": Integer; var DotNet_ArrayResult: Codeunit DotNet_Array)
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_ArrayBytes.GetArray(DotNetArray);
        DotNet_ArrayResult.SetArray(DotNetEncoding.GetChars(DotNetArray, Index, Count));
    end;

    procedure GetBytes(DotNet_ArrayChars: Codeunit DotNet_Array; Index: Integer; "Count": Integer; var DotNet_ArrayResult: Codeunit DotNet_Array)
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_ArrayChars.GetArray(DotNetArray);
        DotNet_ArrayResult.SetArray(DotNetEncoding.GetBytes(DotNetArray, Index, Count));
    end;

    procedure GetBytesWithOffset(DotNet_ArrayChars: Codeunit DotNet_Array; Index: Integer; "Count": Integer; var DotNet_ArrayResult: Codeunit DotNet_Array; ByteIndex: Integer)
    var
        DotNetArray: DotNet Array;
        DotNetArrayResult: DotNet Array;
    begin
        DotNet_ArrayChars.GetArray(DotNetArray);
        DotNet_ArrayResult.GetArray(DotNetArrayResult);
        DotNetEncoding.GetBytes(DotNetArray, Index, Count, DotNetArrayResult, ByteIndex);
    end;

    procedure GetString(DotNet_ArrayBytes: Codeunit DotNet_Array; Index: Integer; "Count": Integer): Text
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_ArrayBytes.GetArray(DotNetArray);
        exit(DotNetEncoding.GetString(DotNetArray, Index, Count));
    end;
}

