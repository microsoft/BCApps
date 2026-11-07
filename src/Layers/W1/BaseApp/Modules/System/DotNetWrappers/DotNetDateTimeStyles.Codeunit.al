namespace System.DateTime;

using System;

codeunit 3004 DotNet_DateTimeStyles
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetDateTimeStyles: DotNet DateTimeStyles;

    procedure "None"()
    begin
        DotNetDateTimeStyles := DotNetDateTimeStyles.None
    end;

    [Scope('OnPrem')]
    procedure GetDateTimeStyles(var DotNetDateTimeStyles2: DotNet DateTimeStyles)
    begin
        DotNetDateTimeStyles2 := DotNetDateTimeStyles
    end;

    [Scope('OnPrem')]
    procedure SetDateTimeStyles(DotNetDateTimeStyles2: DotNet DateTimeStyles)
    begin
        DotNetDateTimeStyles := DotNetDateTimeStyles2
    end;
}

