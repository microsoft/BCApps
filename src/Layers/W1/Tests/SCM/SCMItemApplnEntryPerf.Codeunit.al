// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 137917 "SCM Item Appln. Entry Perf"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Performance] [Item Application Entry] [CheckIsCyclicalLoop]
        IsInitialized := false;
    end;

    var
        CodeCoverage: Record "Code Coverage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        IsInitialized: Boolean;
        TriggerReentry: Boolean;
        ReentryGuard: Boolean;
        UnexpectedHitCountErr: Label 'Hit count for %1 exceeds expected bound: got %2, expected <= %3.', Comment = '%1 = function name, %2 = actual hits, %3 = expected upper bound';
        NotLinearErr: Label 'Hit count of %1 is not linear in N. N1=%2:%3, N2=%4:%5, N3=%6:%7.', Comment = '%1 = proc name, %2, %3,%4, %5, %6, %7 = sizes and hit counts';
        ChainTooShortErr: Label 'G3: chain must contain at least %1 consumption entries, got %2.', Comment = '%1 = expected min count, %2 = actual count';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Item Appln. Entry Perf");
        CodeCoverageMgt.StopApplicationCoverage();
        LibraryVariableStorage.Clear();
        TriggerReentry := false;
        ReentryGuard := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Item Appln. Entry Perf");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Item Appln. Entry Perf");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CycleDetectedBetweenP1OutputAndP2Consumption()
    var
        Item: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProdOrderLine1: Record "Prod. Order Line";
        ProdOrderLine2: Record "Prod. Order Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Manufacturing] [Cyclical Loop] [Correctness]
        // [SCENARIO 626924] When P2's consumption has already been applied to P1's output
        // (FIFO auto-apply), CheckIsCyclicalLoop(Check = C_P2, From = O_P1) must return true
        // because the forward edge O_P1 -> C_P2 exists in the application graph. Guards against
        // the memoization silently masking cycle detection.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Production order P1 producing item, with output posted
        Qty := LibraryRandom.RandIntInRange(2, 5);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder1, ProductionOrder1.Status::Released, ProductionOrder1."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder1, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine1, ProductionOrder1, Item."No.");
        LibraryManufacturing.PostOutput(ProdOrderLine1, Qty, WorkDate(), Item."Unit Cost");

        // [GIVEN] Production order P2 consuming item (auto-applies to P1's output)
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder2, ProductionOrder2.Status::Released, ProductionOrder2."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder2, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item."No.");
        LibraryManufacturing.PostConsumption(ProdOrderLine2, Item, '', '', Qty, WorkDate(), Item."Unit Cost");

        // [GIVEN] Find the two ILEs
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order No.", ProductionOrder1."No.");
        OutputItemLedgerEntry.FindFirst();

        ConsumptionItemLedgerEntry.SetRange("Item No.", Item."No.");
        ConsumptionItemLedgerEntry.SetRange("Entry Type", ConsumptionItemLedgerEntry."Entry Type"::Consumption);
        ConsumptionItemLedgerEntry.SetRange("Order No.", ProductionOrder2."No.");
        ConsumptionItemLedgerEntry.FindFirst();

        // [WHEN] Starting at P1's output, walk forward looking for P2's consumption
        // [THEN] Forward edge (created by the auto-apply) is detected as a loop
        Assert.IsTrue(
          ItemApplicationEntry.CheckIsCyclicalLoop(ConsumptionItemLedgerEntry, OutputItemLedgerEntry),
          'G1: forward edge from P1 output to P2 consumption must be detected by CheckIsCyclicalLoop.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIsCyclicalLoopRespectsDirectionAsymmetry()
    var
        Item: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProdOrderLine1: Record "Prod. Order Line";
        ProdOrderLine2: Record "Prod. Order Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Manufacturing] [Cyclical Loop] [Correctness]
        // [SCENARIO 626924] Same fixture as G1. Walking forward from C_P2 does NOT reach O_P1
        // because no forward edge exists in that direction ΓÇö the application is O_P1 -> C_P2, not
        // the reverse. A cache that conflated directions would risk flipping this answer. Guards
        // the per-direction cache-keying requirement called out in spec ┬º4.2.
        Initialize();
        LibraryInventory.CreateItem(Item);

        Qty := LibraryRandom.RandIntInRange(2, 5);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder1, ProductionOrder1.Status::Released, ProductionOrder1."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder1, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine1, ProductionOrder1, Item."No.");
        LibraryManufacturing.PostOutput(ProdOrderLine1, Qty, WorkDate(), Item."Unit Cost");

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder2, ProductionOrder2.Status::Released, ProductionOrder2."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder2, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item."No.");
        LibraryManufacturing.PostConsumption(ProdOrderLine2, Item, '', '', Qty, WorkDate(), Item."Unit Cost");

        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order No.", ProductionOrder1."No.");
        OutputItemLedgerEntry.FindFirst();

        ConsumptionItemLedgerEntry.SetRange("Item No.", Item."No.");
        ConsumptionItemLedgerEntry.SetRange("Entry Type", ConsumptionItemLedgerEntry."Entry Type"::Consumption);
        ConsumptionItemLedgerEntry.SetRange("Order No.", ProductionOrder2."No.");
        ConsumptionItemLedgerEntry.FindFirst();

        // [WHEN] Walking forward from P2 consumption, looking for P1 output
        // [THEN] Not reachable in this direction ΓÇö assertion is FALSE
        Assert.IsFalse(
          ItemApplicationEntry.CheckIsCyclicalLoop(OutputItemLedgerEntry, ConsumptionItemLedgerEntry),
          'G2: walking forward from P2 consumption must NOT reach P1 output.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAdjustmentChainCompleteAfterSiblingOutputMemoization()
    var
        Item: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        StartItemLedgerEntry: Record "Item Ledger Entry";
        TempChainItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemApplicationEntry: Record "Item Application Entry";
        ChainCountFirst: Integer;
        ChainCountSecond: Integer;
        NoOfOutputs: Integer;
    begin
        // [FEATURE] [Cost Adjustment] [GetVisitedEntries] [Correctness]
        // [SCENARIO 626924] Sibling outputs of P1 feed into P2; GetVisitedEntries must return
        // the full reachable chain even after memoization short-circuits sibling walks. Guards the
        // design rule in spec ┬º4.3 that the inner cache gate is placed AFTER the TrackChain block.
        Initialize();
        NoOfOutputs := 3;
        CreatePairedProdOrders(Item, ProductionOrder1, ProductionOrder2, NoOfOutputs);

        StartItemLedgerEntry.SetRange("Item No.", Item."No.");
        StartItemLedgerEntry.SetRange("Entry Type", StartItemLedgerEntry."Entry Type"::Output);
        StartItemLedgerEntry.SetRange("Order No.", ProductionOrder1."No.");
        StartItemLedgerEntry.FindFirst();

        // [WHEN] First walk
        ItemApplicationEntry.GetVisitedEntries(StartItemLedgerEntry, TempChainItemLedgerEntry, true);
        ChainCountFirst := TempChainItemLedgerEntry.Count();

        // [THEN] Chain contains at least one reachable ILE ΓÇö the consumption that the first P1 output
        // was applied to. (Walker can't extend further because P2 produces no outputs in this fixture.)
        Assert.IsTrue(
          ChainCountFirst >= 1,
          StrSubstNo(ChainTooShortErr, 1, ChainCountFirst));

        // [WHEN] Second walk (exercises any cross-call state issues; stability is the real G3 guard ΓÇö
        // if the inner-gate cache lookup were placed before the TrackChain block, the second call's
        // chain would be empty)
        Clear(TempChainItemLedgerEntry);
        ItemApplicationEntry.GetVisitedEntries(StartItemLedgerEntry, TempChainItemLedgerEntry, true);
        ChainCountSecond := TempChainItemLedgerEntry.Count();

        // [THEN] Chain size stable
        Assert.AreEqual(
          ChainCountFirst, ChainCountSecond,
          'G3: chain size must be stable across repeated calls.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReentrancyDoesNotCorruptOuterWalk()
    var
        Item: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProdOrderLine1: Record "Prod. Order Line";
        ProdOrderLine2: Record "Prod. Order Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        ConsumptionItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        ReentrySubscriber: Codeunit "SCM Item Appln. Entry Perf";
        Qty: Integer;
        AnswerNoReentry: Boolean;
        AnswerWithReentry: Boolean;
    begin
        // [FEATURE] [Cyclical Loop] [Reentrancy] [Correctness]
        // [SCENARIO 626924] An event subscriber that triggers a nested CheckIsCyclicalLoop
        // call must not corrupt the outer walk's state. Because this codeunit has
        // EventSubscriberInstance = Manual, the subscriber only fires on the explicitly bound
        // instance ΓÇö this test binds a fresh local instance and primes its TriggerReentry flag.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Qty := 3;

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder1, ProductionOrder1.Status::Released, ProductionOrder1."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder1, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine1, ProductionOrder1, Item."No.");
        LibraryManufacturing.PostOutput(ProdOrderLine1, Qty, WorkDate(), Item."Unit Cost");

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder2, ProductionOrder2.Status::Released, ProductionOrder2."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder2, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item."No.");
        LibraryManufacturing.PostConsumption(ProdOrderLine2, Item, '', '', Qty, WorkDate(), Item."Unit Cost");

        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order No.", ProductionOrder1."No.");
        OutputItemLedgerEntry.FindFirst();

        ConsumptionItemLedgerEntry.SetRange("Item No.", Item."No.");
        ConsumptionItemLedgerEntry.SetRange("Entry Type", ConsumptionItemLedgerEntry."Entry Type"::Consumption);
        ConsumptionItemLedgerEntry.SetRange("Order No.", ProductionOrder2."No.");
        ConsumptionItemLedgerEntry.FindFirst();

        // [WHEN] Baseline call ΓÇö no subscriber bound
        AnswerNoReentry := ItemApplicationEntry.CheckIsCyclicalLoop(OutputItemLedgerEntry, ConsumptionItemLedgerEntry);

        // [WHEN] Reentrant call ΓÇö bind subscriber instance and prime its trigger flag, so the
        // OnCheckIsCyclicalLoopOnBeforeCheckCyclicForwardToAppliedInbounds event fires a nested
        // CheckIsCyclicalLoop call from within the outer walk
        ReentrySubscriber.SetTriggerReentry(true);
        BindSubscription(ReentrySubscriber);
        AnswerWithReentry := ItemApplicationEntry.CheckIsCyclicalLoop(OutputItemLedgerEntry, ConsumptionItemLedgerEntry);
        UnbindSubscription(ReentrySubscriber);

        // [THEN] Same answer
        Assert.AreEqual(
          AnswerNoReentry, AnswerWithReentry,
          'Reentrancy: answer must be identical with and without nested CheckIsCyclicalLoop.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SiblingOutputsShareP2Subgraph()
    var
        Size: array[3] of Integer;
        Hits: array[3] of Integer;
    begin
        // [FEATURE] [Cyclical Loop] [Performance] [Memoization]
        // [SCENARIO 626924] Fixture: P1 has 2N outputs of Item1 (N consumed by P2, N remain open).
        // P2 consumes N of Item1 AND produces N outputs of Item2. Post ONE P1 consumption of Item1;
        // it applies FIFO to one of P1's open Item1 outputs. CheckIsCyclicalLoop walks all P1
        // outputs ΓÇö for each closed P1 output, it descends into the corresponding P2 consumption
        // and enumerates P2's outputs. Without the CheckCyclicProdCyclicalLoop cache, the P2
        // enumeration happens N times per posting (once per closed P1 output); with the cache,
        // only once. IsConstant(hits(N=5), hits(N=20)) catches the difference.
        Initialize();

        Size[1] := 5;
        Size[2] := 10;
        Size[3] := 20;

        Hits[1] := MeasureOrderEnumHitsInOnePosting_2Level(Size[1]);
        Hits[2] := MeasureOrderEnumHitsInOnePosting_2Level(Size[2]);
        Hits[3] := MeasureOrderEnumHitsInOnePosting_2Level(Size[3]);

        Assert.IsTrue(
          LibraryCalcComplexity.IsConstant(Hits[1], Hits[3]),
          StrSubstNo(NotLinearErr, 'CheckCyclicOrderCyclicalLoop',
            Size[1], Hits[1], Size[2], Hits[2], Size[3], Hits[3]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyntheticXByYIsLinear()
    var
        Size: array[3] of Integer;
        Hits: array[3] of Integer;
    begin
        // [FEATURE] [Cyclical Loop] [Performance]
        // [SCENARIO 626924] 2-level cascade, iterate N P1 consumption postings as described in
        // work item 626924 (each posting walks P1 outputs, each of which descends into P2 via the
        // corresponding C_P2). Without the CheckCyclicProdCyclicalLoop cache, total
        // CheckCyclicOrderCyclicalLoop hits across all postings grow as N^2; with the cache,
        // linear in N.
        Initialize();

        Size[1] := 5;
        Size[2] := 10;
        Size[3] := 20;

        Hits[1] := MeasureOrderEnumHitsAcrossNPostings_2Level(Size[1]);
        Hits[2] := MeasureOrderEnumHitsAcrossNPostings_2Level(Size[2]);
        Hits[3] := MeasureOrderEnumHitsAcrossNPostings_2Level(Size[3]);

        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(Size[1], Size[2], Size[3], Hits[1], Hits[2], Hits[3]),
          StrSubstNo(NotLinearErr, 'CheckCyclicOrderCyclicalLoop (2-level iterated)',
            Size[1], Hits[1], Size[2], Hits[2], Size[3], Hits[3]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyntheticXByYByZIsLinear()
    var
        Size: array[3] of Integer;
        Hits: array[3] of Integer;
    begin
        // [FEATURE] [Cyclical Loop] [Performance]
        // [SCENARIO 626924] 3-level cascade (4 orders: PO1 -> PO2 -> PO3 -> PO4 via distinct
        // items). Iterate N P1 consumption postings in PO2. Per posting the walk traverses 3
        // PO-enum levels; the existing outer-wrapper caches collapse the deep descent but the
        // CheckCyclicProdCyclicalLoop enumeration at each level still runs N times per posting
        // without the Prod cache (once per closed parent output). Total Order-enum hits across
        // all N postings grow as N*(2N+1) = O(N^2) without the Prod cache vs O(N) with it ΓÇö
        // IsLinear catches the super-linear growth.
        Initialize();

        Size[1] := 3;
        Size[2] := 6;
        Size[3] := 12;

        Hits[1] := MeasureOrderEnumHitsAcrossNPostings_3Level(Size[1]);
        Hits[2] := MeasureOrderEnumHitsAcrossNPostings_3Level(Size[2]);
        Hits[3] := MeasureOrderEnumHitsAcrossNPostings_3Level(Size[3]);

        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(Size[1], Size[2], Size[3], Hits[1], Hits[2], Hits[3]),
          StrSubstNo(NotLinearErr, 'CheckCyclicOrderCyclicalLoop (3-level iterated)',
            Size[1], Hits[1], Size[2], Hits[2], Size[3], Hits[3]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedSize2LevelCascadeHitsBounded()
    var
        Hits: Integer;
        HitUpperBound: Integer;
    begin
        // [FEATURE] [Cyclical Loop] [Performance]
        // [SCENARIO 626924] Fixed-size 2-level cascade (N=15). With the cache, a single P1
        // consumption posting produces ~2 Order-enum hits; without the cache, ~16. Bound at 10
        // catches both the regression and the fix.
        Initialize();

        Hits := MeasureOrderEnumHitsInOnePosting_2Level(15);
        HitUpperBound := 10;

        Assert.IsTrue(
          Hits <= HitUpperBound,
          StrSubstNo(UnexpectedHitCountErr, 'CheckCyclicOrderCyclicalLoop (2-level fixed size)', Hits, HitUpperBound));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedSize3LevelCascadeHitsBounded()
    var
        Hits: Integer;
        HitUpperBound: Integer;
    begin
        // [FEATURE] [Cyclical Loop] [Performance]
        // [SCENARIO 626924] Fixed-size 3-level cascade (N=8). With the cache, a single P1
        // consumption posting produces ~3 Order-enum hits; without the cache, ~17. Bound at 15
        // catches both the regression and the fix.
        Initialize();

        Hits := MeasureOrderEnumHitsInOnePosting_3Level(8);
        HitUpperBound := 15;

        Assert.IsTrue(
          Hits <= HitUpperBound,
          StrSubstNo(UnexpectedHitCountErr, 'CheckCyclicOrderCyclicalLoop (3-level fixed size)', Hits, HitUpperBound));
    end;

    procedure SetTriggerReentry(NewValue: Boolean)
    begin
        TriggerReentry := NewValue;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Application Entry", 'OnCheckIsCyclicalLoopOnBeforeCheckCyclicForwardToAppliedInbounds', '', false, false)]
    local procedure OnCheckIsCyclicalLoopTriggerReentry(CheckItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; MaxValuationDate: Date; var IsCyclicalLoop: Boolean)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if not TriggerReentry then
            exit;
        if ReentryGuard then
            exit;
        ReentryGuard := true;
        if ItemApplicationEntry.CheckIsCyclicalLoop(CheckItemLedgEntry, FromItemLedgEntry) then;
        ReentryGuard := false;
    end;

    local procedure CreatePairedProdOrders(var Item: Record Item; var ProductionOrder1: Record "Production Order"; var ProductionOrder2: Record "Production Order"; NoOfOutputs: Integer)
    var
        ProdOrderLine1: Record "Prod. Order Line";
        ProdOrderLine2: Record "Prod. Order Line";
        I: Integer;
    begin
        LibraryInventory.CreateItem(Item);

        // P1: produces NoOfOutputs of Item as N outputs of qty 1 each
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder1, ProductionOrder1.Status::Released, ProductionOrder1."Source Type"::Item, Item."No.", NoOfOutputs);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder1, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine1, ProductionOrder1, Item."No.");
        for I := 1 to NoOfOutputs do
            LibraryManufacturing.PostOutput(ProdOrderLine1, 1, WorkDate(), Item."Unit Cost");

        // P2: consumes NoOfOutputs of Item as N consumptions of qty 1 each (each auto-applies FIFO to a P1 output)
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder2, ProductionOrder2.Status::Released, ProductionOrder2."Source Type"::Item, Item."No.", NoOfOutputs);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder2, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item."No.");
        for I := 1 to NoOfOutputs do
            LibraryManufacturing.PostConsumption(ProdOrderLine2, Item, '', '', 1, WorkDate(), Item."Unit Cost");
    end;

    local procedure CreateCascade3Orders(var Item1: Record Item; var Item2: Record Item; var Item3: Record Item; var ProductionOrder1: Record "Production Order"; var ProductionOrder2: Record "Production Order"; var ProductionOrder3: Record "Production Order"; N: Integer)
    var
        ProdOrderLine1: Record "Prod. Order Line";
        ProdOrderLine2: Record "Prod. Order Line";
        ProdOrderLine3: Record "Prod. Order Line";
        I: Integer;
    begin
        // Chain: PO1 produces Item1 -> PO2 consumes Item1 & produces Item2 -> PO3 consumes Item2
        // & produces Item3. PO1 over-produces (2N) so that N Item1 outputs remain open after PO2
        // consumes N ΓÇö those N open Item1 outputs are the supply for the measurement postings.
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);

        // PO1 produces Item1, 2N outputs
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder1, ProductionOrder1.Status::Released, ProductionOrder1."Source Type"::Item, Item1."No.", 2 * N);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder1, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine1, ProductionOrder1, Item1."No.");
        for I := 1 to 2 * N do
            LibraryManufacturing.PostOutput(ProdOrderLine1, 1, WorkDate(), Item1."Unit Cost");

        // PO2 consumes Item1 (applies FIFO to PO1's first N Item1 outputs) and produces Item2
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder2, ProductionOrder2.Status::Released, ProductionOrder2."Source Type"::Item, Item2."No.", N);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder2, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item2."No.");
        for I := 1 to N do
            LibraryManufacturing.PostConsumption(ProdOrderLine2, Item1, '', '', 1, WorkDate(), Item1."Unit Cost");
        for I := 1 to N do
            LibraryManufacturing.PostOutput(ProdOrderLine2, 1, WorkDate(), Item2."Unit Cost");

        // PO3 consumes Item2 (closes PO2's outputs) and produces Item3 (leaf, all open)
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder3, ProductionOrder3.Status::Released, ProductionOrder3."Source Type"::Item, Item3."No.", N);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder3, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine3, ProductionOrder3, Item3."No.");
        for I := 1 to N do
            LibraryManufacturing.PostConsumption(ProdOrderLine3, Item2, '', '', 1, WorkDate(), Item2."Unit Cost");
        for I := 1 to N do
            LibraryManufacturing.PostOutput(ProdOrderLine3, 1, WorkDate(), Item3."Unit Cost");
    end;

    local procedure CreateCascade4Orders(var Item1: Record Item; var Item2: Record Item; var Item3: Record Item; var Item4: Record Item; var ProductionOrder1: Record "Production Order"; var ProductionOrder2: Record "Production Order"; var ProductionOrder3: Record "Production Order"; var ProductionOrder4: Record "Production Order"; N: Integer)
    var
        ProdOrderLine4: Record "Prod. Order Line";
        I: Integer;
    begin
        CreateCascade3Orders(Item1, Item2, Item3, ProductionOrder1, ProductionOrder2, ProductionOrder3, N);

        // PO4 consumes Item3 (closes PO3's outputs) and produces Item4 (leaf, all open)
        LibraryInventory.CreateItem(Item4);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder4, ProductionOrder4.Status::Released, ProductionOrder4."Source Type"::Item, Item4."No.", N);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder4, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine4, ProductionOrder4, Item4."No.");
        for I := 1 to N do
            LibraryManufacturing.PostConsumption(ProdOrderLine4, Item3, '', '', 1, WorkDate(), Item3."Unit Cost");
        for I := 1 to N do
            LibraryManufacturing.PostOutput(ProdOrderLine4, 1, WorkDate(), Item4."Unit Cost");
    end;

    local procedure MeasureOrderEnumHitsInOnePosting_2Level(N: Integer): Integer
    var
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        ProdOrderLine2: Record "Prod. Order Line";
    begin
        CreateCascade3Orders(Item1, Item2, Item3, ProductionOrder1, ProductionOrder2, ProductionOrder3, N);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item2."No.");

        // Post one more Item1 consumption in PO2. It applies FIFO to one of PO1's N remaining
        // open Item1 outputs. The cyclical-loop walk enumerates PO2's Item2 outputs (first
        // PO-enum), descends through each to PO3's consumption, and enumerates PO3's Item3
        // outputs (second PO-enum). Without the CheckCyclicProdCyclicalLoop cache, the PO3
        // enumeration repeats N times (once per PO2 output); with the cache, only once.
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryManufacturing.PostConsumption(ProdOrderLine2, Item1, '', '', 1, WorkDate(), Item1."Unit Cost");
        CodeCoverageMgt.StopApplicationCoverage();

        exit(GetTableProcHitCount(Database::"Item Application Entry", 'CheckCyclicOrderCyclicalLoop'));
    end;

    local procedure MeasureOrderEnumHitsAcrossNPostings_2Level(N: Integer): Integer
    var
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        ProdOrderLine2: Record "Prod. Order Line";
        I: Integer;
    begin
        CreateCascade3Orders(Item1, Item2, Item3, ProductionOrder1, ProductionOrder2, ProductionOrder3, N);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item2."No.");

        // N Item1 consumptions in PO2, each applying to one of PO1's N remaining open Item1 outputs.
        CodeCoverageMgt.StartApplicationCoverage();
        for I := 1 to N do
            LibraryManufacturing.PostConsumption(ProdOrderLine2, Item1, '', '', 1, WorkDate(), Item1."Unit Cost");
        CodeCoverageMgt.StopApplicationCoverage();

        exit(GetTableProcHitCount(Database::"Item Application Entry", 'CheckCyclicOrderCyclicalLoop'));
    end;

    local procedure MeasureOrderEnumHitsInOnePosting_3Level(N: Integer): Integer
    var
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        ProductionOrder4: Record "Production Order";
        ProdOrderLine2: Record "Prod. Order Line";
    begin
        CreateCascade4Orders(
          Item1, Item2, Item3, Item4,
          ProductionOrder1, ProductionOrder2, ProductionOrder3, ProductionOrder4, N);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item2."No.");

        // Walk goes 3 PO-enum levels deep: PO2 (Item2) -> PO3 (Item3) -> PO4 (Item4, leaf).
        // Without the Prod cache, hits grow as 2N + 1; with the cache, constant 3.
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryManufacturing.PostConsumption(ProdOrderLine2, Item1, '', '', 1, WorkDate(), Item1."Unit Cost");
        CodeCoverageMgt.StopApplicationCoverage();

        exit(GetTableProcHitCount(Database::"Item Application Entry", 'CheckCyclicOrderCyclicalLoop'));
    end;

    local procedure MeasureOrderEnumHitsAcrossNPostings_3Level(N: Integer): Integer
    var
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        ProductionOrder1: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        ProductionOrder4: Record "Production Order";
        ProdOrderLine2: Record "Prod. Order Line";
        I: Integer;
    begin
        CreateCascade4Orders(
          Item1, Item2, Item3, Item4,
          ProductionOrder1, ProductionOrder2, ProductionOrder3, ProductionOrder4, N);
        FindProdOrderLine(ProdOrderLine2, ProductionOrder2, Item2."No.");

        // Iterate N Item1 consumptions in PO2. Each posting triggers a full 3-level walk.
        // Per posting: without Prod cache = 2N + 1; with = 3. Total across N postings:
        // without = N*(2N+1) = 2N^2 + N (super-linear in N); with = 3N (linear in N).
        CodeCoverageMgt.StartApplicationCoverage();
        for I := 1 to N do
            LibraryManufacturing.PostConsumption(ProdOrderLine2, Item1, '', '', 1, WorkDate(), Item1."Unit Cost");
        CodeCoverageMgt.StopApplicationCoverage();

        exit(GetTableProcHitCount(Database::"Item Application Entry", 'CheckCyclicOrderCyclicalLoop'));
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
    end;

    local procedure GetTableProcHitCount(ObjectID: Integer; CodeLine: Text): Integer
    begin
        exit(GetCodeCoverageForObject(CodeCoverage."Object Type"::Table, ObjectID, CodeLine));
    end;
}
