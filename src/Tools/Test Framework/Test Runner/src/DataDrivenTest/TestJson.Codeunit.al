namespace System.TestTools.TestRunner;

codeunit 130462 "Test Json" implements "Test Json"
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

    procedure Add(NewValue: Text): Interface "Test Json"
    var
        NewJsonToken: JsonToken;
    begin
        NewJsonToken.ReadFrom(NewValue);
        exit(Add(NewJsonToken));
    end;

    procedure Add(NewJsonToken: JsonToken): Interface "Test Json"
    var
        NewTestJson: Codeunit "Test Json";
    begin
        if not TestJson.IsArray() then
            Error(TheElementIsNotAnArrayErr);

        TestJson.AsArray().Add(NewJsonToken);
        NewTestJson.Initialize(NewJsonToken);
        exit(NewTestJson);
    end;

    procedure Add(Name: Text; NewValue: Text): Interface "Test Json"
    var
        NewJsonObject: JsonObject;
        NewJsonArray: JsonArray;
        NewJsonValue: JsonValue;
    begin
        if NewValue = '' then begin
            NewJsonObject.ReadFrom('{}');
            exit(Add(Name, NewJsonObject.AsToken()));
        end;

        if NewValue = '[]' then begin
            NewJsonArray.ReadFrom('[]');
            exit(Add(Name, NewJsonArray.AsToken()));
        end;

        NewJsonValue.ReadFrom('"' + NewValue + '"');
        exit(Add(Name, NewJsonValue.AsToken()));
    end;

    procedure Add(Name: Text; ValueVariant: JsonToken): Interface "Test Json"
    var
        NewTestJson: Codeunit "Test Json";
    begin
        if TestJson.IsObject() then begin
            TestJson.AsObject().Add(Name, ValueVariant);
            NewTestJson.Initialize(ValueVariant);
            exit(NewTestJson);
        end;

        if TestJson.IsArray() then begin
            TestJson.AsArray().Add(ValueVariant);
            NewTestJson.Initialize(ValueVariant);
            exit(NewTestJson);
        end;
    end;

    procedure AddArray(Name: Text): Interface "Test Json"
    begin
        exit(Add(Name, '[]'));
    end;

    procedure Element(ElementName: Text): Interface "Test Json"
    var
        NewTestJson: Codeunit "Test Json";
        ElementJsonToken: JsonToken;
    begin
        if not TestJson.IsObject() then
            Error(TheElementIsNotAnObjectErr);

        TestJson.AsObject().Get(ElementName, ElementJsonToken);
        NewTestJson.Initialize(ElementJsonToken);
        exit(NewTestJson);
    end;

    procedure ElementAt(ElementIndex: Integer): Interface "Test Json"
    var
        NewTestJson: Codeunit "Test Json";
        JsonElementToken: JsonToken;
    begin
        if not TestJson.IsArray() then
            Error(TheElementIsNotAnArrayErr);
        TestJson.AsArray().Get(ElementIndex, JsonElementToken);
        NewTestJson.Initialize(JsonElementToken);
        exit(NewTestJson);
    end;

    procedure ToText(): Text
    var
        TextOutput: Text;
    begin
        TestJson.WriteTo(TextOutput);
        exit(TextOutput);
    end;

    procedure ReplaceElement(ElementName: Text; NewValue: Text): Interface "Test Json"
    var
        ElementJsonToken: JsonToken;
        NewTestJson: Codeunit "Test Json";
    begin
        ElementJsonToken.ReadFrom(NewValue);

        if not TestJson.AsObject().Get(ElementName, ElementJsonToken) then
            TestJson.AsObject().Add(ElementName, ElementJsonToken);

        NewTestJson.Initialize(ElementJsonToken);
        exit(NewTestJson);
        exit(NewTestJson);
    end;

    procedure ReplaceElement(ElementName: Text; NewJsonToken: JsonToken): Interface "Test Json";
    var
        ElementJsonToken: JsonToken;
        NewTestJson: Codeunit "Test Json";
    begin
        TestJson.AsObject().Get(ElementName, ElementJsonToken);
        ElementJsonToken := NewJsonToken;
        NewTestJson.Initialize(ElementJsonToken);

        exit(NewTestJson);
    end;

    var
        TheElementIsNotAnObjectErr: Label 'The element is not an object, use a different method.';
        TheElementIsNotAnArrayErr: Label 'The element is not an array, use a different method.';
        TestJson: JsonToken;
}