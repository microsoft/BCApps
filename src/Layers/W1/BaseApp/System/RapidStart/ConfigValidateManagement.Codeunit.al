namespace System.IO;

using Microsoft.Inventory.Item;
using System;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

codeunit 8617 "Config. Validate Management"
{

    trigger OnRun()
    begin
    end;

    var
        TypeHelper: Codeunit "Type Helper";

#pragma warning disable AA0470
        FieldLengthExceededMsg: Label 'Field %2 in table %1 can only contain %3 characters (%4).';
        UnsupportedDataTypeMsg: Label '%1 is not a supported data type.';
        InvalidValueForTypeMsg: Label '%1 is not a valid %2.';
        InvalidOptionValueMsg: Label '%1 is not a valid option.\Valid options are %2.';
#pragma warning restore AA0470
        ExternalTablesAreNotAllowedErr: Label 'External tables cannot be added in Configuration Packages.';

    procedure ValidateFieldValue(var RecRef: RecordRef; var FieldRef: FieldRef; Value: Text; SkipValidation: Boolean; LanguageID: Integer)
    var
        "Field": Record "Field";
        OldValue: Variant;
        NewValue: Variant;
        OptionAsInteger: Integer;
        MainLanguageID: Integer;
    begin
        if FieldRef.Class <> FieldClass::Normal then
            exit;

        MainLanguageID := GlobalLanguage;

        if (LanguageID <> 0) and (LanguageID <> GlobalLanguage) then
            GlobalLanguage(LanguageID);

        Field.Get(RecRef.Number, FieldRef.Number);
        TypeHelper.TestFieldIsNotObsolete(Field);

        if not SkipValidation then
            OldValue := FieldRef.VALUE();

        if FieldRef.Type <> FieldType::Option then begin
            if Value <> '' then
                Evaluate(FieldRef, Value)
        end else begin
            OptionAsInteger := GetOptionNo(Value, FieldRef);
            if OptionAsInteger <> -1 then
                FieldRef.Value := OptionAsInteger;
        end;

        if not SkipValidation then begin
            NewValue := FieldRef.VALUE();
            FieldRef.Value := OldValue;
            FieldRef.Validate(NewValue);
        end;

        if MainLanguageID <> GlobalLanguage then
            GlobalLanguage(MainLanguageID);
    end;

    procedure OptionNoExists(var FieldRef: FieldRef; OptionValue: Text): Boolean
    var
        OptionNo: Integer;
    begin
        if Evaluate(OptionNo, OptionValue) then
            exit((FieldRef.GetEnumValueNameFromOrdinalValue(OptionNo) <> '') or ((FieldRef.GetEnumValueNameFromOrdinalValue(OptionNo) = '') and (OptionNo = 0)));

        exit(false);
    end;

    procedure GetOptionNo(Value: Text; FieldRef: FieldRef): Integer
    var
        FieldRefValueVar: Variant;
        FieldRefValueInt: Integer;
    begin
        if (Value = '') and (FieldRef.GetEnumValueName(1) = ' ') then
            exit(0);

        FieldRefValueVar := FieldRef.Value();
        FieldRefValueInt := -1;
        if Evaluate(FieldRef, Value) then begin
            FieldRefValueInt := FieldRef.Value();
            FieldRef.Value(FieldRefValueVar);
        end;

        exit(FieldRefValueInt);
    end;

    procedure GetRelationInfoByIDs(TableNo: Integer; FieldNo: Integer; var RelationTableNo: Integer; var RelationFieldNo: Integer): Boolean
    var
        "Field": Record "Field";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        FieldRef2: FieldRef;
        FieldRef: FieldRef;
        KeyRef2: KeyRef;
    begin
        Field.Get(TableNo, FieldNo);
        TypeHelper.TestFieldIsNotObsolete(Field);

        if Field.RelationTableNo = 0 then
            exit(false);

        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);

        RecRef2.Open(Field.RelationTableNo);

        if Field.RelationFieldNo <> 0 then
            FieldRef2 := RecRef2.Field(Field.RelationFieldNo)
        else begin
            KeyRef2 := RecRef2.KeyIndex(1);
            if KeyRef2.FieldCount > 1 then
                exit(false);
            FieldRef2 := KeyRef2.FieldIndex(1);
        end;

        if (FieldRef2.Type <> FieldRef.Type) or (FieldRef2.Length <> FieldRef.Length) then
            exit(false);

        RelationTableNo := Field.RelationTableNo;
        RelationFieldNo := FieldRef2.Number;
        exit(true);
    end;

    procedure GetRelationTableID(TableID: Integer; FieldID: Integer): Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableID);
        if RecRef.FieldExist(FieldID) then begin
            FieldRef := RecRef.Field(FieldID);
            exit(FieldRef.Relation);
        end;
    end;

    procedure IsRelationInKeyFields(TableNo: Integer; FieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        I: Integer;
    begin
        RecRef.Open(TableNo);
        KeyRef := RecRef.KeyIndex(1);

        for I := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(I);
            if FieldRef.Number = FieldNo then
                exit(true);
        end;
    end;

    procedure ValidateFieldRefRelationAgainstCompanyData(FieldRef: FieldRef): Text
    var
        ConfigTryValidate: Codeunit "Config. Try Validate";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        FieldRef2: FieldRef;
    begin
        RecRef := FieldRef.Record();

        RecRef2.Open(RecRef.Number, true);
        CopyRecRefFields(RecRef2, RecRef, FieldRef);
        RecRef2.Insert();

        FieldRef2 := RecRef2.Field(FieldRef.Number());

        ConfigTryValidate.SetValidateParameters(FieldRef2, FieldRef.Value());

        Commit();
        if not ConfigTryValidate.Run() then
            exit(GetLastErrorText());

        exit('');
    end;

    local procedure CopyRecRefFields(RecRef: RecordRef; SourceRecRef: RecordRef; FieldRefToExclude: FieldRef)
    var
        FieldRef: FieldRef;
        SourceFieldRef: FieldRef;
        FieldCount: Integer;
    begin
        for FieldCount := 1 to SourceRecRef.FieldCount do begin
            SourceFieldRef := SourceRecRef.FieldIndex(FieldCount);
            if FieldRefToExclude.Name <> SourceFieldRef.Name then begin
                FieldRef := RecRef.FieldIndex(FieldCount);
                FieldRef.Value := SourceFieldRef.VALUE();
            end;
        end;
    end;

    procedure EvaluateValue(var FieldRef: FieldRef; Value: Text; XMLValue: Boolean): Text
    begin
        exit(EvaluateValueBase(FieldRef, Value, XMLValue, false));
    end;

    procedure EvaluateValueWithValidate(var FieldRef: FieldRef; Value: Text; XMLValue: Boolean): Text
    begin
        exit(EvaluateValueBase(FieldRef, Value, XMLValue, true));
    end;

    local procedure EvaluateValueBase(var FieldRef: FieldRef; Value: Text; XMLValue: Boolean; Validate: Boolean): Text
    begin
        if (Value <> '') and not IsNormalField(FieldRef) then
            exit(StrSubstNo(UnsupportedDataTypeMsg, FieldRef.Name));

        case FieldRef.Type of
            FieldType::Text:
                exit(EvaluateValueToText(FieldRef, Value, Validate));
            FieldType::Code:
                exit(EvaluateValueToCode(FieldRef, Value, Validate));
            FieldType::Option:
                exit(EvaluateValueToOption(FieldRef, Value, XMLValue, Validate));
            FieldType::Date:
                exit(EvaluateValueToDate(FieldRef, Value, Validate));
            FieldType::DateFormula:
                exit(EvaluateValueToDateFormula(FieldRef, Value, Validate));
            FieldType::DateTime:
                exit(EvaluateValueToDateTime(FieldRef, Value, Validate));
            FieldType::Time:
                exit(EvaluateValueToTime(FieldRef, Value, Validate));
            FieldType::Duration:
                exit(EvaluateValueToDuration(FieldRef, Value, Validate));
            FieldType::Integer:
                exit(EvaluateValueToInteger(FieldRef, Value, Validate));
            FieldType::BigInteger:
                exit(EvaluateValueToBigInteger(FieldRef, Value, Validate));
            FieldType::Decimal:
                exit(EvaluateValueToDecimal(FieldRef, Value, Validate));
            FieldType::Boolean:
                exit(EvaluateValueToBoolean(FieldRef, Value, Validate));
            FieldType::GUID,
            FieldType::MediaSet,
            FieldType::Media:
                exit(EvaluateValueToGuid(FieldRef, Value, Validate));
            FieldType::Blob:
                exit(EvaluateValueToBlob(FieldRef, Value));
            FieldType::TableFilter:
                exit(EvaluateValueToTableFilter(FieldRef, Value));
            FieldType::RecordId:
                exit(EvaluateValueToRecordID(FieldRef, Value, Validate));
        end;
    end;

    local procedure EvaluateValueToText(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        "Field": Record "Field";
        RecordRef: RecordRef;
    begin
        RecordRef := FieldRef.Record();
        Field.Get(RecordRef.Number, FieldRef.Number);
        TypeHelper.TestFieldIsNotObsolete(Field);
        if StrLen(Value) > FieldRef.Length then
            exit(StrSubstNo(FieldLengthExceededMsg, FieldRef.Record().Caption, FieldRef.Caption, FieldRef.Length, Value));

        if Validate then
            FieldRef.Validate(Value)
        else
            FieldRef.Value := Value;
    end;

    local procedure EvaluateValueToCode(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        "Field": Record "Field";
        RecordRef: RecordRef;
        "Code": Code[2048];
    begin
        Code := CopyStr(Value, 1, 1024);
        RecordRef := FieldRef.Record();
        Field.Get(RecordRef.Number, FieldRef.Number);
        TypeHelper.TestFieldIsNotObsolete(Field);
        if StrLen(Value) > Field.Len then
            exit(StrSubstNo(FieldLengthExceededMsg, FieldRef.Record().Caption(), FieldRef.Caption(), FieldRef.Length(), Value));

        if Validate then
            FieldRef.Validate(Code)
        else
            FieldRef.Value := Code;
    end;

    local procedure EvaluateValueToOption(var FieldRef: FieldRef; Value: Text; XMLValue: Boolean; Validate: Boolean): Text
    var
        "Integer": Integer;
    begin
        Integer := -1;
        if XMLValue then begin
            if OptionNoExists(FieldRef, Value) then
                Evaluate(Integer, Value);
        end else
            Integer := GetOptionNo(Value, FieldRef);
        if Integer = -1 then
            exit(StrSubstNo(InvalidOptionValueMsg, Value, FieldRef.OptionCaption));

        if Validate then
            FieldRef.Validate(Integer)
        else
            FieldRef.Value := Integer;
    end;

    local procedure EvaluateValueToDate(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        DotNetDecimal: DotNet Decimal;
        DotNetCultureInfo: DotNet CultureInfo;
        DotNetNumberStyles: DotNet NumberStyles;
        Date: Date;
        ZeroDate: Date;
        Decimal: Decimal;
        IsDateEvaluated: Boolean;
    begin
        // Try parsing as OADate (which Excel uses for date-times)
        ZeroDate := 0D;
        if DotNetDecimal.TryParse(Value, DotNetNumberStyles.Float, DotNetCultureInfo.InvariantCulture, Decimal) then
            if Evaluate(Date, Format(DT2Date(OADateToDateTime(Decimal)))) then
                if (Date <> ZeroDate) then
                    IsDateEvaluated := true;

        // Try parsing as text
        if not IsDateEvaluated then
            if Evaluate(Date, Value) or Evaluate(Date, Value, XMLFormat()) then
                IsDateEvaluated := true;
        if IsDateEvaluated then begin
            if Validate then
                FieldRef.Validate(Date)
            else
                FieldRef.Value := Date;
        end else
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::Date)));
    end;

    local procedure EvaluateValueToDateFormula(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        DateFormula: DateFormula;
    begin
        if not Evaluate(DateFormula, Value) and not Evaluate(DateFormula, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::DateFormula)));

        if Validate then
            FieldRef.Validate(DateFormula)
        else
            FieldRef.Value := DateFormula;
    end;

    local procedure EvaluateValueToDateTime(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        DateTime: DateTime;
    begin
        if not Evaluate(DateTime, Value) and not Evaluate(DateTime, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::DateTime)));

        if Validate then
            FieldRef.Validate(DateTime)
        else
            FieldRef.Value := DateTime;
    end;

    local procedure EvaluateValueToTime(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        Time: Time;
        Decimal: Decimal;
    begin
        if not Evaluate(Time, Value) and not Evaluate(Time, Value, XMLFormat()) then
            if not Evaluate(Decimal, Value) or not Evaluate(Time, Format(DT2Time(OADateToDateTime(Decimal)))) then
                exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::Time)));

        if Validate then
            FieldRef.Validate(Time)
        else
            FieldRef.Value := Time;
    end;

    local procedure EvaluateValueToDuration(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        Duration: Duration;
    begin
        if not Evaluate(Duration, Value) and not Evaluate(Duration, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::Duration)));

        if Validate then
            FieldRef.Validate(Duration)
        else
            FieldRef.Value := Duration;
    end;

    local procedure EvaluateValueToInteger(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        "Integer": Integer;
    begin
        if not Evaluate(Integer, Value) and not Evaluate(Integer, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::Integer)));

        if Validate then
            FieldRef.Validate(Integer)
        else
            FieldRef.Value := Integer;
    end;

    local procedure EvaluateValueToBigInteger(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        BigInteger: BigInteger;
    begin
        if not Evaluate(BigInteger, Value) and not Evaluate(BigInteger, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::BigInteger)));

        if Validate then
            FieldRef.Validate(BigInteger)
        else
            FieldRef.Value := BigInteger;
    end;

    local procedure EvaluateValueToDecimal(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        DecimalValue: Decimal;
    begin
        if not Evaluate(DecimalValue, Value) and not Evaluate(DecimalValue, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::Decimal)));

        RoundDecimalValue(FieldRef, DecimalValue);

        if Validate then
            FieldRef.Validate(DecimalValue)
        else
            FieldRef.Value := DecimalValue;

    end;

    local procedure EvaluateValueToBoolean(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        Boolean: Boolean;
    begin
        if not Evaluate(Boolean, Value) and not Evaluate(Boolean, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::Boolean)));

        if Validate then
            FieldRef.Validate(Boolean)
        else
            FieldRef.Value := Boolean;
    end;

    local procedure EvaluateValueToGuid(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        Guid: Guid;
    begin
        if not Evaluate(Guid, Value) and not Evaluate(Guid, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::GUID)));

        if Validate then
            FieldRef.Validate(Guid)
        else
            FieldRef.Value := Guid;
    end;

    local procedure EvaluateValueToBlob(var FieldRef: FieldRef; Value: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(Value);
        TempBlob.ToFieldRef(FieldRef);
    end;

    local procedure EvaluateValueToTableFilter(var FieldRef: FieldRef; Value: Text): Text
    var
        TableFilter: Text;
    begin
        if not Evaluate(TableFilter, Value) and not Evaluate(TableFilter, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(FieldType::TableFilter)));

        Evaluate(FieldRef, TableFilter);
    end;

    local procedure EvaluateValueToRecordID(var FieldRef: FieldRef; Value: Text; Validate: Boolean): Text
    var
        Field: Record Field;
        RecordID: RecordId;
    begin
        if not Evaluate(RecordID, Value) and not Evaluate(RecordID, Value, XMLFormat()) then
            exit(StrSubstNo(InvalidValueForTypeMsg, Value, Format(Field.Type::RecordID)));

        if Validate then
            FieldRef.Validate(RecordID)
        else
            FieldRef.Value := RecordID;
    end;

    local procedure IsNormalField(FieldRef: FieldRef): Boolean
    begin
        exit(FieldRef.Class = FieldClass::Normal);
    end;

    procedure XMLFormat(): Integer
    begin
        exit(9);
    end;

    procedure IsKeyField(TableID: Integer; FieldID: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            if FieldRef.Number = FieldID then
                exit(true);
        end;

        exit(false);
    end;

    procedure EvaluateTextToFieldRef(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    begin
        if FieldRef.Class in [FieldClass::FlowField, FieldClass::FlowFilter] then
            exit(true);

        case FieldRef.Type of
            FieldType::Option:
                exit(EvaluateTextToFieldRefOption(InputText, FieldRef, ToValidate));
            FieldType::Integer:
                exit(EvaluateTextToFieldRefInteger(InputText, FieldRef, ToValidate));
            FieldType::Decimal:
                exit(EvaluateTextToFieldRefDecimal(InputText, FieldRef, ToValidate));
            FieldType::Date:
                exit(EvaluateTextToFieldRefDate(InputText, FieldRef, ToValidate));
            FieldType::Time:
                exit(EvaluateTextToFieldRefTime(InputText, FieldRef, ToValidate));
            FieldType::DateTime:
                exit(EvaluateTextToFieldRefDateTime(InputText, FieldRef, ToValidate));
            FieldType::Boolean:
                exit(EvaluateTextToFieldRefBoolean(InputText, FieldRef, ToValidate));
            FieldType::Duration:
                exit(EvaluateTextToFieldRefDuration(InputText, FieldRef, ToValidate));
            FieldType::BigInteger:
                exit(EvaluateTextToFieldRefBigInteger(InputText, FieldRef, ToValidate));
            FieldType::GUID:
                exit(EvaluateTextToFieldRefGUID(InputText, FieldRef, ToValidate));
            FieldType::Code:
                exit(EvaluateTextToFieldRefCodeText(InputText, FieldRef, ToValidate));
            FieldType::Text:
                exit(EvaluateTextToFieldRefCodeText(InputText, FieldRef, ToValidate));
            FieldType::DateFormula:
                exit(EvaluateTextToFieldRefDateFormula(InputText, FieldRef, ToValidate));
            FieldType::TableFilter:
                exit(EvaluateTextToFieldRefTableFilter(InputText, FieldRef));
            FieldType::RecordId:
                exit(EvaluateTextToFieldRefRecordID(InputText, FieldRef, ToValidate));
            else
                exit(false);
        end;

        exit(true);
    end;

    local procedure EvaluateTextToFieldRefOption(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        IntVar: Integer;
        IntVar1: Integer;
    begin
        IntVar := GetOptionNo(InputText, FieldRef);
        if IntVar = -1 then
            exit(false);

        if ToValidate then begin
            IntVar1 := FieldRef.VALUE();
            if IntVar1 <> IntVar then
                FieldRef.Validate(IntVar);
        end else
            FieldRef.Value := IntVar;

        exit(true);
    end;

    local procedure EvaluateTextToFieldRefInteger(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        IntVar: Integer;
        IntVar1: Integer;
    begin
        if Evaluate(IntVar, InputText) then begin
            if ToValidate then begin
                IntVar1 := FieldRef.VALUE();
                if IntVar1 <> IntVar then
                    FieldRef.Validate(IntVar);
            end else
                FieldRef.Value := IntVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDecimal(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DecimalVar: Decimal;
        DecimalVar1: Decimal;
    begin
        if Evaluate(DecimalVar, InputText) then begin
            if ToValidate then begin
                DecimalVar1 := FieldRef.VALUE();
                if DecimalVar1 <> DecimalVar then
                    FieldRef.Validate(DecimalVar);
            end else
                FieldRef.Value := DecimalVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDate(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DateVar: Date;
        DateVar1: Date;
    begin
        if Evaluate(DateVar, InputText) then begin
            if ToValidate then begin
                DateVar1 := FieldRef.VALUE();
                if DateVar1 <> DateVar then
                    FieldRef.Validate(DateVar);
            end else
                FieldRef.Value := DateVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefTime(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        TimeVar: Time;
        TimeVar1: Time;
    begin
        if Evaluate(TimeVar, InputText) then begin
            if ToValidate then begin
                TimeVar1 := FieldRef.VALUE();
                if TimeVar1 <> TimeVar then
                    FieldRef.Validate(TimeVar);
            end else
                FieldRef.Value := TimeVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDateTime(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DateTimeVar: DateTime;
        DateTimeVar1: DateTime;
    begin
        if Evaluate(DateTimeVar, InputText) then begin
            if ToValidate then begin
                DateTimeVar1 := FieldRef.VALUE();
                if DateTimeVar1 <> DateTimeVar then
                    FieldRef.Validate(DateTimeVar);
            end else
                FieldRef.Value := DateTimeVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefBoolean(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        BoolVar: Boolean;
        BoolVar1: Boolean;
    begin
        if Evaluate(BoolVar, InputText) then begin
            if ToValidate then begin
                BoolVar1 := FieldRef.VALUE();
                if BoolVar1 <> BoolVar then
                    FieldRef.Validate(BoolVar);
            end else
                FieldRef.Value := BoolVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefDuration(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DurationVar: Duration;
        DurationVar1: Duration;
    begin
        if Evaluate(DurationVar, InputText) then begin
            if ToValidate then begin
                DurationVar1 := FieldRef.VALUE();
                if DurationVar1 <> DurationVar then
                    FieldRef.Validate(DurationVar);
            end else
                FieldRef.Value := DurationVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefBigInteger(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        BigIntVar: BigInteger;
        BigIntVar1: BigInteger;
    begin
        if Evaluate(BigIntVar, InputText) then begin
            if ToValidate then begin
                BigIntVar1 := FieldRef.VALUE();
                if BigIntVar1 <> BigIntVar then
                    FieldRef.Validate(BigIntVar);
            end else
                FieldRef.Value := BigIntVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefGUID(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        GUIDVar: Guid;
        GUIDVar1: Guid;
    begin
        if Evaluate(GUIDVar, InputText) then begin
            if ToValidate then begin
                GUIDVar1 := FieldRef.Value();
                if GUIDVar1 <> GUIDVar then
                    FieldRef.Validate(GUIDVar);
            end else
                FieldRef.Value := GUIDVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefCodeText(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        TextVar: Text[2048];
        TextVar1: Text[2048];
    begin
        if StrLen(InputText) > FieldRef.Length then begin
            if ToValidate then begin
                TextVar := FieldRef.VALUE();
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

        exit(true);
    end;

    local procedure EvaluateTextToFieldRefDateFormula(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        DateFormulaVar: DateFormula;
        DateFormulaVar1: DateFormula;
    begin
        if Evaluate(DateFormulaVar, InputText) then begin
            if ToValidate then begin
                DateFormulaVar1 := FieldRef.VALUE();
                if DateFormulaVar1 <> DateFormulaVar then
                    FieldRef.Validate(DateFormulaVar);
            end else
                FieldRef.Value := DateFormulaVar;
            exit(true);
        end;

        exit(false);
    end;

    local procedure EvaluateTextToFieldRefTableFilter(InputText: Text; var FieldRef: FieldRef): Boolean
    begin
        Evaluate(FieldRef, InputText);
        exit(true);
    end;

    local procedure EvaluateTextToFieldRefRecordID(InputText: Text; var FieldRef: FieldRef; ToValidate: Boolean): Boolean
    var
        RecordIDVar: RecordId;
        RecordIDVar1: RecordId;
    begin
        if EVALUATE(RecordIDVar, InputText) then begin
            if ToValidate then begin
                RecordIDVar1 := FieldRef.VALUE();
                if RecordIDVar1 <> RecordIDVar then
                    FieldRef.VALIDATE(RecordIDVar);
            end else
                FieldRef.VALUE := RecordIDVar;
            exit(true);
        end;

        exit(false);
    end;

    procedure CheckName(FieldName: Text): Text
    var
        FirstChar: Text[1];
    begin
        FirstChar := PadStr(FieldName, 1);

        case FirstChar of
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
                exit('_' + FieldName);
            else
                exit(FieldName);
        end;
    end;

    procedure AddComment(var FieldRef: FieldRef) RowComment: Text
    var
        FieldBuffer: array[250] of Text[250];
        Text10: Text[1];
        Char10: Char;
        StartPos: Integer;
        FieldNo: Integer;
        i: Integer;
    begin
        StartPos := 1;
        FieldNo := 1;
        Char10 := 10;
        Text10 := Format(Char10);

        RowComment := Format(FieldRef.Type);
        case FieldRef.Type of
            FieldType::Text, FieldType::Code:
                RowComment := RowComment + Format(FieldRef.Length);
        end;

        if FieldRef.Type <> FieldType::Option then
            exit(RowComment);

        Clear(FieldBuffer);

        while not (StartPos = StrLen(FieldRef.OptionCaption) + 1) do begin
            if CopyStr(FieldRef.OptionCaption, StartPos, 1) <> ',' then
                FieldBuffer[FieldNo] := FieldBuffer[FieldNo] + CopyStr(FieldRef.OptionCaption, StartPos, 1)
            else
                FieldNo := FieldNo + 1;
            StartPos := StartPos + 1;
        end;

        for i := 1 to FieldNo do
            RowComment := RowComment + Text10 + Format(i - 1) + ': ' + FieldBuffer[i];
    end;

    local procedure LookupObject(ObjectType: Integer; var ObjectID: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        Clear(Objects);
        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", ObjectType);
        AllObjWithCaption.SetFilter("Object ID", '..%1|%2|%3', 1999999999, DATABASE::"Permission Set", DATABASE::Permission);
        AllObjWithCaption.FilterGroup(0);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode := true;
        if Objects.RunModal() = ACTION::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            ObjectID := AllObjWithCaption."Object ID";
        end;
    end;

    procedure LookupTable(var ObjectID: Integer)
    var
        AllObj: Record AllObj;
    begin
        LookupObject(AllObj."Object Type"::Table, ObjectID);
    end;

    procedure LookupPage(var ObjectID: Integer)
    var
        AllObj: Record AllObj;
    begin
        LookupObject(AllObj."Object Type"::Page, ObjectID);
    end;

    procedure TransferRecordDefaultValues(DataTemplateCode: Code[10]; var RecRef: RecordRef; CurFieldNo: Integer; CurDefaultValue: Text)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        FieldRef: FieldRef;
        DefaultValue: Text;
    begin
        ConfigTemplateLine.SetRange("Data Template Code", DataTemplateCode);
        ConfigTemplateLine.SetRange("Table ID", RecRef.Number);
        ConfigTemplateLine.SetFilter("Field ID", '<>%1', 0);
        if ConfigTemplateLine.FindSet() then
            repeat
                FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");
                if ConfigTemplateLine."Field ID" = CurFieldNo then
                    DefaultValue := CurDefaultValue
                else
                    DefaultValue := ConfigTemplateLine."Default Value";
                OnTransferRecordDefaultValuesOnBeforeValidateFieldValue(RecRef, CurFieldNo, CurDefaultValue);
                ValidateFieldValue(RecRef, FieldRef, DefaultValue, true, ConfigTemplateLine."Language ID");
            until ConfigTemplateLine.Next() = 0;
    end;

    local procedure OADateToDateTime(DateTimeDecimal: Decimal): DateTime
    var
        DotNetDateTime: DotNet DateTime;
        ALDateTime: DateTime;
    begin
        if FromOADate(DotNetDateTime, DateTimeDecimal) then
            Evaluate(ALDateTime, DotNetDateTime.ToString());
        exit(ALDateTime);
    end;

    [TryFunction]
    local procedure FromOADate(var DotNetDateTime: DotNet DateTime; DateTimeDecimal: Decimal)
    begin
        DotNetDateTime := DotNetDateTime.FromOADate(DateTimeDecimal);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Package Table", 'OnBeforeInsertEvent', '', true, true)]
    local procedure ThrowErrorForTablesAddedThatAreNotNormalBeforeInsert(var Rec: Record "Config. Package Table")
    begin
        CheckIfTableIsNormal(Rec)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Package Table", 'OnBeforeRenameEvent', '', true, true)]
    local procedure ThrowErrorForTablesAddedThatAreNotNormalBeforeRename(var Rec: Record "Config. Package Table")
    begin
        CheckIfTableIsNormal(Rec)
    end;

    local procedure CheckIfTableIsNormal(ConfigPackageTable: Record "Config. Package Table")
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(ConfigPackageTable."Table ID") then
            if TableMetadata.TableType <> TableMetadata.TableType::Normal then
                Error(ExternalTablesAreNotAllowedErr);
    end;

    local procedure RoundDecimalValue(var DecimalFieldRef: FieldRef; var DecimalValue: Decimal)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ShouldRound: Boolean;
    begin
        // Special rounding for all Qty. per Unit of Measure fields to 5 decimals
        ShouldRound := DecimalFieldRef.Name = ItemUnitofMeasure.FieldName("Qty. per Unit of Measure");
        OnBeforeRoundDecimalValue(DecimalFieldRef, DecimalValue, ShouldRound);
        if ShouldRound then
            DecimalValue := Round(DecimalValue, 0.00001);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundDecimalValue(var DecimalFieldRef: FieldRef; var DecimalValue: Decimal; var ShouldRound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferRecordDefaultValuesOnBeforeValidateFieldValue(var RecordReference: RecordRef; CurFieldNo: Integer; CurDefaultValue: Text)
    begin
    end;
}

