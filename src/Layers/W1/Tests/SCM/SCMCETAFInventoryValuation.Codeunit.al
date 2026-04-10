codeunit 137608 "SCM CETAF Inventory Valuation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [SCM]
        isInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        OpenOutboudEntryErr: Label 'Open Outbound Entry %1 found.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CETAF Inventory Valuation");
        // Lazy Setup.

        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CETAF Inventory Valuation");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CETAF Inventory Valuation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuationDateAVGCost()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader1: Record "Purchase Header";
        ParentItem: Record Item;
        CompItem: Record Item;
        Day1: Date;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();
        Qty := LibraryRandom.RandInt(20);
        QtyPer := LibraryRandom.RandInt(10);

        // Setup.
        SetupProduction(
          ParentItem, CompItem, ProdOrderLine, '', ParentItem."Costing Method"::FIFO, CompItem."Costing Method"::Average, Day1, Qty, QtyPer);

        // Purchase component items.
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, CompItem, '', '', (Qty * QtyPer) / 2, Day1, CompItem."Standard Cost", true, false);
        LibraryPurchase.POSTPurchaseOrder(
          PurchaseHeader1, CompItem, '', '', (Qty * QtyPer) / 2 + 1, Day1 + 30, CompItem."Standard Cost", true, false);

        // Post consumption.
        LibraryManufacturing.CreateConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, CompItem, Day1 + 5, '', '', Qty * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, Day1 + 6, Qty, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post sale.
        LibraryInventory.PostItemJournalLine(
            "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Sale,
            ParentItem, '', '', '', Qty, Day1 + 6, LibraryRandom.RandDec(100, 2));

        // Invoice purchases.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader1.Get(PurchaseHeader1."Document Type", PurchaseHeader1."No.");
        PurchaseHeader1.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);

        // Finish prod. order.
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, Day1, false);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + CompItem."No.", '');

        // Verify adjustment.
        LibraryCosting.CheckAdjustment(ParentItem);
        LibraryCosting.CheckAdjustment(CompItem);
        LibraryManufacturing.CheckProductionOrderCost(ProductionOrder, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostPerUnitWithOutput()
    var
        Location: Record Location;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader1: Record "Purchase Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        SubassemblyItem: Record Item;
        CompItem: Record Item;
        Day1: Date;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();
        Qty := LibraryRandom.RandInt(20);
        QtyPer := LibraryRandom.RandInt(10);

        // Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SetupProduction(
          ParentItem, SubassemblyItem, ProdOrderLine, Location.Code, ParentItem."Costing Method"::Standard,
          CompItem."Costing Method"::Standard, Day1, Qty, QtyPer);
        SubassemblyItem.Get(SubassemblyItem."No.");
        SubassemblyItem.Validate("Replenishment System", SubassemblyItem."Replenishment System"::"Prod. Order");
        SubassemblyItem.Modify();

        LibraryInventory.CreateItem(CompItem, CompItem."Costing Method"::Standard, LibraryRandom.RandDec(50, 2), 0, 0, '');

        // Setup subassembly BOM.
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, SubassemblyItem, CompItem, QtyPer, '');

        // Purchase component items.
        LibraryPurchase.POSTPurchaseOrder(
          PurchaseHeader, SubassemblyItem, Location.Code, '', Qty * QtyPer, Day1, CompItem."Standard Cost", true, false);
        LibraryPurchase.POSTPurchaseOrder(
          PurchaseHeader1, CompItem, Location.Code, '', Qty * QtyPer * QtyPer, Day1, CompItem."Standard Cost", true, false);

        // Post consumption.
        LibraryManufacturing.CreateConsumptionJournalLine(
          ItemJournalBatch, ProdOrderLine, SubassemblyItem, Day1 + 5, Location.Code, '', Qty * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        LibraryManufacturing.CreateConsumptionJournalLine(
          ItemJournalBatch, ProdOrderLine, CompItem, Day1 + 5, Location.Code, '', Qty * QtyPer * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Post output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, Day1 + 5, Qty, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Change standard costs for components.
        UpdateItemStandardCost(CompItem);
        UpdateItemStandardCost(SubassemblyItem);

        // Post negative consumption.
        LibraryManufacturing.CreateConsumptionJournalLine(
          ItemJournalBatch, ProdOrderLine, CompItem, Day1 + 7, Location.Code, '', -Qty * QtyPer * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryManufacturing.CreateConsumptionJournalLine(
          ItemJournalBatch, ProdOrderLine, SubassemblyItem, Day1 + 7, Location.Code, '', -Qty * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post negative output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, Day1 + 7, -Qty, 0);
        ApplyToItemLedgerEntry(ItemJournalLine, TempItemLedgerEntry, ItemJournalBatch, ParentItem."No.");
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Invoice purchases.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader1.Get(PurchaseHeader1."Document Type", PurchaseHeader1."No.");
        PurchaseHeader1.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + SubassemblyItem."No." + '|' + CompItem."No.", '');

        // Verify adjustment.
        LibraryCosting.CheckAdjustment(ParentItem);
        LibraryCosting.CheckAdjustment(SubassemblyItem);
        LibraryCosting.CheckAdjustment(CompItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferAVG()
    var
        Item: Record Item;
    begin
        ValuationDateTransferEntries(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferFIFO()
    var
        Item: Record Item;
    begin
        ValuationDateTransferEntries(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferLIFO()
    var
        Item: Record Item;
    begin
        ValuationDateTransferEntries(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferSTD()
    var
        Item: Record Item;
    begin
        ValuationDateTransferEntries(Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferOrderAVG()
    var
        Item: Record Item;
    begin
        ValuationDateTransferOrders(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferOrderFIFO()
    var
        Item: Record Item;
    begin
        ValuationDateTransferOrders(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferOrderLIFO()
    var
        Item: Record Item;
    begin
        ValuationDateTransferOrders(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValDateTransferOrderSTD()
    var
        Item: Record Item;
    begin
        ValuationDateTransferOrders(Item."Costing Method"::Standard);
    end;

    [Normal]
    local procedure ValuationDateTransferEntries(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();

        // Setup the item.
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Post purchase.
        Qty := LibraryRandom.RandInt(20);
        LibraryPurchase.POSTPurchaseOrder(
          PurchaseHeader, Item, FromLocation.Code, '', Qty, Day1, LibraryRandom.RandDec(100, 2), true, false);

        // Reclassify into second location.
        LibraryInventory.PostReclassificationJournalLine(Item, Day1 + 8, FromLocation.Code, ToLocation.Code, '', '', '', Qty);

        // Invoice the purchase order at a different cost.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Posting Date", Day1 + 15);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(100, 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Normal]
    local procedure ValuationDateTransferOrders(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();

        // Setup the item.
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(InTransitLocation);
        InTransitLocation."Use As In-Transit" := true;
        InTransitLocation.Modify();
        LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);

        // Post purchase.
        Qty := LibraryRandom.RandInt(20);
        LibraryPurchase.POSTPurchaseOrder(
          PurchaseHeader, Item, FromLocation.Code, '', Qty, Day1, LibraryRandom.RandDec(100, 2), true, false);

        // Transfer into second location.
        LibraryInventory.CreateAndPostTransferOrder(
          TransferHeader, Item, FromLocation, ToLocation, InTransitLocation, '', Qty, Day1 + 8, Day1 + 8, true, true);

        // Invoice the purchase order at a different cost.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Posting Date", Day1 + 15);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(100, 2);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValDateLinkedAVG()
    var
        Item: Record Item;
    begin
        ValuationDateLinkedEntries(Item."Costing Method"::Average);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValDateLinkedFIFO()
    var
        Item: Record Item;
    begin
        ValuationDateLinkedEntries(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValDateLinkedLIFO()
    var
        Item: Record Item;
    begin
        ValuationDateLinkedEntries(Item."Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValDateLinkedSTD()
    var
        Item: Record Item;
    begin
        ValuationDateLinkedEntries(Item."Costing Method"::Standard);
    end;

    [Normal]
    local procedure ValuationDateLinkedEntries(CostingMethod: Enum "Costing Method")
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();

        LibraryInventory.UpdateAverageCostSettings(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        LibraryInventory.SetAverageCostSetupInAccPeriods(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        Day1 := WorkDate();
        if Confirm('') then; // ES workaround.

        // Setup the item.
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // Post sales and credit memo.
        Qty := LibraryRandom.RandInt(20);
        LibrarySales.PostSalesOrder(SalesHeader, Item, Location.Code, '', Qty, Day1, LibraryRandom.RandDec(100, 2), true, true);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        LibrarySales.CreateSalesCreditMemo(SalesHeader, SalesLine, Item, Location.Code, '', Qty, Day1, 0, 0);
        SalesLine.Validate("Appl.-from Item Entry", TempItemLedgerEntry."Entry No.");
        SalesLine.Modify();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Post positive adj.
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Qty, Day1 + 2, LibraryRandom.RandDec(100, 2));

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValDateEndlessFIFO()
    var
        Item: Record Item;
    begin
        ValuationDateEndlessLoop(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValDateEndlessLIFO()
    var
        Item: Record Item;
    begin
        ValuationDateEndlessLoop(Item."Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValDateEndlessSTD()
    var
        Item: Record Item;
    begin
        ValuationDateEndlessLoop(Item."Costing Method"::Standard);
    end;

    [Normal]
    local procedure ValuationDateEndlessLoop(CostingMethod: Enum "Costing Method")
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();
        if Confirm('') then; // ES workaround.

        // Setup the item.
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');

        // Post purchase, sales, sales cr. memo.
        Qty := 3 + LibraryRandom.RandInt(20);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, Item, '', '', Qty - 3, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibrarySales.CreateSalesInvoice(SalesHeader, SalesLine, Item, '', '', Qty - 3, Day1 + 5, LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        LibrarySales.CreateSalesCreditMemo(SalesHeader, SalesLine, Item, '', '', Qty - 3, Day1 + 5, 0, 0);
        SalesLine.Validate("Appl.-from Item Entry", TempItemLedgerEntry."Entry No.");
        SalesLine.Modify();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        TempItemLedgerEntry.FindLast();

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Post revaluation.
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
        LibraryInventory.CreateItemJournalLineWithApplication(ItemJournalLine, ItemJournalBatch, Item, '', '', Day1 + 2,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Qty - 3, 0, TempItemLedgerEntry."Entry No.");
        ItemJournalLine.Validate("Inventory Value (Revalued)",
          ItemJournalLine."Inventory Value (Calculated)" + LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValInvtUnitCostFIFO()
    var
        Item: Record Item;
    begin
        ValuateInventoryAndUnitCost(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValInvtUnitCostLIFO()
    var
        Item: Record Item;
    begin
        ValuateInventoryAndUnitCost(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValInvtUnitCostSTD()
    var
        Item: Record Item;
    begin
        ValuateInventoryAndUnitCost(Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValInvtUnitCostAVG()
    var
        Item: Record Item;
    begin
        ValuateInventoryAndUnitCost(Item."Costing Method"::Average);
    end;

    [Normal]
    local procedure ValuateInventoryAndUnitCost(CostingMethod: Enum "Costing Method")
    var
        TransferHeader: Record "Transfer Header";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        InventorySetup: Record "Inventory Setup";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();

        LibraryInventory.UpdateAverageCostSettings(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        LibraryInventory.SetAverageCostSetupInAccPeriods(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        Day1 := WorkDate();

        // Setup the item.
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(InTransitLocation);
        InTransitLocation."Use As In-Transit" := true;
        InTransitLocation.Modify();

        // Post purchase.
        Qty := LibraryRandom.RandInt(20);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, FromLocation.Code, '', Qty, Day1,
          LibraryRandom.RandDec(100, 2), true, true);

        // Transfer into second location.
        LibraryInventory.CreateAndPostTransferOrder(TransferHeader, Item, FromLocation, ToLocation, InTransitLocation, '', Qty, Day1 + 2,
          Day1 + 2, true, true);

        // Post positive adjmt.
        LibraryInventory.PostPositiveAdjustment(Item, FromLocation.Code, '', '', Qty + 1, Day1 + 5, LibraryRandom.RandDec(100, 2));

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);

        // Post sales with charge.
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, FromLocation.Code, '',
          Qty, Day1 + 7, LibraryRandom.RandDec(100, 2));
        LibrarySales.AssignSalesChargeToSalesLine(SalesHeader, SalesLine, Qty, LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjAndReclassFIFO()
    var
        Item: Record Item;
    begin
        AdjAndReclassJournal(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjAndReclassLIFO()
    var
        Item: Record Item;
    begin
        AdjAndReclassJournal(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjAndReclassSTD()
    var
        Item: Record Item;
    begin
        AdjAndReclassJournal(Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjAndReclassAVG()
    var
        Item: Record Item;
    begin
        AdjAndReclassJournal(Item."Costing Method"::Average);
    end;

    [Normal]
    local procedure AdjAndReclassJournal(CostingMethod: Enum "Costing Method")
    var
        Location: Record Location;
        Bin1: Record Bin;
        Bin2: Record Bin;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();

        // Setup the item.
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Bin Mandatory" := true;
        Location.Modify();
        LibraryWarehouse.CreateBin(Bin1, Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin2, Location.Code, '', '', '');

        // Post positive adjmt and purchase in 2 different bins.
        Qty := LibraryRandom.RandInt(20);
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', Bin1.Code,
          Qty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, Location.Code, '',
          Qty, Day1 + 4, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Bin Code", Bin2.Code);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Post reclassification from bin 2 to bin 1.
        LibraryInventory.PostReclassificationJournalLine(Item, Day1 + 4,
          Location.Code, Location.Code, '', Bin2.Code, Bin1.Code, Qty);

        // Assign charge to receipt.
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        PurchRcptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(PurchaseHeader, PurchRcptLine, 1, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValCostAmountActualFIFO()
    var
        Item: Record Item;
    begin
        ValuateCostAmountActual(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValCostAmountActualLIFO()
    var
        Item: Record Item;
    begin
        ValuateCostAmountActual(Item."Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValCostAmountActualSTD()
    var
        Item: Record Item;
    begin
        ValuateCostAmountActual(Item."Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValCostAmountActualAVG()
    var
        Item: Record Item;
    begin
        ValuateCostAmountActual(Item."Costing Method"::Average);
    end;

    [Normal]
    local procedure ValuateCostAmountActual(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        PurchaseHeader: Record "Purchase Header";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();

        // Setup the item.
        LibraryInventory.CreateItem(Item, CostingMethod, LibraryRandom.RandDec(100, 2), 0, LibraryRandom.RandInt(10), '');

        Qty := LibraryRandom.RandInt(20);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty, Day1, Item."Unit Cost", true, true);
        Clear(SalesHeader);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', 2 * Qty, Day1 + 7, Item."Unit Cost", true, false);

        // Undo shipment and then repost.
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', 5 * Qty, Day1 + 14, Item."Unit Cost", true, true);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', 2 * Qty, Day1 + 21, Item."Unit Cost", true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CostingManufFIFO()
    var
        Item: Record Item;
    begin
        CostingManufacturing(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CostingManufLIFO()
    var
        Item: Record Item;
    begin
        CostingManufacturing(Item."Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CostingManufSTD()
    var
        Item: Record Item;
    begin
        CostingManufacturing(Item."Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CostingManufAVG()
    var
        Item: Record Item;
    begin
        CostingManufacturing(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInventoryValueLongFilters()
    var
        Item: Record Item;
        TempErrorBuffer: Record "Error Buffer" temporary;
        CalcInventoryValueCheck: Codeunit "Calc. Inventory Value-Check";
    begin
        // [FEATURE] [Calculate Inventory Value]
        // [SCENARIO 378236] Calculate Inventory Value can be run with Location Filter and Variant Filter longer than 10 characters

        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set filters on Calculate Inventory Value. Fields Location Filter and Variant Filter, both filters longer than 10 characters
        Item.SetRecFilter();
        Item.SetFilter("Location Filter", '%1|%2', LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        Item.SetFilter("Variant Filter", '%1|%2', LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Run Inventory Valuation - Check
        CalcInventoryValueCheck.SetParameters(WorkDate(), "Inventory Value Calc. Per"::"Item Ledger Entry", true, true, false, true);
        CalcInventoryValueCheck.RunCheck(Item, TempErrorBuffer);

        // [THEN] Verification competed without errors
        Assert.RecordIsEmpty(TempErrorBuffer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInventoryValueOpenILEError()
    var
        Item: Record Item;
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        TempErrorBuffer: Record "Error Buffer" temporary;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CalcInventoryValueCheck: Codeunit "Calc. Inventory Value-Check";
    begin
        // [FEATURE] [Calculate Inventory Value]
        // [SCENARIO 378236] Calculate Inventory Value returns error if there are open outbound item ledger entries

        // [GIVEN] Create item "I"
        Initialize();
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Standard, 0, 0, 0, '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post negative adjustment for item "I"
        LibraryInventory.PostNegativeAdjustment(
          Item, Location.Code, ItemVariant.Code, '', LibraryRandom.RandInt(10), WorkDate(), LibraryRandom.RandDec(100, 2));

        // [WHEN] Run Inventory Valuation - Check
        Item.SetRecFilter();
        Item.SetRange("Location Filter", Location.Code);
        Item.SetRange("Variant Filter", ItemVariant.Code);
        CalcInventoryValueCheck.SetParameters(WorkDate(), "Inventory Value Calc. Per"::"Item Ledger Entry", true, true, false, true);
        CalcInventoryValueCheck.RunCheck(Item, TempErrorBuffer);

        // [THEN] Verification returns error: "open outbound entry found".
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();
        TempErrorBuffer.FindFirst();
        Assert.ExpectedMessage(StrSubstNo(OpenOutboudEntryErr, ItemLedgerEntry."Entry No."), TempErrorBuffer."Error Text");
    end;

    [Normal]
    local procedure CostingManufacturing(CostingMethod: Enum "Costing Method")
    var
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        Day1: Date;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();
        Day1 := WorkDate();

        // Setup the items.
        Qty := LibraryRandom.RandDec(100, 2);
        QtyPer := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItemSimple(ParentItem, CostingMethod, 0);
        LibraryInventory.CreateItemSimple(ChildItem, CostingMethod, 0);
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, ChildItem, QtyPer, '');

        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader1, ChildItem, '', '', Qty * QtyPer, Day1,
          LibraryRandom.RandDec(100, 2), true, false);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader2, ChildItem, '', '', Qty * QtyPer, Day1 + 1,
          LibraryRandom.RandDec(100, 2), true, false);

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem, '', '', Qty, Day1 + 5);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.CreateConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, ChildItem, Day1 + 2, '', '', Qty * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, Day1 + 3, Qty, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Undo output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, Day1 + 4, -Qty, 0);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Applies-to Entry", TempItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post output again.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, Day1 + 5, 2 * Qty, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Finish prod. order.
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, Day1 + 5, false);

        // Invoice the receipts.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, false, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, false, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ChildItem."No." + '|' + ParentItem."No.", '');

        // Sell.
        LibrarySales.PostSalesOrder(SalesHeader, ParentItem, '', '', 2 * Qty, Day1 + 14, 0, true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ChildItem."No." + '|' + ParentItem."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(ParentItem);
        LibraryCosting.CheckAdjustment(ChildItem);
    end;

    [Normal]
    local procedure ApplyToItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify();
    end;

    [Normal]
    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    [Normal]
    local procedure SetupProduction(var ParentItem: Record Item; var CompItem: Record Item; var ProdOrderLine: Record "Prod. Order Line"; LocationCode: Code[10]; ParentCostingMethod: Enum "Costing Method"; CompCostingMethod: Enum "Costing Method"; ProdOrderDate: Date; ProducedQty: Decimal; QtyPer: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Setup produced and component item.
        LibraryInventory.CreateItem(ParentItem, ParentCostingMethod, LibraryRandom.RandDec(100, 2), 0, 0, '');
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify();

        LibraryInventory.CreateItem(CompItem, CompCostingMethod, LibraryRandom.RandDec(100, 2), 0, 0, '');

        // Setup BOM and Routing.
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, CompItem, QtyPer, '');

        // Released production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem, LocationCode, '', ProducedQty, ProdOrderDate);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
    end;

    [Normal]
    local procedure UpdateItemStandardCost(var Item: Record Item)
    begin
        Item.Get(Item."No.");
        Item.Validate("Standard Cost", Item."Standard Cost" + LibraryRandom.RandDec(10, 2));
        Item.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

