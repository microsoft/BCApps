codeunit 134490 "ERM Matrix Management"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Matrix]
    end;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryAccSchedule: Codeunit "Library - Account Schedule";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        WrongCaptionRangeMsg: Label 'Wrong CaptionRange length';
        WrongNumberOfColumnsMsg: Label 'Wrong NumberOfLines value';
        DimTotalingTxt: Label '%1|%2', Comment = '%1 - Field Value; %2 - Field Value';
        WrongDimTotalingErr: Label 'Wrong dimension totaling filter.';
        WrongRoundedValueErr: Label 'Wrong value for %1 rounding';
        WrongFormatValueErr: Label 'Wrong value format for %1 rounding';

    [Test]
    [Scope('OnPrem')]
    procedure EmptyCaptionSet()
    var
        CaptionSet: array[32] of Text[80];
        FirstColumn: Text;
        LastColumn: Text;
        DimensionCode: Code[20];
        "Count": Integer;
    begin
        // Verify filtered dimension values when applied filter does not allow any entry

        InitDimensionValues(DimensionCode, Count, CaptionSet, FirstColumn, LastColumn);
        VerifyDimToCaptions('', 0, DimensionCode, FirstColumn, LastColumn, '=0', CaptionSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleEntryInCaptionSet()
    var
        DimensionValue: Record "Dimension Value";
        FirstColumn: Text;
        LastColumn: Text;
        CaptionSet: array[32] of Text[80];
        DimensionCode: Code[20];
        "Count": Integer;
    begin
        // Verify filtered dimension values when applied filter allows only single entry

        InitDimensionValues(DimensionCode, Count, CaptionSet, FirstColumn, LastColumn);
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.FindFirst();
        VerifyDimToCaptions(DimensionValue.Name, 1, DimensionCode, FirstColumn, LastColumn, '=' + DimensionValue.Code, CaptionSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleEntriesInCaptionSet()
    var
        CaptionSet: array[32] of Text[80];
        "Filter": Text;
        FirstDimensionValue: Text;
        LastDimensionValue: Text;
        FirstColumn: Text;
        LastColumn: Text;
        DimensionCode: Code[20];
        "Count": Integer;
        DimensionValueCount: Integer;
        ExpectedCaptionRange: Text;
    begin
        // Verify CaptionRange and NumberOfColumns initialization and CaptionSet filling on multiple DimensionValue.
        // But the number of DimensionValue does not exceed uppper bound of CaptionSet array

        InitDimensionValues(DimensionCode, Count, CaptionSet, FirstColumn, LastColumn);
        BuildDimensionValueFilter(DimensionValueCount, Filter, FirstDimensionValue, LastDimensionValue, Count, DimensionCode);
        ExpectedCaptionRange := FirstDimensionValue + '..' + LastDimensionValue;
        VerifyDimToCaptions(ExpectedCaptionRange, DimensionValueCount, DimensionCode, FirstColumn, LastColumn, Filter, CaptionSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtraEntriesInDimensionValues()
    var
        CaptionSet: array[32] of Text[80];
        FirstColumn: Text;
        LastColumn: Text;
        DimensionCode: Code[20];
        "Count": Integer;
    begin
        // Verify CaptionRange and NumberOfColumns initialization and CaptionSet filling on DimensionValue table.
        // The number of DimensionValue does not exceed uppper bound of CaptionSet array

        InitDimensionValues(DimensionCode, Count, CaptionSet, FirstColumn, LastColumn);
        VerifyDimToCaptions(
          CalcExpectedCaptionRange(CaptionSet, DimensionCode),
          ArrayLen(CaptionSet), DimensionCode, FirstColumn, LastColumn, '', CaptionSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionTotaling()
    var
        TotalingDimValue: Record "Dimension Value";
        CaptionSet: array[32] of Text[80];
        FirstColumn: Text;
        LastColumn: Text;
        DimensionCode: Code[20];
        "Count": Integer;
    begin
        // Verify that amount and drill down of G/L Budget Matrix page works correctly when using dimension for "Show as Columns" option

        InitDimensionValues(DimensionCode, Count, CaptionSet, FirstColumn, LastColumn);
        MakeDimTotaling(TotalingDimValue, DimensionCode);
        VerifyDimTotaling(
          DimensionCode, TotalingDimValue, FirstColumn, LastColumn, '', CaptionSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRoundValueRoundingFactorNone()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.RoundValue function does not make any rounding for RoundingFactor::None. Value = 123.45678 is not rounded
        Value := LibraryRandom.RandDec(100, 5);
        RoundValueWithRoundingFactor(Value, Value, "Analysis Rounding Factor"::None);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRoundValueRoundingFactor1()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.RoundValue function makes rounding with presicion = 1 for RoundingFactor::"1". Value = 123.45678 is rounded to 123
        Value := LibraryRandom.RandDec(100, 5);
        RoundValueWithRoundingFactor(Round(Value, 1), Value, "Analysis Rounding Factor"::"1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRoundValueRoundingFactor1000()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.RoundValue function makes division by 1000 and rounding with presicion = 0.1 for RoundingFactor::"1000". Value = 12345.67891 is "rounded" to 12.3
        Value := LibraryRandom.RandDecInRange(10000, 20000, 5);
        RoundValueWithRoundingFactor(Round(Value / 1000, 0.1), Value, "Analysis Rounding Factor"::"1000");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRoundValueRoundingFactor1000000()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.RoundValue function makes division by 1000000 and rounding with presicion = 0.1 for RoundingFactor::"1000000". Value = 1234567.89123 is "rounded" to 1.2
        Value := LibraryRandom.RandIntInRange(1000000, 2000000) + LibraryRandom.RandDec(1, 5);
        RoundValueWithRoundingFactor(
          Round(Value / 1000000, 0.1), Value, "Analysis Rounding Factor"::"1000000");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatValueRoundingFactorNone()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.FormatValue returns value with format based on GLSetup."Amount Decimal Places" for RoundingFactor::None. Value = 123.45678 converted to '123,46' when GLSetup."Amount Decimal Places" = 2:2
        Value := LibraryRandom.RandDec(100, 5);
        FormatValueWithRoundingFactor(
          Format(Value, 0, LibraryAccSchedule.GetAutoFormatString()), Value, "Analysis Rounding Factor"::None, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatZeroValueRoundingFactorNone()
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.FormatValue returns empty string for Value = 0 for RoundingFactor::None.
        FormatValueWithRoundingFactor('', 0, "Analysis Rounding Factor"::None, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatValueAddCurrencyRoundingFactorNone()
    var
        Decimals: Integer;
        Value: Decimal;
        IntPart: Decimal;
        ExpectedValue: Text;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.FormatValue returns Decimals according to AdditionalCurrency."Amount Decimal Places" for RoundingFactor::None.
        Decimals := LibraryRandom.RandIntInRange(5, 7);
        Value := LibraryRandom.RandDec(100, Decimals);
        SetAddCurrency(CreateCurrencyWithDecimals(Decimals));

        IntPart := Round(Value, 1, '<');
        ExpectedValue :=
          Format(IntPart) + CopyStr(Format(Value - IntPart, 0, LibraryAccSchedule.GetCustomFormatString(Format(Decimals))), 2);

        FormatValueWithRoundingFactor(ExpectedValue, Value, "Analysis Rounding Factor"::None, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatValueRoundingFactor1()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.FormatValue returns value without decimals for RoundingFactor::1. Value = 123.45678 converted to '123'
        Value := LibraryRandom.RandDec(100, 5);
        FormatValueWithRoundingFactor(
          Format(Round(Value, 1)), Value, "Analysis Rounding Factor"::"1", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatValueRoundingFactor1000()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.FormatValue returns value divided by 1000 with 1 decimal for RoundingFactor::1000. Value = 12345.67891 converted to '12,3'
        Value := LibraryRandom.RandDecInRange(10000, 20000, 5);

        FormatValueWithRoundingFactor(
          Format(Value / 1000, 0, LibraryAccSchedule.GetCustomFormatString('1')), Value, "Analysis Rounding Factor"::"1000", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatValueRoundingFactor1000WithLastSymbZero()
    var
        MatrixMgt: Codeunit "Matrix Management";
        Value: Decimal;
        ZeroValue: Decimal;
        ZeroDecimalTxt: Text;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.FormatValue returns value divided by 1000 with ',0' for RoundingFactor::1000 if rounded value is ended with Zero. Value = 12000 converted to '12,0'
        Value := LibraryRandom.RandIntInRange(10, 20) * 1000;
        ZeroValue := 0;
        ZeroDecimalTxt := CopyStr(Format(ZeroValue, 0, LibraryAccSchedule.GetCustomFormatString('1')), 2);
        Assert.IsTrue(
          StrPos(MatrixMgt.FormatAmount(Value, "Analysis Rounding Factor"::"1000", false), ZeroDecimalTxt) > 0,
          StrSubstNo(WrongFormatValueErr, "Analysis Rounding Factor"::"1000"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTFormatValueRoundingFactor1000000()
    var
        Value: Decimal;
    begin
        // [FEATURE] [Rounding Factor] [UT]
        // [SCENARIO 362971] MatrixMgt.FormatValue returns value divided by 1000000 with 1 decimal for RoundingFactor::1000000. Value = 1234567.89123 converted to '1,2'
        Value := LibraryRandom.RandIntInRange(1000000, 2000000) + LibraryRandom.RandDec(1, 5);
        FormatValueWithRoundingFactor(
          Format(Value / 1000000, 0, LibraryAccSchedule.GetCustomFormatString('1')), Value, "Analysis Rounding Factor"::"1000000", false);
    end;

    local procedure RoundValueWithRoundingFactor(ExpectedValue: Decimal; Value: Decimal; RoundingFactor: Enum "Analysis Rounding Factor")
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        Assert.AreEqual(
          ExpectedValue,
          MatrixMgt.RoundAmount(Value, RoundingFactor),
          StrSubstNo(WrongRoundedValueErr, RoundingFactor));
    end;

    local procedure FormatValueWithRoundingFactor(ExpectedValue: Text; Value: Decimal; RoundingFactor: Enum "Analysis Rounding Factor"; AddCurrency: Boolean)
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        Assert.AreEqual(
          ExpectedValue,
          MatrixMgt.FormatAmount(Value, RoundingFactor, AddCurrency),
          StrSubstNo(WrongFormatValueErr, RoundingFactor));
    end;

    local procedure VerifyDimToCaptions(ExpectedCaptionRange: Text; ExpectedNumberOfColumns: Integer; DimensionCode: Code[20]; FirstColumn: Text; LastColumn: Text; DimensionValueFilter: Text; var CaptionSet: array[32] of Text[80])
    var
        DimensionCodeBuffer: array[32] of Record "Dimension Code Buffer";
        MatrixManagement: Codeunit "Matrix Management";
        CaptionRange: Text;
        NumberOfColumns: Integer;
    begin
        MatrixManagement.DimToCaptions(
          CaptionSet, DimensionCodeBuffer, DimensionCode, FirstColumn, LastColumn,
          NumberOfColumns, true, CaptionRange, DimensionValueFilter);

        Assert.AreEqual(ExpectedCaptionRange, CaptionRange, WrongCaptionRangeMsg);
        Assert.AreEqual(ExpectedNumberOfColumns, NumberOfColumns, WrongNumberOfColumnsMsg);
    end;

    local procedure VerifyDimTotaling(DimensionCode: Code[20]; TotalingDimValue: Record "Dimension Value"; FirstColumn: Text; LastColumn: Text; DimensionValueFilter: Text; CaptionSet: array[32] of Text[80])
    var
        DimensionCodeBuffer: array[32] of Record "Dimension Code Buffer";
        MatrixManagement: Codeunit "Matrix Management";
        CaptionRange: Text;
        NumberOfColumns: Integer;
        i: Integer;
    begin
        MatrixManagement.DimToCaptions(
          CaptionSet, DimensionCodeBuffer, DimensionCode, FirstColumn, LastColumn,
          NumberOfColumns, true, CaptionRange, DimensionValueFilter);
        repeat
            i += 1;
        until (DimensionCodeBuffer[i].Code = TotalingDimValue.Code) or (i = ArrayLen(DimensionCodeBuffer));

        Assert.AreEqual(TotalingDimValue.Totaling, DimensionCodeBuffer[i].Totaling, WrongDimTotalingErr);
    end;

    local procedure InitDimensionValues(var DimensionCode: Code[20]; var "Count": Integer; var CaptionSet: array[32] of Text[80]; var FirstColumn: Text; var LastColumn: Text)
    var
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        Index: Integer;
    begin
        Clear(CaptionSet);
        Count := ArrayLen(CaptionSet) + 1;
        FirstColumn := 'GU';
        LastColumn := 'GU' + PadStr('9', 9, '9');

        LibraryDimension.CreateDimension(Dimension);
        DimensionCode := Dimension.Code;

        for Index := 1 to Count do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
            DimensionValue.Validate(Name, PadStr('x', Index, 'x'));
            DimensionValue.Modify(true);
            if Index <= ArrayLen(CaptionSet) then
                CaptionSet[Index] := '';
        end;
    end;

    local procedure BuildDimensionValueFilter(var DimensionValueCount: Integer; var "Filter": Text; var FirstDimValue: Text; var LastDimValue: Text; "Count": Integer; DimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        Step: Integer;
        Index: Integer;
    begin
        DimensionValueCount := LibraryRandom.RandIntInRange(3, 7);
        Step := Count div DimensionValueCount;

        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.FindSet();

        FirstDimValue := DimensionValue.Name;

        Filter := DimensionValue.Code;
        for Index := 2 to DimensionValueCount do begin
            DimensionValue.Next(LibraryRandom.RandInt(Step));
            if StrLen(Filter) + StrLen(DimensionValue.Code) < MaxStrLen(Filter) then begin
                Filter += '|' + DimensionValue.Code;
                LastDimValue := DimensionValue.Name;
            end;
        end;
    end;

    local procedure CalcExpectedCaptionRange(CaptionSet: array[32] of Text[80]; DimensionCode: Code[20]) ExpectedCaptionRange: Text
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.FindSet();
        ExpectedCaptionRange := DimensionValue.Name;
        DimensionValue.Next(ArrayLen(CaptionSet) - 1);
        ExpectedCaptionRange += '..' + DimensionValue.Name;
    end;

    local procedure MakeDimTotaling(var TotalingDimValue: Record "Dimension Value"; DimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DimValueCode: array[2] of Code[20];
        i: Integer;
    begin
        TotalingDimValue.SetRange("Dimension Code", DimensionCode);
        TotalingDimValue.FindFirst();

        DimensionValue.Copy(TotalingDimValue);
        for i := 1 to ArrayLen(DimValueCode) do begin
            DimensionValue.Next();
            DimValueCode[i] := DimensionValue.Code;
        end;

        TotalingDimValue.Validate("Dimension Value Type", TotalingDimValue."Dimension Value Type"::Total);
        TotalingDimValue.Validate(Totaling, StrSubstNo(DimTotalingTxt, DimValueCode[1], DimValueCode[2]));
        TotalingDimValue.Modify(true);
    end;

    local procedure CreateCurrencyWithDecimals(Decimals: Integer): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Amount Decimal Places" := Format(Decimals);
        Currency.Modify();
        exit(Currency.Code);
    end;

    local procedure SetAddCurrency(AddCurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AddCurrencyCode;
        GeneralLedgerSetup.Modify();
    end;
}

