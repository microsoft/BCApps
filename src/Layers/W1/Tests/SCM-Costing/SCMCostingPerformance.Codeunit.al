codeunit 133504 "SCM Costing Performance"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Performance]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        NotLinearCCErr: Label 'Computational cost is not linear.';
        NotConstantCCErr: Label 'Computational cost must be constant.';
        ReceiptProcessing25To50Err: Label 'Receipt processing must increase from 25 to 50 pending entries. Visits: %1, %2.', Comment = '%1 = receipt processing count for 25 entries, %2 = receipt processing count for 50 entries';
        ReceiptProcessing50To100Err: Label 'Receipt processing must increase from 50 to 100 pending entries. Visits: %1, %2.', Comment = '%1 = receipt processing count for 50 entries, %2 = receipt processing count for 100 entries';
        ReceiptNotRevisitedErr: Label 'Old receipt %1 must be revisited.', Comment = '%1 = item ledger entry number';
        ObservedItemNo: Code[20];
        ReceiptVisits: Dictionary of [Integer, Integer];
        ReceiptProcessingCount: Integer;
        BufferedReceiptCount: Integer;
        ObservedItemPasses: Integer;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Costing Performance");

        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOAdjustingOptimisationForPurchaseOnceManySales()
    var
        DurationSmallNo: Integer;
        DurationLargeNo: Integer;
        SmallNoOfSales: Integer;
    begin
        // Workitem VSTF-301226
        if not CodeCoverageMgt.Running() then
            CodeCoverageMgt.StartApplicationCoverage();

        Initialize();
        SmallNoOfSales := LibraryRandom.RandIntInRange(2, 3);
        DurationSmallNo := PurchaseOnceManySales(SmallNoOfSales);
        DurationLargeNo := PurchaseOnceManySales(SmallNoOfSales * 4);

        if CodeCoverageMgt.Running() then
            CodeCoverageMgt.StopApplicationCoverage();

        // The adjusting should have the same duration.
        Assert.AreNearlyEqual(DurationSmallNo, DurationLargeNo, 0.2 * DurationSmallNo,
          StrSubstNo('Costing optimization of one purchase many sales broken (DurationSmallNo (%1) * 1.2  > DurationLargeNo (%2))',
            DurationSmallNo, DurationLargeNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalePurchSale_FIFO()
    begin
        Initialize();
        SalePurchSale("Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalePurchSale_Avg()
    begin
        Initialize();
        SalePurchSale("Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_PurchReturnShptAnd2Sales_FIFO()
    begin
        Initialize();
        PurchReturnShptAnd2Sales("Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_PurchReturnShptAnd2Sales_AvgFixedAppln()
    begin
        Initialize();
        PurchReturnShptAnd2Sales("Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_PurchReturnShptAnd2Sales_AvgNoAppln()
    begin
        Initialize();
        PurchReturnShptAnd2Sales("Costing Method"::Average, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_UndoReturnReceiptAnd2Sales_FIFO()
    begin
        Initialize();
        UndoReturnReceiptAnd2Sales("Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_UndoReturnReceiptAnd2Sales_AvgFixedAppln()
    begin
        Initialize();
        UndoReturnReceiptAnd2Sales("Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_UndoReturnReceiptAnd2Sales_AvgNoAppln()
    begin
        Initialize();
        UndoReturnReceiptAnd2Sales("Costing Method"::Average, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF268387()
    var
        Item: Record Item;
        LinesWithOneSKU: Integer;
        LinesWithTwoSKU: Integer;
        LinesWithThreeSKU: Integer;
    begin
        // Workitem VSTF-268387
        Initialize();
        if not CodeCoverageMgt.Running() then
            CodeCoverageMgt.StartApplicationCoverage();

        CreateItem(Item, "Costing Method"::FIFO);
        LinesWithOneSKU := PostItemJournalLineWithSKU(Item);
        LinesWithTwoSKU := PostItemJournalLineWithSKU(Item);
        LinesWithThreeSKU := PostItemJournalLineWithSKU(Item);

        if CodeCoverageMgt.Running() then
            CodeCoverageMgt.StopApplicationCoverage();

        // There should be the same code covered with and without SKU.
        Assert.AreEqual(2, LinesWithOneSKU, 'GetInvtSetup should only be hit twice.');
        Assert.AreEqual(1, LinesWithTwoSKU - LinesWithOneSKU, 'There should be the a difference of 1 hit per SKU. See bug 268387.');
        Assert.AreEqual(1, LinesWithThreeSKU - LinesWithTwoSKU, 'There should be the a difference of 1 hit per SKU. See bug 268387.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS94483_ManyConsumptionsAppliedToOneInbound()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemQty: Integer;
        NoOfConsumtionsSmall: Integer;
        NoOfConsumtionsMedium: Integer;
        NoOfConsumtionsLarge: Integer;
        NoOfHitsSmall: Integer;
        NoOfHitsMedium: Integer;
        NoOfHitsLarge: Integer;
    begin
        ItemQty := 1000;
        NoOfConsumtionsSmall := 10;
        NoOfConsumtionsMedium := 20;
        NoOfConsumtionsLarge := 50;

        CreateProductionOrder(ProdOrderLine, ItemQty);

        if not CodeCoverageMgt.Running() then
            CodeCoverageMgt.StartApplicationCoverage();
        NoOfHitsSmall := PostPurchWithConsumptionAndAdjust(ProdOrderLine, ItemQty, NoOfConsumtionsSmall);
        NoOfHitsMedium := PostPurchWithConsumptionAndAdjust(ProdOrderLine, ItemQty, NoOfConsumtionsMedium);
        NoOfHitsLarge := PostPurchWithConsumptionAndAdjust(ProdOrderLine, ItemQty, NoOfConsumtionsLarge);
        if CodeCoverageMgt.Running() then
            CodeCoverageMgt.StopApplicationCoverage();

        VerifyLinearComputationalComplexity(NoOfConsumtionsSmall, NoOfConsumtionsMedium, NoOfConsumtionsLarge,
          NoOfHitsSmall, NoOfHitsMedium, NoOfHitsLarge);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateUnitCostSKUNotCalledWhenNotAdjustmentPosted()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Location: array[3] of Record Location;
        SKU: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        I: Integer;
        NoOfHitsSmall: Integer;
        NoOfHitsLarge: Integer;
    begin
        // [FEATURE] [Stockkeeping Unit]
        // [SCENARIO 263791] "Adjust Cost - Item Entries" job does not recalculate SKU unit cost when no adjustment entries were posted

        Initialize();

        // [GIVEN] "Average Cost Calc. Type" is set to "Item & Location & Variant" to track cost by SKU
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);

        // [GIVEN] Item "I" with a stockkeeping unit "SKU1" on location "L1"
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location[1].Code, Item."No.", '');

        // [GIVEN] Post purcashe entry for SKU1 and run cost adjustment
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location[1].Code, '', 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CodeCoverageMgt.StartApplicationCoverage();
        NoOfHitsSmall := CodeCoverageMgt.ApplicationHits();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        NoOfHitsSmall := CodeCoverageMgt.ApplicationHits() - NoOfHitsSmall;

        // [GIVEN] Create two more SKU's for item "I"
        LibraryWarehouse.CreateLocation(Location[2]);
        LibraryWarehouse.CreateLocation(Location[3]);
        for I := 2 to ArrayLen(Location) do
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location[I].Code, Item."No.", '');

        // [GIVEN] Post purchase entry for SKU1
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location[1].Code, '', 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run cost adjustment
        NoOfHitsLarge := CodeCoverageMgt.ApplicationHits();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        NoOfHitsLarge := CodeCoverageMgt.ApplicationHits() - NoOfHitsLarge;
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] Cost adjustment routine demonstrates the same performance for 1 SKU and 3 SKUs
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHitsSmall, NoOfHitsLarge), NotConstantCCErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UninvoicedShipmentsKeep100ReceiptsPendingAcrossRuns()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReceiptEntryNos: List of [Integer];
        ProcessingCounts: array[3] of Integer;
        BufferedCount: Integer;
        RunNo: Integer;
        ValueEntryCount: Integer;
    begin
        // [SCENARIO] A FIFO item has 100 invoiced purchase receipts, each fully applied to a shipped but uninvoiced sales line.
        // Adjustment leaves these receipts marked "Applied Entry to Adjust" because sales invoicing is still outstanding.
        // Before each of three later runs, a new positive adjustment makes the item eligible for processing without editing flags.
        // Verify that every original receipt is visited again, remains buffered and marked before and after each run,
        // and retains its correct cost without additional value entries. This characterizes legitimate deferred work, not a defect.
        InitializePendingReceiptScenario(Item);
        PostReceiptAndShipmentBatch(Item, 100, SalesHeader, ReceiptEntryNos);
        RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCounts[1], BufferedCount);
        VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, true);
        Assert.AreEqual(100, BufferedCount, 'All receipts awaiting sales invoicing must remain buffered.');

        for RunNo := 1 to ArrayLen(ProcessingCounts) do begin
            // New posting selects the item naturally; no existing entry or item flags are edited.
            PostFreshEntryToTriggerAdjustment(Item);
            VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, true);
            ValueEntryCount := CountItemValueEntries(Item."No.");

            RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCounts[RunNo], BufferedCount);

            VerifyEveryReceiptVisited(ReceiptEntryNos);
            Assert.IsTrue(ProcessingCounts[RunNo] >= 100, 'Each later run must revisit the 100 old receipts.');
            Assert.AreEqual(100, BufferedCount, 'The same receipts must remain buffered after each later run.');
            VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, true);
            Assert.AreEqual(ValueEntryCount, CountItemValueEntries(Item."No."), 'Revisiting unchanged pending receipts must not create value entries.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PendingReceiptProcessingGrowsWith25Then50Then100Entries()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReceiptEntryNos: List of [Integer];
        BatchSizes: array[3] of Integer;
        ProcessingCounts: array[3] of Integer;
        BufferedCount: Integer;
        Stage: Integer;
        ValueEntryCount: Integer;
    begin
        // [SCENARIO] Invoiced receipts applied to uninvoiced shipments accumulate for one FIFO item in batches of 25, 25 and 50.
        // At each backlog size (25, 50 and 100), a single new positive adjustment triggers another run without changing old applications.
        // Verify that all historical receipts are revisited and remain pending, while their costs and the value-entry count stay unchanged.
        // Compare receipt-processing counts, not elapsed time, to demonstrate increasing repeated work as unfinished invoicing accumulates.
        InitializePendingReceiptScenario(Item);
        BatchSizes[1] := 25;
        BatchSizes[2] := 25;
        BatchSizes[3] := 50;

        for Stage := 1 to ArrayLen(BatchSizes) do begin
            PostReceiptAndShipmentBatch(Item, BatchSizes[Stage], SalesHeader, ReceiptEntryNos);
            RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCounts[Stage], BufferedCount);
            VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, true);

            PostFreshEntryToTriggerAdjustment(Item);
            ValueEntryCount := CountItemValueEntries(Item."No.");
            RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCounts[Stage], BufferedCount);

            VerifyEveryReceiptVisited(ReceiptEntryNos);
            Assert.AreEqual(ReceiptEntryNos.Count(), BufferedCount, 'The accumulated receipt backlog must survive each run.');
            VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, true);
            Assert.AreEqual(ValueEntryCount, CountItemValueEntries(Item."No."), 'Additional processing must not change already correct costs.');
        end;

        Assert.IsTrue(
            ProcessingCounts[2] > ProcessingCounts[1],
            StrSubstNo(ReceiptProcessing25To50Err, ProcessingCounts[1], ProcessingCounts[2]));
        Assert.IsTrue(
            ProcessingCounts[3] > ProcessingCounts[2],
            StrSubstNo(ReceiptProcessing50To100Err, ProcessingCounts[2], ProcessingCounts[3]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Invoicing100ShipmentsStopsRepeatedReceiptProcessing()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReceiptEntryNos: List of [Integer];
        ProcessingCount: Integer;
        BufferedCount: Integer;
        RunNo: Integer;
        ValueEntryCount: Integer;
    begin
        // [SCENARIO] Establish 100 invoiced receipts applied to uninvoiced shipments and confirm they remain pending on a later run.
        // Invoice all shipments and adjust costs: the receipts must be processed, leave the pending buffer and have their flags cleared,
        // with actual receipt/sales costs of 10/-10 per pair and zero expected costs.
        // Trigger three more runs using new positive adjustments and verify zero visits to the original receipts, no restored flags
        // and no additional adjustment value entries. This distinguishes resolved work from legitimately deferred invoicing.
        InitializePendingReceiptScenario(Item);
        PostReceiptAndShipmentBatch(Item, 100, SalesHeader, ReceiptEntryNos);
        RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCount, BufferedCount);
        VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, true);
        Assert.AreEqual(100, BufferedCount, 'The control must first establish a real pending backlog.');

        PostFreshEntryToTriggerAdjustment(Item);
        RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCount, BufferedCount);
        VerifyEveryReceiptVisited(ReceiptEntryNos);
        VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, true);

        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCount, BufferedCount);
        VerifyEveryReceiptVisited(ReceiptEntryNos);
        VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, false);
        Assert.AreEqual(0, BufferedCount, 'Invoicing must resolve all tracked receipt deferrals.');

        for RunNo := 1 to 3 do begin
            PostFreshEntryToTriggerAdjustment(Item);
            ValueEntryCount := CountItemValueEntries(Item."No.");
            RunObservedReceiptAdjustment(Item."No.", ReceiptEntryNos, ProcessingCount, BufferedCount);

            Assert.AreEqual(0, ProcessingCount, 'Later postings must not cause completed receipts to be processed again.');
            Assert.AreEqual(0, BufferedCount, 'Completed receipts must not accumulate in a later buffer.');
            VerifyReceiptBacklog(Item."No.", ReceiptEntryNos, false);
            Assert.AreEqual(ValueEntryCount, CountItemValueEntries(Item."No."), 'Completed receipt costs must remain unchanged.');
        end;
    end;

    local procedure InitializePendingReceiptScenario(var Item: Record Item)
    begin
        Initialize();
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAutomaticCostPosting(false);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 10);
    end;

    local procedure PostReceiptAndShipmentBatch(Item: Record Item; EntryCount: Integer; var SalesHeader: Record "Sales Header"; var ReceiptEntryNos: List of [Integer])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PreviousEntryNo: Integer;
        NewReceiptCount: Integer;
        LineNo: Integer;
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetLoadFields("Entry No.");
        if ItemLedgerEntry.FindLast() then
            PreviousEntryNo := ItemLedgerEntry."Entry No.";

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for LineNo := 1 to EntryCount do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
            PurchaseLine.Validate("Direct Unit Cost", 10);
            PurchaseLine.Modify(true);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        ItemLedgerEntry.SetFilter("Entry No.", '>%1', PreviousEntryNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.FindSet();
        repeat
            ReceiptEntryNos.Add(ItemLedgerEntry."Entry No.");
            NewReceiptCount += 1;
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
            SalesLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
            SalesLine.Validate("Unit Price", 20);
            SalesLine.Modify(true);
        until ItemLedgerEntry.Next() = 0;
        Assert.AreEqual(EntryCount, NewReceiptCount, 'Each purchase line must create a distinct tracked receipt.');
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure PostFreshEntryToTriggerAdjustment(var Item: Record Item)
    begin
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, WorkDate(), 10);
        Item.Get(Item."No.");
        Item.TestField("Cost is Adjusted", false);
    end;

    local procedure RunObservedReceiptAdjustment(ItemNo: Code[20]; ReceiptEntryNos: List of [Integer]; var ProcessingCount: Integer; var BufferedCount: Integer)
    var
        Item: Record Item;
        EntryNo: Integer;
    begin
        ObservedItemNo := ItemNo;
        Clear(ReceiptVisits);
        ReceiptProcessingCount := 0;
        BufferedReceiptCount := 0;
        ObservedItemPasses := 0;
        foreach EntryNo in ReceiptEntryNos do
            ReceiptVisits.Add(EntryNo, 0);

        BindSubscription(this);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        UnbindSubscription(this);

        Assert.IsTrue(ObservedItemPasses > 0, 'The item must actually be processed, not skipped as already adjusted.');
        Item.Get(ItemNo);
        Item.TestField("Cost is Adjusted", true);
        ProcessingCount := ReceiptProcessingCount;
        BufferedCount := BufferedReceiptCount;
        Clear(ObservedItemNo);
    end;

    local procedure VerifyEveryReceiptVisited(ReceiptEntryNos: List of [Integer])
    var
        EntryNo: Integer;
    begin
        foreach EntryNo in ReceiptEntryNos do
            Assert.IsTrue(ReceiptVisits.Get(EntryNo) > 0, StrSubstNo(ReceiptNotRevisitedErr, EntryNo));
    end;

    local procedure VerifyReceiptBacklog(ItemNo: Code[20]; ReceiptEntryNos: List of [Integer]; Pending: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
    begin
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        foreach EntryNo in ReceiptEntryNos do begin
            ItemLedgerEntry.Get(EntryNo);
            ItemLedgerEntry.TestField("Item No.", ItemNo);
            ItemLedgerEntry.TestField(Quantity, 1);
            ItemLedgerEntry.TestField("Remaining Quantity", 0);
            ItemLedgerEntry.TestField("Completely Invoiced", true);
            ItemLedgerEntry.TestField("Applied Entry to Adjust", Pending);
            ItemLedgerEntry.TestField("Cost Amount (Actual)", 10);
            ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
        end;

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        Assert.RecordCount(ItemLedgerEntry, ReceiptEntryNos.Count());
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField(Quantity, -1);
            ItemLedgerEntry.TestField("Completely Invoiced", not Pending);
            if Pending then begin
                ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
                ItemLedgerEntry.TestField("Cost Amount (Expected)", -10);
            end else begin
                ItemLedgerEntry.TestField("Cost Amount (Actual)", -10);
                ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
            end;
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CountItemValueEntries(ItemNo: Code[20]): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        exit(ValueEntry.Count());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnAdjustItemAppliedCostForItemLedgerEntry, '', false, false)]
    local procedure CountTrackedReceiptProcessing(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        Visits: Integer;
    begin
        if ItemLedgEntry."Item No." <> ObservedItemNo then
            exit;
        if ReceiptVisits.Get(ItemLedgEntry."Entry No.", Visits) then begin
            ReceiptVisits.Set(ItemLedgEntry."Entry No.", Visits + 1);
            ReceiptProcessingCount += 1;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", OnBeforeUpdateItemUnitCost2, '', false, false)]
    local procedure CountTrackedBufferedReceipts(var Item: Record Item; var ItemLedgEntryToAdjust: Dictionary of [Code[20], List of [Integer]])
    var
        BufferedEntries: List of [Integer];
        EntryNo: Integer;
    begin
        if Item."No." <> ObservedItemNo then
            exit;
        ObservedItemPasses += 1;
        BufferedReceiptCount := 0;
        if ItemLedgEntryToAdjust.Get(Item."No.", BufferedEntries) then
            foreach EntryNo in BufferedEntries do
                if ReceiptVisits.ContainsKey(EntryNo) then
                    BufferedReceiptCount += 1;
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure PurchaseOnceManySales(PurchaseQty: Integer) NoOfLinesHIt: Integer
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        Loc: Code[10];
        Variant: Code[10];
        jj: Decimal;
        Day1: Date;
    begin
        CreateItem(Item, Item."Costing Method"::FIFO);
        Day1 := WorkDate();
        Loc := '';
        Variant := '';
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase, Item, '', '', '', PurchaseQty, Day1, 2);

        ItemLedgEntry.FindLast();

        for jj := 1 to PurchaseQty - 1 do begin
            LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch, Item, Loc, Variant, Day1, ItemJournalLine."Entry Type"::Sale, 1, 0.007);
            ItemJournalLine.Modify(true);

            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

            if jj = PurchaseQty - 1 then
                NoOfLinesHIt := CodeCoverageMgt.ApplicationHits();
            LibraryCosting.AdjustCostItemEntries(Item."No.", '');
            if jj = PurchaseQty - 1 then
                NoOfLinesHIt := CodeCoverageMgt.ApplicationHits() - NoOfLinesHIt;

            ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgEntry."Entry No.");
            ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<> %1', 0);
            ItemApplnEntry.SetRange("Outbound Entry is Updated", false);
            Assert.IsTrue(not ItemApplnEntry.FindFirst(),
              StrSubstNo('Item Application Entries with inbound %1 and "Outbound Entry is Updated" == FALSE NOT EMPTY',
                ItemLedgEntry."Entry No."));
        end;
    end;

    local procedure PostItemJournalLineWithSKU(Item: Record Item) NoOfHits: Integer
    var
        CodeCover: Record "Code Coverage";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);
        NoOfHits := GetCodeCoverageForObject(CodeCover."Object Type"::Codeunit, 5804, 'GetInvtSetup');
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase, Item, '', '', '',
          LibraryRandom.RandDec(100, 2), WorkDate(), LibraryRandom.RandDec(100, 2));
        NoOfHits := GetCodeCoverageForObject(CodeCover."Object Type"::Codeunit, 5804, 'GetInvtSetup') - NoOfHits;
    end;

    local procedure PostPurchWithConsumptionAndAdjust(ProdOrderLine: Record "Prod. Order Line"; Quantity: Decimal; NoOfConsumptions: Integer): Integer
    var
        Item: Record Item;
        NoOfHits: Integer;
        I: Integer;
    begin
        Item.Get(ProdOrderLine."Item No.");
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Quantity, WorkDate(), Item."Unit Cost");
        for I := 1 to NoOfConsumptions do
            LibraryManufacturing.POSTConsumption(
              ProdOrderLine, Item, '', '', Quantity / NoOfConsumptions, WorkDate(), Item."Unit Cost" + LibraryRandom.RandDecInRange(20, 30, 2));

        NoOfHits := CodeCoverageMgt.ApplicationHits();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        exit(CodeCoverageMgt.ApplicationHits() - NoOfHits);
    end;

    local procedure CreateProductionOrder(var ProdOrderLine: Record "Prod. Order Line"; Quantity: Decimal)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        CreateItem(Item, Item."Costing Method"::Average);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 1;
        ProdOrderLine."Item No." := Item."No.";
        ProdOrderLine.Insert(true);
    end;

    local procedure SalePurchSale(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesHeader: Record "Sales Header";
        FirstSaleItemApplnEntry: Record "Item Application Entry";
        SecondSaleItemApplnEntry: Record "Item Application Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        SetupItemQtyCost(Item, Qty1, Qty2, UnitCost, UnitPrice, CostingMethod);

        // Create and Post Sales
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty1, WorkDate(), UnitPrice, true, true);

        // Create and Post Purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty1 + Qty2, WorkDate(), UnitCost, true, true);
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindLast();
        FirstSaleItemApplnEntry.Find('+');
        FirstSaleItemApplnEntry.Next(-1);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);

        // Create and post item charge
        CreateandPostItemCharge(PurchRcptLine);
        // Verify
        VerifyApplnEntry(FirstSaleItemApplnEntry, false, CostingMethod = Item."Costing Method"::Average);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);

        // Create and Post Second Sales
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty2, WorkDate(), UnitPrice, true, true);
        SecondSaleItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);
        VerifyApplnEntry(SecondSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);
    end;

    local procedure PurchReturnShptAnd2Sales(CostingMethod: Enum "Costing Method"; AvgCostNoApplication: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ReturnPurchaseHeader: Record "Purchase Header";
        ReturnPurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchReturnItemApplnEntry: Record "Item Application Entry";
        FirstSaleItemApplnEntry: Record "Item Application Entry";
        SecondSaleItemApplnEntry: Record "Item Application Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        SetupItemQtyCost(Item, Qty1, Qty2, UnitCost, UnitPrice, CostingMethod);

        // Create and Post Purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty1 + Qty2, WorkDate(), UnitCost, true, true);
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindLast();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();

        // Create and Post Return Order
        LibraryPurchase.CreatePurchaseReturnOrder(ReturnPurchaseHeader, ReturnPurchaseLine, Item, '', '', Qty1, WorkDate(), UnitCost);
        ReturnPurchaseLine.SetRange("Document Type", ReturnPurchaseLine."Document Type");
        ReturnPurchaseLine.SetRange("Document No.", ReturnPurchaseLine."Document No.");
        ReturnPurchaseLine.FindFirst();
        ReturnPurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReturnPurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(ReturnPurchaseHeader, true, true);
        PurchReturnItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);

        // Create and Post Sales
        PostSalesOrder(Item, Qty2 / 2, UnitPrice, not AvgCostNoApplication, ItemLedgerEntry."Entry No.");
        FirstSaleItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);

        // Create and post item charge
        CreateandPostItemCharge(PurchRcptLine);
        // Verify
        VerifyApplnEntry(PurchReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, false, AvgCostNoApplication);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);

        // Create and Post Second Sales
        PostSalesOrder(Item, Qty2 / 2, UnitPrice, not AvgCostNoApplication, ItemLedgerEntry."Entry No.");
        SecondSaleItemApplnEntry.FindLast();
        // Verify
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, false, AvgCostNoApplication);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, true, AvgCostNoApplication);
    end;

    local procedure UndoReturnReceiptAnd2Sales(CostingMethod: Enum "Costing Method"; AvgCostNoApplication: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnSalesHeader: Record "Sales Header";
        ReturnSalesLine: Record "Sales Line";
        PurchItemLedgerEntry: Record "Item Ledger Entry";
        SalesItemLedgerEntry: Record "Item Ledger Entry";
        ReturnRcptLine: Record "Return Receipt Line";
        SalesReturnItemApplnEntry: Record "Item Application Entry";
        UndoSalesReturnItemApplnEntry: Record "Item Application Entry";
        SecondSaleItemApplnEntry: Record "Item Application Entry";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        Qty1: Decimal;
        Qty2: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        SetupItemQtyCost(Item, Qty1, Qty2, UnitCost, UnitPrice, CostingMethod);

        // Create and Post Purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty1 + Qty2, WorkDate(), UnitCost, true, true);
        PurchItemLedgerEntry.SetRange("Item No.", Item."No.");
        PurchItemLedgerEntry.FindLast();
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindLast();

        // Create and Post Sales
        PostSalesOrder(Item, Qty1, UnitPrice, not AvgCostNoApplication, PurchItemLedgerEntry."Entry No.");
        SalesItemLedgerEntry.SetRange("Item No.", Item."No.");
        SalesItemLedgerEntry.FindLast();

        // Create and Ship Sales Return Order
        LibrarySales.CreateSalesReturnOrder(ReturnSalesHeader, ReturnSalesLine, Item, '', '', Qty1, WorkDate(), UnitCost, UnitPrice);
        ReturnSalesLine.SetRange("Document Type", ReturnSalesLine."Document Type");
        ReturnSalesLine.SetRange("Document No.", ReturnSalesLine."Document No.");
        ReturnSalesLine.FindFirst();
        ReturnSalesLine.Validate("Appl.-from Item Entry", SalesItemLedgerEntry."Entry No.");
        ReturnSalesLine.Modify(true);
        LibrarySales.PostSalesDocument(ReturnSalesHeader, true, false);
        SalesReturnItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);

        // Undo Return Receipt
        ReturnRcptLine.SetRange("No.", Item."No.");
        ReturnRcptLine.FindLast();
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);
        UndoSalesReturnItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);

        // Create and post item charge
        CreateandPostItemCharge(PurchRcptLine);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);

        // Create and Post Second Sales
        PostSalesOrder(Item, Qty2, UnitPrice, not AvgCostNoApplication, PurchItemLedgerEntry."Entry No.");
        SecondSaleItemApplnEntry.FindLast();
        // Verify
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, false, AvgCostNoApplication);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, true, AvgCostNoApplication);
    end;

    local procedure SetupItemQtyCost(var Item: Record Item; var Qty1: Decimal; var Qty2: Decimal; var UnitCost: Decimal; var UnitPrice: Decimal; CostingMethod: Enum "Costing Method")
    begin
        Qty1 := LibraryRandom.RandDecInRange(1, 100, 2);
        Qty2 := LibraryRandom.RandDecInRange(1, 100, 2);
        UnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        UnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        LibraryInventory.CreateItemSimple(Item, CostingMethod, UnitCost);
    end;

    local procedure CreateandPostItemCharge(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.");
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchHeader, PurchRcptLine, PurchRcptLine.Quantity, LibraryRandom.RandDecInRange(1, 10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure PostSalesOrder(var Item: Record Item; Qty: Decimal; UnitPrice: Decimal; PostWithApplyTo: Boolean; ApplToEntry: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        if PostWithApplyTo then begin
            LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', 0D);
            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Validate("Appl.-to Item Entry", ApplToEntry);
            SalesLine.Modify();
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end else
            LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty, WorkDate(), UnitPrice, true, true);
    end;

    local procedure VerifyApplnEntry(var ItemApplnEntry: Record "Item Application Entry"; ExpectedOutbndUpdatedValue: Boolean; AvgCostNoApplication: Boolean)
    begin
        if AvgCostNoApplication then
            exit;

        ItemApplnEntry.Find('=');
        ItemApplnEntry.TestField("Outbound Entry is Updated", ExpectedOutbndUpdatedValue);
    end;

    local procedure VerifyLinearComputationalComplexity(x1: Decimal; x2: Decimal; x3: Integer; fx1: Decimal; fx2: Decimal; fx3: Decimal)
    begin
        Assert.IsTrue(LibraryCalcComplexity.IsLinear(x1, x2, x3, fx1, fx2, fx3), NotLinearCCErr);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; Line: Text) NoOfHits: Integer
    var
        CodeCover: Record "Code Coverage";
    begin
        CodeCoverageMgt.Refresh();
        CodeCover.SetRange("Line Type", CodeCover."Line Type"::Code);
        CodeCover.SetRange("Object Type", ObjectType);
        CodeCover.SetRange("Object ID", ObjectID);
        CodeCover.SetFilter("No. of Hits", '>%1', 0);
        CodeCover.SetFilter(Line, '@*' + Line + '*');
        if CodeCover.FindSet() then
            repeat
                NoOfHits += CodeCover."No. of Hits";
            until CodeCover.Next() = 0;
    end;
}
