// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

using Microsoft.CRM.Outlook;
using System;
using System.Utilities;
using System.Xml;

codeunit 5459 "JSON Management"
{

    trigger OnRun()
    begin
    end;

    var
        JsonArray: DotNet JArray;
        JsonObject: DotNet JObject;
        IEnumerator: DotNet GenericIEnumerator1;

    procedure InitializeCollection(JSONString: Text)
    begin
        InitializeCollectionFromString(JSONString);
    end;

    procedure InitializeEmptyCollection()
    begin
        JsonArray := JsonArray.JArray();
    end;

    procedure InitializeObject(JSONString: Text)
    begin
        InitializeObjectFromString(JSONString);
    end;

    [Scope('OnPrem')]
    procedure InitializeObjectFromJObject(NewJsonObject: DotNet JObject)
    begin
        JsonObject := NewJsonObject;
    end;

    [Scope('OnPrem')]
    procedure InitializeCollectionFromJArray(NewJsonArray: DotNet JArray)
    begin
        JsonArray := NewJsonArray;
    end;

    procedure InitializeEmptyObject()
    begin
        JsonObject := JsonObject.JObject();
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

    procedure InitializeFromString(JSONString: Text): Boolean
    begin
        Clear(JsonObject);
        if JSONString <> '' then
            exit(TryParseJObjectFromString(JsonObject, JSONString));

        InitializeEmptyObject();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetJSONObject(var JObject: DotNet JObject)
    begin
        JObject := JsonObject;
    end;

    [Scope('OnPrem')]
    procedure GetJsonArray(var JArray: DotNet JArray)
    begin
        JArray := JsonArray;
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

    procedure GetJObjectFromCollectionByIndex(var JObject: DotNet JObject; Index: Integer): Boolean
    begin
        if (GetCollectionCount() = 0) or (GetCollectionCount() <= Index) then
            exit(false);

        JObject := JsonArray.Item(Index);
        exit(not IsNull(JObject))
    end;

    [Scope('OnPrem')]
    procedure GetJObjectFromCollectionByPropertyValue(var JObject: DotNet JObject; propertyName: Text; value: Text): Boolean
    var
        IEnumerable: DotNet GenericIEnumerable1;
        IEnumerator: DotNet GenericIEnumerator1;
    begin
        Clear(JObject);
        IEnumerable := JsonArray.SelectTokens(StrSubstNo('$[?(@.%1 == ''%2'')]', propertyName, value), false);
        IEnumerator := IEnumerable.GetEnumerator();

        if IEnumerator.MoveNext() then begin
            JObject := IEnumerator.Current;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Variant): Boolean
    var
        JProperty: DotNet JProperty;
        JToken: DotNet JToken;
    begin
        Clear(value);
        if JObject.TryGetValue(propertyName, JToken) then begin
            JProperty := JObject.Property(propertyName);
            value := JProperty.Value();
            exit(true);
        end;
    end;

    procedure GetPropertyValueByName(propertyName: Text; var value: Variant): Boolean
    begin
        exit(GetPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    [Scope('OnPrem')]
    procedure GetPropertyValueFromJObjectByPathSetToFieldRef(JObject: DotNet JObject; propertyPath: Text; var FieldRef: FieldRef): Boolean
    var
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
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
                        IntVar := OutlookSynchTypeConv.TextToOptionValue(Value, FieldRef.OptionCaption);
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

    procedure GetPropertyValueFromJObjectByPath(JObject: DotNet JObject; fullyQualifiedPropertyName: Text; var value: Variant): Boolean
    var
        containerJObject: DotNet JObject;
        propertyName: Text;
    begin
        Clear(value);
        DecomposeQualifiedPathToContainerObjectAndPropertyName(JObject, fullyQualifiedPropertyName, containerJObject, propertyName);
        if IsNull(containerJObject) then
            exit(false);

        exit(GetPropertyValueFromJObjectByName(containerJObject, propertyName, value));
    end;

    [Scope('OnPrem')]
    procedure GetStringPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Text): Boolean
    var
        VariantValue: Variant;
    begin
        Clear(value);
        if GetPropertyValueFromJObjectByName(JObject, propertyName, VariantValue) then begin
            value := Format(VariantValue);
            exit(true);
        end;
        exit(false);
    end;

    procedure GetStringPropertyValueByName(propertyName: Text; var value: Text): Boolean
    begin
        exit(GetStringPropertyValueFromJObjectByName(JsonObject, propertyName, value));
    end;

    [Scope('OnPrem')]
    procedure GetStringPropertyValueFromJObjectByPath(JObject: DotNet JObject; fullyQualifiedPropertyName: Text; var value: Text): Boolean
    var
        VariantValue: Variant;
    begin
        Clear(value);
        if GetPropertyValueFromJObjectByPath(JObject, fullyQualifiedPropertyName, VariantValue) then begin
            value := Format(VariantValue);
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetEnumPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Option)
    var
        StringValue: Text;
    begin
        GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue);
        Evaluate(value, StringValue, 0);
    end;

    [Scope('OnPrem')]
    procedure GetBoolPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Boolean): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue, 2);
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetArrayPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var JArray: DotNet JArray): Boolean
    var
        JProperty: DotNet JProperty;
        JToken: DotNet JToken;
    begin
        Clear(JArray);
        if JObject.TryGetValue(propertyName, JToken) then begin
            JProperty := JObject.Property(propertyName);
            JArray := JProperty.Value();
            exit(true);
        end;
        exit(false);
    end;

    procedure GetArrayPropertyValueAsStringByName(propertyName: Text; var value: Text): Boolean
    var
        JArray: DotNet JArray;
    begin
        if not GetArrayPropertyValueFromJObjectByName(JsonObject, propertyName, JArray) then
            exit(false);

        value := JArray.ToString();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetObjectPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var JSubObject: DotNet JObject): Boolean
    var
        JProperty: DotNet JProperty;
        JToken: DotNet JToken;
    begin
        Clear(JSubObject);
        if JObject.TryGetValue(propertyName, JToken) then begin
            JProperty := JObject.Property(propertyName);
            JSubObject := JProperty.Value();
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetDecimalPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Decimal): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetGuidPropertyValueFromJObjectByName(JObject: DotNet JObject; propertyName: Text; var value: Guid): Boolean
    var
        StringValue: Text;
    begin
        if GetStringPropertyValueFromJObjectByName(JObject, propertyName, StringValue) then begin
            Evaluate(value, StringValue);
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetValueFromJObject(JToken: DotNet JToken; var value: Variant)
    var
        JValue: DotNet JValue;
    begin
        Clear(value);
        JValue := JToken;
        value := JValue.Value();
    end;

    [Scope('OnPrem')]
    procedure GetStringValueFromJObject(JObject: DotNet JObject; var value: Text)
    var
        VariantValue: Variant;
    begin
        Clear(value);
        GetValueFromJObject(JObject, VariantValue);
        value := Format(VariantValue);
    end;

    [Scope('OnPrem')]
    procedure AddJArrayToJObject(var JObject: DotNet JObject; propertyName: Text; value: Variant)
    var
        JArray2: DotNet JArray;
        JProperty: DotNet JProperty;
    begin
        JArray2 := value;
        JObject.Add(JProperty.JProperty(propertyName, JArray2));
    end;

    [Scope('OnPrem')]
    procedure AddJObjectToJObject(var JObject: DotNet JObject; propertyName: Text; value: Variant)
    var
        JObject2: DotNet JObject;
        JToken: DotNet JToken;
        ValueText: Text;
    begin
        JObject2 := value;
        ValueText := Format(value);
        JObject.Add(propertyName, JToken.Parse(ValueText));
    end;

    [Scope('OnPrem')]
    procedure AddJObjectToJArray(var JArray: DotNet JArray; value: Variant)
    var
        JObject: DotNet JObject;
    begin
        JObject := value;
        JArray.Add(JObject.DeepClone());
    end;

    [Scope('OnPrem')]
    procedure AddJPropertyToJObject(var JObject: DotNet JObject; propertyName: Text; value: Variant)
    var
        JObject2: DotNet JObject;
        JProperty: DotNet JProperty;
        ValueText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddJPropertyToJObject(JObject, JProperty, propertyName, value, IsHandled);
        if IsHandled then
            exit;

        case true of
            value.IsDotNet:
                begin
                    JObject2 := value;
                    JObject.Add(propertyName, JObject2);
                end;
            value.IsInteger,
            value.IsDecimal,
            value.IsBoolean:
                begin
                    JProperty := JProperty.JProperty(propertyName, value);
                    JObject.Add(JProperty);
                end;
            else begin
                ValueText := Format(value, 0, 9);
                JProperty := JProperty.JProperty(propertyName, ValueText);
                JObject.Add(JProperty);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddNullJPropertyToJObject(var JObject: DotNet JObject; propertyName: Text)
    var
        JValue: DotNet JValue;
    begin
        JObject.Add(propertyName, JValue.CreateNull());
    end;

    [Scope('OnPrem')]
    procedure AddJValueToJObject(var JObject: DotNet JToken; value: Variant)
    var
        JValue: DotNet JValue;
    begin
        JObject := JValue.JValue(value);
    end;

    [Scope('OnPrem')]
    procedure AddJObjectToCollection(JObject: DotNet JObject)
    begin
        JsonArray.Add(JObject.DeepClone());
    end;

    [Scope('OnPrem')]
    procedure AddJArrayContentToCollection(JArray: DotNet JArray)
    begin
        JsonArray.Merge(JArray.DeepClone());
    end;

    [Scope('OnPrem')]
    procedure ReplaceOrAddJPropertyInJObject(var JObject: DotNet JObject; propertyName: Text; value: Variant): Boolean
    var
        JProperty: DotNet JProperty;
        OldProperty: DotNet JProperty;
        oldValue: Variant;
    begin
        JProperty := JObject.Property(propertyName);
        if not IsNull(JProperty) then begin
            OldProperty := JObject.Property(propertyName);
            oldValue := OldProperty.Value();
            JProperty.Replace(JProperty.JProperty(propertyName, value));
            exit(Format(oldValue) <> Format(value));
        end;

        AddJPropertyToJObject(JObject, propertyName, value);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ReplaceOrAddDescendantJPropertyInJObject(var JObject: DotNet JObject; fullyQualifiedPropertyName: Text; value: Variant): Boolean
    var
        containerJObject: DotNet JObject;
        propertyName: Text;
    begin
        DecomposeQualifiedPathToContainerObjectAndPropertyName(JObject, fullyQualifiedPropertyName, containerJObject, propertyName);
        exit(ReplaceOrAddJPropertyInJObject(containerJObject, propertyName, value));
    end;

    procedure GetCollectionCount(): Integer
    begin
        exit(JsonArray.Count);
    end;

    procedure WriteCollectionToString(): Text
    begin
        exit(JsonArray.ToString());
    end;

    procedure WriteObjectToString(): Text
    begin
        if not IsNull(JsonObject) then
            exit(JsonObject.ToString());
    end;

    procedure FormatDecimalToJSONProperty(Value: Decimal; PropertyName: Text): Text
    var
        JProperty: DotNet JProperty;
    begin
        JProperty := JProperty.JProperty(PropertyName, Value);
        exit(JProperty.ToString());
    end;

    local procedure GetLastIndexOfPeriod(String: Text) LastIndex: Integer
    var
        Index: Integer;
    begin
        Index := StrPos(String, '.');
        LastIndex := Index;
        while Index > 0 do begin
            String := CopyStr(String, Index + 1);
            Index := StrPos(String, '.');
            LastIndex += Index;
        end;
    end;

    local procedure GetSubstringToLastPeriod(String: Text): Text
    var
        Index: Integer;
    begin
        Index := GetLastIndexOfPeriod(String);
        if Index > 0 then
            exit(CopyStr(String, 1, Index - 1));
    end;

    local procedure DecomposeQualifiedPathToContainerObjectAndPropertyName(var JObject: DotNet JObject; fullyQualifiedPropertyName: Text; var containerJObject: DotNet JObject; var propertyName: Text)
    var
        containerJToken: DotNet JToken;
        containingPath: Text;
    begin
        Clear(containerJObject);
        propertyName := '';

        containingPath := GetSubstringToLastPeriod(fullyQualifiedPropertyName);
        containerJToken := JObject.SelectToken(containingPath);
        if IsNull(containerJToken) then begin
            DecomposeQualifiedPathToContainerObjectAndPropertyName(JObject, containingPath, containerJObject, propertyName);
            containerJObject.Add(propertyName, JObject.JObject());
            containerJToken := JObject.SelectToken(containingPath);
        end;

        containerJObject := containerJToken;
        if containingPath <> '' then
            propertyName := CopyStr(fullyQualifiedPropertyName, StrLen(containingPath) + 2)
        else
            propertyName := fullyQualifiedPropertyName;
    end;

    procedure XMLTextToJSONText(Xml: Text) Json: Text
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        JsonConvert: DotNet JsonConvert;
        JsonFormatting: DotNet Formatting;
        XmlDocument: DotNet XmlDocument;
    begin
        XMLDOMMgt.LoadXMLDocumentFromText(Xml, XmlDocument);
        Json := JsonConvert.SerializeXmlNode(XmlDocument.DocumentElement, JsonFormatting.Indented, true);
    end;

    procedure JSONTextToXMLText(Json: Text; DocumentElementName: Text) Xml: Text
    var
        JsonConvert: DotNet JsonConvert;
        XmlDocument: DotNet XmlDocument;
    begin
        XmlDocument := JsonConvert.DeserializeXmlNode(Json, DocumentElementName);
        Xml := XmlDocument.OuterXml();
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryParseJObjectFromString(var JObject: DotNet JObject; StringToParse: Variant)
    begin
        JObject := JObject.Parse(Format(StringToParse));
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryParseJArrayFromString(var JsonArray: DotNet JArray; StringToParse: Variant)
    begin
        JsonArray := JsonArray.Parse(Format(StringToParse));
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

    procedure SetValue(Path: Text; Value: Variant)
    begin
        if IsNull(JsonObject) then
            InitializeEmptyObject();
        ReplaceOrAddDescendantJPropertyInJObject(JsonObject, Path, Value);
    end;

    procedure GetValue(Path: Text): Text
    var
        SelectedJToken: DotNet JToken;
    begin
        if IsNull(JsonObject) then
            exit('');

        SelectedJToken := JsonObject.SelectToken(Path);
        if not IsNull(SelectedJToken) then
            exit(SelectedJToken.ToString());
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

    procedure HasValue(Name: Text; Value: Text): Boolean
    begin
        if not IsNull(JsonObject) then
            exit(StrPos(GetValue(Name), Value) = 1);
    end;

    procedure AddArrayValue(Value: Variant)
    begin
        if IsNull(JsonArray) then
            InitializeEmptyCollection();
        JsonArray.Add(Value);
    end;

    procedure AddJson(Path: Text; JsonString: Text)
    var
        JObject: DotNet JObject;
    begin
        if JsonString <> '' then
            if TryParseJObjectFromString(JObject, JsonString) then
                SetValue(Path, JObject);
    end;

    procedure AddJsonArray(Path: Text; JsonArrayString: Text)
    var
        JsonArrayLocal: DotNet JArray;
    begin
        if JsonArrayString <> '' then
            if TryParseJArrayFromString(JsonArrayLocal, JsonArrayString) then
                SetValue(Path, JsonArrayLocal);
    end;

    procedure SelectTokenFromRoot(Path: Text): Boolean
    begin
        if IsNull(JsonObject) then
            exit(false);

        JsonObject := JsonObject.Root;
        JsonObject := JsonObject.SelectToken(Path);
        exit(not IsNull(JsonObject));
    end;

    procedure ReadProperties(): Boolean
    var
        IEnumerable: DotNet GenericIEnumerable1;
    begin
        if not JsonObject.HasValues then
            exit(false);

        IEnumerable := JsonObject.Properties();
        IEnumerator := IEnumerable.GetEnumerator();
        exit(true);
    end;

    procedure GetNextProperty(var Name: Text; var Value: Text): Boolean
    var
        JProperty: DotNet JProperty;
    begin
        Name := '';
        Value := '';

        if not IEnumerator.MoveNext() then
            exit(false);

        JProperty := IEnumerator.Current;
        if IsNull(JProperty) then
            exit(false);

        Name := JProperty.Name;
        Value := Format(JProperty.Value);
        exit(true);
    end;

    procedure SelectItemFromRoot(Path: Text; Index: Integer): Boolean
    begin
        if SelectTokenFromRoot(Path) then
            JsonObject := JsonObject.Item(Index);
        exit(not IsNull(JsonObject));
    end;

    procedure GetCount(): Integer
    begin
        if not IsNull(JsonObject) then
            exit(JsonObject.Count);
    end;

    procedure SetJsonWebResponseError(var JsonString: Text; "code": Text; name: Text; description: Text)
    begin
        if InitializeFromString(JsonString) then begin
            SetValue('Error.code', code);
            SetValue('Error.name', name);
            SetValue('Error.description', description);
            JsonString := WriteObjectToString();
        end;
    end;

    procedure GetJsonWebResponseError(JsonString: Text; var "code": Text; var name: Text; var description: Text): Boolean
    begin
        if InitializeFromString(JsonString) then begin
            code := GetValue('Error.code');
            name := GetValue('Error.name');
            description := GetValue('Error.description');
            exit(true);
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddJPropertyToJObject(var JObject: DotNet "JObject"; var JProperty: DotNet "JProperty"; propertyName: Text; value: Variant; var IsHandled: Boolean)
    begin
    end;
}

