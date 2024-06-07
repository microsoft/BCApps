// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130462 "Test Output Json"
{
    procedure Initialize()
    begin
        this.Initialize('{}');
    end;

    procedure Initialize(TestJsonValue: Text)
    begin
        this.TestJson.ReadFrom(TestJsonValue);
    end;

    procedure Initialize(var TestJsonObject: JsonToken)
    begin
        this.TestJson := TestJsonObject;
    end;

    procedure Add(NewValue: Text): Codeunit "Test Output Json"
    var
        NewJsonToken: JsonToken;
    begin
        NewJsonToken.ReadFrom(NewValue);
        exit(this.Add(NewJsonToken));
    end;

    procedure Add(var NewJsonToken: JsonToken): Codeunit "Test Output Json"
    var
        NewTestJson: Codeunit "Test Output Json";
    begin
        if not this.TestJson.IsArray() then
            Error(this.TheElementIsNotAnArrayErr);

        this.TestJson.AsArray().Add(NewJsonToken);
        NewTestJson.Initialize(NewJsonToken);
        exit(NewTestJson);
    end;

    procedure Add(Name: Text; NewValue: Text): Codeunit "Test Output Json"
    var
        NewJsonObject: JsonObject;
        NewJsonArray: JsonArray;
        NewJsonValue: JsonValue;
        NewJsonToken: JsonToken;
    begin
        if NewValue = '' then begin
            NewJsonObject.ReadFrom('{}');
            NewJsonToken := NewJsonObject.AsToken();
            exit(this.Add(Name, NewJsonToken));
        end;

        if NewValue = '[]' then begin
            NewJsonArray.ReadFrom('[]');
            NewJsonToken := NewJsonArray.AsToken();
            exit(this.Add(Name, NewJsonToken));
        end;

        NewJsonValue.ReadFrom('"' + NewValue + '"');
        NewJsonToken := NewJsonValue.AsToken();
        exit(this.Add(Name, NewJsonToken));
    end;

    procedure Add(Name: Text; DecimalValue: Decimal): Codeunit "Test Output Json"
    var
        NewJsonValue: JsonValue;
        NewJsonToken: JsonToken;
    begin
        NewJsonValue.SetValue(DecimalValue);
        NewJsonToken := NewJsonValue.AsToken();
        exit(this.Add(Name, NewJsonToken));
    end;

    procedure Add(Name: Text; IntegerValue: Integer): Codeunit "Test Output Json"
    var
        NewJsonValue: JsonValue;
        NewJsonToken: JsonToken;
    begin
        NewJsonValue.SetValue(IntegerValue);
        NewJsonToken := NewJsonValue.AsToken();
        exit(this.Add(Name, NewJsonToken));
    end;

    procedure Add(Name: Text; BooleanValue: Boolean): Codeunit "Test Output Json"
    var
        NewJsonValue: JsonValue;
        NewJsonToken: JsonToken;
    begin
        NewJsonValue.SetValue(BooleanValue);
        NewJsonToken := NewJsonValue.AsToken();
        exit(this.Add(Name, NewJsonToken));
    end;

    procedure Add(Name: Text; DateTimeValue: DateTime): Codeunit "Test Output Json"
    var
        NewJsonValue: JsonValue;
        NewJsonToken: JsonToken;
    begin
        NewJsonValue.SetValue(DateTimeValue);
        NewJsonToken := NewJsonValue.AsToken();
        exit(this.Add(Name, NewJsonToken));
    end;

    procedure Add(Name: Text; DateValue: Date): Codeunit "Test Output Json"
    var
        NewJsonValue: JsonValue;
        NewJsonToken: JsonToken;
    begin
        NewJsonValue.SetValue(DateValue);
        NewJsonToken := NewJsonValue.AsToken();
        exit(this.Add(Name, NewJsonToken));
    end;

    procedure Add(Name: Text; var ValueVariant: JsonToken): Codeunit "Test Output Json"
    var
        NewTestJson: Codeunit "Test Output Json";
        NewJsonObject: JsonObject;
        NewJsonToken: JsonToken;
    begin
        if this.TestJson.IsObject() then begin
            this.TestJson.AsObject().Add(Name, ValueVariant);
            NewTestJson.Initialize(ValueVariant);
            exit(NewTestJson);
        end;

        if not this.TestJson.IsArray() then
            Error(this.WrongTypeOrNotInitializedErr);

        if Name = '' then begin
            this.TestJson.AsArray().Add(ValueVariant);
            NewTestJson.Initialize(ValueVariant);
            exit(NewTestJson);
        end;

        NewJsonObject.ReadFrom('{}');
        NewJsonObject.Add(Name, ValueVariant);
        NewJsonToken := NewJsonObject.AsToken();
        this.TestJson.AsArray().Add(NewJsonToken);
        NewTestJson.Initialize(NewJsonToken);
        exit(NewTestJson);
    end;

    procedure AddArray(Name: Text): Codeunit "Test Output Json"
    begin
        exit(this.Add(Name, '[]'));
    end;

    procedure Element(ElementName: Text): Codeunit "Test Output Json"
    var
        NewTestJson: Codeunit "Test Output Json";
        ElementJsonToken: JsonToken;
    begin
        if not this.TestJson.IsObject() then
            Error(this.TheElementIsNotAnObjectErr);

        this.TestJson.AsObject().Get(ElementName, ElementJsonToken);
        NewTestJson.Initialize(ElementJsonToken);
        exit(NewTestJson);
    end;

    procedure ElementAt(ElementIndex: Integer): Codeunit "Test Output Json"
    var
        NewTestJson: Codeunit "Test Output Json";
        JsonElementToken: JsonToken;
    begin
        if not this.TestJson.IsArray() then
            Error(this.TheElementIsNotAnArrayErr);
        this.TestJson.AsArray().Get(ElementIndex, JsonElementToken);
        NewTestJson.Initialize(JsonElementToken);
        exit(NewTestJson);
    end;

    procedure ToText(): Text
    var
        TextOutput: Text;
    begin
        this.TestJson.WriteTo(TextOutput);
        if TextOutput = 'null' then
            exit('');

        exit(TextOutput);
    end;

    procedure DownloadToFile()
    var
        TempDummyTestInput: Record "Test Input" temporary;
        JsonOutStream: OutStream;
        TextOutput: Text;
        FileNameTxt: Text;
        JsonInStream: InStream;
    begin
        TempDummyTestInput."Test Input".CreateOutStream(JsonOutStream, TempDummyTestInput.GetTextEncoding());
        TextOutput := this.ToText();
        if TextOutput = '' then
            Error(this.NoDataOutputsWereRecordedErr);

        TempDummyTestInput.Insert();
        JsonOutStream.Write(TextOutput);
        TempDummyTestInput.Modify();
        TempDummyTestInput.CalcFields("Test Input");
        TempDummyTestInput."Test Input".CreateInStream(JsonInStream, TempDummyTestInput.GetTextEncoding());
        FileNameTxt := this.TestOutputJsonTok;
        DownloadFromStream(JsonInStream, 'Test', '', '', FileNameTxt);
    end;

    procedure ReplaceElement(ElementName: Text; NewValue: Text): Codeunit "Test Output Json"
    var
        NewTestJson: Codeunit "Test Output Json";
        ElementJsonToken: JsonToken;
    begin
        if not this.TestJson.AsObject().Get(ElementName, ElementJsonToken) then begin
            ElementJsonToken.ReadFrom(NewValue);
            this.TestJson.AsObject().Add(ElementName, ElementJsonToken);
        end else
            ElementJsonToken.ReadFrom(NewValue);

        NewTestJson.Initialize(ElementJsonToken);
        exit(NewTestJson);
    end;

    procedure ReplaceElement(ElementName: Text; var NewJsonToken: JsonToken): Codeunit "Test Output Json"
    var
        NewTestJson: Codeunit "Test Output Json";
        ElementJsonToken: JsonToken;
    begin
        this.TestJson.AsObject().Get(ElementName, ElementJsonToken);
        ElementJsonToken := NewJsonToken;
        NewTestJson.Initialize(ElementJsonToken);

        exit(NewTestJson);
    end;

    var
        TheElementIsNotAnObjectErr: Label 'DataOutput - The element is not an object, use a different method.';
        TheElementIsNotAnArrayErr: Label 'DataOutput - The element is not an array, use a different method.';
        NoDataOutputsWereRecordedErr: Label 'No data outputs were recorded.';
        WrongTypeOrNotInitializedErr: Label 'The data output is not initialized or is of the wrong type. It must be an Json object or array.';
        TestJson: JsonToken;
        TestOutputJsonTok: Label 'TestOutput.json';
}