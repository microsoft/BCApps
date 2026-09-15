namespace System.Utilities;

using System;

codeunit 3035 DotNet_Buffer
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetBuffer: DotNet Buffer;

    procedure BlockCopy(var Source_DotNet_Array: Codeunit DotNet_Array; SourceOffset: Integer; var Destination_DotNet_Array: Codeunit DotNet_Array; DestinationOffset: Integer; "Count": Integer)
    var
        SourceDotNetArray: DotNet Array;
        DestinationDotNetArray: DotNet Array;
    begin
        Source_DotNet_Array.GetArray(SourceDotNetArray);
        Destination_DotNet_Array.GetArray(DestinationDotNetArray);
        DotNetBuffer.BlockCopy(SourceDotNetArray, SourceOffset, DestinationDotNetArray, DestinationOffset, Count);
    end;

    procedure ByteLength(var DotNet_Array: Codeunit DotNet_Array): Integer
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_Array.GetArray(DotNetArray);
        exit(DotNetBuffer.ByteLength(DotNetArray));
    end;

    procedure GetByte(var DotNet_Array: Codeunit DotNet_Array; Index: Integer): Integer
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_Array.GetArray(DotNetArray);
        exit(DotNetBuffer.GetByte(DotNetArray, Index));
    end;

    procedure SetByte(var DotNet_Array: Codeunit DotNet_Array; Index: Integer; Value: Integer)
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_Array.GetArray(DotNetArray);
        DotNetBuffer.SetByte(DotNetArray, Index, Value);
    end;
}

