// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.Period;

codeunit 5611 "Calculate Normal Depreciation"
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "FA Posting Type Setup" = r;

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        DeprBookCode: Code[10];
        DaysInFiscalYear: Integer;
        EntryAmounts: array[4] of Decimal;
        MinusBookValue: Decimal;
        DateFromProjection: Date;
        SkipOnZero: Boolean;
        UntilDate: Date;
        Sign: Integer;
        FirstDeprDate: Date;
        NumberOfDays: Integer;
        NumberOfDays2: Integer;
        DaysInPeriod: Integer;
        UseDeprStartingDate: Boolean;
        BookValue: Decimal;
        BookValue2: Decimal;
        DeprBasis: Decimal;
        SalvageValue: Decimal;
        SalvageValue2: Decimal;
        AcquisitionDate: Date;
        DisposalDate: Date;
        DeprMethod: Enum "FA Depr. Method Internal";
        DeprStartingDate: Date;
        FirstUserDefinedDeprDate: Date;
        SLPercent: Decimal;
        DBPercent: Decimal;
        FixedAmount: Decimal;
        DeprYears: Decimal;
        DeprTableCode: Code[10];
        FinalRoundingAmount: Decimal;
        EndingBookValue: Decimal;
        AmountBelowZero: Decimal;
        PercentBelowZero: Decimal;
        StartingDate: Date;
        EndingDate: Date;
        Factor: Decimal;
        UseHalfYearConvention: Boolean;
        NewYearDate: Date;
        DeprInTwoFiscalYears: Boolean;
        TempDeprAmount: Decimal;
        Year365Days: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Force No. of Days must only be specified if %1 %2 = %3.';
        Text001: Label '%2 must not be 100 for %1.';
        Text002: Label '%2 must be %3 if %4 %5 = %6 for %1.';
        Text003: Label '%2 must not be later than %3 for %1.';
        Text004: Label '%1 %2 must not be used together with the Half-Year Convention for %3.';
        Text005: Label '%1 must not be used together with the Half-Year Convention for %2.';
        Text006: Label '%1 must be %2 or later for %3.';
        Text007: Label '%1 must not be used together with %2 for %3.';
        Text008: Label '%1 must not be used together with %2 = %3 for %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Calculate(var DeprAmount: Decimal; var NumberOfDays4: Integer; FANo: Code[20]; DeprBookCode2: Code[10]; UntilDate2: Date; EntryAmounts2: array[4] of Decimal; DateFromProjection2: Date; DaysInPeriod2: Integer)
    var
        i: Integer;
        IsHandled: Boolean;
        StorageDecimal: Dictionary of [Text, Decimal];
        StorageInteger: Dictionary of [Text, Integer];
        StorageDate: Dictionary of [Text, Date];
        StorageCode: Dictionary of [Text, Code[10]];
    begin
        IsHandled := false;
        OnBeforeCalculate(DeprAmount, NumberOfDays4, FANo, DeprBookCode2, UntilDate2, EntryAmounts2, DateFromProjection2, DaysInPeriod2, IsHandled);
        if IsHandled then
            exit;

        ClearAll();
        DeprAmount := 0;
        NumberOfDays4 := 0;
        DeprBookCode := DeprBookCode2;
        FA.Get(FANo);
        DeprBook.Get(DeprBookCode);
        if not FADeprBook.Get(FANo, DeprBookCode) then
            exit;
        OnAfterGetDeprBooks(DeprBook, FADeprBook);

        UntilDate := UntilDate2;
        for i := 1 to 4 do
            EntryAmounts[i] := EntryAmounts2[i];
        DateFromProjection := DateFromProjection2;
        DaysInPeriod := DaysInPeriod2;

        if DaysInPeriod > 0 then
            if DeprBook."Periodic Depr. Date Calc." <> DeprBook."Periodic Depr. Date Calc."::"Last Entry" then begin
                DeprBook."Periodic Depr. Date Calc." := DeprBook."Periodic Depr. Date Calc."::"Last Entry";
                Error(
                  Text000,
                  DeprBook.TableCaption, DeprBook.FieldCaption("Periodic Depr. Date Calc."), DeprBook."Periodic Depr. Date Calc.");
            end;
        OnBeforeCalcTransferValueSetVariables(FirstDeprDate, Year365Days, UseDeprStartingDate, NumberOfDays2, UseHalfYearConvention);

        AssignVariablesToStorage(StorageDecimal, StorageInteger, StorageDate, StorageCode, DeprBookCode2, DateFromProjection2, UntilDate2, DaysInPeriod2, NumberOfDays4, DeprAmount);
        IsHandled := false;
        OnCalculateOnBeforeTransferValue(FANo, StorageDecimal, StorageInteger, StorageDate, StorageCode, EntryAmounts2, EntryAmounts, DeprMethod, Year365Days, IsHandled);
        if IsHandled then
            AssignStorageToVariables(StorageDecimal, StorageInteger, StorageDate, StorageCode, DeprBookCode2, DateFromProjection2, UntilDate2, DaysInPeriod2, NumberOfDays4, DeprAmount)
        else
            TransferValues();

        if not SkipRecord() then begin
            Sign := 1;
            if not FADeprBook."Use FA Ledger Check" then begin
                if DeprBook."Use FA Ledger Check" then
                    FADeprBook.TestField("Use FA Ledger Check", true);
                FADeprBook.TestField("Fixed Depr. Amount below Zero", 0);
                FADeprBook.TestField("Depr. below Zero %", 0);
                Sign := DepreciationCalc.GetSign(BookValue, DeprBasis, SalvageValue, MinusBookValue);
                if Sign = 0 then
                    exit;
                if Sign = -1 then
                    DepreciationCalc.GetNewSigns(BookValue, DeprBasis, SalvageValue, MinusBookValue);
            end;
            if (FADeprBook."Fixed Depr. Amount below Zero" > 0) or
               (FADeprBook."Depr. below Zero %" > 0)
            then
                FADeprBook.TestField("Use FA Ledger Check", true);

            IsHandled := false;
            OnCalculateOnBeforeAssignSkipOnZeroValue(FANo, FADeprBook, Sign, BookValue, DeprBasis, SalvageValue, MinusBookValue, SkipOnZero, EndingBookValue, IsHandled);
            if not IsHandled then begin
                if BookValue + SalvageValue <= 0 then
                    SkipOnZero := true;
                if (SalvageValue >= 0) and (BookValue <= EndingBookValue) then
                    SkipOnZero := true;
            end;

            if not
               (SkipOnZero and
                not DeprBook."Allow Depr. below Zero" and
                not DeprBook."Use FA Ledger Check")
            then begin
                IsHandled := false;
                OnAfterSkipOnZeroValue(DeprBook, SkipOnZero, IsHandled);
                if not IsHandled then
                    if SkipOnZero then
                        DeprMethod := DeprMethod::"Below Zero";

                DeprAmount := Sign * CalculateDeprAmount();

                IsHandled := false;
                OnAfterCalcFinalDeprAmount(FANo, FADeprBook, DeprBook, Sign, BookValue, DeprAmount, IsHandled, NumberOfDays2);
                if not IsHandled then
                    if Sign * DeprAmount > 0 then
                        DeprAmount := 0;

                NumberOfDays4 := NumberOfDays2;
            end;
        end;
    end;

    local procedure SkipRecord(): Boolean
    var
        IsHandled: Boolean;
        ExitValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipRecord(
            FA,
            DeprBook,
            DisposalDate,
            AcquisitionDate,
            UntilDate,
            DeprMethod,
            BookValue,
            DeprBasis,
            SalvageValue,
            MinusBookValue,
            ExitValue,
            IsHandled);

        if IsHandled then
            exit(ExitValue);

        exit(
          (DisposalDate > 0D) or
          (AcquisitionDate = 0D) or
          (DeprMethod = DeprMethod::Manual) or
          (AcquisitionDate > UntilDate) or
          FA.Inactive or
          FA.Blocked);
    end;

    local procedure ProcessDaysInPeriod()
    begin
        if DaysInPeriod > 0 then begin
            Factor := DaysInPeriod / NumberOfDays;
            NumberOfDays := DaysInPeriod;
        end;
        OnAfterProcessDaysInPeriod(NumberofDays, DaysInPeriod, Factor, FA, DeprBook, FirstDeprDate, UntilDate, Year365Days);
    end;

    local procedure CalculateDeprAmount(): Decimal
    var
        Amount: Decimal;
        IsHandled: Boolean;
    begin
        if DateFromProjection > 0D then
            FirstDeprDate := DateFromProjection
        else begin
            FirstDeprDate := DepreciationCalc.GetFirstDeprDate(FA."No.", DeprBookCode, Year365Days, DeprBook."Use Accounting Period");
            if FirstDeprDate > UntilDate then
                exit(0);
            UseDeprStartingDate := DepreciationCalc.UseDeprStartingDate(FA."No.", DeprBookCode);
            if UseDeprStartingDate then
                FirstDeprDate := DeprStartingDate;
        end;
        if FirstDeprDate < DeprStartingDate then
            FirstDeprDate := DeprStartingDate;

        IsHandled := false;
        OnBeforeNumberofDayCalculateNumberofDays(FA, DeprBook, NumberofDays, FirstDeprDate, UntilDate, Year365Days, IsHandled, FADeprBook);
        if not IsHandled then
            NumberOfDays := DepreciationCalc.DeprDays(FirstDeprDate, UntilDate, Year365Days, DeprBook."Use Accounting Period");

        Factor := 1;
        if NumberOfDays <= 0 then
            exit(0);
        ProcessDaysInPeriod();
        UseHalfYearConvention := SetHalfYearConventionMethod();

        UpdateDaysInFiscalYear(FA, DeprBook, NumberOfDays, DaysInFiscalYear, IsHandled);
        // Method Last Entry
        if UseDeprStartingDate or
           (DateFromProjection > 0D) or
           (DeprMethod = DeprMethod::"Below Zero") or
           (DeprBook."Periodic Depr. Date Calc." = DeprBook."Periodic Depr. Date Calc."::"Last Entry")
        then begin
            NumberOfDays2 := NumberOfDays;
            if UseHalfYearConvention then
                Amount := CalcHalfYearConventionDepr()
            else
                case DeprMethod of
                    DeprMethod::"Straight-Line":
                        Amount := CalcSLAmount();
                    DeprMethod::"Declining-Balance 1":
                        Amount := CalcDB1Amount();
                    DeprMethod::"Declining-Balance 2":
                        Amount := CalcDB2Amount();
                    DeprMethod::"DB1/SL",
                    DeprMethod::"DB2/SL":
                        Amount := CalcDBSLAmount();
                    DeprMethod::Manual:
                        Amount := 0;
                    DeprMethod::"User-Defined":
                        Amount := CalcUserDefinedAmount(UntilDate);
                    DeprMethod::"Below Zero":
                        Amount := DepreciationCalc.CalcRounding(DeprBookCode, CalcBelowZeroAmount());
                    DeprMethod::"Country Specific":
                        ;
                    // Reserved for implementation of country specific methods
                    else
                        OnCalculateDeprAmountOnDeprMethodCaseLastEntry(
                            FADeprBook, BookValue, DeprBasis, DeprYears, DaysInFiscalYear, NumberOfDays, Amount, DateFromProjection, UntilDate, DeprMethod);
                end;
            OnCalculateDeprAmountOnAfterAssignAmountLastEntry(FADeprBook, UntilDate, DateFromProjection, BookValue, UseHalfYearConvention, DaysInFiscalYear, NumberOfDays);
        end
        // Method Last Depreciation Entry
        else begin
            if UseHalfYearConvention then
                DeprBook.TestField(
                  "Periodic Depr. Date Calc.", DeprBook."Periodic Depr. Date Calc."::"Last Entry");
            Amount := 0;
            StartingDate := 0D;
            EndingDate := 0D;
            DepreciationCalc.GetDeprPeriod(
              FA."No.", DeprBookCode, UntilDate, StartingDate, EndingDate, NumberOfDays, Year365Days, DeprBook."Use Accounting Period");
            FirstDeprDate := StartingDate;
            NumberOfDays2 := DepreciationCalc.DeprDays(FirstDeprDate, UntilDate, Year365Days, DeprBook."Use Accounting Period");
            while NumberOfDays > 0 do begin
                DepreciationCalc.CalculateDeprInPeriod(
                  FA."No.", DeprBookCode, EndingDate, Amount, Sign,
                  BookValue, DeprBasis, SalvageValue, MinusBookValue);
                if DepreciationCalc.GetSign(
                     BookValue, DeprBasis, SalvageValue, MinusBookValue) <> 1
                then
                    exit(0);
                case DeprMethod of
                    DeprMethod::"Straight-Line":
                        Amount := Amount + CalcSLAmount();
                    DeprMethod::"Declining-Balance 1":
                        Amount := Amount + CalcDB1Amount();
                    DeprMethod::"Declining-Balance 2":
                        Amount := Amount + CalcDB2Amount();
                    DeprMethod::Manual:
                        Amount := 0;
                    DeprMethod::"User-Defined":
                        Amount := Amount + CalcUserDefinedAmount(EndingDate);
                    DeprMethod::"Country Specific":
                        ;
                    // Reserved for implementation of country specific
                    else
                        OnCalculateDeprAmountOnDeprMethodCaseLastDeprEntry(
                            FADeprBook, BookValue, DeprBasis, DeprYears, DaysInFiscalYear, NumberOfDays, Amount, DateFromProjection, UntilDate, DeprMethod);
                end;
                DepreciationCalc.GetDeprPeriod(
                  FA."No.", DeprBookCode, UntilDate, StartingDate, EndingDate, NumberOfDays, Year365Days, DeprBook."Use Accounting Period");
                FirstDeprDate := StartingDate;
            end;
        end;

        IsHandled := false;
        OnAfterCalculateFinalAmount(DeprBook, Amount, IsHandled, FA, UntilDate, BookValue);
        if not IsHandled then
            if Amount >= 0 then
                exit(0);

        IsHandled := false;
        OnCalculateDeprAmountOnBeforeCalculateDeprAmount(FA, SkipOnZero, DeprBookCode, Amount, BookValue2, SalvageValue2, EndingBookValue, FinalRoundingAmount, IsHandled);

        if IsHandled then
            exit(Amount);

        if not SkipOnZero then
            DepreciationCalc.AdjustDepr(
              DeprBookCode, Amount, Abs(BookValue2), -Abs(SalvageValue2),
              EndingBookValue, FinalRoundingAmount);

        OnAfterCalculateDeprAmount(
          FA, SkipOnZero, DeprBookCode, Amount, Abs(BookValue2), -Abs(SalvageValue2), EndingBookValue, FinalRoundingAmount);

        exit(Round(Amount));
    end;

    local procedure CalcTempDeprAmount(var DeprAmount: Decimal): Boolean
    begin
        DeprAmount := 0;
        if FADeprBook."Temp. Ending Date" = 0D then
            exit(false);
        if (FirstDeprDate <= FADeprBook."Temp. Ending Date") and (UntilDate > FADeprBook."Temp. Ending Date") then
            Error(
              Text006,
              FADeprBook.FieldCaption("Temp. Ending Date"),
              UntilDate,
              GetFAName());
        if FADeprBook."Temp. Ending Date" >= UntilDate then begin
            if FADeprBook."Use Half-Year Convention" then
                Error(
                  Text005,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  GetFAName());
            if FADeprBook."Use DB% First Fiscal Year" then
                Error(
                  Text007,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  FADeprBook.FieldCaption("Use DB% First Fiscal Year"),
                  GetFAName());
            if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"User-Defined" then
                Error(
                  Text008,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  FADeprBook.FieldCaption("Depreciation Method"),
                  FADeprBook."Depreciation Method",
                  GetFAName());
            if DeprMethod = DeprMethod::"Below Zero" then
                Error(
                  Text007,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  DeprBook.FieldCaption("Allow Depr. below Zero"),
                  GetFAName());
            DeprBook.TestField(
              "Periodic Depr. Date Calc.", DeprBook."Periodic Depr. Date Calc."::"Last Entry");
            DeprAmount := -(NumberOfDays / DaysInFiscalYear) * FADeprBook."Temp. Fixed Depr. Amount";
            exit(true)
        end;
        exit(false);
    end;

    local procedure CalcSLAmount(): Decimal
    var
        RemainingLife: Decimal;
        IsHandled: Boolean;
        Result: Decimal;
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            exit(TempDeprAmount);

        if SLPercent > 0 then begin
            Result := (-SLPercent / 100) * (NumberOfDays / DaysInFiscalYear) * DeprBasis;
            OnCalcSLAmountOnAfterCalcFromSLPercent(FA, FADeprBook, BookValue, DeprBasis, DaysInFiscalYear, NumberOfDays, SLPercent, Result);
            exit(Result);
        end;

        IsHandled := false;
        OnCalcSLAmountOnBeforeCheckFixedAmount(FA, FixedAmount, NumberOfDays, DaysInFiscalYear, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if FixedAmount > 0 then
            exit(-FixedAmount * NumberOfDays / DaysInFiscalYear);

        if DeprYears > 0 then begin
            if DeprBook."Use Accounting Period" then
                RemainingLife := FADeprBook."Depreciation Ending Date" - FADeprBook."Depreciation Starting Date" + 1 -
                  DepreciationCalc.DeprDays(DeprStartingDate, DepreciationCalc.Yesterday(FirstDeprDate,
                      Year365Days, DeprBook."Use Accounting Period"),
                    Year365Days, DeprBook."Use Accounting Period")
            else
                RemainingLife :=
                  (DeprYears * DaysInFiscalYear) -
                  DepreciationCalc.DeprDays(
                    DeprStartingDate, DepreciationCalc.Yesterday(FirstDeprDate, Year365Days, DeprBook."Use Accounting Period"),
                    Year365Days, DeprBook."Use Accounting Period");
            if RemainingLife < 1 then begin
                Result := -BookValue;
                OnCalcSLAmountOnAfterCalcResultForRemainingLifeExpired(FA, FADeprBook, BookValue, Result);
                exit(Result);
            end;

            IsHandled := false;
            OnAfterCalcSL(FA, FADeprBook, UntilDate, BookValue, DeprBasis, DeprYears, NumberOfDays, DaysInFiscalYear, Result, IsHandled, RemainingLife, FirstDeprDate);
            if IsHandled then
                exit(Result);

            exit(-(BookValue + SalvageValue - MinusBookValue) * NumberOfDays / RemainingLife);
        end;
        exit(0);
    end;

    procedure CalcDB1Amount() Result: Decimal
    var
        DeprInFiscalYear: Decimal;
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            exit(TempDeprAmount);

        if DateFromProjection = 0D then
            DeprInFiscalYear := DepreciationCalc.DeprInFiscalYear(FA."No.", DeprBookCode, UntilDate)
        else
            DeprInFiscalYear := EntryAmounts[3];
        if DeprInTwoFiscalYears then
            DeprInFiscalYear := 0;

        result := -(DBPercent / 100) * (NumberOfDays / DaysInFiscalYear) *
          (BookValue + SalvageValue - MinusBookValue - Sign * DeprInFiscalYear);

        OnAfterCalcDB1Amount(DBPercent, NumberOfDays, DaysInFiscalYear, BookValue, SalvageValue, MinusBookValue, Sign, DeprInFiscalYear, Result, FADeprBook, FirstDeprDate);
    end;

    local procedure CalcDB2Amount(): Decimal
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            exit(TempDeprAmount);

        exit(
          -(1 - Power(1 - DBPercent / 100, NumberOfDays / DaysInFiscalYear)) *
          (BookValue - MinusBookValue));
    end;

    local procedure CalcDBSLAmount(): Decimal
    var
        FADateCalc: Codeunit "FA Date Calculation";
        SLAmount: Decimal;
        DBAmount: Decimal;
    begin
        if DeprMethod = DeprMethod::"DB1/SL" then
            DBAmount := CalcDB1Amount()
        else
            DBAmount := CalcDB2Amount();
        if FADeprBook."Use DB% First Fiscal Year" then
            if FADateCalc.GetFiscalYear(DeprBookCode, UntilDate) =
               FADateCalc.GetFiscalYear(DeprBookCode, DeprStartingDate)
            then
                exit(DBAmount);
        SLAmount := CalcSLAmount();
        if SLAmount < DBAmount then
            exit(SLAmount);

        OnAfterCalcDBSLAmount(DBAmount, SLAmount, FADeprBook, DateFromProjection);
        exit(DBAmount)
    end;

    local procedure CalcUserDefinedAmount(EndingDate: Date): Decimal
    var
        TableDeprCalc: Codeunit "Table Depr. Calculation";
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            Error('');

        exit(
          -TableDeprCalc.GetTablePercent(DeprBook.Code, DeprTableCode,
            FirstUserDefinedDeprDate, FirstDeprDate, EndingDate) *
          DeprBasis * Factor);
    end;

    local procedure CalcBelowZeroAmount(): Decimal
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            Error('');

        if PercentBelowZero > 0 then
            exit((-PercentBelowZero / 100) * (NumberOfDays / DaysInFiscalYear) * DeprBasis);
        if AmountBelowZero > 0 then
            exit(-AmountBelowZero * NumberOfDays / DaysInFiscalYear);
        exit(0);
    end;

    local procedure TransferValues()
    var
        IsHandled: Boolean;
    begin
        FADeprBook.TestField("Depreciation Starting Date");
        if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"User-Defined" then begin
            FADeprBook.TestField("Depreciation Table Code");
            FADeprBook.TestField("First User-Defined Depr. Date");
        end;
        case FADeprBook."Depreciation Method" of
            FADeprBook."Depreciation Method"::"Declining-Balance 1",
          FADeprBook."Depreciation Method"::"Declining-Balance 2",
          FADeprBook."Depreciation Method"::"DB1/SL",
          FADeprBook."Depreciation Method"::"DB2/SL":
                if FADeprBook."Declining-Balance %" >= 100 then
                    Error(Text001, GetFAName(), FADeprBook.FieldCaption("Declining-Balance %"));
        end;
        if (DeprBook."Periodic Depr. Date Calc." = DeprBook."Periodic Depr. Date Calc."::"Last Depr. Entry") and
           (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::"Straight-Line")
        then begin
            FADeprBook."Depreciation Method" := FADeprBook."Depreciation Method"::"Straight-Line";
            Error(
              Text002,
              GetFAName(),
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              DeprBook.TableCaption(),
              DeprBook.FieldCaption("Periodic Depr. Date Calc."),
              DeprBook."Periodic Depr. Date Calc.");
        end;

        SetDeprMethod(FADeprBook);
        OnTransferValuesOnAfterSetDeprMethod(FADeprBook, UntilDate);

        if DateFromProjection = 0D then begin
            FADeprBook.CalcFields("Book Value");
            BookValue := FADeprBook."Book Value";
        end else
            BookValue := EntryAmounts[1];
        MinusBookValue := DepreciationCalc.GetMinusBookValue(FA."No.", DeprBookCode, 0D, 0D);
        FADeprBook.CalcFields("Depreciable Basis", "Salvage Value");
        DeprBasis := FADeprBook."Depreciable Basis";
        SalvageValue := FADeprBook."Salvage Value";

        OnAfterBookValueRecalculateBookValue(FA, DeprBook, FALedgEntry, DeprBasis, BookValue, EndingDate, FADeprBook."Disposal Date", FADeprBook, DateFromProjection, SalvageValue);

        BookValue2 := BookValue;
        SalvageValue2 := SalvageValue;
        DeprStartingDate := FADeprBook."Depreciation Starting Date";
        DeprTableCode := FADeprBook."Depreciation Table Code";
        FirstUserDefinedDeprDate := FADeprBook."First User-Defined Depr. Date";
        if (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"User-Defined") and
           (FirstUserDefinedDeprDate > DeprStartingDate)
        then
            Error(
              Text003,
              GetFAName(), FADeprBook.FieldCaption("First User-Defined Depr. Date"), FADeprBook.FieldCaption("Depreciation Starting Date"));

        SLPercent := FADeprBook."Straight-Line %";
        DBPercent := FADeprBook."Declining-Balance %";

        OnAfterBookValueCheckAddedDeprApplicable(FADeprBook, DeprBook, FALedgEntry, UntilDate, DBPercent, SLPercent);

        DeprYears := FADeprBook."No. of Depreciation Years";
        if FADeprBook."Depreciation Ending Date" > 0D then begin
            if FADeprBook."Depreciation Starting Date" > FADeprBook."Depreciation Ending Date" then
                Error(
                  Text003,
                  GetFAName(), FADeprBook.FieldCaption("Depreciation Starting Date"), FADeprBook.FieldCaption("Depreciation Ending Date"));
            DeprYears :=
              DepreciationCalc.DeprDays(
                FADeprBook."Depreciation Starting Date", FADeprBook."Depreciation Ending Date", false, DeprBook."Use Accounting Period") / 360;
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
        PercentBelowZero := FADeprBook."Depr. below Zero %";
        AmountBelowZero := FADeprBook."Fixed Depr. Amount below Zero";
        DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year";
        if DaysInFiscalYear = 0 then
            DaysInFiscalYear := 360;
        Year365Days := DeprBook."Fiscal Year 365 Days";

        IsHandled := false;
        OnAfterDaysinFYRecalculateDaysInFiscalYear(FADeprBook, DeprBook, UntilDate, DaysInFiscalYear, Year365Days, IsHandled);

        if Year365Days then begin
            if not IsHandled then
                DaysInFiscalYear := 365;

            DeprYears :=
              DepreciationCalc.DeprDays(
                FADeprBook."Depreciation Starting Date", FADeprBook."Depreciation Ending Date", true, false) / DaysInFiscalYear;
        end;

        OnAfterTransferValues2(FA, FADeprBook, Year365Days, DeprYears, DeprMethod, DeprBasis, BookValue);
    end;

    local procedure GetFAName(): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure SetHalfYearConventionMethod(): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetHalfYearConventionMethod(FADeprBook, DeprMethod, Year365Days, FirstDeprDate, NewYearDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not FADeprBook."Use Half-Year Convention" then
            exit(false);
        if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::Manual then
            exit(false);
        if DeprMethod = DeprMethod::"Below Zero" then
            exit(false);
        if AccountingPeriod.IsEmpty() then
            exit(false);

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter(
          "Starting Date", '>=%1',
          DepreciationCalc.ToMorrow(FADeprBook."Depreciation Starting Date", Year365Days, DeprBook."Use Accounting Period"));
        AccountingPeriod.FindFirst();
        NewYearDate := AccountingPeriod."Starting Date";
        if FirstDeprDate >= NewYearDate then
            exit(false);

        if DeprBook."No. of Days in Fiscal Year" <> 0 then
            DeprBook.TestField("No. of Days in Fiscal Year", 360);
        if DeprMethod in
           [DeprMethod::"Declining-Balance 2",
            DeprMethod::"DB2/SL",
            DeprMethod::"User-Defined"]
        then
            Error(
              Text004,
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              GetFAName());
        exit(true);
    end;

    local procedure CalcHalfYearConventionDepr(): Decimal
    var
        DeprAmount: Decimal;
        HalfYearPercent: Decimal;
        HalfYearFactor: Decimal;
        OriginalNumberOfDays: Integer;
        OriginalBookValue: Decimal;
        OriginalFirstDeprDate: Date;
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            Error('');

        HalfYearPercent := CalcHalfYearPercent();

        HalfYearFactor :=
          DaysInFiscalYear / 2 /
          DepreciationCalc.DeprDays(
            FADeprBook."Depreciation Starting Date",
            DepreciationCalc.Yesterday(NewYearDate, Year365Days, DeprBook."Use Accounting Period"),
            Year365Days, DeprBook."Use Accounting Period");
        DeprInTwoFiscalYears := UntilDate >= NewYearDate;

        OriginalNumberOfDays := NumberOfDays;
        OriginalBookValue := BookValue;
        OriginalFirstDeprDate := FirstDeprDate;

        if DeprInTwoFiscalYears then
            NumberOfDays :=
              DepreciationCalc.DeprDays(
                FirstDeprDate, DepreciationCalc.Yesterday(NewYearDate, Year365Days, DeprBook."Use Accounting Period"), Year365Days);
        if FixedAmount > 0 then
            DeprAmount := -FixedAmount * NumberOfDays / DaysInFiscalYear * HalfYearFactor
        else
            DeprAmount :=
              (-HalfYearPercent / 100) * (NumberOfDays / DaysInFiscalYear) * DeprBasis * HalfYearFactor;
        OnCalcHalfYearConventionDeprOnAfterFirstCalcDeprAmount(
            FADeprBook, FixedAmount, NumberOfDays, DaysInFiscalYear,
            HalfYearFactor, UntilDate, HalfYearPercent, NewYearDate, FirstDeprDate, DeprAmount);

        if DeprInTwoFiscalYears then begin
            NumberOfDays := DepreciationCalc.DeprDays(NewYearDate, UntilDate, Year365Days, DeprBook."Use Accounting Period");
            FirstDeprDate := NewYearDate;
            BookValue := BookValue + DeprAmount;
            case DeprMethod of
                DeprMethod::"Straight-Line":
                    DeprAmount := DeprAmount + CalcSLAmount();
                DeprMethod::"Declining-Balance 1":
                    DeprAmount := DeprAmount + CalcDB1Amount();
                DeprMethod::"DB1/SL":
                    DeprAmount := DeprAmount + CalcDBSLAmount();
                DeprMethod::"Country Specific":
                    ; // Reserved for implementation of country specific
            end;
        end;
        NumberOfDays := OriginalNumberOfDays;
        BookValue := OriginalBookValue;
        FirstDeprDate := OriginalFirstDeprDate;
        DeprInTwoFiscalYears := false;
        exit(DeprAmount);
    end;

    local procedure CalcHalfYearPercent() HalfYearPercent: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcHalfYearPercent(FADeprBook, NewYearDate, Year365Days, DaysInFiscalYear, DeprMethod, SLPercent, HalfYearPercent, IsHandled);
        if IsHandled then
            exit(HalfYearPercent);

        if (DeprMethod = DeprMethod::"Declining-Balance 1") or (DeprMethod = DeprMethod::"DB1/SL") then
            HalfYearPercent := DBPercent
        else
            if SLPercent > 0 then
                HalfYearPercent := SLPercent
            else
                if DeprYears > 0 then
                    HalfYearPercent :=
                      100 /
                      (DepreciationCalc.DeprDays(
                         NewYearDate, FADeprBook."Depreciation Ending Date", Year365Days, DeprBook."Use Accounting Period") +
                       DaysInFiscalYear / 2) * DaysInFiscalYear
                else
                    HalfYearPercent := 0;
    end;

    local procedure SetDeprMethod(FADeprBook: Record "FA Depreciation Book")
    begin
        DeprMethod := FADeprBook."Depreciation Method";
    end;

    local procedure AssignVariablesToStorage(
        var StorageDecimal: Dictionary of [Text, Decimal];
        var StorageInteger: Dictionary of [Text, Integer];
        var StorageDate: Dictionary of [Text, Date];
        var StorageCode: Dictionary of [Text, Code[10]];
        DeprBookCode2: Code[10];
        DateFromProjection2: Date;
        UntilDate2: Date;
        DaysInPeriod2: Integer;
        NumberOfDays4: Integer;
        DeprAmount: Decimal)
    var
        DeprBookCodeLbl: label 'DeprBookCode';
        DeprTableCodeLbl: Label 'DeprTableCode';
        DateFromProjectionLbl: Label 'DateFromProjection';
        EndDateDateLbl: Label 'EndDate';
        DeprStartingDateLbl: Label 'DeprStartingDate';
        FirstUserDefinedDeprDateLbl: Label 'FirstUserDefinedDeprDate';
        AcquisitionDateLbl: Label 'AcquisitionDate';
        DisposalDateLbl: Label 'DisposalDate';
        DaysInPeriodLbl: Label 'DaysInPeriod';
        NumberOfDays4Lbl: Label 'NumberOfDays4';
        DaysInFiscalYearLbl: Label 'DaysInFiscalYear';
        DeprAmountLbl: Label 'DeprAmount';
        BookValueLbl: Label 'BookValue';
        MinusBookValueLbl: Label 'MinusBookValue';
        DeprBasisLbl: Label 'DeprBasis';
        SalvageValueLbl: Label 'SalvageValue';
        CopyBookValueLbl: Label 'CopyBookValue';
        SLPercentLbl: Label 'SLPercent';
        DBPercentLbl: Label 'DBPercent';
        DeprYearsLbl: Label 'DeprYears';
        FixedAmountLbl: Label 'FixedAmount';
        FinalRoundingAmountLbl: Label 'FinalRoundingAmount';
        EndingBookValueLbl: Label 'EndingBookValue';
        PercentBelowZeroLbl: Label 'PercentBelowZero';
        AmountBelowZeroLbl: Label 'AmountBelowZero';
    begin
        Clear(StorageCode);
        Clear(StorageDate);
        Clear(StorageDecimal);
        Clear(StorageInteger);

        StorageCode.Set(DeprBookCodeLbl, DeprBookCode2);
        StorageCode.Set(DeprTableCodeLbl, DeprTableCode);

        StorageDate.Set(DateFromProjectionLbl, DateFromProjection2);
        StorageDate.Set(EndDateDateLbl, UntilDate2);
        StorageDate.Set(DeprStartingDateLbl, DeprStartingDate);
        StorageDate.Set(FirstUserDefinedDeprDateLbl, FirstUserDefinedDeprDate);
        StorageDate.Set(AcquisitionDateLbl, AcquisitionDate);
        StorageDate.Set(DisposalDateLbl, DisposalDate);

        StorageInteger.Set(DaysInPeriodLbl, DaysInPeriod2);
        StorageInteger.Set(NumberOfDays4Lbl, NumberOfDays4);
        StorageInteger.Set(DaysInFiscalYearLbl, DaysInFiscalYear);

        StorageDecimal.Set(DeprAmountLbl, DeprAmount);
        StorageDecimal.Set(BookValueLbl, BookValue);
        StorageDecimal.Set(MinusBookValueLbl, MinusBookValue);
        StorageDecimal.Set(DeprBasisLbl, DeprBasis);
        StorageDecimal.Set(SalvageValueLbl, SalvageValue);
        StorageDecimal.set(CopyBookValueLbl, BookValue2);
        StorageDecimal.set(SLPercentLbl, SLPercent);
        StorageDecimal.Set(DBPercentLbl, DBPercent);
        StorageDecimal.Set(DeprYearsLbl, DeprYears);
        StorageDecimal.Set(FixedAmountLbl, FixedAmount);
        StorageDecimal.Set(FinalRoundingAmountLbl, FinalRoundingAmount);
        StorageDecimal.Set(EndingBookValueLbl, EndingBookValue);
        StorageDecimal.Set(PercentBelowZeroLbl, PercentBelowZero);
        StorageDecimal.Set(AmountBelowZeroLbl, AmountBelowZero);
    end;

    local procedure AssignStorageToVariables(
        var StorageDecimal: Dictionary of [Text, Decimal];
        var StorageInteger: Dictionary of [Text, Integer];
        var StorageDate: Dictionary of [Text, Date];
        var StorageCode: Dictionary of [Text, Code[10]];
        var DeprBookCode2: Code[10];
        var DateFromProjection2: Date;
        var UntilDate2: Date;
        var DaysInPeriod2: Integer;
        var NumberOfDays4: Integer;
        var DeprAmount: Decimal)
    var
        DeprBookCodeLbl: label 'DeprBookCode';
        DeprTableCodeLbl: Label 'DeprTableCode';
        DateFromProjectionLbl: Label 'DateFromProjection';
        EndDateLbl: Label 'EndDate';
        DeprStartingDateLbl: Label 'DeprStartingDate';
        FirstUserDefinedDeprDateLbl: Label 'FirstUserDefinedDeprDate';
        AcquisitionDateLbl: Label 'AcquisitionDate';
        DisposalDateLbl: Label 'DisposalDate';
        DaysInPeriodLbl: Label 'DaysInPeriod';
        NumberOfDays4Lbl: Label 'NumberOfDays4';
        DaysInFiscalYearLbl: Label 'DaysInFiscalYear';
        DeprAmountLbl: Label 'DeprAmount';
        BookValueLbl: Label 'BookValue';
        MinusBookValueLbl: Label 'MinusBookValue';
        DeprBasisLbl: Label 'DeprBasis';
        SalvageValueLbl: Label 'SalvageValue';
        CopyBookValueLbl: Label 'CopyBookValue';
        SLPercentLbl: Label 'SLPercent';
        DBPercentLbl: Label 'DBPercent';
        DeprYearsLbl: Label 'DeprYears';
        FixedAmountLbl: Label 'FixedAmount';
        FinalRoundingAmountLbl: Label 'FinalRoundingAmount';
        EndingBookValueLbl: Label 'EndingBookValue';
        PercentBelowZeroLbl: Label 'PercentBelowZero';
        AmountBelowZeroLbl: Label 'AmountBelowZero';
    begin
        DeprBookCode2 := StorageCode.Get(DeprBookCodeLbl);
        DeprTableCode := StorageCode.Get(DeprTableCodeLbl);

        DateFromProjection2 := StorageDate.Get(DateFromProjectionLbl);
        UntilDate2 := StorageDate.Get(EndDateLbl);
        DeprStartingDate := StorageDate.Get(DeprStartingDateLbl);
        FirstUserDefinedDeprDate := StorageDate.Get(FirstUserDefinedDeprDateLbl);
        AcquisitionDate := StorageDate.Get(AcquisitionDateLbl);
        DisposalDate := StorageDate.Get(DisposalDateLbl);

        DaysInPeriod2 := StorageInteger.Get(DaysInPeriodLbl);
        NumberOfDays4 := StorageInteger.Get(NumberOfDays4Lbl);
        DaysInFiscalYear := StorageInteger.Get(DaysInFiscalYearLbl);

        DeprAmount := StorageDecimal.Get(DeprAmountLbl);
        BookValue := StorageDecimal.Get(BookValueLbl);
        MinusBookValue := StorageDecimal.Get(MinusBookValueLbl);
        DeprBasis := StorageDecimal.Get(DeprBasisLbl);
        SalvageValue := StorageDecimal.Get(SalvageValueLbl);
        BookValue2 := StorageDecimal.Get(CopyBookValueLbl);
        SLPercent := StorageDecimal.Get(SLPercentLbl);
        DBPercent := StorageDecimal.Get(DBPercentLbl);
        DeprYears := StorageDecimal.Get(DeprYearsLbl);
        FixedAmount := StorageDecimal.Get(FixedAmountLbl);
        FinalRoundingAmount := StorageDecimal.Get(FinalRoundingAmountLbl);
        EndingBookValue := StorageDecimal.Get(EndingBookValueLbl);
        PercentBelowZero := StorageDecimal.Get(PercentBelowZeroLbl);
        AmountBelowZero := StorageDecimal.Get(AmountBelowZeroLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var DeprAmount: Decimal; var NumberOfDays4: Integer; FANo: Code[20]; DeprBookCode2: Code[10]; UntilDate2: Date; EntryAmounts2: array[4] of Decimal; DateFromProjection2: Date; DaysInPeriod2: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeprBooks(var DepreciationBook: Record "Depreciation Book"; var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateOnBeforeTransferValue(
        FANo: Code[20];
        var StorageDecimal: Dictionary of [Text, Decimal];
        var StorageInterger: Dictionary of [Text, Integer];
        var StorageDate: Dictionary of [Text, Date];
        var StorageCode: Dictionary of [Text, Code[10]];
        var EntryAmounts2: array[4] of Decimal;
        var EntryAmounts: array[4] of Decimal;
        var DeprMethod: Enum "FA Depr. Method Internal";
        var Year365Days: Boolean;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSkipRecord(
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        DisposalDate: date;
        AcquisitionDate: date;
        UntilDate: Date;
        FADeprMethod: Enum "FA Depreciation Method";
        BookValue: Decimal;
        DeprBasis: Decimal;
        SalvageValue: Decimal;
        MinusBookValue: Decimal;
        var ReturnValue: Boolean;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTransferValueSetVariables(
        var FirstDate: date;
        var Year365Days: Boolean;
        var UseDeprStartingDate: Boolean;
        var NumberOfDays2: integer;
        var UseHalfYearConvention: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNumberofDayCalculateNumberofDays(
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        var NumberofDays: Integer;
        FirstDeprDate: date;
        var UntilDate: Date;
        Year365Days: Boolean;
        var IsHandled: Boolean;
        FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure UpdateDaysInFiscalYear(
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        var NumberofDays: Integer;
        var DaysInFiscalYear: Integer;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBookValueRecalculateBookValue(FixedAsset: Record "Fixed Asset"; DeprBook: Record "Depreciation Book"; FAledgEntry2: Record "FA Ledger Entry"; var DeprBasis: Decimal; var BookValue: Decimal; var DeprEndingDate: Date; DisposalDate: Date; var FADepreciationBook: Record "FA Depreciation Book"; DateFromProjection: Date; var SalvageValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBookValueCheckAddedDeprApplicable(
        FADepBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        UntilDate: Date;
        var DBPercent: Decimal;
        var SlPercent: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDaysinFYRecalculateDaysInFiscalYear(
        FADepBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        UntilDate: Date;
        var DaysInFiscalYear: Integer;
        Year365Days: Boolean;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateFinalAmount(DepreBook: Record "Depreciation Book"; var Amount: Decimal; var IsHandled: Boolean; FA: Record "Fixed Asset"; UntilDate: Date; BookValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSkipOnZeroValue(DepreBook: Record "Depreciation Book"; var SkipOnZero: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcFinalDeprAmount(FANo: Code[20]; FADeprBook: Record "FA Depreciation Book"; DepreBook: Record "Depreciation Book"; Sign: Integer; BookValue: Decimal; var DeprAmount: Decimal; var IsHandled: Boolean; var NumberOfDays: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDeprAmount(FixedAsset: Record "Fixed Asset"; SkipOnZero: Boolean; DeprBookCode: Code[20]; var Amount: Decimal; BookValue: Decimal; SalvageValue: Decimal; EndingBookValue: Decimal; FinalRoundingAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSL(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; BookValue: Decimal; DeprBasis: Decimal; DeprYears: Decimal; NumberOfDays: Integer; DaysInFiscalYear: Integer; var ExitValue: Decimal; var IsHandled: Boolean; var RemainingLife: Decimal; var FirstDeprDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDB1Amount(DBPercent: Decimal; NumberOfDays: Integer; DaysInFiscalYear: Integer; BookValue: Decimal; SalvageValue: Decimal; MinusBookValue: Decimal; Sign: Integer; DeprInFiscalYear: Decimal; var Result: Decimal; FADepreciationBook: Record "FA Depreciation Book"; FirstDeprDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValues2(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; Year365Days: Boolean; var DeprYears: Decimal; var DeprMethod: Enum "FA Depr. Method Internal"; var DeprBasis: Decimal; var BookValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDaysInPeriod(var NumberofDays: Integer; var DaysInPeriod: Integer; var Factor: Decimal; FixedAsset: Record "Fixed Asset"; DeprBook: Record "Depreciation Book"; var FirstDeprDate: date; UntilDate: Date; Year365Days: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcHalfYearPercent(FADeprBook: Record "FA Depreciation Book"; NewYearDate: Date; Year365Days: Boolean; DaysInFiscalYear: Integer; DeprMethod: Enum "FA Depr. Method Internal"; SLPercent: Decimal; var HalfYearPercent: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateDeprAmountOnAfterAssignAmountLastEntry(FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; DateFromProjection: Date; BookValue: Decimal; UseHalfYearConvention: Boolean; DaysInFiscalYear: Integer; NumberOfDays: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSLAmountOnAfterCalcFromSLPercent(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; DeprBasis: Decimal; DaysInFiscalYear: Integer; NumberOfDays: Integer; SLPercent: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSLAmountOnAfterCalcResultForRemainingLifeExpired(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateDeprAmountOnDeprMethodCaseLastEntry(FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; DeprBasis: Decimal; DeprYears: Decimal; DaysInFiscalYear: Integer; NumberOfDays: Integer; var Amount: Decimal; DateFromProjection: Date; UntilDate: Date; DeprMethod: Enum "FA Depr. Method Internal")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateDeprAmountOnDeprMethodCaseLastDeprEntry(FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; DeprBasis: Decimal; DeprYears: Decimal; DaysInFiscalYear: Integer; NumberOfDays: Integer; var Amount: Decimal; DateFromProjection: Date; UntilDate: Date; DeprMethod: Enum "FA Depr. Method Internal")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcHalfYearConventionDeprOnAfterFirstCalcDeprAmount(FADeprBook: Record "FA Depreciation Book"; FixedAmount: Decimal; NumberOfDays: Integer; DaysInFiscalYear: Integer; HalfYearFactor: Decimal; UntilDate: Date; HalfYearPercent: Decimal; NewYearDate: Date; FirstDeprDate: Date; var DeprAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferValuesOnAfterSetDeprMethod(var FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateDeprAmountOnBeforeCalculateDeprAmount(FixedAsset: Record "Fixed Asset"; SkipOnZero: Boolean; DeprBookCode: Code[20]; var Amount: Decimal; BookValue: Decimal; SalvageValue2: Decimal; EndingBookValue: Decimal; FinalRoundingAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeAssignSkipOnZeroValue(FANo: Code[20]; FADepreciationBook: Record "FA Depreciation Book"; var Sign: Integer; var BookValue: Decimal; var DeprBasis: Decimal; var SalvageValue: Decimal; var MinusBookValue: Decimal; var SkipOnZero: Boolean; EndingBookValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDBSLAmount(var DBAmount: Decimal; SLAmount: Decimal; FADepreciationBook: Record "FA Depreciation Book"; DateFromProjection: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSLAmountOnBeforeCheckFixedAmount(FixedAsset: Record "Fixed Asset"; FixedAmount: Decimal; NumberOfDays: Integer; DaysInFiscalYear: Integer; var IsHandled: Boolean; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetHalfYearConventionMethod(FADeprBook: Record "FA Depreciation Book"; DeprMethod: Enum "FA Depr. Method Internal"; Year365Days: Boolean; FirstDeprDate: Date; NewYearDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

