codeunit 103327 "WMS Test Use Case 17"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 17");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103327, 17, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseActivLine: Record "Warehouse Activity Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhsePickOrderHeader: Record "Whse. Internal Pick Header";
        WhsePickOrderLine: Record "Whse. Internal Pick Line";
        SelectionForm: Page "Whse. Test Selection";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
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

        if LastIteration = '17-1-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, true, 1);

        if LastIteration = '17-1-1-20' then
            exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'PICK', 'W-01-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'PICK', 'W-01-0001', 3, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'BULK', 'W-05-0007', 50, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'BULK', 'W-05-0001', 10, 'PALLET');

        if LastIteration = '17-1-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '17-1-2-20' then
            exit;

        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS17-1-2');

        if LastIteration = '17-1-2-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '17-1-2-40' then
            exit;

        TestScriptMgmt.BlockBin('WHITE', 'PICK', 'W-01-0002', 'C_TEST', '32', 'PCS', 2);

        if LastIteration = '17-1-2-50' then
            exit;
        // 17-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '17-1-3-10' then
            exit;
        // 17-1-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'D_PROD', 15, 'WHITE');
        TestScriptMgmt.InsertProdOrderLine(ProdOrder, ProdOrderLine, 10000, 'D_PROD', 'WHITE', 15, 'PCS');

        if LastIteration = '17-1-4-10' then
            exit;

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

        if LastIteration = '17-1-4-20' then
            exit;

        TestScriptMgmt.CreatePickWorksheet(PickWkshLine, 'PICK', 'DEFAULT', 'WHITE', 2, '101001');

        if LastIteration = '17-1-4-30' then
            exit;
        // 17-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '17-1-5-10' then
            exit;
        // 17-1-6
        PickWkshLine.AutofillQtyToHandle(PickWkshLine);

        if LastIteration = '17-1-6-10' then
            exit;

        TestScriptMgmt.CreatePickFromWksh(
          PickWkshLine, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        if LastIteration = '17-1-6-20' then
            exit;
        // 17-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '17-1-7-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '17-2-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, true, 1);

        if LastIteration = '17-2-1-20' then
            exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'D_PROD', '', 'PICK', 'W-01-0002', 22, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0001', 3, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-01-0003', 5, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-02-0001', 45, 'PCS');

        if LastIteration = '17-2-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '17-2-2-20' then
            exit;

        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS17-2-2');

        if LastIteration = '17-2-2-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '17-2-2-40' then
            exit;
        // 17-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '17-2-3-10' then
            exit;
        // 17-2-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 22, 'WHITE');
        TestScriptMgmt.InsertProdOrderLine(ProdOrder, ProdOrderLine, 10000, 'E_PROD', 'WHITE', 22, 'PCS');

        if LastIteration = '17-2-4-10' then
            exit;

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

        if LastIteration = '17-2-4-20' then
            exit;

        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '17-2-4-30' then
            exit;
        // 17-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '17-2-5-10' then
            exit;
        // 17-2-6
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 30000, '', '', 0);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'Production', 'W-07-0002', 0);

        if LastIteration = '17-2-6-10' then
            exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '17-2-6-20' then
            exit;
        // 17-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '17-2-7-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '17-3-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, false, 1);

        if LastIteration = '17-3-1-20' then
            exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0002', 15, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-01-0003', 37, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'PICK', 'W-04-0001', 4, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'PICK', 'W-04-0002', 1, 'PALLET');

        if LastIteration = '17-3-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '17-3-2-20' then
            exit;

        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS17-3-2');

        if LastIteration = '17-3-2-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '17-3-2-40' then
            exit;
        // 17-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '17-3-3-10' then
            exit;
        // 17-3-4
        TestScriptMgmt.InsertWhsePickOrderHeader(WhsePickOrderHeader, 'WHITE', 'Production', 'W-07-0001');

        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 10000, 'A_TEST', '12', 'WHITE', 'Production', 'W-07-0001', 15, 'PCS');
        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 20000, 'C_TEST', '32', 'WHITE', 'Production', 'W-07-0001', 15, 'PCS');

        if LastIteration = '17-3-4-10' then
            exit;

        TestScriptMgmt.ReleaseWhsePickOrder(WhsePickOrderHeader);

        if LastIteration = '17-3-4-20' then
            exit;

        Commit();
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011127D,
          'A_TEST', '12', 'W-01-0002', 'W-10-0001', 15, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 20000, 20011127D,
          'C_TEST', '32', 'W-04-0001', 'W-04-0002', 2, 'PALLET');

        if LastIteration = '17-3-4-30' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreatePickFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);
        WhseWkshLine.Reset();

        if LastIteration = '17-3-4-40' then
            exit;

        TestScriptMgmt.CreatePickWorksheet(PickWkshLine, 'PICK', 'DEFAULT', 'WHITE', 1, 'WI000001');

        if LastIteration = '17-3-4-50' then
            exit;
        // 17-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '17-3-5-10' then
            exit;
        // 17-3-6
        Clear(WhseWkshLine);
        Clear(PickWkshLine);
        PickWkshLine.SetCurrentKey("Worksheet Template Name", Name,
          "Location Code", "Sorting Sequence No.");
        PickWkshLine.SetRange("Worksheet Template Name", 'PICK');
        PickWkshLine.SetRange(Name, 'DEFAULT');
        PickWkshLine.SetRange("Location Code", 'WHITE');
        PickWkshLine.SetRange("Whse. Document No.", 'WI000001');
        PickWkshLine.Find('-');

        if LastIteration = '17-3-6-10' then
            exit;

        TestScriptMgmt.CreatePickFromWksh(
          PickWkshLine, '', 1, 0, "Whse. Activity Sorting Method"::None, false, true, false, false, false, false, false);

        if LastIteration = '17-3-6-20' then
            exit;
        // 17-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '17-3-7-10' then
            exit;
        // 17-3-8
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '17-3-8-10' then
            exit;
        // 17-3-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '17-3-9-10' then
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

