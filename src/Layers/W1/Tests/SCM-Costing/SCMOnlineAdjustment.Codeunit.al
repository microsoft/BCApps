codeunit 137001 "SCM Online Adjustment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Automatic Cost Adjustment] [SCM]
        IsInitialized := false;
    end;

    var
        InventorySetup: Record "Inventory Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ErrorNoPurchLine: Label 'No purchase line has been found for item %1.';
        ErrorNoEntryFound: Label 'No value entry found for item %1 of type %2.';
        ErrorWrongCost: Label 'Cost per unit should be %1 (2 decimals) for item %2.';
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        ErrorWrongTotal: Label 'Total cost for value entries should be %1 for item %2.';
        ErrorValueEntries: Label 'Expected %1 entries of ILE Type: %2, Entry Type: %3, Document Type: %4 for item %5.';
        ErrorValueEntry: Label 'Value mismatch in value entry %1, field %2. ';
        ErrorZeroQty: Label 'Transfer Qty should not be 0.';
        DummyMessage: Label 'Message?';
        ItemDeletionErr: Label 'You cannot delete %1 %2 because', Comment = '%1= Item.TableCaption(),%2= Item.No,%3=Planning Component.TABLECAPTION';
        PostingNoSeriesLbl: Label 'No Seires must be from Posting No Series if exists in Item Journal Batch.';


    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlineAdjStandard()
    var
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ValueEntry: Record "Value Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        // 1. Setup demo data.
        // 2. Setup app parameters.
        // 3. Create item with costing method Standard.
        // 4. Create purchase order.
        // 5. Invoice purchase order.
        // 6. Post revaluation journal for item.
        // 7. Create purchase return order.
        // 8. Post purchase return order as invoiced.
        // 9. Validate value entries.

        // Setup: Steps 1-7.
        Initialize();

        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Week, InventorySetup."Average Cost Calc. Type"::Item);

        CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase);

        CreateSingleLinePurchaseOrder(PurchaseHeader, Item."No.", PurchaseLine.Type::Item);

        PostPurchaseOrder(PurchInvHeader, PurchaseHeader);

        PostItemRevaluationJournal(TempItemJournalLine, Item, 1);

        CreatePurchaseReturnOrder(PurchaseHeader, PurchInvHeader);

        // Execute: Invoice purchase return order.
        PostPurchaseReturnOrder(PurchCrMemoHdr, PurchaseHeader);

        // Validate: Value entries.
        CheckPurchInvEntries(Item."No.", PurchInvHeader."No.");
        CheckRevalEntries(TempItemJournalLine, Item."No.");
        CheckOutboundValueEntries(
          TempItemJournalLine,
          ValueEntry."Item Ledger Entry Type"::Purchase,
          ValueEntry."Document Type"::"Purchase Credit Memo",
          ValueEntry."Entry Type"::"Direct Cost",
          PurchCrMemoHdr."No.",
          Item."No.");

        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Purchase,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Purchase Invoice"),
          1, StrSubstNo(ErrorValueEntries, 1, 'Purchase', 'Direct Cost', 'Purchase Invoice', Item."No."));

        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Purchase,
            ValueEntry."Entry Type"::Revaluation,
            ValueEntry."Document Type"::" "),
          1, StrSubstNo(ErrorValueEntries, 1, 'Purchase', 'Revaluation', '', Item."No."));

        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Purchase,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Purchase Credit Memo"),
          2, StrSubstNo(ErrorValueEntries, 2, 'Purchase', 'Direct Cost', 'Purchase Credit Memo', Item."No."));

        // Tier Down.
        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlineAdjAverage()
    var
        Item: Record Item;
        TempPurchInvHeader: Record "Purch. Inv. Header" temporary;
        PurchaseHeader: Record "Purchase Header";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        SalesHeader: Record "Sales Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ValueEntry: Record "Value Entry";
        DocumentNo: Code[20];
    begin
        // 1. Setup demo data.
        // 2. Setup app parameters.
        // 3. Create item with costing method Average.
        // 4. Create 2 purchase orders with 1 line for item.
        // 5. Invoice purchase orders.
        // 6. Create sales order for item.
        // 7. Invoice sales order.
        // 8. Revaluate item.
        // 9. Verify value entries.

        // Setup: Steps 1-7.
        Initialize();

        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Week,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");

        CreateItem(Item, Item."Costing Method"::Average, Item."Replenishment System"::Purchase);

        CreateSingleLinePurchaseOrder(PurchaseHeader, Item."No.", PurchaseLine.Type::Item);
        PostPurchaseOrder(PurchInvHeader, PurchaseHeader);
        TempPurchInvHeader := PurchInvHeader;
        TempPurchInvHeader.Insert();

        CreateSingleLinePurchaseOrder(PurchaseHeader, Item."No.", PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();

        PurchaseLine.Validate("Direct Unit Cost", 0);
        PurchaseLine.Modify(true);
        PostPurchaseOrder(PurchInvHeader, PurchaseHeader);
        TempPurchInvHeader := PurchInvHeader;
        TempPurchInvHeader.Insert();

        CreateSingleLineSalesOrder(SalesHeader, Item);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Execute: Revaluate item.
        PostItemRevaluationJournal(TempItemJournalLine, Item, 1);

        // Validate: Value entries.
        TempPurchInvHeader.FindSet();
        repeat
            CheckPurchInvEntries(Item."No.", TempPurchInvHeader."No.");
        until TempPurchInvHeader.Next() = 0;

        CheckRevalEntries(TempItemJournalLine, Item."No.");
        CheckOutboundValueEntries(
          TempItemJournalLine,
          ValueEntry."Item Ledger Entry Type"::Sale,
          ValueEntry."Document Type"::"Sales Invoice",
          ValueEntry."Entry Type"::"Direct Cost",
          DocumentNo,
          Item."No.");

        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Purchase,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Purchase Invoice"),
          2, StrSubstNo(ErrorValueEntries, 2, 'Purchase', 'Direct Cost', 'Purchase Invoice', Item."No."));

        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Purchase,
            ValueEntry."Entry Type"::Revaluation,
            ValueEntry."Document Type"::" "),
          1, StrSubstNo(ErrorValueEntries, 2, 'Purchase', 'Revaluation', '', Item."No."));

        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Purchase,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Purchase Credit Memo"),
          0, StrSubstNo(ErrorValueEntries, 2, 'Purchase', 'Direct Cost', 'Purchase Credit Memo', Item."No."));

        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Sale,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Sales Invoice"),
          1, StrSubstNo(ErrorValueEntries, 2, 'Sale', 'Direct Cost', 'Sales Invoice', Item."No."));

        // Tier Down.
        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPlanningLineWithItemDeletion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
    begin
        // Verify that error exist after running the order planning and delete the item.

        // Setup: Create Item and Create Production BOM & Create sales order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSingleLineBOM(ProductionBOMHeader, Item);
        CreateProdItem(ParentItem, ProductionBOMHeader."No.");
        CreateSingleLineSalesOrder(SalesHeader, ParentItem);
        OrderPlanningMgt.GetOrdersToPlan(RequisitionLine);

        // Exercise: Delete the Item.
        asserterror Item.Delete(true);

        // Verify: Verifying error message.
        Assert.ExpectedError(StrSubstNo(ItemDeletionErr, Item.TableCaption(), Item."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlineAdjProdOrder()
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ItemJournalTemplate: Record "Item Journal Template";
        Item: Record Item;
        Item1: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        ValueEntry: Record "Value Entry";
        PurchInvHeader1: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Charges] [Production] [Purchase] [Cost Average]
        // [SCENARIO] Check Unit cost and Value entries for Item with Average costing method after purchase, production and Adjust Cost

        // [GIVEN] Demo data, "Automatic Cost Adjustment": Month, "Average Cost Calc. Type": Item.
        Initialize();

        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Month, InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Component item with costing method Average.
        CreateItem(Item1, Item1."Costing Method"::Average, Item1."Replenishment System"::Purchase);

        // [GIVEN] Posted purchase order for component item.
        CreateSingleLinePurchaseOrder(PurchaseHeader, Item1."No.", PurchaseLine.Type::Item);
        PostPurchaseOrder(PurchInvHeader, PurchaseHeader);

        // [GIVEN] BOM with component item on line.
        CreateSingleLineBOM(ProductionBOMHeader, Item1);
        // [GIVEN] Single line routing for a random work center.
        CreateSingleLineRouting(RoutingHeader);

        // [GIVEN] Parent item with costing method Average.
        CreateItem(Item, Item."Costing Method"::Average, Item."Replenishment System"::"Prod. Order");
        // [GIVEN] Routing and BOM assigned to parent item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
        Item.Modify(true);

        Item1.CalcFields(Inventory);
        ProductionOrder.DeleteAll();

        // [GIVEN] Created and refreshed production order for parent item.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          Item."No.", Item1.Inventory);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Consumption and output posted.
        PostProductionOrder(TempItemJournalLine, ProductionOrder."No.", ItemJournalTemplate.Type::Consumption);
        PostProductionOrder(TempItemJournalLine, ProductionOrder."No.", ItemJournalTemplate.Type::Output);
        // [GIVEN] Production order finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Item charge added to production order through a purchase order.
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateSingleLinePurchaseOrder(PurchaseHeader, ItemCharge."No.", PurchaseLine.Type::"Charge (Item)");
        AssignItemCharges(PurchaseHeader, Item1."No.");
        PostPurchaseOrder(PurchInvHeader1, PurchaseHeader);

        // [WHEN] Adjust cost-item entries is run.
        LibraryCosting.AdjustCostItemEntries(ProductionOrder."Source No.", '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Unit cost and value entries for parent item are correct.
        CheckOutputValueEntries(PurchInvHeader, PurchInvHeader1, ProductionOrder, TempItemJournalLine);
        CheckAverageCost(Item."No.");

        // [THEN] Number of entries for parent item are correct.
        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Output,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::" "), 3, StrSubstNo(ErrorValueEntries, 2, 'Output', 'Direct Cost', '', Item."No."));

        // Tear Down.
        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlineAdjTransfers()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        ValueEntry: Record "Value Entry";
        PurchInvHeader1: Record "Purch. Inv. Header";
        TransferHeader: Record "Transfer Header";
        Location: Record Location;
        Location1: Record Location;
        Location2: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Charges] [Transfer] [FIFO] [Purchase]
        // [SCENARIO] Check Unit cost and Value entries for FIFO Item after purchase, transfer and Adjust Cost

        // [GIVEN] Demo data and app parameters set-up. 2 simple locations, 1 in-transit location.
        Initialize();

        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item);

        LibraryWarehouse.CreateTransferLocations(Location, Location1, Location2);

        // [GIVEN] Item with costing method FIFO.
        CreateItem(Item, Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase);

        // [GIVEN] Posted purchase order for FIFO item, for location A.
        CreateSingleLinePurchaseOrder(PurchaseHeader, Item."No.", PurchaseLine.Type::Item);
        UpdatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", Location.Code);
        PostPurchaseOrder(PurchInvHeader, PurchaseHeader);

        // [GIVEN] Posted a transfer order from location A to location B.
        CreateSingleLineTransferOrder(TransferHeader, TransferLine, Location, Location1, Location2, Item);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // [GIVEN] Item charge added to the purchase order and purchase order invoiced.
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateSingleLinePurchaseOrder(PurchaseHeader, ItemCharge."No.", PurchaseLine.Type::"Charge (Item)");
        AssignItemCharges(PurchaseHeader, Item."No.");
        PostPurchaseOrder(PurchInvHeader1, PurchaseHeader);

        // [WHEN] Adjust cost-item entries is run.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Unit cost and value entries for item are correct.
        CheckTransferValueEntries(
          PurchInvHeader,
          PurchInvHeader1,
          ValueEntry."Document Type"::"Transfer Shipment",
          Item."No.",
          Location.Code,
          TransferLine.Quantity,
          -1);
        CheckTransferValueEntries(
          PurchInvHeader, PurchInvHeader1, ValueEntry."Document Type"::"Transfer Shipment",
          Item."No.", Location2.Code, TransferLine.Quantity, 1);
        CheckTransferValueEntries(
          PurchInvHeader,
          PurchInvHeader1,
          ValueEntry."Document Type"::"Transfer Receipt",
          Item."No.",
          Location2.Code,
          TransferLine.Quantity,
          -1);
        CheckTransferValueEntries(
          PurchInvHeader,
          PurchInvHeader1,
          ValueEntry."Document Type"::"Transfer Receipt",
          Item."No.",
          Location1.Code,
          TransferLine.Quantity,
          1);

        // [THEN] Item ledger entries number is correct for item.
        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Transfer,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Transfer Shipment"), 4,
          StrSubstNo(ErrorValueEntries, 4, 'Transfer', 'Direct Cost', 'Transfer Shipment', Item."No."));
        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.",
            ValueEntry."Item Ledger Entry Type"::Transfer,
            ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Transfer Receipt"), 4,
          StrSubstNo(ErrorValueEntries, 4, 'Transfer', 'Direct Cost', 'Transfer Receipt', Item."No."));

        // Tier Down.
        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item);
    end;

    local procedure OnlineAdjMultipleTransfers(AvgCostCalcType: Enum "Average Cost Calculation Type")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        TransferHeader: Record "Transfer Header";
        Location: Record Location;
        Location1: Record Location;
        TempLocation: Record Location temporary;
        TransferLine: Record "Transfer Line";
        "count": Integer;
    begin
        // Test for SE bug 266685.
        // 1. Setup demo data. Add a number of locations.
        // 2. Setup app parameters.
        // 3. Create item with costing method Average.
        // 4. Create and post purchase order for item, for the last location.
        // 5. Create and post transfer order from the last location, back and forth to all the other locations.
        // 6. Adjust cost-item entries.
        // 7. Validate unit cost.
        // 8. Validate item ledger entries for item.

        // Setup.
        Initialize();
        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Never, AvgCostCalcType);

        // Create locations.
        TempLocation.DeleteAll();
        for count := 1 to 4 do begin
            LibraryWarehouse.CreateLocation(Location);
            LibraryInventory.UpdateInventoryPostingSetup(Location);
            TempLocation := Location;
            TempLocation.Insert();
        end;

        // Create in-transit location.
        LibraryWarehouse.CreateInTransitLocation(Location1);
        CreateItem(Item, Item."Costing Method"::Average, Item."Replenishment System"::Purchase);

        // Create and post purchase order for item, for the last location.
        CreateSingleLinePurchaseOrder(PurchaseHeader, Item."No.", PurchaseLine.Type::Item);
        UpdatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", Location.Code);
        PostPurchaseOrder(PurchInvHeader, PurchaseHeader);

        // Create and post transfer order from the last location, back and forth to all the other locations.
        TempLocation.SetFilter(Code, '<>%1', Location.Code);
        if TempLocation.FindSet() then
            repeat
                LibraryWarehouse.CreateTransferHeader(TransferHeader, Location.Code, TempLocation.Code, Location1.Code);
                LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", PurchaseLine.Quantity);
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

                LibraryWarehouse.CreateTransferHeader(TransferHeader, TempLocation.Code, Location.Code, Location1.Code);
                LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", PurchaseLine.Quantity);
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
            until TempLocation.Next() = 0;

        // Execute: Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Validate: Item unit cost.
        Item.Get(Item."No.");
        Assert.AreEqual(CalcUnitCost(Item."No."), Item."Unit Cost", 'Wrong item average cost.');

        // Validate: Number of entries.
        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.", ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Transfer Shipment"), 12,
          StrSubstNo(ErrorValueEntries, 12, 'Transfer', 'Direct Cost', 'Transfer Shipment', Item."No."));
        Assert.AreEqual(
          GetNoOfEntries(
            Item."No.", ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::"Direct Cost",
            ValueEntry."Document Type"::"Transfer Receipt"), 12,
          StrSubstNo(ErrorValueEntries, 12, 'Transfer', 'Direct Cost', 'Transfer Receipt', Item."No."));

        // Tear Down.
        SetupParameters(InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Item()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Transfer] [Average Cost Calculation Type] [Cost Average]
        // [SCENARIO] Check Unit cost and ILEs for Item with costing method Average after purchase, transfer and Adjust Cost, Calculation Type = Item

        // [GIVEN] Setup demo data. Add a number of locations.
        // [GIVEN] Average Cost Calculation Type = Item.
        // [GIVEN] Create item with costing method Average.
        // [GIVEN] Create and post purchase order for item, for the last location.
        // [GIVEN] Create and post transfer order from the last location, back and forth to all the other locations.
        // [WHEN] Adjust cost-item entries.
        // [THEN] Validate unit cost.
        // [THEN] Validate item ledger entries for item.
        OnlineAdjMultipleTransfers(InventorySetup."Average Cost Calc. Type"::Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemAndLocation()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Transfer] [Average Cost Calculation Type] [Cost Average]
        // [SCENARIO] Check Unit cost and ILEs for Item with costing method Average after purchase, transfer and Adjust Cost, Calculation Type = Item,Location,Variant

        // [GIVEN] Setup demo data. Add a number of locations.
        // [GIVEN] Average Cost Calculation Type = Item,Location,Variant.
        // [GIVEN] Create item with costing method Average.
        // [GIVEN] Create and post purchase order for item, for the last location.
        // [GIVEN] Create and post transfer order from the last location, back and forth to all the other locations.
        // [WHEN] Adjust cost-item entries.
        // [THEN] Validate unit cost.
        // [THEN] Validate item ledger entries for item.
        OnlineAdjMultipleTransfers("Average Cost Calculation Type"::"Item & Location & Variant");
    end;

    [Test]
    procedure TakePostingNoseiesFromBatchWhileItmRevalutionJnlPost()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Item1: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        NoSeriesLine: array[2] of Record "No. Series Line";
        NoSeries: array[2] of Record "No. Series";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        DocNo: Code[20];
    begin
        // [SCENARIO -506688] Issue with Posting No. Series on Item Revaluation journal batch
        Initialize();

        // [GIVEN] Item is created.
        LibraryInventory.CreateItem(Item1);

        // [GIVEN] New Item is Posted Into Item Ledger Entry.
        PostItemJournalToPostNewlyCreatedItemIntoILE(
          Item1."No.",
          LibraryRandom.RandDec(100, 0));

        // [GIVEN] Item Journal Template with Revaluation Type is created.
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        ItemJournalTemplate.Type := ItemJournalTemplate.Type::Revaluation;
        ItemJournalTemplate.Modify(true);

        // [GIVEN] Item Journal Batch is created.
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Document No series and Posting No Series are created.
        NoSeries[1].Get(LibraryERM.CreateNoSeriesCode());
        NoSeriesLine[1].SetRange("Series Code", NoSeries[1].Code);
        NoSeriesLine[1].FindFirst();
        NoSeriesLine[1]."Starting Date" := WorkDate();
        NoSeriesLine[1]."Starting No." := LibraryRandom.RandText(2) + '-' + Format(LibraryRandom.RandInt(4));
        NoSeriesLine[1]."Increment-by No." := 1;
        NoSeriesLine[1].Modify();

        NoSeries[2].Get(LibraryERM.CreateNoSeriesCode());
        NoSeriesLine[2].SetRange("Series Code", NoSeries[2].Code);
        NoSeriesLine[2].FindFirst();
        NoSeriesLine[2]."Starting Date" := WorkDate();
        NoSeriesLine[2]."Starting No." := LibraryRandom.RandText(2) + '-' + Format(LibraryRandom.RandInt(4));
        NoSeriesLine[2]."Increment-by No." := 1;
        NoSeriesLine[2].Modify();

        // [GIVEN] No Series are assigned to Item Journal Batch.
        ItemJournalBatch."No. Series" := NoSeries[1].Code;
        ItemJournalBatch."Posting No. Series" := NoSeries[2].Code;
        ItemJournalBatch.Modify(true);

        // [GIVEN] Revaluation Journal and Documnet No are created. 
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalTemplate.Name,
          ItemJournalBatch.Name,
          ItemJournalBatch."Template Type"::Revaluation,
          Item1."No.",
          0);

        // [GIVEN] Get No Series Code into Variable.
        DocNo := NoSeriesBatch.GetNextNo(ItemJournalBatch."No. Series", ItemJournalLine."Posting Date");

        // [GIVEN] Calculation of inventory value for selected item.
        LibraryCosting.CreateRevaluationJnlLines(
          Item1,
          ItemJournalLine,
          DocNo,
          "Inventory Value Calc. Per"::Item,
          "Inventory Value Calc. Base"::" ",
          true,
          true,
          false,
          WorkDate());

        // [GIVEN] Collect and post the resulted Item Journal Line.
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", Item1."No.");
        ItemJournalLine.FindFirst();

        // [GIVEN] Revalue item cost in the item journal.
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Calculated)" + LibraryRandom.RandInt(10));
        ItemJournalLine.Modify(true);

        // [GIVEN] Post revaluation Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] The value of Document No in Value entry and in No series.
        VerifyTheValueOfDocumentNoFromValueEntry(Item1."No.", NoSeriesLine[2]."Starting No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Online Adjustment");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Online Adjustment");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Online Adjustment");
    end;

    local procedure SetupParameters(AutCostAdjustment: Enum "Automatic Cost Adjustment Type"; CalcType: Enum "Average Cost Calculation Type")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        ExecuteUIHandlers();

        // Setup Sales and Purchases.
        LibrarySales.SetCreditWarningsToNoWarnings();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", false);
        PurchasesPayablesSetup.Modify(true);

        // Setup Inventory.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, AutCostAdjustment, CalcType, InventorySetup."Average Cost Period"::Day);

        // Setup Manufacturing.
        LibraryManufacturing.UpdateManufacturingSetup(
          ManufacturingSetup, ManufacturingSetup."Show Capacity In", '', true, true, true);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; ReplenishmentMethod: Enum "Replenishment System"): Code[20]
    var
        UnitCost: Decimal;
    begin
        // Create item.
        LibraryInventory.CreateItem(Item);

        // Set desired costing method and unit cost.
        UnitCost := LibraryRandom.RandInt(100);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Replenishment System", ReplenishmentMethod);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Last Direct Cost", Item."Unit Cost");

        if CostingMethod = Item."Costing Method"::Standard then
            Item.Validate("Standard Cost", UnitCost);

        Item.Modify(true);

        exit(Item."No.");
    end;

    local procedure CreateSingleLinePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LineType: Enum "Purchase Line Type"): Code[20]
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Order Date", WorkDate());
        PurchaseHeader.Modify(true);

        CreatePurchaseLine(PurchaseHeader, ItemNo, LineType);

        exit(PurchaseHeader."No.");
    end;

    local procedure CreateProdItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LineType: Enum "Purchase Line Type")
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, ItemNo, LibraryRandom.RandInt(10));

        // Use random direct unit cost for non-standard costed items
        if LineType = PurchaseLine.Type::Item then begin
            Item.Get(ItemNo);
            if Item."Costing Method" <> Item."Costing Method"::Standard then
                PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        end
        else
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));

        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"): Code[20]
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order",
          PurchInvHeader."Buy-from Vendor No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", PurchInvHeader."Buy-from Vendor No.");
        PurchaseHeader.Validate("Location Code", PurchInvHeader."Location Code");
        PurchaseHeader.Validate("Currency Code", PurchInvHeader."Currency Code");
        PurchaseHeader.Modify(true);

        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if PurchInvLine.FindSet() then
            repeat
                PurchaseLine.Init();
                PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
                PurchaseLine.Validate("Line No.", PurchInvLine."Line No.");
                PurchaseLine.Insert(true);

                PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
                PurchaseLine.Validate("No.", PurchInvLine."No.");
                PurchaseLine.Validate(Quantity, PurchInvLine.Quantity);
                PurchaseLine.Validate("Location Code", PurchInvLine."Location Code");
                PurchaseLine.Modify(true);
                PurchInvLine.Next();
            until PurchInvLine.Next() = 0;

        exit(PurchaseHeader."No.");
    end;

    local procedure CreateSingleLineSalesOrder(var SalesHeader: Record "Sales Header"; Item: Record Item): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Header with blank currency and location.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Order Date", WorkDate() + LibraryRandom.RandInt(30));
        SalesHeader.Modify(true);

        Item.CalcFields(Inventory);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(Round(Item.Inventory)));

        exit(SalesHeader."No.");
    end;

    local procedure CreateSingleLineBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item): Code[20]
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateSingleLineRouting(var RoutingHeader: Record "Routing Header"): Code[20]
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Manual);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '100', RoutingLine.Type::"Work Center", WorkCenter."No.");

        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(100));
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateSingleLineTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; Location: Record Location; Location1: Record Location; Location2: Record Location; Item: Record Item)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location.Code, Location1.Code, Location2.Code);

        Item.CalcFields(Inventory);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(Item.Inventory));
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurchaseOrder(var PurchInvHeader: Record "Purch. Inv. Header"; PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Return Invoice.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        exit(PurchInvHeader."No.");
    end;

    local procedure PostPurchaseReturnOrder(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Return Credit Memo number.
        PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
        PurchCrMemoHdr.FindFirst();

        exit(PurchCrMemoHdr."No.");
    end;

    local procedure PostProductionOrder(var TempItemJournalLine: Record "Item Journal Line" temporary; ProductionOrderNo: Code[20]; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption, ItemJournalTemplate.Name);

        case Type of
            ItemJournalTemplate.Type::Consumption:
                LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
            ItemJournalTemplate.Type::Output:
                begin
                    LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
                    LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, '', ProductionOrderNo);
                    LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
                end;
        end;

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindSet();
        repeat
            TempItemJournalLine := ItemJournalLine;
            TempItemJournalLine.Insert();
        until ItemJournalLine.Next() = 0;

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostItemRevaluationJournal(var TempItemJournalLine: Record "Item Journal Line" temporary; Item: Record Item; RevalDirection: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Item1: Record Item;
        ItemJournalLine1: Record "Item Journal Line";
        CalculatedValue: Decimal;
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine1, ItemJournalTemplate.Name,
          Format(LibraryRandom.RandInt(10000)), ItemJournalBatch."Template Type"::Revaluation, Item."No.", 0);

        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalLine1."Journal Template Name");
        ItemJournalBatch.SetRange(Name, ItemJournalLine1."Journal Batch Name");
        ItemJournalBatch.FindFirst();
        ItemJournalBatch.Validate("No. Series", '');
        ItemJournalBatch.Modify(true);

        // Calculate inventory value for selected item.
        Item1.SetRange("No.", Item."No.");
        LibraryCosting.CreateRevaluationJnlLines(
          Item1, ItemJournalLine1, CopyStr(Item."No.", 1, 5),
          "Inventory Value Calc. Per"::Item, "Inventory Value Calc. Base"::" ", true, true, false, WorkDate());

        // Collect and post the resulted Item Journal Line.
        ItemJournalLine1.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine1.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine1.SetRange("Item No.", Item."No.");
        ItemJournalLine1.FindFirst();

        // Revalue item cost.
        CalculatedValue := ItemJournalLine1."Unit Cost (Calculated)";
        ItemJournalLine1.Validate("Unit Cost (Revalued)", CalculatedValue + RevalDirection * LibraryRandom.RandInt(10));
        ItemJournalLine1.Validate("Inventory Value (Revalued)",
          ItemJournalLine1."Unit Cost (Revalued)" * ItemJournalLine1."Invoiced Quantity");
        ItemJournalLine1.Modify(true);

        // Save in temporary table.
        TempItemJournalLine := ItemJournalLine1;
        TempItemJournalLine.Insert();

        // Post revaluation.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure AssignItemCharges(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();

        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();

        // Insert charge for selected purchase receipt and purchase order line.
        LibraryCosting.AssignItemChargePurch(PurchaseLine, PurchRcptLine);
    end;

    local procedure GetNoOfEntries(ItemNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; EntryType: Enum "Cost Entry Type"; DocumentType: Enum "Item Ledger Document Type"): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Entry Type", EntryType);

        exit(ValueEntry.Count);
    end;

    local procedure CalcUnitCost(ItemNo: Code[20]): Decimal
    var
        ValueEntry: Record "Value Entry";
        SumValue: Decimal;
        SumQty: Decimal;
    begin
        // Get value entries to calculate the average cost on.
        ValueEntry.SetFilter("Item No.", ItemNo);
        ValueEntry.SetFilter("Item Ledger Entry Type", '%1|%2', ValueEntry."Item Ledger Entry Type"::Purchase,
          ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.SetFilter("Document Type", '%1|%2', ValueEntry."Document Type"::"Purchase Invoice", ValueEntry."Document Type"::" ");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        SumValue := 0;
        SumQty := 0;

        // Calculate weighted average cost for item.
        if ValueEntry.FindSet() then
            repeat
                SumValue := SumValue + ValueEntry."Cost Amount (Actual)";
                SumQty := SumQty + ValueEntry."Invoiced Quantity";
            until ValueEntry.Next() = 0;

        if SumQty <> 0 then
            exit(Round(SumValue / SumQty, LibraryERM.GetUnitAmountRoundingPrecision()));

        exit(0);
    end;

    local procedure CheckPurchInvEntries(ItemNo: Code[20]; PurchaseInvoiceHeaderNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ValueEntry: Record "Value Entry";
    begin
        // Filter for purchase invoice no.
        PurchInvHeader.Get(PurchaseInvoiceHeaderNo);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange("No.", ItemNo);
        Assert.IsFalse(PurchInvLine.IsEmpty, StrSubstNo(ErrorNoPurchLine, ItemNo));
        PurchInvLine.FindFirst();

        // Filter purchase invoice - direct cost entries for item.
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Document No.", PurchaseInvoiceHeaderNo);
        Assert.IsFalse(ValueEntry.IsEmpty, StrSubstNo(ErrorNoEntryFound, ItemNo, 'Direct cost'));
        ValueEntry.FindFirst();

        // Test value entry fields.
        ValueEntry.TestField("Cost Amount (Actual)", Round(PurchInvLine.Quantity *
            PurchInvLine."Direct Unit Cost", LibraryERM.GetAmountRoundingPrecision()));
        ValueEntry.TestField("Cost Posted to G/L", ValueEntry."Cost Amount (Actual)");
        ValueEntry.TestField("Valued Quantity", PurchInvLine.Quantity);
        ValueEntry.TestField("Invoiced Quantity", PurchInvLine.Quantity);
        ValueEntry.TestField("Cost per Unit", PurchInvLine."Direct Unit Cost");
    end;

    local procedure CheckRevalEntries(TempItemJournalLine: Record "Item Journal Line" temporary; ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        RevalCostDiff: Decimal;
    begin
        Item.Get(ItemNo);

        // Filter purchase invoice - direct cost entries for item.
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        Assert.IsFalse(ValueEntry.IsEmpty, StrSubstNo(ErrorNoEntryFound, ItemNo, 'Revaluation'));
        ValueEntry.FindFirst();

        // Test value entry fields.
        Assert.AreEqual(
          ValueEntry."Cost Posted to G/L",
          ValueEntry."Cost Amount (Actual)",
          StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost Amount (Actual)'));

        case Item."Costing Method" of
            Item."Costing Method"::Standard:
                begin
                    RevalCostDiff := TempItemJournalLine."Unit Cost (Revalued)" - TempItemJournalLine."Unit Cost (Calculated)";
                    Assert.AreNearlyEqual(
                      RevalCostDiff,
                      ValueEntry."Cost per Unit",
                      0.01,
                      StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost per Unit'));

                    Assert.AreEqual(
                      TempItemJournalLine.Quantity,
                      ValueEntry."Valued Quantity",
                      StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Valued Quantity'));

                    Assert.AreNearlyEqual(
                      Round(RevalCostDiff * TempItemJournalLine.Quantity, LibraryERM.GetAmountRoundingPrecision()),
                      ValueEntry."Cost Amount (Actual)",
                      0.01,
                      StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost Amount (Actual)'));
                end;
            Item."Costing Method"::Average:
                begin
                    RevalCostDiff := TempItemJournalLine."Inventory Value (Revalued)" - TempItemJournalLine."Inventory Value (Calculated)";
                    Assert.AreNearlyEqual(
                      RevalCostDiff,
                      ValueEntry."Cost Amount (Actual)",
                      0.01,
                      StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost Amount (Actual)'));

                    Assert.AreNearlyEqual(
                      Round(RevalCostDiff / ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision()),
                      ValueEntry."Cost per Unit",
                      0.01,
                      StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost per unit'));
                end;
        end;
    end;

    local procedure CheckOutboundValueEntries(ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntryType: Enum "Item Ledger Document Type"; DocumentType: Enum "Item Ledger Document Type"; EntryType: Enum "Cost Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
        RevalCostDiff: Decimal;
    begin
        // Filter for value entry.
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(ValueEntry.IsEmpty, StrSubstNo(ErrorNoEntryFound, ItemNo, Format(DocumentType)));
        ValueEntry.FindSet();

        // Test value entry fields.
        repeat
            if ValueEntry.Adjustment then begin
                RevalCostDiff := ItemJournalLine."Unit Cost (Revalued)" - ItemJournalLine."Unit Cost (Calculated)";
                Assert.AreNearlyEqual(
                  RevalCostDiff,
                  ValueEntry."Cost per Unit",
                  0.01,
                  StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost per Unit'));
            end
            else
                Assert.AreNearlyEqual(
                  ValueEntry."Cost per Unit",
                  CalcUnitCost(ItemNo),
                  0.01,
                  StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost per Unit'));

            Assert.AreEqual(
              ValueEntry."Cost Posted to G/L",
              ValueEntry."Cost Amount (Actual)",
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost posted to GL'));

            Assert.AreNearlyEqual(
              Round(ValueEntry."Cost per Unit" * ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision()),
              ValueEntry."Cost Amount (Actual)",
              0.01,
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost Amount (Actual)'));
        until ValueEntry.Next() = 0;
    end;

    local procedure CheckAverageCost(ItemNo: Code[20])
    var
        Item: Record Item;
        UnitCost: Decimal;
    begin
        Item.Get(ItemNo);
        UnitCost := CalcUnitCost(ItemNo);
        Assert.AreNearlyEqual(
          Round(Item."Unit Cost", LibraryERM.GetAmountRoundingPrecision()),
          UnitCost,
          0.01,
          StrSubstNo(ErrorWrongCost, UnitCost, ItemNo));
    end;

    local procedure CheckOutputValueEntries(PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeader1: Record "Purch. Inv. Header"; ProductionOrder: Record "Production Order"; ItemJournalLine: Record "Item Journal Line")
    var
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        PurchInvLine: Record "Purch. Inv. Line";
        TotalCost: Decimal;
        CalculatedTotalCost: Decimal;
    begin
        Item.Get(ProductionOrder."Source No.");

        // Filter for value entry.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::" ");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Document No.", ProductionOrder."No.");
        Assert.IsFalse(ValueEntry.IsEmpty, StrSubstNo(ErrorNoEntryFound, Item."No.", Format('Output')));
        ValueEntry.FindSet();
        TotalCost := 0;
        CalculatedTotalCost := 0;

        // Calculate actual cost and test value entry fields.
        repeat
            TotalCost += ValueEntry."Cost per Unit" * ValueEntry."Valued Quantity";
            Assert.AreEqual(
              ValueEntry."Cost Posted to G/L",
              ValueEntry."Cost Amount (Actual)",
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost Amount (Actual)'));

            Assert.AreNearlyEqual(
              ValueEntry."Cost per Unit" * ValueEntry."Valued Quantity",
              ValueEntry."Cost Amount (Actual)",
              0.01,
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost Amount (Actual)'));
        until ValueEntry.Next() = 0;

        // Calculate expected cost.
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();

        // Cost of raw material as initially purchased.
        CalculatedTotalCost := PurchInvLine."Direct Unit Cost" * PurchInvLine.Quantity;

        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader1."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"Charge (Item)");
        PurchInvLine.FindFirst();

        // Cost of item charge assigned to purchased item.
        // Cost of capacity.
        ItemJournalLine.FindFirst();
        CalculatedTotalCost := CalculatedTotalCost +
          PurchInvLine."Line Amount" +
          ItemJournalLine."Unit Cost" * ItemJournalLine."Run Time";

        // Test actual total cost.
        Assert.AreNearlyEqual(TotalCost, CalculatedTotalCost, 0.01, StrSubstNo(ErrorWrongTotal, CalculatedTotalCost, Item."No."));
    end;

    local procedure CheckTransferValueEntries(PurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeader1: Record "Purch. Inv. Header"; DocumentType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[20]; TransferQty: Decimal; TransferSign: Integer)
    var
        ValueEntry: Record "Value Entry";
        PurchInvLine: Record "Purch. Inv. Line";
        UnitCost: Decimal;
        ChargeLineAmount: Decimal;
    begin
        // Get item costs.
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
        UnitCost := PurchInvLine."Unit Cost (LCY)";

        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PurchInvHeader1."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"Charge (Item)");
        PurchInvLine.FindFirst();
        ChargeLineAmount := PurchInvLine."Line Amount";

        // Filter for value entry.
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Transfer);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Location Code", LocationCode);
        ValueEntry.FindFirst();
        Assert.AreEqual(ValueEntry.Count, 2, StrSubstNo(ErrorNoEntryFound, ItemNo, Format(DocumentType)));
        Assert.AreNotEqual(TransferQty, 0, ErrorZeroQty);

        // Validate fields.
        if ValueEntry.Adjustment then begin
            Assert.AreNearlyEqual(
              ChargeLineAmount / TransferQty, ValueEntry."Cost per Unit", 0.01,
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost per Unit'));
            Assert.AreEqual(ValueEntry."Invoiced Quantity", 0, StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Invoiced Quantity'));
            Assert.AreEqual(
              ValueEntry."Item Ledger Entry Quantity", 0, StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Item Ledger Entry Quantity'));
            Assert.AreEqual(ValueEntry."Cost Posted to G/L", 0, StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost posted to GL'));
        end
        else begin
            Assert.AreNearlyEqual(
              UnitCost, ValueEntry."Cost per Unit", 0.01, StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost per Unit'));
            Assert.AreEqual(ValueEntry."Item Ledger Entry Quantity", TransferQty * TransferSign,
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Item Ledger Entry Quantity'));
            Assert.AreEqual(ValueEntry."Invoiced Quantity", TransferQty * TransferSign,
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Invoiced Quantity'));
            Assert.AreEqual(ValueEntry."Cost Posted to G/L", ValueEntry."Cost Amount (Actual)",
              StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost posted to GL'));
        end;

        Assert.AreEqual(ValueEntry."Valued Quantity", TransferQty * TransferSign,
          StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Valued Quantity'));
        Assert.AreNearlyEqual(
          Round(ValueEntry."Cost per Unit" * ValueEntry."Valued Quantity", LibraryERM.GetAmountRoundingPrecision()),
          ValueEntry."Cost Amount (Actual)",
          0.01, StrSubstNo(ErrorValueEntry, ValueEntry."Entry No.", 'Cost Amount (Actual)'));
    end;

    local procedure PostItemJournalToPostNewlyCreatedItemIntoILE(ItemNo: code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure VerifyTheValueOfDocumentNoFromValueEntry(ItemNo: code[20]; NoSeries: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.FindLast();

        Assert.AreEqual(NoSeries, ValueEntry."Document No.", PostingNoSeriesLbl);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure ExecuteUIHandlers()
    begin
        Message('');
        if Confirm(DummyMessage) then;
    end;
}

