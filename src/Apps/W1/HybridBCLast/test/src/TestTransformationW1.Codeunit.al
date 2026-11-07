codeunit 139666 "Test Transformation W1"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryHybridBCLast: Codeunit "Library - Hybrid BC Last";
        CountryCodeTxt: Label 'W1', Locked = true;
        ProductIdTxt: Label 'DynamicsBCLast', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FrenchScheduleMappingsRespectCountryAndInstalledApp()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        TableMappings: Record "Table Mappings";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] French schedule mappings exist only in FR with Reports FR installed and remain idempotent.
        Initialize();

        // [GIVEN] The supported previous-release cloud migration product is selected.
        IntelligentCloudSetup.Get();
        IntelligentCloudSetup."Product ID" := ProductIdTxt;
        IntelligentCloudSetup.Modify(false);

        // [WHEN] Default mappings are restored and then added again without deletion.
        HybridCloudManagement.RestoreDefaultMigrationTableMappings(true);
        HybridCloudManagement.RestoreDefaultMigrationTableMappings(false);

        // [THEN] The native environment has exactly its appropriate FR mappings and release boundaries.
        TableMappings.SetRange("To APP ID", '{6f93dbc5-c674-430e-b5f4-232449d55c20}');
        Assert.AreEqual(ExpectedFrenchMappingCount(), TableMappings.Count(), 'Country and installed-app boundaries must be respected without duplicate mappings.');
        VerifyFrenchMapping(TableMappings);
    end;

    [Test]
    procedure VerifyMappedTablesStaged()
    var
        SourceTableMapping: Record "Source Table Mapping";
    begin
        // [SCENARIO] W1 extension maps tables that need to be staged
        LibraryHybridBCLast.InitializeMapping(14.5);

        // [WHEN] The extension is installed
        // [THEN] The Source Table Mapping table is populated with staged tables
        SourceTableMapping.SetRange("Country Code", CountryCodeTxt);
        SourceTableMapping.SetRange(Staged, true);
        Assert.AreEqual(0, SourceTableMapping.Count(), 'Unexpected number of mapped, staged tables.');
    end;

    [Test]
    procedure VerifyMappedTablesUnstaged()
    var
        SourceTableMapping: Record "Source Table Mapping";
    begin
        // [SCENARIO] W1 extension maps tables that are not staged
        LibraryHybridBCLast.InitializeMapping(14.5);

        // [WHEN] The extension is installed
        // [THEN] The Source Table Mapping table is populated with the unstages tables
        SourceTableMapping.SetRange("Country Code", CountryCodeTxt);
        SourceTableMapping.SetRange(Staged, false);
        Assert.AreEqual(0, SourceTableMapping.Count(), 'Unexpected number of mapped, unstaged tables.');
    end;

    /// <summary>
    /// This test is meant to catch issues with the mapping code that populates the "Table Mappings" and "Table Field Mappings" tables wrt to obsoleted tables and fields.
    /// If fields are deleted from the schema, the code to populate the "Table Mappings" and "Table Field Mappings" tables will fail.
    /// If fields are osboleted (pending or removed), the tst will fail.
    /// In case the test fails, the mapping code needs CLEAN and CLEANSCHEMA preprocessor symbols. The test will have to manually exclude the fields that are 'handled' with preprocessor symbols.
    /// </summary>
    [Test]
    procedure VerifyMappedFieldsExist()
    var
        TableMappings: Record "Table Mappings";
        TableFieldMappings: Record "Table Field Mappings";
        Field: Record Field;
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        MissingTablesAndFields: List of [Text];
        MissingName: Text;
        MissingNames: TextBuilder;
    begin
        // [SCENARIO] All mapped tables and fields exist]
        // [WHEN] The mapping tables are initialized
        LibraryHybridBCLast.InitializeMapping(14.5);
        IntelligentCloudSetup.Get();
        IntelligentCloudSetup."Product ID" := ProductIdTxt;
        IntelligentCloudSetup.Modify();
        HybridCloudManagement.RestoreDefaultMigrationTableMappings(true);


        // [THEN] it only contains tables and fields that exist in the database
        assert.RecordIsNotEmpty(TableMappings, 'Table Mappings should not be empty.');
        assert.RecordIsNotEmpty(TableFieldMappings, 'Table Field Mappings should not be empty.');

        TableMappings.FindSet();
        repeat
            Field.SetRange(TableName, TableMappings."From Table Name");
            Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
            if IsFrenchScheduleSourceMapping(TableMappings) then begin
#if not CLEANSCHEMA33
                // These retained Pending tables are deliberately readable during the first-release copy window.
                Field.SetFilter(ObsoleteState, '%1|%2', Field.ObsoleteState::No, Field.ObsoleteState::Pending);
                if Field.IsEmpty() then
                    MissingTablesAndFields.Add(TableMappings."From Table Name");
#endif
            end else
                if Field.IsEmpty() then
                    MissingTablesAndFields.Add(TableMappings."From Table Name");

            Field.SetRange(TableName, TableMappings."To Table Name");
            Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
            if Field.Isempty() then
                MissingTablesAndFields.Add(TableMappings."To Table Name");
        until TableMappings.Next() = 0;

        TableFieldMappings.FindSet();
        repeat
            Field.SetRange(TableName, TableFieldMappings."From Table Name");
            Field.SetRange(FieldName, TableFieldMappings."From Table Field Name");
            Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
            if Field.IsEmpty then
                MissingTablesAndFields.Add(TableFieldMappings."From Table Name" + '' + TableFieldMappings."From Table Field Name");

            Field.SetRange(TableName, TableFieldMappings."To Table Name");
            Field.SetRange(FieldName, TableFieldMappings."To Table Field Name");
            Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
            if Field.IsEmpty then
                MissingTablesAndFields.Add(TableFieldMappings."To Table Name" + '' + TableFieldMappings."To Table Field Name");
        until TableFieldMappings.Next() = 0;

        // Assert that there are no missing tables or fields
        if MissingTablesAndFields.Count() > 0 then begin
            // if/when we have moved and obsoleted fields, this assert will need to be updated. see comment above
            foreach MissingName in MissingTablesAndFields do
                MissingNames.AppendLine(MissingName);
            error('Missing tables and/or fields: %1', MissingNames.ToText());
        end;
    end;

    local procedure Initialize()
    begin
        LibraryHybridBCLast.InitializeMapping(29.1);
    end;

    local procedure IsFrenchScheduleSourceMapping(TableMappings: Record "Table Mappings"): Boolean
    begin
        exit(
            (TableMappings."From APP ID" = '{437dbf0e-84ff-417a-965d-ed2bb9650972}') and
            (TableMappings."To APP ID" = '{6f93dbc5-c674-430e-b5f4-232449d55c20}') and
            (TableMappings."From Table ID" in [10800, 10801]));
    end;

    local procedure ExpectedFrenchMappingCount(): Integer
    var
        InstalledApp: Record "NAV App Installed App";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.GetApplicationFamily() <> 'FR' then
            exit(0);
        if InstalledApp.Get('{6f93dbc5-c674-430e-b5f4-232449d55c20}') then
            exit(2);
        exit(0);
    end;

    local procedure VerifyFrenchMapping(var TableMappings: Record "Table Mappings")
    begin
        if not TableMappings.FindSet() then
            exit;
        repeat
            Assert.AreEqual('{437DBF0E-84FF-417A-965D-ED2BB9650972}', UpperCase(Format(TableMappings."From APP ID")), 'The source app must remain Base Application.');
            Assert.AreEqual(29, TableMappings."Applies From BC Major Release", 'The mapping starts at the supported release.');
            Assert.AreEqual(1, TableMappings."Applies From BC Minor Release", 'The mapping starts at 29.1.');
            Assert.IsTrue(TableMappings."Per Company", 'Financial schedule definitions are per-company.');
            case TableMappings."From Table ID" of
                10800:
                    Assert.AreEqual(10826, TableMappings."To Table ID", 'The header maps to its planned replacement identity.');
                10801:
                    Assert.AreEqual(10827, TableMappings."To Table ID", 'The line maps to its planned replacement identity.');
                else
                    Assert.Fail('Only the two scoped legacy tables may map to Reports FR.');
            end;
        until TableMappings.Next() = 0;
    end;
}