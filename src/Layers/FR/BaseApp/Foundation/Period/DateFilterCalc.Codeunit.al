// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using System;
using System.Utilities;

codeunit 358 "DateFilter-Calc"
{

    trigger OnRun()
    begin
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        StartDate: Date;
        Text10800: Label 'The selected date is not a starting period.';
        Text10801: Label 'The starting date must be the first day of a month.';
        Text10802: Label 'The ending date must be the last day of a month.';
        DateInsteadOfPeriodErr: Label 'You must enter a date interval, such as 01.01.17..31.01.17.';

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Fiscal Year %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CreateFiscalYearFilter(var "Filter": Text[30]; var Name: Text[30]; Date: Date; NextStep: Integer)
    begin
        CreateAccountingDateFilter(Filter, Name, true, Date, NextStep);
    end;

    procedure CreateAccountingPeriodFilter(var "Filter": Text[30]; var Name: Text[30]; Date: Date; NextStep: Integer)
    begin
        CreateAccountingDateFilter(Filter, Name, false, Date, NextStep);
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

    local procedure CreateAccountingDateFilter(var "Filter": Text[30]; var Name: Text[30]; FiscalYear: Boolean; Date: Date; NextStep: Integer)
    begin
        AccountingPeriod.Reset();
        if FiscalYear then
            AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod."Starting Date" := Date;
        if not AccountingPeriod.Find('=<>') then
            exit;
        if AccountingPeriod."Starting Date" > Date then
            NextStep := NextStep - 1;
        if NextStep <> 0 then
            if AccountingPeriod.Next(NextStep) <> NextStep then begin
                if NextStep < 0 then
                    Filter := '..' + Format(AccountingPeriod."Starting Date" - 1)
                else
                    Filter := Format(AccountingPeriod."Starting Date") + '..' + Format(DMY2Date(31, 12, 9999));
                Name := '...';
                exit;
            end;
        StartDate := AccountingPeriod."Starting Date";
        if FiscalYear then
            Name := StrSubstNo(Text000, Format(Date2DMY(StartDate, 3)))
        else
            Name := AccountingPeriod.Name;
        if AccountingPeriod.Next() <> 0 then
            Filter := Format(StartDate) + '..' + Format(AccountingPeriod."Starting Date" - 1)
        else begin
            Filter := Format(StartDate) + '..' + Format(DMY2Date(31, 12, 9999));
            Name := Name + '...';
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifiyDateFilter("Filter": Text[30])
    begin
        if Filter = ',,,' then
            Error(Text10800);
    end;

    [Scope('OnPrem')]
    procedure VerifMonthPeriod("Filter": Text[30])
    var
        Date: Record Date;
        FilterDate: Date;
        FilterPos: Integer;
    begin
        if CopyStr(Filter, StrLen(Filter) - 1, 2) = '..' then
            exit;
        // Begin Check
        FilterPos := StrPos(Filter, '..');

        if FilterPos = 0 then
            Error(DateInsteadOfPeriodErr);

        Evaluate(FilterDate, CopyStr(Filter, 1, FilterPos - 1));
        Date.SetRange("Period Type", Date."Period Type"::Month);
        Date.SetRange(Date."Period Start", FilterDate);
        if not Date.Find('-') then
            Error(Text10801);

        Date.Reset();
        // Ending check
        if FilterPos <> 0 then begin
            Evaluate(FilterDate, CopyStr(Filter, FilterPos + 2, 8));
            Date.SetRange("Period Type", Date."Period Type"::Month);
            Date.SetRange(Date."Period End", ClosingDate(FilterDate));
            if not Date.Find('-') then
                Error(Text10802);
        end;
    end;

    [Scope('OnPrem')]
    procedure ReturnEndingPeriod(StartPeriod: Date; PeriodType: Option Date,Week,Month,Quarter,Year): Date
    var
        PeriodDate: Record Date;
    begin
        PeriodDate.SetRange("Period Type", PeriodType);
        PeriodDate.SetRange("Period Start", StartPeriod);
        if PeriodDate.Find('-') then
            exit(PeriodDate."Period End")
        else
            exit(0D);
    end;
}

