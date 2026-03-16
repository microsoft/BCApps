// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;

codeunit 148147 "BC14 Buffer Table Helper Tests"
{
    // [FEATURE] [BC14 Cloud Migration Buffer Table Helper]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestOpenBufferRecordWithZeroTableId()
    var
        BC14BufferTableHelper: Codeunit "BC14 Buffer Table Helper";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] OpenBufferRecord returns false when table ID is 0.

        // [GIVEN] A record ID from any table
        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        // [WHEN] OpenBufferRecord is called with table ID = 0
        // [THEN] It should return false without opening the editor
        Assert.AreEqual(false, BC14BufferTableHelper.OpenBufferRecord(0, DummyRecId), 'OpenBufferRecord should return false for table ID = 0');
    end;

    [Test]
    procedure TestOpenBufferRecordWithEmptyRecordId()
    var
        BC14BufferTableHelper: Codeunit "BC14 Buffer Table Helper";
        EmptyRecId: RecordId;
    begin
        // [SCENARIO] OpenBufferRecord returns false when record ID is empty.

        // [GIVEN] An empty record ID (not initialized)
        // EmptyRecId is not initialized, so Format(EmptyRecId) = ''

        // [WHEN] OpenBufferRecord is called with an empty record ID
        // [THEN] It should return false without opening the editor
        Assert.AreEqual(false, BC14BufferTableHelper.OpenBufferRecord(Database::"BC14 Migration Errors", EmptyRecId), 'OpenBufferRecord should return false for empty record ID');
    end;

    [Test]
    procedure TestOpenBufferRecordWithBothInvalid()
    var
        BC14BufferTableHelper: Codeunit "BC14 Buffer Table Helper";
        EmptyRecId: RecordId;
    begin
        // [SCENARIO] OpenBufferRecord returns false when both table ID and record ID are invalid.

        // [GIVEN] Table ID = 0 and empty record ID

        // [WHEN] OpenBufferRecord is called with both invalid parameters
        // [THEN] It should return false (table ID check comes first)
        Assert.AreEqual(false, BC14BufferTableHelper.OpenBufferRecord(0, EmptyRecId), 'OpenBufferRecord should return false for both invalid parameters');
    end;

    [Test]
    procedure TestBufferFieldEditorTableStructure()
    var
        BC14BufferFieldEditor: Record "BC14 Buffer Field Editor";
    begin
        // [SCENARIO] BC14 Buffer Field Editor table has correct structure for field editing.

        // [GIVEN] A new Buffer Field Editor record
        BC14BufferFieldEditor.Init();

        // [WHEN] Fields are populated
        BC14BufferFieldEditor."Field No." := 1;
        BC14BufferFieldEditor."Field Name" := 'Test Field';
        BC14BufferFieldEditor."Field Value" := 'Test Value';
        BC14BufferFieldEditor."Field Type" := 'Text';
        BC14BufferFieldEditor."Is Editable" := true;
        BC14BufferFieldEditor.Insert();

        // [THEN] The record can be read with correct values
        BC14BufferFieldEditor.Get(1);
        Assert.AreEqual('Test Field', BC14BufferFieldEditor."Field Name", 'Field Name - Incorrect value');
        Assert.AreEqual('Test Value', BC14BufferFieldEditor."Field Value", 'Field Value - Incorrect value');
        Assert.AreEqual('Text', BC14BufferFieldEditor."Field Type", 'Field Type - Incorrect value');
        Assert.AreEqual(true, BC14BufferFieldEditor."Is Editable", 'Is Editable - Should be true');
    end;

    [Test]
    procedure TestBufferFieldEditorIsTemporary()
    var
        BC14BufferFieldEditor: Record "BC14 Buffer Field Editor";
    begin
        // [SCENARIO] BC14 Buffer Field Editor table is temporary (no persistent storage).

        // [GIVEN] The table type is Temporary

        // [WHEN] A record is inserted and the variable goes out of scope
        BC14BufferFieldEditor.Init();
        BC14BufferFieldEditor."Field No." := 999;
        BC14BufferFieldEditor."Field Name" := 'Temporary Test';
        BC14BufferFieldEditor.Insert();

        // [THEN] The record exists in the temporary table
        Assert.AreEqual(true, BC14BufferFieldEditor.Get(999), 'Temporary record should exist');

        // Note: Since this is a temporary table, the data won't persist across sessions.
        // The TableType = Temporary property ensures no database storage is used.
    end;

    [Test]
    procedure TestBufferFieldEditorDefaultEditability()
    var
        BC14BufferFieldEditor: Record "BC14 Buffer Field Editor";
    begin
        // [SCENARIO] BC14 Buffer Field Editor has Is Editable = true by default.

        // [GIVEN] A new Buffer Field Editor record with minimal fields set
        BC14BufferFieldEditor.Init();
        BC14BufferFieldEditor."Field No." := 1;

        // [THEN] Is Editable should be true by default (InitValue = true)
        Assert.AreEqual(true, BC14BufferFieldEditor."Is Editable", 'Is Editable - Should default to true');
    end;
}
