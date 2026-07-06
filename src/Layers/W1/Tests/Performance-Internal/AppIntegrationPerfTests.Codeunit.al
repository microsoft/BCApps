codeunit 139092 "App Integration Perf Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [INT]
        LibraryPerformanceProfiler.SetProfilerIdentification('139092 - App Integration Perf Tests')
    end;

    var
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPerformanceProfiler: Codeunit "Library - Performance Profiler";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        isInitialized: Boolean;
        TraceDumpFilePath: Text;
        DefualtExchangeRateAmount: Decimal;
        NumberOfCurrencies: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesOrderFromCRMSalesOrder()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        APIMockEvents: Codeunit "API Mock Events";
    begin
        Initialize();
        ClearCRMData();

        // CDS SystemID uptake should remove this call
        APIMockEvents.SetIsIntegrationManagementEnabled(true);
        BindSubscription(APIMockEvents);
        CreateCRMSalesorderInLCY(CRMSalesorder);

        LibraryPerformanceProfiler.StartProfiler(true);
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestCreateSalesOrderFromCRMSalesOrder',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"CRM Sales Order to Sales Order", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchCustomerCoupledToCRMAccount()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        UncoupledCRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        // [GIVEN] A valid and registered CRM Connection Setup
        Initialize();

        // [GIVEN] A mapping allowing synch only for coupled records (the default setting)
        ResetDefaultCRMSetupConfiguration();

        // [GIVEN] A CRM source with two records, one coupled and one not coupled
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(UncoupledCRMAccount);

        // [GIVEN] The coupled record has different data on both sides
        // This is the default at the moment because both are randomly generated, but just in case:
        CRMAccount.Name := 'New Name';
        CRMAccount.Modify();

        // Make sure synchronization happens from CRM to NAV
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping.Modify();

        LibraryPerformanceProfiler.StartProfiler(true);
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestSynchCustomerCoupledToCRMAccount',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"CRM Integration Table Synch.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchUoMFromCRMUoM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TestIntegrationTable: Record "Test Integration Table";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        ExpectedLatestDateTime: DateTime;
    begin
        // [FEATURE] [Modified On]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A CRM source of 2 records that can be copied to NAV
        LibraryCRMIntegration.CreateIntegrationTableData(0, 2);
        ExpectedLatestDateTime := CreateDateTime(Today + 1, Time);
        TestIntegrationTable.FindLast();
        TestIntegrationTable."Integration Modified Field" := ExpectedLatestDateTime;
        TestIntegrationTable.Modify();

        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := 0DT;
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        LibraryPerformanceProfiler.StartProfiler(true);
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestSynchUoMFromCRMUoM',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"CRM Integration Table Synch.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchUoMToCRMUoM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        // [FEATURE] [Modified On]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A NAV source of 2 records that can be copied to CRM
        LibraryCRMIntegration.CreateIntegrationTableData(2, 0);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;

        LibraryPerformanceProfiler.StartProfiler(true);
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestSynchUoMToCRMUoM',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"CRM Integration Table Synch.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBidirectionalSynchOfUoM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        // [FEATURE] [Direction]
        Initialize();
        LibraryCRMIntegration.CreateIntegrationTableMapping(IntegrationTableMapping);

        // [GIVEN] A valid and registered CRM Connection Setup
        // [GIVEN] A NAV source of 2 records
        // [GIVEN] A CRM source of 2 records
        // [GIVEN] A mapping with direction set to bidirectional
        // [GIVEN] A mapping allowing record creation
        LibraryCRMIntegration.CreateIntegrationTableData(2, 2);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        IntegrationSynchJob.DeleteAll();
        LibraryPerformanceProfiler.StartProfiler(true);
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestBidirectionalSynchOfUoM',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"CRM Integration Table Synch.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssigningCategoryToItem()
    var
        FirstItemCategory: Record "Item Category";
        ChildItemCategory: Record "Item Category";
        FirstItemAttribute: Record "Item Attribute";
        LastItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        Item: Record Item;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        ItemCard: TestPage "Item Card";
        LastItemAttributeValue: Text;
    begin
        Initialize();
        // [GIVEN] Category Hierarchy of 2 parent categories and 2 children for each
        CreateItemCategoryHierarchy(2);
        CreateTestItemAttributes();
        LibraryInventory.CreateItem(Item);
        LastItemAttributeValue := LibraryUtility.GenerateGUID();
        LibraryNotificationMgt.DisableAllNotifications();

        // [WHEN]  assign 1 item attribute the first category and 1 attribute to the second one
        FirstItemCategory.FindFirst();
        ChildItemCategory.SetRange("Parent Category", FirstItemCategory.Code);
        ChildItemCategory.FindFirst();
        FirstItemAttribute.FindFirst();
        LastItemAttribute.FindLast();

        FirstItemAttributeValue.SetRange("Attribute ID", FirstItemAttribute.ID);
        FirstItemAttributeValue.FindFirst();

        AssignItemAttributeValueToCategory(FirstItemCategory, FirstItemAttribute, FirstItemAttributeValue.Value);
        AssignItemAttributeValueToCategory(ChildItemCategory, LastItemAttribute, LastItemAttributeValue);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        LibraryPerformanceProfiler.StartProfiler(true);
        ItemCard."Item Category Code".SetValue(ChildItemCategory.Code);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestAssigningCategoryToItem',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Item Card", true);
    end;

    [Test]
    [HandlerFunctions('ItemAttributeValueListHandler')]
    [Scope('OnPrem')]
    procedure TestAssignOptionAttributesToItemViaItemCard()
    var
        Item: Record Item;
        FirstItemAttribute: Record "Item Attribute";
        FirstItemAttributeValue: Record "Item Attribute Value";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        // [GIVEN] An item and a set of item attributes
        CreateTestOptionItemAttributes();
        LibraryInventory.CreateItem(Item);

        // [WHEN] The user assigns some attribute values to the item
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        FirstItemAttribute.FindFirst();
        LibraryPerformanceProfiler.StartProfiler(true);
        AssignItemAttributeViaItemCard(FirstItemAttribute, FirstItemAttributeValue, ItemCard);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestAssignOptionAttributesToItemViaItemCard',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Item Card", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMapCurrencyExchangeRate()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        Currency: Record Currency;
        TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        // Setup
        Initialize();

        CreateCurrencyExchangeDataExchangeSetup(DataExchLineDef);
        MapMandatoryFields(DataExchLineDef);
        MapCommonFields(DataExchLineDef);
        MapAdditionalFields(DataExchLineDef);
        CreateCurrencies(Currency, TempCurrencyExchangeRate, WorkDate(), NumberOfCurrencies);
        CreateDataExchangeTestData(DataExch, DataExchLineDef, TempCurrencyExchangeRate);

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        // Execute
        LibraryPerformanceProfiler.StartProfiler(true);
        CODEUNIT.Run(CODEUNIT::"Map Currency Exchange Rate", DataExch);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestMapCurrencyExchangeRate',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Map Currency Exchange Rate", true);
    end;

    local procedure Initialize()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        MyNotifications: Record "My Notifications";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        Currency.DeleteAll();
        CurrencyExchangeRate.DeleteAll();
        DataExch.DeleteAll(true);
        DataExchDef.DeleteAll(true);
        CurrExchRateUpdateSetup.DeleteAll(true);

        DefualtExchangeRateAmount := 1;
        NumberOfCurrencies := 10;
        if isInitialized then
            exit;

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        isInitialized := true;
        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure ResetDefaultCRMSetupConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure ClearCRMData()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMAccount: Record "CRM Account";
        CRMSalesorder: Record "CRM Salesorder";
    begin
        CRMAccount.DeleteAll();
        CRMTransactioncurrency.DeleteAll();
        CRMSalesorder.DeleteAll();
    end;

    local procedure CreateCRMSalesorderInLCY(var CRMSalesorder: Record "CRM Salesorder")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CreateCRMSalesorderWithCurrency(CRMSalesorder, GeneralLedgerSetup.GetCurrencyCode(''));
    end;

    local procedure CreateCRMSalesorderWithCurrency(var CRMSalesorder: Record "CRM Salesorder"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(CurrencyCode, 1, 5));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCRMSalesorder(CRMSalesorder, CRMTransactioncurrency.TransactionCurrencyId, CRMAccount.AccountId);
    end;

    local procedure CreateSalesOrderInNAV(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);
    end;

    local procedure CreateCRMSalesorder(var CRMSalesorder: Record "CRM Salesorder"; CurrencyId: Guid; AccountId: Guid)
    begin
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(CRMSalesorder, AccountId, CurrencyId);
    end;

    local procedure CreateItemCategoryHierarchy(LevelsNumber: Integer)
    var
        ItemCategory: Record "Item Category";
        CurrentLevel: Integer;
    begin
        // creating simple hierarchy of 2 parent categories and 2 children for each
        ItemCategory.DeleteAll();

        if LevelsNumber <= 0 then
            exit;
        CreateItemCategory('');
        CreateItemCategory('');
        for CurrentLevel := 1 to (LevelsNumber - 1) do begin
            ItemCategory.SetRange(Indentation, CurrentLevel - 1);
            if ItemCategory.FindSet() then
                repeat
                    CreateItemCategory(ItemCategory.Code);
                    CreateItemCategory(ItemCategory.Code);
                until ItemCategory.Next() = 0;
        end;
    end;

    local procedure CreateTestItemAttributes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.DeleteAll();
        CreateTestOptionItemAttribute();
        CreateNonOptionTestItemAttribute(ItemAttribute.Type::Text, '');
    end;

    local procedure AssignItemAttributeValueToCategory(ItemCategory: Record "Item Category"; ItemAttribute: Record "Item Attribute"; ItemAttributeValue: Text)
    var
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        ItemCategoryCard.OpenEdit();
        ItemCategoryCard.GotoRecord(ItemCategory);
        ItemCategoryCard.Attributes.New();
        ItemCategoryCard.Attributes."Attribute Name".SetValue(ItemAttribute.Name);
        ItemCategoryCard.Attributes.Value.SetValue(ItemAttributeValue);
        ItemCategoryCard.Close();
    end;

    local procedure CreateItemCategory(ParentCategory: Code[20]) ItemCategoryCode: Code[20]
    var
        ItemCategoryCard: TestPage "Item Category Card";
    begin
        ItemCategoryCard.OpenNew();
        ItemCategoryCode := LibraryUtility.GenerateGUID();
        ItemCategoryCard.Code.SetValue(ItemCategoryCode);
        ItemCategoryCard.Description.SetValue(Format(ItemCategoryCode + ItemCategoryCode));
        ItemCategoryCard."Parent Category".SetValue(ParentCategory);
        ItemCategoryCard.OK().Invoke();
    end;

    local procedure CreateTestOptionItemAttributeValues(var ItemAttributes: TestPage "Item Attributes")
    var
        ItemAttributeValues: TestPage "Item Attribute Values";
        FirstAttributeValueName: Text;
        SecondAttributeValueName: Text;
    begin
        ItemAttributeValues.Trap();
        ItemAttributes.ItemAttributeValues.Invoke();
        ItemAttributeValues.First();
        FirstAttributeValueName := LibraryUtility.GenerateGUID();
        ItemAttributeValues.Value.SetValue(FirstAttributeValueName);
        ItemAttributeValues.Next();
        SecondAttributeValueName := LibraryUtility.GenerateGUID();
        ItemAttributeValues.Value.SetValue(SecondAttributeValueName);
        ItemAttributeValues.Close();
    end;

    local procedure CreateTestOptionItemAttribute()
    var
        DummyItemAttribute: Record "Item Attribute";
        ItemAttributes: TestPage "Item Attributes";
        AttributeName: Text;
    begin
        ItemAttributes.OpenNew();
        AttributeName := LibraryUtility.GenerateGUID();
        ItemAttributes.Name.SetValue(LowerCase(AttributeName));
        ItemAttributes.Type.SetValue(DummyItemAttribute.Type::Option);
        CreateTestOptionItemAttributeValues(ItemAttributes);
        ItemAttributes.Close();
    end;

    local procedure CreateNonOptionTestItemAttribute(Type: Option; UoM: Text)
    var
        ItemAttributeCard: TestPage "Item Attribute";
        AttributeName: Text;
    begin
        ItemAttributeCard.OpenNew();
        AttributeName := LibraryUtility.GenerateGUID();
        ItemAttributeCard.Name.SetValue(LowerCase(AttributeName));
        ItemAttributeCard.Type.SetValue(Type);
        ItemAttributeCard."Unit of Measure".SetValue(UoM);
        ItemAttributeCard.Close();
    end;

    local procedure CreateTestOptionItemAttributes()
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.DeleteAll();
        CreateTestOptionItemAttribute();
        CreateTestOptionItemAttribute();
    end;

    local procedure AssignItemAttributeViaItemCard(ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value"; var ItemCard: TestPage "Item Card")
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.FindFirst();
        SetItemAttributesViaItemCard(ItemCard, ItemAttribute, ItemAttributeValue.Value);
    end;

    local procedure SetItemAttributesViaItemCard(var ItemCard: TestPage "Item Card"; var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Text)
    begin
        LibraryVariableStorage.Enqueue(ItemAttribute);
        LibraryVariableStorage.Enqueue(ItemAttributeValue);
        ItemCard.Attributes.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAttributeValueListHandler(var ItemAttributeValueEditor: TestPage "Item Attribute Value Editor")
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeVar: Variant;
        ItemAttributeValueVar: Variant;
        ItemAttributeValue: Text;
    begin
        LibraryVariableStorage.Dequeue(ItemAttributeVar);
        LibraryVariableStorage.Dequeue(ItemAttributeValueVar);
        ItemAttribute := ItemAttributeVar;
        ItemAttributeValue := ItemAttributeValueVar;
        ItemAttributeValueEditor.ItemAttributeValueList.New();
        ItemAttributeValueEditor.ItemAttributeValueList."Attribute Name".SetValue(ItemAttribute.Name);
        ItemAttributeValueEditor.ItemAttributeValueList.Value.SetValue(ItemAttributeValue);
        ItemAttributeValueEditor.OK().Invoke();
    end;

    local procedure CreateDataExchangeDefinition(var DataExchDef: Record "Data Exch. Def")
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, CODEUNIT::"Import XML File to Data Exch.",
          CODEUNIT::"Map Data Exch. To RapidStart", CODEUNIT::"Import XML File to Data Exch.", 0, 0, 0);
    end;

    local procedure CreateCurrencyExchangeDataExchangeSetup(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        CreateDataExchangeDefinition(DataExchDef);

        DataExchLineDef.InsertRec(DataExchDef.Code, 'CEXR', 'Currency Exchange Rate', 0);
        CreateDataExchMapping(DataExchLineDef);
    end;

    local procedure MapMandatoryFields(DataExchLineDef: Record "Data Exch. Line Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ColumnNo: Integer;
    begin
        GetLastColumnNo(ColumnNo, DataExchLineDef);

        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Currency Code"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"));
    end;

    local procedure MapCommonFields(DataExchLineDef: Record "Data Exch. Line Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ColumnNo: Integer;
    begin
        GetLastColumnNo(ColumnNo, DataExchLineDef);

        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Starting Date"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"));
    end;

    local procedure MapAdditionalFields(DataExchLineDef: Record "Data Exch. Line Def")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ColumnNo: Integer;
    begin
        GetLastColumnNo(ColumnNo, DataExchLineDef);

        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Adjustment Exch. Rate Amount"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Currency Code"));
        MapFields(ColumnNo, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Adjmt Exch Rate Amt"));
    end;

    local procedure CreateDataExchangeTestData(var DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrentNodeID: Integer;
        LineNo: Integer;
    begin
        CreateDataExchange(DataExch, DataExchLineDef);
        CurrentNodeID := 1;
        LineNo := 1;
        if CurrencyExchangeRate.FindSet() then
            repeat
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Currency Code"), CurrencyExchangeRate."Currency Code",
                  CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Exch. Rate Amount"),
                  Format(CurrencyExchangeRate."Relational Exch. Rate Amount"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Starting Date"),
                  Format(CurrencyExchangeRate."Starting Date"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Exchange Rate Amount"),
                  Format(CurrencyExchangeRate."Exchange Rate Amount"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Adjustment Exch. Rate Amount"),
                  Format(CurrencyExchangeRate."Adjustment Exch. Rate Amount"), CurrentNodeID, LineNo);
                CreateDataExchangeField(
                  DataExch, DataExchLineDef, CurrencyExchangeRate.FieldNo("Relational Adjmt Exch Rate Amt"),
                  Format(CurrencyExchangeRate."Relational Adjmt Exch Rate Amt"), CurrentNodeID, LineNo);
                LineNo += 1;
            until CurrencyExchangeRate.Next() = 0;
    end;

    local procedure CreateCurrencies(var Currency: Record Currency; var TempExpectedCurrencyExchangeRate: Record "Currency Exchange Rate" temporary; StartDate: Date; NumberToInsert: Integer)
    var
        I: Integer;
    begin
        for I := 1 to NumberToInsert do begin
            Clear(Currency);
            LibraryERM.CreateCurrency(Currency);

            // This exchange rate will be used to generate Data Exchange data and to assert values
            TempExpectedCurrencyExchangeRate.Init();
            TempExpectedCurrencyExchangeRate.Validate("Currency Code", Currency.Code);
            TempExpectedCurrencyExchangeRate.Validate("Starting Date", StartDate);
            TempExpectedCurrencyExchangeRate.Insert(true);

            TempExpectedCurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInRange(1, 1000, 2));
            TempExpectedCurrencyExchangeRate.Validate("Exchange Rate Amount", DefualtExchangeRateAmount);
            TempExpectedCurrencyExchangeRate.Validate(
              "Adjustment Exch. Rate Amount", TempExpectedCurrencyExchangeRate."Exchange Rate Amount");
            TempExpectedCurrencyExchangeRate.Validate(
              "Relational Adjmt Exch Rate Amt", TempExpectedCurrencyExchangeRate."Relational Exch. Rate Amount");
            TempExpectedCurrencyExchangeRate.Modify(true);
        end;
    end;

    local procedure CreateDataExchange(var DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def")
    begin
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
    end;

    local procedure CreateDataExchangeField(DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; FieldNo: Integer; TextValue: Text[250]; var CurrentNodeID: Integer; LineNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchFieldMapping.SetRange("Field ID", FieldNo);
        if not DataExchFieldMapping.FindFirst() then
            exit;

        DataExchField.Init();
        DataExchField.Validate("Data Exch. No.", DataExch."Entry No.");
        DataExchField.Validate("Column No.", DataExchFieldMapping."Column No.");
        DataExchField.Validate("Node ID", GetNodeID(CurrentNodeID));
        DataExchField.Validate(Value, TextValue);
        DataExchField.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchField.Validate("Line No.", LineNo);
        DataExchField.Insert(true);

        CurrentNodeID += 1;
    end;

    local procedure CreateDataExchMapping(DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Init();
        DataExchMapping.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.Validate("Table ID", DATABASE::"Currency Exchange Rate");
        DataExchMapping.Insert(true);
    end;

    local procedure MapFields(var ColumnNo: Integer; DataExchLineDef: Record "Data Exch. Line Def"; FieldID: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        CreateDataExchangeColumnDef(DataExchColumnDef, DataExchLineDef, ColumnNo, '');
        CreateDataExchFieldMapping(DataExchColumnDef, FieldID);
        ColumnNo += 1;
    end;

    local procedure GetLastColumnNo(var ColumnNo: Integer; DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);

        if DataExchColumnDef.FindLast() then
            ColumnNo := DataExchColumnDef."Column No." + 1
        else
            ColumnNo := 1;
    end;

    local procedure GetNodeID(CurrentNodeCount: Integer): Text
    begin
        exit(Format(CurrentNodeCount, 0, '<Integer,4><Filler Char,0>'))
    end;

    local procedure CreateDataExchangeColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer; Path: Text[250])
    var
        Language: Codeunit Language;
    begin
        DataExchColumnDef.Init();
        DataExchColumnDef.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.Validate("Column No.", ColumnNo);
        DataExchColumnDef.Validate("Data Formatting Culture", Language.GetCultureName(WindowsLanguage));
        DataExchColumnDef.Validate(Path, Path);
        DataExchColumnDef.Insert(true);
    end;

    local procedure CreateDataExchFieldMapping(DataExchColumnDef: Record "Data Exch. Column Def"; FieldID: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchColumnDef."Data Exch. Def Code");
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchColumnDef."Data Exch. Line Def Code");
        DataExchFieldMapping.Validate("Column No.", DataExchColumnDef."Column No.");
        DataExchFieldMapping.Validate("Table ID", DATABASE::"Currency Exchange Rate");
        DataExchFieldMapping.Validate("Field ID", FieldID);
        DataExchFieldMapping.Insert(true);
    end;
}

