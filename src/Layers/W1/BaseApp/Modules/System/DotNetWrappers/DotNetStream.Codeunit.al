namespace System.IO;

using System;
using System.Utilities;

codeunit 3034 DotNet_Stream
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetStream: DotNet Stream;

    procedure FromInStream(InputStream: InStream)
    begin
        DotNetStream := InputStream;
    end;

    procedure FromOutStream(OutputStream: OutStream)
    begin
        DotNetStream := OutputStream;
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(SYSTEM.IsNull(DotNetStream));
    end;

    procedure Close()
    begin
        DotNetStream.Close();
    end;

    procedure Dispose()
    begin
        DotNetStream.Dispose();
    end;

    procedure CanSeek(): Boolean
    begin
        exit(DotNetStream.CanSeek);
    end;

    procedure CanRead(): Boolean
    begin
        exit(DotNetStream.CanRead);
    end;

    procedure CanWrite(): Boolean
    begin
        exit(DotNetStream.CanWrite);
    end;

    procedure Length(): BigInteger
    begin
        exit(DotNetStream.Length);
    end;

    procedure Position(): BigInteger
    begin
        exit(DotNetStream.Position);
    end;

    procedure ReadByte(): Integer
    begin
        exit(DotNetStream.ReadByte());
    end;

    procedure WriteByte(Value: Integer)
    begin
        DotNetStream.WriteByte(Value);
    end;

    procedure Seek(Offset: Integer; var DotNet_SeekOrigin: Codeunit DotNet_SeekOrigin): BigInteger
    var
        DotNetSeekOrigin: DotNet SeekOrigin;
    begin
        DotNet_SeekOrigin.GetSeekOrigin(DotNetSeekOrigin);
        exit(DotNetStream.Seek(Offset, DotNetSeekOrigin));
    end;

    procedure Read(var DotNet_Array: Codeunit DotNet_Array; Offset: Integer; "Count": Integer): Integer
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_Array.GetArray(DotNetArray);
        exit(DotNetStream.Read(DotNetArray, Offset, Count));
    end;

    procedure Write(var DotNet_Array: Codeunit DotNet_Array; Offset: Integer; "Count": Integer)
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_Array.GetArray(DotNetArray);
        DotNetStream.Write(DotNetArray, Offset, Count);
    end;

    [Scope('OnPrem')]
    procedure GetStream(var CurrentDotNetStream: DotNet Stream)
    begin
        CurrentDotNetStream := DotNetStream;
    end;

    [Scope('OnPrem')]
    procedure SetStream(NewDotNetStream: DotNet Stream)
    begin
        DotNetStream := NewDotNetStream;
    end;
}

