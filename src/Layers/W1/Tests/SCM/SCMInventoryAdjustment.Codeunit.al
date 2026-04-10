codeunit 137037 "SCM Inventory Adjustment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Consumption] [SCM]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryCosting: Codeunit "Library - Costing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ProductionOrderNo: Code[20];
        RandomConsumptionQty: Integer;
        ErrMsgAmounts: Label 'The Amounts must match.';
        RandomScrapQty: Integer;

    [Test]
    [HandlerFunctions('ProdJournalConsumpPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderPostProdJnlFIFO()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        PurchaseHeader: Record "Purchase Header";
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::FIFO;

        // Random Consumption Quantity used inside page handler - ProdJournalConsumpPageHandler.
        RandomConsumptionQty := LibraryRandom.RandInt(5);
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 1, false);
        SelectProdBOMLine(ProductionBOMLine, ProductionOrder."Source No.");

        // Verify: Verification of Quantity for Consumption in Item Ledger Entry.
        VerifyConsumptionQuantity(
          ProductionOrder."No.", ProductionOrder.Quantity * ProductionBOMLine."Quantity per", RandomConsumptionQty);
    end;

    [Test]
    [HandlerFunctions('ProdJournalConsumpPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderFIFO()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalCostAmount: Decimal;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::FIFO;

        // Random Consumption Quantity used inside page handler - ProdJournalConsumpPageHandler.
        RandomConsumptionQty := LibraryRandom.RandInt(5);
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 1, false);
        SelectProdBOMLine(ProductionBOMLine, ProductionOrder."Source No.");
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
        TotalCostAmount :=
          PurchaseLine."Unit Cost" * ((ProductionOrder.Quantity * ProductionBOMLine."Quantity per") + RandomConsumptionQty);

        // Exercise: Change Status of Production Order to Finished. Run Adjust Cost Item Entries report.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");

        // Verify: Verification of Consumption Quantity and Cost Amount(Actual) in Item Ledger Entry.
        VerifyConsumptionQuantity(
          ProductionOrder."No.", ProductionOrder.Quantity * ProductionBOMLine."Quantity per", RandomConsumptionQty);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -TotalCostAmount);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, TotalCostAmount);
    end;

    [Test]
    [HandlerFunctions('ProdJournalConsumpPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderFullInvoiceFIFO()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalCostAmount: Decimal;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::FIFO;

        // Random Consumption Quantity used inside page handler - ProdJournalConsumpPageHandler.
        RandomConsumptionQty := LibraryRandom.RandInt(5);
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 1, false);
        SelectProdBOMLine(ProductionBOMLine, ProductionOrder."Source No.");

        // Change Status of Production Order to Finished. Re-open Purchase Order And Update Direct Unit Cost. Random values not important.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        ReopenPurchaseOrder(PurchaseHeader, PurchaseLine);
        UpdatePurchaseLine(
          PurchaseLine, PurchaseLine.FieldNo("Direct Unit Cost"), PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(5));
        TotalCostAmount :=
          PurchaseLine."Direct Unit Cost" * ((ProductionOrder.Quantity * ProductionBOMLine."Quantity per") + RandomConsumptionQty);

        // Exercise: Post Purchase Order as Invoice. Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");

        // Verify: Verification of Consumption Quantity and Cost Amount(Actual) in Item Ledger Entry.
        VerifyConsumptionQuantity(
          ProductionOrder."No.", ProductionOrder.Quantity * ProductionBOMLine."Quantity per", RandomConsumptionQty);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -TotalCostAmount);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, TotalCostAmount);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPostPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderPostProdJnlStandard()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        ItemConsumptionQuantity: Integer;
        ItemConsumptionQuantity2: Integer;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::Standard;
        CostingMethod[2] := Item."Costing Method"::FIFO;
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 2, false);

        // Calculate Consumption Quantity for Item Ledger Entry.
        ItemConsumptionQuantity := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::Standard);
        ItemConsumptionQuantity2 := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::FIFO);

        // Verify: Verification of Quantity for Consumption in Item Ledger Entry.
        VerifyConsumptionQuantity(ProductionOrder."No.", ItemConsumptionQuantity, ItemConsumptionQuantity2);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPostPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderStandard()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionCostAmount: Decimal;
        OutputCostAmount: Decimal;
        ItemConsumptionQuantity: Integer;
        ItemConsumptionQuantity2: Integer;
        StandardCost: Decimal;
        ChildItemNo: Code[20];
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::Standard;
        CostingMethod[2] := Item."Costing Method"::FIFO;
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 2, false);

        // Calculate Expected Consumption Cost Amount and Component Consumption Quantity.
        ItemConsumptionQuantity := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::Standard);
        StandardCost := TempItem."Standard Cost";
        ItemConsumptionQuantity2 := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::FIFO);
        ChildItemNo := TempItem."No.";
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", ChildItemNo);
        PurchaseLine.FindFirst();
        ConsumptionCostAmount := (ItemConsumptionQuantity * StandardCost) + (ItemConsumptionQuantity2 * PurchaseLine."Direct Unit Cost");

        // Calculate Expected Output Cost Amount.
        OutputCostAmount := ProductionOrder.Quantity * SelectItemCost(ProductionOrder."Source No.", Item.FieldNo("Standard Cost"));

        // Exercise: Change Status of Production Order to Finished. Run Adjust Cost Item Entries report.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");

        // Verify: Verification of Consumption Quantity and Cost Amount(Actual) in Item Ledger Entry.
        VerifyConsumptionQuantity(ProductionOrder."No.", ItemConsumptionQuantity, ItemConsumptionQuantity2);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -ConsumptionCostAmount);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, OutputCostAmount);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPostPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderInvoiceStandard()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ChildItemNo: Code[20];
        ConsumptionCostAmount: Decimal;
        OutputCostAmount: Decimal;
        ItemConsumptionQuantity: Integer;
        ItemConsumptionQuantity2: Integer;
        StandardCost: Decimal;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::Standard;
        CostingMethod[2] := Item."Costing Method"::FIFO;
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 2, false);

        // Change Status of Production Order to Finished. Re-open Purchase Order And Update Direct Unit Cost and Qty to Invoice.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        ReopenPurchaseOrder(PurchaseHeader, PurchaseLine);
        UpdateDirectUnitCostInvoiceQty(PurchaseLine);

        // Calculate Component Item Consumption Quantity.
        ItemConsumptionQuantity := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::Standard);
        StandardCost := TempItem."Standard Cost";
        ItemConsumptionQuantity2 := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::FIFO);
        ChildItemNo := TempItem."No.";

        // Calculate Expected Output Cost Amount.
        OutputCostAmount := ProductionOrder.Quantity * SelectItemCost(ProductionOrder."Source No.", Item.FieldNo("Standard Cost"));

        // Exercise: Post Purchase Order as Invoice. Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");

        // Verify: Verification of Consumption Quantity and Cost Amount(Actual) in Item Ledger Entry.
        Item.Get(ChildItemNo);
        ConsumptionCostAmount := (ItemConsumptionQuantity * StandardCost) + (ItemConsumptionQuantity2 * Item."Unit Cost");
        VerifyConsumptionQuantity(ProductionOrder."No.", ItemConsumptionQuantity, ItemConsumptionQuantity2);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -ConsumptionCostAmount);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, OutputCostAmount);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPostPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderPostProdJnlLIFO()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        ItemConsumptionQuantity: Integer;
        ItemConsumptionQuantity2: Integer;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::LIFO;
        CostingMethod[2] := Item."Costing Method"::LIFO;
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 2, true);

        // Calculate Consumption Quantity for Item Ledger Entry.
        TempItem.FindSet();
        ItemConsumptionQuantity := SelectItemConsumptionQuantity(ProductionOrder.Quantity, TempItem."No.");
        TempItem.Next();
        ItemConsumptionQuantity2 := SelectItemConsumptionQuantity(ProductionOrder.Quantity, TempItem."No.");

        // Verify: Verification of Quantity for Consumption in Item Ledger Entry.
        VerifyConsumptionQuantity(ProductionOrder."No.", ItemConsumptionQuantity, ItemConsumptionQuantity2);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPostPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderLIFO()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionCostAmount: Decimal;
        OutputCostAmount: Decimal;
        ItemConsumptionQuantity: Integer;
        ItemConsumptionQuantity2: Integer;
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::LIFO;
        CostingMethod[2] := Item."Costing Method"::LIFO;
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 2, true);

        // Calculate Expected Consumption Cost Amount and Component Consumption Quantity.
        TempItem.FindSet();
        ChildItemNo := TempItem."No.";
        ItemConsumptionQuantity := SelectItemConsumptionQuantity(ProductionOrder.Quantity, ChildItemNo);
        TempItem.Next();
        ChildItemNo2 := TempItem."No.";
        ItemConsumptionQuantity2 := SelectItemConsumptionQuantity(ProductionOrder.Quantity, ChildItemNo2);

        // Exercise: Change Status of Production Order to Finished. Run Adjust Cost Item Entries report.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");

        // Verify: Verification of Consumption Quantity and Cost Amount(Actual) in Item Ledger Entry.
        Item.Get(ChildItemNo);
        Item2.Get(ChildItemNo2);
        ConsumptionCostAmount := (ItemConsumptionQuantity * Item."Unit Cost") + (ItemConsumptionQuantity2 * Item2."Unit Cost");
        VerifyConsumptionQuantity(ProductionOrder."No.", ItemConsumptionQuantity, ItemConsumptionQuantity2);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -ConsumptionCostAmount);

        // Calculate Expected Output Cost Amount.
        OutputCostAmount := ProductionOrder.Quantity * SelectItemCost(ProductionOrder."Source No.", Item.FieldNo("Unit Cost"));

        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, OutputCostAmount);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPostPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderFullInvoiceLIFO()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionCostAmount: Decimal;
        OutputCostAmount: Decimal;
        ItemConsumptionQuantity: Integer;
        ItemConsumptionQuantity2: Integer;
        CostingMethod: array[2] of Enum "Costing Method";
        LastDirectCost: Decimal;
        LastDirectCost2: Decimal;
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::LIFO;
        CostingMethod[2] := Item."Costing Method"::LIFO;
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 2, true);

        // Change Status of Production Order to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        ReopenPurchaseOrder(PurchaseHeader, PurchaseLine);
        UpdateDirectUnitCostInvoiceQty(PurchaseLine);
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");
        ReopenPurchaseOrder(PurchaseHeader, PurchaseLine);
        UpdatePurchaseLine(PurchaseLine, PurchaseLine.FieldNo("Qty. to Invoice"), 1);
        UpdateVendorInvoiceNo(PurchaseHeader);

        // Exercise: Invoice Purchase Order Completely and Execute Adjust Cost Item Entries.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");

        // Verify: Verification of Consumption Quantity and Cost Amount(Actual) in Item Ledger Entry.
        // Calculate Expected Consumption Cost Amount and Component Consumption Quantity.
        TempItem.FindSet();
        LastDirectCost := SelectItemCost(TempItem."No.", Item.FieldNo("Last Direct Cost"));
        ItemConsumptionQuantity := SelectItemConsumptionQuantity(ProductionOrder.Quantity, TempItem."No.");
        TempItem.Next();
        LastDirectCost2 := SelectItemCost(TempItem."No.", Item.FieldNo("Last Direct Cost"));
        ItemConsumptionQuantity2 := SelectItemConsumptionQuantity(ProductionOrder.Quantity, TempItem."No.");
        ConsumptionCostAmount := (ItemConsumptionQuantity * LastDirectCost) + (ItemConsumptionQuantity2 * LastDirectCost2);

        VerifyConsumptionQuantity(ProductionOrder."No.", ItemConsumptionQuantity, ItemConsumptionQuantity2);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -ConsumptionCostAmount);

        // Calculate Expected Output Cost Amount.
        OutputCostAmount := ProductionOrder.Quantity * SelectItemCost(ProductionOrder."Source No.", Item.FieldNo("Unit Cost"));
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, OutputCostAmount);
    end;

    [Test]
    [HandlerFunctions('ProdJournalScrapPageHandler')]
    [Scope('OnPrem')]
    procedure PostProdJnlWithScrapStandard()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemConsumptionQuantity: Integer;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::Standard;

        // Random Scrap Quantity used inside page handler - ProdJournalScrapPageHandler.
        RandomScrapQty := LibraryRandom.RandInt(5);
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 1, false);

        // Calculate Consumption Quantity for Item Ledger Entry.
        ItemConsumptionQuantity := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::Standard);

        // Verify: Verification of Scrap Quantity in Capacity Ledger Entry and Quantity for Consumption in Item Ledger Entry.
        VerifyCapacityLedgerEntry(ProductionOrder."No.", RandomScrapQty);
        SelectItemLedgerEntries(ItemLedgerEntry, ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.TestField(Quantity, -ItemConsumptionQuantity);
    end;

    [Test]
    [HandlerFunctions('ProdJournalScrapPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdWithScrapStandard()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionCostAmount: Decimal;
        OutputCostAmount: Decimal;
        ItemConsumptionQuantity: Integer;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::Standard;

        // Random Scrap Quantity used inside page handler - ProdJournalScrapPageHandler.
        RandomScrapQty := LibraryRandom.RandInt(5);
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 1, false);

        // Calculate Expected Consumption Cost Amount and Component Consumption Quantity.
        ItemConsumptionQuantity := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::Standard);
        ConsumptionCostAmount := ItemConsumptionQuantity * TempItem."Standard Cost";

        // Calculate Expected Output Cost Amount.
        OutputCostAmount := ProductionOrder.Quantity * SelectItemCost(ProductionOrder."Source No.", Item.FieldNo("Standard Cost"));

        // Exercise: Change Status of Production Order to Finished. Run Adjust Cost Item Entries report.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");

        // Verify: Verification of Scrap Quantity in Capacity Ledger Entry and Quantity for Consumption in Item Ledger Entry.
        VerifyCapacityLedgerEntry(ProductionOrder."No.", RandomScrapQty);
        SelectItemLedgerEntries(ItemLedgerEntry, ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.TestField(Quantity, -ItemConsumptionQuantity);

        // Verification of Cost Amount(Actual) in Item Ledger Entry.
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -ConsumptionCostAmount);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, OutputCostAmount);
    end;

    [Test]
    [HandlerFunctions('ProdJournalScrapPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdWithScrapInvoiceStd()
    var
        TempItem: Record Item temporary;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionCostAmount: Decimal;
        OutputCostAmount: Decimal;
        ItemConsumptionQuantity: Integer;
        CostingMethod: array[2] of Enum "Costing Method";
    begin
        // Setup.
        Initialize();
        CostingMethod[1] := Item."Costing Method"::Standard;

        // Random Scrap Quantity used inside page handler - ProdJournalScrapPageHandler.
        RandomScrapQty := LibraryRandom.RandInt(5);
        ReleasedProductionOrderSetup(TempItem, PurchaseHeader, ProductionOrder, CostingMethod, 1, false);

        // Change Status of Production Order to Finished. Re-open Purchase Order And Update Direct Unit Cost and Qty to Invoice.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        ReopenPurchaseOrder(PurchaseHeader, PurchaseLine);
        UpdateDirectUnitCostInvoiceQty(PurchaseLine);

        // Calculate Expected Component Item Consumption Quantity.
        ItemConsumptionQuantity := ProductionOrder.Quantity * SelectBOMLineQuantityPer(TempItem, TempItem."Costing Method"::Standard);

        // Calculate Expected Output Cost Amount.
        OutputCostAmount := ProductionOrder.Quantity * SelectItemCost(ProductionOrder."Source No.", Item.FieldNo("Standard Cost"));

        // Exercise: Post Purchase Order as Invoice. Run Adjust Cost Item Entries report.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        AdjustCostItemEntries(TempItem, ProductionOrder."Source No.");
        ConsumptionCostAmount := ItemConsumptionQuantity * TempItem."Standard Cost";

        // Verify: Verification of Scrap Quantity in Capacity Ledger Entry and Quantity for Consumption in Item Ledger Entry.
        VerifyCapacityLedgerEntry(ProductionOrder."No.", RandomScrapQty);
        SelectItemLedgerEntries(ItemLedgerEntry, ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.TestField(Quantity, -ItemConsumptionQuantity);

        // Verification of Cost Amount(Actual) in Item Ledger Entry.
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Consumption, -ConsumptionCostAmount);
        VerifyProductionILECostAmount(ProductionOrder."No.", ItemLedgerEntry."Entry Type"::Output, OutputCostAmount);
    end;

    local procedure ReleasedProductionOrderSetup(var TempItem: Record Item temporary; var PurchaseHeader: Record "Purchase Header"; var ProductionOrder: Record "Production Order"; CostingMethod: array[2] of Enum "Costing Method"; NoOfComponents: Integer; PartialInvoice: Boolean)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Update Sales Setup, Create Child Items with respective costing method. Create Purchase Order and Receive only.
        // Create Production BOM and Create Parent Item and attach Production BOM.
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        CreateItemsAndCopyToTemp(TempItem, CostingMethod, NoOfComponents);
        CreatePurchaseOrder(PurchaseHeader, TempItem);
        if PartialInvoice then begin
            SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
            UpdatePurchaseLine(PurchaseLine, PurchaseLine.FieldNo("Qty. to Invoice"), 1);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, PartialInvoice);
        CreateProductionBOM(ProductionBOMHeader, TempItem);
        CreateItem(Item, CostingMethod[1], ProductionBOMHeader."No.");

        // Create and Refresh Released Production Order.
        CreateAndRefreshRelProdOrder(ProductionOrder, Item."No.");
        ProductionOrderNo := ProductionOrder."No.";

        // Open and perform required actions in Production Journal Handler. Post Production Journal.
        // Exercise for Test method : RelProdOrderPostProdJnl.
        // ----------------------------------------------------------------
        // Function                         Page Handler Invoked
        // ----------------------------------------------------------------
        // ProdOrderPostProdJnlFIFO         ProdJournalConsumpPageHandler
        // FinishProdOrderFIFO              ProdJournalConsumpPageHandler
        // FinishProdOrderInvoiceFIFO       ProdJournalConsumpPageHandler
        // ProdOrderPostProdJnlStandard     ProdJournalPostPageHandler
        // FinishProdOrderStandard          ProdJournalPostPageHandler
        // FinishProdOrderInvoiceStandard   ProdJournalPostPageHandler
        // ProdOrderPostProdJnlLIFO         ProdJournalPostPageHandler
        // FinishProdOrderLIFO              ProdJournalPostPageHandler
        // FinishProdOrderFullInvoiceLIFO   ProdJournalPostPageHandler
        // PostProdJnlWithScrapStandard     ProdJournalScrapPageHandler
        // FinishProdWithScrapStandard      ProdJournalScrapPageHandler
        // FinishProdWithScrapInvoiceStd    ProdJournalScrapPageHandler
        // ----------------------------------------------------------------

        OpenProductionJournal(ProductionOrder);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Adjustment");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Adjustment");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Adjustment");
    end;

    local procedure CreateItemsAndCopyToTemp(var TempItem: Record Item temporary; CostingMethod: array[2] of Enum "Costing Method"; NoOfItems: Integer)
    var
        Item: Record Item;
        Counter: Integer;
    begin
        for Counter := 1 to NoOfItems do begin
            Clear(Item);
            CreateItem(Item, CostingMethod[Counter], '');
            TempItem := Item;
            TempItem.Insert();
        end;
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var TempItem: Record Item temporary)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        TempItem.FindSet();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        UpdateVendorInvoiceNo(PurchaseHeader);
        repeat
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, TempItem."No.", LibraryRandom.RandInt(10) + 100);  // Value important.
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Random value not important.
            PurchaseLine.Modify(true);
        until TempItem.Next() = 0;
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var TempItem: Record Item temporary)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Random values not important.
        TempItem.FindSet();
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, TempItem."Base Unit of Measure");
        repeat
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, TempItem."No.", LibraryRandom.RandInt(5));
        until TempItem.Next() = 0;
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ProductionBOMNo: Code[20])
    begin
        // Random values not important.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(5), Item."Reordering Policy", Item."Flushing Method"::"Pick + Manual", '',
          ProductionBOMNo);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshRelProdOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, SourceNo,
          LibraryRandom.RandInt(5));  // Value not important.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure OpenProductionJournal(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // Open Production Journal based on selected Production Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
    end;

    local procedure SelectProdBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindSet();
    end;

    local procedure SelectBOMLineQuantityPer(var TempItem: Record Item temporary; ItemCostingMethod: Enum "Costing Method"): Integer
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        TempItem.Reset();
        TempItem.SetRange("Costing Method", ItemCostingMethod);
        TempItem.FindFirst();
        ProductionBOMLine.SetRange("No.", TempItem."No.");
        ProductionBOMLine.FindFirst();
        exit(ProductionBOMLine."Quantity per");
    end;

    local procedure ReopenPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseLine."Document Type"::Order);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Purchase Line base on Field and its corresponding value.
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(PurchaseLine);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateDirectUnitCostInvoiceQty(var PurchaseLine: Record "Purchase Line")
    begin
        // Random values not important.
        repeat
            UpdatePurchaseLine(
              PurchaseLine, PurchaseLine.FieldNo("Direct Unit Cost"), PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(5));
            if PurchaseLine."Qty. to Invoice" = 0 then
                exit;
            UpdatePurchaseLine(PurchaseLine, PurchaseLine.FieldNo("Qty. to Invoice"), PurchaseLine."Qty. to Invoice" - 1);
        until PurchaseLine.Next() = 0;
    end;

    local procedure SelectItemConsumptionQuantity(ProductionOrderQuantity: Integer; No: Code[20]): Decimal
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("No.", No);
        ProductionBOMLine.FindFirst();
        exit(ProductionOrderQuantity * ProductionBOMLine."Quantity per");
    end;

    local procedure SelectItemLedgerEntries(var ItemLedgerEntry: Record "Item Ledger Entry"; DocumentNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindSet();
    end;

    local procedure SelectItemCost(ItemNo: Code[20]; FieldNo: Integer) CurrentValue: Decimal
    var
        Item: Record Item;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Item.Get(ItemNo);
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(FieldNo);
        CurrentValue := FieldRef.Value();
    end;

    local procedure AdjustCostItemEntries(var TempItem: Record Item temporary; ItemNo: Code[20])
    var
        Counter: Integer;
        ItemString: Text[250];
    begin
        TempItem.FindSet();
        for Counter := 1 to TempItem.Count do begin
            ItemString := ItemString + TempItem."No." + '|';
            TempItem.Next();
        end;
        ItemString := ItemString + ItemNo;
        LibraryCosting.AdjustCostItemEntries(ItemString, '');
    end;

    local procedure VerifyConsumptionQuantity(DocumentNo: Code[20]; Quantity: Integer; Quantity2: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Consumption quantities from Item Ledger Entry.
        SelectItemLedgerEntries(ItemLedgerEntry, DocumentNo, ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.TestField(Quantity, -Quantity);
        ItemLedgerEntry.Next();
        ItemLedgerEntry.TestField(Quantity, -Quantity2);
    end;

    local procedure VerifyProductionILECostAmount(DocumentNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; ExpectedTotalCostAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Assert: Codeunit Assert;
        ActualCostAmountConsumption: Decimal;
    begin
        // Verify Cost Amount(Actual) after Adjustment from Item Ledger Entry.
        GeneralLedgerSetup.Get();
        SelectItemLedgerEntries(ItemLedgerEntry, DocumentNo, EntryType);
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            ActualCostAmountConsumption += ItemLedgerEntry."Cost Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;
        Assert.AreNearlyEqual(
          ExpectedTotalCostAmount, ActualCostAmountConsumption, GeneralLedgerSetup."Inv. Rounding Precision (LCY)", ErrMsgAmounts);
    end;

    local procedure VerifyCapacityLedgerEntry(DocumentNo: Code[20]; ScrapQuantity: Integer)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Document No.", DocumentNo);
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntry.TestField("Scrap Quantity", ScrapQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdJournalConsumpPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate(Quantity, ItemJournalLine.Quantity + RandomConsumptionQty);  // Random values not important.
        ItemJournalLine.Modify(true);
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();

        // Post Production Journal lines with modified Consumption Quantity.
        repeat
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        until ItemJournalLine.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdJournalScrapPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Scrap Quantity", RandomScrapQty);  // Random values not important.
        ItemJournalLine.Modify(true);
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();

        // Post Production Journal lines with modified Consumption Quantity.
        repeat
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        until ItemJournalLine.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdJournalPostPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();

        // Post Production Journal lines.
        repeat
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        until ItemJournalLine.Next() = 0;
    end;
}

