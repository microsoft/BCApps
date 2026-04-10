codeunit 137612 "SCM Costing Rollup Sev 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryERM: Codeunit "Library - ERM";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        UnexpectedValueMsg: Label 'Unexpected %1 value in %2.';
        CalcStdCostOptionTxt: Label '&Top level,&All levels';
        MissingQst: Label '\\  * Some output is still missing.\  * Some consumption is still missing.';
        RunAdjCostMsg: Label 'You must run the Adjust Cost - Item Entries batch job once to adjust these.';
        ItemFilterTok: Label '%1|%2|%3';
        isInitialized: Boolean;
        InvCostMustBeZeroErr: Label 'Total cost amount must be 0 after correction.';
        ReverseCapacityLedgerEntryForSubContractingErr: Label 'Entry cannot be reversed as it is linked to the subcontracting work center.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Rollup Sev 2");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 2");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 2");
    end;

    [Test]
    [HandlerFunctions('RunAdjustCostMsgHandler,CalculateStdCostHandler,MissingOutputConfirmHandler')]
    [Scope('OnPrem')]
    procedure Test_B208054_AdjustAlways()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();

        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Always);
        InventorySetup.Modify(true);
        // Avoid instability due to message appearing only if Automatic Cost Adjustment was not already set to Always
        Message(RunAdjCostMsg);
        B208054(true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostHandler,MissingOutputConfirmHandler')]
    [Scope('OnPrem')]
    procedure Test_B208054_AdjustNever()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();

        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Never);
        InventorySetup.Modify(true);
        B208054(false);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure B208054(AutoCostAdjustAlways: Boolean)
    var
        CompItem: Record Item;
        ParentItem: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ParSecItemUnitOfMeasure: Record "Item Unit of Measure";
        CompSecItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
    begin
        // This test automates the exact bug repro
        // Numbers have not been randomized because they introduce instability in the test

        // Create component
        CreateItemWithAdditionalUOM_FixedVal(CompItem, CompSecItemUnitOfMeasure, CompItem."Costing Method"::FIFO, 0.01188, 8.77193);

        // Create parent
        CreateItemWithAdditionalUOM_FixedVal(ParentItem, ParSecItemUnitOfMeasure, CompItem."Costing Method"::Standard, 0, 200);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ParentItem."Replenishment System" := ParentItem."Replenishment System"::"Prod. Order";
        ParentItem.Modify();

        // Create Production BOM with Scrap
        CreateProductionBOM(ProductionBOMHeader, ParentItem, CompItem, ParentItem."Base Unit of Measure", '', 1, 10);

        // Create Work Center
        CreateWorkCenter_FixedCost(WorkCenter, 0.07174, 0.00381);

        // Create Routing
        LibraryManufacturing.CreateRoutingforWorkCenter(RoutingHeader, ParentItem, WorkCenter."No.");

        // Standard Cost calculate
        CalculateStdCost.CalcItem(ParentItem."No.", false);

        // Receive Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CompItem, '', '', 2600, WorkDate(), 0.47754);
        PurchaseLine.Validate("Unit of Measure Code", CompSecItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Direct Unit Cost", 0.47754);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Create Released Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem, '', '', 10000, WorkDate());
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // Post Output
        LibraryManufacturing.POSTOutputWithItemTracking(ProdOrderLine, 2400, 2400, WorkDate(), ParentItem."Standard Cost", '', 'A');
        LibraryManufacturing.POSTOutputWithItemTracking(ProdOrderLine, 1200, 1200, WorkDate(), ParentItem."Standard Cost", '', 'A');
        LibraryManufacturing.POSTOutputWithItemTracking(ProdOrderLine, 3600, 3600, WorkDate(), ParentItem."Standard Cost", '', 'B');
        LibraryManufacturing.POSTOutputWithItemTracking(ProdOrderLine, 2600, 2600, WorkDate(), ParentItem."Standard Cost", '', 'C');
        LibraryManufacturing.POSTOutputWithItemTracking(ProdOrderLine, 33, 33, WorkDate(), ParentItem."Standard Cost", '', 'D');
        LibraryManufacturing.POSTOutputWithItemTracking(ProdOrderLine, 69, 69, WorkDate(), ParentItem."Standard Cost", '', 'E');

        // Post Consumption
        LibraryManufacturing.POSTConsumption(ProdOrderLine, CompItem, '', '', ProductionOrder.Quantity, WorkDate(), CompItem."Unit Cost");

        // Change Prod. Order status
        LibraryVariableStorage.Enqueue(MissingQst);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Create and post sales order
        CreateAndPostSalesOrderWithItemTracking(ParentItem, ParSecItemUnitOfMeasure.Code);
        if not AutoCostAdjustAlways then
            LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ParentItem."No.", CompItem."No."), '');

        // Change Cost and invoice purch. order
        PurchaseHeader.Find('=');
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Find('=');
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" - 0.00001);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        if not AutoCostAdjustAlways then
            LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ParentItem."No.", CompItem."No."), '');

        LibraryCosting.CheckAdjustment(ParentItem);
        LibraryCosting.CheckAdjustment(CompItem);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B114689()
    var
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ValueEntry: Record "Value Entry";
        OutputQty: Decimal;
        QtyPer: Decimal;
        OutputQtyToReverse: Decimal;
        UnitCost: Decimal;
    begin
        // Workitem 339242, PS 53689.
        // Prepare Inventory Setup.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');
        OldInventorySetup.Get();
        UpdateInventorySetup(InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Set quantities and costs.
        OutputQty := LibraryRandom.RandIntInRange(11, 20);
        QtyPer := LibraryRandom.RandInt(10);
        OutputQtyToReverse := LibraryRandom.RandIntInRange(2, OutputQty - 1);
        UnitCost := LibraryRandom.RandInt(100);

        // Prepare reference data.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, UnitCost);
        LibraryInventory.CreateItemSimple(CompItem, Item."Costing Method"::FIFO, UnitCost);
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, Item, CompItem, QtyPer, '');

        // Add inventory for the component.
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CompItem, Location.Code, '', OutputQty * QtyPer, WorkDate(), UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Post multiple batches of output.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item, Location.Code, '', OutputQty, WorkDate());
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.POSTOutput(ProdOrderLine, OutputQtyToReverse, WorkDate(), Item."Unit Cost");
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        LibraryManufacturing.POSTOutput(ProdOrderLine, OutputQty - OutputQtyToReverse, WorkDate(), Item."Unit Cost");

        // Revert first output using application.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), -OutputQtyToReverse, Item."Unit Cost");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Applies-to Entry", TempItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Finish the production order.
        LibraryManufacturing.POSTConsumption(ProdOrderLine, CompItem, Location.Code, '', (OutputQty - OutputQtyToReverse) * QtyPer,
          WorkDate(), CompItem."Unit Cost");
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);

        // Invoice component at a different cost.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Direct Unit Cost", UnitCost + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Verify: No rounding entry is generated.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        Assert.IsTrue(ValueEntry.IsEmpty, 'Rounding entry found for item ' + Item."No.");

        // Tear down.
        UpdateInventorySetup(InventorySetup, OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment",
          OldInventorySetup."Average Cost Calc. Type", OldInventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B208116_ZeroPurchaseCost()
    begin
        // Bug: 208116
        // Post Value Entry to G/L is correct with Zero Cost - Purchase and Verify Quantity, Actual/Expected Cost in Item Ledger Entry.
        Initialize();
        PostValueEntryToGLWithZeroCost();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B208116_ZeroCostACYCostAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Bug: 208116
        // This test case verifies Post Value Entry to G/L and ACY Cost Amount is correct with Zero costs in Purchase transaction.

        // Setup: Create Currency and updated then same on General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateAddCurrencySetup(CreateCurrency());
        PostValueEntryToGLWithZeroCost();

        // Tear Down: Rollback Inventory Setup.
        UpdateAddCurrencySetup(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure PostValueEntryToGLWithZeroCost()
    var
        Item: Record Item;
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        Component: Code[20];
        Component2: Code[20];
        Quantity: Decimal;
        ProductionQuantity: Decimal;
    begin
        // Bug: 208116
        // This test case verifies Post Value Entry to G/L and ACY Cost Amount is correct with Zero costs in Purchase transaction.

        // Setup: Create Purchase Order for Production and Component Item. Post as Receive.
        OldInventorySetup.Get();
        Quantity := 10 + LibraryRandom.RandInt(100);  // Using Random value for Quantity.
        ProductionQuantity := LibraryRandom.RandInt(Quantity);  // Using Random value of Quantity for Production Quantity.
        ItemNo :=
          CreateItem(
            Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandDec(10, 2),
            Item."Order Tracking Policy"::None);
        Component :=
          CreateItem(
            Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase, 0,
            Item."Order Tracking Policy"::None);
        Component2 :=
          CreateItem(
            Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase, 0,
            Item."Order Tracking Policy"::None);

        // Added Production BOM No. on Item.
        Item.Get(ItemNo);
        Item.Validate(
          "Production BOM No.", LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Component, Component2, 1));
        Item.Modify(true);
        UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Component, Quantity);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Component2, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Create Production Order, Refresh, Post Production Jounral and change status from Release to Finish.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, ProductionQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
        PostProductionJournal(ProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Exercise: Run Adjust Cost Item Entries report.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo(ItemFilterTok, ItemNo, Component, Component2), '');

        // Verify: Verify Quantity Expected/Actual Cost ACY for Component Item in Item Ledger Entry.
        VerifyItemLedgerEntry(Component, true, Quantity);
        VerifyItemLedgerEntry(Component, false, -ProductionQuantity);

        // Tear Down: Rollback Inventory Setup.
        UpdateInventorySetup(
          InventorySetup, OldInventorySetup."Automatic Cost Posting", OldInventorySetup."Expected Cost Posting to G/L",
          OldInventorySetup."Automatic Cost Adjustment", OldInventorySetup."Average Cost Calc. Type",
          OldInventorySetup."Average Cost Period");
    end;

    [Normal]
    local procedure DeleteApplOnPurchReturnOrder(Serial: Boolean; Lot: Boolean; TrackingOption: Option)
    var
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify there is no error when posting unapplied Purchase Return Order with serial/lot numbers.
        // VSTF: 212797.

        // Setup: Update Inventory Setup and Purchase Payable Setup.
        Initialize();
        OldInventorySetup.Get();
        UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true);

        // Create and post Purchase Order, Create Purchase Return Order.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(Serial, Lot));
        CreateAndPostPurchaseOrderWithIT(PurchaseHeader, Item."No.", TrackingOption);

        CreatePurchRetOrderGetPstdDocLineToRev(
          PurchaseHeader, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."No.", Item."No.");
        UpdateApplyToItemEntryOnPurchLine(PurchaseLine, PurchaseHeader."No.");

        // Exercise: Post Purchase Return Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: No error when posting. Resulting value entries are unapplied.
        VerifyValueEntryNoApplication(Item."No.");

        // Tear Down.
        UpdateInventorySetup(
          InventorySetup, OldInventorySetup."Automatic Cost Posting", OldInventorySetup."Expected Cost Posting to G/L",
          OldInventorySetup."Automatic Cost Adjustment", OldInventorySetup."Average Cost Calc. Type",
          OldInventorySetup."Average Cost Period");
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B235243_ApplyToPurchReturnOrder()
    var
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error while posting Purchase Return Order when Apply to Item Entry is Zero using Get Posted Document Lines to Reverse.

        // Setup: Update Inventory Setup and Purchase Payable Setup.
        Initialize();
        OldInventorySetup.Get();
        UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true);

        CreateAndPostPurcOrderThenCreatePurchReturnOrder(Item, PurchaseHeader, PurchaseLine);

        // Exercise: Post Purchase Return Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify error while posting Purchase Return Order when Apply to Item Entry is Zero.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Appl.-to Item Entry"), '');

        // Tear Down.
        UpdateInventorySetup(
          InventorySetup, OldInventorySetup."Automatic Cost Posting", OldInventorySetup."Expected Cost Posting to G/L",
          OldInventorySetup."Automatic Cost Adjustment", OldInventorySetup."Average Cost Calc. Type",
          OldInventorySetup."Average Cost Period");
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B235243_ApplyFromSalesReturnOrder()
    var
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify error while posting sales Return Order when Apply from Item Entry is Zero using Get Posted Document Lines to Reverse.

        // Setup: Update Inventory Setup and Sales Receivable Setup.
        Initialize();
        OldInventorySetup.Get();
        UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(true, SalesReceivablesSetup."Stockout Warning");

        // Create and post Sales order, create Sales Return Order.
        CreateAndPostSalesOrder(SalesHeader);
        CreateSalRetOrderGetPstdDocLineToRev(
          SalesHeader2, SalesHeader."Sell-to Customer No.", SalesHeader."No.");
        UpdateApplyFromItemEntryOnSalesLine(SalesLine, SalesHeader2."No.");

        // Exercise: Post Sales Return Order.
        asserterror LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Verify error while posting sales Return Order when Apply from Item Entry is Zero.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Appl.-from Item Entry"), '');

        // Tear Down.
        UpdateInventorySetup(
          InventorySetup, OldInventorySetup."Automatic Cost Posting", OldInventorySetup."Expected Cost Posting to G/L",
          OldInventorySetup."Automatic Cost Adjustment", OldInventorySetup."Average Cost Calc. Type",
          OldInventorySetup."Average Cost Period");
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory", SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B212797_Serial()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo;
    begin
        // VSTF: 212797.
        DeleteApplOnPurchReturnOrder(true, false, TrackingOption::AssignSerialNo);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B245050_252794_Lot()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo;
    begin
        // VSTF: 245050, 252794.
        DeleteApplOnPurchReturnOrder(false, true, TrackingOption::AssignLotNo);
    end;

    local procedure CreateAndPostPurcOrderThenCreatePurchReturnOrder(var Item: Record Item; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        CreateAndPostPurchaseOrder(
          PurchaseLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO));

        CreatePurchRetOrderGetPstdDocLineToRev(
          PurchaseHeader, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No.", PurchaseLine."No.");
        UpdateApplyToItemEntryOnPurchLine(PurchaseLine, PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B212797_Reservation()
    var
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        // Verify there is no error when posting unapplied Purchase Return Order with reservations.
        // VSTF: 212797.

        // Setup: Update Inventory Setup and Purchase Payable Setup.
        Initialize();
        OldInventorySetup.Get();
        UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true);

        CreateAndPostPurcOrderThenCreatePurchReturnOrder(Item, PurchaseHeader, PurchaseLine);

        ReservMgt.SetReservSource(PurchaseLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', WorkDate(), PurchaseLine.Quantity, PurchaseLine."Quantity (Base)");

        // Exercise: Post Purchase Return Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: No error when posting. Resulting value entries are unapplied.
        VerifyValueEntryNoApplication(PurchaseLine."No.");

        // Tear Down.
        UpdateInventorySetup(
          InventorySetup, OldInventorySetup."Automatic Cost Posting", OldInventorySetup."Expected Cost Posting to G/L",
          OldInventorySetup."Automatic Cost Adjustment", OldInventorySetup."Average Cost Calc. Type",
          OldInventorySetup."Average Cost Period");
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B231122_AdjUsingItemJournal()
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Verify Item Ledger Entry for Positive and Negative Adjustment and Item Application Entry.

        // Setup: Create Item and post Item Journal Line for Positive and Negative Adjustment.
        Initialize();
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, WorkDate() + 7, 0);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, WorkDate() + 4, LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, WorkDate() + 2, 0);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Exercise: Adjust cost item entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify Item Application Entry.
        LibraryCosting.CheckAdjustment(Item);
        VerifyItemApplicationEntry(TempItemLedgerEntry."Entry No.", TempItemLedgerEntry.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B231122_ACIEUsingItemJournal()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Verify Adjusted Cost Amount in Value Entry.

        // Setup: Create Item and Item Journal Line for Positive and Negative Adjustment.
        Initialize();
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemNo :=
          CreateItem(
            Item."Costing Method"::Average, Item."Replenishment System"::Purchase, LibraryRandom.RandDec(100, 2),
            Item."Order Tracking Policy"::None);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Taking Random Unit Cost.
        ItemJournalLine.Modify(true);

        CreateItemJournalLine(
          ItemJournalLine2, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine2."Entry Type"::"Negative Adjmt.", ItemNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Exercise:
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');  // Using blank value for Item Category.

        // Verify: Verify Adjusted Cost Amount in Value Entry.
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", Round(ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit"));
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B237877()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        Location: Record Location;
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        FirstOutputItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        QtyPer: Decimal;
    begin
        // Setup: Update Inventory Setup.
        Initialize();
        UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Create child Items with required Costing method and Inventory, create Production BOM.
        Quantity := LibraryRandom.RandInt(10);
        QtyPer := LibraryRandom.RandInt(5);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2));
        LibraryInventory.CreateItemSimple(Item2, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2));
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Item."No.", Item2."No.", QtyPer);

        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', LibraryRandom.RandInt(100), WorkDate(), Quantity * QtyPer);
        LibraryInventory.PostPositiveAdjustment(Item2, Location.Code, '', '', LibraryRandom.RandInt(100), WorkDate(), Quantity * QtyPer);

        // Create Parent item and attach Production BOM.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(10, 2), Item."Reordering Policy"::"Lot-for-Lot",
          Item."Flushing Method"::"Pick + Manual", '', ProductionBOMHeader."No.");

        // Create Production Order, Refresh and Post Production Journal.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item, Location.Code, '', Quantity, WorkDate());
        PostProductionJournal(ProductionOrder);

        // Create Output with negative qty, apply to existing item ledger entry for production item, post to make the Output Nil.
        SelectItemLedgerEntry(FirstOutputItemLedgerEntry, Item."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), -Quantity, Item."Unit Cost");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Applies-to Entry", FirstOutputItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post Output again with positive quantity, finish the Released Production Order and Adjust Cost.
        LibraryManufacturing.POSTOutput(ProdOrderLine, Quantity, WorkDate(), Item."Unit Cost");

        // Exercise: Finish Production Order and run Adjust Cost.
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);

        // Verify: Verify Cost Amount (Actual) for both positive and negative entries in Item Ledger Entry.
        Item.Get(Item."No.");
        VerifyItemLedgerCostAmount(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.", Quantity, Item."Unit Cost" * Quantity, true);
        VerifyItemLedgerCostAmount(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.", -Quantity, -Item."Unit Cost" * Quantity, false);

        // Create Revaluation Journal and apply to first ILE of production Item.
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
        LibraryInventory.MakeItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, WorkDate(), ItemJournalLine."Entry Type"::Purchase, 0);
        ItemJournalLine.Validate("Applies-to Entry", FirstOutputItemLedgerEntry."Entry No.");
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Calculated)" + LibraryRandom.RandInt(10));
        ItemJournalLine.Insert(true);

        // Exercise: Post Revaluation Journal with new Unit Cost for production item.
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Verify: Verify Cost Amount (Actual) for both positive and negative entries in Item Ledger Entry.
        VerifyItemLedgerCostAmount(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.", Quantity,
          ItemJournalLine."Unit Cost (Revalued)" * ItemJournalLine."Quantity (Base)", true);
        VerifyItemLedgerCostAmount(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.", -Quantity,
          -ItemJournalLine."Unit Cost (Revalued)" * ItemJournalLine."Quantity (Base)", false);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B242530_NegOutputBackwardFlushing()
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Parent and Child Items in Certified Production BOM. Update Backward Flushing method on child Item. Create and post Purchase Order for Child Item. Create and Refresh a Released Production Order.
        Initialize();
        OldInventorySetup.Get();
        UpdateInventorySetup(InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        CreateSetupFor242530(TempItemLedgerEntry, Item, ChildItem, ProductionOrder);

        // Exercise: Post the negative Output for the Production Order.
        CreateAndPostOutputJournalWithApplyEntry(TempItemLedgerEntry);

        // Verify: Verify the Cost Amount Actual as zero for Output Entry.
        VerifyValueEntry(Item."No.", ProductionOrder."No.", TempItemLedgerEntry."Entry Type"::Output, 0);

        // Tear down.
        UpdateInventorySetup(
          InventorySetup, OldInventorySetup."Automatic Cost Posting", OldInventorySetup."Expected Cost Posting to G/L",
          OldInventorySetup."Automatic Cost Adjustment", OldInventorySetup."Average Cost Calc. Type",
          OldInventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B242530_FinishRPOBackwardFlushing()
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        OldInventorySetup: Record "Inventory Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Parent and Child Items in Certified Production BOM. Update Backward Flushing method on child Item. Create and post Purchase Order for Child Item. Create and Refresh a Released Production Order.
        Initialize();
        OldInventorySetup.Get();
        UpdateInventorySetup(InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        CreateSetupFor242530(TempItemLedgerEntry, Item, ChildItem, ProductionOrder);
        ChildItem.CalcFields(Inventory);

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the Cost Amount Actual in Value Entry created.
        // We flushed the entire value of the component inventory.
        VerifyValueEntry(
          ChildItem."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Consumption,
          -ChildItem.Inventory * ChildItem."Unit Cost");
        VerifyValueEntry(Item."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Output, 0);

        // Tear down.
        UpdateInventorySetup(
          InventorySetup, OldInventorySetup."Automatic Cost Posting", OldInventorySetup."Expected Cost Posting to G/L",
          OldInventorySetup."Automatic Cost Adjustment", OldInventorySetup."Average Cost Calc. Type",
          OldInventorySetup."Average Cost Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B264328_PositiveAdj()
    var
        ReservEntry: Record "Reservation Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Amount: Decimal;
        Counter: Integer;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post ItemJournal with Positive Adjustment.
        Initialize();
        Quantity := 3;
        Amount := 10;
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false));
        // Exercise: Create and Post Item Journal line for Positive Adjmt. with Item Tracking.
        CreateItemJnlLinewFixQtyAndAmt(
          ItemJournalBatch, ItemJournalLine, Item, WorkDate(), ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, Amount);

        for Counter := 1 to 3 do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine,
              LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Serial No."), DATABASE::"Item Ledger Entry"), '', 1);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Verify: Verify Cost Amont(Actual) in Item Ledger Entry.
        VerifyILETotalCost(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", true, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B264328_Purchase()
    var
        ReservEntry: Record "Reservation Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Amount: Decimal;
        Counter: Integer;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post ItemJournal with Purchase.
        Initialize();
        Quantity := 3;
        Amount := 10;
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false));

        // Exercise: Create and Post Item Journal line for Positive Adjmt. with Item Tracking.
        CreateItemJnlLinewFixQtyAndAmt(
          ItemJournalBatch, ItemJournalLine, Item, WorkDate(), ItemJournalLine."Entry Type"::Purchase, Quantity, Amount);

        for Counter := 1 to 3 do
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine,
              LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Serial No."), DATABASE::"Item Ledger Entry"), '', 1);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Verify: Verify Cost Amont(Actual) in Item Ledger Entry.
        VerifyILETotalCost(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", true, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B264653()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry1: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        Qty: Decimal;
    begin
        // Verify Item Ledger Entries when Item Costing Method is Average and after applying Revalued Inbound Entry to Outbound.

        // Setup: Create Item,Create and Post Item Journal with Positive adjustment
        // Create and Post Revaluation Journal
        // Create Item Journal with Negative adjustment.

        Initialize();

        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        Qty := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(
          Item, Item."Costing Method"::Average, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandInt(10), '');
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Qty, WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', Qty, WorkDate() + 4, 0);

        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Qty, WorkDate() + 4, LibraryRandom.RandDec(100, 2));
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        LibraryInventory.CreateRevaluationJournalLine(
          ItemJournalBatch, Item, WorkDate() + 4, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Calculated)" + LibraryRandom.RandInt(10));
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        LibraryPatterns.POSTItemJournalLineWithApplication(
          ItemJournalBatch."Template Type"::Item, ItemLedgerEntry."Entry Type"::"Negative Adjmt.", Item, '', '',
          Qty, WorkDate() + 4, 0, TempItemLedgerEntry."Entry No.");

        // Exercise: Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify Item Ledger Entry.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Posting Date", WorkDate() + 4);
        ItemLedgerEntry.SetRange("Applies-to Entry", TempItemLedgerEntry."Entry No.");
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", false);

        ItemLedgerEntry.TestField(Quantity, -Qty);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry1.Get(TempItemLedgerEntry."Entry No.");
        ItemLedgerEntry1.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry."Cost Amount (Actual)" := Round(ItemLedgerEntry."Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", Round(-ItemLedgerEntry1."Cost Amount (Actual)"));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure B267677()
    var
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostingDate: Date;
    begin
        // Verify Value Entries for an Item which have zero Inventory after run the Adjust Cost Item Entries.
        // Fixed values are used to test for rounding error

        // Setup: Update Inventory Setup and Sales Receivable Setup.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(
          InventorySetup, true, InventorySetup."Expected Cost Posting to G/L", InventorySetup."Automatic Cost Adjustment",
          InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period"::Month);
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(true, SalesReceivablesSetup."Stockout Warning");

        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 966.26829);

        // Exercise
        PostingDate := WorkDate();
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', 41, PostingDate, 966.26829, true, true);

        PostingDate += 7;
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', 41, PostingDate, 10000, true, true);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();

        LibrarySales.CreateSalesReturnOrder(SalesHeader, SalesLine, Item, '', '', 41, PostingDate, 966.26829, 10000);
        SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        PostingDate += 7;
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', 41, PostingDate, 10000, true, true);

        PostingDate += 7;
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', 41, PostingDate, 966.26829, true, true);

        PostingDate += 7;
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', 41, PostingDate, 10000, true, true);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify
        LibraryCosting.CheckAdjustment(Item);

        // Teardown:
        UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory", SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure B343200_ACIE_ValuationDate()
    var
        InventorySetup: Record "Inventory Setup";
        ComponentItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJnlMgt: Codeunit "Production Journal Mgt";
    begin
        // [FEATURE] [Production] [Adjust Cost - Item Entries] [Valuation Date]
        // [SCENARIO 343200] verify that valuation date is not changed after ACIE for production order posted in 2 iterations on different dates

        Initialize();

        // [GIVEN] Update Inventory Setup: set Average Cost Period = Month
        SetAvgCostingPeriodInInvSetup(InventorySetup, InventorySetup."Average Cost Period"::Month);

        // [GIVEN] Create component item. Costing Method = Average, Replenishment System = Purchase
        CreateItemWithAvgCosting(ComponentItem, ComponentItem."Replenishment System"::Purchase);

        // [GIVEN] Create production item. Costing Method = Average, Replenishment System = Production order
        CreateItemWithAvgCosting(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        // [GIVEN] Create BOM and assign to the production item
        CreateProductionBOM(ProductionBOMHeader, ProdItem, ComponentItem, ProdItem."Base Unit of Measure", '', 1, 0);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] We need at least 2 components available for the production order
        LibraryInventory.PostItemJournalLine(
            "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Purchase,
             ComponentItem, '', '', '', 2, WorkDate(), ProdItem."Unit Cost");

        CreateReleaseProdOrderWithLine(ProdOrder, ProdOrderLine, ProdItem, 2);
        ProductionJnlMgt.InitSetupValues();
        ProductionJnlMgt.CreateJnlLines(ProdOrder, ProdOrderLine."Line No.");

        // [WHEN] Posting consumption and output in 2 iterations with a one day delay
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', 1, WorkDate(), ComponentItem."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, 1, WorkDate(), ProdItem."Unit Cost");
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, '', '', 1, CalcDate('<+1D>', WorkDate()), ComponentItem."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, 1, CalcDate('<+1D>', WorkDate()), ProdItem."Unit Cost");

        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrder."No.");

        LibraryCosting.AdjustCostItemEntries(ProdItem."No.", '');

        // [THEN] All valuation dates in output value entries are set to the latest posting date
        VerifyCostAmountOnValuationDate(ComponentItem."No.", ProdOrder."No.", WorkDate(), -ComponentItem."Unit Cost");
        VerifyCostAmountOnValuationDate(ComponentItem."No.", ProdOrder."No.", WorkDate() + 1, -ComponentItem."Unit Cost");
        VerifyCostAmountOnValuationDate(ProdItem."No.", ProdOrder."No.", WorkDate() + 1, ComponentItem."Unit Cost" * 2);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrderWithNonBaseUOM()
    var
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        ChildItem: Record Item;
        NonBaseItemUOM: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingLine: Record "Routing Line";
        Location: Record Location;
        RoutingLink: Record "Routing Link";
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test: PS 49588 (Vedbaek SE)  -  VSTF HF 211299
        Initialize();
        CustomizeSetupsAndLocation(Location);
        CreateManufacturingItems(ParentItem, NonBaseItemUOM, ChildItem);
        CreateRoutingSetup(WorkCenter, RoutingLine, RoutingLink);
        CreateProductionBOM(
          ProductionBOMHeader, ParentItem, ChildItem, NonBaseItemUOM.Code, RoutingLink.Code, LibraryRandom.RandDec(20, 2), 0);
        UpdateItemRoutingNo(ParentItem, RoutingLine."Routing No.");

        // Supply child item
        LibraryInventory.PostPositiveAdjustment(ChildItem, Location.Code, '', '',
          LibraryRandom.RandDec(125, 2), WorkDate(), LibraryRandom.RandDec(225, 2));

        // Create and refresh Released Production Order. Update new Unit Of Measure on Production Order Line.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", Location.Code);
        UpdateProdOrderLineUnitOfMeasureCode(ParentItem."No.", NonBaseItemUOM.Code);

        // Calculate subcontracts from subcontracting worksheet and create subcontracted purchase order
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(ParentItem."No.");

        SelectPurchaseOrderLine(PurchaseLine, ParentItem."No.");
        VerifyPurchaseOrderLine(PurchaseLine, NonBaseItemUOM, ParentItem."No.", Location.Code,
          ProductionOrder.Quantity, RoutingLine."Unit Cost per");

        // Post purchase header (only receipt)
        PurchaseHeader.SetCurrentKey("Document Type", "No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // Now post invoice
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        VerifyCapacityLedgerEntries(WorkCenter."No.", ParentItem."No.", ProductionOrder.Quantity,
          NonBaseItemUOM."Qty. per Unit of Measure", RoutingLine."Unit Cost per");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MsgHandler,ItemChargeAssignmentPurchPageHandler,PostedTransferReceiptLinePageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostForTransferAndItemChargeAssignment()
    var
        InventorySetup: Record "Inventory Setup";
        ComponentItem: Record Item;
        ProdItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        Quantity: Decimal;
        VendorNo: Code[20];
    begin
        // This test is verify that Value Entries are correct after posting transfer order and assign Item Charge with Average Cost Calc. Type = Item

        // Setup: Update Inventory Setup
        UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Create a production item
        CreateProdItemWithAvgCosting(ComponentItem, ProdItem);

        VendorNo := CreateVendor();
        Quantity := LibraryRandom.RandInt(10);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);

        // Create and Post Purchase Order
        CreatePurchaseDocWithDirectUnitCost(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          VendorNo, PurchaseLine.Type::Item, ComponentItem."No.", Quantity, FromLocation.Code);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create a Transfer Order
        CreateAndPostTransferOrder(ComponentItem."No.", FromLocation.Code, ToLocation.Code, Quantity);

        // Exercise: Create and Post Purchase Invoice with Assign Item Charge
        // Verify: Post successfully without error
        CreateAndPostPurchaseInvoiceWithAssignItemCharge(VendorNo, Quantity, ToLocation.Code, ComponentItem."No.");

        // Create a Release Production Order, update Location Code on Component line, post Production Journal, change Status to Finished
        CreateReleasedProdOrderAndChangeStatusToFinished(ProdItem, ComponentItem, Quantity, ToLocation.Code);

        // Exercise: Run Adjust Cost - Item Entries Batch job
        LibraryCosting.AdjustCostItemEntries(ComponentItem."No." + '|' + ProdItem."No.", '');

        // Verify: Verify Value Entries - Cost Amount Actual should contain the Item Charge adjust entry, the total should be zero.
        Assert.AreEqual(0, InventoryCostByItem(ComponentItem."No."), InvCostMustBeZeroErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure VerifyCapacityLedgerEntryMustNotBeReversedWhenSubcontractingIsTrue()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 562491] Verify Capacity Ledger Entry must not be reversed When "Subcontracting" is true on Capacity Ledger Entry.
        Initialize();

        // [GIVEN] Create an item.
        CreateItem(Item);

        // [GIVEN] Create Routing with Subcontracting.
        CreateRoutingAndUpdateItemSubcontracted(Item, WorkCenter, true);

        // [GIVEN] Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // [GIVEN] Calculate Subcontracting
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Accept and Carry Out Action Message on Subcontracting Worksheet.
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // [GIVEN] Post Purchase Order.
        PostPurchaseOrder(Item."No.", true, true);

        // [GIVEN] Find Capacity Ledger Entry.
        FindCapacityLedgerEntry(CapacityLedgerEntry, ProductionOrder."No.", WorkCenter."No.");

        // [WHEN] Reverse Capacity Ledger Entry.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        asserterror CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Capacity Ledger Entry must not be reversed When "Subcontracting" is true on Capacity Ledger Entry.
        Assert.ExpectedError(ReverseCapacityLedgerEntryForSubContractingErr);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,MsgHandler,YesConfirmHandler')]
    procedure VerifyReverseItemLedgerEntryShouldBeCreatedForConsumptionWhenReverseIsExecuted()
    var
        MfgSetup: Record "Manufacturing Setup";
        OutputItem: Record Item;
        CompItem: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 567053] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Consumption" when Reverse action is executed.
        // if there is production order with Routing with subcontracting.
        Initialize();

        // [GIVEN] Get "Manufacturing Setup".
        MfgSetup.Get();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(OutputItem, CompItem, LibraryRandom.RandIntInRange(1, 10));

        // [GIVEN] Create and Post Item Journal Line for Component item.
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(100, 200), '', MfgSetup."Components at Location");

        // [GIVEN] Create Routing with Subcontracting.
        CreateRoutingAndUpdateItemSubcontracted(OutputItem, WorkCenter, true);

        // [GIVEN] Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", LibraryRandom.RandIntInRange(1, 10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Document No.", ProductionOrder."No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Consumption));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Consumption".
        ItemLedgerEntry.Get(ItemLedgerEntries."Entry No.".AsInteger());
        FindLastItemLedgerEntry(ItemLedgerEntry, "Inventory Order Type"::Production, ProductionOrder."No.", ItemLedgerEntry."Order Line No.", "Item Ledger Entry Type"::Consumption);
        Assert.AreEqual(
            -ItemLedgerEntries.Quantity.AsInteger(),
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -ItemLedgerEntries.Quantity.AsInteger(), ItemLedgerEntry.TableCaption()));
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateAndPostSalesOrderWithItemTracking(var Item: Record Item; SecondUoMCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        FirstSalesLine: Record "Sales Line";
        SecondSalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(FirstSalesLine, SalesHeader, FirstSalesLine.Type::Item, Item."No.", 49);
        FirstSalesLine.Validate("Unit of Measure Code", SecondUoMCode);
        FirstSalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SecondSalesLine, SalesHeader, SecondSalesLine.Type::Item, Item."No.", 102);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, FirstSalesLine, '', 'A', 3600);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, FirstSalesLine, '', 'B', 3600);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, FirstSalesLine, '', 'C', 2600);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SecondSalesLine, '', 'D', 33);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SecondSalesLine, '', 'E', 69);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Normal]
    local procedure CustomizeSetupsAndLocation(var Location: Record Location)
    var
        InvtSetup: Record "Inventory Setup";
        MfgSetup: Record "Manufacturing Setup";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        UpdateInventorySetup(InvtSetup, true, true, InvtSetup."Automatic Cost Adjustment"::Always,
          InvtSetup."Average Cost Calc. Type"::Item,
          InvtSetup."Average Cost Period"::Day);
        LibraryManufacturing.UpdateManufacturingSetup(MfgSetup, '', Location.Code, true, true, true);
    end;

    local procedure CreateAndModifyItem(ReplenishmentSystem: Enum "Replenishment System"; CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(10, 2));  // Using Random value for Overhead Rate.
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 1));  // Using Random value for Standard Cost.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostOutputJournalWithApplyEntry(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", TempItemLedgerEntry."Document No.");
        ProdOrderLine.SetRange("Item No.", TempItemLedgerEntry."Item No.");
        ProdOrderLine.FindFirst();

        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), -TempItemLedgerEntry.Quantity, 0);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Applies-to Entry", TempItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateItem(CostingMethod: Enum "Costing Method"; ReplenishmentSystem: Enum "Replenishment System"; StandardCost: Decimal; OrderTrackingPolicy: Enum "Order Tracking Policy"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemSimple(Item, CostingMethod, StandardCost);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);

        exit(Item."No.");
    end;

    [Normal]
    local procedure CreateItemWithAdditionalUOM(var Item: Record Item; var NewItemUOM: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(NewItemUOM, Item."No.", LibraryRandom.RandDec(100, 2));
    end;

    [Normal]
    local procedure CreateItemWithAdditionalUOM_FixedVal(var Item: Record Item; var NewItemUOM: Record "Item Unit of Measure"; CostingMethod: Enum "Costing Method"; UnitCost: Decimal; QtyperUoM: Decimal)
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, UnitCost, 0, 0, '');
        LibraryInventory.CreateItemUnitOfMeasureCode(NewItemUOM, Item."No.", QtyperUoM);
    end;

    local procedure CreateItemWithAvgCosting(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        Item.Get(
            CreateItem(
                Item."Costing Method"::Average, ReplenishmentSystem, LibraryRandom.RandDec(10, 2),
                "Order Tracking Policy"::None));
    end;

    local procedure CreateItemTrackingCode(SNSpecific: Boolean; LOTSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LOTSpecific);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, JournalTemplateName, JournalBatchName, EntryType, ItemNo, LibraryRandom.RandInt(100));  // Taking Random Quantity.
    end;

    local procedure CreateItemJnlLinewFixQtyAndAmt(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; Item: Record Item; PostingDate: Date; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal; Amount: Decimal)
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.MakeItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, PostingDate, EntryType, Quantity);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Insert();
    end;

    local procedure CreateProdItemWithAvgCosting(var ComponentItem: Record Item; var ProdItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithAvgCosting(ComponentItem, ComponentItem."Replenishment System"::Purchase);
        CreateItemWithAvgCosting(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        CreateProductionBOM(ProductionBOMHeader, ProdItem, ComponentItem, ProdItem."Base Unit of Measure", '', 1, 0);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);
    end;

    [Normal]
    local procedure CreateManufacturingItems(var ParentItem: Record Item; var NonBaseItemUOM: Record "Item Unit of Measure"; var ChildItem: Record Item)
    begin
        CreateItemWithAdditionalUOM(ParentItem, NonBaseItemUOM);
        ParentItem.Validate("Costing Method", ParentItem."Costing Method"::Average);
        ParentItem.Modify(true);

        LibraryInventory.CreateItem(ChildItem);
        ChildItem.Validate("Costing Method", ChildItem."Costing Method"::Average);
        ChildItem.Validate("Replenishment System", ChildItem."Replenishment System"::Purchase);
        ChildItem.Validate("Flushing Method", ChildItem."Flushing Method"::Backward);
        ChildItem.Modify(true);
    end;

    local procedure CreateSubcontractedWorkCenter(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        WorkCenter.Validate("Direct Unit Cost", 0);
        WorkCenter.Validate("Specific Unit Cost", true);
        LibraryPurchase.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);

        // Calculate calendar
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()),
          CalcDate('<1M>', WorkDate()));
    end;

    local procedure CreateWorkCenter_FixedCost(var WorkCenter: Record "Work Center"; DirectUnitCost: Decimal; OverheadRate: Decimal)
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate("Overhead Rate", OverheadRate);
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    [Normal]
    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProducedItem: Record Item; ComponentItem: Record Item; UOMCode: Code[10]; RoutingLinkCode: Code[10]; CompQty: Decimal; ScrapPercent: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UOMCode);

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
          ProductionBOMLine.Type::Item, ComponentItem."No.", CompQty);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem."Base Unit of Measure");
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Validate("Scrap %", ScrapPercent);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ProducedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocWithDirectUnitCost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderWithIT(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo)
    var
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        TrackingSpecification: Record "Tracking Specification";
        Counter: Integer;
        SerialNoAssgnCount: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        for Counter := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
              LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random Direct Unit Cost.
            PurchaseLine.Modify(true);
            case TrackingOption of
                TrackingOption::AssignSerialNo:
                    for SerialNoAssgnCount := 1 to PurchaseLine."Quantity (Base)" do
                        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine,
                          LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification"),
                          '', 1);
                TrackingOption::AssignLotNo:
                    LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine,
                      '', LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Lot No."), DATABASE::"Tracking Specification"),
                      PurchaseLine."Quantity (Base)");
            end;
        end;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        Item.Get(No);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '',
          LibraryRandom.RandInt(10), WorkDate(), LibraryRandom.RandDec(100, 2));
        UpdateGeneralPostingSetup(PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithAssignItemCharge(VendorNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePurchaseDocWithDirectUnitCost(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendorNo, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", Quantity, LocationCode);

        LibraryVariableStorage.Enqueue(ItemNo); // ItemNo used in PostedTransferReceiptLinePageHandler.
        PurchaseLine.ShowItemChargeAssgnt();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', LibraryRandom.RandDec(100, 2), WorkDate(),
          LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostTransferOrder(ItemNo: Code[20]; FromLocation: Code[10]; ToLocation: Code[10]; Qty: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransitLocation: Record Location;
    begin
        TransitLocation.SetRange("Use As In-Transit", true);
        TransitLocation.FindFirst();

        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);

        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure CreateReleaseProdOrderWithLine(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; ItemQty: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder,
          ProductionOrder.Status::Released,
          Item,
          '',
          '',
          ItemQty,
          WorkDate());

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo,
          OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        RoutingLine.Validate("Unit Cost per", LibraryRandom.RandDec(10, 2));
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingLine: Record "Routing Line"; var RoutingLink: Record "Routing Link")
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateSubcontractedWorkCenter(WorkCenter);

        // Setup routing (and its cost) for parent item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", RoutingLink.Code);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateReleasedProdOrderAndChangeStatusToFinished(ProdItem: Record Item; ComponentItem: Record Item; Quantity: Decimal; LocationCode: Code[10])
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJnlMgt: Codeunit "Production Journal Mgt";
    begin
        CreateReleaseProdOrderWithLine(ProdOrder, ProdOrderLine, ProdItem, Quantity);
        ProductionJnlMgt.InitSetupValues();
        ProductionJnlMgt.CreateJnlLines(ProdOrder, ProdOrderLine."Line No.");
        UpdateLocationCodeForComponentToProdOrder(ProdOrder, LocationCode);

        // Posting consumption and output
        LibraryManufacturing.POSTConsumption(ProdOrderLine, ComponentItem, LocationCode, '', Quantity, WorkDate(), ComponentItem."Unit Cost");
        LibraryManufacturing.POSTOutput(ProdOrderLine, Quantity, WorkDate(), ProdItem."Unit Cost");

        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrder."No.");
    end;

    local procedure CreatePurchRetOrderGetPstdDocLineToRev(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; OrderNo: Code[20]; ItemNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindLast();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange("No.", ItemNo);
        PurchInvLine.FindLast();
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopyPurchInvLinesToDoc(
          PurchaseHeader, PurchInvLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CreateSalRetOrderGetPstdDocLineToRev(var SalesHeader: Record "Sales Header"; SelltoCustomerNo: Code[20]; OrderNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SelltoCustomerNo);
        SalesInvHeader.SetRange("Order No.", OrderNo);
        SalesInvHeader.FindLast();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.FindLast();
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopySalesInvLinesToDoc(SalesHeader, SalesInvLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
    end;

    local procedure CarryOutActionMessageSubcontractWksh(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure CreateSetupFor242530(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var Item: Record Item; var ChildItem: Record Item; var ProductionOrder: Record "Production Order")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
        QtyPer: Decimal;
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2));
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);

        LibraryInventory.CreateItemSimple(ChildItem, ChildItem."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2));
        ChildItem.Validate("Flushing Method", Item."Flushing Method"::Backward);
        ChildItem.Modify(true);

        Quantity := LibraryRandom.RandInt(100);
        QtyPer := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, Item, ChildItem, QtyPer, '');
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, ChildItem, '', '', Quantity * QtyPer, WorkDate(), ChildItem."Unit Cost", true, false);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item, '', '', Quantity, WorkDate());

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ProductionOrder."Source No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.OutputJournalExplodeOrderLineRouting(ItemJournalBatch, ProdOrderLine, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Positive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, Positive);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FilterValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type")
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
    end;

    local procedure InventoryCostByItem(ItemNo: Code[20]): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");

        exit(ValueEntry."Cost Amount (Actual)");
    end;

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProductionJournalMgt.InitSetupValues();
        ProductionJournalMgt.SetTemplateAndBatchName();
        ProductionJournalMgt.CreateJnlLines(ProductionOrder, ProdOrderLine."Line No.");
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Document No.", ProductionOrder."No.");
        ItemJournalLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SelectItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure SetAvgCostingPeriodInInvSetup(InventorySetup: Record "Inventory Setup"; AvgCostingPeriod: Enum "Average Cost Period Type")
    begin
        InventorySetup.Get();
        UpdateInventorySetup(
          InventorySetup,
          true,
          InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment",
          InventorySetup."Average Cost Calc. Type",
          AvgCostingPeriod);
    end;

    local procedure UpdateItemRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetup(PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        if GeneralPostingSetup."Purch. Account" = '' then begin
            LibraryERM.FindGLAccount(GLAccount);
            GeneralPostingSetup.Validate("Purch. Account", GLAccount."No.");
            GeneralPostingSetup.Modify(true);
        end;
    end;

    local procedure UpdatePurchasesPayablesSetup(ExactCostReversingMandatory: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(ExactCostReversingMandatory: Boolean; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateInventorySetup(var InventorySetup: Record "Inventory Setup"; AutomaticCostPosting: Boolean; ExpectedCostPostingtoGL: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type"; AverageCostCalcType: Enum "Average Cost Calculation Type"; AverageCostPeriod: Enum "Average Cost Period Type")
    begin
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, AutomaticCostPosting, ExpectedCostPostingtoGL, AutomaticCostAdjustment, AverageCostCalcType, AverageCostPeriod);
        // Dummy Message and Confirm to avoid dependency on previous state of Inventory Setup
        Message('');
        if Confirm('') then;
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateAddCurrencySetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateApplyToItemEntryOnPurchLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetFilter("No.", '<>''''');
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Appl.-to Item Entry", 0);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateApplyFromItemEntryOnSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetFilter("No.", '<>''''');
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Appl.-from Item Entry", 0);
        SalesLine.Modify(true);
    end;

    local procedure UpdateLocationCodeForComponentToProdOrder(ProductionOrder: Record "Production Order"; LocationCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();

        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Modify(true);
    end;

    [Normal]
    local procedure VerifyPurchaseOrderLine(PurchaseLine: Record "Purchase Line"; ItemUOM: Record "Item Unit of Measure"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        Assert.AreEqual(PurchaseLine."Unit of Measure Code", ItemUOM.Code,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Unit of Measure Code"), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine.Type, PurchaseLine.Type::Item,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption(Type), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine."No.", ItemNo,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("No."), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine."Location Code", LocationCode,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Location Code"), PurchaseLine.TableCaption()));
        Assert.AreEqual(PurchaseLine.Quantity, Qty,
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption(Quantity), PurchaseLine.TableCaption()));

        Assert.AreNearlyEqual(PurchaseLine."Line Amount",
          DirectUnitCost * Qty * ItemUOM."Qty. per Unit of Measure",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Line Amount"), PurchaseLine.TableCaption()));
        Assert.AreNearlyEqual(PurchaseLine."Direct Unit Cost",
          DirectUnitCost * ItemUOM."Qty. per Unit of Measure",
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, PurchaseLine.FieldCaption("Direct Unit Cost"), PurchaseLine.TableCaption()));
    end;

    [Normal]
    local procedure VerifyCapacityLedgerEntries(WorkCenterNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; QtyPerBaseUOM: Decimal; DirectUnitCost: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Item No.", ItemNo);
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenterNo);
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.FindLast();

        Assert.AreNearlyEqual(CapacityLedgerEntry."Output Quantity",
          Qty * QtyPerBaseUOM,
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, CapacityLedgerEntry.FieldCaption("Output Quantity"), CapacityLedgerEntry.TableCaption()));

        CapacityLedgerEntry.CalcFields("Direct Cost");
        Assert.AreNearlyEqual(CapacityLedgerEntry."Direct Cost",
          Qty * QtyPerBaseUOM * DirectUnitCost,
          LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(UnexpectedValueMsg, CapacityLedgerEntry.FieldCaption("Direct Cost"), CapacityLedgerEntry.TableCaption()));
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Positive: Boolean; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, Positive);
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
        ItemLedgerEntry.TestField("Cost Amount (Expected) (ACY)", 0);
        ItemLedgerEntry.TestField("Cost Amount (Actual) (ACY)", 0);
    end;

    local procedure VerifyItemLedgerCostAmount(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; ExpectedCostAmount: Decimal; Positive: Boolean)
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, Positive);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");

        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", ExpectedCostAmount);
    end;

    [Normal]
    local procedure VerifyILETotalCost(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Positive: Boolean; ExpCostAmount: Decimal)
    var
        ActualCostAmount: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.SetRange(Positive, Positive);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            ActualCostAmount += ItemLedgerEntry."Cost Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;
        Assert.AreNearlyEqual(ExpCostAmount, ActualCostAmount, 0.01, 'Wrong cost rounding for item ' + ItemNo);
    end;

    local procedure VerifyCostAmountOnValuationDate(ItemNo: Code[20]; ProdOrderNo: Code[20]; ValuationDate: Date; CostAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProdOrderNo);
        ValueEntry.SetRange("Valuation Date", ValuationDate);
        ValueEntry.CalcSums("Cost Amount (Actual)");

        ValueEntry.TestField("Cost Amount (Actual)", CostAmount);
    end;

    [Normal]
    local procedure VerifyValueEntryNoApplication(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo");
        ValueEntry.SetRange(Adjustment, false);
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Applies-to Entry", 0);
        until ValueEntry.Next() = 0;
    end;

    local procedure VerifyValueEntry(ItemNo: Code[20]; DocumentNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntry(ValueEntry, DocumentNo, ItemLedgerEntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyItemApplicationEntry(EntryNo: Integer; Quantity: Decimal)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", EntryNo);
        ItemApplicationEntry.SetRange("Cost Application", false);
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField(Quantity, Quantity);
    end;

    local procedure CreateRoutingAndUpdateItemSubcontracted(var Item: Record Item; var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean): Code[10]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        CreateWorkCenter(WorkCenter, IsSubcontracted);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLink.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(RoutingLink.Code);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        if IsSubcontracted then
            WorkCenter.Validate("Subcontractor No.", LibraryPurchase.CreateVendorNo());

        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        OperationNo := LibraryManufacturing.FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, BinCode);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure PostPurchaseOrder(ItemNo: Code[20]; ShipReceive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        if Invoice and (PurchaseHeader."Vendor Invoice No." = '') then
            PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ShipReceive, Invoice);
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure FindCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; ProductionOrderNo: Code[20]; WorkCenterNo: Code[20])
    begin
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrderNo);
        CapacityLedgerEntry.SetRange("Work Center No.", WorkCenterNo);
        CapacityLedgerEntry.FindFirst();
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(Item2);

        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; InventoryOrderType: Enum "Inventory Order Type"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ItemLedgerEntryType: Enum "Item Ledger Entry Type")
    begin
        ItemLedgerEntry.SetRange("Order Type", InventoryOrderType);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderLineNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.FindLast();
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalLineWithUnitCost(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; UnitCost: Decimal)
    begin
        ItemJournalSetup(ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Msg: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStdCostHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        if Options = CalcStdCostOptionTxt then
            Choice := 2;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MissingOutputConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RunAdjustCostMsgHandler(InputMessage: Text[1024])
    begin
        // If this is not the message that this function is meant to handle, then propagate it further
        if StrPos(InputMessage, RunAdjCostMsg) = 0 then
            Message(InputMessage);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetTransferReceiptLines.Invoke();
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(ItemChargeAssignmentPurch.AssignableQty.AsDecimal());
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferReceiptLinePageHandler(var PostedTransferReceiptLines: TestPage "Posted Transfer Receipt Lines")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        PostedTransferReceiptLines.FILTER.SetFilter("Item No.", ItemNo);
        PostedTransferReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;
}
