codeunit 137617 "Production & Assembly Costing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Rounding]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2', Comment = '%1 = Field Caption , %2 = Expected Value';

    [Test]
    [Scope('OnPrem')]
    procedure TransferRoundingAfterChangingAvgCostCalcType()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO 359395] Cost adjustment of transfers of an average-cost item after changing cost calculation type from "Item" to "Item & Location & Variant"
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Item "I" with Average costing method
        CreateItem(Item, LibraryRandom.RandDec(10000, 5), Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase and partial sale of item "I" on location "L1"
        PostPurchaseAndSaleItemJnlLines(Item."No.");

        // [GIVEN] Transfer remaining quantity of item "I" to location "L2"
        SelectTransferJournalBatch(ItemJournalBatch);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Transfer, Item."No.", 3 * 3.71, WorkDate());
        ItemJournalLine.Validate("New Location Code", Location.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [GIVEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        VerifyInvtIsZero(Item."No.");

        // [GIVEN] Set average cost calculation type = Item & Location & Variant
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Inventory cost amount is 0
        VerifyInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnRoundingAfterChangingAvgCostCalcType()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO 359395] Cost adjustment of average-costed sales returns after changing cost calculation type from "Item" to "Item & Location & Variant"
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, LibraryRandom.RandDec(10000, 5), Item."Costing Method"::Average);

        // [GIVEN] Post purchase and sales entries for item "I" without fixed cost application
        PostPurchaseAndSaleItemJnlLines(Item."No.");

        SelectItemJournalBatch(ItemJournalBatch);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 3 * 3.71, WorkDate());
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Post partial sales return with cost application
        ItemLedgEntry.FindLast();
        CreateItemJournalLineWithAppliesFrom(
          ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", -3 * 3.71, '', ItemLedgEntry."Entry No.", WorkDate());
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        VerifyInvtIsZero(Item."No.");

        // [GIVEN] Set average cost calculation type = Item & Location & Variant
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Inventory cost amount is 0
        VerifyInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnPostingOnDifferentDates()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        I: Integer;
        PostingDate: Date;
    begin
        // [SCENARIO 359395] Cost adjustment of average-costed sales returns on different dates after changing cost calculation type from "Item" to "Item & Location & Variant"
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, LibraryRandom.RandDec(10000, 5), Item."Costing Method"::Average);

        // [GIVEN] Post purchase and partial sale for item "I" without fixed cost application
        PostManyPurchasesAndSalesNoApplication(Item."No.");

        // [GIVEN] Sale remaining quantity of item "I" and undo sale with cost application on different date
        PostingDate := WorkDate();
        SelectItemJournalBatch(ItemJournalBatch);
        for I := 1 to 9 do begin
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 3.71, PostingDate);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

            ItemLedgEntry.FindLast();
            PostingDate := PostingDate + 1;
            CreateItemJournalLineWithAppliesFrom(
              ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", -3.71, '', ItemLedgEntry."Entry No.", PostingDate);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [GIVEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        VerifyInvtIsZero(Item."No.");

        // [GIVEN] Set average cost calculation type = Item & Location & Variant
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Inventory cost amount is 0
        VerifyInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransfersAndAppliedSalesAfterChangingAvgCostCalcType()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        InventorySetup: Record "Inventory Setup";
        I: Integer;
    begin
        // [SCENARIO 359395] Cost adjustment of average-costed item with sales and transfers posted without fixed application after changing cost calculation type from "Item" to "Item & Location & Variant"
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, LibraryRandom.RandDec(10000, 5), Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase and partial sale for item "I" without fixed cost application
        PostManyPurchasesAndSalesNoApplication(Item."No.");

        // [GIVEN] Transfer remaining quantity to another location
        SelectTransferJournalBatch(ItemJournalBatch);
        for I := 1 to 9 do begin
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Transfer, Item."No.", 3.71, WorkDate());
            ItemJournalLine.Validate("New Location Code", Location.Code);
            ItemJournalLine.Modify(true);
        end;
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [GIVEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        VerifyInvtIsZero(Item."No.");

        // [GIVEN] Set average cost calculation type = Item & Location & Variant
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Inventory cost amount is 0
        VerifyInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnRoundingWithFixedCostApplication()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        i: Integer;
    begin
        // [SCENARIO 359395] Cost adjustment of average-costed item with sales and returns posted with fixed application after changing cost calculation type from "Item" to "Item & Location & Variant"
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);
        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, LibraryRandom.RandDec(10000, 5), Item."Costing Method"::Average);
        // [GIVEN] Post purchase and partial sale for item "I" without fixed cost application
        PostManyPurchasesAndSalesNoApplication(Item."No.");

        // [GIVEN] Sale remaining quantity of item "I" and undo sale with cost application on the same date
        SelectItemJournalBatch(ItemJournalBatch);
        for i := 1 to 9 do begin
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 3.71, WorkDate());
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

            ItemLedgEntry.FindLast();

            Initialize();
            CreateItemJournalLineWithAppliesFrom(
              ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", -3.71, '', ItemLedgEntry."Entry No.", WorkDate());
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [GIVEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        VerifyInvtIsZero(Item."No.");

        // [GIVEN] Set average cost calculation type = Item & Location & Variant
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Inventory cost amount is 0
        VerifyInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransfersAndAppliedSales()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemLedgEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        FromEntryTo: Integer;
        I: Integer;
    begin
        // [SCENARIO 359395] Cost adjustment of an average-costed item transferred with fixed cost application
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, 0, Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase entries for item "I" on location "L1"
        SelectItemJournalBatch(ItemJnlBatch);
        for I := 1 to 6 do
            CreateItemJournalLineWithUnitCost(ItemJnlBatch, ItemJnlLine."Entry Type"::Purchase, Item."No.", 2.44, 6710, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJnlBatch, ItemJnlLine."Entry Type"::Purchase, Item."No.", 1.63, 6710, WorkDate());

        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
        ItemLedgEntry.FindLast();
        FromEntryTo := ItemLedgEntry."Entry No.";
        FromEntryTo -= 2;

        // [GIVEN] Transfer item "I" from location "L1" to locatin "L2", then sale from "L2" with cost application
        SelectTransferJournalBatch(ItemJnlBatch);
        for I := 1 to 4 do begin
            CreateItemJournalLine(ItemJnlLine, ItemJnlBatch, ItemJnlLine."Entry Type"::Transfer, Item."No.", 2.44, WorkDate());
            ItemJnlLine.Validate("New Location Code", Location.Code);
            ItemJnlLine.Modify(true);
            LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

            ItemLedgEntry.FindLast();

            CreateItemJournalLineWithAppliesTo(
              ItemJnlBatch, ItemJnlLine."Entry Type"::Sale, Item."No.", 2.44, Location.Code, ItemLedgEntry."Entry No.", WorkDate());

            LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
        end;

        // [GIVEN] Sell remaining quantity from locaiton "L1", post with cost application
        SelectItemJournalBatch(ItemJnlBatch);
        CreateItemJournalLineWithAppliesTo(ItemJnlBatch, ItemJnlLine."Entry Type"::Sale, Item."No.", 2.44, '', FromEntryTo, WorkDate());
        CreateItemJournalLineWithAppliesTo(ItemJnlBatch, ItemJnlLine."Entry Type"::Sale, Item."No.", 2.44, '', FromEntryTo + 1, WorkDate());
        CreateItemJournalLineWithAppliesTo(ItemJnlBatch, ItemJnlLine."Entry Type"::Sale, Item."No.", 1.63, '', FromEntryTo + 2, WorkDate());

        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Actual cost amount of item "I" is 0
        VerifyZeroActualCostRemains(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnWithFixedApplication()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        InventorySetup: Record "Inventory Setup";
        I: Integer;
        FromEntryTo: Integer;
    begin
        // [SCENARIO 359395] Adjust cost of sales with applied undo sale and a correction of undo
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, 0, Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase entries for item "I"
        PostPurchasesItemJournalLines(Item."No.");

        ItemLedgEntry.FindLast();
        FromEntryTo := ItemLedgEntry."Entry No.";
        FromEntryTo -= 2;

        SelectItemJournalBatch(ItemJournalBatch);
        for I := 1 to 4 do begin
            // [GIVEN] Post sales entries without application to purchase
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 2.44, WorkDate());
            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

            // [GIVEN] Undo sale with fixed cost application
            ItemLedgEntry.FindLast();
            CreateItemJournalLineWithAppliesFrom(
              ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", -2.44, Location.Code, ItemLedgEntry."Entry No.", WorkDate());

            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

            // [GIVEN] Post sale with aplication to previous sales return
            ItemLedgEntry.FindLast();
            CreateItemJournalLineWithAppliesTo(
              ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 2.44, Location.Code, ItemLedgEntry."Entry No.", WorkDate());

            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        end;
        PostSalesItemJournalWithCostApplication(Item."No.", FromEntryTo, WorkDate());

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Actual cost amount of item "I" is 0
        VerifyZeroActualCostRemains(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyRoundingWithFixedCostApplicationByItem()
    var
        Item: Record Item;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        InventorySetup: Record "Inventory Setup";
        I: Integer;
        FromEntryTo: Integer;
    begin
        // [FEATURE] [Assembly] [Self-consumption] [Average Cost]
        // [SCENARIO 359395] Adjust cost of assembly rework with self-consumption and applied sales when average cost is calculated by item.
        Initialize();

        // [GIVEN] Set average cost calculation type = Item
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item);

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, 0, Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase entries for item "I"
        PostPurchasesItemJournalLines(Item."No.");

        ItemLedgEntry.FindLast();
        FromEntryTo := ItemLedgEntry."Entry No.";
        FromEntryTo -= 2;

        // [GIVEN] Create and post assembly order consuming and producing the same item "I"
        // [GIVEN] Sell assembled items with fixed cost application
        SelectItemJournalBatch(ItemJournalBatch);
        for I := 1 to 4 do begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", Location.Code, 2.44, '');
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, Item."No.", Item."Base Unit of Measure", 2.44, 1, '');
            AssemblyLine.Validate("Location Code", '');
            AssemblyLine.Modify(true);

            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

            ItemLedgEntry.FindLast();
            CreateItemJournalLineWithAppliesTo(
              ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 2.44, Location.Code, ItemLedgEntry."Entry No.", WorkDate());
            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        end;

        PostSalesItemJournalWithCostApplication(Item."No.", FromEntryTo, WorkDate());

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Actual cost amount of item "I" is 0
        VerifyZeroActualCostRemains(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyRoundingWithFixedCostApplicationByItemVariantLocation()
    var
        Item: Record Item;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        InventorySetup: Record "Inventory Setup";
        I: Integer;
        FromEntryTo: Integer;
    begin
        // [FEATURE] [Assembly] [Self-consumption] [Average Cost]
        // [SCENARIO 359395] Adjust cost of assembly rework with self-consumption and applied sales when average cost is calculated by item & location & variant.
        Initialize();

        // [GIVEN] Set average cost calculation type = "Item & Location & Variant"
        SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant");

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, 0, Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase entries for item "I"
        PostPurchasesItemJournalLines(Item."No.");

        ItemLedgEntry.FindLast();
        FromEntryTo := ItemLedgEntry."Entry No.";
        FromEntryTo -= 2;

        // [GIVEN] Create and post assembly order consuming and producing the same item "I"
        // [GIVEN] Sell assembled items with fixed cost application
        SelectItemJournalBatch(ItemJournalBatch);
        for I := 1 to 4 do begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", Location.Code, 2.44, '');
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, Item."No.", Item."Base Unit of Measure", 2.44, 1, '');
            AssemblyLine.Validate("Location Code", '');
            AssemblyLine.Modify(true);

            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

            ItemLedgEntry.FindLast();
            CreateItemJournalLineWithAppliesTo(
              ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 2.44, Location.Code, ItemLedgEntry."Entry No.", WorkDate());
            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        end;

        PostSalesItemJournalWithCostApplication(Item."No.", FromEntryTo, WorkDate());

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Actual cost amount of item "I" is 0
        VerifyZeroActualCostRemains(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyRoundingWithFixedCostApplicationWithinMonthValuationPeriod()
    var
        Item: Record Item;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        InventorySetup: Record "Inventory Setup";
        I: Integer;
        FromEntryTo: Integer;
    begin
        // [FEATURE] [Assembly] [Self-consumption] [Average Cost]
        // [SCENARIO 359395] Adjust cost of assembly rework with self-consumption and applied sales within month-long valuation period.
        Initialize();

        // [GIVEN] Set average cost calculation type = "Item" and valuation period = "Month".
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Month);

        // [GIVEN] Item "I" with "Average" costing method
        CreateItem(Item, 0, Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Post purchase entries for item "I" on WORKDATE.
        PostPurchasesItemJournalLines(Item."No.");

        ItemLedgEntry.FindLast();
        FromEntryTo := ItemLedgEntry."Entry No.";
        FromEntryTo -= 2;

        // [GIVEN] Create and post assembly order consuming and producing the same item "I", due date = WorkDate() + 1 day.
        // [GIVEN] Sell assembled items with fixed cost application on WorkDate() + 2 days.
        SelectItemJournalBatch(ItemJournalBatch);
        for I := 1 to 4 do begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate() + 1, Item."No.", Location.Code, 2.44, '');
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, Item."No.", Item."Base Unit of Measure", 2.44, 1, '');
            AssemblyLine.Validate("Location Code", '');
            AssemblyLine.Modify(true);

            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

            ItemLedgEntry.FindLast();
            CreateItemJournalLineWithAppliesTo(
              ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, Item."No.", 2.44, Location.Code, ItemLedgEntry."Entry No.", WorkDate() + 2);
            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
        end;

        // [GIVEN] Sell the remaining quantity, set posting date = WorkDate() + 3 days.
        PostSalesItemJournalWithCostApplication(Item."No.", FromEntryTo, WorkDate() + 3);

        // [WHEN] Run "Adjust cost - item entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Actual cost amount of item "I" is 0
        VerifyZeroActualCostRemains(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageCostCalculationOfAssemblyWithSelfConsumption()
    var
        InventorySetup: Record "Inventory Setup";
        AsmItem: Record Item;
        CompItem: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
    begin
        // [FEATURE] [Assembly] [Self-consumption] [Average Cost]
        // [SCENARIO 294427] Average cost calculation of assembled item being used as a component of itself, and another component item.
        Initialize();

        // [GIVEN] Set average cost calculation type = "Item" and valuation period = "Day".
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // [GIVEN] Assembled item "A" and its component "C", both are set up for "Average" costing method.
        CreateItem(AsmItem, 0, AsmItem."Costing Method"::Average);
        CreateItem(CompItem, 0, CompItem."Costing Method"::Average);

        // [GIVEN] Post the inventory of both items.
        // [GIVEN] Item "A": post 1 pc for 100 LCY and another 1 pc for 180 LCY. The average cost is 140 LCY.
        // [GIVEN] Item "C": post 2 pcs for 10 LCY each.
        SelectItemJournalBatch(ItemJournalBatch);
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, AsmItem."No.", 1, 100.0, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, AsmItem."No.", 1, 180.0, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, CompItem."No.", 2, 10.0, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [GIVEN] Two assembly orders for item "A".
        // [GIVEN] Add two component lines to each order: 1 pc of item "A" and 1 pc of item "C".
        // [GIVEN] Post both assemblies.
        for i := 1 to 2 do begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), AsmItem."No.", '', 1, '');
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, AsmItem."No.", AsmItem."Base Unit of Measure", 1, 1, '');
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, CompItem."No.", CompItem."Base Unit of Measure", 1, 1, '');
            LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        end;

        // [GIVEN] Write the remaining quantity of "A" off the inventory.
        CreateItemJournalLineWithUnitCost(
          ItemJournalBatch, ItemJournalLine."Entry Type"::"Negative Adjmt.", AsmItem."No.", 1, 0.0, WorkDate());
        CreateItemJournalLineWithUnitCost(
          ItemJournalBatch, ItemJournalLine."Entry Type"::"Negative Adjmt.", AsmItem."No.", 1, 0.0, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [WHEN] Adjust cost of both "A" and "C".
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', AsmItem."No.", CompItem."No."), '');

        // [THEN] The average cost of item "A" = 150 LCY. (140 LCY after the purchase plus 10 LCY as the consumption of component "C").
        AsmItem.Find();
        AsmItem.TestField("Unit Cost", 150.0);

        // [THEN] The average cost of item "C" = 10 LCY.
        CompItem.Find();
        CompItem.TestField("Unit Cost", 10.0);

        // [THEN] The average cost of output of "A" = 150 LCY.
        // [THEN] The average cost of consumption of "A" = 140 LCY.
        VerifyItemEntriesCost(AsmItem."No.", ItemLedgerEntry."Entry Type"::"Assembly Output", 150.0);
        VerifyItemEntriesCost(AsmItem."No.", ItemLedgerEntry."Entry Type"::"Assembly Consumption", -140.0);

        // [THEN] The average cost of consumption of "C" = 10 LCY.
        VerifyItemEntriesCost(CompItem."No.", ItemLedgerEntry."Entry Type"::"Assembly Consumption", -10.0);

        // [THEN] The remaining quantity and amount of item "A" in the inventory is zero.
        VerifyZeroActualCostRemains(AsmItem."No.");

        // [THEN] The remaining quantity and amount of item "C" in the inventory is zero.
        VerifyZeroActualCostRemains(CompItem."No.");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AverageCostCalculationOfProdOrderWithSelfConsumption()
    var
        InventorySetup: Record "Inventory Setup";
        ProdItem: Record Item;
        CompItem: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
    begin
        // [FEATURE] [Production Order] [Self-consumption] [Average Cost]
        // [SCENARIO 294427] Average cost calculation of manufacturing item being used as a component of itself, and another component item.
        Initialize();

        // [GIVEN] Set average cost calculation type = "Item" and valuation period = "Day".
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);

        // [GIVEN] Production item "P" and its component "C", both are set up for "Average" costing method.
        CreateItem(ProdItem, 0, ProdItem."Costing Method"::Average);
        CreateItem(CompItem, 0, CompItem."Costing Method"::Average);

        // [GIVEN] Post the inventory of both items.
        // [GIVEN] Item "P": post 1 pc for 100 LCY and another 1 pc for 180 LCY. The average cost is 140 LCY.
        // [GIVEN] Item "C": post 2 pcs for 10 LCY each.
        SelectItemJournalBatch(ItemJournalBatch);
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ProdItem."No.", 1, 100.0, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ProdItem."No.", 1, 180.0, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, CompItem."No.", 2, 10.0, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [GIVEN] Two production orders for item "P".
        // [GIVEN] Add two prod. order component lines to each order: 1 pc of item "P" and 1 pc of item "C".
        // [GIVEN] Post both output and consumption.
        // [GIVEN] Change status of the production orders to "Finished".
        for i := 1 to 2 do begin
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

            FindProdOrderLine(ProdOrderLine, ProductionOrder, ProdItem."No.");
            CreateProdOrderComponentWithItem(ProdOrderComponent, ProdOrderLine, ProdItem."No.", 1);
            CreateProdOrderComponentWithItem(ProdOrderComponent, ProdOrderLine, CompItem."No.", 1);
            LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

            ProductionOrder.Find();
            LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);
        end;

        // [GIVEN] Write the remaining quantity of "P" off the inventory.
        CreateItemJournalLineWithUnitCost(
          ItemJournalBatch, ItemJournalLine."Entry Type"::"Negative Adjmt.", ProdItem."No.", 1, 0.0, WorkDate());
        CreateItemJournalLineWithUnitCost(
          ItemJournalBatch, ItemJournalLine."Entry Type"::"Negative Adjmt.", ProdItem."No.", 1, 0.0, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [WHEN] Adjust cost of both "P" and "C".
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ProdItem."No.", CompItem."No."), '');

        // [THEN] The average cost of item "P" = 150 LCY. (140 LCY after the purchase plus 10 LCY as the consumption of component "C").
        ProdItem.Find();
        ProdItem.TestField("Unit Cost", 150.0);

        // [THEN] The average cost of item "C" = 10 LCY.
        CompItem.Find();
        CompItem.TestField("Unit Cost", 10.0);

        // [THEN] The average cost of output of "P" = 150 LCY.
        // [THEN] The average cost of consumption of "P" = 140 LCY.
        VerifyItemEntriesCost(ProdItem."No.", ItemLedgerEntry."Entry Type"::Output, 150.0);
        VerifyItemEntriesCost(ProdItem."No.", ItemLedgerEntry."Entry Type"::Consumption, -140.0);

        // [THEN] The average cost of consumption of "C" = 10 LCY.
        VerifyItemEntriesCost(CompItem."No.", ItemLedgerEntry."Entry Type"::Consumption, -10.0);

        // [THEN] The remaining quantity and amount of item "P" in the inventory is zero.
        VerifyZeroActualCostRemains(ProdItem."No.");

        // [THEN] The remaining quantity and amount of item "C" in the inventory is zero.
        VerifyZeroActualCostRemains(CompItem."No.");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AverageCostCalculationOfMakeToOrderProdOrder()
    var
        CompItem: Record Item;
        IntermdItem: Record Item;
        FinalItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CompUnitCost: Decimal;
    begin
        // [FEATURE] [Production Order] [Make-to-Order] [Average Cost]
        // [SCENARIO 333128] Average cost calculation of multilevel production order.
        Initialize();
        CompUnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Component item "C", intermediate production item "I", final production item "P".
        // [GIVEN] Items "C", "I", "P" are set up for Average costing method and have various unit costs.
        CreateItem(CompItem, CompUnitCost, CompItem."Costing Method"::Average);
        CreateItem(IntermdItem, LibraryRandom.RandDecInRange(101, 200, 2), IntermdItem."Costing Method"::Average);
        CreateItem(FinalItem, LibraryRandom.RandDecInRange(201, 300, 2), FinalItem."Costing Method"::Average);

        // [GIVEN] Set up production BOMs for items "I" and "P" so that 1 pcs "P" consists of 1 pc "I", which in its turn consists of 1 pc "C".
        CreateProductionBOM(IntermdItem, CompItem);
        CreateProductionBOM(FinalItem, IntermdItem);

        // [GIVEN] Post inventory for item "C". Unit cost = "X".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create multilevel production order for final item "P".
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, FinalItem."No.", 1);

        // [GIVEN] Post consumption of "C" and output of "C".
        FindProdOrderLine(ProdOrderLine, ProductionOrder, IntermdItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Post consumption of "C" and output of "P".
        FindProdOrderLine(ProdOrderLine, ProductionOrder, FinalItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run cost adjustment for items "C", "I", "P".
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2|%3', CompItem."No.", IntermdItem."No.", FinalItem."No."), '');

        // [THEN] Output of "I" has unit cost equal to "X".
        VerifyItemEntriesCost(IntermdItem."No.", ItemLedgerEntry."Entry Type"::Output, CompUnitCost);

        // [THEN] Output of "P" has unit cost equal to "X".
        VerifyItemEntriesCost(FinalItem."No.", ItemLedgerEntry."Entry Type"::Output, CompUnitCost);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandlerForDimensionSetID')]
    [Scope('OnPrem')]
    procedure VerifyDimensionSetIDForEntryTypeConsumptionInProductionJournal()
    var
        ComponentItem: Record Item;
        ProducedItem: Record Item;
        Location: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 476262] Verify "Dimension Set ID" for "Entry Type" Consumption in Production Journal.
        Initialize();

        // [GIVEN] Create two Dimensions with its Dimension Values.
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDimWithDimValue(DimensionValue2);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Update "Components at Location" in Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Components at Location", Location.Code);
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create a Default Dimension for Location.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension,
            Database::Location,
            Location.Code,
            DimensionValue."Dimension Code",
            DimensionValue.Code);

        // [GIVEN] Create Component and Produced Item.
        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateItem(ProducedItem);

        // [GIVEN] Create a Default Dimension for Produced Item.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension2,
            Database::Item,
            ProducedItem."No.",
            DimensionValue2."Dimension Code",
            DimensionValue2.Code);

        // [GIVEN] Create a Production BOM.
        CreateProductionBOM(ProducedItem, ComponentItem);

        // [GIVEN] Create a Production Order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            ProducedItem."No.",
            1);

        // [GIVEN] Update Location Code in Production Order.
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [WHEN] Refresh a Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Store Component Item No. and Dimension Set ID.
        LibraryVariableStorage.Enqueue(ComponentItem."No.");
        FindProdOrderLine(ProdOrderLine, ProductionOrder, ProducedItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [VERIFY] Verify "Dimension Set ID" for "Entry Type" Consumption in Production Journal.
        Assert.AreEqual(
            ProductionOrder."Dimension Set ID",
            LibraryVariableStorage.DequeueInteger(),
            StrSubstNo(
                ValueMustBeEqualErr,
                ProductionOrder.FieldCaption("Dimension Set ID"),
                ProductionOrder."Dimension Set ID"));
    end;

    [Test]
    procedure AssemblyOrderWithDimensionShouldPostWithoutError()
    var
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AssembledItem: Record Item;
        CompItem: Record Item;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyLine: Record "Posted Assembly Line";
    begin
        // [SCENARIO 478427] When posting an Assembly Order a Dimension error is shown for a missing Dimension although the Dimension value is specified in the header and lines
        Initialize();

        // [GIVEN] Create Comp Item
        CreateItem(CompItem);

        // [GIVEN] Create Assembled Item
        LibraryInventory.CreateItem(AssembledItem);
        CreateDefaultDimensionForItem(DefaultDimension, AssembledItem."No.");

        // [GIVEN] Create two Dimensions with its Dimension Values.
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create a Default Dimension for Location.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension2,
            Database::Location,
            Location.Code,
            DimensionValue."Dimension Code",
            DimensionValue.Code);

        // [GIVEN] Create an Item Journal Line to purchase inventory for assembly Item
        LibraryInventory.CreateItemJnlLine(
            ItemJournalLine,
            "Item Ledger Entry Type"::Purchase,
            WorkDate(),
            CompItem."No.",
            LibraryRandom.RandInt(10),
            Location.Code);

        // [GIVEN] Create Inventory Posting Setup for assembly Item  Inventory Posting Group & Location.
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, CompItem."Inventory Posting Group");
        InventoryPostingSetup."Inventory Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup.Modify();

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create an Assembly Order & Validate Dimension Set ID.
        CreateAssemblyOrderWithLocationCode(AssemblyHeader, AssemblyLine, AssembledItem, CompItem, Location);

        // [THEN] Post the created Assembly Order.
        Codeunit.Run(Codeunit::"Assembly-Post", AssemblyHeader);

        // [THEN] Find Posted Assembly Header.
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.FindFirst();

        // [THEN] Find Posted Assembly Line.
        PostedAssemblyLine.Get(PostedAssemblyHeader."No.", AssemblyLine."Line No.");

        // [VERIFY] Verify Dimension Set ID is same in Posted Assembly Line, and in the created Assembly Line.
        Assert.AreEqual(
            PostedAssemblyLine."Dimension Set ID",
            AssemblyLine."Dimension Set ID",
            StrSubstNo(
                ValueMustBeEqualErr,
                PostedAssemblyLine.FieldCaption("Dimension Set ID"),
                AssemblyLine."Dimension Set ID"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Production & Assembly Costing");
        // Lazy Setup.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Production & Assembly Costing");

        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Production & Assembly Costing");
    end;

    local procedure CreateItem(var Item: Record Item; UnitCost: Decimal; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; PostingDate: Date)
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalLineWithAppliesFrom(ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; AppliesFromEntry: Integer; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, EntryType, ItemNo, Qty, PostingDate);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Applies-from Entry", AppliesFromEntry);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalLineWithAppliesTo(ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; AppliesToEntry: Integer; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, EntryType, ItemNo, Qty, PostingDate);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalLineWithUnitCost(ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, EntryType, ItemNo, Qty, PostingDate);
        ItemJournalLine.Validate("Unit Amount", UnitCost);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateProdOrderComponentWithItem(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; QtyPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateProductionBOM(var ProdItem: Record Item; CompItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Modify(true);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure PostPurchasesItemJournalLines(ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);

        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 2.44, 6710, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 2.44, 6710, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 2.44, 6710, WorkDate());

        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 2.44, 6709, WorkDate());

        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 2.44, 6710, WorkDate());
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 2.44, 6710, WorkDate());

        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 1.63, 6710, WorkDate());

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostSalesItemJournalWithCostApplication(ItemNo: Code[20]; EntryNo: Integer; PostingDate: Date)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        CreateItemJournalLineWithAppliesTo(ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, ItemNo, 2.44, '', EntryNo, PostingDate);
        CreateItemJournalLineWithAppliesTo(ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, ItemNo, 2.44, '', EntryNo + 1, PostingDate);
        CreateItemJournalLineWithAppliesTo(ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, ItemNo, 1.63, '', EntryNo + 2, PostingDate);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostManyPurchasesAndSalesNoApplication(ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        I: Integer;
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        for I := 1 to 21 do
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 3.69, WorkDate());

        for I := 1 to 21 do
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 3.71, WorkDate());

        for I := 1 to 21 do
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, ItemNo, 3.69, WorkDate());

        for I := 1 to 12 do
            CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, ItemNo, 3.71, WorkDate());

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostPurchaseAndSaleItemJnlLines(ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 7 * 3.69, WorkDate());
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Purchase, ItemNo, 7 * 3.71, WorkDate());
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, ItemNo, 7 * 3.69, WorkDate());
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::Sale, ItemNo, 4 * 3.71, WorkDate());
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatchByTemplateType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
    end;

    local procedure SelectTransferJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatchByTemplateType(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
    end;

    local procedure SelectItemJournalBatchByTemplateType(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
    end;

    local procedure SetAverageCostSetup(AvgCostCalcType: Enum "Average Cost Calculation Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        LibraryInventory.UpdateAverageCostSettings(AvgCostCalcType, InventorySetup."Average Cost Period");
    end;

    local procedure VerifyItemEntriesCost(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; ActualCost: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Cost Amount (Actual)", ActualCost);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyInvtIsZero(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindSet();
        repeat
            ItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
            ItemLedgEntry.TestField("Cost Amount (Expected)", 0);
            ItemLedgEntry.TestField("Cost Amount (Actual)", 0);
        until ItemLedgEntry.Next() = 0;
    end;

    local procedure VerifyZeroActualCostRemains(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Cost Amount (Actual)");
        ValueEntry.TestField("Item Ledger Entry Quantity", 0);
        ValueEntry.TestField("Cost Amount (Actual)", 0);
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateDefaultDimensionForItem(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
    end;

    local procedure CreateAssemblyOrderWithLocationCode(
        var AssemblyHeader: Record "Assembly Header";
        var AssemblyLine: Record "Assembly Line";
        MainItem: Record Item;
        Item: Record Item;
        Location: Record Location)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), MainItem."No.", '', LibraryRandom.RandInt(0), '');
        AssemblyHeader.Validate("Location Code", Location.Code);
        AssemblyHeader.Validate("Shortcut Dimension 1 Code", '');
        AssemblyHeader.Modify(true);

        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader,
            AssemblyLine,
            "BOM Component Type"::Item,
            Item."No.",
            Item."Base Unit of Measure",
            LibraryRandom.RandInt(0),
            LibraryRandom.RandInt(0), Item.Description);
        AssemblyLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalModalPageHandlerForDimensionSetID(var ProductionJournal: TestPage "Production Journal")
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Item No.", LibraryVariableStorage.DequeueText());
        ItemJnlLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemJnlLine."Dimension Set ID");
    end;
}

