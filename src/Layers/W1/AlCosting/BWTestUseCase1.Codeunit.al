codeunit 103351 "BW Test Use Case 1"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 1");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103351, 1, 0, '', 1);

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
            5:
                PerformTestCase5();
            6:
                PerformTestCase6();
            7:
                PerformTestCase7();
            13:
                PerformTestCase13();
            14:
                PerformTestCase14();
            16:
                PerformTestCase16();
            17:
                PerformTestCase17();
            19:
                PerformTestCase19();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-1-1-10' then
            exit;

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Purch. Account", '7130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '1-1-1-20' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Receive" := true;
        Loc.Modify();

        if LastIteration = '1-1-1-30' then
            exit;
        // 1-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS1-1-2', false);

        if LastIteration = '1-1-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_Test', '', 'SILVER', 2, 'BOX', 100, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'C_Test', '31', 'SILVER', 7, 'PCS', 22, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'GPS', '', '', 1, '', 15, false);
        PurchLine.Validate("Qty. to Receive", 1);
        PurchLine.Modify(true);

        if LastIteration = '1-1-2-20' then
            exit;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN01', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN02', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '1-1-2-30' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '1-1-2-40' then
            exit;

        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'SILVER', '', 'S-01-0001');

        if LastIteration = '1-1-2-50' then
            exit;

        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'SILVER');

        if LastIteration = '1-1-2-60' then
            exit;

        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 2, LastILENo);

        if LastIteration = '1-1-2-70' then
            exit;

        WhseRcptLine."No." := WhseRcptHeader."No.";
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '1-1-2-80' then
            exit;
        // 1-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-1-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-2-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-2-1', 'A_TEST', '', 'SILVER', '', 10, 'PCS', 10, 0, 'S-01-0001');

        if LastIteration = '1-2-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-2-1-30' then
            exit;
        // 1-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS1-2-2', false);
        PurchHeader.Validate("Vendor Cr. Memo No.", 'TCS1-2-2');

        if LastIteration = '1-2-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', 4, 'PCS', 12, false);
        PurchLine.Validate("Return Reason Code", 'NONEED');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', -3, 'PCS', 12, false);
        PurchLine.Validate("Return Reason Code", 'WRONG');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', -1, 'PCS', 12, false);
        PurchLine.Validate("Return Reason Code", 'DAMAGED');
        PurchLine.Modify(true);

        if LastIteration = '1-2-2-20' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '1-2-2-30' then
            exit;

        PurchHeader.Invoice := true;
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-2-2-40' then
            exit;
        // 1-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-2-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        GenPostSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        CreateRes: Codeunit "Create Reserv. Entry";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-3-1-10' then
            exit;

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Purch. Credit Memo Account", '7130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '1-3-1-20' then
            exit;
        // 1-3-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS1-3-2', false);
        PurchHeader.Validate("Vendor Cr. Memo No.", 'TCS1-3-2');
        PurchHeader.Modify(true);

        if LastIteration = '1-3-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_Test', '', 'SILVER', -2, 'BOX', 12, false);
        PurchLine.Validate("Bin Code", 'S-03-0001');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '11', 'SILVER', -3, 'PCS', 11, false);
        PurchLine.Validate("Bin Code", 'S-01-0001');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'P-RESTOCK', '', 'SILVER', 2, '', 32, false);

        if LastIteration = '1-3-2-20' then
            exit;

        CreateReservEntryFor(39, 3, PurchHeader."No.", '', 0, 10000, 1, -1, -1, 'SN01', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);
        CreateReservEntryFor(39, 3, PurchHeader."No.", '', 0, 10000, 1, -1, -1, 'SN02', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);

        if LastIteration = '1-3-2-30' then
            exit;

        ItemChargeAssgntPurch.Init();
        ItemChargeAssgntPurch."Document Type" := PurchLine."Document Type";
        ItemChargeAssgntPurch."Document No." := PurchLine."Document No.";
        ItemChargeAssgntPurch."Document Line No." := 30000;
        ItemChargeAssgntPurch."Item Charge No." := 'P-RESTOCK';
        ItemChargeAssignt.CreateDocChargeAssgnt(ItemChargeAssgntPurch, PurchLine."Receipt No.");
        PurchLine.UpdateItemChargeAssgnt();
        ItemChargeAssignt.AssignItemCharges(PurchLine, 2, 64, 1);

        if LastIteration = '1-3-2-40' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '1-3-2-50' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-3-2-60' then
            exit;
        // 1-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-3-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        InvSetup: Record "Inventory Setup";
        Loc: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        Loc.Get('BLUE');
        Loc."Bin Mandatory" := true;
        Loc.Modify();

        InvSetup.Get();
        InvSetup."Location Mandatory" := true;
        InvSetup.Modify();

        if LastIteration = '1-4-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-4-1', 'B_TEST', '', 'SILVER', '', 10, 'PCS', 12, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS1-4-1', '80216-T', '', 'BLUE', '', 5, 'PCS', 1.23, 0, 'A1');

        TestScriptMgmt.InsertResEntry(ResEntry, 'BLUE', 10002, "Reservation Status"::Prospect, 20011125D, '80216-T', '', '', 'LN0001', 3, 3, 83, 2,
          'ITEM', 'DEFAULT', 10002, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'BLUE', 10002, "Reservation Status"::Prospect, 20011125D, '80216-T', '', '', 'LN01', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', 10002, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'BLUE', 10002, "Reservation Status"::Prospect, 20011125D, '80216-T', '', '', 'LN02', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', 10002, true);

        if LastIteration = '1-4-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-4-1-30' then
            exit;
        // 1-4-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '1-4-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'B_Test', '', 8, 'PCS', 12, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-01-0001');
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'B_Test', '', -2, 'PCS', 12, 'SILVER', 'WRONG');
        SalesLine.Validate("Bin Code", 'S-01-0002');
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_Test', '', -3, 'PCS', 12, 'SILVER', 'WRONG');
        SalesLine.Validate("Bin Code", 'S-01-0003');
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'B_Test', '', -1, 'PCS', 12, 'BLUE', 'WRONG');
        SalesLine.Validate("Bin Code", 'A1');
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '80216-T', '', 3, 'PCS', 1.23, 'BLUE', '');
        SalesLine.Validate("Bin Code", 'A1');
        SalesLine.Validate("Unit Price", 1.23);
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '80216-T', '', 2, 'PCS', 1.23, 'BLUE', '');
        SalesLine.Validate("Bin Code", 'A1');
        SalesLine.Validate("Unit Price", 1.23);
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::"Charge (Item)", 'JB-FREIGHT', '', 1, '', 2, 'BLUE', '');

        if LastIteration = '1-4-2-20' then
            exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'BLUE', 50000, "Reservation Status"::Prospect, 20011125D, '80216-T', '', '', 'LN0001', 3, 3, 37, 1, SalesHeader."No.", '', 50000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'BLUE', 60000, "Reservation Status"::Prospect, 20011125D, '80216-T', '', '', 'LN01', 1, 1, 37, 1, SalesHeader."No.", '', 60000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'BLUE', 60000, "Reservation Status"::Prospect, 20011125D, '80216-T', '', '', 'LN02', 1, 1, 37, 1, SalesHeader."No.", '', 60000, true);

        if LastIteration = '1-4-2-30' then
            exit;

        ItemChargeAssgntSales.Init();
        ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
        ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
        ItemChargeAssgntSales."Document Line No." := 70000;
        ItemChargeAssgntSales."Item Charge No." := 'JB-FREIGHT';
        ItemChargeAssignt.CreateDocChargeAssgn(ItemChargeAssgntSales, '');
        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Item No.", 'B_TEST');
        ItemChargeAssgntSales.DeleteAll();
        ItemChargeAssgntSales.Reset();
        SalesLine.UpdateItemChargeAssgnt();
        ItemChargeAssignt.AssignItemCharges(SalesLine, 1, 2, 1);

        if LastIteration = '1-4-2-40' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '1-4-2-50' then
            exit;

        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-4-2-60' then
            exit;
        // 1-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-4-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-5-1-10' then
            exit;
        // 1-5-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011124D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '1-5-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'S_Test', '42', 20, 'PCS', 0, 'SILVER', 'NONEED');
        SalesLine.Validate("Bin Code", 'S-01-0003');
        SalesLine.Validate("Return Qty. to Receive", 13);
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);

        if LastIteration = '1-5-2-20' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '1-5-2-30' then
            exit;

        SalesHeader.Invoice := true;
        SalesHeader.Receive := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-5-2-40' then
            exit;
        // 1-5-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-5-3-10' then
            exit;
        // 1-5-4
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        SalesLine.Validate("Return Qty. to Receive", 5);
        SalesLine.Modify(true);

        if LastIteration = '1-5-4-10' then
            exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-5-4-20' then
            exit;
        // 1-5-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '1-5-5-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    var
        GenPostSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        CreateRes: Codeunit "Create Reserv. Entry";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-6-1-10' then
            exit;

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Sales Credit Memo Account", '6130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '1-6-1-20' then
            exit;
        // 1-6-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '30000', 0D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '1-6-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', '', 2, 'BOX', 80, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-02-0001');
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '12', 5, 'PCS', 55, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-01-0001');
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'UPS', '', 2, '', 30, 'SILVER', '');

        if LastIteration = '1-6-2-20' then
            exit;

        CreateReservEntryFor(37, 3, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN01', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);
        CreateReservEntryFor(37, 3, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN02', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);

        if LastIteration = '1-6-2-30' then
            exit;

        ItemChargeAssgntSales.Init();
        ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
        ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
        ItemChargeAssgntSales."Document Line No." := 30000;
        ItemChargeAssgntSales."Item Charge No." := 'UPS';
        ItemChargeAssignt.CreateDocChargeAssgn(ItemChargeAssgntSales, SalesLine."Return Receipt No.");
        SalesLine.UpdateItemChargeAssgnt();
        ItemChargeAssignt.AssignItemCharges(SalesLine, 2, 60, 1);

        if LastIteration = '1-6-2-40' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '1-6-2-50' then
            exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-6-2-60' then
            exit;
        // 1-6-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-6-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        Loc: Record Location;
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        BC: Record "Bin Content";
        GetBC: Report "Whse. Get Bin Content";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        Loc.Get('BLUE');
        Loc."Bin Mandatory" := true;
        Loc.Modify();

        if LastIteration = '1-7-1-10' then
            exit;
        // 1-7-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-7-2', 'A_TEST', '', 'BLUE', '', 52, 'PCS', 14, 0, 'A1');

        if LastIteration = '1-7-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-7-2-20' then
            exit;
        // 1-7-3
        TestScriptMgmt.InsertTransferHeader(TransHeader, 'BLUE', 'SILVER', 'OWN LOG.', 20011125D);

        if LastIteration = '1-7-3-10' then
            exit;

        BC.Reset();
        BC.SetRange("Location Code", 'BLUE');
        BC.SetRange("Item No.", 'A_TEST');
        GetBC.SetTableView(BC);
        GetBC.UseRequestPage(false);
        GetBC.InitializeTransferHeader(TransHeader);
        GetBC.RunModal();
        Clear(GetBC);

        if LastIteration = '1-7-3-20' then
            exit;

        TransLine.Get(TransHeader."No.", 10000);
        TransLine.Validate(Quantity, 12);
        TransLine.Modify(true);

        if LastIteration = '1-7-3-30' then
            exit;

        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 20000, 'A_TEST', '', 'PCS', 20, 0, 20);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 30000, 'A_TEST', '', 'PCS', 18, 0, 18);
        TransLine.SetRange("Document No.", TransHeader."No.");
        TransLine.ModifyAll("Transfer-from Bin Code", 'A1', true);
        TransLine.ModifyAll("Transfer-To Bin Code", 'S-01-0001', true);
        TransLine.Get(TransHeader."No.", 20000);
        TransLine.Validate("Transfer-To Bin Code", 'S-01-0002');
        TransLine.Modify(true);

        if LastIteration = '1-7-3-40' then
            exit;

        TestScriptMgmt.ReleaseTransferOrder(TransHeader);

        if LastIteration = '1-7-3-50' then
            exit;

        TestScriptMgmt.PostTransferOrder(TransHeader, true);

        if LastIteration = '1-7-3-60' then
            exit;
        // 1-7-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '1-7-4-10' then
            exit;
        // 1-7-5
        TestScriptMgmt.PostTransferOrder(TransHeader, false);

        if LastIteration = '1-7-5-10' then
            exit;
        // 1-7-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '1-7-6-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase13()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-13-1-10' then
            exit;

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Purch. Account", '7130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '1-13-1-20' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Put-away" := true;
        Loc."Require Pick" := true;
        Loc.Modify();

        if LastIteration = '1-13-1-30' then
            exit;
        // 1-13-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS1-13-2', false);

        if LastIteration = '1-13-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_Test', '', 'SILVER', 2, 'BOX', 100, false);
        PurchLine.Validate("Bin Code", 'S-01-0001');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'C_Test', '31', 'SILVER', 7, 'PCS', 22, false);
        PurchLine.Validate("Bin Code", 'S-01-0001');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::"Charge (Item)", 'GPS', '', '', 1, '', 15, false);
        PurchLine.Validate("Qty. to Receive", 1);
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'SILVER', 10, 'PCS', 22, false);

        if LastIteration = '1-13-2-20' then
            exit;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN01', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN02', '');
        CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 10, 1, 10, '', 'LOT01');
        CreateRes.CreateEntry('80002', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '1-13-2-30' then
            exit;

        PurchLine.Validate("Bin Code", 'S-01-0002');
        PurchLine.Modify(true);

        if LastIteration = '1-13-2-40' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '1-13-2-50' then
            exit;

        Clear(PurchHeader);
        PurchHeader."No." := '123456789012345';
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", '20000');
        PurchHeader.Validate("Order Date", 20011125D);
        PurchHeader.Validate("Posting Date", 20011125D);
        PurchHeader.Validate("Location Code", 'SILVER');
        PurchHeader.Validate("Vendor Invoice No.", 'TCS1-13-2-B');
        PurchHeader.Modify();

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B_Test', '', 'SILVER', 5, 'PCS', 4.2, false);
        PurchLine.Validate("Bin Code", 'S-01-0003');
        PurchLine.Validate("Qty. to Receive", 5);
        PurchLine.Modify(true);

        if LastIteration = '1-13-2-60' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '1-13-2-70' then
            exit;
        // 1-13-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-13-3-10' then
            exit;
        // 1-13-4
        Clear(PurchHeader);
        PurchHeader.Find('-');
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Purchase Order", PurchHeader."No.");
        PurchHeader.Find('+');
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Purchase Order", PurchHeader."No.");

        if LastIteration = '1-13-4-10' then
            exit;
        // 1-13-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '1-13-5-10' then
            exit;
        // 1-13-6
        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);
        WhseActivLine.FindFirst();
        WhseActivLine.Get(WhseActivLine."Activity Type", WhseActivLine."No.", 30000);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type".AsInteger(), WhseActivLine."No.", 30000, '', 'S-01-0001', 6);
        WhseActivLine.SplitLine(WhseActivLine);
        WhseActivLine.Get(WhseActivLine."Activity Type", WhseActivLine."No.", 40000);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type".AsInteger(), WhseActivLine."No.", 40000, '', 'S-01-0002', 5);
        WhseActivLine.SplitLine(WhseActivLine);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type".AsInteger(), WhseActivLine."No.", 50000, '', 'S-01-0003', 5);

        if LastIteration = '1-13-6-10' then
            exit;
        // 1-13-7
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);
        if WhseActivLine.FindFirst() then
            TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '1-13-7-10' then
            exit;

        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-13-7-20' then
            exit;
        // 1-13-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '1-13-8-10' then
            exit;
        // 1-13-9
        Clear(SalesHeader);
        SalesHeader."No." := '123456789012345';
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Validate("Order Date", 20011125D);
        SalesHeader.Validate("Posting Date", 20011125D);
        SalesHeader.Validate("Location Code", 'SILVER');
        SalesHeader.Modify();

        if LastIteration = '1-13-9-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 4, 'PCS', 12, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-01-0002');
        SalesLine.Modify(true);

        if LastIteration = '1-13-9-20' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '1-13-9-30' then
            exit;

        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.");

        if LastIteration = '1-13-9-40' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);
        WhseActivLine.Get(WhseActivLine."Activity Type", WhseActivLine."No.", 10000);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type".AsInteger(), WhseActivLine."No.", 10000, '', 'S-01-0002', 2);
        WhseActivLine."Lot No." := 'LOT01';
        WhseActivLine.Modify();
        WhseActivLine.SplitLine(WhseActivLine);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type".AsInteger(), WhseActivLine."No.", 20000, '', 'S-01-0003', 2);

        if LastIteration = '1-13-9-50' then
            exit;

        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '1-13-9-60' then
            exit;

        SalesHeader.Find('-');
        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-13-9-70' then
            exit;
        // 1-13-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '1-13-10-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase14()
    var
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-14-1-10' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Put-away" := true;
        Loc.Modify();

        if LastIteration = '1-14-1-20' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-14-1', 'A_TEST', '', 'SILVER', '', 10, 'PCS', 10, 0, 'S-01-0001');

        if LastIteration = '1-14-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-14-1-40' then
            exit;
        // 1-14-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS1-14-2', false);
        PurchHeader.Validate("Vendor Cr. Memo No.", 'TCS1-14-2');

        if LastIteration = '1-14-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', 4, 'PCS', 10, false);
        PurchLine.Validate("Return Reason Code", 'NONEED');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', -3, 'PCS', 10, false);
        PurchLine.Validate("Return Reason Code", 'WRONG');
        PurchLine.Modify(true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', -1, 'PCS', 10, false);
        PurchLine.Validate("Return Reason Code", 'DAMAGED');
        PurchLine.Modify(true);

        if LastIteration = '1-14-2-20' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '1-14-2-30' then
            exit;
        // 1-14-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-14-3-10' then
            exit;
        // 1-14-4
        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 4, 'SILVER');
        TestScriptMgmt.CreateInvPutAway(WhseActivHeader);

        if LastIteration = '1-14-4-10' then
            exit;
        // 1-14-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '1-14-5-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '1-14-5-20' then
            exit;
        // 1-14-6
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '1-14-6-10' then
            exit;

        PurchHeader.Find('-');
        PurchHeader.Invoice := true;
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-14-6-20' then
            exit;
        // 1-14-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '1-14-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase16()
    var
        Loc: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-16-1-10' then
            exit;

        Loc.Get('BLUE');
        Loc."Bin Mandatory" := true;
        Loc.Modify();
        Loc.Get('SILVER');
        Loc."Require Put-away" := true;
        Loc.Modify();

        if LastIteration = '1-16-1-20' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-16-1', 'B_TEST', '', 'SILVER', '', 10, 'PCS', 12, 0, 'S-01-0001');

        if LastIteration = '1-16-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-16-1-40' then
            exit;
        // 1-16-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '1-16-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'B_Test', '', 8, 'PCS', 12, 'SILVER', '');
        SalesLine.Validate("Bin Code", 'S-01-0001');
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'B_Test', '', -2, 'PCS', 12, 'SILVER', 'WRONG');
        SalesLine.Validate("Bin Code", 'S-01-0002');
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_Test', '', -3, 'PCS', 12, 'SILVER', 'WRONG');
        SalesLine.Validate("Bin Code", 'S-01-0003');
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'B_Test', '', -1, 'PCS', 12, 'BLUE', 'WRONG');
        SalesLine.Validate("Bin Code", 'A1');
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);

        if LastIteration = '1-16-2-20' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '1-16-2-30' then
            exit;
        // 1-16-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-16-3-10' then
            exit;
        // 1-16-4
        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 4, 'SILVER');
        TestScriptMgmt.CreateInvPutAway(WhseActivHeader);

        if LastIteration = '1-16-4-10' then
            exit;
        // 1-16-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '1-16-5-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '1-16-5-20' then
            exit;
        // 1-16-6
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '1-16-6-10' then
            exit;

        SalesHeader.Find('-');
        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-16-6-20' then
            exit;
        // 1-16-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '1-16-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase17()
    var
        Loc: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-17-1-10' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Put-away" := true;
        Loc.Modify();

        if LastIteration = '1-17-1-20' then
            exit;
        // 1-17-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '1-17-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'S_Test', '42', 20, 'PCS', 0, 'SILVER', 'NONEED');
        SalesLine.Validate("Bin Code", 'S-01-0003');
        SalesLine.Validate("Return Qty. to Receive", 13);
        SalesLine.Validate("Unit Price", 12);
        SalesLine.Modify(true);

        if LastIteration = '1-17-2-20' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '1-17-2-30' then
            exit;
        // 1-17-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '1-17-3-10' then
            exit;
        // 1-17-4
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.");

        if LastIteration = '1-17-4-10' then
            exit;
        // 1-17-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '1-17-5-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '1-17-5-20' then
            exit;
        // 1-17-6
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '1-17-6-10' then
            exit;

        Commit();
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Receive := false;
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-17-6-20' then
            exit;
        // 1-17-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '1-17-7-10' then
            exit;
        // 1-17-8
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        SalesLine.Validate("Return Qty. to Receive", 5);
        SalesLine.Modify(true);

        if LastIteration = '1-17-8-10' then
            exit;
        // 1-17-9
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.");

        if LastIteration = '1-17-9-10' then
            exit;
        // 1-17-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '1-17-10-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '1-17-10-20' then
            exit;
        // 1-17-11
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '1-17-11-10' then
            exit;

        Commit();
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Receive := false;
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-17-11-20' then
            exit;
        // 1-17-12
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 12, LastILENo);

        if LastIteration = '1-17-12-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase19()
    var
        Loc: Record Location;
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        BC: Record "Bin Content";
        GetBC: Report "Whse. Get Bin Content";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-19-1-10' then
            exit;

        Loc.Get('BLUE');
        Loc."Bin Mandatory" := true;
        Loc."Require Pick" := true;
        Loc.Modify();
        Loc.Get('SILVER');
        Loc."Require Put-away" := true;
        Loc.Modify();

        if LastIteration = '1-19-1-20' then
            exit;
        // 1-19-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-19-2', 'A_TEST', '', 'BLUE', '', 52, 'PCS', 14, 0, 'A1');

        if LastIteration = '1-19-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-19-2-20' then
            exit;
        // 1-19-3
        TestScriptMgmt.InsertTransferHeader(TransHeader, 'BLUE', 'SILVER', 'OWN LOG.', 20011125D);

        if LastIteration = '1-19-3-10' then
            exit;

        BC.Reset();
        BC.SetRange("Location Code", 'BLUE');
        BC.SetRange("Item No.", 'A_TEST');
        GetBC.SetTableView(BC);
        GetBC.UseRequestPage(false);
        GetBC.InitializeTransferHeader(TransHeader);
        GetBC.RunModal();
        Clear(GetBC);

        if LastIteration = '1-19-3-20' then
            exit;

        TransLine.Get(TransHeader."No.", 10000);
        TransLine.Validate(Quantity, 12);
        TransLine.Modify(true);

        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 20000, 'A_TEST', '', 'PCS', 20, 0, 20);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 30000, 'A_TEST', '', 'PCS', 18, 0, 18);
        TransLine.SetRange("Document No.", TransHeader."No.");
        TransLine.ModifyAll("Transfer-from Bin Code", 'A1', true);
        TransLine.ModifyAll("Transfer-To Bin Code", 'S-01-0001', true);
        TransLine.Get(TransHeader."No.", 20000);
        TransLine.Validate("Transfer-To Bin Code", 'S-01-0002');
        TransLine.Modify(true);

        if LastIteration = '1-19-3-30' then
            exit;

        TestScriptMgmt.ReleaseTransferOrder(TransHeader);

        if LastIteration = '1-19-3-40' then
            exit;
        // 1-19-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '1-19-4-10' then
            exit;
        // 1-19-5
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Outbound Transfer", TransHeader."No.");

        if LastIteration = '1-19-5-10' then
            exit;
        // 1-19-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '1-19-6-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '1-19-6-20' then
            exit;
        // 1-19-7
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, true);

        if LastIteration = '1-19-7-10' then
            exit;
        // 1-19-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '1-19-8-10' then
            exit;
        // 1-19-9
        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 4, 'SILVER');
        TestScriptMgmt.CreateInvPutAway(WhseActivHeader);

        if LastIteration = '1-19-9-10' then
            exit;
        // 1-19-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '1-19-10-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '1-19-10-20' then
            exit;
        // 1-19-11
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, true);

        if LastIteration = '1-19-11-10' then
            exit;
        // 1-19-12
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 12, LastILENo);

        if LastIteration = '1-19-12-10' then
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

