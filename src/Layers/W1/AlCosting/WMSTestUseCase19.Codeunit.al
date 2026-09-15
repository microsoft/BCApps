codeunit 103329 "WMS Test Use Case 19"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 19");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103329, 19, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhsePickOrderHeader: Record "Whse. Internal Pick Header";
        WhsePickOrderLine: Record "Whse. Internal Pick Line";
        SelectionForm: Page "Whse. Test Selection";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '19-1-1-10' then
            exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, true, 1);

        if LastIteration = '19-1-1-20' then
            exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'PICK', 'W-01-0001', 99, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '11', 'PICK', 'W-02-0002', 52, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-01-0002', 22, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-03-0001', 4, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-04-0001', 30, 'PCS');

        if LastIteration = '19-1-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '19-1-2-20' then
            exit;

        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS19-1-2');

        if LastIteration = '19-1-2-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '19-1-2-40' then
            exit;
        // 19-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '19-1-3-10' then
            exit;
        // 19-1-4
        Commit();
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011127D,
          'C_TEST', '32', 'W-01-0001', 'W-10-0001', 10, 'PCS');

        if LastIteration = '19-1-4-10' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreatePickFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);
        WhseWkshLine.Reset();

        if LastIteration = '19-1-4-20' then
            exit;

        TestScriptMgmt.InsertWhsePickOrderHeader(WhsePickOrderHeader, 'WHITE', 'Production', 'w-07-0001');

        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 10000, 'C_TEST', '32', 'WHITE', 'Production', 'w-07-0001', 100, 'PCS');
        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 20000, 'B_TEST', '', 'WHITE', 'Production', 'w-07-0001', 20, 'PCS');
        TestScriptMgmt.InsertWhsePickOrderLines(
          WhsePickOrderLine, WhsePickOrderHeader, 30000, 'A_TEST', '12', 'WHITE', 'Production', 'w-07-0001', 20, 'PCS');

        if LastIteration = '19-1-4-30' then
            exit;

        TestScriptMgmt.CreatePickFromPickOrder(WhsePickOrderHeader);

        if LastIteration = '19-1-4-40' then
            exit;
        // 19-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '19-1-5-10' then
            exit;
        // 19-1-6
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 30000, '', '', 0);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'Production', 'w-07-0001', 0);

        if LastIteration = '19-1-6-10' then
            exit;

        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '19-1-6-20' then
            exit;
        // 19-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '19-1-7-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        BinContent: Record "Bin Content";
        ReplenishmtBatch: Report "Calculate Bin Replenishment";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '19-2-1-10' then
            exit;

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-01-0001', 'C_TEST', '32', 'PCS', 5, 300);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-02-0001', 'A_TEST', '12', 'PCS', 13, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-03-0001', 'B_TEST', '', 'PCS', 10, 600);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'w-07-0001', 'A_TEST', '12', 'PALLET', 2, 20);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'w-07-0001', 'B_TEST', '', 'PCS', 20, 250);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'w-07-0001', 'C_TEST', '32', 'PCS', 20, 300);

        if LastIteration = '19-2-1-20' then
            exit;

        GlobalPrecondition.SetupLocation('STD', true, false, false, false, 1);

        if LastIteration = '19-2-1-30' then
            exit;
        GetLastILENo();

        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'PICK', 'W-01-0001', 20, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0001', 20, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'PICK', 'W-02-0002', 20, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'PICK', 'W-03-0001', 20, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0001', 1, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'A_TEST', '12', 'BULK', 'W-05-0016', 9, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0002', 30, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'BULK', 'W-05-0015', 250, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'BULK', 'W-05-0003', 30, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'C_TEST', '32', 'BULK', 'W-05-0014', 10, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'QC', 'W-10-0001', 10, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'RECEIVE', 'W-08-0001', 10, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'SHIP', 'W-09-0001', 10, 'PCS');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseJnlLineNo), 20011126D,
          'B_TEST', '', 'STAGE', 'W-06-0001', 10, 'PCS');

        if LastIteration = '19-2-2-10' then
            exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '19-2-2-20' then
            exit;

        TestScriptMgmt.CalcWhseAdjustment(ItemJnlLine, 20011125D, 'TCS19-2-2');

        if LastIteration = '19-2-2-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '19-2-2-40' then
            exit;
        // 19-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '19-2-3-10' then
            exit;
        // 19-2-4
        WhseJnlLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011126D,
          'C_TEST', '32', 'W-05-0003', 'W-10-0001', 10, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 20000, 20011126D,
          'A_TEST', '12', 'W-05-0016', 'W-02-0003', 1, 'PALLET');

        if LastIteration = '19-2-4-10' then
            exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreatePickFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '19-2-4-20' then
            exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011128D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011128D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'B_Test', '', 5, 'PCS', 16, 'WHITE', '');

        if LastIteration = '19-2-4-30' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '19-2-4-40' then
            exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '19-2-4-50' then
            exit;

        WhseShptHeader.SetRange("Location Code", 'WHITE');
        WhseShptHeader.Find('-');
        TestScriptMgmt.ModifyWhseShptLine(WhseShptLine, WhseShptHeader."No.", 10000, 'SHIP', 'W-09-0002', 0);

        if LastIteration = '19-2-4-60' then
            exit;

        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '19-2-4-70' then
            exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.FindFirst();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '19-2-4-80' then
            exit;
        // 19-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '19-2-5-10' then
            exit;
        // 19-2-6
        BinContent.SetRange("Location Code", 'WHITE');
        ReplenishmtBatch.UseRequestPage(false);
        ReplenishmtBatch.InitializeRequest('MOVEMENT', 'DEFAULT', 'WHITE', true, true, false);
        ReplenishmtBatch.SetTableView(BinContent);
        ReplenishmtBatch.RunModal();

        if LastIteration = '19-2-6-10' then
            exit;
        // 19-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '19-2-7-10' then
            exit;
        // 19-2-8
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreatePickFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '19-2-8-10' then
            exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.FindLast();
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '19-2-8-20' then
            exit;
        // 19-2-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '19-2-9-10' then
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

