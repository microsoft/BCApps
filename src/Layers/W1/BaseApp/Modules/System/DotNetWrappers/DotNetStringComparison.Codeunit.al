namespace System.Text;

using System;

codeunit 3015 DotNet_StringComparison
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetStringComparison: DotNet StringComparison;

    procedure OrdinalIgnoreCase(): Integer
    begin
        exit(DotNetStringComparison.OrdinalIgnoreCase)
    end;

    [Scope('OnPrem')]
    procedure GetStringComparison(var DotNetStringComparison2: DotNet StringComparison)
    begin
        DotNetStringComparison2 := DotNetStringComparison
    end;

    [Scope('OnPrem')]
    procedure SetStringComparison(DotNetStringComparison2: DotNet StringComparison)
    begin
        DotNetStringComparison := DotNetStringComparison2
    end;
}

