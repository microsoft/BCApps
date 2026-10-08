codeunit 103318 "WMS Test Use Case 8"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 8");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103318, 8, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        SelectionForm: Page "Whse. Test Selection";
        GlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
        ShowAlsoPassTests: Boolean;
        TestUseCase: array[50] of Boolean;
        WhseJnlLineNo: Integer;
        ItemJnlLineNo: Integer;
        WhseWkshLineNo: Integer;
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '8-1-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '8-1-1-20' then
            exit;
        GetLastILENo();
        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0001', 10, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'BULK', 'W-05-0001', 240, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0002', 11, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'BULK', 'W-05-0002', 26, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0003', 15, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0002', 15, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0003', 11, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0001', 9, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0003', 300, 'PCS');

        if LastIteration = '8-1-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS8-1-2');
        if ItemJnlLine.FindLast() then
            ItemJnlLineNo := ItemJnlLine."Line No."
        else
            ItemJnlLineNo := 10000;
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'A_TEST', '', 'GREEN', '', 100, 'PCS', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-1-2', 'A_TEST', '11', 'BLUE', '', 15, 'PALLET', 100, 0);

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-1-2-20' then
            exit;
        // 8-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-1-3-10' then
            exit;
        // 8-1-4
        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertReclassWhseJnlLine(WhseJnlLine, 'RECLASS', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'BULK', 'W-05-0001', 'PICK', 'W-01-0001', 40, 'PCS');
        TestScriptMgmt.InsertReclassWhseJnlLine(WhseJnlLine, 'RECLASS', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'BULK', 'W-05-0001', 'SHIP', 'W-09-0001', 100, 'PCS');
        TestScriptMgmt.InsertReclassWhseJnlLine(WhseJnlLine, 'RECLASS', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'BULK', 'W-05-0002', 'PICK', 'W-01-0002', 26, 'PCS');
        TestScriptMgmt.InsertReclassWhseJnlLine(WhseJnlLine, 'RECLASS', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0003', 'BULK', 'W-05-0002', 15, 'PALLET');
        TestScriptMgmt.InsertReclassWhseJnlLine(WhseJnlLine, 'RECLASS', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0003', 'PICK', 'W-01-0002', 11, 'PCS');
        TestScriptMgmt.InsertReclassWhseJnlLine(WhseJnlLine, 'RECLASS', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0001', 'PICK', 'W-01-0002', 9, 'PCS');
        TestScriptMgmt.InsertReclassWhseJnlLine(WhseJnlLine, 'RECLASS', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0003', 'PICK', 'W-02-0001', 100, 'PCS');

        if LastIteration = '8-1-4-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '8-1-4-20' then
            exit;
        // 8-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '8-1-5-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        WhseActivityPost: Codeunit "Whse.-Activity-Register";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '8-2-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '8-2-1-20' then
            exit;
        GetLastILENo();
        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'BULK', 'W-05-0002', 250, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'BULK', 'W-05-0002', 37, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0002', 20, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0003', 300, 'PCS');

        if LastIteration = '8-2-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS8-2-2');

        if ItemJnlLine.FindLast() then
            ItemJnlLineNo := ItemJnlLine."Line No."
        else
            ItemJnlLineNo := 10000;
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'A_TEST', '', 'GREEN', '', 250, 'PCS', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-2-2', 'A_TEST', '11', 'BLUE', '', 37, 'PCS', 15, 0);

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-2-2-20' then
            exit;
        // 8-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-2-3-10' then
            exit;
        // 8-2-4
        WhseWkshLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011126D,
          'A_TEST', '', 'W-05-0002', 'W-01-0001', 200, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011126D,
          'A_TEST', '', 'W-05-0002', 'W-09-0002', 50, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011126D,
          'A_TEST', '11', 'W-05-0002', 'W-01-0002', 37, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011126D,
          'A_TEST', '12', 'W-05-0002', 'W-01-0003', 10, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011126D,
          'A_TEST', '12', 'W-05-0002', 'W-02-0001', 10, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011126D,
          'B_TEST', '', 'W-05-0003', 'W-02-0002', 100, 'PCS');

        if LastIteration = '8-2-4-10' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '8-2-4-20' then
            exit;
        // 8-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '8-2-5-10' then
            exit;
        // 8-2-6
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        if WhseActivLine.FindFirst() then
            WhseActivityPost.Run(WhseActivLine);

        if LastIteration = '8-2-6-10' then
            exit;
        // 8-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '8-2-7-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        BinContent: Record "Bin Content";
        ReplenishmtBatch: Report "Calculate Bin Replenishment";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '8-3-1-10' then
            exit;

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-01-0001', 'A_TEST', '', 'PCS', 20, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-02-0001', 'A_TEST', '12', 'PCS', 10, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-03-0001', 'A_TEST', '12', 'PCS', 11, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-02-0002', 'B_TEST', '', 'PCS', 50, 1050);

        if LastIteration = '8-3-1-20' then
            exit;

        GlobalPrecondition.SetupLocation('STD', false, false, false, false, 0);

        if LastIteration = '8-3-1-30' then
            exit;
        GetLastILENo();
        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'PICK', 'W-01-0001', 10, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '', 'BULK', 'W-05-0001', 240, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0002', 11, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-01-0001', 26, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0003', 15, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0007', 15, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0003', 11, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0001', 9, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0003', 270, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-02-0002', 30, 'PCS');

        if LastIteration = '8-3-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);
        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS8-1-2');

        if ItemJnlLine.FindLast() then
            ItemJnlLineNo := ItemJnlLine."Line No."
        else
            ItemJnlLineNo := 10000;
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'A_TEST', '', 'GREEN', '', 100, 'PCS', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS8-3-2', 'A_TEST', '11', 'BLUE', '', 15, 'PALLET', 100, 0);

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '8-3-2-20' then
            exit;
        // 8-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '8-3-3-10' then
            exit;
        // 8-3-4
        Clear(ReplenishmtBatch);
        BinContent.SetRange("Location Code", 'WHITE');
        BinContent.SetRange("Zone Code", 'PICK');
        BinContent.SetRange("Bin Code", 'W-02-0002');
        BinContent.SetRange("Item No.", 'B_TEST');
        BinContent.SetRange("Variant Code", '');
        BinContent.SetRange("Unit of Measure Code", 'PCS');
        ReplenishmtBatch.UseRequestPage(false);
        ReplenishmtBatch.InitializeRequest('MOVEMENT', 'DEFAULT', 'WHITE', true, true, false);
        ReplenishmtBatch.SetTableView(BinContent);
        ReplenishmtBatch.RunModal();

        if LastIteration = '8-3-4-10' then
            exit;
        // 8-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '8-3-5-10' then
            exit;
        // 8-3-6
        WhseWkshLine.Find('-');
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '8-3-6-10' then
            exit;

        Clear(ReplenishmtBatch);
        BinContent.Reset();
        BinContent.SetRange("Location Code", 'WHITE');
        BinContent.SetRange("Zone Code", 'PICK');
        ReplenishmtBatch.UseRequestPage(false);
        ReplenishmtBatch.InitializeRequest('MOVEMENT', 'DEFAULT', 'WHITE', true, true, false);
        ReplenishmtBatch.SetTableView(BinContent);
        ReplenishmtBatch.RunModal();

        if LastIteration = '8-3-6-20' then
            exit;
        // 8-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '8-3-7-10' then
            exit;
        // 8-3-8
        WhseWkshLine.Find('-');
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::Item, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '8-3-8-10' then
            exit;
        // 8-3-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '8-3-9-10' then
            exit;
        // 8-3-10
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '8-3-10-10' then
            exit;
        // 8-3-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '8-3-11-10' then
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

