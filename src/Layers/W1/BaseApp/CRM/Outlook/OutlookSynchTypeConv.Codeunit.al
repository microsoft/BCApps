// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System.Reflection;

codeunit 5302 "Outlook Synch. Type Conv"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The filter expression ''%1'' is invalid.\Please redefine your criteria.';
#pragma warning restore AA0470
        Text002: Label 'The filter cannot be processed because the expression is too long.\Please redefine your criteria.';
#pragma warning disable AA0470
        Text003: Label 'The synchronization failed because the %1 field in the %2 table is of an unsupported type. Please contact your system administrator.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        "Field": Record "Field";

    local procedure GetOptionsQuantity(OptionString: Text): Integer
    var
        Counter: Integer;
        CommaPosition: Integer;
    begin
        if StrPos(OptionString, ',') = 0 then
            exit(0);

        repeat
            CommaPosition := StrPos(OptionString, ',');
            OptionString := DelStr(OptionString, 1, CommaPosition);
            Counter := Counter + 1;
        until CommaPosition = 0;

        exit(Counter - 1);
    end;

    procedure GetSubStrByNo(Number: Integer; CommaString: Text) SelectedStr: Text
    var
        SubStrQuantity: Integer;
        Counter: Integer;
        CommaPosition: Integer;
    begin
        if Number <= 0 then
            exit;

        SubStrQuantity := GetOptionsQuantity(CommaString);
        if SubStrQuantity + 1 < Number then
            exit;

        repeat
            Counter := Counter + 1;
            CommaPosition := StrPos(CommaString, ',');
            if CommaPosition = 0 then
                SelectedStr := CommaString
            else begin
                SelectedStr := CopyStr(CommaString, 1, CommaPosition - 1);
                CommaString := DelStr(CommaString, 1, CommaPosition);
            end;
        until Counter = Number;
    end;

    procedure EvaluateTextToFieldRef(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        GUIDVar: Guid;
        GUIDVar1: Guid;
        BigIntVar: BigInteger;
        BigIntVar1: BigInteger;
        IntVar: Integer;
        IntVar1: Integer;
        DecimalVar: Decimal;
        DecimalVar1: Decimal;
        BoolVar: Boolean;
        BoolVar1: Boolean;
        DateVar: Date;
        DateVar1: Date;
        TimeVar: Time;
        TimeVar1: Time;
        DateTimeVar: DateTime;
        DateTimeVar1: DateTime;
        DurationVar: Duration;
        DurationVar1: Duration;
        DateFormulaVar: DateFormula;
        DateFormulaVar1: DateFormula;
        TextVar: Text;
        TextVar1: Text;
    begin
        if FieldRef.Class in [FieldClass::FlowField, FieldClass::FlowFilter] then
            exit(true);

        case FieldRef.Type of
            FieldType::Option:
                begin
                    if not Evaluate(IntVar, InputText) then
                        IntVar := TextToOptionValue(InputText, FieldRef.OptionCaption);
                    if IntVar < 0 then
                        exit(false);

                    if ToValidate then begin
                        IntVar1 := FieldRef.Value();
                        if IntVar1 <> IntVar then
                            FieldRef.Validate(IntVar);
                    end else
                        FieldRef.Value := IntVar;
                end;
            FieldType::Integer:
                if TextToInteger(InputText, IntVar) then begin
                    if ToValidate then begin
                        IntVar1 := FieldRef.Value();
                        if IntVar1 <> IntVar then
                            FieldRef.Validate(IntVar);
                    end else
                        FieldRef.Value := IntVar;
                end else
                    exit(false);
            FieldType::Decimal:
                if TextToDecimal(InputText, DecimalVar) then begin
                    if ToValidate then begin
                        DecimalVar1 := FieldRef.Value();
                        if DecimalVar1 <> DecimalVar then
                            FieldRef.Validate(DecimalVar);
                    end else
                        FieldRef.Value := DecimalVar;
                end else
                    exit(false);
            FieldType::Date:
                if TextToDate(InputText, DateVar, true) then begin
                    if ToValidate then begin
                        DateVar1 := FieldRef.Value();
                        if DateVar1 <> DateVar then
                            FieldRef.Validate(DateVar);
                    end else
                        FieldRef.Value := DateVar;
                end else
                    exit(false);
            FieldType::Time:
                if TextToTime(InputText, TimeVar, true) then begin
                    if ToValidate then begin
                        TimeVar1 := FieldRef.Value();
                        if TimeVar1 <> TimeVar then
                            FieldRef.Validate(TimeVar);
                    end else
                        FieldRef.Value := TimeVar;
                end else
                    exit(false);
            FieldType::DateTime:
                if TextToDateTime(InputText, DateTimeVar) then begin
                    if ToValidate then begin
                        DateTimeVar1 := FieldRef.Value();
                        if DateTimeVar1 <> DateTimeVar then
                            FieldRef.Validate(DateTimeVar);
                    end else
                        FieldRef.Value := DateTimeVar;
                end else
                    exit(false);
            FieldType::Boolean:
                if TextToBoolean(InputText, BoolVar) then begin
                    if ToValidate then begin
                        BoolVar1 := FieldRef.Value();
                        if BoolVar1 <> BoolVar then
                            FieldRef.Validate(BoolVar);
                    end else
                        FieldRef.Value := BoolVar;
                end else
                    exit(false);
            FieldType::Duration:
                if TextToDuration(InputText, DurationVar) then begin
                    if ToValidate then begin
                        DurationVar1 := FieldRef.Value();
                        if DurationVar1 <> DurationVar then
                            FieldRef.Validate(DurationVar);
                    end else
                        FieldRef.Value := DurationVar;
                end else
                    exit(false);
            FieldType::BigInteger:
                if TextToBigInteger(InputText, BigIntVar) then begin
                    if ToValidate then begin
                        BigIntVar1 := FieldRef.Value();
                        if BigIntVar1 <> BigIntVar then
                            FieldRef.Validate(BigIntVar);
                    end else
                        FieldRef.Value := BigIntVar;
                end else
                    exit(false);
            FieldType::GUID:
                if TextToGUID(InputText, GUIDVar) then begin
                    if ToValidate then begin
                        GUIDVar1 := FieldRef.Value();
                        if GUIDVar1 <> GUIDVar then
                            FieldRef.Validate(GUIDVar);
                    end else
                        FieldRef.Value := GUIDVar;
                end else
                    exit(false);
            FieldType::Code, FieldType::Text:
                if StrLen(InputText) > FieldRef.Length then begin
                    if ToValidate then begin
                        TextVar := FieldRef.Value();
                        TextVar1 := PadStr(InputText, FieldRef.Length);
                        if TextVar <> TextVar1 then
                            FieldRef.Validate(TextVar1);
                    end else
                        FieldRef.Value := PadStr(InputText, FieldRef.Length);
                end else
                    if ToValidate then begin
                        TextVar := FieldRef.Value();
                        if TextVar <> InputText then
                            FieldRef.Validate(InputText);
                    end else
                        FieldRef.Value := InputText;
            FieldType::DateFormula:
                if TextToDateFormula(InputText, DateFormulaVar) then begin
                    if ToValidate then begin
                        DateFormulaVar1 := FieldRef.Value();
                        if DateFormulaVar1 <> DateFormulaVar then
                            FieldRef.Validate(DateFormulaVar);
                    end else
                        FieldRef.Value := DateFormulaVar;
                end else
                    exit(false);
            else
                exit(false);
        end;

        exit(true);
    end;

    procedure TextToOptionValue(InputText: Text; OptionString: Text): Integer
    var
        IntVar: Integer;
        Counter: Integer;
    begin
        if InputText = '' then
            InputText := ' ';

        if Evaluate(IntVar, InputText) then begin
            if IntVar < 0 then
                IntVar := -1;
            if GetOptionsQuantity(OptionString) < IntVar then
                IntVar := -1;
        end else begin
            IntVar := -1;
            for Counter := 1 to GetOptionsQuantity(OptionString) + 1 do
                if UpperCase(GetSubStrByNo(Counter, OptionString)) = UpperCase(InputText) then
                    IntVar := Counter - 1;
        end;

        exit(IntVar);
    end;

    procedure TextToInteger(InputText: Text; var IntVar: Integer) IsConverted: Boolean
    begin
        IsConverted := Evaluate(IntVar, InputText);
    end;

    procedure TextToBigInteger(InputText: Text; var BigIntVar: BigInteger) IsConverted: Boolean
    begin
        IsConverted := Evaluate(BigIntVar, InputText);
    end;

    procedure TextToBoolean(InputText: Text; var BoolVar: Boolean) IsConverted: Boolean
    begin
        IsConverted := Evaluate(BoolVar, InputText);
    end;

    procedure TextToGUID(InputText: Text; var GUIDVar: Guid) IsConverted: Boolean
    begin
        IsConverted := Evaluate(GUIDVar, InputText);
    end;

    procedure TextToDecimal(InputText: Text; var DecVar: Decimal) IsConverted: Boolean
    var
        PartArray: array[2] of Text;
        IntegeralPart: Integer;
        FractionalPart: Integer;
        Sign: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTextToDecimal(InputText, DecVar, IsConverted, IsHandled);
        if IsHandled then
            exit(IsConverted);

        InputText := ConvertStr(InputText, '.', ',');
        if StrPos(InputText, ',') = 0 then begin
            IsConverted := TextToInteger(InputText, IntegeralPart);
            if IsConverted then
                DecVar := IntegeralPart;
            exit;
        end;

        PartArray[1] := GetSubStrByNo(1, InputText);
        PartArray[2] := GetSubStrByNo(2, InputText);

        IsConverted := Evaluate(IntegeralPart, PartArray[1]);
        if not IsConverted then
            exit;

        IsConverted := Evaluate(FractionalPart, PartArray[2]);
        if not IsConverted then
            exit;

        if StrPos(InputText, '-') = 0 then
            Sign := 1
        else
            Sign := -1;
        DecVar := (Sign * (Abs(IntegeralPart) + (FractionalPart / Power(10, StrLen(PartArray[2])))));
    end;

    local procedure TextToDate(InputText: Text; var DateVar: Date; UseLocalTime: Boolean) IsConverted: Boolean
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        DateTimeVar: DateTime;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTextToDate(InputText, DateVar, UseLocalTime, IsConverted, IsHandled);
        if IsHandled then
            exit(IsConverted);

        InputText := ConvertStr(InputText, ' ', ',');
        if StrPos(InputText, ',') = 0 then
            exit;

        InputText := GetSubStrByNo(1, InputText);
        InputText := ConvertStr(InputText, '/', ',');
        if StrPos(InputText, ',') = 0 then
            exit;

        IsConverted := Evaluate(Month, GetSubStrByNo(1, InputText));
        if not IsConverted then
            exit;

        InputText := DelStr(InputText, 1, StrPos(InputText, ','));
        if StrPos(InputText, ',') = 0 then begin
            IsConverted := false;
            exit;
        end;

        IsConverted := Evaluate(Day, GetSubStrByNo(1, InputText));
        if not IsConverted then
            exit;

        IsConverted := Evaluate(Year, GetSubStrByNo(2, InputText));
        if not IsConverted then
            exit;

        if (Day < 1) and (Day > 31) and (Month < 1) and (Month > 12) then begin
            IsConverted := false;
            exit;
        end;

        DateVar := DMY2Date(Day, Month, Year);
        if DateVar = 45010101D then
            DateVar := 0D
        else begin
            if UseLocalTime then
                DateTimeVar := UTC2LocalDT(CreateDateTime(DateVar, 000000T))
            else
                DateTimeVar := CreateDateTime(DateVar, 000000T);
            DateVar := DT2Date(DateTimeVar);
        end;
    end;

    local procedure TextToTime(InputText: Text; var TimeVar: Time; UseLocalTime: Boolean) IsConverted: Boolean
    var
        DateTimeVar: DateTime;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTextToTime(InputText, TimeVar, UseLocalTime, IsConverted, IsHandled);
        if IsHandled then
            exit(IsConverted);

        InputText := ConvertStr(InputText, ' ', ',');
        if StrPos(InputText, ',') = 0 then
            exit;

        IsConverted := Evaluate(TimeVar, GetSubStrByNo(2, InputText));

        if not IsConverted then
            exit;

        if UseLocalTime then
            DateTimeVar := UTC2LocalDT(CreateDateTime(Today, TimeVar))
        else
            DateTimeVar := CreateDateTime(Today, TimeVar);
        TimeVar := DT2Time(DateTimeVar);
    end;

    procedure TextToDateTime(InputText: Text; var DateTimeVar: DateTime) IsConverted: Boolean
    var
        DateVar: Date;
        TimeVar: Time;
    begin
        IsConverted := TextToDate(InputText, DateVar, false);
        if not IsConverted then
            exit;

        IsConverted := TextToTime(InputText, TimeVar, false);
        if not IsConverted then
            exit;

        if DateVar <> 0D then
            DateTimeVar := UTC2LocalDT(CreateDateTime(DateVar, TimeVar))
        else
            if TimeVar <> 0T then
                DateTimeVar := CreateDateTime(Today, TimeVar);
    end;

    procedure TextToDuration(InputText: Text; var DurationVar: Duration) IsConverted: Boolean
    var
        Millisec: BigInteger;
    begin
        if not Evaluate(Millisec, InputText) then
            exit;

        Millisec := Millisec * 60000;
        DurationVar := Millisec;
        IsConverted := true;
    end;

    procedure TextToDateFormula(InputText: Text; var DateFormulaVar: DateFormula) IsConverted: Boolean
    begin
        IsConverted := Evaluate(DateFormulaVar, InputText);
    end;

    procedure OptionValueToText(InputInteger: Integer; OptionString: Text) OutputText: Text
    begin
        if (InputInteger >= 0) and (InputInteger <= GetOptionsQuantity(OptionString)) then
            OutputText := SelectStr(InputInteger + 1, OptionString);
    end;

    procedure FieldOptionValueToText(InputInteger: Integer; OptionRecordId: Integer; OptionFieldId: Integer) OutputText: Text
    var
        OptionString: Text;
    begin
        OptionString := GetOptionCaption(OptionRecordId, OptionFieldId);
        if (InputInteger >= 0) and (InputInteger <= GetOptionsQuantity(OptionString)) then
            OutputText := SelectStr(InputInteger + 1, OptionString);
    end;

    procedure EvaluateOptionField(FieldRef: FieldRef; var ValueToEvaluate: Text): Boolean
    var
        IntValue: Integer;
    begin
        IntValue := TextToOptionValue(ValueToEvaluate, FieldRef.OptionCaption);
        if IntValue <> -1 then
            ValueToEvaluate := SelectStr(IntValue + 1, FieldRef.OptionCaption);
        exit(IntValue <> -1);
    end;

    procedure EvaluateFilterOptionField(FieldRef: FieldRef; var FilterValueToEvaluate: Text; ReplaceOptionsWithValues: Boolean) Asserted: Boolean
    var
        AssertedOption: Text;
        TempString: Text;
        ArrayImpliedOptions: array[20] of Text;
        IntValue: Integer;
        I: Integer;
        SpaceRemovePosStart: Integer;
        SpaceRemovePosEnd: Integer;
        ImpliedOption: Text;
    begin
        TempString := FilterValueToEvaluate;

        if not ParseFilterExpression(TempString, ArrayImpliedOptions) then
            Error(Text001, FilterValueToEvaluate);

        TempString := FilterValueToEvaluate;
        SpaceRemovePosStart := 1;

        for I := 1 to 20 do begin
            AssertedOption := '';
            ImpliedOption := '';
            if ArrayImpliedOptions[I] <> '' then begin
                ImpliedOption := ArrayImpliedOptions[I];

                if Evaluate(IntValue, ImpliedOption) then begin
                    AssertedOption := OptionValueToText(IntValue, FieldRef.OptionCaption);
                    Asserted := AssertedOption <> '';
                end else begin
                    IntValue := TextToOptionValue(ImpliedOption, FieldRef.OptionCaption);
                    if IntValue <> -1 then
                        AssertedOption := SelectStr(IntValue + 1, FieldRef.OptionCaption);
                    Asserted := IntValue <> -1;
                end;

                if not Asserted then
                    exit;

                if ReplaceOptionsWithValues then
                    AssertedOption := Format(IntValue);

                if (StrPos(AssertedOption, '(') <> 0) or (StrPos(AssertedOption, ')') <> 0) or (AssertedOption = ' ') then
                    AssertedOption := StrSubstNo('''%1''', AssertedOption);

                SpaceRemovePosEnd := StrPos(TempString, ImpliedOption);
                TempString := RemoveSpaceChars(TempString, SpaceRemovePosStart, SpaceRemovePosEnd);

                if (StrLen(TempString) + StrLen(AssertedOption) - StrLen(ImpliedOption)) > MaxStrLen(TempString) then
                    Error(Text002);

                SpaceRemovePosStart := StrPos(TempString, ImpliedOption) + StrLen(AssertedOption);

                TempString := ReplaceText(TempString, ImpliedOption, AssertedOption, true);
            end;
        end;
        TempString := RemoveSpaceChars(TempString, SpaceRemovePosStart, StrLen(TempString));

        FilterValueToEvaluate := TempString;
    end;

    local procedure ParseFilterExpression(var FilterExpression: Text; var ArrayTokens: array[20] of Text): Boolean
    var
        TempStr: Text;
        ReservedFilterChars: Text;
        I: Integer;
        "Count": Integer;
    begin
        if FilterExpression = '' then
            FilterExpression := ' ';

        FilterExpression := ConvertStr(FilterExpression, '&|', ',,');
        FilterExpression := ReplaceText(FilterExpression, '..', ',', false);

        if FilterExpression[StrLen(FilterExpression)] = ',' then
            exit(false);

        TempStr := FilterExpression;
        Count := 1;

        while StrPos(TempStr, ',') > 0 do begin
            TempStr := DelStr(TempStr, StrPos(TempStr, ','), 1);
            Count := Count + 1;
        end;

        if Count > 20 then
            exit(false);

        ReservedFilterChars := '&|<>=()';
        FilterExpression := DelChr(FilterExpression, '=', ReservedFilterChars);
        FilterExpression := DelChr(FilterExpression, '<>', ' ');

        if FilterExpression = '' then
            exit(false);

        for I := 1 to Count do
            ArrayTokens[I] := DelChr(GetSubStrByNo(I, FilterExpression), '<>', ' ');

        exit(true);
    end;

    local procedure ReplaceText(Text: Text; FromText: Text; ToText: Text; OnlyOnce: Boolean): Text
    var
        I: Integer;
    begin
        repeat
            I := StrPos(Text, FromText);
            if I > 0 then begin
                Text := DelStr(Text, I, StrLen(FromText));
                Text := InsStr(Text, ToText, I);
            end;
        until (I = 0) or OnlyOnce;
        exit(Text);
    end;

    local procedure RemoveSpaceChars(Text: Text; StartPos: Integer; EndPos: Integer) OutText: Text
    var
        SpaceRemovedString: Text;
    begin
        OutText := Text;
        if (StrLen(Text) > EndPos) and (EndPos > StartPos) then begin
            SpaceRemovedString := CopyStr(Text, StartPos, EndPos - StartPos);
            OutText := ReplaceText(Text, SpaceRemovedString, DelChr(SpaceRemovedString, '=', ' '), true);
        end;
    end;

    procedure TruncateString(var InputString: Text; NewLength: Integer)
    begin
        if StrLen(InputString) > NewLength then
            InputString := PadStr(InputString, NewLength);
    end;

    procedure SetTimeFormat(InTime: Time) OutTime: Text
    begin
        OutTime := ConvertStr(Format(InTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), ' ', '0');
    end;

    procedure SetDateFormat(InDate: Date) OutDate: Text
    begin
        OutDate := Format(InDate, 0, '<Month,2>/<Day,2>/<Year4>');
    end;

    procedure SetDateTimeFormat(InDateTime: DateTime) OutDateTime: Text
    begin
        if InDateTime = 0DT then
            OutDateTime := SetDateFormat(45010101D) + ' ' + SetTimeFormat(000000T)
        else
            OutDateTime := SetDateFormat(DT2Date(InDateTime)) + ' ' + SetTimeFormat(DT2Time(InDateTime));
    end;

    procedure SetDecimalFormat(InDecimal: Decimal) OutDecimal: Text
    begin
        OutDecimal := Format(InDecimal, 0, '<Sign>') + Format(InDecimal, 0, '<Integer>');

        if CopyStr(Format(InDecimal, 0, '<Decimals>'), 2) <> '' then
            OutDecimal := OutDecimal + '.' + CopyStr(Format(InDecimal, 0, '<Decimals>'), 2)
        else
            OutDecimal := OutDecimal + '.0';
    end;

    procedure SetBoolFormat(InBoolean: Boolean) OutBoolean: Text
    begin
        if InBoolean then
            OutBoolean := '1'
        else
            OutBoolean := '0';
    end;

    [Scope('OnPrem')]
    procedure PrepareFieldValueForXML(FldRef: FieldRef) OutText: Text
    var
        RecID: RecordID;
        Date: Date;
        Time: Time;
        DateTime: DateTime;
        BigInt: BigInteger;
        Decimal: Decimal;
        Bool: Boolean;
    begin
        if FldRef.Class = FieldClass::FlowField then
            FldRef.CalcField();

        case FldRef.Type of
            FieldType::Option:
                OutText := Format(FldRef);
            FieldType::Text, FieldType::Code:
                OutText := Format(FldRef.Value);
            FieldType::Date:
                begin
                    Evaluate(Date, Format(FldRef.Value));
                    DateTime := CreateDateTime(Date, 0T);
                    Date := DT2Date(LocalDT2UTC(DateTime));
                    OutText := SetDateFormat(Date);
                end;
            FieldType::Time:
                begin
                    Evaluate(Time, Format(FldRef.Value));
                    DateTime := CreateDateTime(Today, Time);
                    Time := DT2Time(LocalDT2UTC(DateTime));
                    OutText := SetTimeFormat(Time);
                end;
            FieldType::DateTime:
                begin
                    Evaluate(DateTime, Format(FldRef.Value));
                    OutText := SetDateTimeFormat(LocalDT2UTC(DateTime));
                end;
            FieldType::Integer, FieldType::BigInteger:
                OutText := Format(FldRef.Value);
            FieldType::Duration:
                begin
                    BigInt := FldRef.Value();
                    // Use round to avoid conversion errors due to the conversion from decimal to long.
                    BigInt := Round(BigInt / 60000, 1);
                    OutText := Format(BigInt);
                end;
            FieldType::Decimal:
                begin
                    Evaluate(Decimal, Format(FldRef.Value));
                    OutText := SetDecimalFormat(Decimal);
                end;
            FieldType::DateFormula:
                OutText := Format(FldRef.Value);
            FieldType::Boolean:
                begin
                    Evaluate(Bool, Format(FldRef.Value));
                    OutText := SetBoolFormat(Bool);
                end;
            FieldType::GUID:
                OutText := Format(FldRef.Value);
            else begin
                RecID := FldRef.Record().RecordId;
                Field.Get(RecID.TableNo, FldRef.Number);
                Error(Text003, Field."Field Caption", FldRef.Record().Caption);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetValueFormat(FormattedValue: Text; FldRef: FieldRef) OutText: Text
    var
        RecID: RecordID;
        Date: Date;
        Time: Time;
        DateTime: DateTime;
        BigInt: BigInteger;
        Decimal: Decimal;
        Bool: Boolean;
        DurationVar: Duration;
    begin
        case FldRef.Type of
            FieldType::Text, FieldType::Code, FieldType::Option, FieldType::DateFormula, FieldType::GUID:
                OutText := FormattedValue;
            FieldType::Date:
                begin
                    Evaluate(Date, FormattedValue, 9);
                    if Date <> 0D then
                        OutText := SetDateTimeFormat(CreateDateTime(Date, 000000T));
                end;
            FieldType::Time:
                begin
                    Evaluate(Time, FormattedValue, 9);
                    OutText := SetDateTimeFormat(CreateDateTime(45010101D, Time));
                end;
            FieldType::DateTime:
                begin
                    Evaluate(DateTime, FormattedValue, 9);
                    OutText := SetDateTimeFormat(DateTime);
                end;
            FieldType::Integer, FieldType::BigInteger:
                OutText := FormattedValue;
            FieldType::Decimal:
                begin
                    Evaluate(Decimal, FormattedValue, 9);
                    OutText := SetDecimalFormat(Decimal);
                end;
            FieldType::Boolean:
                begin
                    Evaluate(Bool, FormattedValue, 9);
                    OutText := SetBoolFormat(Bool);
                end;
            FieldType::Duration:
                begin
                    Evaluate(DurationVar, FormattedValue, 9);
                    BigInt := DurationVar / 60000;
                    OutText := Format(BigInt);
                end;
            else begin
                RecID := FldRef.Record().RecordId;
                Field.Get(RecID.TableNo, FldRef.Number);
                Error(Text003, FldRef.Caption, FldRef.Record().Caption);
            end;
        end;
    end;

    procedure HandleFilterChars(InputText: Text; MaxLength: Integer): Text
    var
        Pos: Integer;
        Char: Char;
        QuotesNeeded: Boolean;
    begin
        if (StrLen(InputText) + 2) > MaxLength then
            exit(InputText);

        Pos := 1;
        repeat
            Char := InputText[Pos];
            if Char in ['@', '(', ')', '<', '>', '&', '|', '='] then
                QuotesNeeded := true;
            Pos := Pos + 1;
        until (Pos = MaxLength) or QuotesNeeded;

        if QuotesNeeded then
            exit(StrSubstNo('"%1"', InputText));
        exit(InputText);
    end;

    procedure ReplaceFilterChars(InputString: Text) Result: Text
    begin
        Result := ConvertStr(InputString, '@()<>&|="''', '??????????');
        if Result = '' then
            Result := '''''';
        exit(Result);
    end;

    procedure LocalDT2UTC(LocalDT: DateTime) UTC: DateTime
    begin
        if LocalDT <> 0DT then
            UTC := ParseUTCString(Format(LocalDT, 0, 9))
        else
            UTC := 0DT;
    end;

    procedure UTC2LocalDT(UTC: DateTime) LocalDT: DateTime
    var
        UTCDifference: Duration;
    begin
        if UTC <> 0DT then begin
            UTCDifference := UTC - LocalDT2UTC(UTC);
            LocalDT := UTC + UTCDifference;
        end else
            LocalDT := 0DT;
    end;

    procedure UTCString2LocalDT(UTCString: Text) ResultDT: DateTime
    var
        UTC: DateTime;
    begin
        UTC := ParseUTCString(UTCString);
        ResultDT := UTC2LocalDT(UTC);
    end;

    local procedure ParseUTCString(UTCString: Text) ResultDT: DateTime
    var
        Time: Time;
        Year: Integer;
        Month: Integer;
        Day: Integer;
        Hour: Integer;
        Minute: Integer;
        Sec: Integer;
        Millisec: Integer;
        PosDot: Integer;
        PosZ: Integer;
    begin
        if UTCString = '' then
            exit(0DT);
        Evaluate(Year, CopyStr(UTCString, 1, 4));
        Evaluate(Month, CopyStr(UTCString, 6, 2));
        Evaluate(Day, CopyStr(UTCString, 9, 2));
        Evaluate(Hour, CopyStr(UTCString, 12, 2));
        Evaluate(Minute, CopyStr(UTCString, 15, 2));
        Evaluate(Sec, CopyStr(UTCString, 18, 2));
        PosDot := StrPos(UTCString, '.');
        PosZ := StrPos(UTCString, 'Z');
        if PosDot > 0 then
            Evaluate(Millisec, CopyStr(UTCString, PosDot + 1, PosZ - PosDot - 1));
        Evaluate(Time, StrSubstNo('%1:%2:%3.%4', Hour, Minute, Sec, Millisec));
        ResultDT := CreateDateTime(DMY2Date(Day, Month, Year), Time);
    end;

    local procedure GetOptionCaption(TableId: Integer; FieldId: Integer) OptionCaption: Text
    var
        OptionRecordRef: RecordRef;
        OptionFieldRef: FieldRef;
    begin
        OptionRecordRef.Open(TableId);
        OptionFieldRef := OptionRecordRef.Field(FieldId);
        OptionCaption := OptionFieldRef.OptionCaption;
        OptionRecordRef.Close();
    end;

    procedure RunningUTC(): Boolean
    var
        DateTimeNow: DateTime;
        EvalUTCTime: Time;
        EvalTime: Time;
        EvalDateTime: DateTime;
        UTCHour: Text;
        calculatedHour: Text;
        UTCText: Text;
        hourNumber: Integer;
        UTChourNumber: Integer;
    begin
        DateTimeNow := CurrentDateTime;

        // Documented format 9 is: 2003-04-05T03:35:55.553Z
        // We only want the Time, so we need to get rid of Date and the ending Z
        UTCText := Format(DateTimeNow, 0, 9);
        UTCText := CopyStr(UTCText, StrPos(UTCText, 'T') + 1);
        UTCText := DelChr(UTCText, '=', 'Z');

        // Get only the current hour
        Evaluate(EvalUTCTime, UTCText);
        UTCHour := Format(EvalUTCTime);
        UTCHour := CopyStr(UTCHour, 1, StrPos(UTCHour, ':') - 1);
        Evaluate(UTChourNumber, UTCHour);

        // Documented format 0 is: 05-04-03 4.35 (But this changes with settings)
        // Get the Time only
        Evaluate(EvalDateTime, Format(DateTimeNow, 0, 0));
        EvalTime := DT2Time(EvalDateTime);
        calculatedHour := Format(EvalTime);
        calculatedHour := CopyStr(calculatedHour, 1, StrPos(calculatedHour, ':') - 1);
        Evaluate(hourNumber, calculatedHour);

        exit(hourNumber = UTChourNumber);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTextToDate(InputText: Text; var DateVar: Date; UseLocalTime: Boolean; var IsConverted: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTextToDecimal(InputText: Text; var DecVar: Decimal; var IsConverted: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTextToTime(InputText: Text; var TimeVar: Time; var UseLocalTime: Boolean; var IsConverted: Boolean; var IsHandled: Boolean);
    begin
    end;
}

