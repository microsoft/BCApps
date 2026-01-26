codeunit 144100 "ERM Fiscal LIFO"
{
    // // [FEATURE] [Item Cost History] [Calculate End Year Costs]
    // 
    // 1. Verifying Item Cost History after Calculate End Year Costs for current year. Components Valuation Average Cost, Estimated WIP Consumption True.
    // 2. Verifying Item Cost History after Calculate End Year Costs for current year. Components Valuation Average Cost, Estimated WIP Consumption False.
    // 3. Verifying Item Cost History after Calculate End Year Costs for current year. Components Valuation Weighted Average Cost, Estimated WIP Consumption True.
    // 4. Verifying Item Cost History after Calculate End Year Costs for current year. Components Valuation Weighted Average Cost, Estimated WIP Consumption False.
    // 5. Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Average Cost, Estimated WIP Consumption True.
    // 6. Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Average Cost, Estimated WIP Consumption False.
    // 7. Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Weighted Average Cost, Estimated WIP Consumption True.
    // 8. Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Weighted Average Cost, Estimated WIP Consumption False.
    // 9. Verify End Year Inventory on Ledger Entry Details report.
    // 10. Verify Residual Quantity in Lifo Band When End Year Inventory is more than Start Year Inventory.
    // 11. Verify Residual Quantity in Lifo Band When End Year Inventory is less than Start Year Inventory.
    // 12. Verify Definitive data error after Calculate End Year Cost.
    // 13. Verify Final data error after Calculate End Year Cost.
    // 
    // Covers Test Cases for WI - 345878.
    // --------------------------------------------------------------------------------------
    // Test Function Name                                         TFS ID
    // --------------------------------------------------------------------------------------
    // CurrentYearCostEstimatedWIPConsumptionTrue                 15718,15720,156412,156417
    // CurrentYearCostEstimatedWIPConsumptionFalse                156418
    // CurrentYearWeightedAverageConsumptionTrue                  156419
    // CurrentYearWeightedAverageConsumptionFalse                 156420
    // PreviousYearCostEstimatedWIPConsumptionTrue                156413
    // PreviousYearCostEstimatedWIPConsumptionFalse               156414
    // PreviousYearWeightedAverageConsumptionTrue                 156415,156406,156410
    // PreviousYearWeightedAverageConsumptionFalse                156416,263400,155719,155721
    // 
    // Covers Test Cases for WI - 345141.
    // --------------------------------------------------------------------------------------
    // Test Function Name                                         TFS ID
    // --------------------------------------------------------------------------------------
    // PrintLedgerEntryDetails                                    156433
    // EndYearInventoryMoreThanStartYearInventory                 156438
    // EndYearInventoryLessThanStartYearInventory                 156445
    // PreviousYearDefinitiveDataError                            156402
    // FinalDataErrorCalculateEndYearCost                         156405

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DefinitiveErr: Label 'Previous Year %1 data must be defined as definitive first.';
        FinalDataErr: Label 'Data for Year %1 has already been defined as Final. You cannot calculate/recalculate data for Year %1.';

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CurrentYearCostEstimatedWIPConsumptionTrue()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for currenty year. Components Valuation Average Cost, Estimated WIP Consumption True.
        CalculateEndYearCostsDefinitiveforCurrentYear(ItemCostingSetup."Components Valuation"::"Average Cost", true);  // Using true for Estimated WIP Consumption.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CurrentYearCostEstimatedWIPConsumptionFalse()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for current year. Components Valuation Average Cost, Estimated WIP Consumption False.
        CalculateEndYearCostsDefinitiveforCurrentYear(ItemCostingSetup."Components Valuation"::"Average Cost", false);  // Using false for Estimated WIP Consumption.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CurrentYearWeightedAverageConsumptionTrue()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for current year. Components Valuation Weighted Average Cost, Estimated WIP Consumption True.
        CalculateEndYearCostsDefinitiveforCurrentYear(ItemCostingSetup."Components Valuation"::"Weighted Average Cost", true);  // Using true for Estimated WIP Consumption.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CurrentYearWeightedAverageConsumptionFalse()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for current year. Components Valuation Weighted Average Cost, Estimated WIP Consumption False.
        CalculateEndYearCostsDefinitiveforCurrentYear(ItemCostingSetup."Components Valuation"::"Weighted Average Cost", false);  // Using false for Estimated WIP Consumption.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviousYearCostEstimatedWIPConsumptionTrue()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Average Cost, Estimated WIP Consumption True.
        CalculateEndYearCostsDefinitiveforPreviousYear(ItemCostingSetup."Components Valuation"::"Average Cost", true, false);  // Using true for Estimated WIP Consumption. False for Definitive.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviousYearCostEstimatedWIPConsumptionFalse()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Average Cost, Estimated WIP Consumption False.
        CalculateEndYearCostsDefinitiveforPreviousYear(ItemCostingSetup."Components Valuation"::"Average Cost", false, false);  // Using false for Estimated WIP Consumption. False for Definitive.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviousYearWeightedAverageConsumptionTrue()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Weighted Average Cost, Estimated WIP Consumption True.
        CalculateEndYearCostsDefinitiveforPreviousYear(ItemCostingSetup."Components Valuation"::"Weighted Average Cost", true, false);  // Using true for Estimated WIP Consumption. False for Definitive.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviousYearWeightedAverageConsumptionFalse()
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verifying Item Cost History after Calculate End Year Costs for previous year. Components Valuation Weighted Average Cost, Estimated WIP Consumption False.
        CalculateEndYearCostsDefinitiveforPreviousYear(ItemCostingSetup."Components Valuation"::"Weighted Average Cost", false, true);   // Using False for Estimated WIP Consumption. True for Definitive.
    end;

    [Test]
    [HandlerFunctions('LedgerEntryDetailsRequestPageHandler,CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintLedgerEntryDetails()
    var
        Item: Record Item;
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        // Verify End Year Inventory on Ledger Entry Details report.

        // Setup.
        Initialize();
        Item.Get(CreateItem(Item."Inventory Valuation"::Average));
        EnqueueVariablesForHandler(CalcDate('<CY>', WorkDate()), false);  // Using False for Definitive.
        CalculateEndYearCosts(Item."No.", ItemCostingSetup."Components Valuation"::"Average Cost", true);
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue for LedgerEntryDetailsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Ledger Entry Details");  // Opens LedgerEntryDetailsRequestPageHandler.

        // Verify.
        Item.CalcFields(Inventory);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Summary__End_Year_Inventory_', Item.Inventory);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EndYearInventoryMoreThanStartYearInventory()
    begin
        // Verify Residual Quantity in Lifo Band When End Year Inventory is more than Start Year Inventory.
        // Setup.
        Initialize();
        EndYearInventoryAndStartYearInventory(LibraryRandom.RandDec(10, 2), LibraryRandom.RandDecInRange(100, 200, 2));  // Large Value for Current Year Quantity. Using random for Previous Year Quantity.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EndYearInventoryLessThanStartYearInventory()
    begin
        // Verify Residual Quantity in Lifo Band When End Year Inventory is less than Start Year Inventory.
        // Setup.
        Initialize();
        EndYearInventoryAndStartYearInventory(LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDec(10, 2));  // Using random for Current Year Quantity. Large Value for Previous Year Quantity.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PreviousYearDefinitiveDataError()
    begin
        // Verify Definitive data error after Calculate End Year Cost.
        DefinitiveDataError(false, CalcDate('<CY>', WorkDate()), DefinitiveErr);  // Using false for Definitive.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinalDataErrorCalculateEndYearCost()
    begin
        // Verify Final data error after Calculate End Year Cost.
        DefinitiveDataError(true, CalcDate('<-CY-1D>', WorkDate()), FinalDataErr);  // Using false for Definitive.
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FIFOAndLIFOIncludePrevYearCostsForPurchItemWithStockDecreased()
    var
        Item: Record Item;
    begin
        // [SCENARIO 255417] Balances from the previous year are considered in FIFO and LIFO costs of current year-end inventory, when you run Calculate End Year Costs report for a purchased item, and the stock is decreased.
        Initialize();

        // [GIVEN] Purchased item.
        CreateItemForReplenishmentSystem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Previous year:
        // [GIVEN] Purchase for 100 pcs and unit cost = 10 LCY.
        // [GIVEN] Purchase for 100 pcs and unit cost = 20 LCY.
        // [GIVEN] Sales for 100 pcs. The year-end inventory at the end of the year = 100 pcs.

        // [GIVEN] This year:
        // [GIVEN] Purchase for 100 pcs and unit cost = 40 LCY.
        // [GIVEN] Sales for 150 pcs. The year-end inventory = 50 pcs, which is less than in the previous year.
        CreateAndPostPurchasesAndSalesInPreviousAndCurrentYear(Item."No.", 50);

        // [GIVEN] "Calculate End Year Costs" report is run for the previous year with "Definitive" option in order to close the period.
        Commit();
        RunCalculateEndYearCostsReport(CalcDate('<-CY-1D>', WorkDate()), true);

        // [WHEN] Run "Calculate End Year Costs" report for the current year.
        RunCalculateEndYearCostsReport(CalcDate('<CY>', WorkDate()), false);

        // [THEN] "FIFO Cost" in Item Cost History is equal to 40 LCY (0 pcs remained from the last year, 50 pcs by 40 LCY remained this year).
        // [THEN] "LIFO Cost" in Item Cost History is equal to 10 LCY (50 pcs by 10 LCY remained from the last year, 0 pcs remained this year).
        VerifyFIFOAndLIFOCostsInItemCostHistory(
          Item."No.", CalcDate('<CY>', WorkDate()),
          (0 * 20.0 + 50 * 40.0) / 50,
          (50 * 10.0 + 0 * 40.0) / 50);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FIFOAndLIFOIncludePrevYearCostsForPurchItemWithStockIncreased()
    var
        Item: Record Item;
    begin
        // [SCENARIO 255417] Balances from the previous year are considered in FIFO and LIFO costs of current year-end inventory, when you run Calculate End Year Costs report for a purchased item, and the stock is increased.
        Initialize();

        // [GIVEN] Purchased item.
        CreateItemForReplenishmentSystem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Previous year:
        // [GIVEN] Purchase for 100 pcs and unit cost = 10 LCY.
        // [GIVEN] Purchase for 100 pcs and unit cost = 20 LCY.
        // [GIVEN] Sales for 100 pcs. The year-end inventory at the end of the year = 100 pcs.

        // [GIVEN] This year:
        // [GIVEN] Purchase for 100 pcs and unit cost = 40 LCY.
        // [GIVEN] Sales for 50 pcs. The year-end inventory = 150 pcs, which is greater than in the previous year.
        CreateAndPostPurchasesAndSalesInPreviousAndCurrentYear(Item."No.", 150);

        // [GIVEN] "Calculate End Year Costs" report is run for the previous year with "Definitive" option in order to close the period.
        Commit();
        RunCalculateEndYearCostsReport(CalcDate('<-CY-1D>', WorkDate()), true);

        // [WHEN] Run "Calculate End Year Costs" report for the current year.
        RunCalculateEndYearCostsReport(CalcDate('<CY>', WorkDate()), false);

        // [THEN] "FIFO Cost" in Item Cost History is equal to 33.33 LCY (50 pcs by 20 LCY remained from the last year, 100 pcs by 40 LCY remained this year).
        // [THEN] "LIFO Cost" in Item Cost History is equal to 20 LCY (100 pcs by 10 LCY remained from the last year, 50 pcs by 40 LCY remained this year).
        VerifyFIFOAndLIFOCostsInItemCostHistory(
          Item."No.", CalcDate('<CY>', WorkDate()),
          (50 * 20.0 + 100 * 40.0) / 150,
          (100 * 10.0 + 50 * 40.0) / 150);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FIFOAndLIFOIncludePrevYearCostsForProdItemWithStockDecreased()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // [SCENARIO 255417] Balances from the previous year are considered in FIFO and LIFO costs of current year-end inventory, when you run Calculate End Year Costs report for a production item, and the stock is decreased.
        Initialize();

        // [GIVEN] Production item.
        CreateItemForReplenishmentSystem(Item, Item."Replenishment System"::"Prod. Order");

        // [GIVEN] Previous year:
        // [GIVEN] Produced 100 pcs of the item, unit cost = 20 LCY. The cost is set using "Before Start Item Cost" functionality.
        // [GIVEN] "Calculate End Year Costs" report is run with "Definitive" option in order to close the period.
        AddBeforeStartCostToProdItem(Item."No.", CalcDate('<-1Y>', WorkDate()), 100, 20.0);
        Commit();
        RunCalculateEndYearCostsReport(CalcDate('<-CY-1D>', WorkDate()), true);
        BeforeStartItemCost.DeleteAll();

        // [GIVEN] This year:
        // [GIVEN] Produced 100 pcs, unit cost = 40 LCY. The cost is set using "Before Start Item Cost" functionality.
        // [GIVEN] Sales for 150 pcs. The year-end inventory = 50 pcs, which is less than in the previous year.
        AddBeforeStartCostToProdItem(Item."No.", WorkDate(), 100, 40.0);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", WorkDate(), 150, 0.0);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run "Calculate End Year Costs" report for the current year.
        Commit();
        RunCalculateEndYearCostsReport(CalcDate('<CY>', WorkDate()), false);

        // [THEN] "FIFO Cost" in Item Cost History is equal to 40 LCY (0 pcs remained from the last year, 50 pcs by 40 LCY remained this year).
        // [THEN] "LIFO Cost" in Item Cost History is equal to 20 LCY (50 pcs by 20 LCY remained from the last year, 0 pcs remained this year).
        VerifyFIFOAndLIFOCostsInItemCostHistory(
          Item."No.", CalcDate('<CY>', WorkDate()),
          (0 * 20.0 + 50 * 40.0) / 50,
          (50 * 20.0 + 0 * 40.0) / 50);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FIFOAndLIFOIncludePrevYearCostsForProdItemWithStockIncreased()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // [SCENARIO 255417] Balances from the previous year are considered in FIFO and LIFO costs of current year-end inventory, when you run Calculate End Year Costs report for a production item, and the stock is increased.
        Initialize();

        // [GIVEN] Production item.
        CreateItemForReplenishmentSystem(Item, Item."Replenishment System"::"Prod. Order");

        // [GIVEN] Previous year:
        // [GIVEN] Produced 100 pcs of the item, unit cost = 20 LCY. The cost is set using "Before Start Item Cost" functionality.
        // [GIVEN] "Calculate End Year Costs" report is run with "Definitive" option in order to close the period.
        AddBeforeStartCostToProdItem(Item."No.", CalcDate('<-1Y>', WorkDate()), 100, 20.0);
        Commit();
        RunCalculateEndYearCostsReport(CalcDate('<-CY-1D>', WorkDate()), true);
        BeforeStartItemCost.DeleteAll();

        // [GIVEN] This year:
        // [GIVEN] Produced 100 pcs, unit cost = 40 LCY. The cost is set using "Before Start Item Cost" functionality.
        // [GIVEN] Sales for 50 pcs. The year-end inventory = 150 pcs, which is greater than in the previous year.
        AddBeforeStartCostToProdItem(Item."No.", WorkDate(), 100, 40.0);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", WorkDate(), 50, 0.0);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run "Calculate End Year Costs" report for the current year.
        Commit();
        RunCalculateEndYearCostsReport(CalcDate('<CY>', WorkDate()), false);

        // [THEN] "FIFO Cost" in Item Cost History is equal to 33.33 LCY (50 pcs by 20 LCY remained from the last year, 100 pcs by 40 LCY remained this year).
        // [THEN] "LIFO Cost" in Item Cost History is equal to 26.67 LCY (100 pcs by 20 LCY remained from the last year, 50 pcs by 40 LCY remained this year).
        VerifyFIFOAndLIFOCostsInItemCostHistory(
          Item."No.", CalcDate('<CY>', WorkDate()),
          (50 * 20.0 + 100 * 40.0) / 150,
          (100 * 20.0 + 50 * 40.0) / 150);
    end;

    local procedure Initialize()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        LibraryVariableStorage.Clear();
        ItemCostHistory.DeleteAll();
    end;

    local procedure AddBeforeStartCostToProdItem(ItemNo: Code[20]; StartingDate: Date; Qty: Decimal; UnitCost: Decimal)
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
        ItemJournalLine: Record "Item Journal Line";
    begin
        BeforeStartItemCost.Init();
        BeforeStartItemCost.Validate("Item No.", ItemNo);
        BeforeStartItemCost.Validate("Starting Date", StartingDate);
        BeforeStartItemCost.Validate("Production Quantity", Qty);
        BeforeStartItemCost.Validate("Production Amount", Qty * UnitCost);
        BeforeStartItemCost.Insert(true);

        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, StartingDate, Qty, 0.0);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CalculateEndYearCostForDefinitive(ItemNo: Code[20]; PreviousYearDate: Date)
    begin
        CreateAndPostItemJournal(ItemNo, PreviousYearDate, LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        REPORT.Run(REPORT::"Calculate End Year Costs");  // Opens CalculateEndYearCostsRequestPageHandler.
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; PostingDate: Date; Qty: Decimal; UnitAmount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostItemJournal(ItemNo: Code[20]; PostingDate: Date; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, PostingDate, Quantity, LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchasesAndSalesInPreviousAndCurrentYear(ItemNo: Code[20]; EndInventory: Decimal)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Previous year.
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, CalcDate('<-1Y>', WorkDate()), 100, 10.0);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, CalcDate('<-1Y>', WorkDate()), 100, 20.0);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, ItemNo, CalcDate('<-1Y>', WorkDate()), 100, 0.0);

        // Current year.
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, WorkDate(), 100, 40.0);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, ItemNo, WorkDate(), Item.Inventory - EndInventory, 0.0);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CalculateEndYearCosts(ItemNo: Code[20]; ComponentsValuation: Option; EstimatedWIPConsumption: Boolean)
    begin
        // Setup.
        CreateAndUpdateItemCostingSetup(ComponentsValuation, EstimatedWIPConsumption);
        CreateAndPostItemJournal(ItemNo, CalcDate('<-CY-1D>', WorkDate()), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        CreateAndPostItemJournal(ItemNo, CalcDate('<CY>', WorkDate()), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        CreateAndPostPurchaseOrder(ItemNo);
        CreateAndPostReleaseProdOrder(ItemNo);

        // Exercise.
        REPORT.Run(REPORT::"Calculate End Year Costs");  // Opens CalculateEndYearCostsRequestPageHandler.
    end;

    local procedure CreateItem(InventoryValuation: Option): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Valuation", InventoryValuation);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemForReplenishmentSystem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateAndUpdateItemCostingSetup(ComponentsValuation: Option; EstimatedWIPConsumption: Boolean)
    var
        ItemCostingSetup: Record "Item Costing Setup";
    begin
        LibraryITLocalization.CreateItemCostingSetup(ItemCostingSetup);
        ItemCostingSetup.Validate("Components Valuation", ComponentsValuation);
        ItemCostingSetup.Validate("Estimated WIP Consumption", EstimatedWIPConsumption);
        ItemCostingSetup.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Using true for receive and invoice.
    end;

    local procedure CreateAndPostReleaseProdOrder(ItemNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // Using false for Forward and CreateInbRqst. True for CalcLine,CalcRoutings,CalcComponents
    end;

    local procedure CalculateEndYearCostsDefinitiveforCurrentYear(ComponentsValuation: Option; EstimatedWIPConsumption: Boolean)
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // Setup And Exercise.
        Initialize();
        ItemNo := CreateItem(Item."Inventory Valuation"::Average);
        EnqueueVariablesForHandler(CalcDate('<CY>', WorkDate()), false);  // Using False for Definitive.
        CalculateEndYearCosts(ItemNo, ComponentsValuation, EstimatedWIPConsumption);

        // Verify: Verifying Item Cost History after Calculate End Year Costs for current year.
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        VerifyItemCostHistory(ItemNo, GetItemLedgerEntryQuantity(ItemNo), Item.Inventory, false);
    end;

    local procedure CalculateEndYearCostsDefinitiveforPreviousYear(ComponentsValuation: Option; EstimatedWIPConsumption: Boolean; Definitive: Boolean)
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // Setup And Exercise.
        Initialize();
        ItemNo := CreateItem(Item."Inventory Valuation"::Average);
        EnqueueVariablesForHandler(CalcDate('<-CY-1D>', WorkDate()), Definitive);
        CalculateEndYearCosts(ItemNo, ComponentsValuation, EstimatedWIPConsumption);

        // Verify: Verifying Item Cost History after Calculate End Year Costs.
        VerifyItemCostHistory(ItemNo, 0, GetItemLedgerEntryQuantity(ItemNo), Definitive);  // Using 0 for Start Year Inventory.
    end;

    local procedure DefinitiveDataError(Definitive: Boolean; CurrentOrPreviousYear: Date; DataError: Text[1024])
    var
        Item: Record Item;
        ItemCostingSetup: Record "Item Costing Setup";
        ItemNo: Code[20];
    begin
        // Setup.
        Initialize();
        ItemNo := CreateItem(Item."Inventory Valuation"::"Discrete LIFO");
        CreateAndUpdateItemCostingSetup(ItemCostingSetup."Components Valuation"::"Average Cost", true);  // Using true for Estimated WIP Consumption.
        EnqueueVariablesForHandler(CalcDate('<-CY-1D>', WorkDate()), Definitive);
        CalculateEndYearCostForDefinitive(ItemNo, CalcDate('<-CY-1D>', WorkDate()));
        CreateAndPostItemJournal(ItemNo, CurrentOrPreviousYear, LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        EnqueueVariablesForHandler(CurrentOrPreviousYear, false);  // Using false for Definitive.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Calculate End Year Costs");  // Opens CalculateEndYearCostsRequestPageHandler.

        // Verify.
        Assert.ExpectedError(StrSubstNo(DataError, Date2DMY(CalcDate('<-CY-1D>', WorkDate()), 3)));
    end;

    local procedure EndYearInventoryAndStartYearInventory(PreviousYearQuantity: Decimal; CurrentYearQuantity: Decimal)
    var
        Item: Record Item;
        ItemCostingSetup: Record "Item Costing Setup";
        ItemCostHistory: Record "Item Cost History";
        LIFOBand: Record "Lifo Band";
        ItemNo: Code[20];
    begin
        ItemNo := CreateItem(Item."Inventory Valuation"::"Discrete LIFO");
        CreateAndUpdateItemCostingSetup(ItemCostingSetup."Components Valuation"::"Average Cost", true);  // Using true for Estimated WIP Consumption.
        CreateAndPostItemJournal(ItemNo, CalcDate('<-CY-1D>', WorkDate()), PreviousYearQuantity);
        CreateAndPostItemJournal(ItemNo, CalcDate('<CY>', WorkDate()), CurrentYearQuantity);
        EnqueueVariablesForHandler(CalcDate('<CY>', WorkDate()), false);  // Using false for Definitive.

        // Exercise.
        REPORT.Run(REPORT::"Calculate End Year Costs");  // Opens CalculateEndYearCostsRequestPageHandler.

        // Verify: Verifying Residual Quantity in LIFO Band.
        ItemCostHistory.SetRange("Item No.", ItemNo);
        ItemCostHistory.FindFirst();

        LIFOBand.SetRange("Item No.", ItemNo);
        LIFOBand.FindFirst();
        LIFOBand.TestField("Residual Quantity", ItemCostHistory."End Year Inventory" - ItemCostHistory."Start Year Inventory");
    end;

    local procedure EnqueueVariablesForHandler(ReferenceDate: Date; Definitive: Boolean)
    begin
        // Enqueue for CalculateEndYearCostsRequestPageHandler.
        LibraryVariableStorage.Enqueue(ReferenceDate);
        LibraryVariableStorage.Enqueue(Definitive);
    end;

    local procedure RunCalculateEndYearCostsReport(ReferenceDate: Date; Definitive: Boolean)
    begin
        EnqueueVariablesForHandler(ReferenceDate, Definitive);
        REPORT.Run(REPORT::"Calculate End Year Costs");
    end;

    local procedure GetItemLedgerEntryQuantity(ItemNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Posting Date", CalcDate('<-CY-1D>', WorkDate()));
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry.Quantity);
    end;

    local procedure VerifyItemCostHistory(ItemNo: Code[20]; StartYearInventory: Decimal; EndYearInventory: Decimal; Definitive: Boolean)
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        ItemCostHistory.SetRange("Item No.", ItemNo);
        ItemCostHistory.FindFirst();
        ItemCostHistory.TestField("Start Year Inventory", StartYearInventory);
        ItemCostHistory.TestField("End Year Inventory", EndYearInventory);
        ItemCostHistory.TestField(Definitive, Definitive);
    end;

    local procedure VerifyFIFOAndLIFOCostsInItemCostHistory(ItemNo: Code[20]; CompetenceDate: Date; FIFOCost: Decimal; LIFOCost: Decimal)
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        ItemCostHistory.Get(ItemNo, CompetenceDate);
        ItemCostHistory.TestField("FIFO Cost", FIFOCost);
        ItemCostHistory.TestField("LIFO Cost", LIFOCost);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateEndYearCostsRequestPageHandler(var CalculateEndYearCosts: TestRequestPage "Calculate End Year Costs")
    var
        Definitive: Variant;
        ReferenceDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReferenceDate);
        LibraryVariableStorage.Dequeue(Definitive);
        CalculateEndYearCosts.ReferenceDate.SetValue(ReferenceDate);
        CalculateEndYearCosts.Definitive.SetValue(Definitive);
        CalculateEndYearCosts.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LedgerEntryDetailsRequestPageHandler(var LedgerEntryDetails: TestRequestPage "Ledger Entry Details")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LedgerEntryDetails."Item Cost History".SetFilter("Item No.", ItemNo);
        LedgerEntryDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

