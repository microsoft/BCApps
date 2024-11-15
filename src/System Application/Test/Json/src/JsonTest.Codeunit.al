// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Text.Json;

using System.Text.Json;
using System.Device;
using System.TestLibraries.Utilities;

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
}
