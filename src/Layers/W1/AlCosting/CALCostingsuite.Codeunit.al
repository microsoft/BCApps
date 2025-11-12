codeunit 137100 "CAL Costing suite"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    // DK: Skipped for Execution
    // GB: Skipped for Execution
    // FR: Skipped for Execution
    // NL: Skipped for Execution
    // IT: Skipped for Execution
    // AU: Skipped for Execution
    // IN: Skipped for Execution
    // NZ: Skipped for Execution
    // US: Skipped for Execution
    // CA: Skipped for Execution
    // MX: Skipped for Execution
    // 
    // This codeunit contain a breakdown of all the test cases contained in the old costing suite:
    // 
    // A. 103509 - Test - Warehousing
    //   Naming of the functions:
    //   1.As there are 2 types WMS and BW, the names are:
    //     a.For WMS: WMSTC[x] where x is from 1 to 72.
    //     b.For BW:  BWTC[x] where x is from 1 to 45.
    //   In case of a failure, in the log it will be mentioned the Use case number and Test case number
    // 
    // B. 103510 - Test - CETAF
    //   Naming of the functions:
    //     CETAFTC[x], where x is from 1 to 76.
    //   In case of a failure, in the log it will be mentioned the Use case number and Test case number
    // 
    //   B.1 This suite contains also the following
    //     103421 - Corsica_UpdateSalesStatistics
    //     103422 - Corsica_ClosingInventoryPeriod
    //     103424 - Corsica_Resiliency
    //     103425 - Corsica_AdjCostOfCOGS
    //     103426 - Corsica_TracingCost_VE_GL
    //     103427 - Corsica_ValuingInvtAtAvgCost
    //   B.2 There is also the 7th suite but all the TC are currently commented out (from the initial development):
    //     103423 - Corsica_ExactCostReversing
    // 
    //   For the above, naming of the test methods is like [SuiteName][Test name]
    //   In case of a failure, in the log it will be mentioned the Suite name and Test name.
    // 
    // C. One Test method suites
    //   103512 - Test 370
    //   103514 - Test 300
    //   103517 - Test - Inventory Posting
    //   103518 - Test - Avg. Cost Calc. Type
    //   103521 - Test - Eliminate Rndg Residual
    //   103522 - Test - Dimension Combinations
    // 
    //   For the above, naming of the test methods is like Tst[CodeunitName].
    //   In case of a failure, in the log it will be mentioned the Suite name "full suite".
    // 
    // D. Dependant Test cases (kind of ordered tests)
    //   103526 - Test - Sales Pricing
    //   103527 - Test - Sales Line Discounting
    //   103528 - Test - Purchase Pricing
    //   103529 - Test - Purch. Line Discounting
    // 
    //   For the above, naming of the test methods is like Tst[CodeunitName].
    //   In case of a failure, in the log it will be mentioned the Suite name "full suite".
    // 
    // E. All other suites:
    //   103511 - Test - Partial Posting
    //   103513 - Test - Flushing
    //   103515 - Test - Additional Refactoring
    //   103519 - Test - Severity 1 issues
    //   103520 - Test - Output Posting
    //   103523 - Test - Undo Quantity Posting
    //   103524 - Test - GN Netcom
    //   103525 - Test - White Paper
    //   103537 - Test - Reconcil. Traceability
    //   103538 - Test - Non-Inventoriable Cost
    //   103539 - Test - Undo Qty Posting (Unit)
    //   103540 - Test - Hotfix Scenarios
    //   103541 - Test - Inventory Revaluation
    //   103542 - Test - Planning
    // 
    //   For the above, naming of the test methods is like Tst[CodeunitName][TestName].
    //   In case of a failure, in the log it will be mentioned the Suite name and Test name.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        Initialized := false;
        CETAFInitialized := false;
    end;

    var
        RunManager: Codeunit "Testscript Run Manager";
        TestPartialPosting: Codeunit "Test - Partial Posting";
        TestFlushing: Codeunit "Test - Flushing";
        Test300: Codeunit "Test 300";
        TestAdditionalRefactoring: Codeunit "Test - Additional Refactoring";
        Test370: Codeunit "Test 370";
        TestSeverity1Issues: Codeunit "Test - Severity 1 issues";
        TestOutputPosting: Codeunit "Test - Output Posting";
        TestInventoryPosting: Codeunit "Test - Inventory Posting";
        TestAvgCostCalcType: Codeunit "Test - Avg. Cost Calc. Type";
        TestUndoQuantityPosting: Codeunit "Test - Undo Quantity Posting";
        TestGNNetcom: Codeunit "Test - GN Netcom";
        TestWhitePaper: Codeunit "Test - White Paper";
        TestSalesPricing: Codeunit "Test - Sales Pricing";
        TestSalesLineDiscounting: Codeunit "Test - Sales Line Discounting";
        TestEliminateRndgResidual: Codeunit "Test - Eliminate Rndg Residual";
        TestDimensionCombinations: Codeunit "Test - Dimension Combinations";
        TestPurchasePricing: Codeunit "Test - Purchase Pricing";
        TestPurchLineDiscounting: Codeunit "Test - Purch. Line Discounting";
        TestReconcilTraceability: Codeunit "Test - Reconcil. Traceability";
        TestNonInventoriableCost: Codeunit "Test - Non-Inventoriable Cost";
        TestUndoQtyPostingUnit: Codeunit "Test - Undo Qty Posting (Unit)";
        TestHotfixScenarios: Codeunit "Test - Hotfix Scenarios";
        TestInventoryRevaluation: Codeunit "Test - Inventory Revaluation";
        KnownError42525Err: Label 'Known failure - test commented out also in original suite  - check bug 42525 already logged.';
        Initialized: Boolean;
        CETAFInitialized: Boolean;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        if Initialized then
            exit;

        Initialized := true;
        Commit();
    end;

    [Scope('OnPrem')]
    procedure CETAFInitialize()
    begin
        Initialize();

        RunManager.ClearTestResultTable();

        if CETAFInitialized then
            exit;

        RunManager.PrepareCETAF();
        CETAFInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineA2()
    begin
        // [FEATURE] [Sales] [Partial Posting]
        // [SCENARIO] Sales Order - fully shipped and invoiced
        Initialize();
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('A2');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineA2');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineA3()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('A3');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineA3');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineB9()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('B9');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineB9');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineB11()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('B11');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineB11');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineC1()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('C1');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineC1');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineC2()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('C2');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineC2');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineC3()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('C3');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineC3');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineC4()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('C4');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineC4');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyPosLineC5()
    begin
        InitTstPartialPosting();
        TestPartialPosting.TestOnlyPosLine('C5');
        RunManager.ValidateRun('Test - Partial Posting', 'TestOnlyPosLineC5');
        // [THEN] ILE(Quantity,"Invoiced Quantity","Sales Amount (Actual)"), GLEntry(Amount)
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure Tst370()
    begin
        // [FEATURE] [Production] [Variance] [Cost Standard] [FIFO] [Cost Average] [ACY]
        // [SCENARIO] Production of nested Items with different costing methods reflected in G/L
        AllInitialize(CODEUNIT::"Test 370");
        Test370.SetShowScriptResult(false);
        Test370.Run();
        RunManager.ValidateRun('Test 370', 'full suite');
        // [WHEN] InvtAdjmt.MakeMultiLevelAdjmt and Post Inventory Cost to G/L
        // [THEN] Net change on GLEntry(Amount,ACY)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlushingTC1()
    begin
        InitTstFlushing();
        TestFlushing."Test 1"();
        RunManager.ValidateRun('TestFlushing', 'Test 1');
        // [THEN] N/A
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlushingTC2()
    begin
        InitTstFlushing();
        TestFlushing."Test 2"();
        RunManager.ValidateRun('TestFlushing', 'Test 2');
        // [THEN] N/A
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Tst300()
    begin
        // [FEATURE] [Costing] [Production] [Indirect Cost] [Cost Standard]
        // [SCENARIO] 16 cases: Standard cost depends on components' "Lot Size", Routing setup, BOM's quantity and UOM, Machine centers setup
        AllInitialize(CODEUNIT::"Test 300");
        Test300.SetShowTestResuts(false);
        Test300.Run();
        RunManager.ValidateRun('Test 300', 'full suite');
        // [WHEN] CalcStdCost.CalcItems
        // [THEN] Item Cost Components (Rolled-up/Single-Level/Standard Cost)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_1_1()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-1-1"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-1-1');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item("Unit Cost", <Average Cost>), ILE ("Cost Amount (Expected)","Cost Amount (Actual)","Completely Invoiced")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_1_3()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-1-3"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-1-3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item("Unit Cost", <Average Cost>), ILE ("Cost Amount (Expected)","Cost Amount (Actual)","Completely Invoiced")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_1_5_6()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-1-5_6"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-1-5_6');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item("Unit Cost", <Average Cost>), ILE ("Cost Amount (Actual)","Completely Invoiced")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_1_7_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-1-7_8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-1-7_8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item("Unit Cost", <Average Cost>), ILE ("Cost Amount (Actual)","Completely Invoiced")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_2_2()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-2-2"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-2-2');
        // [WHEN] Item deleted; Adjust Cost Item Entries
        // [THEN] No error on adjustment
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_2_5a_6b()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-2-5a_6b"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-2-5a_6b');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item("Unit Cost", <Average Cost>), ILE ("Cost Amount (Expected)","Cost Amount (Actual)","Completely Invoiced")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_2_10()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-2-10"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-2-10');
        // [GIVEN] Empty ILE
        // [WHEN] Adjust Cost Item Entries
        // [THEN] No error on adjustment
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_2_3_1()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-2-3-1"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-2-3-1');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_1_6()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-1-6"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-1-6');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_1_7()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-1-7"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-1-7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_1_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-1-8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-1-8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_1_9()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-1-9"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-1-9');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_1_11_12()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-1-11_12"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-1-11_12');
        // [GIVEN] Negative Consumption
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_1_13_14()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-1-13_14"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-1-13_14');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_1()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-1"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-1');
        // [GIVEN] Partial Sales Invoice on WorkDate() +1D
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_2()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-2"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-2');
        // [GIVEN] Sales Credit Memo on WorkDate() -1D
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_4_5()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-4_5"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-4_5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_6()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-6"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-6');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_7()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-7"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_8_11()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-8_11"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-8_11');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_13()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-13"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-13');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_15()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-15"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-15');
        // [GIVEN] Sell more
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_17()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-17"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-17');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_18()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-18"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-18');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_19()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-19"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-19');
        // [GIVEN] Sale first
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_20()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-20"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-20');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_2_23()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-2-23"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-2-23');
        // [GIVEN] Consumption
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_3_1()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-3-1"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-3-1');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_3_2()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-3-2"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-3-2');
        // [GIVEN] Reclassification Jnl
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_3_5()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-3-5"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-3-5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_3_6_7()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-3-6_7"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-3-6_7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_3_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-3-8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-3-8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_3_9()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-3-9"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-3-9');
        // [GIVEN] 50 Transfers
        // [WHEN] Adjust Cost Item Entries
        // [THEN] 201 x ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_3_3_10()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-3-3-10"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-3-3-10');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_1_2()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-1_2"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-1_2');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_3()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-3"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_4_5()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-4_5"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-4_5');
        // [GIVEN] Partial Purchase Invoice
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_7()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-7"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-8');
        // [GIVEN] Consumption
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_10()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-10"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-10');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_11()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-11"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-11');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_12()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-12"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-12');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_14()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-14"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-14');
        // [GIVEN] Sales Invoice - Ret.Order
        // [GIVEN] Modified Purchase Invoice
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_1_15()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-1-15"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-1-15');
        // [GIVEN] Sales Invoice - Ret.Order - Invoice
        // [GIVEN] Modified Purchase Invoice
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_2_3()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-2-3"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-2-3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_2_4_5()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-2-4_5"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-2-4_5');
        // [GIVEN] Purchase Credit Memo
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_3_2()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-3-2"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-3-2');
        // [WHEN] Adjust Cost Item Entries
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_3_5()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-3-5"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-3-5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_3_6()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-3-6"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-3-6');
        // [GIVEN] Purchase on +5D
        // [GIVEN] Sale on -2d
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_3_7_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-3-7_8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-3-7_8');
        // [GIVEN] PO1 - SO - PCM1 - PO2 - PCM2
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_3_9()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-3-9"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-3-9');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_4_3_11()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-4-3-11"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-4-3-11');
        // [GIVEN] PO1 - SO - PRO1 - PO2 - PRO2
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_1_1()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-1-1"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-1-1');
        // [GIVEN] Apply to 1st line
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_1_2_3()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-1-2_3"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-1-2_3');
        // [GIVEN] Apply to 2nd line
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_1_4_5()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-1-4_5"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-1-4_5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_1_6_7()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-1-6_7"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-1-6_7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_1_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-1-8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-1-8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_1_9()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-1-9"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-1-9');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_1_2()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-1_2"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-1_2');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_3()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-3"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_4()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-4"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-4');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)") = All zeros
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_6_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-6_8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-6_8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)") = All zeros
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_9()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-9"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-9');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_10()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-10"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-10');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_11_12()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-11_12"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-11_12');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Expected) (ACY)","Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_14()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-14"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-14');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_15()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-15"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-15');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_16()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-16"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-16');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] 103 x ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_2_17()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-2-17"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-2-17');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
        // [THEN] Value Entry count=184
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_1()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-1"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-1');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_2()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-2"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-2');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_3()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-3"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_4()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-4"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-4');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_5()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-5"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_6()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-6"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-6');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_7()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-7"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_8()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-8"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_10()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-10"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-10');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_12()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-12"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-12');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_13()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-13"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-13');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_5_3_14()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-5-3-14"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-5-3-14');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAddlRefactTC1_6_1_9()
    begin
        InitTstAdditionalRefact();
        TestAdditionalRefactoring."1-6-1-9"();
        RunManager.ValidateRun('TestAdditionalRefactoring', '1-6-1-9');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)","Cost Amount (Actual) (ACY)")
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstInventoryPosting()
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO] Insert 34 Value Entries (Purchase,Sale,Pos/Neg Admt,Transfer,Consump,Output)("Direct Cost","Indirect Cost",Variance(5 types),Revaluation,Rounding)
        AllInitialize(CODEUNIT::"Test - Inventory Posting");
        TestInventoryPosting.SetShowScriptResult(false);
        TestInventoryPosting.Run();
        RunManager.ValidateRun('Test - Inventory Posting', 'full suite');
        // [WHEN] run "Post Inventory To G/L"
        // [THEN] Verify 68 G/L Entries
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstAvgCostCalcType()
    begin
        // [FEATURE] [Average Cost Calc. Type]
        // [SCENARIO] Item with BOM (C, CV): Purchase ; Sale; Post Output,Consumption; Finish Prod Order;
        AllInitialize(CODEUNIT::"Test - Avg. Cost Calc. Type");
        TestAvgCostCalcType.SetShowScriptResult(false);
        TestAvgCostCalcType.Run();
        RunManager.ValidateRun('Test - Avg. Cost Calc. Type', 'full suite');
        // [WHEN] Change "Average Cost Calc. Type" and AdjustInvtCost
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesPT_906_847_GK5K_A()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."PT-906-847-GK5K_A"();
        RunManager.ValidateRun('TestSeverity1Issues', 'PT-906-847-GK5K_A');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesPT_906_847_GK5K_B()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."PT-906-847-GK5K_B"();
        RunManager.ValidateRun('TestSeverity1Issues', 'PT-906-847-GK5K_B');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesPT_906_847_GK5K_C()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."PT-906-847-GK5K_C"();
        RunManager.ValidateRun('TestSeverity1Issues', 'PT-906-847-GK5K_C');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesPT_906_847_GK5K_D()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."PT-906-847-GK5K_D"();
        RunManager.ValidateRun('TestSeverity1Issues', 'PT-906-847-GK5K_D');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesAU_273_336_49K6()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."AU-273-336-49K6"();
        RunManager.ValidateRun('TestSeverity1Issues', 'AU-273-336-49K6');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesNL_359_913_PH66()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."NL-359-913-PH66"();
        RunManager.ValidateRun('TestSeverity1Issues', 'NL-359-913-PH66');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
        // [THEN] Value Entry SUM("Cost Amount (Actual)") = 0
        // [THEN] Item Appln Entry COUNT = 1
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesAU_972_992_NCJ7()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."AU-972-992-NCJ7"();
        RunManager.ValidateRun('TestSeverity1Issues', 'AU-972-992-NCJ7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] zero VE.EntryType::Rounding entries
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesCH_974_71_CCS4()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."CH-974-71-CCS4"();
        RunManager.ValidateRun('TestSeverity1Issues', 'CH-974-71-CCS4');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] no endless loop
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesUS_88_465_2PUB()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."US-88-465-2PUB"();
        RunManager.ValidateRun('TestSeverity1Issues', 'US-88-465-2PUB');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
        // [THEN] Value Entry SUM("Cost Amount (Actual)") = 0
        // [THEN] ValueEntry."Valued By Average Cost" = No
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesS_88_465_2PUBAvgC()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."US-88-465-2PUB_AverageCost"();
        RunManager.ValidateRun('TestSeverity1Issues', 'US-88-465-2PUB_AverageCost');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
        // [THEN] Value Entry SUM("Cost Amount (Actual)") = 0
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesUS_698_286_GLCP()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."US-698-286-GLCP"();
        RunManager.ValidateRun('TestSeverity1Issues', 'US-698-286-GLCP');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
        // [THEN] Value Entry SUM("Cost Amount (Actual)") = 0
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesAU_948_721_FV3G()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."AU-948-721-FV3G"();
        RunManager.ValidateRun('TestSeverity1Issues', 'AU-948-721-FV3G');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Unit Cost",<Average Cost>)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_A()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_A"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_A');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry SUM("Cost Amount (Actual)") = 0
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_B()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_B"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_B');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry SUM("Cost Amount (Actual)") = 0
        // [THEN] Item Charges adjusted all VEs
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_C()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_C"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_C');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE SUM("Cost Amount (Actual)") = 0
        // [THEN] ILE ("Cost Amount (Actual)") = "X" * Qty
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_D()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_D"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_D');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE SUM("Cost Amount (Actual)") = 0
        // [THEN] ILE ("Cost Amount (Actual)") = "X" * Qty
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_E()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_E"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_E');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE SUM("Cost Amount (Actual)") = 0
        // [THEN] ILE ("Cost Amount (Actual)") = "X" * Qty
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_F()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_F"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_F');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_G()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_G"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_G');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE SUM("Cost Amount (Actual)") = 0
        // [THEN] ILE ("Cost Amount (Actual)") = "X" * Qty
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_H()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_H"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_H');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE SUM("Cost Amount (Actual)") = 0
        // [THEN] ILE ("Cost Amount (Actual)") = "X" * Qty
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesID_297_538_4DUT_I()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."ID-297-538-4DUT_I"();
        RunManager.ValidateRun('TestSeverity1Issues', 'ID-297-538-4DUT_I');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE SUM("Cost Amount (Actual)") = 0
        // [THEN] ILE ("Cost Amount (Actual)") = "X" * Qty
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesDE_734_304_BGN5()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues."DE-734-304-BGN5"();
        RunManager.ValidateRun('TestSeverity1Issues', 'DE-734-304-BGN5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] No endless loop nor division by zero
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSev1IssuesManufVETypes()
    begin
        InitTstSeverity1issues();
        TestSeverity1Issues.ManufacturingValueEntryTypes();
        RunManager.ValidateRun('TestSeverity1Issues', 'ManufacturingValueEntryTypes');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] VE ("Entry Type","Variance Type","Cost per Unit")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstOutputPosting()
    begin
        // [FEATURE] [Production] [Output] [Capacity]
        // [SCENARIO] 6 Cases: Post Output Jnl Lines with diff params
        AllInitialize(CODEUNIT::"Test - Output Posting");
        TestOutputPosting.SetShowScriptResult(false);
        TestOutputPosting.Run();
        RunManager.ValidateRun('Test - Output Posting', 'full suite');
        // [WHEN] Post Output Journal Line
        // [THEN] Capacity Ledg. Entry (Quantity,"Setup Time","Run Time","Stop Time","Direct Cost")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstEliminateRndgResidual()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [FIFO] [Rounding] [ACY]
        // [SCENARIO] Rounding in ACY is not zero for: Purch Inv (2 lines); Sales Inv (208 lines)
        AllInitialize(CODEUNIT::"Test - Eliminate Rndg Residual");
        TestEliminateRndgResidual.SetShowScriptResult(false);
        TestEliminateRndgResidual.Run();
        RunManager.ValidateRun('Test - Eliminate Rndg Residual', 'full suite');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] VE."Entry Type"::Rounding - SUM("Cost Amount (Actual) (ACY)") <> 0
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstDimensionCombinations()
    begin
        // [FEATURE] [Post Inventory Cost to G/L] [Global Dimension]
        // [SCENARIO] Multiple Items with Global Dims posted to G/L
        AllInitialize(CODEUNIT::"Test - Dimension Combinations");
        TestDimensionCombinations.SetShowScriptResult(false);
        TestDimensionCombinations.Run();
        RunManager.ValidateRun('Test - Dimension Combinations', 'full suite');
        // [WHEN] Post Inventory to G/L
        // [THEN] G/L Entry ("G/L Account No.","Global Dimension 1/2 Code")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC1()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 1"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 1');
        // [THEN] Net change is zero on G/L ("Invt. Accrual Acc. (Interim)","Inventory Account (Interim)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC2()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 2"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 2');
        // [WHEN] Rcpt/Undo Rcpt/Invoice Order
        // [THEN] BlnktPurchLine ("Quantity Received","Quantity Invoiced")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC3()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 3"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 3');
        // [WHEN] Invoice Purchase Order fully
        // [THEN] Purchase Order is deleted
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC4()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 4"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 4');
        // [WHEN] Invoice Purchase Order fully
        // [THEN] Purchase Order is deleted
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC5()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 5"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 5');
        // [WHEN] Invoice Purchase Order fully
        // [THEN] Net change is zero on G/L ("Invt. Accrual Acc. (Interim)","Inventory Account (Interim)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC6()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 6"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 6');
        // [WHEN] Invoice Purchase Ret. Order fully
        // [THEN] Purchase Order is deleted
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC7()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 7"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 7');
        // [GIVEN] Purchase Order: Line.Quantity is "5"
        // [GIVEN] Receive "3" of "5"
        // [GIVEN] Line.Quantity set to "4"
        // [WHEN] Undo Receipt Line
        // [THEN] Line.Quantity is "4"
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstUndoQuantityPostingTC9()
    begin
        InitTstUndoQuantityPosting();
        TestUndoQuantityPosting."Test 9"();
        RunManager.ValidateRun('TestUndoQuantityPosting', 'Test 9');
        // [GIVEN] Receipt Order and Reopen it
        // [WHEN] Undo Receipt on open Purchase Order
        // [THEN] Purch.Order."Status" is "Open"
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstGNNetcomTC1()
    begin
        InitTstGNNetcom();
        TestGNNetcom."Test 1"();
        RunManager.ValidateRun('TestGNNetcom', 'Test 1');
        // [GIVEN] Set filter for Item "X"
        // [WHEN] run report "Calculate Inventory Value" (CalcStdCost.CalcItems)
        // [THEN] Item "X" ("Standard Cost") is updated, Item "Y" is not updated
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstGNNetcomTC2()
    begin
        InitTstGNNetcom();
        TestGNNetcom."Test 2"();
        RunManager.ValidateRun('TestGNNetcom', 'Test 2');
        // [WHEN] Post Inventory To G/L
        // [THEN] G/L Entry (Amount,"Amount (ACY)") for Inventory, Inventory Adjustment
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstGNNetcomTC3()
    begin
        InitTstGNNetcom();
        TestGNNetcom."Test 3"();
        RunManager.ValidateRun('TestGNNetcom', 'Test 3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] no endless loop
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstWhitePaperTC1()
    begin
        InitTstWhitePaper();
        TestWhitePaper."Test 1"();
        RunManager.ValidateRun('TestWhitePaper', 'Test 1');
        // [WHEN] Post Revaluation
        // [THEN] Value Entry ("Valuation Date","Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstWhitePaperTC2()
    begin
        InitTstWhitePaper();
        TestWhitePaper."Test 2"();
        RunManager.ValidateRun('TestWhitePaper', 'Test 2');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry ("Valuation Date","Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstWhitePaperTC3()
    begin
        InitTstWhitePaper();
        TestWhitePaper."Test 3"();
        RunManager.ValidateRun('TestWhitePaper', 'Test 3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry ("Valuation Date","Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstWhitePaperTC4()
    begin
        InitTstWhitePaper();
        TestWhitePaper."Test 4"();
        RunManager.ValidateRun('TestWhitePaper', 'Test 4');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry ("Valuation Date","Cost Amount (Actual)","Cost Amount (Expected)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstWhitePaperTC5()
    begin
        InitTstWhitePaper();
        TestWhitePaper."Test 5"();
        RunManager.ValidateRun('TestWhitePaper', 'Test 5');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Actual)" = "12")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstSalesPricing()
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] 8 cases: Sales Prices set, best "Unit Price" selected
        AllInitialize(CODEUNIT::"Test - Sales Pricing");
        TestSalesPricing.SetShowScriptResult(false);
        TestSalesPricing.Run();
        RunManager.ValidateRun('Test - Sales Pricing', 'full suite');
        // [WHEN] Insert Sales Line
        // [THEN] Sales Line ("Unit Price")
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TstSalesLineDiscounting()
    begin
        // [FEATURE] [Sales] [Line Discount] [Invoice Discount]
        // [SCENARIO] 10 cases: Sales Line "Line Discount %" is calculated for different Item disc. groups and customer prices groups
        AllInitialize(CODEUNIT::"Test - Sales Line Discounting");
        TestSalesLineDiscounting.SetShowScriptResult(false);
        TestSalesLineDiscounting.Run();
        RunManager.ValidateRun('TestSalesLineDiscounting', 'full suite');
        // [WHEN] Create/modify Sales Lines or/and post Invoices
        // [THEN] Sales Line ("Line Discount %","Unit Price","Inv. Discount Amount"); Sales Invoice Line ("Line Amount")
        // [THEN] Item Journal Line ("Unit Amount")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstPurchasePricing()
    begin
        // [FEATURE] [Purchase] [Price]
        // [SCENARIO] 7 cases: Purchase Prices set,"Direct Unit Cost" calculated in lines
        AllInitialize(CODEUNIT::"Test - Purchase Pricing");
        TestPurchasePricing.SetShowScriptResult(false);
        TestPurchasePricing.Run();
        RunManager.ValidateRun('TestSalesLineDiscounting', 'full suite');
        // [WHEN] Create/modify Purchase line
        // [THEN] Purchase Line ("Direct Unit Cost")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstPurchLineDiscounting()
    begin
        // [FEATURE] [Purchase] [Line Discount]
        // [SCENARIO] 6 cases: Purchase Line "Line Discount %" is calculated for different purchase line discounts
        AllInitialize(CODEUNIT::"Test - Purch. Line Discounting");
        TestPurchLineDiscounting.SetShowScriptResult(false);
        TestPurchLineDiscounting.Run();
        RunManager.ValidateRun('Test - Purch. Line Discounting', 'full suite');
        // [WHEN] Create/modify Purchase Lines or/and post Invoices
        // [THEN] Purchase Line ("Line Discount %"); Purchase Invoice Line ("Line Discount %")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC1()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test1();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test1');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC2()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test2();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test2');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Expected)","Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC3()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test3();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test3');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC4()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test4();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test4');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC5()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test5();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)"): Direct Cost=100, Rounding=-0.01
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC6()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test6();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test6');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC7()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test7();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC8()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test8();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstReconcilTraceabilityTC9()
    begin
        InitTstReconcilTraceability();
        TestReconcilTraceability.Test9();
        RunManager.ValidateRun('TestReconcilTraceability', 'Test9');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC1()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test1();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test1');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC2()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test2();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test2');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC3()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test3();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test3');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC4()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test4();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test4');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC5()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test5();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test5');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC6()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test6();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test6');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC7()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test7();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test7');
        // [WHEN] Post Purchase Credit Memo
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC8()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test8();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test8');
        // [WHEN] Post Purchase Credit Memo
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC9()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test9();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test9');
        // [WHEN] Post Purchase Credit Memo
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC10()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test10();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test10');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC11()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test11();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test11');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC12()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test12();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test12');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC13()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test13();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test13');
        // [WHEN] Invoice Purchase Order
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC14()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test14();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test14');
        // [WHEN] Post Purchase Credit Memo
        // [THEN] ILE ("Cost Amount (Non-Invtbl.)") = 0
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC15()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test15();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test15');
        // [WHEN] Delete Purchase Invoice with assigned Item Charges
        // [THEN] Purchase Invoice is deleted silently
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC16()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test16();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test16');
        // [WHEN] Post Purchase Invoice
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC17()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test17();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test17');
        // [WHEN] Post Purchase Invoice
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC18()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test18();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test18');
        // [WHEN] Post Purchase Invoice
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC19()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test19();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test19');
        // [WHEN] Post Purchase Invoice
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC20()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test20();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test20');
        // [WHEN] Post Purchase Invoice
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC21()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test21();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test21');
        // [WHEN] Post Purchase Credit Memo
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC22()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test22();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test22');
        // [WHEN] Post Purchase Credit Memo
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstNonInventoriableCostTC23()
    begin
        InitTstNonInventoriableCost();
        TestNonInventoriableCost.Test23();
        RunManager.ValidateRun('TestNonInventoriableCost', 'Test23');
        // [WHEN] Post Purchase Credit Memo
        // [THEN] Value Entry ("Valued Quantity","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC1()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test1();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test1');
        // [WHEN] Undo Purchase Receipt
        // [THEN] Rcpt Line (Quantity=-1, Correction=TRUE)
        // [THEN] Purchase Line ("Qty. to Receive","Quantity Received","Qty. Rcd. Not Invoiced")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC2()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test2();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test2');
        // [WHEN] Undo Purchase Receipt
        // [THEN] Purchase Blanket Line ("Qty. to Receive","Quantity Received")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC3()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test3();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test3');
        // [WHEN] Post Purchase Receipt
        // [THEN] Receipt Line ("Order No.")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC4()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test4();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test4');
        // [WHEN] Delete Purchase Order
        // [THEN] Purchase Order is deleted
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC5()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test5();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test5');
        // [WHEN] Undo Purchase Receipt
        // [THEN] Receipt Line (Quantity)
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC6()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test6();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test6');
        // [WHEN] Undo Purchase Return Shipment
        // [THEN] Purchase Line ("Return Qty. to Ship","Return Qty. Shipped","Return Shpd. Not Invd.")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC7()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test7();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test7');
        // [WHEN] Undo Purchase Return Shipment
        // [THEN] ILE ("Cost Amount...") are completely reversed by Undo
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC8()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test8();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test8');
        // [WHEN] Post Purchase Ret. Shipment
        // [THEN] New Ret. Shipment created
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC9()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test9();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test9');
        // [WHEN] Delete Ret. Order
        // [THEN] Ret. Order is deleted
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC10()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test10();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test10');
        // [WHEN] Undo Purchase Return Shipment
        // [THEN] ILE ("Cost Amount...") are completely reversed by Undo
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC11()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test11();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test11');
        // [WHEN] Undo Sales Shipment
        // [THEN] Sales Line ("Qty. to Ship","Quantity Shipped","Qty. Shipped Not Invoiced")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC12()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test12();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test12');
        // [WHEN] Undo Sales Shipment
        // [THEN] Sales Blanket Line ("Qty. to Ship","Quantity Shipped")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC13()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test13();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test13');
        // [WHEN] Undo Sales Shipment
        // [THEN] ILE ("Cost Amount...") are completely reverted
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC14()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test14();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test14');
        // [WHEN] Post Sales Shipment
        // [THEN] New Shipment line created
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC15()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test15();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test15');
        // [WHEN] Delete Sales Order
        // [THEN] Order is deleted
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC16()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test16();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test16');
        // [WHEN] Undo Sales Shipment
        // [THEN] ILE ("Cost Amount...") are completely reverted
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC17()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test17();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test17');
        // [WHEN] Undo Sales Ret Receipt
        // [THEN] Sales Line ("Return Qty. to Receive","Return Qty. Received","Return Qty. Rcd. Not Invd.")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC18()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test18();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test18');
        // [WHEN] Undo Sales Ret Receipt
        // [THEN] ILE ("Cost Amount...") are completely reverted
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC19()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test19();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test19');
        // [WHEN] Post Return Receipt
        // [THEN] New Ret.Rcpt created
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC20()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test20();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test20');
        // [WHEN] Delete Sales Order
        // [THEN] Sales Order is deleted
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TstUndoQtyPostingUnitTC21()
    begin
        InitTstUndoQtyPostingUnit();
        TestUndoQtyPostingUnit.Test21();
        RunManager.ValidateRun('TestUndoQtyPostingUnit', 'Test21');
        // [WHEN] Undo Sales Ret Receipt
        // [THEN] ILE ("Cost Amount...") are completely reverted
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnHQ_252_729_KAXY()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."HQ-252-729-KAXY"();
        RunManager.ValidateRun('TestHotfixScenarios', 'HQ-252-729-KAXY');
        // [WHEN] Post Sales Invoice
        // [THEN] Value Entry SUM("Cost Amount (Actual)" = 0); No rounding entries
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnDE_155_33_RCCC()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."DE-155-33-RCCC"();
        RunManager.ValidateRun('TestHotfixScenarios', 'DE-155-33-RCCC');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] 2 Value Entries inserted by adjustment
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnHU_70_411_XJT7()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."HU-70-411-XJT7"();
        RunManager.ValidateRun('TestHotfixScenarios', 'HU-70-411-XJT7');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Adjustment is finished, no endless loop
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnLT_699_912_PKGA()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."LT-699-912-PKGA"();
        RunManager.ValidateRun('TestHotfixScenarios', 'LT-699-912-PKGA');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry SUM("Cost Amount (Actual)") = 0
    end;

    [Scope('OnPrem')]
    procedure TstHFScnCompletelyInvd()
    begin
        // [FEATURE] [FIFO] [Production]
        // [SCENARIO] Prod Order; Post Consump (negative); Finish Prod Order.
        Error(KnownError42525Err);
        // InitTstHotfixScenarios;
        // TestHotfixScenarios."Completely Invd for neg cons.";
        // RunManager.ValidateRun('TestHotfixScenarios','Completely Invd for neg cons.');
        // [WHEN] Finish Production Order
        // [THEN] ILE "Completely Invoiced" = TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnQtyConversion()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."Qty conversion w/consumption"();
        RunManager.ValidateRun('TestHotfixScenarios', 'Qty conversion w/consumption');
        // [GIVEN] Purch Invoice (32 x PCS)
        // [WHEN] Post Consumption (1 x PALLET)
        // [THEN] ILE.Quantity = -32
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnCA_701_636_JRXL()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."CA-701-636-JRXL"();
        RunManager.ValidateRun('TestHotfixScenarios', 'CA-701-636-JRXL');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)") = 0
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnUS_704_763_NK3Z()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."US-704-763-NK3Z"();
        RunManager.ValidateRun('TestHotfixScenarios', 'US-704-763-NK3Z');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Item ("Last Direct Cost",<Average Cost> on RED)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnPT_469_766_SEYZ()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."PT-469-766-SEYZ"();
        RunManager.ValidateRun('TestHotfixScenarios', 'PT-469-766-SEYZ');
        // [WHEN] Post Sales Invoice
        // [THEN] Value Entry ("Sales Amount (Actual)","Sales Amount (Expected)","Cost Amount (Actual)","Cost Amount (Expected)","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnHQ_704_165_YJN2()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."HQ-704-165-YJN2"();
        RunManager.ValidateRun('TestHotfixScenarios', 'HQ-704-165-YJN2');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnDK_338_281_WK8H()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."DK-338-281-WK8H"();
        RunManager.ValidateRun('TestHotfixScenarios', 'DK-338-281-WK8H');
        // [WHEN] Post Revaluation
        // [THEN] Value Entry ("Sales Amount (Actual)","Sales Amount (Expected)","Cost Amount (Actual)","Cost Amount (Expected)","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnSG_501_754_ZU7R()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."SG-501-754-ZU7R"();
        RunManager.ValidateRun('TestHotfixScenarios', 'SG-501-754-ZU7R');
        // [WHEN] Post Sales Credit Memo
        // [THEN] Value Entry ("Sales Amount (Actual)","Sales Amount (Expected)","Cost Amount (Actual)","Cost Amount (Expected)","Cost Amount (Non-Invtbl.)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnAdjdAvg()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."Adjd Avg Costed Sales Credit"();
        RunManager.ValidateRun('TestHotfixScenarios', 'Adjd Avg Costed Sales Credit');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry ("Cost Amount (Actual)","Valued By Average Cost",Adjustment)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnCostOnZero()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."Cost on Zero Quantities"();
        RunManager.ValidateRun('TestHotfixScenarios', 'Cost on Zero Quantities');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnItemCharge()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."Item Charge in ACY"();
        RunManager.ValidateRun('TestHotfixScenarios', 'Item Charge in ACY');
        // [WHEN] Post Purchase Invoice with Item Charges / Post Output
        // [THEN] Value Entry ("Cost Amount (Actual) (ACY)","Cost per Unit (ACY)" |"Cost Amount (Expected)","Cost Amount (Expected) (ACY)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnNL_697_699_NF6E()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."NL-697-699-NF6E"();
        RunManager.ValidateRun('TestHotfixScenarios', 'NL-697-699-NF6E');
        // [WHEN] Adjust Cost Item Entries (second time)
        // [THEN] No additional value Entries created
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnNL_25_285_8LF5()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."NL-25-285-8LF5"();
        RunManager.ValidateRun('TestHotfixScenarios', 'NL-25-285-8LF5');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Rounding Value Entry does not inserted
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnDE_750_440_XEGV()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."DE-750-440-XEGV"();
        RunManager.ValidateRun('TestHotfixScenarios', 'DE-750-440-XEGV');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] no endless loop
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnHQ_179_565_YK8Z()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."HQ-179-565-YK8Z"();
        RunManager.ValidateRun('TestHotfixScenarios', 'HQ-179-565-YK8Z');
        // [WHEN] Invoice Purchase Order
        // [THEN] Value Entry ("Cost Amount (Actual)" = 12)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnHQ_214_60_HDRS()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."HQ-214-60-HDRS"();
        RunManager.ValidateRun('TestHotfixScenarios', 'HQ-214-60-HDRS');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] Value Entry ("Valued Quantity")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnAU_312_772_F9LY()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."AU-312-772-F9LY"();
        RunManager.ValidateRun('TestHotfixScenarios', 'AU-312-772-F9LY');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnCH_73_866_CCYP()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."CH-73-866-CCYP"();
        RunManager.ValidateRun('TestHotfixScenarios', 'CH-73-866-CCYP');
        // [WHEN] Invoice Sales Order
        // [THEN] Value Entry ("Cost Amount (Actual)" = 0)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnDE_299_115_4H8P()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."DE-299-115-4H8P"();
        RunManager.ValidateRun('TestHotfixScenarios', 'DE-299-115-4H8P');
        // [WHEN] Post Sales Shipment
        // [THEN] Value Entry ("Sales Amount (Expected)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnFI_492_147_FA5D()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."FI-492-147-FA5D"();
        RunManager.ValidateRun('TestHotfixScenarios', 'FI-492-147-FA5D');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnCZ_803_600_KKG8()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."CZ-803-600-KKG8"();
        RunManager.ValidateRun('TestHotfixScenarios', 'CZ-803-600-KKG8');
        // [WHEN] Adjust Cost Item Entries
        // [THEN] no endless loop
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnCZ_799_772_8G6F()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."CZ-799-772-8G6F"();
        RunManager.ValidateRun('TestHotfixScenarios', 'CZ-799-772-8G6F');
        // [WHEN] Post Sale Journal Line
        // [THEN] Value Entry SUM("Cost Amount (Actual)" = 0)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstHFScnCZ_642_426_REG9()
    begin
        InitTstHotfixScenarios();
        TestHotfixScenarios."CZ-642-426-REG9"();
        RunManager.ValidateRun('TestHotfixScenarios', 'CZ-642-426-REG9');
        // [WHEN] Calculate Item Average Cost
        // [THEN] <no verification>
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstInvRevaluationTestFIFO()
    begin
        InitTstInventoryRevaluation();
        TestInventoryRevaluation.TestFIFO();
        RunManager.ValidateRun('TestInventoryRevaluation', 'TestFIFO');
        // [WHEN] Post Revaluation Journal Lines
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Scope('OnPrem')]
    procedure TstInvRevaluationTestAverage()
    begin
        InitTstInventoryRevaluation();
        TestInventoryRevaluation.TestAverage();
        RunManager.ValidateRun('TestInventoryRevaluation', 'TestAverage');
        // [WHEN] Post Revaluation Journal Lines
        // [THEN] <no verification>
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TstInvRevaluationTestStandard()
    begin
        InitTstInventoryRevaluation();
        TestInventoryRevaluation.TestStandard();
        RunManager.ValidateRun('TestInventoryRevaluation', 'TestStandard');
        // [WHEN] Post Revaluation Journal Lines
        // [THEN] ILE ("Cost Amount (Actual)")
    end;

    [Scope('OnPrem')]
    procedure AllInitialize("CodeUnit": Integer)
    begin
        Initialize();

        RunManager.PrepareOldSuites(CodeUnit);
        RunManager.ClearTestResultTable();

        Commit();
    end;

    local procedure InitTstPartialPosting()
    begin
        AllInitialize(CODEUNIT::"Test - Partial Posting");

        TestPartialPosting.SetPreconditions();

        Commit();
    end;

    local procedure InitTstFlushing()
    begin
        AllInitialize(CODEUNIT::"Test - Flushing");

        TestFlushing.SetPreconditions();

        Commit();
    end;

    local procedure InitTstAdditionalRefact()
    begin
        AllInitialize(CODEUNIT::"Test - Additional Refactoring");

        TestAdditionalRefactoring.SetPreconditions();

        Commit();
    end;

    local procedure InitTstSeverity1issues()
    begin
        AllInitialize(CODEUNIT::"Test - Severity 1 issues");

        TestSeverity1Issues.SetPreconditions();

        Commit();
    end;

    local procedure InitTstUndoQuantityPosting()
    begin
        AllInitialize(CODEUNIT::"Test - Undo Quantity Posting");

        TestUndoQuantityPosting.SetPreconditions();

        Commit();
    end;

    local procedure InitTstGNNetcom()
    begin
        AllInitialize(CODEUNIT::"Test - GN Netcom");

        TestGNNetcom.SetPreconditions();

        Commit();
    end;

    local procedure InitTstWhitePaper()
    begin
        AllInitialize(CODEUNIT::"Test - White Paper");

        TestWhitePaper.SetPreconditions();

        Commit();
    end;

    local procedure InitTstReconcilTraceability()
    begin
        AllInitialize(CODEUNIT::"Test - Reconcil. Traceability");

        TestReconcilTraceability.SetPreconditions();

        Commit();
    end;

    local procedure InitTstNonInventoriableCost()
    begin
        AllInitialize(CODEUNIT::"Test - Non-Inventoriable Cost");

        TestNonInventoriableCost.SetPreconditions();

        Commit();
    end;

    local procedure InitTstUndoQtyPostingUnit()
    begin
        AllInitialize(CODEUNIT::"Test - Undo Qty Posting (Unit)");

        TestUndoQtyPostingUnit.SetPreconditions();

        Commit();
    end;

    local procedure InitTstHotfixScenarios()
    begin
        AllInitialize(CODEUNIT::"Test - Hotfix Scenarios");

        TestHotfixScenarios.SetPreconditions();

        Commit();
    end;

    local procedure InitTstInventoryRevaluation()
    begin
        AllInitialize(CODEUNIT::"Test - Inventory Revaluation");

        TestInventoryRevaluation.SetPreconditions();

        Commit();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

