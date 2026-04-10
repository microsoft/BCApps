codeunit 136610 "ERM RS Package Base Operations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Config Package] [Rapid Start]
        isInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        RelatedTableDataError: Label 'TableData Must Be Empty = %1 in %2 table.';
        TableCannotBeRenamed: Label 'You cannot rename the configuration package table.';
        TableIsNotAddedToPackage: Label 'Table is not added to package.';
        ReportGetTablesOneRecord: Label 'One record should be created.';
        SingleEntryRecNo: Integer;
        ReportGetTablesExpectedTable: Label 'Expected Table Error.';
        MustBeNoPackageErrors: Label 'Must Be No Package Errors in %1 table.';
        ConfigPackageTableAlreadyExists: Label 'already exists.';
        Fields_WrongIncludeField: Label 'Wrong Include Field count.';
        Fields_WrongValidateField: Label 'Wrong Validate Field value.';
        Fields_WrongProcessingOrderErr: Label 'Processing Order for field %1 must be %2.';
        Fields_WrongFieldName: Label 'Wrong Field Name.';
        Fields_WrongRelationTableNo: Label 'Wrong Relation Table No.';
        Fields_WrongDimensionField: Label 'Incorrect field value.';
        TableMustNotBeAddedErr: Label 'Table %1 Must not be added to the package.';
        FieldTok: Label 'FieldName';
        TableTok: Label 'TableName';
        CannotBeFoundInRelatedTableErr: Label 'cannot be found in the related table (Config. Package Table)';
        NameTok: Label '1 <>,./\+-&()%:=? A  B''`[]!_';
        CannotAddParentErr: Label 'Cannot add a parent table. This table is already included in a three-level hierarchy, which is the maximum.';
        CannotBeItsOwnParentErr: Label 'Cannot add the parent table. A table cannot be its own parent or child.';
        CircularDependencyErr: Label 'Cannot add the parent table. The table is already the child of the selected tab.';
        ParentTableNotFoundErr: Label 'Cannot find table %1.';

    [Test]
    [Scope('OnPrem')]
    procedure DeletePackage()
    var
        ConfigPackage: Record "Config. Package";
        PackageCode: Code[20];
    begin
        // [SCENARIO] package clears related data when it is deleted.

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Related Tables
        CreatePackageDataPairWithPKRelation(ConfigPackage);

        // 3. Delete Package
        PackageCode := ConfigPackage.Code;
        ConfigPackage.Delete(true);

        // 4. Verify that related tables deleted.
        // package records, tables, data, filters, fields, errors
        VerifyRelatedRecordCount(PackageCode, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePackages_DeleteOneOfTheTwoPackages_OneDeletedAndOtherRemain()
    var
        ConfigPackage1: Record "Config. Package";
        ConfigPackage2: Record "Config. Package";
        PackageCode: Code[20];
    begin
        Initialize();

        CreatePackageDataPairWithPKRelation(ConfigPackage1);
        CreatePackageDataPairWithPKRelation(ConfigPackage2);

        PackageCode := ConfigPackage1.Code;
        ConfigPackage1.Delete(true);

        VerifyRelatedRecordCount(PackageCode, 0, true);
        VerifyRelatedRecordCount(ConfigPackage2.Code, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenamePackage()
    var
        ConfigPackage: Record "Config. Package";
    begin
        // [SCENARIO] package renamed related data when it is renamed

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Related Tables
        CreatePackageDataPairWithPKRelation(ConfigPackage);

        // 3. Rename Package
        ConfigPackage.Rename(LibraryUtility.GenerateRandomCode(ConfigPackage.FieldNo(Code), DATABASE::"Config. Package"));

        // 4. Verify that related tables renamed for:
        // package records, tables, data, filters, fields, errors
        VerifyRelatedRecordCount(ConfigPackage.Code, 0, false);
    end;

    [Test]
    [HandlerFunctions('Report_GetTables_RequestPageRun_Handler,Report_GetTables_SelectedTables_SelectionHandler')]
    [Scope('OnPrem')]
    procedure Report_GetTables_SelectedTables()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO] it is possible to add tables listed in the config. worksheet using function "Get Tables"
        // [SCENARIO] for parameter: Selected tables

        // 1. Setup.
        Initialize();

        // 2. Generate WS Lines and Package
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', '', false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Vendor, '', '', false);

        LibraryRapidStart.CreatePackage(ConfigPackage);

        // 3. Get Package Table Customer from Worksheet
        GetTables_Report_Run(ConfigPackage.Code, false);

        // 4. Verify only one record with table Customer created (no waste records)
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageTable.Count = 1, ReportGetTablesOneRecord);
        ConfigPackageTable.FindFirst();
        Assert.IsTrue(ConfigPackageTable."Table ID" = DATABASE::Customer, ReportGetTablesExpectedTable);
    end;

    [HandlerFunctions('Report_GetTables_RequestPageRun_Handler,Report_GetTables_SelectedTables_SelectAllHandler')]
    [Scope('OnPrem')]
    procedure Report_GetTables_WithDataOnly()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO] it is possible to add tables listed in the config. worksheet using function "Get Tables"
        // [SCENARIO] for parameter: With Data Only

        // 1. Setup.
        Initialize();

        // 2. Generate WS Lines and Package
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', '', false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::"Line Number Buffer", '', '', false);

        LibraryRapidStart.CreatePackage(ConfigPackage);

        // 3. Get Package Table Customer from Worksheet
        GetTables_Report_Run(ConfigPackage.Code, true);

        // 4. Verify only one record with table Customer created (no waste records)
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageTable.Count = 1, ReportGetTablesOneRecord);
        ConfigPackageTable.FindFirst();
        Assert.IsTrue(ConfigPackageTable."Table ID" = DATABASE::Customer, ReportGetTablesExpectedTable);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddPackageTableNotInWorksheet()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigLine: Record "Config. Line";
    begin
        // [SCENARIO] it is possible to add tables which are not listed in the config. worksheet

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table Customer
        LibraryRapidStart.CreatePackage(ConfigPackage);
        ConfigLine.SetRange("Table ID", DATABASE::Customer);
        ConfigLine.SetFilter("Package Code", '%1|''''', ConfigPackage.Code);
        ConfigLine.DeleteAll();
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Customer);

        // 3. Verify that table customer added to package.
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetRange("Table ID", DATABASE::Customer);
        Assert.IsTrue(not ConfigPackageTable.IsEmpty, TableIsNotAddedToPackage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentTableIDRalatedToExistingTables()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: array[3] of Record "Config. Package Table";
    begin
        // [FEATURE] [Parent Table ID] [UT]
        // [SCENARIO] 'Parent Table ID' can not be negative value, non-existing table ID or a child of the same table

        // [GIVEN] Package with 3 tables
        CreatePackageOf3Tables(ConfigPackage, ConfigPackageTable);

        // [WHEN] Set 'Parent Table ID' to a negative value
        asserterror ConfigPackageTable[1].Validate("Parent Table ID", -1);
        // [THEN] Error message: 'Cannot be found in related table'
        Assert.ExpectedError(CannotBeFoundInRelatedTableErr);

        // [WHEN] Set 'Parent Table ID' to Table ID that doesn't exist
        asserterror ConfigPackageTable[3].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID" + 1);
        // [THEN] Error message: 'Cannot be found in related table'
        Assert.ExpectedError(CannotBeFoundInRelatedTableErr);

        // [WHEN] Set 'Parent Table ID' to 'Table ID'
        asserterror ConfigPackageTable[2].Validate("Parent Table ID", ConfigPackageTable[2]."Table ID");
        // [THEN] Error message:
        Assert.ExpectedError(CannotBeItsOwnParentErr);

        // [WHEN] Set 'Parent Table ID' to Table ID that does exist
        ConfigPackageTable[3].Validate("Parent Table ID", ConfigPackageTable[1]."Table ID");
        // [THEN] Validated succesfully
        ConfigPackageTable[3].TestField("Parent Table ID", ConfigPackageTable[1]."Table ID");
        ConfigPackageTable[3].Modify(true);

        // [WHEN] Circular dependency between 2 tables
        asserterror ConfigPackageTable[1].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID");
        Assert.ExpectedError(CircularDependencyErr);

        // [WHEN] Set 'Parent Table ID' to 0
        ConfigPackageTable[3].Validate("Parent Table ID", 0);
        // [THEN] Validated succesfully
        ConfigPackageTable[3].TestField("Parent Table ID", 0);

        // [WHEN] Wrong non-existing table is assigned as parent table
        ConfigPackageTable[3]."Parent Table ID" := 1;
        ConfigPackageTable[3].Modify(true);

        // [THEN] Validation will fail that table 1 doesn't exist
        asserterror ConfigPackageTable[2].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID");
        Assert.ExpectedError(StrSubstNo(ParentTableNotFoundErr, 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingMoreThan3ParentTables()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: array[8] of Record "Config. Package Table";
    begin
        // [FEATURE] [Parent Table ID] [UT]
        // [SCENARIO] Validating more than 3 level of parent tables

        // [GIVEN] Package with 4 tables
        CreatePackageOf8Tables(ConfigPackage, ConfigPackageTable);

        // [When] Validating table parents as following (child) 4-> 3-> 2 (parent)
        ConfigPackageTable[4].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID");
        ConfigPackageTable[4].Modify(true);
        ConfigPackageTable[3].Validate("Parent Table ID", ConfigPackageTable[2]."Table ID");
        ConfigPackageTable[3].Modify(true);

        // [THEN] Validating another parent table should fail (child) 4-> 3-> 2-> 1 (parent)
        asserterror ConfigPackageTable[2].Validate("Parent Table ID", ConfigPackageTable[1]."Table ID");
        Assert.ExpectedError(CannotAddParentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingMoreThan3childrenTables()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: array[8] of Record "Config. Package Table";
    begin
        // [FEATURE] [Parent Table ID] [UT]
        // [SCENARIO] Validating more than 3 level of children tables

        // [GIVEN] Package with 4 tables
        CreatePackageOf8Tables(ConfigPackage, ConfigPackageTable);

        // [When] Validating table parents as following (child) 3-> 2-> 1 (parent)
        ConfigPackageTable[2].Validate("Parent Table ID", ConfigPackageTable[1]."Table ID");
        ConfigPackageTable[2].Modify(true);
        ConfigPackageTable[3].Validate("Parent Table ID", ConfigPackageTable[2]."Table ID");
        ConfigPackageTable[3].Modify(true);

        // [THEN] Validating another child table should fail (child) 4-> 3-> 2-> 1 (parent)
        asserterror ConfigPackageTable[4].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID");
        Assert.ExpectedError(CannotAddParentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingTablewithParentAndChild()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: array[8] of Record "Config. Package Table";
    begin
        // [FEATURE] [Parent Table ID] [UT]
        // [SCENARIO] Validating that a table who has a parent and another who has a child can't have parent-child relation

        // [GIVEN] Package with 4 tables
        CreatePackageOf8Tables(ConfigPackage, ConfigPackageTable);
        // [WHEN] Config Table has following parents: (child) 4-> 3 (parent) and (child) 2-> 1 (parent)
        ConfigPackageTable[2].Validate("Parent Table ID", ConfigPackageTable[1]."Table ID");
        ConfigPackageTable[2].Modify(true);
        ConfigPackageTable[4].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID");
        ConfigPackageTable[4].Modify(true);

        // [THEN] Validating table 2 as parent to table 3 should fail (child) 4-> 3-> 2-> 1 (parent)
        asserterror ConfigPackageTable[3].Validate("Parent Table ID", ConfigPackageTable[2]."Table ID");
        Assert.ExpectedError(CannotAddParentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingTableWithMultiplechildren()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: array[8] of Record "Config. Package Table";
    begin
        // [FEATURE] [Parent Table ID] [UT]
        // [SCENARIO] Validating 3 level tables but with multiple children in each level
        // [GIVEN] Package with 8 tables
        CreatePackageOf8Tables(ConfigPackage, ConfigPackageTable);

        // [WHEN] Validating table parents as following (child) 2-> 1 and 3-> 1(parent)
        ConfigPackageTable[2].Validate("Parent Table ID", ConfigPackageTable[1]."Table ID");
        ConfigPackageTable[2].Modify(true);
        ConfigPackageTable[3].Validate("Parent Table ID", ConfigPackageTable[1]."Table ID");
        ConfigPackageTable[3].Modify(true);

        // [WHEN] Validating table parents as following (child) 5-> 4 and 6-> 4(parent)

        ConfigPackageTable[5].Validate("Parent Table ID", ConfigPackageTable[4]."Table ID");
        ConfigPackageTable[5].Modify(true);
        ConfigPackageTable[6].Validate("Parent Table ID", ConfigPackageTable[4]."Table ID");
        ConfigPackageTable[6].Modify(true);

        // [WHEN] Validating table parents as following (child) 4-> 1 (parent)
        ConfigPackageTable[4].Validate("Parent Table ID", ConfigPackageTable[1]."Table ID");
        ConfigPackageTable[4].Modify(true);

        // [WHEN] Validating table parents as following (child) 4-> 2, 5-> 2 and 6-> 2(parent)
        ConfigPackageTable[7].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID");
        ConfigPackageTable[7].Modify(true);
        ConfigPackageTable[8].Validate("Parent Table ID", ConfigPackageTable[3]."Table ID");
        ConfigPackageTable[8].Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePackageLine()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        TableID: Integer;
    begin
        // [SCENARIO] package's table can be deleted (with related tables)

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Related Tables
        CreatePackageDataPairWithPKRelation(ConfigPackage);

        // 3. Delete Package Table
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.FindFirst();
        TableID := ConfigPackageTable."Table ID";
        ConfigPackageTable.Delete(true);

        // 4. Verify that Package Table and related tables deleted:
        // package records, data, filters, fields, errors
        VerifyRelatedRecordCount(ConfigPackage.Code, TableID, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenamePackageLine()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO] package's table can be "renamed" - table id is changed

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table Customer
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);

        // 3. Rename Package Table
        asserterror ConfigPackageTable.Rename(ConfigPackage.Code, DATABASE::Vendor);

        // 4. Verify that table cannot be renamed in package
        Assert.ExpectedError(TableCannotBeRenamed);
    end;

    [Test]
    [HandlerFunctions('Report_CopyPackage_Handler')]
    [Scope('OnPrem')]
    procedure Report_CopyPackage()
    var
        ConfigPackage: Record "Config. Package";
        NewPackageCode: Code[20];
    begin
        // [SCENARIO] package can be copied without data to the new package

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Related Tables
        CreatePackageDataPairWithPKRelation(ConfigPackage);

        // 3. Run Copy Package report
        NewPackageCode := LibraryUtility.GenerateRandomCode(ConfigPackage.FieldNo(Code), DATABASE::"Config. Package");
        CopyPackage_Report_Run(ConfigPackage, NewPackageCode, false);

        // 4. Verify destination package created, tables created, table data and errors skipped
        VerifyCopyDataRelatedRecordCount(NewPackageCode, false);
    end;

    [Test]
    [HandlerFunctions('Report_CopyPackage_Handler')]
    [Scope('OnPrem')]
    procedure Report_CopyPackage_WithData()
    var
        ConfigPackage: Record "Config. Package";
        NewPackageCode: Code[20];
    begin
        // [SCENARIO] package can be copied with data to the new package

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Related Tables
        CreatePackageDataPairWithPKRelation(ConfigPackage);

        // 3. Run Copy Package report with data
        NewPackageCode := LibraryUtility.GenerateRandomCode(ConfigPackage.FieldNo(Code), DATABASE::"Config. Package");
        CopyPackage_Report_Run(ConfigPackage, NewPackageCode, true);

        // 4. Verify destination package created, tables and table data created, errors skipped
        VerifyCopyDataRelatedRecordCount(NewPackageCode, true);
    end;

    [Test]
    [HandlerFunctions('Report_CopyPackage_Handler')]
    [Scope('OnPrem')]
    procedure Report_CopyPackage_ToExistentPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        NewPackageCode: Code[20];
    begin
        // [SCENARIO] package cannot be copied to the existent package

        // 1. Setup.
        Initialize();

        // 2. Generate Destination Package and Package with Table Customer
        LibraryRapidStart.CreatePackage(ConfigPackage);
        NewPackageCode := ConfigPackage.Code;

        CreatePackageForTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);

        // 3. Run Copy Package report
        asserterror CopyPackage_Report_Run(ConfigPackage, NewPackageCode, false);

        // 4. Verify copying to existent package is forbidden
        Assert.ExpectedError(ConfigPackageTableAlreadyExists);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFields_IncludeField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        FieldCount: Integer;
    begin
        // [SCENARIO] Include Field is true for all fields

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table VAT Posting Setup
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, DATABASE::"VAT Posting Setup");

        // 3. Verify Include Field is true for all fields by default
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::"VAT Posting Setup");
        FieldCount := ConfigPackageField.Count();
        ConfigPackageField.SetRange("Include Field", true);

        Assert.AreEqual(FieldCount, ConfigPackageField.Count, Fields_WrongIncludeField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFields_ValidateField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
    begin
        // [SCENARIO] Validate Field is true for fields by default

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table Item
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, DATABASE::Item);

        // 3. Verify Validate Field is true for fields by default
        ConfigPackageField.Get(ConfigPackage.Code, DATABASE::Item, 3);
        Assert.AreEqual(true, ConfigPackageField."Validate Field", Fields_WrongValidateField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFields_ValidateField_Exception()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
    begin
        // [SCENARIO] Validate Field is false for fields with exception

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table VAT Posting Setup
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, DATABASE::"VAT Posting Setup");

        // 3. Verify Validate Field is false for fields with exception
        ConfigPackageField.Get(ConfigPackage.Code, DATABASE::"VAT Posting Setup", 4);
        Assert.AreEqual(false, ConfigPackageField."Validate Field", Fields_WrongValidateField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFields_ProcessingOrder()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ProcessingOrder: Integer;
    begin
        // [SCENARIO] Check default value of Processing Order, first numbering of key fields.

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table Item Vendor
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, DATABASE::"Item Vendor");

        // 3. Verification Processing Order value is sequential
        ProcessingOrder := 0;
        ConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::"Item Vendor");
        VerifyFieldProcessingOrder(ConfigPackageField, ProcessingOrder, true); // key fields numbered first
        VerifyFieldProcessingOrder(ConfigPackageField, ProcessingOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFields_FieldName()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        "Field": Record "Field";
        TableID: Integer;
    begin
        // [SCENARIO] Check default value of Field Name.

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table Customer
        TableID := DATABASE::Customer;
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, TableID);

        // 3. Verify Field Name is correct
        Field.SetRange(TableNo, TableID);
        Field.FindFirst();
        ConfigPackageField.Get(ConfigPackage.Code, TableID, Field."No.");

        Assert.AreEqual(Field.FieldName, ConfigPackageField."Field Name", Fields_WrongFieldName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFields_RelationTableID()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        "Field": Record "Field";
        Customer: Record Customer;
        TableID: Integer;
    begin
        // [SCENARIO] Check default value of Relation Table ID.

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table Customer
        TableID := DATABASE::Customer;
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, TableID);

        // 3. Verify Related Table ID is correct
        Field.SetRange(TableNo, TableID);
        Field.SetRange("No.", Customer.FieldNo("Territory Code"));
        Field.FindFirst();
        ConfigPackageField.Get(ConfigPackage.Code, TableID, Field."No.");

        Assert.AreEqual(Field.RelationTableNo, ConfigPackageField."Relation Table ID", Fields_WrongRelationTableNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFields_DimensionDefaultField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        TableID: Integer;
    begin
        // [SCENARIO] Check default value of Dimension field.

        // 1. Setup.
        Initialize();

        // 2. Generate Package With Table Customer
        TableID := DATABASE::Customer;
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, TableID);

        // 3. Verify Related Table ID is correct
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", TableID);
        ConfigPackageField.FindFirst();
        Assert.IsFalse(ConfigPackageField.Dimension, Fields_WrongDimensionField);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure VerifyFields_DimensionTrueField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        TableID: Integer;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Package table fields for dimensions are inserted if "Dimensions as Columns" set to 'Yes'.
        Initialize();

        // [GIVEN] Generate Package With Table Customer, where
        TableID := DATABASE::Customer;
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, TableID);
        // [WHEN] Set "Dimensions as Columns" to 'Yes'
        ConfigPackageTable.Validate("Dimensions as Columns", true);
        ConfigPackageTable.Modify();

        // [THEN] Inserted a Package field for table Customer, where "Dimension" is 'Yes'
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", TableID);
        ConfigPackageField.SetRange(Dimension, true);
        Assert.IsTrue(ConfigPackageField.FindFirst(), Fields_WrongDimensionField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetRelatedTablesSkipsSystemTable()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        TableID: Integer;
        RelatedTableID: Integer;
    begin
        // [SCENARIO 331856] 'Get Related Tables' skips system tables
        FindTableWithRelatedSystemTable(TableID, RelatedTableID);
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, TableID);

        ConfigPackageMgt.GetRelatedTables(ConfigPackageTable);

        ConfigPackageTable.SetRange("Table ID", RelatedTableID);
        Assert.IsTrue(ConfigPackageTable.IsEmpty, StrSubstNo(TableMustNotBeAddedErr, RelatedTableID));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateConfigLinePackageDataConfigLineMaximumIntLineNo()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        LineNo: Integer;
        ConfigPackageDataCode: Code[20];
        ShiftLineNo: BigInteger;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 371799] UpdateConfigLinePackageData processes Config. Line with Line No. of maximum int value
        Initialize();

        // [GIVEN] Config. Line with "Line No." = 2147483647 (maximum int value)
        LineNo := 2147483647;
        CreateSimpleConfigLine(ConfigLine, LineNo);

        // [GIVEN] Config. Package Data with Value = 5
        ShiftLineNo := LibraryRandom.RandIntInRange(1, 100);
        ConfigPackageDataCode :=
          LibraryUtility.GenerateRandomCode(ConfigPackageData.FieldNo("Package Code"), DATABASE::"Config. Package Data");
        CreateSimpleConfigPackageData(ConfigPackageData, ConfigPackageDataCode, ShiftLineNo, ConfigLine.FieldNo("Line No."));

        // [WHEN] Run UpdateConfigLinePackageData for Config. Package Data
        ConfigPackageManagement.UpdateConfigLinePackageData(ConfigPackageDataCode);

        // [THEN] Config. Package Data Value = 2147483647 + 5 + 10000
        ConfigPackageData.Find();
        Assert.AreEqual(Format(LineNo + ShiftLineNo + 10000L), ConfigPackageData.Value, ConfigPackageData.FieldCaption(Value));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateConfigLinePackageDataConfigPackageDataMaximumIntValue()
    var
        ConfigLine: Record "Config. Line";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        LineNo: Integer;
        ConfigPackageDataCode: Code[20];
        ShiftLineNo: BigInteger;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 371799] UpdateConfigLinePackageData processes Config. Package Data with Value of maximum int value
        Initialize();

        // [GIVEN] Config. Line with Line No = 50000
        LineNo := LibraryUtility.GetNewRecNo(ConfigLine, ConfigLine.FieldNo("Line No."));
        CreateSimpleConfigLine(ConfigLine, LineNo);

        // [GIVEN] Config Package Data with Value = 2147483647 (maximum int value)
        ShiftLineNo := 2147483647;
        ConfigPackageDataCode :=
          LibraryUtility.GenerateRandomCode(ConfigPackageData.FieldNo("Package Code"), DATABASE::"Config. Package Data");
        CreateSimpleConfigPackageData(ConfigPackageData, ConfigPackageDataCode, ShiftLineNo, ConfigLine.FieldNo("Line No."));

        // [WHEN] Run UpdateConfigLinePackageData for Config Package Data
        ConfigPackageManagement.UpdateConfigLinePackageData(ConfigPackageDataCode);

        // [THEN] Config. Package Data Value = 50000 + 2147483647 + 10000
        ConfigPackageData.Find();
        Assert.AreEqual(Format(LineNo + ShiftLineNo + 10000L), ConfigPackageData.Value, ConfigPackageData.FieldCaption(Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFieldElementNameAddPrefixTrue()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381067] "Config. XML Exchange".GetFieldElementName adds prefix 'Field_' when AddPrefixMode = TRUE
        ConfigXMLExchange.SetPrefixMode(true);
        Assert.AreEqual('Field_' + FieldTok, ConfigXMLExchange.GetFieldElementName(FieldTok), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFieldElementNameAddPrefixFalse()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381067] "Config. XML Exchange".GetFieldElementName does not add prefix 'Field_' when AddPrefixMode = FALSE
        ConfigXMLExchange.SetPrefixMode(false);
        Assert.AreEqual(Format(FieldTok), ConfigXMLExchange.GetFieldElementName(FieldTok), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetTableElementNameAddPrefixTrue()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381067] "Config. XML Exchange".GetTableElementName adds prefix 'Table_' when AddPrefixMode = TRUE
        ConfigXMLExchange.SetPrefixMode(true);
        Assert.AreEqual('Table_' + TableTok, ConfigXMLExchange.GetTableElementName(TableTok), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetTableElementNameAddPrefixFalse()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381067] "Config. XML Exchange".GetTableElementName does not add prefix 'Table_' when AddPrefixMode = FALSE
        ConfigXMLExchange.SetPrefixMode(false);
        Assert.AreEqual(Format(TableTok), ConfigXMLExchange.GetTableElementName(TableTok), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageWithBlankLine()
    var
        ConfigPackage: Record "Config. Package";
        CustomerPriceGroup: Record "Customer Price Group";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        XMLDocument: DotNet XmlDocument;
        FilePath: Text;
    begin
        // [FEATURE] [XML]
        // [SCENARIO 217909] "Config. XML Exchange".ImportPackageXMLDocument is preparing data for applying package when XML contains the first record with no data
        Initialize();

        // [GIVEN] Exported XML file with empty table "Customer Price Group"
        CustomerPriceGroup.DeleteAll();
        FilePath := CreateConfigPackageAndExportToXML(ConfigPackage);

        // [GIVEN] Add new record to XML file "Customer Price Group".Code = "TEST"
        // [GIVEN] "Customer Price Group"."Price Includes VAT" = FALSE
        // [GIVEN] "Customer Price Group"."Allow Invoice Disc." = FALSE
        // [GIVEN] "Customer Price Group"."VAT Bus. Posting Gr. (Price)" = "POSTGR01"
        // [GIVEN] "Customer Price Group"."Description" = "Test Description"
        // [GIVEN] "Customer Price Group"."Allow Line Disc." = FALSE
        AddCustPriceGroupToXML(CustomerPriceGroup, XMLDocument, FilePath);

        // [WHEN] Importing updated XML file
        ConfigXMLExchange.ImportPackageXMLDocument(XMLDocument, '');

        // [THEN] Table Config. Package Data contains 6 records with value = '' for the first record
        // [THEN] Table Config. Package Data contains 6 records for the second record
        // [THEN] Config. Package Data for field "Code" with "Value" = TEST
        // [THEN] Config. Package Data for field "Price Includes VAT" with "Value" = FALSE
        // [THEN] Config. Package Data for field "Allow Invoice Disc." with "Value" = FALSE
        // [THEN] Config. Package Data for field "VAT Bus. Posting Gr. (Price)" with "Value" = "POSTGR01"
        // [THEN] Config. Package Data for field "Description" with "Value" = "Test Description"
        // [THEN] Config. Package Data for field "Allow Line Disc." with "Value" = FALSE
        VerifyConfigPackageData(CustomerPriceGroup, ConfigPackage.Code, DATABASE::"Customer Price Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetElementNameReturnsNormalizedName()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        Name: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217924] COD8614.GetElementName removes invalid characters and spaces from given argument and adds _ sign if resulting name begins from invalid character (digit i.e.)
        // or is a not recommended char
        Name := NameTok;
        Assert.AreEqual('_1_AB_', ConfigXMLExchange.GetElementName(Name), Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TextManagement_ReplaceInvalidCharacters()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        Name: Text[250];
        SubstChar: Char;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217924] COD6224.ReplaceXMLInvalidCharacters replaces invalid characters with given character. It keeps Letters, Digits, Underscores, etc.
        Name := NameTok + 'ƒ0';
        SubstChar := 'Z';
        Assert.AreEqual('ZZZZZ.ZZZ-ZZZZ:ZZZAZZBZZZZZ_ƒ0', XMLDOMManagement.ReplaceXMLInvalidCharacters(Name, SubstChar), Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTrueIsMultiRelationConfigPackageField()
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217835] If field of table has 2 or more related tables then "Config. Package Management"."IsFieldMultiRelation" for that field return TRUE
        Initialize();

        // [GIVEN] Field with multi related tables (Table 27 (Item), Field 5425 (Sales Unit of Measure))
        FindFieldWithMultiRelation(TableRelationsMetadata);

        // [WHEN] Invoke "Config. Package Management"."IsFieldMultiRelation"

        // [THEN] Result = TRUE
        Assert.IsTrue(
          ConfigPackageManagement.IsFieldMultiRelation(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No."),
          'Result of IsMultiRelation should be TRUE.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFalseIsMultiRelationConfigPackageField()
    var
        Item: Record Item;
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217835] If field of table has 1 or nothing related tables then "Config. Package Management"."IsFieldMultiRelation" for that field return FALSE
        Initialize();

        Assert.IsFalse(
          ConfigPackageManagement.IsFieldMultiRelation(DATABASE::Item, Item.FieldNo("No.")), 'Result of IsMultiRelation should be FALSE.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetRelationTablesIDConfigPackageFieldMultiRelation()
    var
        ConfigPackageField: Record "Config. Package Field";
        ItemJournalLine: Record "Item Journal Line";
        ActualResult: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217835] If field of table has 2 or more related tables then "Config. Package Field"."GetRelationTablesID" for that field return a list of related tables
        Initialize();

        // [GIVEN] Field with multi related tables (Table "Item Journal Line", Field "Source No.")
        // [GIVEN] Related tables: Customer, Vendor, Item.

        // [GIVEN] Config. Package Field for field "Source No."
        ConfigPackageField."Table ID" := DATABASE::"Item Journal Line";
        ConfigPackageField."Field ID" := ItemJournalLine.FieldNo("Source No.");

        // [WHEN] Invoke "Config. Package Field"."GetRelationTablesID"
        ActualResult := ConfigPackageField.GetRelationTablesID();

        // [THEN] Result = '18|23|27'.
        Assert.IsTrue(
          StrPos(ActualResult, StrSubstNo('%1|%2|%3', DATABASE::Customer, DATABASE::Vendor, DATABASE::Item)) > 0,
          'Wrong list of related tables.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetRelationTablesIDConfigPackageFieldSingleRelation()
    var
        ConfigPackageField: Record "Config. Package Field";
        Item: Record Item;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217835] If field of table has 1 related tables then "Config. Package Field"."GetRelationTablesID" for that field return a ID of related table
        Initialize();

        ConfigPackageField."Table ID" := DATABASE::Item;

        // [THEN] Table relation for Item."Base Unit of Measure" field is "Unit of Measure" table.
        ConfigPackageField."Field ID" := Item.FieldNo("Base Unit of Measure");
        Assert.AreEqual(
          Format(DATABASE::"Unit of Measure"), ConfigPackageField.GetRelationTablesID(), 'Wrong list of related tables.');

        // [THEN] Table relation for Item."Sales Unit of Measure" field is "Item Unit of Measure" table.
        ConfigPackageField."Field ID" := Item.FieldNo("Sales Unit of Measure");
        Assert.AreEqual(
          Format(DATABASE::"Item Unit of Measure"), ConfigPackageField.GetRelationTablesID(), 'Wrong list of related tables.');

        // [THEN] Table relation for Item."Purch. Unit of Measure" field is "Item Unit of Measure" table.
        ConfigPackageField."Field ID" := Item.FieldNo("Purch. Unit of Measure");
        Assert.AreEqual(
          Format(DATABASE::"Item Unit of Measure"), ConfigPackageField.GetRelationTablesID(), 'Wrong list of related tables.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetRelationTablesIDConfigPackageFieldNoRelation()
    var
        ConfigPackageField: Record "Config. Package Field";
        Item: Record Item;
        ActualResult: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217835] If field of table hasn't related tables then "Config. Package Field"."GetRelationTablesID" for that field return empty string
        Initialize();

        ConfigPackageField."Table ID" := DATABASE::Item;
        ConfigPackageField."Field ID" := Item.FieldNo(Type);

        ActualResult := ConfigPackageField.GetRelationTablesID();

        // [THEN] Result = ''
        Assert.AreEqual('', ActualResult, 'Wrong list of related tables.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageFilter_CrossColumnFilter_False_FirstCustomer()
    var
        ConfigPackageTable: Record "Config. Package Table";
        RecRef: RecordRef;
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        CustomerNo: array[2] of Code[20];
    begin
        // [SCENARIO 346990] "Config. XML Exchange".ApplyPackageFilter() in case of "Cross-Column Filter" = False, two customers and filter by the first customer
        Initialize();

        // [GIVEN] 4 posted sales invoices with the following "Sell-To"\"Bill-To" customers: A\A, B\B, A\B, B\A
        // [GIVEN] Config. package table "Sales Invoice Header" with "Cross-Column Filter" = False, two filters: "Sell-To" = A, "Bill-To" = A
        CustomerNo[1] := LibraryUtility.GenerateGUID();
        CustomerNo[2] := LibraryUtility.GenerateGUID();
        CreateConfigPackageForSalesInvoiceHeaderWithTwoFilters(ConfigPackageTable, false, CustomerNo, CustomerNo[1]);
        ConfigPackageTable.TestField("Cross-Column Filter", false);

        // [WHEN] Invoke "Config. XML Exchange".ApplyPackageFilter() for "Sales Invoice Header" RecordRef
        RecRef.Open(Database::"Sales Invoice Header");
        ConfigXMLExchange.ApplyPackageFilter(ConfigPackageTable, RecRef);

        // [THEN] RecRef is filtered with one invoice for "Sell-To"\"Bill-To" : A\A
        VerifyFirstDocAfterApplyPackageFilter(RecRef, 1, CustomerNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageFilter_CrossColumnFilter_False_SecondCustomer()
    var
        ConfigPackageTable: Record "Config. Package Table";
        RecRef: RecordRef;
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        CustomerNo: array[2] of Code[20];
    begin
        // [SCENARIO 346990] "Config. XML Exchange".ApplyPackageFilter() in case of "Cross-Column Filter" = False, two customers and filter by the second customer
        Initialize();

        // [GIVEN] 4 posted sales invoices with the following "Sell-To"\"Bill-To" customers: A\A, B\B, A\B, B\A
        // [GIVEN] Config. package table "Sales Invoice Header" with "Cross-Column Filter" = False, two filters: "Sell-To" = B, "Bill-To" = B
        CustomerNo[1] := LibraryUtility.GenerateGUID();
        CustomerNo[2] := LibraryUtility.GenerateGUID();
        CreateConfigPackageForSalesInvoiceHeaderWithTwoFilters(ConfigPackageTable, false, CustomerNo, CustomerNo[2]);
        ConfigPackageTable.TestField("Cross-Column Filter", false);

        // [WHEN] Invoke "Config. XML Exchange".ApplyPackageFilter() for "Sales Invoice Header" RecordRef
        RecRef.Open(Database::"Sales Invoice Header");
        ConfigXMLExchange.ApplyPackageFilter(ConfigPackageTable, RecRef);

        // [THEN] RecRef is filtered with one invoice for "Sell-To"\"Bill-To" : B\B
        VerifyFirstDocAfterApplyPackageFilter(RecRef, 1, CustomerNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageFilter_CrossColumnFilter_True_FirstCustomer()
    var
        ConfigPackageTable: Record "Config. Package Table";
        RecRef: RecordRef;
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        CustomerNo: array[2] of Code[20];
    begin
        // [SCENARIO 346990] "Config. XML Exchange".ApplyPackageFilter() in case of "Cross-Column Filter" = True, two customers and filter by the first customer
        Initialize();

        // [GIVEN] 4 posted sales invoices with the following "Sell-To"\"Bill-To" customers: A\A, B\B, A\B, B\A
        // [GIVEN] Config. package table "Sales Invoice Header" with "Cross-Column Filter" = True, two filters: "Sell-To" = A, "Bill-To" = A
        CustomerNo[1] := LibraryUtility.GenerateGUID();
        CustomerNo[2] := LibraryUtility.GenerateGUID();
        CreateConfigPackageForSalesInvoiceHeaderWithTwoFilters(ConfigPackageTable, true, CustomerNo, CustomerNo[1]);
        ConfigPackageTable.TestField("Cross-Column Filter", true);

        // [WHEN] Invoke "Config. XML Exchange".ApplyPackageFilter() for "Sales Invoice Header" RecordRef
        RecRef.Open(Database::"Sales Invoice Header");
        ConfigXMLExchange.ApplyPackageFilter(ConfigPackageTable, RecRef);

        // [THEN] RecRef is filtered with 3 invoices for "Sell-To"\"Bill-To" : A\A, A\B, B\A
        VerifyFirstDocAfterApplyPackageFilter(RecRef, 3, CustomerNo[1]);
        VerifyNextDocAfterApplyPackageFilter(RecRef, CustomerNo[1], CustomerNo[2]);
        VerifyNextDocAfterApplyPackageFilter(RecRef, CustomerNo[2], CustomerNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPackageFilter_CrossColumnFilter_True_SecondCustomer()
    var
        ConfigPackageTable: Record "Config. Package Table";
        RecRef: RecordRef;
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        CustomerNo: array[2] of Code[20];
    begin
        // [SCENARIO 346990] "Config. XML Exchange".ApplyPackageFilter() in case of "Cross-Column Filter" = True, two customers and filter by the second customer
        Initialize();

        // [GIVEN] 4 posted sales invoices with the following "Sell-To"\"Bill-To" customers: A\A, B\B, A\B, B\A
        // [GIVEN] Config. package table "Sales Invoice Header" with "Cross-Column Filter" = True, two filters: "Sell-To" = B, "Bill-To" = B
        CustomerNo[1] := LibraryUtility.GenerateGUID();
        CustomerNo[2] := LibraryUtility.GenerateGUID();
        CreateConfigPackageForSalesInvoiceHeaderWithTwoFilters(ConfigPackageTable, true, CustomerNo, CustomerNo[2]);
        ConfigPackageTable.TestField("Cross-Column Filter", true);

        // [WHEN] Invoke "Config. XML Exchange".ApplyPackageFilter() for "Sales Invoice Header" RecordRef
        RecRef.Open(Database::"Sales Invoice Header");
        ConfigXMLExchange.ApplyPackageFilter(ConfigPackageTable, RecRef);

        // [THEN] RecRef is filtered with 3 invoices for "Sell-To"\"Bill-To" : B\B, A\B, B\A
        VerifyFirstDocAfterApplyPackageFilter(RecRef, 3, CustomerNo[2]);
        VerifyNextDocAfterApplyPackageFilter(RecRef, CustomerNo[1], CustomerNo[2]);
        VerifyNextDocAfterApplyPackageFilter(RecRef, CustomerNo[2], CustomerNo[1]);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Package Base Operations");
        LibraryVariableStorage.Clear();
        LibraryRapidStart.CleanUp('');
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM RS Package Base Operations");

        HideDialog();

        SingleEntryRecNo := 1;
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM RS Package Base Operations");
    end;

    local procedure HideDialog()
    var
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigPackageMgt.SetHideDialog(true);
    end;

    local procedure CreateConfigPackageForSalesInvoiceHeaderWithTwoFilters(var ConfigPackageTable: Record "Config. Package Table"; CrossColumnFilter: Boolean; CustomerNo: array[2] of Code[20]; CustomerNoFilter: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        MockSalesInvoiceHeader(CustomerNo[1], CustomerNo[1]);
        MockSalesInvoiceHeader(CustomerNo[2], CustomerNo[2]);
        MockSalesInvoiceHeader(CustomerNo[1], CustomerNo[2]);
        MockSalesInvoiceHeader(CustomerNo[2], CustomerNo[1]);

        CreatePackageForTable(ConfigPackage, ConfigPackageTable, Database::"Sales Invoice Header");
        CreateConfigPackageFilter(ConfigPackageTable, DummySalesInvoiceHeader.FieldNo("Sell-to Customer No."), CustomerNoFilter);
        CreateConfigPackageFilter(ConfigPackageTable, DummySalesInvoiceHeader.FieldNo("Bill-to Customer No."), CustomerNoFilter);
        ConfigPackageTable."Cross-Column Filter" := CrossColumnFilter;
        ConfigPackageTable.Modify();
    end;

    local procedure CreatePackageDataPairWithPKRelation(var ConfigPackage: Record "Config. Package")
    var
        RelatedConfigPackageTable: Record "Config. Package Table";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ConfigPackageFilter: Record "Config. Package Filter";
        LibraryERM: Codeunit "Library - ERM";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        KeyValueWithRelation: Code[10];
        KeyValueWithoutRelation: Code[10];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate); // Master
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name); // Related

        KeyValueWithRelation := GenJournalTemplate.Name;
        KeyValueWithoutRelation := GenJournalBatch.Name;

        GenJournalTemplate.Delete();
        GenJournalBatch.Delete();

        // Related Table field with relation

        // PK Field with relation
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          RelatedConfigPackageTable,
          DATABASE::"Gen. Journal Batch",
          GenJournalBatch.FieldNo("Journal Template Name"),
          KeyValueWithRelation,
          SingleEntryRecNo);

        // Field without relation
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          RelatedConfigPackageTable,
          DATABASE::"Gen. Journal Batch",
          GenJournalBatch.FieldNo(Name),
          KeyValueWithoutRelation,
          SingleEntryRecNo);

        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Gen. Journal Batch", 0, GenJournalBatch.FieldNo(Name), GenJournalBatch.Name);

        LibraryRapidStart.ValidatePackage(ConfigPackage, false);
    end;

    local procedure CreateConfigPackageAndExportToXML(var ConfigPackage: Record "Config. Package") FilePath: Text
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        CreatePackageForTable(ConfigPackage, ConfigPackageTable, DATABASE::"Customer Price Group");
        ConfigPackage."Exclude Config. Tables" := true;
        ConfigPackage.Modify(true);
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Customer Price Group");
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);
    end;

    local procedure AddCustPriceGroupToXML(var CustomerPriceGroup: Record "Customer Price Group"; var XMLDocument: DotNet XmlDocument; FilePath: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        DocumentElement: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        DummyXMLNode: DotNet XmlNode;
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(FilePath, XMLDocument);
        DocumentElement := XMLDocument.DocumentElement.FirstChild;
        CreateDummyCustPriceGroup(CustomerPriceGroup);
        XMLDOMManagement.AddElement(
          DocumentElement, ConfigXMLExchange.GetElementName(CustomerPriceGroup.TableName), '', '', XMLNode);
        XMLDOMManagement.AddElement(
          XMLNode, ConfigXMLExchange.GetElementName(CustomerPriceGroup.FieldName(Code)), CustomerPriceGroup.Code, '', DummyXMLNode);
        XMLDOMManagement.AddElement(
          XMLNode, ConfigXMLExchange.GetElementName(CustomerPriceGroup.FieldName("Price Includes VAT")),
          Format(CustomerPriceGroup."Price Includes VAT"), '', DummyXMLNode);
        XMLDOMManagement.AddElement(
          XMLNode, ConfigXMLExchange.GetElementName(CustomerPriceGroup.FieldName("Allow Invoice Disc.")),
          Format(CustomerPriceGroup."Allow Invoice Disc."), '', DummyXMLNode);
        XMLDOMManagement.AddElement(
          XMLNode, ConfigXMLExchange.GetElementName(CustomerPriceGroup.FieldName("VAT Bus. Posting Gr. (Price)")),
          CustomerPriceGroup."VAT Bus. Posting Gr. (Price)", '', DummyXMLNode);
        XMLDOMManagement.AddElement(
          XMLNode, ConfigXMLExchange.GetElementName(CustomerPriceGroup.FieldName(Description)),
          CustomerPriceGroup.Description, '', DummyXMLNode);
        XMLDOMManagement.AddElement(
          XMLNode, ConfigXMLExchange.GetElementName(CustomerPriceGroup.FieldName("Allow Line Disc.")),
          Format(CustomerPriceGroup."Allow Line Disc."), '', DummyXMLNode);
    end;

    local procedure ExportToXML(PackageCode: Code[20]; var ConfigPackageTable: Record "Config. Package Table"; var FilePath: Text)
    var
        FileManagement: Codeunit "File Management";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
    begin
        FilePath := FileManagement.ServerTempFileName('xml');
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetHideDialog(true);
        ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, FilePath);
    end;

    local procedure CreateDummyCustPriceGroup(var CustomerPriceGroup: Record "Customer Price Group")
    begin
        Clear(CustomerPriceGroup);
        CustomerPriceGroup.Code :=
          LibraryUtility.GenerateRandomCode(CustomerPriceGroup.FieldNo(Code), DATABASE::"Customer Price Group");
        CustomerPriceGroup."VAT Bus. Posting Gr. (Price)" :=
          LibraryUtility.GenerateRandomCode(CustomerPriceGroup.FieldNo("VAT Bus. Posting Gr. (Price)"), DATABASE::"Customer Price Group");
        CustomerPriceGroup.Description := LibraryUtility.GenerateGUID();
    end;

    local procedure VerifyRelatedRecordCount(PackageCode: Code[20]; TableID: Integer; MustBeEmpty: Boolean)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageRecord.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageField.SetRange("Package Code", PackageCode);
        ConfigPackageError.SetRange("Package Code", PackageCode);
        ConfigPackageFilter.SetRange("Package Code", PackageCode);

        if TableID <> 0 then begin
            ConfigPackageTable.SetRange("Table ID", TableID);
            ConfigPackageRecord.SetRange("Table ID", TableID);
            ConfigPackageData.SetRange("Table ID", TableID);
            ConfigPackageField.SetRange("Table ID", TableID);
            ConfigPackageError.SetRange("Table ID", TableID);
            ConfigPackageFilter.SetRange("Table ID", TableID);
        end;

        Assert.AreEqual(
          MustBeEmpty, ConfigPackageTable.IsEmpty, StrSubstNo(RelatedTableDataError, MustBeEmpty, ConfigPackageTable.TableName));
        Assert.AreEqual(
          MustBeEmpty, ConfigPackageRecord.IsEmpty, StrSubstNo(RelatedTableDataError, MustBeEmpty, ConfigPackageRecord.TableName));
        Assert.AreEqual(MustBeEmpty, ConfigPackageData.IsEmpty, StrSubstNo(RelatedTableDataError, MustBeEmpty, ConfigPackageData.TableName));
        Assert.AreEqual(
          MustBeEmpty, ConfigPackageField.IsEmpty, StrSubstNo(RelatedTableDataError, MustBeEmpty, ConfigPackageField.TableName));
        Assert.AreEqual(
          MustBeEmpty, ConfigPackageError.IsEmpty, StrSubstNo(RelatedTableDataError, MustBeEmpty, ConfigPackageError.TableName));
        Assert.AreEqual(
          MustBeEmpty, ConfigPackageFilter.IsEmpty, StrSubstNo(RelatedTableDataError, MustBeEmpty, ConfigPackageFilter.TableName));
    end;

    local procedure VerifyCopyDataRelatedRecordCount(NewPackageCode: Code[20]; CopyData: Boolean)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackage.SetRange(Code, NewPackageCode);
        Assert.IsFalse(ConfigPackage.IsEmpty, StrSubstNo(RelatedTableDataError, false, ConfigPackage.TableName));
        ConfigPackageTable.SetRange("Package Code", NewPackageCode);
        Assert.IsFalse(ConfigPackageTable.IsEmpty, StrSubstNo(RelatedTableDataError, false, ConfigPackageTable.TableName));
        ConfigPackageField.SetRange("Package Code", NewPackageCode);
        Assert.IsFalse(ConfigPackageField.IsEmpty, StrSubstNo(RelatedTableDataError, false, ConfigPackageField.TableName));
        ConfigPackageFilter.SetRange("Package Code", NewPackageCode);
        Assert.IsFalse(ConfigPackageFilter.IsEmpty, StrSubstNo(RelatedTableDataError, false, ConfigPackageFilter.TableName));

        ConfigPackageRecord.SetRange("Package Code", NewPackageCode);
        Assert.IsTrue(
          CopyData <> ConfigPackageRecord.IsEmpty, StrSubstNo(RelatedTableDataError, not CopyData, ConfigPackageRecord.TableName));
        ConfigPackageData.SetRange("Package Code", NewPackageCode);
        Assert.IsTrue(CopyData <> ConfigPackageData.IsEmpty, StrSubstNo(RelatedTableDataError, not CopyData, ConfigPackageData.TableName));
        ConfigPackageError.SetRange("Package Code", NewPackageCode);
        Assert.IsTrue(ConfigPackageError.IsEmpty, StrSubstNo(MustBeNoPackageErrors, ConfigPackageError.TableName));

        if CopyData then begin
            ConfigPackageRecord.SetRange(Invalid, true);
            Assert.IsTrue(ConfigPackageRecord.IsEmpty, StrSubstNo(MustBeNoPackageErrors, ConfigPackageRecord.TableName));
            ConfigPackageData.SetRange(Invalid, true);
            Assert.IsTrue(ConfigPackageData.IsEmpty, StrSubstNo(MustBeNoPackageErrors, ConfigPackageData.TableName));
        end;
    end;

    local procedure VerifyFieldProcessingOrder(var ConfigPackageField: Record "Config. Package Field"; var ProcessingOrder: Integer; KeyField: Boolean)
    begin
        ConfigPackageField.SetRange("Primary Key", KeyField);
        ConfigPackageField.FindFirst();
        repeat
            ProcessingOrder += 1;
            Assert.AreEqual(
              ProcessingOrder,
              ConfigPackageField."Processing Order",
              StrSubstNo(Fields_WrongProcessingOrderErr, ConfigPackageField.FieldName("Processing Order"), ProcessingOrder));
        until ConfigPackageField.Next() = 0;
    end;

    local procedure GetTables_Report_Run(PackageCode: Code[20]; WithDataOnly: Boolean)
    var
        GetPackageTables: Report "Get Package Tables";
    begin
        Commit();  // Commit required to avoid test failure.
        LibraryVariableStorage.Enqueue(WithDataOnly);
        GetPackageTables.Set(PackageCode);
        GetPackageTables.Run();
    end;

    local procedure CopyPackage_Report_Run(var ConfigPackage: Record "Config. Package"; NewPackageCode: Code[20]; WithDataOnly: Boolean)
    var
        CopyPackage: Report "Copy Package";
    begin
        Commit();  // Commit required to avoid test failure.
        LibraryVariableStorage.Enqueue(NewPackageCode);
        LibraryVariableStorage.Enqueue(WithDataOnly);
        CopyPackage.Set(ConfigPackage);
        CopyPackage.Run();
    end;

    local procedure CreatePackageForTable(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; TableId: Integer)
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableId);
    end;

    local procedure CreateConfigPackageFilter(ConfigPackageTable: Record "Config. Package Table"; FieldId: Integer; FieldFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        ConfigPackageFilter."Package Code" := ConfigPackageTable."Package Code";
        ConfigPackageFilter."Table ID" := ConfigPackageTable."Table ID";
        ConfigPackageFilter."Field ID" := FieldId;
        ConfigPackageFilter."Field Filter" := FieldFilter;
        ConfigPackageFilter.Insert();
    end;

    local procedure CreatePackageOf3Tables(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: array[3] of Record "Config. Package Table")
    var
        "Field": Record "Field";
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        Field.FindFirst();
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable[1], ConfigPackage.Code, Field.TableNo);
        Field.SetRange(TableNo, Field.TableNo + 1, 10000);
        Field.FindFirst();
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable[2], ConfigPackage.Code, Field.TableNo);
        Field.FindLast();
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable[3], ConfigPackage.Code, Field.TableNo);
        Commit();
    end;

    local procedure CreatePackageOf8Tables(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: array[8] of Record "Config. Package Table")
    var
        "Field": Record "Field";
        I: Integer;
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        for I := 1 to 8 do begin
            Field.FindFirst();
            LibraryRapidStart.CreatePackageTable(ConfigPackageTable[I], ConfigPackage.Code, Field.TableNo);
            Field.SetRange(TableNo, Field.TableNo + 1, 10000);
        end;
        Commit();
    end;

    local procedure CreateSimpleConfigLine(var ConfigLine: Record "Config. Line"; LineNo: BigInteger)
    begin
        ConfigLine.Init();
        ConfigLine.Validate("Line No.", LineNo);
        ConfigLine.Insert();
    end;

    local procedure CreateSimpleConfigPackageData(var ConfigPackageData: Record "Config. Package Data"; ConfigPackageDataCode: Code[20]; NewValue: BigInteger; FieldId: Integer)
    begin
        ConfigPackageData.Init();
        ConfigPackageData."Package Code" := ConfigPackageDataCode;
        ConfigPackageData."Table ID" := DATABASE::"Config. Line";
        ConfigPackageData."Field ID" := FieldId;
        ConfigPackageData.Value := Format(NewValue);
        ConfigPackageData.Insert();
    end;

    local procedure MockSalesInvoiceHeader(SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Sell-to Customer No." := SellToCustomerNo;
        SalesInvoiceHeader."Bill-to Customer No." := BillToCustomerNo;
        SalesInvoiceHeader.Insert();
    end;

    local procedure FindTableWithRelatedSystemTable(var TableID: Integer; var ReleatedTableID: Integer)
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, 1, 99000999);
        Field.SetFilter(RelationTableNo, '>=%1', 2000000006);
        Field.FindFirst();

        TableID := Field.TableNo;
        ReleatedTableID := Field.RelationTableNo;
    end;

    local procedure FindFieldWithMultiRelation(var TableRelationsMetadata: Record "Table Relations Metadata")
    begin
        TableRelationsMetadata.SetRange("Related Field No.", 2);
        TableRelationsMetadata.SetRange("Condition Field No.", 1);
        TableRelationsMetadata.FindFirst();
    end;

    local procedure VerifyConfigPackageData(CustomerPriceGroup: Record "Customer Price Group"; ConfigPackageCode: Code[20]; TableID: Integer)
    begin
        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 1, CustomerPriceGroup.FieldNo(Code), '');
        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 1, CustomerPriceGroup.FieldNo("Price Includes VAT"), '');
        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 1, CustomerPriceGroup.FieldNo("Allow Invoice Disc."), '');
        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 1, CustomerPriceGroup.FieldNo("VAT Bus. Posting Gr. (Price)"), '');
        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 1, CustomerPriceGroup.FieldNo(Description), '');
        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 1, CustomerPriceGroup.FieldNo("Allow Line Disc."), '');

        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 2, CustomerPriceGroup.FieldNo(Code), CustomerPriceGroup.Code);
        VerifyConfigPackageDataValue(
          ConfigPackageCode, TableID, 2, CustomerPriceGroup.FieldNo("Price Includes VAT"), Format(CustomerPriceGroup."Price Includes VAT"));
        VerifyConfigPackageDataValue(
          ConfigPackageCode, TableID, 2, CustomerPriceGroup.FieldNo("Allow Invoice Disc."),
          Format(CustomerPriceGroup."Allow Invoice Disc."));
        VerifyConfigPackageDataValue(
          ConfigPackageCode, TableID, 2, CustomerPriceGroup.FieldNo("VAT Bus. Posting Gr. (Price)"),
          CustomerPriceGroup."VAT Bus. Posting Gr. (Price)");
        VerifyConfigPackageDataValue(ConfigPackageCode, TableID, 2, CustomerPriceGroup.FieldNo(Description), CustomerPriceGroup.Description);
        VerifyConfigPackageDataValue(
          ConfigPackageCode, TableID, 2, CustomerPriceGroup.FieldNo("Allow Line Disc."), Format(CustomerPriceGroup."Allow Line Disc."));
    end;

    local procedure VerifyConfigPackageDataValue(ConfigPackageCode: Code[20]; TableID: Integer; No: Integer; FieldID: Integer; ExpectedValue: Text)
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.Get(ConfigPackageCode, TableID, No, FieldID);
        ConfigPackageData.TestField(Value, ExpectedValue);
    end;

    local procedure VerifyFirstDocAfterApplyPackageFilter(var RecRef: RecordRef; ExpectedCount: Integer; ExpectedCustomerNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Assert.RecordCount(RecRef, ExpectedCount);
        RecRef.FindSet();
        RecRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.TestField("Sell-to Customer No.", ExpectedCustomerNo);
        SalesInvoiceHeader.TestField("Bill-to Customer No.", ExpectedCustomerNo);
    end;

    local procedure VerifyNextDocAfterApplyPackageFilter(var RecRef: RecordRef; SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        RecRef.Next();
        RecRef.SetTable(SalesInvoiceHeader);
        SalesInvoiceHeader.TestField("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceHeader.TestField("Bill-to Customer No.", BillToCustomerNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Report_GetTables_RequestPageRun_Handler(var GetPackageTables: TestRequestPage "Get Package Tables")
    var
        WithDataOnly: Variant;
    begin
        GetPackageTables.SelectTables.AssistEdit();
        LibraryVariableStorage.Dequeue(WithDataOnly);
        GetPackageTables.WithDataOnly.SetValue(WithDataOnly);
        GetPackageTables.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Report_GetTables_SelectedTables_SelectionHandler(var ConfigSelection: TestPage "Config. Selection")
    begin
        ConfigSelection.First();
        ConfigSelection.Selected.SetValue(true);
        ConfigSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Report_GetTables_SelectedTables_SelectAllHandler(var ConfigSelection: TestPage "Config. Selection")
    begin
        ConfigSelection.First();
        repeat
            ConfigSelection.Selected.SetValue(true);
        until ConfigSelection.Next();
        ConfigSelection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Report_CopyPackage_Handler(var CopyPackage: TestRequestPage "Copy Package")
    var
        NewPackageCode: Variant;
        CopyData: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewPackageCode);
        LibraryVariableStorage.Dequeue(CopyData);
        CopyPackage.Package.SetValue(NewPackageCode);
        CopyPackage.CopyData.SetValue(CopyData);
        CopyPackage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

