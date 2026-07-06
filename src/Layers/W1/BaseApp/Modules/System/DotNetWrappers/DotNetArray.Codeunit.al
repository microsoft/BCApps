namespace System.Utilities;

using System;

codeunit 3000 DotNet_Array
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetArray: DotNet Array;

    procedure StringArray(Length: Integer)
    var
        DotNetString: DotNet String;
    begin
        DotNetArray := DotNetArray.CreateInstance(GetDotNetType(DotNetString), Length);
    end;

    procedure CharArray(Length: Integer)
    var
        DotNetChar: DotNet Char;
    begin
        DotNetArray := DotNetArray.CreateInstance(GetDotNetType(DotNetChar), Length);
    end;

    procedure ByteArray(Length: Integer)
    var
        DotNetByte: DotNet Byte;
    begin
        DotNetArray := DotNetArray.CreateInstance(GetDotNetType(DotNetByte), Length);
    end;

    procedure Int32Array(Length: Integer)
    var
        DotNetInt32: DotNet Int32;
    begin
        DotNetArray := DotNetArray.CreateInstance(GetDotNetType(DotNetInt32), Length);
    end;

    procedure Length(): Integer
    begin
        exit(DotNetArray.Length)
    end;

    procedure SetTextValue(NewValue: Text; Index: Integer)
    begin
        DotNetArray.SetValue(NewValue, Index);
    end;

    procedure SetCharValue(NewValue: Char; Index: Integer)
    begin
        DotNetArray.SetValue(NewValue, Index);
    end;

    procedure SetByteValue(NewValue: Byte; Index: Integer)
    begin
        DotNetArray.SetValue(NewValue, Index);
    end;

    procedure SetIntValue(NewValue: Integer; Index: Integer)
    begin
        DotNetArray.SetValue(NewValue, Index);
    end;

    procedure GetValueAsText(Index: Integer): Text
    begin
        exit(DotNetArray.GetValue(Index))
    end;

    procedure GetValueAsChar(Index: Integer): Char
    begin
        exit(DotNetArray.GetValue(Index));
    end;

    procedure GetValueAsInteger(Index: Integer): Integer
    begin
        exit(DotNetArray.GetValue(Index));
    end;

    [Scope('OnPrem')]
    procedure GetArray(var DotNetArray2: DotNet Array)
    begin
        DotNetArray2 := DotNetArray
    end;

    [Scope('OnPrem')]
    procedure SetArray(DotNetArray2: DotNet Array)
    begin
        DotNetArray := DotNetArray2
    end;

    procedure IsNull(): Boolean
    begin
        exit(SYSTEM.IsNull(DotNetArray));
    end;
}

