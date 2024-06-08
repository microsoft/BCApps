// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130464 "Test Input Json"
{
    procedure Initialize()
    begin
        this.Initialize('{}');
    end;

    procedure Initialize(TestJsonValue: Text)
    begin
        this.TestJson.ReadFrom(TestJsonValue);
    end;

    procedure Initialize(TestJsonObject: JsonToken)
    begin
        this.TestJson := TestJsonObject;
    end;

    procedure Element(ElementName: Text): Codeunit "Test Input Json"
    var
        TestInputJson: Codeunit "Test Input Json";
        ElementSearchedExist: Boolean;
    begin
        TestInputJson := this.ElementExists(ElementName, ElementSearchedExist);
        if not ElementSearchedExist then
            Error(this.ElementDoesNotExistErr);

        exit(TestInputJson);
    end;

    procedure ElementExists(ElementName: Text; var ElementFound: Boolean): Codeunit "Test Input Json"
    var
        NewTestJson: Codeunit "Test Input Json";
        ElementJsonToken: JsonToken;
    begin
        ElementFound := false;

        if not this.TestJson.IsObject() then
            exit(NewTestJson);

        if not this.TestJson.AsObject().Get(ElementName, ElementJsonToken) then
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
        if not this.TestJson.IsArray() then
            Error(this.TheElementIsNotAnArrayErr);
        this.TestJson.AsArray().Get(ElementIndex, JsonElementToken);
        NewTestJson.Initialize(JsonElementToken);
        exit(NewTestJson);
    end;

    procedure ElementValue(): JsonValue
    begin
        exit(this.TestJson.AsValue());
    end;

    procedure ValueAsText(): Text
    begin
        exit(this.TestJson.AsValue().AsText());
    end;

    procedure ValueAsInteger(): Integer
    begin
        exit(this.TestJson.AsValue().AsInteger());
    end;

    procedure ValueAsDecimal(): Decimal
    begin
        exit(this.TestJson.AsValue().AsDecimal());
    end;

    procedure ValueAsBoolean(): Boolean
    begin
        exit(this.TestJson.AsValue().AsBoolean());
    end;

    var
        ElementDoesNotExistErr: Label 'DataInput - The element does not exist.';
        TheElementIsNotAnArrayErr: Label 'DataInput - The element is not an array, use a different method.';
        TestJson: JsonToken;
}