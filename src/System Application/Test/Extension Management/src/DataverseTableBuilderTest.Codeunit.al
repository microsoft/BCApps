// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps.ExtensionGeneration;

using System.Apps;
using System.Apps.ExtensionGeneration;
using System.Reflection;
using System.TestLibraries.Apps.ExtensionGeneration;
using System.TestLibraries.Utilities;

codeunit 133103 "Dataverse Table Builder Test"
{
    Subtype = Test;
    TestType = UnitTest;

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
        Fields: List of [Text];
    begin
        // [GIVEN] A schema and fields to generate a table extension.
        Initialize();
        Schema := DVTableBuilderTestLibrary.GetMockProxyTableSchema();
        Fields := DVTableBuilderTestLibrary.GetMockProxyTableFields();

        // [WHEN] Table generation is started, the table is updated with the fields and the generation is committed.
        DataverseTableBuilder.StartGeneration(false);
        DataverseTableBuilder.UpdateExistingTable(Database::"Mock Proxy", Fields, Schema);
        DataverseTableBuilder.CommitGeneration();

        // [THEN] The table extension is generated with the fields.
        Field.SetRange(TableNo, Database::"Mock Proxy");
        foreach FieldName in Fields do begin
            Field.SetRange(FieldName, FieldName);
            Field.FindFirst();
            Assert.AreEqual(FieldName, Field.ExternalName, 'Field is not generated correctly');
        end;

        // Cleanup
        UninstallExtension();
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
        Fields: List of [Text];
    begin
        // [GIVEN] A generation is started.
        Initialize();
        Schema := DVTableBuilderTestLibrary.GetMockProxyTableSchema();
        Fields := DVTableBuilderTestLibrary.GetMockProxyTableFields();
        DataverseTableBuilder.StartGeneration(false);
        FieldNames.Add(Fields.Get(4));
        DataverseTableBuilder.UpdateExistingTable(Database::"Mock Proxy", FieldNames, Schema);

        // [WHEN] A new generation is started with override = true
        DataverseTableBuilder.StartGeneration(true);
        Clear(FieldNames);
        FieldNames.Add(Fields.Get(5));
        DataverseTableBuilder.UpdateExistingTable(Database::"Mock Proxy", FieldNames, Schema);

        // [THEN] The table extension is generated with only the fields from the second generation.
        DataverseTableBuilder.CommitGeneration();
        Field.SetRange(TableNo, Database::"Mock Proxy");
        Field.SetRange(FieldName, Fields.Get(4));
        Assert.RecordIsEmpty(Field);
        Field.SetRange(FieldName, Fields.Get(5));
        Field.FindFirst();
        Assert.AreEqual(Fields.Get(5), Field.ExternalName, 'Field is not generated correctly');

        // Cleanup
        UninstallExtension();
    end;

    local procedure Initialize()
    begin
        UninstallExtension();
        DataverseTableBuilder.ClearGeneration();
    end;

    local procedure UninstallExtension()
    var
        NavAppInstalledApp: Record "NAV App Installed App";
        ExtensionManagement: Codeunit "Extension Management";
    begin
        NavAppInstalledApp.SetRange(Name, 'CRM Sync Designer');
        NavAppInstalledApp.SetRange(Publisher, 'Designer');
        if NavAppInstalledApp.FindSet() then
            repeat
                ExtensionManagement.UninstallExtension(NavAppInstalledApp."Package ID", false);
            until NavAppInstalledApp.Next() = 0;
    end;
}