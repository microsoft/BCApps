namespace System.Text;

using System;
using System.Utilities;

codeunit 3007 DotNet_String
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetString: DotNet String;

    procedure FromCharArray(DotNet_ArrayChar: Codeunit DotNet_Array)
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_ArrayChar.GetArray(DotNetArray);
        DotNetString := DotNetString.String(DotNetArray);
    end;

    procedure Set(Text: Text)
    begin
        DotNetString := Text
    end;

    procedure Replace(ToReplace: Text; ReplacementText: Text): Text
    begin
        exit(DotNetString.Replace(ToReplace, ReplacementText))
    end;

    procedure Split(DotNet_ArraySplit: Codeunit DotNet_Array; var DotNet_ArrayReturn: Codeunit DotNet_Array)
    var
        DotNetArraySplit: DotNet Array;
    begin
        DotNet_ArraySplit.GetArray(DotNetArraySplit);
        DotNet_ArrayReturn.SetArray(DotNetString.Split(DotNetArraySplit));
    end;

    procedure ToCharArray(StartIndex: Integer; Length: Integer; var DotNet_Array: Codeunit DotNet_Array)
    begin
        DotNet_Array.SetArray(DotNetString.ToCharArray(StartIndex, Length));
    end;

    procedure Length(): Integer
    begin
        exit(DotNetString.Length);
    end;

    procedure StartsWith(Value: Text): Boolean
    begin
        exit(DotNetString.StartsWith(Value))
    end;

    procedure EndsWith(Value: Text): Boolean
    begin
        exit(DotNetString.EndsWith(Value))
    end;

    procedure ToString(): Text
    begin
        exit(DotNetString.ToString());
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetString));
    end;

    [Scope('OnPrem')]
    procedure GetString(var DotNetString2: DotNet String)
    begin
        DotNetString2 := DotNetString
    end;

    [Scope('OnPrem')]
    procedure SetString(DotNetString2: DotNet String)
    begin
        DotNetString := DotNetString2
    end;

    procedure PadRight(TotalWidth: Integer; PaddingChar: Char): Text
    begin
        exit(DotNetString.PadRight(TotalWidth, PaddingChar));
    end;

    procedure PadLeft(TotalWidth: Integer; PaddingChar: Char): Text
    begin
        exit(DotNetString.PadLeft(TotalWidth, PaddingChar));
    end;

    procedure IndexOfChar(Value: Char; StartIndex: Integer): Integer
    begin
        exit(DotNetString.IndexOf(Value, StartIndex));
    end;

    procedure IndexOfString(Value: Text; StartIndex: Integer): Integer
    begin
        exit(DotNetString.IndexOf(Value, StartIndex));
    end;

    procedure LastIndexOfString(Value: Text): Integer;
    begin
        exit(DotNetString.LastIndexOf(Value));
    end;

    procedure Substring(StartIndex: Integer; Length: Integer): Text
    begin
        exit(DotNetString.Substring(StartIndex, Length));
    end;

    procedure Trim(): Text
    begin
        exit(DotNetString.Trim());
    end;

    procedure TrimStart(var DotNet_ArrayTrimChars: Codeunit DotNet_Array): Text
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_ArrayTrimChars.GetArray(DotNetArray);
        exit(DotNetString.TrimStart(DotNetArray));
    end;

    procedure TrimEnd(var DotNet_ArrayTrimChars: Codeunit DotNet_Array): Text
    var
        DotNetArray: DotNet Array;
    begin
        DotNet_ArrayTrimChars.GetArray(DotNetArray);
        exit(DotNetString.TrimEnd(DotNetArray));
    end;

    procedure Normalize(DotNet_NormalizationForm: Codeunit DotNet_NormalizationForm): Text
    var
        DotNetNormalizationForm: DotNet NormalizationForm;
    begin
        DotNet_NormalizationForm.GetNormalizationForm(DotNetNormalizationForm);
        exit(DotNetString.Normalize(DotNetNormalizationForm));
    end;

    procedure Normalize(): Text
    begin
        exit(DotNetString.Normalize());
    end;

    procedure IsNormalized(DotNet_NormalizationForm: Codeunit DotNet_NormalizationForm): Boolean
    var
        DotNetNormalizationForm: DotNet NormalizationForm;
    begin
        DotNet_NormalizationForm.GetNormalizationForm(DotNetNormalizationForm);
        exit(DotNetString.IsNormalized(DotNetNormalizationForm));
    end;
}

