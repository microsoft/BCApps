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
        ElementExists: Boolean;
    begin
        TestInputJson := ElementExists(ElementName, ElementExists);
        if not ElementExists then
            Error(ElementDoesNotExistErr);

        exit(TestInputJson);
    end;

    procedure ElementExists(ElementName: Text; var ElementExists: Boolean): Codeunit "Test Input Json"
    var
        NewTestJson: Codeunit "Test Input Json";
        ElementJsonToken: JsonToken;
    begin
        ElementExists := false;

        if not TestJson.IsObject() then
            exit(NewTestJson);

        if not TestJson.AsObject().Get(ElementName, ElementJsonToken) then
            exit(NewTestJson);

        ElementExists := true;
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

    var
        ElementDoesNotExistErr: Label 'DataInput - The element does not exist.';
        TheElementIsNotAnArrayErr: Label 'DataInput - The element is not an array, use a different method.';
        TestJson: JsonToken;
}