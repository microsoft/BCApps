codeunit 103359 "BW Test Use Case 9"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        QASetup: Record "Whse. QA Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
    begin
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 9");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103359, 9, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        ResEntry: Record "Reservation Entry";
        SelectionForm: Page "Whse. Test Selection";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        TestScriptMgmt: Codeunit "BW TestscriptManagement";
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ShowAlsoPassTests: Boolean;
        TestUseCase: array[50] of Boolean;
        ItemJnlLineNo: Integer;
        LastILENo: Integer;
        NoOfFields: array[20] of Integer;
        NoOfRecords: array[20] of Integer;
        ObjectNo: Integer;
        TestCaseNo: Integer;
        UseCaseNo: Integer;
        TestLevel: Option All,Selected;
        FirstIteration: Text[30];
        LastIteration: Text[30];
        TestCaseDesc: array[50] of Text[100];
        TestResultsPath: Text[250];

    [Scope('OnPrem')]
    procedure Test(NewObjectNo: Integer; NewUseCaseNo: Integer; NewTestLevel: Option All,Selected; NewLastIteration: Text[30]; NewTestCaseNo: Integer): Boolean
    begin
        ObjectNo := NewObjectNo;
        UseCaseNo := NewUseCaseNo;
        TestLevel := NewTestLevel;
        LastIteration := NewLastIteration;
        TestCaseNo := NewTestCaseNo;

        UseCase.Get('BW', UseCaseNo);
        TestScriptMgmt.InitializeOutput(ObjectNo, '');
        TestResultsPath := TestScriptMgmt.GetTestResultsPath();
        TestScriptMgmt.SetNumbers(NoOfRecords, NoOfFields);

        if LastIteration <> '' then begin
            TestCase.Get('BW', UseCaseNo, TestCaseNo);
            TestCaseDesc[TestCaseNo] :=
              Format(UseCaseNo) + '.' + Format(TestCaseNo) + ' ' + TestCase.Description;
            HandleTestCases();
        end else begin
            TestCaseNo := 0;
            Clear(TestUseCase);
            Clear(TestCaseDesc);

            TestCase.Reset();
            TestCase.SetRange("Project Code", 'BW');
            TestCase.SetRange("Use Case No.", UseCaseNo);
            TestCase.SetRange("Testscript Completed", true);
            if not TestCase.Find('-') then
                exit(true);
            repeat
                TestCaseNo := TestCase."Test Case No.";
                if TestCaseNo <= ArrayLen(TestCaseDesc) then
                    TestCaseDesc[TestCaseNo] :=
                      Format(UseCaseNo) + '.' + Format(TestCaseNo) + ' ' + TestCase.Description;
            until TestCase.Next() = 0;

            if TestLevel = TestLevel::Selected then begin
                Commit();
                SelectionForm.SetSelection(TestCaseDesc, false, UseCaseNo,
                  'Select Test Case for Use Case ' + Format(UseCaseNo) + '. ' + UseCase.Description);
                SelectionForm.LookupMode := true;
                if SelectionForm.RunModal() <> ACTION::LookupOK then
                    exit(false);
                SelectionForm.GetSelection(TestLevel, TestUseCase, ShowAlsoPassTests);
            end;

            for TestCaseNo := 1 to ArrayLen(TestCaseDesc) do
                if TestCaseDesc[TestCaseNo] <> '' then
                    HandleTestCases();
        end;

        TestScriptMgmt.GetNumbers(NoOfRecords, NoOfFields);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure HandleTestCases()
    begin
        if TestLevel = TestLevel::Selected then
            if not TestUseCase[TestCaseNo] then
                exit;

        case TestCaseNo of
            1:
                PerformTestCase1();
            2:
                PerformTestCase2();
            5:
                PerformTestCase5();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        EntrySummary: Record "Entry Summary";
        ItemJnlLine: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        CalcConsumption: Report "Calc. Consumption";
        ReservationMgt: Codeunit "Reservation Management";
        ProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '9-1-1-10' then
            exit;
        // 9-1-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-1-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-1-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-1-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-1-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-1-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-1-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '9-1-2-10' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);

        if LastIteration = '9-1-2-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-1-2-30' then
            exit;
        // 9-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '9-1-3-10' then
            exit;
        // 9-1-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'E_PROD', '', 2, 'PCS', 123.45, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 'S-03-0001', 2, 2, 0, 0, false);

        if LastIteration = '9-1-4-10' then
            exit;

        ProdOrderFromSale.SetHideValidationDialog(true);
        ProdOrderFromSale.CreateProductionOrder(
            SalesLine, "Production Order Status"::Simulated, "Create Production Order Type"::ItemOrder);

        if LastIteration = '9-1-4-20' then
            exit;
        // 9-1-5
        ProdOrder.FindFirst();
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, SalesHeader."Posting Date", false);

        if LastIteration = '9-1-5-10' then
            exit;

        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, 1);
        ProdOrderLine.Validate("Ending Time");
        ProdOrderLine.Modify();

        if LastIteration = '9-1-5-20' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.FindFirst() then begin

            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN04', '');
            CreateReservEntry.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.FindFirst() then begin
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateReservEntry.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '9-1-5-30' then
            exit;

        EntrySummary.Init();
        EntrySummary."Entry No." := 1;
        EntrySummary."Table ID" := DATABASE::"Item Ledger Entry";
        EntrySummary."Summary Type" := 'Item Ledger Entry';
        EntrySummary."Total Quantity" := 1;
        ReservationMgt.SetReservSource(ProdOrderComp);
        ReservEntry."Serial No." := '';
        ReservEntry."Lot No." := 'LN02';
        ReservationMgt.SetTrackingFromReservEntry(ReservEntry);
        ReservationMgt.SetItemTrackingHandling(2);
        ReservationMgt.AutoReserveOneLine(
          EntrySummary."Entry No.", EntrySummary."Total Quantity", EntrySummary."Total Quantity", '', 20011125D);

        if LastIteration = '9-1-5-40' then
            exit;
        // 9-1-6
        ProdOrder.FindFirst();
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '9-1-6-10' then
            exit;

        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-1-6-20' then
            exit;
        // 9-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '9-1-7-10' then
            exit;
        // 9-1-8
        ProdOrder.Reset();
        ProdOrder.FindFirst();
        WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '9-1-8-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-1-8-20' then
            exit;
        // 9-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '9-1-9-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        CalcConsumption: Report "Calc. Consumption";
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ProdBOMHdr.Get('D_PROD');
        ProdBOMHdr.Status := ProdBOMHdr.Status::"Under Development";
        ProdBOMHdr.Modify();
        ProdBOMLine.SetRange("Production BOM No.", 'D_PROD');
        if ProdBOMLine.FindFirst() then begin
            ProdBOMLine."Quantity per" := 2;
            ProdBOMLine.Modify();
        end;
        ProdBOMHdr.Status := ProdBOMHdr.Status::Certified;
        ProdBOMHdr.Modify();

        if LastIteration = '9-2-1-10' then
            exit;
        // 9-2-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-2-2', 'C_TEST', '32', 'SILVER', '',
          10, 'PCS', 13.13, 0, 'S-01-0001');

        if LastIteration = '9-2-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-2-2-20' then
            exit;
        // 9-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '9-2-3-10' then
            exit;
        // 9-2-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'D_PROD', 4, 'SILVER');

        if LastIteration = '9-2-4-10' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Location Code", 'SILVER');
        ProdOrderLine.Validate("Bin Code", 'S-04-0001');
        ProdOrderLine.Modify();

        if LastIteration = '9-2-4-20' then
            exit;
        // 9-2-5
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '9-2-5-10' then
            exit;

        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-2-5-20' then
            exit;
        // 9-2-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '9-2-6-10' then
            exit;
        // 9-2-7
        ProdOrder.Reset();
        ProdOrder.Find('-');
        WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Output Quantity", 1);
        ItemJnlLine.Modify();

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-2-7-10' then
            exit;

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", 'OUTPUT');
        ItemJnlLine.Validate("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.Validate("Line No.", 10000);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Posting Date", 20011125D);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Document No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", 'D_PROD');
        ItemJnlLine.Validate("Location Code", 'SILVER');
        ItemJnlLine.Validate("Output Quantity", -1);
        ItemJnlLine.Validate("Unit of Measure Code", 'PCS');
        ItemJnlLine.Insert();

        ItemJnlLine.Validate("Applies-to Entry", 3);
        ItemJnlLine.Modify();

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-2-7-20' then
            exit;
        // 9-2-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '9-2-8-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        Location: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        EntrySummary: Record "Entry Summary";
        WhseActivLine: Record "Warehouse Activity Line";
        ReservEntry: Record "Reservation Entry";
        CreateRes: Codeunit "Create Reserv. Entry";
        ReservationMgt: Codeunit "Reservation Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        SNCode: Code[20];
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '9-5-1-10' then
            exit;

        Location.Get('SILVER');
        Location."Require Pick" := true;
        Location."Require Put-away" := true;
        Location.Modify();

        if LastIteration = '9-5-1-20' then
            exit;
        // 9-5-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-5-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-5-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-5-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-5-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-5-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS9-5-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '9-5-2-10' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);

        if LastIteration = '9-5-2-20' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);

        if LastIteration = '9-5-2-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '9-5-2-40' then
            exit;
        // 9-5-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '9-5-3-10' then
            exit;
        // 9-5-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 1, 'SILVER');

        if LastIteration = '9-5-4-10' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        WhseProdRelease.Release(ProdOrder);
        WhseOutputProdRelease.Release(ProdOrder);

        if LastIteration = '9-5-4-20' then
            exit;

        if LastIteration = '9-5-4-30' then
            exit;

        ProdOrderLine.Reset();
        ProdOrderLine.FindFirst();
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.FindFirst() then begin
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '9-5-4-40' then
            exit;

        EntrySummary.Init();
        EntrySummary."Entry No." := 1;
        EntrySummary."Table ID" := DATABASE::"Item Ledger Entry";
        EntrySummary."Summary Type" := 'Item Ledger Entry';
        EntrySummary."Total Quantity" := 1;
        ReservationMgt.SetReservSource(ProdOrderComp);
        ReservEntry."Serial No." := '';
        ReservEntry."Lot No." := 'LN02';
        ReservationMgt.SetTrackingFromReservEntry(ReservEntry);
        ReservationMgt.SetItemTrackingHandling(2);
        ReservationMgt.AutoReserveOneLine(EntrySummary."Entry No.", EntrySummary."Total Quantity", EntrySummary."Total Quantity", '', 20011125D);

        if LastIteration = '9-5-4-50' then
            exit;
        // 9-5-5
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Prod. Consumption", ProdOrder."No.");

        if LastIteration = '9-5-5-10' then
            exit;

        WhseActivLine.Find('+');
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);
        SNCode := 'SN01';
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
                SNCode := 'SN04';
            until WhseActivLine.Next() = 0;

        if LastIteration = '9-5-5-20' then
            exit;
        // 9-5-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '9-5-6-10' then
            exit;
        // 9-5-7
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '9-5-7-10' then
            exit;
        // 9-5-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '9-5-8-10' then
            exit;
        // 9-5-9
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Prod. Output", ProdOrder."No.");

        if LastIteration = '9-5-9-10' then
            exit;

        WhseActivLine.Find('-');
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '9-5-9-20' then
            exit;
        // 9-5-10
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '9-5-10-10' then
            exit;
        // 9-5-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '9-5-11-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure GetLastILENo(): Integer
    begin
        LastILENo := TestScriptMgmt.GetLastItemLedgEntryNo();
    end;

    [Scope('OnPrem')]
    procedure GetNextNo(var LastNo: Integer): Integer
    begin
        exit(TestScriptMgmt.GetNextNo(LastNo));
    end;

    [Scope('OnPrem')]
    procedure SetFirstIteration(NewFirstUseCaseNo: Integer; NewFirstTestCaseNo: Integer; NewFirstIterationNo: Integer; NewFirstStepNo: Integer)
    begin
        UseCaseNo := NewFirstUseCaseNo;
        TestCaseNo := NewFirstTestCaseNo;
        FirstIteration := Format(UseCaseNo) + '-' + Format(TestCaseNo) + '-' +
          Format(NewFirstIterationNo) + '-' + Format(NewFirstStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetLastIteration(NewLastUseCaseNo: Integer; NewLastTestCaseNo: Integer; NewLastIterationNo: Integer; NewLastStepNo: Integer)
    begin
        LastIteration := Format(NewLastUseCaseNo) + '-' + Format(NewLastTestCaseNo) + '-' +
          Format(NewLastIterationNo) + '-' + Format(NewLastStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetNumbers(NewNoOfRecords: array[20] of Integer; NewNoOfFields: array[20] of Integer)
    begin
        CopyArray(NoOfRecords, NewNoOfRecords, 1);
        CopyArray(NoOfFields, NewNoOfFields, 1);
    end;

    [Scope('OnPrem')]
    procedure GetNumbers(var NewNoOfRecords: array[20] of Integer; var NewNoOfFields: array[20] of Integer)
    begin
        CopyArray(NewNoOfRecords, NoOfRecords, 1);
        CopyArray(NewNoOfFields, NoOfFields, 1);
    end;

    local procedure ModifyProdBom()
    var
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        WMSGlobalPrecondition: Codeunit "WMS Set Global Preconditions";
    begin
        ProdBOMHdr.Get('E_PROD');
        ProdBOMHdr.Status := ProdBOMHdr.Status::"Under Development";
        ProdBOMHdr.Modify();
        ProdBOMLine.SetRange("Production BOM No.", 'E_PROD');
        if ProdBOMLine.Find('-') then
            repeat
                ProdBOMLine.Delete();
            until ProdBOMLine.Next() = 0;
        WMSGlobalPrecondition.InsertProdBOMHdr('E_PROD', 'Product E', 'PCS');
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 10000, ProdBOMLine.Type::Item, 'D_PROD', '', 1);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 20000, ProdBOMLine.Type::Item, 'A_TEST', '12', 13);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 30000, ProdBOMLine.Type::Item, 'B_TEST', '', 12);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 40000, ProdBOMLine.Type::Item, 'T_TEST', '', 2);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 50000, ProdBOMLine.Type::Item, 'L_TEST', '', 1);
        WMSGlobalPrecondition.ModifyProdBOMHdr('E_PROD', ProdBOMHdr.Status::Certified);
    end;

    local procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntry.CreateReservEntryFor(
            ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;
}

