codeunit 103330 "WMS Test Use Case 20"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 20");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103330, 20, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseActivLine: Record "Warehouse Activity Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WhsePickOrderHeader: Record "Whse. Internal Pick Header";
        WhsePickOrderLine: Record "Whse. Internal Pick Line";
        SelectionForm: Page "Whse. Test Selection";
        RefreshProdOrder: Report "Refresh Production Order";
        GlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
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
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '20-1-1-10' then exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, true, 1);

        if LastIteration = '20-1-1-20' then exit;

        Item.Get('A_TEST');
        Item."Flushing Method" := Item."Flushing Method"::Forward;
        Item.Modify();
        Item.Get('B_TEST');
        Item."Flushing Method" := Item."Flushing Method"::Forward;
        Item.Modify();
        Item.Get('D_PROD');
        Item."Flushing Method" := Item."Flushing Method"::Forward;
        Item.Modify();

        if LastIteration = '20-1-1-30' then exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-01-0001', 52, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-03-0001', 4, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'D_PROD', '', 'PICK', 'W-04-0002', 60, 'PCS');

        if LastIteration = '20-1-2-10' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '20-1-2-20' then exit;

        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS20-1-2');

        if LastIteration = '20-1-2-30' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '20-1-2-40' then exit;

        TestScriptMgmt.InsertWhsePickOrderHeader(WhsePickOrderHeader, 'WHITE', 'Production', 'w-07-0001');

        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 10000, 'B_TEST', '', 'WHITE', 'Production', 'w-07-0001', 50, 'PCS');
        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 20000, 'A_TEST', '12', 'WHITE', 'Production', 'w-07-0001', 50, 'PCS');
        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 30000, 'D_PROD', '', 'WHITE', 'Production', 'w-07-0001', 50, 'PCS');

        if LastIteration = '20-1-2-50' then exit;

        TestScriptMgmt.CreatePickFromPickOrder(WhsePickOrderHeader);

        if LastIteration = '20-1-2-60' then exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '20-1-2-70' then exit;
        // 20-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '20-1-3-10' then exit;
        // 20-1-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 30, 'WHITE');
        TestScriptMgmt.InsertProdOrderLine(ProdOrder, ProdOrderLine, 10000, 'E_PROD', 'WHITE', 30, 'PCS');

        if LastIteration = '20-1-4-10' then exit;

        ProdOrder.SetRange(Status, ProdOrder.Status);
        ProdOrder.SetRange("No.", ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        RefreshProdOrder.SetTableView(ProdOrder);
        RefreshProdOrder.UseRequestPage(false);
        RefreshProdOrder.RunModal();
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        Clear(RefreshProdOrder);

        if LastIteration = '20-1-4-20' then exit;
        // 20-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '20-1-5-10' then exit;
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

