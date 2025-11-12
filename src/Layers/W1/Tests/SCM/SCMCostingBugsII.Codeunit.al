codeunit 137621 "SCM Costing Bugs II"
{
    Permissions = TableData "Item Application Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        TooLowErr: Label 'is too low';
        InventoryValueErr: Label 'Inventory value must be 0 after adjustment.';
        ItemNoAdjustedErr: Label 'Item cost was not adjusted.';
        OutbndEntryIsNotUpdatedErr: Label '"Outbound Entry is Updated" must be TRUE after adjustment.';
        WrongStandardCostVarianceErr: Label 'Item standard cost variance is incorrect.';
        WrongCostAmountErr: Label '%1 after adjustment is incorrect', Comment = 'Field name (Cost Amount (Expected) or Cost Amount (Actual)): Cost Amount (Expected) after adjustment is incorrect';
        InsufficientQtyErr: Label 'You have insufficient quantity of Item %1', Comment = '%1 - Item No.';
        STRMENUWasNotCalledTxt: Label 'STRMENU was not called';
        ValueIsNotPopulatedTxt: Label 'Value is not populated';
        ListOf3SuggestAssignmentStrMenuTxt: Label 'Equally,By Weight,By Volume';
        ListOf4SuggestAssignmentStrMenuTxt: Label 'Equally,By Amount,By Weight,By Volume';

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler,ViewUnappliedEntriesModalHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS219011()
    var
        ValueEntry: Record "Value Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        ApplicationWorksheet: TestPage "Application Worksheet";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();

        // Setup Item.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');

        // Post negative adjustment for item.
        Day1 := WorkDate();
        Qty := LibraryRandom.RandIntInRange(2, 10);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', Qty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Post positive adjustment for item.
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Qty, Day1, LibraryRandom.RandDec(100, 2));

        // Post and invoice Purchase.
        LibraryPurchase.PostPurchaseOrder(PurchaseHeader, Item, '', '', Qty, Day1, LibraryRandom.RandDec(100, 2), true, true);

        // Ship and Invoice Sales.
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty, Day1, LibraryRandom.RandDec(100, 2), true, true);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Remove application between positive and negative adjustment.
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(TempItemLedgerEntry."Entry Type"::"Positive Adjmt."));
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.AppliedEntries.Invoke();

        // Remove application is executed in the page handler.

        // Reapply from the Unapplied Entries page.
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(TempItemLedgerEntry."Entry Type"::"Negative Adjmt."));
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.UnappliedEntries.Invoke();

        // On page exit, reapplication of entries is confirmed.
        ApplicationWorksheet.OK().Invoke();

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        // Item Application Entry is generated correctly.
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", TempItemLedgerEntry."Entry No.");
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField(Quantity, -Qty);
        ItemApplicationEntry.TestField("Cost Application", true);

        // Value Entries for the reapplied Item Ledger Entry are exempted from average cost calculation.
        ValueEntry.SetRange("Item Ledger Entry No.", TempItemLedgerEntry."Entry No.");
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Valued By Average Cost", false);
        until ValueEntry.Next() = 0;

        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS234879()
    var
        ValueEntry: Record "Value Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        ApplicationWorksheet: TestPage "Application Worksheet";
        Day1: Date;
        Qty: Decimal;
    begin
        Initialize();

        // Setup Item.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');

        Day1 := WorkDate();
        Qty := LibraryRandom.RandIntInRange(2, 10);
        // Post positive adjustment for item.
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Qty, Day1, LibraryRandom.RandDec(100, 2));

        // Post negative adjustment.
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', Qty, Day1 + 7, LibraryRandom.RandDec(100, 2));

        // Post positive adjustment for item.
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Qty, Day1 + 4, LibraryRandom.RandDec(100, 2));

        // Post negative adjustment.
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', Qty, Day1 + 1, LibraryRandom.RandDec(100, 2));
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Remove application between positive and negative adjustment.
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(TempItemLedgerEntry."Entry Type"::"Negative Adjmt."));
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.AppliedEntries.Invoke();
        if ApplicationWorksheet.Next() then
            ApplicationWorksheet.AppliedEntries.Invoke();

        // Remove application is executed in the page handler.

        // On page exit, reapplication of entries is confirmed.
        ApplicationWorksheet.OK().Invoke();

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        // Item Application Entry is generated correctly.
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", TempItemLedgerEntry."Entry No.");
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField(Quantity, -Qty);
        ItemApplicationEntry.TestField("Cost Application", false);

        // Value Entries for the reapplied Item Ledger Entry have the Valuation date equal to Posting date.
        ValueEntry.SetRange("Item Ledger Entry No.", TempItemLedgerEntry."Entry No.");
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Valued By Average Cost", true);
            ValueEntry.TestField("Valuation Date", TempItemLedgerEntry."Posting Date");
        until ValueEntry.Next() = 0;

        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [HandlerFunctions('ViewUnappliedEntriesModalHandler')]
    [Scope('OnPrem')]
    procedure TFS251070TFS256704()
    var
        InventorySetup: Record "Inventory Setup";
        ItemJournalLine: Record "Item Journal Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderLine: Record "Prod. Order Line";
        CompItem: Record Item;
        Location: Record Location;
        ApplicationWorksheet: TestPage "Application Worksheet";
        Qty: Decimal;
    begin
        // [FEATURE] [Output Journal] [Production Order]
        // [SCENARIO 251070] Check Adjustment after applying negative Consumption on Production Order
        Initialize();

        // [GIVEN] Setup Parent and Component item.
        // [GIVEN] BOM and Routing.
        // [GIVEN] Purchase Component Item.
        // [GIVEN] Released Production Order.
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateRelProdOrder(ProdOrderLine, Location.Code, CompItem, Qty);

        // [GIVEN] Post Output.
        LibraryManufacturing.OutputJournalExplodeOrderLineRouting(ItemJournalBatch, ProdOrderLine, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // [GIVEN] Post Negative Output applied to previous Output.
        PostNegativeOutput(ItemJournalBatch, ProdOrderLine, Qty, TempItemLedgerEntry."Entry No.");

        // [GIVEN] Post Consumtion Reversal for Component Item
        LibraryManufacturing.CreateConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, CompItem, WorkDate(), Location.Code, '', -Qty, 0);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [GIVEN] Apply Consumption to Negative Consumption from the Unapplied Entries page.
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", CompItem."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(TempItemLedgerEntry."Entry Type"::Consumption));
        ApplicationWorksheet.FILTER.SetFilter(Positive, Format(true));
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.UnappliedEntries.Invoke();

        // [THEN] Verify Adjustment.
        LibraryCosting.CheckAdjustment(CompItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS217346()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        CompItem: Record Item;
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        Initialize();

        // Setup produced and component item.
        LibraryInventory.CreateItem(ParentItem, ParentItem."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), 0, 0, '');
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify();

        LibraryInventory.CreateItem(CompItem, CompItem."Costing Method"::FIFO, 0, 0, 0, '');
        CompItem.Modify();

        // Setup BOM and Routing.
        QtyPer := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, CompItem, QtyPer, '');

        // Purchase component item.
        Qty := LibraryRandom.RandInt(100);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, CompItem, '', '', Qty * QtyPer, WorkDate(), 0, true, false);

        // Released production order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem, '', '', Qty, WorkDate());
        FindProdOrderLine(ProdOrderLine, ProductionOrder);

        // Post output.
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), Qty, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post consumption.
        LibraryManufacturing.CreateConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, CompItem, WorkDate(), '', '', Qty * QtyPer, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Finish Prod. Order.
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + CompItem."No.", '');

        // Invoice purchase with a cost.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostPurchaseInvoiceWithNewUnitCost(PurchaseHeader, LibraryRandom.RandDec(100, 2));

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(ParentItem."No." + '|' + CompItem."No.", '');

        // Verify.
        VerifyPostValueEntryToGL(ProductionOrder);
        LibraryCosting.CheckAdjustment(CompItem);
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler,ViewUnapplEntrSelectNextModalHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS330379()
    var
        Item: Record Item;
        ApplicationWorksheet: TestPage "Application Worksheet";
        PostingDate: array[5] of Date;
        Interval: DateFormula;
    begin
        // Repro steps
        Initialize();
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // Post item journal lines and adjust cost
        Evaluate(Interval, '<5D>');
        PostingDate[1] := WorkDate();
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[1], 1000);
        PostingDate[2] := CalcDate(Interval, WorkDate());
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[2], 1000);
        PostingDate[3] := CalcDate(Interval, PostingDate[2]);
        PostPurchaseJournal(Item, '', '', '', 2, PostingDate[3], 1200);
        PostingDate[4] := CalcDate(Interval, PostingDate[3]);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, PostingDate[4], 0);

        AdjustCostAndVerify(Item."No.", 1100);

        // Reapply the negative adjustment to the 2nd purchase
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(3)); // Negative Adjustment
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.AppliedEntries.Invoke(); // Remove application is executed in the page handler.

        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(3)); // Negative Adjustment
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.UnappliedEntries.Invoke();
        ApplicationWorksheet.OK().Invoke();

        AdjustCostAndVerify(Item."No.", 3400 / 3);

        // Post Sales of the remaining quantity
        LibraryInventory.PostItemJournalLine(
            "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Sale,
             Item, '', '', '', 3, PostingDate[3], 0);

        AdjustCostAndVerify(Item."No.", 3400 / 3);
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS330379NotFixedApplication()
    var
        Item: Record Item;
        ApplicationWorksheet: TestPage "Application Worksheet";
        PostingDate: array[5] of Date;
        Interval: DateFormula;
    begin
        // Repro steps
        Initialize();
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // Post item journal lines and adjust cost
        Evaluate(Interval, '<5D>');
        PostingDate[1] := WorkDate();
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[1], 1000);
        PostingDate[2] := CalcDate(Interval, WorkDate());
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[2], 1000);
        PostingDate[3] := CalcDate(Interval, PostingDate[2]);
        PostPurchaseJournal(Item, '', '', '', 2, PostingDate[3], 1200);
        PostingDate[4] := CalcDate(Interval, PostingDate[3]);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, PostingDate[4], 0);

        AdjustCostAndVerify(Item."No.", 1100);

        // Reapply the negative adjustment by closing worksheet
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(3)); // Negative Adjustment
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.AppliedEntries.Invoke(); // Remove application is executed in the page handler.

        ApplicationWorksheet.OK().Invoke();

        AdjustCostAndVerify(Item."No.", 1100);

        // Post Sales of the remaining quantity
        LibraryInventory.PostItemJournalLine(
            "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Sale,
             Item, '', '', '', 3, PostingDate[3], 0);

        AdjustCostAndVerify(Item."No.", 1100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS330379ApplyInJnl()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PostingDate: array[5] of Date;
        Interval: DateFormula;
    begin
        // Same scenario as in TFS330379 - the negative adjustment is applied to 2nd purchase in item journal
        Initialize();
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // Post item journal lines
        Evaluate(Interval, '<5D>');
        PostingDate[1] := WorkDate();
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[1], 1000);
        PostingDate[2] := CalcDate(Interval, WorkDate());
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[2], 1000);
        PostingDate[3] := CalcDate(Interval, PostingDate[2]);
        PostPurchaseJournal(Item, '', '', '', 2, PostingDate[3], 1200);

        // Post negative adjustment and make a fixed application to second entry
        PostingDate[4] := CalcDate(Interval, PostingDate[3]);
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, "Item Journal Template Type"::Item);
        LibraryInventory.MakeItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, PostingDate[4], ItemLedgerEntry."Entry Type"::"Negative Adjmt.", 1);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Posting Date", PostingDate[2]);
        ItemLedgerEntry.FindFirst();
        ItemJournalLine."Applies-to Entry" := ItemLedgerEntry."Entry No.";
        ItemJournalLine.Insert();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post Sales of the remaining quantity
        LibraryInventory.PostItemJournalLine(
            "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Sale,
             Item, '', '', '', 3, PostingDate[3], 0);

        AdjustCostAndVerify(Item."No.", 3400 / 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS330379ApplyInJnlTryManyInbndFixed()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PostingDate: array[5] of Date;
        Interval: DateFormula;
    begin
        // Same scenario as in TFS330379 - the negative adjustment is applied to 2nd purchase in item journal
        Initialize();
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // Post item journal lines
        Evaluate(Interval, '<5D>');
        PostingDate[1] := WorkDate();
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[1], 1000);
        PostingDate[2] := CalcDate(Interval, WorkDate());
        PostPurchaseJournal(Item, '', '', '', 1, PostingDate[2], 1000);
        PostingDate[3] := CalcDate(Interval, PostingDate[2]);
        PostPurchaseJournal(Item, '', '', '', 2, PostingDate[3], 1200);

        // Post negative adjustment and make a fixed application to second purchase
        // The negative quantity should be higher than the purchase
        PostingDate[4] := CalcDate(Interval, PostingDate[3]);
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, "Item Journal Template Type"::Item);
        LibraryInventory.MakeItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, PostingDate[4], ItemLedgerEntry."Entry Type"::"Negative Adjmt.", 3);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Posting Date", PostingDate[2]);
        ItemLedgerEntry.FindFirst();
        ItemJournalLine."Applies-to Entry" := ItemLedgerEntry."Entry No."; // Quantity in ILE cannot cover negative adjustment
        ItemJournalLine.Insert();

        asserterror LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        Assert.ExpectedError(TooLowErr);
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler,ViewUnapplEntrSelectNextModalHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure NoErrorWhenCloseApplicationWorksheetPage()
    var
        Item: Record Item;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        Initialize();

        // [GIVEN] Set Automatic Cost Adjustment = Always
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Create Item and update Inventory
        CreateItemAndUpdateInventory(Item);

        // [GIVEN] Remove application between positive and negative adjustment.
        ApplicationWorksheet.OpenEdit();
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        FindApplicationWorksheetLine(ApplicationWorksheet, Item."No.", Format(TempItemLedgerEntry."Entry Type"::"Negative Adjmt."));
        ApplicationWorksheet.AppliedEntries.Invoke();

        // Remove application is executed in the ViewAppliedEntriesHandler.

        // [GIVEN] Click Unapplied Entries button on the Application Worksheet page.
        FindApplicationWorksheetLine(ApplicationWorksheet, Item."No.", Format(TempItemLedgerEntry."Entry Type"::"Negative Adjmt."));
        ApplicationWorksheet.UnappliedEntries.Invoke();

        // [GIVEN] Select 2nd entry, click OK to Reapply.
        // Executed in the ViewUnapplEntrSelectNextModalHandler.

        // [GIVEN] Click OK button on the Application Worksheet page.
        ApplicationWorksheet.OK().Invoke();

        // [WHEN] Click Yes to confirm reapplication message.
        // Executed in the ReapplyOpenEntriesConfirmHandler.

        // [THEN] Application Worksheet close without error message.
        // [THEN] Item is not blocked by Application Worksheet.
        Item.Find();
        Item.TestField("Application Wksh. User ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS354142_RoundingAfterTwoAdjustments()
    var
        Item: Record Item;
        Quantity: Decimal;
        CostAmount: Decimal;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');

        Quantity := 3;
        CostAmount := 10;
        PostPositiveAdjustment(Item, '', Quantity, CostAmount, 0);

        PostNegativeAdjmtAndVerify(Item, Item."Unit Cost", 1);
        VerifyOutboudEntriesUpdated(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS354142_AdjmtRoundingPartialShipmentApplication()
    var
        Item: Record Item;
        I: Integer;
        Quantity: Decimal;
        CostAmount: Decimal;
    begin
        Initialize();
        Quantity := 3;
        CostAmount := 10;
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');
        for I := 1 to 3 do
            PostPositiveAdjustment(Item, '', Quantity, CostAmount, 0);

        PostNegativeAdjmtAndVerify(Item, Item."Unit Cost", 7);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS355737_AdjmtRoundingAfterReturn()
    var
        ItemNo: Code[20];
        OrderNo: Code[20];
        InventoryQty: Decimal;
        InventoryAmt: Decimal;
    begin
        Initialize();

        InventoryQty := LibraryRandom.RandIntInRange(100, 200);
        InventoryAmt := LibraryRandom.RandDecInRange(100, 200, 2);

        ItemNo := CreateItemPostPositiveAdjmt(InventoryQty, InventoryAmt);
        OrderNo := CreateOrderAndShip(ItemNo, InventoryQty - 1);
        UndoSalesShipment(OrderNo);
        ChangeSalesLineQuantityAndPost(OrderNo, InventoryQty);

        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        VerifyInventoryAmountIsZero(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS356239_ShipAndReturnOnNegativeInventory()
    var
        Item: Record Item;
        Qty: Integer;
        Amt: Decimal;
    begin
        Initialize();

        Qty := LibraryRandom.RandIntInRange(10, 20);
        Amt := LibraryRandom.RandDec(100, 2);

        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        PostSalesShipmentAndUndo(Item, Qty, Amt);
        PostSalesShipmentAndUndo(Item, Qty + 1, Amt);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        Assert.IsTrue(Item."Cost is Adjusted", ItemNoAdjustedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS359257_VerifyStandardCostVarianceRounding()
    var
        Item: Record Item;
    begin
        Initialize();
        ReadjustStandardCostItem(Item);
        VerifyItemStandardCost(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS359257_VerifyStandardCostVarianceRoundingACY()
    var
        Item: Record Item;
        CurrencyCode: Code[10];
        CurrExchRate: Decimal;
    begin
        Initialize();
        CurrExchRate := LibraryRandom.RandDecInRange(5, 10, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrExchRate, CurrExchRate);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        ReadjustStandardCostItem(Item);
        VerifyItemStandardCostACY(Item."No.", CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS359756_AdjustCostRoundingAfterTwoAdjmts()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify that adjustment rounding is posted after the purchase is completely invoiced

        SaleReceivedAndTransferredItem(Item, PurchaseHeader);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        VerifyInventoryAmountIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS359532_OpenEntriesWithNoCostingChainExcluded()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationBlue: Record Location;
        LocationRed: Record Location;
        BaseQty: Integer;
        SaleQty: Integer;
        UnitCost: Decimal;
    begin
        Initialize();

        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);

        BaseQty := LibraryRandom.RandIntInRange(50, 100);
        SaleQty := BaseQty * 4;
        UnitCost := LibraryRandom.RandDecInRange(100, 200, 2);

        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, LocationBlue.Code, '', SaleQty, WorkDate(), 0);
        MakeSalesLine(SalesHeader, Item."No.", BaseQty * 2);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        LibraryInventory.PostPositiveAdjustment(Item, LocationRed.Code, '', '', BaseQty * 2, CalcDate('<1D>', WorkDate()), UnitCost);
        LibraryInventory.PostReclassificationJournalLine(
          Item, CalcDate('<2D>', WorkDate()), LocationRed.Code, LocationBlue.Code, '', '', '', BaseQty);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        VerifyILECostAmount(Item."No.", -SaleQty * UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ACIEPurchaseReturnWithValuationDateOtherThanPostingAppliedToTransfer()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        Amount: array[2] of Decimal;
        ExpectedCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries]
        // [SCENARIO 371768] Item ledger entries receive average cost when a purchase return having valuation date earlier than its posting date, is applied to a transfer
        Initialize();

        Amount[1] := 3.33333;
        Amount[2] := 7.73737;

        // [GIVEN] Item "I" with "Average" costign method
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');

        // [GIVEN] 2 locations: "L1", "L2"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Item "I" is received on "L1" location (2 pcs + 3 pcs with different cost amount)
        // [GIVEN] 2 psc of item "I" are sold from location "L1"
        LibraryInventory.PostPositiveAdjustment(Item, Location[1].Code, '', '', 3, WorkDate(), Amount[1]);
        LibraryInventory.PostPositiveAdjustment(Item, Location[1].Code, '', '', 2, WorkDate(), Amount[2]);
        LibraryInventory.PostNegativeAdjustment(Item, Location[1].Code, '', '', 2, WorkDate(), Amount[1]);

        // [GIVEN] 2 pcs of item "I" are moved from location "L1" to "L2", Posting Date = WorkDate() + 1 day
        PostItemJournalTransfer(Item, Location[1].Code, Location[2].Code, 2, CalcDate('<1D>', WorkDate()));
        // [GIVEN] 2 pcs of item "I" are moved from location "L2" to "L1", Posting Date = WorkDate() + 1 day
        PostItemJournalTransfer(Item, Location[2].Code, Location[1].Code, 2, CalcDate('<1D>', WorkDate()));

        // [GIVEN] Post purchase return of 2 pcs of item "I" and apply to the transfer entry, Posting Date = WorkDate() + 2 days
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Transfer);
        ItemLedgEntry.FindLast();
        LibraryPatterns.POSTItemJournalLineWithApplication(
          ItemJnlTemplate.Type::Item, ItemJnlLine."Entry Type"::Purchase, Item, Location[1].Code, '', -2,
          CalcDate('<2D>', WorkDate()), Amount[1], ItemLedgEntry."Entry No.");

        // [WHEN] Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // [THEN] Average cost amount on WORKDATE is equal to average cost amount on WorkDate() + 2 days
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgEntry.FindFirst();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        ExpectedCost := ItemLedgEntry."Cost Amount (Actual)";

        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Purchase);
        ItemLedgEntry.FindFirst();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgEntry.TestField("Cost Amount (Actual)", ExpectedCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustRevaluedTransferWithStandardCost()
    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        Location1: Record Location;
        Location2: Record Location;
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        StandardCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Partial Revaluation]
        // [SCENARIO 372019] Revalued inbound transfer entry is adjusted correctly for an item with "Standard" costing method
        Initialize();

        StandardCost := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Item "I" with "Standard" costing method, standard cost = "X"
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, StandardCost);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location1);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);

        // [GIVEN] Purchase order for 3 pcs of item "I" on location "L1". Order is posted as received, not invoiced
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, Location1.Code, '', 3, WorkDate(), Item."Unit Cost", true, false);
        // [GIVEN] Move 3 pcs of item "I" from location "L1" to location "L2"
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), Location1.Code, Location2.Code, '', '', '', 3);
        // [GIVEN] Sell 1 item, posting date = WorkDate() + 1
        LibraryInventory.PostNegativeAdjustment(Item, Location2.Code, '', '', 1, CalcDate('<1D>', WorkDate()), StandardCost * 2);

        // [GIVEN] Remaining 2 pcs of item "I" are revalued on WorkDate() + 2, revalued unit cost = "X" * 1.1
        PostRevaluationJournalLine(Item, CalcDate('<2D>', WorkDate()), StandardCost * 1.1);
        // [GIVEN] 1 item is sold on WorkDate() + 3
        LibraryInventory.PostNegativeAdjustment(Item, Location2.Code, '', '', 1, CalcDate('<3D>', WorkDate()), StandardCost * 2);

        // [GIVEN] Purchase order is invoiced, cost adjusted
        ReleasePurchDoc.Reopen(PurchaseHeader);
        PostPurchaseInvoiceWithNewUnitCost(PurchaseHeader, StandardCost * 3);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] The last remaining item is revalued, new cost = "X" * 1.2
        PostRevaluationJournalLine(Item, CalcDate('<4D>', WorkDate()), StandardCost * 1.2);
        // [GIVEN] Last item is sold
        LibraryInventory.PostNegativeAdjustment(Item, Location2.Code, '', '', 1, CalcDate('<5D>', WorkDate()), StandardCost * 2);

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Cost amount in the inbound transfer entry on location "L2" is "X" * 3.4 (= 2 * 1.1 * X + 1.2 * X)
        GLSetup.Get();
        VerifyRevaluedTransferCostAmount(Item."No.", Location2.Code, Round(StandardCost * 3.4, GLSetup."Amount Rounding Precision"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionCreatingLoopFailsOnDifferentLocations()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        LocationBlue: Record Location;
        LocationRed: Record Location;
    begin
        // [FEATURE] [Manufacturing]
        // [SCENARIO 375615] It is not allowed to post prod. order consumption that would create loop in cost application on 2 different locations
        Initialize();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Production order "P1" producing 2 pcs of item "I" on "Red" location
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, Item."No.", 2);
        ProdOrder.Validate("Location Code", LocationRed.Code);
        ProdOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProdOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine[1], ProdOrder);

        // [GIVEN] Stock of 1 item "I" on "Blue" location
        LibraryInventory.PostPositiveAdjustment(Item, LocationBlue.Code, '', '', 1, WorkDate(), 0);
        // [GIVEN] Post output of 2 pcs of item "I" on "Red" location
        LibraryManufacturing.POSTOutput(ProdOrderLine[1], 2, WorkDate(), Item."Unit Cost");

        // [GIVEN] Production order "P2" consuming and producing the same item "I" on "Blue" location
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, Item."No.", 2);
        ProdOrder.Validate("Location Code", LocationBlue.Code);
        ProdOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProdOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine[2], ProdOrder);

        // [GIVEN] Consume 2 pcs of item "I" from "Red" location for order "P2"
        LibraryManufacturing.POSTConsumption(ProdOrderLine[2], Item, LocationRed.Code, '', 2, WorkDate(), Item."Unit Cost");
        // [GIVEN] Post output of 2 pcs of item "I" on "Blue" location for order "P2"
        LibraryManufacturing.POSTOutput(ProdOrderLine[2], 2, WorkDate(), Item."Unit Cost");

        // [WHEN] Try to consume 2 pcs of item "I" from "Blue" location for production order "P1"
        asserterror LibraryManufacturing.POSTConsumption(ProdOrderLine[1], Item, LocationBlue.Code, '', 2, WorkDate(), Item."Unit Cost");
        // [THEN] Receive an error message "Insufficient quantity of item I", since this consumption would create a loop in cost application
        Assert.ExpectedError(StrSubstNo(InsufficientQtyErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionCreatingLoopFailsOnOneLocation()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
    begin
        // [FEATURE] [Manufacturing]
        // [SCENARIO 375615] It is not allowed to post prod. order consumption that would create loop in cost application on one location
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Production Order "P1" producing item "I"
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, Item."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProdOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine[1], ProdOrder);
        // [GIVEN] Post output of 1 pcs of item "I"
        LibraryManufacturing.POSTOutput(ProdOrderLine[1], 1, WorkDate(), Item."Unit Cost");

        // [GIVEN] Post inventory stock of 1 item "I"
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, WorkDate(), 0);

        // [GIVEN] Production order "P2" producing and consuming item "I"
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdOrder."Source Type"::Item, Item."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProdOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine[2], ProdOrder);
        // [GIVEN] Consume item "I" in order "P2"
        LibraryManufacturing.POSTConsumption(ProdOrderLine[2], Item, '', '', 1, WorkDate(), Item."Unit Cost");
        // [GIVEN] Post output of item "I" in order "P2"
        LibraryManufacturing.POSTOutput(ProdOrderLine[2], 1, WorkDate(), Item."Unit Cost");

        // [WHEN] Try posting consumption of item "I" for production order "P1"
        asserterror LibraryManufacturing.POSTConsumption(ProdOrderLine[1], Item, '', '', 2, WorkDate(), Item."Unit Cost");

        // [THEN] Receive an error message "Insufficient quantity of item I", since this consumption would create a loop in cost application
        Assert.ExpectedError(StrSubstNo(InsufficientQtyErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoConsumptionsCycle()
    var
        Item: Record Item;
        ProductionOrder: array[3] of Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        I: Integer;
    begin
        // [FEATURE] [Adjust Cost - Item Entries]
        // [SCENARIO 381650] Posting of two consumption entries in one batch, when only the second entry creates a cycle in cost application, should fail
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] 3 released production orders "P1", "P2" and "P3". Source item is "I" for all orders.
        for I := 1 to 3 do begin
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder[I], ProductionOrder[I].Status::Released, ProductionOrder[I]."Source Type"::Item, Item."No.", 2);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder[I], false, true, true, true, false);
        end;

        // [GIVEN] Post output of 1 item "I" in order "P2"
        CreateAndPostOutputJournalLine(Item."No.", ProductionOrder[2]."No.", 1);

        // [GIVEN] Post consumption of 1 item "I" in order "P1"
        CreateAndPostConsumptionJournalLine(Item."No.", ProductionOrder[1]."No.", 1);

        // [GIVEN] Post output of 1 item "I" in order "P1"
        CreateAndPostOutputJournalLine(Item."No.", ProductionOrder[1]."No.", 1);

        // [GIVEN] Post output of 1 item "I" in order "P1"
        CreateAndPostOutputJournalLine(Item."No.", ProductionOrder[1]."No.", 1);

        // [GIVEN] Create consumption journal line - 1 item "I" in order "P3"
        CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder[3]."No.", Item."No.", 1);
        // [GIVEN] Create consumption journal line - 1 item "I" in order "P2"
        CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder[2]."No.", Item."No.", 1);

        // [WHEN] Post consumption journal
        asserterror LibraryManufacturing.PostConsumptionJournal();

        // [THEN] Error is raised: "You have insufficient quantity of Item I on inventory"
        Assert.ExpectedError(StrSubstNo(InsufficientQtyErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckConsumptionAfterPostingNegativeOutput()
    var
        Location: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderLine: Record "Prod. Order Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        CompItem: Record Item;
        InventorySetup: Record "Inventory Setup";
        Qty: Decimal;
    begin
        // [FEATURE] [Output Journal] [Production Order]
        // [SCENARIO 376642] No Consupmtion should be posted for Journal Line with negative "Output Quantity"
        Initialize();

        // [GIVEN] Released Prod Order
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateRelProdOrder(ProdOrderLine, Location.Code, CompItem, Qty);

        // [GIVEN] Post Output
        LibraryManufacturing.OutputJournalExplodeOrderLineRouting(ItemJournalBatch, ProdOrderLine, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // [WHEN] Post Negative Output applied to previous Output
        PostNegativeOutput(ItemJournalBatch, ProdOrderLine, Qty, TempItemLedgerEntry."Entry No.");
        // [THEN] Consumtion is not posted for Component Item
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        Assert.RecordIsEmpty(ItemLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemEntriesReappliedOnApplWorksheetCrashAndOpenBack()
    var
        Item: Record Item;
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        // [FEATURE] [Application Worksheet]
        // [SCENARIO 380140] Item Ledger Entries that are unapplied by Application Worksheet and not reapplied back due to a its accidental crash, are reapplied back on next opening of the Worksheet.
        Initialize();

        // [GIVEN] Posted positive and negative Item Ledger Entries applied to each other.
        // [GIVEN] Item Ledger Entries are unapplied with Application Worksheet.
        LibraryInventory.CreateItem(Item);
        PostAndUnapplyPositiveAndNegativeAdjustments(
          Item, LibraryRandom.RandInt(20), PositiveItemLedgerEntry, NegativeItemLedgerEntry, true);

        // [GIVEN] Item is blocked by Application Worksheet.
        BlockItemWithApplWorksheet(Item);

        // [WHEN] Open Application Worksheet.
        ApplicationWorksheet.OpenView();

        // [THEN] Item Ledger Entries are applied back.
        PositiveItemLedgerEntry.Find();
        PositiveItemLedgerEntry.TestField("Remaining Quantity", PositiveItemLedgerEntry.Quantity + NegativeItemLedgerEntry.Quantity);
        NegativeItemLedgerEntry.Find();
        NegativeItemLedgerEntry.TestField("Remaining Quantity", 0);

        // [THEN] Item is not blocked by Application Worksheet.
        Item.Find();
        Item.TestField("Application Wksh. User ID", '');

        // [THEN] Item Application Entry History is cleared off.
        VeriryItemApplicationEntryHistory(PositiveItemLedgerEntry);
        VeriryItemApplicationEntryHistory(NegativeItemLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAdjustedAndItemReleasedOnApplWorksheetOpen()
    var
        Item: Record Item;
        PosItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        NegItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ApplicationWorksheet: TestPage "Application Worksheet";
        Quantity: Decimal;
    begin
        // [FEATURE] [Application Worksheet]
        // [SCENARIO 380525] Cost of Item Ledger Entries that is not adjusted due to an accidental crash of Application Worksheet is adjusted on the next opening of the Worksheet. Blocked items are released.
        Initialize();

        // [GIVEN] Automatic Cost Adjustment = Always in Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Posted two pairs of positive and negative Item Ledger Entries ("E1+", "E1-"), ("E2+", "E2-").
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(20);
        PostPositiveAndNegativeEntries(Item, Quantity, PosItemLedgerEntry[1], NegItemLedgerEntry[1]);
        PostPositiveAndNegativeEntries(Item, Quantity, PosItemLedgerEntry[2], NegItemLedgerEntry[2]);

        // [GIVEN] Both pairs of Item Ledger Entries are unapplied with Application Worksheet.
        UnapplyItemLedgerEntries(PosItemLedgerEntry[1]."Entry No.", NegItemLedgerEntry[1]."Entry No.", true);
        UnapplyItemLedgerEntries(PosItemLedgerEntry[2]."Entry No.", NegItemLedgerEntry[2]."Entry No.", true);

        // [GIVEN] Item is blocked by Application Worksheet.
        BlockItemWithApplWorksheet(Item);

        // [GIVEN] Item Ledger Entries are applied back criss-cross ("E1+" to "E2-", "E2+" to "E1-").
        ItemJnlPostLine.ReApply(PosItemLedgerEntry[1], NegItemLedgerEntry[2]."Entry No.");
        ItemJnlPostLine.ReApply(PosItemLedgerEntry[2], NegItemLedgerEntry[1]."Entry No.");

        // [WHEN] Open Application Worksheet.
        ApplicationWorksheet.OpenView();

        // [THEN] Cost of negative entries "E1-" and "E2-" is adjusted.
        VerifyItemLedgerEntriesCostEquality(PosItemLedgerEntry[1], NegItemLedgerEntry[2]);
        VerifyItemLedgerEntriesCostEquality(PosItemLedgerEntry[2], NegItemLedgerEntry[1]);

        // [THEN] Item is not blocked by Application Worksheet.
        Item.Find();
        Item.TestField("Application Wksh. User ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemEntriesNotReappliedOnApplWorksheetOpenIfTheyNotUnappliedByTheWorksheet()
    var
        Item: Record Item;
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        // [FEATURE] [Application Worksheet]
        // [SCENARIO 380140] Item Ledger Entries that are unapplied not by Application Worksheet, remain unapplied on next opening of the Worksheet.
        Initialize();

        // [GIVEN] Posted positive and negative Item Ledger Entries applied to each other.
        // [GIVEN] Item Ledger Entries are unapplied not with Application Worksheet.
        LibraryInventory.CreateItem(Item);
        PostAndUnapplyPositiveAndNegativeAdjustments(
          Item, LibraryRandom.RandInt(20), PositiveItemLedgerEntry, NegativeItemLedgerEntry, false);

        // [WHEN] Open Application Worksheet.
        ApplicationWorksheet.OpenView();
        // [THEN] Item Ledger Entries are not applied.
        PositiveItemLedgerEntry.Find();
        PositiveItemLedgerEntry.TestField("Remaining Quantity", PositiveItemLedgerEntry.Quantity);

        NegativeItemLedgerEntry.Find();
        NegativeItemLedgerEntry.TestField("Remaining Quantity", NegativeItemLedgerEntry.Quantity);

        // [THEN] Item is not blocked by Application Worksheet.
        Item.Find();
        Item.TestField("Application Wksh. User ID", '');
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure SavedItemApplHistoryEntriesAreClearedOffOnClosingApplicationWorksheet()
    var
        Item: Record Item;
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        // [FEATURE] [Application Worksheet]
        // [SCENARIO 380140] Item Application Entry History in which unapplied Item Entries are saved for reapplication in case of a sudden crash, is cleared off when Application Worksheet is safely closed.
        Initialize();

        // [GIVEN] Posted positive and negative Item Ledger Entries applied to each other.
        LibraryInventory.CreateItem(Item);
        PostPositiveAndNegativeEntries(Item, LibraryRandom.RandInt(20), PositiveItemLedgerEntry, NegativeItemLedgerEntry);

        // [GIVEN] Item Ledger Entries are unapplied by Application Worksheet.
        // Remove application is done in the page handler.
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(PositiveItemLedgerEntry."Entry Type"));
        if ApplicationWorksheet.First() then
            ApplicationWorksheet.AppliedEntries.Invoke();

        // [WHEN] Close the Application Worksheet.
        ApplicationWorksheet.OK().Invoke();

        // [THEN] Item Application Entry History is cleared off.
        VeriryItemApplicationEntryHistory(PositiveItemLedgerEntry);
        VeriryItemApplicationEntryHistory(NegativeItemLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler')]
    [Scope('OnPrem')]
    procedure ItemNotBlockedWhenNothingUnapplied()
    var
        Item: Record Item;
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        // [FEATURE] [Application Worksheet]
        // [SCENARIO 260491] Item is not blocked by application worksheet if no entries are unapplied.
        Initialize();

        // [GIVEN] Post positive and negative item entries and remove the item application between them.
        LibraryInventory.CreateItem(Item);
        PostAndUnapplyPositiveAndNegativeAdjustments(
          Item, LibraryRandom.RandInt(10), PositiveItemLedgerEntry, NegativeItemLedgerEntry, false);

        // [WHEN] Open Application Worksheet on the positive entry -> "Applied Entries" -> "Remove Application", despite nothing to unapply.
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(PositiveItemLedgerEntry."Entry Type"));
        ApplicationWorksheet.First();
        ApplicationWorksheet.AppliedEntries.Invoke();
        ApplicationWorksheet.OK().Invoke();

        // [THEN] Item is not blocked by application worksheet.
        Item.Find();
        Item.TestField("Application Wksh. User ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostExecutableWhenChangeItemInReleasedProductionOrder()
    var
        Item: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Production] [Output] [Adjust Cost - Item Entries]
        // [SCENARIO 260831] "Adjust Cost Item Entries" can be executed after changing item with posted entries in released production order
        Initialize();

        // [GIVEN] Items "I1" and "I2"
        for i := 1 to 2 do
            LibraryInventory.CreateItem(Item[i]);

        // [GIVEN] Released production order "R" for item "I1"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item[1]."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Post output of "Q" pieces of "I1" in "R", item ledger entry "E" is created
        Quantity := LibraryRandom.RandInt(10);
        PostOutput(ProductionOrder."No.", Item[1]."No.", Quantity, 0);

        FindOutputItemLedgerEntry(ItemLedgerEntry, Item[1]."No.");

        // [GIVEN] Post negative output of "-Q" pieces of "I1" in "R", applied to "E"
        PostOutput(ProductionOrder."No.", Item[1]."No.", -Quantity, ItemLedgerEntry."Entry No.");

        // [GIVEN] Change "I1" to "I2" in "R" line
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        ProdOrderLine.Validate("Item No.", Item[2]."No.");
        ProdOrderLine.Modify(true);

        // [GIVEN] Post output of "Q" pieces of "I2" in "R"
        PostOutput(ProductionOrder."No.", Item[2]."No.", Quantity, 0);

        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run Adjust Cost for items above
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', Item[1]."No.", Item[2]."No."), '');

        // [THEN] "Cost is Adjusted" is set on for these items
        for i := 1 to 2 do begin
            Item[i].Find();
            Item[i].TestField("Cost is Adjusted", true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSuggestAssgntDialogueForReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        StrMenuCalled: Boolean;
    begin
        // [FEATURE] [Item Charge] [Suggest Assignment]
        // [SCENARIO 380487] If all "Item Charge Assignment (Purch)" have "Applies-to Doc. Type" Sales Shipment then Suggest Item Charge Assignment function provides Dialog with Options Equally,Amount.
        Initialize();

        // [GIVEN] "Item Charge Assignment (Purch)" for "Sales Shipment Line"
        CreateItemChargeAssgntPurchForSalesShptLine(PurchaseLine);

        LibraryVariableStorage.Enqueue(StrMenuCalled); // Enque FALSE for handler

        // [WHEN] Suggest Assignment
        ItemChargeAssgntPurch.SuggestAssgnt(PurchaseLine, PurchaseLine.Quantity, PurchaseLine."Line Amount", PurchaseLine.Quantity, PurchaseLine."Line Amount");

        // [THEN] STRMENU occurs
        StrMenuCalled := LibraryVariableStorage.DequeueBoolean(); // STRMENU called flag
        Assert.IsFalse(StrMenuCalled, STRMENUWasNotCalledTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSuggestAssgntDialogueForTransferReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // [FEATURE] [Item Charge] [Suggest Assignment]
        // [SCENARIO 380487] If all "Item Charge Assignment (Purch)" have "Applies-to Doc. Type" Transfer Receipt then Suggest Item Charge Assignment function doesn't provide any Dialog.
        Initialize();

        // [GIVEN] "Item Charge Assignment (Purch)" for "Transfer Receipt Line"
        CreateItemChargeAssgntPurchForTransferReceiptLine(PurchaseLine, ItemChargeAssignmentPurch);

        // [WHEN] Suggest Assignment
        ItemChargeAssgntPurch.SuggestAssgnt(PurchaseLine, PurchaseLine.Quantity, PurchaseLine."Line Amount", PurchaseLine.Quantity, PurchaseLine."Line Amount");

        // [THEN] "Qty. to Assign" is populated. No Dialogue occurs.
        Assert.AreEqual(1, ItemChargeAssignmentPurch."Qty. to Assign", ValueIsNotPopulatedTxt);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure CheckSuggestAssgntDialogueForDifferentReceipts()
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // [FEATURE] [Item Charge] [Suggest Assignment]
        // [SCENARIO 380487] If "Item Charge Assignment (Purch)" have different "Applies-to Doc. Type" then Suggest Item Charge Assignment function provides Dialog with Options Equally,Amount.
        Initialize();

        // [GIVEN] "Item Charge Assignment (Purch)" for "Sales Shipment Line" and "Transfer Receipt Line"
        CreateItemChargeAssgntPurchForSalesShptLineAndTransferReceiptLine(PurchaseLine);

        // [WHEN] Suggest Assignment
        ItemChargeAssgntPurch.SuggestAssgnt(PurchaseLine, PurchaseLine.Quantity, PurchaseLine."Line Amount", PurchaseLine.Quantity, PurchaseLine."Line Amount");

        // [THEN] STRMENU shows with 3 choices: "Equally", "By Weight", "By Volume"
        Assert.AreEqual(ListOf3SuggestAssignmentStrMenuTxt, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferCausingApplicationCycleIsPostedUnapplied()
    var
        LocationBlue: Record Location;
        LocationRed: Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Item Application] [Transfer] [Reclassification Journal]
        // [SCENARIO 217342] Direct transfer created in Reclassification Journal should be posted with no item application on its positive side when the posting causes a loop in item application.
        Initialize();

        // [GIVEN] Item "I", locations "A" and "B".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');

        // [GIVEN] Positive adjustment for "q" pcs. of item "I" is posted on location "A".
        LibraryInventory.PostPositiveAdjustment(Item, LocationBlue.Code, '', '', LibraryRandom.RandInt(10), WorkDate(), 0);

        // [GIVEN] Negative adjustment for "Q" ("Q" > "q") pcs. of item "I" is posted on location "A". The inventory is now negative on "A" as the negative adjustment is not fully applied.
        // [GIVEN] Posted item entry no. = "1".
        LibraryInventory.PostNegativeAdjustment(Item, LocationBlue.Code, '', '', LibraryRandom.RandIntInRange(11, 20), WorkDate(), 0);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.", LocationBlue.Code, false);

        // [GIVEN] Positive adjustment for "Q" pcs. of item "I" is posted on "A". The positive adjustment journal line is set to be applied from item entry "1".
        // [GIVEN] Posted item entry no. = "2".
        PostPositiveAdjustment(Item, LocationBlue.Code, Abs(ItemLedgerEntry.Quantity), 0, ItemLedgerEntry."Entry No.");

        // [GIVEN] Transfer 1 pc. of "I" from location "A" to "B" is posted in reclassification journal.
        // [GIVEN] Posted item entries nos. = "3" and "4".
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), LocationBlue.Code, LocationRed.Code, '', '', '', 1);

        // [WHEN] Post transfer 1 pc. of "I" back from "B" to "A" in reclassification journal. Posted item entries nos. = "5" and "6". That could make an application loop: "1" -> "2" -> "3" -> "4" -> "5" -> "6" -> "1".
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), LocationRed.Code, LocationBlue.Code, '', '', '', 1);

        // [THEN] The item entry "6" has been successfully posted and not applied to "1", thereby avoiding the loop.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LocationBlue.Code, true);
        ItemLedgerEntry.TestField("Remaining Quantity", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SkipLookingForAppliedTransferEntryForNegativeILE()
    var
        Location: array[3] of Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        AppliedTransEntryExists: Boolean;
        Qty: Decimal;
    begin
        // [FEATURE] [Item Application Entry] [Transfer] [UT]
        // [SCENARIO 286625] AppliedInbndTransEntryExists function in Table 339 Item Application Entry does not look for an applied transfer item entry if its item entry parameter points to a negative ILE.
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Locations "From", "To", "In-Transit".
        CreateLocationsChain(Location[1], Location[2], Location[3]);

        // [GIVEN] Post positive adjustment for 20 pcs on location "From".
        // [GIVEN] Post negative adjustment for 10 pcs on location "From".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(Item, Location[1].Code, '', '', 2 * Qty, WorkDate(), 0);
        LibraryInventory.PostNegativeAdjustment(Item, Location[1].Code, '', '', Qty, WorkDate(), 0);

        // [GIVEN] Transfer 10 pcs from location "From" to location "To".
        PostItemJournalTransfer(Item, Location[1].Code, Location[2].Code, Qty, WorkDate());

        // [WHEN] Invoke AppliedInbndTransEntryExists function in Table 339 for the negative adjustment item entry.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.", Location[1].Code, false);
        AppliedTransEntryExists := ItemApplicationEntry.AppliedInbndTransEntryExists(ItemLedgerEntry."Entry No.", true);

        // [THEN] No applied transfer ILE is found.
        Assert.IsFalse(AppliedTransEntryExists, 'Applied transfer item entry cannot exist for a negative item entry.');

        // [THEN] The search for an applied transfer item entry is interrupted before Item Application Entry table is filtered by "Transferred-from Entry No." field.
        Assert.AreEqual(
          '', ItemApplicationEntry.GetFilter("Transferred-from Entry No."),
          'No need to search for applied transfer entry for a negative item entry.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LookingForAppliedTransferEntryForPositiveILE()
    var
        Location: array[3] of Record Location;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        AppliedTransEntryExists: Boolean;
        Qty: Decimal;
    begin
        // [FEATURE] [Item Application Entry] [Transfer] [UT]
        // [SCENARIO 286625] AppliedInbndTransEntryExists function in Table 339 Item Application Entry finds an applied transfer item entry to a positive ILE.
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Locations "From", "To", "In-Transit".
        CreateLocationsChain(Location[1], Location[2], Location[3]);

        // [GIVEN] Post positive adjustment for 20 pcs on location "From".
        // [GIVEN] Post negative adjustment for 10 pcs on location "From".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(Item, Location[1].Code, '', '', 2 * Qty, WorkDate(), 0);
        LibraryInventory.PostNegativeAdjustment(Item, Location[1].Code, '', '', Qty, WorkDate(), 0);

        // [GIVEN] Transfer 10 pcs from location "From" to location "To".
        PostItemJournalTransfer(Item, Location[1].Code, Location[2].Code, Qty, WorkDate());

        // [WHEN] Invoke AppliedInbndTransEntryExists function in Table 339 for the positive adjustment item entry.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Location[1].Code, true);
        AppliedTransEntryExists := ItemApplicationEntry.AppliedInbndTransEntryExists(ItemLedgerEntry."Entry No.", true);

        // [THEN] Applied transfer ILE is found.
        Assert.IsTrue(AppliedTransEntryExists, 'Applied transfer item entry is not found.');

        // [THEN] The function finds the inbound item entry to location "To".
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, Location[2].Code, true);
        ItemApplicationEntry.TestField("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesHandler,ViewUnappliedEntriesModalHandler')]
    [Scope('OnPrem')]
    procedure ItemNotBlockedAfterReApply()
    var
        Item: Record Item;
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        // [FEATURE] [Application Worksheet] [Item Application Entry] [UT]
        // [SCENARIO 288094] Item is not blocked after Reapply is invoked on Item Application Worksheet.
        Initialize();

        // [GIVEN] Post positive and negative item entries.
        LibraryInventory.CreateItem(Item);
        PostPositiveAndNegativeEntries(Item, LibraryRandom.RandDec(100, 2), PositiveItemLedgerEntry, NegativeItemLedgerEntry);

        // [GIVEN] Application Worksheet is focused on the positive entry.
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", Item."No.");
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", Format(PositiveItemLedgerEntry."Entry Type"));
        ApplicationWorksheet.FILTER.SetFilter("Document No.", PositiveItemLedgerEntry."Document No.");
        ApplicationWorksheet.First();

        // [GIVEN] Entries unapplied in ViewAppliedEntriesHandler.
        ApplicationWorksheet.AppliedEntries.Invoke();

        // [GIVEN] Entries applied in ViewUnappliedEntriesModalHandler.
        ApplicationWorksheet.UnappliedEntries.Invoke();

        // [WHEN] Reapply is invoked and Application Worksheet is closed without confirmation dialogue.
        ApplicationWorksheet.Reapply.Invoke();
        ApplicationWorksheet.OK().Invoke();

        // [THEN] Item is not blocked by Application Worksheet.
        Item.Find();
        Item.TestField("Application Wksh. User ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliedEntryToAdjustOnPurchItemEntryIsOnUntilAppliedSalesAreFullyInvoiced()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Purchase] [Sales]
        // [SCENARIO 294814] When there are multiple sales item entries applied to one purchase entry and the cost of the purchase is changed after receipt, the new cost is fully transferred from the purchase to the sales.
        Initialize();

        // [GIVEN] Item with FIFO costing method.
        CreateItem(Item, Item."Costing Method"::FIFO, 0, Item."Replenishment System"::Purchase, 1);

        // [GIVEN] Purchase order with two lines.
        // [GIVEN] 1st line: Quantity = 3, Direct Unit Cost = 10.
        // [GIVEN] 2nd line: Quantity = 1, Direct Unit Cost = 15.
        // [GIVEN] Post the receipt.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, Item."No.", 3);
        UpdateQtyToInvoiceAndUnitCostOnPurchaseLine(PurchaseLine[1], 0, 10);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, Item."No.", 1);
        UpdateQtyToInvoiceAndUnitCostOnPurchaseLine(PurchaseLine[2], 0, 15);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Sales order with two lines.
        // [GIVEN] 1st line: Quantity = 2.
        // [GIVEN] 2nd line: Quantity = 2.
        // [GIVEN] Post the shipment.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] The 1st purchase line for 3 pcs is now applied to both sales lines.

        // [GIVEN] Update the 1st purchase line. Set "Qty. to Invoice" = 3, Direct Unit Cost = 12.
        UpdateQtyToInvoiceAndUnitCostOnPurchaseLine(PurchaseLine[1], PurchaseLine[1].Quantity, 12);

        // [GIVEN] Update the 2nd purchase line. Set "Qty. to Invoice" = 0.
        UpdateQtyToInvoiceAndUnitCostOnPurchaseLine(PurchaseLine[2], 0, PurchaseLine[2]."Direct Unit Cost");

        // [GIVEN] Invoice the 1st purchase line.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] The item entry representing the invoiced purchase line still have "Applied Entry to Adjust" = TRUE.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Purchase, '', true);
        ItemLedgerEntry.TestField("Applied Entry to Adjust", true);

        // [GIVEN] Post the sales invoice.
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Update the 2nd purchase line. Set "Qty. to Invoice" = 1, Direct Unit Cost = 16.
        UpdateQtyToInvoiceAndUnitCostOnPurchaseLine(PurchaseLine[2], PurchaseLine[2].Quantity, 16);

        // [GIVEN] Invoice the 2nd purchase line.
        // [GIVEN] Both the purchase and the sales are fully posted now.
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The item inventory = 0.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 0);

        // [THEN] The remaining cost amount = 0.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", 0);

        // [THEN] "Applied entry to adjust" = FALSE on the purchase item entries.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Purchase, '', true);
        ItemLedgerEntry.TestField("Applied Entry to Adjust", false);
        ItemLedgerEntry.Next();
        ItemLedgerEntry.TestField("Applied Entry to Adjust", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostApplicationFalseOnOutboundEntryAppliedToTransferReceipt()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Average Costing Method] [Item Application Entry] [Cost Application] [Transfer]
        // [SCENARIO 307863] "Cost Application" is false for all outbound entries applied to transfer receipt for item with costing method = "Average".
        Initialize();

        // [GIVEN] Item with costing method = "Average".
        CreateItem(Item, Item."Costing Method"::Average, 0, Item."Replenishment System"::Purchase, 1);
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);

        // [GIVEN] Post positive inventory adjustment for "X" pcs on location "From".
        Qty := LibraryRandom.RandIntInRange(10, 20);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationFrom.Code, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Transfer half the inventory ("X" / 2) from location "From" to location "To".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty / 2);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [GIVEN] Post sales for "X" pcs on location "To".
        // [GIVEN] This results in negative inventory on "To".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationTo.Code, '', Qty);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Sale);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Transfer another half the inventory from "From" to "To" in order to fulfill the sales.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty / 2);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] "Cost Application" is FALSE on two item application entries for item entry type of "Sale".
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale, LocationTo.Code, false);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        Assert.RecordCount(ItemApplicationEntry, 2);

        ItemApplicationEntry.SetRange("Cost Application", false);
        Assert.RecordCount(ItemApplicationEntry, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuationDateOnOutboundEntryIsEqualToTheLatestDateOnAppliedInboundEntry()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        Qty: Decimal;
        AdditionalQty: Decimal;
    begin
        // [FEATURE] [Average Costing Method] [Valuation Date] [Transfer]
        // [SCENARIO 318318] Valuation date on an outbound entry is equal to the latest valuation date among applied inbound entries.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);
        AdditionalQty := LibraryRandom.RandInt(5);

        // [GIVEN] Item with costing method = Average.
        CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandDec(10, 2), Item."Replenishment System"::Purchase, 1);
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);

        // [GIVEN] Place 3 pcs of the item to location "From", posting date = 25/01.
        CreateAndPostItemJournalLineWithPostingDate(Item."No.", LocationFrom.Code, Qty, WorkDate());

        // [GIVEN] Transfer 3 pcs from location "From" to location "To", posting date = 22/01.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader.Validate("Posting Date", WorkDate() - 3);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [GIVEN] Place another 1 pc to location "To", posting date = 24/01.
        CreateAndPostItemJournalLineWithPostingDate(Item."No.", LocationTo.Code, AdditionalQty, WorkDate() - 1);

        // [WHEN] Write off all remaining quantity (4 pcs) from location "To". This item entry is applied to both inbound transfer (3 pcs) and positive adjustment (1 pc).
        CreateAndPostItemJournalLineWithPostingDate(Item."No.", LocationTo.Code, -(Qty + AdditionalQty), WorkDate() - 1);

        // [THEN] The valuation date of the posted negative entry is 25/01 (the latest date among the inbound entries).
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.", LocationTo.Code, false);
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Valuation Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateBufferizedOutboundEntryAfterCostOfInboundEntryHasChanged()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Adjust Cost - Item Entries] [Item Application] [Transfer]
        // [SCENARIO 367382] Adjusted cost of outbound entry is recalculated again after the Adjust Cost batch job recalculates inbound transfer entry the outbound entry is applied to.
        Initialize();

        // [GIVEN] Locations "A" and "B".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Item with Unit Cost = 18.0 LCY.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, 0, 18.0);

        // [GIVEN] Post 1 pc to inventory on location "A", unit cost = 18.0 LCY.
        CreateAndPostItemJournalLineWithUnitAmount(Item."No.", Location[1].Code, 1, 18.0);

        // [GIVEN] Purchase order for 100 pcs on location "B", unit cost = 100.0 LCY.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 100, Location[2].Code, WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", 100.0);
        PurchaseLine.Modify(true);

        // [GIVEN] Receive the purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Transfer 80 pcs from location "B" to "A".
        CreateAndPostItemReclassificationJournalLine(Item."No.", Location[2].Code, Location[1].Code, 80, 0);

        // [GIVEN] Update unit cost on the purchase line to 20.0 LCY.
        PurchaseHeader.Find();
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", 20.0);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Transfer 80 pcs from location "A" back to "B".
        // [GIVEN] The outbound entry on location "A" is applied to two inbound entries - 1 pc to the positive adjustment and 79 pcs to the purchase.
        CreateAndPostItemReclassificationJournalLine(Item."No.", Location[1].Code, Location[2].Code, 80, 0);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Unit cost on the item card = 19.98 LCY (100 pcs for 20.0 LCY + 1 pc for 18.0 LCY).
        Item.Find();
        Assert.AreNearlyEqual(
          (100 * 20.0 + 1 * 18.0) / (100 + 1), Item."Unit Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong unit cost on item card.');

        // [THEN] Cost amount on the outbound item entry for the second transfer is equal to -1598.0 LCY (79 pcs for 20.0 LCY + 1 pc for 18.0 LCY).
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, Location[1].Code, false);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", -(79 * 20.0 + 1 * 18.0));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure CheckSuggestAssgntStrMenuForReceipts()
    var
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        // [FEATURE] [Item Charge] [Suggest Assignment]
        // [SCENARIO 380487] If all "Item Charge Assignment (Purch)" have "Applies-to Doc. Type" Sales Shipment then Suggest Item Charge Assignment function provides Dialog with Options Equally,Amount.
        Initialize();

        // [GIVEN] "Item Charge Assignment (Purch)" for "Sales Shipment Line"
        CreateItemChargeAssgntPurchForSalesShptLine(PurchaseLine);
        InsertItemChargeAssgntPurchForSalesShptLine(PurchaseLine);

        // [WHEN] Suggest Assignment
        ItemChargeAssgntPurch.SuggestAssgnt(PurchaseLine, PurchaseLine.Quantity, PurchaseLine."Line Amount", PurchaseLine.Quantity, PurchaseLine."Line Amount");

        // [THEN] STRMENU occurs
        // [THEN] STRMENU shows with 4 choices: "Equally", "By Amount", "By Weight", "By Volume"
        Assert.AreEqual(ListOf4SuggestAssignmentStrMenuTxt, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostApplicationFalseOnValuedByAverageCostOutboundEntryAppliedToTransferReceipt()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Average Costing Method] [Item Application Entry] [Cost Application] [Transfer]
        // [SCENARIO 378792] "Cost Application" is false for outbound entry valued by average cost applied to transfer receipt for item with costing method = "Average"
        Initialize();

        // [GIVEN] Item with costing method = "Average".
        CreateItem(Item, Item."Costing Method"::Average, 0, Item."Replenishment System"::Purchase, 1);
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Post sales for "X" pcs on location "To".
        // [GIVEN] This results in negative inventory on "To" and Value Entry with "Valued by Average Cost" = TRUE.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationTo.Code, '', Qty);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Sale);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Post positive inventory adjustment for "X" pcs on location "From".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationFrom.Code, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Transfer the inventory from "From" to "To" in order to fulfill the sales.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] "Cost Application" is FALSE on item application entry for item entry type of "Sale".
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale, LocationTo.Code, false);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField("Cost Application", false);
    end;

    [Test]
    procedure EliminateRoundingErrOnAdjustAvgCostForTransferChain()
    var
        InventorySetup: Record "Inventory Setup";
        LocationBlue: Record Location;
        LocationRed: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: array[2] of Record "Purch. Rcpt. Line";
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost - Item Entries] [Transfer]
        // [SCENARIO 384317] Eliminate rounding residual amount on adjusting average cost for chain of transfers.
        Initialize();

        // [GIVEN] Calculate average cost per Item.
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Month);

        // [GIVEN] Locations "Blue", "Red".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);

        // [GIVEN] Item with Average costing method.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');

        // [GIVEN] Post a purchase order at location "Blue". Quantity = 15 pcs, unit cost = 2.21 LCY.
        // [GIVEN] Post a purchase order at location "Blue". Quantity = 2 pcs, unit cost = 2.21 LCY.
        CreateAndPostPurchaseOrder(PurchRcptLine[1], Item."No.", LocationBlue.Code, 15, 2.21);
        CreateAndPostPurchaseOrder(PurchRcptLine[2], Item."No.", LocationBlue.Code, 2, 2.21);

        // [GIVEN] Transfer 15 + 2 pcs to location "Red".
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), LocationBlue.Code, LocationRed.Code, '', '', '', 15);
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), LocationBlue.Code, LocationRed.Code, '', '', '', 2);

        // [GIVEN] Transfer 15 + 2 pcs back to location "Blue".
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), LocationRed.Code, LocationBlue.Code, '', '', '', 15);
        FindLastItemLedgerEntry(ItemLedgerEntry[1], Item."No.", LocationBlue.Code, true);
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), LocationRed.Code, LocationBlue.Code, '', '', '', 2);
        FindLastItemLedgerEntry(ItemLedgerEntry[2], Item."No.", LocationBlue.Code, true);

        // [GIVEN] Zero out inventory at location "Blue".
        CreateAndPostItemJournalLineWithAppliesToEntry(Item."No.", LocationBlue.Code, -15, ItemLedgerEntry[1]."Entry No.");
        CreateAndPostItemJournalLineWithAppliesToEntry(Item."No.", LocationBlue.Code, -2, ItemLedgerEntry[2]."Entry No.");

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Create purchase invoice for item charge.
        // [GIVEN] Assign 0.21 LCY to the receipt of 15 pcs.
        // [GIVEN] Assign 0.01 LCY to the receipt of 2 pcs.
        // [GIVEN] Post the invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        CreatePurchaseLineForItemCharge(PurchaseLine, PurchaseHeader, PurchRcptLine[1], 0.21);
        CreatePurchaseLineForItemCharge(PurchaseLine, PurchaseHeader, PurchRcptLine[2], 0.01);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The remaining quantity in stock = 0.
        // [THEN] The remaining cost amount = 0.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Cost Amount (Actual)");
        ValueEntry.TestField("Item Ledger Entry Quantity", 0);
        ValueEntry.TestField("Cost Amount (Actual)", 0);
    end;

    [Test]
    procedure CostAdjustmentRoundingIssueWithFIFOItemAfterRevaluation()
    var
        Item: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Charge]
        // [SCENARIO 385318] Eliminate rounding errors in cost adjustment of FIFO item.
        Initialize();

        // [GIVEN] FIFO item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);

        // [GIVEN] Receive and invoice purchase order for 3 pcs per 5.29 LCY.
        // [GIVEN] Purchase receipt = "R".
        CreateAndPostPurchaseOrderAndFindRcptLine(PurchRcptLine, Item."No.", '', 3, 5.29);

        // [GIVEN] Write off 3 pcs from the inventory. Item ledger entry no. = "X".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', -3);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.", '', false);

        // [GIVEN] Post positive adjustment for 3 pc with the cost applied from the item entry "X".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 3);
        ItemJournalLine.Validate("Applies-from Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Post three lines of negative adjustment, each for 1 pc.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', -1);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 1);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Adjust cost item entries.
        // [GIVEN] Each item entry posted now has Unit Cost = 5.29.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Create purchase invoice for item charge and apply it to the purchase receipt "R". Unit Cost = 0.23.
        // [GIVEN] Post the invoice.
        CreateAndPostPurchaseInvoiceForItemCharge(PurchRcptLine, 0.23);

        // [GIVEN] The total cost of purchase after posting charge is equal to 16.10 LCY (3 * 5.29 + 0.23 = 16.10).
        // [GIVEN] The rounded cost of each outbound entry for -1 pc must be -5.37 (-5.366666...) which gives the cost of -3 pcs = -16.11 (-3 * 5.37).
        // [GIVEN] The difference of -0.01 will be added to the inbound entry directly applied to the three negative adjustments.

        // [WHEN] Adjust cost item entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The sums of quantity and cost amount of all item entries becomes zero.
        VerifyValueEntry(Item."No.", 0, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CostAdjustmentRoundingIssueWithAsmItemAfterComponentRevalued()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        BOMComponent: Record "BOM Component";
        LocationRed: Record Location;
        LocationBlue: Record Location;
        LocationInTransit: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        AssemblyHeader: Record "Assembly Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Charge] [Assembly] [Transfer]
        // [SCENARIO 385318] Eliminate rounding errors in cost adjustment of assembled item after its component is revalued.
        Initialize();

        // [GIVEN] Locations "Blue", "Red".
        LibraryWarehouse.CreateTransferLocations(LocationBlue, LocationRed, LocationInTransit);

        // [GIVEN] Component item "C".
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Costing Method", CompItem."Costing Method"::FIFO);
        CompItem.Modify(true);

        // [GIVEN] Assembled item "A". Unit Cost = 5.29 LCY.
        // [GIVEN] Use "C" as component for "A".
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Costing Method", AsmItem."Costing Method"::FIFO);
        AsmItem.Validate("Unit Cost", 5.29);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Modify(true);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [GIVEN] Receive and invoice purchase order at location "Blue" for 3 pcs of item "C", 5.29 LCY each.
        // [GIVEN] Purchase receipt = "R".
        CreateAndPostPurchaseOrderAndFindRcptLine(PurchRcptLine, CompItem."No.", LocationBlue.Code, 3, 5.29);

        // [GIVEN] Create and post assembly order for 3 pcs of item "A" at location "Blue".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), AsmItem."No.", LocationBlue.Code, 3, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Transfer 3 pcs of item "A" from "Blue" to "Red".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationBlue.Code, LocationRed.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, AsmItem."No.", 3);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [GIVEN] Create and post sales order for item "A" at location "Red", three lines, 1 pc per each line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationRed.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmItem."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', CompItem."No.", AsmItem."No."), '');

        // [GIVEN] Purchase invoice with item charge assigned to the receipt "R". Unit Cost = 0.23.
        CreateAndPostPurchaseInvoiceForItemCharge(PurchRcptLine, 0.23);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', CompItem."No.", AsmItem."No."), '');

        // [THEN] The sums of quantity and cost amount for item "A" are equal to 0.
        VerifyValueEntry(AsmItem."No.", 0, 0);
    end;

    [Test]
    procedure EliminateNegativeRoundingResidueInCostAdjustForAvgCostItem()
    var
        InventorySetup: Record "Inventory Setup";
        Location: array[2] of Record Location;
        Item: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost - Item Entries] [Rounding]
        // [SCENARIO 391424] Eliminate negative cost amount residue after running cost adjustment for average cost item.
        Initialize();

        // [GIVEN] Average cost is calculated per Item, period = Month.
        InventorySetup.Get();
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Month);

        // [GIVEN] Item with Average costing method.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');

        // [GIVEN] Locations "L1", "L2".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Post a purchase order at location "L1". Quantity = 5 pcs, unit cost = 0.0029 LCY.
        CreateAndPostPurchaseOrder(PurchRcptLine, Item."No.", Location[1].Code, 5, 0.0029);

        // [GIVEN] Transfer 5 pcs to location "L2".
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), Location[1].Code, Location[2].Code, '', '', '', 5);

        // [GIVEN] Transfer 5 pcs back to location "L1".
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate(), Location[2].Code, Location[1].Code, '', '', '', 5);
        FindLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location[1].Code, true);

        // [GIVEN] Post 5 x 1 pc negative adjustments from location "L1".
        CreateAndPostItemJournalLineWithAppliesToEntry(Item."No.", Location[1].Code, -1, ItemLedgerEntry."Entry No.");
        CreateAndPostItemJournalLineWithAppliesToEntry(Item."No.", Location[1].Code, -1, ItemLedgerEntry."Entry No.");
        CreateAndPostItemJournalLineWithAppliesToEntry(Item."No.", Location[1].Code, -1, ItemLedgerEntry."Entry No.");
        CreateAndPostItemJournalLineWithAppliesToEntry(Item."No.", Location[1].Code, -1, ItemLedgerEntry."Entry No.");
        CreateAndPostItemJournalLineWithAppliesToEntry(Item."No.", Location[1].Code, -1, ItemLedgerEntry."Entry No.");

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The remaining quantity in stock = 0.
        // [THEN] The remaining cost amount = 0.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Cost Amount (Actual)");
        ValueEntry.TestField("Item Ledger Entry Quantity", 0);
        ValueEntry.TestField("Cost Amount (Actual)", 0);
    end;

    [Test]
    procedure ValuedByAverageCostTrueWhenUnapplyFixedItemApplForAvgCostItem()
    var
        Item: Record Item;
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [FEATURE] [Item Application] [Average Cost]
        // [SCENARIO 395193] For an item with average costing method, "Valued by Average Cost" is set to TRUE on value entries for outbound item entry when removing fixed application to an inbound entry.
        Initialize();

        // [GIVEN] Item with "Average" costing method.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Post positive and negative inventory adjustments.
        PostAndUnapplyPositiveAndNegativeAdjustments(
          Item, LibraryRandom.RandInt(10), PositiveItemLedgerEntry, NegativeItemLedgerEntry, false);

        // [GIVEN] Establish fixed application between the two item entries.
        ItemJnlPostLine.ReApply(PositiveItemLedgerEntry, NegativeItemLedgerEntry."Entry No.");

        // [GIVEN] Check that the item entries are applied, "Valued by Average Cost" on value entries for the negative entry = FALSE.
        NegativeItemLedgerEntry.Find();
        NegativeItemLedgerEntry.TestField("Applies-to Entry", PositiveItemLedgerEntry."Entry No.");
        VerifyValuedByAverageCostValueEntry(NegativeItemLedgerEntry."Entry No.", false);

        // [WHEN] Un-apply item entries.
        UnapplyItemLedgerEntries(
          PositiveItemLedgerEntry."Entry No.", NegativeItemLedgerEntry."Entry No.", false);

        // [THEN] The item application has been removed.
        NegativeItemLedgerEntry.Find();
        NegativeItemLedgerEntry.TestField("Applies-to Entry", 0);

        // [THEN] "Valued by Average Cost" on value entries for the negative entry = TRUE.
        VerifyValuedByAverageCostValueEntry(NegativeItemLedgerEntry."Entry No.", true);
    end;

    [Test]
    [HandlerFunctions('AdjustCostItemEntriesRequestPageHandler')]
    procedure UpdateAnalysisViewOnAdjustCostWithAutomaticCostPosting()
    var
        Item: Record Item;
        AnalysisView: Record "Analysis View";
        Qty: Decimal;
        LastEntryNo: Integer;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory to G/L] [Analysis View]
        // [SCENARIO 415686] Analysis view is updated on running cost adjustment with automatic cost posting to G/L.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Enable "Automatic Cost Posting" in inventory setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Post positive inventory adjustment with "Unit Amount" > 0.
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLineWithUnitAmount(Item."No.", '', Qty, LibraryRandom.RandDec(100, 2));

        // [GIVEN] Post negative inventory adjustment with "Unit Amount" = 0.
        CreateAndPostItemJournalLineWithUnitAmount(Item."No.", '', -Qty, 0);

        // [GIVEN] Create analysis view, set "Update on Posting" = TRUE.
        // [GIVEN] Update the analysis view, note the "Last Entry No." = "N".
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Update on Posting", true);
        AnalysisView.Modify(true);
        LibraryERM.UpdateAnalysisView(AnalysisView);
        AnalysisView.Find();
        LastEntryNo := AnalysisView."Last Entry No.";

        // [WHEN] Run the cost adjustment.
        RunCostAdjustment(Item."No.");

        // [THEN] "Last Entry No." on the analysis view is updated to "N" + 2 (the cost adjustment posts 1 value entry and 2 g/l entries).
        AnalysisView.Find();
        AnalysisView.TestField("Last Entry No.", LastEntryNo + 2);
    end;

    [Test]
    procedure CostAdjustmentPostCostToGLForItemWithInventoryValueZero()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InventoryAdjustment: Codeunit "Inventory Adjustment";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Inventory Value Zero] [Automatic Cost Posting]
        // [SCENARIO 421553] Cost adjustment succeeds to post cost to G/L for item with Inventory Value Zero.
        Initialize();
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Set Automatic Cost Posting = TRUE.
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post positive adjustment, quantity = 1, unit cost = 50.
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, WorkDate(), UnitCost);

        // [GIVEN] Set "Inventory Value Zero" = TRUE on item.
        Item.Find();
        Item.Validate("Inventory Value Zero", true);
        Item.Modify(true);

        // [GIVEN] Post negative adjustment, quantity = 1, unit cost = 0.
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, WorkDate(), 0);

        // [WHEN] Run the cost adjustment.
        Item.SetRecFilter();
        InventoryAdjustment.SetProperties(false, true);
        InventoryAdjustment.SetFilterItem(Item);
        InventoryAdjustment.MakeMultiLevelAdjmt();

        // [THEN] "Cost Amount (Actual)" = "Cost Posted to G/L" = -50 for the negative adjustment item entry.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.", '', false);
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Posted to G/L");
        ValueEntry.TestField("Cost Amount (Actual)", -UnitCost);
        ValueEntry.TestField("Cost Posted to G/L", -UnitCost);
    end;

    [Test]
    procedure NonInventoriableValueEntryHasValuedByAverageCostFalseAfterUnapply()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineCharge: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        InboundItemLedgerEntry: Record "Item Ledger Entry";
        OutboundItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Item Application] [Average Cost] [Item Charge]
        // [SCENARIO 427700] For an item with average costing method, "Valued by Average Cost" = FALSE on non-inventoriable value entries for outbound item entry when removing application to an inbound entry.
        Initialize();

        // [GIVEN] Item with average costing method.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(20, 40, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Post positive adjustment, note the inbound item entry "I".
        PostPositiveAdjustment(Item, '', 1, Item."Unit Cost", 0);
        FindItemLedgerEntry(InboundItemLedgerEntry, Item."No.", InboundItemLedgerEntry."Entry Type"::"Positive Adjmt.", '', true);

        // [GIVEN] Post sales order with an item line and an item charge line, note the outbound item entry "O".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLineItem, SalesHeader."Document Type"::Order, '', Item."No.", 1, '', WorkDate());
        LibrarySales.CreateSalesLine(
          SalesLineCharge, SalesHeader, SalesLineCharge.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        SalesLineCharge.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLineCharge.Modify(true);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLineCharge, SalesLineItem."Document Type",
          SalesLineItem."Document No.", SalesLineItem."Line No.", Item."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindItemLedgerEntry(OutboundItemLedgerEntry, Item."No.", OutboundItemLedgerEntry."Entry Type"::Sale, '', false);

        // [WHEN] Unapply item entries "I" and "O".
        UnapplyItemLedgerEntries(InboundItemLedgerEntry."Entry No.", OutboundItemLedgerEntry."Entry No.", false);

        // [THEN] "Valued by Average Cost" = False on the non-inventoriable value entry for item charge.
        ValueEntry.SetRange("Item Ledger Entry No.", OutboundItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Item Charge No.", SalesLineCharge."No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Valued By Average Cost", false);
    end;

    [Test]
    procedure RemainingCostZeroWhenInventoryZeroForAverageCostItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Average Costing Method]
        // [SCENARIO 429386] Remaining cost must be zero when remaining inventory is zero.
        Initialize();

        // [GIVEN] Average cost item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Purchase order, quantity = 15, direct unit cost = 14.19.
        // [GIVEN] Post as Receive.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 15, '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", 14.19);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Sales order, quantity = 15.
        // [GIVEN] Ship and invoice.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 15, '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Update "Direct Unit Cost" on the purchase line from 14.19 to 14.189.
        // [GIVEN] Invoice the purchase order.
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", 14.189);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Check the item's remaining quantity and cost:
        // [THEN] Quantity = 0, "Cost Amount" = 0.
        VerifyValueEntry(Item."No.", 0, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure StartAutomaticCostAdjustmentAfterNeverChangedToAlways()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitAmount: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Automatic Cost Adjustment]
        // [SCENARIO 463262] Start automatic cost adjustment on posting the next item entry after "Automatic Cost Adjustment" setting is changed from "Never" to "Always".
        Initialize();
        UnitAmount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] "Automatic Cost Adjustment" = "Never" in Inventory Setup.
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Never);
        InventorySetup.Modify(true);

        // [GIVEN] Post positive inventory adjustment using item journal. "Unit Amount" = "X".
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLineWithUnitAmount(Item."No.", '', LibraryRandom.RandIntInRange(50, 100), UnitAmount);

        // [GIVEN] Post negative adjustment, set "Unit Amount" = 0.
        CreateAndPostItemJournalLineWithUnitAmount(Item."No.", '', -LibraryRandom.RandInt(10), 0);

        // [GIVEN] Ensure that the negative entry is not adjusted automatically.
        FindLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', false);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);

        // [WHEN] Set "Automatic Cost Adjusment" = "Always".
        InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Always);
        InventorySetup.Modify(true);

        // [THEN] Post negative adjustment, set "Unit Amount" = 0.
        CreateAndPostItemJournalLineWithUnitAmount(Item."No.", '', -LibraryRandom.RandInt(10), 0);

        // [THEN] The cost of the negative entry has been automatically adjusted to "X".
        FindLastItemLedgerEntry(ItemLedgerEntry, Item."No.", '', false);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", ItemLedgerEntry.Quantity * UnitAmount);
    end;

    [Test]
    procedure RoundingInExpectedCostAmountAfterPostingWithAlternateUoM()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        LotNos: array[20] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [Expected Cost] [Rounding] [Unit of Measure]
        // [SCENARIO 466852] Correct rounding in Cost Amount (Expected) after posting purchase receipt for alternate unit of measure.
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := 0.001;
        GeneralLedgerSetup.Modify();

        LibraryItemTracking.CreateLotItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 0.10273);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 4000, '', WorkDate());
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Direct Unit Cost", 6);
        PurchaseLine.Modify(true);

        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNos[i], 20.546);
        end;

        // [WHEN]
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN]
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Cost Amount (Expected)");
        ValueEntry.TestField("Cost Amount (Expected)", 24000);
    end;

    [Test]
    procedure RoundingInActualCostForRevaluationForAvgCostItem()
    var
        InventorySetup: Record "Inventory Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Revaluation]
        // [SCENARIO 466595] Correct rounding in Cost Amount (Actual) after posting one revaluation line for two item entries.
        Initialize();

        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Amount Rounding Precision" := 1;
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := 0.01;
        GeneralLedgerSetup.Modify();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        CreateAndPostItemJournalLineWithPostingDate(Item."No.", '', 2000, WorkDate());
        CreateAndPostItemJournalLineWithPostingDate(Item."No.", '', 244, WorkDate());

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN]
        PostRevaluationJournalLineForDefinedAmount(Item, WorkDate(), 1376775);

        // [THEN]
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", 1376775);
    end;

    [Test]
    procedure ValuationDateInChainOfOutboundEntriesWithOneAppliedFrom()
    var
        CompItem, ProdItem : Record Item;
        LocationFrom, LocationTo : Record Location;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        RecordCount: Integer;
    begin
        // [FEATURE] [Costing] [Valuation Date]
        // [SCENARIO 474048] Update Valuation Date caused by posting consumption onto chain of outbound entries.
        Initialize();

        // [GIVEN] Locations "A" and "B".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Component item "C" and production item "P".
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(ProdItem);
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ProdItem, CompItem, 1, '');

        // [GIVEN] Post 100 pcs of item "C" to inventory at location "A". Posting date = Jan. 1.
        CreateAndPostItemJournalLineWithPostingDate(CompItem."No.", LocationFrom.Code, 100, WorkDate());

        // [GIVEN] Create production order for item "P" at location "A". Due date = Jan. 5.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 10);
        ProductionOrder.Validate("Location Code", LocationFrom.Code);
        ProductionOrder.Validate("Due Date", WorkDate() + 5);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Post output of "P"; new item ledger entry = "X".
        PostOutput(ProductionOrder."No.", ProdItem."No.", ProductionOrder.Quantity, 0);
        FindLastItemLedgerEntry(ItemLedgerEntry, ProdItem."No.", LocationFrom.Code, true);

        // [GIVEN] Create and post item reclassification of item "P" from location "A" to location "B".
        CreateAndPostItemReclassificationJournalLine(ProdItem."No.", LocationFrom.Code, LocationTo.Code, 10, ItemLedgerEntry."Entry No.");

        // [GIVEN] Post three negative item entries at location "B", quantity = -1, posting dates = Jan. 10, Jan. 11, Jan. 12.
        CreateAndPostItemJournalLineWithPostingDate(ProdItem."No.", LocationTo.Code, -1, WorkDate() + 10);
        CreateAndPostItemJournalLineWithPostingDate(ProdItem."No.", LocationTo.Code, -1, WorkDate() + 11);
        FindLastItemLedgerEntry(ItemLedgerEntry, ProdItem."No.", LocationTo.Code, false);
        CreateAndPostItemJournalLineWithPostingDate(ProdItem."No.", LocationTo.Code, -1, WorkDate() + 12);

        // [GIVEN] Post positive item entry at location "B", quantity = 1, applied to the negative entry for Jan. 11.
        CreateAndPostItemJournalLineWithAppliesFromEntry(ProdItem."No.", LocationTo.Code, 1, ItemLedgerEntry."Entry No.");

        // [WHEN] Post consumption for the production order, posting date = Jan. 20.
        CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder."No.", CompItem."No.", 10);
        ItemJournalLine.Validate("Posting Date", WorkDate() + 20);
        ItemJournalLine.Validate("Location Code", LocationFrom.Code);
        ItemJournalLine.Modify(true);
        LibraryManufacturing.PostConsumptionJournal();

        // [THEN] "Valuation Date" on all posted value entries for item "P" is updated to Jan. 20.
        ValueEntry.SetRange("Item No.", ProdItem."No.");
        RecordCount := ValueEntry.Count();
        ValueEntry.SetRange("Valuation Date", WorkDate() + 20);
        Assert.RecordCount(ValueEntry, RecordCount);
    end;

    [Test]
    procedure CollectingItemLedgerEntryTypesUsedUT()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemLedgerEntryTypesUsed: Dictionary of [Enum "Item Ledger Entry Type", Boolean];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 502401] Making a dictionary of used item ledger entry types.
        Initialize();
        ItemNo := LibraryUtility.GenerateGUID();

        if ItemLedgerEntry.FindSet() then
            repeat
                TempItemLedgerEntry := ItemLedgerEntry;
                TempItemLedgerEntry.Insert();
            until ItemLedgerEntry.Next() = 0;
        ItemLedgerEntry.DeleteAll();

        MockItemLedgerEntry("Item Ledger Entry Type"::Consumption, '');
        MockItemLedgerEntry("Item Ledger Entry Type"::"Positive Adjmt.", '');
        MockItemLedgerEntry("Item Ledger Entry Type"::Purchase, ItemNo);
        MockItemLedgerEntry("Item Ledger Entry Type"::Transfer, ItemNo);

        ItemLedgerEntry.CollectItemLedgerEntryTypesUsed(ItemLedgerEntryTypesUsed, ItemNo);
        Assert.IsFalse(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::Consumption), '');
        Assert.IsFalse(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::"Positive Adjmt."), '');
        Assert.IsTrue(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::Purchase), '');
        Assert.IsTrue(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::Transfer), '');
        Assert.IsFalse(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::"Negative Adjmt."), '');

        ItemLedgerEntry.CollectItemLedgerEntryTypesUsed(ItemLedgerEntryTypesUsed, '');
        Assert.IsTrue(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::Consumption), '');
        Assert.IsTrue(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::"Positive Adjmt."), '');
        Assert.IsTrue(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::Purchase), '');
        Assert.IsTrue(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::Transfer), '');
        Assert.IsFalse(ItemLedgerEntryTypesUsed.Get("Item Ledger Entry Type"::"Negative Adjmt."), '');

        // tear down
        ItemLedgerEntry.DeleteAll();
        if TempItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry := TempItemLedgerEntry;
                ItemLedgerEntry.Insert();
            until TempItemLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure CostOfNegativeTransferEntryAppliedToThreePositiveEntries()
    var
        Item: Record Item;
        FromLocation, ToLocation, InTransitLocation : Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Costing] [Cost Adjustment]
        // [SCENARIO 548066] Verify correct cost of negative transfer entry applied to three positive entries.
        Initialize();

        // [GIVEN] Locations "From", "To", "In Transit".
        // [GIVEN] Item with FIFO costing method.
        CreateLocationsChain(FromLocation, ToLocation, InTransitLocation);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 8.0);

        // [GIVEN] Post 5 pcs of the item to location "From". Unit cost = 8.
        PostPositiveAdjustment(Item, FromLocation.Code, 5, 40.0, 0);

        // [GIVEN] Post -1 pcs of the item from location "From". Unit cost = 9.
        // [GIVEN] Post 1 pcs of the item to location "From". Unit cost = 9. Apply to the negative entry.
        LibraryInventory.PostNegativeAdjustment(Item, FromLocation.Code, '', '', 1, WorkDate(), 9.0);
        FindLastItemLedgerEntry(ItemLedgerEntry, Item."No.", FromLocation.Code, false);
        PostPositiveAdjustment(Item, FromLocation.Code, 1, 9.0, ItemLedgerEntry."Entry No.");

        // [GIVEN] Post -1 pcs of the item from location "From". Unit cost = 9.
        // [GIVEN] Post 1 pcs of the item to location "From". Unit cost = 9. Apply to the negative entry.
        LibraryInventory.PostNegativeAdjustment(Item, FromLocation.Code, '', '', 1, WorkDate(), 9.0);
        FindLastItemLedgerEntry(ItemLedgerEntry, Item."No.", FromLocation.Code, false);
        PostPositiveAdjustment(Item, FromLocation.Code, 1, 9.0, ItemLedgerEntry."Entry No.");

        // [GIVEN] Transfer 5 pcs of the item from location "From" to location "To".
        LibraryInventory.CreateAndPostTransferOrder(
          TransferHeader, Item, FromLocation, ToLocation, InTransitLocation, '', 5, WorkDate(), WorkDate(), true, true);

        // [WHEN] Run the cost adjustment.
        // [THEN] Unit cost of the item is equal to 8, because the source of cost for all further entries is the positive entry with unit cost = 8.
        AdjustCostAndVerify(Item."No.", 8.0);
    end;

    [Test]
    procedure UpdateOverheadRateOnItemWithAdjustedCost()
    var
        Item: Record Item;
    begin
        // [SCENARIO 557883] Update overhead rate does not trigger cost adjustment when "Cost is Adjusted" = true.
        // [SCENARIO 557883] Update indirect cost % does not trigger cost adjustment when "Cost is Adjusted" = true.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Cost is Adjusted" := true;
        Item.Modify(true);

        Item.Validate("Overhead Rate", LibraryRandom.RandInt(10));
        Item.Validate("Indirect Cost %", LibraryRandom.RandInt(10));
    end;

    [Test]
    procedure UpdateOverheadRateOnItemNoOrdersExist()
    var
        Item: Record Item;
    begin
        // [SCENARIO 557883] Update overhead rate does not trigger cost adjustment when no production or assembly orders exist.
        // [SCENARIO 557883] Update indirect cost % does not trigger cost adjustment when no production or assembly orders exist.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Cost is Adjusted" := false;
        Item.Modify(true);

        Item.Validate("Overhead Rate", LibraryRandom.RandInt(10));
        Item.Validate("Indirect Cost %", LibraryRandom.RandInt(10));
        Item.Modify(true);

        Item.TestField("Cost is Adjusted", false);
    end;

    [Test]
    procedure UpdateOverheadRateOnItemAllOrdersAdjusted()
    var
        Item: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        // [SCENARIO 557883] Update overhead rate does not trigger cost adjustment when all production or assembly orders are adjusted.
        // [SCENARIO 557883] Update indirect cost % does not trigger cost adjustment when all production or assembly orders are adjusted.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Cost is Adjusted" := false;
        Item.Modify(true);

        InventoryAdjmtEntryOrder.Init();
        InventoryAdjmtEntryOrder."Item No." := Item."No.";
        InventoryAdjmtEntryOrder."Order Type" := InventoryAdjmtEntryOrder."Order Type"::Assembly;
        InventoryAdjmtEntryOrder."Order No." := LibraryUtility.GenerateGUID();
        InventoryAdjmtEntryOrder."Cost is Adjusted" := true;
        InventoryAdjmtEntryOrder.Insert();

        InventoryAdjmtEntryOrder.Init();
        InventoryAdjmtEntryOrder."Item No." := Item."No.";
        InventoryAdjmtEntryOrder."Order Type" := InventoryAdjmtEntryOrder."Order Type"::Production;
        InventoryAdjmtEntryOrder."Order No." := LibraryUtility.GenerateGUID();
        InventoryAdjmtEntryOrder."Is Finished" := true;
        InventoryAdjmtEntryOrder."Cost is Adjusted" := true;
        InventoryAdjmtEntryOrder.Insert();

        InventoryAdjmtEntryOrder.Init();
        InventoryAdjmtEntryOrder."Item No." := Item."No.";
        InventoryAdjmtEntryOrder."Order Type" := InventoryAdjmtEntryOrder."Order Type"::Production;
        InventoryAdjmtEntryOrder."Order No." := LibraryUtility.GenerateGUID();
        InventoryAdjmtEntryOrder."Is Finished" := false;
        InventoryAdjmtEntryOrder."Cost is Adjusted" := false;
        InventoryAdjmtEntryOrder.Insert();

        Item.Validate("Overhead Rate", LibraryRandom.RandInt(10));
        Item.Validate("Indirect Cost %", LibraryRandom.RandInt(10));
        Item.Modify(true);

        Item.TestField("Cost is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UpdateOverheadRateOnItemAsmOrderExists()
    var
        AsmItem, CompItem, UnrelatedItem : Record Item;
        AssemblyHeader: Record "Assembly Header";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        // [SCENARIO 557883] Update overhead rate triggers cost adjustment when non-adjusted assembly orders exist.
        Initialize();

        // [GIVEN] Set "Automatic Cost Adjustment" = "Never" in Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtNever();

        // [GIVEN] Create assembly item, component item, and an item unrelated to the assembly.
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(UnrelatedItem);
        UnrelatedItem."Cost is Adjusted" := false;
        UnrelatedItem.Modify(true);

        // [GIVEN] Create assembly BOM.
        LibraryAssembly.CreateAssemblyListComponent("BOM Component Type"::Item, CompItem."No.", AsmItem."No.", '', 0, 1, true);

        // [GIVEN] Post positive inventory adjustment for the component item.
        PostPositiveAdjustment(CompItem, '', 1, 1.0, 0);

        // [GIVEN] Create and post assembly order.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 10, AsmItem."No.", '', 1, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Check the cost is not adjusted for the assembly order, Overhead Rate = 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Assembly, AssemblyHeader."No.", 0);
        InventoryAdjmtEntryOrder.TestField("Overhead Rate", 0);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", false);
        AsmItem.Find();
        AsmItem.TestField("Cost is Adjusted", false);

        // [WHEN] Update the overhead rate for the assembly item.
        AsmItem.Validate("Overhead Rate", 10);
        AsmItem.Modify(true);

        // [THEN] The cost of the assembly item is adjusted.
        AsmItem.TestField("Cost is Adjusted", true);

        // [THEN] New Overhead Rate is saved for the assembly item.
        AsmItem.TestField("Overhead Rate", 10);

        // [THEN] The cost of the component item is adjusted, Overhead Rate is not changed and remains 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Assembly, AssemblyHeader."No.", 0);
        InventoryAdjmtEntryOrder.TestField("Overhead Rate", 0);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", true);

        // [THEN] The cost of the component item and the unrelated item is not adjusted.
        CompItem.Find();
        CompItem.TestField("Cost is Adjusted", false);
        UnrelatedItem.Find();
        UnrelatedItem.TestField("Cost is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UpdateOverheadRateOnItemFinishedProdOrderExists()
    var
        ProdItem, UnrelatedItem : Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        // [SCENARIO 557883] Update overhead rate triggers cost adjustment when non-adjusted finished production orders exist.
        Initialize();

        // [GIVEN] Set "Automatic Cost Adjustment" = "Never" in Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtNever();

        // [GIVEN] Create production item and one more item unrelated to the production.
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(UnrelatedItem);
        UnrelatedItem."Cost is Adjusted" := false;
        UnrelatedItem.Modify(true);

        // [GIVEN] Create released production order and post the output.
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        PostOutput(ProductionOrder."No.", ProdItem."No.", ProductionOrder.Quantity, 0);

        // [GIVEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Check the cost is not adjusted for the production order, Overhead Rate = 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.TestField("Overhead Rate", 0);
        InventoryAdjmtEntryOrder.TestField("Is Finished", true);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", false);
        ProdItem.Find();
        ProdItem.TestField("Cost is Adjusted", false);

        // [WHEN] Update the overhead rate for the production item.
        ProdItem.Validate("Overhead Rate", 10);
        ProdItem.Modify(true);

        // [THEN] The cost of the production item is adjusted.
        ProdItem.TestField("Cost is Adjusted", true);

        // [THEN] New Overhead Rate is saved for the production item.
        ProdItem.TestField("Overhead Rate", 10);

        // [THEN] The cost of the component item is adjusted, Overhead Rate is not changed and remains 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.TestField("Overhead Rate", 0);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", true);

        // [THEN] The cost of the unrelated item is not adjusted.
        UnrelatedItem.Find();
        UnrelatedItem.TestField("Cost is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UpdateIndirectCostPercOnItemAsmOrderExists()
    var
        AsmItem, CompItem, UnrelatedItem : Record Item;
        AssemblyHeader: Record "Assembly Header";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        // [SCENARIO 557883] Update Indirect Cost % triggers cost adjustment when non-adjusted assembly orders exist.
        Initialize();

        // [GIVEN] Set "Automatic Cost Adjustment" = "Never" in Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtNever();

        // [GIVEN] Create assembly item, component item, and an item unrelated to the assembly.
        LibraryInventory.CreateItem(AsmItem);
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(UnrelatedItem);
        UnrelatedItem."Cost is Adjusted" := false;
        UnrelatedItem.Modify(true);

        // [GIVEN] Create assembly BOM.
        LibraryAssembly.CreateAssemblyListComponent("BOM Component Type"::Item, CompItem."No.", AsmItem."No.", '', 0, 1, true);

        // [GIVEN] Post positive inventory adjustment for the component item.
        PostPositiveAdjustment(CompItem, '', 1, 1.0, 0);

        // [GIVEN] Create and post assembly order.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 10, AsmItem."No.", '', 1, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [GIVEN] Check the cost is not adjusted for the assembly order, Indirect Cost % = 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Assembly, AssemblyHeader."No.", 0);
        InventoryAdjmtEntryOrder.TestField("Indirect Cost %", 0);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", false);
        AsmItem.Find();
        AsmItem.TestField("Cost is Adjusted", false);

        // [WHEN] Update the indirect cost % for the assembly item.
        AsmItem.Validate("Indirect Cost %", 10);
        AsmItem.Modify(true);

        // [THEN] The cost of the assembly item is adjusted.
        AsmItem.TestField("Cost is Adjusted", true);

        // [THEN] New Indirect Cost % is saved for the assembly item.
        AsmItem.TestField("Indirect Cost %", 10);

        // [THEN] The cost of the component item is adjusted, Indirect Cost % is not changed and remains 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Assembly, AssemblyHeader."No.", 0);
        InventoryAdjmtEntryOrder.TestField("Indirect Cost %", 0);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", true);

        // [THEN] The cost of the component item and the unrelated item is not adjusted.
        CompItem.Find();
        CompItem.TestField("Cost is Adjusted", false);
        UnrelatedItem.Find();
        UnrelatedItem.TestField("Cost is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UpdateIndirectCostPercOnItemFinishedProdOrderExists()
    var
        ProdItem, UnrelatedItem : Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        // [SCENARIO 557883] Update Indirect Cost % triggers cost adjustment when non-adjusted finished production orders exist.
        Initialize();

        // [GIVEN] Set "Automatic Cost Adjustment" = "Never" in Inventory Setup.
        LibraryInventory.SetAutomaticCostAdjmtNever();

        // [GIVEN] Create production item and one more item unrelated to the production.
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(UnrelatedItem);
        UnrelatedItem."Cost is Adjusted" := false;
        UnrelatedItem.Modify(true);

        // [GIVEN] Create released production order and post the output.
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        PostOutput(ProductionOrder."No.", ProdItem."No.", ProductionOrder.Quantity, 0);

        // [GIVEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Check the cost is not adjusted for the production order, Indirect Cost % = 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.TestField("Indirect Cost %", 0);
        InventoryAdjmtEntryOrder.TestField("Is Finished", true);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", false);
        ProdItem.Find();
        ProdItem.TestField("Cost is Adjusted", false);

        // [WHEN] Update the Indirect Cost % for the production item.
        ProdItem.Validate("Indirect Cost %", 10);
        ProdItem.Modify(true);

        // [THEN] The cost of the production item is adjusted.
        ProdItem.TestField("Cost is Adjusted", true);

        // [THEN] New Indirect Cost % is saved for the production item.
        ProdItem.TestField("Indirect Cost %", 10);

        // [THEN] The cost of the component item is adjusted, Indirect Cost % is not changed and remains 0.
        InventoryAdjmtEntryOrder.Get(InventoryAdjmtEntryOrder."Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        InventoryAdjmtEntryOrder.TestField("Indirect Cost %", 0);
        InventoryAdjmtEntryOrder.TestField("Cost is Adjusted", true);

        // [THEN] The cost of the unrelated item is not adjusted.
        UnrelatedItem.Find();
        UnrelatedItem.TestField("Cost is Adjusted", false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Bugs II");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        // Lazy Setup.

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Bugs II");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Bugs II");
    end;

    local procedure BlockItemWithApplWorksheet(var Item: Record Item)
    begin
        Item.Find();
        Item.Validate("Application Wksh. User ID", UserId);
        Item.Modify(true);
    end;

    local procedure CreateAndPostConsumptionJournalLine(ItemNo: Code[20]; ProdOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateConsumptionJournalLine(ItemJournalLine, ProdOrderNo, ItemNo, Quantity);
        LibraryManufacturing.PostConsumptionJournal();
    end;

    local procedure CreatePurchaseLineForItemCharge(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; PurchRcptLine: Record "Purch. Rcpt. Line"; DirectUnitCost: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Qty, LocationCode, WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure CreateAndPostOutputJournalLine(ItemNo: Code[20]; ProdOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalLine(ItemJournalLine, ItemNo, ProdOrderNo, Quantity);
        LibraryManufacturing.PostOutputJournal();
    end;

    local procedure CreateAndPostItemJournalLineWithPostingDate(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithAppliesToEntry(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; AppliesToEntry: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithAppliesFromEntry(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; AppliesFromEntry: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        ItemJournalLine.Validate("Applies-from Entry", AppliesFromEntry);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithUnitAmount(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemReclassificationJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; NewLocationCode: Code[10]; Qty: Decimal; AppliesToEntry: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("New Location Code", NewLocationCode);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseOrderAndFindRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Qty, LocationCode, WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure CreateAndPostPurchaseInvoiceForItemCharge(PurchRcptLine: Record "Purch. Rcpt. Line"; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateConsumptionJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        InitItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);
        ItemJournalLine.Init();
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Consumption;

        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderNo);
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; UnitCost: Decimal; ReplenishmentSystem: Enum "Replenishment System"; RoundingPrecision: Decimal)
    begin
        LibraryInventory.CreateItemSimple(Item, CostingMethod, UnitCost);

        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Rounding Precision", RoundingPrecision);
        Item.Modify(true);
    end;

    local procedure CreateItemAndUpdateInventory(var Item: Record Item)
    var
        LocationBlue: Record Location;
        Qty: Decimal;
        i: Integer;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');
        Qty := LibraryRandom.RandDec(100, 2);
        for i := 1 to 2 do
            LibraryInventory.PostPositiveAdjustment(Item, LocationBlue.Code, '', '', Qty, WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostNegativeAdjustment(Item, LocationBlue.Code, '', '', Qty, WorkDate(), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateItemPostPositiveAdjmt(Quantity: Decimal; CostAmount: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');
        LibraryPatterns.POSTPositiveAdjustmentAmount(Item, '', '', Quantity, WorkDate(), CostAmount);

        exit(Item."No.");
    end;

    local procedure CreateRelProdOrder(var ProdOrderLine: Record "Prod. Order Line"; LocationCode: Code[10]; var CompItem: Record Item; var Qty: Decimal)
    var
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        RoutingLink: Record "Routing Link";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        QtyPer: Decimal;
    begin
        LibraryInventory.CreateItem(ParentItem, ParentItem."Costing Method"::FIFO, 0, 0, 0, '');
        ParentItem.Validate("Flushing Method", ParentItem."Flushing Method"::Backward);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Modify();

        LibraryInventory.CreateItem(CompItem, CompItem."Costing Method"::FIFO, 0, 0, 0, '');
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::Backward);
        CompItem.Modify();

        QtyPer := LibraryRandom.RandInt(10);
        RoutingLink.FindFirst();
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, CompItem, QtyPer, RoutingLink.Code);
        LibraryManufacturing.CreateRouting(RoutingHeader, ParentItem, RoutingLink.Code, 0);

        Qty := LibraryRandom.RandInt(100);
        LibraryPurchase.POSTPurchaseOrder(
          PurchaseHeader, CompItem, LocationCode, '', Qty * QtyPer, WorkDate(), LibraryRandom.RandDec(100, 5), true, true);

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem, LocationCode, '', Qty, WorkDate());
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
    end;

    local procedure CreateOrderAndShip(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Quantity, WorkDate(), Item."Unit Cost", true, false);

        exit(SalesHeader."No.");
    end;

    local procedure CreateLocationsChain(var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
    end;

    local procedure CreateOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ProdOrderNo: Code[20]; OutputQty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        InitItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProdOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalesShptLine(var SalesShptLine: Record "Sales Shipment Line")
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Qty: Decimal;
    begin
        // All numbers aren't a matter.
        Qty := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty, WorkDate(), LibraryRandom.RandDec(100, 2), true, true);
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty, WorkDate(), LibraryRandom.RandDec(100, 2), true, true);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        SalesShptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");
    end;

    local procedure CreateTransferReceiptLine(var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
    begin
        // All numbers aren't a matter.
        Qty := LibraryRandom.RandInt(10);
        CreateLocationsChain(FromLocation, ToLocation, TransitLocation);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.POSTPurchaseOrder(
          PurchaseHeader, Item, FromLocation.Code, '', Qty, WorkDate(), LibraryRandom.RandDec(100, 2), true, true);
        LibraryInventory.CreateAndPostTransferOrder(
          TransferHeader, Item, FromLocation, ToLocation, TransitLocation, '', Qty, WorkDate(), WorkDate(), true, true);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);
        TransferReceiptLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");
    end;

    local procedure CreateItemCharge(var PurchaseLine: Record "Purchase Line"; var ItemCharge: Record "Item Charge")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreateItemChargePurchaseLine(PurchaseLine, ItemCharge, PurchaseHeader, 1, LibraryRandom.RandDec(100, 2));
    end;

    local procedure InitItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, TemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure InsertItemChargeAssgntPurchForSalesShptLine(PurchaseLine: Record "Purchase Line")
    var
        SalesShptLine: Record "Sales Shipment Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        CreateSalesShptLine(SalesShptLine);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Sales Shipment",
          SalesShptLine."Document No.", SalesShptLine."Line No.", SalesShptLine."No.");
    end;

    local procedure InsertItemChargeAssgntPurchForTransferReceiptLine(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line")
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        CreateTransferReceiptLine(TransferReceiptLine);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Transfer Receipt",
          TransferReceiptLine."Document No.", TransferReceiptLine."Line No.", TransferReceiptLine."Item No.");
    end;

    local procedure CreateItemChargeAssgntPurchForSalesShptLine(var PurchaseLine: Record "Purchase Line")
    var
        ItemCharge: Record "Item Charge";
    begin
        CreateItemCharge(PurchaseLine, ItemCharge);
        InsertItemChargeAssgntPurchForSalesShptLine(PurchaseLine);
    end;

    local procedure CreateItemChargeAssgntPurchForTransferReceiptLine(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemCharge: Record "Item Charge";
    begin
        CreateItemCharge(PurchaseLine, ItemCharge);
        InsertItemChargeAssgntPurchForTransferReceiptLine(ItemChargeAssignmentPurch, PurchaseLine);
    end;

    local procedure CreateItemChargeAssgntPurchForSalesShptLineAndTransferReceiptLine(var PurchaseLine: Record "Purchase Line")
    var
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        CreateItemCharge(PurchaseLine, ItemCharge);
        InsertItemChargeAssgntPurchForSalesShptLine(PurchaseLine);
        InsertItemChargeAssgntPurchForTransferReceiptLine(ItemChargeAssignmentPurch, PurchaseLine);
    end;

    local procedure ChangeSalesLineQuantityAndPost(OrderNo: Code[20]; NewQuantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Find();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderNo);
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure FindApplicationWorksheetLine(var ApplicationWorksheet: TestPage "Application Worksheet"; ItemNo: Code[20]; EntryType: Text[50])
    begin
        ApplicationWorksheet.FILTER.SetFilter("Item No.", ItemNo);
        ApplicationWorksheet.FILTER.SetFilter("Entry Type", EntryType);
        ApplicationWorksheet.First();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; LocationCode: Code[10]; IsPositive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; IsPositive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindLast();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindOutputItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure MakeItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, TemplateType);
    end;

    local procedure MakeSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure MockItemLedgerEntry(ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Entry Type" := ItemLedgerEntryType;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Insert();
    end;

    local procedure PostProductionOrderAndFinish(ProductionOrder: Record "Production Order"; ComponentItem: Record Item; QtyToConsume: Decimal; QtyToProduce: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.CreateConsumptionJournalLine(
          ItemJournalBatch, ProdOrderLine, ComponentItem, WorkDate(), '', '', QtyToConsume, ComponentItem."Unit Cost");
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), QtyToProduce, 0);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);
    end;

    local procedure PostOutput(ProductionOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; AppliesToEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntryNo);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure ReadjustStandardCostItem(var Item: Record Item)
    var
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemStandardCost: Decimal;
        InitialComponentCost: Decimal;
        NewComponentCost: Decimal;
        Qty: Decimal;
    begin
        Qty := 100000;
        ItemStandardCost := Round(0.00755, LibraryERM.GetUnitAmountRoundingPrecision());
        InitialComponentCost := Round(0.00855, LibraryERM.GetUnitAmountRoundingPrecision());
        NewComponentCost := Round(0.00875, LibraryERM.GetUnitAmountRoundingPrecision());

        CreateItem(
          ComponentItem, ComponentItem."Costing Method"::FIFO, 0, ComponentItem."Replenishment System"::Purchase,
          LibraryERM.GetUnitAmountRoundingPrecision());
        CreateItem(
          Item, Item."Costing Method"::Standard, ItemStandardCost, Item."Replenishment System"::"Prod. Order",
          LibraryERM.GetUnitAmountRoundingPrecision());
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, Item, ComponentItem, 1, '');

        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ComponentItem, '', '', Qty, WorkDate(), InitialComponentCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseLine.Find();

        PostItemConsumptionAndOutput(ProductionOrder, Item, ComponentItem, Qty, Qty);
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', Item."No.", ComponentItem."No."), '');

        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Find();
        UpdateQtyToInvoiceAndUnitCostOnPurchaseLine(PurchaseLine, PurchaseLine."Qty. to Invoice", NewComponentCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', Item."No.", ComponentItem."No."), '');
    end;

    local procedure RunCostAdjustment(ItemNo: Code[20])
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
    begin
        Commit();
        AdjustCostItemEntries.InitializeRequest(ItemNo, '');
        AdjustCostItemEntries.UseRequestPage(true);
        AdjustCostItemEntries.RunModal();
    end;

    local procedure UpdateQtyToInvoiceAndUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure UndoSalesShipment(OrderNo: Code[20])
    var
        SalesShptLine: Record "Sales Shipment Line";
    begin
        SalesShptLine.SetRange("Order No.", OrderNo);
        LibrarySales.UndoSalesShipmentLine(SalesShptLine);
    end;

    local procedure VerifyOutboudEntriesUpdated(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, false);
        ItemLedgerEntry.FindSet();
        repeat
            ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplnEntry.FindFirst();
            Assert.IsTrue(ItemApplnEntry."Outbound Entry is Updated", OutbndEntryIsNotUpdatedErr);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyPostValueEntryToGL(ProductionOrder: Record "Production Order")
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ProductionOrder."Source No.");
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProductionOrder."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.SetRange("Cost Amount (Actual)", 0);
        if ValueEntry.FindSet() then
            repeat
                PostValueEntryToGL.SetRange("Value Entry No.", ValueEntry."Entry No.");
                PostValueEntryToGL.SetRange("Item No.", ValueEntry."Item No.");
                Assert.AreEqual(
                  0, PostValueEntryToGL.Count,
                  'Value Entry ' + Format(ValueEntry."Entry No.") + 'has Cost Amount Actual of 0 and should not be posted to G/L');
            until ValueEntry.Next() = 0;
    end;

    local procedure VerifyILECostAmount(ItemNo: Code[20]; ExpectedCostAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)");
        Assert.AreEqual(
          ExpectedCostAmount, ItemLedgerEntry."Cost Amount (Expected)", StrSubstNo(WrongCostAmountErr, ItemLedgerEntry.FieldCaption("Cost Amount (Expected)")));
    end;

    local procedure VerifyItemLedgerEntriesCostEquality(var PosItemLedgerEntry: Record "Item Ledger Entry"; var NegItemLedgerEntry: Record "Item Ledger Entry")
    begin
        PosItemLedgerEntry.Find();
        PosItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        NegItemLedgerEntry.Find();
        NegItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(PosItemLedgerEntry."Cost Amount (Actual)", -NegItemLedgerEntry."Cost Amount (Actual)", ItemNoAdjustedErr);
    end;

    local procedure VerifyInventoryAmountIsZero(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
        Assert.AreNearlyEqual(0, ValueEntry."Cost Amount (Expected)", 0.01, InventoryValueErr);
        Assert.AreNearlyEqual(0, ValueEntry."Cost Amount (Actual)", 0.01, InventoryValueErr);
    end;

    local procedure VerifyItemStandardCost(ItemNo: Code[20])
    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(Item."Standard Cost" * Item.Inventory, ValueEntry."Cost Amount (Actual)", WrongStandardCostVarianceErr);
    end;

    local procedure VerifyItemStandardCostACY(ItemNo: Code[20]; ACYCode: Code[10])
    var
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual) (ACY)", "Invoiced Quantity");

        Currency.Get(ACYCode);
        Assert.AreNearlyEqual(
          Item."Standard Cost" * CurrExchRate.ExchangeRate(WorkDate(), ACYCode),
          ValueEntry."Cost Amount (Actual) (ACY)" / ValueEntry."Invoiced Quantity",
          Currency."Unit-Amount Rounding Precision",
          WrongStandardCostVarianceErr);
    end;

    local procedure VerifyRevaluedTransferCostAmount(ItemNo: Code[20]; LocationCode: Code[10]; CostAmount: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Transfer);
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Location Code", LocationCode);
        ItemLedgEntry.SetRange(Positive, true);
        ItemLedgEntry.FindFirst();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(
          CostAmount, ItemLedgEntry."Cost Amount (Actual)", StrSubstNo(WrongCostAmountErr, ItemLedgEntry.FieldCaption("Cost Amount (Actual)")));
    end;

    local procedure VeriryItemApplicationEntryHistory(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
    begin
        ItemLedgerEntry.FindSet();
        repeat
            ItemApplicationEntryHistory.Init();
            ItemApplicationEntryHistory.SetRange("Entry No.", 0);
            ItemApplicationEntryHistory.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
            Assert.RecordIsEmpty(ItemApplicationEntryHistory);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyValueEntry(ItemNo: Code[20]; Qty: Decimal; CostAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Cost Amount (Actual)");
        ValueEntry.TestField("Item Ledger Entry Quantity", Qty);
        ValueEntry.TestField("Cost Amount (Actual)", CostAmount);
    end;

    local procedure VerifyValuedByAverageCostValueEntry(ItemLedgerEntryNo: Integer; ValuedByAverageCost: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Valued By Average Cost", ValuedByAverageCost);
        until ValueEntry.Next() = 0;
    end;

    local procedure AdjustCostAndVerify(ItemNo: Code[20]; ExpectedUnitCost: Decimal)
    var
        Item: Record Item;
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        Item.Get(ItemNo);
        Assert.AreNearlyEqual(ExpectedUnitCost, Item."Unit Cost", LibraryERM.GetUnitAmountRoundingPrecision(), '');
    end;

    local procedure PostItemConsumptionAndOutput(var ProductionOrder: Record "Production Order"; ProdItem: Record Item; ComponentItem: Record Item; QtyToProduce: Decimal; QtyToConsume: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProdItem, '', '', QtyToProduce, WorkDate());
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, true);
        PostProductionOrderAndFinish(ProductionOrder, ComponentItem, QtyToConsume, QtyToProduce);
    end;

    local procedure PostNegativeOutput(ItemJournalBatch: Record "Item Journal Batch"; ProdOrderLine: Record "Prod. Order Line"; Qty: Decimal; EntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), -Qty, 0);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Applies-to Entry", EntryNo);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostItemJournalSaleByItem(Item: Record Item; LocationCode: Code[10]; Qty: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        I: Integer;
    begin
        MakeItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        for I := 1 to Qty do
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch, Item, LocationCode, '', WorkDate(), ItemJournalLine."Entry Type"::Sale, 1,
              LibraryRandom.RandDec(100, 2) + 1);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostItemJournalTransfer(Item: Record Item; FromLocationCode: Code[10]; ToLocationCode: Code[10]; Qty: Decimal; PostingDate: Date)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemReclassificationJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, '', FromLocationCode, ToLocationCode, '', '', PostingDate, Qty);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostPositiveAdjustment(Item: Record Item; LocationCode: Code[10]; Quantity: Decimal; Amount: Decimal; AppliesFromEntryNo: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, LocationCode, '', WorkDate(), ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, 0);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Validate("Applies-from Entry", AppliesFromEntryNo);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostPositiveAndNegativeEntries(Item: Record Item; Quantity: Decimal; var PositiveItemLedgerEntry: Record "Item Ledger Entry"; var NegativeItemLedgerEntry: Record "Item Ledger Entry")
    begin
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Quantity, WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', Quantity, WorkDate(), LibraryRandom.RandDec(100, 2));

        PositiveItemLedgerEntry.SetRange("Item No.", Item."No.");
        PositiveItemLedgerEntry.SetRange(Positive, true);
        PositiveItemLedgerEntry.FindLast();

        NegativeItemLedgerEntry.SetRange("Item No.", Item."No.");
        NegativeItemLedgerEntry.SetRange(Positive, false);
        NegativeItemLedgerEntry.FindLast();
    end;

    local procedure PostAndUnapplyPositiveAndNegativeAdjustments(Item: Record Item; Quantity: Decimal; var PositiveItemLedgerEntry: Record "Item Ledger Entry"; var NegativeItemLedgerEntry: Record "Item Ledger Entry"; AreUnappliedWithApplWorksheet: Boolean)
    begin
        PostPositiveAndNegativeEntries(Item, Quantity, PositiveItemLedgerEntry, NegativeItemLedgerEntry);
        UnapplyItemLedgerEntries(
          PositiveItemLedgerEntry."Entry No.", NegativeItemLedgerEntry."Entry No.", AreUnappliedWithApplWorksheet);
    end;

    local procedure PostPurchaseInvoiceWithNewUnitCost(var PurchaseHeader: Record "Purchase Header"; NewUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Direct Unit Cost", NewUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    procedure PostPurchaseJournal(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; BinCode: Code[20]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal)
    begin
        LibraryInventory.PostItemJournalLine(
            "Item Journal Template Type"::Item, "Item Ledger Entry Type"::Purchase, Item,
            LocationCode, VariantCode, BinCode, Qty, PostingDate, UnitAmount);
    end;

    local procedure PostNegativeAdjmtAndVerify(Item: Record Item; UnitCost: Decimal; FirstShipmentQty: Decimal)
    begin
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', FirstShipmentQty, WorkDate(), Item."Unit Cost");
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, WorkDate(), UnitCost);
        LibraryInventory.PostNegativeAdjustment(Item, '', '', '', 1, WorkDate(), UnitCost);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        VerifyInventoryAmountIsZero(Item."No.");
    end;

    local procedure PostRevaluationJournalLine(var Item: Record Item; PostingDate: Date; RevaluedUnitCost: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        MakeItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateRevaluationJournalLine(ItemJournalBatch, Item, PostingDate, "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ");

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", RevaluedUnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostRevaluationJournalLineForDefinedAmount(var Item: Record Item; PostingDate: Date; InvtValueRevalued: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        MakeItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateRevaluationJournalLine(ItemJournalBatch, Item, PostingDate, "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ");

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Inventory Value (Revalued)", InvtValueRevalued);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostSalesShipmentAndUndo(Item: Record Item; Quantity: Decimal; Amount: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Quantity, WorkDate(), Amount, true, false);
        UndoSalesShipment(SalesHeader."No.");
    end;

    local procedure SaleReceivedAndTransferredItem(var Item: Record Item; var PurchaseHeader: Record "Purchase Header")
    var
        Location: array[2] of Record Location;
        Qty: Integer;
        UnitCost: Decimal;
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 0);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // Hardcoded numbers to reproduce rounding issue
        Qty := 6;
        UnitCost := 8.74444;
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, Location[1].Code, '', Qty, WorkDate(), UnitCost, true, false);
        PostItemJournalTransfer(Item, Location[1].Code, Location[2].Code, Qty, WorkDate());

        PostItemJournalSaleByItem(Item, Location[2].Code, Qty);
    end;

    local procedure UnapplyItemLedgerEntries(PosItemLedgEntryNo: Integer; NegItemLedgEntryNo: Integer; AreUnappliedWithApplWorksheet: Boolean)
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlPostLine.SetCalledFromApplicationWorksheet(AreUnappliedWithApplWorksheet);

        ItemApplicationEntry.SetRange("Inbound Item Entry No.", PosItemLedgEntryNo);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", NegItemLedgEntryNo);
        ItemApplicationEntry.FindFirst();
        ItemJnlPostLine.UnApply(ItemApplicationEntry);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ViewAppliedEntriesHandler(var ViewAppliedEntries: TestPage "View Applied Entries")
    begin
        ViewAppliedEntries.RemoveAppButton.Invoke();
        ViewAppliedEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ViewUnappliedEntriesModalHandler(var ViewAppliedEntries: TestPage "View Applied Entries")
    begin
        ViewAppliedEntries.First();
        ViewAppliedEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ViewUnapplEntrSelectNextModalHandler(var ViewAppliedEntries: TestPage "View Applied Entries")
    begin
        ViewAppliedEntries.First();
        ViewAppliedEntries.Next();
        ViewAppliedEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure AdjustCostItemEntriesRequestPageHandler(var AdjustCostItemEntries: TestRequestPage "Adjust Cost - Item Entries")
    begin
        AdjustCostItemEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Option);
        Choice := 1;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

