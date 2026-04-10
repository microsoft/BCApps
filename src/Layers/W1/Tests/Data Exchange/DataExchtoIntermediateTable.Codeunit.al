codeunit 139156 "DataExch to Intermediate Table"
{
    Permissions = TableData "Data Exch." = id;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Intermediate Data Import]
    end;

    var
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TargetTableFieldDefinitionMustBeSpeicfiedErr: Label 'You must specify a target table for the column definition.';

    local procedure Initialize()
    var
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        DataExchDef.DeleteAll();
        DataExch.DeleteAll();
        DataExchField.DeleteAll();
        DataExchColumnDef.DeleteAll();
        DataExchMapping.DeleteAll();
        DataExchFieldMapping.DeleteAll();
        IntermediateDataImport.DeleteAll();

        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingOneTableOnly()
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfRecords: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing single table
        // [THEN] it is properly imported into Intermediate Table
        Initialize();
        CreateCurrencyExchangeSetup(DataExchLineDef, DataExchDef);
        NumberOfRecords := 10;
        CreateCurrencyExchangeTestData(DataExch, DataExchLineDef, NumberOfRecords, CurrentNodeID, LineNo);

        // Execute
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToIntermediateTable(DataExch, DataExchLineDef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentChildTables()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records that have parent child relationship setup
        // [THEN] They are properly imported into Intermediate Table
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 3;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        // Execute
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToIntermediateTable(DataExch, SalesHeaderDataExchLineDef);
        VerifyValuesTransferredToIntermediateTable(DataExch, SalesLineDataExchLineDef);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(DataExch, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingMixedParentChildAndFlatTables()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        CurrencyExchangeRateDataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        NumberOfCurrencyExchangeRateRecords: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records with and without parent/child relationship setup
        // [THEN] They are properly imported into Intermediate Table
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);
        CreateCurrencyExchangeSetup(CurrencyExchangeRateDataExchLineDef, DataExchDef);

        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 1;
        NumberOfCurrencyExchangeRateRecords := 10;

        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);
        CreateCurrencyExchangeTestData(
          DataExch, CurrencyExchangeRateDataExchLineDef, NumberOfCurrencyExchangeRateRecords, CurrentNodeID, LineNo);

        // Execute
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToIntermediateTable(DataExch, SalesHeaderDataExchLineDef);
        VerifyValuesTransferredToIntermediateTable(DataExch, SalesLineDataExchLineDef);
        VerifyValuesTransferredToIntermediateTable(DataExch, CurrencyExchangeRateDataExchLineDef);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(DataExch, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentChildWithoutChildRecords()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        IntermediateDataImport: Record "Intermediate Data Import";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records that have parent child relationship setup but there is no child definitions
        // [THEN] They are properly imported into Intermediate Table
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 0;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        // Execute
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify Values Transferred correctly
        VerifyValuesTransferredToIntermediateTable(DataExch, SalesHeaderDataExchLineDef);
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", DATABASE::"Sales Line");
        Assert.IsTrue(IntermediateDataImport.IsEmpty, 'There should be no entries for Sales Line records');

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(DataExch, DATABASE::"Sales Header", DATABASE::"Sales Line", 0, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentHasDataWhileChildenDoNot()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        IntermediateDataImport: Record "Intermediate Data Import";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records and child records have only the record definition and no other data
        // [THEN] They are properly imported into Intermediate Table
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);
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
        NumberOfSalesLinesPerHeader := 0;
        // Execute
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify Values Transferred correctly
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", DATABASE::"Sales Line");
        Assert.IsTrue(IntermediateDataImport.IsEmpty, 'There should be no entries for Sales Line records');
        VerifyValuesTransferredToIntermediateTable(DataExch, SalesHeaderDataExchLineDef);

        // Verify Parent is assigned to child Lines
        VerifyParentIsAssignedToAllLines(DataExch, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMappingParentAndChildrenOnlyDefinitions()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        IntermediateDataImport: Record "Intermediate Data Import";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing multiple records where parent and child have only record definition
        // [THEN] They are properly imported into Intermediate Table
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);
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
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify Values Transferred correctly
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(IntermediateDataImport.IsEmpty, 'There should be no entries for Sales Header and Line records');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRunMappingTwice()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        CurrencyExchangeRateDataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        TempDataExchField: Record "Data Exch. Field" temporary;
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        NumberOfCurrencyExchangeRateRecords: Integer;
        I: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        // [WHEN] Importing data into Intermediate Table
        // [THEN] It is possible to import multiple times
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);
        CreateCurrencyExchangeSetup(CurrencyExchangeRateDataExchLineDef, DataExchDef);

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
            MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);
            LoadDataExchangeFieldIntoTemp(DataExch, DataExchDef, TempDataExchField);

            // Verify Values Transferred correctly
            VerifyValuesTransferredToIntermediateTableMultipleImport(DataExch, TempDataExchField, DataExchDef);

            // Verify Parent is assigned to child Lines
            VerifyParentIsAssignedToAllLines(DataExch, DATABASE::"Sales Header", DATABASE::"Sales Line", NumberOfSalesLinesPerHeader, 2);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoRecordsToMap()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        IntermediateDataImport: Record "Intermediate Data Import";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
    begin
        // [WHEN] There are no records to import but the definion is present
        // [THEN] No records are imported
        Initialize();
        DataExch.Init();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);

        // Execute
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify no data is present
        Assert.IsTrue(IntermediateDataImport.IsEmpty, 'No records should be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoDataExchangeDefinitionFieldsPresent()
    var
        DataExch: Record "Data Exch.";
        IntermediateDataImport: Record "Intermediate Data Import";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
    begin
        // [WHEN] There is no definition but the codeunit is run
        // [THEN] No records are imported
        Initialize();
        DataExch.Init();

        // Execute
        MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify no data is present
        Assert.IsTrue(IntermediateDataImport.IsEmpty, 'No records should be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingDataExchangeDefinition()
    var
        SalesHeaderDataExchLineDef: Record "Data Exch. Line Def";
        SalesLineDataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExch: Record "Data Exch.";
        MapDataExchToIntermediate: Codeunit "Map DataExch To Intermediate";
        NumberOfSalesHeaders: Integer;
        NumberOfSalesLinesPerHeader: Integer;
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        Initialize();
        CreateSalesHeaderAndSalesLinesSetup(SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, DataExchDef);
        NumberOfSalesHeaders := 2;
        NumberOfSalesLinesPerHeader := 3;
        CreateSalesHeaderAndSalesLinesTestData(
          DataExch, SalesHeaderDataExchLineDef, SalesLineDataExchLineDef, NumberOfSalesHeaders, NumberOfSalesLinesPerHeader,
          CurrentNodeID, LineNo);

        DataExchFieldMapping.DeleteAll();

        // Execute
        asserterror MapDataExchToIntermediate.ProcessAllLinesColumnMapping(DataExch);

        // Verify
        Assert.ExpectedError(TargetTableFieldDefinitionMustBeSpeicfiedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTIntermInsertUpdate()
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        EntryNo: Integer;
        ParentRecNo: Integer;
        RecNo: Integer;
        RandomValue: Text[250];
    begin
        Initialize();

        EntryNo := LibraryRandom.RandInt(100);
        ParentRecNo := 0;
        RecNo := 1;
        // Exercise / verify
        // Insert
        RandomValue := LibraryUtility.GenerateRandomCode(IntermediateDataImport.FieldNo(Value), DATABASE::"Intermediate Data Import");
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          ParentRecNo, RecNo, RandomValue);
        Assert.AreEqual(1, IntermediateDataImport.Count, 'Wrong number of entries in the intermediate table');
        Assert.AreEqual(RandomValue, IntermediateDataImport.Value, 'Wrong value for entry in the intermediate table');
        // Update
        RandomValue := LibraryUtility.GenerateRandomCode(IntermediateDataImport.FieldNo(Value), DATABASE::"Intermediate Data Import");
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          ParentRecNo, RecNo, RandomValue);
        Assert.AreEqual(1, IntermediateDataImport.Count, 'Wrong number of entries in the intermediate table');
        Assert.AreEqual(RandomValue, IntermediateDataImport.Value, 'Wrong value for entry in the intermediate table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTIntermGetValue()
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        EntryNo: Integer;
        ParentRecNo: Integer;
        RecNo: Integer;
        RandomValue: Text[250];
    begin
        Initialize();

        EntryNo := LibraryRandom.RandInt(100);
        ParentRecNo := 0;
        RecNo := 1;
        // Init
        RandomValue := LibraryUtility.GenerateRandomCode(IntermediateDataImport.FieldNo(Value), DATABASE::"Intermediate Data Import");
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          ParentRecNo, RecNo, RandomValue);
        Assert.AreEqual(1, IntermediateDataImport.Count, 'Wrong number of entries in the intermediate table');
        Assert.AreEqual(RandomValue, IntermediateDataImport.Value, 'Wrong value for entry in the intermediate table');
        // Get Value - Exercise/verify
        Assert.AreEqual(RandomValue, IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
            ParentRecNo, RecNo), 'Wrong value for entry in the intermediate table');
        IntermediateDataImport.Delete();
        Assert.AreEqual('', IntermediateDataImport.GetEntryValue(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
            ParentRecNo, RecNo), 'Value for entry should have been deleted from the intermediate table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTIntermFindEntry()
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        EntryNo: Integer;
        ParentRecNo: Integer;
        RecNo: Integer;
    begin
        Initialize();

        EntryNo := LibraryRandom.RandInt(100);
        ParentRecNo := 0;
        RecNo := 1;
        // Init
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."), ParentRecNo, RecNo,
          LibraryUtility.GenerateRandomCode(IntermediateDataImport.FieldNo(Value), DATABASE::"Intermediate Data Import"));
        Assert.AreEqual(1, IntermediateDataImport.Count, 'Wrong number of entries in the intermediate table');
        // insert new record no
        RecNo += 1;
        IntermediateDataImport.InsertOrUpdateEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."), ParentRecNo, RecNo,
          LibraryUtility.GenerateRandomCode(IntermediateDataImport.FieldNo(Value), DATABASE::"Intermediate Data Import"));
        Assert.AreEqual(2, IntermediateDataImport.Count, 'Wrong number of entries in the intermediate table');
        // Find entry - Exercise/verify
        Assert.IsTrue(IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
            ParentRecNo, RecNo - 1), 'Value for entry not found in the intermediate table');
        Assert.IsTrue(IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
            ParentRecNo, RecNo), 'Value for entry not found in the intermediate table');
        Assert.IsFalse(IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
            ParentRecNo + 1, RecNo), 'Value for entry should not exist in the intermediate table');
        Assert.IsFalse(IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
            ParentRecNo, RecNo + 1), 'Value for entry should not exist in the intermediate table');
        Assert.IsFalse(IntermediateDataImport.FindEntry(EntryNo + 1, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
            ParentRecNo, RecNo), 'Value for entry should not exist in the intermediate table');
        Assert.IsFalse(IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Line", PurchaseHeader.FieldNo("No."),
            ParentRecNo, RecNo), 'Value for entry should not exist in the intermediate table');
        Assert.IsFalse(IntermediateDataImport.FindEntry(EntryNo, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
            ParentRecNo, RecNo), 'Value for entry should not exist in the intermediate table');
    end;

    local procedure CreateSalesHeaderAndSalesLinesSetup(var SalesHeaderDataExchLineDef: Record "Data Exch. Line Def"; var SalesLineDataExchLineDef: Record "Data Exch. Line Def"; var DataExchDef: Record "Data Exch. Def")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ColumnNo: Integer;
    begin
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
              '', I);
            CreateDataExchangeField(
              DataExchField, DataExch, SalesHeaderDataExchLineDef, 2, '', ValueNodeID, '', I);
            CreateDataExchangeField(
              DataExchField, DataExch, SalesHeaderDataExchLineDef, 3, Customer."No.", ValueNodeID, '', I);

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
        I: Integer;
    begin
        if DataExch."Entry No." = 0 then
            CreateDataExchange(DataExchLineDef, DataExch);

        for I := 1 to NoOfRecords do begin
            CurrentNodeID += 1;
            LineNo += 1;

            // Insert Sales Header record definition
            CreateDataExchangeField(DataExchField, DataExch, DataExchLineDef, -1, '', CurrentNodeID, '', I);

            LibraryERM.CreateCurrency(Currency);

            // Insert other values
            ValueNodeID := 1;
            CreateDataExchangeField(
              DataExchField, DataExch, DataExchLineDef, 11, Currency.Code, ValueNodeID, '', I);
            CreateDataExchangeField(
              DataExchField, DataExch, DataExchLineDef, 12, Format(Today), ValueNodeID, '', I);
            CreateDataExchangeField(
              DataExchField, DataExch, DataExchLineDef, 13, Format(LibraryRandom.RandDecInRange(1, 10000, 2)), CurrentNodeID,
              '', I);
        end;
    end;

    local procedure CreateCurrencyExchangeSetup(var DataExchLineDef: Record "Data Exch. Line Def"; var DataExchDef: Record "Data Exch. Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ColumnNo: Integer;
    begin
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
          CODEUNIT::"Map DataExch To Intermediate", CODEUNIT::"Import XML File to Data Exch.", 0, 0, 0);
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
        DataExchMapping.Validate("Table ID", DATABASE::"Intermediate Data Import");
        DataExchMapping.Insert(true);
    end;

    local procedure CreateDataExchFieldMapping(DataExchColumnDef: Record "Data Exch. Column Def"; TargetTableID: Integer; TargetFieldID: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchColumnDef."Data Exch. Def Code");
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchColumnDef."Data Exch. Line Def Code");
        DataExchFieldMapping.Validate("Table ID", DATABASE::"Intermediate Data Import");
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
        LineNodeID: Integer;
    begin
        CreateDataExchangeField(
          DataExchField, DataExch, SalesLineDataExchLineDef, -1, '', CurrentNodeID, SalesHeaderRecordDefinitionNodeID, LineNo);

        LineNodeID := 1;
        LibraryInventory.CreateItem(Item);
        CreateDataExchangeField(
          DataExchField, DataExch, SalesLineDataExchLineDef, 1, Item."No.", LineNodeID, SalesHeaderRecordDefinitionNodeID, LineNo);
        CreateDataExchangeField(
          DataExchField, DataExch, SalesLineDataExchLineDef, 2, Format(LibraryRandom.RandIntInRange(1, 10)), LineNodeID,
          SalesHeaderRecordDefinitionNodeID, LineNo);
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

    local procedure VerifyValuesTransferredToIntermediateTable(DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchField: Record "Data Exch. Field";
        DataExchField2: Record "Data Exch. Field";
    begin
        GetDataExchangeFieldsWithValuesOnly(DataExch, DataExchLineDef, DataExchField);
        VerifyValuesTransferredToIntermediateTable2(DataExch, DataExchField, DataExchField2, DataExchLineDef);
    end;

    local procedure VerifyValuesTransferredToIntermediateTableMultipleImport(DataExch: Record "Data Exch."; var TempDataExchField: Record "Data Exch. Field" temporary; DataExchDef: Record "Data Exch. Def")
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
            VerifyValuesTransferredToIntermediateTable2(DataExch, TempDataExchField, TempReferenceDataExchField, DataExchLineDef);
        until DataExchLineDef.Next() = 0;
    end;

    local procedure VerifyValuesTransferredToIntermediateTable2(DataExch: Record "Data Exch."; var DataExchField: Record "Data Exch. Field"; var ReferenceDataExchField: Record "Data Exch. Field"; DataExchLineDef: Record "Data Exch. Line Def")
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.FindSet();

        repeat
            DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
            DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
            DataExchFieldMapping.SetRange("Column No.", DataExchField."Column No.");
            DataExchFieldMapping.FindFirst();

            IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
            IntermediateDataImport.SetRange("Table ID", DataExchFieldMapping."Target Table ID");
            IntermediateDataImport.SetRange("Field ID", DataExchFieldMapping."Target Field ID");
            IntermediateDataImport.SetRange(Value, DataExchField.Value);

            ReferenceDataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
            ReferenceDataExchField.SetFilter("Column No.", '>0');
            ReferenceDataExchField.SetRange(Value, DataExchField.Value);
            ReferenceDataExchField.SetRange("Data Exch. No.", DataExchField."Data Exch. No.");

            Assert.AreEqual(
              ReferenceDataExchField.Count, IntermediateDataImport.Count,
              'There should be same number of values in Intermediate Data Import table');
        until DataExchField.Next() = 0;
    end;

    local procedure VerifyParentIsAssignedToAllLines(DataExch: Record "Data Exch."; ParentTableID: Integer; ChildTableID: Integer; NumberOfRecordsPerParent: Integer; NumberOfValuesPerSalesLine: Integer)
    var
        ChildIntermediateDataImport: Record "Intermediate Data Import";
        ParentIntermediateDataImport: Record "Intermediate Data Import";
    begin
        ParentIntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        ParentIntermediateDataImport.SetRange("Table ID", ParentTableID);

        ChildIntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        ChildIntermediateDataImport.SetRange("Table ID", ChildTableID);

        ParentIntermediateDataImport.FindSet();

        repeat
            ChildIntermediateDataImport.SetRange("Parent Record No.", ParentIntermediateDataImport."Record No.");
            Assert.AreEqual(NumberOfRecordsPerParent * NumberOfValuesPerSalesLine,
              ChildIntermediateDataImport.Count, 'Wrong number of Child Records found');
        until ParentIntermediateDataImport.Next() = 0;
    end;
}

