// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Text.Json;

using System.Device;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Text.Json;

codeunit 139910 "Json Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure TestGetCollectionCount()
    var
        Json: Codeunit "Json";
        ExpectedCount: Integer;
        ActualCount: Integer;
    begin
        // [GIVEN] A JSON collection is initialized with a known number of elements
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"}]');
        ExpectedCount := 2;

        // [WHEN] Retrieve the count of elements in the collection
        ActualCount := Json.GetCollectionCount();

        // [THEN] The actual count matches the expected count
        Assert.AreEqual(ExpectedCount, ActualCount, 'The count of elements in the JSON collection does not match the expected value.');
    end;

    [Test]
    procedure TestGetObjectFromCollectionByIndex()
    var
        Json: Codeunit "Json";
        ExpectedJObject: JsonObject;
        ExpectedJObjectText: Text;
        ActualJObject: JsonObject;
        ActualJObjectText: Text;
        Success: Boolean;
    begin
        // [GIVEN] A JSON collection with known objects
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"}]');

        // [WHEN] Retrieve an object by its index
        ExpectedJObject.ReadFrom('{"id":"XYZ789"}');
        ExpectedJObject.WriteTo(ExpectedJObjectText);
        Success := Json.GetObjectFromCollectionByIndex(1, ActualJObjectText); // Index is zero-based
        ActualJObject.ReadFrom(ActualJObjectText);
        ActualJObject.WriteTo(ActualJObjectText);

        // [THEN] The retrieved object matches the expected object
        Assert.IsTrue(Success, 'Failed to retrieve object by index.');
        Assert.AreEqual(ExpectedJObjectText, ActualJObjectText, 'The retrieved object does not match the expected object.');
    end;

    [Test]
    procedure TestGetObjectFromCollectionByZeroIndex()
    var
        Json: Codeunit "Json";
        ExpectedJObject: JsonObject;
        ExpectedJObjectText: Text;
        ActualJObject: JsonObject;
        ActualJObjectText: Text;
        Success: Boolean;
    begin
        // [GIVEN] A JSON collection with known objects
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"}]');

        // [WHEN] Retrieve an object by a zero index
        ExpectedJObject.ReadFrom('{"id":"ABC123"}');
        ExpectedJObject.WriteTo(ExpectedJObjectText);
        Success := Json.GetObjectFromCollectionByIndex(0, ActualJObjectText);
        ActualJObject.ReadFrom(ActualJObjectText);
        ActualJObject.WriteTo(ActualJObjectText);

        // [THEN] The retrieved object matches the expected object
        Assert.IsTrue(Success, 'Failed to retrieve object by index.');
        Assert.AreEqual(ExpectedJObjectText, ActualJObjectText, 'The retrieved object does not match the expected object.');
    end;

    [Test]
    procedure TestGetValueAndSetToRecFieldNo()
    var
        Printer: Record Printer;
        Json: Codeunit "Json";
        RecRef: RecordRef;
        JsonObjectText: Text;
    begin
        // [GIVEN] A JSON object and a record initialized
        JsonObjectText := '{"id":"ABC123","name":"Test Name"}';
        Json.InitializeObject(JsonObjectText);
        RecRef.GetTable(Printer);

        // [WHEN] Set values from JSON to record fields
        Json.GetValueAndSetToRecFieldNo(RecRef, 'id', Printer.FieldNo(ID));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'name', Printer.FieldNo(Name));
        RecRef.SetTable(Printer);

        // [THEN] The record fields are updated correctly
        Assert.AreEqual('ABC123', Printer.ID, 'The Id field was not set correctly.');
        Assert.AreEqual('Test Name', Printer.Name, 'The Name field was not set correctly.');
    end;

    [Test]
    procedure TestGetPropertyValueByName()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
        Value: Variant;
    begin
        // [GIVEN] A JSON object with a known value
        JsonObjectText := '{"id":"ABC123", "name":"Test Name"}';
        Json.InitializeObject(JsonObjectText);

        // [WHEN] Retrieve a value from the JSON object
        Json.GetPropertyValueByName('id', Value);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual('ABC123', Format(Value), 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetStringPropertyValueByName()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
        Value: Text;
    begin
        // [GIVEN] A JSON object with a known value
        JsonObjectText := '{"id":"ABC123", "name":"Test Name"}';
        Json.InitializeObject(JsonObjectText);

        // [WHEN] Retrieve a value from the JSON object
        Json.GetStringPropertyValueByName('id', Value);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual('ABC123', Value, 'The retrieved value does not match the expected value.');

        // [WHEN] Retrieve a value from the JSON object
        Json.GetStringPropertyValueByName('name', Value);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual('Test Name', Value, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetStringPropertyValuePreservesBooleanCasing()
    var
        Json: Codeunit "Json";
        Value: Text;
    begin
        Json.InitializeObject('{"boolean":true,"text":"true"}');

        Assert.IsTrue(Json.GetStringPropertyValueByName('boolean', Value), 'Boolean property was not found.');
        Assert.AreEqual('True', Value, 'Boolean JSON value was not formatted compatibly.');
        Assert.IsTrue(Json.GetStringPropertyValueByName('text', Value), 'Text property was not found.');
        Assert.AreEqual('true', Value, 'Text JSON value was changed while normalizing Boolean values.');
    end;

    [Test]
    procedure TestGetIntegerPropertyValueFromJObjectByName()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
        Value: Integer;
    begin
        // [GIVEN] A JSON object with a known value
        JsonObjectText := '{"id":123, "name":"Test Name"}';
        Json.InitializeObject(JsonObjectText);

        // [WHEN] Retrieve a value from the JSON object
        Json.GetIntegerPropertyValueFromJObjectByName('id', Value);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual(123, Value, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetBoolPropertyValueFromJObjectByName()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
        Value: Boolean;
    begin
        // [GIVEN] A JSON object with a known value
        JsonObjectText := '{"id":123, "name":"Test Name", "isActive":true}';
        Json.InitializeObject(JsonObjectText);

        // [WHEN] Retrieve a value from the JSON object
        Json.GetBoolPropertyValueFromJObjectByName('isActive', Value);

        // [THEN] The retrieved value matches the expected value
        Assert.IsTrue(Value, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetDecimalPropertyValueFromJObjectByName()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
        Value: Decimal;
    begin
        // [GIVEN] A JSON object with a known value
        JsonObjectText := '{"id":123, "name":"Test Name", "price":123.45}';
        Json.InitializeObject(JsonObjectText);

        // [WHEN] Retrieve a value from the JSON object
        Json.GetDecimalPropertyValueFromJObjectByName('price', Value);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual(123.45, Value, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetGuidPropertyValueFromJObjectByName()
    var
        Json: Codeunit "Json";
        ExpectedValue: Guid;
        Value: Guid;
    begin
        // [GIVEN] A JSON object with a GUID value
        ExpectedValue := CreateGuid();
        Json.InitializeObject('{"id":"' + Format(ExpectedValue) + '"}');

        // [WHEN] Retrieve the GUID from the JSON object
        Assert.IsTrue(Json.GetGuidPropertyValueFromJObjectByName('id', Value), 'The GUID property was not found.');

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual(ExpectedValue, Value, 'The retrieved GUID value does not match the expected value.');
    end;

    [Test]
    procedure TestGetEnumPropertyValueFromJObjectByName()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
        Value: Option Option1,Option2,Option3;
    begin
        // [GIVEN] A JSON object with a known value
        JsonObjectText := '{"id":123, "name":"Test Name", "optionValue":"Option1"}';
        Json.InitializeObject(JsonObjectText);

        // [WHEN] Retrieve a value from the JSON object
        Json.GetEnumPropertyValueFromJObjectByName('optionValue', Value);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual(Value::Option1, Value, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetCollectionAsText()
    var
        Json: Codeunit "Json";
        JsonArrayText: Text;
    begin

        // [GIVEN] A JSON array with a known value
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"}]');

        // [WHEN] Retrieve JSON array
        JsonArrayText := Json.GetCollectionAsText();

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual('[{"id":"ABC123"},{"id":"XYZ789"}]', JsonArrayText, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetCollection()
    var
        Json: Codeunit "Json";
        JsonArray: JsonArray;
        JsonArrayText: Text;
    begin
        // [GIVEN] A JSON array with a known value
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"}]');

        // [WHEN] Retrieve JSON array
        JsonArray := Json.GetCollection();
        JsonArray.WriteTo(JsonArrayText);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual('[{"id":"ABC123"},{"id":"XYZ789"}]', JsonArrayText, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetObjectAsText()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
    begin
        // [GIVEN] A JSON object with a known value
        Json.InitializeObject('{"id":"ABC123","name":"Test Name"}');

        // [WHEN] Retrieve JSON object
        JsonObjectText := Json.GetObjectAsText();

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual('{"id":"ABC123","name":"Test Name"}', JsonObjectText, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestGetObject()
    var
        Json: Codeunit "Json";
        JsonObject: JsonObject;
        JsonObjectText: Text;
    begin
        // [GIVEN] A JSON object with a known value
        Json.InitializeObject('{"id":"ABC123","name":"Test Name"}');

        // [WHEN] Retrieve JSON object
        JsonObject := Json.GetObject();
        JsonObject.WriteTo(JsonObjectText);

        // [THEN] The retrieved value matches the expected value
        Assert.AreEqual('{"id":"ABC123","name":"Test Name"}', JsonObjectText, 'The retrieved value does not match the expected value.');
    end;

    [Test]
    procedure TestXMLTextToJSONTextWithUTF8BOM()
    var
        Json: Codeunit "Json";
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        ByteOrderMarkUtf8: Text[1];
        JsonText: Text;
        XmlText: Text;
    begin
        // [GIVEN] XML text prefixed with a UTF-8 byte order mark
        ByteOrderMarkUtf8[1] := 65279;
        XmlText := ByteOrderMarkUtf8 + '<root><value>test</value></root>';

        // [WHEN] The XML text is converted to JSON
        JsonText := Json.XMLTextToJSONText(XmlText);

        // [THEN] The JSON contains the XML document element content
        Assert.IsTrue(JsonObject.ReadFrom(JsonText), 'The XML text was not converted to valid JSON.');
        Assert.IsTrue(JsonObject.Get('value', JsonToken), 'The converted JSON does not contain the expected value.');
        Assert.IsTrue(JsonToken.IsValue(), 'The converted JSON value has an unexpected type.');
        Assert.AreEqual('test', JsonToken.AsValue().AsText(), 'The converted JSON value is incorrect.');
    end;

    [Test]
    procedure TestXMLTextToJSONTextRejectsDTD()
    var
        Json: Codeunit "Json";
    begin
        asserterror Json.XMLTextToJSONText('<!DOCTYPE root [<!ENTITY value "test">]><root>&value;</root>');
    end;

    [Test]
    procedure TestJSONTextToXMLTextWithoutDeclaration()
    var
        Json: Codeunit "Json";
        XmlText: Text;
    begin
        // [WHEN] JSON text is converted to XML
        XmlText := Json.JSONTextToXMLText('{"value":"test"}', 'root');

        // [THEN] The XML contains only the document element, without an XML declaration
        Assert.AreEqual('<root><value>test</value></root>', XmlText, 'The converted XML is incorrect.');
        Assert.AreEqual(0, StrPos(XmlText, '<?xml'), 'The converted XML must not contain an XML declaration.');
    end;

    [Test]
    procedure TestReplaceOrAddJPropertyInJObject()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
        NewJsonObjectText: Text;
    begin
        // [GIVEN] A JSON object with a known value
        Json.InitializeObject('{"id":"ABC123","name":"Test Name"}');

        // [WHEN] Replace a property in the JSON object
        Json.ReplaceOrAddJPropertyInJObject('id', 'XYZ987');
        JsonObjectText := Json.GetObjectAsText();

        // [THEN] The replaced value matches the expected value
        Assert.AreEqual('{"id":"XYZ987","name":"Test Name"}', JsonObjectText, 'The replaced value does not match the expected value.');

        // [WHEN] Add a new property to the JSON object
        Json.ReplaceOrAddJPropertyInJObject('newProperty', 'New Property Value');
        NewJsonObjectText := Json.GetObjectAsText();

        // [THEN] The added value matches the expected value
        Assert.AreEqual('{"id":"XYZ987","name":"Test Name","newProperty":"New Property Value"}', NewJsonObjectText, 'The added value does not match the expected value.');
    end;

    [Test]
    procedure TestReplaceJObjectInCollection()
    var
        Json: Codeunit "Json";
        JsonArrayText: Text;
        NewJsonArrayText: Text;
    begin
        // [GIVEN] A JSON array with a known value
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"}]');

        // [WHEN] Replace JSON object in the JSON array
        Json.ReplaceJObjectInCollection(0, '{"id":"DYK484"}');
        JsonArrayText := Json.GetCollectionAsText();

        // [THEN] The replaced value matches the expected value
        Assert.AreEqual('[{"id":"DYK484"},{"id":"XYZ789"}]', JsonArrayText, 'The replaced value does not match the expected value.');

        // [WHEN] Replace JSON object in the JSON array
        Json.ReplaceJObjectInCollection(1, '{"id":"ZXY987"}');
        NewJsonArrayText := Json.GetCollectionAsText();

        // [THEN] The replaced value matches the expected value
        Assert.AreEqual('[{"id":"DYK484"},{"id":"ZXY987"}]', NewJsonArrayText, 'The replaced value does not match the expected value.');
    end;

    [Test]
    procedure TestAddJObjectToCollection()
    var
        Json: Codeunit "Json";
        JsonArrayText: Text;
    begin
        // [GIVEN] A JSON array with a known value
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"}]');

        // [WHEN] Add JSON object to the JSON array
        Json.AddJObjectToCollection('{"id":"DYK484"}');
        JsonArrayText := Json.GetCollectionAsText();

        // [THEN] The added value matches the expected value
        Assert.AreEqual('[{"id":"ABC123"},{"id":"XYZ789"},{"id":"DYK484"}]', JsonArrayText, 'The added value does not match the expected value.');
    end;

    [Test]
    procedure TestRemoveJObjectFromCollection()
    var
        Json: Codeunit "Json";
        JsonArrayText: Text;
    begin
        // [GIVEN] A JSON array with a known value
        Json.InitializeCollection('[{"id":"ABC123"},{"id":"XYZ789"},{"id":"DYK484"}]');

        // [WHEN] Remove JSON object from the JSON array
        Json.RemoveJObjectFromCollection(1);
        JsonArrayText := Json.GetCollectionAsText();

        // [THEN] The removed value matches the expected value
        Assert.AreEqual('[{"id":"ABC123"},{"id":"DYK484"}]', JsonArrayText, 'The removed value does not match the expected value.');
    end;

    [Test]
    procedure TestEmptyInitialization()
    var
        Json: Codeunit "Json";
    begin
        // [WHEN] Empty object and collection text are initialized
        Json.InitializeObject('');
        Json.InitializeCollection('');

        // [THEN] Both native states contain empty JSON containers
        Assert.AreEqual('{}', Json.GetObjectAsText(), 'Empty object initialization did not create an empty object.');
    end;

    [Test]
    procedure TestInvalidJsonInputRaisesError()
    var
        Json: Codeunit "Json";
    begin
        asserterror Json.InitializeCollection('not json');
        asserterror Json.InitializeObject('not json');

        Json.InitializeCollection('[]');
        asserterror Json.AddJObjectToCollection('not json');
        Assert.AreEqual('[]', Json.GetCollectionAsText(), 'Invalid object input changed the collection.');
        Assert.AreEqual('[]', Json.GetCollectionAsText(true), 'Invalid object input changed the indented collection.');
        Assert.AreEqual(0, Json.GetCollectionCount(), 'Invalid object input changed the collection count.');

        Json.InitializeCollection('[{}]');
        asserterror Json.ReplaceJObjectInCollection(0, 'not json');
        Assert.AreEqual('[{}]', Json.GetCollectionAsText(), 'Invalid replacement input changed the collection.');
        Assert.AreEqual(1, Json.GetCollectionCount(), 'Invalid replacement input changed the collection count.');
    end;

    [Test]
    procedure TestObjectAndCollectionStateAreIndependent()
    var
        Json: Codeunit "Json";
        SelectedObjectText: Text;
    begin
        // [GIVEN] Independently initialized object and collection states
        Json.InitializeObject('{"objectState":"first"}');
        Json.InitializeCollection('[{"collectionState":"kept"}]');

        // [THEN] Initializing the collection did not replace object state
        Assert.AreEqual('{"objectState":"first"}', Json.GetObjectAsText(), 'Collection initialization changed object state.');

        // [WHEN] Object state is initialized again
        Json.InitializeObject('{"objectState":"second"}');

        // [THEN] Collection state is unchanged
        Assert.AreEqual('[{"collectionState":"kept"}]', Json.GetCollectionAsText(), 'Object initialization changed collection state.');

        // [GIVEN] Object state refers to an item in the current collection
        Assert.IsTrue(Json.GetObjectFromCollectionByIndex(0, SelectedObjectText), 'The collection object was not selected.');

        // [WHEN] Collection state is initialized again
        Json.InitializeCollection('[{"collectionState":"replacement"}]');

        // [THEN] The previously selected object remains valid and independent of the new collection
        Assert.AreEqual('{"collectionState":"kept"}', Json.GetObjectAsText(), 'Collection reinitialization changed the selected object state.');
        Assert.AreEqual('[{"collectionState":"replacement"}]', Json.GetCollectionAsText(), 'Collection reinitialization produced unexpected state.');
    end;

    [Test]
    procedure TestInvalidCollectionIndexesAreSafe()
    var
        Json: Codeunit "Json";
        JsonObjectText: Text;
    begin
        // [GIVEN] A collection with one object
        Json.InitializeCollection('[{"id":"one"}]');
        JsonObjectText := 'unchanged';

        // [WHEN] Negative and out-of-range indexes are used
        // [THEN] Operations fail without changing collection state or the output parameter
        Assert.IsFalse(Json.GetObjectFromCollectionByIndex(-1, JsonObjectText), 'A negative index was accepted.');
        Assert.AreEqual('unchanged', JsonObjectText, 'A failed selection changed the output value.');
        Assert.IsFalse(Json.GetObjectFromCollectionByIndex(1, JsonObjectText), 'An out-of-range index was accepted.');
        Assert.IsFalse(Json.RemoveJObjectFromCollection(-1), 'A negative remove index was accepted.');
        Assert.IsFalse(Json.RemoveJObjectFromCollection(1), 'An out-of-range remove index was accepted.');
        Assert.IsFalse(Json.ReplaceJObjectInCollection(-1, '{"id":"replacement"}'), 'A negative replace index was accepted.');
        Assert.IsFalse(Json.ReplaceJObjectInCollection(1, '{"id":"replacement"}'), 'An out-of-range replace index was accepted.');
        Assert.AreEqual('[{"id":"one"}]', Json.GetCollectionAsText(), 'An invalid index changed collection state.');
    end;

    [Test]
    procedure TestSelectedCollectionObjectMutatesCollectionState()
    var
        Json: Codeunit "Json";
        SelectedObjectText: Text;
    begin
        // [GIVEN] The first collection object is selected
        Json.InitializeCollection('[{"id":"one"},{"id":"two"}]');
        Assert.IsTrue(Json.GetObjectFromCollectionByIndex(0, SelectedObjectText), 'The collection object was not selected.');

        // [WHEN] Object state is changed
        Json.ReplaceOrAddJPropertyInJObject('selected', true);

        // [THEN] Object state still refers to the selected collection item
        Assert.AreEqual('[{"id":"one","selected":true},{"id":"two"}]', Json.GetCollectionAsText(), 'Selected object mutation was not reflected in collection state.');
    end;

    [Test]
    procedure TestReplacedCollectionObjectRemainsSelected()
    var
        Json: Codeunit "Json";
    begin
        // [GIVEN] A collection object is replaced
        Json.InitializeCollection('[{"id":"one"}]');
        Assert.IsTrue(Json.ReplaceJObjectInCollection(0, '{"id":"replacement"}'), 'The collection object was not replaced.');

        // [WHEN] Object state is changed after replacement
        Json.ReplaceOrAddJPropertyInJObject('selected', true);

        // [THEN] Object state refers to the replacement in the collection
        Assert.AreEqual('[{"id":"replacement","selected":true}]', Json.GetCollectionAsText(), 'Replacement did not remain selected as object state.');
    end;

    [Test]
    procedure TestGetCollectionAndObjectReturnDeepClones()
    var
        Json: Codeunit "Json";
        DetachedArray: JsonArray;
        DetachedObject: JsonObject;
        NestedObject: JsonObject;
        JsonToken: JsonToken;
    begin
        // [GIVEN] Object and collection states containing nested objects
        Json.InitializeCollection('[{"nested":{"value":1}}]');
        Json.InitializeObject('{"nested":{"value":1}}');

        // [WHEN] Nested values in the returned native containers are changed
        DetachedArray := Json.GetCollection();
        DetachedArray.Get(0, JsonToken);
        DetachedObject := JsonToken.AsObject();
        DetachedObject.Get('nested', JsonToken);
        NestedObject := JsonToken.AsObject();
        NestedObject.Replace('value', 2);

        DetachedObject := Json.GetObject();
        DetachedObject.Get('nested', JsonToken);
        NestedObject := JsonToken.AsObject();
        NestedObject.Replace('value', 2);

        // [THEN] Persistent states are detached even for nested values
        Assert.AreEqual('[{"nested":{"value":1}}]', Json.GetCollectionAsText(), 'GetCollection returned an alias instead of a deep clone.');
        Assert.AreEqual('{"nested":{"value":1}}', Json.GetObjectAsText(), 'GetObject returned an alias instead of a deep clone.');
    end;

    [Test]
    procedure TestAddJObjectToCollectionDeepClonesObjectState()
    var
        Json: Codeunit "Json";
    begin
        // [GIVEN] An object is added to an empty collection
        Json.InitializeCollection('');
        Json.AddJObjectToCollection('{"nested":{"value":1}}');

        // [WHEN] The source object state is changed after the add
        Json.ReplaceOrAddJPropertyInJObject('sourceOnly', true);

        // [THEN] The collection contains a detached deep clone
        Assert.AreEqual('[{"nested":{"value":1}}]', Json.GetCollectionAsText(), 'AddJObjectToCollection retained an alias to object state.');
        Assert.AreEqual('{"nested":{"value":1},"sourceOnly":true}', Json.GetObjectAsText(), 'Object state did not retain the source object.');
    end;

    [Test]
    procedure TestVariantPropertyTypes()
    var
        Json: Codeunit "Json";
        ArrayValue: JsonArray;
        ObjectValue: JsonObject;
        Value: Variant;
        BooleanValue: Boolean;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        TextValue: Text;
    begin
        // [GIVEN] JSON properties of each native JSON shape
        Json.InitializeObject('{"text":"value","integer":42,"decimal":12.5,"boolean":true,"null":null,"object":{"id":1},"array":[1,2]}');

        // [WHEN] Scalar values are requested as variants
        Assert.IsTrue(Json.GetPropertyValueByName('text', Value), 'Text property was not found.');
        Assert.IsTrue(Value.IsText(), 'Text JSON value was not returned as AL Text.');
        TextValue := Value;
        Assert.AreEqual('value', TextValue, 'Text variant value is incorrect.');

        Assert.IsTrue(Json.GetPropertyValueByName('integer', Value), 'Integer property was not found.');
        Assert.IsTrue(Value.IsInteger(), 'Integer JSON value was not returned as AL Integer.');
        IntegerValue := Value;
        Assert.AreEqual(42, IntegerValue, 'Integer variant value is incorrect.');

        Assert.IsTrue(Json.GetPropertyValueByName('decimal', Value), 'Decimal property was not found.');
        Assert.IsTrue(Value.IsDecimal(), 'Decimal JSON value was not returned as AL Decimal.');
        DecimalValue := Value;
        Assert.AreEqual(12.5, DecimalValue, 'Decimal variant value is incorrect.');

        Assert.IsTrue(Json.GetPropertyValueByName('boolean', Value), 'Boolean property was not found.');
        Assert.IsTrue(Value.IsBoolean(), 'Boolean JSON value was not returned as AL Boolean.');
        BooleanValue := Value;
        Assert.IsTrue(BooleanValue, 'Boolean variant value is incorrect.');

        // [THEN] Native object and array values are carried directly by Variant
        Assert.IsTrue(Json.GetPropertyValueByName('object', Value), 'Object property was not found.');
        Assert.IsTrue(Value.IsJsonObject(), 'Object JSON value was not returned as a native JsonObject.');
        ObjectValue := Value;
        ObjectValue.WriteTo(TextValue);
        Assert.AreEqual('{"id":1}', TextValue, 'Object variant value is incorrect.');

        Assert.IsTrue(Json.GetPropertyValueByName('array', Value), 'Array property was not found.');
        Assert.IsTrue(Value.IsJsonArray(), 'Array JSON value was not returned as a native JsonArray.');
        ArrayValue := Value;
        ArrayValue.WriteTo(TextValue);
        Assert.AreEqual('[1,2]', TextValue, 'Array variant value is incorrect.');
    end;

    [Test]
    procedure TestNullAndMissingProperties()
    var
        Json: Codeunit "Json";
        Value: Variant;
        TextValue: Text;
        IntegerValue: Integer;
    begin
        // [GIVEN] An object containing a JSON null
        Json.InitializeObject('{"null":null}');

        // [WHEN] The null property is requested
        Value := 'not cleared';
        Assert.IsTrue(Json.GetPropertyValueByName('null', Value), 'An existing null property was reported as missing.');

        // [THEN] JSON null is represented by a cleared Variant
        Assert.AreEqual('', Format(Value), 'JSON null did not clear the Variant value.');
        Assert.IsFalse(Value.IsText(), 'JSON null was incorrectly returned as text.');

        // [WHEN] A missing property is requested
        Value := 'not cleared';

        // [THEN] The call returns false and still clears the output Variant
        Assert.IsFalse(Json.GetPropertyValueByName('missing', Value), 'A missing property was reported as present.');
        Assert.AreEqual('', Format(Value), 'A missing property did not clear the Variant value.');

        // [THEN] String null is empty, while a typed null is rejected
        TextValue := 'not cleared';
        Assert.IsTrue(Json.GetStringPropertyValueByName('null', TextValue), 'String getter did not recognize an existing null property.');
        Assert.AreEqual('', TextValue, 'String getter did not return an empty value for JSON null.');
        Assert.IsFalse(Json.GetIntegerPropertyValueFromJObjectByName('null', IntegerValue), 'Typed getter accepted JSON null.');
        Assert.IsFalse(Json.GetStringPropertyValueByName('missing', TextValue), 'String getter accepted a missing property.');
    end;

    [Test]
    procedure TestAddPropertyPreservesNativeScalarDispatch()
    var
        Json: Codeunit "Json";
        JsonArrayValue: JsonArray;
        JsonObjectValue: JsonObject;
        ExpectedDate: Date;
    begin
        // [GIVEN] An empty JSON object
        Json.InitializeObject('');
        ExpectedDate := DMY2Date(9, 9, 2026);
        JsonArrayValue.ReadFrom('[1,2]');
        JsonObjectValue.ReadFrom('{"id":1}');

        // [WHEN] Native JSON containers, scalar values, and another AL value are added
        Json.ReplaceOrAddJPropertyInJObject('object', JsonObjectValue);
        Json.ReplaceOrAddJPropertyInJObject('array', JsonArrayValue);
        Json.ReplaceOrAddJPropertyInJObject('integer', 7);
        Json.ReplaceOrAddJPropertyInJObject('decimal', 12.5);
        Json.ReplaceOrAddJPropertyInJObject('boolean', true);
        Json.ReplaceOrAddJPropertyInJObject('date', ExpectedDate);

        // [THEN] JSON containers and scalar types are preserved, and other AL values use format 9 text
        Assert.AreEqual('{"object":{"id":1},"array":[1,2],"integer":7,"decimal":12.5,"boolean":true,"date":"2026-09-09"}', Json.GetObjectAsText(), 'Property dispatch produced unexpected JSON types.');
    end;

    [Test]
    procedure TestReplaceOrAddReturnValue()
    var
        Json: Codeunit "Json";
    begin
        // [GIVEN] An object with existing scalar properties
        Json.InitializeObject('{"text":"same","integer":1}');

        // [THEN] Equal replacements return false
        Assert.IsFalse(Json.ReplaceOrAddJPropertyInJObject('text', 'same'), 'An equal text replacement was reported as changed.');
        Assert.IsFalse(Json.ReplaceOrAddJPropertyInJObject('integer', 1), 'An equal integer replacement was reported as changed.');

        // [THEN] Changed replacements and additions return true
        Assert.IsTrue(Json.ReplaceOrAddJPropertyInJObject('integer', 2), 'A changed replacement was not reported.');
        Assert.IsTrue(Json.ReplaceOrAddJPropertyInJObject('added', false), 'A new property was not reported.');
        Assert.AreEqual('{"text":"same","integer":2,"added":false}', Json.GetObjectAsText(), 'Replacement or addition produced unexpected JSON.');
    end;

    [Test]
    procedure TestGetValueAndSetToSupportedFieldTypes()
    var
        AccessControl: Record "Access Control";
        ObjectMetadata: Record Object;
        Profile: Record Profile;
        RecordLink: Record "Record Link";
        SourcePrinter: Record Printer;
        TableInformation: Record "Table Information";
        Json: Codeunit "Json";
        FieldsJsonObject: JsonObject;
        RootJsonObject: JsonObject;
        BlobInStream: InStream;
        RecordRef: RecordRef;
        ExpectedDate: Date;
        ExpectedGuid: Guid;
        ExpectedRecordId: RecordId;
        BlobText: Text;
        JsonText: Text;
        LongText: Text;
    begin
        // [GIVEN] JSON values for every documented field type available on existing records
        ExpectedDate := DMY2Date(9, 9, 2026);
        ExpectedGuid := CreateGuid();
        SourcePrinter.ID := 'JSON-RECORD-ID';
        ExpectedRecordId := SourcePrinter.RecordId();
        LongText := PadStr('', 300, 'X');

        FieldsJsonObject.Add('integer', 42);
        FieldsJsonObject.Add('decimal', 12.5);
        FieldsJsonObject.Add('date', ExpectedDate);
        FieldsJsonObject.Add('boolean', true);
        FieldsJsonObject.Add('guid', Format(ExpectedGuid));
        FieldsJsonObject.Add('text', LongText);
        FieldsJsonObject.Add('code', 'lowercase');
        FieldsJsonObject.Add('option', 1);
        FieldsJsonObject.Add('blob', 'SGVsbG8=');
        FieldsJsonObject.Add('recordId', Format(ExpectedRecordId));
        RootJsonObject.Add('fields', FieldsJsonObject);
        RootJsonObject.WriteTo(JsonText);
        Json.InitializeObject(JsonText);

        // [WHEN] Paths are assigned to Integer, Text, Boolean, Option, BLOB, and RecordID fields
        RecordRef.GetTable(RecordLink);
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.integer', RecordLink.FieldNo("Link ID")), 'Integer path was not assigned.');
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.text', RecordLink.FieldNo(Description)), 'Text path was not assigned.');
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.boolean', RecordLink.FieldNo(Notify)), 'Boolean path was not assigned.');
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.option', RecordLink.FieldNo(Type)), 'Option path was not assigned.');
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.blob', RecordLink.FieldNo(Note)), 'BLOB path was not assigned.');
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.recordId', RecordLink.FieldNo("Record ID")), 'RecordID path was not assigned.');
        RecordRef.SetTable(RecordLink);

        // [THEN] The fields contain converted values, including text truncation and decoded Base64
        Assert.AreEqual(42, RecordLink."Link ID", 'Integer field value is incorrect.');
        Assert.AreEqual(250, StrLen(RecordLink.Description), 'Text field value was not truncated to the field length.');
        Assert.IsTrue(RecordLink.Notify, 'Boolean field value is incorrect.');
        Assert.AreEqual(RecordLink.Type::Note, RecordLink.Type, 'Option field value is incorrect.');
        Assert.AreEqual(Format(ExpectedRecordId), Format(RecordLink."Record ID"), 'RecordID field value is incorrect.');
        RecordLink.Note.CreateInStream(BlobInStream);
        BlobInStream.ReadText(BlobText);
        Assert.AreEqual('Hello', BlobText, 'BLOB field value was not decoded from Base64.');

        // [WHEN] The remaining documented field types are assigned on existing platform records
        RecordRef.GetTable(TableInformation);
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.decimal', TableInformation.FieldNo("Record Size")), 'Decimal path was not assigned.');
        RecordRef.SetTable(TableInformation);

        RecordRef.GetTable(ObjectMetadata);
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.date', ObjectMetadata.FieldNo(Date)), 'Date path was not assigned.');
        RecordRef.SetTable(ObjectMetadata);

        RecordRef.GetTable(AccessControl);
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.guid', AccessControl.FieldNo("User Security ID")), 'GUID path was not assigned.');
        RecordRef.SetTable(AccessControl);

        RecordRef.GetTable(Profile);
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'fields.code', Profile.FieldNo("Profile ID")), 'Code path was not assigned.');
        RecordRef.SetTable(Profile);

        // [THEN] Decimal, Date, GUID, and Code conversions are correct
        Assert.AreEqual(12.5, TableInformation."Record Size", 'Decimal field value is incorrect.');
        Assert.AreEqual(ExpectedDate, ObjectMetadata.Date, 'Date field value is incorrect.');
        Assert.AreEqual(ExpectedGuid, AccessControl."User Security ID", 'GUID field value is incorrect.');
        Assert.AreEqual('LOWERCASE', Profile."Profile ID", 'Code field value is incorrect.');
    end;

    [Test]
    procedure TestGetValueAndSetToRecFieldNoHandlesNullAndMissingPaths()
    var
        Printer: Record Printer;
        Json: Codeunit "Json";
        RecordRef: RecordRef;
    begin
        // [GIVEN] A record value and an object with a null property
        Printer.ID := 'unchanged';
        RecordRef.GetTable(Printer);
        Json.InitializeObject('{"nested":{"null":null}}');

        // [THEN] Null and missing paths return false without changing the field
        Assert.IsFalse(Json.GetValueAndSetToRecFieldNo(RecordRef, 'nested.null', Printer.FieldNo(ID)), 'A null path was assigned to a field.');
        Assert.IsFalse(Json.GetValueAndSetToRecFieldNo(RecordRef, 'nested.missing', Printer.FieldNo(ID)), 'A missing path was assigned to a field.');
        RecordRef.SetTable(Printer);
        Assert.AreEqual('unchanged', Printer.ID, 'A null or missing path changed the target field.');
    end;

    [Test]
    procedure TestGetValueAndSetToRecFieldNoSelectsArrayPath()
    var
        Printer: Record Printer;
        Json: Codeunit "Json";
        RecordRef: RecordRef;
    begin
        // [GIVEN] A nested array path
        Json.InitializeObject('{"items":[{"name":"selected"}]}');
        RecordRef.GetTable(Printer);

        // [WHEN] The array item path is assigned
        Assert.IsTrue(Json.GetValueAndSetToRecFieldNo(RecordRef, 'items[0].name', Printer.FieldNo(Name)), 'Array path was not selected.');
        RecordRef.SetTable(Printer);

        // [THEN] The selected value is assigned
        Assert.AreEqual('selected', Printer.Name, 'Array path selected an unexpected value.');
    end;

    [Test]
    procedure TestGetCollectionAsTextIndentedGoldenOutput()
    var
        Json: Codeunit "Json";
        CRLF: Text[2];
        ExpectedText: Text;
    begin
        // [GIVEN] Nested JSON with empty containers and escaped property/value text
        Json.InitializeCollection('[{"quoted\"key":"quote\" slash\\ line\r\n","nested":{"emptyObject":{},"emptyArray":[],"values":[1,true,null]}}]');
        CRLF[1] := 13;
        CRLF[2] := 10;
        ExpectedText :=
            '[' + CRLF +
            '  {' + CRLF +
            '    "quoted\"key": "quote\" slash\\ line\r\n",' + CRLF +
            '    "nested": {' + CRLF +
            '      "emptyObject": {},' + CRLF +
            '      "emptyArray": [],' + CRLF +
            '      "values": [' + CRLF +
            '        1,' + CRLF +
            '        true,' + CRLF +
            '        null' + CRLF +
            '      ]' + CRLF +
            '    }' + CRLF +
            '  }' + CRLF +
            ']';

        // [WHEN] The collection is formatted with indentation
        // [THEN] Output exactly matches JsonConvert-compatible indentation and CRLF placement
        Assert.AreEqual(ExpectedText, Json.GetCollectionAsText(true), 'Indented JSON output does not match the expected golden text.');
    end;
}
