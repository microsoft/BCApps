codeunit 137085 "Cost Adjustment Features"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Adjustment] [SCM] 
        Initialized := false;
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        Initialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Cost Adjustment Features");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Cost Adjustment Features");

        SetManualCostAdjustmentParameters();

        LibrarySetupStorage.SaveInventorySetup();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Cost Adjustment Features");
    end;

    // TEST CASES:

    // 1. Adjusting cost until valuation date:
    // 1.1. FIFO item - the date is ignored, all periods are adjusted
    // 1.2. Average cost item - select last period, all periods are adjusted
    // 1.3. Average cost item - select first period, check cost and item setup
    // 1.4. Average cost item - adjust cost in two iterations
    // 1.5. Average cost item - select already adjusted period, check that nothing is adjusted
    // 1.6. Average cost item - multiple locations

    // 2. Adjusting cost for selected orders:
    // 2.2. Any costing method - same for assembly order

    // 3. Forced adjustment:
    // 3.1. Force adjustment on the Item Ledger Entries page for FIFO item - positive entry, reopens item and entry
    // 3.2. Force adjustment on the Item Ledger Entries page for FIFO item - negative entry, error
    // 3.3. Force adjustment on the Item Ledger Entries page for average cost item, entries not direct-applied - only reopens item
    // 3.4. Force adjustment on the Item Ledger Entries page for average cost item, entries direct-applied - reopens item and entry
    // 3.5. Outbound Entry is Updated on the Item Application Entries page - all applied outbound entries are updated
    // 3.6. Set/Reset Cost Application on the Item Application Entries page

    // 4. Item-by-item committing:
    // 4.1. Adjust two items - second fails, check that first is adjusted and second is not
    // 4.2. Adjust two items - first fails, check that both are not adjusted
    // 4.3. Adjust two items - first unfinished, check that it's not committed

    // 5. Cost adjustment with parameters:
    // 5.1. Manual adjustment with the report
    // 5.3. Triggered adjustment - find code that invokes it
    // 5.4. Automatic adjustment

    // 6. Cost adjustment tracer:
    // 6.1. Trace one item - check that log is saved
    // 6.2. Trace two items - check that log is saved
    // 6.4. Trace item with error - check that log is saved
    // 6.5. Trace item with timeout - check that log is saved
    // 6.6. Trace two items, second with error - check that log is saved for both
    // 6.7. Trace two times, check that log only contains the last tracing
    // 6.8. Batch run with tracing is not auto-rescheduled

    // 7. Action messages (check already existing tests):
    // 7.1. Tests for cost adjustment not running
    // 7.2. Tests for cost adjustment running long for item
    // 7.3. Tests for recommended values
    // 7.4. Tests for unused inventory periods
    // 7.5. Tests for many periods to adjust
    // 7.7. Tests for excluded items
    // 7.8. Check that no check is performed before it reaches the next check date/time
    // 7.9. Snooze action message - call several times, check next date.
    // 7.10. Check run all tests
    // 7.11. Data discrepancy

    // 9. Minor changes:
    // 9.1. Cost adjustment for deleted item
    // 9.2. Check that items are adjusted from highest to lowest low-level code.
    // 9.3. Add test for adjusting revaluation to ensure there is no infinite loop in the code.

    [Test]
    procedure T11_AdjustTillDate_FIFO()
    var
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Three consecutive posting dates - "Date 1", "Date 2", "Date 3".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));
        Dates.Add(CalcDate('<2M>', WorkDate()));

        // [GIVEN] FIFO cost item with three posted entries: +10 on "Date 1", -5 on "Date 2", -5 on "Date 3".
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(2));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(3));

        // [WHEN] Adjust cost until "Date 2".
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(2));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] Check that all periods are adjusted and the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted");
        VerifyItemCostAmountZero(Item."No.");

        AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        Assert.RecordIsEmpty(AvgCostAdjmtEntryPoint);
    end;

    [Test]
    procedure T12_AdjustTillDate_Avg_LastPeriod()
    var
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Three consecutive posting dates - "Date 1", "Date 2", "Date 3".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));
        Dates.Add(CalcDate('<2M>', WorkDate()));

        // [GIVEN] Average cost item with three posted entries: +10 on "Date 1", -5 on "Date 2", -5 on "Date 3".
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(2));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(3));

        // [WHEN] Adjust cost until "Date 3".
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(3));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] Check that all periods are adjusted and the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted");
        VerifyItemCostAmountZero(Item."No.");

        AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        Assert.RecordIsEmpty(AvgCostAdjmtEntryPoint);
    end;

    [Test]
    procedure T13_AdjustTillDate_Avg_FirstPeriod()
    var
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Three consecutive posting dates - "Date 1", "Date 2", "Date 3".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));
        Dates.Add(CalcDate('<2M>', WorkDate()));

        // [GIVEN] Average cost item with three posted entries: +10 on "Date 1", -5 on "Date 2", -5 on "Date 3".
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(2));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(3));

        // [WHEN] Adjust cost until "Date 2".
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(2));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] Check that the item remains not adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", false);

        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(1));
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(2));
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(3));
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);

        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", Dates.Get(3));
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
    end;

    [Test]
    procedure T14_AdjustTillDate_Avg_TwoIterations()
    var
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Three consecutive posting dates - "Date 1", "Date 2", "Date 3".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));
        Dates.Add(CalcDate('<2M>', WorkDate()));

        // [GIVEN] Average cost item with four posted entries: +10 on "Date 1", -5 on "Date 2", +10 and -5 on "Date 3".
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(2));
        PostItemJournalLine(Item."No.", 10, 20, Dates.Get(3));
        PostItemJournalLine(Item."No.", -5, 0, Dates.Get(3));

        // [GIVEN] Adjust cost until "Date 2".
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(2));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [GIVEN] Check that the unit cost of the item is 25.
        // [GIVEN] Remaining inventory is 10, sum of cost amount is 250.
        Item.Find();
        Item.TestField("Unit Cost", 25);
        Item.TestField("Cost is Adjusted", false);

        // [WHEN] Adjust cost until "Date 3".
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(3));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] Check that the unit cost of the item is 16.667.
        Item.Find();
        Assert.AreNearlyEqual(16.667, Item."Unit Cost", 0.001, '');
        Item.TestField("Cost is Adjusted");
    end;

    [Test]
    procedure T15_AdjustTillDate_Avg_AlreadyAdjusted()
    var
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Two consecutive posting dates - "Date 1", "Date 2".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));

        // [GIVEN] Average cost item.
        CreateItem(Item, Item."Costing Method"::Average);

        // [GIVEN] Post +10 on "Date 1". Unit Cost = 10.
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));

        // [GIVEN] Adjust cost until "Date 1".
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(1));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [GIVEN] Unit cost of the item is 10.
        Item.Find();
        Item.TestField("Unit Cost", 10);

        // [GIVEN] Post +10 on "Date 2". Unit Cost = 20.
        PostItemJournalLine(Item."No.", 10, 20, Dates.Get(2));

        // [WHEN] Adjust cost until "Date 1" again.
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', Dates.Get(1));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] Check that the unit cost of the item is updated to 15, but the item remains not adjusted.
        Item.Find();
        Item.TestField("Unit Cost", 15);
        Item.TestField("Cost is Adjusted", false);
    end;

    [Test]
    procedure T16_AdjustTillDate_Avg_MultipleLocations()
    var
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        Location1, Location2 : Record Location;
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Two consecutive posting dates - "Date 1", "Date 2".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));

        // [GIVEN] Two locations - "Location 1", "Location 2".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location1);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);

        // [GIVEN] Average cost item with two entries posted at each location: +10 on "Date 1", -10 on "Date 2".
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", Location1.Code, 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", Location2.Code, 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", Location1.Code, -10, 0, Dates.Get(2));
        PostItemJournalLine(Item."No.", Location2.Code, -10, 0, Dates.Get(2));

        // [WHEN] Locate the "Avg. Cost Adjmt. Entry Point" for "Location 1" and "Date 1" and run the cost adjustment until that date.
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', Location1.Code, Dates.Get(1));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] Check that the item remains not adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", false);

        // [THEN] Check that entry points for both "Location 1" and "Location 2" are adjusted until "Date 1".
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', Location1.Code, Dates.Get(1));
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', Location2.Code, Dates.Get(1));
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', Location1.Code, Dates.Get(2));
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', Location2.Code, Dates.Get(2));
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);

        // [THEN] Finish the adjustment of the item.
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', Location2.Code, Dates.Get(2));
        AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] The item is fully adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted");
        VerifyItemCostAmountZero(Item."No.");
    end;

    [Test]
    procedure T31_ForcedReadjustmentOfFIFOItem()
    var
        Item: Record Item;
        ItemLedgerEntry1, ItemLedgerEntry2, FilteredItemLedgerEntry : Record "Item Ledger Entry";
        ItemLedgerEntryEdit: Codeunit "Item Ledger Entry-Edit";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Four consecutive posting dates - "Date 1", "Date 2", "Date 3", "Date 4".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));
        Dates.Add(CalcDate('<2M>', WorkDate()));
        Dates.Add(CalcDate('<3M>', WorkDate()));

        // [GIVEN] FIFO cost item with four posted entries: +10 on "Date 1", +10 on "Date 2", -10 on "Date 3", -10 on "Date 4".
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", 10, 20, Dates.Get(2));
        PostItemJournalLine(Item."No.", -10, 0, Dates.Get(3));
        PostItemJournalLine(Item."No.", -10, 0, Dates.Get(4));

        // [GIVEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [GIVEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        // [GIVEN] Check that the positive item ledger entries aren't marked as "Applied Entry to Adjust".
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", false);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        // [WHEN] Force re-adjustment of the two positive item ledger entries.
        FilteredItemLedgerEntry.SetFilter("Entry No.", '%1|%2', ItemLedgerEntry1."Entry No.", ItemLedgerEntry2."Entry No.");
        ItemLedgerEntryEdit.SetAppliedEntriesToAdjust(FilteredItemLedgerEntry);

        // [THEN] Check that the positive item ledger entries are marked as "Applied Entry to Adjust".
        // [THEN] Check that the item is not adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", false);
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", true);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", true);
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(3));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", false);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(4));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        // [THEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [THEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted");

        VerifyItemCostAmountZero(Item."No.");
    end;

    [Test]
    procedure T32_ForcedReadjustmentOfFIFOItem_Failing()
    var
        Item: Record Item;
        ItemLedgerEntry1, ItemLedgerEntry2, FilteredItemLedgerEntry : Record "Item Ledger Entry";
        ItemLedgerEntryEdit: Codeunit "Item Ledger Entry-Edit";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Two consecutive posting dates - "Date 1", "Date 2".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));

        // [GIVEN] FIFO cost item with two posted entries: +10 on "Date 1", -10 on "Date 2".
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", -10, 0, Dates.Get(2));

        // [GIVEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [GIVEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        // [GIVEN] Check that none of the item ledger entries are marked as "Applied Entry to Adjust".
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", false);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        Commit();

        // [WHEN] Try to force re-adjustment of both the positive and negative item ledger entries.
        FilteredItemLedgerEntry.SetFilter("Entry No.", '%1|%2', ItemLedgerEntry1."Entry No.", ItemLedgerEntry2."Entry No.");
        asserterror ItemLedgerEntryEdit.SetAppliedEntriesToAdjust(FilteredItemLedgerEntry);

        // [THEN] The re-adjustment fails because you cannot select a negative entry.

        // [THEN] Check that the item remains adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Check that none of the item ledger entries are marked as "Applied Entry to Adjust".
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", false);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        // [THEN] The cost amounts should be zero (balanced)
        VerifyItemCostAmountZero(Item."No.");
    end;

    [Test]
    procedure T33_ForcedReadjustmentOfAverageItem_OnlyReopensItem()
    var
        Item: Record Item;
        ItemLedgerEntry1, ItemLedgerEntry2, FilteredItemLedgerEntry : Record "Item Ledger Entry";
        ItemLedgerEntryEdit: Codeunit "Item Ledger Entry-Edit";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Two consecutive posting dates - "Date 1", "Date 2".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));

        // [GIVEN] FIFO cost item with two posted entries: +10 on "Date 1", -10 on "Date 2". There is no direct application between the entries.
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        PostItemJournalLine(Item."No.", -10, 0, Dates.Get(2));

        // [GIVEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [GIVEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        // [GIVEN] Check that the positive item ledger entries aren't marked as "Applied Entry to Adjust".
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", false);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        // [WHEN] Mark the positive item ledger entry as "Applied Entry to Adjust".
        FilteredItemLedgerEntry.SetRange("Entry No.", ItemLedgerEntry1."Entry No.");
        ItemLedgerEntryEdit.SetAppliedEntriesToAdjust(FilteredItemLedgerEntry);

        // [THEN] Check that the entries are not marked.
        // [THEN] Check that the item is not adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", false);
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", false);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        // [THEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [THEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted");

        VerifyItemCostAmountZero(Item."No.");
    end;

    [Test]
    procedure T34_ForcedReadjustmentOfAverageItem_NegativeEntry()
    var
        Item: Record Item;
        ItemLedgerEntry1, ItemLedgerEntry2, FilteredItemLedgerEntry : Record "Item Ledger Entry";
        ItemLedgerEntryEdit: Codeunit "Item Ledger Entry-Edit";
        Dates: List of [Date];
    begin
        Initialize();

        // [GIVEN] Two consecutive posting dates - "Date 1", "Date 2".
        Dates.Add(WorkDate());
        Dates.Add(CalcDate('<1M>', WorkDate()));

        // [GIVEN] FIFO cost item with two posted entries: +10 on "Date 1", -10 on "Date 2". The negative entry is applied to the positive entry.
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 10, Dates.Get(1));
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        PostItemJournalLine(Item."No.", '', -10, 0, Dates.Get(2), ItemLedgerEntry1."Entry No.");

        // [GIVEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [GIVEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        // [GIVEN] Check that the positive item ledger entries aren't marked as "Applied Entry to Adjust".
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", false);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        // [WHEN] Mark the negative item ledger entry as "Applied Entry to Adjust".
        FilteredItemLedgerEntry.SetRange("Entry No.", ItemLedgerEntry2."Entry No.");
        ItemLedgerEntryEdit.SetAppliedEntriesToAdjust(FilteredItemLedgerEntry);

        // [THEN] Check that the applied positive item ledger entry is marked as "Applied Entry to Adjust".
        // [THEN] Check that the item is not adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", false);
        FindItemLedgerEntry(ItemLedgerEntry1, Item."No.", Dates.Get(1));
        ItemLedgerEntry1.TestField("Applied Entry to Adjust", true);
        FindItemLedgerEntry(ItemLedgerEntry2, Item."No.", Dates.Get(2));
        ItemLedgerEntry2.TestField("Applied Entry to Adjust", false);

        // [THEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [THEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted");

        VerifyItemCostAmountZero(Item."No.");
    end;

    [Test]
    procedure T35_ResetOutboundEntryIsUpdated()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry, FilteredItemApplicationEntry : Record "Item Application Entry";
    begin
        Initialize();

        // [GIVEN] FIFO cost item.
        CreateItem(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Post three entries: +10, -1, -1.
        PostItemJournalLine(Item."No.", 10, 10, WorkDate());
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate());
        PostItemJournalLine(Item."No.", -1, 0, WorkDate());
        PostItemJournalLine(Item."No.", -1, 0, WorkDate());

        // [GIVEN] Run the cost adjustment for the item.
        RunCostAdjustment(Item."No.");

        // [GIVEN] Check that the item is adjusted.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        // [GIVEN] Check that the two negative item ledger entries is marked as "Outbound Entry is Updated".
        FilteredItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
        FilteredItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>0');
        FilteredItemApplicationEntry.SetRange("Outbound Entry is Updated", true);
        Assert.RecordCount(FilteredItemApplicationEntry, 2);

        // [WHEN] Reset the "Outbound Entry is Updated", passing the positive item ledger entry as a parameter.
        ItemApplicationEntry.SetOutboundsNotUpdated(ItemLedgerEntry);

        // [THEN] Check that the two negative item ledger entries are not marked as "Outbound Entry is Updated".
        Assert.RecordCount(FilteredItemApplicationEntry, 0);
    end;

    [Test]
    procedure T36_SetResetCostApplicationForItemApplicationEntry()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        Initialize();

        // [GIVEN] Average cost item.
        CreateItem(Item, Item."Costing Method"::Average);

        // [GIVEN] Post two entries: +10, -10.
        // [GIVEN] The negative entry is applied to the positive entry.
        PostItemJournalLine(Item."No.", 10, 10, WorkDate());
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate());
        PostItemJournalLine(Item."No.", '', -10, 0, WorkDate(), ItemLedgerEntry."Entry No.");

        // [GIVEN] Find the item application entries. Check that the Cost Application is true.
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
        ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>0');
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField("Cost Application", true);

        // [WHEN] Reset the Cost Application.
        // [THEN] Check that the Cost Application is false.
        ItemApplicationEntry.SetCostApplication(false);
        ItemApplicationEntry.TestField("Cost Application", false);

        // [THEN] Set the Cost Application back to true.
        // [THEN] Check that the Cost Application is true.
        ItemApplicationEntry.SetCostApplication(true);
        ItemApplicationEntry.TestField("Cost Application", true);
    end;

    [Test]
    procedure T41_PerItemCommit_AdjustTwoItems_SecondFails()
    var
        Item1, Item2, FilteredItem : Record Item;
    begin
        Initialize();

        CreateItem(Item1, Item1."Costing Method"::Average);
        CreateItem(Item2, Item2."Costing Method"::FIFO);

        PostItemJournalLine(Item1."No.", 10, 10, WorkDate());
        PostItemJournalLine(Item1."No.", -10, 0, WorkDate());
        PostItemJournalLine(Item2."No.", 10, 10, WorkDate());
        PostItemJournalLine(Item2."No.", -10, 0, WorkDate());

        LibraryVariableStorage.Enqueue('T41_PerItemCommit_AdjustTwoItems_SecondFails');
        LibraryVariableStorage.Enqueue(Item2."No.");

        Commit();

        BindSubscription(this);
        FilteredItem.SetFilter("No.", '%1|%2', Item1."No.", Item2."No.");
        asserterror RunCostAdjustment(FilteredItem, true);
        UnbindSubscription(this);

        Item1.Find();
        Item1.TestField("Cost is Adjusted", true);
        VerifyItemCostAmountZero(Item1."No.");

        Item2.Find();
        Item2.TestField("Cost is Adjusted", false);
        asserterror VerifyItemCostAmountZero(Item2."No.");
    end;

    [Test]
    procedure T42_PerItemCommit_AdjustTwoItems_FirstFails()
    var
        Item1, Item2, FilteredItem : Record Item;
    begin
        Initialize();

        CreateItem(Item1, Item1."Costing Method"::Average);
        CreateItem(Item2, Item2."Costing Method"::FIFO);

        PostItemJournalLine(Item1."No.", 10, 10, WorkDate());
        PostItemJournalLine(Item1."No.", -10, 0, WorkDate());
        PostItemJournalLine(Item2."No.", 10, 10, WorkDate());
        PostItemJournalLine(Item2."No.", -10, 0, WorkDate());

        LibraryVariableStorage.Enqueue('T42_PerItemCommit_AdjustTwoItems_FirstFails');
        LibraryVariableStorage.Enqueue(Item1."No.");

        Commit();

        BindSubscription(this);
        FilteredItem.SetFilter("No.", '%1|%2', Item1."No.", Item2."No.");
        asserterror RunCostAdjustment(FilteredItem, true);
        UnbindSubscription(this);

        Item1.Find();
        Item1.TestField("Cost is Adjusted", false);
        asserterror VerifyItemCostAmountZero(Item1."No.");

        Item2.Find();
        Item2.TestField("Cost is Adjusted", false);
        asserterror VerifyItemCostAmountZero(Item2."No.");
    end;

    [Test]
    procedure T43_PerItemCommit_AdjustTwoItems_FirstUnfinished()
    var
        Item1, Item2, FilteredItem : Record Item;
    begin
        Initialize();

        CreateItem(Item1, Item1."Costing Method"::FIFO);
        CreateItem(Item2, Item2."Costing Method"::FIFO);

        PostItemJournalLine(Item1."No.", 10, 10, WorkDate());
        PostItemJournalLine(Item1."No.", -10, 0, WorkDate());
        PostItemJournalLine(Item2."No.", 10, 10, WorkDate());
        PostItemJournalLine(Item2."No.", -10, 0, WorkDate());

        LibraryVariableStorage.Enqueue('T43_PerItemCommit_AdjustTwoItems_FirstUnfinished');
        LibraryVariableStorage.Enqueue(Item1."No.");
        LibraryVariableStorage.Enqueue(Item2."No.");

        Commit();

        BindSubscription(this);
        FilteredItem.SetFilter("No.", '%1|%2', Item1."No.", Item2."No.");
        asserterror RunCostAdjustment(FilteredItem, true);
        UnbindSubscription(this);

        Item1.Find();
        Item1.TestField("Cost is Adjusted", false);
        asserterror VerifyItemCostAmountZero(Item1."No.");

        Item2.Find();
        Item2.TestField("Cost is Adjusted", false);
        asserterror VerifyItemCostAmountZero(Item2."No.");
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", 10);
        Item.Validate("Last Direct Cost", 10);
        Item.Modify(true);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; PostingDate: Date)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Posting Date", PostingDate);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date)
    begin
        PostItemJournalLine(ItemNo, '', Quantity, UnitAmount, PostingDate, 0);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date)
    begin
        PostItemJournalLine(ItemNo, LocationCode, Quantity, UnitAmount, PostingDate, 0);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date; AppliesToEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine."Applies-to Entry" := AppliesToEntryNo;
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RunCostAdjustment(ItemNo: Code[20])
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
    end;

    local procedure RunCostAdjustment(var Item: Record Item; PerItemCommit: Boolean)
    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CostAdjustmentItemRunner: Codeunit "Cost Adjustment Item Runner";
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
    begin
        CostAdjustmentParameter."Item-By-Item Commit" := PerItemCommit;
        CostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
        CostAdjustmentItemRunner.SetParameters(CostAdjustmentParamsMgt);
        CostAdjustmentItemRunner.Run(Item);
    end;

    local procedure SetManualCostAdjustmentParameters()
    begin
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAutomaticCostPosting(false);
        LibraryInventory.SetAverageCostSetup(
          "Average Cost Calculation Type"::"Item & Location & Variant", "Average Cost Period Type"::Day);
    end;

    local procedure VerifyItemCostAmountZero(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        ValueEntry.TestField("Cost Amount (Actual)", 0);
        ValueEntry.TestField("Cost Amount (Expected)", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnUpdateItemUnitCostOnAfterItemGet, '', false, false)]
    local procedure RaiseError(var Item: Record Item)
    var
        TestFunctionName: Text;
    begin
        TestFunctionName := LibraryVariableStorage.PeekText(1);
        if TestFunctionName in ['T41_PerItemCommit_AdjustTwoItems_SecondFails',
                                'T42_PerItemCommit_AdjustTwoItems_FirstFails']
        then
            if Item."No." = LibraryVariableStorage.PeekText(2) then
                Assert.Fail(Item."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnBeforeUpdateItemUnitCost2, '', false, false)]
    local procedure AddRoundOfAdjustment(var Item: Record Item; var ItemLedgEntryToAdjust: Dictionary of [Code[20], List of [Integer]])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntryList: List of [Integer];
        TestFunctionName: Text;
    begin
        TestFunctionName := LibraryVariableStorage.PeekText(1);
        if TestFunctionName = 'T43_PerItemCommit_AdjustTwoItems_FirstUnfinished' then begin
            if Item."No." = LibraryVariableStorage.PeekText(2) then begin
                ItemLedgerEntry.SetRange("Item No.", Item."No.");
                ItemLedgerEntry.SetRange(Positive, true);
                ItemLedgerEntry.FindFirst();
                ItemLedgerEntryList.Add(ItemLedgerEntry."Entry No.");
                ItemLedgEntryToAdjust.Add(Item."No.", ItemLedgerEntryList);
            end;
            if Item."No." = LibraryVariableStorage.PeekText(3) then
                Assert.Fail(Item."No.");
        end;
    end;
}