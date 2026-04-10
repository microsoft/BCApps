codeunit 137451 "Phys. Invt. Order PAG UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order] [UI]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LinesInsertedToOrderMsg: Label '%1 lines inserted into the order %2.', Comment = '%1 = counters, %2 = Order No.';

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintPostedPhysicalInventoryOrder()
    var
        ReportSelections: Record "Report Selections";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PostedPhysInvtOrder: TestPage "Posted Phys. Invt. Order";
    begin
        // [SCENARIO] validate Print - OnAction Trigger of Page ID - 5005358 Posted Physical Inventory Order.
        // Setup.
        CreateReportSelections(ReportSelections.Usage::"P.Phys.Invt.Order", REPORT::"Posted Phys. Invt. Order Diff.");
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);

        // Exercise & verify: Invokes Action - Print on Page Posted Phys. Invt. Order. Added ReportHandler - PostedPhysInvtOrderDiffReportHandler.
        PostedPhysInvtOrder.OpenEdit();
        PostedPhysInvtOrder.Print.Invoke();  // Invokes PostedPhysInvtOrderDiffReportHandler.
        PostedPhysInvtOrder.Close();
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecordingReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintPostedPhysInvtRecording()
    var
        ReportSelections: Record "Report Selections";
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
        PostedPhysInvtRecording: TestPage "Posted Phys. Invt. Recording";
    begin
        // [SCENARIO] validate Print - OnAction Trigger of Page ID - 5005362 Posted Physical Inventory Recording.
        // Setup.
        CreateReportSelections(ReportSelections.Usage::"P.Phys.Invt.Rec.", REPORT::"Posted Phys. Invt. Recording");
        CreatePostedPhysInvtRecHeader(PstdPhysInvtRecordHdr, LibraryUTUtility.GetNewCode());

        // Exercise & verify: Invokes Action - Print on Page Posted Phys. Invt. Recording. Added ReportHandler - PostedPhysInvtRecordingReportHandler.
        PostedPhysInvtRecording.OpenEdit();
        PostedPhysInvtRecording.Print.Invoke();  // Invokes PostedPhysInvtRecordingReportHandler.
        PostedPhysInvtRecording.Close();
    end;

    [Test]
    [HandlerFunctions('PhysInvtRecordingReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintPhysicalInventoryRecording()
    var
        ReportSelections: Record "Report Selections";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInventoryRecording: TestPage "Phys. Inventory Recording";
    begin
        // [SCENARIO] validate Print - OnAction Trigger of Page ID - 5005354 Physical Inventory Recording.
        // Setup.
        CreateReportSelections(ReportSelections.Usage::"Phys.Invt.Rec.", REPORT::"Phys. Invt. Recording");
        CreatePhysInvtRecordingHeader(PhysInvtRecordHeader, LibraryUTUtility.GetNewCode());

        // Exercise & verify: Invokes Action - Print on Page Phys. Invt. Recording. Added ReportHandler - PhysInvtRecordingReportHandler.
        PhysInventoryRecording.OpenEdit();
        PhysInventoryRecording.Print.Invoke();  // Invokes PhysInvtRecordingReportHandler.
        PhysInventoryRecording.Close();
    end;

    [Test]
    [HandlerFunctions('PostPhysInvtOrderNavigatePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordsPostPhysInvtOrderHeaderOnNavigate()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        // [SCENARIO] validate FindRecords function of Page ID - 344 Navigate.
        // Setup.
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);

        // Exercise & verify: Run Page Navigate for Posted Physical Inventory Order Header. Verify correct entries created for Posted Physical Inventory Order Header in PostPhysInvtOrderNavigatePageHandler.
        OpenPageNavigate(PstdPhysInvtOrderHdr."No.");  // Invokes PostPhysInvtOrderNavigatePageHandler.
    end;

    [Test]
    [HandlerFunctions('PhysInvtLedgEntryNavigatePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FindRecordsPhysInvtLedgEntryOnNavigate()
    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
    begin
        // [SCENARIO] validate FindRecords function of Page ID - 344 Navigate.
        // Setup.
        CreatePhysInventoryLedgerEntry(PhysInvtLedgEntry);

        // Exercise & verify: Run Page Navigate for Physical Inventory Ledger Entry. Verify correct entries created for Physical Inventory Ledger Entry in PhysInvtLedgEntryNavigatePageHandler.
        OpenPageNavigate(PhysInvtLedgEntry."Document No.");  // Invokes PhysInvtLedgEntryNavigatePageHandler.
    end;

    [Test]
    [HandlerFunctions('ShowPostPhysInvtOrderNavigatePageHandler,PostedPhysInvtOrderListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowRecordsPostPhysInvtOrderHeaderOnNavigate()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        // [SCENARIO] validate ShowRecords function of Page ID - 344 Navigate.
        // Setup.
        Initialize();
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);
        LibraryVariableStorage.Enqueue(PstdPhysInvtOrderHdr."No."); // Required inside PostedPhysInvtOrderListPageHandler.

        // Exercise & verify: Run Page Navigate for Posted Physical Inventory Order Header and invoke the Show action to verify correct entries for Posted Physical Inventory Order Header.
        OpenPageNavigate(PstdPhysInvtOrderHdr."No.");
    end;

    [Test]
    [HandlerFunctions('ShowPhysInvtLedgEntryNavigatePageHandler,PhysInventoryLedgerEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowRecordsPhysInvtLedgEntryOnNavigate()
    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
    begin
        // [SCENARIO] validate ShowRecords function of Page ID - 344 Navigate.
        // Setup.
        Initialize();
        CreatePhysInventoryLedgerEntry(PhysInvtLedgEntry);
        LibraryVariableStorage.Enqueue(PhysInvtLedgEntry."Document No."); // Required inside PhysInventoryLedgerEntriesPageHandler.

        // Exercise & verify: Run Page Navigate for Physical Inventory Ledger Entry and invoke the Show action to verify correct entries for Physical Inventory Ledger Entry.
        OpenPageNavigate(PhysInvtLedgEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('PostPhysInvtOrderNavigatePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigatePostedPhysInvtOrderList()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PostedPhysInvtOrderList: TestPage "Posted Phys. Invt. Order List";
    begin
        // [SCENARIO] validate Navigate - OnAction Trigger of Page Posted Phys. Invt. Order List.
        // Setup.
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);

        // Exercise & verify: Invokes Action - Navigate on page Posted Phys. Invt. Order List. Verify correct entries created for Posted Physical Inventory Order Header in PostPhysInvtOrderNavigatePageHandler.
        PostedPhysInvtOrderList.OpenEdit();
        PostedPhysInvtOrderList.FILTER.SetFilter("No.", PstdPhysInvtOrderHdr."No.");
        PostedPhysInvtOrderList.Navigate.Invoke();  // Invokes PostPhysInvtOrderNavigatePageHandler.
        PostedPhysInvtOrderList.Close();
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RecordingLinesPostedPhysInvtOrderSubform()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
        PostedPhysInvtOrder: TestPage "Posted Phys. Invt. Order";
    begin
        // [SCENARIO] validate RecordingLines - OnAction Trigger of Page Posted Physical Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderHdr."No.");

        PstdPhysInvtRecordLine."Order No." := PstdPhysInvtOrderHdr."No.";
        PstdPhysInvtRecordLine."Order Line No." := PstdPhysInvtOrderLine."Line No.";
        PstdPhysInvtRecordLine.Insert();
        LibraryVariableStorage.Enqueue(PstdPhysInvtOrderHdr."No.");  // Required inside PostedPhysInvtRecordLinesPageHandler.

        // Exercise & verify: Invokes Action - RecordingLines on Posted Physical Inventory Order Subform and verify correct entries created for Posted Physical Inventory Order Header in PostedPhysInvtRecordLinesPageHandler.
        OpenPostedPhysInventoryOrderPage(PostedPhysInvtOrder, PstdPhysInvtOrderHdr."No.");
        PostedPhysInvtOrder.OrderLines.RecordingLines.Invoke();  // Invokes PostedPhysInvtRecordLinesPageHandler.
        PostedPhysInvtOrder.Close();
    end;

    [Test]
    [HandlerFunctions('DimensionSetEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DimensionPostedPhysInvtOrderSubform()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntry2: Record "Dimension Set Entry";
        PostedPhysInvtOrder: TestPage "Posted Phys. Invt. Order";
    begin
        // [SCENARIO] validate Dimension - OnAction trigger of Page Posted Physical Inventory Order Subform.
        // Setup.
        Initialize();
        DimensionSetEntry.FindLast();
        CreateDimensionSetEntry(DimensionSetEntry2, DimensionSetEntry."Dimension Set ID" + 1);  // Value required for non existing Dimension Set Entry.

        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderHdr."No.");
        PstdPhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry2."Dimension Set ID";
        PstdPhysInvtOrderLine.Modify();
        LibraryVariableStorage.Enqueue(DimensionSetEntry2."Dimension Code");  // Required inside DimensionSetEntriesPageHandler.
        LibraryVariableStorage.Enqueue(DimensionSetEntry2."Dimension Value Code");  // Required inside DimensionSetEntriesPageHandler.

        // Exercise & verify: Invokes Action - Dimensions on Posted Physical Inventory Order Subform and verify correct entries created for Posted Physical Inventory Order Header in DimensionSetEntriesPageHandler.
        OpenPostedPhysInventoryOrderPage(PostedPhysInvtOrder, PstdPhysInvtOrderHdr."No.");
        PostedPhysInvtOrder.OrderLines.Dimensions.Invoke();  // Invokes DimensionSetEntriesPageHandler.
        PostedPhysInvtOrder.Close();
    end;

    [Test]
    [HandlerFunctions('PostedExpInvtOrderTrackingPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExpectedTrackingLinesPostedPhysInvtOrderSubformPackage()
    var
        PstdExpInvtOrderTracking: Record "Pstd.Exp.Invt.Order.Tracking";
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PostedPhysInvtOrder: TestPage "Posted Phys. Invt. Order";
    begin
        // [SCENARIO] validate ExpectedTrackingLines - OnAction trigger of Page ID - 5005360  Posted Physical Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderHdr."No.");
        PstdPhysInvtOrderLine."Quantity (Base)" := 1;
        PstdPhysInvtOrderLine.Modify();

        CreatePostedExpInvtOrderTracking(
          PstdExpInvtOrderTracking, PstdPhysInvtOrderLine."Document No.", PstdPhysInvtOrderLine."Line No.");
        LibraryVariableStorage.Enqueue(PstdPhysInvtOrderHdr."No.");
        LibraryVariableStorage.Enqueue(PstdExpInvtOrderTracking."Serial No.");
        LibraryVariableStorage.Enqueue(PstdExpInvtOrderTracking."Lot No.");
        LibraryVariableStorage.Enqueue(PstdExpInvtOrderTracking."Package No.");

        // Exercise & verify: Invokes Action - ExpectedTrackingLines on Posted Physical Inventory Order Subform and verify correct entries created for Posted Physical Inventory Order Header in DimensionSetEntriesPageHandler.
        OpenPostedPhysInventoryOrderPage(PostedPhysInvtOrder, PstdPhysInvtOrderHdr."No.");
        PostedPhysInvtOrder.OrderLines.ExpectedTrackingLines.Invoke();  // Invokes PostedExpInvtTrackingPageHandler.
        PostedPhysInvtOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetSourcesUsedPackageTrackingLines()
    var
        InvtOrderTrackingBuffer: Record "Invt. Order Tracking";
        InvtOrderTrackingLinesPage: Page "Invt. Order Tracking Lines";
        InvtOrderTrackingLines: TestPage "Invt. Order Tracking Lines";
    begin
        // [SCENARIO] validate SetSources Function on Page Used Tracking Lines.
        // Setup: Create Physical Inventory Tracking Buffer.
        InvtOrderTrackingBuffer."Serial No." := LibraryUTUtility.GetNewCode();
        InvtOrderTrackingBuffer."Lot No." := LibraryUTUtility.GetNewCode();
        InvtOrderTrackingBuffer."Package No." := LibraryUTUtility.GetNewCode();
        InvtOrderTrackingBuffer."Qty. Expected (Base)" := 1;
        InvtOrderTrackingBuffer.Insert();
        InvtOrderTrackingLines.Trap();

        // [WHEN] SetSources and run the Page - Used Tracking Lines.
        InvtOrderTrackingLinesPage.SetSources(InvtOrderTrackingBuffer);
        InvtOrderTrackingLinesPage.Run();

        // [THEN] Verify Serial No, Lot, Package No and Qty. Expected (Base) on Page Used Tracking Lines.
        InvtOrderTrackingLines."Serial No.".AssertEquals(InvtOrderTrackingBuffer."Serial No.");
        InvtOrderTrackingLines."Lot No.".AssertEquals(InvtOrderTrackingBuffer."Lot No.");
        InvtOrderTrackingLines."Package No.".AssertEquals(InvtOrderTrackingBuffer."Package No.");
        InvtOrderTrackingLines."Qty. Expected (Base)".AssertEquals(InvtOrderTrackingBuffer."Qty. Expected (Base)");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPhysInvtOrderStatisticsError()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderStatistics: TestPage "Phys. Invt. Order Statistics";
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        // [SCENARIO] validate Trigger OnAfterGetRecord on Page Phys. Invt. Order Statistics.
        // Setup: Create Physical Inventory Order and open Physical Inventory Order page.
        OpenPhysInventoryOrderPage(PhysInventoryOrder, CreatePhysInventoryOrder(PhysInvtOrderLine."Entry Type"::" ", 0, false));  // Quantity (Base) - 0 and Without Difference - False.

        // [WHEN] Open Physical Inventory Order Statistics page.
        PhysInvtOrderStatistics.Trap();
        asserterror PhysInventoryOrder.Statistics.Invoke();

        // [THEN] Verify Error Code, Error Msg - Unknown Entry type.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('PhysInventoryOrderLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoCorrectLinesDrillDownPhysInvtOrderStatistics()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderStatistics: TestPage "Phys. Invt. Order Statistics";
    begin
        // [SCENARIO] validate Trigger OnDrillDown of NoCorrectLines on Page Phys. Invt. Order Statistics.
        // Setup: Create Physical Inventory Order and open Physical Inventory Order Statistics page.
        Initialize();
        OpenPhysInvtOrderStatisticsPage(PhysInvtOrderStatistics, PhysInvtOrderLine."Entry Type"::"Positive Adjmt.", 0, true);  // Quantity (Base) - 0 and Without Difference - True.

        // Exercise.
        PhysInvtOrderStatistics.NoCorrectLines.DrillDown();  // Open page in PhysInventoryOrderLinesPageHandler.

        // [THEN] Verify NoCorrectLines on Physical Inventory Order Statistics page and Entry Type and Quantity Base verify in Page handler - PhysInventoryOrderLinesPageHandler.
        PhysInvtOrderStatistics.NoCorrectLines.AssertEquals(1);
        PhysInvtOrderStatistics.Close();
    end;

    [Test]
    [HandlerFunctions('PhysInventoryOrderLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoPosDiffLinesDrillDownPhysInvtOrderStatistics()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderStatistics: TestPage "Phys. Invt. Order Statistics";
    begin
        // [SCENARIO] validate Trigger OnDrillDown of NoPosDiffLines on Page Phys. Invt. Order Statistics.
        // Setup: Create Physical Inventory Order and open Physical Inventory Order Statistics page.
        Initialize();
        OpenPhysInvtOrderStatisticsPage(PhysInvtOrderStatistics, PhysInvtOrderLine."Entry Type"::"Positive Adjmt.", 1, false);  // Quantity (Base) - 1 and Without Difference - False.

        // Exercise.
        PhysInvtOrderStatistics.NoPosDiffLines.DrillDown();  // Open page in PhysInventoryOrderLinesPageHandler.

        // [THEN] Verify NoPosDiffLines on Physical Inventory Order Statistics page and Entry Type and Quantity Base verify in Page handler - PhysInventoryOrderLinesPageHandler.
        PhysInvtOrderStatistics.NoPosDiffLines.AssertEquals(1);
        PhysInvtOrderStatistics.Close();
    end;

    [Test]
    [HandlerFunctions('PhysInventoryOrderLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoNegDiffLinesDrillDownPhysInvtOrderStatistics()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderStatistics: TestPage "Phys. Invt. Order Statistics";
    begin
        // [SCENARIO] validate Trigger OnDrillDown of NoNegDiffLines on Page Phys. Invt. Order Statistics.
        // Setup: Create Physical Inventory Order and open Physical Inventory Order Statistics page.
        Initialize();
        OpenPhysInvtOrderStatisticsPage(PhysInvtOrderStatistics, PhysInvtOrderLine."Entry Type"::"Negative Adjmt.", 0, false);  // Quantity (Base) - 0 and Without Difference - False.

        // Exercise.
        PhysInvtOrderStatistics.NoNegDiffLines.DrillDown();  // Open page in PhysInventoryOrderLinesPageHandler.

        // [THEN] Verify NoNegDiffLines on Physical Inventory Order Statistics page and Entry Type and Quantity Base verify in Page handler - PhysInventoryOrderLinesPageHandler.
        PhysInvtOrderStatistics.NoNegDiffLines.AssertEquals(1);
        PhysInvtOrderStatistics.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPostedPhysInvtOrderStatError()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PostedPhysInvtOrderStat: TestPage "Posted Phys. Invt. Order Stat.";
        PostedPhysInvtOrder: TestPage "Posted Phys. Invt. Order";
    begin
        // [SCENARIO] validate Trigger OnAfterGetRecord on Page Posted Phys. Invt. Order Stat.
        // Setup: Create Posted Physical Inventory Order and open Posted Physical Inventory Order page.
        OpenPostedPhysInventoryOrderPage(
          PostedPhysInvtOrder, CreatePostedPhysInventoryOrder(PstdPhysInvtOrderLine."Entry Type"::" ", 0, false));  // Quantity (Base) - 0 and Without Difference - False.

        // [WHEN] Open Posted Physical Inventory Order Statistics page.
        PostedPhysInvtOrderStat.Trap();
        asserterror PostedPhysInvtOrder.Statistics.Invoke();

        // [THEN] Verify Error Code, Error Msg - Unknown Entry type.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoCorrectLinesDrillDownPostedPhysInvtOrderStat()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PostedPhysInvtOrderStat: TestPage "Posted Phys. Invt. Order Stat.";
    begin
        // [SCENARIO] validate Trigger OnDrillDown of NoCorrectLines on Page Posted Phys. Invt. Order Stat.
        // Setup: Create Posted Physical Inventory Order and open Posted Physical Inventory Order Statistics page.
        Initialize();
        OpenPostedPhysInvtOrderStatisticsPage(
          PostedPhysInvtOrderStat, PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.", 0, true);  // Quantity (Base) - 0 and Without Difference - True.

        // Exercise.
        PostedPhysInvtOrderStat.NoCorrectLines.DrillDown();  // Open page in PstdPhysInvtOrderLinesPageHandler.

        // [THEN] Verify NoCorrectLines on Posted Physical Inventory Order Statistics page and Entry Type and Quantity Base verify in Page handler - PstdPhysInvtOrderLinesPageHandler.
        PostedPhysInvtOrderStat.NoCorrectLines.AssertEquals(1);
        PostedPhysInvtOrderStat.Close();
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoPosDiffLinesDrillDownPostedPhysInvtOrderStat()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PostedPhysInvtOrderStat: TestPage "Posted Phys. Invt. Order Stat.";
    begin
        // [SCENARIO] Validate Trigger OnDrillDown of NoPosDiffLines on Page Posted Phys. Invt. Order Stat.
        // [GIVEN]: Create Posted Physical Inventory Order Pos Line with Expected Qty = 1 and Recorded Qty = 0
        Initialize();
        OpenPostedPhysInvtOrderStatisticsPage(PostedPhysInvtOrderStat, PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.", 1, false);  // Quantity (Base) - 1 and Without Difference - False.

        // [WHEN] Open Posted Physical Inventory Order Statistics page.
        PostedPhysInvtOrderStat.NoPosDiffLines.DrillDown();  // Open page in PstdPhysInvtOrderLinesPageHandler.

        // [THEN] Verify NoPosDiffLines on Posted Physical Inventory Order Statistics page and Entry Type and Quantity Base verify in Page handler - PstdPhysInvtOrderLinesPageHandler.
        // [THEN] DiffAmountPosDiffLines should be -1
        PostedPhysInvtOrderStat.NoPosDiffLines.AssertEquals(1);
        PostedPhysInvtOrderStat.DiffAmountPosDiffLines.AssertEquals(-1);
        PostedPhysInvtOrderStat.Close();
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoNegDiffLinesDrillDownPostedPhysInvtOrderStat()
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PostedPhysInvtOrderStat: TestPage "Posted Phys. Invt. Order Stat.";
    begin
        // [SCENARIO] Validate Trigger OnDrillDown of NoNegDiffLines on Page Posted Phys. Invt. Order Stat.
        // [GIVEN]: Create Posted Physical Inventory Order Neg Line with Expected Qty = 1 and Recorded Qty = 0
        Initialize();
        OpenPostedPhysInvtOrderStatisticsPage(PostedPhysInvtOrderStat, PstdPhysInvtOrderLine."Entry Type"::"Negative Adjmt.", 0, false);  // Quantity (Base) - 0 and Without Difference - False.

        // [WHEN] Open Posted Physical Inventory Order Statistics page.
        PostedPhysInvtOrderStat.NoNegDiffLines.DrillDown();  // Open page in PstdPhysInvtOrderLinesPageHandler.

        // [THEN] Verify NoNegDiffLines on Posted Physical Inventory Order Statistics page and Entry Type and Quantity Base verify in Page handler - PstdPhysInvtOrderLinesPageHandler.
        // [THEN] DiffAmountPosDiffLines should be -1
        PostedPhysInvtOrderStat.NoNegDiffLines.AssertEquals(1);
        PostedPhysInvtOrderStat.DiffAmountNegDiffLines.AssertEquals(-1);
        PostedPhysInvtOrderStat.Close();
    end;

    [Test]
    [HandlerFunctions('CopyPhysInvtOrderRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyDocumentPhysInventoryOrder()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderHeader2: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Item: Record Item;
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        // [SCENARIO] validate function CopyDocument of Page Phys. Inventory Order.

        // Setup: Create Physical Inventory Order with Line, and create another Physical Inventory Order Header.
        Initialize();
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader2);

        // [WHEN] Invoke Action - CopyDocument of Page Physical Inventory Order.
        Commit();  // COMMIT required because explicit COMMIT in OnPreReport Trigger of Report Copy Phys. Invt. Order.
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside CopyPhysInvtOrderRequestPageHandler.
        PhysInventoryOrder.OpenEdit();
        PhysInventoryOrder.FILTER.SetFilter("No.", PhysInvtOrderHeader2."No.");
        PhysInventoryOrder.CopyDocument.Invoke();
        PhysInventoryOrder.Close();

        // [THEN] Verify Physical Inventory Order Line successfully copied to second Physical Inventory Order.
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader2."No.");
        PhysInvtOrderLine.FindFirst();
        PhysInvtOrderLine.TestField("Item No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('PhysInvtOrderTestReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestReportPhysInventoryOrder()
    var
        ReportSelections: Record "Report Selections";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        // [SCENARIO] validate function TestReport of Page Phys. Inventory Order.
        // Setup.
        CreateReportSelections(ReportSelections.Usage::"Phys.Invt.Order Test", REPORT::"Phys. Invt. Order - Test");
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);

        // Exercise & Verify: Invoke Action - TestReport on Page Phys. Inventory Order. Verify Physical Invt. Order Test report opens up.
        PhysInventoryOrder.OpenEdit();
        PhysInventoryOrder.FILTER.SetFilter("No.", PhysInvtOrderHeader."No.");
        PhysInventoryOrder.TestReport.Invoke();  // Invokes PhysInvtOrderTestReportHandler.
        PhysInventoryOrder.Close();
    end;

    [Test]
    [HandlerFunctions('CopyPhysInvtOrderRequestPageHandler,MessageHandlerValidateText')]
    [Scope('OnPrem')]
    procedure ValidateMessageOnCopyDocumentPhysInventoryOrder()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderHeader2: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        // [SCENARIO 507018] Non-meaningful placeholder in the copy document notification for the physical inventory orders.
        Initialize();

        // [GIVEN] Setup: Create Physical Inventory Order with Line, and create another Physical Inventory Order Header.
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader2);

        // [WHEN] Invoke Action - CopyDocument of Page Physical Inventory Order.
        Commit();  // COMMIT required because explicit COMMIT in OnPreReport Trigger of Report Copy Phys. Invt. Order.
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeader."No.");  // Required inside CopyPhysInvtOrderRequestPageHandler.

        // [THEN] Message is displayed informing that one order line was inserted verifying in MessageHandlerValidateText 
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.FindSet();
        LibraryVariableStorage.Enqueue(StrSubstNo(LinesInsertedToOrderMsg, PhysInvtOrderLine.Count, PhysInvtOrderHeader2."No."));
        PhysInventoryOrder.OpenEdit();
        PhysInventoryOrder.FILTER.SetFilter("No.", PhysInvtOrderHeader2."No.");
        PhysInventoryOrder.CopyDocument.Invoke();
        PhysInventoryOrder.Close();

        // [THEN] Verify: Physical Inventory Order Line successfully copied to second Physical Inventory Order.
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader2."No.");
        PhysInvtOrderLine.FindFirst();
        PhysInvtOrderLine.TestField("Item No.", Item."No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionSetID: Integer)
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue."Dimension Code" := LibraryUTUtility.GetNewCode();
        DimensionValue.Code := LibraryUTUtility.GetNewCode();
        DimensionValue.Insert();

        DimensionSetEntry."Dimension Set ID" := DimensionSetID;
        DimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimensionSetEntry.Insert();
    end;

    local procedure CreateReportSelections(Usage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := LibraryUTUtility.GetNewCode10();
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    local procedure CreatePostedPhysInvtOrderHeader(var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr")
    begin
        PstdPhysInvtOrderHdr."No." := LibraryUTUtility.GetNewCode();
        PstdPhysInvtOrderHdr."Posting Date" := WorkDate();
        PstdPhysInvtOrderHdr.Insert();
    end;

    local procedure CreatePostedPhysInvtOrderLine(var PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line"; DocumentNo: Code[20])
    begin
        PstdPhysInvtOrderLine."Document No." := DocumentNo;
        PstdPhysInvtOrderLine."Line No." := 1;
        PstdPhysInvtOrderLine."Item No." := LibraryUTUtility.GetNewCode();
        PstdPhysInvtOrderLine.Insert();
    end;

    local procedure CreatePostedPhysInvtRecHeader(var PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr"; OrderNo: Code[20])
    begin
        PstdPhysInvtRecordHdr."Order No." := OrderNo;
        PstdPhysInvtRecordHdr."Recording No." := 1;
        PstdPhysInvtRecordHdr.Insert();
    end;

    local procedure CreatePhysInvtRecordingHeader(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; OrderNo: Code[20])
    begin
        PhysInvtRecordHeader."Order No." := OrderNo;
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Insert();
    end;

    local procedure CreatePhysInventoryLedgerEntry(var PhysInventoryLedgerEntry2: Record "Phys. Inventory Ledger Entry")
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        PhysInventoryLedgerEntry.FindLast();
        if PhysInventoryLedgerEntry."Entry No." = 0 then
            PhysInventoryLedgerEntry2."Entry No." := 1
        else
            PhysInventoryLedgerEntry2."Entry No." := PhysInventoryLedgerEntry."Entry No." + 1;
        PhysInventoryLedgerEntry2."Document No." := LibraryUTUtility.GetNewCode();
        PhysInventoryLedgerEntry2."Posting Date" := WorkDate();
        PhysInventoryLedgerEntry2.Insert();
    end;

    local procedure CreatePostedExpInvtOrderTracking(var PstdExpInvtOrderTracking: Record "Pstd.Exp.Invt.Order.Tracking"; DocumentNo: Code[20]; OrderLineNo: Integer)
    begin
        PstdExpInvtOrderTracking."Order No" := DocumentNo;
        PstdExpInvtOrderTracking."Order Line No." := OrderLineNo;
        PstdExpInvtOrderTracking."Serial No." := LibraryUTUtility.GetNewCode();
        PstdExpInvtOrderTracking."Lot No." := LibraryUTUtility.GetNewCode();
        PstdExpInvtOrderTracking."Package No." := LibraryUTUtility.GetNewCode();
        PstdExpInvtOrderTracking."Quantity (Base)" := 1;
        PstdExpInvtOrderTracking.Insert();
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();
    end;

    local procedure OpenPageNavigate(DocumentNo: Code[20])
    var
        Navigate: Page Navigate;
    begin
        // Set Document for Navigate with Posting Date and Document No.
        Navigate.SetDoc(WorkDate(), DocumentNo);
        Navigate.Run();
    end;

    local procedure CreatePhysInventoryOrder(EntryType: Option; QuantityBase: Decimal; WithoutDifference: Boolean): Code[20]
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // Create Physical Inventory Order Header.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        PhysInvtOrderHeader.Status := PhysInvtOrderHeader.Status::Finished;
        PhysInvtOrderHeader.Modify();

        // Create Physical Inventory Order Line.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", LibraryUTUtility.GetNewCode());
        PhysInvtOrderLine."Entry Type" := EntryType;
        PhysInvtOrderLine."Quantity (Base)" := QuantityBase;
        PhysInvtOrderLine."Without Difference" := WithoutDifference;
        PhysInvtOrderLine.Modify();
        exit(PhysInvtOrderHeader."No.");
    end;

    local procedure CreatePhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        PhysInvtOrderLine."Document No." := PhysInvtOrderHeaderNo;
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Item No." := ItemNo;
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePostedPhysInventoryOrder(EntryType: Option; QuantityBase: Decimal; WithoutDifference: Boolean): Code[20]
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // Create Posted Physical Inventory Order Header.
        CreatePostedPhysInvtOrderHeader(PstdPhysInvtOrderHdr);
        PstdPhysInvtOrderHdr.Status := PstdPhysInvtOrderHdr.Status::Finished;
        PstdPhysInvtOrderHdr.Modify();

        // Create Posted Physical Inventory Order Line.
        CreatePostedPhysInvtOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderHdr."No.");
        PstdPhysInvtOrderLine."Entry Type" := EntryType;
        PstdPhysInvtOrderLine."Quantity (Base)" := QuantityBase;
        PstdPhysInvtOrderLine."Qty. Expected (Base)" := 1;
        PstdPhysInvtOrderLine."Unit Amount" := 1;
        PstdPhysInvtOrderLine."Without Difference" := WithoutDifference;
        PstdPhysInvtOrderLine.Modify();
        exit(PstdPhysInvtOrderHdr."No.");
    end;

    local procedure OpenPhysInventoryOrderPage(var PhysInventoryOrder: TestPage "Physical Inventory Order"; No: Code[20])
    begin
        PhysInventoryOrder.OpenEdit();
        PhysInventoryOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPostedPhysInventoryOrderPage(var PostedPhysInvtOrder: TestPage "Posted Phys. Invt. Order"; No: Code[20])
    begin
        PostedPhysInvtOrder.OpenEdit();
        PostedPhysInvtOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPhysInvtOrderStatisticsPage(var PhysInvtOrderStatistics: TestPage "Phys. Invt. Order Statistics"; EntryType: Option; QuantityBase: Decimal; WithoutDifference: Boolean)
    var
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        OpenPhysInventoryOrderPage(PhysInventoryOrder, CreatePhysInventoryOrder(EntryType, QuantityBase, WithoutDifference));

        // Enqueue value for Page handler PhysInventoryOrderLinesPageHandler.
        LibraryVariableStorage.Enqueue(EntryType);
        LibraryVariableStorage.Enqueue(QuantityBase);
        PhysInvtOrderStatistics.Trap();
        PhysInventoryOrder.Statistics.Invoke();
    end;

    local procedure OpenPostedPhysInvtOrderStatisticsPage(var PostedPhysInvtOrderStat: TestPage "Posted Phys. Invt. Order Stat."; EntryType: Option; QuantityBase: Decimal; WithoutDifference: Boolean)
    var
        PostedPhysInvtOrder: TestPage "Posted Phys. Invt. Order";
    begin
        OpenPostedPhysInventoryOrderPage(PostedPhysInvtOrder, CreatePostedPhysInventoryOrder(EntryType, QuantityBase, WithoutDifference));

        // Enqueue value for Page handler PstdPhysInvtOrderLinesPageHandler.
        LibraryVariableStorage.Enqueue(EntryType);
        LibraryVariableStorage.Enqueue(QuantityBase);
        PostedPhysInvtOrderStat.Trap();
        PostedPhysInvtOrder.Statistics.Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtOrderDiffReportHandler(var PostedPhysInvtOrderDiff: Report "Posted Phys. Invt. Order Diff.")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecordingReportHandler(var PostedPhysInvtRecording: Report "Posted Phys. Invt. Recording")
    begin
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PhysInvtRecordingReportHandler(var PhysInvtRecording: Report "Phys. Invt. Recording")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostPhysInvtOrderNavigatePageHandler(var Navigate: TestPage Navigate)
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        Navigate."Table Name".AssertEquals(PstdPhysInvtOrderHdr.TableName);
        Navigate."No. of Records".AssertEquals(1);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtLedgEntryNavigatePageHandler(var Navigate: TestPage Navigate)
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        Navigate."Table Name".AssertEquals(PhysInventoryLedgerEntry.TableName);
        Navigate."No. of Records".AssertEquals(1);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ShowPostPhysInvtOrderNavigatePageHandler(var Navigate: TestPage Navigate)
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
    begin
        Navigate.FindFirstField("Table Name", PstdPhysInvtOrderHdr.TableName);
        Navigate.Show.Invoke();  // Opens PostedPhysInvtOrderListPageHandler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtOrderListPageHandler(var PostedPhysInvtOrderList: TestPage "Posted Phys. Invt. Order List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PostedPhysInvtOrderList."No.".AssertEquals(No);
        PostedPhysInvtOrderList."Posting Date".AssertEquals(WorkDate());
        PostedPhysInvtOrderList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ShowPhysInvtLedgEntryNavigatePageHandler(var Navigate: TestPage Navigate)
    begin
        Navigate.FindFirstField("Table Name", 'Phys. Inventory Ledger Entry');
        Navigate.Show.Invoke();  // Opens PhysInventoryLedgerEntriesPageHandler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntriesPageHandler(var PhysInventoryLedgerEntries: TestPage "Phys. Inventory Ledger Entries")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PhysInventoryLedgerEntries."Document No.".AssertEquals(DocumentNo);
        PhysInventoryLedgerEntries."Posting Date".AssertEquals(WorkDate());
        PhysInventoryLedgerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesPageHandler(var DimensionSetEntries: TestPage "Dimension Set Entries")
    var
        DimensionCode: Variant;
        DimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        LibraryVariableStorage.Dequeue(DimensionValueCode);
        DimensionSetEntries."Dimension Code".AssertEquals(DimensionCode);
        DimensionSetEntries.DimensionValueCode.AssertEquals(DimensionValueCode);
        DimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedExpInvtOrderTrackingPageHandler(var PostedExpInvtOrderTracking: TestPage "Posted.Exp.Invt.Order.Tracking")
    var
        OrderNo: Variant;
        SerialNo: Variant;
        LotNo: Variant;
        PackageNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(PackageNo);
        PostedExpInvtOrderTracking."Serial No.".AssertEquals(SerialNo);
        PostedExpInvtOrderTracking."Lot No.".AssertEquals(LotNo);
        PostedExpInvtOrderTracking."Package No.".AssertEquals(PackageNo);
        PostedExpInvtOrderTracking."Quantity (Base)".AssertEquals(1);
        PostedExpInvtOrderTracking."Order No".AssertEquals(OrderNo);
        PostedExpInvtOrderTracking."Order Line No.".AssertEquals(1);
        PostedExpInvtOrderTracking.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecLinesPageHandler(var PostedPhysInvtRecLines: TestPage "Posted Phys. Invt. Rec. Lines")
    var
        OrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        PostedPhysInvtRecLines."Order No.".AssertEquals(OrderNo);
        PostedPhysInvtRecLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryOrderLinesPageHandler(var PhysInventoryOrderLines: TestPage "Physical Inventory Order Lines")
    var
        EntryType: Variant;
        QuantityBase: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryType);
        LibraryVariableStorage.Dequeue(QuantityBase);
        PhysInventoryOrderLines."Entry Type".AssertEquals(EntryType);
        PhysInventoryOrderLines."Quantity (Base)".AssertEquals(QuantityBase);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtOrderLinesPageHandler(var PostedPhysInvtOrderLines: TestPage "Posted Phys. Invt. Order Lines")
    var
        EntryType: Variant;
        QuantityBase: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryType);
        LibraryVariableStorage.Dequeue(QuantityBase);
        PostedPhysInvtOrderLines."Entry Type".AssertEquals(EntryType);
        PostedPhysInvtOrderLines."Quantity (Base)".AssertEquals(QuantityBase);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPhysInvtOrderRequestPageHandler(var CopyPhysInvtOrder: TestRequestPage "Copy Phys. Invt. Order")
    var
        PhysInvtOrderHeaderNo: Variant;
        DocumentType: Option "Phys. Invt. Order","Posted Phys. Invt. Order ";
    begin
        LibraryVariableStorage.Dequeue(PhysInvtOrderHeaderNo);
        CopyPhysInvtOrder.DocumentType.SetValue(Format(DocumentType::"Phys. Invt. Order"));
        CopyPhysInvtOrder.DocumentNo.SetValue(PhysInvtOrderHeaderNo);
        CopyPhysInvtOrder.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PhysInvtOrderTestReportHandler(var PhysInvtOrderTest: Report "Phys. Invt. Order - Test")
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateText(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;
}

