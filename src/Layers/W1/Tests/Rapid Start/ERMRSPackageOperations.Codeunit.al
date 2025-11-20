codeunit 136603 "ERM RS Package Operations"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start]
    end;

    var
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryERM: Codeunit "Library - ERM";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        ConfigPckgCompressionMgt: Codeunit "Config. Pckg. Compression Mgt.";
        FileMgt: Codeunit "File Management";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APIMockEvents: Codeunit "API Mock Events";
        isInitialized: Boolean;
        PackageDataErr: Label 'There are errors in Package Data Error.';
        ApplyErr: Label 'There are errors in Apply Migration Data.';
        Text101Err: Label 'Package Card page shows incorrect data.';
        Text103Err: Label 'Gen. Journal Line is not posted.';
        NoDataAfterImportErr: Label 'No Data In Package.';
        ErrorInApplyingWithoutValidationFlagErr: Label 'Data is not applied in case validation flag for field is set to false.';
        FlowFieldAppearedInDataErr: Label 'Only normal fields should be available after import.';
        ErrorOnEvaluatingErr: Label 'Error on evaluating %1 datatype.', Locked = true;
        NoErrorOnEvaluatingErr: Label 'Must be error on evaluating %1 datatype.', Locked = true;
        FieldValueIsIncorrectErr: Label '%1 is incorrect.', Locked = true;
        ExportImportInterfereErr: Label 'XML Package Data Export/Import change existing package data.';
        ExportImportWrongPackageErr: Label 'XML Package Data Export/Import process wrong package.';
        TableNotValidatedErr: Label 'Table ID was validated incorrectly.';
        XMLGeneratedIncorrectlyErr: Label 'Localization information in the XML document was generated incorrectly.';
        FileTextMsg: Label 'FileText';
        NotGZIPFormatErr: Label 'Generated file is not in GZIP format.';
        FileContentMismatchErr: Label 'File content mismatch after GZIP compression.';
        DecompressWrongResultErr: Label 'Decompress returns true for non GZip file.';
        ValueIsIncorrectErr: Label '%1 value is incorrect.', Locked = true;
        PackageErr: Label 'There are errors in Package %1.', Locked = true;
        UnhandledConfirmErr: Label 'Unhandled UI: Confirm';
        PackageImportErr: Label 'An error occurred while importing the %1 table. The table does not exist in the database.', Comment = 'An error occurred while importing the -452 table. The table does not exist in the database.', Locked = true;
        RedundancyInTheShopCalendarErr: Label 'There is redundancy in the Shop Calendar.';
        MustBeIntegersErr: Label 'must be Integer or BigInteger';
        FileNameForHandler: Text;
        MissingLineErr: Label 'Line %1 does not exist in preview page.', Locked = true;
        ExistingLineErr: Label 'Line %1 must not exist in preview page.', Locked = true;
        PackageCodeMustMatchErr: Label 'The package code in all sheets of the Excel file must match the selected package code, %1. Modify the package code in the Excel file or import this file from the Configuration Packages page to create a new package.', Comment = '%1 - package code';
        ImportNotAllowedErr: Label 'Cannot import table %1 through a Configuration Package.', Comment = '%1 = The name of the table.';
        ExternalTablesAreNotAllowedErr: Label 'External tables cannot be added in Configuration Packages.';



    [Test]
    procedure AddingExternalTablesToConfigPackagesTest()
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // Exercise, Verify
        ConfigPackageTable."Table ID" := Database::"CRM Account";
        asserterror ConfigPackageTable.Insert();
        Assert.ExpectedError(ExternalTablesAreNotAllowedErr);

        // Setup
        ConfigPackageTable."Table ID" := Database::Customer;
        ConfigPackageTable.Insert();

        // Exercise, Verify
        asserterror ConfigPackageTable.Rename('', Database::"CRM Account");
        Assert.ExpectedError(ExternalTablesAreNotAllowedErr);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure T001_AutoincrementCannotBeSetForFieldInPK()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        // [FEATURE] [AutoIncrement] [UT]
        // [SCENARIO] "AutoIncrement" is not allowed for the field, where "Primary Key" is 'Yes'.
        // [GIVEN] Field, where "Primary Key" is Yes.
        ConfigPackageField.Init();
        ConfigPackageField."Primary Key" := true;

        // [WHEN] Set "AutoIncrement" to Yes
        asserterror ConfigPackageField.Validate(AutoIncrement, true);

        // [THEN] Error: 'Primary Key must be No'
        Assert.ExpectedTestFieldError(ConfigPackageField.FieldCaption("Primary Key"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_AutoincrementAcceptsIntegersOnly()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        // [FEATURE] [AutoIncrement] [UT]
        // [SCENARIO] "AutoIncrement" is allowed for the field, where Type is 'Integer' or 'BigInteger'
        FindFieldOfType(ConfigPackageField, 'Integer');
        ConfigPackageField.Validate(AutoIncrement, true);

        FindFieldOfType(ConfigPackageField, 'BigInteger');
        ConfigPackageField.Validate(AutoIncrement, true);

        FindFieldOfType(ConfigPackageField, 'Code');
        asserterror ConfigPackageField.Validate(AutoIncrement, true);
        Assert.ExpectedError(MustBeIntegersErr);

        FindFieldOfType(ConfigPackageField, 'Text');
        asserterror ConfigPackageField.Validate(AutoIncrement, true);
        Assert.ExpectedError(MustBeIntegersErr);

        FindFieldOfType(ConfigPackageField, 'Decimal');
        asserterror ConfigPackageField.Validate(AutoIncrement, true);
        Assert.ExpectedError(MustBeIntegersErr);

        FindFieldOfType(ConfigPackageField, 'GUID');
        asserterror ConfigPackageField.Validate(AutoIncrement, true);
        Assert.ExpectedError(MustBeIntegersErr);

        FindFieldOfType(ConfigPackageField, 'Boolean');
        asserterror ConfigPackageField.Validate(AutoIncrement, true);
        Assert.ExpectedError(MustBeIntegersErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T010_AutoIncrementFieldGetsValueBeforeInsert()
    var
        TableAutoIncrementOutOfPK: Record "Table AutoIncrement Out Of PK";
        ConfigPackage: Record "Config. Package";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LastID: Integer;
    begin
        // [FEATURE] [AutoIncrement]
        // [SCENARIO 280914] Record with autoincrement field out of primary key should be imported with the value defined in the package data.
        // [GIVEN] Table 1471 is empty, the last incremented value for ID was '5'
        TableAutoIncrementOutOfPK.Init();
        TableAutoIncrementOutOfPK.ID := 5;
        TableAutoIncrementOutOfPK.Insert();
        LastID := TableAutoIncrementOutOfPK.ID;
        TableAutoIncrementOutOfPK.DeleteAll();

        // [GIVEN] Package record for table 1471, where ID = '4'
        LibraryRapidStart.CreatePackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Table AutoIncrement Out Of PK");
        LibraryRapidStart.CreatePackageRecord(ConfigPackageRecord, ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", 1);
        AssistedSetupTestLibrary.CallOnRegister();
        LibraryRapidStart.CreatePackageFieldData(
          ConfigPackageRecord, TableAutoIncrementOutOfPK.FieldNo("Setup ID"), Format(AssistedSetupTestLibrary.FirstPageID()));
        TableAutoIncrementOutOfPK.Category := TableAutoIncrementOutOfPK.Category::"2";
        LibraryRapidStart.CreatePackageFieldData(
          ConfigPackageRecord, TableAutoIncrementOutOfPK.FieldNo(Category), Format(TableAutoIncrementOutOfPK.Category::"2"));
        LibraryRapidStart.CreatePackageFieldData(
          ConfigPackageRecord, TableAutoIncrementOutOfPK.FieldNo(ID), Format(LastID - 1));

        // [GIVEN] Field "ID", where "Autoincrement" is 'Yes'
        ConfigPackageField.Get(ConfigPackage.Code, DATABASE::"Table AutoIncrement Out Of PK", TableAutoIncrementOutOfPK.FieldNo(ID));
        ConfigPackageField.Validate(AutoIncrement, true);
        ConfigPackageField.Modify(true);

        // [WHEN] Insert package record
        ConfigPackageManagement.SetHideDialog(true);
        ConfigPackageManagement.ApplyPackage(ConfigPackage, ConfigPackageTable, false);

        // [THEN] Record is inserted, where ID = '4'
        TableAutoIncrementOutOfPK.Get(AssistedSetupTestLibrary.FirstPageID(), TableAutoIncrementOutOfPK.Category::"2");
        TableAutoIncrementOutOfPK.TestField(ID, LastID - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportAndApplyPackageWithBlobField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        FilePath: Text;
        OriginalWorkDescription: Text;
    begin
        // [FEATURE] [Config Package]
        // [SCENARIO] Blob field can be exported, imported and applied
        Initialize();

        // [GIVEN] Sales Header with non-blank "Work Description" field exists
        CreateSalesOrderWithWorkDescription(SalesHeader);
        OriginalWorkDescription := SalesHeader.GetWorkDescription();

        // [GIVEN] Package for Sales Header with the work description field included
        CreatePackageWithBlobField(ConfigPackage, SalesHeader);

        // [WHEN] The package is exported
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        // [WHEN] The work description is set to empty value in system    
        SalesHeader.FindFirst();
        SalesHeader.SetWorkDescription('');
        SalesHeader.Modify();

        // [WHEN] The package is exported back to system
        ImportPackageXML(ConfigPackage.Code, FilePath);
        Erase(FilePath);

        // [THEN] The work description is still blank
        SalesHeader.FindFirst();
        Assert.AreEqual('', SalesHeader.GetWorkDescription(), SalesHeader.FieldCaption("Work Description"));

        // [WHEN] The package is applied
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] The work description is set to the value from the excel package
        SalesHeader.FindFirst();
        Assert.AreEqual(OriginalWorkDescription, SalesHeader.GetWorkDescription(), SalesHeader.FieldCaption("Work Description"));
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewHandler')]
    [Scope('OnPrem')]
    procedure ExportImportAndApplyPackageWithBlobFieldExcel()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigPackageCard: TestPage "Config. Package Card";
        OriginalWorkDescription: Text;
    begin
        // [FEATURE] [Config Package]
        // [SCENARIO] Blob field can be exported to excel, imported from excel and applied
        Initialize();

        // [GIVEN] Sales Order with work description
        LibrarySales.CreateSalesOrder(SalesHeader);
        OriginalWorkDescription := LibraryRandom.RandText(MaxStrLen(SalesHeader."Sell-to Customer Name"));
        SalesHeader.SetWorkDescription(OriginalWorkDescription);
        SalesHeader.Modify();

        // [GIVEN] Config package "A" for table "Sales Header"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, Database::"Sales Header");

        // [GIVEN] All fields except PK fields and "Work Description" are excluded from export
        LibraryRapidStart.SetIncludeAllFields(ConfigPackage.Code, Database::"Sales Header", false);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, Database::"Sales Header", SalesHeader.FieldNo("Work Description"), true);

        // [WHEN] The package is exported
        Commit();
        ExportToExcel(ConfigPackageTable);

        // [WHEN] The work description is set to empty value in system    
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
        SalesHeader.SetWorkDescription('');
        SalesHeader.Modify();

        // [WHEN] Open "Config. Package Card" page on 'A'
        ConfigPackageCard.OpenView();
        ConfigPackageCard.Filter.SetFilter(Code, ConfigPackage.Code);

        // [WHEN] Run action "Import From Excel" on package card page
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        LibraryVariableStorage.Enqueue(1); // expected numer of sheets in Excel for ExcelImportPreviewHandler
        ConfigPackageCard.ImportFromExcel.Invoke();

        // [THEN] The work description is still blank
        SalesHeader.FindFirst();
        Assert.AreEqual('', SalesHeader.GetWorkDescription(), SalesHeader.FieldCaption("Work Description"));

        // [WHEN] The package is applied
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] The work description is set to the value from the excel package
        SalesHeader.FindFirst();
        Assert.AreEqual(OriginalWorkDescription, SalesHeader.GetWorkDescription(), SalesHeader.FieldCaption("Work Description"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyDependentTableWithEmpyParentTableID()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        FilePath: Text;
    begin
        // [FEATURE] [Config Package]
        // [SCENARIO 158249] Dependent table with empty 'Parent Table ID' should not be applied due to a confirmation request
        Initialize();
        // [GIVEN] Imported a package with 3 tables: Customer, Sales Header, Sales Line
        // [GIVEN] The dependent table Sales Line has 'Parent Table ID' = 0
        CustomerNo := CreateSalesInvPackage(ConfigPackage, 0);
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        DeleteCustomerRelatedData(CustomerNo);
        ImportPackageXML(ConfigPackage.Code, FilePath);
        Erase(FilePath);

        // [WHEN] Apply the package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] The package application interrupted by a request for user confirmation
        VerifyConfigPackageError(ConfigPackage.Code, 36, SalesHeader.FieldNo("Sell-to Customer No."), UnhandledConfirmErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyDependentTableWithFilledParentTableID()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        CustomerNo: Code[20];
        FilePath: Text;
    begin
        // [FEATURE] [Config Package]
        // [SCENARIO 158249] Dependent table with filled 'Parent Table ID' should be applied without errors
        Initialize();
        // [GIVEN] Imported a package with 3 tables: Customer, Sales Header, Sales Line
        // [GIVEN] The dependent table Sales Line has 'Parent Table ID' = 36
        CustomerNo := CreateSalesInvPackage(ConfigPackage, DATABASE::"Sales Header");
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        DeleteCustomerRelatedData(CustomerNo);
        ImportPackageXML(ConfigPackage.Code, FilePath);
        Erase(FilePath);

        // [WHEN] Apply the package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);
        // [THEN] The package is applied without errors
        VerifyNoConfigPackageErrors(ConfigPackage.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        Customer: Record Customer;
    begin
        // [FEATURE] [Config Package]
        // [SCENARIO 122575] a new Package can be created and applied for Master Records.
        Initialize();

        // [GIVEN] Created a new package table record for Customer.
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, true);

        // [THEN] Table name is "Customer"
        // [THEN] Count of records in package table equal to count in DB
        ConfigPackageTable.CalcFields("Table Name");
        Assert.AreEqual(ConfigPackageTable.GetNoOfDatabaseRecords(), Customer.Count(), 'Wrong number of Database Records in the package');
        ConfigPackageTable.TestField("Table Name", Customer.TableName());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPackageToXML()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
    begin
        // [FEATURE] [XML]
        // [SCENARIO 122577] The new Package can be exported to XML.
        Initialize();
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        Erase(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageFromXML()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [XML]
        // [SCENARIO 122579] The new Package can be imported from XML.
        Initialize();
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);

        ExportImportXML(ConfigPackage.Code);

        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer), NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotApplyPackageWithIntegrationTableMapping()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ConfigPackageError: Record "Config. Package Error";
        IntegrationTableMappingRecordCount: Integer;
    begin
        // [FEATURE] [XML]
        // [SCENARIO] A package can be created, exported and imported with integration table mappings, but not applied.
        Initialize();
        InitializeCRM();

        // [GIVEN] Integration table mappings
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, Database::"Integration Table Mapping");
        Assert.RecordIsNotEmpty(IntegrationTableMapping);
        IntegrationTableMappingRecordCount := IntegrationTableMapping.Count();
        ExportImportXML(ConfigPackage.Code);

        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Integration Table Mapping"), NoDataAfterImportErr);
        IntegrationTableMapping.DeleteAll();
        Assert.RecordIsEmpty(IntegrationTableMapping);

        // [WHEN] Attempting to apply the package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] No integration table mapping records are imported and an error message is logged for each record in the package.
        Assert.RecordIsEmpty(IntegrationTableMapping);
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.SetRange("Table ID", DATABASE::"Integration Table Mapping");
        ConfigPackageError.SetRange("Error Text", StrSubstNo(ImportNotAllowedErr, IntegrationTableMapping.TableCaption()));
        Assert.RecordCount(ConfigPackageError, IntegrationTableMappingRecordCount);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure CannotApplyPackageWithIntegrationFieldMapping()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ConfigPackageError: Record "Config. Package Error";
        IntegrationFieldMappingRecordCount: Integer;
    begin
        // [FEATURE] [XML]
        // [SCENARIO] A package can be created, exported and imported with integration field mappings, but not applied.
        Initialize();
        InitializeCRM();

        // [GIVEN] Integration field mappings
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, Database::"Integration Field Mapping");
        Assert.RecordIsNotEmpty(IntegrationFieldMapping);
        IntegrationFieldMappingRecordCount := IntegrationFieldMapping.Count();
        ExportImportXML(ConfigPackage.Code);

        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Integration Field Mapping"), NoDataAfterImportErr);
        IntegrationFieldMapping.DeleteAll();
        Assert.RecordIsEmpty(IntegrationFieldMapping);

        // [WHEN] Attempting to apply the package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] No integration field mapping records are imported and an error message is loggee for each record in the package.
        Assert.RecordIsEmpty(IntegrationFieldMapping);
        ConfigPackageError.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageError.SetRange("Table ID", DATABASE::"Integration Field Mapping");
        ConfigPackageError.SetRange("Error Text", StrSubstNo(ImportNotAllowedErr, IntegrationFieldMapping.TableCaption()));
        Assert.RecordCount(ConfigPackageError, IntegrationFieldMappingRecordCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportLocalizedPackageToXML()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        PackageXML: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        XMLAttributes: DotNet XmlNodeList;
    begin
        // [FEATURE] [XML]
        // [SCENARIO] localization attributes are exported to XML
        Initialize();

        // [GIVEN] Generated a localized package
        CreateConfigPackage(ConfigPackage);
        ConfigPackage.Validate("Language ID", FindFirstLanguage());
        ConfigPackage.Modify(true);

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, FindRandomTableID(100));
        SetLocalizeFields(ConfigPackage.Code, ConfigPackageTable."Table ID");

        // [WHEN] Export Package to XML
        PackageXML := PackageXML.XmlDocument();
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigXMLExchange.ExportPackageXMLDocument(PackageXML, ConfigPackageTable, ConfigPackage, true);

        // [THEN] '_locDefinition' node and '_loc' attributes have been generated in XML document
        XMLNode := PackageXML.SelectSingleNode('//_locDefinition');
        XMLAttributes := PackageXML.SelectNodes('//@_loc');

        Assert.IsTrue((XMLNode.InnerXml <> '') and (XMLAttributes.Count <> 0), XMLGeneratedIncorrectlyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithPageID_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        RandomPageId: Integer;
    begin
        // [FEATURE] [XML]
        // [SCENARIO] 'Page ID' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Page ID' = "X"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        RandomPageId := LibraryRandom.RandInt(1000);
        ConfigPackageTable."Page ID" := RandomPageId;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Page ID' = "X"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(RandomPageId, ConfigPackageTable."Page ID", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithPackageProcessingOrder_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        RandomId: Integer;
    begin
        // [FEATURE] [XML]
        // [SCENARIO] 'Package Processing Order' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Package Processing Order' = "X"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        RandomId := LibraryRandom.RandInt(1000);
        ConfigPackageTable."Package Processing Order" := RandomId;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Package Processing Order' = "X"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(RandomId, ConfigPackageTable."Package Processing Order", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithParentTableID_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [XML]
        // [SCENARIO 158249] Filled 'Parent Table ID' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Table ID' = 37, 'Parent Table ID' = 36
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Sales Line");

        ConfigPackageTable."Parent Table ID" := DATABASE::"Sales Header";
        ConfigPackageTable.Modify();
        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Table ID' = 37, 'Parent Table ID' = 36
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Sales Line");
        Assert.AreEqual(DATABASE::"Sales Header", ConfigPackageTable."Parent Table ID", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithDeleteRecsBeforeProcessing_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [XML]
        // [SCENARIO] Filled 'Delete Recs Before Processing' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Delete Recs Before Processing' = "Yes"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        ConfigPackageTable."Delete Recs Before Processing" := true;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Delete Recs Before Processing' = "Yes"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(true, ConfigPackageTable."Delete Recs Before Processing", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithProcessingOrder_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        RandomId: Integer;
    begin
        // [FEATURE] [XML]
        // [SCENARIO 158249] Filled 'Processing Order' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Processing Order' = "X"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        RandomId := LibraryRandom.RandInt(1000);
        ConfigPackageTable."Processing Order" := RandomId;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Processing Order' = "X"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(RandomId, ConfigPackageTable."Processing Order", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithDataTemplate_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        RandomCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO] Filled 'Data Template' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Data Template' = "X"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        RandomCode := LibraryUtility.GenerateRandomCode(ConfigPackageTable.FieldNo("Data Template"), DATABASE::"Config. Package Table");
        ConfigPackageTable."Data Template" := RandomCode;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Data Template' = "X"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(RandomCode, ConfigPackageTable."Data Template", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithComments_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        RandomCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO] Filled 'Comments' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Comments' = "X"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        RandomCode := LibraryUtility.GenerateRandomCode(ConfigPackageTable.FieldNo(Comments), DATABASE::"Config. Package Table");
        ConfigPackageTable.Comments := RandomCode;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Comments' = "X"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(RandomCode, ConfigPackageTable.Comments, NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithCreatedByUser_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        RandomCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO] Filled 'Created by User ID' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Created by User ID' = "X"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        RandomCode :=
          LibraryUtility.GenerateRandomCode(ConfigPackageTable.FieldNo("Created by User ID"), DATABASE::"Config. Package Table");
        ConfigPackageTable."Created by User ID" := RandomCode;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Created by User ID' = "X"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(RandomCode, ConfigPackageTable."Created by User ID", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithSkipTableTriggers_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [XML]
        // [SCENARIO] Filled 'Skip Table Triggers' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Skip Table Triggers' = "Yes"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        ConfigPackageTable."Skip Table Triggers" := true;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Skip Table Triggers' = "Yes"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(true, ConfigPackageTable."Skip Table Triggers", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithDimensionsAsColumns_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [Dimension] [XML]
        // [SCENARIO] Filled 'Dimensions as Columns' field can be stored to and restored from XML
        Initialize();
        // [GIVEN] Package with Table, where 'Dimensions as Columns' = "Yes"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        ConfigPackageTable."Dimensions as Columns" := true;
        ConfigPackageTable.Modify();

        // [GIVEN] Package exported to an XML file
        // [WHEN] Import Package from the XML file
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Package contains Table, where 'Dimensions as Columns' = "Yes"
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(true, ConfigPackageTable."Dimensions as Columns", NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithBLOBField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        GLAccFilter: Text[250];
    begin
        // [SCENARIO] Pass BLOB (binary files) via RapidStart package
        Initialize();
        // [GIVEN] Two G/L Accounts, first one has a picture (BLOB value)
        CreateTwoGLAccountsFirstWithBLOB(GLAccFilter);
        // [GIVEN] Config. Package with 'G/L Account' table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"G/L Account");
        // [GIVEN] Set all fields excluded except PK and Picture to decrease package processing time
        IncludeGLAccountPictureConfigPackageField(ConfigPackage.Code);
        // [GIVEN] Set filter for two Contacts to decrease package processing time
        SetContactConfigPackageFilter(ConfigPackage.Code, GLAccFilter);
        // [WHEN] Export and then import package
        ExportImportXML(ConfigPackage.Code);
        // [THEN] "Config. Package Data"."BLOB Value" = Contact.Picture per each Contact
        VerifyConfigPackageDataBLOBValues(ConfigPackage.Code, GLAccFilter);
        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"G/L Account"), NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackage_ExportPackageTableWithMediaSetField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        ItemFilter: Text[250];
        FilePath: Text;
    begin
        // [SCENARIO] Pass MediaSet (binary files) via RapidStart package
        Initialize();
        // [GIVEN] Two Items, first item has a picture (MediaSet value)
        CreateTwoItemsFirstWithMediaSet(ItemFilter);
        // [GIVEN] Config. Package with Item table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Item);
        // [GIVEN] Set all fields excluded except PK and Picture to decrease package processing time
        IncludeItemPictureConfigPackageField(ConfigPackage.Code);
        // [GIVEN] Set filter for two items to decrease package processing time
        SetItemConfigPackageFilter(ConfigPackage.Code, ItemFilter);

        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);
        GetExpectedMediaSet(TempConfigMediaBuffer);

        LibraryRapidStart.CleanUp(ConfigPackage.Code);
        ConfigXMLExchange.ImportPackageXML(FilePath);
        Erase(FilePath);

        // [WHEN] Export and then import package
        ExportImportXML(ConfigPackage.Code);
        // [THEN] "Config. Package Data"."BLOB Value" = Item.Picture per each item
        VerifyConfigPackageDataMediaSetValues(ConfigPackage.Code, ItemFilter, TempConfigMediaBuffer);
        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Item), NoDataAfterImportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackages_ExportOneOfTwoPackage_ImpordDoNotSpoiledExistingData()
    var
        ConfigPackage1: Record "Config. Package";
        ConfigPackage2: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
    begin
        // [FEATURE] [XML]
        // [SCENARIO] Imported package should not affect existing equal package
        Initialize();
        // [GIVEN] Two equal packages: "A" and "B"
        CreateSimplePackage(ConfigPackage1);
        CreateSimplePackage(ConfigPackage2);
        // [GIVEN] Package "A" is exported to XML
        ExportToXML(ConfigPackage1.Code, ConfigPackageTable, FilePath);
        // [WHEN] Import Package "A" from XML
        ConfigXMLExchange.ImportPackageXML(FilePath);
        Erase(FilePath);
        // [THEN] Package "B" is not affected
        Assert.IsTrue(IsPackageDataExists(ConfigPackage2.Code, false), ExportImportWrongPackageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackages_ImportOneOfTwoPackage_RequiredPackageProcessed()
    var
        ConfigPackage1: Record "Config. Package";
        ConfigPackage2: Record "Config. Package";
    begin
        // [FEATURE] [XML]
        // [SCENARIO] Deleted package should not contains data, while there is equal package
        Initialize();
        // [GIVEN] Two equal packages: "A" and "B"
        CreateSimplePackage(ConfigPackage1);
        CreateSimplePackage(ConfigPackage2);

        // [GIVEN] Package "A" is exported, removed, and imported back
        ExportImportXML(ConfigPackage1.Code);
        // [WHEN] remove Package "B"
        LibraryRapidStart.CleanUp(ConfigPackage2.Code);

        // [THEN] Package "A" contains data, Package "B" does not.
        Assert.IsTrue(
          IsPackageDataExists(ConfigPackage1.Code, false) and not IsPackageDataExists(ConfigPackage2.Code, true),
          ExportImportInterfereErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GZIP_CompressTextFile_CompressedFileInGZIPFormat()
    var
        CompressedServerFileName: Text;
    begin
        // [FEATURE] [GZIP] [UT]
        // [SCENARIO] 'ServersideCompress' method compresses data to GZIP file
        // [WHEN] Create compressed file "F" (by ServersideCompress)
        CompressedServerFileName := CreateCompressedFile();
        // [THEN] File "F" is GZIP file
        VerifyGZIPHeader(CompressedServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GZIP_CompressDecompressTextFile_FileContentMatch()
    var
        CompressedServerFileName: Text;
        DecompressedServerFileName: Text;
        Text: Text;
    begin
        // [FEATURE] [GZIP] [UT]
        // [SCENARIO] 'ServersideDecompress' method decompresses GZIP file
        // [GIVEN] Compressed file "F" (by ServersideCompress)
        CompressedServerFileName := CreateCompressedFile();
        // [WHEN] Decompress file "F" (by ServersideDecompress)
        DecompressedServerFileName := FileMgt.ServerTempFileName('');
        ConfigPckgCompressionMgt.ServersideDecompress(CompressedServerFileName, DecompressedServerFileName);
        // [THEN] decompressed content is equal to the initial content
        Text := ReadTextFromFile(DecompressedServerFileName);
        Assert.IsTrue(Text = FileTextMsg, FileContentMismatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GZIP_DecompressNonGZipFile_FunctionReturnFalse()
    var
        ServerFileName: Text;
        DecompressedServerFileName: Text;
    begin
        // [FEATURE] [GZIP] [UT]
        // [SCENARIO] 'ServersideDecompress' method should fail on attempt to unzip non-GZIP file
        // [GIVEN] Text file "F"
        CreateTextFile(ServerFileName);

        DecompressedServerFileName := FileMgt.ServerTempFileName('');
        // [WHEN] Decompress file "F" (by ServersideDecompress)
        // [THEN] Error message
        Assert.IsFalse(
          ConfigPckgCompressionMgt.ServersideDecompress(ServerFileName, DecompressedServerFileName),
          DecompressWrongResultErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageFromXMLMultiple()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
        PackageCode: Code[20];
    begin
        // [FEATURE] [XML]
        // [SCENARIO] the new Package can be imported from XML for related tables.
        Initialize();
        // [GIVEN] Package with 7 tables
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"VAT Product Posting Group");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"VAT Business Posting Group");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"VAT Posting Setup");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Business Posting Group");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Product Posting Group");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"General Posting Setup");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"G/L Account");
        // [GIVEN] Package exported to XML
        FilePath := FileMgt.ServerTempFileName('xml');
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        if ConfigPackageTable.FindSet() then
            repeat
                ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, FilePath);
            until ConfigPackageTable.Next() = 0;

        PackageCode := ConfigPackage.Code;
        LibraryRapidStart.CleanUp(PackageCode);

        // [WHEN] Import package from XML
        ConfigXMLExchange.ImportPackageXML(FilePath);
        // [THEN] Package contains 7 tables
        ConfigPackage.Get(PackageCode);
        Assert.IsTrue(
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"VAT Product Posting Group") and
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"VAT Business Posting Group") and
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"VAT Posting Setup") and
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Gen. Business Posting Group") and
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Gen. Product Posting Group") and
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"General Posting Setup") and
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"G/L Account"),
          PackageDataErr);

        Erase(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageFromXMLValidate()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageError: Record "Config. Package Error";
        Customer: Record Customer;
        ConfigPackageField: Record "Config. Package Field";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RecRef: RecordRef;
        XMLDocument: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
    begin
        // [SCENARIO] the new Package can be validated with function Validate Table Relation.
        Initialize();
        // [GIVEN] XML file contains Customer data
        XMLDOMManagement.LoadXMLNodeFromText(
          '<?xml version="1.0" encoding="UTF-16" standalone="yes"?><DataList></DataList>', DocumentElement);
        XMLDocument := DocumentElement.OwnerDocument;

        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, false);
        ConfigPackageTable.CalcFields("Table Name");

        LibrarySales.CreateCustomer(Customer);
        RecRef.GetTable(Customer);
        AddConfigPackageTableToXML(XMLDocument, DocumentElement, ConfigPackageTable, RecRef);
        // [GIVEN] PAckage is imported from XML
        ConfigXMLExchange.ImportPackageXMLDocument(XMLDocument, '');

        // [WHEN] Validate table relation
        LibraryRapidStart.ValidatePackage(ConfigPackage, false);
        // [THEN] Config Package Error table is empty
        Assert.IsTrue(ConfigPackageError.IsEmpty, PackageDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageFromXMLApply()
    var
        ConfigPackage: Record "Config. Package";
        Country: Record "Country/Region";
        Location: Record Location;
        CountryCode: Code[10];
        LocationCode: Code[10];
    begin
        // [SCENARIO] Records of package tables imported from XML should be inserted by Apply package
        Initialize();
        // [GIVEN] Import Package from XML, that contains records: Country "C", and Location "L" linked to "C"
        ImportFromXML(ConfigPackage, CountryCode, LocationCode);

        // [GIVEN] Apply Package
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] Country 'C' and Location 'L' exist in database
        Assert.IsTrue(Country.Get(CountryCode) and Location.Get(LocationCode), ApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportAndApplyRSPackage_DataImported()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        PaymentMethod: Record "Payment Method";
        ConfigPackageImport: Codeunit "Config. Package - Import";
        PaymentMethodCode: Code[10];
        FilePath: Text;
        CompressedServerFileName: Text;
    begin
        Initialize();

        CreatePaymentMethod(PaymentMethod);
        PaymentMethodCode := PaymentMethod.Code;

        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Payment Method");
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);

        CompressedServerFileName := FileMgt.ServerTempFileName('');
        ConfigPckgCompressionMgt.ServersideCompress(FilePath, CompressedServerFileName);

        PaymentMethod.Delete();
        Erase(FilePath);

        ConfigPackageImport.ImportAndApplyRapidStartPackage(CompressedServerFileName);

        Assert.IsTrue(
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Payment Method") and
          PaymentMethod.Get(PaymentMethodCode),
          NoDataAfterImportErr);

        PaymentMethod.Delete();
        Erase(CompressedServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageFromXMLKeyApply()
    var
        ConfigPackage: Record "Config. Package";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroupCode: Code[20];
        GenBusPostingGroupCode: Code[20];
    begin
        Initialize();
        ImportFromXMLKey(ConfigPackage, GenProductPostingGroupCode, GenBusPostingGroupCode);

        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        Assert.IsTrue(
          GenBusPostingGroup.Get(GenBusPostingGroupCode) and
          GenProductPostingGroup.Get(GenProductPostingGroupCode) and
          GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProductPostingGroupCode),
          ApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportDataFromXMLValidatedYes()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Location: Record Location;
        PostCode: Record "Post Code";
        LocationCode: Code[20];
        PostCode2: Code[20];
        City2: Text[30];
        FilePath: Text;
    begin
        Initialize();

        // Create new location
        LibraryWarehouse.CreateLocation(Location);
        LibraryERM.CreatePostCode(PostCode);
        Location.City := PostCode.City;
        Location."Post Code" := PostCode.Code;
        Location.Modify();
        LocationCode := Location.Code;
        PostCode2 := Location."Post Code";
        City2 := Location.City;

        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Location);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::Location, Location.FieldNo(Name), true);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::Location, Location.FieldNo("Name 2"), true);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::Location, Location.FieldNo(City), true);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::Location, Location.FieldNo("Post Code"), true);

        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        LibraryRapidStart.CleanUp(ConfigPackage.Code);
        PostCode.Delete();
        Location.Delete();

        ConfigXMLExchange.ImportPackageXML(FilePath);
        LibraryRapidStart.SetValidateOneField(ConfigPackage.Code, DATABASE::Location, Location.FieldNo(City), false);
        LibraryRapidStart.SetValidateOneField(ConfigPackage.Code, DATABASE::Location, Location.FieldNo("Post Code"), false);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        Location.Get(LocationCode);
        Assert.IsTrue(
          (City2 = Location.City) and
          (PostCode2 = Location."Post Code"),
          ErrorInApplyingWithoutValidationFlagErr);

        Erase(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportNormalFieldsOnly()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        AvailableFields: Integer;
    begin
        // [SCENARIO] no FlowFields or FlowFilters are created after import
        Initialize();

        // Package Table Fields are automatically initialized here and contain only normal field class fields and no blobs
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        // Export all package table fields
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::Customer);
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, true);
        AvailableFields := GetNoOfAvailableFields(ConfigPackageTable);

        ExportImportXML(ConfigPackage.Code);

        // Check number of available fields after import
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Customer);
        Assert.AreEqual(AvailableFields, GetNoOfAvailableFields(ConfigPackageTable), FlowFieldAppearedInDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportGenJnlLineAndPost()
    var
        GenJnlLine: Record "Gen. Journal Line";
        ConfigPackage: Record "Config. Package";
        GLAccount: Record "G/L Account";
        PaymentMethod: Record "Payment Method";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        PaymentTerms: Record "Payment Terms";
        DocumentNo: Code[20];
        Amount: Decimal;
        FilePath: Text;
    begin
        Initialize();

        // Init general setup
        CreateGenJnlLineSetup(
          GLAccount,
          PaymentMethod,
          GenBusinessPostingGroup,
          GenProductPostingGroup,
          GeneralPostingSetup,
          VATBusinessPostingGroup,
          VATProductPostingGroup,
          VendorPostingGroup,
          PaymentTerms);

        CreateGenJnlLines(GenJnlLine, Amount, GLAccount."No.", DocumentNo);
        // Export data to XML
        CreateAndExportPackageDataForGenJnlLine(ConfigPackage, FilePath);

        // Delete the created line before import
        GenJnlLine.Delete(true);
        LibraryRapidStart.CleanUp(ConfigPackage.Code);
        // Import created file
        ConfigXMLExchange.ImportPackageXML(FilePath);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        PostGenJnlLines(GLAccount."No.", DocumentNo);

        // Verification
        VerifyGenJnlLineAmount(GenJnlLine."Document Type"::Invoice, DocumentNo, GLAccount."No.", Amount);

        Erase(FilePath);
        CleanupGenJnlSetupData(
          PaymentMethod,
          GenBusinessPostingGroup,
          GenProductPostingGroup,
          GeneralPostingSetup,
          VATBusinessPostingGroup,
          VATProductPostingGroup,
          VendorPostingGroup,
          PaymentTerms);
    end;

    [Test]
    procedure TestExportPackageXMLToStream()
    var
        ConfigPackage: Record "Config. Package";
        DummyRSTable: Record DummyRSTable;
        ConfigPackageTable: Record "Config. Package Table";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        TempBlob: Codeunit "Temp Blob";
        TempBlobInStream: InStream;
        PackageOutStream: OutStream;
        PackageOutput: Text;
        SingleLine: Text;
    begin
        // [SCENARIO] Exporting a package to an OutStream.
        Initialize();

        // [GIVEN] A record of DummyRSTable in the database
        DummyRSTable.DeleteAll();
        DummyRSTable."Entry No." := 1;
        DummyRSTable."Decimal Field" := 3.21;
        DummyRSTable."Date Field" := 20180325D;
        DummyRSTable."Text Field" := 'Lorem ipsum dolor sit amet';
        DummyRSTable.Insert();

        // [GIVEN] Rapidstart package is created from DummyRSTable table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::DummyRSTable);

        // [GIVEN] No other tables are included in the package
        ConfigPackage."Exclude Config. Tables" := true;
        ConfigPackage.Modify();

        // [WHEN] The package is exported
        TempBlob.CreateOutStream(PackageOutStream);
        ConfigXMLExchange.ExportPackageXMLToStream(ConfigPackage, PackageOutStream);

        // [THEN] The content corresponds to the package that was exported
        TempBlob.CreateInStream(TempBlobInStream);
        Assert.AreEqual(1646, TempBlob.Length(), 'Wrong length of the exported package.');
        while not TempBlobInStream.EOS do begin
            TempBlobInStream.Read(SingleLine);
            PackageOutput += SingleLine;
        end;
        Assert.IsSubstring(PackageOutput, '<TableID>136607</TableID>');
        Assert.IsSubstring(PackageOutput, 'Lorem ipsum dolor sit amet');
    end;

    [Test]
    procedure TestImportTextFieldsWith2048Characters()
    var
        ConfigPackage: Record "Config. Package";
        DummyRSTable: Record DummyRSTable;
        ConfigPackageTable: Record "Config. Package Table";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        TempBlob: Codeunit "Temp Blob";
        TempBlobInStream: InStream;
        PackageOutStream: OutStream;
    begin
        // [SCENARIO] Text fields larger than 250 characters are not truncated on import.
        Initialize();

        // [GIVEN] A record of DummyRSTable in the database
        DummyRSTable.DeleteAll();
        DummyRSTable."Entry No." := 1;
        DummyRSTable."Decimal Field" := 3.21;
        DummyRSTable."Date Field" := 20180325D;
        DummyRSTable."Text Field" := 'Lorem ipsum dolor sit amet';
        DummyRSTable."Long Text Field" := GetLongText();
        DummyRSTable.Insert();

        // [GIVEN] Rapidstart package is created from DummyRSTable table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::DummyRSTable);

        // [GIVEN] No other tables are included in the package
        ConfigPackage."Exclude Config. Tables" := true;
        ConfigPackage.Modify();

        // [GIVEN] The package is exported
        TempBlob.CreateOutStream(PackageOutStream);
        ConfigXMLExchange.ExportPackageXMLToStream(ConfigPackage, PackageOutStream);

        // Cleanup before import
        DummyRSTable.DeleteAll();
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        // [WHEN] the rapidstart package is imported and applied
        TempBlob.CreateInStream(TempBlobInStream);
        ConfigXMLExchange.ImportPackageXMLFromStream(TempBlobInStream);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] DummyRSTable records are properly applied
        VerifyDummyRSTableRecords(DummyRSTable);
        // [THEN] The text field with 2048 characters is filled properly
        DummyRSTable.FindFirst();
        Assert.AreEqual(GetLongText(), DummyRSTable."Long Text Field", 'Incorrect content of the long text field.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNoofFields()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        NoOfFields: Integer;
    begin
        // [SCENARIO] The field "No of Fields Included" in Package Table represents the actual data
        Initialize();

        // [GIVEN] Add table Vendor to Package
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Vendor);

        // [WHEN] Select some package fields
        LibraryRapidStart.SetIncludeFields(ConfigPackage.Code, DATABASE::Vendor, 2, 22, true);
        LibraryRapidStart.SetIncludeFields(ConfigPackage.Code, DATABASE::Vendor, 54, 85, true);
        LibraryRapidStart.SetIncludeFields(ConfigPackage.Code, DATABASE::Vendor, 92, 103, true);

        ConfigPackageField.Reset();
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::Vendor);
        ConfigPackageField.SetRange("Include Field", true);
        NoOfFields := ConfigPackageField.Count();

        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Vendor);
        ConfigPackageTable.CalcFields("No. of Fields Included");

        // [THEN] Validate field show correct data
        Assert.AreEqual(NoOfFields, ConfigPackageTable."No. of Fields Included", Text101Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageOverviewPage_DatabaseDataAction()
    var
        ConfigPackageCard: TestPage "Config. Package Card";
        VendorList: TestPage "Vendor List";
    begin
        // Preparation
        Initialize();
        InitializePackageCard(ConfigPackageCard, false);

        // [THEN] Check page Vendor List is opened by Database Records
        VendorList.Trap();
        ConfigPackageCard.Control10.DatabaseRecords.Invoke();
        VendorList.Close();
    end;

    [Test]
    [HandlerFunctions('PackageRecordsPageHandler')]
    [Scope('OnPrem')]
    procedure PackageOverviewPage_PackageDataAction()
    var
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        Initialize();
        InitializePackageCard(ConfigPackageCard, true);

        // [WHEN] Package Records page open
        ConfigPackageCard.Control10.PackageRecords.Invoke();
    end;

    [Test]
    [HandlerFunctions('PackageFieldsPageHandler')]
    [Scope('OnPrem')]
    procedure PackageOverviewPage_PackageFieldsAction()
    var
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        Initialize();
        InitializePackageCard(ConfigPackageCard, true);

        // [WHEN] Package Fields page open
        ConfigPackageCard.Control10.PackageFields.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PackageOverviewPage_ValidateRelationsAction()
    var
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        Initialize();
        InitializePackageCard(ConfigPackageCard, true);

        // [WHEN] Validate relations
        ConfigPackageCard.Control10.ValidateRelations.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Option()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Local Address Format"),
            Format(GLSetup."Local Address Format"::"City+Post Code")) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Option'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Local Address Format"),
            Format(GLSetup."Inv. Rounding Type (LCY)"::Nearest)) = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Option'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Integer()
    var
        GLEntry: Record "G/L Entry";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"G/L Entry", GLEntry.FieldNo("Entry No."), Format(LibraryRandom.RandInt(1000))) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Integer'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"G/L Entry", GLEntry.FieldNo("Entry No."), Format(LibraryRandom.RandDec(1000, 5))) = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Integer'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Decimal()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Inv. Rounding Precision (LCY)"),
            Format(LibraryRandom.RandDec(1000, 5))) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Decimal'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Inv. Rounding Precision (LCY)"), 'WrongDecimal') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Decimal'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Date()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Allow Posting From"), Format(WorkDate())) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Date'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Allow Posting From"), 'WrongDate') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Date'));
    end;

    [Test]
    procedure EvaluateValue_Date_DifferentFormats()
    var
        GLSetup: Record "General Ledger Setup";
        OADateValue: Text;
        CurrentWorkDate: Date;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"General Ledger Setup");
        FieldRef := RecRef.Field(GLSetup.FieldNo("Allow Posting From"));

        CurrentWorkDate := WorkDate();

        // [WHEN] Work date is evaluated to date
        // [THEN] No error is returned
        Assert.AreEqual('', ConfigValidateMgt.EvaluateValue(FieldRef, Format(CurrentWorkDate), false), StrSubstNo(ErrorOnEvaluatingErr, 'Date'));

        // [THEN] The date is as expected
        Assert.AreEqual(FieldRef.Value, CurrentWorkDate, 'Incorrect date has been evaluated.');

        // [WHEN] A text 'WrongDate' is evaluated to a Date
        // [THEN] The expected error text is returned
        Assert.AreEqual('WrongDate is not a valid Date.', ConfigValidateMgt.EvaluateValue(FieldRef, 'WrongDate', false), StrSubstNo(NoErrorOnEvaluatingErr, 'Date'));

        OADateValue := '45012'; // the OADate value for  2023-03-27
        // [WHEN] The date 2023-03-27 in the OADate format is evaluated to date
        // [THEN] No error is returned
        Assert.AreEqual('', ConfigValidateMgt.EvaluateValue(FieldRef, '45012', false), StrSubstNo(ErrorOnEvaluatingErr, 'Date'));

        // [THEN] The date is as expected
        Assert.AreEqual(DMY2DATE(27, 3, 2023), FieldRef.Value, 'Incorrect date has been evaluated.');

        // [WHEN] The date 01.01.2022 is evaluated to date
        // [THEN] No error is returned
        Assert.AreEqual('', ConfigValidateMgt.EvaluateValue(FieldRef, '01.01.2022', false), StrSubstNo(ErrorOnEvaluatingErr, 'Date'));

        // [THEN] The date is as expected
        Assert.AreEqual(DMY2DATE(1, 1, 2022), FieldRef.Value, 'Incorrect date has been evaluated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Time()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo(Time), Format(Time)) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Time'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo(Time), 'WrongTime') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Time'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_DateTime()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Date and Time"), Format(CurrentDateTime)) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'DateTime'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Date and Time"), 'WrongDateTime') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'DateTime'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Boolean()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Register Time"), Format(false)) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Boolean'));
        Assert.IsTrue(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Register Time"), Format(true)) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Boolean'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Register Time"), 'Maybe') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Boolean'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_BigInteger()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Entry No."),
            Format(LibraryRandom.RandInt(1000))) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'BigInteger'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Entry No."), 'WrongBigInteger') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'BigInteger'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_GUID()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"Job Queue Entry", JobQueueEntry.FieldNo(ID), Format(CreateGuid())) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'GUID'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"Job Queue Entry", JobQueueEntry.FieldNo(ID), 'WrongGuid') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'GUID'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Code()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Bank Account Nos."), GLSetup."Bank Account Nos.") = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Code'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Bank Account Nos."), 'TooLongCode0123456789') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Code'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Text()
    var
        GLEntry: Record "G/L Entry";
        LongText: Text[250];
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"G/L Entry", GLEntry.FieldNo(Description), 'Test text') = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Text'));

        LongText := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description) + 1), 1, MaxStrLen(LongText));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"G/L Entry", GLEntry.FieldNo(Description), LongText) = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Text'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_DateFormula()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Payment Discount Grace Period"), '+1Y') = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'DateFormula'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"General Ledger Setup", GLSetup.FieldNo("Payment Discount Grace Period"),
            'Long Long Time Ago In a galaxy far away') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'DateFormula'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_Duration()
    var
        ToDo: Record "To-do";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"To-do", ToDo.FieldNo(Duration), Format(CurrentDateTime - CreateDateTime(WorkDate() - 1, Time))) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'Duration'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"To-do", ToDo.FieldNo(Duration), 'WrongDuration') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'Duration'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateValue_RecordID()
    var
        GLSetup: Record "General Ledger Setup";
        ChangeLogEntry: Record "Change Log Entry";
    begin
        Assert.IsTrue(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Record ID"), Format(GLSetup.RECORDID)) = '',
          StrSubstNo(ErrorOnEvaluatingErr, 'RecordID'));
        Assert.IsFalse(
          EvaluateValue(DATABASE::"Change Log Entry", ChangeLogEntry.FieldNo("Record ID"), 'WrongRecordID') = '',
          StrSubstNo(NoErrorOnEvaluatingErr, 'RecordID'));
    end;


    [Test]
    [Scope('OnPrem')]
    procedure PackageCardDatabaseRecords()
    var
        PaymentMethod: Record "Payment Method";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageCard: TestPage "Config. Package Card";
        I: Integer;
    begin
        Initialize();

        // Create several database records
        for I := 1 to 3 do
            CreatePaymentMethod(PaymentMethod);

        Commit();

        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Payment Method");
        ConfigPackageCard.OpenView();
        ConfigPackageCard.GotoRecord(ConfigPackage);
        ConfigPackageCard.Control10.First();

        Assert.AreEqual(
          Format(PaymentMethod.Count),
          ConfigPackageCard.Control10.NoOfDatabaseRecords.Value,
          StrSubstNo(FieldValueIsIncorrectErr, ConfigPackageCard.Control10.NoOfDatabaseRecords.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PackageCardPackageCreation()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageCard: TestPage "Config. Package Card";
        TableID: Integer;
    begin
        // [SCENARIO] package can be created from the package card page
        ConfigPackageCard.OpenNew();
        ConfigPackageCard.Code.SetValue(LibraryUtility.GenerateRandomCode(ConfigPackage.FieldNo(Code), DATABASE::"Config. Package"));
        ConfigPackageCard."Package Name".SetValue(ConfigPackageCard.Code);
        ConfigPackageCard."Language ID".SetValue(FindFirstLanguage());

        TableID := FindRandomTableID(100);
        ConfigPackageCard.Control10.New();
        ConfigPackageCard.Control10."Table ID".SetValue(TableID);
        // Verify that the table ID is validated
        Assert.AreEqual(GetTableName(TableID), ConfigPackageCard.Control10."Table Name".Value, TableNotValidatedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ExportImportStructuredPackageWithDimAsCol()
    var
        ConfigPackage: Record "Config. Package";
        ConfigLine: Record "Config. Line";
        PackageCode: Code[20];
    begin
        // [SCENARIO 333276] Export/Import package with structured config. lines with Dim As Columns in additional area
        HideDialog();

        CreateConfigPackage(ConfigPackage);
        PackageCode := ConfigPackage.Code;

        FillInWorksheet(PackageCode);

        // EXECUTE
        ExportImportXML(PackageCode);

        // VERIFY that last config line has correct Table ID value
        ConfigLine.SetRange("Package Code", PackageCode);
        ConfigLine.FindLast();
        Assert.AreEqual(DATABASE::Customer, ConfigLine."Table ID", StrSubstNo(ValueIsIncorrectErr, ConfigLine.FieldName("Table ID")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportPackageWithMultilineConfigTemplate()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTemplateHeaderCode: Code[10];
    begin
        // [SCENARIO 101422] TestHierarchy function of Config Template should work successfully when importing multiple lines from package.

        // [GIVEN] Create package with multiline configuration template.
        Initialize();
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Config. Template Line");
        ConfigTemplateHeaderCode := CreateConfigTemplateWithMultipleLines();

        // [WHEN] Export package, cleanup all packages and templates and import package?
        ExportImportXMLWithPackageAndTemplateCleanup(ConfigPackage.Code, ConfigTemplateHeaderCode);

        // [THEN] Check that there are no errors of import.
        ConfigPackage.CalcFields("No. of Errors");
        Assert.AreEqual(0, ConfigPackage."No. of Errors", StrSubstNo(PackageErr, ConfigPackage.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ExportImportPackageWithAutoIncrementFieldMarkedAsPK()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageTable: Record "Config. Package Table";
        DimensionSetTreeNode: array[2] of Record "Dimension Set Tree Node";
    begin
        // [FEATURE] [Apply] [Primary Key] [AutoIncrement]
        // [SCENARIO] The exported AutoIncrement field marked as "Primary Key" member should be imported and applied
        Initialize();
        // [GIVEN] Dimension Set Tree Node, where (AutoIncrement) "Dimension Set ID"  = 3
        DimensionSetTreeNode[1].DeleteAll();
        DimensionSetTreeNode[1].Init();
        DimensionSetTreeNode[1]."Parent Dimension Set ID" := 1;
        DimensionSetTreeNode[1]."Dimension Value ID" := 2;
        DimensionSetTreeNode[1]."Dimension Set ID" := 3;
        DimensionSetTreeNode[1]."In Use" := true;
        DimensionSetTreeNode[1].Insert();

        // [GIVEN] Config package for table 481 "Dimension Set Tree Node"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Dimension Set Tree Node");
        ConfigPackage."Exclude Config. Tables" := true;
        ConfigPackage.Modify();
        // [GIVEN] Field "Dimension Set ID" is marked as "Primary Key" (though it is not in PK actually)
        ConfigPackageField.Get(
          ConfigPackage.Code, DATABASE::"Dimension Set Tree Node", DimensionSetTreeNode[1].FieldNo("Dimension Set ID"));
        ConfigPackageField."Primary Key" := true;
        ConfigPackageField.Modify();

        // [GIVEN] Export/Import the package
        ExportImportXML(ConfigPackage.Code);
        // [GIVEN] Dimension Set Tree Node is deleted
        DimensionSetTreeNode[2].DeleteAll();

        // [WHEN] Apply the package
        LibraryRapidStart.ApplyPackage(ConfigPackage, false);

        // [THEN] Dimension Set Tree Node is restored, without errors
        Assert.RecordCount(DimensionSetTreeNode[2], 1);
        DimensionSetTreeNode[2].FindFirst();
        DimensionSetTreeNode[2].TestField("Parent Dimension Set ID", DimensionSetTreeNode[1]."Parent Dimension Set ID");
        DimensionSetTreeNode[2].TestField("Dimension Value ID", DimensionSetTreeNode[1]."Dimension Value ID");
        DimensionSetTreeNode[2].TestField("Dimension Set ID", DimensionSetTreeNode[1]."Dimension Set ID");
        DimensionSetTreeNode[2].TestField("In Use", DimensionSetTreeNode[1]."In Use");
    end;

    [Test]
    [HandlerFunctions('CheckProcessingOrderPackageFieldsPageHandler')]
    [Scope('OnPrem')]
    procedure ProcessingOrderAfterAddTableField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [SCENARIO 371875] Config. Package Fields Processing Order after adding a Field
        Initialize();

        // [GIVEN] Config Package with Table "X" and "Z" fields
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Payment Method");
        ConfigPackageTable.CalcFields("No. of Fields Included");
        LibraryVariableStorage.Enqueue(ConfigPackageTable."No. of Fields Included");

        // [GIVEN] New field added to the Table "X"
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::"Payment Method");
        ConfigPackageField.FindLast();
        ConfigPackageField.Delete();

        // [WHEN] Package Fields page is opened
        ConfigPackageCard.OpenView();
        ConfigPackageCard.GotoRecord(ConfigPackage);
        ConfigPackageCard.Control10.First();
        ConfigPackageCard.Control10.PackageFields.Invoke();

        // [THEN] Processing Order for all fields begins from 1 and ends with "Z" + 1
    end;

    [Scope('OnPrem')]
    procedure EvaluateValue_DateTimeInOADateFormat()
    var
        PositivePayEntry: Record "Positive Pay Entry";
        DateTime: DateTime;
        OADate: Integer;
        OATime: Decimal;
        NowTime: Time;
        NowDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376593] RapidStart correctly processes Date and Time values in OADate format

        // [GIVEN] Current Date = 30/10/15 and Time = 15:32:57 in OADate format (42307 and 0,6478819444)
        DateTime := CreateDateTime(Today, Time);
        DateTime := RoundDateTime(DateTime, 1000, '<'); // rounding to avoid milliseconds
        NowDate := DT2Date(DateTime);
        NowTime := DT2Time(DateTime);
        GetOADateTime(DateTime, OADate, OATime);

        // [WHEN] RapidStart evaluates Date and Time in OADate format
        EvaluateDateTimeValue(
          DATABASE::"Positive Pay Entry", PositivePayEntry.FieldNo("Last Upload Date"),
          PositivePayEntry.FieldNo("Last Upload Time"), Format(OADate), Format(OATime), NowDate, NowTime);
        // [THEN] Fields values of Date = 30/10/15, Time = 15:32:57
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcelNotExistingPackageFromListPage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Currency: Record Currency;
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigPackages: TestPage "Config. Packages";
        PackageCode: Code[20];
    begin
        // [FEATURE] [Excel] [UI]
        // [SCENARIO 379003] Import from Excel (ran from the list page) creates not existing package and table lines.
        Initialize();

        // [GIVEN] Config package "A" for table 'Currency'
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Currency);
        // [GIVEN] Export "A" to Excel
        ExportToExcel(ConfigPackageTable);
        // [GIVEN] Rename the package 'A' to 'XA'
        PackageCode := ConfigPackage.Code;
        ConfigPackage.Rename('X' + ConfigPackage.Code);
        // [GIVEN] Open "Config. Packages" list page on 'XA'
        ConfigPackages.OpenView();
        ConfigPackages.FILTER.SetFilter(Code, ConfigPackage.Code);

        // [WHEN] Run action "Import From Excel" on package list page
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        LibraryVariableStorage.Enqueue(1); // expected numer of sheets in Excel for ExcelImportPreviewHandler
        ConfigPackages.ImportFromExcel.Invoke();

        // [THEN] Page "Config. Package Import Preview" is open, where is one line: "Package Code" is 'A', "Table ID" is 4, "Table Name" is 'Currency'
        Assert.AreEqual(PackageCode, LibraryVariableStorage.DequeueText(), 'wrong package code in preview'); // from ExcelImportPreviewHandler
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'new package');
        Assert.AreEqual(DATABASE::Currency, LibraryVariableStorage.DequeueInteger(), 'wrong package code in preview');
        Assert.AreEqual(Currency.TableCaption(), LibraryVariableStorage.DequeueText(), 'wrong table name in preview');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'new table');
        // [WHEN] Run "Import" action
        // [THEN] Config. Package 'XA' does exist with table 'Currency'
        Assert.IsTrue(ConfigPackage.FindFirst(), 'renamed package is not found');
        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Currency), 'renamed package does not include Currency table');
        // [THEN] Config. Package 'A' does exist, where is table 'Currency'
        Assert.IsTrue(ConfigPackage.Get(PackageCode), 'new package is not created');
        Assert.IsTrue(ConfigPackageTable.Get(PackageCode, DATABASE::Currency), 'new package does not include Currency table');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcelExistingPackageFromCardPage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigPackageCard: TestPage "Config. Package Card";
    begin
        // [FEATURE] [Excel] [UI]
        // [SCENARIO 379003] Import from Excel (ran from the card page) updates an existing package and creates missing table lines.
        Initialize();

        // [GIVEN] Config package "A" for tables 'Currency', 'Country\Region'
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Currency);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Country/Region");

        // [GIVEN] Export "A" to Excel
        ExportToExcelFullPackage(ConfigPackageTable);
        // [GIVEN] Removed package table 'Country\Region'
        ConfigPackageTable.Delete();

        // [GIVEN] Open "Config. Package Card" page on 'A'
        ConfigPackageCard.OpenView();
        ConfigPackageCard.FILTER.SetFilter(Code, ConfigPackage.Code);

        // [WHEN] Run action "Import From Excel" on package card page
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        LibraryVariableStorage.Enqueue(2); // expected numer of sheets in Excel for ExcelImportPreviewHandler
        ConfigPackageCard.ImportFromExcel.Invoke();

        // [THEN] Page "Config. Package Import Preview" is open, where are two lines:
        // [THEN] The first one, where "Package Code" is 'A', "Table ID" is 4, "Table Name" is 'Currency','New Package' and 'New Table' are 'No'
        Assert.AreEqual(ConfigPackage.Code, LibraryVariableStorage.DequeueText(), 'wrong package code in preview #1'); // from ExcelImportPreviewHandler
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'new package #1');
        Assert.AreEqual(DATABASE::Currency, LibraryVariableStorage.DequeueInteger(), 'wrong package code in preview #1');
        Assert.AreEqual(Currency.TableCaption(), LibraryVariableStorage.DequeueText(), 'wrong table name in preview #1');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'new table #1');
        // [THEN] The first one, where "Package Code" is 'A', "Table ID" is 9, "Table Name" is 'Country\Region','New Package' is 'No','New Table' is 'Yes'
        Assert.AreEqual(ConfigPackage.Code, LibraryVariableStorage.DequeueText(), 'wrong package code in preview #2'); // from ExcelImportPreviewHandler
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'new package #2');
        Assert.AreEqual(DATABASE::"Country/Region", LibraryVariableStorage.DequeueInteger(), 'wrong package code in preview #2');
        Assert.AreEqual(CountryRegion.TableCaption(), LibraryVariableStorage.DequeueText(), 'wrong table name in preview #2');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'new table #2');
        // [WHEN] Run "Import" action
        // [THEN] Config. Package 'A' does exist, where are tables 'Currency', 'Country\Region'
        Assert.IsTrue(ConfigPackage.FindFirst(), 'package does not exist');
        Assert.IsTrue(ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::Currency), 'package does not include Currency table');
        Assert.IsTrue(
          ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Country/Region"), 'package does not include Country\Region table');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewSimpleHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcelPackageCodeMustMatchInExcelFromCardPage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigPackageCard: TestPage "Config. Package Card";
        PackageCode: array[2] of Code[20];
    begin
        // [FEATURE] [Excel] [UI]
        // [SCENARIO 379003] Import from Excel (ran from the card page) should fail if package code does not match the code in the excel file.
        Initialize();

        // [GIVEN] Config package "A" for tables 'Currency'
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Currency);
        // [GIVEN] Export "A" to Excel
        ExportToExcelFullPackage(ConfigPackageTable);

        // [GIVEN] Rename the package 'A' to 'XA'
        PackageCode[1] := ConfigPackage.Code;
        PackageCode[2] := CopyStr('X' + ConfigPackage.Code, 1, 20);
        ConfigPackage.Rename(PackageCode[2]);

        // [GIVEN] Open "Config. Package Card" page on 'XA'
        ConfigPackageCard.OpenView();
        ConfigPackageCard.Filter.SetFilter(Code, PackageCode[2]);

        // [WHEN] Run action "Import From Excel" on package card page
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        asserterror ConfigPackageCard.ImportFromExcel.Invoke();

        // [THEN] Error message: 'The package code in all sheets of the excel file must match the selected package code XA'
        Assert.ExpectedError(StrSubstNo(PackageCodeMustMatchErr, PackageCode[2]));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcelExistingPackageFromCardSubpage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        CountryRegion: Record "Country/Region";
        PaymentTerms: Record "Payment Terms";
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigPackageCard: TestPage "Config. Package Card";
        ExpectedCountryRegionCount: Integer;
    begin
        // [FEATURE] [Excel] [UI]
        // [SCENARIO 379003] Import from Excel (ran from the table subpage) updates the selected table lines.
        Initialize();

        // [GIVEN] Config package "A" for tables 'Payment Terms', 'Country\Region'
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Payment Terms");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Country/Region");

        // [GIVEN] Export "A" to Excel
        ExportToExcelFullPackage(ConfigPackageTable);

        // [GIVEN] 'Currency' and 'Country/Region' tables are empty
        ExpectedCountryRegionCount := CountryRegion.Count();
        CountryRegion.DeleteAll();
        PaymentTerms.DeleteAll();

        // [GIVEN] Open "Config. Packages" list page on 'A'
        ConfigPackageCard.OpenView();
        ConfigPackageCard.FILTER.SetFilter(Code, ConfigPackage.Code);

        // [WHEN] Run action "Import From Excel" on table subpage for the table 9.
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        LibraryVariableStorage.Enqueue(1); // expected numer of sheets in Excel for ExcelImportPreviewHandler
        ConfigPackageCard.Control10.Last();
        ConfigPackageCard.Control10.ImportFromExcel.Invoke();

        // [THEN] Page "Config. Package Import Preview" is open, where is one line,
        // [THEN] where "Package Code" is 'A', "Table ID" is 9, "Table Name" is 'Country\Region','New Package' is 'No','New Table' is 'No'
        Assert.AreEqual(ConfigPackage.Code, LibraryVariableStorage.DequeueText(), 'wrong package code in preview'); // from ExcelImportPreviewHandler
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'new package');
        Assert.AreEqual(DATABASE::"Country/Region", LibraryVariableStorage.DequeueInteger(), 'wrong package code in preview');
        Assert.AreEqual(CountryRegion.TableCaption(), LibraryVariableStorage.DequeueText(), 'wrong table name in preview');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'new table');
        // [WHEN] Run "Import" action
        // [THEN] 'Country/Region' table data is imported, 'Payment Terms' table is empty
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Payment Terms");
        ConfigPackageTable.CalcFields("No. of Package Records");
        ConfigPackageTable.TestField("No. of Package Records", 0);
        ConfigPackageTable.Get(ConfigPackage.Code, DATABASE::"Country/Region");
        ConfigPackageTable.CalcFields("No. of Package Records");
        ConfigPackageTable.TestField("No. of Package Records", ExpectedCountryRegionCount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPreviewShowsMultipleMarkedTables()
    var
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageImportPreview: Page "Config. Package Import Preview";
        ConfigPackageImportPreviewPage: TestPage "Config. Package Import Preview";
    begin
        // [FEATURE] [Excel] [UI] [UT]
        TempConfigPackageTable.Init();
        TempConfigPackageTable."Table ID" := DATABASE::"Payment Terms";
        TempConfigPackageTable.Insert();
        TempConfigPackageTable."Table ID" := DATABASE::"G/L Entry";
        TempConfigPackageTable.Insert();
        // [WHEN] Open ConfigPackageImportPreview page, where are 2 table lines
        ConfigPackageImportPreviewPage.Trap();
        ConfigPackageImportPreview.SetData('', TempConfigPackageTable);
        ConfigPackageImportPreview.Run();

        // [THEN] Action "Import" is enabled
        Assert.IsTrue(ConfigPackageImportPreviewPage.Import.Enabled(), 'Import should be enabled');
        ConfigPackageImportPreviewPage.First();
        ConfigPackageImportPreviewPage."Table ID".AssertEquals(3);
        ConfigPackageImportPreviewPage.Next();
        ConfigPackageImportPreviewPage."Table ID".AssertEquals(17);
        Assert.IsFalse(ConfigPackageImportPreviewPage.Next(), 'must be 2 lines');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPreviewDisabledImportIfNoTables()
    var
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageImportPreview: Page "Config. Package Import Preview";
        ConfigPackageImportPreviewPage: TestPage "Config. Package Import Preview";
    begin
        // [FEATURE] [Excel] [UI] [UT]
        TempConfigPackageTable.DeleteAll();
        // [WHEN] Open ConfigPackageImportPreview page, where are no table lines
        ConfigPackageImportPreviewPage.Trap();
        ConfigPackageImportPreview.SetData('', TempConfigPackageTable);
        ConfigPackageImportPreview.Run();

        // [THEN] Action "Import" is disabled
        Assert.IsFalse(ConfigPackageImportPreviewPage.Import.Enabled(), 'Import should be disabled');
        Assert.IsFalse(ConfigPackageImportPreviewPage.First(), 'must be empty list');
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcelBlobField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigPackageCard: TestPage "Config. Package Card";
        OriginalWorkDescription: Text;
    begin
        // [FEATURE] [Excel] [UI]
        // [SCENARIO] Blob fields are imported as configured.
        Initialize();

        // [GIVEN] Sales Header with non-blank "Work Description" field exists
        CreateSalesOrderWithWorkDescription(SalesHeader);
        OriginalWorkDescription := SalesHeader.GetWorkDescription();

        // [GIVEN] Config package "A" for table "Sales Header"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, Database::"Sales Header");

        // [GIVEN] All fields except PK fields and "Work Description" are excluded from export
        LibraryRapidStart.SetIncludeAllFields(ConfigPackage.Code, Database::"Sales Header", false);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, Database::"Sales Header", SalesHeader.FieldNo("Work Description"), true);

        // [GIVEN] Package "A" is exported to Excel
        Commit();
        ExportToExcel(ConfigPackageTable);

        // [GIVEN] "Work Description" field is set to different value
        SalesHeader.Find();
        SalesHeader.SetWorkDescription(LibraryRandom.RandText(MaxStrLen(SalesHeader."Sell-to Customer No.")));
        SalesHeader.Modify();

        // [GIVEN] Open "Config. Package Card" page on 'A'
        ConfigPackageCard.OpenView();
        ConfigPackageCard.Filter.SetFilter(Code, ConfigPackage.Code);

        // [WHEN] Run action "Import From Excel" on package card page
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        LibraryVariableStorage.Enqueue(1); // expected numer of sheets in Excel for ExcelImportPreviewHandler
        ConfigPackageCard.ImportFromExcel.Invoke();

        // [THEN] Imported package contains exported work description
        SalesHeader.SetRecFilter();
        VerifyConfigPackageDataBLOBValuesFromExcel(ConfigPackage.Code, SalesHeader, OriginalWorkDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportToExcelCustomProcessingOrderedPackageField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        Currency: Record Currency;
    begin
        // [FEATURE] [Excel]
        // [SCENARIO 379003] Configuration package table takes into account settings of "Processing Order" value of related configuration package fields on exporting to excel.
        Initialize();
        Currency.FindFirst();

        // [GIVEN] Config package "A" for table "Currency"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Currency);

        // [GIVEN] "Config. Package Field"."Processing Order" for "Description" field changed from 12 (default) to 1
        // [GIVEN] "Config. Package Field"."Processing Order" for "Code" field changed from 1 (default) to 12
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Table ID", DATABASE::Currency);
        SetConfigPackageFieldProcessingOrder(
          ConfigPackageField, Currency.FieldNo(Code), 12);
        SetConfigPackageFieldProcessingOrder(
          ConfigPackageField, Currency.FieldNo(Description), 1);

        // [WHEN] Export "A" to Excel
        Commit();
        ExportToExcel(ConfigPackageTable);

        // [THEN] Field "Description" exported into first ('A') column
        // [THEN] Field "Code" exported into 12th ('L') column
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('A', 3, 1, Currency.FieldCaption(Description));
        LibraryReportValidation.VerifyCellValueByRef('L', 3, 1, Currency.FieldCaption(Code));
        LibraryReportValidation.VerifyCellValueByRef('A', 4, 1, Currency.Description);
        LibraryReportValidation.VerifyCellValueByRef('L', 4, 1, Currency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportToExcelBlobField()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        SalesHeader: Record "Sales Header";
        Base64Convert: Codeunit "Base64 Convert";
        WorkDescription: Text;
        LineCounter: Integer;
        InStream: InStream;
    begin
        // [FEATURE] [Excel]
        // [SCENARIO] Blob fields are exported to Excel as configured.
        Initialize();

        // [GIVEN] Sales Header with non-blank "Work Description" field exists
        CreateSalesOrderWithWorkDescription(SalesHeader);

        // [GIVEN] Config package "A" for table "Sales Header"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, Database::"Sales Header");

        // [GIVEN] All fields except PK fields and "Work Description" are excluded from export
        LibraryRapidStart.SetIncludeAllFields(ConfigPackage.Code, Database::"Sales Header", false);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, Database::"Sales Header", SalesHeader.FieldNo("Work Description"), true);

        // [WHEN] Export "A" to Excel
        Commit();
        ExportToExcel(ConfigPackageTable);

        // [THEN] PK fields are first two columns in Excel
        // [THEN] Work Description is exported into third column
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('A', 3, 1, SalesHeader.FieldCaption("Document Type"));
        LibraryReportValidation.VerifyCellValueByRef('B', 3, 1, SalesHeader.FieldCaption("No."));
        LibraryReportValidation.VerifyCellValueByRef('C', 3, 1, SalesHeader.FieldCaption("Work Description"));

        Clear(SalesHeader);
        LineCounter := 4;
        if SalesHeader.FindSet() then
            repeat
                LibraryReportValidation.VerifyCellValueByRef('A', LineCounter, 1, Format(SalesHeader."Document Type"));
                LibraryReportValidation.VerifyCellValueByRef('B', LineCounter, 1, SalesHeader."No.");
                SalesHeader.CalcFields("Work Description");
                SalesHeader."Work Description".CreateInStream(InStream, TextEncoding::UTF8);
                InStream.Read(WorkDescription);
                if WorkDescription <> '' then
                    LibraryReportValidation.VerifyCellValueByRef('C', LineCounter, 1, Base64Convert.ToBase64(WorkDescription, TextEncoding::UTF8));
                LineCounter += 1;
            until SalesHeader.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageWithNonExistingTable()
    var
        ConfigPackageError: Record "Config. Package Error";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocument: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
        TableID: Integer;
        TextXMLPackage: Text;
        PackageCode: Code[20];
    begin
        // [SCENARIO 380200] Importing of Package with non existing table does not break import process, but creates Package Error
        // [FEATURE] [UT]

        // [GIVEN] Package "PACK01" with non existing table "-452"
        PackageCode := 'PACK01';
        TableID := -452;
        TextXMLPackage :=
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-16" standalone="yes"?>' +
            '<DataList LanguageID="1033" ProductVersion="NAV 7.1" PackageName="Tables" Code="%1">' +
            '<ApprovalSetupList><TableID>%2</TableID></ApprovalSetupList></DataList>',
            PackageCode,
            TableID);
        XMLDOMManagement.LoadXMLNodeFromText(TextXMLPackage, DocumentElement);
        XMLDocument := DocumentElement.OwnerDocument;

        // [WHEN] Importing "PACK01"
        // [THEN] Package imported
        ConfigXMLExchange.ImportPackageXMLDocument(XMLDocument, '');

        // [THEN] A config. package error is created for "PACK01" informing that table "-452" does not exists
        ConfigPackageError.SetRange("Package Code", PackageCode);
        ConfigPackageError.FindFirst();
        ConfigPackageError.TestField("Table ID", TableID);
        ConfigPackageError.TestField("Error Text", StrSubstNo(PackageImportErr, TableID));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetNoOfDatabaseRecordsWhenTableIDIsZero()
    var
        DummyConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ProcedureResult: Integer;
    begin
        // [SCENARIO 380200] GetNoOfDatabaseRecords returns 0 if "Table ID" is 0
        // [FEATURE] [UT]

        ConfigPackageTable.Init();
        ConfigPackageTable."Package Code" := DummyConfigPackage.Code;
        ConfigPackageTable."Table ID" := 0;
        ProcedureResult := ConfigPackageTable.GetNoOfDatabaseRecords();
        Assert.AreEqual(0, ProcedureResult, 'GetNoOfDatabaseRecords result must be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetNoOfDatabaseRecordsWhenTableIDExists()
    var
        "Area": Record "Area";
        DummyConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ProcedureResult: Integer;
    begin
        // [SCENARIO 380200] GetNoOfDatabaseRecords returns count of records for an existing table ID
        // [FEATURE] [UT]

        Area.DeleteAll();
        Area.Init();
        Area.Insert();

        CreatePackageWithTable(DummyConfigPackage, ConfigPackageTable, DATABASE::Area);
        ProcedureResult := ConfigPackageTable.GetNoOfDatabaseRecords();
        Assert.AreEqual(1, ProcedureResult, 'GetNoOfDatabaseRecords result must be 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetNoOfDatabaseRecordsWhenTableIDNotExists()
    var
        DummyConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ProcedureResult: Integer;
    begin
        // [SCENARIO 380200] GetNoOfDatabaseRecords returns 0 for a non-existing table ID
        // [FEATURE] [UT]

        ConfigPackageTable.Init();
        ConfigPackageTable."Package Code" := DummyConfigPackage.Code;
        ConfigPackageTable."Table ID" := -452;
        ProcedureResult := ConfigPackageTable.GetNoOfDatabaseRecords();
        Assert.AreEqual(0, ProcedureResult, 'GetNoOfDatabaseRecords result must be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackage_ImportCreateMissingCodesValueInFieldPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        Customer: Record Customer;
        FieldNo1: Integer;
        FieldNo2: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382272] Import Config Package should save the "Create Missing Codes" package field value
        Initialize();

        // [GIVEN] Config Package for Customer
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);

        // [GIVEN] Config Package Field setup for Customer.City and Customer."Territory Code"
        FieldNo1 := Customer.FieldNo(City);
        FieldNo2 := Customer.FieldNo("Territory Code");
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::Customer, FieldNo1, true);
        LibraryRapidStart.SetIncludeOneField(ConfigPackage.Code, DATABASE::Customer, FieldNo2, true);

        // [GIVEN] Customer.City field setup "Create Missing Codes" set to TRUE
        LibraryRapidStart.SetCreateMissingCodesForField(ConfigPackage.Code, DATABASE::Customer, FieldNo1, true);
        // [GIVEN] Customer."Territory Code" field setup "Create Missing Codes" set to FALSE
        LibraryRapidStart.SetCreateMissingCodesForField(ConfigPackage.Code, DATABASE::Customer, FieldNo2, false);

        // [WHEN] Import Config Package
        ExportImportXML(ConfigPackage.Code);

        // [THEN] Customer.City field setup "Create Missing Codes" is TRUE
        ConfigPackageField.Get(ConfigPackage.Code, DATABASE::Customer, FieldNo1);
        ConfigPackageField.TestField("Create Missing Codes", true);

        // [THEN] Customer."Territory Code" field setup "Create Missing Codes" is FALSE
        ConfigPackageField.Get(ConfigPackage.Code, DATABASE::Customer, FieldNo2);
        ConfigPackageField.TestField("Create Missing Codes", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShopCalendarWorkingDaysImportIdentical()
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ConfigPackage: Record "Config. Package";
    begin
        // [FEATURE] [Shop Calendar]
        // [SCENARIO 234987] When import the same "Shop Calendar Working Days" as existing no errors occur.
        Initialize();

        // [GIVEN] Populated "Shop Calendar Working Days" table "T"
        CreateShopCalendarWithWorkingDays(ShopCalendarWorkingDays, 080000T, 160000T);

        // [GIVEN] Configuration package "P" with the data identical to the data of "T"
        CreateShopCalendarWorkingDaysPackage(ConfigPackage);
        CreateShopCalendarWorkingDaysPackageData(ShopCalendarWorkingDays, ConfigPackage.Code, 0);

        // [WHEN] Apply the package "P" to "T"
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] No errors occur
        VerifyNoConfigPackageErrors(ConfigPackage.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShopCalendarWorkingDaysImportWithRedundancy()
    var
        ConfigPackage: Record "Config. Package";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        // [FEATURE] [Shop Calendar]
        // [SCENARIO 234987] When import the same "Shop Calendar Working Days" with redundancy the import error occurs.
        Initialize();

        // [GIVEN] Populated "Shop Calendar Working Days" table "T"
        CreateShopCalendarWithWorkingDays(ShopCalendarWorkingDays, 080000T, 160000T);

        // [GIVEN] Configuration package "P" with the data distinct of the data of "T" and causing the error "There is redundancy in the Shop Calendar."
        CreateShopCalendarWorkingDaysPackage(ConfigPackage);
        CreateShopCalendarWorkingDaysPackageData(ShopCalendarWorkingDays, ConfigPackage.Code, 60 * 60 * 1000);

        // [WHEN] Apply the package "P" to "T"
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] The error "There is redundancy in the Shop Calendar." occurs.
        VerifyConfigPackageError(
          ConfigPackage.Code, DATABASE::"Shop Calendar Working Days", ShopCalendarWorkingDays.FieldNo("Starting Time"),
          RedundancyInTheShopCalendarErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShopCalendarWorkingDaysImportNotOverlappingPackage()
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ConfigPackage: Record "Config. Package";
    begin
        // [FEATURE] [Shop Calendar]
        // [SCENARIO 234987] When import the same "Shop Calendar Working Days" and target table does not contain overlapping data no errors occur.
        Initialize();

        // [GIVEN] "Shop Calendar Working Days" table "T" with "Shop Calendar Code" "S" and "Work Shift Code" "W" and Days from Monday to Friday
        CreateShopCalendarWithWorkingDays(ShopCalendarWorkingDays, 080000T, 160000T);

        // [GIVEN] Configuration package "P" with Days from Monday to Friday, "Shop Calendar Code" and "Work Shift Code" are different from "S" and "W"
        CreateShopCalendarWithWorkingDays(ShopCalendarWorkingDays, 080000T, 160000T);
        CreateShopCalendarWorkingDaysPackage(ConfigPackage);
        CreateShopCalendarWorkingDaysPackageData(ShopCalendarWorkingDays, ConfigPackage.Code, 0);
        DeleteShopCalendarRelatedData(ShopCalendarWorkingDays);

        // [WHEN] Apply the package "P" to "T"
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] No errors occur and "T" contains also data of "P"
        VerifyNoConfigPackageErrors(ConfigPackage.Code);
        VerifyFiveDaysShopCalendar(ShopCalendarWorkingDays, 080000T, 160000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPackageWithoutConfigMediaBufferTable()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DummyFilePath: Text;
    begin
        // [SCENARIO 272396] "Config. XML Exchange".ExportPackageXMLDocument doesn't add "Config. Media Buffer" to RapidStart package if Media folder is empty
        Initialize();

        // [GIVEN] RapidStart package with "Config. Package Table"
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, FindRandomTableID(100));

        // [WHEN] Exporting the RapidStart package
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, DummyFilePath);

        // [THEN] The RapidStart package doesn't contain "Config. Package Table" for table "Config. Media Buffer"
        Clear(ConfigPackageTable);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetRange("Table ID", DATABASE::"Config. Media Buffer");
        Assert.RecordCount(ConfigPackageTable, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankOptionValueEvaluatedToDefault()
    var
        JobQueueEntry: Record "Job Queue Entry";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 275495] Blank option value assigned to a table field from a Rapid Start package is evaluated to the default option value
        Initialize();

        // [GIVEN] Field "Object Type to Run" in the "Job Queue Entry" has several blanked option values: ,,,Report,,Codeunit. "InitValue" value is "Report"
        RecRef.Open(DATABASE::"Job Queue Entry");
        FieldRef := RecRef.Field(JobQueueEntry.FieldNo("Object Type to Run"));

        // [WHEN] Assign a blank option value to the field through Rapid Start
        ConfigValidateMgt.EvaluateTextToFieldRef('', FieldRef, true);

        // [THEN] Default value "Report" is assigned instead
        JobQueueEntry.Init();
        FieldRef.TestField(JobQueueEntry."Object Type to Run");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddTennantPermissionsToPackage()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 309494] "Tenant Permission" and "Tenant Permission Set" can be added to Config. Package
        Initialize();

        // [GIVEN] RapidStart package
        CreateConfigPackage(ConfigPackage);

        // [WHEN] Add "Tenant Permission" and "Tenant Permission Set" tables to the package
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Tenant Permission");
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Tenant Permission Set");

        // [THEN] Tables are added successfully
        Clear(ConfigPackageTable);
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetFilter("Table ID", '%1|%2', DATABASE::"Tenant Permission", DATABASE::"Tenant Permission Set");
        Assert.RecordCount(ConfigPackageTable, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageWithOptionsAndEnums()
    var
        OptionAndEnumRS: Record OptionAndEnumRS;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
    begin
        // Init
        Initialize();
        OptionAndEnumRS.DeleteAll();

        // [GIVEN] that we have tables with both enums and options
        InsertOptionAndEnumRs(0, OptionAndEnumRS.OptionField::Zero, OptionAndEnumRS.EnumField::Eight);
        InsertOptionAndEnumRs(1, OptionAndEnumRS.OptionField::One, OptionAndEnumRS.EnumField::Nine);
        InsertOptionAndEnumRs(2, OptionAndEnumRS.OptionField::Two, OptionAndEnumRS.EnumField::Ten);

        // [GIVEN] a rapidstart package is create from that table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::OptionAndEnumRS);
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        // Cleanup before import
        OptionAndEnumRS.DeleteAll();
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        // [WHEN] the rapidstart package is imported and applied
        ConfigXMLExchange.ImportPackageXML(FilePath);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] the options and enums are properly applied
        VerifyEnumsAndOptionsAfterApplyingPackage()
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageWithTranslatedOptionsAndEnums()
    var
        OptionAndEnumRS: Record OptionAndEnumRS;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
        LanguageId: Integer;
    begin
        // Init
        Initialize();
        OptionAndEnumRS.DeleteAll();

        // [GIVEN] that the system is running in a different language
        LanguageId := GlobalLanguage();
        // Change to DAN
        GlobalLanguage(1030);

        // [GIVEN] that we have tables with both enums and options
        InsertOptionAndEnumRs(0, OptionAndEnumRS.OptionField::Zero, OptionAndEnumRS.EnumField::Eight);
        InsertOptionAndEnumRs(1, OptionAndEnumRS.OptionField::One, OptionAndEnumRS.EnumField::Nine);
        InsertOptionAndEnumRs(2, OptionAndEnumRS.OptionField::Two, OptionAndEnumRS.EnumField::Ten);

        // [GIVEN] a rapidstart package is create from that table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::OptionAndEnumRS);
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        // Cleanup before import
        OptionAndEnumRS.DeleteAll();
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        // [WHEN] the rapidstart package is imported and applied
        ConfigXMLExchange.ImportPackageXML(FilePath);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] the option and enums are properly applied
        VerifyEnumsAndOptionsAfterApplyingPackage();
        GlobalLanguage(LanguageId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportConfigPackageWithPercentInColumn()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        FilePath: Text;
    begin
        // [SCENARIO 390268] Export and import of Config. Package with record that has similar columns differ by % symbol
        Initialize();

        // [GIVEN] 3 "Inventory Adjmt. Entry Order" lines
        // 1st Line "Indirect Cost %" = 0, Indirect Cost = 1;
        // 2nd Line "Indirect Cost %" = 0, Indirect Cost = 2;
        // 3rd Line "Indirect Cost %" = 0, Indirect Cost = 3;
        InventoryAdjmtEntryOrder.DeleteAll();
        MockInventoryAdjmtEntryOrderLines(3);

        // [GIVEN] Config. Package with Inventory Adjmt. Entry Order table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Inventory Adjmt. Entry (Order)");

        // [GIVEN] Package "A" is exported to XML
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        // [GIVEN] All Inventory Adjmt. Entry Order records are deleted;
        InventoryAdjmtEntryOrder.DeleteAll();

        // [WHEN] Package "A" is imported from XML
        // [THEN] No error message appears 
        ImportPackageXML(ConfigPackage.Code, FilePath);
        Erase(FilePath);

        // [WHEN] Apply the package 
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] The package is applied without errors
        // [THEN] "Inventory Adjmt. Entry Order" has original values of "Indirect Cost %" and "Indirect Cost" 
        VerifyNoConfigPackageErrors(ConfigPackage.Code);
        VerifyInventoryAdjmtEntryOrderLines(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportImportConfigPackageWithDecimalRounding()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        BaseUnitOfMeasure: Record "Unit of Measure";
        OtherUnitOfMeasure: Record "Unit of Measure";
        FilePath: Text;
    begin
        // [SCENARIO 453468] Export and import of Config. Package with Qty. per Unit of Measure require rounding to 5 decimals
        Initialize();

        // [GIVEN] Create Item with 2 units of measure and Qty. per Unit of Measure with more than 5 decimals
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", BaseUnitOfMeasure.Code, 1);
        LibraryInventory.CreateUnitOfMeasureCode(OtherUnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", OtherUnitOfMeasure.Code, 1.23456789);

        // [GIVEN] Create Package with Item Unit Of Measure table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Item Unit of Measure");

        // [GIVEN] Config. Package is exported to XML
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        // [GIVEN] Delete created other unit of measure
        ItemUnitOfMeasure.Delete();

        // [WHEN] Package is imported from XML
        // [THEN] No error message appears 
        ImportPackageXML(ConfigPackage.Code, FilePath);
        Erase(FilePath);

        // [WHEN] Apply the package 
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] The package is applied without errors
        // [THEN] and Qty. per Unit of Measure" rounded to 5 decimals
        ItemUnitOfMeasure.Get(Item."No.", OtherUnitOfMeasure.Code);
        Assert.AreEqual(ItemUnitOfMeasure."Qty. per Unit of Measure", 1.23457, 'value should be rounded to 5 decimals.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageWithDuplicatedXMLFields()
    var
        DuplicatedXMLFields: Record DuplicatedXMLFields;
        TempDuplicatedXMLFields: Record DuplicatedXMLFields temporary;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
    begin
        // [SCENARIO 390268] Table with duplicated XML field names can be imported with XML package
        Initialize();
        DuplicatedXMLFields.DeleteAll();

        // [GIVEN] Create several records of DuplicatedXMLFields table
        InsertDuplicatedXMLFieldsRecords(LibraryRandom.RandIntInRange(5, 10), TempDuplicatedXMLFields);

        // [GIVEN] Rapidstart package is created from DuplicatedXMLFields table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::DuplicatedXMLFields);
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        // Cleanup before import
        DuplicatedXMLFields.DeleteAll();
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        // [WHEN] the rapidstart package is imported and applied
        ConfigXMLExchange.ImportPackageXML(FilePath);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] DuplicatedXMLFields records are properly applied
        VerifyDuplicatedXMLFieldsRecords(TempDuplicatedXMLFields);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportToExcelDuplicatedXMLFields()
    var
        DuplicatedXMLFields: Record DuplicatedXMLFields;
        TempDuplicatedXMLFields: Record DuplicatedXMLFields temporary;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // [SCENARIO 390268] Table with duplicated XML field names can be exported to Excel 
        Initialize();
        DuplicatedXMLFields.DeleteAll();

        // [GIVEN] Create 1 record of DuplicatedXMLFields table
        InsertDuplicatedXMLFieldsRecords(1, TempDuplicatedXMLFields);

        // [GIVEN] Rapidstart package is created from DuplicatedXMLFields table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::DuplicatedXMLFields);

        // [WHEN] Export package to Excel
        Commit();
        ExportToExcel(ConfigPackageTable);

        // [THEN] Column headers contain field names, decimal cells have proper values
        VerifyDuplicatedXMLFieldsRecordsExcelFile(TempDuplicatedXMLFields);
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcelPackageWithDuplicatedXMLFields()
    var
        DuplicatedXMLFields: Record DuplicatedXMLFields;
        TempDuplicatedXMLFields: Record DuplicatedXMLFields temporary;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
    begin
        // [SCENARIO 390268] Table with duplicated XML field names can be imported from Excel 
        Initialize();
        DuplicatedXMLFields.DeleteAll();

        // [GIVEN] Create several records of DuplicatedXMLFields table
        InsertDuplicatedXMLFieldsRecords(LibraryRandom.RandIntInRange(5, 10), TempDuplicatedXMLFields);

        // [GIVEN] Excel file is created from DuplicatedXMLFields table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::DuplicatedXMLFields);
        Commit();
        ExportToExcel(ConfigPackageTable);

        // Cleanup before import
        DuplicatedXMLFields.DeleteAll();

        // [WHEN] Import package from Excel
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        LibraryVariableStorage.Enqueue(1); // expected numer of sheets in Excel for ExcelImportPreviewHandler

        ConfigExcelExchange.ImportExcelFromSelectedPackage(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] DuplicatedXMLFields records are properly applied
        VerifyDuplicatedXMLFieldsRecords(TempDuplicatedXMLFields);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPackageWithEmptyXMLFieldNames()
    var
        DummyRSTable: Record DummyRSTable;
        TempDummyRSTable: Record DummyRSTable temporary;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        FilePath: Text;
    begin
        // [SCENARIO 390268] Package can be imported with empty "XML Field Name" fields in the "Config. Package Field" table (old package import scenario)
        Initialize();
        DummyRSTable.DeleteAll();

        // [GIVEN] Create several records of DummyRSTable table
        InsertDummyRSTableRecords(LibraryRandom.RandIntInRange(5, 10), TempDummyRSTable);

        // [GIVEN] Rapidstart package "P" is created from DummyRSTable table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::DummyRSTable);
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);

        // [GIVEN] Make "XML Field Name" empty for all "Config. Package Field" records of package "P"
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.ModifyAll("XML Field Name", '');

        // Cleanup before import
        DummyRSTable.DeleteAll();
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        // [WHEN] the rapidstart package is imported and applied
        ConfigXMLExchange.ImportPackageXML(FilePath);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] DummyRSTable records are properly applied
        VerifyDummyRSTableRecords(TempDummyRSTable);
    end;

    [Test]
    [HandlerFunctions('ExcelImportPreviewHandler')]
    [Scope('OnPrem')]
    procedure ImportFromExcelPackageWithEmptyXMLFieldNames()
    var
        DummyRSTable: Record DummyRSTable;
        TempDummyRSTable: Record DummyRSTable temporary;
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ERMRSPackageOperations: Codeunit "ERM RS Package Operations";
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
    begin
        // [SCENARIO 390268] Package can be imported from Excel with empty "XML Field Name" fields in the "Config. Package Field" table (old package import scenario) 
        Initialize();
        DummyRSTable.DeleteAll();

        // [GIVEN] Create several records of DummyRSTable table
        InsertDummyRSTableRecords(LibraryRandom.RandIntInRange(5, 10), TempDummyRSTable);

        // [GIVEN] Excel file is created from DummyRSTable table
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::DummyRSTable);
        Commit();
        ExportToExcel(ConfigPackageTable);

        // [GIVEN] Make "XML Field Name" empty for all "Config. Package Field" records of package "P"
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.ModifyAll("XML Field Name", '');

        // Cleanup before import
        DummyRSTable.DeleteAll();

        // [WHEN] Import package from Excel
        BindSubscription(ERMRSPackageOperations);
        ERMRSPackageOperations.SetFileName(LibraryReportValidation.GetFileName()); // for OnImportExcelToBLOBHandler
        LibraryVariableStorage.Enqueue(1); // expected numer of sheets in Excel for ExcelImportPreviewHandler

        ConfigExcelExchange.ImportExcelFromSelectedPackage(ConfigPackage.Code);
        LibraryRapidStart.ApplyPackage(ConfigPackage, true);

        // [THEN] DummyRSTable records are properly applied
        VerifyDummyRSTableRecords(TempDummyRSTable);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportConfigPackageIncludesConfigMediaBuffer()
    var
        ConfigPackage: Array[2] of Record "Config. Package";
        ConfigPackageTable: Array[2] of Record "Config. Package Table";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlNodeList: DotNet XmlNodeList;
        XMLDocument: DotNet XmlDocument;
        ItemFilter: Text[250];
        FilePath: Text;
    begin
        // [SCENARIO 399994] Export of Config. Package should include Config. Media Buffer for this Config. Package
        Initialize();

        // [GIVEN] Two Items, first item has a picture (MediaSet value)
        CreateTwoItemsFirstWithMediaSet(ItemFilter);

        // [GIVEN] Config. Package "1" with Item table
        CreatePackageWithTable(ConfigPackage[1], ConfigPackageTable[1], DATABASE::Item);
        ConfigPackage[1].Validate("Exclude Config. Tables", true);
        ConfigPackage[1].Modify(true);

        // [GIVEN] Config. Package "2" with Item table
        CreatePackageWithTable(ConfigPackage[2], ConfigPackageTable[2], DATABASE::Item);
        ConfigPackage[2].Validate("Exclude Config. Tables", true);
        ConfigPackage[2].Modify(true);

        // [GIVEN] Set filter for two items to decrease package processing time
        SetItemConfigPackageFilter(ConfigPackage[1].Code, ItemFilter);
        SetItemConfigPackageFilter(ConfigPackage[2].Code, ItemFilter);

        // [GIVEN] Exported Config. Package "1"
        FilePath := FileMgt.ServerTempFileName('xml');
        ExportToXML(ConfigPackage[1].Code, ConfigPackageTable[1], FilePath);

        // [WHEN] Exported Config. Package "2"
        FilePath := FileMgt.ServerTempFileName('xml');
        ExportToXML(ConfigPackage[2].Code, ConfigPackageTable[2], FilePath);

        // [THEN] Package contains Config. Media Buffer records only for Config. Package "2"
        XMLDOMManagement.LoadXMLDocumentFromFile(FilePath, XMLDocument);
        XMLDOMManagement.FindNodes(XmlDocument.DocumentElement, '/DataList/ConfigMediaBufferList', XmlNodeList);

        // <ConfigMediaBufferList>
        // <TableID>8630</TableID>
        // <ConfigMediaBuffer>
        //  <PackageCode>ConfigPackage[2].Code</PackageCode>
        //  .. 
        // <ConfigMediaBuffer>
        // </ConfigMediaBufferList>
        Assert.AreEqual(2, XmlNodeList.Item(0).ChildNodes.Count, ''); // 2 nodes TableID and ConfigMediaBuffer for Config. Package "2"
        Assert.AreEqual(FORMAT(Database::"Config. Media Buffer"), XmlNodeList.ItemOf(0).SelectSingleNode('TableID').InnerText, '');
        Assert.AreEqual(ConfigPackage[2].Code, XmlNodeList.Item(0).ChildNodes.Item(1).SelectSingleNode('PackageCode').InnerText, '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Package Operations");
        Clear(LibraryReportValidation);
        LibraryRapidStart.CleanUp('');
        LibraryVariableStorage.Clear();
        FileNameForHandler := '';
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM RS Package Operations");

        HideDialog();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        APIMockEvents.SetAPIServicesEnabled(false);
        RemoveSalesData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM RS Package Operations");
    end;

    local procedure CreateSalesOrderWithWorkDescription(var SalesHeader: Record "Sales Header")
    var
        TypeHelper: Codeunit "Type Helper";
        WorkDescriptionTextBuilder: TextBuilder;
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        WorkDescriptionTextBuilder.Append(LibraryRandom.RandText(MaxStrLen(SalesHeader."Currency Code")));
        WorkDescriptionTextBuilder.Append(TypeHelper.LFSeparator());
        WorkDescriptionTextBuilder.Append(LibraryRandom.RandText(MaxStrLen(SalesHeader."Currency Code")));
        WorkDescriptionTextBuilder.Append(TypeHelper.LFSeparator());
        WorkDescriptionTextBuilder.Append(LibraryRandom.RandText(MaxStrLen(SalesHeader."Currency Code")));
        WorkDescriptionTextBuilder.Append(TypeHelper.LFSeparator());
        SalesHeader.SetWorkDescription(WorkDescriptionTextBuilder.ToText());
        SalesHeader.Modify();
    end;

    local procedure MockInventoryAdjmtEntryOrderLines(NoOfLines: Integer)
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        i: Integer;
    begin
        for i := 1 to NoOfLines do begin
            InventoryAdjmtEntryOrder.Init();
            InventoryAdjmtEntryOrder.Validate("Order Type", InventoryAdjmtEntryOrder."Order Type"::Production);
            InventoryAdjmtEntryOrder.Validate("Order No.", Format(i));
            InventoryAdjmtEntryOrder.Validate("Order Line No.", i);
            InventoryAdjmtEntryOrder.Validate("Indirect Cost %", 0);
            InventoryAdjmtEntryOrder.Validate("Indirect Cost", i);
            InventoryAdjmtEntryOrder.Insert(TRUE);
        end;
    end;

    local procedure VerifyInventoryAdjmtEntryOrderLines(NoOfLines: Integer)
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        i: Integer;
    begin
        InventoryAdjmtEntryOrder.FindFirst();
        for i := 1 to NoOfLines do begin
            InventoryAdjmtEntryOrder.TestField("Indirect Cost %", 0);
            InventoryAdjmtEntryOrder.TestField("Indirect Cost", i);
            InventoryAdjmtEntryOrder.Next();
        end;
    end;

    local procedure RemoveSalesData()
    var
        Customer: record Customer;
        SalesHeader: record "Sales Header";
        SalesLine: record "Sales Line";
    begin
        Customer.DeleteAll();
        SalesHeader.DeleteAll();
        SalesLine.DeleteAll();
    end;

    local procedure CreateConfigPackage(var ConfigPackage: record "Config. Package")
    begin
        LibraryRapidStart.CreatePackage(ConfigPackage);
        ConfigPackage."Min. Count For Async Import" := 999999999; // to avoid background jobs
        ConfigPackage.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetFileName(FileName: Text)
    begin
        FileNameForHandler := FileName;
    end;

    local procedure DeleteCustomerRelatedData(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesLine.DeleteAll(true);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.DeleteAll(true);
        Customer.SetRange("No.", CustomerNo);
        Customer.DeleteAll(true);
    end;

    local procedure DeleteShopCalendarRelatedData(var ShopCalendarWorkingDaysFilters: Record "Shop Calendar Working Days")
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        ShopCalendarWorkingDays.CopyFilters(ShopCalendarWorkingDaysFilters);
        ShopCalendarWorkingDays.DeleteAll(true);
    end;

    local procedure FindFieldOfType(var ConfigPackageField: Record "Config. Package Field"; TypeName: Text)
    var
        "Field": Record "Field";
    begin
        Assert.IsTrue(Evaluate(Field.Type, TypeName), TypeName);
        Field.SetRange(Type, Field.Type);
        Assert.IsTrue(Field.FindFirst(), 'cannot find the field');
        ConfigPackageField."Table ID" := Field.TableNo;
        ConfigPackageField."Field ID" := Field."No.";
    end;

    local procedure ImportFromXML(var ConfigPackage: Record "Config. Package"; var CountryCode: Code[10]; var LocationCode: Code[10])
    var
        ConfigPackageTable: Record "Config. Package Table";
        Country: Record "Country/Region";
        Location: Record Location;
        XMLDOMManagement: Codeunit "XML DOM Management";
        RecRef: RecordRef;
        XMLDocument: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
    begin
        LibraryERM.CreateCountryRegion(Country);
        CountryCode := Country.Code;

        LibraryWarehouse.CreateLocation(Location);
        Location."Country/Region Code" := CountryCode;
        Location.Modify();
        LocationCode := Location.Code;

        CreateConfigPackage(ConfigPackage);
        XMLDOMManagement.LoadXMLNodeFromText(
          '<?xml version="1.0" encoding="UTF-16" standalone="yes"?><DataList Code="' + ConfigPackage.Code + '"></DataList>',
          DocumentElement);
        XMLDocument := DocumentElement.OwnerDocument;

        // Add CountryRegionList
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Country/Region");
        IncludeField(ConfigPackageTable, 0, false);
        IncludeField(ConfigPackageTable, Country.FieldNo(Code), true);
        RecRef.GetTable(Country);
        AddConfigPackageTableToXML(XMLDocument, DocumentElement, ConfigPackageTable, RecRef);
        // Add LocationList
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::Location);
        IncludeField(ConfigPackageTable, 0, false);
        IncludeField(ConfigPackageTable, Location.FieldNo(Code), true);
        IncludeField(ConfigPackageTable, Location.FieldNo("Country/Region Code"), true);
        RecRef.GetTable(Location);
        AddConfigPackageTableToXML(XMLDocument, DocumentElement, ConfigPackageTable, RecRef);

        Country.Delete();
        Location.Delete();
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        ConfigXMLExchange.ImportPackageXMLDocument(XMLDocument, '');
    end;

    local procedure ImportPackageXML(PackageCode: Code[20]; XMLDataFile: text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocument: DotNet XmlDocument;
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(XMLDataFile, XMLDocument);
        ConfigXMLExchange.ImportPackageXMLDocument(XMLDocument, PackageCode);
    end;

    local procedure ImportFromXMLKey(var ConfigPackage: Record "Config. Package"; var GenProductPostingGroupCode: Code[20]; var GenBusPostingGroupCode: Code[20])
    var
        ConfigPackageTable: Record "Config. Package Table";
        GeneralPostingSetup: Record "General Posting Setup";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        XMLDOMManagement: Codeunit "XML DOM Management";
        RecRef: RecordRef;
        XMLDocument: DotNet XmlDocument;
        DocumentElement: DotNet XmlNode;
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GenProductPostingGroupCode := GenProductPostingGroup.Code;
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroupCode := GenBusPostingGroup.Code;
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProductPostingGroup.Code);

        CreateConfigPackage(ConfigPackage);
        XMLDOMManagement.LoadXMLNodeFromText(
          '<?xml version="1.0" encoding="UTF-16" standalone="yes"?><DataList Code="' + ConfigPackage.Code + '"></DataList>',
          DocumentElement);
        XMLDocument := DocumentElement.OwnerDocument;

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"General Posting Setup");
        RecRef.GetTable(GeneralPostingSetup);
        AddConfigPackageTableToXML(XMLDocument, DocumentElement, ConfigPackageTable, RecRef);

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Business Posting Group");
        RecRef.GetTable(GenBusPostingGroup);
        AddConfigPackageTableToXML(XMLDocument, DocumentElement, ConfigPackageTable, RecRef);

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Product Posting Group");
        RecRef.GetTable(GenProductPostingGroup);
        AddConfigPackageTableToXML(XMLDocument, DocumentElement, ConfigPackageTable, RecRef);

        GenProductPostingGroup.Delete();
        GenBusPostingGroup.Delete();
        GeneralPostingSetup.Delete();
        LibraryRapidStart.CleanUp(ConfigPackage.Code);

        ConfigXMLExchange.ImportPackageXMLDocument(XMLDocument, '');
    end;

    local procedure AddXMLNode(var XMLDocument: DotNet XmlDocument; ParentNode: DotNet XmlNode; Node: DotNet XmlNode; FieldName: Text[250]; FieldText: Text[250])
    begin
        Node := XMLDocument.CreateElement(ConfigXMLExchange.GetElementName(FieldName));
        Node.InnerText := Format(FieldText);
        ParentNode.AppendChild(Node);
    end;

    local procedure AddConfigPackageTableToXML(var XMLDocument: DotNet XmlDocument; DocumentElement: DotNet XmlNode; ConfigPackageTable: Record "Config. Package Table"; RecRef: RecordRef)
    var
        ConfigPackageField: Record "Config. Package Field";
        FieldRef: FieldRef;
        TableNode: DotNet XmlNode;
        TableIDNode: DotNet XmlNode;
        FormIDNode: DotNet XmlNode;
        RecordNode: DotNet XmlNode;
        FieldNode: DotNet XmlNode;
    begin
        ConfigPackageTable.CalcFields("Table Name");
        TableNode := XMLDocument.CreateElement(ConfigXMLExchange.GetElementName(CopyStr(ConfigPackageTable."Table Name" + 'List', 1, 250)));
        DocumentElement.AppendChild(TableNode);

        AddXMLNode(XMLDocument, TableNode, TableIDNode, CopyStr(ConfigPackageTable.FieldName("Table ID"), 1, 250), Format(ConfigPackageTable."Table ID"));
        AddXMLNode(XMLDocument, TableNode, FormIDNode, CopyStr(ConfigPackageTable.FieldName("Page ID"), 1, 250), Format(ConfigPackageTable."Page ID"));
        AddXMLNode(
          XMLDocument, TableNode, FormIDNode, CopyStr(ConfigPackageTable.FieldName("Processing Order"), 1, 250),
          Format(ConfigPackageTable."Processing Order"));
        AddXMLNode(XMLDocument, TableNode, RecordNode, ConfigPackageTable."Table Name", '');

        ConfigPackageField.Reset();
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageField.SetRange("Include Field", true);
        if ConfigPackageField.FindSet() then
            repeat
                FieldRef := RecRef.Field(ConfigPackageField."Field ID");
                AddXMLNode(XMLDocument, RecordNode, FieldNode, CopyStr(FieldRef.Name(), 1, 250), Format(FieldRef.Value()));
            until ConfigPackageField.Next() = 0;
    end;

    local procedure VerifyGenJnlLineAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Reset();
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();

        Assert.AreEqual(-Amount, GLEntry.Amount, Text103Err);
    end;

    local procedure GetNoOfAvailableFields(var ConfigPackageTable: Record "Config. Package Table"): Integer
    begin
        ConfigPackageTable.CalcFields("No. of Fields Available");
        exit(ConfigPackageTable."No. of Fields Available");
    end;

    local procedure EvaluateValue(TableNo: Integer; FieldNo: Integer; Value: Text[250]) ErrorText: Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        ErrorText := ConfigValidateMgt.EvaluateValue(FieldRef, Value, false);
        if ErrorText <> '' then
            exit(ErrorText);

        ConfigValidateMgt.EvaluateTextToFieldRef(Value, FieldRef, true);
        ConfigValidateMgt.EvaluateTextToFieldRef(Value, FieldRef, false);
    end;

    local procedure EvaluateDateTimeValue(TableNo: Integer; FieldNoDate: Integer; FieldNoTime: Integer; ValueDate: Text[250]; ValueTime: Text[250]; Date: Date; Time: Time)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);

        FieldRef := RecRef.Field(FieldNoDate);
        ConfigValidateMgt.EvaluateValue(FieldRef, ValueDate, false);
        FieldRef.TestField(Date);

        FieldRef := RecRef.Field(FieldNoTime);
        ConfigValidateMgt.EvaluateValue(FieldRef, ValueTime, false);
        FieldRef.TestField(Time);
    end;

    local procedure HideDialog()
    begin
        ConfigPackageMgt.SetHideDialog(true);
        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetHideDialog(true);
    end;

    local procedure CreatePackageWithTable(var ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; TableNo: Integer)
    begin
        CreateConfigPackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, TableNo);
    end;

    local procedure CreatePaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        PaymentMethod.Init();
        PaymentMethod.Validate(Code, LibraryUtility.GenerateRandomCode(PaymentMethod.FieldNo(Code), DATABASE::"Payment Method"));
        PaymentMethod.Insert(true);
    end;

    local procedure CreatePurchSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        if not PurchSetup.Get() then begin
            PurchSetup.Init();
            PurchSetup.Insert(true);
        end;
    end;

    local procedure CreatePackageWithBlobField(var ConfigPackage: Record "Config. Package"; var SalesHeader: Record "Sales Header")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, Database::"Sales Header");
        IncludeField(ConfigPackageTable, 0, false);
        IncludeField(ConfigPackageTable, SalesHeader.FieldNo("Document Type"), true);
        IncludeField(ConfigPackageTable, SalesHeader.FieldNo("No."), true);
        IncludeField(ConfigPackageTable, SalesHeader.FieldNo("Work Description"), true);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Sales Header", 0,
          SalesHeader.FieldNo("Document Type"), Format(SalesHeader."Document Type"));
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Sales Header", 0,
          SalesHeader.FieldNo("No."), SalesHeader."No.");
    end;

    local procedure CreateSalesInvPackage(var ConfigPackage: Record "Config. Package"; ParentTableID: Integer) CustomerNo: Code[20]
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Modify(true);
        CustomerNo := Customer."No.";

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CustomerNo, LibraryInventory.CreateItemNo(), 3, '', WorkDate());

        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::Customer);
        IncludeField(ConfigPackageTable, 0, false);
        IncludeField(ConfigPackageTable, Customer.FieldNo("No."), true);
        IncludeField(ConfigPackageTable, Customer.FieldNo("Customer Posting Group"), true);
        ValidateField(ConfigPackageTable, Customer.FieldNo("Customer Posting Group"), false);
        IncludeField(ConfigPackageTable, Customer.FieldNo("Gen. Bus. Posting Group"), true);
        ValidateField(ConfigPackageTable, Customer.FieldNo("Gen. Bus. Posting Group"), false);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::Customer, 0,
          Customer.FieldNo("No."), SalesHeader."Sell-to Customer No.");

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Header");
        IncludeField(ConfigPackageTable, 0, false);
        IncludeField(ConfigPackageTable, SalesHeader.FieldNo("Document Type"), true);
        IncludeField(ConfigPackageTable, SalesHeader.FieldNo("No."), true);
        ValidateField(ConfigPackageTable, SalesHeader.FieldNo("No."), false);
        IncludeField(ConfigPackageTable, SalesHeader.FieldNo("Sell-to Customer No."), true);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Sales Header", 0,
          SalesHeader.FieldNo("Sell-to Customer No."), SalesHeader."Sell-to Customer No.");

        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Sales Line");
        ConfigPackageTable."Parent Table ID" := ParentTableID;
        ConfigPackageTable.Modify();
        IncludeField(ConfigPackageTable, 0, false);
        IncludeField(ConfigPackageTable, SalesLine.FieldNo("Document Type"), true);
        IncludeField(ConfigPackageTable, SalesLine.FieldNo("Document No."), true);
        IncludeField(ConfigPackageTable, SalesLine.FieldNo("Line No."), true);
        IncludeField(ConfigPackageTable, SalesLine.FieldNo("Sell-to Customer No."), true);
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Sales Line", 0,
          SalesLine.FieldNo("Sell-to Customer No."), SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateShopCalendarWithWorkingDays(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; FromTime: Time; ToTime: Time)
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShift: Record "Work Shift";
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        CreateFiveShopCalendarWorkingDays(ShopCalendar.Code, WorkShift.Code, FromTime, ToTime);
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendar.Code);
        ShopCalendarWorkingDays.SetRange("Work Shift Code", WorkShift.Code);
    end;

    local procedure CreateFiveShopCalendarWorkingDays(ShopCalendarCode: Code[10]; WorkShiftCode: Code[10]; FromTime: Time; ToTime: Time)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        D: Option;
    begin
        for D := ShopCalendarWorkingDays.Day::Monday to ShopCalendarWorkingDays.Day::Friday do
            LibraryManufacturing.CreateShopCalendarWorkingDays(ShopCalendarWorkingDays, ShopCalendarCode, D, WorkShiftCode, FromTime, ToTime);
    end;

    local procedure SetShopCalendarWorkingDaysFieldProcessingOrder(ConfigPackageCode: Code[20]; FieldId: Integer; ProcessingOrder: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.Get(ConfigPackageCode, DATABASE::"Shop Calendar Working Days", FieldId);
        SetConfigPackageFieldProcessingOrder(ConfigPackageField, FieldId, ProcessingOrder);
    end;

    local procedure CreateShopCalendarWorkingDaysPackage(var ConfigPackage: Record "Config. Package")
    var
        ConfigPackageTable: Record "Config. Package Table";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, DATABASE::"Shop Calendar Working Days");
        IncludeField(ConfigPackageTable, 0, false);
        IncludeField(ConfigPackageTable, ShopCalendarWorkingDays.FieldNo("Shop Calendar Code"), true);
        IncludeField(ConfigPackageTable, ShopCalendarWorkingDays.FieldNo("Work Shift Code"), true);
        IncludeField(ConfigPackageTable, ShopCalendarWorkingDays.FieldNo(Day), true);
        IncludeField(ConfigPackageTable, ShopCalendarWorkingDays.FieldNo("Starting Time"), true);
        IncludeField(ConfigPackageTable, ShopCalendarWorkingDays.FieldNo("Ending Time"), true);

        SetShopCalendarWorkingDaysFieldProcessingOrder(ConfigPackage.Code, ShopCalendarWorkingDays.FieldNo("Shop Calendar Code"), 1);
        SetShopCalendarWorkingDaysFieldProcessingOrder(ConfigPackage.Code, ShopCalendarWorkingDays.FieldNo("Work Shift Code"), 2);
        SetShopCalendarWorkingDaysFieldProcessingOrder(ConfigPackage.Code, ShopCalendarWorkingDays.FieldNo(Day), 3);
        SetShopCalendarWorkingDaysFieldProcessingOrder(ConfigPackage.Code, ShopCalendarWorkingDays.FieldNo("Starting Time"), 4);
        SetShopCalendarWorkingDaysFieldProcessingOrder(ConfigPackage.Code, ShopCalendarWorkingDays.FieldNo("Ending Time"), 5);
    end;

    local procedure CreateShopCalendarWorkingDaysPackageData(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; ConfigPackageCode: Code[20]; TimeShift: Integer)
    var
        RecordsCount: Integer;
        T: Time;
    begin
        if ShopCalendarWorkingDays.FindFirst() then
            repeat
                RecordsCount += 1;
                LibraryRapidStart.CreatePackageData(
                  ConfigPackageCode, DATABASE::"Shop Calendar Working Days", RecordsCount,
                  ShopCalendarWorkingDays.FieldNo("Shop Calendar Code"), Format(ShopCalendarWorkingDays."Shop Calendar Code"));
                LibraryRapidStart.CreatePackageData(
                  ConfigPackageCode, DATABASE::"Shop Calendar Working Days", RecordsCount,
                  ShopCalendarWorkingDays.FieldNo("Work Shift Code"), Format(ShopCalendarWorkingDays."Work Shift Code"));
                LibraryRapidStart.CreatePackageData(
                  ConfigPackageCode, DATABASE::"Shop Calendar Working Days", RecordsCount, ShopCalendarWorkingDays.FieldNo(Day), Format(ShopCalendarWorkingDays.Day));
                T := ShopCalendarWorkingDays."Starting Time" + TimeShift;
                LibraryRapidStart.CreatePackageData(
                  ConfigPackageCode, DATABASE::"Shop Calendar Working Days", RecordsCount, ShopCalendarWorkingDays.FieldNo("Starting Time"), Format(T));
                T := ShopCalendarWorkingDays."Ending Time" + TimeShift;
                LibraryRapidStart.CreatePackageData(
                  ConfigPackageCode, DATABASE::"Shop Calendar Working Days", RecordsCount, ShopCalendarWorkingDays.FieldNo("Ending Time"), Format(T));
            until ShopCalendarWorkingDays.Next() = 0;
    end;

    local procedure CreateVendorPostingGroup(var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        VendorPostingGroup.Init();
        VendorPostingGroup.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(VendorPostingGroup.FieldNo(Code), DATABASE::"Vendor Posting Group"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Vendor Posting Group", VendorPostingGroup.FieldNo(Code))));

        VendorPostingGroup.Insert(true);
    end;

    local procedure CreateAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
    begin
        AccountingPeriod.SetRange(Closed, false);
        if not AccountingPeriod.FindFirst() then begin
            Date.SetRange("Period Type", Date."Period Type"::Month);
            Date.SetRange("Period Start", 0D, WorkDate());
            Date.FindLast();

            AccountingPeriod.Init();
            AccountingPeriod.Validate("Starting Date", Date."Period Start");
            AccountingPeriod.Insert(true);
        end;
    end;

    local procedure CreateGenJnlLineSetup(var GLAccount: Record "G/L Account"; var PaymentMethod: Record "Payment Method"; var GenBusinessPostingGroup: Record "Gen. Business Posting Group"; var GenProductPostingGroup: Record "Gen. Product Posting Group"; var GeneralPostingSetup: Record "General Posting Setup"; var VATBusinessPostingGroup: Record "VAT Business Posting Group"; var VATProductPostingGroup: Record "VAT Product Posting Group"; var VendorPostingGroup: Record "Vendor Posting Group"; var PaymentTerms: Record "Payment Terms")
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<0D>');
        PaymentTerms.Modify(true);

        CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup."Payables Account" := GLAccount."No.";
        VendorPostingGroup.Modify(true);
        CreatePurchSetup();
        CreatePaymentMethod(PaymentMethod);

        CreateAccountingPeriod();
    end;

    local procedure CreateGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"; var Amount: Decimal; GLAccountNo: Code[20]; var DocumentNo: Code[20])
    var
        Vendor: Record Vendor;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlTemplate2: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        VendorNo: Code[20];
    begin
        // Create Gen. Journal Template and Batch
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        GenJnlTemplate.Validate(Type, GenJnlTemplate.Type::Payments);
        GenJnlTemplate.Modify(true);
        // There must be at least 1 gen. journal template of type "General", otherwise CreateGeneralJnlLine fails
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate2);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);

        // Creating Gen. Journal Line
        LibraryPurchase.CreateVendor(Vendor);
        VendorNo := Vendor."No.";
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::Invoice,
          GenJnlLine."Account Type"::Vendor, VendorNo, -Amount);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", GLAccountNo);
        GenJnlLine.Modify(true);
        DocumentNo := GenJnlLine."Document No.";
    end;

    local procedure CreateConfigTemplateWithMultipleLines(): Code[10]
    var
        Item: Record Item;
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader.Validate("Table ID", DATABASE::Item);
        ConfigTemplateHeader.Modify(true);

        CreateConfigTemplateLine(
          ConfigTemplateHeader.Code, Item.FieldNo("Inventory Posting Group"), CopyStr(Item.FieldName("Inventory Posting Group"), 1, 30));
        CreateConfigTemplateLine(
          ConfigTemplateHeader.Code, Item.FieldNo("Gen. Prod. Posting Group"), CopyStr(Item.FieldName("Gen. Prod. Posting Group"), 1, 30));
        CreateConfigTemplateLine(
          ConfigTemplateHeader.Code, Item.FieldNo("Allow Invoice Disc."), CopyStr(Item.FieldName("Allow Invoice Disc."), 1, 30));
        exit(ConfigTemplateHeader.Code);
    end;

    local procedure CreateConfigTemplateLine(ConfigTemplateHeaderCode: Code[10]; FieldID: Integer; FieldNameValue: Text[30])
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeaderCode);
        ConfigTemplateLine.Validate(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.Validate("Field ID", FieldID);
        ConfigTemplateLine.Validate("Field Name", FieldNameValue);
        ConfigTemplateLine.Modify(true);
    end;

    local procedure CleanupGenJnlSetupData(var PaymentMethod: Record "Payment Method"; var GenBusinessPostingGroup: Record "Gen. Business Posting Group"; var GenProductPostingGroup: Record "Gen. Product Posting Group"; var GeneralPostingSetup: Record "General Posting Setup"; var VATBusinessPostingGroup: Record "VAT Business Posting Group"; var VATProductPostingGroup: Record "VAT Product Posting Group"; var VendorPostingGroup: Record "Vendor Posting Group"; var PaymentTerms: Record "Payment Terms")
    begin
        if PaymentMethod.Get(PaymentMethod.Code) then
            PaymentMethod.Delete(true);

        if GenBusinessPostingGroup.Get(GenBusinessPostingGroup.Code) then
            GenBusinessPostingGroup.Delete(true);

        if GenProductPostingGroup.Get(GenProductPostingGroup.Code) then
            GenProductPostingGroup.Delete(true);

        if GeneralPostingSetup.Get(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code) then
            GeneralPostingSetup.Delete(true);

        if VATBusinessPostingGroup.Get(VATBusinessPostingGroup.Code) then
            VATBusinessPostingGroup.Delete(true);

        if VATProductPostingGroup.Get(VATProductPostingGroup.Code) then
            VATProductPostingGroup.Delete(true);

        if VendorPostingGroup.Get(VendorPostingGroup.Code) then
            VendorPostingGroup.Delete(true);

        if PaymentTerms.Get(PaymentTerms.Code) then
            PaymentTerms.Delete(true);
    end;

    local procedure CleanupPackageAndTemplate(PackageCode: Code[20]; ConfigTemplateHeaderCode: Code[10])
    var
        ConfigPackage: Record "Config. Package";
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigPackage.SetRange(Code, PackageCode);
        ConfigPackage.DeleteAll(true);
        ConfigTemplateHeader.SetRange(Code, ConfigTemplateHeaderCode);
        ConfigTemplateHeader.DeleteAll(true);
    end;

    local procedure CreateAndExportPackageDataForGenJnlLine(var ConfigPackage: Record "Config. Package"; var FilePath: Text)
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        // Creating Package with table Gen. Journal Line
        CreateConfigPackage(ConfigPackage);
        LibraryRapidStart.CreatePackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Gen. Journal Line");

        // Select package table fields for export
        LibraryRapidStart.SetIncludeFields(ConfigPackage.Code, DATABASE::"Gen. Journal Line", 2, 77, true);

        // Export data to XML
        ExportToXML(ConfigPackage.Code, ConfigPackageTable, FilePath);
    end;

    local procedure PostGenJnlLines(GLAccountNo: Code[20]; DocumentNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Bal. Account No.", GLAccountNo);
        if GenJnlLine.FindFirst() then
            if GenJnlLine."Document No." = DocumentNo then
                LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure ExportImportXML(PackageCode: Code[20])
    var
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
    begin
        ExportToXML(PackageCode, ConfigPackageTable, FilePath);
        LibraryRapidStart.CleanUp(PackageCode);
        ConfigXMLExchange.ImportPackageXML(FilePath);
        Erase(FilePath);
    end;

    local procedure ExportImportXMLWithPackageAndTemplateCleanup(PackageCode: Code[20]; ConfigTemplateHeaderCode: Code[10])
    var
        ConfigPackageTable: Record "Config. Package Table";
        FilePath: Text;
    begin
        ExportToXML(PackageCode, ConfigPackageTable, FilePath);
        CleanupPackageAndTemplate(PackageCode, ConfigTemplateHeaderCode);
        ConfigXMLExchange.ImportPackageXML(FilePath);
        Erase(FilePath);
    end;

    local procedure ExportToXML(PackageCode: Code[20]; var ConfigPackageTable: Record "Config. Package Table"; var FilePath: Text)
    begin
        FilePath := FileMgt.ServerTempFileName('xml');
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, FilePath);
    end;

    local procedure ExportToExcel(var ConfigPackageTable: Record "Config. Package Table")
    begin
        ConfigPackageTable.SetRecFilter();
        ExportToExcelFullPackage(ConfigPackageTable);
    end;

    local procedure ExportToExcelFullPackage(var ConfigPackageTable: Record "Config. Package Table")
    var
        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigExcelExchange.SetHideDialog(true);
        ConfigExcelExchange.SetFileOnServer(true);
        FileName := FileManagement.ServerTempFileName('xlsx');
        ConfigExcelExchange.ExportExcel(FileName, ConfigPackageTable, false, false);
        LibraryReportValidation.SetFullFileName(FileName);
    end;

    local procedure FindRandomTableID(MaxID: Integer): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.FindSet();
        if MaxID <= AllObj."Object ID" then
            exit(AllObj."Object ID");

        AllObj.Next(LibraryRandom.RandInt(MaxID - AllObj."Object ID"));
        exit(AllObj."Object ID");
    end;

    local procedure GetTableName(TableID: Integer): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        exit(RecRef.Name);
    end;

    local procedure FindFirstLanguage(): Integer
    var
        WinLanguage: Record "Windows Language";
    begin
        WinLanguage.FindFirst();
        exit(WinLanguage."Language ID");
    end;

    local procedure SetLocalizeFields(ConfigPackageCode: Code[20]; TableID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageField.SetRange("Table ID", TableID);
        ConfigPackageField.ModifyAll("Localize Field", true);
    end;

    local procedure CreateSimplePackage(var ConfigPackage: Record "Config. Package")
    var
        GenJnlTemplateConfigPackageTable: Record "Config. Package Table";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalTemplateName: Code[10];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplateName := GenJournalTemplate.Name;
        GenJournalTemplate.Delete();
        LibraryRapidStart.CreatePackageDataForField(
          ConfigPackage,
          GenJnlTemplateConfigPackageTable,
          DATABASE::"Gen. Journal Template",
          GenJournalTemplate.FieldNo(Name),
          GenJournalTemplateName,
          1);
        ConfigPackage."Min. Count For Async Import" := 999999999;
        ConfigPackage.Modify();
    end;

    local procedure IsPackageDataExists(ConfigPackageCode: Code[20]; AnyData: Boolean): Boolean
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageField.SetRange("Package Code", ConfigPackageCode);

        if AnyData then
            exit(ConfigPackage.Get(ConfigPackageCode) or not ConfigPackageTable.IsEmpty() or not ConfigPackageField.IsEmpty);
        exit(ConfigPackage.Get(ConfigPackageCode) and not ConfigPackageTable.IsEmpty() and not ConfigPackageField.IsEmpty);
    end;

    local procedure CreateTextFile(var FileName: Text)
    var
        File: File;
    begin
        FileName := FileMgt.ServerTempFileName('');
        File.WriteMode := true;
        File.TextMode := true;
        File.Create(FileName);
        File.Write(FileTextMsg);
        File.Close();
    end;

    local procedure ReadTextFromFile(FileName: Text) Text: Text[1024]
    var
        File: File;
    begin
        File.WriteMode := false;
        File.TextMode := true;
        File.Open(FileName);
        File.Read(Text);
    end;

    local procedure VerifyGZIPHeader(CompressedServerFileName: Text)
    var
        DataCompression: Codeunit "Data Compression";
        CompressedServerFile: File;
        CompressedServerFileInStream: InStream;
        IsGZip: Boolean;
    begin
        CompressedServerFile.Open(CompressedServerFileName);
        CompressedServerFile.CreateInStream(CompressedServerFileInStream);
        IsGZip := DataCompression.IsGZip(CompressedServerFileInStream);
        CompressedServerFile.Close();
        Assert.IsTrue(IsGZip, NotGZIPFormatErr);
    end;

    local procedure CreateCompressedFile() CompressedServerFileName: Text
    var
        ServerFileName: Text;
    begin
        CreateTextFile(ServerFileName);

        CompressedServerFileName := FileMgt.ServerTempFileName('');
        ConfigPckgCompressionMgt.ServersideCompress(ServerFileName, CompressedServerFileName);
    end;

    local procedure InitializePackageCard(var ConfigPackageCard: TestPage "Config. Package Card"; FillPackageData: Boolean)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        TableID: Integer;
    begin
        // Create package
        TableID := DATABASE::Vendor;

        CreatePackageWithTable(ConfigPackage, ConfigPackageTable, TableID);
        // Export and import data to fill package tables
        if FillPackageData then
            ExportImportXML(ConfigPackage.Code);

        // Open Package Card page and add table
        ConfigPackageCard.OpenEdit();
        ConfigPackageCard.GotoRecord(ConfigPackage);
    end;

    local procedure FindTableID(): Integer
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.FindFirst();

        exit(AllObj."Object ID");
    end;

    local procedure FindNextTableID(TableID: Integer): Integer
    var
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetFilter("Object ID", '>%1', TableID);
        AllObj.FindFirst();

        exit(AllObj."Object ID");
    end;

    local procedure FillInWorksheet(PackageCode: Code[20])
    var
        ConfigLine: Record "Config. Line";
        TableID: Integer;
    begin
        TableID := FindTableID();
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Area, 0, 'main area', PackageCode, false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Group, 0, '', PackageCode, false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', PackageCode, false);
        TableID := FindNextTableID(TableID);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Group, 0, '', PackageCode, false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', PackageCode, false);
        TableID := FindNextTableID(TableID);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Group, 0, '', PackageCode, false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, TableID, '', PackageCode, false);

        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Area, 0, 'additional area', PackageCode, false);
        LibraryRapidStart.CreateConfigLine(ConfigLine, ConfigLine."Line Type"::Table, DATABASE::Customer, '', PackageCode, true);
    end;

    local procedure GetOADateTime(DateTime: DateTime; var OADate: Integer; var OATime: Decimal)
    var
        DotNetDateTime: DotNet DateTime;
        Date: Date;
        Time: Time;
        Hours: Integer;
        Minutes: Integer;
        Seconds: Integer;
        OADateTime: Decimal;
    begin
        Date := DT2Date(DateTime);
        Time := DT2Time(DateTime);
        Evaluate(Hours, Format(Time, 2, '<Hours24,2>'));
        Evaluate(Minutes, Format(Time, 2, '<Minutes,2>'));
        Evaluate(Seconds, Format(Time, 2, '<Seconds,2>'));
        DotNetDateTime :=
          DotNetDateTime.DateTime(
            Date2DMY(Date, 3), Date2DMY(Date, 2), Date2DMY(Date, 1),
            Hours, Minutes, Seconds);

        OADateTime := DotNetDateTime.ToOADate();
        OADate := OADateTime div 1;
        OATime := OADateTime - OADate;
    end;

    [Scope('OnPrem')]
    procedure IncludeField(ConfigPackageTable: Record "Config. Package Table"; FieldID: Integer; SetInclude: Boolean)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        if FieldID <> 0 then
            ConfigPackageField.SetRange("Field ID", FieldID);
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, SetInclude);
    end;

    [Scope('OnPrem')]
    procedure ValidateField(ConfigPackageTable: Record "Config. Package Table"; FieldID: Integer; SetValidate: Boolean)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        if FieldID <> 0 then
            ConfigPackageField.SetRange("Field ID", FieldID);
        ConfigPackageField.ModifyAll("Validate Field", SetValidate);
    end;

    local procedure IncludeGLAccountPictureConfigPackageField(ConfigPackageCode: Code[20])
    var
        ConfigPackageField: Record "Config. Package Field";
        GLAccount: Record "G/L Account";
    begin
        ConfigPackageField.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageField.SetRange("Table ID", DATABASE::"G/L Account");
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, false);
        ConfigPackageField.SetRange("Field ID", GLAccount.FieldNo(Picture));
        ConfigPackageField.FindFirst();
        ConfigPackageField.Validate("Include Field", true);
        ConfigPackageField.Modify(true);
    end;

    local procedure CreateTwoGLAccountsFirstWithBLOB(var GLAccFilter: Text[250])
    var
        GLAccount: Record "G/L Account";
        OStream: OutStream;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Picture.CreateOutStream(OStream);
        OStream.WriteText(LibraryUtility.GenerateGUID());
        GLAccount.Modify(true);
        GLAccFilter := GLAccount."No.";

        Clear(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccFilter += '..' + GLAccount."No.";
    end;

    local procedure SetContactConfigPackageFilter(ConfigPackageCode: Code[20]; ContactFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        Contact: Record Contact;
    begin
        ConfigPackageFilter.Init();
        ConfigPackageFilter.Validate("Package Code", ConfigPackageCode);
        ConfigPackageFilter.Validate("Table ID", DATABASE::Contact);
        ConfigPackageFilter.Validate("Field ID", Contact.FieldNo("No."));
        ConfigPackageFilter.Validate("Field Filter", ContactFilter);
        ConfigPackageFilter.Insert(true);
    end;

    local procedure VerifyConfigPackageDataBLOBValues(ConfigPackageCode: Code[20]; GLAccFilter: Text[250])
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageDataBLOB: Record "Config. Package Data";
        GLAccount: Record "G/L Account";
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageData.SetRange("Table ID", DATABASE::"G/L Account");
        ConfigPackageData.SetRange("Field ID", GLAccount.FieldNo("No."));
        GLAccount.SetAutoCalcFields(Picture);
        GLAccount.SetFilter("No.", GLAccFilter);
        GLAccount.FindSet();
        repeat
            ConfigPackageData.SetRange(Value, GLAccount."No.");
            ConfigPackageData.FindFirst();
            ConfigPackageDataBLOB.Get(ConfigPackageCode, DATABASE::"G/L Account", ConfigPackageData."No.", GLAccount.FieldNo(Picture));
            ConfigPackageDataBLOB.CalcFields("BLOB Value");
            ConfigPackageDataBLOB.TestField("BLOB Value", GLAccount.Picture);
        until GLAccount.Next() = 0;
    end;

    local procedure VerifyConfigPackageDataBLOBValuesFromExcel(ConfigPackageCode: Code[20]; var SalesHeader: Record "Sales Header"; OriginalWorkDescription: Text)
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageDataBLOB: Record "Config. Package Data";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Sales Header");
        ConfigPackageData.SetRange("Field ID", SalesHeader.FieldNo("No."));
        SalesHeader.FindSet();
        repeat
            SalesHeader.CalcFields("Work Description");
            ConfigPackageData.SetRange(Value, SalesHeader."No.");
            ConfigPackageData.FindFirst();

            ConfigPackageDataBLOB.Get(ConfigPackageCode, DATABASE::"Sales Header", ConfigPackageData."No.", SalesHeader.FieldNo("Work Description"));
            ConfigPackageDataBLOB.CalcFields("BLOB Value");
            ConfigPackageDataBLOB."BLOB Value".CreateInStream(InStream);
            Assert.AreEqual(OriginalWorkDescription, TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()), ConfigPackageDataBLOB.FieldCaption("BLOB Value"));
        until SalesHeader.Next() = 0;
    end;

    local procedure IncludeItemPictureConfigPackageField(ConfigPackageCode: Code[20])
    var
        ConfigPackageField: Record "Config. Package Field";
        DummyItem: Record Item;
    begin
        ConfigPackageField.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageField.SetRange("Table ID", DATABASE::Item);
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, false);
        ConfigPackageField.SetRange("Field ID", DummyItem.FieldNo(Picture));
        ConfigPackageField.FindFirst();
        ConfigPackageField.Validate("Include Field", true);
        ConfigPackageField.Modify(true);
    end;

    local procedure CreateTwoItemsFirstWithMediaSet(var ItemFilter: Text[250])
    var
        Item: Record Item;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        LibraryInventory.CreateItem(Item);
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(GetImageBase64Text(), OutStream);
        TempBlob.CreateInStream(InStream);
        Item.Picture.ImportStream(InStream, Item.Description + '.jpg');
        Item.Modify(true);
        ItemFilter := Item."No.";

        Clear(Item);
        LibraryInventory.CreateItem(Item);
        ItemFilter += '..' + Item."No.";
    end;

    local procedure SetItemConfigPackageFilter(ConfigPackageCode: Code[20]; ItemFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        Item: Record Item;
    begin
        ConfigPackageFilter.Init();
        ConfigPackageFilter.Validate("Package Code", ConfigPackageCode);
        ConfigPackageFilter.Validate("Table ID", DATABASE::Item);
        ConfigPackageFilter.Validate("Field ID", Item.FieldNo("No."));
        ConfigPackageFilter.Validate("Field Filter", ItemFilter);
        ConfigPackageFilter.Insert(true);
    end;

    local procedure SetConfigPackageFieldProcessingOrder(var ConfigPackageField: Record "Config. Package Field"; FieldId: Integer; ProcessingOrder: Integer)
    begin
        ConfigPackageField.SetRange("Field ID", FieldId);
        ConfigPackageField.FindFirst();
        ConfigPackageField."Processing Order" := ProcessingOrder;
        ConfigPackageField.Modify();
    end;

    local procedure VerifyConfigPackageDataMediaSetValues(ConfigPackageCode: Code[20]; ItemFilter: Text[250]; var ConfigMediaBuffer: Record "Config. Media Buffer")
    var
        ConfigPackageData: Record "Config. Package Data";
        Item: Record Item;
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageData.SetRange("Table ID", DATABASE::Item);
        ConfigPackageData.SetRange("Field ID", Item.FieldNo("No."));

        Item.SetFilter("No.", ItemFilter);
        Item.FindSet();
        repeat
            ConfigPackageData.SetRange(Value, Item."No.");
            ConfigPackageData.FindFirst();
            ConfigMediaBuffer.SetRange("Package Code", ConfigPackageCode);
            ConfigMediaBuffer.SetRange("Media Set ID", Format(Item.Picture));
            Assert.AreEqual(
              Item.Picture.Count, ConfigMediaBuffer.Count, StrSubstNo('There should be %1 records for config data', Item.Picture.Count));
        until Item.Next() = 0;
    end;

    local procedure VerifyConfigPackageError(ConfigPackageCode: Code[20]; TableID: Integer; FieldID: Integer; ErrorText: Text)
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageError.SetRange("Table ID", TableID);
        ConfigPackageError.FindFirst();
        ConfigPackageError.TestField("Field ID", FieldID);
        Assert.ExpectedMessage(ErrorText, ConfigPackageError."Error Text");
    end;

    local procedure VerifyNoConfigPackageErrors(ConfigPackageCode: Code[20])
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", ConfigPackageCode);
        Assert.IsTrue(ConfigPackageError.IsEmpty, ConfigPackageError.TableName);
    end;

    local procedure VerifyFiveDaysShopCalendar(var ShopCalendarWorkingDaysFilters: Record "Shop Calendar Working Days"; FromTime: Time; ToTime: Time)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        D: Option;
    begin
        ShopCalendarWorkingDays.CopyFilters(ShopCalendarWorkingDaysFilters);
        ShopCalendarWorkingDays.SetRange("Starting Time", FromTime);
        ShopCalendarWorkingDays.SetRange("Ending Time", ToTime);
        for D := ShopCalendarWorkingDays.Day::Monday to ShopCalendarWorkingDays.Day::Friday do begin
            ShopCalendarWorkingDays.SetRange(Day, D);
            ShopCalendarWorkingDays.FindFirst();
        end;
    end;

    local procedure InsertOptionAndEnumRs(PK: Integer; OptionInt: Integer; EnumInt: Enum EnumRs)
    var
        OptionAndEnumRS: Record OptionAndEnumRS;
    begin
        OptionAndEnumRS.PK := PK;
        OptionAndEnumRS.OptionField := OptionInt;
        OptionAndEnumRS.EnumField := EnumInt;
        OptionAndEnumRS.Insert();
    end;

    local procedure InsertDuplicatedXMLFieldsRecords(NumberOfEntries: Integer; var TempDuplicatedXMLFields: Record DuplicatedXMLFields temporary)
    var
        DuplicatedXMLFields: Record DuplicatedXMLFields;
        i: Integer;
    begin
        for i := 1 to NumberOfEntries do begin
            DuplicatedXMLFields."Entry No." := i;
            DuplicatedXMLFields."Indirect Amount %" := LibraryRandom.RandDecInRange(0, 100, 2);
            DuplicatedXMLFields."Indirect (Amount) %" := LibraryRandom.RandDecInRange(0, 100, 2);
            DuplicatedXMLFields."Indirect Amount" := LibraryRandom.RandDecInRange(0, 100, 2);
            DuplicatedXMLFields."<Indirect %> Amount" := LibraryRandom.RandDecInRange(0, 100, 2);
            DuplicatedXMLFields.Insert();

            TempDuplicatedXMLFields := DuplicatedXMLFields;
            TempDuplicatedXMLFields.Insert();
        end;
    end;

    local procedure InsertDummyRSTableRecords(NumberOfEntries: Integer; var TempDummyRSTable: Record DummyRSTable temporary)
    var
        DummyRSTable: Record DummyRSTable;
        i: Integer;
    begin
        for i := 1 to NumberOfEntries do begin
            DummyRSTable."Entry No." := i;
            DummyRSTable."Decimal Field" := LibraryRandom.RandDecInRange(0, 100, 2);
            DummyRSTable."Date Field" := LibraryRandom.RandDateFrom(WorkDate(), 100);
            DummyRSTable."Code Field" := LibraryUtility.GenerateRandomCode20(DummyRSTable.FieldNo("Code Field"), Database::DummyRSTable);
            DummyRSTable."Text Field" := LibraryUtility.GenerateRandomText(MaxStrLen(DummyRSTable."Text Field"));
            DummyRSTable.Insert();

            TempDummyRSTable := DummyRSTable;
            TempDummyRSTable.Insert();
        end;
    end;

    local procedure VerifyEnumsAndOptionsAfterApplyingPackage()
    var
        OptionAndEnumRS: Record OptionAndEnumRS;
    begin
        OptionAndEnumRS.Get(0);
        Assert.AreEqual(OptionAndEnumRS.OptionField::Zero, OptionAndEnumRS.OptionField, 'Option or Enum values differ after rapidstart import');
        Assert.AreEqual(OptionAndEnumRS.EnumField::Eight, OptionAndEnumRS.EnumField, 'Option or Enum values differ after rapidstart import');

        OptionAndEnumRS.Get(1);
        Assert.AreEqual(OptionAndEnumRS.OptionField::One, OptionAndEnumRS.OptionField, 'Option or Enum values differ after rapidstart import');
        Assert.AreEqual(OptionAndEnumRS.EnumField::Nine, OptionAndEnumRS.EnumField, 'Option or Enum values differ after rapidstart import');

        OptionAndEnumRS.Get(2);
        Assert.AreEqual(OptionAndEnumRS.OptionField::Two, OptionAndEnumRS.OptionField, 'Option or Enum values differ after rapidstart import');
        Assert.AreEqual(OptionAndEnumRS.EnumField::Ten, OptionAndEnumRS.EnumField, 'Option or Enum values differ after rapidstart import');
    end;

    local procedure VerifyDuplicatedXMLFieldsRecords(var TempDuplicatedXMLFields: Record DuplicatedXMLFields temporary)
    var
        DuplicatedXMLFields: Record DuplicatedXMLFields;
    begin
        TempDuplicatedXMLFields.FindSet();
        repeat
            DuplicatedXMLFields.Get(TempDuplicatedXMLFields."Entry No.");
            DuplicatedXMLFields.TestField("<Indirect %> Amount", TempDuplicatedXMLFields."<Indirect %> Amount");
            DuplicatedXMLFields.TestField("Indirect (Amount) %", TempDuplicatedXMLFields."Indirect (Amount) %");
            DuplicatedXMLFields.TestField("Indirect Amount %", TempDuplicatedXMLFields."Indirect Amount %");
            DuplicatedXMLFields.TestField("Indirect Amount", TempDuplicatedXMLFields."Indirect Amount");
        until TempDuplicatedXMLFields.Next() = 0;
    end;

    local procedure VerifyDummyRSTableRecords(var TempDummyRSTable: Record DummyRSTable temporary)
    var
        DummyRSTable: Record DummyRSTable;
    begin
        TempDummyRSTable.FindSet();
        repeat
            DummyRSTable.Get(TempDummyRSTable."Entry No.");
            DummyRSTable.TestField("Decimal Field", TempDummyRSTable."Decimal Field");
            DummyRSTable.TestField("Date Field", TempDummyRSTable."Date Field");
            DummyRSTable.TestField("Code Field", TempDummyRSTable."Code Field");
            DummyRSTable.TestField("Text Field", TempDummyRSTable."Text Field");
        until TempDummyRSTable.Next() = 0;
    end;

    local procedure VerifyDuplicatedXMLFieldsRecordsExcelFile(var TempDuplicatedXMLFields: Record DuplicatedXMLFields temporary)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('A', 3, 1, TempDuplicatedXMLFields.FieldCaption("Entry No."));
        LibraryReportValidation.VerifyCellValueByRef('B', 3, 1, TempDuplicatedXMLFields.FieldCaption("Indirect Amount %"));
        LibraryReportValidation.VerifyCellValueByRef('C', 3, 1, TempDuplicatedXMLFields.FieldCaption("Indirect (Amount) %"));
        LibraryReportValidation.VerifyCellValueByRef('D', 3, 1, TempDuplicatedXMLFields.FieldCaption("Indirect Amount"));
        LibraryReportValidation.VerifyCellValueByRef('E', 3, 1, TempDuplicatedXMLFields.FieldCaption("<Indirect %> Amount"));
        LibraryReportValidation.VerifyCellValueByRef('B', 4, 1, LibraryReportValidation.FormatDecimalValue(TempDuplicatedXMLFields."Indirect Amount %"));
        LibraryReportValidation.VerifyCellValueByRef('C', 4, 1, LibraryReportValidation.FormatDecimalValue(TempDuplicatedXMLFields."Indirect (Amount) %"));
        LibraryReportValidation.VerifyCellValueByRef('D', 4, 1, LibraryReportValidation.FormatDecimalValue(TempDuplicatedXMLFields."Indirect Amount"));
        LibraryReportValidation.VerifyCellValueByRef('E', 4, 1, LibraryReportValidation.FormatDecimalValue(TempDuplicatedXMLFields."<Indirect %> Amount"));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PackageRecordsPageHandler(var ConfigPackageRecords: TestPage "Config. Package Records")
    begin
        ConfigPackageRecords.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PackageFieldsPageHandler(var ConfigPackageFields: TestPage "Config. Package Fields")
    begin
        ConfigPackageFields.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckProcessingOrderPackageFieldsPageHandler(var ConfigPackageFields: TestPage "Config. Package Fields")
    var
        NoOfFields: Integer;
        I: Integer;
    begin
        NoOfFields := LibraryVariableStorage.DequeueInteger();
        ConfigPackageFields.First();
        for I := 1 to NoOfFields do begin
            ConfigPackageFields."Processing Order".AssertEquals(I);
            ConfigPackageFields.Next();
        end;
        ConfigPackageFields.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure GetImageBase64Text(): Text
    begin
        exit(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAEnQAABJ0Ad5mH3gAAAAMSURBVBhXY3growIAAycBLhVrvukAAAAASUVORK5CYII=');
    end;

    local procedure GetExpectedMediaSet(var TmpConfigMediaBuffer: Record "Config. Media Buffer")
    var
        ConfigMediaBuffer: Record "Config. Media Buffer";
    begin
        TmpConfigMediaBuffer.Reset();
        TmpConfigMediaBuffer.DeleteAll();

        if not ConfigMediaBuffer.FindSet() then
            exit;

        repeat
            TmpConfigMediaBuffer.TransferFields(ConfigMediaBuffer, true);
            TmpConfigMediaBuffer.Insert();
        until ConfigMediaBuffer.Next() = 0;
    end;

    local procedure InitializeCRM()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMConnectionSetup.DeleteAll();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, '');
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);

        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Team;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);

        CRMConnectionSetup.Get('');
        CRMConnectionSetup.RegisterConnection();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Excel Exchange", 'OnImportExcelFile', '', false, false)]
    local procedure OnImportExcelToBLOBHandler(var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
        FileMgt.BLOBImportFromServerFile(TempBlob, FileNameForHandler);
        IsHandled := TempBlob.HasValue();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExcelImportPreviewHandler(var ConfigPackageImportPreview: TestPage "Config. Package Import Preview")
    var
        i: Integer;
        SheetCount: Integer;
    begin
        // gets Int as input - number of expected lines, puts lines content to VariableStorage; Runs Import action.
        Assert.IsTrue(ConfigPackageImportPreview.First(), 'there must be lines in preview page');
        SheetCount := LibraryVariableStorage.DequeueInteger();
        for i := 1 to SheetCount do begin
            LibraryVariableStorage.Enqueue(ConfigPackageImportPreview."Package Code".Value());
            LibraryVariableStorage.Enqueue(ConfigPackageImportPreview."New Package".AsBoolean());
            LibraryVariableStorage.Enqueue(ConfigPackageImportPreview."Table ID".AsInteger());
            LibraryVariableStorage.Enqueue(ConfigPackageImportPreview."Table Name".Value());
            LibraryVariableStorage.Enqueue(ConfigPackageImportPreview."New Table".AsBoolean());
            if SheetCount > i then
                Assert.IsTrue(ConfigPackageImportPreview.Next(), StrSubstNo(MissingLineErr, i + 1))
            else
                Assert.IsFalse(ConfigPackageImportPreview.Next(), StrSubstNo(ExistingLineErr, i + 1));
        end;
        ConfigPackageImportPreview.Import.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExcelImportPreviewSimpleHandler(var ConfigPackageImportPreview: TestPage "Config. Package Import Preview")
    begin
        ConfigPackageImportPreview.Import.Invoke();
    end;

    procedure GetLongText(): Text;
    begin
        exit('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam eros urna, lobortis a ligula ac, sagittis luctus risus. Praesent vehicula sem vitae mi ornare, et placerat mauris tristique. Nunc hendrerit ornare lacus. Fusce fringilla nec sem id vulputate. Fusce congue lorem sit amet nunc laoreet tincidunt. Donec lacinia cursus felis quis finibus. Praesent quis dui ut libero iaculis tristique quis quis urna. Maecenas elementum, tellus sed mollis ultricies, magna massa pretium quam, eget mattis nisl velit ac metus. Suspendisse finibus tortor sit amet ipsum commodo luctus. Etiam ut tellus ac purus commodo convallis. Suspendisse potenti. Nam vehicula, dolor nec laoreet elementum, nunc augue tristique eros, sed commodo nisl lorem nec mauris. Praesent rhoncus, elit nec tristique blandit, sapien lacus pulvinar lorem, nec aliquet tortor magna vel nunc. Fusce a nibh in magna laoreet ullamcorper eget quis ex. Sed nec odio id augue placerat molestie et at ex. Vivamus pellentesque eleifend imperdiet. Mauris dolor odio, malesuada a vestibulum eu, blandit quis elit. Nullam fringilla metus eu faucibus fringilla. Sed at ipsum tempus, hendrerit leo quis, tempor massa. Ut blandit sapien eget imperdiet sagittis. Nam mattis lobortis magna, at cursus quam hendrerit nec. Suspendisse semper ultrices urna, at fermentum nunc pulvinar sit amet. Morbi sollicitudin purus in arcu mattis, sed malesuada urna ornare. Curabitur pulvinar aliquam quam at sodales. Sed congue lectus fermentum efficitur dapibus. Aenean et velit suscipit, lobortis ipsum non, rutrum dui. Mauris purus nisl, dapibus id consectetur sed, tincidunt vel eros. Proin ultrices felis a sapien vehicula ullamcorper. Nulla laoreet velit et libero faucibus rutrum in a tellus. Praesent quis risus in massa dictum vehicula et nec dolor. Nullam dignissim bibendum vestibulum. Maecenas in tempus tortor, quis maximus urna. Sed aliquam et dui eget congue. In odio velit, dapibus quis ante at, fermentum pellentesque neque. Maecenas viverra fusce.');
    end;
}

