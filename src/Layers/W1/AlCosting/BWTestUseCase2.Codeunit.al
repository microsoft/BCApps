codeunit 103352 "BW Test Use Case 2"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 2");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103352, 2, 0, '', 1);

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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        ItemJnlLineRes: Codeunit "Item Jnl. Line-Reserve";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '2-1-1-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS2-1-2', 'A_TEST', '', 'SILVER', '', 250, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-1-2', 'A_TEST', '', 'SILVER', '', 100, 'PCS', 10, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS2-1-2', 'A_TEST', '11', 'SILVER', '', 37, 'PCS', 15, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-1-2', 'A_TEST', '11', 'SILVER', '', 15, 'PALLET', 100, 0, 'S-01-0003');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS2-1-2', 'A_TEST', '12', 'SILVER', '', 30, 'PALLET', 100, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-1-2', 'A_TEST', '12', 'SILVER', '', 20, 'PCS', 16, 0, 'S-01-0003');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-1-2', 'B_TEST', '', 'SILVER', '', 5, 'PCS', 50, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS2-1-2', 'B_TEST', '', 'SILVER', '', 5, 'PALLET', 150, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-1-2', 'T_TEST', '', 'SILVER', '', 2, 'BOX', 100, 0, 'S-02-0001');

        if LastIteration = '2-1-2-10' then
            exit;
        // 2-1-3
        ItemJnlLineNo := 0;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);

        if LastIteration = '2-1-3-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '2-1-3-20' then
            exit;
        // 2-1-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '2-1-4-10' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertReclassJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011126D,
          ItemJnlLine."Entry Type"::Transfer, 'T01001', 'A_TEST', '11', 'SILVER', 'SILVER', 17, 'PCS', 0, 0,
          'S-01-0002', 'S-01-0001');
        TestScriptMgmt.InsertReclassJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011126D,
          ItemJnlLine."Entry Type"::Transfer, 'T01001', 'A_TEST', '11', 'SILVER', 'SILVER', 15, 'PALLET', 0, 0,
          'S-01-0003', 'S-01-0001');
        TestScriptMgmt.InsertReclassJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011126D,
          ItemJnlLine."Entry Type"::Transfer, 'T01001', 'A_TEST', '', 'SILVER', 'SILVER', 150, 'PCS', 0, 0,
          'S-01-0001', 'S-01-0002');
        TestScriptMgmt.InsertReclassJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011126D,
          ItemJnlLine."Entry Type"::Transfer, 'T01001', 'A_TEST', '', 'SILVER', 'SILVER', 100, 'PCS', 0, 0,
          'S-01-0002', 'S-02-0001');
        TestScriptMgmt.InsertReclassJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011126D,
          ItemJnlLine."Entry Type"::Transfer, 'T01001', 'T_TEST', '', 'SILVER', 'SILVER', 1, 'BOX', 0, 0,
          'S-02-0001', 'S-01-0003');
        Clear(ItemJnlLineRes);
        TempTrackingSpecification.Reset();
        TempTrackingSpecification.DeleteAll();
        TempTrackingSpecification.Init();
        TempTrackingSpecification.Validate("Item No.", ItemJnlLine."Item No.");
        TempTrackingSpecification.Validate("Location Code", ItemJnlLine."Location Code");
        TempTrackingSpecification.Validate("Serial No.", 'SN01');
        TempTrackingSpecification.Validate("New Serial No.", 'SN01');
        TempTrackingSpecification.Validate("Quantity (Base)", 1);
        TempTrackingSpecification.Validate("Qty. per Unit of Measure", 1);
        TempTrackingSpecification.Insert();
        ItemJnlLineRes.RegisterBinContentItemTracking(ItemJnlLine, TempTrackingSpecification);
        TestScriptMgmt.InsertReclassJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011126D,
          ItemJnlLine."Entry Type"::Transfer, 'T01001', 'T_TEST', '', 'SILVER', 'WHITE', 1, 'BOX', 0, 0,
          'S-02-0001', '');

        if LastIteration = '2-1-5-10' then
            exit;
        // 2-1-6
        ItemJnlLineNo := 4;

        Clear(ItemJnlLineRes);
        TempTrackingSpecification.Reset();
        TempTrackingSpecification.DeleteAll();

        TempTrackingSpecification.Init();
        TempTrackingSpecification.Validate("Item No.", ItemJnlLine."Item No.");
        TempTrackingSpecification.Validate("Location Code", ItemJnlLine."Location Code");
        TempTrackingSpecification.Validate("Serial No.", 'SN02');
        TempTrackingSpecification.Validate("New Serial No.", 'SN02');
        TempTrackingSpecification.Validate("Quantity (Base)", 1);

        TempTrackingSpecification.Validate("Qty. per Unit of Measure", 1);
        TempTrackingSpecification.Insert();
        ItemJnlLineRes.RegisterBinContentItemTracking(ItemJnlLine, TempTrackingSpecification);

        if LastIteration = '2-1-6-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '2-1-6-20' then
            exit;
        // 2-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '2-1-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        BC: Record "Bin Content";
        GetBC: Report "Whse. Get Bin Content";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '2-2-1-10' then
            exit;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-2-1', 'A_TEST', '11', 'SILVER', '', 25, 'PCS', 15, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-2-1', 'B_TEST', '', 'SILVER', '', 5, 'PCS', 50, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS2-2-1', 'B_TEST', '22', 'SILVER', '', 5, 'PALLET', 150, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-2-1', 'B_TEST', '', 'GREEN', '', 10, 'PCS', 15, 0, '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS2-2-1', '80002', '', 'SILVER', '', 10, 'PCS', 15, 0, 'S-01-0003');

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, '80002', '', '', 'LOT01', 5, 5, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, '80002', '', '', 'LOT02', 5, 5, 83, 0,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);

        if LastIteration = '2-2-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '2-2-1-30' then
            exit;
        // 2-2-2
        BC.Reset();
        BC.SetRange("Location Code", 'SILVER');
        BC.SetRange("Item No.", 'B_TEST');
        ItemJnlLine."Journal Template Name" := 'RECLASS';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        ItemJnlLine."Posting Date" := 20011125D;
        ItemJnlLine."Document No." := 'T01001';
        GetBC.SetTableView(BC);
        GetBC.UseRequestPage(false);
        GetBC.InitializeItemJournalLine(ItemJnlLine);
        GetBC.RunModal();
        Clear(GetBC);

        if LastIteration = '2-2-2-10' then
            exit;
        // 2-2-3
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        ItemJnlLine.SetRange("Item No.", 'B_TEST');
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine."Document No." := 'T01001';
                if ItemJnlLine."Variant Code" = '' then
                    ItemJnlLine.Validate("New Bin Code", 'S-01-0002')
                else
                    ItemJnlLine.Validate("New Bin Code", 'S-01-0001');
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;

        if LastIteration = '2-2-3-10' then
            exit;
        // 2-2-4
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '2-2-4-10' then
            exit;
        // 2-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '2-2-5-10' then
            exit;
        // 2-2-6
        TestScriptMgmt.InsertReclassJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D, ItemJnlLine."Entry Type"::Transfer,
          'T01001', '80002', '', 'SILVER', 'SILVER', 10, 'PCS', 0, 0, 'S-01-0003', 'S-02-0001');

        if LastIteration = '2-2-6-10' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, '80002', '', '', 'LOT01', 5, 5, 83, 4,
          'RECLASS', 'DEFAULT', ItemJnlLine."Line No.", true);
        Clear(ResEntry);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, '80002', '', '', 'LOT02', 5, 5, 83, 4,
          'RECLASS', 'DEFAULT', ItemJnlLine."Line No.", true);
        ResEntry.FindFirst();
        ResEntry."New Lot No." := 'LOT01';
        ResEntry.Modify();
        ResEntry.Next();
        ResEntry."New Lot No." := 'LOT02';
        ResEntry.Modify();

        if LastIteration = '2-2-6-20' then
            exit;
        // 2-2-7
        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '2-2-7-10' then
            exit;
        // 2-2-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '2-2-8-10' then
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

