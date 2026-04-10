codeunit 134562 "Object Selection"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Object Selection]
    end;

    var
        Assert: Codeunit Assert;
        CalcFieldValueErr: Label 'CalcField %1 was not calculated correctly', Comment = '@1 = CalcFieldRef';
        CalcFieldLengthErr: Label 'Length of CalcField %1 does not fit referenced object caption', Comment = '%1 = CalcFieldRef';
        LibraryUtility: Codeunit "Library - Utility";
        ReportSelectionErr: Label 'There is no Report Selections within the filter';

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowReportSelection()
    var
        CashFlowReportSelection: Record "Cash Flow Report Selection";
    begin
        RunReportTest(
          DATABASE::"Cash Flow Report Selection",
          CashFlowReportSelection.FieldNo("Report ID"),
          CashFlowReportSelection.FieldNo("Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostJournalTemplate()
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        RunReportTest(
          DATABASE::"Cost Journal Template",
          CostJournalTemplate.FieldNo("Posting Report ID"),
          CostJournalTemplate.FieldNo("Posting Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResJournalTemplate()
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        RunReportTest(
          DATABASE::"Res. Journal Template",
          ResJournalTemplate.FieldNo("Test Report ID"),
          ResJournalTemplate.FieldNo("Test Report Caption"));
        RunPageTest(
          DATABASE::"Res. Journal Template",
          ResJournalTemplate.FieldNo("Page ID"),
          ResJournalTemplate.FieldNo("Page Caption"));
        RunReportTest(
          DATABASE::"Res. Journal Template",
          ResJournalTemplate.FieldNo("Posting Report ID"),
          ResJournalTemplate.FieldNo("Posting Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalTemplate()
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        RunReportTest(
          DATABASE::"Job Journal Template",
          JobJournalTemplate.FieldNo("Test Report ID"),
          JobJournalTemplate.FieldNo("Test Report Caption"));
        RunPageTest(
          DATABASE::"Job Journal Template",
          JobJournalTemplate.FieldNo("Page ID"),
          JobJournalTemplate.FieldNo("Page Caption"));
        RunReportTest(
          DATABASE::"Job Journal Template",
          JobJournalTemplate.FieldNo("Posting Report ID"),
          JobJournalTemplate.FieldNo("Posting Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWkshTemplate()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        RunPageTest(
          DATABASE::"Req. Wksh. Template",
          ReqWkshTemplate.FieldNo("Page ID"),
          ReqWkshTemplate.FieldNo("Page Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATStatementTemplate()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        RunReportTest(
          DATABASE::"VAT Statement Template",
          VATStatementTemplate.FieldNo("VAT Statement Report ID"),
          VATStatementTemplate.FieldNo("VAT Statement Report Caption"));
        RunPageTest(
          DATABASE::"VAT Statement Template",
          VATStatementTemplate.FieldNo("Page ID"),
          VATStatementTemplate.FieldNo("Page Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimension()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        RunTableTest(
          DATABASE::"Default Dimension",
          DefaultDimension.FieldNo("Table ID"),
          DefaultDimension.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionPriority()
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
    begin
        RunTableTest(
          DATABASE::"Default Dimension Priority",
          DefaultDimensionPriority.FieldNo("Table ID"),
          DefaultDimensionPriority.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeLogSetupTable()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        RunTableTest(
          DATABASE::"Change Log Setup (Table)",
          ChangeLogSetupTable.FieldNo("Table No."),
          ChangeLogSetupTable.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeLogEntry()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        RunTableTest(
          DATABASE::"Change Log Entry",
          ChangeLogEntry.FieldNo("Table No."),
          ChangeLogEntry.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntry()
    var
        AllObj: Record AllObj;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        RunTestWithObjectType(
          DATABASE::"Job Queue Entry",
          JobQueueEntry.FieldNo("Object Type to Run"),
          JobQueueEntry.FieldNo("Object ID to Run"),
          JobQueueEntry.FieldNo("Object Caption to Run"),
          AllObj."Object Type"::Report);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueLogEntry()
    var
        AllObj: Record AllObj;
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        RunTestWithObjectType(
          DATABASE::"Job Queue Log Entry",
          JobQueueLogEntry.FieldNo("Object Type to Run"),
          JobQueueLogEntry.FieldNo("Object ID to Run"),
          JobQueueLogEntry.FieldNo("Object Caption to Run"),
          AllObj."Object Type"::Report);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentCriteriaLine()
    var
        SegmentCriteriaLine: Record "Segment Criteria Line";
    begin
        RunTableTest(
          DATABASE::"Segment Criteria Line",
          SegmentCriteriaLine.FieldNo("Table No."),
          SegmentCriteriaLine.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SavedSegmentCriteriaLine()
    var
        SavedSegmentCriteriaLine: Record "Saved Segment Criteria Line";
    begin
        RunTableTest(
          DATABASE::"Saved Segment Criteria Line",
          SavedSegmentCriteriaLine.FieldNo("Table No."),
          SavedSegmentCriteriaLine.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalTemplate()
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        RunReportTest(
          DATABASE::"FA Journal Template",
          FAJournalTemplate.FieldNo("Test Report ID"),
          FAJournalTemplate.FieldNo("Test Report Caption"));
        RunPageTest(
          DATABASE::"FA Journal Template",
          FAJournalTemplate.FieldNo("Page ID"),
          FAJournalTemplate.FieldNo("Page Caption"));
        RunReportTest(
          DATABASE::"FA Journal Template",
          FAJournalTemplate.FieldNo("Posting Report ID"),
          FAJournalTemplate.FieldNo("Posting Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAReclassJournalTemplate()
    var
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
    begin
        RunPageTest(
          DATABASE::"FA Reclass. Journal Template",
          FAReclassJournalTemplate.FieldNo("Page ID"),
          FAReclassJournalTemplate.FieldNo("Page Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsuranceJournalTemplate()
    var
        InsuranceJournalTemplate: Record "Insurance Journal Template";
    begin
        RunReportTest(
          DATABASE::"Insurance Journal Template",
          InsuranceJournalTemplate.FieldNo("Test Report ID"),
          InsuranceJournalTemplate.FieldNo("Test Report Caption"));
        RunPageTest(
          DATABASE::"Insurance Journal Template",
          InsuranceJournalTemplate.FieldNo("Page ID"),
          InsuranceJournalTemplate.FieldNo("Page Caption"));
        RunReportTest(
          DATABASE::"Insurance Journal Template",
          InsuranceJournalTemplate.FieldNo("Posting Report ID"),
          InsuranceJournalTemplate.FieldNo("Posting Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseJournalTemplate()
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        RunReportTest(
          DATABASE::"Warehouse Journal Template",
          WarehouseJournalTemplate.FieldNo("Test Report ID"),
          WarehouseJournalTemplate.FieldNo("Test Report Caption"));
        RunPageTest(
          DATABASE::"Warehouse Journal Template",
          WarehouseJournalTemplate.FieldNo("Page ID"),
          WarehouseJournalTemplate.FieldNo("Page Caption"));
        RunReportTest(
          DATABASE::"Warehouse Journal Template",
          WarehouseJournalTemplate.FieldNo("Registering Report ID"),
          WarehouseJournalTemplate.FieldNo("Registering Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseWorksheetTemplate()
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        RunPageTest(
          DATABASE::"Whse. Worksheet Template",
          WhseWorksheetTemplate.FieldNo("Page ID"),
          WhseWorksheetTemplate.FieldNo("Page Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCreationWkshTemplate()
    var
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
    begin
        RunPageTest(
          DATABASE::"Bin Creation Wksh. Template",
          BinCreationWkshTemplate.FieldNo("Page ID"),
          BinCreationWkshTemplate.FieldNo("Page Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportSelections()
    var
        ReportSelections: Record "Report Selections";
    begin
        RunReportTest(
          DATABASE::"Report Selections",
          ReportSelections.FieldNo("Report ID"),
          ReportSelections.FieldNo("Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrinterSelection()
    var
        PrinterSelection: Record "Printer Selection";
    begin
        RunReportTest(
          DATABASE::"Printer Selection",
          PrinterSelection.FieldNo("Report ID"),
          PrinterSelection.FieldNo("Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        RunReportTest(
          DATABASE::"Gen. Journal Template",
          GenJournalTemplate.FieldNo("Test Report ID"),
          GenJournalTemplate.FieldNo("Test Report Caption"));
        RunPageTest(
          DATABASE::"Gen. Journal Template",
          GenJournalTemplate.FieldNo("Page ID"),
          GenJournalTemplate.FieldNo("Page Caption"));
        RunReportTest(
          DATABASE::"Gen. Journal Template",
          GenJournalTemplate.FieldNo("Posting Report ID"),
          GenJournalTemplate.FieldNo("Posting Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalTemplate()
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        RunReportTest(
          DATABASE::"Item Journal Template",
          ItemJournalTemplate.FieldNo("Test Report ID"),
          ItemJournalTemplate.FieldNo("Test Report Caption"));
        RunPageTest(
          DATABASE::"Item Journal Template",
          ItemJournalTemplate.FieldNo("Page ID"),
          ItemJournalTemplate.FieldNo("Page Caption"));
        RunReportTest(
          DATABASE::"Item Journal Template",
          ItemJournalTemplate.FieldNo("Posting Report ID"),
          ItemJournalTemplate.FieldNo("Posting Report Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigQuestionArea()
    var
        ConfigQuestionArea: Record "Config. Question Area";
    begin
        RunTableTest(
          DATABASE::"Config. Question Area",
          ConfigQuestionArea.FieldNo("Table ID"),
          ConfigQuestionArea.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigPackageTable()
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        RunTableTest(
          DATABASE::"Config. Package Table",
          ConfigPackageTable.FieldNo("Table ID"),
          ConfigPackageTable.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateHeader()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        RunTableTest(
          DATABASE::"Config. Template Header",
          ConfigTemplateHeader.FieldNo("Table ID"),
          ConfigTemplateHeader.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigTemplateLine()
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        RunTableTest(
          DATABASE::"Config. Template Line",
          ConfigTemplateLine.FieldNo("Table ID"),
          ConfigTemplateLine.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateComprRegister()
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        RunTableTest(
          DATABASE::"Date Compr. Register",
          DateComprRegister.FieldNo("Table ID"),
          DateComprRegister.FieldNo("Table Caption"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOrderInReportSelectionInventory()
    var
        ReportSelectionInventory: TestPage "Report Selection - Inventory";
        ReportUsage2: Option "Transfer Order","Transfer Shipment","Transfer Receipt","Inventory Period Test","Asm. Order","P.Assembly Order";
    begin
        // [FEATURE] [Report Selection] [Assembly]
        // [SCENARIO 375912] Report Selection - Inventory should include Assembly Order
        ReportSelectionInventory.OpenEdit();

        // [WHEN] Set "Asm.Order" for Usage in Report Selection Inventory Page
        ReportSelectionInventory.ReportUsage2.SetValue(ReportUsage2::"Asm. Order");

        // [THEN] "Report ID" is 902 (Assembly Order)
        ReportSelectionInventory."Report ID".AssertEquals(REPORT::"Assembly Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedAssemblyOrderInReportSelectionInventory()
    var
        ReportSelectionInventory: TestPage "Report Selection - Inventory";
        ReportUsage2: Option "Transfer Order","Transfer Shipment","Transfer Receipt","Inventory Period Test","Asm. Order","P.Assembly Order";
    begin
        // [FEATURE] [Report Selection] [Assembly]
        // [SCENARIO 375912] Report Selection - Inventory should include Posted Assembly Order
        ReportSelectionInventory.OpenEdit();

        // [WHEN] Set "P.Asm.Order" for Usage in Report Selection Inventory Page
        ReportSelectionInventory.ReportUsage2.SetValue(ReportUsage2::"P.Assembly Order");

        // [THEN] "Report ID" is 910 (Posted Assembly Order)
        ReportSelectionInventory."Report ID".AssertEquals(REPORT::"Posted Assembly Order");
    end;

    [Test]
    [HandlerFunctions('ProdOrderJobCardHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardOnFirmPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderJobCard" of "Firm Planned Prod. Orders" Page should run "Prod. Order - Job Card" Report

        // [GIVEN] Report Selection for M1
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M1, REPORT::"Prod. Order - Job Card");
        FirmPlannedProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderJobCard" action on "Firm Planned Prod. Order" Page
        Commit();
        FirmPlannedProdOrders.ProdOrderJobCard.Invoke();

        // [THEN] Report "Prod. Order - Job Card" is run
        // Verify through ProdOrderJobCardHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderMatRequisitionHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderMaterialRequisitionOnFirmPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderMaterialRequisition" of "Firm Planned Prod. Orders" Page should run "Prod. Order - Mat. Requisition" Report

        // [GIVEN] Report Selection for M2
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M2, REPORT::"Prod. Order - Mat. Requisition");
        FirmPlannedProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderMaterialRequisition" action on "Firm Planned Prod. Order" Page
        Commit();
        FirmPlannedProdOrders.ProdOrderMaterialRequisition.Invoke();

        // [THEN] Report "Prod. Order - Mat. Requisition" is run
        // Verify through ProdOrderMatRequisitionHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListOnFirmPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderShortageList" of "Firm Planned Prod. Orders" Page should run "Prod. Order - Shortage List" Report

        // [GIVEN] Report Selection for M3
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M3, REPORT::"Prod. Order - Shortage List");
        FirmPlannedProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderShortageList" action on "Firm Planned Prod. Order" Page
        Commit();
        FirmPlannedProdOrders.ProdOrderShortageList.Invoke();

        // [THEN] Report "Prod. Order - Shortage List" is run
        // Verify through ProdOrderShortageListHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderJobCardHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardOnRelPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        RelProdOrders: TestPage "Released Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderJobCard" of "Released Production Orders" Page should run "Prod. Order - Job Card" Report

        // [GIVEN] Report Selection for M1
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M1, REPORT::"Prod. Order - Job Card");
        RelProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderJobCard" action on "Released Production Orders" Page
        Commit();
        RelProdOrders.ProdOrderJobCard.Invoke();

        // [THEN] Report "Prod. Order - Job Card" is run
        // Verify through ProdOrderJobCardHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderMatRequisitionHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderMaterialRequisitionOnRelPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        RelProdOrders: TestPage "Released Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderMaterialRequisition" of "Released Production Orders" Page should run "Prod. Order - Mat. Requisition" Report

        // [GIVEN] Report Selection for M2
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M2, REPORT::"Prod. Order - Mat. Requisition");
        RelProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderMaterialRequisition" action on "Released Production Orders" Page
        Commit();
        RelProdOrders.ProdOrderMaterialRequisition.Invoke();

        // [THEN] Report "Prod. Order - Mat. Requisition" is run
        // Verify through ProdOrderMatRequisitionHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListOnRelPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        RelProdOrders: TestPage "Released Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderShortageList" of "Released Production Orders" Page should run "Prod. Order - Shortage List" Report

        // [GIVEN] Report Selection for M3
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M3, REPORT::"Prod. Order - Shortage List");
        RelProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderShortageList" action on "Released Production Orders" Page
        Commit();
        RelProdOrders.ProdOrderShortageList.Invoke();

        // [THEN] Report "Prod. Order - Shortage List" is run
        // Verify through ProdOrderShortageListHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderJobCardHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardOnFinPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        FinProdOrders: TestPage "Finished Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderJobCard" of "Finished Production Orders" Page should run "Prod. Order - Job Card" Report

        // [GIVEN] Report Selection for M1
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M1, REPORT::"Prod. Order - Job Card");
        FinProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderJobCard" action on "Finished Production Orders" Page
        Commit();
        FinProdOrders.ProdOrderJobCard.Invoke();

        // [THEN] Report "Prod. Order - Job Card" is run
        // Verify through ProdOrderJobCardHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderMatRequisitionHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderMaterialRequisitionOnFinPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        FinProdOrders: TestPage "Finished Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderMaterialRequisition" of "Finished Production Orders" Page should run "Prod. Order - Mat. Requisition" Report

        // [GIVEN] Report Selection for M2
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M2, REPORT::"Prod. Order - Mat. Requisition");
        FinProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderMaterialRequisition" action on "Finished Production Orders" Page
        Commit();
        FinProdOrders.ProdOrderMaterialRequisition.Invoke();

        // [THEN] Report "Prod. Order - Mat. Requisition" is run
        // Verify through ProdOrderMatRequisitionHandler
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListOnFinPlannedProdOrders()
    var
        ReportSelections: Record "Report Selections";
        FinProdOrders: TestPage "Finished Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderShortageList" of "Finished Production Orders" Page should run "Prod. Order - Shortage List" Report

        // [GIVEN] Report Selection for M3
        ReportSelections.DeleteAll();
        CreateReportSelection(ReportSelections.Usage::M3, REPORT::"Prod. Order - Shortage List");
        FinProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderShortageList" action on "Finished Production Orders" Page
        Commit();
        FinProdOrders.ProdOrderShortageList.Invoke();

        // [THEN] Report "Prod. Order - Shortage List" is run
        // Verify through ProdOrderShortageListHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardOnFirmPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderJobCard" of "Firm Planned Prod. Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M1
        ReportSelections.DeleteAll();
        FirmPlannedProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderJobCard" action on "Firm Planned Prod. Order" Page
        asserterror FirmPlannedProdOrders.ProdOrderJobCard.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderMaterialRequisitionOnFirmPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderMaterialRequisition" of "Firm Planned Prod. Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M2
        ReportSelections.DeleteAll();
        FirmPlannedProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderMaterialRequisition" action on "Firm Planned Prod. Order" Page
        asserterror FirmPlannedProdOrders.ProdOrderMaterialRequisition.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListOnFirmPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderShortageList" of "Firm Planned Prod. Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M3
        ReportSelections.DeleteAll();
        FirmPlannedProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderShortageList" action on "Firm Planned Prod. Order" Page
        asserterror FirmPlannedProdOrders.ProdOrderShortageList.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardOnRelPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        RelProdOrders: TestPage "Released Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderJobCard" of "Released Production Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M1
        ReportSelections.DeleteAll();
        RelProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderJobCard" action on "Released Production Orders" Page
        asserterror RelProdOrders.ProdOrderJobCard.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderMaterialRequisitionOnRelPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        RelProdOrders: TestPage "Released Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderMaterialRequisition" of "Released Production Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M2
        ReportSelections.DeleteAll();
        RelProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderMaterialRequisition" action on "Released Production Orders" Page
        asserterror RelProdOrders.ProdOrderMaterialRequisition.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListOnRelPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        RelProdOrders: TestPage "Released Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderShortageList" of "Released Production Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M3
        ReportSelections.DeleteAll();
        RelProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderShortageList" action on "Released Production Orders" Page
        asserterror RelProdOrders.ProdOrderShortageList.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardOnFinPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        FinProdOrders: TestPage "Finished Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderJobCard" of "Finished Production Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M1
        ReportSelections.DeleteAll();
        FinProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderJobCard" action on "Finished Production Orders" Page
        asserterror FinProdOrders.ProdOrderJobCard.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderMaterialRequisitionOnFinPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        FinProdOrders: TestPage "Finished Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderMaterialRequisition" of "Finished Production Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M2
        ReportSelections.DeleteAll();
        FinProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderMaterialRequisition" action on "Finished Production Orders" Page
        asserterror FinProdOrders.ProdOrderMaterialRequisition.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListOnFinPlannedProdOrdersError()
    var
        ReportSelections: Record "Report Selections";
        FinProdOrders: TestPage "Finished Production Orders";
    begin
        // [FEATURE] [UT] [Report Selection] [Production Order]
        // [SCENARIO 376612] "ProdOrderShortageList" of "Finished Production Orders" Page should fail if no Report Selection is setup

        // [GIVEN] No Report Selection for M3
        ReportSelections.DeleteAll();
        FinProdOrders.OpenNew();

        // [WHEN] Run "ProdOrderShortageList" action on "Finished Production Orders" Page
        asserterror FinProdOrders.ProdOrderShortageList.Invoke();

        // [THEN] Error is thrown: "There is no Report Selections within the filter"
        Assert.ExpectedError(ReportSelectionErr);
    end;

    local procedure RunTest(TableId: Integer; IdFieldNo: Integer; CalcFieldNo: Integer; ObjectType: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        CalcFieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        // Initiliaze
        InitCalcRecord(
          CalcFieldRef, AllObjWithCaption, RecRef, TableId, IdFieldNo, CalcFieldNo, ObjectType);

        // Excercise
        CalcFieldRef.CalcField();

        // Test
        VerifyCalculatedField(AllObjWithCaption, CalcFieldRef);
    end;

    local procedure RunTestWithObjectType(TableId: Integer; ObjectTypeFieldNo: Integer; IdFieldNo: Integer; CalcFieldNo: Integer; ObjectType: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        CalcFieldRef: FieldRef;
    begin
        // Initiliaze
        InitCalcRecordWithObjectType(
          CalcFieldRef, AllObjWithCaption, TableId, ObjectTypeFieldNo, IdFieldNo, CalcFieldNo,
          ObjectType);

        // Excercise
        CalcFieldRef.CalcField();

        // Test
        VerifyCalculatedField(AllObjWithCaption, CalcFieldRef);
    end;

    local procedure RunPageTest(ObjectIdToTest: Integer; IdFieldNo: Integer; CalcFieldNo: Integer)
    var
        AllObj: Record AllObj;
    begin
        RunTest(
          ObjectIdToTest, IdFieldNo, CalcFieldNo, AllObj."Object Type"::Page);
    end;

    local procedure RunReportTest(ObjectIdToTest: Integer; IdFieldNo: Integer; CalcFieldNo: Integer)
    var
        AllObj: Record AllObj;
    begin
        RunTest(
          ObjectIdToTest, IdFieldNo, CalcFieldNo, AllObj."Object Type"::Report);
    end;

    local procedure RunTableTest(ObjectIdToTest: Integer; IdFieldNo: Integer; CalcFieldNo: Integer)
    var
        AllObj: Record AllObj;
    begin
        RunTest(
          ObjectIdToTest, IdFieldNo, CalcFieldNo, AllObj."Object Type"::Table);
    end;

    local procedure VerifyCalculatedField(AllObjWithCaption: Record AllObjWithCaption; CalcFieldRef: FieldRef)
    begin
        Assert.IsTrue(
          CalcFieldRef.Length >= MaxStrLen(AllObjWithCaption."Object Caption"),
          StrSubstNo(CalcFieldLengthErr, CalcFieldRef.Name));

        Assert.AreEqual(
          AllObjWithCaption."Object Caption",
          CalcFieldRef.Value,
          StrSubstNo(CalcFieldValueErr, CalcFieldRef.Name));
    end;

    local procedure InitCalcRecord(var CalcFieldRef: FieldRef; var AllObjWithCaption: Record AllObjWithCaption; var RecRef: RecordRef; TableId: Integer; IdFieldNo: Integer; CalcFieldNo: Integer; ObjectType: Integer)
    var
        IdFieldRef: FieldRef;
        ObjectId: Integer;
    begin
        GetAllObjWithCaption(AllObjWithCaption, ObjectType, ObjectId);

        RecRef.Open(TableId);
        IdFieldRef := RecRef.Field(IdFieldNo);
        CalcFieldRef := RecRef.Field(CalcFieldNo);
        IdFieldRef.Value(ObjectId);
    end;

    local procedure InitCalcRecordWithObjectType(var CalcFieldRef: FieldRef; var AllObjWithCaption: Record AllObjWithCaption; TableId: Integer; ObjectTypeFieldNo: Integer; IdFieldNo: Integer; CalcFieldNo: Integer; ObjectType: Integer)
    var
        RecRef: RecordRef;
        ObjectTypeFieldRef: FieldRef;
    begin
        InitCalcRecord(
          CalcFieldRef, AllObjWithCaption, RecRef, TableId, IdFieldNo, CalcFieldNo, ObjectType);

        ObjectTypeFieldRef := RecRef.Field(ObjectTypeFieldNo);
        ObjectTypeFieldRef.Value(ObjectType);
    end;

    local procedure GetAllObjWithCaption(var AllObjWithCaption: Record AllObjWithCaption; ObjectType: Integer; var ObjectId: Integer)
    begin
        AllObjWithCaption.SetRange("Object Type", ObjectType);
        AllObjWithCaption.FindFirst();
        ObjectId := AllObjWithCaption."Object ID";
    end;

    local procedure CreateReportSelection(UsageOption: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := UsageOption;
        ReportSelections.Sequence :=
          LibraryUtility.GenerateRandomCode(ReportSelections.FieldNo(Sequence), DATABASE::"Report Selections");
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardHandler(var ProdOrderJobCard: TestRequestPage "Prod. Order - Job Card")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderMatRequisitionHandler(var ProdOrderMatRequisition: TestRequestPage "Prod. Order - Mat. Requisition")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListHandler(var ProdOrderShortageList: TestRequestPage "Prod. Order - Shortage List")
    begin
    end;
}

