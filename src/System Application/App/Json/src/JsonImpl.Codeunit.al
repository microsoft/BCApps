// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Json;

using System;
using System.Utilities;
using System.Text;

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

    procedure GetObjectFromCollectionByIndex(var "Object": Text; Index: Integer): Boolean
    var
        JObject: DotNet JObject;
    begin
        if not GetJObjectFromCollectionByIndex(JObject, Index) then
            exit(false);

        Object := JObject.ToString();
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
        JProperty: DotNet JProperty;
        RecID: RecordID;
        Value: Variant;
        DecimalVal: Decimal;
        BoolVal: Boolean;
        GuidVal: Guid;
        DateVal: Date;
        Success: Boolean;
        IntVar: Integer;
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

    local procedure InitializeEmptyCollection()
    begin
        JsonArray := JsonArray.JArray();
    end;

    local procedure InitializeEmptyObject()
    begin
        JsonObject := JsonObject.JObject();
    end;
}

