codeunit 137603 "SCM CETAF Costing Revaluation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Revaluation] [SCM]
        isInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        TXTCalcPerILEAvgCostErr: Label 'You must not revalue items with Costing Method Average, if Calculate Per is Item Ledger Entry.';
        TXTIncorrectUnitCostErr: Label 'Incorrect value in Unit Cost (Calculated) field in revaluation line.';

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CETAF Costing Revaluation");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CETAF Costing Revaluation");

        LibraryInventory.UpdateAverageCostSettings(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        LibraryInventory.SetAverageCostSetupInAccPeriods(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryPatterns.SetNoSeries();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CETAF Costing Revaluation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFOwLoc_RevalueExInvPerItem()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInv(Item."Costing Method"::FIFO, 0, "Inventory Value Calc. Per"::Item, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvgwLoc_RevalueExInvPerItem()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInv(Item."Costing Method"::Average, 0, "Inventory Value Calc. Per"::Item, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStdwLoc_RevalueExInvPerItem()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInv(Item."Costing Method"::Standard, 50, "Inventory Value Calc. Per"::Item, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFOwLoc_RevalueExInvPerItem()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInv(Item."Costing Method"::LIFO, 0, "Inventory Value Calc. Per"::Item, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFOwLoc_RevalueInboundILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueInboundILEwLoc(Item."Costing Method"::FIFO, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvgwLoc_RevalueInboundILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueInboundILEwLoc(Item."Costing Method"::Average, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStdwLoc_RevalueInboundILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueInboundILEwLoc(Item."Costing Method"::Standard, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFO_RevalueExInvPerItemNegZeroInv()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInvNegZeroInv(Item."Costing Method"::LIFO, 0, "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvg_RevalueExInvPerItemNegZeroInv()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInvNegZeroInv(Item."Costing Method"::Average, 0, "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStd_RevalueExInvPerItemNegZeroInv()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInvNegZeroInv(Item."Costing Method"::Standard, 50, "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFOwLoc_RevalueExInvPerILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInv(Item."Costing Method"::FIFO, 0, "Inventory Value Calc. Per"::"Item Ledger Entry", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvgwLoc_RevalueExInvPerILE()
    var
        Item: Record Item;
    begin
        Initialize();
        asserterror TestRevalueExistingInv(Item."Costing Method"::Average, 0, "Inventory Value Calc. Per"::"Item Ledger Entry", true);
        Assert.ExpectedError(TXTCalcPerILEAvgCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStdwLoc_RevalueExInvPerILE()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInv(Item."Costing Method"::Standard, 50, "Inventory Value Calc. Per"::"Item Ledger Entry", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvgwLocVar_RevalueExInvPerItem()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInvwLocVar(Item."Costing Method"::Average, 0, "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStdwLocVar_RevalueExInvPerItem()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevalueExistingInvwLocVar(Item."Costing Method"::Standard, 50, "Inventory Value Calc. Per"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFORounding()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRounding(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvgRounding()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRounding(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStdRounding()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRounding(Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFORevaluationCircularTransfer()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationCircularTransfer(Item."Costing Method"::FIFO, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFORevaluationCircularTransfer()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationCircularTransfer(Item."Costing Method"::LIFO, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvgRevaluationCircularTransfer()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationCircularTransfer(Item."Costing Method"::Average, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStdRevaluationCircularTransfer()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationCircularTransfer(Item."Costing Method"::Standard, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFIFORevaluationSalesReturn()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationSalesReturn(Item."Costing Method"::FIFO, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLIFORevaluationSalesReturn()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationSalesReturn(Item."Costing Method"::LIFO, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAvgRevaluationSalesReturn()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationSalesReturn(Item."Costing Method"::Average, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStdRevaluationSalesReturn()
    var
        Item: Record Item;
    begin
        Initialize();
        TestRevaluationSalesReturn(Item."Costing Method"::Standard, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF265306()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Day1: Date;
        Qty: Decimal;
    begin
        // Test to reproduce Bug265306
        Initialize();

        // Make item
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryRandom.RandInt(10), 0, 0, '');

        Day1 := DMY2Date(3, 3, 2011);
        Qty := LibraryRandom.RandInt(100);

        // Post item journals
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item, '', '', '', Qty, Day1,
          LibraryRandom.RandInt(10));
        Item.Get(Item."No.");
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item, '', '', '', Qty, Day1 + 4,
          Item."Last Direct Cost");
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item, '', '', '', Qty, Day1 + 4,
          LibraryRandom.RandInt(10));
        ItemLedgerEntry.FindLast(); // store the ILE for last posistive adjustment

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Revaluation journal
        LibraryInventory.CreateRevaluationJournalLine(
          ItemJournalBatch, Item, Day1 + 4, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        FindFirstItemJnlLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.Validate("Unit Cost (Revalued)", LibraryRandom.RandInt(10));
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Post negative adjustment
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        Item.Get(Item."No.");
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item, '', '', Day1 + 4, ItemJournalLine."Entry Type"::"Negative Adjmt.", Qty, Item."Unit Cost");
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS245517()
    var
        Location: Record Location;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        Day1: Date;
        Qty: Decimal;
    begin
        // Test to reproduce Bug245517 in TFS
        Initialize();

        // Setup Item.
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, 0, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        Day1 := WorkDate();
        Qty := LibraryRandom.RandIntInRange(2, 10);
        // Post positive adjustment for item.
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', Qty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Revalue.
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, Item, Day1, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJournalBatch, LibraryRandom.RandDecInRange(1, 3, 2));

        // Post positive adjustment at different location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', Qty, Day1, 0);
        LibraryPatterns.InsertTempILEFromLast(TempItemLedgerEntry);

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Revalue to a lesser unit cost.
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, Item, Day1, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJournalBatch, LibraryRandom.RandDecInRange(0, 1, 2));

        // Adjust.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify.
        LibraryCosting.CheckAdjustment(Item);
        Item.Get(Item."No.");
        repeat
            ItemLedgerEntry.Get(TempItemLedgerEntry."Entry No.");
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            Assert.AreEqual(
              Round(TempItemLedgerEntry.Quantity * Item."Unit Cost", LibraryERM.GetAmountRoundingPrecision()),
              ItemLedgerEntry."Cost Amount (Actual)", 'Wrong revalued cost amount in entry ' + Format(ItemLedgerEntry."Entry No."));
        until TempItemLedgerEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF311425()
    var
        FIFOItem: Record Item;
        LIFOItem: Record Item;
        RevalueItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Day1: Date;
        Qty: Decimal;
    begin
        // Test to reproduce Bug311425
        Initialize();
        Day1 := WorkDate();

        // Make item
        LibraryInventory.CreateItem(FIFOItem, FIFOItem."Costing Method"::FIFO, LibraryRandom.RandInt(10), 0, 0, '');
        LibraryInventory.CreateItem(LIFOItem, LIFOItem."Costing Method"::LIFO, LibraryRandom.RandInt(10), 0, 0, '');

        // Post Item Journals
        Qty := LibraryRandom.RandInt(100);
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", FIFOItem, '', '', '', Qty, Day1,
          FIFOItem."Unit Cost");
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", LIFOItem, '', '', '', Qty, Day1,
          LIFOItem."Unit Cost");

        // Do Revaluation and Verify
        RevalueItem.SetFilter("No.", '%1|%2', FIFOItem."No.", LIFOItem."No.");
        RevalueItem.SetFilter("Costing Method", '%1|%2', RevalueItem."Costing Method"::FIFO, RevalueItem."Costing Method"::LIFO);

        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, RevalueItem, Day1, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.CHECKCalcInvPost(FIFOItem, ItemJournalBatch, Day1, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, '', '');
        LibraryPatterns.CHECKCalcInvPost(LIFOItem, ItemJournalBatch, Day1, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF177847()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalBatch2: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        TotalQty: Decimal;
        SalesQty: Decimal;
        UnitCost: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Standard Cost] [Revaluation]
        // [SCENARIO] Calc. Inventory Value for Standard Cost Item does not take into account later Revaluation.

        // [GIVEN] Purchase Item of Standard Cost = 0, Purchase Cost = "X".
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, 0);
        UnitCost := LibraryRandom.RandDec(2, 2);

        // Purchase Item
        TotalQty := LibraryRandom.RandDecInRange(2, 100, 2);
        PostingDate := WorkDate();
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase, Item, '', '', '', TotalQty, PostingDate, UnitCost);

        // [GIVEN] Sell Part of Item in Inventory
        SalesQty := LibraryRandom.RandDecInRange(1, Round(TotalQty - 1, 1), 2);
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Sale, Item, '', '', '', SalesQty, PostingDate + 1,
          Item."Unit Cost");

        // [GIVEN] Adjust - both inbound and outbound should have a cost of 0
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Revalue the remaining quantity in Day 2 - set Unit Cost to the intended value
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, Item, PostingDate + 1, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", UnitCost);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [GIVEN] Adjust
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Run Calc. Inventory Value on Day 1
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch2, Item, PostingDate, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        ItemJournalLine2.SetRange("Journal Batch Name", ItemJournalBatch2.Name);
        ItemJournalLine2.FindFirst();

        // [THEN] Check Unit Cost = 0 (since the total cost was 0 on Day 1)
        Assert.AreEqual(0, ItemJournalLine2."Unit Cost (Calculated)", TXTIncorrectUnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF343888()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        TotalQty: Decimal;
        TotalAmount: Decimal;
        i: Integer;
    begin
        // Check that revaluation journal lines correctly created for simple item and option "Calculate ByVariant"

        Initialize();
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 0);
        for i := 1 to 2 do
            PostPositiveAdjmtOnNewLocation(TotalQty, TotalAmount, Item);

        LibraryInventory.CreateRevaluationJournalLine(
          ItemJournalBatch, Item, WorkDate(), "Inventory Value Calc. Per"::Item, false, true, false, "Inventory Value Calc. Base"::" "); // pass true for ByVariant
        VerifyAmountsOnItemJnlLine(ItemJournalBatch, TotalQty, TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateUnitCostStandardWithLaterValueEntry()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Standard Cost] [Calculate Inventory Value]
        // [SCENARIO 137138] Calc. Inventory Value on date "A" for Standard Cost Item takes into account Value Entry with "Posting Date" > "A" but "Valuation Date" <= "A".

        // [GIVEN] Create Purchase Order for Item of Standard Cost = "X".
        Initialize();
        UnitCost := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, UnitCost);
        LibraryPurchase.CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, '', '', LibraryRandom.RandInt(5), WorkDate(), UnitCost);

        // [GIVEN] Post Receipt.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [GIVEN] Post Invoice of Posting Date = WorkDate() + 2 days.
        PurchaseHeader.Validate("Posting Date", WorkDate() + 2);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Run Calc. Inventory Value on WorkDate() + 1 day.
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, Item, WorkDate() + 1, "Inventory Value Calc. Per"::Item,
          false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();

        // [THEN] Check "Unit Cost (Calculated)" = "X" (since the cost was posted on WorkDate() + 2 days)
        Assert.AreEqual(UnitCost, ItemJournalLine."Unit Cost (Calculated)", TXTIncorrectUnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAppliedRevaluationExcludedFromAvgCostCalc()
    var
        LocationBlue: Record Location;
        LocationRed: Record Location;
        Item: Record Item;
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        Qty: Decimal;
        Cost: Decimal;
        NewCost: Decimal;
    begin
        // [FEATURE] [Average Cost] [Transfer] [Item Reclassification]
        // [SCENARIO 345543] Value entries for revaluation are excluded from average cost calculation when the cost of inbound entry is inherited from outbound entry.
        Initialize();

        Qty := LibraryRandom.RandInt(10);
        Cost := LibraryRandom.RandDec(10, 2);
        NewCost := LibraryRandom.RandDecInRange(50, 100, 2);

        // [GIVEN] Locations "Blue" and "Red".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);

        // [GIVEN] Item with Costing Method = "Average".
        // [GIVEN] Post 1 pc to the inventory on each location, unit cost = 10 LCY.
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);
        CreateAndPostItemJnlLine(Item."No.", LocationBlue.Code, Qty, Cost);
        CreateAndPostItemJnlLine(Item."No.", LocationBlue.Code, Qty, Cost);

        // [GIVEN] Transfer the inventory from location "Blue" to "Red" using reclassification journal.
        ItemLedgerEntry[1].Get(CreateAndPostReclassJnlLine(Item."No.", LocationBlue.Code, LocationRed.Code, Qty));
        ItemLedgerEntry[2].Get(CreateAndPostReclassJnlLine(Item."No.", LocationBlue.Code, LocationRed.Code, Qty));

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Create revaluation journal line to revalue the first incoming transfer to "Red" location.
        // [GIVEN] Set new unit cost = 50 LCY.
        // [GIVEN] Post the revaluation journal.
        CreateAndPostRevaluationJnlLine(Item."No.", ItemLedgerEntry[1]."Entry No.", NewCost);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The cost of revalued item entry has not changed.
        ItemLedgerEntry[1].CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry[1].TestField("Cost Amount (Actual)", NewCost);

        // [THEN] The revaluation does not affect average cost.
        ItemLedgerEntry[2].CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry[2].TestField("Cost Amount (Actual)", Cost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialRevaluationEntriesExcludedFromAvgCostCalc()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        OldCost: Decimal;
        NewCost: Decimal;
    begin
        // [FEATURE] [Average Cost] [Calculate Inventory Value]
        // [SCENARIO 368884] A revaluation of remaining quantity of an inbound entry does not affect cost of posted applied outbound entries.
        Initialize();
        OldCost := LibraryRandom.RandDec(100, 2);
        NewCost := 2 * OldCost;

        // [GIVEN] Item with Costing Method = "Average".
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // [GIVEN] Post positive adjustment for 2 pcs, unit cost = 10 LCY.
        // [GIVEN] Post negative adjustment for 1 pc.
        ItemLedgerEntry[1].Get(CreateAndPostItemJnlLine(Item."No.", '', 2, OldCost));
        ItemLedgerEntry[2].Get(CreateAndPostItemJnlLine(Item."No.", '', -1, 0));

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Open revaluation journal and calculate inventory value.
        // [GIVEN] Revalue the remaining 1 pc of the positive entry, set new unit cost = 20 LCY.
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, Item, WorkDate(), "Inventory Value Calc. Per"::Item,
          false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');
        LibraryPatterns.ModifyPostRevaluation(ItemJournalBatch, NewCost / OldCost);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The cost of the revalued entry = 30 LCY (1 pc for 10 LCY + 1 pc for 20 LCY).
        ItemLedgerEntry[1].CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry[1].TestField("Cost Amount (Actual)", 1 * OldCost + 1 * NewCost);

        // [THEN] The cost of the outbound entry = 10 LCY (not changed).
        ItemLedgerEntry[2].CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry[2].TestField("Cost Amount (Actual)", -OldCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevaluationOfItemEntryNotAppliedFromOutbndIncludedToAvgCostCalc()
    var
        Item: Record Item;
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        NewCost: Decimal;
    begin
        // [FEATURE] [Average Cost]
        // [SCENARIO 368884] Value entries for revaluation are included in average cost calculation when the cost of inbound entry is not inherited from outbound entry.
        Initialize();
        NewCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Item with Costing Method = "Average".
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Average, 0);

        // [GIVEN] Post positive adjustment for 1 pc, unit cost = 0.
        // [GIVEN] Post negative adjustment for 1 pc.
        ItemLedgerEntry[1].Get(CreateAndPostItemJnlLine(Item."No.", '', 1, 0));
        ItemLedgerEntry[2].Get(CreateAndPostItemJnlLine(Item."No.", '', -1, 0));

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Revalue the positive adjustment entry, new unit cost = 10 LCY.
        CreateAndPostRevaluationJnlLine(Item."No.", ItemLedgerEntry[1]."Entry No.", NewCost);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The cost of inbound entry = 10 LCY.
        ItemLedgerEntry[1].CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry[1].TestField("Cost Amount (Actual)", NewCost);

        // [THEN] The cost of outbound entry = 10 LCY.
        ItemLedgerEntry[2].CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry[2].TestField("Cost Amount (Actual)", -NewCost);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmYesHandler,MessageHandler')]
    procedure RevalOfOutputWithLaterValuationDate()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        UnitAmount: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Output]
        // [SCENARIO 418069] Calculate Inventory Value in revaluation journal recognizes cost of output with Valuation Date > Posting Date.
        Initialize();
        UnitAmount := LibraryRandom.RandDec(100, 2);
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Component item "C" set up for backward flushing.
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::Backward);
        CompItem.Modify(true);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);

        // [GIVEN] Production item "P".
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Post the component "C" to inventory, unit cost = 50 LCY.
        CreateAndPostItemJnlLine(CompItem."No.", '', LibraryRandom.RandIntInRange(50, 100), UnitAmount);

        // [GIVEN] Production order for 10 pcs of item "P".
        // [GIVEN] Post output on WORKDATE.
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", Qty);
        ProdOrderLine.SetRange("Item No.", ProdItem."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Finish the production order with posting date = WorkDate() + 30 days.
        // [GIVEN] The consumption of component "C" is thereby posted later than output.
        LibraryManufacturing.ChangeProdOrderStatus(
          ProductionOrder, ProductionOrder.Status::Finished, LibraryRandom.RandDate(30), false);

        // [GIVEN] Adjust cost.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', CompItem."No.", ProdItem."No."), '');

        // [WHEN] Calculate Inventory Value for item "P" in revaluation journal on WORKDATE.
        LibraryPatterns.CalculateInventoryValueRun(
          ItemJournalBatch, ProdItem, WorkDate(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false, '', '');

        // [THEN] The batch job recognizes the cost of components.
        // [THEN] A revaluation journal line for item "P" with quantity = 10 and calculated unit cost = 50 LCY is created.
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", ProdItem."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, Qty);
        ItemJournalLine.TestField("Unit Cost (Calculated)", UnitAmount);
    end;

    local procedure TestRevalueExistingInv(CostingMethod: Enum "Costing Method"; StandardCost: Decimal; CalcPer: Enum "Inventory Value Calc. Per"; FilterByLocation: Boolean)
    var
        Item: Record Item;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJnlBatch: Record "Item Journal Batch";
        Location1: Record Location;
        Location2: Record Location;
        LocationFilter: Code[10];
        LocationCode: array[2] of Code[10];
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, StandardCost, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location1);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);
        LocationCode[1] := Location1.Code;
        LocationCode[2] := Location2.Code;
        CreateSetupEntrieswLocInbndandOutbnd(Item, LocationCode, TempItemLedgerEntry, WorkDate());
        TempItemLedgerEntry.FindFirst();
        if FilterByLocation then
            LocationFilter := TempItemLedgerEntry."Location Code";
        ExecuteRevalueExistingInventory(Item, ItemJnlBatch, WorkDate() + 3, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", LocationFilter, '');
        ModifyPostRevaluation(ItemJnlBatch, Item."No.", 1.1);
        LibraryCosting.CheckAdjustment(Item);
    end;

    local procedure TestRevalueExistingInvNegZeroInv(CostingMethod: Enum "Costing Method"; StandardCost: Decimal; CalcPer: Enum "Inventory Value Calc. Per")
    var
        Item: Record Item;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, StandardCost, 0, 0, '');
        CreateSetupEntriesNegInv(Item, TempItemLedgerEntry, WorkDate());
        ExecuteRevalueExistingInventory(Item, ItemJnlBatch, WorkDate() + 2, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        ExecuteRevalueExistingInventory(Item, ItemJnlBatch, WorkDate() + 1, CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        ExecuteRevalueExistingInventory(Item, ItemJnlBatch, WorkDate(), CalcPer, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
    end;

    local procedure TestRevalueExistingInvwLocVar(CostingMethod: Enum "Costing Method"; StandardCost: Decimal; CalcPer: Enum "Inventory Value Calc. Per")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJnlBatch: Record "Item Journal Batch";
        Location1: Record Location;
        Location2: Record Location;
        LocationCode: array[2] of Code[10];
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, StandardCost, 3.33, 11.33, '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location1);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);
        LocationCode[1] := Location1.Code;
        LocationCode[2] := Location2.Code;
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode[1], Item."No.", '');
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode[1], Item."No.", ItemVariant.Code);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode[2], Item."No.", '');
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode[2], Item."No.", ItemVariant.Code);

        CreateSetupEntrieswSKU2Loc2Var(Item, TempItemLedgerEntry, WorkDate(), LocationCode, ItemVariant.Code);

        ExecuteRevalueExistingInventory(
          Item, ItemJnlBatch, WorkDate() + 2, CalcPer, CostingMethod <> Item."Costing Method"::Average,
          CostingMethod <> Item."Costing Method"::Average, false, "Inventory Value Calc. Base"::" ", '', '');
        ModifyPostRevaluation(ItemJnlBatch, Item."No.", 1.1);
        LibraryCosting.CheckAdjustment(Item);

        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate() + 9, '', LocationCode[1], '', '', '', 5);
        LibraryInventory.PostReclassificationJournalLine(Item, WorkDate() + 9, LocationCode[2], LocationCode[1], ItemVariant.Code, '', '', 5);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        ExecuteRevalueExistingInventory(
          Item, ItemJnlBatch, WorkDate() + 9, CalcPer, CostingMethod <> Item."Costing Method"::Average,
          CostingMethod <> Item."Costing Method"::Average, false, "Inventory Value Calc. Base"::" ", '', '');
        ModifyPostRevaluation(ItemJnlBatch, Item."No.", 1.1);
        LibraryCosting.CheckAdjustment(Item);
    end;

    local procedure TestRevalueInboundILEwLoc(CostingMethod: Enum "Costing Method"; StandardCost: Decimal)
    var
        Item: Record Item;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        Location1: Record Location;
        Location2: Record Location;
        LocationCode: array[2] of Code[10];
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, StandardCost, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location1);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);
        LocationCode[1] := Location1.Code;
        LocationCode[2] := Location2.Code;
        CreateSetupEntrieswLocInbndandOutbnd(Item, LocationCode, TempItemLedgerEntry, WorkDate());
        TempItemLedgerEntry.FindFirst();
        LibraryPatterns.ExecutePostRevalueInboundILE(Item, TempItemLedgerEntry, 1.1);
    end;

    local procedure TestRounding(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        ItemJnlBatch: Record "Item Journal Batch";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempRefValueEntry: Record "Value Entry" temporary;
        ValueEntry: Record "Value Entry";
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, 3.33333, 0, 0, '');
        CreateSetupEntriesRounding(Item, TempItemLedgerEntry, WorkDate());
        TempItemLedgerEntry.FindFirst();
        if CostingMethod = Item."Costing Method"::Average then begin
            ExecuteRevalueExistingInventory(Item, ItemJnlBatch, WorkDate(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
            ModifyPostRevaluation(ItemJnlBatch, Item."No.", 1.2);
        end else
            LibraryPatterns.ExecutePostRevalueInboundILE(Item, TempItemLedgerEntry, 1.2);
        LibraryCosting.CheckAdjustment(Item);

        if CostingMethod <> Item."Costing Method"::Average then begin
            ValueEntry.SetRange("Item No.", Item."No.");
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
            ValueEntry.FindSet();

            TempRefValueEntry."Cost Amount (Expected)" := 0;
            TempRefValueEntry."Cost Amount (Actual)" := -0.01;
            TempRefValueEntry."Valued Quantity" := 3;
            TempRefValueEntry."Cost per Unit" := 0;
            TempRefValueEntry."Valuation Date" := TempItemLedgerEntry."Posting Date";
            TempRefValueEntry."Entry Type" := TempRefValueEntry."Entry Type"::Rounding;
            TempRefValueEntry."Variance Type" := TempRefValueEntry."Variance Type"::" ";

            LibraryPatterns.CHECKValueEntry(TempRefValueEntry, ValueEntry);

            ValueEntry.Next();
            TempRefValueEntry."Cost Amount (Actual)" := 0.01;
            LibraryPatterns.CHECKValueEntry(TempRefValueEntry, ValueEntry);
        end;
    end;

    local procedure TestRevaluationCircularTransfer(CostingMethod: Enum "Costing Method"; StandardCost: Decimal)
    var
        Item: Record Item;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJnlBatch: Record "Item Journal Batch";
        Location: Record Location;
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, StandardCost, 0, 0, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateSetupEntriesCircularTransfer(Item, TempItemLedgerEntry, Location.Code, WorkDate());
        ExecuteRevalueExistingInventory(Item, ItemJnlBatch, WorkDate(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        ModifyPostRevaluation(ItemJnlBatch, Item."No.", 1.1);
        LibraryCosting.CheckAdjustment(Item);

        TempItemLedgerEntry.SetRange(Positive, true);
        LibraryCosting.CheckInboundEntriesCost(TempItemLedgerEntry);
    end;

    local procedure TestRevaluationSalesReturn(CostingMethod: Enum "Costing Method"; StandardCost: Decimal)
    var
        Item: Record Item;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItem(Item, CostingMethod, StandardCost, 0, 0, '');
        CreateSetupEntriesSalesReturn(Item, TempItemLedgerEntry, WorkDate());
        ExecuteRevalueExistingInventory(Item, ItemJnlBatch, WorkDate(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", '', '');
        ModifyPostRevaluation(ItemJnlBatch, Item."No.", 1.1);
        LibraryCosting.CheckAdjustment(Item);

        TempItemLedgerEntry.SetRange(Positive, true);
        LibraryCosting.CheckInboundEntriesCost(TempItemLedgerEntry);
    end;

    local procedure CreateSetupEntrieswLocInbndandOutbnd(Item: Record Item; LocationCode: array[2] of Code[10]; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; StartDate: Date)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
        Qty4: Decimal;
        Qty5: Decimal;
        Qty6: Decimal;
        Cost1: Decimal;
        Cost3: Decimal;
        Cost5: Decimal;
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        Qty1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Qty2 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Qty3 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Qty4 := LibraryRandom.RandDecInDecimalRange(10, 50, 2);
        Qty5 := LibraryRandom.RandDecInDecimalRange(10, 100, 2);
        Qty6 := LibraryRandom.RandDecInDecimalRange(10, 50, 2);
        Cost1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Cost3 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Cost5 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, LocationCode[1], '', StartDate, ItemJnlLine."Entry Type"::"Positive Adjmt.", Qty1, Cost1);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, LocationCode[2], '', StartDate, ItemJnlLine."Entry Type"::"Positive Adjmt.", Qty2, Cost1);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, LocationCode[1], '', StartDate + 1, ItemJnlLine."Entry Type"::"Positive Adjmt.", Qty3, Cost3);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, LocationCode[1], '', StartDate + 2, ItemJnlLine."Entry Type"::"Negative Adjmt.", Qty4, 0);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, LocationCode[1], '', StartDate + 3, ItemJnlLine."Entry Type"::"Positive Adjmt.", Qty5, Cost5);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, LocationCode[1], '', StartDate + 5, ItemJnlLine."Entry Type"::"Negative Adjmt.", Qty6, 0);

        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            TempItemLedgerEntry := ItemLedgerEntry;
            TempItemLedgerEntry.Insert();
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CreateSetupEntriesNegInv(Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; StartDate: Date)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
        Cost1: Decimal;
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        Qty1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Qty3 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Qty2 := Qty1 + Qty3;
        Cost1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate, ItemJnlLine."Entry Type"::Purchase, Qty1, Cost1);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 1, ItemJnlLine."Entry Type"::Sale, Qty2, 0);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 2, ItemJnlLine."Entry Type"::Purchase, Qty3, Cost1);

        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            TempItemLedgerEntry := ItemLedgerEntry;
            TempItemLedgerEntry.Insert();
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CreateSetupEntrieswSKU2Loc2Var(Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; StartDate: Date; Location: array[2] of Code[10]; ItemVariant: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Cost1: Decimal;
        Cost2: Decimal;
        Cost3: Decimal;
        Cost4: Decimal;
        Cost5: Decimal;
        Cost6: Decimal;
        QtyNoLocPur1: Decimal;
        QtyNoLocPur2: Decimal;
        QtyNoLocSal1: Decimal;
        QtyNoLocSal2: Decimal;
        QtyLoc1VarPur1: Decimal;
        QtyLoc1VarPur2: Decimal;
        QtyLoc1VarSal1: Decimal;
        QtyLoc1VarSal2: Decimal;
        QtyLoc2VarPur1: Decimal;
        QtyLoc2VarPur2: Decimal;
        QtyLoc2VarSal1: Decimal;
        QtyLoc2VarSal2: Decimal;
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        QtyNoLocSal1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        // Applies to Sal1, with some leftovers
        QtyNoLocPur1 := LibraryRandom.RandDecInDecimalRange(QtyNoLocSal1, 300, 2);
        QtyNoLocPur2 := LibraryRandom.RandDecInDecimalRange(50, 100, 2);
        // Applies to only one of previous purchases
        QtyNoLocSal2 := LibraryRandom.RandDecInDecimalRange(1, Minimum(QtyNoLocPur1 - QtyNoLocSal1, QtyNoLocPur2) - 5, 2);

        QtyLoc1VarSal1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        // Applies to Sal1, with some leftovers
        QtyLoc1VarPur1 := LibraryRandom.RandDecInDecimalRange(QtyLoc1VarSal1, 300, 2);
        QtyLoc1VarPur2 := LibraryRandom.RandDecInDecimalRange(50, 100, 2);
        // Applies to only one of previous purchases
        QtyLoc1VarSal2 := LibraryRandom.RandDecInDecimalRange(1, Minimum(QtyLoc1VarPur1 - QtyLoc1VarSal1, QtyLoc1VarPur2) - 5, 2);

        QtyLoc2VarSal1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        // Applies to Sal1, with some leftovers
        QtyLoc2VarPur1 := LibraryRandom.RandDecInDecimalRange(QtyLoc2VarSal1, 300, 2);
        QtyLoc2VarPur2 := LibraryRandom.RandDecInDecimalRange(50, 100, 2);
        // Applies to only one of previous purchases
        QtyLoc2VarSal2 := LibraryRandom.RandDecInDecimalRange(1, Minimum(QtyLoc2VarPur1 - QtyLoc2VarSal1, QtyLoc2VarPur2) - 5, 2);

        Cost1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Cost2 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Cost3 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Cost4 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Cost5 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Cost6 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 2, ItemJnlLine."Entry Type"::Sale, QtyNoLocSal1, 0);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[1], ItemVariant, StartDate + 2, ItemJnlLine."Entry Type"::Sale, QtyLoc1VarSal1, 0);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[2], ItemVariant, StartDate + 2, ItemJnlLine."Entry Type"::Sale, QtyLoc2VarSal1, 0);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 1, ItemJnlLine."Entry Type"::Purchase, QtyNoLocPur1, Cost1);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[1], ItemVariant, StartDate + 1, ItemJnlLine."Entry Type"::Purchase, QtyLoc1VarPur1, Cost2);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[2], ItemVariant, StartDate + 1, ItemJnlLine."Entry Type"::Purchase, QtyLoc2VarPur1, Cost3);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate, ItemJnlLine."Entry Type"::Purchase, QtyNoLocPur2, Cost4);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[1], ItemVariant, StartDate, ItemJnlLine."Entry Type"::Purchase, QtyLoc1VarPur2, Cost5);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[2], ItemVariant, StartDate, ItemJnlLine."Entry Type"::Purchase, QtyLoc2VarPur2, Cost6);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 7, ItemJnlLine."Entry Type"::Sale, QtyNoLocSal2, 0);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[1], ItemVariant, StartDate + 7, ItemJnlLine."Entry Type"::Sale, QtyLoc1VarSal2, 0);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, Location[2], ItemVariant, StartDate + 7, ItemJnlLine."Entry Type"::Sale, QtyLoc2VarSal2, 0);

        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            TempItemLedgerEntry := ItemLedgerEntry;
            TempItemLedgerEntry.Insert();
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CreateSetupEntriesRounding(Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; StartDate: Date)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        // 3 items are purchased at Unit Cost of 3.33333, and sold individually, to force creation of extra rounding Value Entry for non-average costed items
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate, ItemJnlLine."Entry Type"::Purchase, 3, 3.33333);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 1, ItemJnlLine."Entry Type"::Sale, 1, 0);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 1, ItemJnlLine."Entry Type"::Sale, 1, 0);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 1, ItemJnlLine."Entry Type"::Sale, 1, 0);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            TempItemLedgerEntry := ItemLedgerEntry;
            TempItemLedgerEntry.Insert();
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CreateSetupEntriesCircularTransfer(Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; LocationCode: Code[10]; StartDate: Date)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlBatchTransfer: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        Cost1: Decimal;
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        Qty1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Qty2 := LibraryRandom.RandDecInDecimalRange(10, Qty1, 2);

        Cost1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate, ItemJnlLine."Entry Type"::"Positive Adjmt.", Qty1, Cost1);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        ItemLedgerEntry.SetCurrentKey("Item No.", "Entry No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatchTransfer, ItemJnlBatch."Template Type"::Transfer);

        LibraryInventory.CreateItemReclassificationJournalLine(ItemJnlLine, ItemJnlBatchTransfer, Item, '', '', LocationCode,
          '', '', StartDate + 2, Qty2);
        ItemJnlLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJnlLine.Modify();

        LibraryInventory.PostItemJournalBatch(ItemJnlBatchTransfer);

        LibraryInventory.PostReclassificationJournalLine(Item, StartDate + 3, LocationCode, '', '', '', '', Qty2);

        ItemLedgerEntry.FindSet();

        repeat
            TempItemLedgerEntry := ItemLedgerEntry;
            TempItemLedgerEntry.Insert();
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CreateSetupEntriesSalesReturn(Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; StartDate: Date)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlBatchSalesReturn: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        Cost1: Decimal;
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Item);

        Qty1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        Qty2 := LibraryRandom.RandDecInDecimalRange(10, Qty1, 2);

        Cost1 := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate, ItemJnlLine."Entry Type"::Purchase, Qty1, Cost1);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, '', '', StartDate + 2, ItemJnlLine."Entry Type"::Sale, Qty2, 0);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
        ItemLedgerEntry.SetCurrentKey("Item No.", "Entry No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            TempItemLedgerEntry := ItemLedgerEntry;
            TempItemLedgerEntry.Insert();
        until ItemLedgerEntry.Next() = 0;

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatchSalesReturn, ItemJnlBatchSalesReturn."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlBatchSalesReturn, Item, '', '', StartDate + 3, ItemJnlLine."Entry Type"::Sale, -Qty2, 0);
        ItemJnlLine.Validate("Applies-from Entry", ItemLedgerEntry."Entry No.");
        ItemJnlLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJnlBatchSalesReturn);

        ItemLedgerEntry.FindLast();
        TempItemLedgerEntry := ItemLedgerEntry;
        TempItemLedgerEntry.Insert();
    end;

    local procedure CreateAndPostItemJnlLine(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; UnitAmount: Decimal): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type", ItemNo, LocationCode);
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure CreateAndPostReclassJnlLine(ItemNo: Code[20]; LocationCode: Code[10]; NewLocationCode: Code[10]; Qty: Decimal): Integer
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("New Location Code", NewLocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Transfer, ItemNo, NewLocationCode);
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure CreateAndPostRevaluationJnlLine(ItemNo: Code[20]; AppliesToEntryNo: Integer; UnitCostRevalued: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetUpNewLine(ItemJournalLine);
        ItemJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntryNo);
        ItemJournalLine.Validate("Unit Cost (Revalued)", UnitCostRevalued);
        ItemJournalLine.Insert(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure ExecuteRevalueExistingInventory(var Item: Record Item; var ItemJnlBatch: Record "Item Journal Batch"; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; UpdStdCost: Boolean; CalcBase: Enum "Inventory Value Calc. Base"; LocationFilter: Code[20]; VariantFilter: Code[20])
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryCosting.CheckAdjustment(Item);

        LibraryPatterns.CalculateInventoryValueRun(
          ItemJnlBatch, Item, PostingDate, CalculatePer, ByLocation, ByVariant, UpdStdCost, CalcBase, false, LocationFilter, VariantFilter);

        LibraryPatterns.CHECKCalcInvPost(Item, ItemJnlBatch, PostingDate, CalculatePer, ByLocation, ByVariant, LocationFilter, VariantFilter);
    end;

    local procedure ModifyPostRevaluation(ItemJnlBatch: Record "Item Journal Batch"; ItemNoFilter: Code[20]; Factor: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        if ItemJnlLine.FindSet() then
            repeat
                ItemJnlLine.Validate(
                  "Inventory Value (Revalued)", Round(ItemJnlLine."Inventory Value (Revalued)" * Factor, LibraryERM.GetAmountRoundingPrecision()));
                ItemJnlLine.Modify();
            until (ItemJnlLine.Next() = 0);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
        LibraryCosting.AdjustCostItemEntries(ItemNoFilter, '');
    end;

    local procedure FindFirstItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ItemJnlBatch: Record "Item Journal Batch")
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        ItemJnlLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindLast();
    end;

    local procedure PostPositiveAdjmtOnNewLocation(var TotalQty: Decimal; var TotalAmount: Decimal; Item: Record Item)
    var
        Location: Record Location;
        Qty: Decimal;
        UnitAmount: Decimal;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Qty := LibraryRandom.RandInt(100);
        UnitAmount := LibraryRandom.RandDec(100, 2);
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', Qty, WorkDate(), UnitAmount);
        TotalQty += Qty;
        TotalAmount += Qty * UnitAmount;
    end;

    local procedure Minimum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 < Value2 then
            exit(Value1);

        exit(Value2);
    end;

    local procedure VerifyAmountsOnItemJnlLine(ItemJnlBatch: Record "Item Journal Batch"; ExpectedQty: Decimal; ExpectedInvValue: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        FindFirstItemJnlLine(ItemJnlLine, ItemJnlBatch);
        ItemJnlLine.TestField(Quantity, ExpectedQty);
        ItemJnlLine.TestField("Inventory Value (Calculated)", ExpectedInvValue);
    end;

    [ModalPageHandler]
    procedure ProductionJournalModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

