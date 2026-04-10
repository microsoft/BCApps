codeunit 137402 "SCM Costing Batch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RoundingMethodCode: Code[10];
        isInitialized: Boolean;
        BlankDocumentNoError: Label 'You must specify a %1';
        ValidationError: Label '%1 must be %2.';
        ShowError: Boolean;
        SalesLCY2: Decimal;
        COGSLCY2: Decimal;
        NonInvtblCostsLCY2: Decimal;
        ProfitLCY2: Decimal;
        ProfitPercentage2: Decimal;
        FileName: Label '%1%2.pdf';
        StandardCostWorksheetMustExist: Label 'Standard Cost Worksheet must exist.';
        UnknownError: Label 'Unknown Error.';
        AverageCost: Decimal;
        IncreaseQuantity: Decimal;
        DecreaseQuantity: Decimal;
        CalculationDate: Date;
        Adjust: Option "Item Card","Stockkeeping Unit Card";
        AdjustField: Enum ItemCostPriceFieldOption;
        AdjustmentFactor: Integer;
        InvalidColumnCaptionError: Label 'Period in columns caption were not updated according to the view by filter.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        AmountErr: Label '%1 must be %2 in %3', Comment = '%1 = Amount of GL Entry, %2 = Standard Cost of SKU, %3 = GL Entry';
        StandardCostMustMatchErr: Label 'Standard Cost of Item and SKU must match for Item No. %1', Comment = '%1 = Item No.';
        StandardCostMustNotMatchErr: Label 'Standard Cost of Item and SKU must not match for Item No. %1', Comment = '%1 = Item No.';
        SingleLevelCapacityCostMustMatchErr: Label 'Single-Level Capacity Cost of Item and SKU must match for Item No. %1', Comment = '%1 = Item No.';
        SingleLevelCapacityCostMustNotMatchErr: Label 'Single-Level Capacity Cost of Item and SKU must not match for Item No. %1', Comment = '%1 = Item No.';
        SingleLevelMaterialCostMustMatchErr: Label 'Single-Level Material Cost of Item and SKU must match for Item No. %1', Comment = '%1 = Item No.';
        SingleLevelMaterialCostMustNotMatchErr: Label 'Single-Level Material Cost of Item and SKU must not match for Item No. %1', Comment = '%1 = Item No.';
        CostAmountMustNotMatchErr: Label 'Cost Amount for Item and SKU must not match for Item No. %1 in Prod. Order Line.', Comment = '%1 = Item No.';
        CurrentSaveValuesId: Integer;

    [Test]
    [HandlerFunctions('AdjustCostItemEntriesHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryWithAdjustCostItemEntries()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        Quantity: Decimal;
        PurchaseUnitAmount: Decimal;
        PurchaseUnitAmount2: Decimal;
        SalesUnitAmount: Decimal;
    begin
        // Validate Item Ledger Entry after running Adjust Cost Item Entries.

        // Setup: Update Sales Receivable and Inventory Setup. Create and post Item Journal Lines.
        Initialize();
        DisableAutomaticCostPosting();

        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random Quantity.
        SalesUnitAmount := SetPurchaseAndSaleAmount(PurchaseUnitAmount, PurchaseUnitAmount2);

        // Use Default Costing Method FIFO is required for the Test.
        CreateItem(Item);
        DocumentNo :=
          CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount);
        DocumentNo2 :=
          CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount2);
        DocumentNo3 :=
          CreateAndPostItemJournalLine(
            ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", Quantity + Quantity / 2, SalesUnitAmount);  // Quantity + Quantity / 2 is required for Adjust Cost Item Entries.

        // Exercise: Run Adjust Cost Item Entries.
        RunAdjustCostItemEntries(Item."No.");
        PostInvtCostToGL();

        // Verify: Verify Item Ledger Entry after running Adjust Cost Item Entries.
        VerifyItemLedgerEntry(
          DocumentNo, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, Quantity * PurchaseUnitAmount, 0, false);
        VerifyItemLedgerEntry(
          DocumentNo2, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, Quantity * PurchaseUnitAmount2, 0, true);
        VerifyItemLedgerEntry(
          DocumentNo3, ItemJournalLine."Entry Type"::Sale, Item."No.", -(Quantity + Quantity / 2),
          -((Quantity * PurchaseUnitAmount) + (Quantity / 2 * PurchaseUnitAmount2)), (Quantity + Quantity / 2) * SalesUnitAmount, false);
    end;

    [Test]
    [HandlerFunctions('AdjustCostItemEntriesHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ValueEntryWithAdjustCostItemEntries()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        Quantity: Decimal;
        PurchaseUnitAmount: Decimal;
        PurchaseUnitAmount2: Decimal;
        SalesUnitAmount: Decimal;
    begin
        // Validate Value Entry after running Adjust Cost Item Entries.

        // Setup: Update Sales Receivable and Inventory Setup. Create and post Item Journal Lines.
        Initialize();
        DisableAutomaticCostPosting();

        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random Quantity.
        SalesUnitAmount := SetPurchaseAndSaleAmount(PurchaseUnitAmount, PurchaseUnitAmount2);

        // Use Default Costing Method FIFO is required for the Test.
        CreateItem(Item);
        DocumentNo :=
          CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount);
        DocumentNo2 :=
          CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount2);
        DocumentNo3 :=
          CreateAndPostItemJournalLine(
            ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", Quantity + Quantity / 2, SalesUnitAmount);  // Quantity + Quantity / 2 is required for Adjust Cost Item Entries.

        // Exercise: Run Adjust Cost Item Entries.
        RunAdjustCostItemEntries(Item."No.");
        PostInvtCostToGL();

        // Verify: Verify Value Entry after running Adjust Cost Item Entries.
        VerifyValueEntry(DocumentNo, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, Quantity * PurchaseUnitAmount, 0, false);
        VerifyValueEntry(DocumentNo2, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, Quantity * PurchaseUnitAmount2, 0, false);
        VerifyValueEntry(
          DocumentNo3, ItemJournalLine."Entry Type"::Sale, Item."No.", -(Quantity + Quantity / 2),
          -((Quantity + Quantity / 2) * PurchaseUnitAmount), (Quantity + Quantity / 2) * SalesUnitAmount, false);
        VerifyValueEntry(
          DocumentNo3, ItemJournalLine."Entry Type"::Sale, Item."No.", 0, -Quantity / 2 * (PurchaseUnitAmount2 - PurchaseUnitAmount), 0, true);
    end;

    [Test]
    [HandlerFunctions('ItemStatisticsHandler,ItemStatisticsMatrixHandler,AdjustCostItemEntriesHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ItemStatisticsAndItemTurnoverWithAdjustCostItemEntries()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        PurchaseUnitAmount: Decimal;
        PurchaseUnitAmount2: Decimal;
        SalesUnitAmount: Decimal;
    begin
        // Validate Item Statistics And Item Turnover after running Adjust Cost Item Entries.

        // Setup: Update Sales Receivable and Inventory Setup. Create and post Item Journal Lines.
        Initialize();
        DisableAutomaticCostPosting();

        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random Quantity.
        SalesUnitAmount := SetPurchaseAndSaleAmount(PurchaseUnitAmount, PurchaseUnitAmount2);

        // Use Default Costing Method FIFO is required for the Test.
        CreateItem(Item);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", Quantity + Quantity / 2, SalesUnitAmount);  // Quantity + Quantity / 2 is required for Adjust Cost Item Entries.
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount2);

        // Exercise: Run Adjust Cost Item Entries.
        RunAdjustCostItemEntries(Item."No.");
        PostInvtCostToGL();

        // Verify: Verify Item Statistics and Turnover after running Adjust Cost Item Entries.
        RunItemStatistics(Item."No.", "Analysis Rounding Factor"::None);
        VerifyItemStatistics(Quantity, SalesUnitAmount, PurchaseUnitAmount, PurchaseUnitAmount2, "Analysis Rounding Factor"::None);
        VerifyItemTurnover(Item."No.", Quantity, SalesUnitAmount, PurchaseUnitAmount, PurchaseUnitAmount2);
    end;

    [Test]
    [HandlerFunctions('ItemStatisticsHandler,ItemStatisticsMatrixHandler,AdjustCostItemEntriesHandler')]
    [Scope('OnPrem')]
    procedure ItemStatisticsWithRoundingFactor1()
    var
        ItemNo: Code[20];
        Quantity: Decimal;
        SalesUnitAmount: Decimal;
    begin
        // [FEATURE] [UI] [Item Statistics]
        // [SCENARIO 363269] Run Item Statistics with Rounding Factor = "1"
        Initialize();

        // [GIVEN] Turned off Warnings in Sales Receivable Setup, "Automatic Cost Posting"/Adjustment in Inventory Setup
        DisableAutomaticCostPosting();

        // [GIVEN] Sales Item Journal line with Sales Amount = "X"
        CreateItemDataRoundingFactor(ItemNo, Quantity, SalesUnitAmount, 1);

        // [WHEN] Run Item Statistics with RoundingFactor::"1"
        RunItemStatistics(ItemNo, "Analysis Rounding Factor"::"1");
        // [THEN] Sales Amount = "X" on Item Statistics is rounded according to RoundingFactor::"1"
        // [THEN] Profit % on Item Statistics is rounded according to RoundingFactor::"1"
        VerifyItemStatistics(Quantity, SalesUnitAmount, 0, 0, "Analysis Rounding Factor"::"1");
    end;

    [Test]
    [HandlerFunctions('ItemStatisticsHandler,ItemStatisticsMatrixHandler,AdjustCostItemEntriesHandler')]
    [Scope('OnPrem')]
    procedure ItemStatisticsWithRoundingFactor1000()
    var
        ItemNo: Code[20];
        Quantity: Decimal;
        SalesUnitAmount: Decimal;
    begin
        // [FEATURE] [UI] [Item Statistics]
        // [SCENARIO 363269] Run Item Statistics with Rounding Factor = "1000"
        Initialize();

        // [GIVEN] Turned off Warnings in Sales Receivable Setup, "Automatic Cost Posting"/Adjustment in Inventory Setup
        DisableAutomaticCostPosting();

        // [GIVEN] Sales Item Journal line with Sales Amount = "X"
        CreateItemDataRoundingFactor(ItemNo, Quantity, SalesUnitAmount, 1000);

        // [WHEN] Run Item Statistics with RoundingFactor::"1000"
        RunItemStatistics(ItemNo, "Analysis Rounding Factor"::"1000");
        // [THEN] Sales Amount = "X" on Item Statistics is reduced with division by 1000 and rounded to RoundingFactor::"1000"
        // [THEN] Profit % on Item Statistics is rounded according to RoundingFactor::"1000"
        VerifyItemStatistics(Quantity, SalesUnitAmount, 0, 0, "Analysis Rounding Factor"::"1000");
    end;

    [Test]
    [HandlerFunctions('AdjustCostItemEntriesHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryWithAdjustCostItemEntries()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
        Quantity: Decimal;
        PurchaseUnitAmount: Decimal;
        PurchaseUnitAmount2: Decimal;
        SalesUnitAmount: Decimal;
        EntryNo: Integer;
    begin
        // Validate G/L Entry after running Adjust Cost Item Entries.

        // Setup: Update Sales Receivable and Inventory Setup. Create and post Item Journal Lines.
        Initialize();
        DisableAutomaticCostPosting();

        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random Quantity.
        SalesUnitAmount := SetPurchaseAndSaleAmount(PurchaseUnitAmount, PurchaseUnitAmount2);

        // Use Default Costing Method FIFO is required for the Test.
        CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, PurchaseUnitAmount2);
        DocumentNo :=
          CreateAndPostItemJournalLine(
            ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", Quantity + Quantity / 2, SalesUnitAmount);  // Quantity + Quantity / 2 is required for Adjust Cost Item Entries.

        // Exercise: Run Adjust Cost Item Entries.
        PostInvtCostToGL();
        EntryNo := GetGLEntryNo(DocumentNo);
        RunAdjustCostItemEntries(Item."No.");
        PostInvtCostToGL();

        // Verify: Verify G/L Entry after running Adjust Cost Item Entries.
        VerifyGLEntry(DocumentNo, EntryNo, -Quantity / 2 * (PurchaseUnitAmount2 - PurchaseUnitAmount));
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangeHandler')]
    [Scope('OnPrem')]
    procedure ImplementStandardCostChangeError()
    var
        Item: Record Item;
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        ItemJournalLine: Record "Item Journal Line";
        StandardCostWorksheetName: Code[10];
    begin
        // Test error occurs on running Implement Standard Cost Change report without Document No.

        // Setup: Create Item and Standard Cost Worksheet Name. Run Suggest Item Standard Cost report.
        Initialize();
        CreateItem(Item);
        StandardCostWorksheetName := CreateStandardCostWorksheetName();
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWorksheetName, LibraryRandom.RandInt(5), '');  // Use random value for Standard Cost Adjustment Factor.

        // Exercise: Run Implement Standard Cost Change.
        ShowError := true;  // Use global variable for request page handler.
        asserterror RunImplementStandardCostChange(StandardCostWorksheetName, StandardCostWorksheet.Type::Item, Item."No.");

        // Verify: Verify error message.
        Assert.AreEqual(
          StrSubstNo(BlankDocumentNoError, LowerCase(ItemJournalLine.FieldCaption("Document No."))), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangeHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImplementStandardCostChange()
    var
        Item: Record Item;
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        StandardCostWorksheetName: Code[10];
    begin
        // Test functionality of Implement Standard Cost Change report.

        // Setup: Create Item, Work Center, Machine Center and Standard Cost Worksheet Name. Run Suggest Item Standard Cost and Suggest Work and Machine Center Standard Cost report.
        Initialize();
        CreateItem(Item);
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter);
        StandardCostWorksheetName := CreateStandardCostWorksheetName();
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWorksheetName, LibraryRandom.RandInt(5), '');  // Use random value for Standard Cost Adjustment Factor.
        LibraryManufacturing.SuggestCapacityStandardCost(
          WorkCenter, MachineCenter, StandardCostWorksheetName, LibraryRandom.RandInt(5), '');  // Use random value for Standard Cost Adjustment Factor.

        // Exercise: Run Implement Standard Cost Change.
        RunImplementStandardCostChange(StandardCostWorksheetName, StandardCostWorksheet.Type::Item, Item."No.");
        RunImplementStandardCostChange(StandardCostWorksheetName, StandardCostWorksheet.Type::"Work Center", WorkCenter."No.");
        RunImplementStandardCostChange(StandardCostWorksheetName, StandardCostWorksheet.Type::"Machine Center", MachineCenter."No.");

        // Verify: Verify Standard Cost must be implemented.
        VerifyStandardCostWorksheet(StandardCostWorksheetName, StandardCostWorksheet.Type::Item, Item."No.");
        VerifyStandardCostWorksheet(StandardCostWorksheetName, StandardCostWorksheet.Type::"Work Center", WorkCenter."No.");
        VerifyStandardCostWorksheet(StandardCostWorksheetName, StandardCostWorksheet.Type::"Machine Center", MachineCenter."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemStandardCostWithoutRoundingFactor()
    begin
        // Test functionality of Suggest Item Standard Cost report without Rounding Factor.

        Initialize();
        SuggestItemStandardCost('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemStandardCostWithRoundingFactor()
    var
        RoundingMethod: Record "Rounding Method";
    begin
        // Test functionality of Suggest Item Standard Cost report with Rounding Factor.

        Initialize();
        RoundingMethod.FindFirst();
        SuggestItemStandardCost(RoundingMethod.Code);
    end;

    local procedure SuggestItemStandardCost(StandardCostRoundingMethod: Code[10])
    var
        Item: Record Item;
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        SuggestItemStandardCost: Report "Suggest Item Standard Cost";
        StandardCostWorksheetName: Code[10];
        StandardCostAdjustmentFactor: Integer;
    begin
        // Setup: Create Item and Standard Cost Worksheet Name.
        CreateItem(Item);
        StandardCostWorksheetName := CreateStandardCostWorksheetName();

        // Exercise: Run Suggest Item Standard Cost.
        StandardCostAdjustmentFactor := LibraryRandom.RandInt(5);  // Use random value for Standard Cost Adjustment Factor.
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWorksheetName, StandardCostAdjustmentFactor, StandardCostRoundingMethod);

        // Verify: Verify New Standard Cost for Item on Standard Cost Worksheet.
        FindStandardCostWorksheet(StandardCostWorksheet, StandardCostWorksheetName, StandardCostWorksheet.Type::Item, Item."No.");
        StandardCostWorksheet.TestField(
          "New Standard Cost",
          SuggestItemStandardCost.RoundAndAdjustAmt(
            StandardCostWorksheet."Standard Cost", StandardCostRoundingMethod, StandardCostAdjustmentFactor));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestWorkAndMachineCenterStandardCostWithoutRoundingFactor()
    begin
        // Test functionality of Suggest Work and Machine Center Standard Cost report without Rounding Factor.

        Initialize();
        SuggestWorkAndMachineCenterStandardCost('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestWorkAndMachineCenterStandardCostWithRoundingFactor()
    var
        RoundingMethod: Record "Rounding Method";
    begin
        // Test functionality of Suggest Work and Machine Center Standard Cost report with Rounding Factor.

        Initialize();
        RoundingMethod.FindFirst();
        SuggestWorkAndMachineCenterStandardCost(RoundingMethod.Code);
    end;

    local procedure SuggestWorkAndMachineCenterStandardCost(StandardCostRoundingMethod: Code[10])
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        SuggestCapacityStandardCost: Report "Suggest Capacity Standard Cost";
        StandardCostWorksheetName: Code[10];
        StandardCostAdjustmentFactor: Integer;
    begin
        // Setup: Create Work Center, Machine Center and Standard Cost Worksheet Name.
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter);
        StandardCostWorksheetName := CreateStandardCostWorksheetName();

        // Exercise: Run Implement Standard Cost Change.
        StandardCostAdjustmentFactor := LibraryRandom.RandInt(5);  // Use random value for Standard Cost Adjustment Factor.
        LibraryManufacturing.SuggestCapacityStandardCost(
          WorkCenter, MachineCenter, StandardCostWorksheetName, StandardCostAdjustmentFactor, StandardCostRoundingMethod);

        // Verify: Verify New Standard Cost for Work Center and Machine Center on Standard Cost Worksheet.
        FindStandardCostWorksheet(
          StandardCostWorksheet, StandardCostWorksheetName, StandardCostWorksheet.Type::"Work Center", WorkCenter."No.");
        StandardCostWorksheet.TestField(
          "New Standard Cost",
          SuggestCapacityStandardCost.RoundAndAdjustAmt(
            StandardCostWorksheet."Standard Cost", StandardCostRoundingMethod, StandardCostAdjustmentFactor));
        FindStandardCostWorksheet(
          StandardCostWorksheet, StandardCostWorksheetName, StandardCostWorksheet.Type::"Machine Center", MachineCenter."No.");
        StandardCostWorksheet.TestField(
          "New Standard Cost",
          SuggestCapacityStandardCost.RoundAndAdjustAmt(
            StandardCostWorksheet."Standard Cost", StandardCostRoundingMethod, StandardCostAdjustmentFactor));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardCostWorksheetBeforeRollUp()
    var
        Item: Record Item;
        StandardCostWorksheetName: Code[10];
    begin
        // Run Suggest Item Standard Cost report and verify number of Standard Cost Worksheet Lines must not be zero.

        // Setup: Create Standard Cost Worksheet Name.
        Initialize();
        StandardCostWorksheetName := CreateStandardCostWorksheetName();
        CreateItem(Item);

        // Exercise: Run Suggest Item Standard Cost.
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWorksheetName, LibraryRandom.RandInt(10), '');  // Use random value for Standard Cost Adjustment Factor.

        // Verify: Verify number of Standard Cost Worksheet Lines must not be zero.
        Assert.IsTrue(GetNumberOfStandardCostWorksheetLines(StandardCostWorksheetName) > 0, StandardCostWorksheetMustExist);
    end;

    [Test]
    [HandlerFunctions('RollUpStandardCostHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardCostWorksheetAfterRollUp()
    var
        Item: Record Item;
        StandardCostWorksheetName: Code[10];
        CountRowsBeforeRollup: Integer;
    begin
        // Roll Up Standard Cost with calculation date workdate and verify some more lines added after Roll Up.

        // Setup: Create Standard Cost Worksheet Name. Run Suggest Item Standard Cost.
        Initialize();
        StandardCostWorksheetName := CreateStandardCostWorksheetName();
        CreateItem(Item);
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWorksheetName, LibraryRandom.RandInt(10), '');  // Use random value for Standard Cost Adjustment Factor.

        // Exercise: Roll Up Standard Cost with calculation date workdate.
        CountRowsBeforeRollup := GetNumberOfStandardCostWorksheetLines(StandardCostWorksheetName);
        CalculationDate := WorkDate();  // Use CalculationDate as global for Test Request Page Handler.
        RunRollUpStandardCost(StandardCostWorksheetName);

        // Verify: Verify some more lines added after Roll Up.
        Assert.IsTrue(
          GetNumberOfStandardCostWorksheetLines(StandardCostWorksheetName) > CountRowsBeforeRollup, StandardCostWorksheetMustExist);
    end;

    [Test]
    [HandlerFunctions('RollUpStandardCostHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStandardCostAfterDelete()
    var
        Item: Record Item;
        StandardCostWorksheetName: Code[10];
        CountRowsBeforeRollup: Integer;
    begin
        // Delete all lines on Standard Cost Worksheet. Roll Up Standard Cost with calculation date random day less than workdate and verify some more lines added after Roll Up.

        // Setup: Create Standard Cost Worksheet Name. Run Suggest Item Standard Cost.
        Initialize();
        StandardCostWorksheetName := CreateStandardCostWorksheetName();
        CreateItem(Item);
        LibraryCosting.SuggestItemStandardCost(Item, StandardCostWorksheetName, LibraryRandom.RandInt(10), '');  // Use random value for Standard Cost Adjustment Factor.
        CountRowsBeforeRollup := GetNumberOfStandardCostWorksheetLines(StandardCostWorksheetName);

        // Exercise: Delete all lines on Standard Cost Worksheet. Roll Up Standard Cost with calculation date random day less than workdate.
        DeleteStandardCostWorksheetLines(StandardCostWorksheetName);
        CalculationDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Use CalculationDate as global for Test Request Page Handler.
        RunRollUpStandardCost(StandardCostWorksheetName);

        // Verify: Verify some more lines added after Roll Up.
        Assert.IsTrue(
          GetNumberOfStandardCostWorksheetLines(StandardCostWorksheetName) > CountRowsBeforeRollup, StandardCostWorksheetMustExist);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemPriceOnWorksheetWithSalesTypeCustomer()
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        // Test functionality of Suggest Item Price On Worksheet report with Sales Type as Customer.

        Initialize();
        SuggestItemPriceOnWorksheet(SalesPriceWorksheet."Sales Type"::Customer, CreateCustomer(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemPriceOnWorksheetWithSalesTypeAllCustomers()
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        // Test functionality of Suggest Item Price On Worksheet report with Sales Type as All Customers.

        Initialize();
        SuggestItemPriceOnWorksheet(SalesPriceWorksheet."Sales Type"::"All Customers", '', CreateCurrency());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemPriceOnWorksheetWithSalesTypeCampaign()
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        // Test functionality of Suggest Item Price On Worksheet report with Sales Type as Campaign.

        Initialize();
        SuggestItemPriceOnWorksheet(SalesPriceWorksheet."Sales Type"::Campaign, CreateCampaign(), CreateCurrency());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestItemPriceOnWorksheetWithSalesTypeCustomerPriceGroup()
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        // Test functionality of Suggest Item Price On Worksheet report with Sales Type as Customer Price Group.

        Initialize();
        SuggestItemPriceOnWorksheet(SalesPriceWorksheet."Sales Type"::"Customer Price Group", CreateCustomerPriceGroup(), CreateCurrency());
    end;

    local procedure SuggestItemPriceOnWorksheet(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; CurrencyCode: Code[10])
    var
        Item: Record Item;
    begin
        // Setup.
        CreateItem(Item);

        // Exercise: Run Suggest Item Price on Worksheet.
        LibraryCosting.SuggestItemPriceWorksheet2(Item, SalesCode, SalesType, 0, LibraryRandom.RandInt(10), CurrencyCode);  // Use random Unit Price Factor and zero Price Lower Limit.

        // Verify: Verify Sales Price Worksheet must exist.
        VerifySalesPriceWorksheet(SalesType, SalesCode, CurrencyCode, Item."No.");
    end;

    [Test]
    [HandlerFunctions('AverageCostCalcOverviewHandler')]
    [Scope('OnPrem')]
    procedure AverageCostCalculationWithStandardCostingMethod()
    var
        Item: Record Item;
    begin
        // Test Average Cost Calculation Functionality for Costing Method as Standard.

        Initialize();
        AverageCostCalculation(Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2));  // Use random Standard Cost.
    end;

    [Test]
    [HandlerFunctions('AverageCostCalcOverviewHandler')]
    [Scope('OnPrem')]
    procedure AverageCostCalculationWithAverageCostingMethod()
    var
        Item: Record Item;
    begin
        // Test Average Cost Calculation Functionality for Costing Method as Average.

        Initialize();
        AverageCostCalculation(Item."Costing Method"::Average, 0);  // Use 0 for Standard Cost.
    end;

    local procedure AverageCostCalculation(CostingMethod: Enum "Costing Method"; StandardCost: Decimal)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
    begin
        // Setup: Update Sales and Receivable Setup. Create Item with Costing Method as Standard / Average. Create and post Purchase Order. Create and post Sales Order.
        CreateAndModifyItem(Item, CostingMethod, StandardCost, 0);  // Use 0 for Unit Cost.
        CreateAndPostPurchaseDocument(PurchaseLine, Item."No.");
        CreateAndPostSalesDocument(SalesLine, Item."No.");
        AverageCost := Item."Standard Cost";  // Use AverageCost as global for handler.
        if CostingMethod = Item."Costing Method"::Average then
            AverageCost :=
              (PurchaseLine."Line Amount" - (SalesLine.Quantity * PurchaseLine."Direct Unit Cost")) /
              (PurchaseLine.Quantity - SalesLine.Quantity);  // Use AverageCost as global for handler.
        IncreaseQuantity := PurchaseLine.Quantity;  // Use IncreaseQuantity as global for handler.
        DecreaseQuantity := -SalesLine.Quantity;  // Use DecreaseQuantity as global for handler.

        // Exercise: Show Average Cost Adjustment Point.
        ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Item);

        // Verify: Verification performed into AverageCostCalcOverviewHandler function.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateUnitCostReportWithOneLevelAndFalseReservations()
    var
        CalcMethod: Option "One Level","All Levels";
    begin
        // Test to verify that Unit Cost on Production order line changes when we run Update Unit Cost report with One Level Calculation method.

        Initialize();
        UpdateUnitCostReport(CalcMethod::"One Level", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateUnitCostReportWithAllLevelsAndTrueReservations()
    var
        CalcMethod: Option "One Level","All Levels";
    begin
        // Test to verify that Unit Cost on Production order line changes when we run Update Unit Cost report with All Levels Calculation method.

        Initialize();
        UpdateUnitCostReport(CalcMethod::"All Levels", true);
    end;

    local procedure UpdateUnitCostReport(CalcMethod: Option "One Level","All Levels"; UpdateReservations: Boolean)
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ExpectedUnitCost: Decimal;
        RemainingQuantity: Decimal;
        ItemNo: Code[20];
    begin
        // Setup: Create an Item with Production BOM. Create a Released Production Order for the new Item and Refresh it.
        ItemNo := CreateManufacturingItem(ProductionBOMLine);
        Item.Get(ProductionBOMLine."No.");
        CreateAndRefreshProductionOrder(ProductionOrder, ItemNo);

        // Exercise: Run Update Unit Cost report.
        RemainingQuantity := ProductionBOMLine."Quantity per" * ProductionOrder.Quantity;
        ExpectedUnitCost := (RemainingQuantity * Item."Unit Cost") / ProductionOrder.Quantity;
        LibraryManufacturing.UpdateUnitCost(ProductionOrder, CalcMethod, UpdateReservations);

        // Verify: Unit Cost gets updated based on the Unit Cost of Component Item.
        VerifyUnitCostInProductionOrderLine(ProductionOrder, ExpectedUnitCost);
    end;

    [Test]
    [HandlerFunctions('AdjustCostItemEntriesHandler')]
    [Scope('OnPrem')]
    procedure UpdateUnitCostInItemJournalAndAdjustCostItemEntries()
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        UnitAmount: Decimal;
        ItemNo: Code[20];
    begin
        // Test to verify that Unit Cost on Production order line changes when we run Adjust Cost Item Entries batch job after posting Item Journal with updated Unit Cost for Item.

        // Setup: Create an Item with Production BOM. Create Released Production Order and Refresh it. Create and Post Item Journal line with updated Unit Cost.
        Initialize();
        ItemNo := CreateManufacturingItem(ProductionBOMLine);
        CreateAndRefreshProductionOrder(ProductionOrder, ItemNo);
        UnitAmount := CreateAndPostItemJournalLineWithUnitCost(ItemNo);

        // Exercise: Run Adust Cost Item Entries batch job.
        RunAdjustCostItemEntries(ItemNo);

        // Verify: Unit Cost gets updated based on the Unit Cost on Item Journal line.
        VerifyUnitCostInProductionOrderLine(ProductionOrder, UnitAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyStandardCostWorksheetReportWithoutAdjustmentFactor()
    begin
        // Test functionality of Copy Standard Cost Worksheet report with Adjustment Factor.

        Initialize();
        CopyStandardCostWorksheet('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyStandardCostWorksheetReportCostWithRoundingFactor()
    var
        RoundingMethod: Record "Rounding Method";
    begin
        // Test functionality of Copy Standard Cost Worksheet report with Rounding Factor.

        Initialize();
        RoundingMethod.FindFirst();
        CopyStandardCostWorksheet(RoundingMethod.Code);
    end;

    local procedure CopyStandardCostWorksheet(StandardCostRoundingMethod: Code[10])
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        StandardCostWorksheetName: Code[10];
        StandardCostWorksheetName2: Code[10];
    begin
        // Setup: Create Work Center, Machine Center, Standard Cost Worksheet Name and Run Suggest Work And Machine Center Standard Cost Report.
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter);
        StandardCostWorksheetName := CreateStandardCostWorksheetName();
        LibraryManufacturing.SuggestCapacityStandardCost(
          WorkCenter, MachineCenter, StandardCostWorksheetName, LibraryRandom.RandInt(5), StandardCostRoundingMethod);  // Use random value for Standard Cost Adjustment Factor.
        StandardCostWorksheetName2 := CreateStandardCostWorksheetName();  // Create new Worksheet Name.

        // Exercise: Run Copy Standard Cost Worksheet Report.
        LibraryCosting.CopyStandardCostWorksheet(StandardCostWorksheetName, StandardCostWorksheetName2);

        // Verify: Verify Lines are copied from Old Worksheet to New Worksheet.
        VerifyCopyStandardCostWorkSheet(StandardCostWorksheetName2, StandardCostWorksheet.Type::"Work Center", WorkCenter."No.");
        VerifyCopyStandardCostWorkSheet(StandardCostWorksheetName2, StandardCostWorksheet.Type::"Machine Center", MachineCenter."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceOnWorksheetWithSalesTypeCustomer()
    begin
        // Test functionality of Suggest Sales Price on Worksheet report with Sales Type as Customer.

        Initialize();
        SuggestSalesPriceOnWorksheet("Sales Price Type"::Customer, CreateCustomer());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceOnWorksheetWithSalesTypeAllCustomers()
    begin
        // Test functionality of Suggest Sales Price on Worksheet report with Sales Type as All Customers.

        Initialize();
        SuggestSalesPriceOnWorksheet("Sales Price Type"::"All Customers", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceOnWorksheetWithSalesTypeCampaign()
    begin
        // Test functionality of Suggest Sales Price on Worksheet report with Sales Type as Campaign.

        Initialize();
        SuggestSalesPriceOnWorksheet("Sales Price Type"::Campaign, CreateCampaign());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceOnWorksheetWithSalesTypeCustomerPriceGroup()
    begin
        // Test functionality of Suggest Sales Price on Worksheet report with Sales Type as Customer Price Group.

        Initialize();
        SuggestSalesPriceOnWorksheet("Sales Price Type"::"Customer Price Group", CreateCustomerPriceGroup());
    end;

    local procedure SuggestSalesPriceOnWorksheet(SalesType: Enum "Sales Price Type"; SalesCode: Code[20])
    var
        Item: Record Item;
    begin
        // Setup: Create Item and Sales Price.
        CreateItem(Item);
        CreateSalesPrice(Item, SalesType, SalesCode);

        // Exercise: Run Suggest Sales Price Worksheet report.
        LibraryCosting.SuggestSalesPriceWorksheet(
          Item, SalesCode, SalesType, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));  // Use random values for Price Lower Limit and Unit Price Factor.

        // Verify: Verify Sales Price Worksheet must exist.
        VerifySalesPriceWorksheet(SalesType, SalesCode, '', Item."No.");
    end;

    [Test]
    [HandlerFunctions('AdjustItemCostPricesHandler')]
    [Scope('OnPrem')]
    procedure AdjustItemCostPricesReportForItemUnitPrice()
    var
        Item: Record Item;
        UnitPrice: Decimal;
    begin
        // Test to check the functionality of Adjust Item Cost Prices report for Item Unit Price.

        // Setup: Create Item with Unit Price. Set values to global variables.
        CreateAndModifyItem(Item, Item."Costing Method"::FIFO, 0, LibraryRandom.RandDec(100, 2));  // Taking Random value for Unit Cost. Taking 0 for Standard Cost as it is not required in the test.
        UnitPrice := Item."Unit Price";
        DefineGlobalValues(Adjust::"Item Card", AdjustField::"Unit Price", LibraryRandom.RandInt(5), '');

        // Exercise: Run Adjust Item Cost Prices batch report.
        RunAdjustItemCostPricesReportWithItem(Item);

        // Verify: Unit Price of Item.
        Item.Get(Item."No.");
        Item.TestField("Unit Price", UnitPrice * AdjustmentFactor);
    end;

    [Test]
    [HandlerFunctions('AdjustItemCostPricesHandler')]
    [Scope('OnPrem')]
    procedure AdjustItemCostPricesReportForStockkeepingUnitStandardCost()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Test to check the functionality of Adjust Item Cost Prices report for Stock keeping Unit Standard Cost.

        // Setup: Create Item with Standard Cost. Create Stock keeping Unit. Set values to global variables.
        CreateAndModifyItem(Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), 0);  // Taking Random value for Standard Cost. Taking 0 for Unit Price as it is not required in the test.
        CreateStockkeepingUnit(Item);
        DefineGlobalValues(Adjust::"Stockkeeping Unit Card", AdjustField::"Standard Cost", LibraryRandom.RandInt(5), '');

        // Exercise: Run Adjust Item Cost Prices batch report.
        RunAdjustItemCostPricesReportWithStockkeepingUnit(Item."No.");

        // Verify: Standard Cost of Stock keeping Unit.
        FindStockkeepingUnit(StockkeepingUnit, Item."No.");
        StockkeepingUnit.TestField("Standard Cost", Item."Standard Cost" * AdjustmentFactor);
    end;

    [Test]
    [HandlerFunctions('AdjustItemCostPricesHandler')]
    [Scope('OnPrem')]
    procedure AdjustItemCostPricesReportForStockkeepingUnitLastDirectCostWithRoundingMethod()
    var
        Item: Record Item;
        RoundingMethod: Record "Rounding Method";
        StockkeepingUnit: Record "Stockkeeping Unit";
        LastDirectCost: Decimal;
    begin
        // Test to check the functionality of Adjust Item Cost Prices report for Stock keeping Unit Last Direct Cost with Rounding method.

        // Setup: Create Item with Standard Cost. Create Stock keeping Unit and update Last Direct Cost. Set values to global variables. Find first Rounding method.
        DeleteObjectOptionsIfNeeded();
        CreateAndModifyItem(Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), 0);  // Taking Random value for Standard Cost. Taking 0 for Unit Price as it is not required in the test.
        CreateStockkeepingUnit(Item);
        LastDirectCost := UpdateLastDirectCostOnStockkeepingUnit(Item."No.");
        RoundingMethod.FindFirst();
        DefineGlobalValues(
          Adjust::"Stockkeeping Unit Card", AdjustField::"Last Direct Cost",
          LibraryRandom.RandInt(10), RoundingMethod.Code);

        // Exercise: Run Adjust Item Cost Prices batch report.
        RunAdjustItemCostPricesReportWithStockkeepingUnit(Item."No.");

        // Verify: Last Direct Cost of Stock keeping Unit.
        FindStockkeepingUnit(StockkeepingUnit, Item."No.");
        StockkeepingUnit.TestField("Last Direct Cost", Round(LastDirectCost * AdjustmentFactor, RoundingMethod.Precision));
    end;

    [Test]
    [HandlerFunctions('ItemsStatisticsHandler,ItemsStatisticsMatrixHandler')]
    [Scope('OnPrem')]
    procedure CheckFieldCaptionOnItemStatisticsMatrixPage()
    begin
        // Verify Field Caption on Item Statistics Matrix Page when View by Set to Week.

        // Setup.
        Initialize();

        // Exercise: Run Item Statistics Page.
        PAGE.RunModal(PAGE::"Item Statistics");

        // Verify: Verification done for Field Caption on Item Statistics Matrix Page using Item Show Matrix Page Handler.
    end;

    [Test]
    [HandlerFunctions('AdjustItemCostPricesHandler')]
    [Scope('OnPrem')]
    procedure AdjustItemCostPricesForStockkeepingUnitLastDirectCostWithItemFilter()
    var
        Item: Record Item;
        Item2: Record Item;
        LastDirectCost: Decimal;
        NotChangedLastDirectCost: Decimal;
    begin
        // Setup: Find a Stock Keeping Unit and update Last Direct Cost. Create Item with Vendor No.
        // Create Stock keeping Unit and update Last Direct Cost. Set values for global variables.
        NotChangedLastDirectCost := CreateSKUWithLastDirectCost(Item, '');
        LastDirectCost := CreateSKUWithLastDirectCost(Item2, CreateVendor());
        DefineGlobalValues(
          Adjust::"Stockkeeping Unit Card", AdjustField::"Last Direct Cost", LibraryRandom.RandIntInRange(2, 5), '');

        // Exercise: Run Adjust Item Cost Prices batch report with Vendor No. filter for Item.
        RunAdjustItemCostPricesReportWithItemFilter(Item2."Vendor No.");

        // Verify: Verify the Last Direct Cost of Stock keeping Unit without the filter Vendor No. was not adjusted.
        // Verify the Last Direct Cost of Stock keeping Unit with the filter Vendor No. was adjusted.
        VerifyLastDirectCostOfStockkeepingUnit(Item."No.", NotChangedLastDirectCost);
        VerifyLastDirectCostOfStockkeepingUnit(Item2."No.", LastDirectCost * AdjustmentFactor);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CapacityCostPostedToGLForTwoItemsInOneProductionOrder()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        Item: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Manufacturing]
        // [SCENARIO 372232] Capacity cost is posted to G/L when two item are produced in one production order

        // [GIVEN] Work center "W" with unit cost = "X"
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Routing with one operation using work center "W", two manufactured items "I1" and "I2" with the routing
        CreateRouting(RoutingHeader, WorkCenter."No.");
        CreateItemWithRouting(Item[1], RoutingHeader."No.");
        CreateItemWithRouting(Item[2], RoutingHeader."No.");

        // [GIVEN] Production order with 2 lines: first line - item "I1", second line - item "I2"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          Item[1]."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item[1]."No.", '', '', LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item[2]."No.", '', '', LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [GIVEN] Post capacity consumption for the production order in 4 lines: "I1", "I2", "I1", "I2"
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        CreateOutputJournalLine(ItemJournalTemplate, ItemJournalBatch, Item[1]."No.", ProductionOrder."No.");
        CreateOutputJournalLine(ItemJournalTemplate, ItemJournalBatch, Item[2]."No.", ProductionOrder."No.");
        CreateOutputJournalLine(ItemJournalTemplate, ItemJournalBatch, Item[1]."No.", ProductionOrder."No.");
        CreateOutputJournalLine(ItemJournalTemplate, ItemJournalBatch, Item[2]."No.", ProductionOrder."No.");

        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Run Time", 1);
            ItemJournalLine.Validate("Output Quantity", 0);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [WHEN] Post inventory cost to G/L
        PostInvtCostToGL();

        // [THEN] "Cost Posted to G/L" is "X" in all value entries
        VerifyProdOrderCostPostedToGL(ProductionOrder."No.", WorkCenter."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SuggestCapacityStandardCostPageHandler')]
    procedure SuggestCapacityStdCostRprtCreatesWorkCenterStdCostWorksheetsWhenWorkCenterFilterIsApplied()
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        StandardCostWorksheetName: Code[10];
    begin
        // [SCENARIO 537875] Suggest Capacity Standard Cost Report creates Standard Cost Worksheets of only Work Centers when Work Center option is selected in Source field of Request Page.

        // [GIVEN] Create Work Center.
        CreateWorkCenter(WorkCenter);

        // [GIVEN] Create Machine Center.
        CreateMachineCenter(MachineCenter);

        // [GIVEN] Create Standard Cost WorkSheet.
        StandardCostWorksheetName := CreateStandardCostWorksheetName();

        // [GIVEN] Run Suggest Capacity Standard Cost Report Using Use random value for Standard Cost Adjustment Factor.
        RunSuggestCapacityStandardCostReport(
            WorkCenter,
            MachineCenter,
            StandardCostWorksheetName,
            LibraryRandom.RandInt(5),
            '');

        // [WHEN] Find Standard Cost WorkSheet.
        StandardCostWorksheet.SetRange("Standard Cost Worksheet Name", StandardCostWorksheetName);

        // [THEN] Only one Standard Cost Worksheet must be found.
        Assert.RecordCount(StandardCostWorksheet, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AdjustCostItemEntriesHandler')]
    procedure StdCostOfSKUAndAmtOfGLEntryAreSameWhenFinishProOrderAndRunAdjustCostItemEntries()
    var
        GLEntry: Record "G/L Entry";
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 295780] Standard Cost of Stockkeeping Unit is equal to Amount of GL Entry
        // which is created when Production Order is Finished and Stan runs Adjust Cost Item Entries.

        // [GIVEN] Update Automatic Cost Posting, Expected Cost posting to G/L
        // and Average Cost Calc. Type in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);
        LibraryInventory.SetAverageCostSetup("Average Cost Calculation Type"::"Item & Location & Variant", "Average Cost Period Type"::Day);

        // [GIVEN] Create a WorkCenter with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create a Routing.
        CreateRouting(RoutingHeader, WorkCenter."No.");

        // [GIVEN] Create an Item with Routing and Production BOM.
        CreateItemWithRoutingAndProdBOM(Item, RoutingHeader, ProductionBOMLine);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code and Standard Cost in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location.Code);
        StockkeepingUnit.Validate("Standard Cost", LibraryRandom.RandIntInRange(10, 10));
        StockkeepingUnit.Modify(true);

        // [GIVEN] Create a Production Order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        // [GIVEN] Validate Location Code.
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Refresh Prod. Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournal(ProductionOrder, Item);

        // [GIVEN] Change Prod. Order Status.
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);

        // [GIVEN] Find Production Order.
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Finished);
        ProductionOrder.FindFirst();

        // [GIVEN] Run Adjust Cost Item Entries.
        RunAdjustCostItemEntries(Item."No.");

        // [WHEN] Find GL Entry.
        GLEntry.SetLoadFields("Document No.", Amount);
        GLEntry.SetRange("Document No.", ProductionOrder."No.");
        GLEntry.FindFirst();

        // [THEN] Amount of GL Entry is equal to Standard Cost of Stockkeeping Unit.
        Assert.AreEqual(
            StockkeepingUnit."Standard Cost",
            Abs(GLEntry.Amount),
            StrSubstNo(
                AmountErr,
                Abs(GLEntry.Amount),
                StockkeepingUnit."Standard Cost",
                GLEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure StdCostOfSKUIsCalculatedBasedOnRoutingAndProdBOMOfItemIfBothBlankOnSKUWhenCalcStdCostForSKU()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: Record "Work Center";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [SCENARIO 295780] Standard Cost of Stockkeeping Unit is calculated based on Routing and
        // Production BOM of Item if both are blank on it when Calculate Standard Cost.

        // [GIVEN] Create a Work Center with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create a Routing.
        CreateRouting(RoutingHeader, WorkCenter."No.");

        // [GIVEN] Create an Item with Routing and Production BOM.
        CreateItemWithRoutingAndProdBOM(Item, RoutingHeader, ProductionBOMLine);

        // [GIVEN] Calculate Standard Cost for Item.
        Clear(CalculateStandardCost);
        CalculateStandardCost.CalcItem(Item."No.", false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location.Code);
        StockkeepingUnit.Validate("Routing No.", '');
        StockkeepingUnit.Validate("Production BOM No.", '');
        StockkeepingUnit.Modify(true);

        // [GIVEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // [GIVEN] Find Item.
        Item.Get(Item."No.");

        // [WHEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");

        // [THEN] Standard Cost of Stockkeeping Unit is equal to Standard Cost of Item.
        Assert.AreEqual(Item."Standard Cost", StockkeepingUnit."Standard Cost", StrSubstNo(StandardCostMustMatchErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure StdCostOfSKUIsCalculatedBasedOnItsRoutingAndProdBOMOfItemIfBlankProdBOMOnSKUWhenCalcStdCostForSKU()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: array[2] of Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: array[2] of Record "Work Center";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [SCENARIO 295780] Standard Cost of Stockkeeping Unit is calculated based on its Routing and
        // Production BOM of Item if Production BOM No. is blank on it when Calculate Standard Cost.

        // [GIVEN] Create two Work Centers with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[1]);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[2]);

        // [GIVEN] Validate Unit Cost in Work Center [1].
        WorkCenter[1].Validate("Unit Cost", LibraryRandom.RandIntInRange(10, 10));
        WorkCenter[1].Modify(true);

        // [GIVEN] Create two Routings.
        CreateRouting(RoutingHeader[1], WorkCenter[1]."No.");
        CreateRouting(RoutingHeader[2], WorkCenter[2]."No.");

        // [GIVEN] Create an Item with Routing and Production BOM.
        CreateItemWithRoutingAndProdBOM(Item, RoutingHeader[1], ProductionBOMLine);

        // [GIVEN] Calculate Standard Cost for Item.
        Clear(CalculateStandardCost);
        CalculateStandardCost.CalcItem(Item."No.", false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location.Code);
        StockkeepingUnit.Validate("Routing No.", RoutingHeader[2]."No.");
        StockkeepingUnit.Validate("Production BOM No.", '');
        StockkeepingUnit.Modify(true);

        // [GIVEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // [GIVEN] Find Item.
        Item.Get(Item."No.");

        // [WHEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");

        // [THEN] Standard Cost of Stockkeeping Unit is not equal to Standard Cost of Item.
        Assert.AreNotEqual(Item."Standard Cost", StockkeepingUnit."Standard Cost", StrSubstNo(StandardCostMustNotMatchErr, Item."No."));

        // [THEN] Single-Level Material Cost of Stockkeeping Unit is equal to Single-Level Material Cost of Item.
        Assert.AreEqual(
            Item."Single-Level Material Cost",
            StockkeepingUnit."Single-Level Material Cost",
            StrSubstNo(
                SingleLevelMaterialCostMustMatchErr,
                Item."No."));

        // [THEN] Single-Level Capacity Cost of Stockkeeping Unit is not equal to Single-Level Capacity Cost of Item.
        Assert.AreNotEqual(
            Item."Single-Level Capacity Cost",
            StockkeepingUnit."Single-Level Capacity Cost",
            StrSubstNo(
                SingleLevelCapacityCostMustNotMatchErr,
                Item."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure StdCostOfSKUIsCalculatedBasedOnItsProdBOMAndRoutingOfItemIfBlankRoutingOnSKUWhenCalcStdCostForSKU()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionBOMLine: array[2] of Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: Record "Work Center";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [SCENARIO 295780] Standard Cost of Stockkeeping Unit is calculated based on its Production BOM and
        // Routing of Item if Routing No. is blank on it when Calculate Standard Cost.

        // [GIVEN] Create a Work Center with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create a Routing.
        CreateRouting(RoutingHeader, WorkCenter."No.");

        // [GIVEN] Create an Item with Routing and Production BOM.
        CreateItemWithRoutingAndProdBOM(Item, RoutingHeader, ProductionBOMLine[1]);

        // [GIVEN] Calculate Standard Cost for Item.
        Clear(CalculateStandardCost);
        CalculateStandardCost.CalcItem(Item."No.", false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location.Code);
        StockkeepingUnit.Validate("Routing No.", '');
        StockkeepingUnit.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine[2], Item."Base Unit of Measure"));
        StockkeepingUnit.Modify(true);

        // [GIVEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // [GIVEN] Find Item.
        Item.Get(Item."No.");

        // [WHEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");

        // [THEN] Standard Cost of Stockkeeping Unit is not equal to Standard Cost of Item.
        Assert.AreNotEqual(Item."Standard Cost", StockkeepingUnit."Standard Cost", StrSubstNo(StandardCostMustNotMatchErr, Item."No."));

        // [THEN] Single-Level Material Cost of Stockkeeping Unit is not equal to Single-Level Material Cost of Item.
        Assert.AreNotEqual(
            Item."Single-Level Material Cost",
            StockkeepingUnit."Single-Level Material Cost",
            StrSubstNo(
                SingleLevelMaterialCostMustNotMatchErr,
                Item."No."));

        // [THEN] Single-Level Capacity Cost of Stockkeeping Unit is equal to Single-Level Capacity Cost of Item.
        Assert.AreEqual(
            Item."Single-Level Capacity Cost",
            StockkeepingUnit."Single-Level Capacity Cost",
            StrSubstNo(
                SingleLevelCapacityCostMustMatchErr,
                Item."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure StdCostOfSKUIsCalculatedBasedOnItsRoutingAndProdBOMIfBothNotBlankOnSKUWhenCalcStdCostForSKU()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionBOMLine: array[2] of Record "Production BOM Line";
        RoutingHeader: array[2] of Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: array[2] of Record "Work Center";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [SCENARIO 295780] Standard Cost of Stockkeeping Unit is calculated based on its Production BOM and
        // Routing if both are not blank on it when Calculate Standard Cost.

        // [GIVEN] Create two Work Centers with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[1]);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[2]);

        // [GIVEN] Validate Unit Cost in Work Center [1].
        WorkCenter[1].Validate("Unit Cost", LibraryRandom.RandIntInRange(10, 10));
        WorkCenter[1].Modify(true);

        // [GIVEN] Create two Routings.
        CreateRouting(RoutingHeader[1], WorkCenter[1]."No.");
        CreateRouting(RoutingHeader[2], WorkCenter[2]."No.");

        // [GIVEN] Create an Item with Routing and Production BOM.
        CreateItemWithRoutingAndProdBOM(Item, RoutingHeader[1], ProductionBOMLine[1]);

        // [GIVEN] Calculate Standard Cost for Item.
        Clear(CalculateStandardCost);
        CalculateStandardCost.CalcItem(Item."No.", false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location.Code);
        StockkeepingUnit.Validate("Routing No.", RoutingHeader[2]."No.");
        StockkeepingUnit.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine[2], Item."Base Unit of Measure"));
        StockkeepingUnit.Modify(true);

        // [GIVEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // [GIVEN] Find Item.
        Item.Get(Item."No.");

        // [WHEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");

        // [THEN] Standard Cost of Stockkeeping Unit is not equal to Standard Cost of Item.
        Assert.AreNotEqual(Item."Standard Cost", StockkeepingUnit."Standard Cost", StrSubstNo(StandardCostMustNotMatchErr, Item."No."));

        // [THEN] Single-Level Material Cost of Stockkeeping Unit is not equal to Single-Level Material Cost of Item.
        Assert.AreNotEqual(
            Item."Single-Level Material Cost",
            StockkeepingUnit."Single-Level Material Cost",
            StrSubstNo(
                SingleLevelMaterialCostMustNotMatchErr,
                Item."No."));

        // [THEN] Single-Level Capacity Cost of Stockkeeping Unit is not equal to Single-Level Capacity Cost of Item.
        Assert.AreNotEqual(
            Item."Single-Level Capacity Cost",
            StockkeepingUnit."Single-Level Capacity Cost",
            StrSubstNo(
                SingleLevelCapacityCostMustNotMatchErr,
                Item."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure StdCostOfSKUIsCalculatedEvenIfLengthOfItemNoIsUpTo20()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: array[2] of Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: array[2] of Record "Work Center";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [SCENARIO 563958] Standard Cost of Stockkeeping Unit is calculated even
        // if the Item No. is up to 20 characters in length.

        // [GIVEN] Create two Work Centers with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[1]);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[2]);

        // [GIVEN] Validate Unit Cost in Work Center [1].
        WorkCenter[1].Validate("Unit Cost", LibraryRandom.RandIntInRange(10, 10));
        WorkCenter[1].Modify(true);

        // [GIVEN] Create two Routings.
        CreateRouting(RoutingHeader[1], WorkCenter[1]."No.");
        CreateRouting(RoutingHeader[2], WorkCenter[2]."No.");

        // [GIVEN] Create an Item without No. Series and of 20 characters in length.
        CreateItemWithoutNoSeries(Item);

        // [GIVEN] Validate Routing and Production BOM in Item.
        ValidateRoutingAndProdBOMInItem(Item, RoutingHeader[1], ProductionBOMLine);

        // [GIVEN] Calculate Standard Cost for Item.
        Clear(CalculateStandardCost);
        CalculateStandardCost.CalcItem(Item."No.", false);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location.Code);
        StockkeepingUnit.Validate("Routing No.", RoutingHeader[2]."No.");
        StockkeepingUnit.Validate("Production BOM No.", '');
        StockkeepingUnit.Modify(true);

        // [GIVEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // [GIVEN] Find Item.
        Item.Get(Item."No.");

        // [WHEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");

        // [THEN] Standard Cost of Stockkeeping Unit is not equal to Standard Cost of Item.
        Assert.AreNotEqual(Item."Standard Cost", StockkeepingUnit."Standard Cost", StrSubstNo(StandardCostMustNotMatchErr, Item."No."));

        // [THEN] Single-Level Material Cost of Stockkeeping Unit is equal to Single-Level Material Cost of Item.
        Assert.AreEqual(
            Item."Single-Level Material Cost",
            StockkeepingUnit."Single-Level Material Cost",
            StrSubstNo(
                SingleLevelMaterialCostMustMatchErr,
                Item."No."));

        // [THEN] Single-Level Capacity Cost of Stockkeeping Unit is not equal to Single-Level Capacity Cost of Item.
        Assert.AreNotEqual(
            Item."Single-Level Capacity Cost",
            StockkeepingUnit."Single-Level Capacity Cost",
            StrSubstNo(
                SingleLevelCapacityCostMustNotMatchErr,
                Item."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure CostAmountInProdOrderLineIsCalculatedByUnitCostOfSKUWhenSelectLocationCodeOfSKU()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: Record "Work Center";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        CostAmount: Decimal;
    begin
        // [SCENARIO 563931] Cost Amount in Prod. Order line is calculated by Unit Cost of
        // Stockkeeping Unit when Validate Location Code of Stockkeeping Unit.

        // [GIVEN] Create a Work Center with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Validate Unit Cost in Work Center.
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandIntInRange(10, 10));
        WorkCenter.Modify(true);

        // [GIVEN] Create a Routing.
        CreateRouting(RoutingHeader, WorkCenter."No.");

        // [GIVEN] Create an Item and Validate Costing Method, Replenishment System and Production BOM No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine, Item."Base Unit of Measure"));
        Item.Modify(true);

        // [GIVEN] Calculate Standard Cost for Item.
        Clear(CalculateStandardCost);
        CalculateStandardCost.CalcItem(Item."No.", false);

        // [GIVEN] Create two Locations with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location[1].Code);
        StockkeepingUnit.Validate("Routing No.", RoutingHeader."No.");
        StockkeepingUnit.Validate("Production BOM No.", '');
        StockkeepingUnit.Modify(true);

        // [GIVEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // [GIVEN] Find Item.
        Item.Get(Item."No.");

        // [WHEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");

        // [THEN] Standard Cost of Stockkeeping Unit is not equal to Standard Cost of Item.
        Assert.AreNotEqual(Item."Standard Cost", StockkeepingUnit."Standard Cost", StrSubstNo(StandardCostMustNotMatchErr, Item."No."));

        // [GIVEN] Create a Production Order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Create a Prod. Order Line.
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine,
            ProdOrderLine.Status::Released,
            ProductionOrder."No.",
            Item."No.",
            '',
            Location[2].Code,
            LibraryRandom.RandInt(0));

        // [GIVEN] Generate and save Cost Amount [1] in a Variable.
        CostAmount := ProdOrderLine."Cost Amount";

        // [WHEN] Validate Location Code in Prod. Order Line.
        ProdOrderLine.Validate("Location Code", Location[1].Code);
        ProdOrderLine.Modify(true);

        // [THEN] Cost Amount of Prod. Order Line is not equal to CostAmount.
        Assert.AreNotEqual(CostAmount, ProdOrderLine."Cost Amount", StrSubstNo(CostAmountMustNotMatchErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure CostAmountInProdOrderLineIsCalculatedByUnitCostOfItemWhenLocationCodeIsBlank()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        WorkCenter: Record "Work Center";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // [SCENARIO 563931] Cost Amount in Prod. Order line is calculated by Unit Cost of
        // Item when Validate Location Code to blank.

        // [GIVEN] Create a Work Center with Calendar.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Validate Unit Cost in Work Center.
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandIntInRange(10, 10));
        WorkCenter.Modify(true);

        // [GIVEN] Create a Routing.
        CreateRouting(RoutingHeader, WorkCenter."No.");

        // [GIVEN] Create an Item and Validate Costing Method, Replenishment System and Production BOM No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine, Item."Base Unit of Measure"));
        Item.Modify(true);

        // [GIVEN] Calculate Standard Cost for Item.
        Clear(CalculateStandardCost);
        CalculateStandardCost.CalcItem(Item."No.", false);

        // [GIVEN] Create two Locations with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Create Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(Item, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Stockkeeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        StockkeepingUnit.Validate("Location Code", Location[1].Code);
        StockkeepingUnit.Validate("Routing No.", RoutingHeader."No.");
        StockkeepingUnit.Validate("Production BOM No.", '');
        StockkeepingUnit.Modify(true);

        // [GIVEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code");

        // [GIVEN] Find Item.
        Item.Get(Item."No.");

        // [WHEN] Find Stockkeeping Unit.
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");

        // [THEN] Standard Cost of Stockkeeping Unit is not equal to Standard Cost of Item.
        Assert.AreNotEqual(Item."Standard Cost", StockkeepingUnit."Standard Cost", StrSubstNo(StandardCostMustNotMatchErr, Item."No."));

        // [GIVEN] Create a Production Order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Create a Prod. Order Line.
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine,
            ProdOrderLine.Status::Released,
            ProductionOrder."No.",
            Item."No.",
            '',
            Location[2].Code,
            LibraryRandom.RandInt(0));

        // [WHEN] Validate Location Code in Prod. Order Line.
        ProdOrderLine.Validate("Location Code", Location[1].Code);
        ProdOrderLine.Modify(true);

        // [THEN] Cost Amount of Prod. Order Line is equal to Standard Cost of SKU.
        Assert.AreEqual(
            StockkeepingUnit."Standard Cost",
            ProdOrderLine."Cost Amount",
            StrSubstNo(AmountErr, ProdOrderLine.FieldCaption("Cost Amount"), StockkeepingUnit."Standard Cost", ProdOrderLine.TableCaption()));

        // [WHEN] Validate Location Code to blank in Prod. Order Line.
        ProdOrderLine.Validate("Location Code", '');
        ProdOrderLine.Modify(true);

        // [THEN] Cost Amount of Prod. Order Line is equal to Standard Cost of Item.
        Assert.AreEqual(
            Item."Standard Cost",
            ProdOrderLine."Cost Amount",
            StrSubstNo(AmountErr, ProdOrderLine.FieldCaption("Cost Amount"), Item."Standard Cost", ProdOrderLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Batch");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        // Clear global variables.
        ClearGlobalVariables();

        DeleteObjectOptionsIfNeeded();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Batch");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        RunAdjustCostItemEntries('');
        PostInvtCostToGL();
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Batch");
    end;

    local procedure ClearGlobalVariables()
    begin
        Clear(SalesLCY2);
        Clear(COGSLCY2);
        Clear(NonInvtblCostsLCY2);
        Clear(ProfitLCY2);
        Clear(ProfitPercentage2);
        Clear(ShowError);
        Clear(CalculationDate);
        Clear(AverageCost);
        Clear(IncreaseQuantity);
        Clear(DecreaseQuantity);
    end;

    local procedure CreateCampaign(): Code[20]
    var
        Campaign: Record Campaign;
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        exit(Campaign."No.");
    end;

    local procedure CreateAndModifyItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; StandardCost: Decimal; UnitCost: Decimal)
    begin
        CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Standard Cost", StandardCost);
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal): Code[20]
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine."Document No.");
    end;

    local procedure CreateAndPostItemJournalLineWithUnitCost(ItemNo: Code[20]): Decimal
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(
          ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        ModifyItemJournalLine(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine."Unit Amount");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Use random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Use random Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(10));  // Taking Random Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateItemDataRoundingFactor(var ItemNo: Code[20]; var Quantity: Decimal; var SalesAmount: Decimal; Idx: Integer)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        Quantity := LibraryRandom.RandDec(100, 2);
        SalesAmount := LibraryRandom.RandDec(100, 2) * Idx;
        CreateItem(Item);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", Quantity + Quantity / 2, SalesAmount);
        ItemNo := Item."No.";
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerPriceGroup(): Code[10]
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        exit(CustomerPriceGroup.Code);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; RoutingNo: Code[20])
    begin
        CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center")
    begin
        LibraryManufacturing.CreateMachineCenter(MachineCenter, '', LibraryRandom.RandDec(10, 1));  // Use random value for Capacity.
        MachineCenter.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));  // Use random value for Unit Cost.
        MachineCenter.Modify(true);
    end;

    local procedure CreateManufacturingItem(var ProductionBOMLine: Record "Production BOM Line"): Code[20]
    var
        Item: Record Item;
    begin
        CreateAndModifyItem(Item, Item."Costing Method"::FIFO, 0, LibraryRandom.RandDec(100, 2));  // Use 0 for Standard Cost and random value for Unit Cost.
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine, Item."Base Unit of Measure"));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMLine: Record "Production BOM Line"; UnitOfMeasureCode: Code[10]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
    begin
        CreateAndModifyItem(Item, Item."Costing Method"::FIFO, 0, LibraryRandom.RandDec(100, 2));  // Use 0 for Standard Cost and random value for Unit Cost.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));  // Taking Random Quantity.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateOutputJournalLine(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; ProdOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProdOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(10));
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateSalesPrice(Item: Record Item; SalesType: Enum "Sales Price Type"; SalesCode: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        // Create Sales Price with random Minimum Quantity and Unit Price.
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesType, SalesCode, Item."No.", WorkDate(), '', '', Item."Base Unit of Measure", LibraryRandom.RandDec(100, 2));
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesPrice.Modify(true);
    end;

    local procedure CreateStandardCostWorksheetName(): Code[10]
    var
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
    begin
        LibraryInventory.CreateStandardCostWorksheetName(StandardCostWorksheetName);
        exit(StandardCostWorksheetName.Name);
    end;

    local procedure CreateStockkeepingUnit(Item: Record Item)
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocation(Location);
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", Location.Code);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
    end;

    local procedure CreateSKUWithLastDirectCost(var Item: Record Item; VendorNo: Code[20]): Decimal
    begin
        CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
        CreateStockkeepingUnit(Item);
        exit(UpdateLastDirectCostOnStockkeepingUnit(Item."No."));
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));  // Use random value for Unit Cost.
        WorkCenter.Modify(true);
    end;

    local procedure DeleteStandardCostWorksheetLines(StandardCostWorksheetName: Code[10])
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        StandardCostWorksheet.SetRange("Standard Cost Worksheet Name", StandardCostWorksheetName);
        StandardCostWorksheet.DeleteAll(true);
    end;

    local procedure DefineGlobalValues(AdjustOption: Option; AdjustFieldOption: Enum ItemCostPriceFieldOption; Factor: Decimal; RoundingMethod: Code[10])
    begin
        Adjust := AdjustOption; // This variable is made Global as it is used in the handler.
        AdjustField := AdjustFieldOption; // This variable is made Global as it is used in the handler.
        AdjustmentFactor := Factor; // Taking Random value. This variable is made Global as it is used in the handler.
        RoundingMethodCode := RoundingMethod; // This variable is made Global as it is used in the handler.
    end;

    local procedure FindStandardCostWorksheet(var StandardCostWorksheet: Record "Standard Cost Worksheet"; StandardCostWorksheetName: Code[10]; Type: Enum "Standard Cost Source Type"; No: Code[20])
    begin
        StandardCostWorksheet.SetRange("Standard Cost Worksheet Name", StandardCostWorksheetName);
        StandardCostWorksheet.SetRange(Type, Type);
        StandardCostWorksheet.SetRange("No.", No);
        StandardCostWorksheet.FindFirst();
    end;

    local procedure FindStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20])
    begin
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.FindFirst();
    end;

    local procedure GetGLEntryNo(DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
        exit(GLEntry."Entry No.");
    end;

    local procedure GetNumberOfStandardCostWorksheetLines(StandardCostWorksheetName: Code[10]): Integer
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        StandardCostWorksheet.SetRange("Standard Cost Worksheet Name", StandardCostWorksheetName);
        exit(StandardCostWorksheet.Count);
    end;

    local procedure ModifyItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Taking Random Unit Cost.
        ItemJournalLine.Modify(true);
    end;

    local procedure PostInvtCostToGL()
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostInventoryCosttoGL: Report "Post Inventory Cost to G/L";
        PostMethod: Option "Per Posting Group","Per Entry";
    begin
        Commit();
        PostValueEntryToGL.Reset();
        PostMethod := PostMethod::"Per Entry";
        PostInventoryCosttoGL.InitializeRequest(PostMethod, '', true);
        PostInventoryCosttoGL.SetTableView(PostValueEntryToGL);
        PostInventoryCosttoGL.UseRequestPage(false);
        PostInventoryCosttoGL.SaveAsPdf(StrSubstNo(FileName, TemporaryPath, LibraryUtility.GetGlobalNoSeriesCode()));
    end;

    local procedure RunAdjustCostItemEntries(ItemNoFilter: Text[250])
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
    begin
        Clear(AdjustCostItemEntries);
        Commit();  // Commit required for batch job reports.
        AdjustCostItemEntries.InitializeRequest(ItemNoFilter, '');
        AdjustCostItemEntries.UseRequestPage(true);
        AdjustCostItemEntries.RunModal();
    end;

    local procedure RunAdjustItemCostPricesReportWithItem(Item: Record Item)
    var
        AdjustItemCostsPrices: Report "Adjust Item Costs/Prices";
    begin
        Commit();  // COMMIT is required to run the report.
        Clear(AdjustItemCostsPrices);
        Item.SetRange("No.", Item."No.");
        AdjustItemCostsPrices.SetTableView(Item);
        AdjustItemCostsPrices.UseRequestPage(true);
        AdjustItemCostsPrices.Run();
    end;

    local procedure RunAdjustItemCostPricesReportWithStockkeepingUnit(ItemNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        AdjustItemCostsPrices: Report "Adjust Item Costs/Prices";
    begin
        Commit();  // COMMIT is required to run the report.
        Clear(AdjustItemCostsPrices);
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        AdjustItemCostsPrices.SetTableView(StockkeepingUnit);
        AdjustItemCostsPrices.UseRequestPage(true);
        AdjustItemCostsPrices.Run();
    end;

    local procedure RunAdjustItemCostPricesReportWithItemFilter(VendorNo: Code[20])
    var
        Item: Record Item;
        AdjustItemCostsPrices: Report "Adjust Item Costs/Prices";
    begin
        Commit(); // COMMIT is required to run the report.
        Clear(AdjustItemCostsPrices);
        Item.SetRange("Vendor No.", VendorNo);
        AdjustItemCostsPrices.SetTableView(Item);
        AdjustItemCostsPrices.UseRequestPage(true);
        AdjustItemCostsPrices.Run();
    end;

    local procedure RunImplementStandardCostChange(StandardCostWorksheetName: Code[10]; Type: Enum "Standard Cost Source Type"; No: Code[20])
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        ImplementStandardCostChange: Report "Implement Standard Cost Change";
    begin
        Commit();  // Commit required for batch job reports.
        StandardCostWorksheet.SetRange("Standard Cost Worksheet Name", StandardCostWorksheetName);
        StandardCostWorksheet.SetRange(Type, Type);
        StandardCostWorksheet.SetRange("No.", No);
        Clear(ImplementStandardCostChange);
        ImplementStandardCostChange.SetTableView(StandardCostWorksheet);
        ImplementStandardCostChange.SetStdCostWksh(StandardCostWorksheetName);
        ImplementStandardCostChange.UseRequestPage(true);
        ImplementStandardCostChange.Run();
    end;

    local procedure RunRollUpStandardCost(StandardCostWorksheetName: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
        RollUpStandardCost: Report "Roll Up Standard Cost";
    begin
        ProductionBOMHeader.ModifyAll(Status, ProductionBOMHeader.Status::Certified);  // Use to Certify all Production BOM before running the report.
        Commit();  // Commit required for batch job reports.
        Item.SetRange("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Clear(RollUpStandardCost);
        RollUpStandardCost.SetTableView(Item);
        RollUpStandardCost.SetStdCostWksh(StandardCostWorksheetName);
        RollUpStandardCost.UseRequestPage(true);
        RollUpStandardCost.Run();
    end;

    local procedure RunItemStatistics(ItemNo: Code[20]; RoundingFactor: Enum "Analysis Rounding Factor")
    var
        ItemCard: TestPage "Item Card";
    begin
        LibraryVariableStorage.Enqueue(RoundingFactor);
        ItemCard.OpenView();
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        ItemCard.Statistics.Invoke();
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetPurchaseAndSaleAmount(var PurchaseUnitAmount: Decimal; var PurchaseUnitAmount2: Decimal): Decimal
    begin
        PurchaseUnitAmount := LibraryRandom.RandDec(100, 2);  // Use Random Unit Amount.
        PurchaseUnitAmount2 := PurchaseUnitAmount + LibraryRandom.RandDec(100, 2);  // PurchaseUnitAmount2 is greater than PurchaseUnitAmount required for test case.
        exit(PurchaseUnitAmount2 + LibraryRandom.RandDec(100, 2));  // SalesUnitAmount is greater than PurchaseUnitAmount2 required for test case.
    end;

    local procedure DisableAutomaticCostPosting()
    begin
        RunAdjustCostItemEntries('');
        LibraryInventory.SetAutomaticCostPosting(false);
        LibraryInventory.SetAutomaticCostAdjmtNever();
    end;

    local procedure UpdateLastDirectCostOnStockkeepingUnit(ItemNo: Code[20]): Decimal
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        FindStockkeepingUnit(StockkeepingUnit, ItemNo);
        StockkeepingUnit.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Taking Random value.
        StockkeepingUnit.Modify(true);
        exit(StockkeepingUnit."Last Direct Cost");
    end;

    local procedure VerifyAverageCostCalcOverview(var AverageCostCalcOverview: TestPage "Average Cost Calc. Overview"; Type: Option; Quantity: Decimal)
    begin
        AverageCostCalcOverview.FILTER.SetFilter(Type, Format(Type));
        AverageCostCalcOverview.AverageCostCntrl.AssertEquals(Round(AverageCost, LibraryERM.GetAmountRoundingPrecision()));
        AverageCostCalcOverview.Quantity.AssertEquals(Quantity);
    end;

    local procedure VerifyCopyStandardCostWorkSheet(StandardCostWorksheetName: Code[10]; Type: Enum "Standard Cost Source Type"; No: Code[20])
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        FindStandardCostWorksheet(StandardCostWorksheet, StandardCostWorksheetName, Type, No);
        StandardCostWorksheet.TestField("No.", No);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; EntryNo: Integer; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter("Entry No.", '>%1', EntryNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(ValidationError, GLEntry.FieldCaption(Amount), Amount));
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; InvoicedQuantity: Decimal; CostAmountActual: Decimal; SalesAmountActual: Decimal; Open: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Open, Open);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Sales Amount (Actual)");
        ItemLedgerEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        Assert.AreNearlyEqual(
          CostAmountActual, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
        Assert.AreNearlyEqual(
          SalesAmountActual, ItemLedgerEntry."Sales Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemLedgerEntry.FieldCaption("Sales Amount (Actual)"), SalesAmountActual));
    end;

    local procedure VerifyItemStatistics(Quantity: Decimal; SalesUnitAmount: Decimal; PurchaseUnitAmount: Decimal; PurchaseUnitAmount2: Decimal; RoundingFactor: Enum "Analysis Rounding Factor")
    var
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        MatrixMgt: Codeunit "Matrix Management";
        SalesLCY: Decimal;
        COGSLCY: Decimal;
        ProfitLCY: Decimal;
        ProfitPercentage: Decimal;
    begin
        SalesLCY := MatrixMgt.RoundAmount((Quantity + Quantity / 2) * SalesUnitAmount, RoundingFactor);
        Assert.AreNearlyEqual(
          SalesLCY, SalesLCY2, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemStatisticsBuffer.FieldCaption("Sales (LCY)"), SalesLCY));

        COGSLCY := -MatrixMgt.RoundAmount((Quantity * PurchaseUnitAmount) + (Quantity / 2 * PurchaseUnitAmount2), RoundingFactor);
        Assert.AreNearlyEqual(
          COGSLCY, COGSLCY2, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemStatisticsBuffer.FieldCaption("COGS (LCY)"), COGSLCY));
        Assert.AreEqual(0, NonInvtblCostsLCY2, StrSubstNo(ValidationError, ItemStatisticsBuffer.FieldCaption("Inventoriable Costs"), 0));

        ProfitLCY := SalesLCY + COGSLCY;
        Assert.AreNearlyEqual(
          ProfitLCY, ProfitLCY2, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemStatisticsBuffer.FieldCaption("Profit (LCY)"), ProfitLCY));

        ProfitPercentage := ProfitLCY / SalesLCY * 100;
        Assert.AreNearlyEqual(
          ProfitPercentage, ProfitPercentage2, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemStatisticsBuffer.FieldCaption("Profit %"), ProfitPercentage));
    end;

    local procedure VerifyItemTurnover(ItemNo: Code[20]; Quantity: Decimal; SalesUnitAmount: Decimal; PurchaseUnitAmount: Decimal; PurchaseUnitAmount2: Decimal)
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemTurnover: TestPage "Item Turnover";
        PurchasesQty: Decimal;
        PurchasesLCY: Decimal;
        SalesQty: Decimal;
        SalesLCY: Decimal;
    begin
        ItemCard.OpenView();
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        ItemTurnover.Trap();
        ItemCard."T&urnover".Invoke();
        ItemTurnover.PeriodType.SetValue(Format(ItemTurnover.PeriodType.GetOption(5)));  // Use 5 for Year Required for Test Case.
        ItemTurnover.ItemTurnoverLines.FILTER.SetFilter("Period Start", Format(DMY2Date(1, 1, Date2DMY(WorkDate(), 3))));

        PurchasesQty := Quantity + Quantity;  // Total Purchase Quantity.
        Assert.AreNearlyEqual(
          PurchasesQty, ItemTurnover.ItemTurnoverLines.PurchasesQty.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, Item.FieldCaption("Purchases (Qty.)"), PurchasesQty));

        PurchasesLCY := (Quantity * PurchaseUnitAmount) + (Quantity * PurchaseUnitAmount2);
        Assert.AreNearlyEqual(
          PurchasesLCY, ItemTurnover.ItemTurnoverLines.PurchasesLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, Item.FieldCaption("Purchases (LCY)"), PurchasesLCY));

        SalesQty := Quantity + Quantity / 2;  // Total Sale Quantity.
        Assert.AreNearlyEqual(
          SalesQty, ItemTurnover.ItemTurnoverLines.SalesQty.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, Item.FieldCaption("Sales (Qty.)"), SalesQty));

        SalesLCY := (Quantity + Quantity / 2) * SalesUnitAmount;
        Assert.AreNearlyEqual(
          SalesLCY, ItemTurnover.ItemTurnoverLines.SalesLCY.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, Item.FieldCaption("Sales (LCY)"), SalesLCY));
    end;

    local procedure VerifySalesPriceWorksheet(SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; CurrencyCode: Code[10]; ItemNo: Code[20])
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        SalesPriceWorksheet.SetRange("Sales Type", SalesType);
        SalesPriceWorksheet.SetRange("Sales Code", SalesCode);
        SalesPriceWorksheet.SetRange("Currency Code", CurrencyCode);
        SalesPriceWorksheet.SetRange("Item No.", ItemNo);
        SalesPriceWorksheet.FindFirst();
    end;

    local procedure VerifyStandardCostWorksheet(StandardCostWorksheetName: Code[10]; Type: Enum "Standard Cost Source Type"; No: Code[20])
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        FindStandardCostWorksheet(StandardCostWorksheet, StandardCostWorksheetName, Type, No);
        StandardCostWorksheet.TestField(Implemented, true);
    end;

    local procedure VerifyLastDirectCostOfStockkeepingUnit(ItemNo: Code[20]; LastDirectCost: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        FindStockkeepingUnit(StockkeepingUnit, ItemNo);
        StockkeepingUnit.TestField("Last Direct Cost", LastDirectCost);
    end;

    local procedure VerifyProdOrderCostPostedToGL(ProdOrderNo: Code[20]; CostAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProdOrderNo);
        ValueEntry.SetFilter("Cost Posted to G/L", '<>%1', CostAmount);
        Assert.RecordIsEmpty(ValueEntry);
    end;

    local procedure VerifyUnitCostInProductionOrderLine(ProductionOrder: Record "Production Order"; UnitCost: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField("Unit Cost", UnitCost);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; InvoicedQuantity: Decimal; CostAmountActual: Decimal; SalesAmountActual: Decimal; Adjustment: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        Assert.AreNearlyEqual(
          CostAmountActual, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
        Assert.AreNearlyEqual(
          SalesAmountActual, ValueEntry."Sales Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ValueEntry.FieldCaption("Sales Amount (Actual)"), SalesAmountActual));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesHandler(var AdjustCostItemEntries: TestRequestPage "Adjust Cost - Item Entries")
    begin
        CurrentSaveValuesId := REPORT::"Adjust Cost - Item Entries";
        AdjustCostItemEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustItemCostPricesHandler(var AdjustItemCostsPrices: TestRequestPage "Adjust Item Costs/Prices")
    begin
        CurrentSaveValuesId := REPORT::"Adjust Item Costs/Prices";
        AdjustItemCostsPrices.Adjust.SetValue(Adjust);
        AdjustItemCostsPrices.AdjustField.SetValue(AdjustField);
        AdjustItemCostsPrices.AdjustmentFactor.SetValue(AdjustmentFactor);
        AdjustItemCostsPrices.Rounding_Method.SetValue(RoundingMethodCode);
        AdjustItemCostsPrices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsHandler(var ItemStatistics: TestPage "Item Statistics")
    var
        RoundingFactor: Variant;
    begin
        ItemStatistics.DateFilter.SetValue(WorkDate());
        LibraryVariableStorage.Dequeue(RoundingFactor);
        ItemStatistics.RoundingFactor.SetValue(RoundingFactor);
        ItemStatistics.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatisticsMatrixHandler(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    begin
        SalesLCY2 := ItemStatisticsMatrix.Amount.AsDecimal();  // Use SalesLCY2 as global for Test Page Handler.
        ItemStatisticsMatrix.Next();
        COGSLCY2 := ItemStatisticsMatrix.Amount.AsDecimal();  // Use COGSLCY2 as global for Test Page Handler.
        ItemStatisticsMatrix.Next();
        NonInvtblCostsLCY2 := ItemStatisticsMatrix.Amount.AsDecimal();  // Use NonInvtblCostsLCY2 as global for Test Page Handler.
        ItemStatisticsMatrix.Next();
        ProfitLCY2 := ItemStatisticsMatrix.Amount.AsDecimal();  // Use ProfitLCY2 as global for Test Page Handler.
        ItemStatisticsMatrix.Next();
        ProfitPercentage2 := ItemStatisticsMatrix.Amount.AsDecimal();  // Use ProfitPercentage2 as global for Test Page Handler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImplementStandardCostChangeHandler(var ImplementStandardCostChange: TestRequestPage "Implement Standard Cost Change")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CurrentSaveValuesId := REPORT::"Implement Standard Cost Change";
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation, ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalTemplate.SetValue(ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalBatchName.SetValue(ItemJournalBatch.Name);
        if ShowError then
            ImplementStandardCostChange.DocumentNo.SetValue('');

        ImplementStandardCostChange.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RollUpStandardCostHandler(var RollUpStandardCost: TestRequestPage "Roll Up Standard Cost")
    begin
        CurrentSaveValuesId := REPORT::"Roll Up Standard Cost";
        RollUpStandardCost.CalculationDate.SetValue(CalculationDate);
        RollUpStandardCost.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCapacityStandardCostPageHandler(var SuggestCapacityStandardCostPage: TestRequestPage "Suggest Capacity Standard Cost")
    var
        WorkSheetSource: Option All,"Work Center","Machine Center",Resource;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            WorkSheetSource::"Work Center":
                SuggestCapacityStandardCostPage.Source.SetValue(WorkSheetSource::"Work Center");
        end;
        SuggestCapacityStandardCostPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AverageCostCalcOverviewHandler(var AverageCostCalcOverview: TestPage "Average Cost Calc. Overview")
    var
        AverageCostCalcOverview2: Record "Average Cost Calc. Overview";
    begin
        VerifyAverageCostCalcOverview(
          AverageCostCalcOverview, AverageCostCalcOverview2.Type::"Closing Entry", IncreaseQuantity + DecreaseQuantity);
        VerifyAverageCostCalcOverview(AverageCostCalcOverview, AverageCostCalcOverview2.Type::Increase, IncreaseQuantity);
        VerifyAverageCostCalcOverview(AverageCostCalcOverview, AverageCostCalcOverview2.Type::Decrease, DecreaseQuantity);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemsStatisticsHandler(var ItemStatistics: TestPage "Item Statistics")
    var
        ViewBy: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        ItemStatistics.DateFilter.SetValue(StrSubstNo('%1..%2', CalcDate('<-CW>', WorkDate()), CalcDate('<CW>', WorkDate())));
        ItemStatistics.ViewBy.SetValue(ViewBy::Week);
        LibraryVariableStorage.Enqueue(ItemStatistics.MATRIX_CaptionRange.Value);
        ItemStatistics.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemsStatisticsMatrixHandler(var ItemStatisticsMatrix: TestPage "Item Statistics Matrix")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Assert.AreEqual(Value, ItemStatisticsMatrix.Field1.Caption, InvalidColumnCaptionError);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

    local procedure RunSuggestCapacityStandardCostReport(var WorkCenter: Record "Work Center"; var MachineCenter: Record "Machine Center"; StandardCostWorksheetName: Code[10]; StandardCostAdjustmentFactor: Integer; StandardCostRoundingMethod: Code[10])
    var
        TmpWorkCenter: Record "Work Center";
        TmpMachineCenter: Record "Machine Center";
        SuggestCapacityStandardCostReport: Report "Suggest Capacity Standard Cost";
        WorkSheetSource: Option All,"Work Center","Machine Center",Resource;
    begin
        Clear(SuggestCapacityStandardCostReport);
        SuggestCapacityStandardCostReport.Initialize(
          StandardCostWorksheetName, StandardCostAdjustmentFactor, 0, 0, StandardCostRoundingMethod, '', '');
        if WorkCenter.HasFilter then
            TmpWorkCenter.CopyFilters(WorkCenter)
        else begin
            WorkCenter.Get(WorkCenter."No.");
            TmpWorkCenter.SetRange("No.", WorkCenter."No.");
        end;
        SuggestCapacityStandardCostReport.SetTableView(TmpWorkCenter);

        if MachineCenter.HasFilter then
            TmpMachineCenter.CopyFilters(MachineCenter)
        else begin
            MachineCenter.Get(MachineCenter."No.");
            TmpMachineCenter.SetRange("No.", MachineCenter."No.");
        end;
        SuggestCapacityStandardCostReport.SetTableView(TmpMachineCenter);
        SuggestCapacityStandardCostReport.UseRequestPage(true);

        Commit();
        LibraryVariableStorage.Enqueue(WorkSheetSource::"Work Center");
        SuggestCapacityStandardCostReport.Run();
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrder: Record "Production Order"; Item: Record Item)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);

        CreateOutputJournalLine(ItemJournalTemplate, ItemJournalBatch, Item."No.", ProductionOrder."No.");

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateItemWithRoutingAndProdBOM(var Item: Record Item; RoutingHeader: Record "Routing Header"; ProductionBOMLine: Record "Production BOM Line")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine, Item."Base Unit of Measure"));
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure ValidateRoutingAndProdBOMInItem(var Item: Record Item; RoutingHeader: Record "Routing Header"; ProductionBOMLine: Record "Production BOM Line")
    begin
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine, Item."Base Unit of Measure"));
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemWithoutNoSeries(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        Item.Init();
        Item."No." := LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), DATABASE::Item);
        Item.Insert(true);

        LibraryInventory.CreateItemUnitOfMeasure(
            ItemUnitOfMeasure,
            Item."No.",
            '',
            LibraryRandom.RandInt(0));

        CreateVATPostingGroup(VATPostingSetup);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);

        Item.Validate(Description, Item."No.");
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate(Type, Item.Type::Inventory);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
    end;

    local procedure CreateVATPostingGroup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingSetup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingSetup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingSetup.Code);
    end;
}
