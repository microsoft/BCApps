// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Posting;

codeunit 5612 "Calculate Custom 1 Depr."
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "FA Posting Type Setup" = r;

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        DeprBookCode: Code[10];
        UntilDate: Date;
        Sign: Integer;
        FirstDeprDate: Date;
        DaysInFiscalYear: Integer;
        NumberOfDays: Integer;
        NumberOfDays4: Integer;
        DaysInPeriod: Integer;
        EntryAmounts: array[4] of Decimal;
        DateFromProjection: Date;
        UseDeprStartingDate: Boolean;
        BookValue: Decimal;
        MinusBookValue: Decimal;
        SalvageValue: Decimal;
        AcquisitionDate: Date;
        DisposalDate: Date;
        DeprMethod: Enum "FA Depreciation Method";
        DeprStartingDate: Date;
        FirstUserDefinedDeprDate: Date;
        SLPercent: Decimal;
        DBPercent: Decimal;
        FixedAmount: Decimal;
        DeprYears: Decimal;
        DeprTable: Code[10];
        FinalRoundingAmount: Decimal;
        EndingBookValue: Decimal;
        Custom1DeprStartingDate: Date;
        Custom1DeprUntil: Date;
        Custom1AccumPercent: Decimal;
        Custom1PercentThisYear: Decimal;
        Custom1PropertyClass: Option " ","Personal Property","Real Property";
        AcquisitionCost: Decimal;
        Custom1Depr: Decimal;
        ExtraDays: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'A depreciation entry must be posted on %2 = %3 for %1.';
        Text001: Label '%2 is positive on %3 = %4 for %1.';
        Text002: Label '%2 must not be 100 for %1.';
        Text003: Label '%2 is later than %3 for %1.';
        Text004: Label 'You must not specify %2 together with %3 = %4 for %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Calculate(var DeprAmount: Decimal; var Custom1DeprAmount: Decimal; var NumberOfDays3: Integer; var Custom1NumberOfDays3: Integer; FANo: Code[20]; DeprBookCode2: Code[10]; UntilDate2: Date; EntryAmounts2: array[4] of Decimal; DateFromProjection2: Date; DaysInPeriod2: Integer)
    var
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculate(DeprAmount, Custom1DeprAmount, NumberOfDays3, Custom1NumberOfDays3, FANo, DeprBookCode2, UntilDate2, EntryAmounts2, DateFromProjection2, DaysInPeriod2, IsHandled);
        if IsHandled then
            exit;

        ClearAll();
        DeprAmount := 0;
        Custom1DeprAmount := 0;
        NumberOfDays3 := 0;
        Custom1NumberOfDays3 := 0;
        DeprBookCode := DeprBookCode2;
        FA.Get(FANo);
        DeprBook.Get(DeprBookCode);
        if not FADeprBook.Get(FANo, DeprBookCode) then
            exit;
        OnAfterGetDeprBooks(DeprBook, FADeprBook);

        DeprBook.TestField("Fiscal Year 365 Days", false);
        for i := 1 to 4 do
            EntryAmounts[i] := EntryAmounts2[i];
        DateFromProjection := DateFromProjection2;
        DaysInPeriod := DaysInPeriod2;
        UntilDate := UntilDate2;
        DeprBook.TestField("Allow Depr. below Zero", false);
        FADeprBook.TestField("Fixed Depr. Amount below Zero", 0);
        FADeprBook.TestField("Depr. below Zero %", 0);
        FADeprBook.TestField("Use Half-Year Convention", false);
        DeprBook.TestField(
          "Periodic Depr. Date Calc.", DeprBook."Periodic Depr. Date Calc."::"Last Entry");

        FADeprBook.TestField("Property Class (Custom 1)");
        FAPostingTypeSetup.Get(
          DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 1");
        FAPostingTypeSetup.TestField("Part of Book Value", true);
        FAPostingTypeSetup.TestField("Part of Depreciable Basis", false);
        FAPostingTypeSetup.TestField("Include in Depr. Calculation", true);
        FAPostingTypeSetup.TestField(Sign, FAPostingTypeSetup.Sign::Credit);

        TransferValues();
        if not SkipRecord() then begin
            Sign := 1;
            if not FADeprBook."Use FA Ledger Check" then begin
                if DeprBook."Use FA Ledger Check" then
                    FADeprBook.TestField("Use FA Ledger Check", true);
                Sign :=
                  DepreciationCalc.GetCustom1Sign(
                    BookValue, AcquisitionCost, Custom1Depr, SalvageValue, MinusBookValue);
                if Sign = 0 then
                    exit;
                if Sign = -1 then
                    DepreciationCalc.GetNewCustom1Signs(
                      BookValue, AcquisitionCost, Custom1Depr, SalvageValue, MinusBookValue);
            end;
            if BookValue + SalvageValue <= 0 then
                exit;
            if (SalvageValue >= 0) and (BookValue <= EndingBookValue) then
                exit;
            if DateFromProjection > 0D then
                FirstDeprDate := DateFromProjection
            else begin
                FirstDeprDate := DepreciationCalc.GetFirstDeprDate(FANo, DeprBookCode, false, DeprBook."Use Accounting Period");
                if (FirstDeprDate > UntilDate) or (FirstDeprDate = 0D) then
                    exit;
                if (Custom1DeprUntil = 0D) or (FirstDeprDate <= Custom1DeprUntil) then begin
                    UseDeprStartingDate := DepreciationCalc.UseDeprStartingDate(FANo, DeprBookCode);
                    if UseDeprStartingDate then
                        FirstDeprDate := DeprStartingDate;
                end;
                if FirstDeprDate < DeprStartingDate then
                    FirstDeprDate := DeprStartingDate;
                if FirstDeprDate > UntilDate then
                    exit;
            end;
            if UseDeprStartingDate then
                ExtraDays := DepreciationCalc.DeprDays(
                    Custom1DeprStartingDate, DeprStartingDate, false, DeprBook."Use Accounting Period") - 1;
            if (Custom1DeprUntil > 0D) and (FirstDeprDate <= Custom1DeprUntil) and
               (UntilDate > Custom1DeprUntil)
            then
                Error(
                  Text000,
                  FAName(), FADeprBook.FieldCaption("Depr. Ending Date (Custom 1)"), Custom1DeprUntil);
            NumberOfDays := DepreciationCalc.DeprDays(FirstDeprDate, UntilDate, false, DeprBook."Use Accounting Period");

            if NumberOfDays <= 0 then
                exit;

            if DaysInPeriod > 0 then begin
                NumberOfDays4 := NumberOfDays;
                NumberOfDays := DaysInPeriod;
                ExtraDays := 0;
            end;

            CalcDeprBasis();

            case DeprMethod of
                DeprMethod::"Straight-Line":
                    DeprAmount := CalcSLAmount();
                DeprMethod::"Declining-Balance 1":
                    DeprAmount := CalcDB1Amount();
                DeprMethod::"Declining-Balance 2":
                    DeprAmount := CalcDB2Amount();
                DeprMethod::"DB1/SL":
                    DeprAmount := CalcDBSLAmount();
                DeprMethod::"DB2/SL",
              DeprMethod::Manual:
                    DeprAmount := 0;
                DeprMethod::"User-Defined":
                    DeprAmount := CalcCustom1Amount();
            end;

            OnCalculateOnBeforeCalcCustom1DeprAmount(DeprMethod, DeprAmount);

            Custom1DeprAmount := CalcCustom1DeprAmount();
            DepreciationCalc.AdjustCustom1(
              DeprBookCode, DeprAmount, Custom1DeprAmount, BookValue, SalvageValue,
              EndingBookValue, FinalRoundingAmount);
            DeprAmount := Sign * DeprAmount;
            Custom1DeprAmount := Sign * Custom1DeprAmount;
            NumberOfDays3 := NumberOfDays;
            Custom1NumberOfDays3 := NumberOfDays + ExtraDays;
        end;
    end;

    local procedure SkipRecord(): Boolean
    begin
        exit(
          (DisposalDate > 0D) or
          (AcquisitionDate = 0D) or
          (DeprMethod = DeprMethod::Manual) or
          (AcquisitionDate > UntilDate) or
          FA.Inactive or
          FA.Blocked);
    end;

    local procedure CalcSLAmount(): Decimal
    var
        RemainingLife: Decimal;
    begin
        if SLPercent > 0 then
            exit(-CalcDeprBasis() * CalcSLPercent() / 100);

        if FixedAmount > 0 then
            exit(-FixedAmount * NumberOfDays / DaysInFiscalYear);

        if DeprYears > 0 then begin
            if (Custom1DeprUntil = 0D) or (UntilDate > Custom1DeprUntil) then begin
                RemainingLife :=
                  (DeprYears * DaysInFiscalYear) -
                  DepreciationCalc.DeprDays(
                    DeprStartingDate, DepreciationCalc.Yesterday(FirstDeprDate, false, DeprBook."Use Accounting Period"),
                    false, DeprBook."Use Accounting Period");
                OnCalcSLAmountOnAfterSetRemainingLife(RemainingLife, Custom1PropertyClass, Custom1DeprStartingDate, Custom1DeprUntil);
                if RemainingLife < 1 then
                    exit(-BookValue);

                exit(-(BookValue + SalvageValue - MinusBookValue) * NumberOfDays / RemainingLife);
            end;
            exit(-AcquisitionCost * NumberOfDays / DeprYears / DaysInFiscalYear);
        end;
        exit(0);
    end;

    local procedure CalcDBSLAmount(): Decimal
    var
        SLAmount: Decimal;
        DBAmount: Decimal;
    begin
        if DeprMethod = DeprMethod::"DB1/SL" then
            DBAmount := CalcDB1Amount()
        else
            DBAmount := CalcDB2Amount();
        if UntilDate <= Custom1DeprUntil then
            exit(DBAmount);
        SLAmount := CalcSLAmount();
        if SLAmount < DBAmount then
            exit(SLAmount);

        exit(DBAmount)
    end;

    local procedure CalcDB2Amount(): Decimal
    begin
        exit(
          -(1 - Power(1 - DBPercent / 100, NumberOfDays / DaysInFiscalYear)) *
          (BookValue - MinusBookValue));
    end;

    local procedure CalcDB1Amount(): Decimal
    var
        DeprInFiscalYear: Decimal;
    begin
        if DateFromProjection = 0D then
            DeprInFiscalYear := DepreciationCalc.DeprInFiscalYear(FA."No.", DeprBookCode, UntilDate)
        else
            DeprInFiscalYear := EntryAmounts[3];
        exit(
          -(DBPercent / 100) * (NumberOfDays / DaysInFiscalYear) *
          (BookValue - MinusBookValue - Sign * DeprInFiscalYear));
    end;

    local procedure CalcCustom1Amount(): Decimal
    var
        TableDeprCalc: Codeunit "Table Depr. Calculation";
        Factor: Decimal;
    begin
        Factor := 1;
        if DaysInPeriod > 0 then
            Factor := DaysInPeriod / NumberOfDays4;
        exit(
          -TableDeprCalc.GetTablePercent(
            DeprBook.Code, DeprTable, FirstUserDefinedDeprDate, FirstDeprDate, UntilDate) *
          AcquisitionCost * Factor);
    end;

    local procedure CalcSLPercent(): Decimal
    var
        FractionOfFiscalYear: Decimal;
        CalcDeprYears: Decimal;
        YearsOfCustom1Depr: Decimal;
    begin
        FractionOfFiscalYear := NumberOfDays / DaysInFiscalYear;
        if SLPercent <= 0 then
            exit(0);
        if (Custom1PropertyClass = Custom1PropertyClass::"Real Property") or
           (Custom1DeprUntil = 0D) or (UntilDate <= Custom1DeprUntil)
        then
            exit(SLPercent * FractionOfFiscalYear);

        YearsOfCustom1Depr :=
          DepreciationCalc.DeprDays(
            Custom1DeprStartingDate, Custom1DeprUntil, false, DeprBook."Use Accounting Period")
          / DaysInFiscalYear;
        CalcDeprYears := 100 / SLPercent;
        if (CalcDeprYears - YearsOfCustom1Depr) <= 0.001 then
            exit(0);
        exit(100 * FractionOfFiscalYear / (CalcDeprYears - YearsOfCustom1Depr));
    end;

    local procedure CalcCustom1DeprPercent(): Decimal
    var
        MaxPercent: Decimal;
        CurrentPercent: Decimal;
    begin
        if (Custom1DeprUntil = 0D) or (UntilDate > Custom1DeprUntil) or (AcquisitionCost < 0.01) then
            exit(0);

        MaxPercent := Custom1AccumPercent - (-Custom1Depr * 100 / AcquisitionCost);
        if MaxPercent < 0 then
            exit(0);
        CurrentPercent := Custom1PercentThisYear * (NumberOfDays + ExtraDays) / DaysInFiscalYear;
        if CurrentPercent > MaxPercent then
            CurrentPercent := MaxPercent;
        exit(CurrentPercent);
    end;

    local procedure CalcCustom1DeprAmount(): Decimal
    begin
        exit(-AcquisitionCost * CalcCustom1DeprPercent() / 100);
    end;

    local procedure CalcDeprBasis(): Decimal
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        if (Custom1DeprUntil = 0D) or (UntilDate <= Custom1DeprUntil) then
            exit(AcquisitionCost);
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
        FALedgEntry.SetRange("FA No.", FA."No.");
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.SetRange("Part of Book Value", true);
        FALedgEntry.SetRange("FA Posting Date", 0D, Custom1DeprUntil);
        FALedgEntry.ReadIsolation(IsolationLevel::ReadCommitted);
        FALedgEntry.CalcSums(Amount);
        if (Sign = -1) and (FALedgEntry.Amount > 0) then
            Error(
              Text001,
              FAName(), FADeprBook.FieldCaption("Book Value"),
              FADeprBook.FieldCaption("Depr. Ending Date (Custom 1)"), Custom1DeprUntil);
        if DateFromProjection = 0D then
            exit(Abs(FALedgEntry.Amount));

        exit(EntryAmounts[4]);
    end;

    local procedure TransferValues()
    begin
        FADeprBook.TestField("Depreciation Starting Date");
        if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"User-Defined" then begin
            FADeprBook.TestField("Depreciation Table Code");
            FADeprBook.TestField("First User-Defined Depr. Date");
        end;
        case FADeprBook."Depreciation Method" of
            FADeprBook."Depreciation Method"::"Declining-Balance 1",
          FADeprBook."Depreciation Method"::"Declining-Balance 2":
                if FADeprBook."Declining-Balance %" >= 100 then
                    Error(Text002, FAName(), FADeprBook.FieldCaption("Declining-Balance %"));
        end;
        if DateFromProjection = 0D then begin
            FADeprBook.CalcFields("Book Value", "Acquisition Cost", "Custom 1", "Salvage Value");
            BookValue := FADeprBook."Book Value";
            Custom1Depr := FADeprBook."Custom 1";
        end else begin
            FADeprBook.CalcFields("Acquisition Cost", "Salvage Value");
            BookValue := EntryAmounts[1];
            Custom1Depr := EntryAmounts[2];
        end;
        MinusBookValue := DepreciationCalc.GetMinusBookValue(FA."No.", DeprBookCode, 0D, 0D);
        AcquisitionCost := FADeprBook."Acquisition Cost";
        SalvageValue := FADeprBook."Salvage Value";
        DeprMethod := FADeprBook."Depreciation Method";
        DeprStartingDate := FADeprBook."Depreciation Starting Date";
        DeprTable := FADeprBook."Depreciation Table Code";
        FirstUserDefinedDeprDate := FADeprBook."First User-Defined Depr. Date";
        if (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"User-Defined") and
           (FirstUserDefinedDeprDate > DeprStartingDate)
        then
            Error(
              Text003,
              FAName(), FADeprBook.FieldCaption("First User-Defined Depr. Date"), FADeprBook.FieldCaption("Depreciation Starting Date"));
        SLPercent := FADeprBook."Straight-Line %";
        DeprYears := FADeprBook."No. of Depreciation Years";
        DBPercent := FADeprBook."Declining-Balance %";
        if FADeprBook."Depreciation Ending Date" > 0D then begin
            if FADeprBook."Depreciation Starting Date" > FADeprBook."Depreciation Ending Date" then
                Error(
                  Text003,
                  FAName(), FADeprBook.FieldCaption("Depreciation Starting Date"), FADeprBook.FieldCaption("Depreciation Ending Date"));
            DeprYears :=
              DepreciationCalc.DeprDays(
                FADeprBook."Depreciation Starting Date", FADeprBook."Depreciation Ending Date", false,
                DeprBook."Use Accounting Period") / 360;
        end;
        FixedAmount := FADeprBook."Fixed Depr. Amount";
        FinalRoundingAmount := FADeprBook."Final Rounding Amount";
        if FinalRoundingAmount = 0 then
            FinalRoundingAmount := DeprBook."Default Final Rounding Amount";
        EndingBookValue := FADeprBook."Ending Book Value";
        if not FADeprBook."Ignore Def. Ending Book Value" and (EndingBookValue = 0) then
            EndingBookValue := DeprBook."Default Ending Book Value";
        AcquisitionDate := FADeprBook."Acquisition Date";
        DisposalDate := FADeprBook."Disposal Date";
        DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year";
        if DaysInFiscalYear = 0 then
            DaysInFiscalYear := 360;
        Custom1DeprStartingDate := FADeprBook."Depr. Starting Date (Custom 1)";
        Custom1DeprUntil := FADeprBook."Depr. Ending Date (Custom 1)";
        Custom1AccumPercent := FADeprBook."Accum. Depr. % (Custom 1)";
        Custom1PercentThisYear := FADeprBook."Depr. This Year % (Custom 1)";
        Custom1PropertyClass := FADeprBook."Property Class (Custom 1)";
        if Custom1DeprStartingDate = 0D then
            Custom1DeprStartingDate := DeprStartingDate;
        if Custom1DeprStartingDate > DeprStartingDate then
            Error(
              Text003,
              FAName(), FADeprBook.FieldCaption("Depr. Starting Date (Custom 1)"), FADeprBook.FieldCaption("Depreciation Starting Date"));
        if (Custom1DeprUntil > 0D) and (Custom1DeprUntil < DeprStartingDate) then
            Error(
              Text003,
              FAName(), FADeprBook.FieldCaption("Depreciation Starting Date"), FADeprBook.FieldCaption("Depr. Ending Date (Custom 1)"));
        if (DeprMethod = DeprMethod::"DB2/SL") and (Custom1DeprUntil > 0D) then
            Error(
              Text004,
              FAName(), FADeprBook.FieldCaption("Depr. Ending Date (Custom 1)"),
              FADeprBook.FieldCaption("Depreciation Method"), FADeprBook."Depreciation Method");
        OnAfterTransferValues(FA, DeprBook, FADeprBook, DeprMethod, UntilDate, SalvageValue, AcquisitionCost);
    end;

    local procedure FAName(): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValues(FixedAsset: Record "Fixed Asset"; DepreciationBook: Record "Depreciation Book"; FADepreciationBook: Record "FA Depreciation Book"; DeprMethod: Enum "FA Depr. Method Internal"; UntilDate: Date; var SalvageValue: Decimal; var AcquisitionCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var DeprAmount: Decimal; var Custom1DeprAmount: Decimal; var NumberOfDays3: Integer; var Custom1NumberOfDays3: Integer; FANo: Code[20]; DeprBookCode2: Code[10]; UntilDate2: Date; EntryAmounts2: array[4] of Decimal; DateFromProjection2: Date; DaysInPeriod2: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeprBooks(var DepreciationBook: Record "Depreciation Book"; var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeCalcCustom1DeprAmount(var FADepreciationMethod: Enum "FA Depreciation Method"; var DeprAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSLAmountOnAfterSetRemainingLife(var RemainingLife: Decimal; Custom1PropertyClass: Option " ","Personal Property","Real Property"; Custom1DeprStartingDate: Date; Custom1DeprUntil: Date)
    begin
    end;
}

