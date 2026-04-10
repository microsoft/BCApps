codeunit 137620 "SCM Costing Bugs I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Adjust Cost Item Entries]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        ERR_REM_QTY_TOO_LOW: Label 'You cannot ship more than the';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        isInitialized: Boolean;
        OriginalQtyMsg: Label 'For one or more return document lines, you chose to return the original quantity';
        TXT_WrongTextInHandler: Label 'Expected message did not appear.';

    [Test]
    [Scope('OnPrem')]
    procedure VSTF202207()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine1: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        ReservEntry1: Record "Reservation Entry";
        ReservEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
        SalesUnitCost: Decimal;
        SalesILENo: Integer;
        SalesReturnAmount: Decimal;
    begin
        Initialize();

        // Make item
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandInt(100), 0, 0, ItemTrackingCode.Code);

        // 1st line
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine1, ItemJournalBatch, Item, '', '', WorkDate(), ItemJournalLine1."Entry Type"::"Positive Adjmt.", 1,
          LibraryRandom.RandInt(100));
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservEntry1, ItemJournalLine1, '',
          LibraryUtility.GenerateRandomCode(ReservEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry"), ItemJournalLine1.Quantity);
        // 2nd line - qty 1 for each lot
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine2, ItemJournalBatch, Item, '', '', WorkDate(), ItemJournalLine2."Entry Type"::"Positive Adjmt.",
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(100));
        while i < ItemJournalLine2.Quantity do begin
            i += 1;
            LibraryItemTracking.CreateItemJournalLineItemTracking(
              ReservEntry, ItemJournalLine2, '',
              LibraryUtility.GenerateRandomCode(ReservEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry"), 1);
        end;
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Make sales order
        SalesUnitCost := LibraryRandom.RandInt(100);
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', ItemJournalLine1.Quantity, WorkDate(), SalesUnitCost);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SalesLine, '', ReservEntry1."Lot No.", ItemJournalLine1.Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false); // Ship
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, false, true); // Invoice
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast(); // above sales ILE
        SalesILENo := ItemLedgerEntry."Entry No.";

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Create sales return order
        LibrarySales.CreateSalesReturnOrder(
          SalesHeader, SalesLine, Item, '', '', ItemJournalLine1.Quantity, WorkDate(), LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(100, 2));
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SalesLine, '', ReservEntry1."Lot No.", ItemJournalLine1.Quantity);
        ReservEntry.Validate("Appl.-from Item Entry", SalesILENo);
        ReservEntry.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false); // Receive
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, false, true); // Invoice

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify
        LibraryCosting.CheckAdjustment(Item);
        ItemLedgerEntry.FindLast(); // above sales return ILE
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        SalesReturnAmount := ItemLedgerEntry."Cost Amount (Actual)";
        ItemLedgerEntry.Get(SalesILENo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        SalesUnitCost := ItemLedgerEntry."Cost Amount (Actual)";
        Assert.AreEqual(-1 * SalesUnitCost * ItemJournalLine1.Quantity, SalesReturnAmount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF265183()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        ProductionOrder4: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Day1: Date;
        Day2: Date;
    begin
        Initialize();

        // Make item
        LibraryInventory.CreateItem(ItemA, ItemA."Costing Method"::Average, LibraryRandom.RandInt(100), 0, 0, '');
        LibraryInventory.CreateItem(ItemB, ItemB."Costing Method"::Average, LibraryRandom.RandInt(100), 0, 0, '');
        LibraryInventory.CreateItem(ItemC, ItemC."Costing Method"::Average, LibraryRandom.RandInt(100), 0, 0, '');

        // Make ProdBOMs
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ItemA, ItemB, 1, '');
        ItemB.Get(ItemB."No.");
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ItemB, ItemC, 1, '');

        Day1 := WorkDate() + 10;
        Day2 := Day1 + 33;

        // Post item journal
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemB, '', '', '', 200, Day1, 0);

        // Create prod. orders
        LibraryManufacturing.CreateProductionOrder(ProductionOrder1, ProductionOrder1.Status::Released, ItemA, '', '', 120, Day2 + 1);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder2, ProductionOrder2.Status::Released, ItemB, '', '', 120, Day2 + 1);

        // Post item journal
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemC, '', '', '', 200, Day2, 0);

        // Production postings
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder2);
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ItemC, '', '', ProductionOrder2.Quantity, Day2 + 1, ItemC."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProductionOrder2.Quantity, Day2 + 1, ItemB."Unit Cost");
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder1);
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ItemB, '', '', ProductionOrder1.Quantity, Day2 + 1, ItemB."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProductionOrder1.Quantity, Day2 + 1, ItemA."Unit Cost");

        // EXERCISE
        // Create and post prod. orders
        LibraryManufacturing.CreateProductionOrder(ProductionOrder3, ProductionOrder3.Status::Released, ItemA, '', '', 15, Day2 + 1);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder4, ProductionOrder4.Status::Released, ItemB, '', '', 15, Day2 + 1);
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder3);
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ItemB, '', '', ProductionOrder3.Quantity, Day2 + 1, ItemB."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProductionOrder3.Quantity, Day2 + 1, ItemA."Unit Cost");
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder4);
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ItemC, '', '', ProductionOrder4.Quantity, Day2 + 1, ItemC."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProductionOrder4.Quantity, Day2 + 1, ItemB."Unit Cost");

        // finish prod orders
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder1, ProductionOrder1.Status::Finished, Day2 + 1, true);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder2, ProductionOrder2.Status::Finished, Day2 + 1, true);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder3, ProductionOrder3.Status::Finished, Day2 + 1, true);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder4, ProductionOrder4.Status::Finished, Day2 + 1, true);

        // adjust cost
        LibraryCosting.AdjustCostItemEntries(ItemB."No.", '');
        LibraryCosting.AdjustCostItemEntries(ItemA."No.", '');
        LibraryCosting.AdjustCostItemEntries(ItemC."No.", '');

        // Verify
        LibraryCosting.CheckAdjustment(ItemA);
        LibraryCosting.CheckAdjustment(ItemB);
        LibraryCosting.CheckAdjustment(ItemC);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF234233Average()
    var
        Item: Record Item;
    begin
        VSTF234233(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF234233FIFO()
    var
        Item: Record Item;
    begin
        VSTF234233(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF234233LIFO()
    var
        Item: Record Item;
    begin
        VSTF234233(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF234233Standard()
    var
        Item: Record Item;
    begin
        VSTF234233(Item."Costing Method"::Standard);
    end;

    local procedure VSTF234233(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        ValueEntry: Record "Value Entry";
        Day1: Date;
        PurchaseQty: Decimal;
        OutputQty: Decimal;
        SalesQty: Decimal;
        VerifyVariance: Boolean;
    begin
        Initialize();

        // Make item
        LibraryInventory.CreateItem(Item, CostingMethod, 0, 0, 0, '');

        Day1 := WorkDate();
        // Post purchase order
        PurchaseQty := LibraryRandom.RandInt(100);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', PurchaseQty, Day1, 0, true, true);

        // Post production
        OutputQty := LibraryRandom.RandIntInRange(1, PurchaseQty);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item, '', '', OutputQty, Day1 - 60);
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.POSTConsumption(ProdOrderLine, Item, '', '', OutputQty, Day1 - 30, Item."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, OutputQty, Day1 - 60, Item."Unit Cost");
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, Day1 - 30, true);

        // Post sales
        SalesQty := LibraryRandom.RandIntInRange(1, PurchaseQty + OutputQty);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', SalesQty, Day1 - 90, Item."Unit Cost", true, true);

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Valuation Date", Day1);
        until ValueEntry.Next() = 0;
        LibraryCosting.CheckAdjustment(Item);
        VerifyVariance := CostingMethod = Item."Costing Method"::Standard;
        LibraryManufacturing.CheckProductionOrderCost(ProductionOrder, VerifyVariance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF272991()
    var
        InventorySetup: Record "Inventory Setup";
        ProducedItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        Initialize();

        // Inventory setup
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Make item and put child into inventory
        LibraryInventory.CreateItem(ChildItem, ChildItem."Costing Method"::Standard, LibraryRandom.RandInt(10), 0, 0, '');
        LibraryInventory.CreateItem(ProducedItem, ProducedItem."Costing Method"::Standard, LibraryRandom.RandInt(10), 0, 0, '');
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItem, '', '', '', 1000, WorkDate(),
          ChildItem."Standard Cost");

        // Make production order and post output and then consumption
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProducedItem, '', '', LibraryRandom.RandInt(10), WorkDate());
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.POSTOutput(ProdOrderLine, ProdOrderLine.Quantity, WorkDate(), ProdOrderLine."Unit Cost");
        ItemLedgerEntry.FindLast(); // output line
        LibraryManufacturing.POSTConsumption(
          ProdOrderLine, ChildItem, '', '', LibraryRandom.RandInt(10), WorkDate(), ChildItem."Standard Cost");

        // Finish prod order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // Verify
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        Assert.IsFalse(ValueEntry.IsEmpty, ''); // should have a variance type of value entry as cost should be auto-adjusted.
        LibraryCosting.CheckAdjustment(ChildItem);
        LibraryCosting.CheckAdjustment(ProducedItem);
        LibraryManufacturing.CheckProductionOrderCost(ProductionOrder, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF206911()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Purch1Cost: Decimal;
        Purch2Cost: Decimal;
        PurchQty: Decimal;
        SalesQty: Decimal;
    begin
        Initialize();

        // Inventory setup
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Make item
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandInt(10), 0, 0, '');

        // Post purchases
        PurchQty := LibraryRandom.RandInt(10);
        Purch1Cost := LibraryRandom.RandInt(10);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', PurchQty, WorkDate(), Purch1Cost, true, true);
        ItemLedgerEntry.FindLast(); // store the first purchase ILE
        Purch2Cost := LibraryRandom.RandIntInRange(Purch1Cost, 20); // higher than cost of 1st purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', PurchQty, WorkDate(), Purch2Cost, true, true);

        // Make sales
        SalesQty := LibraryRandom.RandIntInRange(PurchQty, 2 * PurchQty);
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', SalesQty, WorkDate(), LibraryRandom.RandInt(10));

        // Verify
        asserterror SalesLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        Assert.IsTrue(StrPos(GetLastErrorText, ERR_REM_QTY_TOO_LOW) > 0, '');
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler,OriginalQtyMessageHandler')]
    [Scope('OnPrem')]
    procedure VSTF328958_SunshineScenario()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        Purch1Cost: Decimal;
        PurchQty: Decimal;
        SalesQty: Decimal;
    begin
        Initialize();

        // Make item
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Standard, LibraryRandom.RandInt(10), 0, 0, '');

        // Post purchase
        PurchQty := LibraryRandom.RandInt(10);
        Purch1Cost := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '', PurchQty, WorkDate(), Purch1Cost);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Post sale
        SalesQty := LibraryRandom.RandIntInRange(PurchQty, PurchQty);
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', SalesQty, WorkDate(), LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Make purchase return
        Vendor.Get(VendorNo);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        PurchaseHeader.GetPstdDocLinesToReverse();

        // Verify post purchase return
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler,OriginalQtyMessageHandler')]
    [Scope('OnPrem')]
    procedure VSTF328958_DifferentUOMsScenario()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        NonBaseItemUOM1: Record "Item Unit of Measure";
        NonBaseItemUOM2: Record "Item Unit of Measure";
        VendorNo: Code[20];
        Purch1Cost: Decimal;
        PurchQty: Decimal;
        SalesQty: Decimal;
        QtyPerBaseUOM: Decimal;
    begin
        Initialize();

        // Make item with additional UOMs
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandInt(10), 0, 0, '');
        QtyPerBaseUOM := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItemUnitOfMeasureCode(NonBaseItemUOM1, Item."No.", QtyPerBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasureCode(NonBaseItemUOM2, Item."No.", QtyPerBaseUOM);

        // Post purchase using alternative UOM 1
        PurchQty := LibraryRandom.RandInt(10);
        Purch1Cost := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '', PurchQty, WorkDate(), Purch1Cost);
        PurchaseLine.Validate("Unit of Measure Code", NonBaseItemUOM1.Code);
        PurchaseLine.Modify(true);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Post sale using alternative UOM 2
        SalesQty := LibraryRandom.RandIntInRange(PurchQty, PurchQty);
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', SalesQty, WorkDate(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit of Measure Code", NonBaseItemUOM2.Code);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Make purchase return
        Vendor.Get(VendorNo);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        PurchaseHeader.GetPstdDocLinesToReverse();

        // Verify post purchase return
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF239230()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Day1: Date;
        Day2: Date;
        InventoryQty: Decimal;
        QtyPosItemPosting: Decimal;
        QtyProdOrder: Decimal;
        QtyOutput: Decimal;
        QtyNegItemPosting: Decimal;
    begin
        Initialize();

        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Month);

        // Make item
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandInt(10), 0, 0, '');
        LibraryManufacturing.CreateRouting(RoutingHeader, Item, '', LibraryRandom.RandInt(10));

        Day1 := WorkDate() - 90;
        // Post item journal
        InventoryQty := LibraryRandom.RandDecInDecimalRange(2, 10, 2);
        QtyPosItemPosting := LibraryRandom.RandDecInDecimalRange(1, InventoryQty - 1, 2);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', QtyPosItemPosting, Day1, LibraryRandom.RandInt(10));
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '',
          InventoryQty - QtyPosItemPosting, Day1 + 2, LibraryRandom.RandInt(10));

        Day2 := Day1 + 60;
        // Create prod order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item, '', '', InventoryQty, WorkDate());
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        QtyProdOrder := LibraryRandom.RandDecInDecimalRange(1, InventoryQty - 1, 2);
        LibraryManufacturing.POSTConsumption(ProdOrderLine, Item, '', '', QtyProdOrder, Day2, Item."Unit Cost"); // consume after 2 months
        LibraryManufacturing.POSTConsumption(ProdOrderLine, Item, '', '', InventoryQty - QtyProdOrder, Day2, Item."Unit Cost"); // consume after 2 months

        // Explode routing and post
        QtyOutput := LibraryRandom.RandDecInDecimalRange(1, InventoryQty - 1, 2);
        OutputJournalExplodeRouting(ItemJournalBatch, ProdOrderLine, Day2);
        GetFirstItemJournalLineInBatch(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Output Quantity", QtyOutput);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        OutputJournalExplodeRouting(ItemJournalBatch, ProdOrderLine, Day2);
        GetFirstItemJournalLineInBatch(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Output Quantity", InventoryQty - QtyOutput);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Finish prod order
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, Day2, true);

        // Make negative adjustments
        QtyNegItemPosting := LibraryRandom.RandDecInDecimalRange(1, InventoryQty - 1, 2);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', QtyNegItemPosting, Day2, Item."Unit Cost");
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', InventoryQty - QtyNegItemPosting, Day2, Item."Unit Cost");

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify
        LibraryCosting.CheckAdjustment(Item);
        LibraryManufacturing.CheckProductionOrderCost(ProductionOrder, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF295274()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Day1: Date;
        Qty: Decimal;
        PurchaseQty1: Decimal;
        UnitCost: Decimal;
        Loc: Code[10];
        Variant: Code[10];
        ii: Integer;
    begin
        Initialize();

        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Make item
        LibraryInventory.CreateItem(Item);
        Item."Costing Method" := Item."Costing Method"::Average;
        Item.Modify();

        Day1 := WorkDate();
        Qty := 2388;
        UnitCost := 63.3152;
        PurchaseQty1 := Qty / 4;
        Loc := '';
        Variant := '';

        // Post item journals
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item, '', '', '', Qty, Day1, UnitCost);

        ItemLedgerEntry.Init();
        ItemLedgerEntry.SetRange("Item No.", Item."No.", Item."No.");
        ItemLedgerEntry.FindFirst();

        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        for ii := 1 to 4 do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch, Item, Loc, Variant, Day1, ItemJournalLine."Entry Type"::"Negative Adjmt.", PurchaseQty1,
              UnitCost);
            ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
            ItemJournalLine.Modify(true);
        end;
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF330557_WorkCenterToMachineCenter()
    var
        MachineCenter: Record "Machine Center";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Initialize();

        // Setup the item and its routing.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandInt(10), 0, 0, '');
        LibraryManufacturing.CreateRouting(RoutingHeader, Item, '', LibraryRandom.RandDec(100, 2));

        // Explode routing, modify and post
        MachineCenter.Next(LibraryRandom.RandInt(MachineCenter.Count));
        MachineCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        MachineCenter.Modify();
        PostModifiedOutputJournal(ItemJournalLine, Item, ItemJournalLine.Type::"Machine Center", MachineCenter."No.");

        // Verify
        VerifyOutputValueEntry(ItemJournalLine, MachineCenter."Unit Cost");
    end;

    [Normal]
    local procedure VSTF330557_MachineCenterToWorkCenter(Specific: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        WorkCenterGroup: Record "Work Center Group";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Initialize();

        // Setup the item and its routing.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandInt(10), 0, 0, '');

        WorkCenter.Next(LibraryRandom.RandInt(WorkCenter.Count));
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", 100);
        MachineCenter.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        MachineCenter.Modify();

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Machine Center", MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify();

        // Explode routing, modify and post
        WorkCenterGroup.FindFirst();
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        WorkCenter.Validate("Specific Unit Cost", Specific);
        WorkCenter.Modify();
        CapacityUnitOfMeasure.FindFirst();
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Modify();

        PostModifiedOutputJournal(ItemJournalLine, Item, ItemJournalLine.Type::"Work Center", WorkCenter."No.");

        // Verify
        // For Specific cost Work Centers, the unit cost used is still the original Prod. Order Rtng. Line cost.
        if Specific then
            VerifyOutputValueEntry(ItemJournalLine, MachineCenter."Unit Cost")
        else
            VerifyOutputValueEntry(ItemJournalLine, WorkCenter."Unit Cost")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF330557_SpecificWorkCenter()
    begin
        VSTF330557_MachineCenterToWorkCenter(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF330557_NonSpecificWorkCenter()
    begin
        VSTF330557_MachineCenterToWorkCenter(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF81()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        Initialize();

        // Make item. Post adjustments.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');

        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, WorkDate(), 0);

        // Exercise: Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);

        // Applied entries to adjust flag is not present.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Applied Entry to Adjust", true);
        Assert.IsTrue(ItemLedgerEntry.IsEmpty, 'There should be no Applied Entry flag for the item.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostRoundingAmountForwardedToAppliedProductionEntries()
    var
        ComponentItem: Record Item;
        ParentItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        // [FEATURE] [Manufacturing]
        // [SCENARIO 377809] Rounding amount posted for a production component is transferred to all applied item ledger entries

        // [GIVEN] Create item "I1" with FIFO costing method
        LibraryInventory.CreateItem(ComponentItem, ComponentItem."Costing Method"::FIFO, 0, 0, 0, '');

        // [GIVEN] Create manufactured item "I2" with Standard costing method and item "I1" as a component
        LibraryInventory.CreateItem(ParentItem);

        CreateCertifiedProductionBOM(ProdBOMHeader, ParentItem."Base Unit of Measure", ComponentItem."No.", 1);

        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Production BOM No.", ProdBOMHeader."No.");
        ParentItem.Modify(true);

        // [GIVEN] Create purchase order for 3 components "I1", direct unit cost = 0.33333. Post as received only.
        CreatePurchaseOrderWithDirectCost(PurchaseHeader, PurchaseLine, ComponentItem."No.", '', 3, 1 / 3);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create and refresh production order for item "I2"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", 3);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Post 3 output entries and 3 consumption entries
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        for I := 1 to 3 do begin
            LibraryManufacturing.POSTOutput(ProdOrderLine, 1, WorkDate(), ParentItem."Unit Cost");
            LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', 1, WorkDate(), ComponentItem."Unit Cost");
        end;

        // [GIVEN] Finish production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Sell 3 produced items "I2" in 3 separate sales entries
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        for I := 1 to 3 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ParentItem."No."), '');

        // [GIVEN] Update cost in purchase order and post invoice. New direct unit cost = 0.66666
        ReopenPurchaseDocAndPostInvoiceWithNewCost(PurchaseHeader, PurchaseLine, 2 / 3);

        // [WHEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ComponentItem."No.", ParentItem."No."), '');

        // [THEN] Inventory value of item "I2" is 0
        VerifyItemInventoryValue(ParentItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedEntryToAdjustRemovedWhenTransferCostAdjusted()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        MoveFromLocation: Record Location;
        MoveToLocation: Record Location;
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer]
        // [SCENARIO 377809] All transfer entries are marked as adjusted after adjust cost - item entries is run

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(MoveFromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(MoveToLocation);

        // [GIVEN] Create item "I" with FIFO costing method
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2), 0, 0, '');

        // [GIVEN] Post purchase receipt of item "I" on location "L1"
        Qty := LibraryRandom.RandDec(100, 2);
        CreatePurchaseOrderWithDirectCost(PurchaseHeader, PurchaseLine, Item."No.", MoveFromLocation.Code, Qty, Item."Unit Cost");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post transfer of item "I" from location "L1" to location "L2"
        PostTransferOrder(Item."No.", Qty, MoveFromLocation.Code, MoveToLocation.Code);

        // [GIVEN] Change unit cost in purchase order and post invoice
        ReopenPurchaseDocAndPostInvoiceWithNewCost(PurchaseHeader, PurchaseLine, PurchaseLine."Direct Unit Cost" * 2);

        // [WHEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] There are no entries marked for adjustment
        VerifyItemLedgerEntriesToAdjustNotExist(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetVisitedEntriesWithinValuationPeriod()
    var
        InventorySetup: Record "Inventory Setup";
        Location: array[3] of Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 380539] Function GetVisitedEntries in table 339 "Item Application Entry" should collect entries within valuation period

        Initialize();

        // [GIVEN] Update Inventory Setup: set "Average Cost Calc. Type" = "Item & Location & Variant", "Average Cost Period" = Day and disable automatic cost adjustment
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);

        // [GIVEN] Two locations "L1" and "L2"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        // [GIVEN] Item "I". Post inventory adjustment on location "L2" on WORKDATE
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');
        LibraryInventory.PostPositiveAdjustment(Item, Location[2].Code, '', '', 1, WorkDate(), LibraryRandom.RandDec(100, 2));
        // [GIVEN] Transfer item "I" from location "L2" to "L1" on WorkDate() + 1 day
        LibraryInventory.CreateAndPostTransferOrder(
          TransferHeader, Item, Location[2], Location[1], Location[3], '', 1, WorkDate() + 1, WorkDate() + 1, true, true);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location[2].Code);
        ItemLedgerEntry.FindFirst();

        // [WHEN] Calculate valuation chain on WORKDATE
        ItemApplicationEntry.GetVisitedEntries(ItemLedgerEntry, TempItemLedgerEntry, true);

        // [THEN] Valuation chain is empty, transfers are not included
        Assert.RecordIsEmpty(TempItemLedgerEntry);
    end;

    [Test]
    procedure LocationCodeIsSavedInAvgCostAdjmtEntryPointForFIFOItem()
    var
        Item: Record Item;
        Location: Record Location;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        // [SCENARIO 521477] Location code is saved in Avg. Cost Adjmt. Entry Point for FIFO item.
        Initialize();

        // [GIVEN] Create item "I" with FIFO costing method
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');

        // [GIVEN] Create location "L"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [WHEN] Post positive adjustment of item "I" on location "L"
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', 1, WorkDate(), LibraryRandom.RandDec(100, 2));

        // [THEN] Avg. Cost Adjmt. Entry Point is created with location code "L"
        AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
        AvgCostAdjmtEntryPoint.FindLast();
        AvgCostAdjmtEntryPoint.TestField("Location Code", Location.Code);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Bugs I");
        // Lazy Setup.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Bugs I");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Bugs I");
    end;

    local procedure CreateCertifiedProductionBOM(var ProdBOMHeader: Record "Production BOM Header"; UoMCode: Code[10]; ComponentItemNo: Code[20]; QtyPer: Decimal)
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader, UoMCode);
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ComponentItemNo, QtyPer);
        ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
        ProdBOMHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithDirectCost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; UnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure GetFirstProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        Clear(ProdOrderLine);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure GetFirstItemJournalLineInBatch(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure OutputJournalExplodeRouting(var ItemJournalBatch: Record "Item Journal Batch"; ProdOrderLine: Record "Prod. Order Line"; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);

        Item.Get(ProdOrderLine."Item No.");
        LibraryInventory.MakeItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, PostingDate, ItemJournalLine."Entry Type"::"Positive Adjmt.", 0);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.SetUpNewLine(ItemJournalLine);
        ItemJournalLine.Insert();
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
    end;

    [Normal]
    local procedure PostModifiedOutputJournal(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item; NewType: Enum "Capacity Type Journal"; NewNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // Create prod order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item, '', '',
          LibraryRandom.RandDec(100, 2), WorkDate());
        GetFirstProdOrderLine(ProdOrderLine, ProductionOrder);

        // Explode routing
        LibraryManufacturing.OutputJournalExplodeOrderLineRouting(ItemJournalBatch, ProdOrderLine, WorkDate());
        GetFirstItemJournalLineInBatch(ItemJournalLine, ItemJournalBatch);

        // Change type and post
        ItemJournalLine.Validate(Type, NewType);
        ItemJournalLine.Validate("No.", NewNo);
        ItemJournalLine.Validate("Run Time", LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Validate("Setup Time", LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostTransferOrder(ItemNo: Code[20]; Qty: Decimal; MoveFromLocationCode: Code[10]; MoveToLocationCode: Code[10])
    var
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, MoveFromLocationCode, MoveToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);
    end;

    local procedure ReopenPurchaseDocAndPostInvoiceWithNewCost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; NewUnitCost: Decimal)
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", NewUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure VerifyItemInventoryValue(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        ValueEntry.TestField("Cost Amount (Actual)", 0);
        ValueEntry.TestField("Cost Amount (Expected)", 0);
    end;

    local procedure VerifyItemLedgerEntriesToAdjustNotExist(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Applied Entry to Adjust", true);
        Assert.RecordIsEmpty(ItemLedgerEntry);
    end;

    [Normal]
    local procedure VerifyOutputValueEntry(ItemJournalLine: Record "Item Journal Line"; UnitCost: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order Type", ItemJournalLine."Order Type");
        ValueEntry.SetRange("Order No.", ItemJournalLine."Order No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
        Assert.AreEqual(1, ValueEntry.Count, 'Too many value entries created for capacity.');
        ValueEntry.SetRange(Type, ItemJournalLine.Type);
        ValueEntry.SetRange("No.", ItemJournalLine."No.");
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(ItemJournalLine."Run Time" + ItemJournalLine."Setup Time", ValueEntry."Valued Quantity",
          LibraryERM.GetAmountRoundingPrecision(), 'Wrong valued qty.');
        Assert.AreNearlyEqual(UnitCost * ValueEntry."Valued Quantity", ValueEntry."Cost Amount (Actual)",
          LibraryERM.GetAmountRoundingPrecision(), 'Wrong cost amount.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinePageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.OriginalQuantity.SetValue(true);
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure OriginalQtyMessageHandler(Message: Text)
    begin
        Assert.IsTrue(StrPos(Message, OriginalQtyMsg) > 0, TXT_WrongTextInHandler);
    end;
}

