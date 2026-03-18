namespace System.Text;

using System;

codeunit 3014 DotNet_StringBuilder
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetStringBuilder: DotNet StringBuilder;

    procedure InitStringBuilder(Value: Text)
    begin
        DotNetStringBuilder := DotNetStringBuilder.StringBuilder(Value)
    end;

    procedure Append(Value: Text)
    begin
        DotNetStringBuilder.Append(Value)
    end;

    procedure AppendFormat(Format: Text; Value: Variant)
    begin
        DotNetStringBuilder.AppendFormat(Format, Value);
    end;

    procedure ToString(): Text
    begin
        exit(DotNetStringBuilder.ToString())
    end;

    procedure AppendLine()
    begin
        DotNetStringBuilder.AppendLine();
    end;

    [Scope('OnPrem')]
    procedure GetStringBuilder(var DotNetStringBuilder2: DotNet StringBuilder)
    begin
        DotNetStringBuilder2 := DotNetStringBuilder
    end;

    [Scope('OnPrem')]
    procedure SetStringBuilder(DotNetStringBuilder2: DotNet StringBuilder)
    begin
        DotNetStringBuilder := DotNetStringBuilder2
    end;
}

