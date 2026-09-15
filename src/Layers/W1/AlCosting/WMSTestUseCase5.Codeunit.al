codeunit 103315 "WMS Test Use Case 5"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 5");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103315, 5, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        SelectionForm: Page "Whse. Test Selection";
        GlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
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
            4:
                PerformTestCase4();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseJnlLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '5-1-1-10' then exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, false, 0);

        if LastIteration = '5-1-1-20' then exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0001', 64, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0002', 65, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-04-0001', 66, 'PCS');

        if LastIteration = '5-1-2-10' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS5-1-2');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-1-2-20' then exit;
        // 5-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '5-1-3-10' then exit;
        // 5-1-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011128D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011128D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 65, 'PCS', 20, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '', 65, 'PCS', 20, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A_Test', '11', 66, 'PCS', 21, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'A_Test', '11', 5, 'PALLET', 130, 'GREEN', '');

        if LastIteration = '5-1-4-10' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '5-1-4-20' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '5-1-4-30' then exit;
        // 5-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '5-1-5-10' then exit;
        // 5-1-6
        WhseShptHeader.SetRange("Location Code", 'WHITE');
        WhseShptHeader.Find('-');
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 10000, 'SHIP', 'W-09-0001', 0);
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 20000, 'SHIP', 'W-09-0002', 0);

        if LastIteration = '5-1-6-10' then exit;

        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '5-1-6-20' then exit;
        // 5-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '5-1-7-10' then exit;
        // 5-1-8
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '5-1-8-10' then exit;

        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);
        // 5-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '5-1-9-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseJnlLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '5-2-1-10' then exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, false, 1);

        if LastIteration = '5-2-1-20' then exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'BULK', 'W-05-0008', 130, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'BULK', 'W-05-0001', 60, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-04-0002', 5, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0001', 5, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-01-0002', 20, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0002', 30, 'PCS');

        if LastIteration = '5-2-2-10' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS5-2-2');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-2-2-20' then exit;
        // 5-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '5-2-3-10' then exit;
        // 5-2-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011128D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011128D, 'BLUE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 10, 'PALLET', 16, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '11', 1, 'PALLET', 220, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_Test', '', 20, 'PCS', 22, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(SalesHeader);
        Clear(SalesLine);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011129D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 30, 'PCS', 16, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '11', 11, 'PALLET', 220, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(SalesHeader);
        Clear(SalesLine);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011129D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '11', 45, 'PCS', 18, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '5-2-4-10' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, 'WHITE', 'SHIP', 'W-09-0001');

        if LastIteration = '5-2-4-20' then exit;

        TestScriptMgmt.CreateWhseShptBySourceFilter(WhseShptHeader, 'CUST30000');

        if LastIteration = '5-2-4-30' then exit;

        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '5-2-4-40' then exit;
        // 5-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '5-2-5-10' then exit;
        // 5-2-6
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '5-2-6-10' then exit;

        Clear(WhseShptLine);
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.SetRange("Location Code", WhseShptHeader."Location Code");
        WhseShptLine.Find('-');

        if LastIteration = '5-2-6-20' then exit;

        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '5-2-6-30' then exit;
        // 5-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '5-2-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseJnlLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '5-3-1-10' then exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 1);

        if LastIteration = '5-3-1-20' then exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0001', 65, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-03-0001', 65, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0001', 5, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-04-0001', 65, 'PCS');

        if LastIteration = '5-3-2-10' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS5-3-2');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-3-2-20' then exit;
        // 5-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '5-3-3-10' then exit;
        // 5-3-4
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '10000', 20011127D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011127D, 'WHITE', '', false);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '12', 'WHITE', 65, 'PCS', 16, false);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 10000, 'NONEED');

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '5-3-4-10' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, 'WHITE', 'SHIP', 'W-09-0002');

        if LastIteration = '5-3-4-20' then exit;

        TestScriptMgmt.CreateWhseShptBySourceFilter(WhseShptHeader, 'VEND10000');

        if LastIteration = '5-3-4-30' then exit;

        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '5-3-4-40' then exit;
        // 5-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '5-3-5-10' then exit;
        // 5-3-6
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '5-3-6-10' then exit;

        Clear(WhseShptLine);
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.SetRange("Location Code", WhseShptHeader."Location Code");
        WhseShptLine.Find('-');

        if LastIteration = '5-3-6-20' then exit;

        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '5-3-6-30' then exit;
        // 5-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '5-3-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemJnlLine: Record "Item Journal Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseJnlLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '5-4-1-10' then exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, false, 1);

        if LastIteration = '5-4-1-20' then exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-03-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '', 'PICK', 'W-02-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '21', 'PICK', 'W-03-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '31', 'PICK', 'W-02-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0001', 4, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '21', 'PICK', 'W-03-0001', 5, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '31', 'PICK', 'W-02-0001', 9, 'PALLET');

        if LastIteration = '5-4-2-10' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS5-4-2');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-4-2-20' then exit;
        // 5-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '5-4-3-10' then exit;
        // 5-4-4
        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'WHITE', 'BLUE', 'OWN LOG.', 20011127D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'A_Test', '11', 'PCS', 20, 0, 20);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 20000, 'B_Test', '21', 'PCS', 22, 0, 22);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 30000, 'C_Test', '31', 'PCS', 20, 0, 20);

        TestScriptMgmt.ReleaseTransferOrder(TransferHeader);

        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'WHITE', 'BLUE', 'OUT. LOG.', 20011128D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'A_Test', '', 'PCS', 20, 0, 20);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 20000, 'B_Test', '', 'PCS', 22, 0, 22);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 30000, 'C_Test', '', 'PCS', 20, 0, 20);

        TestScriptMgmt.ReleaseTransferOrder(TransferHeader);

        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'WHITE', 'BLUE', 'OWN LOG.', 20011128D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'A_Test', '11', 'PCS', 21, 0, 21);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 20000, 'B_Test', '21', 'PCS', 23, 0, 23);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 30000, 'C_Test', '31', 'PCS', 21, 0, 21);

        TestScriptMgmt.ReleaseTransferOrder(TransferHeader);

        if LastIteration = '5-4-4-10' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, 'WHITE', 'SHIP', 'W-09-0003');

        if LastIteration = '5-4-4-20' then exit;

        TestScriptMgmt.CreateWhseShptBySourceFilter(WhseShptHeader, 'SHIPBLU');

        if LastIteration = '5-4-4-30' then exit;

        WhseShptHeader.SetRange("Location Code", 'WHITE');
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '5-4-4-40' then exit;
        // 5-4-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '5-4-5-10' then exit;
        // 5-4-6
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '5-4-6-10' then exit;

        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 10000, 'SHIP', 'W-09-0003', 15);
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 20000, 'SHIP', 'W-09-0003', 15);
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 30000, 'SHIP', 'W-09-0003', 15);
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 40000, 'SHIP', 'W-09-0003', 15);
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 50000, 'SHIP', 'W-09-0003', 15);
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 60000, 'SHIP', 'W-09-0003', 15);

        if LastIteration = '5-4-6-20' then exit;

        Clear(WhseShptLine);
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.SetRange("Location Code", WhseShptHeader."Location Code");
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '5-4-6-30' then exit;
        // 5-4-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '5-4-7-10' then exit;
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

