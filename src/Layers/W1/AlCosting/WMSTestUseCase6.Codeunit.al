codeunit 103316 "WMS Test Use Case 6"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 6");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103316, 6, 0, '', 1);

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
            3:
                PerformTestCase3();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemJnlLine: Record "Item Journal Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseJnlLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '6-1-1-10' then exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, true, 1);

        if LastIteration = '6-1-1-20' then exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0001', 1, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-04-0002', 50, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-04-0001', 4, 'PALLET');

        if LastIteration = '6-1-2-10' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS6-1-2');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '6-1-2-20' then exit;
        // 6-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '6-1-3-10' then exit;
        // 6-1-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011128D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011128D, 'BLUE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 13, 'PCS', 16, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '11', 20, 'PCS', 22, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '6-1-4-10' then exit;

        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'WHITE', 'BLUE', 'OWN LOG.', 20011128D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'A_Test', '', 'PCS', 30, 0, 30);

        TestScriptMgmt.ReleaseTransferOrder(TransferHeader);

        if LastIteration = '6-1-4-20' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromTrans(TransferHeader, WhseShptHeader);

        if LastIteration = '6-1-4-30' then exit;

        WhseShptHeader.SetRange("Location Code", 'WHITE');
        WhseShptHeader.Find('-');
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 10000, 'SHIP', 'W-09-0001', 0);

        if LastIteration = '6-1-4-40' then exit;

        TestScriptMgmt.CreateWhseShptBySourceFilter(WhseShptHeader, 'CUST30000');

        if LastIteration = '6-1-4-50' then exit;

        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 20000, 'SHIP', 'W-09-0002', 0);

        if LastIteration = '6-1-4-60' then exit;

        TestScriptMgmt.ReleaseWhseShipment(WhseShptHeader);

        if LastIteration = '6-1-4-70' then exit;

        TestScriptMgmt.CreatePickWorksheet(PickWkshLine, 'PICK', 'DEFAULT', 'WHITE', 0, 'SH000001');

        if LastIteration = '6-1-4-80' then exit;
        // 6-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '6-1-5-10' then exit;
        // 6-1-6
        PickWkshLine.AutofillQtyToHandle(PickWkshLine);

        if LastIteration = '6-1-6-10' then exit;

        TestScriptMgmt.CreatePickFromWksh(
          PickWkshLine, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        if LastIteration = '6-1-6-20' then exit;
        // 6-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '6-1-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemJnlLine: Record "Item Journal Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseJnlLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '6-3-1-10' then exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, true, 1);

        if LastIteration = '6-3-1-20' then exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0001', 52, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'Pick', 'W-03-0003', 52, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0003', 52, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-04-0001', 4, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'Pick', 'W-04-0002', 100, 'PCS');

        if LastIteration = '6-3-2-10' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS6-3-2');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '6-3-2-20' then exit;
        // 6-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '6-3-3-10' then exit;
        // 6-3-4
        TestScriptMgmt.InsertTransferHeader(TransferHeader, 'WHITE', 'BLUE', 'OWN LOG.', 20011128D);

        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 10000, 'A_Test', '', 'PCS', 52, 0, 52);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 20000, 'A_Test', '11', 'PCS', 52, 0, 52);
        TestScriptMgmt.InsertTransferLine(TransferLine, TransferHeader."No.", 30000, 'A_Test', '12', 'PCS', 104, 0, 104);

        TestScriptMgmt.ReleaseTransferOrder(TransferHeader);

        if LastIteration = '6-3-4-10' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, 'WHITE', 'SHIP', 'W-09-0001');

        if LastIteration = '6-3-4-20' then exit;

        TestScriptMgmt.CreateWhseShptFromTrans(TransferHeader, WhseShptHeader);

        if LastIteration = '6-3-4-30' then exit;

        WhseShptHeader.Find('-');
        TestScriptMgmt.ReleaseWhseShipment(WhseShptHeader);

        if LastIteration = '6-3-4-40' then exit;

        TestScriptMgmt.CreatePickWorksheet(PickWkshLine, 'PICK', 'DEFAULT', 'WHITE', 0, 'SH000001');

        if LastIteration = '6-3-4-50' then exit;
        // 6-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '6-3-5-10' then exit;
        // 6-3-6
        PickWkshLine.AutofillQtyToHandle(PickWkshLine);

        if LastIteration = '6-3-6-10' then exit;

        TestScriptMgmt.CreatePickFromWksh(
          PickWkshLine, '', 1, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        if LastIteration = '6-3-6-20' then exit;
        // 6-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '6-3-7-10' then exit;
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

