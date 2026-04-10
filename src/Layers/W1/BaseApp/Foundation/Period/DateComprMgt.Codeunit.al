// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using System.Reflection;

codeunit 356 DateComprMgt
{
    trigger OnRun()
    begin
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        FiscYearDate: array[2] of Date;
        AccountingPeriodDate: array[2] of Date;
        Date1: Date;
        Date2: Date;
        ReportNotFoundLbl: Label 'Report not found';

    procedure GetDateFilter(Date: Date; DateComprReg: Record "Date Compr. Register"; CheckFiscYearEnd: Boolean): Text[250]
    begin
        if (Date = 0D) or (Date = ClosingDate(Date)) then
            exit(Format(Date));

        if (Date < FiscYearDate[1]) or (Date > FiscYearDate[2]) then begin
            FiscYearDate[1] := AccountingPeriod.GetFiscalYearStartDate(Date);
            FiscYearDate[2] := AccountingPeriod.GetFiscalYearEndDate(AccountingPeriod, Date);
            if CheckFiscYearEnd then
                AccountingPeriod.TestField("Date Locked", true);
        end;

        if DateComprReg."Period Length" = DateComprReg."Period Length"::Day then
            exit(Format(Date));

        Date1 := DateComprReg."Starting Date";
        Date2 := DateComprReg."Ending Date";
        Maximize(Date1, FiscYearDate[1]);
        Minimize(Date2, FiscYearDate[2]);

        Maximize(Date1, CalcDate('<-CY>', Date));
        Minimize(Date2, CalcDate('<CY>', Date));
        if DateComprReg."Period Length" = DateComprReg."Period Length"::Year then
            exit(StrSubstNo('%1..%2', Date1, Date2));

        if (Date < AccountingPeriodDate[1]) or (Date > AccountingPeriodDate[2]) then begin
            AccountingPeriod."Starting Date" := Date;
            AccountingPeriod.Find('=<');
            AccountingPeriodDate[1] := AccountingPeriod."Starting Date";
            AccountingPeriod.Next();
            AccountingPeriodDate[2] := AccountingPeriod."Starting Date" - 1;
        end;

        if DateComprReg."Period Length" = DateComprReg."Period Length"::Period then begin
            Maximize(Date1, AccountingPeriodDate[1]);
            Minimize(Date2, AccountingPeriodDate[2]);
            exit(StrSubstNo('%1..%2', Date1, Date2));
        end;

        Maximize(Date1, CalcDate('<-CQ>', Date));
        Minimize(Date2, CalcDate('<CQ>', Date));
        if DateComprReg."Period Length" = DateComprReg."Period Length"::Quarter then
            exit(StrSubstNo('%1..%2', Date1, Date2));

        Maximize(Date1, CalcDate('<-CM>', Date));
        Minimize(Date2, CalcDate('<CM>', Date));
        if DateComprReg."Period Length" = DateComprReg."Period Length"::Month then
            exit(StrSubstNo('%1..%2', Date1, Date2));

        Maximize(Date1, CalcDate('<-CW>', Date));
        Minimize(Date2, CalcDate('<CW>', Date));
        exit(StrSubstNo('%1..%2', Date1, Date2));
    end;

    local procedure Maximize(var Date: Date; NewDate: Date)
    begin
        if Date < NewDate then
            Date := NewDate;
    end;

    local procedure Minimize(var Date: Date; NewDate: Date)
    begin
        if Date > NewDate then
            Date := NewDate;
    end;

    procedure GetReportName(ReportID: Integer): Text
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportMetadata.ReadPermission() then
            if ReportMetadata.Get(ReportID) then
                exit(ReportMetadata.Caption);
        exit(ReportNotFoundLbl);
    end;
}

