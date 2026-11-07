namespace System.IO;

using System;
using System.Utilities;

codeunit 3009 DotNet_MemoryStream
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetMemoryStream: DotNet MemoryStream;

    procedure MemoryStream()
    begin
        DotNetMemoryStream := DotNetMemoryStream.MemoryStream();
    end;

    procedure MemoryStream(var DotNet_Array: Codeunit DotNet_Array)
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_Array.GetArray(DotNetArray);
        DotNetMemoryStream := DotNetMemoryStream.MemoryStream(DotNetArray)
    end;

    procedure ToArray(var DotNet_Array: Codeunit DotNet_Array)
    begin
        DotNet_Array.SetArray(DotNetMemoryStream.ToArray());
    end;

    procedure WriteTo(var OutStream: OutStream)
    begin
        DotNetMemoryStream.WriteTo(OutStream)
    end;

    procedure Close()
    begin
        DotNetMemoryStream.Close();
    end;

    procedure CopyFromInStream(var InStream: InStream)
    begin
        CopyStream(DotNetMemoryStream, InStream)
    end;

    procedure GetDotNetStream(var DotNet_Stream: Codeunit DotNet_Stream)
    begin
        DotNet_Stream.SetStream(DotNetMemoryStream);
    end;

    procedure SetPosition(NewPosition: Integer)
    begin
        DotNetMemoryStream.Position := NewPosition;
    end;

    [Scope('OnPrem')]
    procedure GetMemoryStream(var DotNetMemoryStream2: DotNet MemoryStream)
    begin
        DotNetMemoryStream2 := DotNetMemoryStream
    end;

    [Scope('OnPrem')]
    procedure SetMemoryStream(DotNetMemoryStream2: DotNet MemoryStream)
    begin
        DotNetMemoryStream := DotNetMemoryStream2
    end;
}

