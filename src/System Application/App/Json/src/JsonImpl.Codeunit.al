// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Json;

using System;
using System.Text;
using System.Utilities;

codeunit 5461 "Json Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        JsonArray: DotNet JArray;
        JsonObject: DotNet JObject;


    procedure InitializeCollection(JSONString: Text)
    begin
        InitializeCollectionFromString(JSONString);
    end;

    procedure InitializeObject(JSONString: Text)
    begin
        InitializeObjectFromString(JSONString);
    end;

    procedure GetCollectionCount(): Integer
    begin
        exit(JsonArray.Count);
    end;

    procedure GetCollection() Value: Text
    var
        JArray: JsonArray;
    begin
        JArray.ReadFrom(JsonArray.ToString());
        JArray.WriteTo(Value);
    end;

    procedure GetObject() Value: Text
    var
        JObject: JsonObject;
    begin
        JObject.ReadFrom(JsonObject.ToString());
        JObject.WriteTo(Value);
    end;

    procedure GetObjectFromCollectionByIndex(Index: Integer; var JsonObjectTxt: Text): Boolean
    var
        JObject: DotNet JObject;
    begin
        if not GetJObjectFromCollectionByIndex(JObject, Index) then
            exit(false);

        JsonObjectTxt := JObject.ToString();
        exit(true);
    end;

    procedure GetValueAndSetToRecFieldNo(RecordRef: RecordRef; PropertyPath: Text; FieldNo: Integer): Boolean
    var
        FieldRef: FieldRef;
    begin
        if IsNull(JsonObject) then
            exit(false);

        FieldRef := RecordRef.Field(FieldNo);
        exit(GetPropertyValueFromJObjectByPathSetToFieldRef(JsonObject, PropertyPath, FieldRef));
    end;

    procedure GetPropertyValueByName(propertyName: Text; var value: Variant): Boolean
    begin
        exit(GetPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    procedure GetStringPropertyValueByName(propertyName: Text; var value: Text): Boolean
    begin
        exit(GetStringPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    procedure GetEnumPropertyValueFromJObjectByName(propertyName: Text; var value: Option): Boolean
    begin
        exit(GetEnumPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    procedure GetBoolPropertyValueFromJObjectByName(propertyName: Text; var value: Boolean): Boolean
    begin
        exit(GetBoolPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    procedure GetDecimalPropertyValueFromJObjectByName(propertyName: Text; var value: Decimal): Boolean
    begin
        exit(GetDecimalPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    procedure GetIntegerPropertyValueFromJObjectByName(propertyName: Text; var value: Integer): Boolean
    begin
        exit(GetIntegerPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    procedure GetGuidPropertyValueFromJObjectByName(propertyName: Text; var value: Guid): Boolean
    begin
        exit(GetGuidPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    procedure ReplaceOrAddJPropertyInJObject(propertyName: Text; value: Variant): Boolean
    begin
        exit(ReplaceOrAddJPropertyInJObject(JsonObject, propertyName, value));
    end;

    procedure AddJObjectToCollection(value: Text): Boolean
    begin
        exit(AddJObjectToCollection(JsonArray, value));
    end;

    procedure RemoveJObjectFromCollection(Index: Integer): Boolean
    begin
        exit(RemoveJObjectFromCollection(JsonArray, Index));
    end;

    procedure ReplaceJObjectInCollection(Index: Integer; JSONString: Text): Boolean
    begin
        exit(ReplaceJObjectInCollection(JsonArray, Index, JSONString));
    end;

    local procedure InitializeCollectionFromString(JSONString: Text)
    begin
        Clear(JsonArray);
        if JSONString <> '' then
            JsonArray := JsonArray.Parse(JSONString)
        else
            InitializeEmptyCollection();
    end;

    local procedure InitializeObjectFromString(JSONString: Text)
    begin
        Clear(JsonObject);
        if JSONString <> '' then
            JsonObject := JsonObject.Parse(JSONString)
        else
            InitializeEmptyObject();
    end;

    local procedure GetJObjectFromCollectionByIndex(var JObject: DotNet JObject; Index: Integer): Boolean
    begin
        if (GetCollectionCount() = 0) or (GetCollectionCount() <= Index) then
            exit(false);

        JObject := JsonArray.Item(Index);
        exit(not IsNull(JObject))
    end;

    local procedure GetPropertyValueFromJObjectByPathSetToFieldRef(JObject: DotNet JObject; propertyPath: Text; var FieldRef: FieldRef): Boolean
    var
        RecID: RecordID;
        Value: Variant;
        IntVar: Integer;
        DecimalVal: Decimal;
        GuidVal: Guid;
        DateVal: Date;
        BoolVal, Success : Boolean;
        JProperty: DotNet JProperty;
    begin
        Success := false;
        JProperty := JObject.SelectToken(propertyPath);

        if IsNull(JProperty) then
            exit(false);

        Value := Format(JProperty.Value, 0, 9);

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

    local procedure GetEnumPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Option): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue, 0);
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetBoolPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Boolean): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue, 2);
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetDecimalPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Decimal): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetIntegerPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Integer): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetGuidPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Guid): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetStringPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Text): Boolean
    var
        VariantValue: Variant;
    begin
        Clear(value);
        if GetPropertyValueFromJObjectByName(JObject, propertyName, VariantValue) then begin
            value := Format(VariantValue);
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Variant): Boolean
    var
        JProperty: DotNet JProperty;
        JToken: DotNet JToken;
    begin
        Clear(value);
        if JObject.TryGetValue(propertyName, JToken) then begin
            JProperty := JObject.Property(propertyName);
            value := JProperty.Value;
            exit(true);
        end;
    end;

    local procedure ReplaceOrAddJPropertyInJObject(var JObject: DotNet JObject; propertyName: Text; value: Variant): Boolean
    var
        JProperty: DotNet JProperty;
        OldProperty: DotNet JProperty;
        oldValue: Variant;
    begin
        JProperty := JObject.Property(propertyName);
        if not IsNull(JProperty) then begin
            OldProperty := JObject.Property(propertyName);
            oldValue := OldProperty.Value;
            JProperty.Replace(JProperty.JProperty(propertyName, value));
            exit(Format(oldValue) <> Format(value));
        end;

        AddJPropertyToJObject(JObject, propertyName, value);
        exit(true);
    end;

    local procedure AddJPropertyToJObject(var JObject: DotNet JObject; propertyName: Text; value: Variant)
    var
        JObject2: DotNet JObject;
        JProperty: DotNet JProperty;
        ValueText: Text;
        IsHandled: Boolean;
    begin
        case true of
            value.IsDotNet:
                begin
                    JObject2 := value;
                    JObject.Add(propertyName, JObject2);
                end;
            value.IsInteger,
            value.IsDecimal,
            value.IsBoolean:
                begin
                    JProperty := JProperty.JProperty(propertyName, value);
                    JObject.Add(JProperty);
                end;
            else begin
                ValueText := Format(value, 0, 9);
                JProperty := JProperty.JProperty(propertyName, ValueText);
                JObject.Add(JProperty);
            end;
        end;
    end;

    local procedure ReplaceJObjectInCollection(var JArray: DotNet JArray; Index: Integer; JSONString: Text): Boolean
    var
        JObject: DotNet JObject;
    begin
        if not GetJObjectFromCollectionByIndex(JObject, Index) then
            exit(false);

        if JSONString <> '' then
            JObject := JObject.Parse(JSONString)
        else
            InitializeEmptyObject();

        JArray.RemoveAt(Index);
        JArray.Insert(Index, JObject);
        exit(true);
    end;

    local procedure AddJObjectToCollection(var JArray: DotNet JArray; JSONString: Text): Boolean
    var
        JObject: DotNet JObject;
    begin
        if JSONString <> '' then
            JObject := JObject.Parse(JSONString)
        else
            InitializeEmptyObject();

        AddJObjectToCollection(JObject);
        exit(true);
    end;

    local procedure AddJObjectToCollection(JObject: DotNet JObject)
    begin
        JsonArray.Add(JObject.DeepClone());
    end;

    local procedure RemoveJObjectFromCollection(var JArray: DotNet JArray; Index: Integer): Boolean
    begin
        if (GetCollectionCount() = 0) or (GetCollectionCount() <= Index) then
            exit(false);

        JArray.RemoveAt(Index);
        exit(true);
    end;

    local procedure InitializeEmptyCollection()
    begin
        JsonArray := JsonArray.JArray();
    end;

    local procedure InitializeEmptyObject()
    begin
        JsonObject := JsonObject.JObject();
    end;
}