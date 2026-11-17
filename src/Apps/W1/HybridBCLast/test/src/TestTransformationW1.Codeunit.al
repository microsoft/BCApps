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
        BaseAppAppIdLbl: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        DepreciationDifferencesFIAppIdLbl: Label 'ecb1100e-3081-4c6a-9554-de33c687bf5f', Locked = true;

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
            if Field.Isempty() and
               not (IsDepreciationDifferencesFIMapping(TableMappings."To APP ID") and
                    (TableMappings."From Table Name" = 'Depr. Diff. Posting Buffer'))
            then
                MissingTablesAndFields.Add(TableMappings."From Table Name");

            Field.SetRange(TableName, TableMappings."To Table Name");
            if Field.Isempty() then
                MissingTablesAndFields.Add(TableMappings."To Table Name");
        until TableMappings.Next() = 0;

        TableFieldMappings.FindSet();
        repeat
            Field.SetRange(TableName, TableFieldMappings."From Table Name");
            Field.SetRange(FieldName, TableFieldMappings."From Table Field Name");
            Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
            if Field.IsEmpty
               and not IsExpectedDepreciationDifferencesFISourceField(TableFieldMappings)
#if not CLEANSCHEMA33
               and not IsExpectedObsoleteFieldMapping(TableFieldMappings."From Table Name", TableFieldMappings."From Table Field Name")
#endif
            then
                MissingTablesAndFields.Add(TableFieldMappings."From Table Name" + '' + TableFieldMappings."From Table Field Name");

            Field.SetRange(TableName, TableFieldMappings."To Table Name");
            Field.SetRange(FieldName, TableFieldMappings."To Table Field Name");
            Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
            if Field.IsEmpty
#if not CLEANSCHEMA33
               and not IsExpectedObsoleteFieldMapping(TableFieldMappings."To Table Name", TableFieldMappings."To Table Field Name")
#endif
            then
                MissingTablesAndFields.Add(TableFieldMappings."To Table Name" + '' + TableFieldMappings."To Table Field Name");
        until TableFieldMappings.Next() = 0;

        // Assert that there are no missing tables or fields
        if MissingTablesAndFields.Count() > 0 then
            // if/when we have moved and obsoleted fields, this assert will need to be updated. see comment above
            error('Missing tables and/or fields: %1', MissingTablesAndFields)
    end;

    [Test]
    procedure VerifyDepreciationDifferencesFIMappings()
    var
        InstalledApp: Record "NAV App Installed App";
        TableMappings: Record "Table Mappings";
        TableFieldMappings: Record "Table Field Mappings";
        EnvironmentInformation: Codeunit "Environment Information";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        BaseAppAppId: Guid;
        DepreciationDifferencesFIAppId: Guid;
    begin
        // [SCENARIO] FI delocalization mappings target the installed app and survive repeated initialization.
        LibraryHybridBCLast.InitializeMapping(29.0);
        LibraryHybridBCLast.InitializeWebhookSubscription();
        HybridCloudManagement.RestoreDefaultMigrationTableMappings(true);

        BaseAppAppId := BaseAppAppIdLbl;
        DepreciationDifferencesFIAppId := DepreciationDifferencesFIAppIdLbl;
        TableMappings.SetRange("To APP ID", DepreciationDifferencesFIAppId);
        TableFieldMappings.SetRange("To APP ID", DepreciationDifferencesFIAppId);
        if (EnvironmentInformation.GetApplicationFamily() <> 'FI') or not InstalledApp.Get(DepreciationDifferencesFIAppId) then begin
            Assert.RecordIsEmpty(TableMappings, 'FI table mappings require the FI app to be installed in an FI environment.');
            Assert.RecordIsEmpty(TableFieldMappings, 'FI field mappings require the FI app to be installed in an FI environment.');
            exit;
        end;

        Assert.AreEqual(1, TableMappings.Count(), 'Expected one FI posting buffer mapping.');
        TableMappings.FindFirst();
        Assert.AreEqual(BaseAppAppId, TableMappings."From APP ID", 'Unexpected source app.');
        Assert.AreEqual('Base Application', TableMappings."From App Name", 'Unexpected source app name.');
        Assert.AreEqual(13401, TableMappings."From Table ID", 'Unexpected source posting buffer.');
        Assert.AreEqual('Depr. Diff. Posting Buffer', TableMappings."From Table Name", 'Unexpected source table name.');
        Assert.AreEqual('Depr_ Diff_ Posting Buffer', TableMappings."From Table SQL Name", 'Unexpected source SQL table name.');
        Assert.IsFalse(TableMappings."From Is Extension Table", 'The source posting buffer is not an extension table.');
        Assert.AreEqual('', TableMappings."From Base Table Name", 'The source posting buffer has no base table.');
        Assert.AreEqual('Depreciation Differences FI', TableMappings."To App Name", 'Unexpected destination app name.');
        Assert.AreEqual(13477, TableMappings."To Table ID", 'Unexpected destination posting buffer.');
        Assert.AreEqual('Depr. Diff. Posting Buffer FI', TableMappings."To Table Name", 'Unexpected destination table name.');
        Assert.AreEqual('Depr_ Diff_ Posting Buffer FI', TableMappings."To Table SQL Name", 'Unexpected destination SQL table name.');
        Assert.IsFalse(TableMappings."To Is Extension Table", 'The destination posting buffer is not an extension table.');
        Assert.AreEqual('', TableMappings."To Base Table Name", 'The destination posting buffer has no base table.');
        Assert.AreEqual(30, TableMappings."Applies From BC Major Release", 'Unexpected mapping major version.');
        Assert.AreEqual(0, TableMappings."Applies From BC Minor Release", 'Unexpected mapping minor version.');
        Assert.IsTrue(TableMappings."Per Company", 'Posting buffer data is company-specific.');

        Assert.AreEqual(4, TableFieldMappings.Count(), 'Expected four FI field mappings.');
        VerifyDepreciationDifferencesFIFieldMapping('FA Posting Group', 'Depr. Difference Acc.', 'Deprec. Difference Account', false);
        VerifyDepreciationDifferencesFIFieldMapping('FA Posting Group', 'Depr. Difference Bal. Acc.', 'Deprec. Difference Bal Acct', false);
        VerifyDepreciationDifferencesFIFieldMapping('FA Ledger Entry', 'Depr. Difference Posted', 'Depreciation Difference Posted', false);
        VerifyDepreciationDifferencesFIFieldMapping('Source Code Setup', 'Depr. Difference', 'Depreciation Difference Code', true);

        HybridCloudManagement.RestoreDefaultMigrationTableMappings(false);
        Assert.AreEqual(1, TableMappings.Count(), 'Repeated initialization must not duplicate FI table mappings.');
        Assert.AreEqual(4, TableFieldMappings.Count(), 'Repeated initialization must not duplicate FI field mappings.');

#if not CLEANSCHEMA33
        TableFieldMappings.Reset();
        TableFieldMappings.SetRange("To APP ID", BaseAppAppId);
        TableFieldMappings.SetRange("To Table Name", 'Source Code Setup');
        TableFieldMappings.SetRange("To Table Field Name", 'Depr. Difference');
        TableFieldMappings.SetRange("Applies From BC Major Release", 25);
        Assert.AreEqual(1, TableFieldMappings.Count(), 'The earlier FI audit code mapping must be preserved.');
#endif
    end;

    local procedure VerifyDepreciationDifferencesFIFieldMapping(TableName: Text; FromFieldName: Text; ToFieldName: Text; FromIsExtensionTable: Boolean)
    var
        TableFieldMappings: Record "Table Field Mappings";
        BaseAppAppId: Guid;
        DepreciationDifferencesFIAppId: Guid;
    begin
        BaseAppAppId := BaseAppAppIdLbl;
        DepreciationDifferencesFIAppId := DepreciationDifferencesFIAppIdLbl;
        TableFieldMappings.SetRange("To APP ID", DepreciationDifferencesFIAppId);
        TableFieldMappings.SetRange("From Table Name", TableName);
        TableFieldMappings.SetRange("From Table Field Name", FromFieldName);
        Assert.AreEqual(1, TableFieldMappings.Count(), 'Expected one mapping for each moved FI field.');
        TableFieldMappings.FindFirst();
        Assert.AreEqual(BaseAppAppId, TableFieldMappings."From APP ID", 'Unexpected source app.');
        Assert.AreEqual('Base Application', TableFieldMappings."From App Name", 'Unexpected source app name.');
        Assert.AreEqual(FromIsExtensionTable, TableFieldMappings."From Is Extension Table", 'Unexpected source storage type.');
        if FromIsExtensionTable then
            Assert.AreEqual(TableName, TableFieldMappings."From Base Table Name", 'Unexpected source base table.')
        else
            Assert.AreEqual('', TableFieldMappings."From Base Table Name", 'A source base-app table has no base table name.');
        Assert.AreEqual('Depreciation Differences FI', TableFieldMappings."To App Name", 'Unexpected destination app name.');
        Assert.AreEqual(TableName, TableFieldMappings."To Table Name", 'Unexpected destination table.');
        Assert.AreEqual(ToFieldName, TableFieldMappings."To Table Field Name", 'Unexpected destination field.');
        Assert.IsTrue(TableFieldMappings."To Is Extension Table", 'Moved fields belong to the FI table extensions.');
        Assert.AreEqual(TableName, TableFieldMappings."To Base Table Name", 'Unexpected destination base table.');
        Assert.AreEqual(30, TableFieldMappings."Applies From BC Major Release", 'Unexpected mapping major version.');
        Assert.AreEqual(0, TableFieldMappings."Applies From BC Minor Release", 'Unexpected mapping minor version.');
        Assert.IsTrue(TableFieldMappings."Per Company", 'Moved FI fields are company-specific.');
    end;

    local procedure IsDepreciationDifferencesFIMapping(AppId: Guid): Boolean
    var
        DepreciationDifferencesFIAppId: Guid;
    begin
        DepreciationDifferencesFIAppId := DepreciationDifferencesFIAppIdLbl;
        exit(AppId = DepreciationDifferencesFIAppId);
    end;

    local procedure IsExpectedDepreciationDifferencesFISourceField(TableFieldMappings: Record "Table Field Mappings"): Boolean
    begin
        if not IsDepreciationDifferencesFIMapping(TableFieldMappings."To APP ID") then
            exit(false);

        case TableFieldMappings."From Table Name" of
            'FA Posting Group':
                exit(TableFieldMappings."From Table Field Name" in ['Depr. Difference Acc.', 'Depr. Difference Bal. Acc.']);
            'FA Ledger Entry':
                exit(TableFieldMappings."From Table Field Name" = 'Depr. Difference Posted');
            'Source Code Setup':
                exit(TableFieldMappings."From Table Field Name" = 'Depr. Difference');
        end;
    end;

#if not CLEANSCHEMA33
    local procedure IsExpectedObsoleteFieldMapping(TableName: Text; FieldName: Text): Boolean
    var
        Field: Record Field;
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.GetApplicationFamily() = 'FI' then begin
            Field.Get(Database::"Source Code Setup", 13400);
            exit((TableName = Field.TableName) and (FieldName = Field.FieldName));
        end;
    end;
#endif
}