codeunit 103312 "WMS Test Use Case 2"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 2");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103312, 2, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        SelectionForm: Page "Whse. Test Selection";
        GlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
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
            4:
                PerformTestCase4();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '2-1-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '2-1-1-20' then
            exit;
        GetLastILENo();

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', '', true);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '', 'WHITE', 11, 'Pallet', 200, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '', 'BLUE', 11, 'Pallet', 200, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'N_Test', '', 'WHITE', 5, 'PCS', 130, true);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'A_Test', '11', 'WHITE', 11, 'PALLET', 190, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A_Test', '11', 'GREEN', 11, 'PALLET', 190, false);

        if LastIteration = '2-1-2-10' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '2-1-2-20' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '2-1-2-30' then
            exit;
        // 2-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '2-1-3-10' then
            exit;
        // 2-1-4
        WhseRcptHeader.SetRange("Location Code", 'WHITE');
        WhseRcptHeader.FindFirst();
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, 'RECEIVE', 'W-08-0001', 9);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, 'RECEIVE', 'W-08-0002', 5);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, 'RECEIVE', 'W-08-0003', 8);

        if LastIteration = '2-1-4-10' then
            exit;

        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-1-4-20' then
            exit;
        // 2-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '2-1-5-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '2-2-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '2-2-1-20' then
            exit;
        GetLastILENo();

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS-2-2-2-V1', true);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '', 'WHITE', 11, 'Pallet', 160, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '11', 'WHITE', 65, 'PCS', 12, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_Test', '11', 'WHITE', 5, 'PALLET', 156, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'A_Test', '12', 'WHITE', 10, 'Pallet', 150, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS-2-2-2-V2', true);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '11', 'WHITE', 15, 'Pallet', 170, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '11', 'WHITE', 53, 'PCS', 13, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011126D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011126D, 'WHITE', 'TCS-2-2-2-V3', true);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B_Test', '21', 'WHITE', 15, 'Pallet', 180, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_Test', '22', 'WHITE', 53, 'PCS', 26, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '2-2-2-10' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0003');

        if LastIteration = '2-2-2-20' then
            exit;

        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'VEND10000');

        if LastIteration = '2-2-2-30' then
            exit;
        // 2-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '2-2-3-10' then
            exit;
        // 2-2-4
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, 'RECEIVE', 'W-08-0002', 65);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, 'RECEIVE', 'W-08-0002', 5);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 50000, 'RECEIVE', 'W-08-0004', 15);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 60000, 'RECEIVE', 'W-08-0004', 53);

        if LastIteration = '2-2-4-10' then
            exit;

        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-2-4-20' then
            exit;
        // 2-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '2-2-5-10' then
            exit;
        // 2-2-6
        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');

        if LastIteration = '2-2-6-10' then
            exit;

        PurchHeader.Get(PurchHeader."Document Type"::Order, '106002');
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '2-2-6-20' then
            exit;
        // WhseRcptHeader.AutofillQtyToHandle(WhseRcptHeader);
        if LastIteration = '2-2-6-30' then
            exit;

        Clear(WhseRcptLine);
        WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
        WhseRcptLine.SetRange("Location Code", WhseRcptHeader."Location Code");
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-2-6-40' then
            exit;
        // 2-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '2-2-7-10' then
            exit;
        // 2-2-8
        PurchHeader.Find('-');
        repeat
            PurchHeader.Receive := false;
            PurchHeader.Invoice := true;
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        until PurchHeader.Next() = 0;

        if LastIteration = '2-2-8-10' then
            exit;
        // 2-2-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '2-2-9-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        ItemJnlLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '2-3-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '2-3-1-20' then
            exit;
        GetLastILENo();

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-3-2', 'A_TEST', '', 'BLUE', '', 52, 'PCS', 14, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-3-2', 'A_TEST', '11', 'BLUE', '', 52, 'PCS', 15, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-3-2', 'A_TEST', '12', 'BLUE', '', 4, 'PALLET', 180, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-3-2', 'A_TEST', '12', 'RED', '', 52, 'PCS', 12, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-3-2', 'B_TEST', '', 'RED', '', 10, 'PCS', 9, 0);

        if LastIteration = '2-3-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '2-3-2-20' then
            exit;
        // 2-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '2-3-3-10' then
            exit;
        // 2-3-4
        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'BLUE', 'WHITE', 'OWN LOG.', 20011125D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'A_Test', '', 'PCS', 52, 0, 30);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 20000, 'A_Test', '11', 'PCS', 52, 0, 52);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 30000, 'A_Test', '12', 'PCS', 52, 0, 19);

        if LastIteration = '2-3-4-10' then
            exit;

        TestScriptMgmt.PostTransferOrder(TransferHeader);

        if LastIteration = '2-3-4-20' then
            exit;

        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'RED', 'WHITE', 'OUT. LOG.', 20011126D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'A_Test', '12', 'PCS', 52, 0, 52);

        if LastIteration = '2-3-4-30' then
            exit;

        TestScriptMgmt.PostTransferOrder(TransferHeader);

        if LastIteration = '2-3-4-40' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromTrans(TransferHeader, WhseRcptHeader);

        if LastIteration = '2-3-4-50' then
            exit;

        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'RED', 'WHITE', 'OWN LOG.', 20011126D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'B_Test', '', 'PCS', 5, 0, 5);

        if LastIteration = '2-3-4-60' then
            exit;

        TestScriptMgmt.PostTransferOrder(TransferHeader);

        if LastIteration = '2-3-4-70' then
            exit;
        // 2-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '2-3-5-10' then
            exit;
        // 2-3-6
        WhseRcptHeader.SetRange("Location Code", 'WHITE');
        WhseRcptHeader.FindFirst();
        WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
        WhseRcptLine.FindFirst();
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, 'RECEIVE', 'W-08-0003', 52);

        if LastIteration = '2-3-6-10' then
            exit;

        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-3-6-20' then
            exit;
        // 2-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '2-3-7-10' then
            exit;
        // 2-3-8
        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');

        if LastIteration = '2-3-8-10' then
            exit;

        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'RECEIVEBLU');

        if LastIteration = '2-3-8-20' then
            exit;
        // 2-3-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '2-3-9-10' then
            exit;
        // 2-3-10
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, 'RECEIVE', 'W-08-0002', 52);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, 'RECEIVE', 'W-08-0004', 19);

        if LastIteration = '2-3-10-10' then
            exit;

        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-3-10-20' then
            exit;
        // 2-3-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '2-4-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '2-4-1-20' then
            exit;
        GetLastILENo();

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011114D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'BLUE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 1, 'Pallet', 130, 'WHITE', 'DAMAGED');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '11', 5, 'PCS', 12, 'WHITE', 'WRONG');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '20000', 20011115D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'B_Test', '', 10, 'Pallet', 190, 'WHITE', 'NONEED');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'C_Test', '31', 1, 'PCS', 16, 'WHITE', 'WRONG');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011114D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011126D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 10, 'PCS', 13, 'WHITE', 'DEFECTIVE');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011116D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011126D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'C_Test', '', 5, 'PCS', 16, 'WHITE', 'DEFECTIVE');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '2-4-2-10' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');

        if LastIteration = '2-4-2-20' then
            exit;

        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'CUST30000');

        if LastIteration = '2-4-2-30' then
            exit;

        Clear(WhseRcptLine);
        WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
        WhseRcptLine.SetRange("Location Code", WhseRcptHeader."Location Code");
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-4-2-40' then
            exit;
        // 2-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '2-4-3-10' then
            exit;
        // 2-4-4
        SalesHeader.Get(SalesHeader."Document Type"::"Return Order", '1004');
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');
        WhseRcptHeader.SetRange("Location Code", 'WHITE');
        WhseRcptHeader.Find('+');

        if LastIteration = '2-4-4-10' then
            exit;

        WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
        WhseRcptLine.FindFirst();
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, 'RECEIVE', 'W-08-0002', 5);

        if LastIteration = '2-4-4-20' then
            exit;

        Clear(WhseRcptLine);
        WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
        WhseRcptLine.SetRange("Location Code", WhseRcptHeader."Location Code");
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-4-4-30' then
            exit;
        // 2-4-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '2-4-5-10' then
            exit;
        // 2-4-6
        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0004');

        if LastIteration = '2-4-6-10' then
            exit;

        SalesHeader.Get(SalesHeader."Document Type"::"Return Order", '1002');
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '2-4-6-20' then
            exit;

        WhseRcptHeader.SetRange("Location Code", 'WHITE');
        WhseRcptHeader.Find('+');
        // WhseRcptHeader.AutofillQtyToHandle(WhseRcptHeader);
        if LastIteration = '2-4-6-30' then
            exit;

        Clear(WhseRcptLine);
        WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
        WhseRcptLine.SetRange("Location Code", WhseRcptHeader."Location Code");
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '2-4-6-40' then
            exit;
        // 2-4-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '2-4-7-10' then
            exit;
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

