interface "Test Json"
{
    procedure Initialize();
    procedure Initialize(TestJsonValue: Text);
    procedure Initialize(TestJsonObject: JsonToken);

    procedure Element(ElementName: Text): Interface "Test Json";
    procedure ElementAt(ElementIndex: Integer): Interface "Test Json";

    procedure Add(Name: Text; NewJsonToken: JsonToken): Interface "Test Json";
    procedure Add(NewJsonToken: JsonToken): Interface "Test Json";
    procedure Add(NewValue: Text): Interface "Test Json";
    procedure Add(Name: Text; NewValue: Text): Interface "Test Json";
    procedure AddArray(Name: Text): Interface "Test Json";
    procedure ReplaceElement(Name: Text; NewValue: Text): Interface "Test Json";
    procedure ReplaceElement(Name: Text; NewJsonToken: JsonToken): Interface "Test Json";

    procedure ToText(): Text;
}