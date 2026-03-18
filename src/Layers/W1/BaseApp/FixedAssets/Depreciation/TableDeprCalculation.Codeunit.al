// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Foundation.Period;

codeunit 5618 "Table Depr. Calculation"
{

    trigger OnRun()
    begin
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        DeprBook: Record "Depreciation Book";
        DeprTableHeader: Record "Depreciation Table Header";
        TempDeprTableBuffer: Record "Depreciation Table Buffer" temporary;
        DeprTableLine: Record "Depreciation Table Line";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        DaysInFiscalYear: Integer;
        StartingLimit: Integer;
        EndingLimit: Integer;
        FirstPointer: Integer;
        LastPointer: Integer;
        NumberOfDays: Integer;
        Percentage: Decimal;
        Year365Days: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        NoLinesDefinedErr: Label 'There are no lines defined for Depreciation Table Code %1.', Comment = '%1 = Depreciation Table Code';
        DifferentDatesErr: Label 'First User-Defined Depr. Date %1 and Accounting Period Starting Date %2 must not be different.', Comment = '%1 = Date; %2 = Date';
        UnbrokenSeqErr: Label 'must be an unbroken sequence';
        PeriodMustBeSpecifiedErr: Label 'Period must be specified in Accounting Period.';
        NumberOfDaysErr: Label 'The number of days in an accounting period must not be less than 5.';
        CannotBeErr: Label 'cannot be %1 when %2 is %3 in Depreciation Book %4', Comment = '%1 = Period Length, %2 = Field Caption, %3 = Field Value (Boolean, %4 = Depreciation Book Code';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetTablePercent(DeprBookCode: Code[10]; DeprTableCode: Code[10]; FirstUserDefinedDeprDate: Date; StartingDate: Date; EndingDate: Date): Decimal
    var
        IsHandled: Boolean;
    begin
        ClearAll();
        if (StartingDate = 0D) or (EndingDate = 0D) then
            exit(0);
        if (StartingDate > EndingDate) or (FirstUserDefinedDeprDate > StartingDate) then
            exit(0);
        DeprBook.Get(DeprBookCode);
        DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year";
        if DaysInFiscalYear = 0 then
            DaysInFiscalYear := 360;
        DeprTableHeader.Get(DeprTableCode);
        Year365Days := DeprBook."Fiscal Year 365 Days";
        IsHandled := false;
        OnBeforeValidateYear365Days(DeprBook, IsHandled);
        if not IsHandled then
            if Year365Days then begin
                if (DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Month) or
                   (DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Quarter)
                then
                    DeprTableHeader.FieldError(
                      "Period Length",
                      StrSubstNo(
                        CannotBeErr,
                        DeprTableHeader."Period Length",
                        DeprBook.FieldCaption("Fiscal Year 365 Days"),
                        DeprBook."Fiscal Year 365 Days",
                        DeprBook.Code));
                DaysInFiscalYear := 365;
            end;
        StartingLimit := DepreciationCalc.DeprDays(FirstUserDefinedDeprDate, StartingDate, Year365Days, DeprBook."Use Accounting Period");
        EndingLimit := DepreciationCalc.DeprDays(FirstUserDefinedDeprDate, EndingDate, Year365Days, DeprBook."Use Accounting Period");
        OnGetTablePercentOnAfterSetLimits(DeprBookCode, DeprTableCode, FirstUserDefinedDeprDate, StartingDate, EndingDate, StartingLimit, EndingLimit);

        if not Year365Days then
            if Date2DMY(StartingDate, 2) = 2 then
                if Date2DMY(StartingDate + 1, 1) = 1 then
                    StartingLimit := StartingLimit - (30 - Date2DMY(StartingDate, 1));
        CreateTableBuffer(FirstUserDefinedDeprDate);
        exit(CalculatePercent());
    end;

    local procedure CalculatePercent(): Decimal
    begin
        TempDeprTableBuffer.Find('-');
        LastPointer := 0;
        Percentage := 0;

        repeat
            FirstPointer := LastPointer + 1;
            LastPointer := FirstPointer + TempDeprTableBuffer."No. of Days in Period" - 1;
            NumberOfDays := 0;
            if not ((StartingLimit > LastPointer) or (EndingLimit < FirstPointer)) then begin
                if (StartingLimit < FirstPointer) and (EndingLimit <= LastPointer) then
                    NumberOfDays := EndingLimit - FirstPointer + 1;
                if (StartingLimit < FirstPointer) and (EndingLimit > LastPointer) then
                    NumberOfDays := TempDeprTableBuffer."No. of Days in Period";
                if (StartingLimit >= FirstPointer) and (EndingLimit <= LastPointer) then
                    NumberOfDays := EndingLimit - StartingLimit + 1;
                if (StartingLimit >= FirstPointer) and (EndingLimit > LastPointer) then
                    NumberOfDays := LastPointer - StartingLimit + 1;
                Percentage :=
                  Percentage + TempDeprTableBuffer."Period Depreciation %" * NumberOfDays /
                  TempDeprTableBuffer."No. of Days in Period";
            end;
        until TempDeprTableBuffer.Next() = 0;
        exit(Percentage / 100);
    end;

    local procedure CreateTableBuffer(FirstUserDefinedDeprDate: Date)
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        DaysInPeriod: Integer;
        TotalNoOfDays: Integer;
        PeriodNo: Integer;
    begin
        DeprTableLine.SetRange("Depreciation Table Code", DeprTableHeader.Code);
        if not DeprTableLine.Find('-') then
            Error(NoLinesDefinedErr, DeprTableHeader.Code);

        if DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Period then
            if AccountingPeriod.IsEmpty() then
                AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, FirstUserDefinedDeprDate)
            else begin
                AccountingPeriod.SetFilter("Starting Date", '>=%1', FirstUserDefinedDeprDate);
                if AccountingPeriod.Find('-') then;
                if AccountingPeriod."Starting Date" <> FirstUserDefinedDeprDate then
                    Error(DifferentDatesErr, FirstUserDefinedDeprDate, AccountingPeriod."Starting Date");
            end;
        case DeprTableHeader."Period Length" of
            DeprTableHeader."Period Length"::Period:
                DaysInPeriod := 0;
            DeprTableHeader."Period Length"::Month:
                DaysInPeriod := 30;
            DeprTableHeader."Period Length"::Quarter:
                DaysInPeriod := 90;
            DeprTableHeader."Period Length"::Year:
                DaysInPeriod := DaysInFiscalYear;
        end;
        repeat
            PeriodNo := PeriodNo + 1;
            if PeriodNo <> DeprTableLine."Period No." then
                DeprTableLine.FieldError("Period No.", UnbrokenSeqErr);
            if DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Period then begin
                FirstUserDefinedDeprDate := AccountingPeriod."Starting Date";
                if AccountingPeriod.Next() <> 0 then begin
                    DaysInPeriod :=
                      DepreciationCalc.DeprDays(
                        FirstUserDefinedDeprDate,
                        DepreciationCalc.Yesterday(AccountingPeriod."Starting Date", Year365Days, DeprBook."Use Accounting Period"),
                        Year365Days, DeprBook."Use Accounting Period");
                    OnCreateTableBufferOnAfterCalculateDaysInPeriod(DeprBook, AccountingPeriod, FirstUserDefinedDeprDate, Year365Days, DaysInPeriod);
                end;
                if DaysInPeriod = 0 then
                    Error(PeriodMustBeSpecifiedErr);
                if DaysInPeriod <= 5 then
                    Error(NumberOfDaysErr);
            end;
            InsertTableBuffer(DeprTableLine, TotalNoOfDays, DaysInPeriod, PeriodNo);
        until (DeprTableLine.Next() = 0) or (TotalNoOfDays > EndingLimit);

        while TotalNoOfDays < EndingLimit do begin
            TempDeprTableBuffer."Entry No." := TempDeprTableBuffer."Entry No." + 1;
            TempDeprTableBuffer.Insert();
            TotalNoOfDays := TotalNoOfDays + DaysInPeriod;
        end;
    end;

    local procedure InsertTableBuffer(var DeprTableLine: Record "Depreciation Table Line"; var TotalNoOfDays: Integer; DaysInPeriod: Integer; PeriodNo: Integer)
    begin
        TotalNoOfDays := TotalNoOfDays + DaysInPeriod;
        TempDeprTableBuffer."Entry No." := PeriodNo;
        TempDeprTableBuffer."No. of Days in Period" := DaysInPeriod;
        if DeprTableHeader."Total No. of Units" > 0 then
            TempDeprTableBuffer."Period Depreciation %" :=
              DeprTableLine."No. of Units in Period" * 100 / DeprTableHeader."Total No. of Units"
        else
            TempDeprTableBuffer."Period Depreciation %" := DeprTableLine."Period Depreciation %";
        TempDeprTableBuffer.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateYear365Days(DepreBook: Record "Depreciation Book"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTableBufferOnAfterCalculateDaysInPeriod(DeprBook: Record "Depreciation Book"; AccountingPeriod: Record "Accounting Period"; FirstUserDefinedDeprDate: Date; Year365Days: Boolean; var DaysInPeriod: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTablePercentOnAfterSetLimits(DeprBookCode: Code[10]; DeprTableCode: Code[10]; FirstUserDefinedDeprDate: Date; StartingDate: Date; EndingDate: Date; var StartingLimit: Integer; var EndingLimit: Integer)
    begin
    end;
}

