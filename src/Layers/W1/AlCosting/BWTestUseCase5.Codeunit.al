codeunit 103355 "BW Test Use Case 5"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 5");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103355, 5, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
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
    var
        Loc: Record Location;
        CalcInv: Report "Calculate Inventory";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '5-1-10' then
            exit;

        Loc.Get('BLUE');
        Loc."Bin Mandatory" := true;
        Loc.Modify();

        if LastIteration = '5-1-20' then
            exit;

        if LastIteration = '5-1-30' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'A_TEST', '', 'SILVER', '', 62, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS5-1-2', 'A_TEST', '', 'SILVER', '', 12, 'PCS', 10, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'B_TEST', '', 'SILVER', '', 72, 'PCS', 15, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'B_TEST', '', 'BLUE', '', 17, 'PCS', 15, 0, 'A1');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'C_TEST', '', 'SILVER', '', 1, 'PALLET', 100, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS5-1-2', 'C_TEST', '31', 'SILVER', '', 5, 'PCS', 12, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'C_TEST', '31', 'SILVER', '', 10, 'PCS', 12, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS5-1-2', 'C_TEST', '31', 'SILVER', '', 13, 'PCS', 12, 0, 'S-01-0003');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'D_PROD', '', 'SILVER', '', 4, 'PCS', 50, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'D_PROD', '', 'SILVER', '', 10, 'PCS', 50, 0, 'S-07-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'T_TEST', '', 'SILVER', '', 2, 'BOX', 100, 0, 'S-01-0001');
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 1, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 2, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-1-2', 'T_TEST', '', 'GREEN', '', 2, 'BOX', 100, 0, '');

        if LastIteration = '5-1-2-10' then
            exit;
        // 5-1-3
        ItemJnlLineNo := 2;

        TestScriptMgmt.InsertResEntry(ResEntry, 'GREEN', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN03', '', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'GREEN', TestScriptMgmt.GetNextNo(ItemJnlLineNo), "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN04', '', 1, 1, 83, 2,
          'ITEM', 'DEFAULT', ItemJnlLine."Line No.", true);

        if LastIteration = '5-1-3-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-1-3-20' then
            exit;
        // 5-1-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '5-1-4-10' then
            exit;
        // 5-1-5
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        Item.SetFilter("Location Filter", 'SILVER');
        CalcInv.SetItemJnlLine(ItemJnlLine);
        CalcInv.InitializeRequest(20011125D, 'T02001', false, false);
        CalcInv.SetHideValidationDialog(true);
        CalcInv.UseRequestPage(false);
        CalcInv.SetTableView(Item);
        CalcInv.RunModal();
        Clear(CalcInv);

        if LastIteration = '5-1-5-10' then
            exit;
        // 5-1-6
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'PHYS. INV.');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.SetRange("Item No.", 'A_TEST');
        if ItemJnlLine.Find('-') then
            repeat
                if ItemJnlLine."Qty. (Phys. Inventory)" = 62 then begin
                    ItemJnlLine.Validate("Qty. (Phys. Inventory)", 60);
                    ItemJnlLine.Modify();
                end;
            until ItemJnlLine.Next() = 0;

        ItemJnlLine.SetRange("Item No.", 'C_TEST');
        ItemJnlLine.SetRange("Variant Code", '31');
        if ItemJnlLine.Find('-') then
            repeat
                if ItemJnlLine."Qty. (Phys. Inventory)" = 5 then begin
                    ItemJnlLine.Validate("Qty. (Phys. Inventory)", 7);
                    ItemJnlLine.Modify();
                end;
            until ItemJnlLine.Next() = 0;

        if LastIteration = '5-1-6-10' then
            exit;

        ItemJnlLine.SetRange("Item No.");
        ItemJnlLine.SetRange("Variant Code");
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-1-6-20' then
            exit;
        // 5-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '5-1-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        CalcInv: Report "Calculate Inventory";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '5-2-1-10' then
            exit;

        if LastIteration = '5-2-1-20' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-2-2', 'A_TEST', '', 'SILVER', '', 22, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS5-2-2', 'B_TEST', '22', 'SILVER', '', 33, 'PCS', 15, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-2-2', 'D_PROD', '', 'SILVER', '', 44, 'PCS', 50, 0, 'S-07-0002');

        if LastIteration = '5-2-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-2-2-20' then
            exit;
        GetLastILENo();

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS5-2-2', 'A_TEST', '', 'SILVER', '', 22, 'PCS', 10, 0, 'S-01-0001');

        if LastIteration = '5-2-2-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-2-2-40' then
            exit;
        // 5-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '5-2-3-10' then
            exit;
        // 5-2-4
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        Item.SetFilter("Location Filter", 'SILVER');
        CalcInv.SetItemJnlLine(ItemJnlLine);
        CalcInv.InitializeRequest(20011125D, 'TCS5-1-2', true, false);
        CalcInv.SetHideValidationDialog(true);
        CalcInv.UseRequestPage(false);
        CalcInv.SetTableView(Item);
        CalcInv.RunModal();
        Clear(CalcInv);

        if LastIteration = '5-2-4-10' then
            exit;
        // 5-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '5-2-5-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        Item: Record Item;
        Sku: Record "Stockkeeping Unit";
        CalcInv: Report "Calculate Inventory";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '5-3-1-10' then
            exit;

        if Item.Get('A_TEST') then begin
            Item.Validate("Phys Invt Counting Period Code", 'FAST');
            Item.Modify();
        end;
        if Item.Get('B_TEST') then begin
            Item.Validate("Phys Invt Counting Period Code", 'NORMAL');
            Item.Modify();
        end;
        if Item.Get('C_TEST') then begin
            Item.Validate("Phys Invt Counting Period Code", 'SLOW');
            Item.Modify();
        end;

        if LastIteration = '5-3-1-20' then
            exit;

        if Sku.Get('SILVER', 'A_TEST', '') then begin
            Sku.Validate("Phys Invt Counting Period Code", 'FAST');
            Sku.Modify();
        end;
        if Sku.Get('SILVER', 'C_TEST', '31') then begin
            Sku.Validate("Phys Invt Counting Period Code", 'SLOW');
            Sku.Modify();
        end;

        if LastIteration = '5-3-1-30' then
            exit;
        // 5-3-2
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-3-2', 'A_TEST', '', 'SILVER', '', 62, 'PCS', 10, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS5-3-2', 'A_TEST', '', 'SILVER', '', 12, 'PCS', 10, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-3-2', 'B_TEST', '', 'SILVER', '', 72, 'PCS', 15, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS5-3-2', 'C_TEST', '', 'SILVER', '', 1, 'PALLET', 100, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS5-3-2', 'C_TEST', '31', 'SILVER', '', 5, 'PCS', 12, 0, 'S-02-0001');

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '5-3-2-10' then
            exit;
        // 5-3-3
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        Item.SetFilter("Location Filter", 'SILVER');
        Item.SetFilter("No.", 'A_TEST');
        CalcInv.SetItemJnlLine(ItemJnlLine);
        CalcInv.InitializeRequest(20011125D, 'TCS5-3-3', false, false);
        CalcInv.SetHideValidationDialog(true);
        CalcInv.UseRequestPage(false);
        CalcInv.InitializePhysInvtCount('FAST', 0);
        CalcInv.SetTableView(Item);
        CalcInv.RunModal();
        Clear(CalcInv);
        Item.SetFilter("No.", 'C_TEST');
        CalcInv.SetItemJnlLine(ItemJnlLine);
        CalcInv.InitializeRequest(20011125D, 'TCS5-3-3', false, false);
        CalcInv.SetHideValidationDialog(true);
        CalcInv.UseRequestPage(false);
        CalcInv.InitializePhysInvtCount('SLOW', 0);
        CalcInv.SetTableView(Item);
        CalcInv.RunModal();
        Clear(CalcInv);

        if LastIteration = '5-3-3-10' then
            exit;
        // 5-3-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '5-3-4-10' then
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

