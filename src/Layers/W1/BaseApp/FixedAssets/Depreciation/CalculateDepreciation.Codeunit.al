// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

codeunit 5610 "Calculate Depreciation"
{

    trigger OnRun()
    begin
    end;

    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        CalculateNormalDepr: Codeunit "Calculate Normal Depreciation";
        CalculateCustom1Depr: Codeunit "Calculate Custom 1 Depr.";

    procedure Calculate(var DeprAmount: Decimal; var Custom1Amount: Decimal; var NumberOfDays: Integer; var Custom1NumberOfDays: Integer; FANo: Code[20]; DeprBookCode: Code[10]; UntilDate: Date; EntryAmounts: array[4] of Decimal; DateFromProjection: Date; DaysInPeriod: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculate(DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays, FANo, DeprBookCode, UntilDate, EntryAmounts, DateFromProjection, DaysInPeriod, IsHandled);
        if IsHandled then
            exit;

        DeprAmount := 0;
        Custom1Amount := 0;
        NumberOfDays := 0;
        Custom1NumberOfDays := 0;
        if not DeprBook.Get(DeprBookCode) then
            exit;
        if not FADeprBook.Get(FANo, DeprBookCode) then
            exit;

        CheckDeprDaysInFiscalYear(FADeprBook, DateFromProjection = 0D, UntilDate);

        if DeprBook."Use Custom 1 Depreciation" and
           (FADeprBook."Depr. Ending Date (Custom 1)" > 0D)
        then
            CalculateCustom1Depr.Calculate(
              DeprAmount, Custom1Amount, NumberOfDays,
              Custom1NumberOfDays, FANo, DeprBookCode, UntilDate,
              EntryAmounts, DateFromProjection, DaysInPeriod)
        else
            CalculateNormalDepr.Calculate(
              DeprAmount, NumberOfDays, FANo, DeprBookCode, UntilDate,
              EntryAmounts, DateFromProjection, DaysInPeriod);

        OnAfterCalcDeprYearCalculateAdditionalDepr2ndYear(DeprAmount, FANo, DeprBookCode);
    end;

    local procedure CheckDeprDaysInFiscalYear(FADeprBook: Record "FA Depreciation Book"; CheckDeprDays: Boolean; UntilDate: Date)
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
        FADateCalc: Codeunit "FA Date Calculation";
        FiscalYearBegin: Date;
        NoOfDeprDays: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDeprDaysInFiscalYear(FADeprBook, CheckDeprDays, UntilDate, IsHandled);
        if IsHandled then
            exit;

        if DeprBook."Allow more than 360/365 Days" or not CheckDeprDays then
            exit;
        if (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"Declining-Balance 1") or
           (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"DB1/SL")
        then
            FiscalYearBegin := FADateCalc.GetFiscalYear(DeprBook.Code, UntilDate);
        if not DeprBook."Use Accounting Period" then
            if DeprBook."Fiscal Year 365 Days" then
                NoOfDeprDays := 365
            else
                NoOfDeprDays := 360;
        if DepreciationCalc.DeprDays(
             FiscalYearBegin, UntilDate, DeprBook."Fiscal Year 365 Days", DeprBook."Use Accounting Period") > NoOfDeprDays
        then
            DeprBook.TestField("Allow more than 360/365 Days");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var DeprAmount: Decimal; var Custom1Amount: Decimal; var NumberOfDays: Integer; var Custom1NumberOfDays: Integer; FANo: Code[20]; DeprBookCode: Code[10]; UntilDate: Date; EntryAmounts: array[4] of Decimal; DateFromProjection: Date; DaysInPeriod: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDeprDaysInFiscalYear(FADeprBook: Record "FA Depreciation Book"; CheckDeprDays: Boolean; UntilDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDeprYearCalculateAdditionalDepr2ndYear(var DeprAmount: Decimal; FANo: code[20]; DepreBookCode: code[10])
    begin
    end;
}

