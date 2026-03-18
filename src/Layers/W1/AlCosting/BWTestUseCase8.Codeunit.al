codeunit 103358 "BW Test Use Case 8"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 8");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103358, 8, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        ResEntry: Record "Reservation Entry";
        SelectionForm: Page "Whse. Test Selection";
        TestScriptMgmt: Codeunit "BW TestscriptManagement";
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
            3:
                PerformTestCase3();
            7:
                PerformTestCase7();
            8:
                PerformTestCase8();
            9:
                PerformTestCase9();
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
        CreateRes: Codeunit "Create Reserv. Entry";
        ReservationMgt: Codeunit "Reservation Management";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '8-1-1-10' then exit;
        // 8-1-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '8-1-2-10' then exit;

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

        if LastIteration = '8-1-2-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-1-2-30' then exit;
        // 8-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-1-3-10' then exit;
        // 8-1-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'E_PROD', '', 2, 'PCS', 123.45, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 'S-03-0001', 2, 2, 0, 0, false);

        if LastIteration = '8-1-4-10' then exit;

        CreateProdOrderFromSale.SetHideValidationDialog(true);
        CreateProdOrderFromSale.CreateProductionOrder(
          SalesLine, "Production Order Status"::Simulated, "Create Production Order Type"::ItemOrder);

        if LastIteration = '8-1-4-20' then exit;
        // 8-1-5
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, SalesHeader."Posting Date", false);

        Commit();

        if LastIteration = '8-1-5-10' then exit;

        ProdOrderLine.Find('-');
        ProdOrderLine.Validate(Quantity, 1);
        ProdOrderLine.Validate("Ending Time");
        ProdOrderLine.Modify();

        if LastIteration = '8-1-5-20' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN01', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN04', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-1-5-30' then exit;

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

        if LastIteration = '8-1-5-40' then exit;
        // 8-1-6
        ProdOrder.Find('-');
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '8-1-6-10' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-1-6-20' then exit;
        // 8-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '8-1-7-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        SalesHeader: Record "Sales Header";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        CreateRes: Codeunit "Create Reserv. Entry";
        NextLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '8-2-1-10' then exit;
        // 8-2-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'C_TEST', '', 'SILVER', '',
          10, 'PCS', 13.13, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '8-2-2-10' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);

        if LastIteration = '8-2-2-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-2-2-30' then exit;
        // 8-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-2-3-10' then exit;
        // 8-2-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'E_PROD', 2, 'SILVER');

        if LastIteration = '8-2-4-10' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        ProdOrderComp.Reset();
        ProdOrderComp.Find('+');
        ProdOrderComp2 := ProdOrderComp;
        NextLineNo := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2."Line No." := NextLineNo;
        ProdOrderComp2.Validate("Location Code", 'SILVER');
        ProdOrderComp2.Validate("Item No.", 'B_TEST');
        ProdOrderComp2.Validate("Unit of Measure Code", 'PCS');
        ProdOrderComp2.Validate("Quantity per", -12);
        ProdOrderComp2.Validate("Due Date", WorkDate() - 1);
        ProdOrderComp2.Insert();
        ProdOrderComp2."Line No." := NextLineNo + 10000;
        ProdOrderComp2.Validate("Item No.", 'C_TEST');
        ProdOrderComp2.Validate("Quantity per", 4);
        ProdOrderComp2.Insert();

        if LastIteration = '8-2-4-20' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", 10000);
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN01', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN02', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN03', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN04', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN01');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-2-4-30' then exit;

        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, SalesHeader."Posting Date", false);

        if LastIteration = '8-2-4-40' then exit;
        // 8-2-5
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '8-2-5-10' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-2-5-20' then exit;
        // 8-2-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '8-2-6-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        CreateRes: Codeunit "Create Reserv. Entry";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '8-3-1-10' then exit;
        // 8-3-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '8-3-2-10' then exit;

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

        if LastIteration = '8-3-2-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-3-2-30' then exit;
        // 8-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-3-3-10' then exit;
        // 8-3-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'E_PROD', '', 2, 'PCS', 123.45, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 'S-03-0001', 2, 2, 0, 0, false);

        if LastIteration = '8-3-4-10' then exit;

        Clear(CreateProdOrderFromSale);
        CreateProdOrderFromSale.SetHideValidationDialog(true);
        CreateProdOrderFromSale.CreateProductionOrder(
          SalesLine, "Production Order Status"::Simulated, "Create Production Order Type"::ItemOrder);

        if LastIteration = '8-3-4-20' then exit;
        // 8-3-5
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, SalesHeader."Posting Date", false);

        if LastIteration = '8-3-5-10' then exit;

        ProdOrderLine.Find('-');
        ProdOrderLine.Validate(Quantity, 1);
        ProdOrderLine.Validate("Ending Time");
        ProdOrderLine.Modify();
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN01', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN04', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-3-5-20' then exit;
        // 8-3-6
        ProdOrder.Find('-');
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '8-3-6-10' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-3-6-20' then exit;

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", 'CONSUMP');
        ItemJnlLine.Validate("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine."Line No." := 10000;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Consumption;
        ItemJnlLine."Posting Date" := 20011125D;
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.", 'B_TEST');
        ItemJnlLine.Validate("Unit of Measure Code", 'PCS');
        ItemJnlLine.Validate(Quantity, 2);
        ItemJnlLine.Insert(true);

        if LastIteration = '8-3-6-30' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-3-6-40' then exit;
        // 8-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '8-3-7-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        Loc: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        EntrySummary: Record "Entry Summary";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        ReservEntry: Record "Reservation Entry";
        CreateRes: Codeunit "Create Reserv. Entry";
        ReservationMgt: Codeunit "Reservation Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '8-7-1-10' then exit;

        Loc.Get('SILVER');
        Loc."Require Pick" := true;
        Loc.Modify();

        if LastIteration = '8-7-1-20' then exit;
        // 8-7-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-7-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-7-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-7-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-7-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-7-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-7-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '8-7-2-10' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);

        if LastIteration = '8-7-2-20' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);

        if LastIteration = '8-7-2-30' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-7-2-40' then exit;
        // 8-7-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-7-3-10' then exit;
        // 8-7-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 1, 'SILVER');

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        WhseProdRelease.Release(ProdOrder);

        if LastIteration = '8-7-4-10' then exit;

        ProdOrderLine.Reset();
        ProdOrderLine.Find('-');
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN01', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN04', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-7-4-20' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-7-4-30' then exit;

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

        if LastIteration = '8-7-4-40' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.Find('+');
        ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
        ProdOrderComp.Validate("Item No.", 'A_TEST');
        ProdOrderComp.Validate("Variant Code", '11');
        ProdOrderComp.Validate("Quantity per", -1);
        ProdOrderComp.Validate("Location Code", 'SILVER');
        ProdOrderComp.Validate("Bin Code", 'S-01-0002');
        ProdOrderComp.Insert(true);
        ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
        ProdOrderComp.Insert(true);
        ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
        ProdOrderComp.Validate("Item No.", 'L_TEST');
        ProdOrderComp.Validate("Quantity per", -1);
        ProdOrderComp.Validate("Location Code", 'SILVER');
        ProdOrderComp.Validate("Bin Code", 'S-01-0002');
        ProdOrderComp.Insert(true);
        CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
          ProdOrderComp."Line No.", 1, -1, -1, '', 'LN03');
        CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
        ProdOrderComp.Validate("Item No.", 'T_TEST');
        ProdOrderComp.Validate("Quantity per", -1);
        ProdOrderComp.Validate("Location Code", 'SILVER');
        ProdOrderComp.Validate("Bin Code", 'S-01-0002');
        ProdOrderComp.Insert(true);
        CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
          ProdOrderComp."Line No.", 1, -1, -1, 'SN06', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
        ProdOrderComp.Validate("Item No.", 'T_TEST');
        ProdOrderComp.Validate("Quantity per", -1);
        ProdOrderComp.Validate("Location Code", 'SILVER');
        ProdOrderComp.Validate("Bin Code", 'S-04-0001');
        ProdOrderComp.Insert(true);
        CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
          ProdOrderComp."Line No.", 1, -1, -1, 'SN07', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '8-7-4-50' then exit;
        // 8-7-5
        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 5, 'SILVER');
        TestScriptMgmt.CreateInvPick(WhseActivHeader);
        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 4, 'SILVER');
        TestScriptMgmt.CreateInvPutAway(WhseActivHeader);

        if LastIteration = '8-7-5-10' then exit;

        WhseActivLine.Find('-');
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '8-7-5-20' then exit;
        // 8-7-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '8-7-6-10' then exit;
        // 8-7-7
        WhseActivLine.Reset();

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", 5);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '8-7-7-10' then exit;
        // 8-7-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '8-7-8-10' then exit;
        // 8-7-9
        WhseActivLine.Reset();

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", 4);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '8-7-9-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase8()
    var
        Loc: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        NextLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '8-8-1-10' then exit;

        Loc.Get('SILVER');
        Loc."Require Pick" := true;
        Loc."Require Put-away" := true;
        Loc.Modify();

        if LastIteration = '8-8-1-20' then exit;
        // 8-8-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-8-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-8-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-8-2', 'C_TEST', '', 'SILVER', '',
          10, 'PCS', 13.13, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-8-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-8-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-8-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-8-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '8-8-2-10' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);

        if LastIteration = '8-8-2-20' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10007, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10007, true);

        if LastIteration = '8-8-2-30' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-8-2-40' then exit;
        // 8-8-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-8-3-10' then exit;
        // 8-8-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 2, 'SILVER');

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        WhseProdRelease.Release(ProdOrder);

        if LastIteration = '8-8-4-10' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.Find('+');
        ProdOrderComp2 := ProdOrderComp;
        NextLineNo := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2."Line No." := NextLineNo;
        ProdOrderComp2.Validate("Location Code", 'SILVER');
        ProdOrderComp2.Validate("Item No.", 'B_TEST');
        ProdOrderComp2.Validate("Unit of Measure Code", 'PCS');
        ProdOrderComp2.Validate("Quantity per", -12);
        ProdOrderComp2.Validate("Due Date", WorkDate() - 1);
        ProdOrderComp2.Insert(true);
        ProdOrderComp2."Line No." := NextLineNo + 10000;
        ProdOrderComp2.Validate("Item No.", 'C_TEST');
        ProdOrderComp2.Validate("Quantity per", 4);
        ProdOrderComp2.Insert(true);

        if LastIteration = '8-8-4-20' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", 10000);
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN01', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN02', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN03', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, 'SN04', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-8-4-30' then exit;

        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN01');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-8-4-40' then exit;
        // 8-8-5
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Prod. Consumption", ProdOrder."No.");

        if LastIteration = '8-8-5-10' then exit;

        WhseActivLine.Find('-');
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '8-8-5-20' then exit;
        // 8-8-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '8-8-6-10' then exit;
        // 8-8-7
        WhseActivLine.Find('+');
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '8-8-7-10' then exit;
        // 8-8-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '8-8-8-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase9()
    var
        Loc: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        WhseActivLine: Record "Warehouse Activity Line";
        EntrySummary: Record "Entry Summary";
        ReservEntry: Record "Reservation Entry";
        CreateRes: Codeunit "Create Reserv. Entry";
        ReservationMgt: Codeunit "Reservation Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        NextLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ModifyProdBom();

        if LastIteration = '8-9-1-10' then exit;

        Loc.Get('SILVER');
        Loc."Require Pick" := true;
        Loc.Modify();

        if LastIteration = '8-9-1-20' then exit;
        // 8-9-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-9-2', 'A_TEST', '12', 'SILVER', '',
          39, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-9-2', 'B_TEST', '', 'SILVER', '',
          25, 'PCS', 11.5, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-9-2', 'D_PROD', '', 'SILVER', '',
          18, 'PCS', 16.25, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-9-2', 'E_PROD', '', 'SILVER', '',
          5, 'PCS', 111.11, 0, 'S-03-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-9-2', 'L_TEST', '', 'SILVER', '',
          2, 'BOX', 44.4, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-9-2', 'T_TEST', '', 'SILVER', '',
          4, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '8-9-2-10' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10005, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10005, true);

        if LastIteration = '8-9-2-20' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10006, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10006, true);

        if LastIteration = '8-9-2-30' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-9-2-40' then exit;
        // 8-9-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-9-3-10' then exit;
        // 8-9-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 1, 'SILVER');

        if LastIteration = '8-9-4-10' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        WhseProdRelease.Release(ProdOrder);

        if LastIteration = '8-9-4-20' then exit;

        ProdOrderLine.Reset();
        ProdOrderLine.Find('-');
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN01', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, 'SN04', '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-9-4-30' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetRange("Item No.", 'L_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 3, ProdOrder."No.", '', ProdOrderLine."Line No.",
              ProdOrderComp."Line No.", 1, 1, 1, '', 'LN02');
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '8-9-4-40' then exit;

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

        if LastIteration = '8-9-4-50' then exit;
        // 8-9-5
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Prod. Consumption", ProdOrder."No.");

        if LastIteration = '8-9-5-10' then exit;

        WhseActivLine.Find('-');
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '8-9-5-20' then exit;
        // 8-9-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '8-9-6-10' then exit;
        // 8-9-7
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '8-9-7-10' then exit;
        // 8-9-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '8-9-8-10' then exit;
        // 8-9-9
        ProdOrderComp.Reset();
        ProdOrderComp.Find('+');
        ProdOrderComp2 := ProdOrderComp;
        NextLineNo := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2."Line No." := NextLineNo;
        ProdOrderComp2.Validate("Location Code", 'SILVER');
        ProdOrderComp2.Validate("Quantity per", 2);
        ProdOrderComp2.Validate("Due Date", WorkDate() - 1);
        ProdOrderComp2.Validate("Item No.", 'A_TEST');
        ProdOrderComp2.Validate("Variant Code", '12');
        ProdOrderComp2.Insert();

        if LastIteration = '8-9-9-10' then exit;

        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Prod. Consumption", ProdOrder."No.");

        if LastIteration = '8-9-9-20' then exit;

        WhseActivLine.Find('-');
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '8-9-9-30' then exit;

        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '8-9-9-40' then exit;
        // 8-9-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '8-9-10-10' then exit;


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
        ProdBOMLine.SetRange(ProdBOMLine."Production BOM No.", 'E_PROD');
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
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntry.CreateReservEntryFor(
            ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;
}

