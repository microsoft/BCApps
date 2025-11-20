codeunit 137616 "SCM Costing Rollup Sev 4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        CloseFiscalYearQst: Label 'Do you want to close the fiscal year?';
        ApplErr: Label 'If the item carries serial, lot or package numbers, then you must use the Applies-from Entry field in the Item Tracking Lines window.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        TaxLiableErr: Label 'You cannot combine shipments from orders which have different values of Tax Liable.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Rollup Sev 4");
        // Lazy Setup.

        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 4");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Rollup Sev 4");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PS50190()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();

        LibraryCosting.AdjustCostItemEntries('', '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        LibraryInventory.UpdateAverageCostSettings(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Setup. Make item, post receive and invoice purchase.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 0);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', LibraryRandom.RandDec(10, 2),
          WorkDate(), LibraryRandom.RandDec(100, 2), true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Create new interim accounts...
        InventoryPostingSetup.Get('', Item."Inventory Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        InventoryPostingSetup.Validate("Inventory Account (Interim)", GLAccount."No.");
        InventoryPostingSetup.Modify(true);

        GeneralPostingSetup.Get(PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        InventorySetup.Validate("Expected Cost Posting to G/L", true);
        InventorySetup.Modify(true);

        // Exercise. Post to G/L.
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify. Interim accounts have 0 balance.
        InventoryPostingSetup.Get('', Item."Inventory Posting Group");
        VerifyZeroBalanceForInterim(InventoryPostingSetup."Inventory Account (Interim)");
        GeneralPostingSetup.Get(PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        VerifyZeroBalanceForInterim(GeneralPostingSetup."Invt. Accrual Acc. (Interim)");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PS34589()
    var
        ValueEntry: Record "Value Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        ItemCharge: Record "Item Charge";
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        Initialize();

        // Setup. Post purchase and sale, assign purchase charge to sales shipment.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 0);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', 18, WorkDate(), 30, true, true);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', 18, WorkDate(), 0, true, true);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        SalesShptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");

        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreateItemChargePurchaseLine(PurchaseLine, ItemCharge, PurchaseHeader, 1, 1500);
        SalesShptLine."Item Charge Base Amount" := PurchaseLine.Amount;
        SalesShptLine.Modify();
        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchaseLine, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Sales Shipment",
          SalesShptLine."Document No.", SalesShptLine."Line No.",
          SalesShptLine."No.", 1, 1500);
        ItemChargeAssignmentPurch.Insert();
        ItemChargeAssgntPurch.SuggestAssgnt(PurchaseLine, PurchaseLine.Quantity, PurchaseLine."Line Amount", PurchaseLine.Quantity, PurchaseLine."Line Amount");

        // Execute: Adjust and post to G/L.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Value Entry Cost Amount (Non-Invtbl.).
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.FindFirst();
        Assert.AreEqual(-ItemChargeAssignmentPurch."Amount to Assign", ValueEntry."Cost Amount (Non-Invtbl.)",
          'Wrong value entry.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PS37378()
    var
        Item: Record Item;
        Location: Record Location;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        Initialize();

        // Setup: Create item, add to inventory then remove, generating a rounding entry.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 0);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPatterns.POSTPositiveAdjustmentAmount(Item, Location.Code, '', 3, WorkDate(), 10);
        LibraryInventory.PostNegativeAdjustment(Item, Location.Code, '', '', 1, WorkDate(), 0);
        LibraryInventory.PostNegativeAdjustment(Item, Location.Code, '', '', 1, WorkDate(), 0);
        LibraryInventory.PostNegativeAdjustment(Item, Location.Code, '', '', 1, WorkDate(), 0);

        // Setup dimension with code mandatory for Inventory account.
        InventoryPostingSetup.Get(Location.Code, Item."Inventory Posting Group");
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, InventoryPostingSetup."Inventory Account",
          Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // Exercise: Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: No error expected in adjustment.
        LibraryCosting.CheckAdjustment(Item);

        // Tear down
        DefaultDimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PS39409()
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        Initialize();

        // Setup. Create lot tracked item. Purchase and adjust inventory.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(10, 2));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify();

        LotNo := LibraryUtility.GenerateRandomCode(ReservationEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry");
        Qty := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryPurchase.PostPurchaseOrderWithItemTracking(PurchaseHeader, Item, '', '', Qty, WorkDate(), 0, true, false, '', LotNo);
        LibraryPatterns.POSTNegativeAdjustmentWithItemTracking(Item, '', '', Qty - 50, WorkDate(), '', LotNo);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, '', '', WorkDate(),
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Qty - 75, 0);

        // Exercise. Try to apply from the journal.
        asserterror ItemJournalLine.Validate("Applies-from Entry", TempItemLedgerEntry."Entry No.");

        // Verify. Journal line cannot be posted.
        Assert.ExpectedError(ApplErr);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure PS45737()
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ValueEntry: Record "Value Entry";
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        SalesShptLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        Qty: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        Initialize();

        // Setup. Create item, sale, purchase.
        Qty := LibraryRandom.RandDecInRange(2, 10, 2);
        UnitCost := LibraryRandom.RandDec(100, 2);
        UnitPrice := UnitCost + LibraryRandom.RandDec(10, 2);

        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', Qty, WorkDate(), UnitCost);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty, WorkDate(), UnitPrice, true, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        SalesShptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");
        SalesShptLine.SetRange("Tax Liable", SalesHeader."Tax Liable");

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        Customer.Get(SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShptLine);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();

        SalesLine.Validate(Quantity, SalesLine."Qty. to Invoice" - 1);
        SalesLine.Validate("Unit Price", SalesLine."Unit Price" + LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise. Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Value Entry.
        LibraryCosting.CheckAdjustment(Item);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.FindFirst();
        Assert.AreEqual(0, ValueEntry."Sales Amount (Expected)", 'Wrong sales amount (expected)');
    end;

    [Normal]
    local procedure VerifyZeroBalanceForInterim(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.CalcFields(Balance);
        Assert.AreEqual(0, GLAccount.Balance, 'Interim account ' + GLAccountNo + ' should have 0 balance.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PS38228()
    var
        InventorySetup: Record "Inventory Setup";
        SKU1: Record "Stockkeeping Unit";
        SKU2: Record "Stockkeeping Unit";
        SKU3: Record "Stockkeeping Unit";
        Location1: Record Location;
        Location2: Record Location;
        Location3: Record Location;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Qty: Decimal;
        Qty2: Decimal;
        UnitAmount: Decimal;
    begin
        Initialize();

        // Setup: Create item with avg costing method and SKUs in three different locations
        LibraryInventory.UpdateAverageCostSettings(
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, LibraryRandom.RandDec(10, 2));
        // Create SKUs for the item. These calls also create locations with no warehousing functionality
        LibraryWarehouse.CreateStockkeepingUnit(SKU1, Item);
        LibraryWarehouse.CreateStockkeepingUnit(SKU2, Item);
        LibraryWarehouse.CreateStockkeepingUnit(SKU3, Item);
        Location1.Get(SKU1."Location Code");
        Location2.Get(SKU2."Location Code");
        Location3.Get(SKU3."Location Code");

        // Exercise: Post item journal adjustments. The quantities are manipulated so we end up with a negative qty on hand
        Qty := LibraryRandom.RandDec(5, 2);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Sale,
          Item, Location1.Code, '', '', Qty, WorkDate(), LibraryRandom.RandDec(10, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase,
          Item, Location1.Code, '', '', Qty, WorkDate(), LibraryRandom.RandDec(10, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Sale,
          Item, Location2.Code, '', '', Qty, WorkDate(), LibraryRandom.RandDec(10, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase,
          Item, Location2.Code, '', '', Qty, WorkDate(), LibraryRandom.RandDec(10, 2));

        // Now we have 0 quantity of Item. Force a negative quantity
        Qty := LibraryRandom.RandDec(5, 2);
        Qty2 := LibraryRandom.RandDecInRange(6, 10, 2);
        UnitAmount := LibraryRandom.RandDec(10, 2);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Sale,
          Item, Location3.Code, '', '', Qty2, WorkDate(), LibraryRandom.RandDec(10, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase,
          Item, Location3.Code, '', '', Qty, WorkDate(), UnitAmount);

        // Verify: the unit cost on the item card is updated when we have negative qty on hand
        Item.Get(Item."No.");
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(UnitAmount, Item."Unit Cost", GeneralLedgerSetup."Amount Rounding Precision",
          'Item unit cost is updated in situations with negative qty on hand');
    end;

    [Test]
    [HandlerFunctions('ConsumptionNotFinishedConfirmHandler')]
    [Scope('OnPrem')]
    procedure PS49498()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Create a subcontract Purch. Order (PO) for a production item. Post receipt (PO), finish the Prod. Order,
        // revaluate the item, post invoice (PO) and validate 'Cost Amount (Actual)' in the Output Item Ledger Entry
        // for the production order

        Initialize();

        // Setup: Preparation for subcontracting orders: location, production item & routing setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItemSimple(ChildItem, ChildItem."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateItemSimple(ParentItem, ParentItem."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        CreateRoutingSetup(WorkCenter, RoutingLine, RoutingLink);
        CreateProductionBOM(ProductionBOMHeader, ParentItem, ChildItem, RoutingLink.Code, LibraryRandom.RandDec(20, 2));
        ParentItem.Validate("Routing No.", RoutingLine."Routing No.");
        ParentItem.Modify(true);

        RunAdjustCostItemEntries('', '');  // Any item & item category

        // Supply child item
        LibraryInventory.PostPositiveAdjustment(ChildItem, Location.Code, '', '',
          LibraryRandom.RandDec(50, 2), WorkDate(), 0);

        // Create a released production order for parent item, calculate subcontracts and create subcontract Purch. Order
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", Location.Code);
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(ParentItem."No.");

        // Post receipt of this purchase order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ParentItem."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.SetCurrentKey("Document Type", "No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Change the status of the production order to finished. Ignore the warning (consumption is not finished yet)
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        RunAdjustCostItemEntries('', '');

        // Revaluate the parent item and run the Adjust Cost - Item entries job
        LibraryInventory.CreateRevaluationJournalLine(ItemJournalBatch, ParentItem,
          WorkDate(), "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ");
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", LibraryRandom.RandDec(200, 2));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        RunAdjustCostItemEntries('', '');

        // Post invoice for the subcontract Purch. Order
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        RunAdjustCostItemEntries('', '');

        // Verify 'Unit cost (Actual)' in the Output Item Ledger Entry
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", ParentItem."No.");
        ItemLedgerEntry.FindFirst();

        GeneralLedgerSetup.Get();
        ParentItem.Get(ParentItem."No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreNearlyEqual(ParentItem."Unit Cost" * ItemLedgerEntry.Quantity,
          ItemLedgerEntry."Cost Amount (Actual)",
          GeneralLedgerSetup."Amount Rounding Precision",
          'Cost amount (Actual) matches Standard cost');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PS34691()
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        ParentItem: Record Item;
        ChildItem: Record Item;
        GrandchildItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        NonBaseChildItemUOM: Record "Item Unit of Measure";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        Initialize();

        // Setup
        // Create a 'make-to-order' child item with 2 UOMs and standard costing method
        LibraryInventory.CreateItemSimple(ChildItem, ChildItem."Costing Method"::Standard, 0);
        LibraryInventory.CreateItemUnitOfMeasureCode(NonBaseChildItemUOM, ChildItem."No.", LibraryRandom.RandDec(20, 2));
        ChildItem.Validate("Replenishment System", ChildItem."Replenishment System"::"Prod. Order");
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);

        // Create a Prod BOM for the child item using its base UOM
        LibraryInventory.CreateItemSimple(GrandchildItem, GrandchildItem."Costing Method"::Standard, LibraryRandom.RandDec(5, 2));
        LibraryManufacturing.CreateCertifiedProductionBOM(ProdBOMHeader, GrandchildItem."No.", LibraryRandom.RandDec(5, 2));
        ChildItem.Validate("Production BOM No.", ProdBOMHeader."No.");
        ChildItem.Modify(true);

        // Create a parent item
        LibraryInventory.CreateItemSimple(ParentItem, ParentItem."Costing Method"::Standard, 0);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // Create a Production BOM for the parent item, adding the child item as a component (with its alternative UOM)
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine,
          '', ProdBOMLine.Type::Item, ChildItem."No.", LibraryRandom.RandDec(5, 2));
        ProdBOMLine.Validate("Unit of Measure Code", NonBaseChildItemUOM.Code);
        ProdBOMLine.Modify(true);
        ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
        ProdBOMHeader.Modify(true);
        ParentItem.Validate("Production BOM No.", ProdBOMHeader."No.");
        ParentItem.Modify(true);

        // Run Calc.Standard costs on all levels for the parent item
        ParentItem.SetRange("No.", ParentItem."No.");
        CalculateStandardCost.SetProperties(WorkDate(), true, false, false, '', false);
        CalculateStandardCost.CalcItems(ParentItem, TempItem);
        if TempItem.Find('-') then
            repeat
                Item := TempItem;
                // 'Calculate std costs' directly assigns standard cost. Force propagation to unit cost field
                Item.Validate("Standard Cost", Item."Standard Cost");
                Item.Modify(true);
            until TempItem.Next() = 0;

        // Exercise: Create and refresh a Released Production Order for parent item
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released,
          ProdOrder."Source Type"::Item, ParentItem."No.", LibraryRandom.RandDec(20, 2));
        LibraryManufacturing.RefreshProdOrder(ProdOrder, false, true, true, true, false);

        // Verify: The Production Order line for the component contains the correct unit of measure
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrder."No.", 20000);
        Assert.AreEqual(ProdBOMLine."Unit of Measure Code",
          NonBaseChildItemUOM.Code,
          'Component specified in its alternative unit of measure');

        // Verify: The unit cost of the component has been updated to reflect the UOM used
        GeneralLedgerSetup.Get();
        ChildItem.Get(ChildItem."No.");
        Assert.AreNearlyEqual(ProdOrderLine."Unit Cost",
          ChildItem."Unit Cost" * NonBaseChildItemUOM."Qty. per Unit of Measure",
          GeneralLedgerSetup."Amount Rounding Precision",
          'Unit cost adjusted to alternative unit of measure');
    end;

    [Normal]
    local procedure CreateRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingLine: Record "Routing Line"; var RoutingLink: Record "Routing Link")
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateSubcontractWorkcenter(WorkCenter);

        // Setup routing (and its cost) for parent item
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", RoutingLink.Code);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    [Normal]
    local procedure CreateSubcontractWorkcenter(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryPurchase.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    [Normal]
    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo,
          OperationNo, 0, LibraryRandom.RandDec(5, 2));    // Random run-time cost
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
    end;

    [Normal]
    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProducedItem: Record Item; ComponentItem: Record Item; RoutingLinkCode: Code[10]; CompQty: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProducedItem."Base Unit of Measure");

        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine,
          '', ProductionBOMLine.Type::Item, ComponentItem."No.", CompQty);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem."Base Unit of Measure");
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ProducedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem.Modify(true);
    end;

    [Normal]
    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    [Normal]
    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    [Normal]
    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
    end;

    [Normal]
    local procedure CarryOutActionMessageSubcontractWksh(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    [Normal]
    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    [Normal]
    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    [Normal]
    local procedure RunAdjustCostItemEntries(ItemFilter: Text[250]; ItemCategoryFilter: Text[250])
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
    begin
        Clear(AdjustCostItemEntries);
        AdjustCostItemEntries.InitializeRequest(ItemFilter, ItemCategoryFilter);
        AdjustCostItemEntries.UseRequestPage(false);
        AdjustCostItemEntries.RunModal();
    end;

    local procedure AdjustCostAndVerify(ItemNo: Code[20]; ExpectedUnitCost: Decimal)
    var
        Item: Record Item;
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        Item.Get(ItemNo);
        Assert.AreNearlyEqual(ExpectedUnitCost, Item."Unit Cost", LibraryERM.GetUnitAmountRoundingPrecision(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostNoErrorOccurs()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        UnitCost: Decimal;
    begin
        // Refer to PS 33459 (VedbaekSE) & PS 29207 (Navision Corsica) for issue details.
        Initialize();

        // Setup: make item, setup inventory setup, post item journals
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Month);

        UnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 800, CalcDate('<1M>', WorkDate()), UnitCost);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 200, CalcDate('<2M>', WorkDate()), 0);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 200, CalcDate('<3M>', WorkDate()), 0);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 100, CalcDate('<1Y>', WorkDate()), 0);

        // Exercise: Run adjust cost, and verify that no error occurs
        AdjustCostAndVerify(Item."No.", UnitCost);
    end;

    [Test]
    [HandlerFunctions('FiscalYearCloseConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletionOfItemAfterClosingFiscalYearPostPositiveFirstCostOnNegative()
    begin
        DeletionOfItemAfterClosingFiscalYearScenario(true, true);
    end;

    [Test]
    [HandlerFunctions('FiscalYearCloseConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletionOfItemAfterClosingFiscalYearPostNegativeFirstCostOnNegative()
    begin
        DeletionOfItemAfterClosingFiscalYearScenario(false, true);
    end;

    local procedure DeletionOfItemAfterClosingFiscalYearScenario(PositiveBeforeNegative: Boolean; NegativeHasUnitCost: Boolean)
    var
        Item: Record Item;
        AccountingPeriod: Record "Accounting Period";
        PostingDate: Date;
        PositiveItemJournalUnitCost: Decimal;
        NegativeItemJournalUnitCost: Decimal;
    begin
        // Refer to PS 37363 (VedbaekSE) & PS 29274 (Navision Corsica) for issue details.
        Initialize();

        if Confirm(CloseFiscalYearQst) then;

        // Setup: make item, make postings, adjust cost, close year
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        PostingDate := CalcDate('<-1Y>', WorkDate());
        PositiveItemJournalUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        if NegativeHasUnitCost then
            NegativeItemJournalUnitCost := PositiveItemJournalUnitCost
        else
            NegativeItemJournalUnitCost := 0;
        if PositiveBeforeNegative then begin
            LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, PostingDate, PositiveItemJournalUnitCost);
            LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, PostingDate, NegativeItemJournalUnitCost);
        end else begin
            LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, PostingDate, NegativeItemJournalUnitCost);
            LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, PostingDate, PositiveItemJournalUnitCost);
        end;

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        AccountingPeriod.Get(CalcDate('<-CY>', PostingDate));
        CODEUNIT.Run(CODEUNIT::"Fiscal Year-Close", AccountingPeriod);

        // Exercise: Delete item
        Item.Find();
        Item.Delete(true);

        // Verify: Item is deleted and no error occurs
        Assert.IsFalse(Item.Get(Item."No."), 'Item is deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ILEforItemReturnedByPurchaseCreditIsOpen()
    var
        InventoryPeriod: Record "Inventory Period";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty: Decimal;
    begin
        // Refer to PS 39139 (VedbaekSE) & PS 29308 (Navision Corisca) for issue details.
        Initialize();

        // Setup: Create new inventory period ending date being 20 days from WORKDATE
        InventoryPeriod.Init();
        InventoryPeriod."Ending Date" := CalcDate('<20D>', WorkDate());
        InventoryPeriod.Insert();

        // Setup: Make item, post purchase, post sales.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);
        Qty := LibraryRandom.RandDecInRange(1, 100, 2);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty, WorkDate(), 1, true, true);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty, WorkDate(), 1, true, true);

        // Setup: Post sales credit
        LibrarySales.CreateSalesCreditMemo(SalesHeader, SalesLine, Item, '', '', Qty, WorkDate(), 1, 12);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.FindLast();
        SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Setup: Post purchase credit
    end;

    [Test]
    procedure BlockCombineShipmentsInvoicesOnDifferentTaxLiableOption()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 563076] Block combine shipments if invoices have different "Tax Liable" option.
        Initialize();

        // [GIVEN] Create Sales Order and Post with Tax Liable set to true.
        CustomerNo := CreateSalesOrderAndPost(true, '');

        // [GIVEN] Create Sales Order and Post with Tax Liable set to false.
        CreateSalesOrderAndPost(false, CustomerNo);

        // [GIVEN] Create Sales Header with Document Type "Invoice".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Set Sales Header and filter "Customer No.".
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);

        // [WHEN] Run Get Sales Shipment line.
        asserterror SalesGetShipment.CreateInvLines(SalesShipmentLine);

        // [THEN] Error should be raised on different Tax Liable.
        Assert.ExpectedError(TaxLiableErr);
    end;

    local procedure CreateSalesOrderAndPost(TaxLiable: Boolean; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, CustomerNo, TaxLiable);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        exit(SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; TaxLiable: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Tax Liable", TaxLiable);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 1000, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 50));
        SalesLine.Validate("Unit Cost (LCY)", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConsumptionNotFinishedConfirmHandler(ConfirmMsg: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;   // Finish the order even if consumption is not finished
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure FiscalYearCloseConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CloseFiscalYearQst) > 0, '');
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

