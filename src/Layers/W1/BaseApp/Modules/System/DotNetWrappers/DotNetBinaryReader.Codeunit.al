namespace System.IO;

using System;
using System.Text;
using System.Utilities;

codeunit 3032 DotNet_BinaryReader
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetBinaryReader: DotNet BinaryReader;

    procedure BinaryReader(var DotNet_Stream: Codeunit DotNet_Stream)
    var
        DotNetStream: DotNet Stream;
    begin
        DotNet_Stream.GetStream(DotNetStream);
        DotNetBinaryReader := DotNetBinaryReader.BinaryReader(DotNetStream);
    end;

    procedure BinaryReaderWithEncoding(var DotNet_Stream: Codeunit DotNet_Stream; var DotNet_Encoding: Codeunit DotNet_Encoding)
    var
        DotNetEncoding: DotNet Encoding;
        DotNetStream: DotNet Stream;
    begin
        DotNet_Stream.GetStream(DotNetStream);
        DotNet_Encoding.GetEncoding(DotNetEncoding);
        DotNetBinaryReader := DotNetBinaryReader.BinaryReader(DotNetStream, DotNetEncoding);
    end;

    procedure Close()
    begin
        DotNetBinaryReader.Close();
    end;

    procedure Dispose()
    begin
        DotNetBinaryReader.Dispose();
    end;

    procedure ReadByte(): Byte
    begin
        exit(DotNetBinaryReader.ReadByte());
    end;

    procedure ReadUInt32(): Integer
    begin
        exit(DotNetBinaryReader.ReadUInt32());
    end;

    procedure ReadUInt16(): Integer
    begin
        exit(DotNetBinaryReader.ReadUInt16());
    end;

    procedure ReadInt16(): Integer
    begin
        exit(DotNetBinaryReader.ReadInt16());
    end;

    procedure ReadInt32(): Integer
    begin
        exit(DotNetBinaryReader.ReadInt32());
    end;

    procedure ReadBytes("Count": Integer; var DotNet_Array: Codeunit DotNet_Array)
    begin
        DotNet_Array.SetArray(DotNetBinaryReader.ReadBytes(Count));
    end;

    procedure ReadChars("Count": Integer; var DotNet_Array: Codeunit DotNet_Array)
    begin
        DotNet_Array.SetArray(DotNetBinaryReader.ReadChars(Count));
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetBinaryReader));
    end;

    procedure BaseStream(var DotNet_Stream: Codeunit DotNet_Stream)
    begin
        DotNet_Stream.SetStream(DotNetBinaryReader.BaseStream);
    end;

    procedure ReadChar(): Char
    begin
        exit(DotNetBinaryReader.ReadChar());
    end;

    procedure ReadString(): Text
    begin
        exit(DotNetBinaryReader.ReadString());
    end;

    procedure ReadBoolean(): Boolean
    begin
        exit(DotNetBinaryReader.ReadBoolean());
    end;

    procedure ReadDecimal(): Decimal
    begin
        exit(DotNetBinaryReader.ReadDecimal());
    end;

    [Scope('OnPrem')]
    procedure GetBinaryReader(var DotNetBinaryReader2: DotNet BinaryReader)
    begin
        DotNetBinaryReader2 := DotNetBinaryReader
    end;

    [Scope('OnPrem')]
    procedure SetBinaryReader(var DotNetBinaryReader2: DotNet BinaryReader)
    begin
        DotNetBinaryReader := DotNetBinaryReader2
    end;
}

