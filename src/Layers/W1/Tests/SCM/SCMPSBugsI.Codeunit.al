codeunit 137035 "SCM PS Bugs-I"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ErrMessageNotFoundZeroAmt: Label 'The WIP amount totals must be Zero.';
        ErrMessageCostNotSame: Label 'Cost must be Equal.';
        ErrInventoryValueCalculated: Label 'Inventory Value Calculated must be equal.';
        ErrorGeneratedMustBeSame: Label 'Error Generated Must Be Same.';
        ExpectedOutputMissing: Label 'You cannot finish line %1 on Production Order %2. It has consumption or capacity posted with no output.';
        ErrNoOfLinesMustBeEqual: Label 'No. of Line Must Be Equal.';
        RefText: Label '%1 %2.';
        MSG_Firm_Planned_Prod: Label 'Firm Planned Prod. Order';
        MSG_Change_Status_Q: Label 'Production Order';
        WrongDescriptionInOrderErr: Label 'Wrong description in %1.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        MissingQst: Label '\\  * Some output is still missing.\  * Some consumption is still missing.\\ Do you still want to finish the order?';
        OutputIsMissingQst: Label '\\  * Some output is still missing.\\ Do you still want to finish the order?';
        ConsumptionIsMissingQst: Label '\\  * Some consumption is still missing.\\ Do you still want to finish the order?';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
        OustandingPickLineExistsErr: Label 'You cannot finish production order no. %1 because there is an outstanding pick for one or more components.';
        QuantityErr: Label 'Quantity update should be possible in %1.', Comment = '%1= Table Name.';
        DueDateErr: Label 'Planned production order due date not match with planning worksheet due date';
        SKUInventoryErr: Label 'Expected inventory to be blank for non-inventory item';
        MainItemErr: Label 'New planning worksheet line not created for main item';
        CompoItemErr: Label 'New planning worksheet line not created for component item';

    [Test]
    [Scope('OnPrem')]
    procedure CalcProdOrderLineQuantity()
    begin
        // Create Production order Family and Check Production Order Line Quantity.
        Initialize();
        ProdOrderLineQuantity(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcProdOrderLineQuantityUOM()
    begin
        // Create Production order Family with one Item having alternate UOM and Check Production Order Line Quantity.
        Initialize();
        ProdOrderLineQuantity(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegPlanAndCarryOutActMsg()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
    begin
        // Setup : Update Sales Setup.
        Initialize();

        // Create Item with Replenishment System as Production Order.Create Sales Order.
        CreateItemAndSalesOrder(Item, Item."Replenishment System"::"Prod. Order");
        ItemNo := Item."No.";

        // Create Item with Replenishment System as Purchase.Create Sales Order.
        CreateItemAndSalesOrder(Item, Item."Replenishment System"::Purchase);

        // Execute : Calculate regenerative Plan and Carry Out Action Message Plan for Production Order.
        CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Template Type"::Planning);
        CalculateRegenerativePlan(ItemNo, Item."No.");

        // Verify : Verify two Requisition Lines created for both Items.
        RequisitionLine.SetFilter("No.", '%1|%2', ItemNo, Item."No.");
        Assert.AreEqual(2, RequisitionLine.Count, ErrNoOfLinesMustBeEqual);

        // Execute : Carry Out Action Message for Reference Order Type Production Order.
        CarryOutActMsgPlan(RequisitionLine, ItemNo);

        // Verify : Verify one Requisition Lines Exist after Carry Out Action Message.
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.AreEqual(1, RequisitionLine.Count, ErrNoOfLinesMustBeEqual);

        // Verify Planned Production Order Created.
        FindProdOrder(ProductionOrder, ProductionOrder.Status::Planned, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionOrderSaveAsXML')]
    procedure PrintMultipleProductionOrdersWhenUsingCarryOutActionMessage()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
    begin
        // Setup : Update and Initialize Setup.
        Initialize();

        // Create Item "A" with Replenishment System as Production Order
        CreateItem(
              Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
                Item."Replenishment System"::"Prod. Order");
        UpdateItem(Item, Item."Flushing Method", Item."Reordering Policy"::"Fixed Reorder Qty.", LibraryRandom.RandInt(10));
        ItemNo := Item."No.";

        // Create Item "B" with Replenishment System as Production Order
        CreateItem(
              Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
                Item."Replenishment System"::"Prod. Order");
        UpdateItem(Item, Item."Flushing Method", Item."Reordering Policy"::"Fixed Reorder Qty.", LibraryRandom.RandInt(10));

        // Execute : Calculate regenerative Plan and Carry Out Action Message Plan for Production Order, for both Items.
        CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Template Type"::Planning);
        CalculateRegenerativePlan(ItemNo, Item."No.");

        // Verify : Verify two Requisition Lines created for both Items.
        RequisitionLine.SetFilter("No.", '%1|%2', ItemNo, Item."No.");
        Assert.AreEqual(2, RequisitionLine.Count, ErrNoOfLinesMustBeEqual);

        // Set Prod. Order report selection
        SetupReportSelections("Report Selection Usage"::"Prod.Order", Report::"Prod. Order - List");

        // Execute : Carry Out Action Message for Reference Order Type Production Order.
        CarryOutActMsgPlanFirmPlanAndPrint(RequisitionLine);

        // Verify Firm Planned Production Orders are printed.
        FindProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo);
        VerifyPrintedProdOrders(ProductionOrder);

        FindProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");
        VerifyPrintedProdOrders(ProductionOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemRefPurchaseOrderUnitCost()
    var
        PurchaseLine: Record "Purchase Line";
        ItemReference: Record "Item Reference";
        DirectUnitCost: Decimal;
    begin
        // 1. Setup : Create Item. Create Purchase Order and Item Reference.
        Initialize();
        ItemReferenceSetup(PurchaseLine, ItemReference, "Item Reference Type"::" ", '', false);

        // 2. Execute : Update Item Reference in Purchase Line.
        DirectUnitCost := PurchaseLine."Direct Unit Cost";
        UpdateItemReference(PurchaseLine, ItemReference."Reference No.");

        // 3. Verify : Verify Direct Unit Cost of Purchase Line.
        PurchaseLine.TestField("Direct Unit Cost", DirectUnitCost);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteProdOrderLineConsumption()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderNo: Code[20];
    begin
        // Setup : Update Sales Setup.Create Item and Update Item Inventory.
        Initialize();

        CreateProdBOMUpdateInventory(ProductionBOMHeader);
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");

        // Create Released Production Order and Refresh it.
        ProdOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');

        // Create Consumption Journal.Go to released production order delete prod order line.Post Consumption Journal.
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, '', ItemJournalBatch."Template Type"::Consumption, ProdOrderNo);
        DeleteProdOrderLine(ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Create Output Journal and Post it.
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, Item."No.", ItemJournalBatch."Template Type"::Output, ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderNo);

        // Exercise : Run Adjust cost batch Job.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify : WIP Account.
        VerifyTotalWIPAccountAmount(Item."No.", ProdOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryValueCalcRevalJrnl()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        InventorySetup: Record "Inventory Setup";
        InventoryValueCalculated: Decimal;
    begin
        // 1. Setup : Update Sales Setup.Create Item and Update Inventory.Random values used are not important for test.
        Initialize();

        InventorySetup.Get();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        CreateItem(
          Item, Item."Costing Method"::Average, '', '', Item."Manufacturing Policy", Item."Reordering Policy", Item."Replenishment System");
        Item.Validate("Unit Price", LibraryRandom.RandDec(50, 1));
        Item.Modify(true);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100) + 10);

        // Create Purchase Order and Post receipt.Create Sale Order and Post it.Update Direct unit Cost and Post Invoice.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandInt(100), LibraryRandom.RandDec(50, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, Item."No.", Item.Inventory - 5); // Value used is important for test.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        UpdatePurchaseOrderDirectCost(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 2. Execute : Run Adjust cost and create Revaluation Journal.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        Item.Get(Item."No.");
        CreateItemJournalBatch(ItemJournalBatch);
        Item.SetRange("No.", Item."No.");
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), ItemJournalLine."Document No.", "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);

        // 3. Verify : Inventory Value (Calculated) in Revaluation Journal with Inventory Value at Item card.
        InventoryValueCalculated := GetInventoryValue(Item."No.");
        Item.CalcFields(Inventory);
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          InventoryValueCalculated, Item."Unit Cost" * Item.Inventory, GeneralLedgerSetup."Amount Rounding Precision",
          ErrInventoryValueCalculated);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLastDirectCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseDirectCost: Decimal;
    begin
        // 1. Setup Update Sales and Inventory Setup.Create Negative Adjustment and Post it. Random values used are not important for test.
        Initialize();

        CreateItem(
          Item, Item."Costing Method"::Average, '', '', Item."Manufacturing Policy", Item."Reordering Policy", Item."Replenishment System");
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100));

        // 2 : Create Purchase Order and Post it.Random values used are not important for test.
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandInt(10), LibraryRandom.RandDec(50, 2));
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseDirectCost := PurchaseLine."Direct Unit Cost";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3 : Verify Item Last Direct Cost.
        Item.Get(Item."No.");
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          PurchaseDirectCost, Item."Last Direct Cost", GeneralLedgerSetup."Amount Rounding Precision", ErrMessageCostNotSame);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJrnlEndingTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderNo: Code[20];
    begin
        // 1. Setup : Update Sales Setup.Create Item and Update Item Inventory.
        Initialize();

        CreateProdBOMUpdateInventory(ProductionBOMHeader);
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Stock",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");

        // Create Released Production Order and Refresh it.
        ProdOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');

        // 2. Execute : Create Output Journal. Update Start Time and End time, End time must be less than Start time.Post it.
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, Item."No.", ItemJournalBatch."Template Type"::Output, ProdOrderNo);
        UpdateOutputJrnl(ProdOrderNo, 000000T + LibraryRandom.RandInt(LibraryUtility.ConvertHoursToMilliSec(12)));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 3. Verify : Verify Item Ledger Entry Posted of Entry Type Output.
        ItemLedgerEntry.SetRange("Document No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderCompChangeWithVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderNo: Code[20];
        ItemNo: Code[20];
        ComponentItemDescription: Code[100];
    begin
        // 1. Setup : Update Sales Setup.Create Item and Update Item Inventory.Random values used are not important for test.
        Initialize();

        CreateItem(
          Item, Item."Costing Method", '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::"Prod. Order");
        ItemNo := Item."No.";
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ComponentItemDescription := ItemVariant.Description;

        // Create Finished Item.
        CreateProdBOM(ProductionBOMHeader, Item, Item."Base Unit of Measure");
        CreateItem(
          Item, Item."Costing Method", '', ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Stock",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");

        // 2. Execute : Create Released Production Order with Stock keeping Unit Location and Refresh it and Create
        // Production order component.
        ProdOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');
        UpdateProdOrderComponent(ProdOrderComponent, ProdOrderNo, ItemNo, ItemVariant.Code);

        // 3. Verify : Verify Component Item Description.
        ProdOrderComponent.TestField(Description, ComponentItemDescription);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler,FirmPlannedProdOrderMessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderOutputMissing()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderNo: Code[20];
    begin
        // 1. Setup : Update Sales Setup.Create and Update Item Inventory.
        Initialize();

        CreateItem(
          Item, Item."Costing Method", '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::Purchase);
        UpdateItem(Item, Item."Flushing Method"::Backward, Item."Reordering Policy", 0);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100));

        // Create Routing with Flushing Method Backward.Create Production BOM.
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method"::Backward);
        CreateProdBOM(ProductionBOMHeader, Item, Item."Base Unit of Measure");

        // Create Finished Item.
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");
        UpdateItem(Item, Item."Flushing Method"::"Pick + Manual", Item."Reordering Policy", 0);

        // Create Sales Order and Create Firm Planned Prod order using order Planning.Change Status to Released.
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", Item."No.");
        ProdOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status, ProductionOrder.Status::Released);

        // 2. Execute : Change Status from Released to Finished.
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderNo);

        // 3. Verify: Verify Output entry missing.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
        Assert.AreEqual(
          StrSubstNo(ExpectedOutputMissing, ProdOrderLine."Line No.", ProdOrderLine."Prod. Order No."), GetLastErrorText,
          ErrorGeneratedMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityOnItemLedgerEntryAfterPostingItemJournal()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationCode: Code[10];
        Quantity: Integer;
    begin
        // Verify Quantity on Item Ledger Entry after Posting Item Journal.

        // Setup: Create and modify Location and Items.Post Item Journal.
        Initialize();
        LocationCode := CreateAndModifyLocationCode();
        CreateAndModifyItem(Item, Item."Replenishment System"::"Prod. Order", '', '', '');
        CreateAndModifyItem(
          Item2, Item."Replenishment System"::Purchase, CreateAndModifyItemTrackingCode(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        Quantity := LibraryRandom.RandIntInRange(2, 10);

        // Exercise: Create and Post Item Journal.
        CreateAndPostItemJournalLine(Item."No.", Item2."No.", LocationCode, Quantity);

        // Verify: Verify Quantity and Location Code on Item Ledger Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationCode, Quantity);
        VerifyItemLedgerEntry(ItemLedgerEntry, Item2."No.", LocationCode, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerAsTrue,CreateInvtPutawayPickMvmtRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure QuantityAfterPostingWareHouseInventoryActivity()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseEmployee: Record "Warehouse Employee";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationCode: Code[10];
        WarehouseActivityHeaderSourceNo: Code[20];
        Quantity: Integer;
    begin
        // Verify Quantity on Item Ledger Entry after Posting Warehouse Inventory Activity.

        // 1. Setup: Create and modify Location and Items.Post Item Journal.Create and Refresh Prod. Order.
        Initialize();
        LocationCode := CreateAndModifyLocationCode();
        CreateAndModifyItem(Item, Item."Replenishment System"::"Prod. Order", '', '', '');
        CreateAndModifyItem(
          Item2, Item."Replenishment System"::Purchase, CreateAndModifyItemTrackingCode(), LibraryUtility.GetGlobalNoSeriesCode(), '');
        CreateAndModifyItem(
          Item3, Item."Replenishment System"::Purchase, '', '',
          CreateAndModifyProductionBOM(Item."Base Unit of Measure", Item."No.", Item2."No."));
        Quantity := LibraryRandom.RandIntInRange(2, 10);
        CreateAndPostItemJournalLine(Item."No.", Item2."No.", LocationCode, Quantity);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);
        CreateAndRefreshProductionOrder(ProductionOrder, Item3."No.", Item2."No.", LocationCode);

        // Exercise: Create and Post WareHouse Inventory Activity
        WarehouseActivityHeaderSourceNo :=
          CreateAndPostWareHouseInventoryActivity(ProductionOrder."Source No.", Item."No.", Item2."No.", Quantity);

        // 3. Verify: Verify Invoiced Quantity on Item Ledger Entry.
        ItemLedgerEntry.SetRange("Document No.", WarehouseActivityHeaderSourceNo);
        VerifyItemLedgerEntry(ItemLedgerEntry, Item."No.", LocationCode, -1 * Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderNo: Code[20];
    begin
        // 1. Setup : Update Sales Setup.Create Item and attach it to BOM.
        Initialize();

        CreateItem(
          Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::"Prod. Order");
        CreateProdBOM(ProductionBOMHeader, Item, Item."Base Unit of Measure");
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");

        // Create Finished Item.
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");

        // 2. Execute : Create Released Production Order,refresh it.
        ProdOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');

        // 3. Verify : Production Order Line Created.
        FindProdOrderLine(ProdOrderLine, ProdOrderNo, ProductionOrder.Status);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler,FirmPlannedProdOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderUnitCost()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProdOrderNo: Code[20];
    begin
        // 1. Setup : Update Sales Setup.Create Item and Update Item Inventory.Random values used are not important for test.
        Initialize();

        CreateProdBOMUpdateInventory(ProductionBOMHeader);
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100));

        // Create Sales Order and Auto reserve.
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, Item."No.", Item.Inventory);
        AutoReserveSalesLine(SalesHeader);

        // Create Sales Order and Create Firm Planned Prod order using order Planning.
        Clear(SalesHeader);
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, Item."No.", Item.Inventory);
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", Item."No.");

        // 2. Execute : Find firm planned order and Change Status to released with Update unit cost as TRUE.
        ProdOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status, ProductionOrder.Status::Released);

        // 3. Verify : Sales Order Unit Cost.
        FindSalesLine(SalesHeader, SalesLine);
        VerifyProdComponentUnitCost(ProductionOrder.Status::Released, ProdOrderNo, SalesLine."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SKUUnitCost()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        InventorySetup: Record "Inventory Setup";
        ProductionOrderNo: Code[20];
    begin
        // 1. Setup : Update Sales and Inventory Setup.
        Initialize();

        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);
        LibraryInventory.SetAutomaticCostPosting(false);
        LibraryInventory.SetExpectedCostPosting(false);

        // Create BOM Item and Create Stock keeping Unit.
        CreateItem(
          Item, Item."Costing Method", '', '', Item."Manufacturing Policy"::"Make-to-Stock", Item."Reordering Policy",
          Item."Replenishment System");
        CreateSKUAndUpdateUnitCost(StockkeepingUnit, Item."No.");

        // Create Finished Item.
        CreateProdBOM(ProductionBOMHeader, Item, Item."Base Unit of Measure");
        CreateItem(
          Item, Item."Costing Method", '', ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Stock",
          Item."Reordering Policy", Item."Replenishment System");

        // 2. Execute : Create Released Production Order with Stock keeping Unit Location and Refresh it.
        ProductionOrderNo :=
          CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", StockkeepingUnit."Location Code");

        // 3. Verify : Production order Component cost with SKU Unit Cost.
        VerifyProdComponentUnitCost(ProductionOrder.Status::Released, ProductionOrderNo, StockkeepingUnit."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialOrderCarryOutActMsg()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ItemVendor: Record "Item Vendor";
        PurchaseHeaderNo: Code[20];
    begin
        // 1. Setup : Update Sales Setup.Create Item and Vendor. Update Item Inventory.
        Initialize();

        CreateItem(
          Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::Purchase);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100));

        // Create Sales Order and Update sales line to make it a Special Order.
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, Item."No.", Item.Inventory);
        Purchasing.SetRange("Special Order", true);
        Purchasing.FindFirst();
        UpdateSalesLine(SalesHeader, '', Purchasing.Code);

        // Create Requisition Line. Get sales Order.Perform Carry out Action Message.
        CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Template Type"::"Req.");
        GetSalesOrder(RequisitionLine, Item."No.");
        UpdateReqLine(RequisitionLine, Vendor."No.", Item."No.");
        LibraryPlanning.CarryOutReqWksh(
          RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(),
          StrSubstNo(RefText, RequisitionLine.FieldCaption("Vendor No."), RequisitionLine."Vendor No."));

        // Find Purchase Order and Post Reciept.Post Shipment,
        FindPurchaseHeader(PurchaseHeader, Vendor."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // 2. Execute : Update Direct Unit Cost on Purchase Line and Post Purchase Invoice.
        UpdatePurchaseOrderDirectCost(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // 3. Verify : Verify Purchase Invoice posted.
        PurchInvHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchInvHeader.SetRange("Order No.", PurchaseHeaderNo);
        PurchInvHeader.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMComponentCost()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        UnitOfMeasure: Record "Unit of Measure";
        ProductionOrderNo: Code[20];
        ComponentUnitCost: Decimal;
    begin
        // 1. Setup : Update Sales and Inventory Setup.
        Initialize();

        // Create BOM Item and Create Unit of measure code.
        CreateItem(
          Item, Item."Costing Method", '', '', Item."Manufacturing Policy"::"Make-to-Stock", Item."Reordering Policy",
          Item."Replenishment System");
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        ComponentUnitCost := Item."Unit Cost";

        // Create Finished Item.
        CreateProdBOM(ProductionBOMHeader, Item, Item."Base Unit of Measure");
        CreateItem(
          Item, Item."Costing Method", '', ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Stock",
          Item."Reordering Policy", Item."Replenishment System");

        // 2. Execute : Create Released Production Order with Stock keeping Unit Location and Refresh it.
        ProductionOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');

        // 3. Verify : Production order component cost with Unit Cost in UOM.
        VerifyProdComponentUnitCost(
          ProductionOrder.Status::Released, ProductionOrderNo, ComponentUnitCost * ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMComponentCostManual()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        UnitOfMeasure: Record "Unit of Measure";
        ProdOrderNo: Code[20];
        ComponentUnitCost: Decimal;
    begin
        // 1. Setup : Update Sales Setup.Create Item and attach Alternate Unit of measure to it.
        Initialize();

        CreateItem(
          Item, Item."Costing Method", '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::Purchase);
        UpdateItem(Item, Item."Flushing Method"::Backward, Item."Reordering Policy", 0);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        ComponentUnitCost := Item."Unit Cost";

        // Update Item Inventory.
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100) + 50);

        // Create Production BOM and Production BOM line with Alternate unit of measure.
        CreateProdBOM(ProductionBOMHeader, Item, ItemUnitOfMeasure.Code);
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");

        // Create Finished Item.
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");
        UpdateItem(Item, Item."Flushing Method"::"Pick + Manual", Item."Reordering Policy", 0);

        // Create Released Production Order and Refresh it.
        ProdOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');

        // Create Output Journal and Post it.
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, Item."No.", ItemJournalBatch."Template Type"::Output, ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 2. Execute : Change Status from Released To Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderNo);

        // 3. Verify : Production Components Cost.
        VerifyProdComponentUnitCost(
          ProductionOrder.Status::Finished, ProdOrderNo, ComponentUnitCost * ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ManagedConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValueEntryCostAmtExpNoConsmp()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderNo: Code[20];
    begin
        // 1. Setup : Update Sales and Inventory Setup.
        Initialize();

        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);

        CreateProdBOMUpdateInventory(ProductionBOMHeader);
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Stock",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");

        // Create Released Production Order and Refresh it.
        ProdOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');

        // Create Output Journal and Post it.
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, Item."No.", ItemJournalBatch."Template Type"::Output, ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // 2. Execute : Change Status from Released To Finished.
        LibraryVariableStorage.Enqueue(ConsumptionIsMissingQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderNo);

        // 3. Verify : Value Entry Cost Amount Expected.
        VerifyValueEntry(ProdOrderNo, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure RoutingNoOnProductionOrderLine()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
        Direction: Option Forward,Backward;
        Quantity: Decimal;
    begin
        // Check Routing No. on Prod. Order Line after changing Status from Released to Finished.

        // Setup : Create Production BOM,Production Order and Production Order Lines and Refresh Production Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateProdBOM(ProductionBOMHeader, Item, '');
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method"::"Pick + Manual");
        CreateItem(
          Item2, Item2."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.",
          Item2."Manufacturing Policy"::"Make-to-Stock", Item2."Reordering Policy", Item2."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item2."No.", Quantity);
        CreateProdOrderLines.Copy(ProductionOrder, Direction::Backward, '', true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Exercise : Change Status from Released To Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify : Verify Quantity on Production Order Header and Routing No. On Prod. Order Line.
        FindProdOrder(ProductionOrder, ProductionOrder.Status::Finished, Item2."No.");
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status::Finished);
        ProductionOrder.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Routing No.", Item2."Routing No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceDescriptionInPurchOrder()
    var
        ItemReference: Record "Item Reference";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendNo: Code[20];
    begin
        // Check that purchase order description validates with item reference description

        Initialize();
        VendNo := LibraryPurchase.CreateVendorNo();
        CreateItemWithItemReference(ItemReference, ItemReference."Reference Type"::Vendor, VendNo);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemReference."Item No.", LibraryRandom.RandInt(100));
        Assert.AreEqual(
          ItemReference.Description, PurchaseLine.Description, StrSubstNo(WrongDescriptionInOrderErr, PurchaseHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceDescriptionInSalesOrder()
    var
        ItemReference: Record "Item Reference";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
    begin
        // Check that sales order description validates with item reference description

        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        CreateItemWithItemReference(ItemReference, ItemReference."Reference Type"::Customer, CustNo);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemReference."Item No.", LibraryRandom.RandInt(100));
        Assert.AreEqual(
          ItemReference.Description, SalesLine.Description, StrSubstNo(WrongDescriptionInOrderErr, SalesHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('OutputJournalItemLookupHandler')]
    [Scope('OnPrem')]
    procedure OutputJournalForProdOrderWithMultipleLinesForSameItem()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderLine2: Record "Prod. Order Line";
        OutputJournal: TestPage "Output Journal";
    begin
        // Setup : Update Sales Setup.Create Item and Update Item Inventory.
        Initialize();

        CreateProdBOMUpdateInventory(ProductionBOMHeader);
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");

        // Create Released Production Order and Refresh it.
        CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", '');

        // Add second line for the same item
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindLast();
        ProdOrderLine2 := ProdOrderLine;
        ProdOrderLine2."Line No." := ProdOrderLine."Line No." + 10000;
        ProdOrderLine2.Quantity := 2 * ProdOrderLine.Quantity;
        ProdOrderLine2.Insert();
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Create Output Journal and Post it.
        // LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch,Item."No.",ItemJournalBatch."Template Type"::Output,ProdOrderNo);
        OutputJournal.OpenEdit();
        OutputJournal."Order No.".SetValue(ProductionOrder."No.");
        OutputJournal."Order Line No.".SetValue(ProdOrderLine2."Line No.");
        OutputJournal."Item No.".Lookup();
        OutputJournal."Order Line No.".AssertEquals(ProdOrderLine2."Line No.");
        OutputJournal.Close();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NoDateConflictWarningTrackedNotReservedPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        ReceiptDate: Date;
    begin
        // [FEATURE] [Purchase] [Item Tracking]
        // [SCENARIO 217878] Changing expected receipt date in a purchase order should not raise the date conflict warning when the item is tracked and not reserved

        Initialize();

        // [GIVEN] Lot tracked item "I"
        CreateAndModifyItem(
          Item, Item."Replenishment System"::Purchase, CreateAndModifyItemTrackingCode(), LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Purchase order for the item "I"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        ReceiptDate := PurchaseLine."Expected Receipt Date";

        // [GIVEN] Assign lot no. to the purchase order line
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Move expected receipt date in the order line to an earlier day
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Expected Receipt Date".SetValue(PurchaseLine."Expected Receipt Date" - 1);
        PurchaseOrder.OK().Invoke();

        // [THEN] Expected receipt date is updated without warning
        PurchaseLine.Find();
        PurchaseLine.TestField("Expected Receipt Date", ReceiptDate - 1);
    end;

    [Test]
    [HandlerFunctions('ManagedConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinishingProdOrderWithMissingOutputIsInterruptedIfNotConfirmed()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order] [Production Order Status] [Output] [UT]
        // [SCENARIO 284740] Finishing production order is interrupted when a user chooses not to proceed due to missing output.
        Initialize();

        // [GIVEN] Released production order.
        CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), '');

        // [WHEN] Change status of the production order to "Finished" and choose "No" when warned of missed output.
        LibraryVariableStorage.Enqueue(OutputIsMissingQst);
        LibraryVariableStorage.Enqueue(false);
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Finishing the production order is interrupted to respect the warning.
        Assert.ExpectedError(UpdateInterruptedErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ManagedConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmFinishingProdOrderWithCompleteOutputButMissingConsumption()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production Order] [Production Order Status] [Consumption] [UT]
        // [SCENARIO 284740] Finishing production order with complete output needs a confirmation if the consumption has not been posted in full.
        Initialize();

        // [GIVEN] Released production order.
        CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), '');

        // [GIVEN] Nothing is left to output in the order.
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        ProdOrderLine."Remaining Quantity" := 0;
        ProdOrderLine.Modify();

        // [GIVEN] A component is not consumed yet.
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine);

        // [WHEN] Change status of the production order to "Finished" and choose "Yes" when warned of missed consumption.
        LibraryVariableStorage.Enqueue(ConsumptionIsMissingQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The production order is finished.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOutstandingPickOfComponentCanExistWhenFinishingProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production Order] [Production Order Status] [Consumption] [UT]
        // [SCENARIO 284740] Finishing production order is interrupted with error if outstanding pick line exists for a prod. order component.
        Initialize();

        // [GIVEN] Released production order.
        CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), '');

        // [GIVEN] Nothing is left to output in the order.
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        ProdOrderLine."Remaining Quantity" := 0;
        ProdOrderLine.Modify();

        // [GIVEN] First prod. order component is not consumed and does not have outstanding pick lines.
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine);

        // [GIVEN] Second prod. order component is not consumed. An outstanding pick is created for this component.
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine);
        MockWhsePickForProdOrderComponent(ProdOrderComponent);

        // [WHEN] Change status of the production order to "Finished".
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The error is raised pointing to the outstanding pick line that prevents changing status.
        Assert.ExpectedError(StrSubstNo(OustandingPickLineExistsErr, ProductionOrder."No."));
    end;

    [Test]
    procedure NoOutstandingInvtPickOfComponentCanExistWhenFinishingProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production Order] [Production Order Status] [Consumption] [Inventory Pick] [UT]
        // [SCENARIO 284740] Finishing production order is interrupted with error if outstanding inventory pick line exists for a prod. order component.
        Initialize();

        // [GIVEN] Released production order.
        CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), '');

        // [GIVEN] Nothing is left to output in the order.
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        ProdOrderLine."Remaining Quantity" := 0;
        ProdOrderLine.Modify();

        // [GIVEN] First prod. order component is not consumed and does not have outstanding pick lines.
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine);

        // [GIVEN] Second prod. order component is not consumed. An outstanding inventory pick is created for this component.
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine);
        MockInvtPickForProdOrderComponent(ProdOrderComponent);

        // [WHEN] Change status of the production order to "Finished".
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The error is raised pointing to the outstanding inventory pick line that prevents finishing the order.
        Assert.ExpectedError(StrSubstNo(OustandingPickLineExistsErr, ProductionOrder."No."));
    end;

    [Test]
    [HandlerFunctions('ManagedConfirmHandler')]
    [Scope('OnPrem')]
    procedure FinishingProdOrderWithMissingConsumpIsInterruptedIfNotConfirmed()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production Order] [Production Order Status] [Output] [Consumption] [UT]
        // [SCENARIO 284740] Finishing production order is interrupted when a user chooses not to proceed due to missing consumption.
        Initialize();

        // [GIVEN] Released production order.
        CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);

        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine);

        // [WHEN] Change status of the production order to "Finished" and reply "No" to missing output and consumption warning
        LibraryVariableStorage.Enqueue(MissingQst);
        LibraryVariableStorage.Enqueue(false);
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Finishing the production order is interrupted to respect the warning.
        Assert.ExpectedError(UpdateInterruptedErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinishingProdOrderWithOneCompleteLineAndAnotherFlushedShowsNoWarning()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Production Order] [Production Order Status] [Output] [UT]
        // [SCENARIO 284740] Finishing production order does not warn a user of missing output if the output will be automatically posted due to backward flushing method on unfinished prod. order line.
        Initialize();

        // [GIVEN] Released production order.
        CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), '');

        // [GIVEN] First prod. order line is set up to "Backward" flushing method.
        FindProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        MockProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine, ProdOrderRoutingLine."Flushing Method"::Backward);

        // [GIVEN] Second prod. order line has "Manual" flushing method and is completely posted.
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandInt(10));
        ProdOrderLine."Remaining Quantity" := 0;
        ProdOrderLine.Modify();
        MockProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine, ProdOrderRoutingLine."Flushing Method"::Manual);

        // [WHEN] Change status of the production order to "Finished".
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] No warning is raised.
        // [THEN] The production order is finished.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
    end;

    [Test]
    procedure PlanningComponentsChangingQuantityPossibleNonInventoryItem()
    var
        Item: array[2] of Record Item;
        Location: Record Location;
        PlanningComponent: Record "Planning Component";
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 575511] Planning worksheet in the planning Components when changing Quantity is possible on non inventory Item.
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create an Item and Validate Replenishment System and Policy.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Validate("Reordering Policy", Item[1]."Reordering Policy"::"Lot-for-Lot");

        // [GIVEN] Create an Item with Type Non Inventory.
        LibraryInventory.CreateNonInventoryTypeItem(Item[2]);

        // [GIVEN] Create Certified Production BOM.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, Item[2]."No.", LibraryRandom.RandInt(1));

        // [GIVEN] Validate Production BOM No. in Item.
        Item[1].Validate(Item[1]."Production BOM No.", ProductionBOMHeader."No.");
        Item[1].Modify(true);

        // [GIVEN] Create Sales Document with Item.
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader,
            SalesLine,
            SalesHeader."Document Type"::Order,
            '',
            Item[1]."No.",
            LibraryRandom.RandInt(2),
            Location.Code,
            0D);

        // [GIVEN] Create a Requisition Line.
        CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Template Type"::Planning);

        // [GIVEN] Run Calculate Regenerative plan for Item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item[1], CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [GIVEN] Store a Quantity in Variable.
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Find Planning Component.
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Item No.", Item[2]."No.");
        PlanningComponent.FindFirst();

        // [WHEN] Validate new Quantity in Planning Componenet.
        PlanningComponent.Validate(Quantity, Quantity);
        PlanningComponent.Modify(true);

        // [THEN] Quantity should be able to updated when Item is Non-Inventory.
        Assert.AreEqual(
            Quantity,
            PlanningComponent.Quantity,
            StrSubstNo(
                QuantityErr,
                PlanningComponent.TableName()));
    end;

    [Test]
    procedure CheckDueDateWhileCreatingPlannedProductionOrderFromPlanningWorksheet()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ReqLineInPlanWksh: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        StockkeepingUnit: Record "Stockkeeping Unit";
        SafetyLeadTime: DateFormula;
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        DueDate: Date;
    begin
        // [SCENARIO 566003] Check DueDate While Creating Planned Production Order From Planning Worksheet.
        Initialize();

        // [GIVEN] Create Item with Replenishment System as Production Order.
        CreateItem(Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Stock", Item."Reordering Policy"::" ",
            Item."Replenishment System"::"Prod. Order");

        // [GIVEN] Create Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Stock Keeping Unit.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');
        Evaluate(SafetyLeadTime, '<10D>');
        StockkeepingUnit.Validate(StockkeepingUnit."Safety Lead Time", SafetyLeadTime);
        StockkeepingUnit.Modify(true);

        // [GIVEN] Create Create Requisition Line and Modify Due Date.
        CreateRequisitionLineForItemAndLocation(ReqLineInPlanWksh, RequisitionWkshName, Item."No.", Location.Code, DueDate);

        // [WHEN] Execute : Carry Out Action Message for Reference Order Type Planned Production Order.
        LibraryPlanning.CarryOutPlanWksh(ReqLineInPlanWksh, NewProdOrderChoice::Planned, 0, 0, 0,
            ReqLineInPlanWksh."Worksheet Template Name", ReqLineInPlanWksh."Journal Batch Name", '', '');

        // [THEN] Verify Planned Production Order Created DueDate.
        VerifyPlannedProdOrderDueDate(ProductionOrder, ProductionOrder.Status::Planned, Item."No.", DueDate);
    end;

    [Test]
    [HandlerFunctions('SKURequestPageHandler')]
    procedure CheckInventoryValueIsHiddenForNonInventorySKU()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SKUPage: TestPage "Stockkeeping Unit List";
        SKUCardPage: TestPage "Stockkeeping Unit Card";
        Itemcard: TestPage "Item Card";
    begin
        // [SCENARIO 592721] For Non-Inventory Item SKUs, Check Inventory value is Blank on List and Card page.
        Initialize();

        // [GIVEN] Create Item with Replenishment System as Production Order.
        CreateItem(Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Stock", Item."Reordering Policy"::" ", Item."Replenishment System"::Purchase);
        Item.Validate("Type", Item.Type::"Non-Inventory");
        Item.Modify(true);

        // [GIVEN] Create Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Purchase order for Item and Location.
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, Location.Code, '', LibraryRandom.RandInt(5), WorkDate(), 100);

        // [WHEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Create Stockkeeping Unit for Item and Location.
        LibraryVariableStorage.Enqueue(Location.Code);
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemCard."&Create Stockkeeping Unit".Invoke();
        ItemCard.OK().Invoke();

        // [THEN] Verify Stockkeeping Unit Created for Item and Location Inventory Value is blank on List Page.
        SKUPage.OpenView();
        SKUPage.Filter.SetFilter("Item No.", Item."No.");
        SKUPage.Filter.SetFilter("Location Code", Location."Code");
        Assert.AreEqual('', SKUPage.Inventory.Value, SKUInventoryErr);

        // [THEN] Verify Stockkeeping Unit Created for Item and Location Inventory Value is blank on Card Page.
        SKUCardPage.OpenView();
        SKUCardPage.Filter.SetFilter("Item No.", Item."No.");
        SKUCardPage.Filter.SetFilter("Location Code", Location."Code");
        Assert.AreEqual('', SKUCardPage.Inventory.Value, SKUInventoryErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SKURequestPageHandler')]
    procedure CheckPlanningWorksheetPlanComponentwhenStockkeepingUnitsSetup()
    var
        CompItem: Record Item;
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        MainItem: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        Requisitionline: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Itemcard: TestPage "Item Card";
        SKUCardPage: TestPage "Stockkeeping Unit Card";
        ActualCount: Integer;
    begin
        // [SCENARIO 579977] Check Planning Worksheet Plan Component when Stockkeeping Units Setup for Items.
        Initialize();

        // [GIVEN] Set Manufacturing Setup for Dynamic Low-Level Code and Inventory Setup for ombined MPS/MRP Calculation.
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Dynamic Low-Level Code", true);
        ManufacturingSetup.Modify(true);
        InventorySetup.Get();
        InventorySetup.Validate("Combined MPS/MRP Calculation", true);
        InventorySetup.Modify(true);

        // [GIVEN] Create Item with Replenishment System as Production Order.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Stockkeeping Unit for Item and Location.
        Commit();
        LibraryVariableStorage.Enqueue(Location.Code);
        ItemCard.OpenView();
        ItemCard.GotoRecord(CompItem);
        ItemCard."&Create Stockkeeping Unit".Invoke();
        ItemCard.OK().Invoke();

        // [GIVEN] Modify Stockkeeping Unit for Item.
        SKUCardPage.OpenView();
        SKUCardPage.Filter.SetFilter("Item No.", CompItem."No.");
        SKUCardPage.Filter.SetFilter("Location Code", Location."Code");
        SKUCardPage."Replenishment System".SetValue("Replenishment System"::Purchase);
        SKUCardPage."Reordering Policy".SetValue("Reordering Policy"::"Order");
        SKUCardPage.Close();

        // [GIVEN] Create BOM for the item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);

        // [GIVEN] Create Main Item with Replenishment System as Production Order.
        LibraryInventory.CreateItem(MainItem);

        // [GIVEN] Create Stockkeeping Unit for Main Item and Location.
        Commit();
        LibraryVariableStorage.Enqueue(Location.Code);
        ItemCard.OpenView();
        ItemCard.GotoRecord(MainItem);
        ItemCard."&Create Stockkeeping Unit".Invoke();
        ItemCard.OK().Invoke();

        // [GIVEN] Modify Stockkeeping Unit Created for Main Item.
        SKUCardPage.OpenView();
        SKUCardPage.Filter.SetFilter("Item No.", MainItem."No.");
        SKUCardPage.Filter.SetFilter("Location Code", Location."Code");
        SKUCardPage."Replenishment System".SetValue("Replenishment System"::"Prod. Order");
        SKUCardPage."Reordering Policy".SetValue("Reordering Policy"::"Lot-for-Lot");
        SKUCardPage."Manufacturing Policy".SetValue("Manufacturing Policy"::"Make-to-Stock");
        SKUCardPage."Production BOM No.".SetValue(ProductionBOMHeader."No.");
        SKUCardPage.Close();

        // [WHEN] Create Sales order for Item and Location.
        Librarysales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', MainItem."No.", 10, Location."Code", WorkDate());

        // [WHEN] Calculate regenerative plan in planning worksheet update Planning Worksheet.
        CalculateRegenerativePlanningWorksheet(CompItem, MainItem, WorkDate(), CalcDate('<1Y>', WorkDate()), true, false);

        // [THEN] Verify Actual Count Match with Expected Result for Main Item Planning Worksheet Line.
        CountPlanningWorksheetLine(Requisitionline, ActualCount, MainItem."No.", Location."Code");
        Assert.AreEqual(1, ActualCount, MainItemErr);

        // [THEN] Verify Actual Count Match with Expected Result for Component Item Planning Worksheet Line.
        CountPlanningWorksheetLine(Requisitionline, ActualCount, CompItem."No.", Location."Code");
        Assert.AreEqual(1, ActualCount, CompoItemErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM PS Bugs-I");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM PS Bugs-I");

        NoSeriesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM PS Bugs-I");
    end;

    local procedure AutoReserveSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        // Auto Reserve.
        FindSalesLine(SalesHeader, SalesLine);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CalculateRegenerativePlan(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-1M>', WorkDate()), CalcDate('<-1M>', WorkDate()));
    end;

    local procedure CarryOutActMsgPlanFirmPlanAndPrint(var RequisitionLine: Record "Requisition Line")
    var
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        NewTransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
        NewAsmOrderChoice: Option " ","Make Assembly Orders","Make Assembly Orders & Print";
    begin
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
        LibraryPlanning.CarryOutPlanWksh(
          RequisitionLine, NewProdOrderChoice::"Firm Planned & Print", NewPurchOrderChoice::" ", NewTransOrderChoice::" ", NewAsmOrderChoice::" ", '', '',
          '', '');
    end;

    local procedure CarryOutActMsgPlan(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    var
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        NewTransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
        NewAsmOrderChoice: Option " ","Make Assembly Orders","Make Assembly Orders & Print";
    begin
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutPlanWksh(
          RequisitionLine, NewProdOrderChoice::Planned, NewPurchOrderChoice::" ", NewTransOrderChoice::" ", NewAsmOrderChoice::" ", '', '',
          '', '');
    end;

    local procedure CreateAndModifyItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ItemTrackingCode: Code[10]; LotNos: Code[20]; ProductionBOMHeaderNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Lot Nos.", LotNos);
        Item.Validate("Production BOM No.", ProductionBOMHeaderNo);
        Item.Modify(true);
    end;

    local procedure CreateAndModifyItemJournalLine(JournalTemplateName: Code[10]; ItemJournalBatchName: Code[10]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, JournalTemplateName, ItemJournalBatchName, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndModifyItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateAndModifyLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateAndModifyProductionBOM(BaseUnitofMeasure: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitofMeasure);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, LibraryRandom.RandInt(10));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; Quantity: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournal: TestPage "Item Journal";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        CreateAndModifyItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemNo2, LocationCode, Quantity);
        CreateAndModifyItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemNo, LocationCode, Quantity);
        Commit();  // Due to a limitation in Page Testability, COMMIT is needed in this case.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        ItemJournal.ItemTrackingLines.Invoke();
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJrnl(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostWareHouseInventoryActivity(ProductionOrderSourceNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Integer): Code[20]
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeader.SetRange("Destination No.", ProductionOrderSourceNo);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SetRange("Item No.", ItemNo2);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Delete();
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
        exit(WarehouseActivityHeader."Source No.");
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderComponents.OpenView();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo2);
        ProdOrderComponents.ItemTrackingLines.Invoke();
        ProductionOrder.CreateInvtPutAwayPick();
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ManufacturingPolicy: Enum "Manufacturing Policy"; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        // Random values used are not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, CostingMethod, LibraryRandom.RandDec(50, 2) + LibraryRandom.RandDec(10, 2), ReorderingPolicy,
          Item."Flushing Method", RoutingNo, ProductionBOMNo);

        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate(Description, LibraryUtility.GenerateRandomXMLText(MaxStrLen(Item.Description)));
        Item.Modify(true);
    end;

    local procedure CreateItemWithItemReference(var ItemReference: Record "Item Reference"; RefType: Enum "Item Reference Type"; RefTypeNo: Code[30])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", RefType, RefTypeNo);
        ItemReference.Validate(Description, LibraryUtility.GenerateGUID());
        ItemReference.Modify(true);
    end;

    local procedure CreateItemAndSalesOrder(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateItem(
          Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          ReplenishmentSystem);
        UpdateItem(Item, Item."Flushing Method", Item."Reordering Policy"::"Fixed Reorder Qty.", LibraryRandom.RandInt(10));
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, Item."No.", Item.Inventory);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random values used are important for test.Calculate calendar.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
    end;

    local procedure CreateProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProdBOMUpdateInventory(var ProductionBOMHeader: Record "Production BOM Header")
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemNo: Code[20];
    begin
        CreateItem(
          Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::"Prod. Order");
        ItemNo := Item."No.";
        Clear(Item);
        CreateItem(
          Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Stock", Item."Reordering Policy",
          Item."Replenishment System");
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo, Item."No.", 1); // Value important for Test.

        // Update Production BOM Inventory.
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(100) + 100);
        CreateAndPostItemJrnl(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100) + 100);
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line")
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", LibraryInventory.CreateItemNo());
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandInt(10));
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateProductionFamily(var Family: Record Family; Item: Record Item; Item2: Record Item)
    var
        FamilyLine: Record "Family Line";
    begin
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", LibraryRandom.RandInt(100));
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item2."No.", LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with One Item Line.Random values used are not important for test.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
        UpdateDirectUnitCostPurchaseLine(PurchaseLine, DirectUnitCost);
        UpdateVendorInvoiceNoPurchaseHeader(PurchaseHeader);
    end;

    local procedure CreateRefreshRelProdOrder(var ProductionOrder: Record "Production Order"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; LocationCode: Code[10]): Code[20]
    begin
        // Random values used are not important for test.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, SourceType, SourceNo, LibraryRandom.RandInt(5));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);

        // Refresh Production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        exit(ProductionOrder."No.");
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; TemplateType: Enum "Req. Worksheet Template Type")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", TemplateType);
        RequisitionWkshName.FindFirst();

        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random is used, values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header"; FlushingMethod: Enum "Flushing Method")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        CreateWorkCenter(WorkCenter, FlushingMethod);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
    end;

    local procedure CreateSKUAndUpdateUnitCost(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);

        // Update SKU Unit Cost.Random values used are not important for test.
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.FindFirst();
        StockkeepingUnit.Validate("Unit Cost", StockkeepingUnit."Unit Cost" + LibraryRandom.RandDec(10, 2));
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);
    end;

    local procedure MockProdOrderRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; FlushingMethod: Enum "Flushing Method")
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := ProdOrderLine.Status;
        ProdOrderRoutingLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ProdOrderRoutingLine."Routing Reference No." := ProdOrderLine."Line No.";
        ProdOrderRoutingLine."Routing No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine."Flushing Method" := FlushingMethod;
        ProdOrderRoutingLine.Insert();
    end;

    local procedure MockWhsePickForProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."Source Type" := DATABASE::"Prod. Order Component";
        WarehouseActivityLine."Source Subtype" := ProdOrderComponent.Status.AsInteger();
        WarehouseActivityLine."Source No." := ProdOrderComponent."Prod. Order No.";
        WarehouseActivityLine."Source Line No." := ProdOrderComponent."Prod. Order Line No.";
        WarehouseActivityLine."Source Subline No." := ProdOrderComponent."Line No.";
        WarehouseActivityLine."Qty. Outstanding (Base)" := ProdOrderComponent."Remaining Qty. (Base)";
        WarehouseActivityLine.Insert();
    end;

    local procedure MockInvtPickForProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::"Invt. Pick";
        WarehouseActivityLine."Source Type" := DATABASE::"Prod. Order Component";
        WarehouseActivityLine."Source Subtype" := ProdOrderComponent.Status.AsInteger();
        WarehouseActivityLine."Source No." := ProdOrderComponent."Prod. Order No.";
        WarehouseActivityLine."Source Line No." := ProdOrderComponent."Prod. Order Line No.";
        WarehouseActivityLine."Source Subline No." := ProdOrderComponent."Line No.";
        WarehouseActivityLine."Qty. Outstanding (Base)" := ProdOrderComponent."Remaining Qty. (Base)";
        WarehouseActivityLine."Action Type" := WarehouseActivityLine."Action Type"::Take;
        WarehouseActivityLine.Insert();
    end;

    local procedure DeleteProdOrderLine(ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindLast();
        ProdOrderLine.Delete(true);
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindSet();
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; BuyfromVendorNo: Code[20])
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure GetInventoryValue(ItemNo: Code[20]): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        exit(ItemJournalLine."Inventory Value (Calculated)");
    end;

    local procedure GetSalesOrder(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    var
        SalesLine: Record "Sales Line";
        GetSalesOrders: Report "Get Sales Orders";
        NewRetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        SalesLine.SetRange("No.", No);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 1);  // value used is important for test.
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(NewRetrieveDimensionsFrom::Item);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.Run();
    end;

    local procedure VerifyPrintedProdOrders(var ProductionOrder: Record "Production Order")
    begin
        LibraryReportDataset.AssertElementWithValueExists('Production_Order__No__', ProductionOrder."No.");
        LibraryReportDataset.GetNextRow();
    end;

    local procedure SetupReportSelections(ReportSelectionUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelectionUsage);
        ReportSelections.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Validate(Usage, ReportSelectionUsage);
        ReportSelections.Validate(Sequence, LibraryRandom.RandText(2));
        ReportSelections.Validate("Report ID", ReportId);
        ReportSelections.Insert(true);
    end;

    local procedure ItemReferenceSetup(var PurchaseLine: Record "Purchase Line"; var ItemReference: Record "Item Reference"; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[10]; VariantExist: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // Update Sales Setup. Create Item and Item Variant. Create Item Reference.
        // Random values used are not important for test.

        CreateItem(
          Item, Item."Costing Method", '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::"Prod. Order");
        if VariantExist then
            LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreatePurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandInt(100), Item."Unit Cost");
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", ReferenceType, ReferenceTypeNo);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ProdOrderLineQuantity(UOMExist: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        TempItem: Record Item temporary;
        ProductionBOMHeader: Record "Production BOM Header";
        Family: Record Family;
        ProdOrderNo: Code[20];
    begin
        // 1. Setup : Update Sales and Inventory Setup.Create Finished Item.
        // Create alternate unit of measure and attach the same to Item.Create second Finished Item.

        CreateProdBOMUpdateInventory(ProductionBOMHeader);
        CreateItem(
          Item, Item."Costing Method"::Standard, '', ProductionBOMHeader."No.", Item."Manufacturing Policy", Item."Reordering Policy",
          Item."Replenishment System"::"Prod. Order");
        if UOMExist then
            LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        TransferItemToTemp(TempItem, Item);
        CreateProdBOMUpdateInventory(ProductionBOMHeader);
        CreateItem(
          Item, Item."Costing Method"::Standard, '', ProductionBOMHeader."No.", Item."Manufacturing Policy", Item."Reordering Policy",
          Item."Replenishment System"::"Prod. Order");

        // Create Family and Update unit of measure with alternate unit of measure.
        // Create and Refresh Released Production Order.Refresh it.
        CreateProductionFamily(Family, TempItem, Item);
        if UOMExist then
            UpdateFamilyUOM(Family."No.", TempItem."No.", ItemUnitOfMeasure.Code);
        ProdOrderNo := CreateRefreshRelProdOrder(ProductionOrder, ProductionOrder."Source Type"::Family, Family."No.", '');

        // 3. Verify : Family Quantity with Production Order line Quantity.
        VerifyFamilyProdOrderQuantity(ProdOrderNo, Family."No.");
    end;

    local procedure TransferItemToTemp(var TempItem: Record Item temporary; var Item: Record Item)
    begin
        Item.SetRange("No.", Item."No.");
        Item.FindFirst();
        TempItem := Item;
        TempItem.Insert();
    end;

    local procedure UpdateDirectUnitCostPurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateFamilyUOM(FamilyNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        FamilyLine: Record "Family Line";
    begin
        FamilyLine.SetRange("Family No.", FamilyNo);
        FamilyLine.SetRange("Item No.", ItemNo);
        FamilyLine.FindFirst();
        FamilyLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        FamilyLine.Modify(true);
    end;

    local procedure UpdateItem(var Item: Record Item; FlushingMethod: Enum "Flushing Method"; ReorderingPolicy: Enum "Reordering Policy"; ReorderQuantity: Decimal)
    begin
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Modify(true);
    end;

    local procedure UpdateItemReference(var PurchaseLine: Record "Purchase Line"; ItemReferenceNo: Code[20])
    begin
        PurchaseLine.Validate("Item Reference No.", ItemReferenceNo);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateOutputJrnl(ProdOrderNo: Code[20]; StartingTime: Time)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order No.", ProdOrderNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Starting Time", StartingTime);
            ItemJournalLine.Validate("Ending Time", StartingTime - LibraryRandom.RandInt(LibraryUtility.ConvertHoursToMilliSec(1)));
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure UpdateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Variant Code", VariantCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdatePurchaseOrderDirectCost(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Random values used are not important for test.
        PurchaseHeader.Validate(Status, PurchaseHeader.Status::Open);
        UpdateVendorInvoiceNoPurchaseHeader(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        UpdateDirectUnitCostPurchaseLine(PurchaseLine, PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(10, 2));
    end;

    local procedure UpdateReqLine(var RequisitionLine: Record "Requisition Line"; VendorNo: Code[20]; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateSalesLine(SalesHeader: Record "Sales Header"; ItemReferenceNo: Code[20]; PurchasingCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Validate("Item Reference No.", ItemReferenceNo);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyFamilyProdOrderQuantity(ProdOrderNo: Code[20]; FamilyNo: Code[20])
    var
        FamilyLine: Record "Family Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ExpProdOrderQuantity: Decimal;
        ActualProdOrderQuantity: Decimal;
    begin
        FindProdOrderLine(ProdOrderLine, ProdOrderNo, ProductionOrder.Status::Released);
        repeat
            ItemUnitOfMeasure.Get(ProdOrderLine."Item No.", ProdOrderLine."Unit of Measure Code");
            ActualProdOrderQuantity += ProdOrderLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure";
        until ProdOrderLine.Next() = 0;
        ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo);
        FamilyLine.SetRange("Family No.", FamilyNo);
        FamilyLine.FindSet();
        repeat
            ItemUnitOfMeasure.Get(FamilyLine."Item No.", FamilyLine."Unit of Measure Code");
            ExpProdOrderQuantity += ProductionOrder.Quantity * FamilyLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure";
        until FamilyLine.Next() = 0;
        Assert.AreEqual(ExpProdOrderQuantity, ActualProdOrderQuantity, ErrMessageCostNotSame);
    end;

    local procedure VerifyItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Integer)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyProdComponentUnitCost(Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; UnitCost: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpComponentCost: Decimal;
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindSet();
        repeat
            ExpComponentCost += ProdOrderComponent."Unit Cost";
        until ProdOrderComponent.Next() = 0;
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(UnitCost, ExpComponentCost, GeneralLedgerSetup."Amount Rounding Precision", ErrMessageCostNotSame);
    end;

    local procedure VerifyTotalWIPAccountAmount(ItemNo: Code[20]; ProdOrderNo: Code[20])
    var
        Item: Record Item;
        GLEntry: Record "G/L Entry";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        TotalAmount: Decimal;
    begin
        // Select GL Entry of Production Order for WIP Account and Total the same.
        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."WIP Account");
        GLEntry.SetRange("Document No.", ProdOrderNo);
        if GLEntry.FindSet() then
            repeat
                TotalAmount += GLEntry.Amount;
            until GLEntry.Next() = 0;

        // Verify Total WIP Account amount is Zero.
        Assert.AreEqual(0, TotalAmount, ErrMessageNotFoundZeroAmt);
    end;

    local procedure VerifyValueEntry(ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValueEntryActCost: Decimal;
    begin
        ValueEntry.SetRange("Document No.", ProdOrderNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindSet();
        repeat
            ValueEntryActCost += ValueEntry."Cost Amount (Expected)";
        until ValueEntry.Next() = 0;

        ProductionOrder.Get(ProductionOrder.Status::Finished, ProdOrderNo);
        Item.Get(ItemNo);
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          ProductionOrder.Quantity * Item."Unit Cost", ValueEntryActCost, GeneralLedgerSetup."Amount Rounding Precision",
          ErrMessageCostNotSame);
    end;

    local procedure CreateRequisitionLineForItemAndLocation(var ReqLineInPlanWksh: Record "Requisition Line"; var RequisitionWkshName: Record "Requisition Wksh. Name"; ItemNo: Code[20]; LocationCode: Code[10]; var DueDate: Date)
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(ReqLineInPlanWksh, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        ReqLineInPlanWksh.Validate(Type, ReqLineInPlanWksh.Type::Item);
        ReqLineInPlanWksh.Validate("No.", ItemNo);
        ReqLineInPlanWksh.Validate("Accept Action Message", true);
        ReqLineInPlanWksh.Validate("Location Code", LocationCode);
        ReqLineInPlanWksh.Validate(Quantity, 1);
        ReqLineInPlanWksh.SetCurrFieldNo(ReqLineInPlanWksh.FieldNo("Due Date"));
        ReqLineInPlanWksh.Validate("Due Date", WorkDate());
        ReqLineInPlanWksh.Modify(true);
        DueDate := ReqLineInPlanWksh."Due Date";
    end;

    local procedure VerifyPlannedProdOrderDueDate(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; DueDate: Date)
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();

        Assert.AreEqual(DueDate, ProductionOrder."Due Date", DueDateErr);
    end;

    local procedure CountPlanningWorksheetLine(Requisitionline: Record "Requisition Line"; var ActualCount: Integer; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        Clear(ActualCount);
        Requisitionline.Reset();
        Requisitionline.SetRange("No.", ItemNo);
        Requisitionline.SetRange("Location Code", LocationCode);
        if Requisitionline.FindSet() then
            ActualCount := Requisitionline.Count;
    end;

    local procedure CalculateRegenerativePlanningWorksheet(var CompItemRec: Record Item; var MainItemRec: Record Item; OrderDate: Date; ToDate: Date; RespectPlanningParameters: Boolean; Regenerative: Boolean)
    var
        TmpItemRec: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);  // Find Requisition Worksheet Name to Calculate Plan.
        Commit();
        CalculatePlanPlanWksh.InitializeRequest(OrderDate, ToDate, RespectPlanningParameters, true, true, '', 0D, false);
        CalculatePlanPlanWksh.SetTemplAndWorksheet(RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, Regenerative);
        TmpItemRec.SetFilter("No.", '%1..%2', CompItemRec."No.", MainItemRec."No.");
        CalculatePlanPlanWksh.SetTableView(TmpItemRec);
        CalculatePlanPlanWksh.UseRequestPage(false);
        CalculatePlanPlanWksh.RunModal();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MSG_Change_Status_Q) > 0, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerAsTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ManagedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPutawayPickMvmtRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure FirmPlannedProdOrderMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MSG_Firm_Planned_Prod) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemtrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemtrackingLines."Assign Lot No.".Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandler(var CreateOrderFromSales: Page "Create Order From Sales"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OutputJournalItemLookupHandler(var ProdOrderLineList: TestPage "Prod. Order Line List")
    begin
        ProdOrderLineList.First();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;

    [ReportHandler]
    procedure ProductionOrderSaveAsXML(var AsmOrder: Report "Prod. Order - List")
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryReportDataset.RunReportAndLoad(Report::"Prod. Order - List", ProductionOrder, '');
    end;

    [RequestPageHandler]
    procedure SKURequestPageHandler(var CreateStockkeepingUnit: TestRequestPage "Create Stockkeeping Unit")
    var
        LocationCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(LocationCode);
        CreateStockkeepingUnit.Item.SetFilter("Location Filter", LocationCode);
        CreateStockkeepingUnit.OK().Invoke();
    end;
}
