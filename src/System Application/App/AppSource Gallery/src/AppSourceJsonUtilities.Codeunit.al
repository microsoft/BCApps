// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;

/// <summary>
/// Library for managing AppSource product retrieval and usage.
/// </summary>
codeunit 2516 "AppSource Json Utilities"
{
    Access = Internal;
    InherentEntitlements = x;
    InherentPermissions = X;

    procedure GetDecimalValue(JsonObject: JsonObject; PropertyName: Text): Decimal
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsDecimal());
        exit(0);
    end;

    procedure GetIntegerValue(JsonObject: JsonObject; PropertyName: Text): Integer
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsInteger());
        exit(0);
    end;

    procedure GetDateTimeValue(JsonObject: JsonObject; PropertyName: Text): DateTime
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsDateTime());
        exit(0DT);
    end;

    procedure GetStringValue(JsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonValue: JsonValue;
    begin
        if GetJsonValue(JsonObject, PropertyName, JsonValue) then
            exit(JsonValue.AsText());
        exit('');
    end;

    procedure GetJsonValue(JsonObject: JsonObject; PropertyName: Text; var ReturnValue: JsonValue): Boolean
    var
        JsonToken: JsonToken;
    begin
        if JsonObject.Contains(PropertyName) then
            if JsonObject.Get(PropertyName, JsonToken) then
                if not JsonToken.AsValue().IsNull() then begin
                    ReturnValue := JsonToken.AsValue();
                    exit(true);
                end;
        exit(false);
    end;
}
