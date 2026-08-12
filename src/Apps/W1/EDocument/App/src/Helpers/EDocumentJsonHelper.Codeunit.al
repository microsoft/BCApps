// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Helpers;

codeunit 6121 "EDocument Json Helper"
{
    Access = Internal;

    var
        MalformedAdiResponseTxt: label 'ADI response is missing the expected ''%1'' property; returning an empty object.', Locked = true;
        TelemetryCategoryTxt: label 'E-Document Matching Assistance', Locked = true;

    internal procedure GetHeaderFields(SourceJsonObject: JsonObject): JsonObject
    var
        JsonToken: JsonToken;
        ContentObject, EmptyObject : JsonObject;
    begin
        ContentObject := GetInnerObject(SourceJsonObject);
        if not ContentObject.Get('fields', JsonToken) then begin
            Session.LogMessage('0000UK1', StrSubstNo(MalformedAdiResponseTxt, 'fields'), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTxt);
            exit(EmptyObject);
        end;
        exit(JsonToken.AsObject());
    end;

    internal procedure GetLinesArray(SourceJsonObject: JsonObject): JsonArray
    var
        JsonToken: JsonToken;
        ContentObject: JsonObject;
    begin
        ContentObject := GetInnerObject(SourceJsonObject);
        if ContentObject.Get('items', JsonToken) then
            exit(JsonToken.AsArray());
    end;

    internal procedure HasADIExtractedInvoiceData(SourceJsonObject: JsonObject): Boolean
    var
        InnerObject: JsonObject;
        ItemsJsonArray: JsonArray;
        FieldsToken, ItemToken, ItemFieldsToken : JsonToken;
        ItemIndex: Integer;
    begin
        if not TryGetADIResultObject(SourceJsonObject, InnerObject) then
            exit(false);

        if InnerObject.Get('fields', FieldsToken) and FieldsToken.IsObject() then
            if HasADIExtractedFieldValue(FieldsToken.AsObject()) then
                exit(true);

        if InnerObject.Get('items', ItemToken) and ItemToken.IsArray() then begin
            ItemsJsonArray := ItemToken.AsArray();
            for ItemIndex := 0 to ItemsJsonArray.Count() - 1 do
                if ItemsJsonArray.Get(ItemIndex, ItemToken) and ItemToken.IsObject() then
                    if ItemToken.AsObject().Get('fields', ItemFieldsToken) and ItemFieldsToken.IsObject() then
                        if HasADIExtractedFieldValue(ItemFieldsToken.AsObject()) then
                            exit(true);
        end;

        exit(false);
    end;

    local procedure TryGetADIResultObject(SourceJsonObject: JsonObject; var ResultObject: JsonObject): Boolean
    var
        JsonToken: JsonToken;
        OutputsObject: JsonObject;
    begin
        if not SourceJsonObject.Get('outputs', JsonToken) or not JsonToken.IsObject() then
            exit(false);
        OutputsObject := JsonToken.AsObject();
        if not OutputsObject.Get('1', JsonToken) or not JsonToken.IsObject() then
            exit(false);
        if not JsonToken.AsObject().Get('result', JsonToken) or not JsonToken.IsObject() then
            exit(false);
        ResultObject := JsonToken.AsObject();
        exit(true);
    end;

    local procedure HasADIExtractedFieldValue(FieldsJsonObject: JsonObject): Boolean
    var
        FieldJsonObject: JsonObject;
        FieldNames: List of [Text];
        JsonToken: JsonToken;
        FieldName: Text;
    begin
        FieldNames := FieldsJsonObject.Keys();
        foreach FieldName in FieldNames do
            if FieldsJsonObject.Get(FieldName, JsonToken) and JsonToken.IsObject() then begin
                FieldJsonObject := JsonToken.AsObject();
                if HasADIJsonValue(FieldJsonObject, 'value_text') or
                   HasADIJsonValue(FieldJsonObject, 'value_number') or
                   HasADIJsonValue(FieldJsonObject, 'value_date')
                then
                    exit(true);
            end;

        exit(false);
    end;

    local procedure HasADIJsonValue(FieldJsonObject: JsonObject; PropertyName: Text): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not FieldJsonObject.Get(PropertyName, JsonToken) or not JsonToken.IsValue() then
            exit(false);
        if JsonToken.AsValue().IsNull() then
            exit(false);

        exit(JsonToken.AsValue().AsText().Trim() <> '');
    end;

    internal procedure GetInnerObject(SourceJsonObject: JsonObject): JsonObject
    var
        JsonToken: JsonToken;
        OutputsObject, InnerObject, EmptyObject : JsonObject;
    begin
        if not SourceJsonObject.Get('outputs', JsonToken) then begin
            Session.LogMessage('0000UK2', StrSubstNo(MalformedAdiResponseTxt, 'outputs'), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTxt);
            exit(EmptyObject);
        end;
        OutputsObject := JsonToken.AsObject();
        if not OutputsObject.Get('1', JsonToken) then begin
            Session.LogMessage('0000UK3', StrSubstNo(MalformedAdiResponseTxt, '1'), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTxt);
            exit(EmptyObject);
        end;
        InnerObject := JsonToken.AsObject();
        if not InnerObject.Get('result', JsonToken) then begin
            Session.LogMessage('0000UK4', StrSubstNo(MalformedAdiResponseTxt, 'result'), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategoryTxt);
            exit(EmptyObject);
        end;
        exit(JsonToken.AsObject());
    end;

    internal procedure SetStringValueInField(FieldName: Text; MaxStrLen: Integer; var FieldsJsonObject: JsonObject; var Field: Text)
    var
        JsonValue: JsonValue;
    begin
        if not TryGetJsonFieldValue(FieldName, FieldsJsonObject, 'value_text', JsonValue) then
            exit;
        if TryAssignToText(JsonValue, MaxStrLen, Field) then;
    end;

    internal procedure SetDateValueInField(FieldName: Text; var FieldsJsonObject: JsonObject; var Field: Date)
    var
        JsonValue: JsonValue;
    begin
        if not TryGetJsonFieldValue(FieldName, FieldsJsonObject, 'value_date', JsonValue) then
            exit;

        if TryAssignToDate(JsonValue, Field) then;
    end;

    internal procedure SetNumberValueInField(FieldName: Text; var FieldsJsonObject: JsonObject; var DecimalValue: Decimal): Boolean
    var
        JsonValue: JsonValue;
    begin
        if not TryGetJsonFieldValue(FieldName, FieldsJsonObject, 'value_number', JsonValue) then
            exit(false);
        exit(TryAssignToDecimal(JsonValue, DecimalValue));
    end;

    internal procedure SetCurrencyValueInField(FieldName: Text; var FieldsJsonObject: JsonObject; var Amount: Decimal; var CurrencyCode: Code[10])
    var
        CurrencyValueAsJson: JsonValue;
        FoundCurrency: Text;
    begin
        // 1. Read the number value from the JSON object
        SetNumberValueInField(FieldName, FieldsJsonObject, Amount);

        // 2. Try to read the currency code from the JSON object
        if not TryGetJsonFieldValue(FieldName, FieldsJsonObject, 'currency_code', CurrencyValueAsJson) then
            exit;
        if TryAssignToText(CurrencyValueAsJson, MaxStrLen(CurrencyCode), FoundCurrency) then;

        if FoundCurrency = '' then
            exit;
        if CurrencyCode = '' then begin
            CurrencyCode := CopyStr(FoundCurrency, 1, MaxStrLen(CurrencyCode));
            exit;
        end;
    end;

    local procedure TryGetJsonFieldValue(FieldName: Text; FieldsJsonObject: JsonObject; ValueKey: Text; var JsonValue: JsonValue): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not FieldsJsonObject.Contains(FieldName) then
            exit(false);
        // CAPI returns all parameters, even if they are null. This avoid errors when trying to access a null object
        FieldsJsonObject.Get(FieldName, JsonToken);
        if not JsonToken.IsObject() then
            exit(false);

        JsonToken.AsObject().Get(ValueKey, JsonToken);
        if not JsonToken.IsValue() then
            exit(false);

        JsonValue := JsonToken.AsValue();
        exit(true);
    end;

    [TryFunction]
    internal procedure TryAssignToText(JsonValue: JsonValue; MaxStrLen: Integer; var TextValue: Text)
    begin
        TextValue := CopyStr(JsonValue.AsText(), 1, MaxStrLen);
    end;


    [TryFunction]
    internal procedure TryAssignToDecimal(JsonValue: JsonValue; var DecimalField: Decimal)
    begin
        DecimalField := JsonValue.AsDecimal();
    end;

    [TryFunction]
    internal procedure TryAssignToDate(JsonValue: JsonValue; var DateValue: Date)
    begin
        DateValue := JsonValue.AsDate();
    end;
}