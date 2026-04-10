codeunit 139153 "Data Exch. to RapidStart UT"
{
    Permissions = TableData "Data Exch." = id;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start] [Data Exchange] [Mapping]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TargetTableFieldDefinitionMustBeSpeicfiedErr: Label 'You must specify a target table for the column definition.';

    local procedure Initialize()
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageRecord: Record "Config. Package Record";
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        ConfigPackage.DeleteAll();
        ConfigPackageTable.DeleteAll();
        ConfigPackageData.DeleteAll();
        ConfigPackageRecord.DeleteAll();

        DataExchDef.DeleteAll();
        DataExch.DeleteAll();
        DataExchField.DeleteAll();
        DataExchColumnDef.DeleteAll();
        DataExchMapping.DeleteAll();
        DataExchFieldMapping.DeleteAll();

        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingOneTableOnly()
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfRecords: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing single table
        // [THEN] it is properly imported into RapidStart
        Initialize();
        CreateCurrencyExchangeSetup(DataExchLineDef, ConfigPackage, DataExchDef);
        NumberOfRecords := 10;
        CreateCurrencyExchangeTestData(DataExch, DataExchLineDef, NumberOfRecords, CurrentNodeID, LineNo);

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, DataExchLineDef);

        // Verify Records Are Created
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Currency Exchange Rate", NumberOfRecords);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentChildTables()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records that have parent child relationship setup
        // [THEN] They are properly imported into RapidStart
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 3;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, SalesHeaderDataExchLineDef);
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, SalesLineDataExchLineDef);

        // Verify Records Are Created
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Header", NumberOfSalesHeaders);
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Line", NumberOfSalesHeaders * NumberOfSalesLinesPerHeader);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(ConfigPackage, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingMixedParentChildAndFlatTables()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        CurrencyExchangeRateDataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        NumberOfCurrencyExchangeRateRecords: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records with and without parent/child relationship setup
        // [THEN] They are properly imported into RapidStart
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        CreateCurrencyExchangeSetup(CurrencyExchangeRateDataExchLineDef, ConfigPackage, DataExchDef);

        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 1;
        NumberOfCurrencyExchangeRateRecords := 10;

        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);
        CreateCurrencyExchangeTestData(
          DataExch, CurrencyExchangeRateDataExchLineDef, NumberOfCurrencyExchangeRateRecords, CurrentNodeID, LineNo);

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, SalesHeaderDataExchLineDef);
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, SalesLineDataExchLineDef);
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, CurrencyExchangeRateDataExchLineDef);

        // Verify Records Are Created
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Header", NumberOfSalesHeaders);
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Line", NumberOfSalesHeaders * NumberOfSalesLinesPerHeader);
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Currency Exchange Rate", NumberOfCurrencyExchangeRateRecords);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(ConfigPackage, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentChildWithoutChildRecords()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        ConfigPackageData: Record "Config. Package Data";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records that have parent child relationship setup but there is no child definitions
        // [THEN] They are properly imported into RapidStart
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 0;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, SalesHeaderDataExchLineDef);
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Table ID", DATABASE::"Sales Line");
        Assert.IsTrue(ConfigPackageData.IsEmpty, 'There should be no entries for Sales Line records');

        // Verify No Records are
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Header", NumberOfSalesHeaders);
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Line", 0);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(ConfigPackage, DATABASE::"Sales Header", DATABASE::"Sales Line", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentHasNoDataWhileChildenDoes()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records and parent has the only record definition and no other data
        // [THEN] They are properly imported into RapidStart
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 3;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        // Remove all field values except the record definition
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetFilter("Column No.", '<>-1');
        DataExchField.SetRange("Data Exch. Line Def Code", SalesHeaderDataExchLineDef.Code);
        DataExchField.DeleteAll();

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify Values Transferred correctly
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Table ID", DATABASE::"Sales Header");
        Assert.IsTrue(ConfigPackageData.IsEmpty, 'There should be no entries for Sales Header records');
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, SalesLineDataExchLineDef);

        // Verify Records Are Created
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Header", NumberOfSalesHeaders);
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Line", NumberOfSalesHeaders * NumberOfSalesLinesPerHeader);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(ConfigPackage, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentHasDataWhileChildenDoNot()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records and child records have only the record definition and no other data
        // [THEN] They are properly imported into RapidStart
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 3;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        // Remove all field values except the record definition
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetFilter("Column No.", '<>-1');
        DataExchField.SetRange("Data Exch. Line Def Code", SalesLineDataExchLineDef.Code);
        DataExchField.DeleteAll();

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify Values Transferred correctly
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetRange("Table ID", DATABASE::"Sales Line");
        Assert.IsTrue(ConfigPackageData.IsEmpty, 'There should be no entries for Sales Line records');
        VerifyValuesTransferredToRapidStart(DataExch, ConfigPackage, SalesHeaderDataExchLineDef);

        // Verify Records Are Created
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Header", NumberOfSalesHeaders);
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Line", NumberOfSalesHeaders * NumberOfSalesLinesPerHeader);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(ConfigPackage, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentAndChildrenOnlyDefinitions()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        ConfigPackageData: Record "Config. Package Data";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records where parent and child have only record definition
        // [THEN] They are properly imported into RapidStart
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 3;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        // Remove all field values except the record definition
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetFilter("Column No.", '<>-1');
        DataExchField.DeleteAll();

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify Values Transferred correctly
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        Assert.IsTrue(ConfigPackageData.IsEmpty, 'There should be no entries for Sales Header and Line records');

        // Verify Records are not Created
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Header", NumberOfSalesHeaders);
        VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Line", NumberOfSalesHeaders * NumberOfSalesLinesPerHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunMappingTwice()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        CurrencyExchangeRateDataExchLineDef: Record "Data Exch. Line Def";
        ConfigPackage: Record "Config. Package";
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        TempDataExchField: Record "Data Exch. Field" temporary;
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        NumberOfCurrencyExchangeRateRecords: Integer;
        I: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing data into RapidStart
        // [THEN] It is possible to import multiple times
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        CreateCurrencyExchangeSetup(CurrencyExchangeRateDataExchLineDef, ConfigPackage, DataExchDef);

        for I := 1 to 2 do begin
            // Clean up from previous mapping
            DataExch.DeleteAll();
            DataExchField.DeleteAll();
            Clear(DataExch);
            Clear(DataExchField);

            NumberOfSalesHeaders := 2;
            NumberOfSalesLinesPerHeader := 1;
            NumberOfCurrencyExchangeRateRecords := 10;

            CreateSalesHeaderAndSalesLinesTestData(
              DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
              CurrentNodeID, LineNo);
            CreateCurrencyExchangeTestData(
              DataExch, CurrencyExchangeRateDataExchLineDef, NumberOfCurrencyExchangeRateRecords, CurrentNodeID, LineNo);

            // Execute
            MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);
            LoadDataExchangeFieldIntoTemp(DataExch, DataExchDef, TempDataExchField);

            // Verify Values Transferred correctly
            VerifyValuesTransferredToRapidStartMultipleImport(TempDataExchField, DataExchDef, ConfigPackage);

            // Verify Records Are Created
            VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Header", I * NumberOfSalesHeaders);
            VerifyRapidStartRecords(ConfigPackage, DATABASE::"Sales Line", I * NumberOfSalesHeaders * NumberOfSalesLinesPerHeader);
            VerifyRapidStartRecords(ConfigPackage, DATABASE::"Currency Exchange Rate", I * NumberOfCurrencyExchangeRateRecords);

            // Verify Parent is assigned to child Lines
            VerifyParentIsAssignedToAllLines(ConfigPackage, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoRecordsToMap()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        ConfigPackage: Record "Config. Package";
        DataExch: Record "Data Exch.";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageRecord: Record "Config. Package Record";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
    begin
        // [WHEN] There are no records to import but the definion is present
        // [THEN] No records are imported
        Initialize();
        DataExch.Init();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify no data is present
        Assert.IsTrue(ConfigPackageData.IsEmpty, 'No records should be present');
        Assert.IsTrue(ConfigPackageRecord.IsEmpty, 'No records should be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoDataExchangeDefinitionFieldsPresent()
    var
        ConfigPackage: Record "Config. Package";
        DataExch: Record "Data Exch.";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageRecord: Record "Config. Package Record";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
    begin
        // [WHEN] There is no definition but the codeunit is run
        // [THEN] No records are imported
        Initialize();
        DataExch.Init();
        ConfigPackage.Init();

        // Execute
        MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify no data is present
        Assert.IsTrue(ConfigPackageData.IsEmpty, 'No records should be present');
        Assert.IsTrue(ConfigPackageRecord.IsEmpty, 'No records should be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingDataExchangeDefinition()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        ConfigPackage: Record "Config. Package";
        DataExch: Record "Data Exch.";
        MapDataExchToRapidStart: Codeunit "Map Data Exch. To RapidStart";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, ConfigPackage, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 3;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        DataExchFieldMapping.DeleteAll();

        // Execute
        asserterror MapDataExchToRapidStart.ProcessAllLinesColumnMapping(DataExch, ConfigPackage.Code);

        // Verify
        Assert.ExpectedError(TargetTableFieldDefinitionMustBeSpeicfiedErr);
    end;

    local procedure CreateSalesHeaderAndSalesLinesSetup(var SalesHeaderDataExchLineDef: Record "Data Exch. Line Def"; var SalesLineDataExchLineDef: Record "Data Exch. Line Def"; var ConfigPackage: Record "Config. Package"; var DataExchDef: Record "Data Exch. Def")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProcessingOrder: Integer;
        ColumnNo: Integer;
    begin
        // RapidStart Setup
        if ConfigPackage.Code = '' then
            CreateConfigPackage(ConfigPackage);

        ProcessingOrder := 1;
        CreateConfigPackageTable(ProcessingOrder, ConfigPackage, DATABASE::"Sales Header");
        CreateConfigPackageTable(ProcessingOrder, ConfigPackage, DATABASE::"Sales Line");

        // Data Exchange Setup
        if DataExchDef.Code = '' then
            CreateDataExchangeDefinition(DataExchDef);

        ColumnNo := 1;
        SalesHeaderDataExchLineDef.InsertRec(DataExchDef.Code, 'SH', 'Sales Header', 0);
        CreateDataExchMapping(SalesHeaderDataExchLineDef);
        MapFields(ColumnNo, SalesHeaderDataExchLineDef, DATABASE::"Sales Header", SalesHeader.FieldNo("Document Type"));
        MapFields(ColumnNo, SalesHeaderDataExchLineDef, DATABASE::"Sales Header", SalesHeader.FieldNo("No."));
        MapFields(ColumnNo, SalesHeaderDataExchLineDef, DATABASE::"Sales Header", SalesHeader.FieldNo("Sell-to Customer No."));

        ColumnNo := 1;
        SalesLineDataExchLineDef.InsertRec(DataExchDef.Code, 'SL', 'Sales Line', 0);
        SalesLineDataExchLineDef.Validate("Parent Code", SalesHeaderDataExchLineDef.Code);
        SalesLineDataExchLineDef.Modify(true);

        CreateDataExchMapping(SalesLineDataExchLineDef);
        MapFields(ColumnNo, SalesLineDataExchLineDef, DATABASE::"Sales Line", SalesLine.FieldNo("No."));
        MapFields(ColumnNo, SalesLineDataExchLineDef, DATABASE::"Sales Line", SalesLine.FieldNo(Quantity));
    end;

    local procedure CreateSalesHeaderAndSalesLinesTestData(var DataExch: Record "Data Exch."; SalesHeaderDataExchLineDef: Record "Data Exch. Line Def"; SalesLineDataExchLineDef: Record "Data Exch. Line Def"; NoOfHeaders: Integer; NoOfLines: Integer; var CurrentNodeID: Integer; var LineNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesHeaderRecordDefinitionNodeID: Text[250];
        I: Integer;
        J: Integer;
        ValueNodeID: Integer;
    begin
        if DataExch."Entry No." = 0 then
            CreateDataExchange(SalesHeaderDataExchLineDef, DataExch);

        for I := 1 to NoOfHeaders do begin
            CurrentNodeID += 1;
            LineNo += 1;

            // Insert Sales Header record definition
            CreateDataExchangeField(DataExchField, DataExch, SalesHeaderDataExchLineDef, -1, '', CurrentNodeID, '', I);
            SalesHeaderRecordDefinitionNodeID := DataExchField."Node ID";

            // Insert other values
            ValueNodeID := 1;
            Clear(Customer);
            LibrarySales.CreateCustomer(Customer);
            CreateDataExchangeField(
              DataExchField, DataExch, SalesHeaderDataExchLineDef, 1, Format(SalesHeader."Document Type"::Invoice), ValueNodeID,
              SalesHeaderRecordDefinitionNodeID, I);
            CreateDataExchangeField(
              DataExchField, DataExch, SalesHeaderDataExchLineDef, 2, '', ValueNodeID, SalesHeaderRecordDefinitionNodeID, I);
            CreateDataExchangeField(
              DataExchField, DataExch, SalesHeaderDataExchLineDef, 3, Customer."No.", ValueNodeID, SalesHeaderRecordDefinitionNodeID, I);

            for J := 1 to NoOfLines do begin
                CreateSalesLineDefinition(ValueNodeID, SalesHeaderRecordDefinitionNodeID, SalesLineDataExchLineDef, DataExch, LineNo);
                LineNo += 1;
            end;
        end;
    end;

    local procedure CreateCurrencyExchangeTestData(var DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; NoOfRecords: Integer; var CurrentNodeID: Integer; var LineNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        Currency: Record Currency;
        ValueNodeID: Integer;
        RecordDefinitionNodeID: Text[250];
        I: Integer;
    begin
        if DataExch."Entry No." = 0 then
            CreateDataExchange(DataExchLineDef, DataExch);

        for I := 1 to NoOfRecords do begin
            CurrentNodeID += 1;
            LineNo += 1;

            // Insert Sales Header record definition
            CreateDataExchangeField(DataExchField, DataExch, DataExchLineDef, -1, '', CurrentNodeID, '', I);
            RecordDefinitionNodeID := DataExchField."Node ID";

            LibraryERM.CreateCurrency(Currency);

            // Insert other values
            ValueNodeID := 1;
            CreateDataExchangeField(
              DataExchField, DataExch, DataExchLineDef, 11, Currency.Code, ValueNodeID, RecordDefinitionNodeID, I);
            CreateDataExchangeField(
              DataExchField, DataExch, DataExchLineDef, 12, Format(Today), ValueNodeID, RecordDefinitionNodeID, I);
            CreateDataExchangeField(
              DataExchField, DataExch, DataExchLineDef, 13, Format(LibraryRandom.RandDecInRange(1, 10000, 2)), CurrentNodeID,
              RecordDefinitionNodeID, I);
        end;
    end;

    local procedure CreateCurrencyExchangeSetup(var DataExchLineDef: Record "Data Exch. Line Def"; var ConfigPackage: Record "Config. Package"; var DataExchDef: Record "Data Exch. Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ProcessingOrder: Integer;
        ColumnNo: Integer;
    begin
        // RapidStart Setup
        if ConfigPackage.Code = '' then
            CreateConfigPackage(ConfigPackage);

        ProcessingOrder := 1;
        CreateConfigPackageTable(ProcessingOrder, ConfigPackage, DATABASE::"Currency Exchange Rate");

        // Data Exchange Setup
        if DataExchDef.Code = '' then
            CreateDataExchangeDefinition(DataExchDef);

        ColumnNo := 11;
        DataExchLineDef.InsertRec(DataExchDef.Code, 'CEXR', 'Currency Exchange Rate', 0);
        CreateDataExchMapping(DataExchLineDef);

        MapFields(ColumnNo, DataExchLineDef, DATABASE::"Currency Exchange Rate", CurrencyExchangeRate.FieldNo("Currency Code"));
        MapFields(ColumnNo, DataExchLineDef, DATABASE::"Currency Exchange Rate", CurrencyExchangeRate.FieldNo("Starting Date"));
        MapFields(ColumnNo, DataExchLineDef, DATABASE::"Currency Exchange Rate", CurrencyExchangeRate.FieldNo("Exchange Rate Amount"));
    end;

    local procedure CreateDataExchangeDefinition(var DataExchDef: Record "Data Exch. Def")
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, CODEUNIT::"Import XML File to Data Exch.",
          CODEUNIT::"Map Data Exch. To RapidStart", CODEUNIT::"Import XML File to Data Exch.", 0, 0, 0);
    end;

    local procedure CreateConfigPackage(var ConfigPackage: Record "Config. Package")
    begin
        ConfigPackage.Init();
        ConfigPackage.Code := LibraryUtility.GenerateRandomCode(ConfigPackage.FieldNo(Code), DATABASE::"Config. Package");
        ConfigPackage."Exclude Config. Tables" := true;
        ConfigPackage."Language ID" := GlobalLanguage;
        ConfigPackage.Insert(true);
    end;

    local procedure CreateConfigPackageTable(var ProcessingOrder: Integer; ConfigPackage: Record "Config. Package"; TableID: Integer)
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.Init();
        ConfigPackageTable.Validate("Package Code", ConfigPackage.Code);
        ConfigPackageTable.Validate("Table ID", TableID);
        ConfigPackageTable.Validate("Package Processing Order", ProcessingOrder);
        ProcessingOrder += 1;
        ConfigPackageTable.Insert(true);
    end;

    local procedure CreateDataExchangeColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer; Path: Text[250])
    begin
        DataExchColumnDef.Init();
        DataExchColumnDef.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.Validate("Column No.", ColumnNo);
        DataExchColumnDef.Validate(Path, Path);
        DataExchColumnDef.Insert(true);
    end;

    local procedure CreateDataExchMapping(DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Init();
        DataExchMapping.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.Validate("Table ID", DATABASE::"Config. Package Data");
        DataExchMapping.Insert(true);
    end;

    local procedure CreateDataExchFieldMapping(DataExchColumnDef: Record "Data Exch. Column Def"; TargetTableID: Integer; TargetFieldID: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchColumnDef."Data Exch. Def Code");
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchColumnDef."Data Exch. Line Def Code");
        DataExchFieldMapping.Validate("Table ID", DATABASE::"Config. Package Data");
        DataExchFieldMapping.Validate("Column No.", DataExchColumnDef."Column No.");
        DataExchFieldMapping.Validate("Target Table ID", TargetTableID);
        DataExchFieldMapping.Validate("Target Field ID", TargetFieldID);
        DataExchFieldMapping.Insert(true);
    end;

    local procedure CreateDataExchange(DataExchLineDef: Record "Data Exch. Line Def"; var DataExch: Record "Data Exch.")
    begin
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
    end;

    local procedure CreateDataExchangeField(var DataExchField: Record "Data Exch. Field"; DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer; TextValue: Text[250]; CurrentNodeID: Integer; ParentNodeID: Text[250]; LineNo: Integer)
    begin
        DataExchField.Init();
        DataExchField.Validate("Data Exch. No.", DataExch."Entry No.");
        DataExchField.Validate("Column No.", ColumnNo);
        DataExchField.Validate("Node ID", GetNodeID(CurrentNodeID, ParentNodeID));
        if ColumnNo = -1 then
            DataExchField.Validate("Parent Node ID", ParentNodeID);
        DataExchField.Validate(Value, TextValue);
        DataExchField.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchField.Validate("Line No.", LineNo);
        DataExchField.Insert(true);
    end;

    local procedure CreateSalesLineDefinition(var CurrentNodeID: Integer; SalesHeaderRecordDefinitionNodeID: Text[250]; SalesLineDataExchLineDef: Record "Data Exch. Line Def"; DataExch: Record "Data Exch."; LineNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        Item: Record Item;
        SalesLineRecordDefinitionNodeID: Text[250];
        LineNodeID: Integer;
    begin
        CreateDataExchangeField(
          DataExchField, DataExch, SalesLineDataExchLineDef, -1, '', CurrentNodeID, SalesHeaderRecordDefinitionNodeID, LineNo);
        SalesLineRecordDefinitionNodeID := DataExchField."Node ID";

        LineNodeID := 1;
        LibraryInventory.CreateItem(Item);
        CreateDataExchangeField(
          DataExchField, DataExch, SalesLineDataExchLineDef, 1, Item."No.", LineNodeID, SalesLineRecordDefinitionNodeID, LineNo);
        CreateDataExchangeField(
          DataExchField, DataExch, SalesLineDataExchLineDef, 2, Format(LibraryRandom.RandIntInRange(1, 10)), LineNodeID,
          SalesLineRecordDefinitionNodeID, LineNo);
        CurrentNodeID += 1;
    end;

    local procedure MapFields(var ColumnNo: Integer; DataExchLineDef: Record "Data Exch. Line Def"; TargetTableID: Integer; TargetFieldID: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        CreateDataExchangeColumnDef(DataExchColumnDef, DataExchLineDef, ColumnNo, '');
        CreateDataExchFieldMapping(DataExchColumnDef, TargetTableID, TargetFieldID);
        ColumnNo += 1;
    end;

    local procedure GetNodeID(CurrentNodeCount: Integer; ParentNodeID: Text): Text
    begin
        exit(ParentNodeID + Format(CurrentNodeCount, 0, '<Integer,4><Filler Char,0>'))
    end;

    local procedure GetDataExchangeFieldsWithValuesOnly(DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; var DataExchField: Record "Data Exch. Field")
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchField.SetFilter("Column No.", '>0');
        DataExchField.FindSet();
    end;

    local procedure LoadDataExchangeFieldIntoTemp(DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; var TempDataExchField: Record "Data Exch. Field" temporary)
    var
        DataExchField: Record "Data Exch. Field";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindSet();

        repeat
            Clear(DataExchField);
            GetDataExchangeFieldsWithValuesOnly(DataExch, DataExchLineDef, DataExchField);
            repeat
                TempDataExchField := DataExchField;
                TempDataExchField.Insert();
            until DataExchField.Next() = 0;
        until DataExchLineDef.Next() = 0;
    end;

    local procedure VerifyValuesTransferredToRapidStart(DataExch: Record "Data Exch."; ConfigPackage: Record "Config. Package"; DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchField: Record "Data Exch. Field";
        DataExchField2: Record "Data Exch. Field";
    begin
        GetDataExchangeFieldsWithValuesOnly(DataExch, DataExchLineDef, DataExchField);
        VerifyValuesTransferredToRapidStart2(DataExchField, DataExchField2, ConfigPackage, DataExchLineDef);
    end;

    local procedure VerifyValuesTransferredToRapidStartMultipleImport(var TempDataExchField: Record "Data Exch. Field" temporary; DataExchDef: Record "Data Exch. Def"; ConfigPackage: Record "Config. Package")
    var
        TempReferenceDataExchField: Record "Data Exch. Field" temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        TempDataExchField.Reset();
        TempDataExchField.FindSet();
        repeat
            TempReferenceDataExchField := TempDataExchField;
            TempReferenceDataExchField.Insert();
        until TempDataExchField.Next() = 0;

        TempReferenceDataExchField.FindFirst();

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindSet();
        repeat
            VerifyValuesTransferredToRapidStart2(TempDataExchField, TempReferenceDataExchField, ConfigPackage, DataExchLineDef);
        until DataExchLineDef.Next() = 0;
    end;

    local procedure VerifyValuesTransferredToRapidStart2(var DataExchField: Record "Data Exch. Field"; var ReferenceDataExchField: Record "Data Exch. Field"; ConfigPackage: Record "Config. Package"; DataExchLineDef: Record "Data Exch. Line Def")
    var
        ConfigPackageData: Record "Config. Package Data";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchField.FindSet();

        repeat
            DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
            DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
            DataExchFieldMapping.SetRange("Column No.", DataExchField."Column No.");
            DataExchFieldMapping.FindFirst();

            ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
            ConfigPackageData.SetRange("Table ID", DataExchFieldMapping."Target Table ID");
            ConfigPackageData.SetRange("Field ID", DataExchFieldMapping."Target Field ID");
            ConfigPackageData.SetRange(Value, DataExchField.Value);

            ReferenceDataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
            ReferenceDataExchField.SetFilter("Column No.", '>0');
            ReferenceDataExchField.SetRange(Value, DataExchField.Value);

            Assert.AreEqual(
              ReferenceDataExchField.Count, ConfigPackageData.Count, 'There should be same number of values in the Config Package Data');
        until DataExchField.Next() = 0;
    end;

    local procedure VerifyRapidStartRecords(ConfigPackage: Record "Config. Package"; TableID: Integer; ExpectedNumberOfRecords: Integer)
    var
        ConfigPackageRecord: Record "Config. Package Record";
    begin
        ConfigPackageRecord.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageRecord.SetRange("Table ID", TableID);
        Assert.AreEqual(ExpectedNumberOfRecords, ConfigPackageRecord.Count, 'Wrong number of Config Package Records');
    end;

    local procedure VerifyParentIsAssignedToAllLines(ConfigPackage: Record "Config. Package"; ParentTableID: Integer; ChildTableID: Integer; NumberOfRecordsPerParent: Integer)
    var
        ChildConfigPackageRecord: Record "Config. Package Record";
        ParentConfigPackageRecord: Record "Config. Package Record";
    begin
        ParentConfigPackageRecord.SetRange("Package Code", ConfigPackage.Code);
        ParentConfigPackageRecord.SetRange("Table ID", ParentTableID);

        ChildConfigPackageRecord.SetRange("Package Code", ConfigPackage.Code);
        ChildConfigPackageRecord.SetRange("Table ID", ChildTableID);

        ParentConfigPackageRecord.FindSet();

        repeat
            ChildConfigPackageRecord.SetRange("Parent Record No.", ParentConfigPackageRecord."No.");
            Assert.AreEqual(NumberOfRecordsPerParent, ChildConfigPackageRecord.Count, 'Wrong number of Child Records found');
        until ParentConfigPackageRecord.Next() = 0;
    end;
}

