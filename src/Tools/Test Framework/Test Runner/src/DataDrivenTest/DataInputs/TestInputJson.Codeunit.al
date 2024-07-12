// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130464 "Test Input Json"
{
    procedure Initialize()
    begin
        Initialize('{}');
    end;

    procedure Initialize(TestJsonValue: Text)
    begin
        TestJson.ReadFrom(TestJsonValue);
    end;

    procedure Initialize(TestJsonObject: JsonToken)
    begin
        TestJson := TestJsonObject;
    end;

    procedure Element(ElementName: Text): Codeunit "Test Input Json"
    var
        TestInputJson: Codeunit "Test Input Json";
        ElementSearchedExist: Boolean;
    begin
        TestInputJson := ElementExists(ElementName, ElementSearchedExist);
        if not ElementSearchedExist then
            Error(ElementDoesNotExistErr, ElementName);

        exit(TestInputJson);
    end;

    procedure ElementExists(ElementName: Text; var ElementFound: Boolean): Codeunit "Test Input Json"
    var
        NewTestJson: Codeunit "Test Input Json";
        ElementJsonToken: JsonToken;
    begin
        ElementFound := false;

        if not TestJson.IsObject() then
            exit(NewTestJson);

        if not TestJson.AsObject().Get(ElementName, ElementJsonToken) then
            exit(NewTestJson);

        ElementFound := true;
        NewTestJson.Initialize(ElementJsonToken);
        exit(NewTestJson);
    end;

    procedure ElementAt(ElementIndex: Integer): Codeunit "Test Input Json"
    var
        NewTestJson: Codeunit "Test Input Json";
        JsonElementToken: JsonToken;
    begin
        if not TestJson.IsArray() then
            Error(TheElementIsNotAnArrayErr);
        TestJson.AsArray().Get(ElementIndex, JsonElementToken);
        NewTestJson.Initialize(JsonElementToken);
        exit(NewTestJson);
    end;

    procedure GetElementCount(): Integer
    begin
        if not TestJson.IsArray() then
            Error(TheElementIsNotAnArrayErr);

        exit(TestJson.AsArray().Count());
    end;

    procedure ElementValue(): JsonValue
    begin
        exit(TestJson.AsValue());
    end;

    procedure ValueAsText(): Text
    begin
        exit(TestJson.AsValue().AsText());
    end;

    procedure ValueAsInteger(): Integer
    begin
        exit(TestJson.AsValue().AsInteger());
    end;

    procedure ValueAsDecimal(): Decimal
    begin
        exit(TestJson.AsValue().AsDecimal());
    end;

    procedure ValueAsBoolean(): Boolean
    begin
        exit(TestJson.AsValue().AsBoolean());
    end;

    procedure ValueAsJsonObject(): JsonObject
    begin
        exit(TestJson.AsObject());
    end;

    procedure AsJsonToken(): JsonToken
    begin
        exit(TestJson);
    end;

    procedure ToText(): Text
    var
        TextOutput: Text;
    begin
        TestJson.WriteTo(TextOutput);
        if TextOutput = 'null' then
            exit('');

        exit(TextOutput);
    end;

    var
        ElementDoesNotExistErr: Label 'DataInput - The element %1 does not exist.', Comment = '%1 = Element name';
        TheElementIsNotAnArrayErr: Label 'DataInput - The element is not an array, use a different method.';
        TestJson: JsonToken;
}