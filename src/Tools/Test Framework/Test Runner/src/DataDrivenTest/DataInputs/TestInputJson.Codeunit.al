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

    /// <summary>
    /// Returns the value as Text with all data tool placeholders resolved.
    /// Supported: $DateFormula-...$, $DateTimeFormula-...$.
    /// </summary>
    procedure ValueAsText(): Text
    var
        TestInputDataTools: Codeunit "Test Input Data Tools";
    begin
        exit(TestInputDataTools.ResolveText(TestJson.AsValue().AsText()));
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

    /// <summary>
    /// Returns the value as a Date.
    /// Resolves $DateFormula-&lt;formula&gt;$ placeholders via CalcDate relative to WorkDate.
    /// If the value is not a date formula placeholder, evaluates the resolved text as a date.
    /// </summary>
    procedure ValueAsDate(): Date
    var
        TestInputDataTools: Codeunit "Test Input Data Tools";
    begin
        exit(TestInputDataTools.ResolveAsDate(TestJson.AsValue().AsText()));
    end;

    /// <summary>
    /// Returns the value as a DateTime.
    /// Resolves $DateTimeFormula-&lt;formula&gt;$ placeholders.
    /// Supports optional time (colon format):
    ///   $DateTimeFormula-&lt;formula&gt;$               → time defaults to 0T
    ///   $DateTimeFormula-&lt;formula&gt;-12:30:11$       → explicit time
    ///   $DateTimeFormula-&lt;formula&gt;-12:30:11.1301$  → time with milliseconds
    /// </summary>
    procedure ValueAsDateTime(): DateTime
    var
        TestInputDataTools: Codeunit "Test Input Data Tools";
    begin
        exit(TestInputDataTools.ResolveAsDateTime(TestJson.AsValue().AsText()));
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

        TextOutput := TextOutput.TrimStart('"').TrimEnd('"');

        if TextOutput = 'null' then
            exit('');

        exit(TextOutput);
    end;

    var
        ElementDoesNotExistErr: Label 'DataInput - The element %1 does not exist.', Comment = '%1 = Element name';
        TheElementIsNotAnArrayErr: Label 'DataInput - The element is not an array, use a different method.';
        TestJson: JsonToken;
}