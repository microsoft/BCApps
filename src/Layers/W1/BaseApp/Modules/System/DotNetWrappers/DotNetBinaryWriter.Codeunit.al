namespace System.IO;

using System;
using System.Text;

codeunit 3033 DotNet_BinaryWriter
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetBinaryWriter: DotNet BinaryWriter;

    procedure BinaryWriter(var DotNet_Stream: Codeunit DotNet_Stream)
    var
        DotNetStream: DotNet Stream;
    begin
        DotNet_Stream.GetStream(DotNetStream);
        DotNetBinaryWriter := DotNetBinaryWriter.BinaryWriter(DotNetStream);
    end;

    procedure BinaryWriterWithEncoding(var DotNet_Stream: Codeunit DotNet_Stream; var DotNet_Encoding: Codeunit DotNet_Encoding)
    var
        DotNetEncoding: DotNet Encoding;
        DotNetStream: DotNet Stream;
    begin
        DotNet_Encoding.GetEncoding(DotNetEncoding);
        DotNet_Stream.GetStream(DotNetStream);
        DotNetBinaryWriter := DotNetBinaryWriter.BinaryWriter(DotNetStream, DotNetEncoding);
    end;

    procedure Close()
    begin
        DotNetBinaryWriter.Close();
    end;

    procedure Dispose()
    begin
        DotNetBinaryWriter.Dispose();
    end;

    procedure Flush()
    begin
        DotNetBinaryWriter.Flush();
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetBinaryWriter));
    end;

    procedure Seek(Offset: Integer; var DotNet_SeekOrigin: Codeunit DotNet_SeekOrigin): BigInteger
    var
        DotNetSeekOrigin: DotNet SeekOrigin;
    begin
        DotNet_SeekOrigin.GetSeekOrigin(DotNetSeekOrigin);
        exit(DotNetBinaryWriter.Seek(Offset, DotNetSeekOrigin));
    end;

    procedure WriteByte(Byte: Byte)
    begin
        DotNetBinaryWriter.Write(Byte);
    end;

    procedure WriteInt32("Integer": Integer)
    var
        DotNetConvert: DotNet Convert;
    begin
        DotNetBinaryWriter.Write(DotNetConvert.ToInt32(Integer));
    end;

    procedure WriteInt16("Integer": Integer)
    var
        DotNetConvert: DotNet Convert;
    begin
        DotNetBinaryWriter.Write(DotNetConvert.ToInt16(Integer))
    end;

    procedure WriteUInt16("Integer": Integer)
    var
        DotNetConvert: DotNet Convert;
    begin
        DotNetBinaryWriter.Write(DotNetConvert.ToUInt16(Integer))
    end;

    procedure WriteUInt32("Integer": Integer)
    var
        DotNetConvert: DotNet Convert;
    begin
        DotNetBinaryWriter.Write(DotNetConvert.ToUInt32(Integer))
    end;

    procedure WriteChar(Char: Char)
    begin
        DotNetBinaryWriter.Write(Char)
    end;

    procedure BaseStream(var DotNet_Stream: Codeunit DotNet_Stream)
    begin
        DotNet_Stream.SetStream(DotNetBinaryWriter.BaseStream);
    end;

    procedure WriteString(Text: Text)
    begin
        DotNetBinaryWriter.Write(Text);
    end;

    procedure WriteBoolean(Boolean: Boolean)
    begin
        DotNetBinaryWriter.Write(Boolean)
    end;

    procedure WriteDecimal(Decimal: Decimal)
    begin
        DotNetBinaryWriter.Write(Decimal);
    end;
}

