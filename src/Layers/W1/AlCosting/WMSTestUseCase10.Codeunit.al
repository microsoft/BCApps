codeunit 103320 "WMS Test Use Case 10"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 10");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103320, 10, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        BinContent: Record "Bin Content";
        WhseJnlLine: Record "Warehouse Journal Line";
        SelectionForm: Page "Whse. Test Selection";
        WhseCalcInventory: Report "Whse. Calculate Inventory";
        GlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
        ShowAlsoPassTests: Boolean;
        TestUseCase: array[50] of Boolean;
        ItemJnlLineNo: Integer;
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
        WhseDocNo: Code[20];

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
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '10-1-1-10' then
            exit;

        TestScriptMgmt.InsertDedicatedBin('White', 'Pick', 'W-01-0003', 'A_TEST', '12', 'PCS', 5, 100);
        TestScriptMgmt.InsertDedicatedBin('White', 'Pick', 'W-02-0002', 'B_TEST', '', 'PCS', 2, 1050);

        if LastIteration = '10-1-1-20' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '10-1-1-30' then
            exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'BULK', 'W-05-0001', 7, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0001', 9, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'QC', 'W-10-0001', 1, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'RECEIVE', 'W-08-0001', 5, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'SHIP', 'W-09-0001', 3, 'PCS');

        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'BULK', 'W-05-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0002', 4, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'QC', 'W-10-0001', 2, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'SHIP', 'W-09-0002', 11, 'PCS');

        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'BULK', 'W-05-0003', 2, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'White', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'RECEIVE', 'W-08-0002', 4, 'PALLET');

        if LastIteration = '10-1-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '10-1-2-20' then
            exit;
        // 10-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '10-1-3-10' then
            exit;
        // 10-1-4
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS10-1-4');
        if ItemJnlLine.FindLast() then
            ItemJnlLineNo := ItemJnlLine."Line No."
        else
            ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS10-1-2', 'A_TEST', '', 'BLUE', '', 5, 'PCS', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS10-1-2', 'A_TEST', '', 'GREEN', '', 10, 'PCS', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS10-1-2', 'A_TEST', '11', 'BLUE', '', 10, 'PCS', 15, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS10-1-2', 'A_TEST', '11', 'GREEN', '', 8, 'PCS', 15, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS10-1-2', 'A_TEST', '11', 'BLUE', '', 1, 'PALLET', 100, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS10-1-2', 'A_TEST', '11', 'GREEN', '', 2, 'PALLET', 100, 0);

        if LastIteration = '10-1-4-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '10-1-4-20' then
            exit;
        // 10-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '10-1-5-10' then
            exit;
        // 10-1-6
        WhseJnlLine."Journal Template Name" := 'PHYSINVT';
        WhseJnlLine."Journal Batch Name" := 'DEFAULT';
        WhseJnlLine."Location Code" := 'White';
        WhseCalcInventory.SetWhseJnlLine(WhseJnlLine);
        BinContent.Reset();
        WhseCalcInventory.SetTableView(BinContent);
        WhseCalcInventory.InitializeRequest(20011127D, WhseDocNo, false);
        WhseCalcInventory.UseRequestPage(false);
        WhseCalcInventory.RunModal();
        Clear(WhseCalcInventory);

        if LastIteration = '10-1-6-10' then
            exit;
        // 10-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '10-1-7-10' then
            exit;
        // 10-1-8
        WhseJnlLine.DeleteAll();
        WhseJnlLine."Journal Template Name" := 'PHYSINVT';
        WhseJnlLine."Journal Batch Name" := 'DEFAULT';
        WhseJnlLine."Location Code" := 'White';
        WhseCalcInventory.SetWhseJnlLine(WhseJnlLine);
        BinContent.Reset();
        WhseCalcInventory.SetTableView(BinContent);
        WhseCalcInventory.InitializeRequest(20011128D, WhseDocNo, true);
        WhseCalcInventory.UseRequestPage(false);
        WhseCalcInventory.RunModal();
        Clear(WhseCalcInventory);

        if LastIteration = '10-1-8-10' then
            exit;
        // 10-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '10-1-9-10' then
            exit;
        // 10-1-10
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 10000, 8);
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 20000, 5);
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 30000, 2);
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 40000, 1);
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 50000, 8);
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 60000, 14);
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 120000, 0);
        TestScriptMgmt.ModifyWhseJnlLine(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", 'White', 110000, 9);

        if LastIteration = '10-1-10-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '10-1-10-20' then
            exit;
        // 10-1-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '10-1-11-10' then
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

