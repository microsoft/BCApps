// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Json;

using System.Json;
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
        Success := Json.GetObjectFromCollectionByIndex(ActualJObjectText, 1); // Index is zero-based
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
        Success := Json.GetObjectFromCollectionByIndex(ActualJObjectText, 0);
        ActualJObject.ReadFrom(ActualJObjectText);
        ActualJObject.WriteTo(ActualJObjectText);

        // [THEN] The retrieved object matches the expected object
        Assert.IsTrue(Success, 'Failed to retrieve object by index.');
        Assert.AreEqual(ExpectedJObjectText, ActualJObjectText, 'The retrieved object does not match the expected object.');
    end;

    [Test]
    procedure TestGetValueAndSetToRecFieldNo()
    var
        Json: Codeunit "Json";
        Printer: Record Printer;
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
}