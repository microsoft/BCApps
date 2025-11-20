codeunit 137350 "SCM Inventory Reports - III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        AdjustCostItemEntriesBatchJobMessage: Label 'Some unadjusted value entries will not be covered with the new setting.';
        ItemNoFilter: Label '%1|%2|%3';
        PerEntryError: Label 'Do not enter a Document No. when posting per Entry.';
        PerPostingGroupError: Label 'Please enter a Document No. when posting per Posting Group.';
        PostingDateError: Label 'Enter the posting date.';
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        isInitialized: Boolean;
        RecordCountError: Label 'Record count should be greater than 1.';
        RegisteringDateError: Label 'Enter the Registering Date.';
        SalesLinesShownError: Label 'Sales lines must be shown.';
        UndoShipmentConfirmMessage: Label 'Do you really want to undo the selected Shipment lines?';
        ValueNotMatchedError: Label 'Value not matched';
        ValidationError: Label '%1 must be %2 in Report.';
        ValuationDateError: Label 'Enter the valuation date';
        WIPInventory: Label 'WIP Inventory';
        OptionString: Option AssignSerialNo,AssignLotNo,SelectEntries;
        ApplyToItemEntryErr: Label 'Order No. must be equal to ''%1''  in Item Ledger Entry';
        DimensionMandatoryErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for G/L Account %2.', Comment = '%1: Field(Code) in Table(Dimension), %2: Field(No.) in Table(G/L Account)';
        EntriesPostedToGLMsg: Label 'value entries have been posted to the general ledger.';
        NothingToPostToGLMsg: Label 'There is nothing to post to the general ledger.';
        PostMethod: Option "per Posting Group","per Entry";

    [Test]
    [HandlerFunctions('ConfirmHandler,InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationAfterPostingItemJournal()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Inventory Valuation Report for Cost Posted to G/L after posting Item Journal and Undo the Posted Shipment.

        // Setup: Post Item Journal and Undo Sales Shipment.
        Initialize();
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmMessage);
        PostItemJournalAndUndoShipment(SalesLine);

        // Exercise: Run Inventory Valuation Report.
        RunInventoryValuationReport(SalesLine."No.", WorkDate(), CalcDate('<CY>', WorkDate()));

        // Verify: Verify Inventory Valuation Report.
        VerifyInventoryValuationReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityAfterPostingItemJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        MaxInventory: Decimal;
    begin
        // Verify Inventory Availability Report for updated Stock Keeping Unit with Reorder Point after posting Item Journal.

        // Setup: Create Location, create Item with Reordering Policy Maximum Qty., create Stockkeeping Unit with Reordering Policy Lot-for-Lot and Post Item Journal.
        Initialize();
        MaxInventory := LibraryRandom.RandDec(100, 2);  // Use Random for Maximum Inventory.
        CreateAndUpdateItem(
          Item, Item.Reserve::Never, Item."Reordering Policy"::"Maximum Qty.", MaxInventory, MaxInventory / 2, Item."Costing Method"::FIFO,
          '', '');  // Set Reorder Point less than Max. Inventory.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);  // Use False for Item InInventory Only and Replace Previous SKUs fields.
        UpdateStockkeepingUnit(Location.Code, Item."No.");
        CreateAndPostItemJournalLineWithLocation(ItemJournalLine, Item."No.", Location.Code);

        // Exercise: Run Inventory Availability Report.
        RunInventoryAvailabilityReport(Item."No.");

        // Verify: Verify Inventory Availability Report for updated Stock Keeping Unit with Reorder Point.
        VerifyInventoryAvailabilityReport(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemExpirationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemExpirationAfterPostingPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Item Expiration Report after posting Purchase Order with Expiration Date.

        // Setup: Create and post Purchase Order with Expiration Date.
        Initialize();
        CreatePurchaseOrderWithItemTracking(PurchaseLine, '', false);  // Use blank value for Location Code.
        UpdateReservationEntryExpirationDate(PurchaseLine."No.");
        PostPurchaseOrder(PurchaseLine, true, true);

        // Exercise: Run Item Expiration Report.
        RunItemExpirationReport(PurchaseLine."No.");

        // Verify: Verify Item Expiration Report.
        VerifyItemExpirationReport(PurchaseLine.Quantity, PurchaseLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemRegisterValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegisterAfterPostingItemJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Item Register Report after posting Item Journal.

        // Setup: Create and post Item Journal.
        Initialize();
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, CreateItem(), WorkDate(), LibraryRandom.RandInt(10),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Amount and Quantity.

        // Exercise: Run Item Register Report.
        RunItemRegisterReport(ItemJournalLine);

        // Verify: Verify Item Register Report.
        VerifyItemRegisterReport(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemSubstitutionAfterCreatingSubstitute()
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        // Verify Item Substitutions Report after creating Item Substitute.

        // Setup: Create item and its substitute.
        Initialize();
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, CreateItem());

        // Exercise: Run Item Substitutions Report.
        RunItemSubstitutionsReport(ItemSubstitution."No.");

        // Verify: Verify Item Substitutions Report.
        VerifyItemSubstitutionsReport(ItemSubstitution."Substitute No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationCostSpecAfterRevaluation()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Inventory Valuation Cost Specification Report when Item is revalued more than once.

        // Setup: Create Item and update Inventory Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(AdjustCostItemEntriesBatchJobMessage);
        CreateAndUpdateItem(Item, Item.Reserve::Never, Item."Reordering Policy"::" ", 0, 0, Item."Costing Method"::FIFO, '', '');  // Pass zero values for Maximum Inventory and Reordering Point.
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment"::Always);

        // Create and post Item Journal for Purchase and Revaluate it.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", WorkDate(), Item."Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        CreateAndPostItemJournalForRevaluation(Item."No.", WorkDate());

        // Create and post Item Journal for Sales and Revaluate it.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.", WorkDate(), Item."Unit Cost", ItemJournalLine.Quantity / 2);  // Divide by 2 to Sale partial Quantity.
        CreateAndPostItemJournalForRevaluation(Item."No.", WorkDate());

        // Exercise: Run Inventory Valuation Cost Specification Report.
        RunInvtValuationCostSpecReport(Item."No.", WorkDate());

        // Verify: Verify Inventory Valuation Cost Specification Report.
        VerifyInvtValuationCostSpecReport(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerInvSetup,MessageHandlerInvtSetup,InvtValuationCostSpecRequestPageHandler')]
    [Scope('OnPrem')]
    procedure S474285_InvtValuationCostSpecReportWithAverageCostingAfterRevaluation()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ItemJournalLine: Record "Item Journal Line";
        PositiveQty: array[2] of Decimal;
        NegativeQty: Decimal;
        PositiveUnitCost: array[2] of Decimal;
        AverageUnitCost: Decimal;
        RemainingInventory: Decimal;
        DecimalVariant: Variant;
    begin
        // [FEATURE] [Invt. Valuation - Cost Spec.] [Average Costing Method]
        // [SCENARIO 474285] Verify Inventory Valuation Cost Specification Report when Item is using Average Costing Method.
        Initialize();

        // [GIVEN] Update Inventory Setup.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Month);

        // [GIVEN] Create Item with Average Costing Method.
        CreateAndUpdateItem(Item, Item.Reserve::Never, Item."Reordering Policy"::" ", 0, 0, Item."Costing Method"::Average, '', '');  // Pass zero values for Maximum Inventory and Reordering Point.
        Item.Validate("Unit Cost", 0);
        Item.Modify(true);

        // [GIVEN] Create and post Item Journals: 1st Positive Adjustment, Negative Adjustment, 2nd Positive Adjustment.
        PositiveQty[1] := LibraryRandom.RandDecInRange(2, 10, 2);
        PositiveQty[2] := LibraryRandom.RandDecInRange(2, 10, 2);
        NegativeQty := LibraryRandom.RandDecInRange(1, 5, 2);
        PositiveUnitCost[1] := LibraryRandom.RandDec(100, 2);
        PositiveUnitCost[2] := LibraryRandom.RandDec(100, 2);

        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", CalcDate('<-CM>', WorkDate()), PositiveUnitCost[1], PositiveQty[1]);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", CalcDate('<-CM + 1D>', WorkDate()), 0, NegativeQty);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", CalcDate('<-CM + 3D>', WorkDate()), PositiveUnitCost[2], PositiveQty[2]);
        Commit();

        // [WHEN] Run Inventory Valuation Cost Specification Report for end of Month.
        RunInvtValuationCostSpecReport(Item."No.", CalcDate('<+CM>', WorkDate())); // Uses InvtValuationCostSpecRequestPageHandler.

        // [THEN] Verify Inventory Valuation Cost Specification Report.
        Item.GetBySystemId(Item.SystemId);
        if Item."Unit Cost" <> 0 then
            AverageUnitCost := Item."Unit Cost"
        else
            AverageUnitCost := (PositiveQty[1] * PositiveUnitCost[1] + PositiveQty[2] * PositiveUnitCost[2]) / (PositiveQty[1] + PositiveQty[2]);
        RemainingInventory := PositiveQty[1] - NegativeQty + PositiveQty[2];

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // [THEN] Verify Direct Cost - Unit Cost.
        LibraryReportDataset.FindCurrentRowValue('UnitCost1', DecimalVariant);
        Assert.AreNearlyEqual(AverageUnitCost, DecimalVariant, LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);

        // [THEN] Verify Direct Cost - Verify Quantity.
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainingQty', RemainingInventory);

        // [THEN] Verify Direct Cost - Amount.
        LibraryReportDataset.FindCurrentRowValue('TotalCost', DecimalVariant);
        Assert.AreNearlyEqual(AverageUnitCost * RemainingInventory, DecimalVariant, LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);
    end;

    [Test]
    [HandlerFunctions('InvtValuationCostSpecValuationDateHandler')]
    [Scope('OnPrem')]
    procedure InvtValuationCostSpecValuationDateMustExists()
    begin
        // Verify Inventory Valuation Cost Specification Report for blank Valuation Date.

        // Setup.
        Initialize();
        Commit();

        // Exercise: Run Inventory Valuation Cost Specification Report.
        asserterror RunInvtValuationCostSpecReportWithPage();

        // Verify.
        Assert.ExpectedError(ValuationDateError);
    end;

    [Test]
    [HandlerFunctions('SalesReservationAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReservationAvailAfterCreatingSalesOrder()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Reservation Availability Report after creating Sales Order.

        // Setup: Create Item, create and Receive Purchase Order, create Sales Order.
        Initialize();
        CreateAndReceivePurchaseOrder(PurchaseLine);
        CreateSalesOrderAndModifyQuantity(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);

        // Exercise: Run Sales Reservation Availability Report.
        RunSalesReservationAvailReport(SalesLine."Document No.");

        // Verify: Verify Sales Reservation Availability Report.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        VerifySalesReservationAvailReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesReservationAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReservationAvailSalesLineMustBeShown()
    var
        SalesReservationAvail: Report "Sales Reservation Avail.";
    begin
        // Verify Sales Reservation Availability Report for Show Sales Line as FALSE.

        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(false);     // Show sales lines
        LibraryVariableStorage.Enqueue(true);      // Show reservation entries
        LibraryVariableStorage.Enqueue(false);     // Modify qty...
        Clear(SalesReservationAvail);
        Commit();

        // Exercise.
        asserterror SalesReservationAvail.Run();

        // Verify.
        Assert.ExpectedError(SalesLinesShownError);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,PurchaseReservationAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReservationAvailAfterCreatingPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Purchase Reservation Availability Report after creating Purchase Order.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, CreateItem(), LibraryRandom.RandDec(10, 2), '');  // Use Random value for Quantity.

        // Create and Ship Sales Order.
        CreateSalesOrder(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Reopen Purchase Order to Reserve.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        OpenPurchaseOrderToReserve(PurchaseHeader."No.");

        // Exercise: Run Sales Reservation Availability Report.
        Commit();
        RunPurchaseReservationAvailReport(PurchaseHeader."No.");

        // Verify: Verify Sales Reservation Availability Report.
        VerifyPurchaseReservationAvailReport(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('PurchaseReservationAvailPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReservationAvailPurchaseLineMustBeShown()
    begin
        // Verify Purchase Reservation Availability Report for Show Purchase Line as FALSE.

        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(true);     // Show purchase line
        LibraryVariableStorage.Enqueue(true);    // Show reservation entries
        LibraryVariableStorage.Enqueue(true);    // Modify qty to ship in order lines
        Commit();

        // Exercise.
        REPORT.Run(REPORT::"Purchase Reservation Avail.", true, false);

        // Verify.
        asserterror LibraryReportDataset.LoadDataSetFile();
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanAfterCreatingSalesOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Inventory Availability Plan Report after creating Sales Order.

        // Setup: Create Item, create and Receive Purchase Order, create Sales Order.
        Initialize();
        CreateAndReceivePurchaseOrder(PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        CreateSalesOrder(SalesLine, PurchaseLine."No.", LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        Item.Get(PurchaseLine."No.");
        Item.CalcFields(Inventory, "Qty. on Sales Order");
        LibraryVariableStorage.Enqueue(false);

        // Exercise: Run Inventory Availability Plan Report.
        RunInventoryAvailabilityPlanReport(PurchaseLine."No.");

        // Verify: Verify Inventory Availability Plan Report.
        VerifyQuantityOnInventoryAvailabilityPlanReport(Item.Inventory, Item.Inventory - Item."Qty. on Sales Order");
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanWithStockKeeping()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Inventory Availability Plan Report with Stockkeeping Unit as True.

        // Setup: Create Item with Stockkeeping Unit, Location, create and Post Item Journal Line.
        Initialize();
        Item.Get(CreateItem());
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Item.SetRange("Location Filter", Location.Code);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);  // Use False for Item InInventory Only and Replace Previous SKUs fields.
        CreateAndPostItemJournalLineWithLocation(ItemJournalLine, Item."No.", Location.Code);
        LibraryVariableStorage.Enqueue(true);
        Item.CalcFields(Inventory);

        // Exercise: Run Inventory Availability Plan Report.
        RunInventoryAvailabilityPlanReport(Item."No.");

        // Verify: Verify Inventory Availability Plan Report.
        VerifyQuantityOnInventoryAvailabilityPlanReport(Item.Inventory, Item.Inventory);
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_SKU', Location.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerInvSetup,MessageHandlerInvtSetup,PostInventoryCostToGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostValueEntryToGLWithPurchaseCost()
    var
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        // Post Value Entry to G/L is correct with Zero Cost - Purchase. Post as Receive, Create Release Production Order and Post Production Journal. Post Purchase Order as Invoice and
        // Run Adjust Cost Item Entries and Post Inventory Cost to G/L. Verify report Inventory Cost to G/L Report.

        // Setup: Create Purchase Order for Production and Component Item. Post as Receive.
        Initialize();
        ExecuteUIHandlers();
        Quantity := 10 + LibraryRandom.RandInt(100);  // Using Random value for Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Using Random for Direct Unit Cost.
        PostValueEntryToGL(DirectUnitCost, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerInvSetup,MessageHandlerInvtSetup,PostInventoryCostToGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostValueEntryToGLWithCostACYCostAmount()
    var
        DirectUnitCost: Decimal;
        Quantity: Decimal;
        TotalInventoryValueACY: Decimal;
        Component: Code[20];
        CurrencyCode: Code[10];
    begin
        // Setup General Ledger Setup for Additional Currency,Post Value Entry to G/L is correct with Zero Cost - Purchase. Post as Receive, Create Release Production Order and Post Production Journal. Post Purchase Order as Invoice and
        // Run Adjust Cost Item Entries and Post Inventory Cost to G/L.

        // Setup: Create Purchase Order for Production and Component Item. Post as Receive.
        Initialize();
        ExecuteUIHandlers();
        CurrencyCode := CreateCurrency();
        UpdateAddCurrencySetup(CurrencyCode);
        Quantity := 10 + LibraryRandom.RandInt(100);  // Using Random value for Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Using Random for Direct Unit Cost.
        TotalInventoryValueACY := LibraryERM.ConvertCurrency(Quantity * DirectUnitCost, '', CurrencyCode, WorkDate());
        Component := PostValueEntryToGL(DirectUnitCost, Quantity);

        // Verify: Verify record count in Post Value Entry record,Total Inventory Cost on Inventory Cost To GL Report and  Quantity Expected/Actual Cost ACY for Component Item in Item Ledger Entry.
        VerifyItemLedgerEntry(Component, true, Quantity, TotalInventoryValueACY);
    end;

    local procedure PostValueEntryToGL(DirectUnitCost: Decimal; Quantity: Decimal) Component: Code[20]
    var
        InventorySetup: Record "Inventory Setup";
        ProductionItem: Record Item;
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionQuantity: Decimal;
        TotalInventoryValue: Decimal;
        ItemNo: Code[20];
        Component2: Code[20];
    begin
        // Setup General Ledger Setup for Additional Currency,Post Value Entry to G/L is correct with Zero Cost - Purchase. Post as Receive, Create Release Production Order and Post Production Journal. Post Purchase Order as Invoice and
        // Run Adjust Cost Item Entries and Post Inventory Cost to G/L.

        // Setup: Create Purchase Order for Production and Component Item. Post as Receive.
        InventorySetup.Get();
        ProductionQuantity := LibraryRandom.RandInt(Quantity);  // Using Random value of Quantity for Production Quantity make sure Prod. Quantity less thant Quantity.

        ItemNo :=
          SetupProductionItem(
            ProductionItem."Costing Method"::Standard, ProductionItem."Replenishment System"::"Prod. Order",
            LibraryRandom.RandDec(10, 2));
        Component := SetupProductionItem(ProductionItem."Costing Method"::FIFO, ProductionItem."Replenishment System"::Purchase, 0);
        Component2 := SetupProductionItem(ProductionItem."Costing Method"::FIFO, ProductionItem."Replenishment System"::Purchase, 0);

        // Update Production BOM No. on Item.
        ProductionItem.Get(ItemNo);
        ProductionItem.Validate(
          "Production BOM No.", LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Component, Component2, 1));
        ProductionItem.Modify(true);

        // Set FALSE to Automatic Cost Posting and Expected Cost Posting fields, Create Purchase Order for all Component Item and Post as Receive.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type"::Item,
          InventorySetup."Average Cost Period"::Day);
        CreatePurchaseOrder(PurchaseLine, Component, Quantity, '');
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Component2, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.

        // Create Production Order, Refresh, Post Production Jounral and change status from Release to Finish.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProductionItem."No.", ProductionQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);  // Using TRUE for Calculate Lines and Calc Component parameter.
        PostProductionJournal(ProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Run Adjust Cost Item Entries Report, Reopen Purchase Order and Post as Invoice after updating Unit Price on all Lines.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo(ItemNoFilter, ProductionItem."No.", Component, Component2), '');
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        UpdatePurchaseLineDirectUnitCost(DirectUnitCost, PurchaseHeader."No.");
        TotalInventoryValue := ProductionQuantity * DirectUnitCost * 2;  // DirectUnitCost multiplying by 2 because for both Purchase lines we used same value.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);   // Post as Invoice.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo(ItemNoFilter, ProductionItem."No.", Component, Component2), '');

        // Exercise: Run Post Inventory Cost To GL Report.
        PostValueEntryToGL.SetRange("Item No.", ProductionItem."No.");
        PostValueEntryToGL.SetRange("Posting Date", WorkDate());
        RunPostInventoryCostToGL(PostValueEntryToGL, PostMethod::"per Entry", '', EntriesPostedToGLMsg);

        // Verify: Verify record count in Post Value Entry record,Total Inventory Cost on Inventory Cost To GL Report and  Quantity Expected/Actual Cost ACY for Component Item in Item Ledger Entry.
        VerifyInventoryCostToGLReport(TotalInventoryValue);
        FindPostValueEntry(PostValueEntryToGL, Component);
        Assert.IsTrue(PostValueEntryToGL.Count > 1, RecordCountError);
        repeat
            PostValueEntryToGL.TestField("Posting Date", WorkDate());
        until PostValueEntryToGL.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryReportPostingDateError()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Verify Posting Date error on Calculate Inventory report.

        // Setup: Create Item Journal Batch.
        Initialize();
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");

        // Exercise.
        asserterror RunCalculateInventoryReport(ItemJournalBatch, '', '', 0D);  // Use blank value for Item No., Location Code and 0D for Posting Date.

        // Verify.
        Assert.ExpectedError(PostingDateError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryListReportForTrackingAndQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        LotNo: Code[50];
    begin
        // Verify the Item Tracking numbers and Quantity on the Physical Inventory List report if the option "Show Serial/Lot No" and "Show Qty (Calculated)" are checked.
        LotNo := PhysicalInventoryListReport(PurchaseLine, true, true);  // Booleans value are respective to ShowQuantity and ShowTracking.

        // Verify.
        VerifyQuantityOnPhysInventoryListReport(PurchaseLine);
        LibraryReportDataset.AssertCurrentRowValueEquals('ReservEntryBufferLotNo', LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryListReportWithShowTrackingAndShowQuantityAsFalse()
    var
        PurchaseLine: Record "Purchase Line";
        LotNo: Code[50];
    begin
        // Verify the Item Tracking numbers and Quantity are not shown on the Physical Inventory List report if the option "Show Serial/Lot No" and "Show Qty (Calculated)" are not checked.
        LotNo := PhysicalInventoryListReport(PurchaseLine, false, false);  // Booleans value are respective to ShowQuantity and ShowTracking.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        asserterror LibraryReportDataset.AssertElementWithValueExists('ReservEntryBufferLotNo', LotNo);

        // Rather than testing that the value is not visible (layout), check that it is not configured to be visible but has a correct value
        LibraryReportDataset.AssertElementWithValueExists('ShowQtyCalculated', false);   // Show qty is false
        LibraryReportDataset.AssertElementWithValueExists('QtyCalculated_ItemJnlLin', PurchaseLine.Quantity);
    end;

    local procedure PhysicalInventoryListReport(var PurchaseLine: Record "Purchase Line"; ShowQuantity: Boolean; ShowTracking: Boolean): Code[20]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Item with Tracking Code, create and post Purchase Order with Tracking Lines. Run Calculate Inventory on Phys. Inventory Journal.
        Initialize();
        CreatePurchaseOrderWithItemTracking(PurchaseLine, '', false);  // Blank value is for Location Code.
        FindReservationEntry(ReservationEntry, PurchaseLine."No.");
        PostPurchaseOrder(PurchaseLine, true, false);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        RunCalculateInventoryReport(ItemJournalBatch, PurchaseLine."No.", PurchaseLine."Location Code", WorkDate());

        // Enqueue value for message handler.
        LibraryVariableStorage.Enqueue(ShowQuantity);
        LibraryVariableStorage.Enqueue(ShowTracking);

        // Exercise:
        RunPhysInventoryListReport(ItemJournalBatch);
        exit(ReservationEntry."Lot No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryListReportWithMultipleBatches()
    var
        PurchaseLine: Record "Purchase Line";
        ItemJournalTemplate: Record "Item Journal Template";
        LotNo: Code[50];
    begin
        // Verify the Item Tracking numbers and Quantity on the Physical Inventory List report on multiple batches and templates
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::"Phys. Inventory");
        ItemJournalTemplate.FindFirst();

        LotNo :=
          PhysicalInventoryListReportMultipleTemplatesAndBatches(
            PurchaseLine, true, true,
            LibraryRandom.RandIntInRange(2, 5), LibraryRandom.RandIntInRange(2, 5));

        // Verify.
        VerifyQuantityOnPhysInventoryListReport(PurchaseLine);
        LibraryReportDataset.AssertCurrentRowValueEquals('ReservEntryBufferLotNo', LotNo);

        // Tear Down
        ItemJournalTemplate.SetFilter(Name, '<>%1', ItemJournalTemplate.Name);
        ItemJournalTemplate.DeleteAll();
    end;

    local procedure PhysicalInventoryListReportMultipleTemplatesAndBatches(var PurchaseLine: Record "Purchase Line"; ShowQuantity: Boolean; ShowTracking: Boolean; TemplateCount: Integer; BatchCount: Integer): Code[20]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ReservationEntry: Record "Reservation Entry";
        TemplateIndex: Integer;
        BatchIndex: Integer;
    begin
        // Setup: Create Item with Tracking Code, create and post Purchase Order with Tracking Lines. Run Calculate Inventory on Phys. Inventory Journal.
        Initialize();
        CreatePurchaseOrderWithItemTracking(PurchaseLine, '', false);  // Blank value is for Location Code.
        FindReservationEntry(ReservationEntry, PurchaseLine."No.");
        PostPurchaseOrder(PurchaseLine, true, false);
        for TemplateIndex := 1 to TemplateCount do begin
            LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
            ItemJournalTemplate.Validate(Type, ItemJournalTemplate.Type::"Phys. Inventory");
            ItemJournalTemplate.Modify(true);
            for BatchIndex := 1 to BatchCount do begin
                LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
                RunCalculateInventoryReport(ItemJournalBatch, PurchaseLine."No.", PurchaseLine."Location Code", WorkDate());
            end;
        end;

        // Enqueue value for message handler.
        LibraryVariableStorage.Enqueue(ShowQuantity);
        LibraryVariableStorage.Enqueue(ShowTracking);

        // Exercise:
        RunPhysInventoryListReport(ItemJournalBatch);
        exit(ReservationEntry."Lot No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryListReportWithLocationAndBin()
    var
        Bin: Record Bin;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Verify Physical Inventory List report for non-warehouse location with Bin.

        // Setup: Create Item with Tracking Code, create and post Purchase Order with Tracking Lines. Run Calculate Inventory on Phys. Inventory Journal.
        Initialize();
        CreateLocationWithBin(Bin);
        CreatePurchaseOrder(PurchaseLine, CreateLotTrackedItem(false), LibraryRandom.RandInt(10), Bin."Location Code");  // Use random value for Quantity.
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify(true);
        PurchaseLine.OpenItemTrackingLines();
        FindReservationEntry(ReservationEntry, PurchaseLine."No.");
        PostPurchaseOrder(PurchaseLine, true, false);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        RunCalculateInventoryReport(ItemJournalBatch, PurchaseLine."No.", PurchaseLine."Location Code", WorkDate());

        // Enqueue value for message handler.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);

        // Exercise:
        RunPhysInventoryListReport(ItemJournalBatch);

        // Verify.
        VerifyQuantityOnPhysInventoryListReport(PurchaseLine);
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_ItemJournalLine', PurchaseLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_ItemJournalLine', PurchaseLine."Bin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('ReservEntryBufferLotNo', ReservationEntry."Lot No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryListReportWithWhseLocation()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
    begin
        // Verify Physical Inventory List report for warehouse location.

        // Setup: Create Item with Tracking Code, create and post Purchase Order with Tracking Lines. Run Calculate Inventory on Phys. Inventory Journal.
        Initialize();
        LotNo := CreateAndPostPurchaseOrderWithWMSLocation(PurchaseLine, false);
        RegisterWarehouseActivity(WarehouseActivityLine, PurchaseLine."Document No.");
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        RunCalculateInventoryReport(ItemJournalBatch, PurchaseLine."No.", PurchaseLine."Location Code", WorkDate());

        // Enqueue value for message handler.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);

        // Exercise:
        RunPhysInventoryListReport(ItemJournalBatch);

        // Verify.
        VerifyQuantityOnPhysInventoryListReport(PurchaseLine);
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_ItemJournalLine', PurchaseLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_ItemJournalLine', PurchaseLine."Bin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('ReservEntryBufferLotNo', LotNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseCalculateInventoryReportRegisteringDateError()
    var
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        // Verify Registering Date error on Whse. Calculate Inventory report.

        // Setup: Create Warehouse Location. Create Warehouse Journal Batch.
        Initialize();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);  // Use 1 for Bins per Zone.
        CreateWhseJournalBatch(WarehouseJournalBatch, Location.Code);

        // Exercise.
        asserterror CalculateWarehouseInventory(WarehouseJournalBatch, '', 0D);  // Use blank value for Item No., Location Code and 0D for Posting Date.

        // Verify.
        Assert.ExpectedError(RegisteringDateError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhsePhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhsePhysInventoryListReportShowTrackingAsTrue()
    var
        LotNo: Code[50];
    begin
        // Verify Whse. Phys. Inventory List report when "Show Serial/Lot No" option is checked, if warehouse tracking is defined for a specific Item Tracking Code.
        LotNo := WhsePhysInventoryListReport(true, true, true);  // Booleans value are respective to ShowQuantity, ShowTracking, LotWarehouseTracking.
        LibraryReportDataset.AssertCurrentRowValueEquals('LotNo_WarehuseJournalLine', LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhsePhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhsePhysInventoryListReportShowTrackingAsFalse()
    var
        LotNo: Code[50];
    begin
        // Verify Whse. Phys. Inventory List report when "Show Serial/Lot No" option is not checked, if warehouse tracking is defined for a specific Item Tracking Code.
        LotNo := WhsePhysInventoryListReport(true, false, true);  // Booleans value are respective to ShowQuantity, ShowTracking, LotWarehouseTracking.
        LibraryReportDataset.AssertElementWithValueExists('LotNo_WarehuseJournalLine', LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhsePhysInventoryListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhsePhysInventoryListReportWithNonWarehouseTracking()
    var
        LotNo: Code[50];
    begin
        // Verify Whse. Phys. Inventory List report when "Show Serial/Lot No" option is checked, if warehouse tracking is not defined for a specific Item Tracking Code.
        LotNo := WhsePhysInventoryListReport(true, true, false);  // Booleans value are respective to ShowQuantity, ShowTracking, LotWarehouseTracking.
        LibraryReportDataset.AssertElementWithValueExists('LotNo_WarehuseJournalLine', LotNo);
    end;

    local procedure WhsePhysInventoryListReport(ShowQuantity: Boolean; ShowTracking: Boolean; LotWarehouseTracking: Boolean): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        // Setup: Create Item with Tracking Code, create Purchase Order with Tracking Lines. Create and post Warehouse Receipt. Register Put-away. Run Calculate Inventory on Whse. Phys. Inventory Journal.
        Initialize();
        CreateAndPostPurchaseOrderWithWMSLocation(PurchaseLine, LotWarehouseTracking);
        RegisterWarehouseActivity(WarehouseActivityLine, PurchaseLine."Document No.");
        CreateWhseJournalBatch(WarehouseJournalBatch, PurchaseLine."Location Code");
        CalculateWarehouseInventory(WarehouseJournalBatch, PurchaseLine."No.", WorkDate());

        // Enqueue value for message handler.
        LibraryVariableStorage.Enqueue(ShowQuantity);
        LibraryVariableStorage.Enqueue(ShowTracking);

        // Exercise:
        RunWhsePhysInventoryListReport(WarehouseJournalBatch);

        // Verify.
        VerifyWhsePhysInventoryListReport(WarehouseActivityLine);
        exit(WarehouseActivityLine."Lot No.");
    end;

    [Test]
    [HandlerFunctions('InventoryCostVarianceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryCostVarianceReportForStandardItem()
    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        // Verify Inventory - Cost Variance Report for Item with Costing Method Standard.

        // Setup: Create Item with Costing method Standard, Create and Post Purchase Order.
        Initialize();
        PostPurchaseOrderForVariance(Item, Item."Costing Method"::Standard);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.FindFirst();

        // Exercise.
        RunInventoryCostVarianceReport(Item."No.");

        // Verify.
        VerifyInventoryCostVarianceReport(Item."No.", ValueEntry."Cost Amount (Actual)", Round(ValueEntry."Cost per Unit"));
    end;

    [Test]
    [HandlerFunctions('InventoryCostVarianceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryCostVarianceReportForNonStandardItem()
    var
        Item: Record Item;
    begin
        // Verify Inventory - Cost Variance Report for Item with Costing Method other than Standard.

        // Setup: Create Item with Costing method Standard, Create and Post Purchase Order.
        Initialize();
        PostPurchaseOrderForVariance(Item, Item."Costing Method"::FIFO);

        // Exercise.
        RunInventoryCostVarianceReport(Item."No.");

        // Verify.
        VerifyInventoryCostVarianceReport(Item."No.", 0, 0);  // Take 0 value since no Value Entry is created.
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentNoPerPostingGroupError()
    begin
        // Verify Document No. Error on Post Invt. Cost to G/L - Test Report with Posting Method Per Posting Group.
        RunPostInvtCostToGLTestReport(PostMethod::"per Posting Group", '', PerPostingGroupError);
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLTestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentNoPerEntryError()
    begin
        // Verify Document No. Error on Post Invt. Cost to G/L - Test Report with Posting Method Per Entry.
        RunPostInvtCostToGLTestReport(PostMethod::"per Entry", LibraryUtility.GenerateGUID(), PerEntryError);
    end;

    local procedure RunPostInvtCostToGLTestReport(PostToGLMethod: Option; DocumentNo: Code[20]; Error: Text[1024])
    var
        PostInvtCostToGLTest: Report "Post Invt. Cost to G/L - Test";
    begin
        // Setup.
        Initialize();
        Clear(PostInvtCostToGLTest);
        LibraryVariableStorage.Enqueue(PostToGLMethod);
        LibraryVariableStorage.Enqueue(DocumentNo);
        Commit();  // Commit is required to run the Report.

        // Exercise.
        asserterror PostInvtCostToGLTest.Run();

        // Verify:
        Assert.ExpectedError(StrSubstNo(Error, PostToGLMethod));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,PostInvtCostToGLTestPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnPostInvtCostToGLTestReport()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostInvtCostToGLTest: Report "Post Invt. Cost to G/L - Test";
        ItemNo: Code[20];
    begin
        // Verify Dimension Entry on Post Invt. Cost to G/L - Test Report.

        // Setup: Create Item, create and Post Purchase Order, Adjust Cost Item entries.
        Initialize();
        ItemNo :=
          SetupProductionItem(Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, LibraryRandom.RandDec(10, 2));  // Use Random for Standard Cost.
        UpdateItemDimension(DefaultDimension, ItemNo);
        CreatePurchaseOrder(PurchaseLine, ItemNo, LibraryRandom.RandInt(100), '');  // Use Random for Qunatity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Clear(PostInvtCostToGLTest);
        LibraryVariableStorage.Enqueue(PostMethod::"per Entry");
        LibraryVariableStorage.Enqueue('');  // Blank for Document No.
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostInvtCostToGLTest.SetTableView(PostValueEntryToGL);
        Commit();  // Commit is required to run the Report.

        // Exercise: Run Post Invt. Cost To G/L Test Report.
        PostInvtCostToGLTest.Run();

        // Verify: Verify Dimension Entry on Post Invt. Cost to G/L - Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemValueEntry__Item_No__', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DimText',
          DefaultDimension."Dimension Code" + ' - ' + DefaultDimension."Dimension Value Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,PostInventoryCostToGLRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnPostInvtCostToGLReportRunPerPostingGroup()
    var
        DefaultDimension: Record "Default Dimension";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ItemNo: Code[20];
        Qty: array[2] of Decimal;
        UnitCost: array[2] of Decimal;
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Post Inventory Cost to GL] [Dimension]
        // [SCENARIO 223070] Post Inventory Cost to G/L report run per posting group should show sum of posted amounts by dimensions.
        Initialize();

        // [GIVEN] Item with default dimension code "D" and its value "V".
        ItemNo := CreateItem();
        UpdateItemDimension(DefaultDimension, ItemNo);

        // [GIVEN] Two purchase orders for the item are posted with receipt and invoice option. Overall posted amount = "X".
        for i := 1 to ArrayLen(Qty) do begin
            Qty[i] := LibraryRandom.RandInt(10);
            UnitCost[i] := LibraryRandom.RandDec(10, 2);
            Amount += Qty[i] * UnitCost[i];
            CreateAndPostPurchaseOrder(ItemNo, Qty[i], UnitCost[i]);
        end;

        // [WHEN] Run "Post inventory cost to G/L" report per posting group.
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostValueEntryToGL.SetRange("Posting Date", WorkDate());
        RunPostInventoryCostToGL(
          PostValueEntryToGL, PostMethod::"per Posting Group", LibraryUtility.GenerateGUID(), EntriesPostedToGLMsg);

        // [THEN] The report shows that the posted amount with dimension code "D" and dimension value "V" is equal to "X".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(
          'DimText', StrSubstNo('%1 - %2', DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtPostBufAmount', Amount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerInvtSetup')]
    [Scope('OnPrem')]
    procedure GLAccountDimensionCheckOnNewValueEntryWithZeroAmountShipmentAndInvoice()
    var
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        DimensionCode: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to GL]
        // [SCENARIO 379969] Dimension check of G/L Account, which will be used on posting to G/L, should be performed on new Value Entry with zero Cost Amount (Actual).
        Initialize();

        // [GIVEN] Automatic Cost Posting is set to TRUE in Inventory Setup.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");

        // [GIVEN] Item "I" with no unit cost.
        // [GIVEN] Location "L" with Inventory Posting Setup and mandatory Dimension for "Inventory Account".
        CreateItemAndLocationWithMandatoryDimForInvtAccount(ItemNo, LocationCode, DimensionCode, GLAccountNo);

        // [GIVEN] Sales Order for Item "I" on Location "L".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), ItemNo,
          LibraryRandom.RandInt(10), LocationCode, WorkDate());

        // [WHEN] Post Sales Order with "Ship & Invoice" option.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error message about lack of mandatory Dimension is raised.
        Assert.ExpectedError(StrSubstNo(DimensionMandatoryErr, DimensionCode, GLAccountNo));
    end;

    [Test]
    [HandlerFunctions('MessageHandlerInvtSetup')]
    [Scope('OnPrem')]
    procedure GLAccountDimensionCheckOnNewValueEntryWithZeroAmountShipment()
    var
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        DimensionCode: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to GL]
        // [SCENARIO 303697] G/L Posting check performed on new Value Entry with zero Cost Amount (Actual) when Post Shipment where no G/L Entries are created
        Initialize();

        // [GIVEN] Automatic Cost Posting is set to TRUE in Inventory Setup.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type", InventorySetup."Average Cost Period");

        // [GIVEN] Item "I" with no unit cost.
        // [GIVEN] Location "L" with Inventory Posting Setup and mandatory Dimension for "Inventory Account".
        CreateItemAndLocationWithMandatoryDimForInvtAccount(ItemNo, LocationCode, DimensionCode, GLAccountNo);

        // [GIVEN] Sales Order for Item "I" on Location "L".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), ItemNo,
          LibraryRandom.RandInt(10), LocationCode, WorkDate());

        // [WHEN] Post Sales Order with "Ship" option.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Error message about lack of mandatory Dimension is raised.
        Assert.ExpectedError(StrSubstNo(DimensionMandatoryErr, DimensionCode, GLAccountNo));
    end;

    [Test]
    [HandlerFunctions('PostInventoryCostToGLRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GenBusPostingGroupForSkippedValuesInPostInvtCostToGLReport()
    var
        ValueEntry: Record "Value Entry";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ItemNo: Code[20];
        GenBusPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Post Inventory Cost to GL]
        // [SCENARIO 379963] "Gen. Bus. Posting Group" column in skipped value entries section of "Post Inventory Cost to G/L" report should show "Gen. Bus. Posting Group" of Value Entries.
        Initialize();

        // [GIVEN] Posted Purchase Order with "Receive & Invoice" option.
        ItemNo := CreateItem();
        CreateAndPostPurchaseOrder(ItemNo, LibraryRandom.RandInt(10), LibraryRandom.RandDec(10, 2));
        // [GIVEN] Value Entry for posted Purchase is found. ValueEntry."Gen. Bus. Posting Group" = "X".
        // [GIVEN] Set "Cost Posted to G/L" = "Cost Amount (Actual)" in Value Entry so it will be skipped during posting to G/L.
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
        GenBusPostingGroupCode := ValueEntry."Gen. Bus. Posting Group";
        ValueEntry."Cost Posted to G/L" := ValueEntry."Cost Amount (Actual)";
        ValueEntry."Cost Posted to G/L (ACY)" := ValueEntry."Cost Amount (Actual) (ACY)";
        ValueEntry.Modify();

        // [WHEN] Run "Post Inventory Cost to G/L" batch job on Item.
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostValueEntryToGL.SetRange("Posting Date", WorkDate());
        RunPostInventoryCostToGL(PostValueEntryToGL, PostMethod::"per Entry", '', NothingToPostToGLMsg);

        // [THEN] "Gen. Bus. Posting Group" in the Skipped Entries section of the resulting report is equal to "X".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_SkippedValueEntry', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('GenBusPostingGroup_SkippedValueEntry', GenBusPostingGroupCode);
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValueOnInventoryValuationAfterAdjustCostItemEntries()
    var
        ItemNo: Code[20];
        InvtValue: Decimal;
    begin
        // Check Inventory Value exist on Inventory Valuation Report.

        // Setup: Create Item, Post Item Journal and Run Adjust Cost Item Entries.
        Initialize();
        ItemNo := CreateItemAndRunAdjustCostItemEntries();

        // Exercise: Run  Inventory Valuation Report.
        RunInventoryValuationReportWithPage(ItemNo);

        // Verify: Verify Inventory Value exist on Inventory Valuation Report.
        LibraryReportDataset.LoadDataSetFile();
        InvtValue := CalculateInventoryValue(ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('EndingInvoicedQty', InvtValue);
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValueOnItemAgeCompositionValueAfterAdjustCostItemEntries()
    var
        ItemNo: Code[20];
    begin
        // Check Inventory Value exist on Item Age Composition Value Report.

        // Setup: Create Item, Post Item Journal and Run Adjust Cost Item Entries.
        Initialize();
        ItemNo := CreateItemAndRunAdjustCostItemEntries();

        // Exercise: Run Item Age Composition Value Report.
        RunItemAgeCompositionValueReport(ItemNo);

        // Verify: Verify Inventory Value exist on Item Age Composition Value Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalInvtValue_Item', CalculateInventoryValue(ItemNo));
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler,InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValueAfterAdjustCostItemEntriesOnInventoryValuationReport()
    var
        InventoryValue: Variant;
        ItemNo: Code[20];
    begin
        // Test Inventory Value on Item Age Composition - Value Report as equal to Inventory Valuation after executing the Adjust Cost Item Entries.

        // Setup: Create Item, Post Item Journal,Run Adjust Cost Item Entries and Get Inventory Value from Item Age Composition - Value Report.
        Initialize();
        ItemNo := CreateItemAndRunAdjustCostItemEntries();
        RunItemAgeCompositionValueReport(ItemNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('TotalInvtValue_Item', InventoryValue);

        // Exercise: Run Inventory Valuation Report.
        RunInventoryValuationReportWithPage(ItemNo);

        // Verify: Verify Inventory Value exist on "Inventory Valuation" Report is Same as "Item Age Composition - Value" Report Inventory Value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('EndingInvoicedValue', InventoryValue);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerInvtSetup,CalculateStdCostMenuHandler,ProductionJournalPageHandler,ConfirmHandlerInvSetup,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValueOfWIPAfterRunningInventoryValuationWIPReport()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        ProductionItem: Record Item;
        ProductionOrder: Record "Production Order";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ConsumptionDocumentNo: Code[20];
    begin
        // Run the Inventory Valuation - WIP report for Starting Date greater than Revaluation Journal Posting Date.
        // Verify values on generated report should be Zero.

        // Setup: Update Automatic Cost Posting on Inventory Setup.
        Initialize();
        ExecuteUIHandlers();
        LibraryInventory.UpdateInventorySetup(InventorySetup, true, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // Create Inventory for Child Item and Update Production BOM No. on Parent Item.
        Item.Get(SetupProductionItem(Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase, 0));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostItemJournalLineWithLocation(ItemJournalLine, Item."No.", Location.Code);
        CreateAndUpdateProductionItem(ProductionItem, Item."No.", LibraryRandom.RandDec(10, 2));
        CalculateStandardCost.CalcItem(ProductionItem."No.", false);

        // Create and Post Purchase Order.Create Production Order and Refresh Post Production Jounral.
        CreatAndPostPurchaseOrder(Item."No.", Location.Code);
        CreateAndRefreshRelProdOrder(ProductionOrder, ProductionItem."No.", Location.Code, LibraryRandom.RandDec(10, 2));
        PostProductionJournalWithDate(ProductionOrder, WorkDate());

        // Post Consumption and Output Journal with Negative Quantity and Post Production Journal with greated than Work Date,also change status from Release to Finish..
        ConsumptionDocumentNo := CreateAndPostItemJournalLineWithConsumption(Item."No.", ProductionOrder."No.", Location.Code);
        CreateAndPostOutputJournal(ProductionOrder."Source No.", ProductionOrder."No.", -1 * LibraryRandom.RandInt(5),
          FindItemLedgerEntry(ProductionOrder."Source No.", ConsumptionDocumentNo, ItemLedgerEntry."Entry Type"::Output), false);
        PostProductionJournalWithDate(ProductionOrder, CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate()));
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Run Adjust Cost Item Entries and Post Revaluation Journal After one Month.
        LibraryCosting.AdjustCostItemEntries(ProductionOrder."Source No.", '');
        CreateAndPostItemJournalForRevaluation(Item."No.", CalcDate('<1M>', WorkDate()));
        LibraryCosting.AdjustCostItemEntries(ProductionOrder."Source No.", '');

        // Exercise: Run Inventory Valuation Report greater than Revaluation Posting Date.
        RunInventoryValuationWIPReport(ProductionOrder."No.");

        // Verify: Verify Values on Generated Report should be Blank for related Production Order.
        VerifyValuesOnGeneratedReport(ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemSubstitutionDescriptionWithInterchangeableChecked()
    var
        ItemSubstitution: Record "Item Substitution";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Verify Descriptions for Item Substitution are correct after checking Interchangeable.

        // Setup: Create Item and Item Substitution.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateItemSubstitution(ItemSubstitution, Item."No.");
        Item2.Get(ItemSubstitution."Substitute No.");

        // Exercise: Enable Interchangeable in Item Substitution.
        ItemSubstitution.Validate(Interchangeable, true);
        ItemSubstitution.Modify(true);

        // Verify: Verify Descriptions are correct for two Item Substitution.
        VerifyDescriptionOnItemSubstitution(Item2."No.", Item2.Description);
        VerifyDescriptionOnItemSubstitution(Item."No.", Item.Description);
    end;

    [HandlerFunctions('ItemJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure SetJournalBatchNameFilterOnItemRegisterPage()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemRegisters: TestPage "Item Registers";
    begin
        // Test the filter "Journal Batch Name" set on Item Register is correct.

        // Setup: Create a Item Journal Batch.
        Initialize();
        ItemJournalBatch.FindFirst();
        ItemJournalBatch.CalcFields("Template Type");
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalBatch."Template Type");
        LibraryVariableStorage.Enqueue(ItemJournalBatch.Name); // Enqueue value for ItemJournalBatchesPageHandler.

        // Exercise: Open Item Register Page and set the Journal Batch Name Filter.
        ItemRegisters.OpenView();
        ItemRegisters."Journal Batch Name".Lookup();

        // Verify: Verify the value of Journal Batch Name is correct.
        ItemRegisters."Journal Batch Name".AssertEquals(ItemJournalBatch.Name);
    end;

    [HandlerFunctions('ItemJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure SetJournalBatchNameFilterOnWarehouseRegisterPage()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        WarehouseRegisters: TestPage "Warehouse Registers";
    begin
        // Test the filter "Journal Batch Name" set on Warehouse Register is correct.

        // Setup: Create a Item Journal Batch.
        Initialize();
        ItemJournalBatch.FindFirst();
        ItemJournalBatch.CalcFields("Template Type");
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalBatch."Template Type");
        LibraryVariableStorage.Enqueue(ItemJournalBatch.Name); // Enqueue value for ItemJournalBatchesPageHandler.

        // Exercise: Open Warehouse Register Page and set the Journal Batch Name Filter.
        WarehouseRegisters.OpenView();
        WarehouseRegisters."Journal Batch Name".Lookup();

        // Verify: Verify the value of Journal Batch Name is correct.
        WarehouseRegisters."Journal Batch Name".AssertEquals(ItemJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('ProdJournalPageHandler,ItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerInvSetup')]
    [Scope('OnPrem')]
    procedure ReverseLotNoForOutputJournal()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdItemNo: Code[20];
        FinishedProdOrderNo: Code[20];
        ProdOrderNo: Code[20];
        Qty: Decimal;
    begin
        // Setup: Create Inventory for Child Item and Update Production BOM No. on Parent Item.
        // Create and Refresh two Prod. Orders. Post Production Jounral with Item Tracking. Finish the 1st Prod. Order.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        ProdItemNo := InitSetupForProdItem(Qty);
        FinishedProdOrderNo := PostProdJournalForRelProdOrderWithTracking(ProdItemNo, Qty);
        LibraryManufacturing.ChangeStatusReleasedToFinished(FinishedProdOrderNo);
        ProdOrderNo := PostProdJournalForRelProdOrderWithTracking(ProdItemNo, Qty);

        // Enqueue values for ItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(OptionString::SelectEntries);
        LibraryVariableStorage.Enqueue(ProdOrderNo);
        LibraryVariableStorage.Enqueue(
          FindItemLedgerEntry(ProdItemNo, FinishedProdOrderNo, ItemLedgerEntry."Entry Type"::Output));

        // Exercise: Create Output Journal for Released Prod. Order, on Item Tracking Lines try to reverse the Lot No. of Finished Prod. Order.
        // Verify: Verify that it should not be able to Reverse the Lot No. of the Finished Prod. Order through ItemTrackingLinesHandler.
        CreateOutputJournal(ItemJournalBatch, ProdItemNo, ProdOrderNo, -Qty, 0, true); // True means has Tracking.
    end;

    [Test]
    [HandlerFunctions('InventoryValuationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationWithExpectedCost()
    var
        PurchLine: Record "Purchase Line";
        InventorySetup: Record "Inventory Setup";
    begin
        // Setup: Post Purchase Order as Received
        Initialize();
        InventorySetup.Get();
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup."Expected Cost Posting to G/L" := true;
        InventorySetup.Modify();

        CreatePurchaseOrder(PurchLine, CreateItem(), 10, '');
        PostPurchaseOrder(PurchLine, true, false);
        PurchLine.Find();

        // Exercise: Run Inventory Valuation Report.
        RunInventoryValuationReport(PurchLine."No.", CalcDate('<1M>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // Verify: Verify Inventory Valuation Report.
        VerifyInventoryValuationExpCost(PurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemSubstitutionValidateEmptyItemNo_UT()
    var
        ItemSubstitution: Record "Item Substitution";
        Item: Record Item;
    begin
        // [FEATURE] [UT] [Item Substitution] [Item]
        // [SCENARIO]  Field "Description" in "Item Substitution" record with "Substitute Type" = "Item" is reset to an empty string when setting empty "Substitute No."
        // [GIVEN] "Item Subsitution" "IS" with "Substitution Type" = "Item"
        CreateItemSubstitution(ItemSubstitution, ItemSubstitution.Type::Item, LibraryInventory.CreateItemNo());
        ItemSubstitution.TestField(Description, '');
        // [GIVEN] Item "I" with Description = "D"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] "IS"."Substitution No." = "I"
        ItemSubstitution.Validate("Substitute No.", Item."No.");
        // [GIVEN] "IS".Description = "D"
        ItemSubstitution.TestField(Description, Item.Description);
        // [WHEN] When reset "IS"."Substitution No." = ''
        ItemSubstitution.Validate("Substitute No.", '');
        // [THEN] "IS".Description = ''
        ItemSubstitution.TestField(Description, '');
    end;

    [Test]
    [HandlerFunctions('PostInventoryCostToGLRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleValueEntriesForCapacityNotCapableOfPostingToGLAreShownInSkippedSection()
    var
        ValueEntry: array[2] of Record "Value Entry";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        i: Integer;
    begin
        // [FEATURE] [Post Inventory Cost to GL]
        // [SCENARIO 210793] Multiple value entries for capacity that are not capable of posting due to blank posting groups should be listed in skipped section of Post Inventory to G/L resulting report.
        Initialize();

        // [GIVEN] Two value entries with blank posting groups.
        for i := 1 to ArrayLen(ValueEntry) do
            MockValueEntryForCapacity(ValueEntry[i]);

        // [WHEN] Run "Post Inventory Cost to G/L" batch job on these value entries.
        PostValueEntryToGL.SetFilter("Value Entry No.", '%1|%2', ValueEntry[1]."Entry No.", ValueEntry[2]."Entry No.");
        RunPostInventoryCostToGL(PostValueEntryToGL, PostMethod::"per Entry", '', NothingToPostToGLMsg);

        // [THEN] The skipped entries section of the resulting report contains the value entries.
        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to ArrayLen(ValueEntry) do begin
            LibraryReportDataset.SetRange('EntryNo_SkippedValueEntry', ValueEntry[i]."Entry No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('CostAmt', ValueEntry[i]."Cost Amount (Actual)");
        end;
    end;

    [Test]
    [HandlerFunctions('SalesReservationAvailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReservationAvailMustNotUpdateQtyToShipForLocationWithDirectedPickandPutAway()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineWithLocation: Record "Sales Line";
        SalesLineWithoutLocation: Record "Sales Line";
        Location: Record Location;
        SalesReservationAvail: Report "Sales Reservation Avail.";
    begin
        // [SCENARIO] When running the Sales Reservation Avail. report, items having a location with
        // Directed Put-away and Pick should not have Qty. to Ship updated.
        Initialize();

        // [GIVEN] A sales order with two sales lines, one with a location with Directed Put-away and Pick and one without.
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Directed Put-away and Pick", true);
        Location.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLineWithLocation, SalesHeader, SalesLine.Type::Item, Item."No.", 3);
        LibrarySales.CreateSalesLine(SalesLineWithoutLocation, SalesHeader, SalesLine.Type::Item, Item."No.", 3);
        SalesLineWithLocation."Location Code" := Location.Code;
        SalesLineWithLocation.Modify(true);

        // [WHEN] Running the Sales Reservation Avail. report for the sales order.
        LibraryVariableStorage.Enqueue(true);     // Show sales lines
        LibraryVariableStorage.Enqueue(false);      // Show reservation entries
        LibraryVariableStorage.Enqueue(true);     // Modify qty...
        Commit();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesReservationAvail.SetTableView(SalesLine);
        SalesReservationAvail.Run();

        // [THEN] The sales line with a location with Directed Put-away and Pick should not have Qty. to Ship updated.
        SalesLine.SetRange("Line No.", SalesLineWithLocation."Line No.");
        SalesLine.FindFirst();
        Assert.AreEqual(3, SalesLine."Qty. to Ship", 'Expected qty. to remain unchanged for line with location.');

        // [THEN] The sales line without a location with Directed Put-away and Pick should have Qty. to Ship updated.
        SalesLine.SetRange("Line No.", SalesLineWithoutLocation."Line No.");
        SalesLine.FindFirst();
        Assert.AreEqual(0, SalesLine."Qty. to Ship", 'Expected qty. to be updated for line without location.');
    end;

    [Test]
    [HandlerFunctions('ItemRegisterValueRequestPageHandler')]
    procedure ItemRegisterValueReportWithVariousItemEntryTypes()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemRegister: Record "Item Register";
        Qty: Decimal;
        UnitAmount: Decimal;
    begin
        // [FEATURE] [Item Register - Value]
        // [SCENARIO 414201] Verifying "Item Register - Value" report for various item entry types in one item register entry.
        Initialize();
        Qty := LibraryRandom.RandInt(100);
        UnitAmount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create a positive adjustment and a negative adjustment line in one item journal batch.
        SelectAndClearItemJournalBatch(ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", LibraryInventory.CreateItemNo(), Qty);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", LibraryInventory.CreateItemNo(), Qty);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post both item journal lines in a single transaction.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run "Item Register - Value" report.
        Commit();
        ItemRegister.FindLast();
        ItemRegister.SetRecFilter();
        REPORT.Run(REPORT::"Item Register - Value", true, false, ItemRegister);

        // [THEN] The report prints two lines -
        // [THEN] The first is for the positive adjustment with "Positive Adjmt." cost > 0 and "Negative Adjmt." cost = 0.
        // [THEN] The second is for the negative adjustment with "Positive Adjmt." cost = 0 and "Negative Adjmt." cost < 0.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemEntryTypeTotalCost13', Qty * UnitAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemEntryTypeTotalCost14', 0);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemEntryTypeTotalCost13', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemEntryTypeTotalCost14', -Qty * UnitAmount);
    end;

    [Test]
    [HandlerFunctions('PhysInventoryListRequestPageHandler')]
    procedure PhysicalInventoryListShouldHaveCorrectDecimalQuantity()
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 542153] Calculated quantity rounded in decimal when printing Inventory List.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Store Quantity in Variable.
        Quantity := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Create Purchase Invoice with Item and Stored Quantity.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader,
            PurchaseLine,
            PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorNo(),
            Item."No.",
            Quantity,
            '',
            Today());

        // [GIVEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Select Item Journal Template.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");

        // [GIVEN] Create Item Journal Batch and Validate No. Series.
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate(ItemJournalBatch."No. Series", LibraryERM.CreateNoSeriesCode());
        ItemJournalBatch.Modify(true);

        // [GIVEN] Create Item Journal Line.
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);

        // [GIVEN] Run Calculate Inventory from Item Journal.
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, Today(), false, false);

        // [GIVEN] Store two Variable.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Run Report Phys. Inventory List. 
        Commit();
        Report.Run(Report::"Phys. Inventory List", true, false, ItemJournalBatch);

        // [THEN] Quantity Calculated should be same as Quantity purchased.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('QtyCalculated_ItemJnlLin', Quantity);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Reports - III");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - III");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateInventorySetupCostPosting();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - III");
    end;

    local procedure InitSetupForProdItem(Qty: Decimal): Code[20]
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionItem: Record Item;
        QtyPer: Decimal;
    begin
        Item.Get(SetupProductionItem(Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase, 0));
        QtyPer := LibraryRandom.RandInt(10);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          WorkDate(), LibraryRandom.RandDec(10, 2), 2 * Qty * QtyPer);

        CreateAndUpdateProductionItem(ProductionItem, Item."No.", QtyPer);
        UpdateItemTrackingCodeForItem(ProductionItem, false); // FALSE means do not set Lot Warehouse Tracking.
        exit(ProductionItem."No.");
    end;

    local procedure CreateItemSubstitution(var ItemSubstitution: Record "Item Substitution"; ItemSubstitutionType: Enum "Item Substitution Type"; ItemNo: Code[20])
    begin
        ItemSubstitution.Init();
        ItemSubstitution.Validate(Type, ItemSubstitutionType);
        ItemSubstitution.Validate("No.", ItemNo);
        ItemSubstitution.Validate("Substitute No.", '');
        ItemSubstitution.Insert(true);
    end;

    local procedure CalculateItemLedgerEntryAmount(ItemNo: Code[20]) TotalAmount: Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            TotalAmount += ItemLedgerEntry."Cost Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CalculateInventoryValue(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        exit(Round(Item.Inventory * Item."Unit Cost"));
    end;

    local procedure CalculateWarehouseInventory(WarehouseJournalBatch: Record "Warehouse Journal Batch"; ItemNo: Code[20]; RegisteringDate: Date)
    var
        BinContent: Record "Bin Content";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        BinContent.Init();  // To ignore precal error using INIT.
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", WarehouseJournalBatch."Location Code");
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseCalculateInventory(WarehouseJournalLine, BinContent, RegisteringDate, LibraryUtility.GenerateGUID(), false);
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

    local procedure CreateOutputJournal(var ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; ProductionOrderNo: Code[20]; Quantity: Decimal; AppliesToEntry: Integer; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);

        if Tracking then
            ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure CreateAndPostOutputJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20]; Quantity: Decimal; AppliesToEntry: Integer; Tracking: Boolean)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateOutputJournal(ItemJournalBatch, ItemNo, ProductionOrderNo, Quantity, AppliesToEntry, Tracking);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; PostingDate: Date; UnitAmount: Decimal; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithLocation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          LibraryRandom.RandDec(10, 1));  // Use Random value for Quantity.
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalForRevaluation(ItemNo: Code[20]; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        CreateRevaluationJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, PostingDate, LibraryUtility.GetGlobalNoSeriesCode(), "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ", false);
        RevaluateItemjournalLine(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, Quantity, '');
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
        PostPurchaseOrder(PurchaseLine, true, true);
    end;

    local procedure CreateAndPostPurchaseOrderWithWMSLocation(var PurchaseLine: Record "Purchase Line"; LotWarehouseTracking: Boolean): Code[20]
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);  // Use 1 for Bins per Zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreatePurchaseOrderWithItemTracking(PurchaseLine, Location.Code, LotWarehouseTracking);
        FindReservationEntry(ReservationEntry, PurchaseLine."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseLine."Document No.");
        exit(ReservationEntry."Lot No.");
    end;

    local procedure CreateAndPostItemJournalLineWithConsumption(ItemNo: Code[20]; ProductionOrderNo: Code[20]; LocationCode: Code[10]): Code[20]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Consumption,
          ItemNo, -1 * LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Order No.", ProductionOrderNo);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        exit(ItemJournalLine."Document No.");
    end;

    local procedure CreateAndReceivePurchaseOrder(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndUpdateItem(Item, Item.Reserve::Always, Item."Reordering Policy"::" ", 0, 0, Item."Costing Method"::FIFO, '', '');
        CreatePurchaseOrder(PurchaseLine, Item."No.", LibraryRandom.RandDec(10, 1), '');  // Use random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndRefreshRelProdOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndUpdateItem(var Item: Record Item; Reserve: Enum "Reserve Method"; ReorderingPolicy: Enum "Reordering Policy"; MaximumInventory: Decimal; ReorderPoint: Decimal; CostingMethod: Enum "Costing Method"; ItemTrackingCode: Code[10]; LotNos: Code[20])
    begin
        Item.Get(CreateItem());
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Cost.
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Lot Nos.", LotNos);
        Item.Validate(Reserve, Reserve);
        Item.Modify(true);
    end;

    local procedure CreateAndUpdateProductionItem(var ProductionItem: Record Item; ItemNo: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionItem.Get(
          SetupProductionItem(ProductionItem."Costing Method"::Standard, ProductionItem."Replenishment System"::"Prod. Order",
            LibraryRandom.RandDec(10, 2)));
        ProductionItem.Validate("Production BOM No.",
          LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ItemNo, QtyPer));
        ProductionItem.Modify(true);
    end;

    local procedure CreatAndPostPurchaseOrder(ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LibraryRandom.RandDec(1000, 2), LocationCode);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        exit(LibraryInventory.CreateItem(Item));
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalTemplate: Record "Item Journal Template"; TemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemTrackingCodeLotSpecific(LotWarehouseTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotWarehouseTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemAndRunAdjustCostItemEntries() ItemNo: Code[20]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemNo := CreateItem();
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, WorkDate(), LibraryRandom.RandInt(10),
          LibraryRandom.RandDec(100, 2));
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        exit(ItemNo);
    end;

    local procedure CreateItemAndLocationWithMandatoryDimForInvtAccount(var ItemNo: Code[20]; var LocationCode: Code[10]; var DimensionCode: Code[20]; var GLAccountNo: Code[20])
    var
        Item: Record Item;
        Location: Record Location;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        ItemNo := LibraryInventory.CreateItem(Item);
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        InventoryPostingSetup.Get(Location.Code, Item."Inventory Posting Group");
        CreateMandatoryDefaultDimForGLAccount(DimensionCode, InventoryPostingSetup."Inventory Account");
        GLAccountNo := InventoryPostingSetup."Inventory Account";
    end;

    local procedure CreateLocationWithBin(var Bin: Record Bin)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
    end;

    local procedure CreateLotTrackedItem(LotWarehouseTracking: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCodeLotSpecific(LotWarehouseTracking));  // Use blank value for Serial No.
        exit(Item."No.");
    end;

    local procedure CreateMandatoryDefaultDimForGLAccount(var DimensionCode: Code[20]; GLAccountNo: Code[20])
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode := Dimension.Code;
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, DimensionCode, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithItemTracking(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; LotWarehouseTracking: Boolean)
    begin
        CreatePurchaseOrder(PurchaseLine, CreateLotTrackedItem(LotWarehouseTracking), 1 + LibraryRandom.RandInt(10), LocationCode);  // Add random value to take Quantity more than 1.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateRevaluationJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryUtility.GenerateGUID(); // To rectify the error 'The Item Journal Batch already exists'.
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderAndModifyQuantity(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesLine, ItemNo, LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        OpenSalesOrderToEnterQuantity(SalesHeader."No.", Quantity);
    end;

    local procedure CreateWhseJournalBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::"Physical Inventory");
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
    end;

    local procedure MockValueEntryForCapacity(var ValueEntry: Record "Value Entry")
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::" ";
        ValueEntry."Item Ledger Entry No." := 0;
        ValueEntry."Capacity Ledger Entry No." := LibraryRandom.RandInt(100);
        ValueEntry."Posting Date" := WorkDate();
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Direct Cost";
        ValueEntry."Valued Quantity" := LibraryRandom.RandInt(10);
        ValueEntry."Cost per Unit" := LibraryRandom.RandDec(10, 2);
        ValueEntry."Cost Amount (Actual)" := ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit";
        ValueEntry.Insert();

        PostValueEntryToGL.Init();
        PostValueEntryToGL."Value Entry No." := ValueEntry."Entry No.";
        PostValueEntryToGL."Posting Date" := WorkDate();
        PostValueEntryToGL.Insert();
    end;

    local procedure FindItemLedgerEntry(ItemNo: Code[20]; DocumentNo: Code[20]; EntryType: Enum "Item Ledger Document Type"): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindPostValueEntry(var PostValueEntryToGL: Record "Post Value Entry to G/L"; ItemNo: Code[20])
    begin
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostValueEntryToGL.FindSet();
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
    end;

    local procedure FindSalesShipment(var SalesShipmentLine: Record "Sales Shipment Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure OpenPurchaseOrderToReserve(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchLines.Reserve.Invoke();
    end;

    local procedure OpenSalesOrderToEnterQuantity(No: Code[20]; Quantity: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesOrder.OK().Invoke();
    end;

    local procedure PostItemJournalAndUndoShipment(var SalesLine: Record "Sales Line") DocumentNo: Code[20]
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Create Item with Costing Method Average.
        CreateAndUpdateItem(Item, Item.Reserve::Never, Item."Reordering Policy"::" ", 0, 0, Item."Costing Method"::Average, '', '');  // Pass zero values for Maximum Inventory and Reordering Point.

        // Create and Post Item Journal.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", WorkDate(), Item."Unit Cost",
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Create and Ship Sales Order. Use Random value for calculate Shipment Date.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()),
          ItemJournalLine.Quantity / 2);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Create and Post Item Journal with different Unit Amount. Use Random value for Unit Amount and calculate Posting Date.

        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), LibraryRandom.RandDec(10, 2) +
          Item."Unit Cost", LibraryRandom.RandDec(10, 2));

        // Exercise: Undo the Posted Shipment.
        FindSalesShipment(SalesShipmentLine, DocumentNo, Item."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure PostPurchaseOrder(PurchaseLine: Record "Purchase Line"; Ship: Boolean; Receive: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Ship, Receive);
    end;

    local procedure PostPurchaseOrderForVariance(var Item: Record Item; CostingMethod: Enum "Costing Method")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreateAndUpdateItem(Item, Item.Reserve::Never, Item."Reordering Policy"::"Maximum Qty.", 0, 0, CostingMethod, '', '');
        LibraryVariableStorage.Enqueue(Item."No.");
        CreatePurchaseOrder(PurchaseLine, Item."No.", LibraryRandom.RandDec(10, 2), '');  // Use Random value for Quantity.
        PostPurchaseOrder(PurchaseLine, true, true);
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

    local procedure PostProdJournalForRelProdOrderWithTracking(ItemNo: Code[20]; Qty: Decimal): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryVariableStorage.Enqueue(ItemNo); // Enqueue value for ProdJournalPageHandler.
        LibraryVariableStorage.Enqueue(OptionString::AssignLotNo); // Enqueue value for ItemTrackingLinesHandler.
        CreateAndRefreshRelProdOrder(ProductionOrder, ItemNo, '', Qty);
        PostProductionJournalWithItemTracking(ProductionOrder);
        exit(ProductionOrder."No.");
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostProductionJournalWithDate(var ProductionOrder: Record "Production Order"; Postingdate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(Postingdate);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure PostProductionJournalWithItemTracking(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure RegisterWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RevaluateItemjournalLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Revalued)" - 1);  // Revalue with less than the original Unit Cost.
        ItemJournalLine.Modify(true);
    end;

    local procedure RunCalculateInventoryReport(ItemJournalBatch: Record "Item Journal Batch"; No: Code[20]; LocationCode: Code[10]; PostingDate: Date)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine."Document No." := LibraryUtility.GenerateGUID();
        Item.SetRange("No.", No);
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, PostingDate, false, false);
    end;

    local procedure RunInventoryAvailabilityReport(No: Code[20])
    var
        Item: Record Item;
        InventoryAvailability: Report "Inventory Availability";
    begin
        Clear(InventoryAvailability);
        Item.SetRange("No.", No);
        InventoryAvailability.SetTableView(Item);
        InventoryAvailability.InitializeRequest(true);     // Use TRUE for 'Use stockkeeping unit' field
        InventoryAvailability.CalcNeed(Item, '', '', 0);
        InventoryAvailability.Run();
    end;

    local procedure RunInventoryCostVarianceReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        REPORT.Run(REPORT::"Inventory - Cost Variance", true, false, Item);
    end;

    local procedure RunInventoryValuationReport(No: Code[20]; StartDate: Date; EndDate: Date)
    var
        Item: Record Item;
    begin
        Commit();
        Item.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        REPORT.Run(REPORT::"Inventory Valuation", true, false, Item);
    end;

    local procedure RunItemExpirationReport(No: Code[20])
    var
        Item: Record Item;
        PeriodStartDate: Date;
        PeriodLength: DateFormula;
    begin
        Item.SetRange("No.", No);
        Evaluate(PeriodLength, '<1M>');  // Use 1M for monthly Period.
        PeriodStartDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'y>', WorkDate());         // Adding Random Year to calculate Ending Date.
        LibraryVariableStorage.Enqueue(PeriodStartDate);
        LibraryVariableStorage.Enqueue(PeriodLength);
        REPORT.Run(REPORT::"Item Expiration - Quantity", true, false, Item);
    end;

    local procedure RunItemRegisterReport(ItemJournalLine: Record "Item Journal Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemRegister: Record "Item Register";
    begin
        ItemRegister.SetRange(
          "From Entry No.", FindItemLedgerEntry(
            ItemJournalLine."Item No.", ItemJournalLine."Document No.", ItemLedgerEntry."Entry Type"::Purchase));
        REPORT.Run(REPORT::"Item Register - Value", true, false, ItemRegister);
    end;

    local procedure RunItemSubstitutionsReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        Commit();
        REPORT.Run(REPORT::"Item Substitutions", true, false, Item);
    end;

    local procedure RunInvtValuationCostSpecReport(No: Code[20]; ValuationDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(ValuationDate);
        REPORT.Run(REPORT::"Invt. Valuation - Cost Spec.", true, false, Item);
    end;

    local procedure RunInvtValuationCostSpecReportWithPage()
    var
        InvtValuationCostSpec: Report "Invt. Valuation - Cost Spec.";
    begin
        Clear(InvtValuationCostSpec);
        InvtValuationCostSpec.UseRequestPage(true);
        InvtValuationCostSpec.Run();
    end;

    local procedure RunInventoryValuationReportWithPage(ItemNo: Code[20])
    var
        Item: Record Item;
        StartingDate: Date;
    begin
        StartingDate := 0D;
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(CalcDate('<CY+1Y>', WorkDate()));
        Commit();  // Due to a limitation in Request Page Testability, COMMIT is needed for this case.
        Item.SetRange("No.", ItemNo);
        REPORT.Run(REPORT::"Inventory Valuation", true, false, Item);
    end;

    local procedure RunPhysInventoryListReport(ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalBatch.SetRange(Name, ItemJournalBatch.Name);
        Commit();  // Commit required before running this Report.
        REPORT.Run(REPORT::"Phys. Inventory List", true, false, ItemJournalBatch);
    end;

    local procedure RunSalesReservationAvailReport(No: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", No);
        LibraryVariableStorage.Enqueue(true);    // Show sales line
        LibraryVariableStorage.Enqueue(false);   // Show reservation entries
        LibraryVariableStorage.Enqueue(false);   // Notify qty to ship in order lines
        Commit();
        REPORT.Run(REPORT::"Sales Reservation Avail.", true, false, SalesLine);
    end;

    local procedure RunPostInventoryCostToGL(var PostValueEntryToGL: Record "Post Value Entry to G/L"; PostToGLMethod: Option; DocumentNo: Code[20]; ExpectedResult: Text)
    begin
        LibraryVariableStorage.Enqueue(PostToGLMethod);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpectedResult);
        Commit();
        REPORT.Run(REPORT::"Post Inventory Cost to G/L", true, false, PostValueEntryToGL);
    end;

    local procedure RunPurchaseReservationAvailReport(No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", No);
        LibraryVariableStorage.Enqueue(true);     // Show purchase line
        LibraryVariableStorage.Enqueue(false);    // Show reservation entries
        LibraryVariableStorage.Enqueue(false);    // Modify qty to ship in order lines
        REPORT.Run(REPORT::"Purchase Reservation Avail.", true, false, PurchaseLine);
    end;

    local procedure RunInventoryAvailabilityPlanReport(No: Code[20])
    var
        Item: Record Item;
        PeriodLength: DateFormula;
    begin
        Item.SetRange("No.", No);
        Evaluate(PeriodLength, '<1M>');  // Use 1M for monthly Period.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(PeriodLength);
        Commit();
        REPORT.Run(REPORT::"Inventory - Availability Plan", true, false, Item);
    end;

    local procedure RunItemAgeCompositionValueReport(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Commit();  // Due to a limitation in Request Page Testability, COMMIT is needed for this case.
        Item.SetRange("No.", ItemNo);
        REPORT.Run(REPORT::"Item Age Composition - Value", true, false, Item);
    end;

    local procedure RunWhsePhysInventoryListReport(WarehouseJournalBatch: Record "Warehouse Journal Batch")
    var
        WhsePhysInventoryList: Report "Whse. Phys. Inventory List";
    begin
        WarehouseJournalBatch.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalBatch.SetRange(Name, WarehouseJournalBatch.Name);
        Commit();  // Commit required before running this Report.
        Clear(WhsePhysInventoryList);
        WhsePhysInventoryList.SetTableView(WarehouseJournalBatch);
        WhsePhysInventoryList.Run();
    end;

    local procedure RunInventoryValuationWIPReport(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryVariableStorage.Enqueue(CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), WorkDate()));
        Commit();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Finished);
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupProductionItem(CostingMethod: Enum "Costing Method"; ReplenishmentSystem: Enum "Replenishment System"; StandardCost: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        CreateAndUpdateItem(Item, Item.Reserve::Never, Item."Reordering Policy"::" ", 0, 0, CostingMethod, '', '');
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Standard Cost", StandardCost);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure UpdateAddCurrencySetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateStockkeepingUnit(LocationCode: Code[10]; ItemNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.SetRange("Location Code", LocationCode);
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.FindFirst();
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateInventorySetup(NewAutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", NewAutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateItemDimension(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure UpdatePurchaseLineDirectUnitCost(DirectUnitCost: Decimal; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateReservationEntryExpirationDate(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, ItemNo);
        ReservationEntry.Validate("Expiration Date", WorkDate());
        ReservationEntry.Modify(true);
    end;

    local procedure UpdateItemTrackingCodeForItem(var Item: Record Item; LotWarehouseTracking: Boolean)
    begin
        Item.Validate("Item Tracking Code", CreateItemTrackingCodeLotSpecific(LotWarehouseTracking));
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure VerifyInventoryCostToGLReport(TotalInventoryValue: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        Assert.AreEqual(-TotalInventoryValue, LibraryReportDataset.Sum('WIPInvtAmt'),
          StrSubstNo(ValidationError, WIPInventory, -TotalInventoryValue));
    end;

    local procedure VerifyInventoryAvailabilityReport(ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('LocCode_StockkeepUnit', ItemJournalLine."Location Code");

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ProjAvailBalance', ItemJournalLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('ReordPoint_StockkeepUnit', 0);   // Reorder Point must be 0 for Reordering Policy Lot-For-Lot.
    end;

    local procedure VerifyInventoryCostVarianceReport(ItemNo: Code[20]; TotalVarianceAmount: Decimal; CostPerUnit: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // Variance
        Assert.AreEqual(TotalVarianceAmount, LibraryReportDataset.Sum('Variance'), ValueNotMatchedError);

        // Cost per unit
        LibraryReportDataset.SetRange('ItemNo_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('StandardCost_Item', CostPerUnit);
    end;

    local procedure VerifyInventoryValuationReport(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        ILEAmount: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Item.Get(SalesLine."No.");
        Item.CalcFields(Inventory);
        LibraryReportDataset.SetRange('ItemNo', SalesLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('IncreaseInvoicedQty', Item.Inventory);
        ILEAmount := CalculateItemLedgerEntryAmount(SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('IncreaseInvoicedValue', ILEAmount);
    end;

    local procedure VerifyInventoryValuationExpCost(PurchLine: Record "Purchase Line")
    var
        Item: Record Item;
        ILEAmount: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Item.Get(PurchLine."No.");
        LibraryReportDataset.SetRange('ItemNo', PurchLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('StartingInvoicedQty', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals('StartingExpectedQty', PurchLine."Quantity Received");
        ILEAmount := CalculateItemLedgerEntryAmount(PurchLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('StartingExpectedValue', ILEAmount);
    end;

    local procedure VerifyItemExpirationReport(PurchasedQuantity: Decimal; ItemNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtQty1', PurchasedQuantity); // '... Before' column
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalInvtQty', PurchasedQuantity);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Positive: Boolean; Quantity: Decimal; CostAmountActualACY: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, Positive);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)");
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Cost Amount (Expected) (ACY)", 0);
        Assert.AreNearlyEqual(
          CostAmountActualACY, ItemLedgerEntry."Cost Amount (Actual) (ACY)", LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);
    end;

    local procedure VerifyItemRegisterReport(ItemJournalLine: Record "Item Journal Line")
    begin
        // Verify Invoiced Quantity.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvoicedQuantity_ValueEntry', ItemJournalLine."Quantity (Base)");
    end;

    local procedure VerifyItemSubstitutionsReport(SubstituteNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(SubstituteNo);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Item_Substitution__Substitute_No__', SubstituteNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitCost', Item."Unit Cost");
    end;

    local procedure VerifyInvtValuationCostSpecReport(ItemNo: Code[20])
    var
        Item: Record Item;
        VarDecimal: Variant;
        CostPerUnit: Decimal;
        Revaluation: Decimal;
    begin
        Item.Get(ItemNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // Verify Direct Cost.
        LibraryReportDataset.FindCurrentRowValue('UnitCost1', VarDecimal);
        CostPerUnit := VarDecimal;
        Assert.AreNearlyEqual(Item."Last Direct Cost", CostPerUnit, LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);

        // Verify Revaluation.
        LibraryReportDataset.FindCurrentRowValue('UnitCost2', VarDecimal);
        Revaluation := VarDecimal;
        Assert.AreNearlyEqual(Round(Item."Standard Cost" - Item."Last Direct Cost"),
          Revaluation,
          LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);

        // Verify Quantity.
        Item.CalcFields(Inventory);
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainingQty', Item.Inventory);
    end;

    local procedure VerifySalesReservationAvailReport(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OutstdngQtyBase_SalesLine', SalesLine."Outstanding Quantity");
        SalesLine.CalcFields("Reserved Quantity");
        LibraryReportDataset.AssertCurrentRowValueEquals('ResrvdQtyBase_SalesLine', SalesLine."Reserved Quantity");
    end;

    local procedure VerifyPurchaseReservationAvailReport(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OutstQtyBase_PurchLine', PurchaseLine."Outstanding Quantity");
        PurchaseLine.CalcFields("Reserved Quantity");
        LibraryReportDataset.AssertCurrentRowValueEquals('ReservQtyBase_PurchLine', PurchaseLine."Reserved Quantity");
    end;

    local procedure VerifyQuantityOnInventoryAvailabilityPlanReport(Inventory: Decimal; Quantity: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Inventory_Item', Inventory);
        LibraryReportDataset.AssertCurrentRowValueEquals('ProjAvBalance8', Quantity);
    end;

    local procedure VerifyQuantityOnPhysInventoryListReport(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyCalculated_ItemJnlLin', PurchaseLine.Quantity);
    end;

    local procedure VerifyWhsePhysInventoryListReport(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_WarehouseJournlLin', WarehouseActivityLine."Item No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('QtyCalculated_WhseJnlLine', WarehouseActivityLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_WarehouseJnlLine', WarehouseActivityLine."Location Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('ZoneCode_WarehouseJnlLine', WarehouseActivityLine."Zone Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_WarehouseJnlLine', WarehouseActivityLine."Bin Code");
    end;

    local procedure VerifyValuesOnGeneratedReport(ProductionOrderNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProductionOrder', ProductionOrderNo);
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('ValueEntryCostPostedtoGL', 0);
            LibraryReportDataset.AssertCurrentRowValueEquals('ValueOfOutput', 0);
        end;
    end;

    local procedure VerifyDescriptionOnItemSubstitution(ItemNo: Code[20]; Desc: Text[100])
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        ItemSubstitution.SetRange("Substitute No.", ItemNo);
        ItemSubstitution.FindFirst();
        ItemSubstitution.TestField(Description, Desc);
    end;

    local procedure UpdateInventorySetupCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
    end;

    local procedure ExecuteUIHandlers()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        Message('');
        if Confirm('') then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        Message: Variant;
    begin
        LibraryVariableStorage.Dequeue(Message);
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(Message)) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerInvSetup(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
        ApplToItemEntryNo: Variant;
        OrderNo: Variant;
        TrackingOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);
        TrackingOption := OptionValue;
        case TrackingOption of
            OptionString::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            OptionString::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            OptionString::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    LibraryVariableStorage.Dequeue(OrderNo);
                    LibraryVariableStorage.Dequeue(ApplToItemEntryNo);
                    asserterror ItemTrackingLines."Appl.-to Item Entry".SetValue(ApplToItemEntryNo);
                    Assert.ExpectedError(StrSubstNo(ApplyToItemEntryErr, OrderNo));
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryCostVarianceRequestPageHandler(var InventoryCostVariance: TestRequestPage "Inventory - Cost Variance")
    var
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(FileName);
        InventoryCostVariance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtValuationCostSpecValuationDateHandler(var InvtValuationCostSpec: TestRequestPage "Invt. Valuation - Cost Spec.")
    begin
        InvtValuationCostSpec.ValuationDate.SetValue(0D);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    var
        Message: Variant;
    begin
        LibraryVariableStorage.Dequeue(Message);
        Assert.IsTrue(StrPos(Msg, Message) > 0, Msg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerInvtSetup(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryListRequestPageHandler(var PhysInventoryList: TestRequestPage "Phys. Inventory List")
    var
        ShowQtyCalculated: Variant;
        ShowSerialLotNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowQtyCalculated);
        LibraryVariableStorage.Dequeue(ShowSerialLotNumber);
        PhysInventoryList.ShowCalculatedQty.SetValue(ShowQtyCalculated);
        PhysInventoryList.ShowSerialLotNumber.SetValue(ShowSerialLotNumber);
        PhysInventoryList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLTestPageHandler(var PostInvtCostToGLTest: TestRequestPage "Post Invt. Cost to G/L - Test")
    begin
        PostInvtCostToGLTest.PostingMethod.SetValue(LibraryVariableStorage.DequeueInteger());
        PostInvtCostToGLTest.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        PostInvtCostToGLTest.ShowDimensions.SetValue(true);
        PostInvtCostToGLTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReservationAvailPageHandler(var PurchaseReservationAvail: TestRequestPage "Purchase Reservation Avail.")
    var
        ShowReservationEntries: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowReservationEntries);
        PurchaseReservationAvail.ShowReservationEntries.SetValue(ShowReservationEntries);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesReservationAvailRequestPageHandler(var SalesReservationAvail: TestRequestPage "Sales Reservation Avail.")
    var
        ShowSalesLines: Variant;
        ShowReservationEntries: Variant;
        ModifyQtyToShip: Variant;
    begin
        // True for Show Sales Line, False for 'Show reservation entries' and 'Mofify Qty. To Ship in Order Lines'
        LibraryVariableStorage.Dequeue(ShowSalesLines);
        LibraryVariableStorage.Dequeue(ShowReservationEntries);
        LibraryVariableStorage.Dequeue(ModifyQtyToShip);
        SalesReservationAvail.ShowSalesLines.SetValue(ShowSalesLines);
        SalesReservationAvail.ShowReservationEntries.SetValue(ShowReservationEntries);
        SalesReservationAvail.ModifyQuantityToShip.SetValue(ModifyQtyToShip);

        SalesReservationAvail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhsePhysInventoryListRequestPageHandler(var WhsePhysInventoryList: TestRequestPage "Whse. Phys. Inventory List")
    var
        ShowQtyCalculated: Variant;
        ShowSerialLotNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowQtyCalculated);
        LibraryVariableStorage.Dequeue(ShowSerialLotNumber);
        WhsePhysInventoryList.ShowCalculatedQty.SetValue(ShowQtyCalculated);
        WhsePhysInventoryList.ShowSerialLotNumber.SetValue(ShowSerialLotNumber);
        WhsePhysInventoryList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationRequestPageHandler(var InventoryValuation: TestRequestPage "Inventory Valuation")
    var
        StartingDate: Variant;
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);

        InventoryValuation.StartingDate.SetValue(StartingDate);
        InventoryValuation.EndingDate.SetValue(EndingDate);
        InventoryValuation.IncludeExpectedCost.SetValue(true);
        InventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionValueRequestPageHandler(var ItemAgeCompositionValue: TestRequestPage "Item Age Composition - Value")
    begin
        ItemAgeCompositionValue.EndingDate.SetValue(CalcDate('<CY+1Y>', WorkDate()));
        ItemAgeCompositionValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrderNo: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ProductionOrderNo);
        LibraryVariableStorage.Dequeue(PostingDate);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdJournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.FindFirst();
        ItemJournalLine.OpenItemTrackingLines(false);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationWIPRequestPageHandler(var InventoryValuationWIP: TestRequestPage "Inventory Valuation - WIP")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        InventoryValuationWIP.StartingDate.SetValue(CalcDate('<-CM>', PostingDate));
        InventoryValuationWIP.EndingDate.SetValue(CalcDate('<CM>', PostingDate));
        InventoryValuationWIP.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityRequestPageHandler(var InventoryAvailability: TestRequestPage "Inventory Availability")
    begin
        InventoryAvailability.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemRegisterValueRequestPageHandler(var ItemRegisterValue: TestRequestPage "Item Register - Value")
    begin
        ItemRegisterValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemExpirationRequestPageHandler(var ItemExpiration: TestRequestPage "Item Expiration - Quantity")
    var
        endingDate: Variant;
        periodLength: Variant;
    begin
        LibraryVariableStorage.Dequeue(endingDate);
        LibraryVariableStorage.Dequeue(periodLength);
        ItemExpiration.EndingDate.SetValue(endingDate);
        ItemExpiration.PeriodLength.SetValue(periodLength);

        ItemExpiration.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionRequestPageHandler(var ItemSubstitutions: TestRequestPage "Item Substitutions")
    begin
        ItemSubstitutions.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtValuationCostSpecRequestPageHandler(var InvtValuationCostSpec: TestRequestPage "Invt. Valuation - Cost Spec.")
    var
        ValuationDateVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(ValuationDateVariant);
        InvtValuationCostSpec.ValuationDate.SetValue(ValuationDateVariant);
        InvtValuationCostSpec.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostInventoryCostToGLRequestPageHandler(var PostInventoryCostToGL: TestRequestPage "Post Inventory Cost to G/L")
    begin
        PostInventoryCostToGL.PostMethod.SetValue(LibraryVariableStorage.DequeueInteger());
        PostInventoryCostToGL.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        PostInventoryCostToGL.Post.SetValue(LibraryVariableStorage.DequeueBoolean());

        PostInventoryCostToGL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReservationAvailRequestPageHandler(var PurchaseReservationAvail: TestRequestPage "Purchase Reservation Avail.")
    var
        ShowPurchaseLine: Variant;
        ShowReservationEntries: Variant;
        ModifyQtyToShip: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowPurchaseLine);
        LibraryVariableStorage.Dequeue(ShowReservationEntries);
        LibraryVariableStorage.Dequeue(ModifyQtyToShip);

        PurchaseReservationAvail.ShowPurchLine.SetValue(ShowPurchaseLine);
        PurchaseReservationAvail.ShowReservationEntries.SetValue(ShowReservationEntries);
        PurchaseReservationAvail.ModifyQtuantityToShip.SetValue(ModifyQtyToShip);

        PurchaseReservationAvail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanRequestPageHandler(var InventoryAvailabilityPlan: TestRequestPage "Inventory - Availability Plan")
    var
        UseStockkeepingUnit: Variant;
        PeriodLength: Variant;
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(UseStockkeepingUnit);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(PeriodLength);

        InventoryAvailabilityPlan.StartingDate.SetValue(StartingDate);
        InventoryAvailabilityPlan.PeriodLength.SetValue(PeriodLength);
        InventoryAvailabilityPlan.UseStockkeepUnit.SetValue(UseStockkeepingUnit);

        InventoryAvailabilityPlan.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemJournalBatchesPageHandler(var ItemJournalBatches: TestPage "Item Journal Batches")
    var
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalBatchName);
        ItemJournalBatches.FindFirstField(Name, JournalBatchName);
        ItemJournalBatches.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

