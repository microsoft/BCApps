codeunit 103314 "WMS Test Use Case 4"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 4");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103314, 4, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        WhseJnlLine: Record "Warehouse Journal Line";
        SelectionForm: Page "Whse. Test Selection";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
        GlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        ShowAlsoPassTests: Boolean;
        TestUseCase: array[50] of Boolean;
        WhseJnlLineNo: Integer;
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '4-1-1-10' then
            exit;

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-01-0002', 'A_TEST', '12', 'PCS', 10, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-02-0002', 'A_TEST', '12', 'PCS', 10, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-03-0002', 'A_TEST', '12', 'PCS', 10, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-04-0001', 'A_TEST', '12', 'PCS', 0, 0);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-01-0001', 'A_TEST', '12', 'PALLET', 2, 95);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-02-0001', 'A_TEST', '12', 'PALLET', 2, 95);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-03-0001', 'A_TEST', '12', 'PALLET', 2, 95);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-02-0003', 'B_TEST', '', 'PCS', 5, 60);

        if LastIteration = '4-1-1-20' then
            exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, false, 0);

        if LastIteration = '4-1-1-30' then
            exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0002', 5, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-03-0002', 100, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0001', 1, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0001', 3, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-03-0001', 5, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-02-0003', 6, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0001', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0002', 99, 'PCS');

        if LastIteration = '4-1-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS4-1-2');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '4-1-2-20' then
            exit;
        // 4-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '4-1-3-10' then
            exit;
        // 4-1-4
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '20000', 20011127D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011127D, 'WHITE', '', true);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B_Test', '21', 'WHITE', 50, 'PCS', 13, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_Test', '', 'WHITE', 1, 'PALLET', 190, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'C_Test', '', 'WHITE', 200, 'PCS', 20, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '4-1-4-10' then
            exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '4-1-4-20' then
            exit;

        WhseRcptHeader.SetRange("Location Code", 'WHITE');
        WhseRcptHeader.Find('-');
        // WhseRcptHeader.AutofillQtyToHandle(WhseRcptHeader);
        if LastIteration = '4-1-4-30' then
            exit;

        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, 'RECEIVE', 'W-08-0002', 50);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, 'RECEIVE', 'W-08-0003', 1);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, 'RECEIVE', 'W-08-0001', 200);

        if LastIteration = '4-1-4-40' then
            exit;

        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '4-1-4-50' then
            exit;
        // 4-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '4-1-5-10' then
            exit;
        // 4-1-6
        WhseActivLine.SetRange(WhseActivLine."Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.FindFirst();
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 20000, 'PICK', 'W-04-0002', 50);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'Bulk', 'W-05-0003', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 60000, 'BULK', 'W-05-0005', 60);

        if LastIteration = '4-1-6-10' then
            exit;

        WhseActivLine.Get(WhseActivLine."Activity Type", WhseActivLine."No.", 60000);
        WhseActivLine.SplitLine(WhseActivLine);

        if LastIteration = '4-1-6-20' then
            exit;

        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 70000, 'BULK', 'W-05-0006', 140);

        if LastIteration = '4-1-6-30' then
            exit;

        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '4-1-6-40' then
            exit;
        // 4-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '4-1-7-10' then
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

