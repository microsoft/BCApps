namespace System.DateTime;

using System;

codeunit 3022 DotNet_DateTimeFormatInfo
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetDateTimeFormatInfo: DotNet DateTimeFormatInfo;

    [Scope('OnPrem')]
    procedure GetDateTimeFormatInfo(var DotNetDateTimeFormatInfo2: DotNet DateTimeFormatInfo)
    begin
        DotNetDateTimeFormatInfo2 := DotNetDateTimeFormatInfo
    end;

    [Scope('OnPrem')]
    procedure SetDateTimeFormatInfo(DotNetDateTimeFormatInfo2: DotNet DateTimeFormatInfo)
    begin
        DotNetDateTimeFormatInfo := DotNetDateTimeFormatInfo2
    end;
}

