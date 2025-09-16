// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps.ExtensionGeneration;

using System.Reflection;
using System.TestLibraries.Utilities;
using System.Apps.ExtensionGeneration;
using System.TestLibraries.Apps.ExtensionGeneration;

codeunit 133103 "Dataverse Table Builder Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        DataverseTableBuilder: Codeunit "Dataverse Table Builder";
        DVTableBuilderTestLibrary: Codeunit "DV Table Builder Test Library";

    [Test]
    procedure TestGenerateTableExtension()
    var
        Field: Record Field;
        Schema: Text;
        FieldName: Text;
        Fields: Dictionary of [Text, Text];
    begin
        // [GIVEN] A schema and fields to generate a table extension.
        Initialize();
        Schema := DVTableBuilderTestLibrary.GetMockProxyTableSchema();
        Fields := DVTableBuilderTestLibrary.GetMockProxyTableFields();

        // [WHEN] Table generation is started, the table is updated with the fields and the generation is committed.
        DataverseTableBuilder.StartGeneration(false);
        DataverseTableBuilder.UpdateExistingTable(Database::"Mock Proxy", Fields.Values(), Schema);
        DataverseTableBuilder.CommitGeneration();

        // [THEN] The table extension is generated with the fields.
        Field.SetRange(TableNo, Database::"Mock Proxy");
        foreach FieldName in Fields.Keys do begin
            Field.SetRange(FieldName, FieldName);
            Field.FindFirst();
            Assert.AreEqual(Fields.Get(FieldName), Field.ExternalName, 'Field is not generated correctly');
        end;
    end;

    [Test]
    procedure TestCommitGenerationWithoutStarting()
    begin
        // [GIVEN] No generation is started.
        Initialize();

        // [WHEN] CommitGeneration is called without starting a generation.
        asserterror DataverseTableBuilder.CommitGeneration();

        // [THEN] An error is raised.
        Assert.ExpectedError('Generation has not been started. Start generation first.');
    end;

    [Test]
    procedure TestOverrideGeneration()
    var
        Field: Record Field;
        Schema: Text;
        FieldNames: List of [Text];
        Fields: Dictionary of [Text, Text];
    begin
        // [GIVEN] A generation is started.
        Initialize();
        Schema := DVTableBuilderTestLibrary.GetMockProxyTableSchema();
        Fields := DVTableBuilderTestLibrary.GetMockProxyTableFields();
        DataverseTableBuilder.StartGeneration(false);
        FieldNames.Add(Fields.Values().Get(1));
        DataverseTableBuilder.UpdateExistingTable(Database::"Mock Proxy", FieldNames, Schema);

        // [WHEN] A new generation is started with override = true
        DataverseTableBuilder.StartGeneration(true);
        Clear(FieldNames);
        FieldNames.Add(Fields.Values().Get(2));
        DataverseTableBuilder.UpdateExistingTable(Database::"Mock Proxy", FieldNames, Schema);

        // [THEN] The table extension is generated with only the fields from the second generation.
        DataverseTableBuilder.CommitGeneration();
        Field.SetRange(TableNo, Database::"Mock Proxy");
        Field.SetRange(FieldName, Fields.Keys().Get(1));
        Assert.RecordIsEmpty(Field);
        Field.SetRange(FieldName, Fields.Keys().Get(2));
        Field.FindFirst();
        Assert.AreEqual(Fields.Get(Fields.Keys().Get(2)), Field.ExternalName, 'Field is not generated correctly');
    end;

    local procedure Initialize()
    begin
        DataverseTableBuilder.ClearGeneration();
    end;
}