codeunit 103356 "BW Test Use Case 6"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 6");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103356, 6, 0, '', 1);

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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '6-1-1-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS6-1-2', 'A_TEST', '', 'SILVER', '', 62, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS6-1-2', 'B_TEST', '', 'SILVER', '', 72, 'PCS', 15, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS6-1-2', 'C_TEST', '', 'SILVER', '', 1, 'PALLET', 100, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS6-1-2', 'C_TEST', '31', 'SILVER', '', 5, 'PCS', 12, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS6-1-2', 'T_TEST', '', 'SILVER', '', 2, 'BOX', 100, 0, 'S-01-0001');

        if LastIteration = '6-1-2-10' then
            exit;
        // 6-1-3
        ItemJnlLineNo := 0;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);

        if LastIteration = '6-1-3-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '6-1-3-20' then
            exit;
        // 6-1-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '6-1-4-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '6-2-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS6-2-1', 'A_TEST', '', 'SILVER', '', 62, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS6-2-1', 'B_TEST', '', 'SILVER', '', 72, 'PCS', 15, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS6-2-1', 'C_TEST', '', 'SILVER', '', 1, 'PALLET', 100, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS6-2-1', 'C_TEST', '31', 'SILVER', '', 5, 'PCS', 12, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS6-2-1', 'T_TEST', '', 'SILVER', '', 2, 'BOX', 100, 0, 'S-01-0001');

        if LastIteration = '6-2-1-20' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);

        if LastIteration = '6-2-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '6-2-1-40' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS6-2-2', 'A_TEST', '', 'SILVER', '', 40, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Sale, 'TCS6-2-2', 'B_TEST', '', 'SILVER', '', 60, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS6-2-2', 'C_TEST', '', 'SILVER', '', 1, 'PALLET', 100, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Sale, 'TCS6-2-2', 'C_TEST', '31', 'SILVER', '', 5, 'PCS', 12, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS6-2-2', 'T_TEST', '', 'SILVER', '', 2, 'BOX', 100, 0, 'S-01-0001');

        if LastIteration = '6-2-2-10' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', -1, -1, 83, 3,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", false);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', -1, -1, 83, 3,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", false);

        if LastIteration = '6-2-2-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '6-2-2-30' then
            exit;
        // 6-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '6-2-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResMgmt: Codeunit "Reservation Management";
        AutoRes: Boolean;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '6-3-1-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS6-3-2', 'A_TEST', '', 'SILVER', '', 10, 'PCS', 10, 0, 'S-01-0001');

        if LastIteration = '6-3-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '6-3-2-20' then
            exit;
        // 6-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '6-3-3-10' then
            exit;
        // 6-3-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 9, 'PCS', 0, 'SILVER', 'DAMAGED');

        if LastIteration = '6-3-4-10' then
            exit;
        // 6-3-5
        ItemJnlLineNo := 0;
        ResMgmt.SetReservSource(SalesLine);
        ResMgmt.AutoReserve(AutoRes, '', 20011125D, SalesLine.Quantity, SalesLine."Quantity (Base)");

        if LastIteration = '6-3-5-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS6-3-6', 'A_TEST', '', 'SILVER', '', 6, 'PCS', 10, 0, 'S-01-0001');

        if LastIteration = '6-3-6-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '6-3-6-20' then
            exit;
        // 6-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '6-3-7-10' then
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

