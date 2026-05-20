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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
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
    // 1.1. FIFO item - error
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

    // 10. Earliest Allowed Valuation Date:
    // 10.1. Blank field - posting allowed
    // 10.2. Posting date before cutoff - error
    // 10.3. Posting date on cutoff - allowed
    // 10.4. Adjustment entry before cutoff - allowed (exempt)
    // 10.5. Cost adjustment signaling suppressed for exempt entry before cutoff (no pre-cutoff Avg Cost Adjmt records reopened)
    // 10.6. OnValidate blocks when cost is not adjusted
    // 10.7. OnValidate blocks when an open production/assembly order has output before the cutoff
    // 10.8. OnValidate succeeds when cost is fully adjusted and no open orders block
    // 10.9. Applies-to Entry pointing to a pre-cutoff ILE is blocked at Checkpoint 1
    // 10.11. "Mark for Adjustment" skips pre-cutoff ILEs
    // 10.12. "Mark for Adjustment" still flags post-cutoff ILEs
    // 10.13. Reopening a Finished production order with pre-cutoff value entries is blocked
    // 10.14. UpdateValuationDate with a pre-cutoff Value Entry keeps pre-cutoff entry points adjusted but cascades forward
    // 10.15. Undo of a purchase receipt posted before the cutoff is blocked
    // 10.16. Invoicing a pre-cutoff receipt at a post-cutoff Posting Date posts; the invoice's Valuation Date is redirected to the Posting Date
    // 10.17. Average-cost: invoice amount update post-cutoff preserves pre-cutoff cost, updates post-cutoff negative adjustments
    // 10.18. FIFO: posting a new negative adjustment after cutoff flags the pre-cutoff positive entry for readjustment
    // 10.19. UpdateNextValuations cascade floor: only post-cutoff Avg Cost Adjmt Entry Point records are reopened across multiple periods
    // 10.20. Item charge assigned to a pre-cutoff receipt is blocked at Checkpoint 2 (req 3)
    // 10.21. Revaluation journal line with Applies-to Entry pointing to a pre-cutoff ILE is blocked (req 3)
    // 10.22. Rounding value entry emitted by cost adjustment with pre-cutoff Valuation Date is exempt and posts (req 5)
    // 10.23. FIFO: pre-cutoff sale with negative remaining quantity is adjusted from a post-cutoff purchase
    // 10.24. Average: pre-cutoff sale with negative remaining quantity is adjusted from a post-cutoff purchase; pre-cutoff Avg Cost Adjmt Entry Point stays adjusted

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
        asserterror AvgCostAdjmtEntryPoint.RunCostAdjustmentUntilValuationDate();

        // [THEN] Error is thrown because the costing method of the item is FIFO, and only Average cost items can be adjusted until valuation date.
        Assert.ExpectedError('Costing Method must be equal to ''Average''');
        Assert.ExpectedErrorCode('TestField');
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

    [Test]
    procedure T101_EarliestAllowedValDate_Blank_PostingAllowed()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        // [SCENARIO] When "Earliest Allowed Val. Date" is blank, posting with any date is allowed.
        Initialize();

        // [GIVEN] "Earliest Allowed Val. Date" is blank in Inventory Setup.
        InventorySetup.Get();
        InventorySetup."Earliest Allowed Val. Date" := 0D;
        InventorySetup.Modify();

        // [GIVEN] An item with FIFO costing.
        CreateItem(Item, Item."Costing Method"::FIFO);

        // [WHEN] Post an item journal line with a past posting date.
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 365);

        // [THEN] Posting succeeds - no error.
    end;

    [Test]
    procedure T102_EarliestAllowedValDate_PostingDateBeforeCutoff_Error()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        // [SCENARIO] Posting with a date before "Earliest Allowed Val. Date" raises an error.
        Initialize();

        // [GIVEN] "Earliest Allowed Val. Date" is set.
        InventorySetup.Get();
        InventorySetup."Earliest Allowed Val. Date" := WorkDate();
        InventorySetup.Modify();

        // [GIVEN] An item with FIFO costing.
        CreateItem(Item, Item."Costing Method"::FIFO);

        // [WHEN] Post an item journal line with a date before the cutoff.
        asserterror PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 1);

        // [THEN] Posting fails with the expected error.
        Assert.ExpectedError('before the Earliest Allowed Valuation Date');
    end;

    [Test]
    procedure T103_EarliestAllowedValDate_PostingDateOnCutoff_Allowed()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        // [SCENARIO] Posting with a date equal to "Earliest Allowed Val. Date" is allowed.
        Initialize();

        // [GIVEN] "Earliest Allowed Val. Date" is set.
        InventorySetup.Get();
        InventorySetup."Earliest Allowed Val. Date" := WorkDate();
        InventorySetup.Modify();

        // [GIVEN] An item with FIFO costing.
        CreateItem(Item, Item."Costing Method"::FIFO);

        // [WHEN] Post an item journal line with the cutoff date.
        PostItemJournalLine(Item."No.", 10, 100, WorkDate());

        // [THEN] Posting succeeds - no error.
    end;

    [Test]
    procedure T104_EarliestAllowedValDate_AdjustmentEntry_Exempt()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        // [SCENARIO] Cost adjustment entries with valuation date before cutoff are allowed.
        Initialize();

        // [GIVEN] An item with Average costing.
        CreateItem(Item, Item."Costing Method"::Average);

        // [GIVEN] Post a purchase and a sale before the cutoff.
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 30);
        PostItemJournalLine(Item."No.", -5, 0, WorkDate() - 25);

        // [GIVEN] Set the cutoff date after the purchase date.
        InventorySetup.Get();
        InventorySetup."Earliest Allowed Val. Date" := WorkDate() - 10;
        InventorySetup.Modify();

        // [WHEN] Run cost adjustment - creates adjustment entries with old valuation dates.
        RunCostAdjustment(Item."No.");

        // [THEN] Cost adjustment succeeds - adjustment entries are exempt.
    end;

    [Test]
    procedure T105_EarliestAllowedValDate_SignalingSuppressed()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        // [SCENARIO] After cost adjustment completes, posting a new entry does not flag
        // old periods (before cutoff) for readjustment.
        Initialize();

        // [GIVEN] An item with Average costing.
        CreateItem(Item, Item."Costing Method"::Average);

        // [GIVEN] Post a purchase and run cost adjustment so all periods are adjusted.
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 60);
        RunCostAdjustment(Item."No.");

        // [GIVEN] Set the cutoff date.
        InventorySetup.Get();
        InventorySetup."Earliest Allowed Val. Date" := WorkDate() - 30;
        InventorySetup.Modify();

        // [GIVEN] Verify all entry points are adjusted.
        AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        Assert.RecordIsEmpty(AvgCostAdjmtEntryPoint);

        // [WHEN] Post a new purchase after the cutoff date.
        PostItemJournalLine(Item."No.", 5, 150, WorkDate());

        // [THEN] No entry points before cutoff are flagged for readjustment.
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        AvgCostAdjmtEntryPoint.SetFilter("Valuation Date", '<%1', InventorySetup."Earliest Allowed Val. Date");
        Assert.RecordIsEmpty(AvgCostAdjmtEntryPoint);
    end;

    [Test]
    procedure T106_EarliestAllowedValDate_OnValidate_UnadjustedEntries_Error()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        // [SCENARIO] Setting "Earliest Allowed Val. Date" fails if there are unadjusted item entries on or before the date.
        Initialize();

        // [GIVEN] All existing items are adjusted so we test our own item only.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] An average-cost item with a positive posting, cost not yet adjusted.
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 10);

        // [WHEN] Validate "Earliest Allowed Val. Date" to a date after the posting, without running cost adjustment.
        InventorySetup.Get();
        asserterror InventorySetup.Validate("Earliest Allowed Val. Date", WorkDate());

        // [THEN] Validation fails because cost is not adjusted.
        Assert.ExpectedError('unadjusted item entries');
    end;

    [Test]
    procedure T107_EarliestAllowedValDate_OnValidate_OpenProdOrderOutput_Error()
    var
        InventorySetup: Record "Inventory Setup";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        OrderNo: Code[20];
    begin
        // [SCENARIO] Setting "Earliest Allowed Val. Date" fails if an open production/assembly order has output on/before the date.
        Initialize();

        // [GIVEN] All existing items are adjusted so we test our own fixture only.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] A fresh item and a unique order number.
        CreateItem(Item, Item."Costing Method"::Average);
        OrderNo := LibraryUtility.GenerateGUID();

        // [GIVEN] An open Inventory Adjmt. Entry (Order) referencing a production order.
        InvtAdjmtEntryOrder.Init();
        InvtAdjmtEntryOrder."Order Type" := InvtAdjmtEntryOrder."Order Type"::Production;
        InvtAdjmtEntryOrder."Order No." := OrderNo;
        InvtAdjmtEntryOrder."Order Line No." := 10000;
        InvtAdjmtEntryOrder."Item No." := Item."No.";
        InvtAdjmtEntryOrder."Is Finished" := false;
        InvtAdjmtEntryOrder."Cost is Adjusted" := true;
        InvtAdjmtEntryOrder.Insert();

        // [GIVEN] A related output value entry with Valuation Date before the cutoff.
        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Order Type" := ValueEntry."Order Type"::Production;
        ValueEntry."Order No." := OrderNo;
        ValueEntry."Order Line No." := 10000;
        ValueEntry."Item No." := Item."No.";
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Output;
        ValueEntry."Valuation Date" := WorkDate() - 10;
        ValueEntry."Posting Date" := WorkDate() - 10;
        ValueEntry.Insert();

        // [WHEN] Validate "Earliest Allowed Val. Date".
        InventorySetup.Get();
        asserterror InventorySetup.Validate("Earliest Allowed Val. Date", WorkDate());

        // [THEN] Validation fails with the open-orders error.
        Assert.ExpectedError('open production and assembly orders');
    end;

    [Test]
    procedure T108_EarliestAllowedValDate_OnValidate_FullyAdjusted_Succeeds()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        // [SCENARIO] Setting "Earliest Allowed Val. Date" succeeds when cost is fully adjusted and no open orders block the date.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] A fresh item with posted and fully adjusted entries before the target cutoff.
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 30);
        LibraryCosting.AdjustCostItemEntries('', '');

        // [WHEN] Validate "Earliest Allowed Val. Date" to a date after the posting.
        SetEarliestAllowedValDate(WorkDate() - 10);

        // [THEN] The field holds the new value.
        InventorySetup.Get();
        InventorySetup.TestField("Earliest Allowed Val. Date", WorkDate() - 10);
    end;

    [Test]
    procedure T109_EarliestAllowedValDate_AppliesToEntry_PreCutoff_Blocked()
    var
        Item: Record Item;
        OldItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] Posting with Applies-to Entry pointing to an ILE whose Posting Date is before the cutoff is blocked (req 4).
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] A FIFO item with an adjusted positive entry posted well before the cutoff.
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 60);
        FindItemLedgerEntry(OldItemLedgerEntry, Item."No.", WorkDate() - 60);
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] The cutoff is set between the old posting and today.
        SetEarliestAllowedValDate(WorkDate() - 30);

        // [WHEN] Try to post an outbound at W with Applies-to Entry explicitly pointing at the pre-cutoff ILE.
        asserterror PostItemJournalLine(Item."No.", '', -5, 0, WorkDate(), OldItemLedgerEntry."Entry No.");

        // [THEN] Posting is blocked with the "cannot apply to entry" error.
        Assert.ExpectedError('cannot apply to entry');
    end;

    [Test]
    procedure T111_MarkForAdjustment_PreCutoffILE_Skipped()
    var
        Item: Record Item;
        PreCutoffItemLedgerEntry, FilteredItemLedgerEntry : Record "Item Ledger Entry";
        ItemLedgerEntryEdit: Codeunit "Item Ledger Entry-Edit";
    begin
        // [SCENARIO] SetAppliedEntriesToAdjust must NOT flag an ILE whose Posting Date is before the cutoff,
        //            and must NOT reset Item."Cost is Adjusted" when every selected ILE is pre-cutoff.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] FIFO item with a single adjusted positive ILE dated W-60.
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 60);
        FindItemLedgerEntry(PreCutoffItemLedgerEntry, Item."No.", WorkDate() - 60);

        // [GIVEN] Cutoff set between the posting and today. Adjust all items first so the OnValidate gate passes.
        LibraryCosting.AdjustCostItemEntries('', '');
        PreCutoffItemLedgerEntry.Find();
        PreCutoffItemLedgerEntry.TestField("Applied Entry to Adjust", false);
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        SetEarliestAllowedValDate(WorkDate() - 30);

        // [WHEN] Mark-for-adjustment is invoked on the pre-cutoff ILE.
        FilteredItemLedgerEntry.SetRange("Entry No.", PreCutoffItemLedgerEntry."Entry No.");
        ItemLedgerEntryEdit.SetAppliedEntriesToAdjust(FilteredItemLedgerEntry);

        // [THEN] The ILE is NOT flagged for readjustment.
        PreCutoffItemLedgerEntry.Find();
        PreCutoffItemLedgerEntry.TestField("Applied Entry to Adjust", false);

        // [THEN] The Item's Cost is Adjusted stays true (pre-cutoff ILE was skipped entirely).
        Item.Find();
        Item.TestField("Cost is Adjusted", true);
    end;

    [Test]
    procedure T112_MarkForAdjustment_PostCutoffILE_Marked()
    var
        Item: Record Item;
        PostCutoffItemLedgerEntry, FilteredItemLedgerEntry : Record "Item Ledger Entry";
        ItemLedgerEntryEdit: Codeunit "Item Ledger Entry-Edit";
    begin
        // [SCENARIO] SetAppliedEntriesToAdjust still flags an ILE whose Posting Date is on/after the cutoff.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] FIFO item with a single adjusted positive ILE on WorkDate().
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate());
        FindItemLedgerEntry(PostCutoffItemLedgerEntry, Item."No.", WorkDate());

        // [GIVEN] Cutoff set strictly before the posting date. Adjust all items first so the OnValidate gate passes.
        LibraryCosting.AdjustCostItemEntries('', '');
        PostCutoffItemLedgerEntry.Find();
        PostCutoffItemLedgerEntry.TestField("Applied Entry to Adjust", false);

        SetEarliestAllowedValDate(WorkDate() - 30);

        // [WHEN] Mark-for-adjustment is invoked on the post-cutoff ILE.
        FilteredItemLedgerEntry.SetRange("Entry No.", PostCutoffItemLedgerEntry."Entry No.");
        ItemLedgerEntryEdit.SetAppliedEntriesToAdjust(FilteredItemLedgerEntry);

        // [THEN] The ILE IS flagged for readjustment (normal behavior preserved for post-cutoff entries).
        PostCutoffItemLedgerEntry.Find();
        PostCutoffItemLedgerEntry.TestField("Applied Entry to Adjust", true);
    end;

    [Test]
    procedure T113_ReopenFinishedProdOrder_PreCutoff_Blocked()
    var
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        OrderNo: Code[20];
    begin
        // [SCENARIO] Reopening (status: Finished -> Released) is blocked when the prod order has value entries
        //            with Valuation Date before the cutoff.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] A clean cost-adjustment state so the cutoff can be set later.

        // [GIVEN] A synthetic Finished production order and a related pre-cutoff Value Entry.
        CreateItem(Item, Item."Costing Method"::FIFO);
        OrderNo := LibraryUtility.GenerateGUID();

        ProductionOrder.Init();
        ProductionOrder.Status := ProductionOrder.Status::Finished;
        ProductionOrder."No." := OrderNo;
        ProductionOrder."Source No." := Item."No.";
        ProductionOrder.Insert();

        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Order Type" := ValueEntry."Order Type"::Production;
        ValueEntry."Order No." := OrderNo;
        ValueEntry."Order Line No." := 10000;
        ValueEntry."Item No." := Item."No.";
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Output;
        ValueEntry."Valuation Date" := WorkDate() - 60;
        ValueEntry."Posting Date" := WorkDate() - 60;
        ValueEntry.Insert();

        // [GIVEN] Cutoff is set between the prod order's value entry and today.
        SetEarliestAllowedValDate(WorkDate() - 30);

        // [WHEN] Try to change the Finished prod order to Released.
        asserterror ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);

        // [THEN] Reopen is blocked.
        Assert.ExpectedError('cannot be reopened');
    end;

    [Test]
    procedure T114_UpdateValuationDate_PreCutoffVE_CascadesForward()
    var
        Item: Record Item;
        PreCutoffAvgCostAdjmtEntryPoint, PostCutoffAvgCostAdjmtEntryPoint : Record "Avg. Cost Adjmt. Entry Point";
        ValueEntry: Record "Value Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        // [SCENARIO] When UpdateValuationDate runs with a pre-cutoff Value Entry, the pre-cutoff entry point
        //            stays adjusted (no flip, no insert); the post-cutoff entry point is reopened.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Average-cost item with two adjusted Avg Cost Adjmt Entry Point records:
        //         W-60 (pre-cutoff) and W-10 (post-cutoff). Both rolled through real postings + adjustment.
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 60);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 10);

        // [GIVEN] Cutoff set between the two entry points. Adjust all items first so the OnValidate gate passes.
        LibraryCosting.AdjustCostItemEntries('', '');
        PreCutoffAvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 60);
        PreCutoffAvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        PostCutoffAvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 10);
        PostCutoffAvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);

        SetEarliestAllowedValDate(WorkDate() - 30);

        // [WHEN] UpdateValuationDate is invoked with a Value Entry at the pre-cutoff date.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Valuation Date", WorkDate() - 60);
        ValueEntry.FindFirst();
        AvgCostEntryPointHandler.UpdateValuationDate(ValueEntry);

        Item.Find();
        Item."Cost is Adjusted" := false;
        Item.Modify();

        // [THEN] The pre-cutoff entry point is NOT flipped to unadjusted.
        PreCutoffAvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 60);
        PreCutoffAvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);

        // [THEN] The post-cutoff entry point IS reopened (cascade still runs).
        PostCutoffAvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 10);
        PostCutoffAvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure T115_UndoReceipt_PreCutoff_Blocked()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        // [SCENARIO] Undo of a purchase receipt posted before the cutoff is blocked.
        Initialize();
        if Confirm('') then; // Consume confirmation messages in country localizations.

        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] A purchase order received at W-10.
        CreateItem(Item, Item."Costing Method"::FIFO);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '', 10, WorkDate() - 10, 100);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Cost adjusted and cutoff set to W-5.
        LibraryCosting.AdjustCostItemEntries('', '');
        SetEarliestAllowedValDate(WorkDate() - 5);

        // [WHEN] Try to undo the posted receipt line.
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        UndoPurchRcptLine.SetHideDialog(true);
        asserterror UndoPurchRcptLine.Run(PurchRcptLine);

        // [THEN] Undo is blocked by the cutoff check.
        Assert.ExpectedError('Earliest Allowed Valuation Date');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure T116_InvoiceAfterReceipt_PostingDatePostCutoff_RedirectAllowed()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ReceiptItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] A purchase invoice posted AFTER the cutoff for a receipt BEFORE the cutoff is allowed,
        //            and the invoice's Value Entry has Valuation Date = Posting Date (redirected).
        Initialize();
        if Confirm('') then; // Consume confirmation messages in country localizations.

        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Receipt posted at W-10 via a purchase order.
        CreateItem(Item, Item."Costing Method"::FIFO);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '', 10, WorkDate() - 10, 100);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindItemLedgerEntry(ReceiptItemLedgerEntry, Item."No.", WorkDate() - 10);

        // [GIVEN] Cost adjusted, cutoff set to WorkDate().
        LibraryCosting.AdjustCostItemEntries('', '');
        SetEarliestAllowedValDate(WorkDate());

        // [WHEN] Invoice the outstanding PO with Posting Date = WorkDate().
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] The invoice's value entry has Valuation Date = WorkDate(), not W-10.
        ValueEntry.SetRange("Item Ledger Entry No.", ReceiptItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
        ValueEntry.FindFirst();
        ValueEntry.TestField("Valuation Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure T117_AverageItem_InvoiceUpdate_PreCutoffCostPreserved()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        PreCutoffItemLedgerEntry: Record "Item Ledger Entry";
        PostCutoffItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] Average-cost item: receipt at W-10, four negative adjustments at W-1/W/W+7/W+14.
        //            Adjust, set cutoff=W, update PO amount, invoice at W. Pre-cutoff AvgCost records must
        //            remain adjusted; pre-cutoff neg adjustment at W-1 keeps its cost; post-cutoff neg
        //            adjustments get updated cost on re-adjustment.
        Initialize();
        if Confirm('') then; // Consume confirmation messages in country localizations.

        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Average-cost item with a receipt of 10 @ 100 at W-10 via a purchase order.
        CreateItem(Item, Item."Costing Method"::Average);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '', 10, WorkDate() - 10, 100);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Four negative adjustments at W-1, W, W+7, W+14.
        PostItemJournalLine(Item."No.", -1, 0, WorkDate() - 1);
        PostItemJournalLine(Item."No.", -1, 0, WorkDate());
        PostItemJournalLine(Item."No.", -1, 0, WorkDate() + 7);
        PostItemJournalLine(Item."No.", -1, 0, WorkDate() + 14);

        // [GIVEN] Cost adjusted.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Cutoff = W.
        SetEarliestAllowedValDate(WorkDate());

        // [WHEN] Update the PO's direct unit cost to 150 and post the invoice at WorkDate().
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", 150);
        PurchaseLine.Modify(true);
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Pre-cutoff Avg. Cost Adjmt. Entry Point records remain Cost Is Adjusted = true.
        AvgCostAdjmtEntryPoint.SetRange("Item No.", Item."No.");
        AvgCostAdjmtEntryPoint.SetFilter("Valuation Date", '<%1', WorkDate());
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        Assert.RecordIsEmpty(AvgCostAdjmtEntryPoint);

        // [WHEN] Cost is adjusted again.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] The negative adjustment at W-1 (pre-cutoff) keeps its original unit cost (100).
        FindItemLedgerEntry(PreCutoffItemLedgerEntry, Item."No.", WorkDate() - 1);
        PreCutoffItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        PreCutoffItemLedgerEntry.TestField("Cost Amount (Actual)", -100);

        // [THEN] The negative adjustment at W (post-cutoff) has a different cost than -100 (the invoice delta propagated forward).
        FindItemLedgerEntry(PostCutoffItemLedgerEntry, Item."No.", WorkDate());
        PostCutoffItemLedgerEntry.SetRange(Positive, false);
        PostCutoffItemLedgerEntry.FindFirst();
        PostCutoffItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreNotEqual(-100, PostCutoffItemLedgerEntry."Cost Amount (Actual)", 'Post-cutoff neg adjustment should pick up the invoice delta');
    end;

    [Test]
    procedure T118_FIFOItem_NewNegAdjustment_FlagsPreCutoffPositive()
    var
        Item: Record Item;
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] FIFO item: pre-cutoff positive +10 (W-1), negative -1 (W+1), adjust, set cutoff=W.
        //            Posting another negative -1 auto-applies via FIFO to the pre-cutoff positive and flags it
        //            with "Applied Entry to Adjust" = true (req 2).
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] FIFO item with positive +10 at W-1 and negative -1 at W+1.
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 1);
        PostItemJournalLine(Item."No.", -1, 0, WorkDate() + 1);

        // [GIVEN] Cost adjusted; positive ILE is not currently flagged.
        LibraryCosting.AdjustCostItemEntries('', '');
        FindItemLedgerEntry(PositiveItemLedgerEntry, Item."No.", WorkDate() - 1);
        PositiveItemLedgerEntry.TestField("Applied Entry to Adjust", false);

        // [GIVEN] Cutoff = W.
        SetEarliestAllowedValDate(WorkDate());

        // [WHEN] Post another negative -1 at W+2 (auto-applied to the pre-cutoff positive by FIFO).
        PostItemJournalLine(Item."No.", -1, 0, WorkDate() + 2);

        // [THEN] The pre-cutoff positive ILE is now flagged for readjustment.
        PositiveItemLedgerEntry.Find();
        PositiveItemLedgerEntry.TestField("Applied Entry to Adjust", true);
    end;

    [Test]
    procedure T119_UpdateNextValuations_CascadeFloor_MultiPeriod()
    var
        Item: Record Item;
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        ValueEntry: Record "Value Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        // [SCENARIO] Multi-period cascade: when UpdateValuationDate runs with a pre-cutoff Value Entry,
        //            EVERY post-cutoff Avg Cost Adjmt Entry Point record is reopened (not just the first),
        //            while every pre-cutoff record stays adjusted. Directly exercises the `>%1&>=cutoff`
        //            compound filter in UpdateNextValuations.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Average-cost item with four adjusted Avg Cost Adjmt Entry Point records across multiple periods:
        //         W-60 (pre-cutoff), W-10, W, W+10 (post-cutoff).
        CreateItem(Item, Item."Costing Method"::Average);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 60);
        PostItemJournalLine(Item."No.", 5, 110, WorkDate() - 10);
        PostItemJournalLine(Item."No.", 5, 120, WorkDate());
        PostItemJournalLine(Item."No.", 5, 130, WorkDate() + 10);
        LibraryCosting.AdjustCostItemEntries('', '');

        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 60);
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 10);
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate());
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() + 10);
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);

        // [GIVEN] Cutoff set between the pre-cutoff and first post-cutoff record.
        SetEarliestAllowedValDate(WorkDate() - 30);

        // [WHEN] UpdateValuationDate is invoked with a pre-cutoff Value Entry.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Valuation Date", WorkDate() - 60);
        ValueEntry.FindFirst();
        AvgCostEntryPointHandler.UpdateValuationDate(ValueEntry);

        Item.Find();
        Item."Cost is Adjusted" := false;
        Item.Modify();

        // [THEN] Pre-cutoff record is NOT reopened (still adjusted).
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 60);
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);

        // [THEN] Every post-cutoff record IS reopened (cascaded forward across all periods).
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 10);
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate());
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);
        AvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() + 10);
        AvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure T120_ItemChargeAppliedToPreCutoffReceipt_Blocked()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderItemCharge: Record "Purchase Header";
        PurchaseLineItemCharge: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        // [SCENARIO] An item charge invoiced after the cutoff and assigned to a pre-cutoff receipt is blocked;
        //            the charge value entry inherits the receipt's pre-cutoff Valuation Date and is not redirected
        //            (IsPureInvoicing excludes Item Charge lines). Checkpoint 2 fires (req 3).
        Initialize();
        if Confirm('') then; // Consume confirmation messages in country localizations.

        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] A fully-received, fully-invoiced purchase posted at W-10.
        CreateItem(Item, Item."Costing Method"::FIFO);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '', 10, WorkDate() - 10, 100);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Cost adjusted and cutoff set to WorkDate.
        LibraryCosting.AdjustCostItemEntries('', '');
        SetEarliestAllowedValDate(WorkDate());

        // [WHEN] A new purchase invoice with an item charge line is assigned to the posted receipt and posted at WorkDate.
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderItemCharge, PurchaseHeaderItemCharge."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeaderItemCharge.Validate("Posting Date", WorkDate());
        PurchaseHeaderItemCharge.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineItemCharge, PurchaseHeaderItemCharge, PurchaseLineItemCharge.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLineItemCharge.Validate("Direct Unit Cost", 50);
        PurchaseLineItemCharge.Modify(true);
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindFirst();
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, PurchaseLineItemCharge, ItemCharge,
            Enum::"Purchase Applies-to Document Type"::Receipt,
            PurchRcptLine."Document No.", PurchRcptLine."Line No.", Item."No.", 1, 50);
        ItemChargeAssignmentPurch.Insert(true);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeaderItemCharge, true, true);

        // [THEN] Posting is blocked by the cutoff.
        Assert.ExpectedError('Earliest Allowed Valuation Date');
    end;

    [Test]
    procedure T121_Revaluation_AppliesToPreCutoffEntry_Blocked()
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PreCutoffItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] A revaluation journal line whose Applies-to Entry points to a pre-cutoff ILE is blocked (req 3).
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] FIFO item with an adjusted positive ILE at W-60.
        CreateItem(Item, Item."Costing Method"::FIFO);
        PostItemJournalLine(Item."No.", 10, 100, WorkDate() - 60);
        FindItemLedgerEntry(PreCutoffItemLedgerEntry, Item."No.", WorkDate() - 60);
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Cutoff set to W-30.
        SetEarliestAllowedValDate(WorkDate() - 30);

        // [GIVEN] A clean Revaluation Journal template+batch.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();

        // [WHEN] A revaluation line for the item is created with Applies-to Entry = the pre-cutoff ILE.
        LibraryInventory.CreateItemJnlLineWithNoItem(
            ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.Validate("Applies-to Entry", PreCutoffItemLedgerEntry."Entry No.");
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Validate("Unit Cost (Revalued)", 150);
        ItemJournalLine.Modify(true);

        asserterror LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // [THEN] Blocked by the Applies-to-Entry check.
        Assert.ExpectedError('cannot apply to entry');
    end;

    [Test]
    procedure T122_RoundingEntry_PreCutoffValuationDate_Allowed()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        PurchaseItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] A Rounding value entry emitted by cost adjustment with a pre-cutoff Valuation Date
        //            is exempt and posts (req 5). Setup: 3 pcs purchased for a total of 10 (unit cost 10/3),
        //            then three outbound entries of 1 pc each are applied. The outbounds each pick up a
        //            rounded unit cost of 3.33 and together sum to 9.99. The final outbound is posted in
        //            the valid period (after the cutoff); cost adjustment reconciles the 0.01 residue by
        //            emitting a Rounding VE on the purchase ILE with Valuation Date = the purchase's date
        //            (pre-cutoff). That VE must be allowed to post.
        Initialize();
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] FIFO item.
        CreateItem(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Purchase of 3 pcs for a total Amount of 10 posted at W-10 (unit cost = 10/3).
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 3);
        ItemJournalLine.Validate("Posting Date", WorkDate() - 10);
        ItemJournalLine.Validate(Amount, 10);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        FindItemLedgerEntry(PurchaseItemLedgerEntry, Item."No.", WorkDate() - 10);

        // [GIVEN] Two outbound entries of 1 pc each posted at W-8 and W-6, cost adjusted.
        PostItemJournalLine(Item."No.", '', -1, 0, WorkDate() - 8, 0);
        PostItemJournalLine(Item."No.", '', -1, 0, WorkDate() - 6, 0);
        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Cutoff set to W-2 (after the purchase and first two outbounds).
        SetEarliestAllowedValDate(WorkDate() - 2);

        // [WHEN] The final outbound of 1 pc is posted at W (in the valid period) and cost is adjusted.
        //         The purchase is now fully applied; cost adjustment emits a Rounding VE on the purchase ILE
        //         with Valuation Date = W-10 (pre-cutoff).
        PostItemJournalLine(Item."No.", '', -1, 0, WorkDate(), 0);
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] A Rounding value entry exists on the purchase ILE with a Valuation Date before the cutoff.
        InventorySetup.Get();
        ValueEntry.SetRange("Item Ledger Entry No.", PurchaseItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        ValueEntry.SetFilter("Valuation Date", '<%1', InventorySetup."Earliest Allowed Val. Date");
        Assert.RecordIsNotEmpty(ValueEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure T123_FIFO_PreCutoffSale_AdjustedFromPostCutoffPurchase()
    var
        Item: Record Item;
        SalesItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] FIFO item: a sales order posted before the cutoff (with no inventory) creates an ILE
        //            with negative Remaining Quantity. Cost is adjusted (sale stays at zero cost). Cutoff is set.
        //            A purchase order posted AFTER the cutoff auto-applies via FIFO to the pre-cutoff sale.
        //            Cost adjustment then propagates the purchase's cost into the pre-cutoff sale.
        Initialize();
        if Confirm('') then; // Consume confirmation messages in country localizations.

        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] FIFO item with no inventory.
        CreateItem(Item, Item."Costing Method"::FIFO);

        // [GIVEN] Sales order of 5 pcs posted at W-10 (no cutoff yet). The Sale ILE has Remaining Quantity = -5.
        PostSalesOrder(Item."No.", 5, WorkDate() - 10);
        FindItemLedgerEntry(SalesItemLedgerEntry, Item."No.", WorkDate() - 10);
        SalesItemLedgerEntry.TestField("Remaining Quantity", -5);

        // [GIVEN] Cost adjusted.
        LibraryCosting.AdjustCostItemEntries('', '');
        Item.Find();
        Item.TestField("Cost is Adjusted", true);

        // [GIVEN] Cutoff is set to WorkDate (after the sale, before the upcoming purchase).
        SetEarliestAllowedValDate(WorkDate());

        // [WHEN] Purchase order of 5 pcs at unit cost 100 is posted at W+10 (after the cutoff).
        //        FIFO auto-applies the unapplied pre-cutoff sale to this new positive ILE.
        PostPurchaseOrder(Item."No.", 5, WorkDate() + 10, 100);

        // [WHEN] Cost is adjusted again.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] The sale's Remaining Quantity is now zero (fully applied).
        SalesItemLedgerEntry.Find();
        SalesItemLedgerEntry.TestField("Remaining Quantity", 0);

        // [THEN] The pre-cutoff sale carries the cost from the post-cutoff purchase: 5 * -100 = -500.
        SalesItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        SalesItemLedgerEntry.TestField("Cost Amount (Actual)", -500);

        // [THEN] The item is fully cost-adjusted with a balanced ledger.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);
        VerifyItemCostAmountZero(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure T124_Average_PreCutoffSale_AdjustedFromPostCutoffPurchase()
    var
        Item: Record Item;
        SalesItemLedgerEntry: Record "Item Ledger Entry";
        PreCutoffAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        // [SCENARIO] Average-cost item: a sales order posted before the cutoff (with no inventory) creates an
        //            unadjusted Avg. Cost Adjmt. Entry Point and an ILE with negative Remaining Quantity.
        //            Cost is adjusted - the entry point flips to adjusted. Cutoff is set.
        //            A purchase order posted AFTER the cutoff auto-applies to the pre-cutoff sale, but the
        //            pre-cutoff entry point in table 5804 must NOT be reopened (suppression).
        //            Cost adjustment then propagates the purchase's cost into the pre-cutoff sale.
        Initialize();
        if Confirm('') then; // Consume confirmation messages in country localizations.

        LibraryCosting.AdjustCostItemEntries('', '');

        // [GIVEN] Average-cost item with no inventory.
        CreateItem(Item, Item."Costing Method"::Average);

        // [GIVEN] Sales order of 5 pcs posted at W-10 (no cutoff yet). The Sale ILE has Remaining Quantity = -5.
        PostSalesOrder(Item."No.", 5, WorkDate() - 10);
        FindItemLedgerEntry(SalesItemLedgerEntry, Item."No.", WorkDate() - 10);
        SalesItemLedgerEntry.TestField("Remaining Quantity", -5);

        // [GIVEN] An Avg. Cost Adjmt. Entry Point exists for W-10 and is unadjusted.
        PreCutoffAvgCostAdjmtEntryPoint.Get(Item."No.", '', '', WorkDate() - 10);
        PreCutoffAvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", false);

        // [GIVEN] Cost adjusted - the entry point at W-10 becomes adjusted.
        LibraryCosting.AdjustCostItemEntries('', '');
        PreCutoffAvgCostAdjmtEntryPoint.Find();
        PreCutoffAvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);

        // [GIVEN] Cutoff is set to WorkDate (after the sale, before the upcoming purchase).
        SetEarliestAllowedValDate(WorkDate());

        // [WHEN] Purchase order of 5 pcs at unit cost 100 is posted at W+10 (after the cutoff).
        //        It auto-applies to the pre-cutoff sale.
        PostPurchaseOrder(Item."No.", 5, WorkDate() + 10, 100);

        // [THEN] The pre-cutoff entry point at W-10 stays adjusted (signaling suppressed across the cutoff).
        PreCutoffAvgCostAdjmtEntryPoint.Find();
        PreCutoffAvgCostAdjmtEntryPoint.TestField("Cost Is Adjusted", true);

        // [WHEN] Cost is adjusted again.
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] The sale's Remaining Quantity is now zero (fully applied).
        SalesItemLedgerEntry.Find();
        SalesItemLedgerEntry.TestField("Remaining Quantity", 0);

        // [THEN] The pre-cutoff sale's cost is updated from the post-cutoff purchase: 5 * -100 = -500.
        SalesItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        SalesItemLedgerEntry.TestField("Cost Amount (Actual)", -500);

        // [THEN] The item is fully cost-adjusted with a balanced ledger.
        Item.Find();
        Item.TestField("Cost is Adjusted", true);
        VerifyItemCostAmountZero(Item."No.");
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

    local procedure SetEarliestAllowedValDate(NewDate: Date)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Earliest Allowed Val. Date", NewDate);
        InventorySetup.Modify();
    end;

    local procedure PostSalesOrder(ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date; UnitCost: Decimal)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Item.Get(ItemNo);
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, '', '', Quantity, PostingDate, UnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
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

    [ConfirmHandler]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}