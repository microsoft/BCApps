namespace System.DateTime;

using System;

codeunit 3006 DotNet_DateTimeOffset
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetDateTimeOffsetGlobal: DotNet DateTimeOffset;

    procedure DateTime(var DotNet_DateTime: Codeunit DotNet_DateTime)
    begin
        DotNet_DateTime.SetDateTime(DotNetDateTimeOffsetGlobal.DateTime)
    end;

    [Scope('OnPrem')]
    procedure GetDateTimeOffset(var DotNetDateTimeOffsetResult: DotNet DateTimeOffset)
    begin
        DotNetDateTimeOffsetResult := DotNetDateTimeOffsetGlobal
    end;

    [Scope('OnPrem')]
    procedure SetDateTimeOffset(NewDotNetDateTimeOffset: DotNet DateTimeOffset)
    begin
        DotNetDateTimeOffsetGlobal := NewDotNetDateTimeOffset
    end;

    procedure ConvertToUtcDateTime(DateTimeSource: DateTime): DateTime
    var
        DotNetDateTimeOffsetSource: DotNet DateTimeOffset;
        DotNetDateTimeOffsetNow: DotNet DateTimeOffset;
    begin
        if DateTimeSource = CreateDateTime(0D, 0T) then
            exit(CreateDateTime(0D, 0T));

        DotNetDateTimeOffsetSource := DotNetDateTimeOffsetSource.DateTimeOffset(DateTimeSource);
        DotNetDateTimeOffsetNow := DotNetDateTimeOffsetNow.Now;
        exit(DotNetDateTimeOffsetSource.LocalDateTime - DotNetDateTimeOffsetNow.Offset);
    end;

    procedure GetOffset(): Duration
    var
        DotNetDateTimeOffsetNow: DotNet DateTimeOffset;
    begin
        DotNetDateTimeOffsetNow := DotNetDateTimeOffsetNow.Now;
        exit(DotNetDateTimeOffsetNow.Offset);
    end;
}

