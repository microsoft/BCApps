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
        JsonArrayDotNet: DotNet JArray;
        JsonObjectDotNet: DotNet JObject;

    procedure InitializeCollectionFromString(JSONString: Text)
    begin
        Clear(JsonArrayDotNet);
        if JSONString <> '' then
            JsonArrayDotNet := JsonArrayDotNet.Parse(JSONString)
        else
            InitializeEmptyCollection();
    end;

    procedure InitializeObjectFromString(JSONString: Text)
    begin
        Clear(JsonObjectDotNet);
        if JSONString <> '' then
            JsonObjectDotNet := JsonObjectDotNet.Parse(JSONString)
        else
            InitializeEmptyObject();
    end;

    procedure GetCollectionCount(): Integer
    begin
        exit(JsonArrayDotNet.Count);
    end;

    procedure GetCollectionAsText() Value: Text
    begin
        GetCollection().WriteTo(Value);
    end;

    procedure GetCollection() JArray: JsonArray
    begin
        JArray.ReadFrom(JsonArrayDotNet.ToString());
    end;

    procedure GetObjectAsText() Value: Text
    begin
        GetObject().WriteTo(Value);
    end;

    procedure GetObject() JObject: JsonObject
    begin
        JObject.ReadFrom(JsonObjectDotNet.ToString());
    end;

    procedure GetObjectFromCollectionByIndex(Index: Integer; var JsonObjectTxt: Text): Boolean
    begin
        if not GetJObjectFromCollectionByIndex(Index) then
            exit(false);

        JsonObjectTxt := JsonObjectDotNet.ToString();
        exit(true);
    end;

    procedure GetValueAndSetToRecFieldNo(RecordRef: RecordRef; PropertyPath: Text; FieldNo: Integer): Boolean
    var
        FieldRef: FieldRef;
    begin
        if IsNull(JsonObjectDotNet) then
            exit(false);

        FieldRef := RecordRef.Field(FieldNo);
        exit(GetPropertyValueFromJObjectByPathSetToFieldRef(PropertyPath, FieldRef));
    end;

    procedure GetPropertyValueFromJObjectByName(propertyName: Text; var value: Variant): Boolean
    var
        JPropertyDotNet: DotNet JProperty;
        JTokenDotNet: DotNet JToken;
    begin
        Clear(value);
        if JsonObjectDotNet.TryGetValue(propertyName, JTokenDotNet) then begin
            JPropertyDotNet := JsonObjectDotNet.Property(propertyName);
            value := JPropertyDotNet.Value;
            exit(true);
        end;
        exit(false);
    end;

    procedure GetStringPropertyValueFromJObjectByName(propertyName: Text; var value: Text): Boolean
    var
        VariantValue: Variant;
    begin
        Clear(value);
        if GetPropertyValueFromJObjectByName(propertyName, VariantValue) then begin
            value := Format(VariantValue);
            exit(true);
        end;
        exit(false);
    end;

    procedure GetEnumPropertyValueFromJObjectByName(propertyName: Text; var value: Option): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(propertyName, StringValue) then begin
            Evaluate(value, StringValue, 0);
            exit(true);
        end;
        exit(false);
    end;

    procedure GetBoolPropertyValueFromJObjectByName(propertyName: Text; var value: Boolean): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(propertyName, StringValue) then begin
            Evaluate(value, StringValue, 2);
            exit(true);
        end;
        exit(false);
    end;

    procedure GetDecimalPropertyValueFromJObjectByName(propertyName: Text; var value: Decimal): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    procedure GetIntegerPropertyValueFromJObjectByName(propertyName: Text; var value: Integer): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    procedure GetGuidPropertyValueFromJObjectByName(propertyName: Text; var value: Guid): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    procedure ReplaceOrAddJPropertyInJObject(propertyName: Text; value: Variant): Boolean
    var
        JPropertyDotNet: DotNet JProperty;
        OldPropertyDotNet: DotNet JProperty;
        OldValue: Variant;
    begin
        JPropertyDotNet := JsonObjectDotNet.Property(propertyName);
        if not IsNull(JPropertyDotNet) then begin
            OldPropertyDotNet := JsonObjectDotNet.Property(propertyName);
            OldValue := OldPropertyDotNet.Value;
            JPropertyDotNet.Replace(JPropertyDotNet.JProperty(propertyName, value));
            exit(Format(OldValue) <> Format(value));
        end;

        AddJPropertyToJObject(propertyName, value);
        exit(true);
    end;

    procedure AddJObjectToCollection(JSONString: Text): Boolean
    begin
        if JSONString <> '' then
            JsonObjectDotNet := JsonObjectDotNet.Parse(JSONString)
        else
            InitializeEmptyObject();

        AddJObjectToCollection();
        exit(true);
    end;

    procedure RemoveJObjectFromCollection(Index: Integer): Boolean
    begin
        if (GetCollectionCount() = 0) or (GetCollectionCount() <= Index) then
            exit(false);

        JsonArrayDotNet.RemoveAt(Index);
        exit(true);
    end;

    procedure ReplaceJObjectInCollection(Index: Integer; JSONString: Text): Boolean
    begin
        if not GetJObjectFromCollectionByIndex(Index) then
            exit(false);

        if JSONString <> '' then
            JsonObjectDotNet := JsonObjectDotNet.Parse(JSONString)
        else
            InitializeEmptyObject();

        JsonArrayDotNet.RemoveAt(Index);
        JsonArrayDotNet.Insert(Index, JsonObjectDotNet);
        exit(true);
    end;

    local procedure GetJObjectFromCollectionByIndex(Index: Integer): Boolean
    begin
        if (GetCollectionCount() = 0) or (GetCollectionCount() <= Index) then
            exit(false);

        JsonObjectDotNet := JsonArrayDotNet.Item(Index);
        exit(not IsNull(JsonObjectDotNet))
    end;

    local procedure GetPropertyValueFromJObjectByPathSetToFieldRef(propertyPath: Text; var FieldRef: FieldRef): Boolean
    var
        RecID: RecordId;
        Value: Variant;
        IntVar: Integer;
        DecimalVal: Decimal;
        GuidVal: Guid;
        DateVal: Date;
        BoolVal, Success : Boolean;
        JPropertyDotNet: DotNet JProperty;
    begin
        Success := false;
        JPropertyDotNet := JsonObjectDotNet.SelectToken(propertyPath);

        if IsNull(JPropertyDotNet) then
            exit(false);

        Value := Format(JPropertyDotNet.Value, 0, 9);

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

    local procedure AddJPropertyToJObject(propertyName: Text; value: Variant)
    var
        JObjectDotNet: DotNet JObject;
        JPropertyDotNet: DotNet JProperty;
        ValueText: Text;
    begin
        case true of
            value.IsDotNet:
                begin
                    JObjectDotNet := value;
                    JsonObjectDotNet.Add(propertyName, JObjectDotNet);
                end;
            value.IsInteger,
            value.IsDecimal,
            value.IsBoolean:
                begin
                    JPropertyDotNet := JPropertyDotNet.JProperty(propertyName, value);
                    JsonObjectDotNet.Add(JPropertyDotNet);
                end;
            else begin
                ValueText := Format(value, 0, 9);
                JPropertyDotNet := JPropertyDotNet.JProperty(propertyName, ValueText);
                JsonObjectDotNet.Add(JPropertyDotNet);
            end;
        end;
    end;

    local procedure AddJObjectToCollection()
    begin
        JsonArrayDotNet.Add(JsonObjectDotNet.DeepClone());
    end;

    local procedure InitializeEmptyCollection()
    begin
        JsonArrayDotNet := JsonArrayDotNet.JArray();
    end;

    local procedure InitializeEmptyObject()
    begin
        JsonObjectDotNet := JsonObjectDotNet.JObject();
    end;
}