// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.Period;
using System.Utilities;

codeunit 5617 "FA Date Calculation"
{

    trigger OnRun()
    begin
    end;

    var
        DeprBook: Record "Depreciation Book";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'is later than %1';
        Text001: Label 'It was not possible to find a %1 in %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetFiscalYear(DeprBookCode: Code[10]; EndingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
        FAJnlLine: Record "FA Journal Line";
        FiscalYearStartDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFiscalYear(DeprBookCode, EndingDate, FiscalYearStartDate, IsHandled);
        if IsHandled then
            exit(FiscalYearStartDate);

        DeprBook.Get(DeprBookCode);
        if DeprBook."New Fiscal Year Starting Date" > 0D then begin
            if DeprBook."New Fiscal Year Starting Date" > EndingDate then
                DeprBook.FieldError(
                  "New Fiscal Year Starting Date",
                  StrSubstNo(Text000, FAJnlLine.FieldCaption("FA Posting Date")));
            exit(DeprBook."New Fiscal Year Starting Date");
        end;
        if AccountingPeriod.IsEmpty() then
            exit(CalcDate('<-CY>', EndingDate));
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Starting Date", 0D, EndingDate);
        if AccountingPeriod.FindLast() then
            exit(AccountingPeriod."Starting Date");

        Error(Text001, AccountingPeriod.FieldCaption("Starting Date"), AccountingPeriod.TableCaption);
    end;

    procedure CalculateDate(StartingDate: Date; NumberOfDays: Integer; Year365Days: Boolean): Date
    var
        Years: Integer;
        Days: Integer;
        Months: Integer;
        LocalDate: Date;
    begin
        if NumberOfDays <= 0 then
            exit(StartingDate);
        if Year365Days then
            exit(CalculateDate365(StartingDate, NumberOfDays));
        Years := Date2DMY(StartingDate, 3);
        Months := Date2DMY(StartingDate, 2);
        Days := Date2DMY(StartingDate, 1);
        if Date2DMY(StartingDate + 1, 1) = 1 then
            Days := 30;
        Days := Days + NumberOfDays;
        Months := Months + (Days div 30);
        Days := Days mod 30;
        if Days = 0 then begin
            Days := 30;
            Months := Months - 1;
        end;
        Years := Years + (Months div 12);
        Months := Months mod 12;
        if Months = 0 then begin
            Months := 12;
            Years := Years - 1;
        end;
        if (Months = 2) and (Days > 28) then begin
            Days := 28;
            LocalDate := DMY2Date(28, 2, Years) + 1;
            if Date2DMY(LocalDate, 1) = 29 then
                Days := 29;
        end;
        case Months of
            1, 3, 5, 7, 8, 10, 12:
                if Days = 30 then
                    Days := 31;
        end;
        exit(DMY2Date(Days, Months, Years));
    end;

    local procedure CalculateDate365(StartingDate: Date; NumberOfDays: Integer): Date
    var
        Calendar: Record Date;
        NoOfDays: Integer;
        EndingDate: Date;
        FirstDate: Boolean;
    begin
        Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
        Calendar.SetRange("Period Start", StartingDate, DMY2Date(31, 12, 9999));
        NoOfDays := 1;
        FirstDate := true;
        if Calendar.Find('-') then
            repeat
                if (not ((Date2DMY(Calendar."Period Start", 1) = 29) and (Date2DMY(Calendar."Period Start", 2) = 2))) or
                   FirstDate
                then
                    NoOfDays := NoOfDays + 1;
                FirstDate := false;
            until (Calendar.Next() = 0) or (NumberOfDays < NoOfDays);
        EndingDate := Calendar."Period Start";
        if (Date2DMY(EndingDate, 1) = 29) and (Date2DMY(EndingDate, 2) = 2) then
            EndingDate := EndingDate + 1;
        exit(EndingDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFiscalYear(DeprBookCode: Code[10]; EndingDate: Date; var FiscalYearStartDate: Date; var IsHandled: Boolean)
    begin
    end;
}

