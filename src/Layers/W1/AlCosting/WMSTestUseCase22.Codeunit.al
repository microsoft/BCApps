codeunit 103332 "WMS Test Use Case 22"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 22");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103332, 22, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        WhseWkshLine: Record "Whse. Worksheet Line";
        SelectionForm: Page "Whse. Test Selection";
        GlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ShowAlsoPassTests: Boolean;
        TestUseCase: array[50] of Boolean;
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

        UseCase.Get('WMS', UseCaseNo);
        TestScriptMgmt.InitializeOutput(ObjectNo, '');
        TestResultsPath := TestScriptMgmt.GetTestResultsPath();
        TestScriptMgmt.SetNumbers(NoOfRecords, NoOfFields);

        if LastIteration <> '' then begin
            TestCase.Get('WMS', UseCaseNo, TestCaseNo);
            TestCaseDesc[TestCaseNo] :=
              Format(UseCaseNo) + '.' + Format(TestCaseNo) + ' ' + TestCase.Description;
            HandleTestCases();
        end else begin
            TestCaseNo := 0;
            Clear(TestUseCase);
            Clear(TestCaseDesc);

            TestCase.Reset();
            TestCase.SetRange("Project Code", 'WMS');
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
            8:
                PerformTestCase8();
            9:
                PerformTestCase9();
            10:
                PerformTestCase10();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        ItemJnlLine: Record "Item Journal Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        CalcConsumption: Report "Calc. Consumption";
        ResMgmt: Codeunit "Reservation Management";
        SNCode: Code[20];
        i: Integer;
        AutoReserv: Boolean;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '22-1-1-10' then
            exit;

        TestScriptMgmt.InsertRoutingHeader(RoutingHeader, 'F_PROD', RoutingHeader.Type::Serial);
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '010', RoutingLine.Type::"Work Center", '100', 2, 5, '100');
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '020', RoutingLine.Type::"Work Center", '400', 3, 5, '300');
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();
        WorkCenter.SetFilter("No.", '%1|%2', '100', '400');
        Clear(CalcWorkCenterCal);
        CalcWorkCenterCal.InitializeRequest(20010101D, 20011231D);
        CalcWorkCenterCal.UseRequestPage(false);
        CalcWorkCenterCal.SetTableView(WorkCenter);
        CalcWorkCenterCal.RunModal();

        Item.Get('F_PROD');
        Item.Validate("Routing No.", 'F_PROD');
        Item.Modify(true);

        if LastIteration = '22-1-1-20' then
            exit;
        // 22-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS22-1-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 10, 'BOX', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'F_TEST_BACKFLUSHPICK', 'F1', 'WHITE', 25, 'PCS', 4.56, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'F_TEST_BACKFLUSH', '', 'WHITE', 12, 'PCS', 2.34, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'F_TEST_FORWFLUSHPICK', '', 'WHITE', 10, 'PCS', 3.45, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '1120', '', 'BLUE', 2, 'PCS', 5.67, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1120', '', 'WHITE', 2, 'PCS', 5.67, false);

        if LastIteration = '22-1-2-10' then
            exit;

        SNCode := 'SN00000';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T2', 'WHITE', SNCode, '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        end;

        if LastIteration = '22-1-2-20' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '22-1-2-30' then
            exit;
        // 22-1-3
        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'F_PROD', 4, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Validate("Bin Code", 'W-07-0003');
        ProdOrder.Modify(true);
        WorkDate := 20011130D;

        if LastIteration = '22-1-3-10' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-1-3-20' then
            exit;

        ProdOrderLine.Reset();
        ProdOrderLine.FindFirst();

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'F_TEST_BACKFLUSH');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Routing Link Code", '100');
            ProdOrderComp.Modify();
            ResMgmt.SetReservSource(ProdOrderComp);
            ResMgmt.AutoReserve(AutoReserv, '', 20011130D, ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)");
        end;

        if LastIteration = '22-1-3-30' then
            exit;

        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 1);
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-1-3-40' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'F_TEST_BACKFLUSHPICK');
        if ProdOrderComp.FindFirst() then begin
            ResMgmt.SetReservSource(ProdOrderComp);
            ResMgmt.AutoReserve(AutoReserv, '', 20011130D, ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)");
        end;

        if LastIteration = '22-1-3-50' then
            exit;

        ProdOrderComp.SetRange("Item No.", 'F_TEST_FORWFLUSHPICK');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 0.5);
            ProdOrderComp.Validate("Routing Link Code", '300');
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-1-3-60' then
            exit;

        Clear(ProdOrderComp2);
        ProdOrderComp2.FindLast();
        i := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2."Line No." := i;
        ProdOrderComp2.Validate("Flushing Method", ProdOrderComp2."Flushing Method"::"Pick + Forward");
        ProdOrderComp2.Validate("Quantity per", 1.5);
        ProdOrderComp2.Validate("Routing Link Code", '');
        ProdOrderComp2.Insert(true);

        if LastIteration = '22-1-3-70' then
            exit;

        ProdOrderComp.SetRange("Item No.", '1120');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 0.25);
            ProdOrderComp.Validate("Flushing Method", ProdOrderComp."Flushing Method"::"Pick + Forward");
            ProdOrderComp.Modify(true);
        end;

        if LastIteration = '22-1-3-80' then
            exit;
        // 22-1-4
        ProdOrderComp.SetRange("Item No.", '1120');
        ProdOrderComp.FindFirst();
        ProdOrderComp2.Reset();
        ProdOrderComp2.FindLast();
        i := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2."Line No." := i;
        ProdOrderComp2.Validate("Location Code", 'BLUE');
        ProdOrderComp2.Validate("Flushing Method", ProdOrderComp2."Flushing Method"::"Pick + Forward");
        ProdOrderComp2.Validate("Routing Link Code", '100');
        ProdOrderComp2.Insert(true);
        i := i + 10000;
        ProdOrderComp.SetRange("Item No.", 'F_TEST_BACKFLUSHPICK');
        ProdOrderComp.FindLast();
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2."Line No." := i;
        ProdOrderComp2.Validate("Flushing Method", ProdOrderComp2."Flushing Method"::"Pick + Backward");
        ProdOrderComp2.Validate("Quantity per", -0.25);
        ProdOrderComp2.Validate("Routing Link Code", '');
        ProdOrderComp2.Insert(true);

        if LastIteration = '22-1-4-10' then
            exit;
        // 22-1-5
        PurchHeader.Reset();
        PurchHeader.Find('-');
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '22-1-5-10' then
            exit;

        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '22-1-5-20' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-1-5-30' then
            exit;

        PurchHeader.Find('-');
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '22-1-5-40' then
            exit;

        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011126D,
          'F_TEST_BACKFLUSH', '', 'W-02-0001', 'W-07-0001', 10, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 20000, 20011126D,
          '1120', '', 'W-04-0015', 'W-07-0002', 1, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 30000, 20011126D,
          'F_TEST_FORWFLUSHPICK', '', 'W-01-0001', 'W-07-0002', 6, 'PCS');

        if LastIteration = '22-1-5-50' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '22-1-5-60' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-1-5-70' then
            exit;
        // 22-1-6
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, 20011130D, false);

        if LastIteration = '22-1-6-10' then
            exit;
        // 22-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '22-1-7-10' then
            exit;
        // 22-1-8
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '22-1-8-10' then
            exit;

        SNCode := 'SN00000';
        i := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        if WhseActivLine.Find('-') then
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '22-1-8-20' then
            exit;
        // 22-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '22-1-9-10' then
            exit;
        // 22-1-10
        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-1-10-10' then
            exit;

        ProdOrder.Find('-');
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '22-1-10-20' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.FindFirst();
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-1-10-30' then
            exit;
        // 22-1-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '22-1-11-10' then
            exit;
        // 22-1-12
        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '22-1-12-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-1-12-20' then
            exit;
        // 22-1-13
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, 20011130D, false);

        if LastIteration = '22-1-13-10' then
            exit;
        // 22-1-14
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 14, LastILENo);

        if LastIteration = '22-1-14-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        ItemJnlLine: Record "Item Journal Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        CalcConsumption: Report "Calc. Consumption";
        ResMgmt: Codeunit "Reservation Management";
        SNCode: Code[20];
        i: Integer;
        AutoReserv: Boolean;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '22-2-1-10' then
            exit;

        TestScriptMgmt.InsertRoutingHeader(RoutingHeader, 'F_PROD', RoutingHeader.Type::Serial);
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '010', RoutingLine.Type::"Work Center", '100', 2, 5, '100');
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '020', RoutingLine.Type::"Work Center", '400', 3, 5, '300');
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();
        WorkCenter.SetFilter("No.", '%1|%2', '100', '400');
        Clear(CalcWorkCenterCal);
        CalcWorkCenterCal.InitializeRequest(20010101D, 20011231D);
        CalcWorkCenterCal.UseRequestPage(false);
        CalcWorkCenterCal.SetTableView(WorkCenter);
        CalcWorkCenterCal.RunModal();

        Item.Get('F_PROD');
        Item.Validate("Routing No.", 'F_PROD');
        Item.Modify(true);

        if LastIteration = '22-2-1-20' then
            exit;
        // 22-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS22-2-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 10, 'BOX', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'F_TEST_BACKFLUSHPICK', 'F1', 'WHITE', 25, 'PCS', 4.56, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'F_TEST_BACKFLUSH', '', 'WHITE', 12, 'PCS', 2.34, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'F_TEST_FORWFLUSHPICK', '', 'WHITE', 10, 'PCS', 3.45, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '1120', '', 'BLUE', 2, 'PCS', 5.67, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1120', '', 'WHITE', 2, 'PCS', 5.67, false);

        if LastIteration = '22-2-2-10' then
            exit;

        SNCode := 'SN00000';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T2', 'WHITE', SNCode, '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        end;

        if LastIteration = '22-2-2-20' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '22-2-2-30' then
            exit;
        // 22-2-3
        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'F_PROD', 4, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Validate("Bin Code", 'W-07-0003');
        ProdOrder.Modify(true);
        WorkDate := 20011130D;

        if LastIteration = '22-2-3-10' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-2-3-20' then
            exit;

        ProdOrderLine.Reset();
        ProdOrderLine.FindFirst();

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'F_TEST_BACKFLUSH');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Routing Link Code", '100');
            ProdOrderComp.Modify();
            ResMgmt.SetReservSource(ProdOrderComp);
            ResMgmt.AutoReserve(AutoReserv, '', 20011130D, ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)");
        end;

        if LastIteration = '22-2-3-30' then
            exit;

        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 1);
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-2-3-40' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'F_TEST_BACKFLUSHPICK');
        if ProdOrderComp.FindFirst() then begin
            ResMgmt.SetReservSource(ProdOrderComp);
            ResMgmt.AutoReserve(AutoReserv, '', 20011130D, ProdOrderComp."Remaining Quantity", ProdOrderComp."Remaining Qty. (Base)");
        end;

        if LastIteration = '22-2-3-50' then
            exit;

        ProdOrderComp.SetRange("Item No.", 'F_TEST_FORWFLUSHPICK');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 0.5);
            ProdOrderComp.Validate("Routing Link Code", '300');
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-2-3-60' then
            exit;

        Clear(ProdOrderComp2);
        ProdOrderComp2.FindLast();
        i := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2."Line No." := i;
        ProdOrderComp2.Validate("Flushing Method", ProdOrderComp2."Flushing Method"::"Pick + Forward");
        ProdOrderComp2.Validate("Quantity per", 1.5);
        ProdOrderComp2.Validate("Routing Link Code", '');
        ProdOrderComp2.Insert(true);

        if LastIteration = '22-2-3-70' then
            exit;

        ProdOrderComp.SetRange("Item No.", '1120');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 0.25);
            ProdOrderComp.Validate("Flushing Method", ProdOrderComp."Flushing Method"::"Pick + Forward");
            ProdOrderComp.Modify(true);
        end;

        if LastIteration = '22-2-3-80' then
            exit;
        // 22-2-4
        ProdOrderComp.SetRange("Item No.", '1120');
        ProdOrderComp.FindFirst();
        ProdOrderComp2.Reset();
        ProdOrderComp2.FindLast();
        i := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2."Line No." := i;
        ProdOrderComp2.Validate("Location Code", 'BLUE');
        ProdOrderComp2.Validate("Flushing Method", ProdOrderComp2."Flushing Method"::"Pick + Forward");
        ProdOrderComp2.Validate("Routing Link Code", '100');
        ProdOrderComp2.Insert(true);
        i := i + 10000;
        ProdOrderComp.SetRange("Item No.", 'F_TEST_BACKFLUSHPICK');
        ProdOrderComp.FindLast();
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2."Line No." := i;
        ProdOrderComp2.Validate("Flushing Method", ProdOrderComp2."Flushing Method"::"Pick + Backward");
        ProdOrderComp2.Validate("Quantity per", -0.25);
        ProdOrderComp2.Validate("Routing Link Code", '');
        ProdOrderComp2.Insert(true);

        if LastIteration = '22-2-4-10' then
            exit;
        // 22-2-5
        PurchHeader.Reset();
        PurchHeader.Find('-');
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '22-2-5-10' then
            exit;

        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '22-2-5-20' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-2-5-30' then
            exit;

        PurchHeader.Find('-');
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '22-2-5-40' then
            exit;

        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011126D,
          'F_TEST_BACKFLUSH', '', 'W-02-0001', 'W-07-0001', 10, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 20000, 20011126D,
          '1120', '', 'W-04-0015', 'W-07-0002', 1, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 30000, 20011126D,
          'F_TEST_FORWFLUSHPICK', '', 'W-01-0001', 'W-07-0002', 6, 'PCS');

        if LastIteration = '22-2-5-50' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '22-2-5-60' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-2-5-70' then
            exit;
        // 22-2-6
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '22-2-6-10' then
            exit;
        // 22-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '22-2-7-10' then
            exit;
        // 22-2-8
        TestScriptMgmt.CreaPickFromProdOrderSrc('PICK', 'DEFAULT', 'WHITE');

        if LastIteration = '22-2-8-10' then
            exit;

        WhseWkshLine.Reset();
        WhseWkshLine.Find('-');
        TestScriptMgmt.CreatePickFromWksh(
          WhseWkshLine, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        if LastIteration = '22-2-8-20' then
            exit;

        SNCode := 'SN00000';
        i := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        if WhseActivLine.Find('-') then
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '22-2-8-30' then
            exit;
        // 22-2-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '22-2-9-10' then
            exit;
        // 22-2-10
        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-2-10-10' then
            exit;

        ProdOrder.Find('-');
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '22-2-10-20' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.FindFirst();
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-2-10-30' then
            exit;
        // 22-2-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '22-2-11-10' then
            exit;
        // 22-2-12
        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '22-2-12-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-2-12-20' then
            exit;
        // 22-2-13
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, 20011130D, false);

        if LastIteration = '22-2-13-10' then
            exit;
        // 22-2-14
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 14, LastILENo);

        if LastIteration = '22-2-14-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        Item: Record Item;
        Loc: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        CalcConsumption: Report "Calc. Consumption";
        i: Integer;
        SNCode: Code[20];
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '22-3-1-10' then
            exit;

        Loc.Get('BLUE');
        Loc.Validate("Bin Mandatory", true);
        Loc.Validate("Directed Put-away and Pick", true);
        Loc.Modify(true);

        Zone.Init();
        Zone.Validate("Location Code", 'BLUE');
        Zone.Validate(Code, 'PRODUCTION');
        Zone.Validate("Bin Type Code", 'QC');
        if Zone.Insert(true) then;

        Zone.Init();
        Zone.Validate("Location Code", 'BLUE');
        Zone.Validate(Code, 'RECEIVE');
        Zone.Validate("Bin Type Code", 'RECEIVE');
        if Zone.Insert(true) then;

        Zone.Init();
        Zone.Validate("Location Code", 'BLUE');
        Zone.Validate(Code, 'PICK');
        Zone.Validate("Bin Type Code", 'PUTPICK');
        if Zone.Insert(true) then;

        if LastIteration = '22-3-1-20' then
            exit;

        Bin.Init();
        Bin.Validate("Location Code", 'BLUE');
        Bin.Validate("Zone Code", 'RECEIVE');
        Bin.Validate(Code, 'R1');
        Bin.Validate("Bin Type Code", 'RECEIVE');
        if Bin.Insert(true) then;

        Bin.Init();
        Bin.Validate("Location Code", 'BLUE');
        Bin.Validate(Code, 'P1');
        Bin.Validate("Zone Code", 'PICK');
        Bin.Validate("Bin Type Code", 'PUTPICK');
        if Bin.Insert(true) then;

        Bin.Get('BLUE', 'A1');
        Bin.Validate("Bin Type Code", 'QC');
        Bin.Validate("Zone Code", 'PRODUCTION');
        Bin.Modify(true);

        if LastIteration = '22-3-1-30' then
            exit;

        Loc.Get('BLUE');
        Loc.Validate("Open Shop Floor Bin Code", 'A1');
        Loc.Validate("To-Production Bin Code", 'A1');
        Loc.Validate("From-Production Bin Code", 'A1');
        Loc.Validate("Receipt Bin Code", 'R1');
        Loc.Validate("Put-away Template Code", 'STD');
        Loc.Modify(true);

        if LastIteration = '22-3-1-40' then
            exit;

        GlobalPrecondition.SetupMovementWkshName();

        if LastIteration = '22-3-1-50' then
            exit;

        TestScriptMgmt.InsertRoutingHeader(RoutingHeader, 'F_PROD', RoutingHeader.Type::Serial);
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '010', RoutingLine.Type::"Work Center", '100', 2, 5, '100');
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '020', RoutingLine.Type::"Work Center", '400', 3, 5, '300');
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();
        WorkCenter.SetFilter("No.", '%1|%2', '100', '400');
        Clear(CalcWorkCenterCal);
        CalcWorkCenterCal.InitializeRequest(20010101D, 20011231D);
        CalcWorkCenterCal.UseRequestPage(false);
        CalcWorkCenterCal.SetTableView(WorkCenter);
        CalcWorkCenterCal.RunModal();

        Item.Get('F_PROD');
        Item.Validate("Routing No.", 'F_PROD');
        Item.Modify(true);

        Item.Get('1120');
        Item.Validate("Flushing Method", Item."Flushing Method"::Forward);
        Item.Modify(true);

        if LastIteration = '22-3-1-60' then
            exit;
        // 22-3-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS22-3-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 2, 'BOX', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'F_TEST_BACKFLUSH', '', 'WHITE', 5, 'PCS', 2.34, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'F_TEST_FORWFLUSHPICK', '', 'WHITE', 3, 'PCS', 3.45, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'F_TEST_FORWFLUSHPICK', '', 'RED', 1, 'PCS', 3.45, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'F_TEST_BACKFLUSHPICK', 'F1', 'BLUE', 5, 'PCS', 4.56, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1120', '', 'BLUE', 2, 'PCS', 5.67, false);

        if LastIteration = '22-3-2-10' then
            exit;

        SNCode := 'SN00000';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T2', 'WHITE', SNCode, '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        end;

        if LastIteration = '22-3-2-20' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '22-3-2-30' then
            exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'BLUE');

        if LastIteration = '22-3-2-40' then
            exit;

        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseRcptLine.Reset();
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '22-3-2-50' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-3-2-60' then
            exit;

        Clear(PurchHeader);
        PurchHeader.Find('-');
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '22-3-2-70' then
            exit;
        // 22-3-3
        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'F_PROD', 1, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Validate("Bin Code", 'W-07-0003');
        ProdOrder.Modify(true);
        WorkDate := 20011130D;

        if LastIteration = '22-3-3-10' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-3-3-20' then
            exit;

        ProdOrderLine.Reset();
        ProdOrderLine.FindFirst();

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 1);
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-3-3-30' then
            exit;

        ProdOrderComp.SetRange("Item No.", 'F_TEST_BACKFLUSHPICK');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Location Code", 'BLUE');
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-3-3-40' then
            exit;

        ProdOrderComp.SetRange("Item No.", 'F_TEST_FORWFLUSHPICK');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Quantity per", 1);
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-3-3-50' then
            exit;

        Clear(ProdOrderComp2);
        ProdOrderComp2.FindLast();
        i := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2."Line No." := i;
        ProdOrderComp2.Validate("Location Code", 'RED');
        ProdOrderComp2.Validate("Quantity per", 1);
        ProdOrderComp2.Validate("Routing Link Code", '100');
        ProdOrderComp2.Insert(true);

        if LastIteration = '22-3-3-60' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", '1120');
        if ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Validate("Location Code", 'BLUE');
            ProdOrderComp.Modify();
        end;

        if LastIteration = '22-3-3-70' then
            exit;
        // 22-3-4
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011126D,
          'F_TEST_BACKFLUSH', '', 'W-03-0001', 'W-07-0001', 3, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 20000, 20011126D,
          'F_TEST_FORWFLUSHPICK', '', 'W-02-0001', 'W-07-0002', 1, 'PCS');

        if LastIteration = '22-3-4-10' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '22-3-4-20' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-3-4-30' then
            exit;

        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'BLUE', 10000, 20011126D,
          '1120', '', 'P1', 'A1', 1, 'PCS');

        if LastIteration = '22-3-4-40' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '22-3-4-50' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-3-4-60' then
            exit;
        // 22-3-5
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '22-3-5-10' then
            exit;
        // 22-3-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '22-3-6-10' then
            exit;
        // 22-3-7
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '22-3-7-10' then
            exit;

        SNCode := 'SN00000';
        i := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        if WhseActivLine.Find('-') then
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '22-3-7-20' then
            exit;
        // 22-3-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '22-3-8-10' then
            exit;
        // 22-3-9
        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-3-9-10' then
            exit;

        ProdOrder.Find('-');
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '22-3-9-20' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.FindFirst();
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-3-9-30' then
            exit;
        // 22-3-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '22-3-10-10' then
            exit;
        // 22-3-11
        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '22-3-11-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-3-11-20' then
            exit;
        // 22-3-12
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, 20011130D, false);

        if LastIteration = '22-3-12-10' then
            exit;
        // 22-3-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo);

        if LastIteration = '22-3-13-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase8()
    var
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        WhseActivLine: Record "Warehouse Activity Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSourceType: Option " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '22-8-1-10' then
            exit;

        Item.SetFilter("No.", '%1|%2|%3', 'A_TEST', 'B_TEST', 'D_PROD');
        Item.ModifyAll("Item Tracking Code", 'LOTALL');

        if LastIteration = '22-8-1-20' then
            exit;
        // 22-8-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS22-8-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 20, 'PCS', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 25, 'PCS', 4.56, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'D_PROD', '', 'WHITE', 15, 'PCS', 2.34, false);

        if LastIteration = '22-8-2-10' then
            exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('A_TEST', '12', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 1, 20, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT01A', 0D, 0D);
        TestScriptMgmt.CreateItemTrackfromJnlLine('B_TEST', '', 'WHITE', '', 'LOT01B', 10, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('B_TEST', '', 'WHITE', '', 'LOT02B', 15, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        TestScriptMgmt.SetSourceItemTrkgInfo('D_PROD', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 30000, 1, 15, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT01D', 0D, 0D);

        if LastIteration = '22-8-2-20' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '22-8-2-30' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '22-8-2-40' then
            exit;

        WhseRcptLine.Reset();
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '22-8-2-50' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-8-2-60' then
            exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 10, 'WHITE');

        if LastIteration = '22-8-2-70' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        WhseProdRelease.Release(ProdOrder);

        if LastIteration = '22-8-2-80' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'A_TEST');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('A_TEST', '12', 'WHITE', '', '', 5407, 3, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 13, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT01A', 0D, 0D);
        end;
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('B_TEST', '', 'WHITE', '', '', 5407, 3, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 13, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT02B', 0D, 0D);
        end;
        ProdOrderComp.SetRange("Item No.", 'D_PROD');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('D_PROD', '', 'WHITE', '', '', 5407, 3, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 15, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT01D', 0D, 0D);
        end;

        if LastIteration = '22-8-2-90' then
            exit;

        ProdOrder.Reset();
        ProdOrder.Find('-');
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComp.Find('-') then
            repeat
                ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                  "Warehouse Worksheet Document Type".FromInteger(WhseSourceType::Production), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", DATABASE::"Prod. Order Component",
                  ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.");
            until ProdOrderComp.Next() = 0;
        Commit();

        Clear(CreatePickFromWhseSource);
        Commit();
        ProdOrder.Reset();
        ProdOrder.Find('-');
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '22-8-2-100' then
            exit;
        // 22-8-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '22-8-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase9()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ItemJnlLine: Record "Item Journal Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ITCode: Record "Item Tracking Code";
        BinContent: Record "Bin Content";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        ReplenishmtBatch: Report "Calculate Bin Replenishment";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '22-9-1-10' then
            exit;

        ProdBOMHeader.Get('E_PROD');
        ProdBOMHeader.Status := ProdBOMHeader.Status::New;
        ProdBOMHeader.Modify(true);

        ProdBOMLine.Reset();
        ProdBOMLine.SetRange("Production BOM No.", 'E_PROD');
        ProdBOMLine.FindLast();
        ProdBOMLine."Line No." := ProdBOMLine."Line No." + 10000;
        ProdBOMLine.Validate("No.", 'T_TEST');
        ProdBOMLine.Validate("Variant Code", 'T2');
        ProdBOMLine.Validate("Quantity per", 0.5);
        ProdBOMLine.Insert(true);

        ProdBOMHeader.Get('E_PROD');
        ProdBOMHeader.Status := ProdBOMHeader.Status::Certified;
        ProdBOMHeader.Modify(true);

        Item.SetFilter("No.", '%1|%2', 'D_PROD', 'T_TEST');
        Item.ModifyAll("Flushing Method", 1);
        Item.SetFilter("No.", '%1|%2', 'A_TEST', 'B_TEST');
        Item.ModifyAll("Flushing Method", 2);

        ITCode.Init();
        ITCode.Code := 'LOTSNALL';
        ITCode.Validate("SN Specific Tracking", true);
        ITCode.Validate("Lot Specific Tracking", true);
        ITCode.Validate("SN Warehouse Tracking", true);
        ITCode.Validate("Lot Warehouse Tracking", true);
        if not ITCode.Insert(true) then
            ITCode.Modify();

        Item.Get('T_TEST');
        Item."Item Tracking Code" := 'LOTSNALL';
        Item.Modify();

        if LastIteration = '22-9-1-20' then
            exit;

        Item.Get('B_TEST');
        Item."Item Tracking Code" := 'LOTALL';
        Item.Modify();

        ITCode.Get('LOTALL');
        ITCode.Validate("Lot Warehouse Tracking", true);
        ITCode.Modify();

        if LastIteration = '22-9-1-30' then
            exit;

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'A_TEST', '12', 'PCS', 13, 26);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'B_TEST', '', 'PCS', 13, 25);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'T_TEST', 'T2', 'BOX', 1, 5);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'D_PROD', '', 'PCS', 15, 30);

        if LastIteration = '22-9-1-40' then
            exit;

        TestScriptMgmt.InsertRoutingHeader(RoutingHeader, 'TEST', RoutingHeader.Type::Serial);
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '010', RoutingLine.Type::"Work Center", '100', 20, 5, '100');
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '020', RoutingLine.Type::"Work Center", '400', 30, 5, '');
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        if LastIteration = '22-9-1-50' then
            exit;

        WorkCenter.SetFilter("No.", '%1|%2', '100', '400');
        Clear(CalcWorkCenterCal);
        CalcWorkCenterCal.InitializeRequest(20010101D, 20011231D);
        CalcWorkCenterCal.UseRequestPage(false);
        CalcWorkCenterCal.SetTableView(WorkCenter);
        CalcWorkCenterCal.RunModal();

        if LastIteration = '22-9-1-60' then
            exit;

        Item.Get('E_PROD');
        Item.Validate("Routing No.", 'TEST');
        Item.Modify(true);

        if LastIteration = '22-9-1-70' then
            exit;
        // 22-9-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS22-9-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 25, 'PCS', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 30, 'PCS', 4.56, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'D_PROD', '', 'WHITE', 20, 'PCS', 2.34, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 7, 'BOX', 1.23, false);

        if LastIteration = '22-9-2-10' then
            exit;
        TestScriptMgmt.CreateItemTrackfromJnlLine('B_TEST', '', 'WHITE', '', 'LOT01B', 10, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('B_TEST', '', 'WHITE', '', 'LOT02B', 20, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);

        if LastIteration = '22-9-2-20' then
            exit;

        SNCode := 'SN00';
        for i := 1 to 7 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T2', 'WHITE', SNCode, 'LOT01T', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 40000, true);
        end;

        if LastIteration = '22-9-2-30' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '22-9-2-40' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '22-9-2-50' then
            exit;

        WhseRcptLine.Reset();
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '22-9-2-60' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-9-2-70' then
            exit;

        Clear(ReplenishmtBatch);
        BinContent.Reset();
        BinContent.FindFirst();
        ReplenishmtBatch.UseRequestPage(false);
        ReplenishmtBatch.InitializeRequest('MOVEMENT', 'DEFAULT', 'WHITE', true, true, false);
        ReplenishmtBatch.SetTableView(BinContent);
        ReplenishmtBatch.RunModal();

        if LastIteration = '22-9-2-80' then
            exit;

        WhseWkshLine.FindFirst();
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::Item, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '22-9-2-90' then
            exit;

        SNCode := 'SN01';
        i := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        WhseActivLine.SetRange("Bin Code", 'W-01-0001');
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SetRange("Bin Code");
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Validate("Lot No.", 'LOT01T');
                WhseActivLine.Modify(true);
            until (WhseActivLine.Next() = 0) or
                  ((WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take) and
                   (WhseActivLine."Bin Code" <> 'W-01-0001'));
        end;

        if LastIteration = '22-9-2-100' then
            exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Item No.", 'B_TEST');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LOT02B');
                WhseActivLine.Validate("Qty. to Handle", 20);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '22-9-2-110' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-9-2-120' then
            exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'E_PROD', 2, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Validate("Bin Code", 'W-07-0003');
        ProdOrder.Modify(true);
        WorkDate := 20011130D;

        if LastIteration = '22-9-2-130' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-9-2-140' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.ModifyAll("Routing Link Code", '100', true);

        if LastIteration = '22-9-2-150' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.FindFirst() then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('B_TEST', '', 'WHITE', '', '', 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 3, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LOT02B', 0D, 0D);
        end;

        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.FindFirst() then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('T_TEST', 'T2', 'WHITE', '', '', 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 1, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011130D, 'SN02', 'LOT01T', 0D, 0D);
        end;

        if LastIteration = '22-9-2-160' then
            exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '22-9-2-170' then
            exit;
        // 22-9-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '22-9-3-10' then
            exit;
        // 22-9-4
        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '22-9-4-10' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-9-4-20' then
            exit;
        // 22-9-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '22-9-5-10' then
            exit;
        // 22-9-6
        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'E_PROD', 8, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Validate("Bin Code", 'W-07-0003');
        ProdOrder.Modify(true);

        if LastIteration = '22-9-6-10' then
            exit;

        ProdOrder.Reset();
        ProdOrder.SetRange(Status, 2);
        ProdOrder.Find('-');
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-9-6-20' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.ModifyAll("Routing Link Code", '100', true);

        if LastIteration = '22-9-6-30' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetFilter("Item No.", '%1|%2', 'D_PROD', 'T_TEST');
        ProdOrderComp.ModifyAll("Flushing Method", 2, true);
        ProdOrderComp.SetFilter("Item No.", '%1|%2', 'A_TEST', 'B_TEST');
        ProdOrderComp.ModifyAll("Flushing Method", 1, true);

        if LastIteration = '22-9-6-40' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.FindFirst() then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('B_TEST', '', 'WHITE', '', '', 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 10, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LOT02B', 0D, 0D);
        end;

        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.FindFirst() then begin
            SNCode := 'SN02';
            for i := 1 to 4 do begin
                SNCode := IncStr(SNCode);
                TestScriptMgmt.CreateItemTrackfromJnlLine(
                  'T_TEST', 'T2', 'WHITE', SNCode, 'LOT01T', -1, 1, "Reservation Status"::Surplus, 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", false);
            end;
        end;

        if LastIteration = '22-9-6-50' then
            exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '22-9-6-60' then
            exit;
        // 22-9-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '22-9-7-10' then
            exit;
        // 22-9-8
        ProdOrder.Reset();
        ProdOrder.Find('+');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '22-9-8-10' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-9-8-20' then
            exit;
        // 22-9-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '22-9-9-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase10()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ItemJnlLine: Record "Item Journal Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ITCode: Record "Item Tracking Code";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SNCode: Code[20];
        WhseSourceType: Option " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production;
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '22-10-1-10' then
            exit;

        ProdBOMHeader.Get('E_PROD');
        ProdBOMHeader.Status := ProdBOMHeader.Status::New;
        ProdBOMHeader.Modify(true);

        ProdBOMLine.Reset();
        ProdBOMLine.SetRange("Production BOM No.", 'E_PROD');
        ProdBOMLine.FindLast();
        ProdBOMLine."Line No." := ProdBOMLine."Line No." + 10000;
        ProdBOMLine.Validate("No.", 'T_TEST');
        ProdBOMLine.Validate("Variant Code", 'T2');
        ProdBOMLine.Validate("Quantity per", 0.5);
        ProdBOMLine.Insert(true);

        ProdBOMHeader.Get('E_PROD');
        ProdBOMHeader.Status := ProdBOMHeader.Status::Certified;
        ProdBOMHeader.Modify(true);

        Item.SetFilter("No.", '%1|%2', 'D_PROD', 'T_TEST');
        Item.ModifyAll("Flushing Method", 3);
        Item.SetFilter("No.", '%1|%2', 'A_TEST', 'B_TEST');
        Item.ModifyAll("Flushing Method", 4);

        ITCode.Init();
        ITCode.Code := 'LOTSNALL';
        ITCode.Validate("SN Specific Tracking", true);
        ITCode.Validate("Lot Specific Tracking", true);
        ITCode.Validate("SN Warehouse Tracking", true);
        ITCode.Validate("Lot Warehouse Tracking", true);
        if not ITCode.Insert(true) then
            ITCode.Modify();

        Item.Get('T_TEST');
        Item."Item Tracking Code" := 'LOTSNALL';
        Item.Modify();

        if LastIteration = '22-10-1-20' then
            exit;

        Item.Get('B_TEST');
        Item."Item Tracking Code" := 'LOTALL';
        Item.Modify();

        ITCode.Get('LOTALL');
        ITCode.Validate("Lot Warehouse Tracking", true);
        ITCode.Modify();

        if LastIteration = '22-10-1-30' then
            exit;

        TestScriptMgmt.InsertRoutingHeader(RoutingHeader, 'TEST', RoutingHeader.Type::Serial);
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '010', RoutingLine.Type::"Work Center", '100', 20, 5, '100');
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '020', RoutingLine.Type::"Work Center", '400', 30, 5, '');
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        if LastIteration = '22-10-1-40' then
            exit;

        WorkCenter.SetFilter("No.", '%1|%2', '100', '400');
        Clear(CalcWorkCenterCal);
        CalcWorkCenterCal.InitializeRequest(20010101D, 20011231D);
        CalcWorkCenterCal.UseRequestPage(false);
        CalcWorkCenterCal.SetTableView(WorkCenter);
        CalcWorkCenterCal.RunModal();

        if LastIteration = '22-10-1-50' then
            exit;

        Item.Get('E_PROD');
        Item.Validate("Routing No.", 'TEST');
        Item.Modify(true);

        if LastIteration = '22-10-1-60' then
            exit;
        // 22-10-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS22-10-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 25, 'PCS', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 30, 'PCS', 4.56, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'D_PROD', '', 'WHITE', 20, 'PCS', 2.34, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 7, 'BOX', 1.23, false);

        if LastIteration = '22-10-2-10' then
            exit;

        TestScriptMgmt.CreateItemTrackfromJnlLine('B_TEST', '', 'WHITE', '', 'LOT01B', 10, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('B_TEST', '', 'WHITE', '', 'LOT02B', 20, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);

        if LastIteration = '22-10-2-20' then
            exit;

        SNCode := 'SN00';
        for i := 1 to 7 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T2', 'WHITE', SNCode, 'LOT01T', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 40000, true);
        end;

        if LastIteration = '22-10-2-30' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '22-10-2-40' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '22-10-2-50' then
            exit;

        WhseRcptLine.Reset();
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '22-10-2-60' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-10-2-70' then
            exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'E_PROD', 2, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Validate("Bin Code", 'W-07-0003');
        ProdOrder.Modify(true);
        WorkDate := 20011130D;

        if LastIteration = '22-10-2-80' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-10-2-90' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.ModifyAll("Routing Link Code", '100', true);

        if LastIteration = '22-10-2-100' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('B_TEST', '', 'WHITE', '', '', 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 3, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LOT02B', 0D, 0D);
        end;

        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('T_TEST', 'T2', 'WHITE', '', '', 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 1, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011130D, 'SN02', 'LOT01T', 0D, 0D);
        end;

        if LastIteration = '22-10-2-110' then
            exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '22-10-2-120' then
            exit;
        // 22-10-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '22-10-3-10' then
            exit;
        // 22-10-4
        ProdOrder.Reset();
        ProdOrder.Find('-');
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComp.Find('-') then
            repeat
                ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                  "Warehouse Worksheet Document Type".FromInteger(WhseSourceType::Production), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", DATABASE::"Prod. Order Component",
                  ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.");
            until ProdOrderComp.Next() = 0;
        Commit();

        Clear(CreatePickFromWhseSource);
        Commit();
        ProdOrder.Reset();
        ProdOrder.Find('-');
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();

        if LastIteration = '22-10-4-10' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-10-4-20' then
            exit;

        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '22-10-4-30' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-10-4-40' then
            exit;
        // 22-10-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '22-10-5-10' then
            exit;
        // 22-10-6
        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'E_PROD', 10, 'WHITE');
        ProdOrder.Validate("Starting Date", 20011129D);
        ProdOrder.Validate("Ending Date", 20011129D);
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Validate("Bin Code", 'W-07-0003');
        ProdOrder.Modify(true);

        if LastIteration = '22-10-6-10' then
            exit;

        ProdOrder.Reset();
        ProdOrder.SetRange(Status, 2);
        ProdOrder.Find('-');
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-10-6-20' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.ModifyAll("Routing Link Code", '100', true);

        if LastIteration = '22-10-6-30' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetFilter("Item No.", '%1|%2', 'D_PROD', 'T_TEST');
        ProdOrderComp.ModifyAll("Flushing Method", 4, true);
        ProdOrderComp.SetFilter("Item No.", '%1|%2', 'A_TEST', 'B_TEST');
        ProdOrderComp.ModifyAll("Flushing Method", 3, true);

        if LastIteration = '22-10-6-40' then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('B_TEST', '', 'WHITE', '', '', 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 13, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LOT02B', 0D, 0D);
        end;

        ProdOrderComp.SetRange("Item No.", 'T_TEST');
        if ProdOrderComp.Find('-') then begin
            SNCode := 'SN02';
            for i := 1 to 5 do begin
                SNCode := IncStr(SNCode);
                TestScriptMgmt.CreateItemTrackfromJnlLine(
                  'T_TEST', 'T2', 'WHITE', SNCode, 'LOT01T', -1, 1, "Reservation Status"::Surplus, 5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", false);
            end;
        end;

        if LastIteration = '22-10-6-50' then
            exit;

        ProdOrder.Reset();
        ProdOrder.SetRange(Status, 2);
        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '22-10-6-60' then
            exit;
        // 22-10-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '22-10-7-10' then
            exit;
        // 22-10-8
        ProdOrder.Reset();
        ProdOrder.Find('+');
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComp.Find('-') then
            repeat
                ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                  "Warehouse Worksheet Document Type".FromInteger(WhseSourceType::Production), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", DATABASE::"Prod. Order Component",
                  ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.");
            until ProdOrderComp.Next() = 0;
        Commit();

        Clear(CreatePickFromWhseSource);
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();

        if LastIteration = '22-10-8-10' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '22-10-8-20' then
            exit;

        ProdOrder.Reset();
        ProdOrder.Find('+');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '22-10-8-30' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '22-10-8-40' then
            exit;
        // 22-10-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '22-10-9-10' then
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
}

