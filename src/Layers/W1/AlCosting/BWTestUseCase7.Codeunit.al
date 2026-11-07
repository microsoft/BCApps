codeunit 103357 "BW Test Use Case 7"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 7");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103357, 7, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        ResEntry: Record "Reservation Entry";
        SelectionForm: Page "Whse. Test Selection";
        TestScriptMgmt: Codeunit "BW TestscriptManagement";
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
            4:
                PerformTestCase4();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        GenPostSetup: Record "General Posting Setup";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Purch. Account", '7130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '7-1-1-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-1', 'A_TEST', '11', 'SILVER', '', 5, 'PCS', 46, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-1', 'B_TEST', '', 'SILVER', '', 1, 'PCS', 12, 0, 'S-03-0001');

        if LastIteration = '7-1-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-1-1-30' then
            exit;
        // 7-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS7-1-2', false);

        if LastIteration = '7-1-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_Test', '', 'SILVER', 2, 'BOX', 55, false);
        PurchLine.Validate("Bin Code", 'S-01-0001');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '11', 'SILVER', -4, 'PCS', 46, false);

        if LastIteration = '7-1-2-20' then
            exit;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN01', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN02', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '7-1-2-30' then
            exit;
        // 7-1-3
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-1-3-10' then
            exit;

        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '7-1-3-20' then
            exit;
        // 7-1-4
        Clear(UndoPurchRcptLine);
        PurchRcptLine.Reset();
        PurchRcptLine.SetCurrentKey("Order No.");
        PurchRcptLine.SetRange("Order No.", PurchHeader."No.");
        PurchRcptLine.SetRange("Line No.", 20000);
        PurchRcptLine.FindFirst();
        UndoPurchRcptLine.SetHideDialog(true);
        UndoPurchRcptLine.Run(PurchRcptLine);

        if LastIteration = '7-1-4-10' then
            exit;
        // 7-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '7-1-5-10' then
            exit;
        // 7-1-6
        Clear(UndoPurchRcptLine);
        PurchRcptLine.Reset();
        PurchRcptLine.SetCurrentKey("Order No.");
        PurchRcptLine.SetRange("Order No.", PurchHeader."No.");
        PurchRcptLine.SetRange("Line No.", 10000);
        PurchRcptLine.FindFirst();
        UndoPurchRcptLine.SetHideDialog(true);
        UndoPurchRcptLine.Run(PurchRcptLine);

        if LastIteration = '7-1-6-10' then
            exit;
        // 7-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '7-1-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptLine: Record "Return Shipment Line";
        UndoRtrnShptLine: Codeunit "Undo Return Shipment Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-2-1-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-2-1', 'A_TEST', '12', 'SILVER', '', 10, 'PCS', 9.87, 0, 'S-01-0001');

        if LastIteration = '7-2-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-2-1-30' then
            exit;
        // 7-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS7-2-2', false);
        PurchHeader.Validate("Vendor Cr. Memo No.", 'TCS7-2-2');
        PurchHeader.Modify();

        if LastIteration = '7-2-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '12', 'SILVER', 4, 'PCS', 9.87, false);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 10000, 'NONEED');
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '12', 'SILVER', -3, 'PCS', 9.87, false);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 20000, 'WRONG');
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_Test', '12', 'SILVER', -1, 'PCS', 9.87, false);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 30000, 'DAMAGED');

        if LastIteration = '7-2-2-20' then
            exit;

        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-2-2-30' then
            exit;
        // 7-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '7-2-3-10' then
            exit;
        // 7-2-4
        Clear(UndoRtrnShptLine);
        ReturnShptLine.Reset();
        ReturnShptLine.SetCurrentKey("Return Order No.");
        ReturnShptLine.SetRange("Return Order No.", PurchHeader."No.");
        ReturnShptLine.SetRange("Return Order Line No.", 20000);
        ReturnShptLine.FindFirst();
        UndoRtrnShptLine.SetHideDialog(true);
        UndoRtrnShptLine.Run(ReturnShptLine);

        if LastIteration = '7-2-4-10' then
            exit;
        // 7-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '7-2-5-10' then
            exit;
        // 7-2-6
        Clear(UndoRtrnShptLine);
        ReturnShptLine.Reset();
        ReturnShptLine.SetCurrentKey("Return Order No.");
        ReturnShptLine.SetRange("Return Order No.", PurchHeader."No.");
        ReturnShptLine.SetRange("Return Order Line No.", 10000);
        ReturnShptLine.FindFirst();
        UndoRtrnShptLine.SetHideDialog(true);
        UndoRtrnShptLine.Run(ReturnShptLine);

        if LastIteration = '7-2-6-10' then
            exit;
        // 7-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '7-2-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        UndoShptLine: Codeunit "Undo Sales Shipment Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-3-1-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-3-1', 'A_TEST', '12', 'WHITE', '', 10, 'PCS', 12.34, 0, '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-3-1', 'B_TEST', '', 'SILVER', '', 1, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-3-1', 'L_TEST', '', 'SILVER', '', 3, 'BOX', 43.21, 0, 'S-02-0001');

        if LastIteration = '7-3-1-20' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 1, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 2, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 2, 2, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);

        if LastIteration = '7-3-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-3-1-40' then
            exit;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', 10000, 20011125D, 'A_TEST', '12', '', 'W-01-0001', 9, 'PCS');

        if LastIteration = '7-3-1-50' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '7-2-1-60' then
            exit;
        // 7-3-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '7-3-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'L_Test', '', 3, 'BOX', 45.67, 'SILVER', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '12', 8, 'PCS', 21.34, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A_Test', '12', -5, 'PCS', 21.34, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-03-0001');
        SalesLine.Modify(true);

        if LastIteration = '7-3-2-20' then
            exit;

        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, 1, '', 'LN01');
        CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 2, 2, '', 'LN02');
        CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '7-3-2-30' then
            exit;

        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-3-2-40' then
            exit;
        // 7-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '7-3-3-10' then
            exit;
        // 7-3-4
        Clear(WhseShptHeader);
        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, '', '', '');
        WhseShptHeader.Validate("Location Code", 'WHITE');
        WhseShptHeader.Modify();

        if LastIteration = '7-3-4-10' then
            exit;

        TestScriptMgmt.CreateWhseShptBySourceFilter(WhseShptHeader, 'CUST30000');

        if LastIteration = '7-3-4-20' then
            exit;

        Commit();
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '7-3-4-30' then
            exit;
        // 7-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '7-3-5-10' then
            exit;
        // 7-3-6
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '7-3-6-10' then
            exit;

        WhseShptLine.FindFirst();
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '7-3-6-20' then
            exit;
        // 7-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '7-3-7-10' then
            exit;
        // 7-3-8
        Clear(UndoShptLine);
        SalesShptLine.Reset();
        SalesShptLine.SetRange("No.", 'A_TEST');
        SalesShptLine.SetFilter(Quantity, '=%1', -5);
        SalesShptLine.FindFirst();
        UndoShptLine.SetHideDialog(true);
        UndoShptLine.Run(SalesShptLine);

        if LastIteration = '7-3-8-10' then
            exit;
        // 7-3-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '7-3-9-10' then
            exit;
        // 7-3-10
        Clear(UndoShptLine);
        SalesShptLine.Reset();
        SalesShptLine.SetRange("No.", 'L_TEST');
        SalesShptLine.SetFilter(Quantity, '<>%1', 0);
        SalesShptLine.FindFirst();
        UndoShptLine.SetHideDialog(true);
        UndoShptLine.Run(SalesShptLine);

        if LastIteration = '7-3-10-10' then
            exit;
        // 7-3-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '7-3-11-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RtrnRcptLine: Record "Return Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        UndoSalesRcptLine: Codeunit "Undo Return Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-4-1-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-4-1', 'T_TEST', '', 'SILVER', '', 7, 'BOX', 100, 0, 'S-01-0001');

        if LastIteration = '7-4-1-20' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 1, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 2, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 3, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 4, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 5, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN05', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 6, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN06', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 7, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN07', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);

        if LastIteration = '7-4-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-4-1-40' then
            exit;
        // 7-4-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '7-4-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', '', 4, 'BOX', 100, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-01-0001');
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', '', -2, 'BOX', 100, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-01-0001');
        SalesLine.Modify(true);

        if LastIteration = '7-4-2-20' then
            exit;

        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN00008', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN00009', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN00010', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN00011', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '7-4-2-30' then
            exit;

        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, -1, -1, 'SN01', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, -1, -1, 'SN03', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '7-4-2-40' then
            exit;

        SalesHeader.Receive := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-4-2-50' then
            exit;
        // 7-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '7-4-3-10' then
            exit;
        // 7-4-4
        Clear(UndoSalesRcptLine);
        RtrnRcptLine.Reset();
        RtrnRcptLine.SetRange("Line No.", 10000);
        RtrnRcptLine.FindFirst();
        UndoSalesRcptLine.SetHideDialog(true);
        UndoSalesRcptLine.Run(RtrnRcptLine);

        if LastIteration = '7-4-4-10' then
            exit;
        // 7-4-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '7-4-5-10' then
            exit;
        // 7-4-6
        Clear(UndoSalesRcptLine);
        RtrnRcptLine.Reset();
        RtrnRcptLine.SetRange("Line No.", 20000);
        RtrnRcptLine.FindFirst();
        UndoSalesRcptLine.SetHideDialog(true);
        UndoSalesRcptLine.Run(RtrnRcptLine);

        if LastIteration = '7-4-6-10' then
            exit;
        // 7-4-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '7-4-7-10' then
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

