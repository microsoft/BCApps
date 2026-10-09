namespace System.IO;

#if not CLEAN30
using System;
#endif
using System.Reflection;
using System.Utilities;

table 1236 "JSON Buffer"
{
    Caption = 'JSON Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Depth; Integer)
        {
            Caption = 'Depth';
            DataClassification = SystemMetadata;
        }
        field(3; "Token type"; Option)
        {
            Caption = 'Token type';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,Start Object,Start Array,Start Constructor,Property Name,Comment,Raw,Integer,Decimal,String,Boolean,Null,Undefined,End Object,End Array,End Constructor,Date,Bytes';
            OptionMembers = "None","Start Object","Start Array","Start Constructor","Property Name",Comment,Raw,"Integer",Decimal,String,Boolean,Null,Undefined,"End Object","End Array","End Constructor",Date,Bytes;
        }
        field(4; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(5; "Value Type"; Text[50])
        {
            Caption = 'Value Type';
            DataClassification = SystemMetadata;
        }
        field(6; Path; Text[250])
        {
            Caption = 'Path';
            DataClassification = SystemMetadata;
        }
        field(7; "Value BLOB"; BLOB)
        {
            Caption = 'Value BLOB';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        DevMsgNotTemporaryErr: Label 'This function can only be used when the record is temporary.';
        InvalidJSONErr: Label 'The JSON text is invalid.';
        UnsupportedJSONValueErr: Label 'The JSON text contains a value that is not supported by standard JSON.';
        SystemBooleanTxt: Label 'System.Boolean', Locked = true;
        SystemDateTimeTxt: Label 'System.DateTime', Locked = true;
        SystemDoubleTxt: Label 'System.Double', Locked = true;
        SystemInt64Txt: Label 'System.Int64', Locked = true;
        SystemStringTxt: Label 'System.String', Locked = true;

#if not CLEAN30
    [Obsolete('Use ReadFromBlobStrict for standard JSON. Json.NET-only syntax is not supported by the strict parser.', '30.0')]
    procedure ReadFromBlob(BlobFieldRef: FieldRef)
    var
        TypeHelper: Codeunit "Type Helper";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecordRef(BlobFieldRef.Record(), BlobFieldRef.Number);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
#pragma warning disable AL0432
        ReadFromText(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
#pragma warning restore AL0432
    end;

    [Obsolete('Use ReadFromTextStrict for standard JSON. Json.NET-only syntax is not supported by the strict parser.', '30.0')]
    procedure ReadFromText(JSONText: Text)
    var
        JSONTextReader: DotNet JsonTextReader;
        StringReader: DotNet StringReader;
        TokenType: Integer;
        FormatValue: Integer;
    begin
        if not IsTemporary then
            Error(DevMsgNotTemporaryErr);
        DeleteAll();
        JSONTextReader := JSONTextReader.JsonTextReader(StringReader.StringReader(JSONText));
        if JSONTextReader.Read() then
            repeat
                Init();
                "Entry No." += 1;
                Depth := JSONTextReader.Depth;
                TokenType := JSONTextReader.TokenType;
                "Token type" := TokenType;
                if IsNull(JSONTextReader.Value) then
                    Value := ''
                else begin
                    if JSONTextReader.ValueType.ToString() = 'System.DateTime' then
                        FormatValue := 1
                    else
                        FormatValue := 0;
                    SetValueWithoutModifying(Format(JSONTextReader.Value, 0, FormatValue));
                end;

                if IsNull(JSONTextReader.ValueType) then
                    "Value Type" := ''
                else
                    "Value Type" := Format(JSONTextReader.ValueType);
                Path := JSONTextReader.Path;
                Insert();
            until not JSONTextReader.Read();
    end;
#endif

    procedure ReadFromBlobStrict(BlobFieldRef: FieldRef)
    var
        TypeHelper: Codeunit "Type Helper";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecordRef(BlobFieldRef.Record(), BlobFieldRef.Number);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        ReadFromTextStrict(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
    end;

    procedure ReadFromTextStrict(JSONText: Text)
    var
        JSONToken: JsonToken;
    begin
        if not IsTemporary then
            Error(DevMsgNotTemporaryErr);
        DeleteAll();

        if JSONText.Trim() = '' then
            exit;

        if not IsStrictJSONDocument(JSONText) then
            Error(InvalidJSONErr);

        if not TryReadJSONToken(JSONText, JSONToken) then
            Error(InvalidJSONErr);

        ReadJSONToken(JSONToken, 0);
    end;

    local procedure TryReadJSONToken(JSONText: Text; var JSONToken: JsonToken): Boolean
    var
        JSONArray: JsonArray;
        JSONObject: JsonObject;
        JSONValue: JsonValue;
    begin
        case CopyStr(JSONText.Trim(), 1, 1) of
            '{':
                begin
                    if not JSONObject.ReadFrom(JSONText) then
                        exit(false);
                    JSONToken := JSONObject.AsToken();
                end;
            '[':
                begin
                    if not JSONArray.ReadFrom(JSONText) then
                        exit(false);
                    JSONToken := JSONArray.AsToken();
                end;
            else begin
                if not JSONValue.ReadFrom(JSONText) then
                    exit(false);
                JSONToken := JSONValue.AsToken();
            end;
        end;
        exit(true);
    end;

    // Validates the complete document against the RFC 8259 grammar, because the native parser accepts nonstandard syntax.
    local procedure IsStrictJSONDocument(var JSONText: Text): Boolean
    var
        Position: Integer;
    begin
        Position := 1;
        SkipJSONWhitespace(JSONText, Position);
        if not ScanJSONValue(JSONText, Position) then
            exit(false);
        SkipJSONWhitespace(JSONText, Position);
        exit(Position > StrLen(JSONText));
    end;

    local procedure ScanJSONValue(var JSONText: Text; var Position: Integer): Boolean
    begin
        if Position > StrLen(JSONText) then
            exit(false);

        case JSONText[Position] of
            '{':
                exit(ScanJSONObject(JSONText, Position));
            '[':
                exit(ScanJSONArray(JSONText, Position));
            '"':
                exit(ScanJSONString(JSONText, Position));
            't':
                exit(ScanJSONLiteral(JSONText, Position, 'true'));
            'f':
                exit(ScanJSONLiteral(JSONText, Position, 'false'));
            'n':
                exit(ScanJSONLiteral(JSONText, Position, 'null'));
            '-', '0' .. '9':
                exit(ScanJSONNumber(JSONText, Position));
        end;
        exit(false);
    end;

    local procedure ScanJSONObject(var JSONText: Text; var Position: Integer): Boolean
    begin
        Position += 1;
        SkipJSONWhitespace(JSONText, Position);
        if IsJSONCharacter(JSONText, Position, '}') then begin
            Position += 1;
            exit(true);
        end;

        repeat
            if not IsJSONCharacter(JSONText, Position, '"') then
                exit(false);
            if not ScanJSONString(JSONText, Position) then
                exit(false);
            SkipJSONWhitespace(JSONText, Position);
            if not IsJSONCharacter(JSONText, Position, ':') then
                exit(false);
            Position += 1;
            SkipJSONWhitespace(JSONText, Position);
            if not ScanJSONValue(JSONText, Position) then
                exit(false);
            SkipJSONWhitespace(JSONText, Position);
            if IsJSONCharacter(JSONText, Position, '}') then begin
                Position += 1;
                exit(true);
            end;
            if not IsJSONCharacter(JSONText, Position, ',') then
                exit(false);
            Position += 1;
            SkipJSONWhitespace(JSONText, Position);
        until false;
    end;

    local procedure ScanJSONArray(var JSONText: Text; var Position: Integer): Boolean
    begin
        Position += 1;
        SkipJSONWhitespace(JSONText, Position);
        if IsJSONCharacter(JSONText, Position, ']') then begin
            Position += 1;
            exit(true);
        end;

        repeat
            if not ScanJSONValue(JSONText, Position) then
                exit(false);
            SkipJSONWhitespace(JSONText, Position);
            if IsJSONCharacter(JSONText, Position, ']') then begin
                Position += 1;
                exit(true);
            end;
            if not IsJSONCharacter(JSONText, Position, ',') then
                exit(false);
            Position += 1;
            SkipJSONWhitespace(JSONText, Position);
        until false;
    end;

    local procedure ScanJSONString(var JSONText: Text; var Position: Integer): Boolean
    var
        CharacterCode: Integer;
        EscapeIsValid: Boolean;
        HexDigitIndex: Integer;
    begin
        Position += 1;
        while Position <= StrLen(JSONText) do begin
            CharacterCode := JSONText[Position];
            case true of
                CharacterCode = 34: // "
                    begin
                        Position += 1;
                        exit(true);
                    end;
                CharacterCode < 32:
                    exit(false);
                CharacterCode = 92: // \
                    begin
                        Position += 1;
                        if Position > StrLen(JSONText) then
                            exit(false);
                        if IsJSONCharacter(JSONText, Position, 'u') then begin
                            EscapeIsValid := true;
                            for HexDigitIndex := 1 to 4 do begin
                                Position += 1;
                                EscapeIsValid := EscapeIsValid and IsJSONHexDigit(JSONText, Position);
                            end;
                        end else
                            EscapeIsValid := StrPos('"\/bfnrt', CopyStr(JSONText, Position, 1)) <> 0;
                        if not EscapeIsValid then
                            exit(false);
                    end;
            end;
            Position += 1;
        end;
        exit(false);
    end;

    local procedure ScanJSONNumber(var JSONText: Text; var Position: Integer): Boolean
    var
        HasLeadingZero: Boolean;
    begin
        if IsJSONCharacter(JSONText, Position, '-') then
            Position += 1;

        HasLeadingZero := IsJSONCharacter(JSONText, Position, '0');
        if HasLeadingZero then
            Position += 1
        else
            if not ScanJSONDigits(JSONText, Position) then
                exit(false);

        if IsJSONCharacter(JSONText, Position, '.') then begin
            Position += 1;
            if not ScanJSONDigits(JSONText, Position) then
                exit(false);
        end;

        if IsJSONCharacter(JSONText, Position, 'e') or IsJSONCharacter(JSONText, Position, 'E') then begin
            Position += 1;
            if IsJSONCharacter(JSONText, Position, '+') or IsJSONCharacter(JSONText, Position, '-') then
                Position += 1;
            if not ScanJSONDigits(JSONText, Position) then
                exit(false);
        end;

        exit(true);
    end;

    local procedure ScanJSONDigits(var JSONText: Text; var Position: Integer): Boolean
    var
        StartPosition: Integer;
    begin
        StartPosition := Position;
        while IsJSONDigit(JSONText, Position) do
            Position += 1;
        exit(Position > StartPosition);
    end;

    local procedure ScanJSONLiteral(JSONText: Text; var Position: Integer; Literal: Text): Boolean
    begin
        if CopyStr(JSONText, Position, StrLen(Literal)) <> Literal then
            exit(false);
        Position += StrLen(Literal);
        exit(true);
    end;

    local procedure SkipJSONWhitespace(var JSONText: Text; var Position: Integer)
    begin
        while IsJSONWhitespace(JSONText, Position) do
            Position += 1;
    end;

    local procedure IsJSONWhitespace(JSONText: Text; Position: Integer): Boolean
    var
        CharacterCode: Integer;
    begin
        if Position > StrLen(JSONText) then
            exit(false);
        CharacterCode := JSONText[Position];
        exit(CharacterCode in [9, 10, 13, 32]);
    end;

    local procedure IsJSONCharacter(JSONText: Text; Position: Integer; ExpectedCharacter: Char): Boolean
    begin
        if Position > StrLen(JSONText) then
            exit(false);
        exit(JSONText[Position] = ExpectedCharacter);
    end;

    local procedure IsJSONDigit(JSONText: Text; Position: Integer): Boolean
    begin
        if Position > StrLen(JSONText) then
            exit(false);
        exit(JSONText[Position] in ['0' .. '9']);
    end;

    local procedure IsJSONHexDigit(JSONText: Text; Position: Integer): Boolean
    begin
        if Position > StrLen(JSONText) then
            exit(false);
        exit(JSONText[Position] in ['0' .. '9', 'a' .. 'f', 'A' .. 'F']);
    end;

    local procedure ReadJSONToken(JSONToken: JsonToken; TokenDepth: Integer)
    var
        ChildJSONToken: JsonToken;
        JSONArray: JsonArray;
        JSONObject: JsonObject;
        ArrayIndex: Integer;
        PropertyName: Text;
    begin
        case true of
            JSONToken.IsObject():
                begin
                    InsertJSONBufferRow(TokenDepth, "Token type"::"Start Object", '', '', JSONToken.Path());
                    JSONObject := JSONToken.AsObject();
                    foreach PropertyName in JSONObject.Keys() do begin
                        JSONObject.Get(PropertyName, ChildJSONToken);
                        InsertJSONBufferRow(TokenDepth + 1, "Token type"::"Property Name", PropertyName, SystemStringTxt, ChildJSONToken.Path());
                        ReadJSONToken(ChildJSONToken, TokenDepth + 1);
                    end;
                    InsertJSONBufferRow(TokenDepth, "Token type"::"End Object", '', '', JSONToken.Path());
                end;
            JSONToken.IsArray():
                begin
                    InsertJSONBufferRow(TokenDepth, "Token type"::"Start Array", '', '', JSONToken.Path());
                    JSONArray := JSONToken.AsArray();
                    for ArrayIndex := 0 to JSONArray.Count() - 1 do begin
                        JSONArray.Get(ArrayIndex, ChildJSONToken);
                        ReadJSONToken(ChildJSONToken, TokenDepth + 1);
                    end;
                    InsertJSONBufferRow(TokenDepth, "Token type"::"End Array", '', '', JSONToken.Path());
                end;
            JSONToken.IsValue():
                ReadJSONValue(JSONToken, TokenDepth);
            else
                Error(UnsupportedJSONValueErr);
        end;
    end;

    local procedure ReadJSONValue(JSONToken: JsonToken; TokenDepth: Integer)
    var
        JSONValue: JsonValue;
        BigIntegerValue: BigInteger;
        BooleanValue: Boolean;
        DecimalValue: Decimal;
        SerializedValue: Text;
        ValueText: Text;
    begin
        JSONValue := JSONToken.AsValue();
        if JSONValue.IsNull() then begin
            InsertJSONBufferRow(TokenDepth, "Token type"::Null, '', '', JSONToken.Path());
            exit;
        end;
        if JSONValue.IsUndefined() then
            Error(UnsupportedJSONValueErr);

        JSONToken.WriteTo(SerializedValue);
        case SerializedValue of
            'true',
            'false':
                begin
                    BooleanValue := JSONValue.AsBoolean();
                    if BooleanValue then
                        ValueText := 'Yes'
                    else
                        ValueText := 'No';
                    InsertJSONBufferRow(TokenDepth, "Token type"::Boolean, ValueText, SystemBooleanTxt, JSONToken.Path());
                end;
            else
                if SerializedValue.StartsWith('"') then begin
                    ValueText := JSONValue.AsText();
                    if IsJSONDateTime(ValueText) then
                        InsertJSONBufferRow(TokenDepth, "Token type"::Date, ValueText, SystemDateTimeTxt, JSONToken.Path())
                    else
                        InsertJSONBufferRow(TokenDepth, "Token type"::String, ValueText, SystemStringTxt, JSONToken.Path());
                end else
                    if (StrPos(SerializedValue, '.') = 0) and (StrPos(LowerCase(SerializedValue), 'e') = 0) then begin
                        BigIntegerValue := JSONValue.AsBigInteger();
                        InsertJSONBufferRow(TokenDepth, "Token type"::Integer, Format(BigIntegerValue), SystemInt64Txt, JSONToken.Path());
                    end else begin
                        DecimalValue := JSONValue.AsDecimal();
                        InsertJSONBufferRow(TokenDepth, "Token type"::Decimal, Format(DecimalValue), SystemDoubleTxt, JSONToken.Path());
                    end;
        end;
    end;

    local procedure InsertJSONBufferRow(TokenDepth: Integer; TokenType: Option; NewValue: Text; NewValueType: Text; TokenPath: Text)
    begin
        Init();
        "Entry No." += 1;
        Depth := TokenDepth;
        "Token type" := TokenType;
        SetValueWithoutModifying(NewValue);
        "Value Type" := CopyStr(NewValueType, 1, MaxStrLen("Value Type"));
        Path := CopyStr(TokenPath, 1, MaxStrLen(Path));
        Insert();
    end;

    local procedure IsJSONDateTime(ValueText: Text): Boolean
    var
        DateTimeValue: DateTime;
        ValueToEvaluate: Text;
    begin
        if (StrLen(ValueText) < 19) or
           (CopyStr(ValueText, 5, 1) <> '-') or
           (CopyStr(ValueText, 8, 1) <> '-') or
           (CopyStr(ValueText, 11, 1) <> 'T') or
           (CopyStr(ValueText, 14, 1) <> ':') or
           (CopyStr(ValueText, 17, 1) <> ':')
        then
            exit(false);

        if Evaluate(DateTimeValue, ValueText, 9) then
            exit(true);

        ValueToEvaluate := ValueText;
        if not HasJSONTimeZone(ValueToEvaluate) then
            ValueToEvaluate += 'Z';

        exit(Evaluate(DateTimeValue, ValueToEvaluate, 9));
    end;

    local procedure HasJSONTimeZone(ValueText: Text): Boolean
    var
        TimeZoneText: Text;
    begin
        if ValueText.EndsWith('Z') or ValueText.EndsWith('z') then
            exit(true);
        if StrLen(ValueText) <= 19 then
            exit(false);

        TimeZoneText := CopyStr(ValueText, 20);
        exit(TimeZoneText.Contains('+') or TimeZoneText.Contains('-'));
    end;

    procedure FindArray(var TempJSONBuffer: Record "JSON Buffer" temporary; ArrayName: Text): Boolean
    begin
        TempJSONBuffer.Copy(Rec, true);
        TempJSONBuffer.Reset();

        TempJSONBuffer.SetRange(Path, AppendPathToCurrent(ArrayName));
        if not TempJSONBuffer.FindFirst() then
            exit(false);
        TempJSONBuffer.SetFilter(Path, AppendPathToCurrent(ArrayName) + '[*');
        TempJSONBuffer.SetRange(Depth, TempJSONBuffer.Depth + 1);
        TempJSONBuffer.SetFilter("Token type", '<>%1', "Token type"::"End Object");
        exit(TempJSONBuffer.FindSet());
    end;

    procedure GetPropertyValue(var PropertyValue: Text; PropertyName: Text): Boolean
    begin
        exit(GetPropertyValueAtPath(PropertyValue, PropertyName, Path + '*'));
    end;

    procedure GetPropertyValueAtPath(var PropertyValue: Text; PropertyName: Text; PropertyPath: Text): Boolean
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
    begin
        TempJSONBuffer.Copy(Rec, true);
        TempJSONBuffer.Reset();

        TempJSONBuffer.SetFilter(Path, PropertyPath);
        TempJSONBuffer.SetRange("Token type", "Token type"::"Property Name");
        TempJSONBuffer.SetRange(Value, PropertyName);
        if not TempJSONBuffer.FindFirst() then
            exit;
        if TempJSONBuffer.Get(TempJSONBuffer."Entry No." + 1) then begin
            PropertyValue := TempJSONBuffer.GetValue();
            exit(true);
        end;
    end;

    procedure GetBooleanPropertyValue(var BooleanValue: Boolean; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(BooleanValue, PropertyValue));
    end;

    procedure GetIntegerPropertyValue(var IntegerValue: Integer; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(IntegerValue, PropertyValue));
    end;

    procedure GetDatePropertyValue(var DateValue: Date; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(DateValue, PropertyValue));
    end;

    procedure GetDecimalPropertyValue(var DecimalValue: Decimal; PropertyName: Text): Boolean
    var
        PropertyValue: Text;
    begin
        if GetPropertyValue(PropertyValue, PropertyName) then
            exit(Evaluate(DecimalValue, PropertyValue));
    end;

    local procedure AppendPathToCurrent(AppendPath: Text): Text
    begin
        if Path <> '' then
            exit(Path + '.' + AppendPath);
        exit(AppendPath)
    end;

    procedure GetValue(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Value BLOB");
        if not "Value BLOB".HasValue() then
            exit(Value);

        "Value BLOB".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetValue(NewValue: Text)
    begin
        SetValueWithoutModifying(NewValue);
        Modify();
    end;

    procedure SetValueWithoutModifying(NewValue: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Value BLOB");
        Value := CopyStr(NewValue, 1, MaxStrLen(Value));
        if StrLen(NewValue) <= MaxStrLen(Value) then
            exit; // No need to store anything in the blob
        if NewValue = '' then
            exit;

        "Value BLOB".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(NewValue);
    end;
}
