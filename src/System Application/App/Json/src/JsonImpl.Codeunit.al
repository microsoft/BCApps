// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text.Json;

using System;
using System.Text;
using System.Utilities;

codeunit 5461 "Json Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SourceWarningLength: Integer;
        JsonArrayState: JsonArray;
        JsonObjectState: JsonObject;
        InvalidJsonArrayErr: Label 'The value is not a valid JSON array.';
        InvalidJsonObjectErr: Label 'The value is not a valid JSON object.';
        LogLimitWarningTxt: Label 'The JSON input length (%1) exceeds the maximum suggested length (%2) for JSON processing.', Locked = true;

    internal procedure EmitLengthWarning(SourceLength: Integer; tag: Text; FormatString: Text)
    begin
        if SourceWarningLength <= 0 then
            SourceWarningLength := 10485760; // 10 * 1024 * 1024 = 10 MB

        if SourceLength > SourceWarningLength then
            Session.LogMessage(tag, StrSubstNo(FormatString, SourceLength, SourceWarningLength), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'resources', 'memory');
    end;

    procedure InitializeCollectionFromString(JSONString: Text)
    var
        NewJsonArray: JsonArray;
    begin
        if JSONString <> '' then begin
            EmitLengthWarning(StrLen(JSONString), '0000QNC', LogLimitWarningTxt);
            if not NewJsonArray.ReadFrom(JSONString) then
                Error(InvalidJsonArrayErr);
        end;
        JsonArrayState := NewJsonArray;
    end;

    procedure InitializeObjectFromString(JSONString: Text)
    begin
        if JSONString <> '' then
            EmitLengthWarning(StrLen(JSONString), '0000QND', LogLimitWarningTxt);
        SetObjectStateFromString(JSONString);
    end;

    procedure GetCollectionCount(): Integer
    begin
        exit(JsonArrayState.Count());
    end;

    procedure GetCollectionAsText() Value: Text
    begin
        JsonArrayState.WriteTo(Value);
    end;

    procedure GetCollectionAsText(Indentation: Boolean) Value: Text
    var
        JsonTextBuilder: TextBuilder;
    begin
        if not Indentation then
            exit(GetCollectionAsText());

        AppendJsonArray(JsonArrayState, 0, JsonTextBuilder);
        exit(JsonTextBuilder.ToText());
    end;

    procedure GetCollection() JsonArray: JsonArray
    begin
        exit(JsonArrayState.Clone().AsArray());
    end;

    procedure GetObjectAsText() Value: Text
    begin
        JsonObjectState.WriteTo(Value);
    end;

    procedure GetObject() JsonObject: JsonObject
    begin
        exit(JsonObjectState.Clone().AsObject());
    end;

    procedure GetObjectFromCollectionByIndex(Index: Integer; var JsonObjectTxt: Text): Boolean
    begin
        if not SelectObjectFromCollection(Index) then
            exit(false);

        JsonObjectState.WriteTo(JsonObjectTxt);
        exit(true);
    end;

    procedure GetValueAndSetToRecFieldNo(RecordRef: RecordRef; PropertyPath: Text; FieldNo: Integer): Boolean
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(FieldNo);
        exit(GetPropertyValueFromJObjectByPathSetToFieldRef(PropertyPath, FieldRef));
    end;

#if not CLEAN30
    procedure GetPropertyValueFromJObjectByName(PropertyName: Text; var Value: Variant): Boolean
    var
        JTokenDotNet: DotNet JToken;
        JsonToken: JsonToken;
        JsonText: Text;
    begin
        Clear(Value);
        if not JsonObjectState.Get(PropertyName, JsonToken) then
            exit(false);

        JsonToken.WriteTo(JsonText);
        JTokenDotNet := JTokenDotNet.Parse(JsonText);
        Value := JTokenDotNet;
        exit(true);
    end;
#endif

    procedure GetNativePropertyValueFromJObjectByName(PropertyName: Text; var Value: Variant): Boolean
    var
        JsonToken: JsonToken;
    begin
        Clear(Value);
        if not JsonObjectState.Get(PropertyName, JsonToken) then
            exit(false);

        JsonTokenToVariant(JsonToken, Value);
        exit(true);
    end;

    procedure GetStringPropertyValueFromJObjectByName(PropertyName: Text; var Value: Text): Boolean
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        Clear(Value);
        if not JsonObjectState.Get(PropertyName, JsonToken) then
            exit(false);
        if not JsonToken.IsValue() then begin
            JsonToken.WriteTo(Value);
            exit(true);
        end;

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() or JsonValue.IsUndefined() then
            exit(true);

        Value := GetJsonValueAsText(JsonToken);
        exit(true);
    end;

    procedure GetEnumPropertyValueFromJObjectByName(PropertyName: Text; var Value: Option): Boolean
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        if not GetJsonValueByName(PropertyName, JsonToken) then
            exit(false);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() or JsonValue.IsUndefined() then
            exit(true);

        Evaluate(Value, JsonValue.AsText(), 0);
        exit(true);
    end;

    procedure GetBoolPropertyValueFromJObjectByName(PropertyName: Text; var Value: Boolean): Boolean
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        Clear(Value);
        if not GetJsonValueByName(PropertyName, JsonToken) then
            exit(false);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() or JsonValue.IsUndefined() then
            exit(true);

        Value := JsonValue.AsBoolean();
        exit(true);
    end;

    procedure GetDecimalPropertyValueFromJObjectByName(PropertyName: Text; var Value: Decimal): Boolean
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        Clear(Value);
        if not GetJsonValueByName(PropertyName, JsonToken) then
            exit(false);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() or JsonValue.IsUndefined() then
            exit(true);

        Value := JsonValue.AsDecimal();
        exit(true);
    end;

    procedure GetIntegerPropertyValueFromJObjectByName(PropertyName: Text; var Value: Integer): Boolean
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        Clear(Value);
        if not GetJsonValueByName(PropertyName, JsonToken) then
            exit(false);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() or JsonValue.IsUndefined() then
            exit(true);

        Value := JsonValue.AsInteger();
        exit(true);
    end;

    procedure GetGuidPropertyValueFromJObjectByName(PropertyName: Text; var Value: Guid): Boolean
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        Clear(Value);
        if not GetJsonValueByName(PropertyName, JsonToken) then
            exit(false);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() or JsonValue.IsUndefined() then
            exit(true);

        Evaluate(Value, JsonValue.AsText());
        exit(true);
    end;

    procedure ReplaceOrAddJPropertyInJObject(PropertyName: Text; Value: Variant): Boolean
    var
        NewJsonToken: JsonToken;
        OldJsonToken: JsonToken;
        NewValueText: Text;
        OldValueText: Text;
    begin
        CreateJsonTokenFromVariant(Value, NewJsonToken);
        NewJsonToken.WriteTo(NewValueText);

        if JsonObjectState.Get(PropertyName, OldJsonToken) then begin
            OldJsonToken.WriteTo(OldValueText);
            if OldValueText = NewValueText then
                exit(false);
            ReplaceJsonPropertyPreservingOrder(PropertyName, NewJsonToken);
            exit(true);
        end;

        JsonObjectState.Add(PropertyName, NewJsonToken);
        exit(true);
    end;

    local procedure ReplaceJsonPropertyPreservingOrder(PropertyName: Text; NewJsonToken: JsonToken)
    var
        RebuiltJsonObject: JsonObject;
        PropertyJsonToken: JsonToken;
        PropertyNames: List of [Text];
        CurrentPropertyName: Text;
    begin
        PropertyNames := JsonObjectState.Keys();
        foreach CurrentPropertyName in PropertyNames do
            if CurrentPropertyName = PropertyName then
                RebuiltJsonObject.Add(CurrentPropertyName, NewJsonToken.Clone())
            else begin
                JsonObjectState.Get(CurrentPropertyName, PropertyJsonToken);
                RebuiltJsonObject.Add(CurrentPropertyName, PropertyJsonToken.Clone());
            end;

        foreach CurrentPropertyName in PropertyNames do
            JsonObjectState.Remove(CurrentPropertyName);

        foreach CurrentPropertyName in PropertyNames do begin
            RebuiltJsonObject.Get(CurrentPropertyName, PropertyJsonToken);
            JsonObjectState.Add(CurrentPropertyName, PropertyJsonToken.Clone());
        end;
    end;

    procedure AddJObjectToCollection(JSONString: Text): Boolean
    begin
        SetObjectStateFromString(JSONString);
        AddJObjectToCollection();
        exit(true);
    end;

    procedure RemoveJObjectFromCollection(Index: Integer): Boolean
    begin
        if not IsValidCollectionIndex(Index) then
            exit(false);

        JsonArrayState.RemoveAt(Index);
        exit(true);
    end;

    procedure ReplaceJObjectInCollection(Index: Integer; JSONString: Text): Boolean
    begin
        if not SelectObjectFromCollection(Index) then
            exit(false);

        SetObjectStateFromString(JSONString);
        JsonArrayState.Set(Index, JsonObjectState);
        exit(true);
    end;

    local procedure SelectObjectFromCollection(Index: Integer): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not IsValidCollectionIndex(Index) then
            exit(false);
        if not JsonArrayState.Get(Index, JsonToken) then
            exit(false);
        if not JsonToken.IsObject() then
            exit(false);

        JsonObjectState := JsonToken.AsObject();
        exit(true);
    end;

    local procedure IsValidCollectionIndex(Index: Integer): Boolean
    begin
        exit((Index >= 0) and (Index < JsonArrayState.Count()));
    end;

    local procedure GetJsonValueByName(PropertyName: Text; var JsonToken: JsonToken): Boolean
    begin
        if not JsonObjectState.Get(PropertyName, JsonToken) then
            exit(false);
        if not JsonToken.IsValue() then
            exit(false);

        exit(true);
    end;

    local procedure JsonTokenToVariant(JsonToken: JsonToken; var Value: Variant)
    var
        BigIntegerValue: BigInteger;
        BooleanValue: Boolean;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        JsonArrayValue: JsonArray;
        JsonObjectValue: JsonObject;
        JsonValue: JsonValue;
        SerializedValue: Text;
        TextValue: Text;
    begin
        Clear(Value);
        case true of
            JsonToken.IsObject():
                begin
                    JsonObjectValue := JsonToken.AsObject();
                    Value := JsonObjectValue;
                end;
            JsonToken.IsArray():
                begin
                    JsonArrayValue := JsonToken.AsArray();
                    Value := JsonArrayValue;
                end;
            JsonToken.IsValue():
                begin
                    JsonValue := JsonToken.AsValue();
                    if JsonValue.IsNull() or JsonValue.IsUndefined() then
                        exit;

                    JsonToken.WriteTo(SerializedValue);
                    if SerializedValue.StartsWith('"') then begin
                        TextValue := JsonValue.AsText();
                        Value := TextValue;
                    end else
                        if (SerializedValue = 'true') or (SerializedValue = 'false') then begin
                            BooleanValue := JsonValue.AsBoolean();
                            Value := BooleanValue;
                        end else
                            if (StrPos(SerializedValue, '.') = 0) and (StrPos(LowerCase(SerializedValue), 'e') = 0) and TryGetJsonInteger(JsonValue, IntegerValue) then
                                Value := IntegerValue
                            else
                                if (StrPos(SerializedValue, '.') = 0) and (StrPos(LowerCase(SerializedValue), 'e') = 0) and TryGetJsonBigInteger(JsonValue, BigIntegerValue) then
                                    Value := BigIntegerValue
                                else
                                    if TryGetJsonDecimal(JsonValue, DecimalValue) then
                                        Value := DecimalValue
                                    else begin
                                        TextValue := SerializedValue;
                                        Value := TextValue;
                                    end;
                end;
        end;
    end;

    local procedure GetJsonValueAsText(JsonToken: JsonToken): Text
    var
        SerializedValue: Text;
    begin
        JsonToken.WriteTo(SerializedValue);
        case SerializedValue of
            'true':
                exit('True');
            'false':
                exit('False');
        end;
        exit(JsonToken.AsValue().AsText());
    end;

    [TryFunction]
    local procedure TryGetJsonInteger(JsonValue: JsonValue; var IntegerValue: Integer)
    begin
        IntegerValue := JsonValue.AsInteger();
    end;

    [TryFunction]
    local procedure TryGetJsonBigInteger(JsonValue: JsonValue; var BigIntegerValue: BigInteger)
    begin
        BigIntegerValue := JsonValue.AsBigInteger();
    end;

    [TryFunction]
    local procedure TryGetJsonDecimal(JsonValue: JsonValue; var DecimalValue: Decimal)
    begin
        DecimalValue := JsonValue.AsDecimal();
    end;

    local procedure GetPropertyValueFromJObjectByPathSetToFieldRef(PropertyPath: Text; var FieldRef: FieldRef): Boolean
    var
        RecID: RecordId;
        Value: Text;
        IntVar: Integer;
        DecimalVal: Decimal;
        GuidVal: Guid;
        DateVal: Date;
        BoolVal, Success : Boolean;
        JsonToken: JsonToken;
        JsonValue: JsonValue;
    begin
        if not JsonObjectState.SelectToken(PropertyPath, JsonToken) then
            exit(false);
        if not JsonToken.IsValue() then
            exit(false);

        JsonValue := JsonToken.AsValue();
        if not (JsonValue.IsNull() or JsonValue.IsUndefined()) then
            Value := JsonValue.AsText();

        case FieldRef.Type of
            FieldType::Integer,
            FieldType::Decimal:
                begin
                    Success := Evaluate(DecimalVal, Value, 9);
                    FieldRef.Value(DecimalVal);
                end;
            FieldType::Date:
                begin
                    Success := Evaluate(DateVal, Value, 9);
                    FieldRef.Value(DateVal);
                end;
            FieldType::Boolean:
                begin
                    Success := Evaluate(BoolVal, Value, 9);
                    FieldRef.Value(BoolVal);
                end;
            FieldType::GUID:
                begin
                    Success := Evaluate(GuidVal, Value);
                    FieldRef.Value(GuidVal);
                end;
            FieldType::Text,
            FieldType::Code:
                begin
                    FieldRef.Value(CopyStr(Value, 1, FieldRef.Length));
                    Success := true;
                end;
            FieldType::Option:
                begin
                    if not Evaluate(IntVar, Value) then
                        IntVar := TextToOptionValue(Value, FieldRef.OptionCaption);
                    if IntVar >= 0 then begin
                        FieldRef.Value := IntVar;
                        Success := true;
                    end;
                end;
            FieldType::BLOB:
                if TryReadAsBase64(FieldRef, Value) then
                    Success := true;
            FieldType::RecordID:
                begin
                    Success := Evaluate(RecID, Value);
                    FieldRef.Value(RecID);
                end;
        end;

        exit(Success);
    end;

    [TryFunction]
    local procedure TryReadAsBase64(var BlobFieldRef: FieldRef; Value: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(Value, OutStream);
        RecordRef := BlobFieldRef.Record();
        TempBlob.ToRecordRef(RecordRef, BlobFieldRef.Number);
    end;

    local procedure TextToOptionValue(InputText: Text; OptionString: Text): Integer
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

    local procedure GetSubStrByNo(Number: Integer; CommaString: Text) SelectedStr: Text
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

    local procedure CreateJsonTokenFromVariant(Value: Variant; var JsonToken: JsonToken)
    var
        JsonObject: JsonObject;
    begin
        AddJPropertyToJObject(JsonObject, 'value', Value);
        JsonObject.Get('value', JsonToken);
    end;

    local procedure AddJPropertyToJObject(var JsonObject: JsonObject; PropertyName: Text; Value: Variant)
    var
#if not CLEAN30
        JTokenDotNet: DotNet JToken;
        JsonFormatting: DotNet Formatting;
        JsonText: Text;
#endif
        BigIntegerValue: BigInteger;
        JsonArrayValue: JsonArray;
        JsonObjectValue: JsonObject;
        JsonTokenValue: JsonToken;
        JsonValueValue: JsonValue;
        BooleanValue: Boolean;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        ValueText: Text;
    begin
        case true of
#if not CLEAN30
            Value.IsDotNet:
                begin
                    JTokenDotNet := Value;
                    JsonText := JTokenDotNet.ToString(JsonFormatting.None);
                    JsonTokenValue.ReadFrom(JsonText);
                    JsonObject.Add(PropertyName, JsonTokenValue);
                end;
#endif
            Value.IsJsonToken():
                begin
                    JsonTokenValue := Value;
                    JsonObject.Add(PropertyName, JsonTokenValue);
                end;
            Value.IsJsonValue():
                begin
                    JsonValueValue := Value;
                    JsonObject.Add(PropertyName, JsonValueValue.AsToken());
                end;
            Value.IsJsonObject():
                begin
                    JsonObjectValue := Value;
                    JsonObject.Add(PropertyName, JsonObjectValue);
                end;
            Value.IsJsonArray():
                begin
                    JsonArrayValue := Value;
                    JsonObject.Add(PropertyName, JsonArrayValue);
                end;
            Value.IsBigInteger():
                begin
                    BigIntegerValue := Value;
                    JsonObject.Add(PropertyName, BigIntegerValue);
                end;
            Value.IsInteger():
                begin
                    IntegerValue := Value;
                    JsonObject.Add(PropertyName, IntegerValue);
                end;
            Value.IsDecimal():
                begin
                    DecimalValue := Value;
                    JsonObject.Add(PropertyName, DecimalValue);
                end;
            Value.IsBoolean():
                begin
                    BooleanValue := Value;
                    JsonObject.Add(PropertyName, BooleanValue);
                end;
            else begin
                ValueText := Format(Value, 0, 9);
                JsonObject.Add(PropertyName, ValueText);
            end;
        end;
    end;

    local procedure AddJObjectToCollection()
    begin
        JsonArrayState.Add(JsonObjectState.Clone().AsObject());
    end;

    local procedure SetObjectStateFromString(JSONString: Text)
    var
        NewJsonObject: JsonObject;
    begin
        if JSONString <> '' then
            if not NewJsonObject.ReadFrom(JSONString) then
                Error(InvalidJsonObjectErr);
        JsonObjectState := NewJsonObject;
    end;

    local procedure AppendJsonToken(JsonToken: JsonToken; IndentationLevel: Integer; var JsonTextBuilder: TextBuilder)
    var
        ScalarText: Text;
    begin
        case true of
            JsonToken.IsObject():
                AppendJsonObject(JsonToken.AsObject(), IndentationLevel, JsonTextBuilder);
            JsonToken.IsArray():
                AppendJsonArray(JsonToken.AsArray(), IndentationLevel, JsonTextBuilder);
            else begin
                JsonToken.WriteTo(ScalarText);
                JsonTextBuilder.Append(ScalarText);
            end;
        end;
    end;

    local procedure AppendJsonObject(JsonObject: JsonObject; IndentationLevel: Integer; var JsonTextBuilder: TextBuilder)
    var
        JsonToken: JsonToken;
        PropertyNames: List of [Text];
        PropertyName: Text;
        PropertyIndex: Integer;
    begin
        PropertyNames := JsonObject.Keys();
        if PropertyNames.Count() = 0 then begin
            JsonTextBuilder.Append('{}');
            exit;
        end;

        JsonTextBuilder.Append('{');
        JsonTextBuilder.Append(GetCRLF());
        foreach PropertyName in PropertyNames do begin
            PropertyIndex += 1;
            AppendIndentation(IndentationLevel + 1, JsonTextBuilder);
            JsonTextBuilder.Append(SerializeJsonString(PropertyName));
            JsonTextBuilder.Append(': ');
            JsonObject.Get(PropertyName, JsonToken);
            AppendJsonToken(JsonToken, IndentationLevel + 1, JsonTextBuilder);
            if PropertyIndex < PropertyNames.Count() then
                JsonTextBuilder.Append(',');
            JsonTextBuilder.Append(GetCRLF());
        end;
        AppendIndentation(IndentationLevel, JsonTextBuilder);
        JsonTextBuilder.Append('}');
    end;

    local procedure AppendJsonArray(JsonArray: JsonArray; IndentationLevel: Integer; var JsonTextBuilder: TextBuilder)
    var
        JsonToken: JsonToken;
        Index: Integer;
    begin
        if JsonArray.Count() = 0 then begin
            JsonTextBuilder.Append('[]');
            exit;
        end;

        JsonTextBuilder.Append('[');
        JsonTextBuilder.Append(GetCRLF());
        for Index := 0 to JsonArray.Count() - 1 do begin
            AppendIndentation(IndentationLevel + 1, JsonTextBuilder);
            JsonArray.Get(Index, JsonToken);
            AppendJsonToken(JsonToken, IndentationLevel + 1, JsonTextBuilder);
            if Index < JsonArray.Count() - 1 then
                JsonTextBuilder.Append(',');
            JsonTextBuilder.Append(GetCRLF());
        end;
        AppendIndentation(IndentationLevel, JsonTextBuilder);
        JsonTextBuilder.Append(']');
    end;

    local procedure AppendIndentation(IndentationLevel: Integer; var JsonTextBuilder: TextBuilder)
    begin
        if IndentationLevel > 0 then
            JsonTextBuilder.Append(PadStr('', IndentationLevel * 2, ' '));
    end;

    local procedure SerializeJsonString(Value: Text) SerializedValue: Text
    var
        JsonArray: JsonArray;
    begin
        JsonArray.Add(Value);
        JsonArray.WriteTo(SerializedValue);
        exit(CopyStr(SerializedValue, 2, StrLen(SerializedValue) - 2));
    end;

    local procedure GetCRLF() CRLF: Text[2]
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
    end;

    // XML-JSON compatibility region: native AL has no XmlNodeConverter-equivalent mapping.
    procedure XMLTextToJSONText(Xml: Text) Json: Text
    var
        JsonConvert: DotNet JsonConvert;
        JsonFormatting: DotNet Formatting;
        DotNetXmlDocument: DotNet XmlDocument;
        DtdProcessing: DotNet DtdProcessing;
        StringReader: DotNet StringReader;
        XmlReaderSettings: DotNet XmlReaderSettings;
        XmlTextReader: DotNet XmlTextReader;
    begin
        ClearUTF8BOMSymbols(Xml);
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
        StringReader := StringReader.StringReader(Xml);
        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();
        XmlReaderSettings.DtdProcessing := DtdProcessing.Prohibit;
        XmlTextReader := XmlTextReader.Create(StringReader, XmlReaderSettings);
        DotNetXmlDocument.Load(XmlTextReader);
        XmlTextReader.Close();
        StringReader.Close();
        Json := JsonConvert.SerializeXmlNode(DotNetXmlDocument.DocumentElement, JsonFormatting.Indented, true);
    end;

    procedure JSONTextToXMLText(Json: Text; DocumentElementName: Text) Xml: Text
    var
        JsonConvert: DotNet JsonConvert;
        DotNetXmlDocument: DotNet XmlDocument;
    begin
        DotNetXmlDocument := JsonConvert.DeserializeXmlNode(Json, DocumentElementName);
        Xml := DotNetXmlDocument.DocumentElement.OuterXml();
    end;

    local procedure ClearUTF8BOMSymbols(var Xml: Text)
    var
        ByteOrderMarkUtf8: Char;
    begin
        ByteOrderMarkUtf8 := 65279;
        if Xml = '' then
            exit;
        if Xml[1] = ByteOrderMarkUtf8 then
            Xml := DelStr(Xml, 1, 1);
    end;
    // End XML-JSON compatibility region.
}
