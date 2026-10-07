codeunit 103333 "WMS Test Use Case 23"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 23");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103333, 23, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        WhseWkshLine: Record "Whse. Worksheet Line";
        SelectionForm: Page "Whse. Test Selection";
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
            2:
                PerformTestCase2();
            3:
                PerformTestCase3();
            4:
                PerformTestCase4();
            5:
                PerformTestCase5();
            6:
                PerformTestCase6();
            7:
                PerformTestCase7();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '23-1-1-10' then exit;

        Location.SetRange(Code, 'WHITE');
        Location.Find('-');
        Location."Always Create Pick Line" := true;
        Location.Modify(true);

        if LastIteration = '23-1-1-20' then exit;

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-01-0001', 'A_TEST', '', 'PCS', 10, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-01-0002', 'B_TEST', '', 'PCS', 10, 100);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'PICK', 'W-01-0003', 'T_TEST', 'T2', 'BOX', 10, 100);

        if LastIteration = '23-1-1-30' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS23-1-1', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 10, 'BOX', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '', 'WHITE', 7, 'PCS', 5.67, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 5, 'PCS', 5.67, false);

        SNCode := 'SN00';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateReservEntry.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '23-1-1-40' then exit;
        // 23-1-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T2', 3, 'BOX', 44.11, 'WHITE', '');

        if LastIteration = '23-1-2-10' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'B_Test', '', 3, 'PCS', 12.22, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', 'T2', 4, 'BOX', 44.11, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A_Test', '', 4, 'PCS', 9.75, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, '', 50, 'WHITE', '');

        if LastIteration = '23-1-2-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS23-1-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 1, 'Pcs', 12.22, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 1, 'PCS', 12.22, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 5, 'BOX', 44.11, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 2, 'PCS', 12.22, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'A_TEST', '', 'WHITE', 4, 'PCS', 9.75, false);

        if LastIteration = '23-1-2-30' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        PutAwayWkshLine: Record "Whse. Worksheet Line";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '23-2-1-10' then exit;

        Location.SetRange(Code, 'WHITE');
        Location.Find('-');
        Location."Allow Breakbulk" := false;
        Location.Modify(true);

        if LastIteration = '23-2-1-20' then exit;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 10000, 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS23-2-1', 'A_TEST', '', 'WHITE', '', 1, 'PCS', 10, 0);
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS23-2-1', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'WHITE', 10, 'Pack', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'WHITE', 13, 'Box', 5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80100', '', 'WHITE', 10, 'Pallet', 10, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80216-T', '', 'WHITE', 4, 'PCS', 10, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 4, 'BOX', 1.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'A_TEST', '', 'WHITE', 23, 'PCS', 5.67, false);

        SNCode := 'SN00';
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 50000, 1, 1, 1, SNCode, '');
            CreateReservEntry.CreateEntry('T_TEST', 'T1', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 50000, 1, 1, 1, 'SN-09-0001', '');
        CreateReservEntry.CreateEntry('T_TEST', 'T1', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 1, 4, 4, '', 'LOT01');
        CreateReservEntry.CreateEntry('80216-T', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.Find('-');
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 20000, 'Pick', 'W-01-0002', 10);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'PICK', 'W-01-0001', 13);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 60000, 'Pick', 'W-01-0003', 10);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 80000, 'Pick', 'W-01-0001', 4);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 100000, 'PICK', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 120000, 'Pick', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 140000, 'Pick', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 160000, 'Ship', 'W-09-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 170000, 'Receive', 'W-08-0001', 22);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 180000, 'Pick', 'W-02-0001', 10);
        WhseActivLine.SplitLine(WhseActivLine);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 190000, 'Pick', 'W-02-0002', 1);
        WhseActivLine.SplitLine(WhseActivLine);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 200000, 'Cross-Dock', 'W-14-0002', 10);
        WhseActivLine.SplitLine(WhseActivLine);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 210000, 'QC', 'W-10-0001', 1);

        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        WhseActivHeader.Find('-');
        WhseActivHeader.Delete(true);

        if LastIteration = '23-2-1-30' then exit;

        Bin.SetRange("Location Code", 'WHITE');
        Bin.SetRange(Code, 'W-02-0002');
        Bin.Find('-');
        Bin."Block Movement" := Bin."Block Movement"::All;
        Bin.Modify(true);
        BinContent.Reset();
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.ModifyAll("Block Movement", Bin."Block Movement"::All);

        if LastIteration = '23-2-1-40' then exit;
        // 23-2-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 3, 'PCS', 4.55, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 3, 'BOX', 5.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'T_Test', 'T1', 3, 'BOX', 15.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80216-T', '', 3, 'PCS', 0.8, 'WHITE', '');

        if LastIteration = '23-2-2-10' then exit;
        // 23-2-3
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS23-2-4', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 1, 'Box', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80216-T', '', 'WHITE', 1, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_TEST', '', 'WHITE', 1, 'PCs', 0.73, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'Box', 3.0, false);

        if LastIteration = '23-2-3-10' then exit;

        SNCode := 'SN04';
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
        CreateReservEntry.CreateEntry('T_TEST', 'T1', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, '', 'LOT02');
        CreateReservEntry.CreateEntry('80216-T', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '23-2-3-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '23-2-3-30' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        WhseRcptLine.SetRange(WhseRcptLine."No.", 'Re000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '23-2-3-40' then exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Put-away");
        WhseActivHeader.SetRange("No.", 'PU000002');
        WhseActivHeader.Find('-');
        WhseActivHeader.Delete(true);

        TestScriptMgmt.CreatePutAwayWorksheet(PutAwayWkshLine, 'Put-away', 'Default', 'WHITE', 0, 'R_000002');

        if LastIteration = '23-2-3-50' then exit;
        // 23-2-4
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011125D,
          '80100', '', 'W-01-0001', 'W-01-0002', 2, 'Box');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 20000, 20011125D,
         '80100', '', 'W-01-0001', 'W-05-0001', 1, 'Box');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 30000, 20011125D,
         'T_TEST', 'T1', 'W-01-0001', 'W-01-0002', 1, 'Box');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 40000, 20011125D,
         'T_TEST', 'T1', 'W-01-0001', 'W-07-0001', 2, 'Box');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 50000, 20011125D,
         '80216-T', '', 'W-01-0001', 'W-01-0002', 2, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 60000, 20011125D,
         '80216-T', '', 'W-01-0001', 'W-07-0002', 1, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 70000, 20011125D,
         'A_TEST', '', 'W-02-0001', 'W-01-0002', 2, 'PCS');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 80000, 20011125D,
         'A_TEST', '', 'W-02-0001', 'W-07-0003', 1, 'PCS');

        WhseWkshLine.Reset();
        WhseWkshLine.SetRange(WhseWkshLine."Line No.", 10000);
        WhseWkshLine.Find('-');
        WhseWkshLine.Validate("Qty. to Handle", 1);
        WhseWkshLine.Modify(true);

        WhseWkshLine.Reset();
        WhseWkshLine.SetRange(WhseWkshLine."Line No.", 40000);
        WhseWkshLine.Find('-');
        WhseWkshLine."Qty. to Handle" := 1;
        WhseWkshLine.Modify(true);

        WhseWkshLine.Reset();
        WhseWkshLine.SetRange(WhseWkshLine."Line No.", 50000);
        WhseWkshLine.Find('-');
        WhseWkshLine.Validate("Qty. to Handle", 1);
        WhseWkshLine.Modify(true);

        WhseWkshLine.Reset();
        WhseWkshLine.SetRange(WhseWkshLine."Line No.", 70000);
        WhseWkshLine.Find('-');
        WhseWkshLine.Validate("Qty. to Handle", 1);
        WhseWkshLine.Modify(true);

        if LastIteration = '23-2-4-10' then exit;

        WhseWkshLine.Reset();
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '23-2-4-20' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 50000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Serial No.", 'SN02');
        WhseActivLine.Modify(true);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 60000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Serial No.", 'SN02');
        WhseActivLine.Modify(true);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 70000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Serial No.", 'SN03');
        WhseActivLine.Modify(true);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 80000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Serial No.", 'SN03');
        WhseActivLine.Modify(true);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 110000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Lot No.", 'LOT01');
        WhseActivLine.Modify(true);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 120000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Lot No.", 'LOT01');
        WhseActivLine.Modify(true);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 90000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Lot No.", 'LOT01');
        WhseActivLine.Modify(true);

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Line No.", 100000);
        WhseActivLine.Find('-');
        WhseActivLine.Validate("Lot No.", 'LOT01');
        WhseActivLine.Modify(true);

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '23-2-4-30' then exit;
        // 23-2-5
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 331, 'BOX', 5.11, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_TEST', 'T1', 1, 'BOX', 15.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80216-T', '', 2, 'PCS', 0.8, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'A_TEST', '', 20, 'PCS', 4.55, 'WHITE', '');

        SalesLine.Reset();
        SalesLine.SetRange("Document No.", '1002');
        if SalesLine.Find('-') then
            repeat
                SalesLine."Planned Delivery Date" := 20011130D;
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;

        if LastIteration = '23-2-5-10' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_TEST', '', 20, 'PCS', 4.55, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 10, 'PACK', 5.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'T_TEST', 'T1', 1, 'BOX', 15.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80216-T', '', 1, 'PCS', 0.8, 'WHITE', '');

        SalesLine.Reset();
        SalesLine.SetRange("Document No.", '1003');
        if SalesLine.Find('-') then
            repeat
                SalesLine."Planned Delivery Date" := 20011130D;
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;

        if LastIteration = '23-2-5-20' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '23-3-1-10' then exit;

        Location.SetRange(Code, 'WHITE');
        Location.Find('-');
        Location."Always Create Pick Line" := true;
        Location.Modify(true);

        if LastIteration = '23-3-1-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS23-3-1-W', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'WHITE', 3, 'Pack', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'Pack', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'Pack', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'Pack', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'Pack', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 5, 'Box', 5, false);

        SNCode := 'SN00';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 60000, 1, 1, 1, SNCode, '');
            CreateReservEntry.CreateEntry('T_TEST', 'T1', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.Find('-');
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 20000, 'PICK', 'W-01-0001', 3);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'PICK', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 60000, 'PICK', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 80000, 'PICK', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 100000, 'PICK', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 120000, 'Pick', 'W-02-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 140000, 'Pick', 'W-02-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 160000, 'Pick', 'W-02-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 180000, 'Pick', 'W-02-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 200000, 'Pick', 'W-02-0001', 1);

        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS23-3-1-B', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'Blue', 3, 'Box', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T1', 'Blue', 3, 'Box', 5, false);

        SNCode := 'SN05';
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateReservEntry.CreateEntry('T_TEST', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        PurchHeader.SetRange("No.", '106002');
        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '23-3-1-30' then exit;
        // 23-3-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 10, 'Pack', 1.07, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_TEST', 'T1', 3, 'BOX', 44.11, 'WHITE', '');

        if LastIteration = '23-3-2-10' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_TEST', 'T1', 5, 'BOX', 44.11, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 10, 'Pack', 1.07, 'WHITE', '');

        if LastIteration = '23-3-2-20' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '23-4-1-10' then exit;

        Item.Get('80100');
        Item."Replenishment System" := Item."Replenishment System"::Purchase;
        Item."Put-away Unit of Measure Code" := 'BOX';
        Item.Modify(true);
        Item.Reset();
        Item.Get('D_PROD');
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item.Modify(true);

        if LastIteration = '23-4-1-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS23-4-1', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T1', 'Blue', 1, 'Box', 5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'Blue', 1, 'Pallet', 1, false);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN01', '');
        CreateReservEntry.CreateEntry('T_TEST', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '23-4-1-30' then exit;
        // 23-4-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T1', 1, 'BOX', 44.11, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 1, 'Pallet', 1.07, 'WHITE', '');

        if LastIteration = '23-4-2-10' then exit;
        // 23-4-3
        TestScriptMgmt.InsertTransferHeader(TransHeader, 'BLUE', 'WHITE', 'OWN LOG.', 20011125D);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 10000, 'T_TEST', 'T1', 'BOX', 1, 0, 1);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 20000, '80100', '', 'Pallet', 1, 0, 1);

        if LastIteration = '23-4-3-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '23-5-1-10' then exit;

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'T_TEST', 'T2', 'Box', 2, 5);

        if LastIteration = '23-5-1-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS23-5-1', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T2', 'White', 2, 'Box', 5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80216-T', '', 'White', 2, 'PCS', 1, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'C_TEST', '32', 'White', 3, 'PCS', 1, false);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN01', '');
        CreateReservEntry.CreateEntry('T_TEST', 'T2', 'White', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'SN02', '');
        CreateReservEntry.CreateEntry('T_TEST', 'T2', 'White', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 2, 2, '', 'LOT01');
        CreateReservEntry.CreateEntry('80216-T', '', 'White', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.Find('-');
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 20000, 'PICK', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'Pick', 'W-01-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 60000, 'Pick', 'W-01-0001', 2);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 80000, 'PICK', 'W-01-0001', 3);

        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '23-5-1-30' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '23-6-1-10' then exit;
        // 23-6-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS23-6-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T2', 'White', 4, 'Box', 5, false);

        SNCode := 'SN00';
        for i := 1 to 4 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateReservEntry.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.Find('-');
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 20000, 'PICK', 'W-04-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'Pick', 'W-04-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 60000, 'Pick', 'W-04-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 80000, 'PICK', 'W-04-0001', 1);

        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '23-6-2-10' then exit;
        // 23-6-3
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T2', 3, 'BOX', 12.27, 'WHITE', '');

        if LastIteration = '23-6-3-10' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T2', 2, 'BOX', 12.27, 'WHITE', '');

        if LastIteration = '23-6-3-20' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '23-7-1-10' then exit;
        // 23-7-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS23-7-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C_TEST', '32', 'White', 3, 'PCS', 5, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '23-7-2-10' then exit;
        // 23-7-3
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'White', 'TCS23-7-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '', 'White', 12, 'PCS', 9.27, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '23-7-3-10' then exit;
        // 23-7-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'D_PROD', 4, 'WHITE');
        ProdOrder.Validate("Due Date", 20011126D);
        ProdOrder.Modify(true);
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '23-7-4-10' then exit;
        // 23-7-5
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_TEST', '12', 3, 'PCS', 12.27, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'D_PROD', '', 2, 'PCS', 50.01, 'WHITE', '');

        SalesLine.Reset();
        SalesLine.SetRange("Document No.", '1001');
        if SalesLine.Find('-') then
            repeat
                SalesLine."Planned Delivery Date" := 20011130D;
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
        if LastIteration = '23-7-5-10' then exit;
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

    local procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntry.CreateReservEntryFor(
            ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;
}

