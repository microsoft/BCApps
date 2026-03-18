codeunit 103331 "WMS Test Use Case 21"
{
    // Unsupported version tags:
    // ES: Unable to Compile
    // NA: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        QASetup: Record "Whse. QA Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
    begin
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 21");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103331, 21, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        ResEntry: Record "Reservation Entry";
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
            10:
                PerformTestCase10();
            11:
                PerformTestCase11();
            12:
                PerformTestCase12();
            13:
                PerformTestCase13();
            14:
                PerformTestCase14();
            15:
                PerformTestCase15();
            16:
                PerformTestCase16();
            17:
                PerformTestCase17();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        WhseActivityPost: Codeunit "Whse.-Activity-Register";
        SNCode: Code[20];
        i: Integer;
        EntryNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-1-1-10' then exit;
        // 21-1-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        if LastIteration = '21-1-2-10' then exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80102-T', '', 1, 'PCS', 11.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80102-T', '', 1, 'PCS', 11.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80003', '', 12, 'PCS', 16.1, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80001', '', 1, 'PCS', 12.6, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '70000', '', 10, 'PCS', 30.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '80001', '', 1, 'PCS', 12.6, 'WHITE', '');

        if LastIteration = '21-1-2-20' then exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'WHITE', 20000, "Reservation Status"::Prospect, 20011125D, '80102-T', '', 'SN01', '', 1, 1, 37, 1, SalesHeader."No.", '', 20000, true);

        if LastIteration = '21-1-2-30' then exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Line No.", 10000);
        if SalesLine.Find('-') then
            SalesLine.Delete(true);
        SalesLine.SetRange("Line No.", 40000);
        if SalesLine.Find('-') then
            SalesLine.Delete(true);

        if LastIteration = '21-1-2-40' then exit;

        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 50000);
        SalesLine.Description := 'This is an extremely long text to make a test case';
        SalesLine.Modify();

        if LastIteration = '21-1-2-50' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-1-2-60' then exit;

        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-1-2-70' then exit;
        // 21-1-3
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-1-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80003', '', 'WHITE', 12, 'PCS', 8.2, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '70000', '', 'WHITE', 10, 'PCS', 15.7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80216-T', '', 'WHITE', 100, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80002', '', 'WHITE', 2, 'PCS', 7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '80102-T', '', 'WHITE', 1, 'PCS', 6.3, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '80001', '', 'WHITE', 1, 'PCS', 5.83, false);

        if LastIteration = '21-1-3-10' then exit;

        SNCode := 'SN00000';
        for i := 1 to 12 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('80003', '', 'WHITE', SNCode, '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        end;
        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 40000, 2, 2, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80102-T', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 50000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, 'SN01', '', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80001', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 60000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, 'SN02', '', 0D, 0D);

        if LastIteration = '21-1-3-20' then exit;

        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 20000);
        PurchLine.Description := 'This is an extremely long text to make a test case';
        PurchLine.Modify();

        if LastIteration = '21-1-3-30' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-1-3-40' then exit;

        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-1-3-50' then exit;

        TestScriptMgmt.CreateItemTrackfromJnlLine('80216-T', '', 'WHITE', '', 'LOT00001', 75, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 30000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80216-T', '', 'WHITE', '', 'LOT00002', 25, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 30000, true);

        if LastIteration = '21-1-3-60' then exit;

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-1-3-70' then exit;
        // 21-1-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '21-1-4-10' then exit;
        // 21-1-5
        WhseActivHeader.Reset();
        WhseActivHeader.Find('-');
        WhseActivHeader.Delete(true);

        if LastIteration = '21-1-5-10' then exit;

        PostedWhseRcptHeader.Reset();
        PostedWhseRcptHeader.Find('-');
        TestScriptMgmt.CreaPutAwayFromPostWhseRcptSrc(PostedWhseRcptHeader);

        if LastIteration = '21-1-5-20' then exit;
        // 21-1-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '21-1-6-10' then exit;
        // 21-1-7
        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-1-7-10' then exit;
        // 21-1-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '21-1-8-10' then exit;
        // 21-1-9
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', 10000, 20011125D, '80003', '',
          'W-04-0001', 'W-04-0002', 3, 'PCS');

        if LastIteration = '21-1-9-10' then exit;

        SNCode := 'SN00000';
        WhseItemTrkgLine.Reset();
        WhseItemTrkgLine.Find('-');
        EntryNo := WhseItemTrkgLine."Entry No." + 1;
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            WhseItemTrkgLine.Init();
            WhseItemTrkgLine."Serial No." := SNCode;
            WhseItemTrkgLine.Validate("Quantity (Base)", 1);
            WhseItemTrkgLine."Source Type" := DATABASE::"Whse. Worksheet Line";
            WhseItemTrkgLine."Source ID" := WhseWkshLine.Name;
            WhseItemTrkgLine."Source Ref. No." := WhseWkshLine."Line No.";
            WhseItemTrkgLine."Source Batch Name" := WhseWkshLine."Worksheet Template Name";
            WhseItemTrkgLine."Location Code" := WhseWkshLine."Location Code";
            WhseItemTrkgLine."Item No." := WhseWkshLine."Item No.";
            WhseItemTrkgLine."Entry No." := EntryNo;
            WhseItemTrkgLine.Insert();
            EntryNo := WhseItemTrkgLine."Entry No." + 1;
        end;

        if LastIteration = '21-1-9-20' then exit;

        WhseWkshLine.Description := 'This is an extremely long text to make a test case';
        WhseWkshLine.Modify();

        if LastIteration = '21-1-9-30' then exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '21-1-9-40' then exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        if WhseActivLine.Find('-') then
            WhseActivityPost.Run(WhseActivLine);

        if LastIteration = '21-1-9-50' then exit;
        // 21-1-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '21-1-10-10' then exit;
        // 21-1-11
        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-1-11-10' then exit;
        // 21-1-12
        SNCode := 'SN00000';
        i := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", '80003');
        WhseActivLine.SetRange("Bin Code", 'W-04-0002');
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SetRange("Bin Code");
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until (WhseActivLine.Next() = 0) or
              ((WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take) and
                (WhseActivLine."Bin Code" <> 'W-04-0002'));
        end;
        WhseActivLine.SetRange("Bin Code", 'W-04-0001');
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SetRange("Bin Code");
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until (WhseActivLine.Next() = 0) or
              ((WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take) and
                (WhseActivLine."Bin Code" <> 'W-04-0001'));
        end;
        SNCode := 'SN02';
        WhseActivLine.SetRange("Item No.", '80001');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-1-12-10' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-1-12-20' then exit;
        // 21-1-13
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '21-1-13-10' then exit;
        // 21-1-14
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 14, LastILENo);

        if LastIteration = '21-1-14-10' then exit;
        // 21-1-15
        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(WhseJnlLine, 'ADJMT', 'DEFAULT', 'WHITE', 10000, 20011126D,
          '70000', '', 'PICK', 'W-04-0002', 1, 'PCS');

        if LastIteration = '21-1-15-10' then exit;

        WhseJnlLine.Description := 'This is an extremely long text to make a test case';
        WhseJnlLine.Modify();

        if LastIteration = '21-1-15-20' then exit;

        TestScriptMgmt.WhseJnlPostBatch(WhseJnlLine);

        if LastIteration = '21-1-15-30' then exit;
        // 21-1-16
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 16, LastILENo);

        if LastIteration = '21-1-16-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        GenPostSetup: Record "General Posting Setup";
        ItemTrackCode: Record "Item Tracking Code";
        LotNoInfo: Record "Lot No. Information";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-2-1-10' then exit;

        ItemTrackCode.Get('LOTALL');
        ItemTrackCode."Lot Info. Inbound Must Exist" := true;
        ItemTrackCode."Lot Info. Outbound Must Exist" := true;
        ItemTrackCode.Modify();

        if LastIteration = '21-2-1-20' then exit;

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Sales Account", '6130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '21-2-1-30' then exit;
        // 21-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-2-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80216-T', '', 'WHITE', 28, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 1, 'BOX', 1.11, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 1, 'BOX', 1.11, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'C_TEST', '32', 'WHITE', 7, 'PALLET', 12.37, false);

        if LastIteration = '21-2-2-10' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('T_TEST', 'T1', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, 'SN00001', '', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('T_TEST', 'T1', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, 'SN00002', '', 0D, 0D);

        if LastIteration = '21-2-2-20' then exit;

        if PurchLine.Find('-') then
            PurchLine.ModifyAll(Description, 'This is an extremely long text to make a test case');

        if LastIteration = '21-2-2-30' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-2-2-40' then exit;

        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-2-2-50' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80216-T', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 1, 28, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT00001', 0D, 0D);

        if LastIteration = '21-2-2-60' then exit;

        LotNoInfo.Init();
        LotNoInfo."Item No." := '80216-T';
        LotNoInfo."Lot No." := 'LOT00001';
        LotNoInfo.Description := 'Description for LOT00001';
        if LotNoInfo.Insert() then;

        if LastIteration = '21-2-2-70' then exit;

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-2-2-80' then exit;
        //Split lines in put-away
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.SetRange("Item No.", '80216-T');
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        if WhseActivLine.Find('-') then begin
            TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", WhseActivLine."Line No.", 'PICK', 'W-04-0001', 8);
            WhseActivLine.SplitLine(WhseActivLine);
            WhseActivLine.Find('+');
            TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", WhseActivLine."Line No.", 'PICK', 'W-04-0002', 20);
        end;

        if LastIteration = '21-2-2-90' then exit;
        //Register put-away
        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-2-2-100' then exit;
        // 21-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-2-3-10' then exit;
        // 21-2-4
        //Create new sales order
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        if LastIteration = '21-2-4-10' then exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80216-T', '', 28, 'PCS', 0.8, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'C_TEST', '32', 11, 'PCS', 3.22, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'T_TEST', 'T1', 1, 'BOX', 2.01, 'WHITE', '');

        if LastIteration = '21-2-4-20' then exit;
        //Change the description in all lines
        if SalesLine.Find('-') then
            SalesLine.ModifyAll(Description, 'This is an extremely long text to make a test case');

        if LastIteration = '21-2-4-30' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-2-4-40' then exit;

        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-2-4-50' then exit;
        //Create a pick
        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-2-4-60' then exit;
        //Assign IT info
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", '80216-T');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LOT00001');
                WhseActivLine.Modify();
            until WhseActivLine.Next() = 0;
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Serial No.", 'SN00002');
                WhseActivLine.Modify();
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-2-4-70' then exit;
        //Register the pick
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-2-4-80' then exit;
        // 21-2-5
        //Post the shipment as shipped and invoiced
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '21-2-5-10' then exit;
        // 21-2-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '21-2-6-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        ResEntry: Record "Reservation Entry";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-3-1-10' then exit;
        // 21-3-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        if LastIteration = '21-3-2-10' then exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_TEST', 'T2', 1, 'BOX', 2.08, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_TEST', 'T2', 1, 'BOX', 2.08, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_TEST', '21', 5, 'PCS', 17.88, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '70000', '', 1, 'PCS', 30.7, 'WHITE', '');

        if LastIteration = '21-3-2-20' then exit;
        //Assign IT info
        TestScriptMgmt.InsertResEntry(ResEntry, 'WHITE', 20000, "Reservation Status"::Prospect, 20011125D, 'T_TEST', 'T2', 'SN02', 'LOT02', 1, 1, 37, 1, SalesHeader."No.", '', 20000, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'WHITE', 40000, "Reservation Status"::Prospect, 20011125D, 'T_TEST', 'T2', 'SN01', 'LOT01', 1, 1, 37, 1, SalesHeader."No.", '', 10000, true);

        if LastIteration = '21-3-2-30' then exit;
        //Change description for line 10000
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        SalesLine.Description := 'This is an extremely long text to make a test case';
        SalesLine.Modify();

        SalesLine.Reset();
        SalesLine.Find('-');
        SalesLine.Validate("Shipment Date", 20011130D);
        SalesLine.Modify();

        if LastIteration = '21-3-2-40' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-3-2-50' then exit;

        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-3-2-60' then exit;
        // 21-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-3-3-10' then exit;
        // 21-3-4
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-3-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '70000', '', 'WHITE', 1, 'PCS', 15.7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 1, 'BOX', 0.77, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'B_TEST', '21', 'WHITE', 10, 'PCS', 15, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 1, 'BOX', 0.77, false);

        if LastIteration = '21-3-4-10' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('T_TEST', 'T2', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, 'SN01', 'LOT01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('T_TEST', 'T2', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 40000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, 'SN02', 'LOT02', 0D, 0D);

        if LastIteration = '21-3-4-20' then exit;
        //Change description for line 40000
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 40000);
        PurchLine.Description := 'This is an extremely long text to make a test case';
        PurchLine.Modify();

        if LastIteration = '21-3-4-30' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-3-4-40' then exit;

        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-3-4-60' then exit;
        if LastIteration = '21-3-4-70' then exit;

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-3-4-80' then exit;
        //Change put-away bin for place line of item 70000
        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.SetRange("Item No.", '70000');
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        if WhseActivLine.Find('-') then
            TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", WhseActivLine."Line No.", 'PICK', 'W-04-0011', 1);

        if LastIteration = '21-3-4-90' then exit;
        //Register the put-away
        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-3-4-100' then exit;
        // 21-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '21-3-5-10' then exit;
        // 21-3-6
        //Create a pick for the shipment created before
        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-3-6-10' then exit;
        //Register the pick
        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-3-6-20' then exit;
        // 21-3-7
        //Post the shipment as shipped and invoiced
        Clear(WhseShptLine);
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '21-3-7-10' then exit;
        // 21-3-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '21-3-8-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        WhseSrcFilter: Record "Warehouse Source Filter";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseActivLine: Record "Warehouse Activity Line";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-4-1-10' then exit;

        WhseSrcFilter.Get(1, 'CUSTOMERS');
        WhseSrcFilter."Item No. Filter" := '';
        WhseSrcFilter."Sales Return Orders" := false;
        WhseSrcFilter."Purchase Orders" := false;
        WhseSrcFilter.Modify();

        if LastIteration = '21-4-1-20' then exit;
        // 21-4-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-4-2', false);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80102-T', '', 'WHITE', 10, 'PCS', 6.3, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1000', '', 'WHITE', 1, 'PCS', 2499, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '70000', '', 'WHITE', 100, 'PCS', 50, false);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'A_TEST', '11', 'WHITE', 7, 'PCS', 3.2, false);

        if LastIteration = '21-4-2-10' then exit;

        SNCode := 'SN00000';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('80102-T', '', 'WHITE', SNCode, '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        end;

        if LastIteration = '21-4-2-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-4-2-30' then exit;

        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-4-2-40' then exit;

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-4-2-50' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-4-2-60' then exit;
        // 21-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-4-3-10' then exit;
        // 21-4-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        if LastIteration = '21-4-4-10' then exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80102-T', '', 2, 'PCS', 11.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1000', '', 10, 'PCS', 4000, 'WHITE', '');

        if LastIteration = '21-4-4-20' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-4-4-30' then exit;
        // 21-4-5
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        if LastIteration = '21-4-5-10' then exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80102-T', '', 3, 'PCS', 11.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '1000', '', 10, 'PCS', 4000, 'WHITE', '');

        if LastIteration = '21-4-5-20' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-4-5-30' then exit;
        // 21-4-6
        //Create a new shipment for location WHITE
        Clear(WhseShptHeader);
        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, '', '', '');
        WhseShptHeader.Validate("Location Code", 'WHITE');
        WhseShptHeader.Modify();

        if LastIteration = '21-4-6-10' then exit;
        //Use function 'Get Source Documents...' to get both sales orders
        TestScriptMgmt.CreateWhseShptBySourceFilter(WhseShptHeader, 'CUSTOMERS');

        if LastIteration = '21-4-6-20' then exit;
        //Create a pick
        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-4-6-30' then exit;
        //Assign serial nos.
        SNCode := 'SN00000';
        i := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", '80102-T');
        if WhseActivLine.Find('-') then
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-4-6-40' then exit;
        // 21-4-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '21-4-7-10' then exit;
        // 21-4-8
        //Register the pick.
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-4-8-10' then exit;
        // 21-4-9
        //Post the shipment.
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '21-4-9-10' then exit;
        // 21-4-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '21-4-10-10' then exit;

        Commit();
        // 21-4-11
        if LastIteration = '21-4-11-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        Loc: Record Location;
        Bin: Record Bin;
        ItemUoM: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        ItemChargeAssignSales: Record "Item Charge Assignment (Sales)";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-5-1-10' then exit;

        Loc.Get('WHITE');
        Loc."Bin Capacity Policy" := Loc."Bin Capacity Policy"::"Prohibit More Than Max. Cap.";
        Loc.Modify();

        if LastIteration = '21-5-1-20' then exit;

        Bin.Get('WHITE', 'W-01-0002');
        Bin.Validate("Maximum Weight", 490);
        Bin.Modify();

        if LastIteration = '21-5-1-30' then exit;

        ItemUoM.Get('80100', 'PALLET');
        ItemUoM.Weight := 480;
        ItemUoM.Modify();

        ItemUoM.Get('80100', 'BOX');
        ItemUoM.Weight := 15;
        ItemUoM.Modify();

        if LastIteration = '21-5-1-40' then exit;
        // 21-5-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-5-2', false);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'PALLET', 96, false);

        if LastIteration = '21-5-2-10' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-5-2-20' then exit;

        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-5-2-30' then exit;

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-5-2-40' then exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.SetRange("Item No.", '80100');
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        if WhseActivLine.Find('-') then
            TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", WhseActivLine."Line No.", 'PICK', 'W-01-0002', 1);

        if LastIteration = '21-5-2-50' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-5-2-60' then exit;
        // 21-5-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-5-3-10' then exit;
        // 21-5-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '61000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        if LastIteration = '21-5-4-10' then exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 14, 'BOX', 5.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, '', 100, 'WHITE', '');

        if LastIteration = '21-5-4-20' then exit;

        ItemChargeAssignSales.Init();
        ItemChargeAssignSales."Document Type" := ItemChargeAssignSales."Document Type"::Order;
        ItemChargeAssignSales."Document No." := SalesLine."Document No.";
        ItemChargeAssignSales."Document Line No." := SalesLine."Line No.";
        ItemChargeAssignSales."Line No." := 10000;
        ItemChargeAssignSales."Item Charge No." := 'UPS';
        ItemChargeAssignSales."Item No." := '80100';
        ItemChargeAssignSales."Applies-to Doc. Type" := ItemChargeAssignSales."Applies-to Doc. Type"::Order;
        ItemChargeAssignSales."Applies-to Doc. No." := SalesLine."Document No.";
        ItemChargeAssignSales."Applies-to Doc. Line No." := 10000;
        ItemChargeAssignSales.Validate("Qty. to Assign", 1);
        ItemChargeAssignSales."Unit Cost" := 100;
        ItemChargeAssignSales."Amount to Assign" := 100;
        ItemChargeAssignSales.Insert(true);

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-5-4-30' then exit;

        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-5-4-40' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-5-4-50' then exit;
        // 21-5-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '21-5-5-10' then exit;
        // 21-5-6
        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-5-6-10' then exit;
        // 21-5-7
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '21-5-7-10' then exit;
        // 21-5-8
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 8, LastILENo);

        if LastIteration = '21-5-8-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase10()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CrossDockOpp: Record "Whse. Cross-Dock Opportunity";
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-10-1-10' then exit;
        // 21-10-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '70000', '', 45, 'PCS', 30.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80002', '', 75, 'PCS', 650.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A_TEST', '12', 7, 'PCS', 10.7, 'WHITE', '');
        if LastIteration = '21-10-2-10' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-10-2-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '62000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'White', 'TCS21-10-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'White', 100, 'PCS', 470, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '70000', '', 'WHITE', 50, 'PCS', 4.7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 10, 'PCS', 3.7, false);

        if LastIteration = '21-10-2-30' then exit;

        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT01', 50, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT02', 25, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT03', 25, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);

        if LastIteration = '21-10-2-40' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-10-2-50' then exit;

        Clear(WhseRcptLine);
        WhseRcptLine.SetRange("No.", 'RE000001');
        WhseRcptLine.SetRange("Line No.", 20000);
        if WhseRcptLine.Find('-') then
            WhseRcptLine.Delete();

        if LastIteration = '21-10-2-60' then exit;

        CrossDockMgt.CalculateCrossDockLines(CrossDockOpp, '', 'RE000001', 'WHITE');

        if LastIteration = '21-10-2-70' then exit;

        CrossDockOpp.SetRange("Source Name/No.", 'RE000001');
        CrossDockOpp.SetRange("Source Line No.", 10000);
        CrossDockOpp.Find('-');
        CrossDockOpp.AutoFillQtyToCrossDock(CrossDockOpp);

        CrossDockOpp.SetRange("Source Name/No.", 'RE000001');
        CrossDockOpp.SetRange("Source Line No.", 30000);
        CrossDockOpp.Find('-');
        CrossDockOpp.AutoFillQtyToCrossDock(CrossDockOpp);

        if LastIteration = '21-10-2-80' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-10-2-90' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-10-2-100' then exit;
        // 21-10-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-10-3-10' then exit;
        // 21-10-4
        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', '', '');
        WhseRcptHeader.Validate("Location Code");
        WhseRcptHeader.Validate("Posting Date", 20011127D);
        WhseRcptHeader.Modify();
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-10-4-10' then exit;

        CrossDockMgt.CalculateCrossDockLines(CrossDockOpp, '', 'RE000002', 'WHITE');

        if LastIteration = '21-10-4-20' then exit;

        CrossDockOpp.SetRange("Source Name/No.", 'RE000002');
        CrossDockOpp.SetRange("Source Line No.", 10000);
        CrossDockOpp.Find('-');
        CrossDockOpp.AutoFillQtyToCrossDock(CrossDockOpp);

        if LastIteration = '21-10-4-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-10-4-40' then exit;

        Clear(WhseActivLine);
        i := 0;
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.SetRange("Action Type");
                i := i + 1;
                if i < 3 then begin
                    WhseActivLine.Validate("Qty. to Handle", 45);
                    WhseActivLine.Modify();
                end else
                    WhseActivLine.Delete();
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-10-4-50' then exit;

        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-10-4-60' then exit;
        // 21-10-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '21-10-5-10' then exit;
        // 21-10-6
        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-10-6-10' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Qty. to Handle", 50);
                WhseActivLine.Validate("Lot No.", 'LOT01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-10-6-20' then exit;
        //Split lines in pick
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Item No.", '80002');
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SplitLine(WhseActivLine);
            WhseActivLine.Find('+');
            WhseActivLine.Validate("Bin Code", 'W-14-0001');
            WhseActivLine.Validate("Lot No.", 'LOT02');
            WhseActivLine.Modify(true);
        end;
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SplitLine(WhseActivLine);
            WhseActivLine.Find('+');
            WhseActivLine.Validate("Lot No.", 'LOT02');
            WhseActivLine.Modify(true);
        end;

        if LastIteration = '21-10-6-30' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-10-6-40' then exit;

        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '21-10-6-50' then exit;
        // 21-10-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '21-10-7-10' then exit;
        // 21-10-8
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 65, 'PCS', 650.7, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-10-8-10' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '62000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'White', 'TCS21-10-8', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'White', 100, 'PCS', 470, false);

        if LastIteration = '21-10-8-20' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 1, 100, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT04', 0D, 0D);

        if LastIteration = '21-10-8-30' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-10-8-40' then exit;

        CrossDockMgt.CalculateCrossDockLines(CrossDockOpp, '', 'RE000003', 'WHITE');

        if LastIteration = '21-10-8-50' then exit;

        CrossDockOpp.SetRange("Source Name/No.", 'RE000003');
        CrossDockOpp.SetRange("Source Line No.", 10000);
        CrossDockOpp.Find('-');
        CrossDockOpp.AutoFillQtyToCrossDock(CrossDockOpp);

        if LastIteration = '21-10-8-60' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-10-8-70' then exit;
        // 21-10-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '21-10-9-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase11()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-11-1-10' then exit;
        // 21-11-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Quote, '62000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-11-2', false);
        PurchHeader.Validate("Requested Receipt Date", 20011127D);
        PurchHeader.Modify();

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'WHITE', 200, 'PCS', 750, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 100, 'PCS', 15.7, false);

        if LastIteration = '21-11-2-10' then exit;
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT01', 40, 1, "Reservation Status"::Prospect, 39, 0, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT02', 40, 1, "Reservation Status"::Prospect, 39, 0, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT03', 40, 1, "Reservation Status"::Prospect, 39, 0, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT04', 40, 1, "Reservation Status"::Prospect, 39, 0, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOT05', 40, 1, "Reservation Status"::Prospect, 39, 0, PurchHeader."No.", '', 0, 10000, true);

        if LastIteration = '21-11-2-20' then exit;

        Clear(PurchQuoteToOrder);
        PurchQuoteToOrder.Run(PurchHeader);

        PurchQuoteToOrder.GetPurchOrderHeader(PurchHeader);

        if LastIteration = '21-11-2-30' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-11-2-40' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-11-2-50' then exit;
        // 21-11-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-11-3-10' then exit;
        // 21-11-4
        WhseRcptLine.SetRange("Line No.", 20000);
        WhseRcptLine.Find('-');
        WhseRcptLine.Validate("Qty. to Receive", 0);
        WhseRcptLine.Modify();

        if LastIteration = '21-11-4-10' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-11-4-20' then exit;
        // 21-11-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '21-11-5-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase12()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        SalesBlanketOrderToOrder: Codeunit "Blanket Sales Order to Order";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-12-1-10' then exit;

        Item.SetFilter("No.", '%1|%2|%3', 'A_TEST', 'T_TEST', '80002');
        Item.ModifyAll(Reserve, Item.Reserve::Always);

        if LastIteration = '21-12-1-20' then exit;
        // 21-12-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '62000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-12-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'WHITE', 200, 'PCS', 750, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 100, 'PCS', 15.7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 5, 'BOX', 5.7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B_TEST', '21', 'WHITE', 100, 'PCS', 25.7, false);

        if LastIteration = '21-12-2-10' then exit;

        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOTNUMBER01', 40, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOTNUMBER02', 40, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOTNUMBER03', 40, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOTNUMBER04', 40, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LOTNUMBER05', 40, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);

        if LastIteration = '21-12-2-20' then exit;

        TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T1', 'WHITE', 'SERIALN0001', '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 30000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T1', 'WHITE', 'SERIALN0002', '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 30000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T1', 'WHITE', 'SERIALN0003', '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 30000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T1', 'WHITE', 'SERIALN0004', '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 30000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T1', 'WHITE', 'SERIALN0005', '', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 30000, true);

        if LastIteration = '21-12-2-30' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-12-2-40' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-12-2-50' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.SetFilter("Line No.", '>%1', 20000);
        WhseRcptLine.ModifyAll("Qty. to Receive", 0);

        if LastIteration = '21-12-2-60' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-12-2-70' then exit;
        // 21-12-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-12-3-10' then exit;
        // 21-12-4
        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        WhseRcptLine.AutofillQtyToReceive(WhseRcptLine);
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-12-4-10' then exit;

        WhseActivLine.SetFilter("Lot No.", '<>%1', '');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.");
            until WhseActivLine.Next() = 0;
        WhseActivLine.Reset();
        WhseActivLine.SetFilter("Serial No.", '<>%1', '');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Serial No.");
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-12-4-20' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-12-4-30' then exit;
        // 21-12-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '21-12-5-10' then exit;
        // 21-12-6
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '62000', 20011130D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011130D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 500, 'PCS', 1150.2, 'WHITE', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 80, 80, 1150.2, 0, false);
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_TEST', '12', 500, 'PCS', 101.2, 'WHITE', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 30, 30, 101.2, 0, false);
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_TEST', '21', 500, 'PCS', 91.2, 'WHITE', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 10, 10, 91.2, 0, false);
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'T_TEST', 'T1', 500, 'BOX', 111.2, 'WHITE', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 2, 2, 111.2, 0, false);

        if LastIteration = '21-12-6-10' then exit;

        Clear(SalesBlanketOrderToOrder);
        SalesBlanketOrderToOrder.Run(SalesHeader);

        SalesBlanketOrderToOrder.GetSalesOrderHeader(SalesHeader);

        if LastIteration = '21-12-6-20' then exit;
        // 21-12-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '21-12-7-10' then exit;
        // 21-12-8
        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-12-8-10' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-12-8-20' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-12-8-30' then exit;

        i := 0;
        SNCode := 'SERIALN0000';
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        if WhseActivLine.Find('+') then
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next(-1) = 0;
        WhseActivLine.SetRange("Item No.", '80002');
        WhseActivLine.SetRange("Qty. to Handle", 80);
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Qty. to Handle", 40);
                WhseActivLine.SplitLine(WhseActivLine);
                WhseActivLine.Validate("Lot No.", 'LOTNUMBER02');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.SetRange("Qty. to Handle");
        WhseActivLine.SetRange("Lot No.", '');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LOTNUMBER01');
                if WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take then
                    WhseActivLine.Validate("Bin Code", 'W-04-0001');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-12-8-40' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-12-8-50' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('+');
        WhseShptLine.Validate("Qty. to Ship", 0);
        WhseShptLine.Modify();

        if LastIteration = '21-12-8-60' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '21-12-8-70' then exit;
        // 21-12-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '21-12-9-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase13()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ResEntry: Record "Reservation Entry";
        WhseActivLine: Record "Warehouse Activity Line";
        CombShpts: Report "Combine Shipments";
        DelInvSalesOrders: Report "Delete Invoiced Sales Orders";
        ResMgmt: Codeunit "Reservation Management";
        SNCode: Code[20];
        AutoReserv: Boolean;
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-13-1-10' then exit;

        Item.SetFilter("No.", '%1|%2', 'T_TEST', '80002');
        Item.ModifyAll("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");

        if LastIteration = '21-13-1-20' then exit;
        // 21-13-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '62000', 20011120D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011120D, 'WHITE', 'TCS21-13-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'WHITE', 20, 'PCS', 470, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 20, 20, 470.0, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 5, 'BOX', 4.7, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 5, 5, 4.7, 0);

        if LastIteration = '21-13-2-10' then exit;

        ResEntry.FindFirst();
        ResEntry.Validate("Lot No.", 'LOT01');
        ResEntry.Validate("Quantity (Base)");
        ResEntry."Item Tracking" := ResEntry."Item Tracking"::"Lot No.";
        ResEntry.Modify();

        if LastIteration = '21-13-2-20' then exit;

        ResEntry.Next();
        ResEntry.Validate("Serial No.", 'SN05');
        ResEntry.Validate("Lot No.", 'X1');
        ResEntry.Validate("Quantity (Base)", 1);
        ResEntry."Item Tracking" := ResEntry."Item Tracking"::"Lot and Serial No.";
        ResEntry.Modify();

        SNCode := 'SN00';
        for i := 1 to 4 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine('T_TEST', 'T1', 'WHITE', SNCode, 'X1', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        end;

        if LastIteration = '21-13-2-30' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_TEST', 'T1', 2, 'BOX', 30.7, 'WHITE', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 2, 2, 30.7, 0, false);
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80002', '', 10, 'PCS', 1370, 'WHITE', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 10, 10, 1370, 0, false);

        if LastIteration = '21-13-2-40' then exit;

        SalesLine.Reset();
        if SalesLine.Find('-') then
            repeat
                ResMgmt.SetReservSource(SalesLine);
                ResMgmt.AutoReserve(AutoReserv, '', 20011125D, SalesLine.Quantity, SalesLine."Quantity (Base)");
            until SalesLine.Next() = 0;

        if LastIteration = '21-13-2-50' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-13-2-60' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-13-2-70' then exit;

        PurchLine.Reset();
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.ModifyAll("Expected Receipt Date", 20011124D);

        if LastIteration = '21-13-2-80' then exit;
        // 21-13-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-13-3-10' then exit;
        // 21-13-4
        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '21-13-4-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-13-4-20' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-13-4-30' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-13-4-40' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-13-4-50' then exit;

        Clear(WhseActivLine);
        SNCode := 'SN00';
        i := 0;
        WhseActivLine.SetRange("Item No.", 'T_Test');
        if WhseActivLine.Find('-') then
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode)
                else
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Validate("Lot No.", 'X1');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LOT01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-13-4-60' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '21-13-4-70' then exit;
        // 21-13-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '21-13-5-10' then exit;
        // 21-13-6
        Clear(CombShpts);
        CombShpts.InitializeRequest(20011125D, 20011125D, false, false, false, false);
        CombShpts.SetHideDialog(true);
        CombShpts.UseRequestPage(false);
        CombShpts.RunModal();

        if LastIteration = '21-13-6-10' then exit;

        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", 2);
        SalesHeader.Find('-');
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '21-13-6-20' then exit;

        Clear(DelInvSalesOrders);
        DelInvSalesOrders.UseRequestPage(false);
        DelInvSalesOrders.RunModal();

        if LastIteration = '21-13-6-30' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '21-13-6-40' then exit;

        Clear(SalesHeader);
        Clear(SalesLine);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011129D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_TEST', 'T1', 1, 'BOX', 30.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80002', '', 1, 'PCS', 1370, 'WHITE', '');

        if LastIteration = '21-13-6-50' then exit;

        SalesLine.Reset();
        if SalesLine.Find('-') then
            repeat
                ResMgmt.SetReservSource(SalesLine);
                ResMgmt.AutoReserve(AutoReserv, '', 20011125D, SalesLine.Quantity, SalesLine."Quantity (Base)");
            until SalesLine.Next() = 0;

        if LastIteration = '21-13-6-60' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '21-13-6-70' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-13-6-80' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-13-6-90' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Item No.", 'T_Test');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Serial No.", 'SN03');
                WhseActivLine.Validate("Lot No.", 'X1');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LOT01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-13-6-100' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '21-13-6-110' then exit;
        // 21-13-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '21-13-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase14()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        TransRoute: Record "Transfer Route";
        SKU: Record "Stockkeeping Unit";
        ReqWkshLine: Record "Requisition Line";
        Item: Record Item;
        CalcPlan: Report "Calculate Plan - Plan. Wksh.";
        CarryOut: Report "Carry Out Action Msg. - Req.";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-14-1-10' then exit;

        TransRoute.Init();
        TransRoute."Transfer-from Code" := 'BLUE';
        TransRoute."Transfer-to Code" := 'RED';
        TransRoute."In-Transit Code" := 'OWN LOG.';
        if not TransRoute.Insert() then
            TransRoute.Modify();
        TransRoute.Init();
        TransRoute."Transfer-from Code" := 'GREEN';
        TransRoute."Transfer-to Code" := 'WHITE';
        TransRoute."In-Transit Code" := 'OWN LOG.';
        if not TransRoute.Insert() then
            TransRoute.Modify();

        if LastIteration = '21-14-1-20' then exit;

        SKU.Init();
        SKU."Location Code" := 'WHITE';
        SKU."Item No." := 'T_TEST';
        SKU."Replenishment System" := SKU."Replenishment System"::Transfer;
        SKU."Transfer-from Code" := 'GREEN';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        SKU."Transfer-Level Code" := -1;
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'WHITE';
        SKU."Item No." := '80002';
        SKU."Replenishment System" := SKU."Replenishment System"::Transfer;
        SKU."Transfer-from Code" := 'GREEN';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        SKU."Transfer-Level Code" := -1;
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'GREEN';
        SKU."Item No." := 'T_TEST';
        SKU."Replenishment System" := SKU."Replenishment System"::" ";
        SKU."Vendor No." := '10000';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'GREEN';
        SKU."Item No." := '80002';
        SKU."Replenishment System" := SKU."Replenishment System"::" ";
        SKU."Vendor No." := '10000';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'BLUE';
        SKU."Item No." := 'A_TEST';
        SKU."Replenishment System" := SKU."Replenishment System"::" ";
        SKU."Vendor No." := '10000';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Maximum Qty.";
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'RED';
        SKU."Item No." := 'A_TEST';
        SKU."Replenishment System" := SKU."Replenishment System"::Transfer;
        SKU."Transfer-from Code" := 'BLUE';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Maximum Qty.";
        SKU."Transfer-Level Code" := -1;
        if not SKU.Insert() then
            SKU.Modify();

        if LastIteration = '21-14-1-30' then exit;
        // 21-14-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', '', 3, 'BOX', 30.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80002', '', 20, 'PCS', 1370, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', '', 7, 'BOX', 30.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80002', '', 80, 'PCS', 1370, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'RED', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 10, 'PCS', 3.7, 'RED', '');

        if LastIteration = '21-14-2-10' then exit;

        Item.SetFilter("Location Filter", '<>%1', '');
        CalcPlan.SetTemplAndWorksheet('REQ', 'DEFAULT', true);
        CalcPlan.InitializeRequest(20011125D, 20011125D, false);
        CalcPlan.SetTableView(Item);
        CalcPlan.UseRequestPage := false;
        CalcPlan.RunModal();

        if LastIteration = '21-14-2-20' then exit;

        ReqWkshLine."Worksheet Template Name" := 'REQ';
        ReqWkshLine."Journal Batch Name" := 'DEFAULT';
        CarryOut.SetReqWkshLine(ReqWkshLine);
        CarryOut.SetHideDialog(true);
        CarryOut.InitializeRequest(20011125D, 20011125D, 20011125D, 20011125D, '');
        CarryOut.UseRequestPage := false;
        CarryOut.Run();

        if LastIteration = '21-14-2-30' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('+');
        i := PurchLine."Line No." + 10000;
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, i, PurchLine.Type::Item, '70000', '', 'BLUE', 10, 'PCS', 8.2, false);

        if LastIteration = '21-14-2-40' then exit;

        PurchLine.SetRange(PurchLine."No.", 'T_TEST');
        PurchLine.FindFirst();
        SNCode := 'SN00';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            TestScriptMgmt.CreateItemTrackfromJnlLine(
              'T_TEST', '', 'GREEN', SNCode, 'X1', 1, 1, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, PurchLine."Line No.", true);
        end;

        if LastIteration = '21-14-2-50' then exit;

        PurchLine.SetRange(PurchLine."No.", '80002');
        PurchLine.FindFirst();

        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'GREEN', '', '', 39, 1, PurchHeader."No.", '', 0, PurchLine."Line No.", 1, 100, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LOT01', 0D, 0D);

        if LastIteration = '21-14-2-60' then exit;

        PurchLine.Reset();
        PurchLine.SetRange("Location Code", 'BLUE');
        if PurchLine.Find('-') then
            repeat
                PurchLine.Validate(Quantity);
                PurchLine.Modify();
            until PurchLine.Next() = 0;
        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '21-14-2-70' then exit;

        TransLine.Reset();
        TransLine.SetRange("Transfer-to Code", 'RED');
        TransLine.Find('+');
        TransLine."Line No." := TransLine."Line No." + 10000;
        TransLine.Validate("Item No.", '70000');
        TransLine.Validate(Quantity, 10);
        TransLine.Insert(true);

        if LastIteration = '21-14-2-80' then exit;

        TransHeader.Reset();
        TransHeader.SetRange("No.", TransLine."Document No.");
        TransHeader.Find('-');
        TestScriptMgmt.PostTransferOrder(TransHeader);
        TestScriptMgmt.PostTransferOrderRcpt(TransHeader);

        if LastIteration = '21-14-2-90' then exit;

        SalesHeader.Reset();
        SalesHeader.SetRange("Location Code", 'RED');
        SalesHeader.Find('-');
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '21-14-2-100' then exit;

        Clear(WhseRcptHeader);
        PurchHeader.Reset();
        PurchHeader.Find('-');
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'GREEN');

        if LastIteration = '21-14-2-110' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-14-2-120' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-14-2-130' then exit;

        TransLine.Reset();
        TransLine.SetRange("Transfer-to Code", 'WHITE');
        TransLine.FindFirst();
        TransHeader.Reset();
        TransHeader.SetRange("No.", TransLine."Document No.");
        TransHeader.FindSet();

        TestScriptMgmt.ReleaseTransferOrder(TransHeader);

        if LastIteration = '21-14-2-140' then exit;

        TestScriptMgmt.CreateWhseShptFromTrans(TransHeader, WhseShptHeader);

        if LastIteration = '21-14-2-150' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-14-2-160' then exit;

        Clear(WhseActivLine);
        SNCode := 'SN00';
        WhseActivLine.SetRange("Item No.", 'T_Test');
        if WhseActivLine.FindSet() then
            repeat
                SNCode := IncStr(SNCode);
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Validate("Lot No.", 'X1');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.FindSet() then
            repeat
                WhseActivLine.Validate("Lot No.", 'LOT01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.Reset();
        WhseActivLine.FindFirst();

        if LastIteration = '21-14-2-170' then exit;

        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-14-2-180' then exit;

        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '21-14-2-190' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');

        if LastIteration = '21-14-2-200' then exit;

        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'CUST30000');

        if LastIteration = '21-14-2-210' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-14-2-220' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-14-2-230' then exit;

        Clear(SalesHeader);
        SalesHeader.Reset();
        SalesHeader.SetRange("Sell-to Customer No.", '30000');
        SalesHeader.Find('-');
        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-14-2-240' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.SetRange("Location Code", 'WHITE');
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-14-2-250' then exit;

        SNCode := 'SN03';
        i := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        if WhseActivLine.Find('-') then
            repeat
                i := i + 1;
                if i = 1 then
                    SNCode := IncStr(SNCode);
                if i = 2 then
                    i := 0;
                WhseActivLine.Validate("Serial No.", SNCode);
                WhseActivLine.Validate("Lot No.", 'X1');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LOT01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '21-14-2-260' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-14-2-270' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '21-14-2-280' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader."Vendor Invoice No." := 'TCS21-14-2';
        PurchHeader.Modify();

        if LastIteration = '21-14-2-290' then exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '21-14-2-300' then exit;
        // 21-14-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-14-3-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase15()
    begin
        //commented out as the application was changed, you cannot run date compression automatically
        /*
        WITH TestScriptMgmt DO BEGIN
        // 21-15-1
        
          SetGlobalPreconditions;
        
          IF LastIteration = '21-15-1-10' THEN EXIT;
        
        // 21-15-2
        
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251001D);
          ModifyPurchHeader(PurchHeader,251001D,'WHITE','TCS21-15-2',FALSE);
        
          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','WHITE',200,'PCS',750,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','12','WHITE',100,'PCS',15.70,FALSE);
        
          IF LastIteration = '21-15-2-10' THEN EXIT;
        
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT01',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT02',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT03',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT04',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT05',0D,0D);
        
          IF LastIteration = '21-15-2-20' THEN EXIT;
        
          ReleasePurchDocument(PurchHeader);
        
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
        
          IF LastIteration = '21-15-2-30' THEN EXIT;
        
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
        
          //Register put-away
          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-15-2-40' THEN EXIT;
        
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',011101D);
          ModifySalesHeader(SalesHeader,011101D,'WHITE',TRUE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80002','',75,'PCS',1150.20,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'A_TEST','12',30,'PCS',101.2,'WHITE','');
           END;
        
          IF LastIteration = '21-15-2-50' THEN EXIT;
        
          //Assign IT info
          InsertResEntry(ResEntry,'WHITE',10000,3,011101D,'80002','','','LOT01',40,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'WHITE',10000,3,011101D,'80002','','','LOT02',35,37,1,SalesHeader."No.",'',10000,TRUE);
        
          IF LastIteration = '21-15-2-60' THEN EXIT;
        
          ReleaseSalesDocument(SalesHeader);
        
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');
        
          IF LastIteration = '21-15-2-70' THEN EXIT;
        
          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);
        
          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-15-2-80' THEN EXIT;
        
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);
        
          IF LastIteration = '21-15-2-90' THEN EXIT;
        
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'20000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS21-15-2-B',FALSE);
        
          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','WHITE',100,'PCS',750,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','12','WHITE',50,'PCS',15.70,FALSE);
        
          IF LastIteration = '21-15-2-100' THEN EXIT;
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT06',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT07',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT08',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT09',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT10',0D,0D);
        
          IF LastIteration = '21-15-2-110' THEN EXIT;
        
          ReleasePurchDocument(PurchHeader);
        
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
        
          IF LastIteration = '21-15-2-120' THEN EXIT;
        
          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
        
          //Register put-away
          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-15-2-130' THEN EXIT;
        
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'62000',301101D);
          ModifySalesHeader(SalesHeader,301101D,'WHITE',TRUE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80002','',100,'PCS',1150.20,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'A_TEST','12',30,'PCS',101.2,'WHITE','');
           END;
        
          IF LastIteration = '21-15-2-140' THEN EXIT;
        
          //Assign IT info
          InsertResEntry(ResEntry,'WHITE',10000,3,301101D,'80002','','','LOT03',40,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'WHITE',10000,3,301101D,'80002','','','LOT04',40,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'WHITE',10000,3,301101D,'80002','','','LOT10',20,37,1,SalesHeader."No.",'',10000,TRUE);
        
          IF LastIteration = '21-15-2-150' THEN EXIT;
        
          ReleaseSalesDocument(SalesHeader);
        
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');
        
          IF LastIteration = '21-15-2-160' THEN EXIT;
        
          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);
        
          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-15-2-170' THEN EXIT;
        
          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);
        
          IF LastIteration = '21-15-2-180' THEN EXIT;
        
        // 21-15-3
        
          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);
        
          IF LastIteration = '21-15-3-10' THEN EXIT;
        
        // 21-15-4
          CLEAR(DateCompILE);
          CLEAR(EntrdDateComprReg);
          ILE.Reset();
          ILE.SETRANGE("Item No.",'80002');
          EntrdDateComprReg."Period Length" := 3;
          EntrdDateComprReg."Starting Date" := 010101D;
          EntrdDateComprReg."Ending Date" := 151201D;
          DateCompILE.SetHideDialog(TRUE);
          DateCompILE.InitializeReport(EntrdDateComprReg);
          DateCompILE.SETTABLEVIEW(ILE);
          DateCompILE.USEREQUESTPAGE(FALSE);
          DateCompILE.Run();
        
          IF LastIteration = '21-15-4-10' THEN EXIT;
        
          CLEAR(DateCompWE);
          WE.Reset();
          WE.SETRANGE("Item No.",'80002');
          EntrdDateComprReg."Period Length" := 3;
          EntrdDateComprReg."Starting Date" := 010101D;
          EntrdDateComprReg."Ending Date" := 151201D;
          DateCompWE.SetHideDialog(TRUE);
          DateCompWE.InitializeReport(EntrdDateComprReg,FALSE,FALSE);
          DateCompWE.SETTABLEVIEW(WE);
          DateCompWE.USEREQUESTPAGE(FALSE);
          DateCompWE.Run();
        
          IF LastIteration = '21-15-4-20' THEN EXIT;
        
        // 21-15-5
        
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);
        
          IF LastIteration = '21-15-5-10' THEN EXIT;
          Commit();
        
        END;
        */

    end;

    [Scope('OnPrem')]
    procedure PerformTestCase16()
    begin
        //commented out as the application was changed, you cannot run date compression automatically
        /*
        WITH TestScriptMgmt DO BEGIN
        // 21-16-1
        
          SetGlobalPreconditions;
        
          IF LastIteration = '21-16-1-10' THEN EXIT;
        
        // 21-16-2
        
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251001D);
          ModifyPurchHeader(PurchHeader,251001D,'WHITE','TCS21-16-2',FALSE);
        
          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','WHITE',200,'PCS',750,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','12','WHITE',100,'PCS',15.70,FALSE);
        
          IF LastIteration = '21-16-2-10' THEN EXIT;
        
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT01',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT02',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT03',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT04',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,40,'','');
          InsertItemTrkgInfo(251101D,'','LOT05',0D,0D);
        
          IF LastIteration = '21-16-2-20' THEN EXIT;
        
          ReleasePurchDocument(PurchHeader);
        
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
        
          IF LastIteration = '21-16-2-30' THEN EXIT;
        
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
        
          //Register put-away
          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-16-2-40' THEN EXIT;
        
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',011101D);
          ModifySalesHeader(SalesHeader,011101D,'WHITE',TRUE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80002','',75,'PCS',1150.20,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'A_TEST','12',30,'PCS',101.2,'WHITE','');
           END;
        
          IF LastIteration = '21-16-2-50' THEN EXIT;
        
          //Assign IT info
          InsertResEntry(ResEntry,'WHITE',10000,3,011101D,'80002','','','LOT01',40,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'WHITE',10000,3,011101D,'80002','','','LOT02',35,37,1,SalesHeader."No.",'',10000,TRUE);
        
          IF LastIteration = '21-16-2-60' THEN EXIT;
        
          ReleaseSalesDocument(SalesHeader);
        
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');
        
          IF LastIteration = '21-16-2-70' THEN EXIT;
        
          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);
        
          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-16-2-80' THEN EXIT;
        
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);
        
          IF LastIteration = '21-16-2-90' THEN EXIT;
        
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'20000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS21-16-2-B',FALSE);
        
          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','WHITE',100,'PCS',750,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','12','WHITE',50,'PCS',15.70,FALSE);
        
          IF LastIteration = '21-16-2-100' THEN EXIT;
        
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT06',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT07',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT08',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT09',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,20,'','');
          InsertItemTrkgInfo(251101D,'','LOT10',0D,0D);
        
          IF LastIteration = '21-16-2-110' THEN EXIT;
        
          ReleasePurchDocument(PurchHeader);
        
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
        
          IF LastIteration = '21-16-2-120' THEN EXIT;
        
          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
        
          //Register put-away
          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-16-2-130' THEN EXIT;
        
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'62000',301101D);
          ModifySalesHeader(SalesHeader,301101D,'WHITE',TRUE,FALSE);
        
          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80002','',100,'PCS',1150.20,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'A_TEST','12',30,'PCS',101.2,'WHITE','');
           END;
        
          IF LastIteration = '21-16-2-140' THEN EXIT;
        
          //Assign IT info
          InsertResEntry(ResEntry,'WHITE',10000,3,301101D,'80002','','','LOT03',40,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'WHITE',10000,3,301101D,'80002','','','LOT04',40,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'WHITE',10000,3,301101D,'80002','','','LOT10',20,37,1,SalesHeader."No.",'',10000,TRUE);
        
          IF LastIteration = '21-16-2-150' THEN EXIT;
        
          ReleaseSalesDocument(SalesHeader);
        
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');
        
          IF LastIteration = '21-16-2-160' THEN EXIT;
        
          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);
        
          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
        
          IF LastIteration = '21-16-2-170' THEN EXIT;
        
          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);
        
          IF LastIteration = '21-16-2-180' THEN EXIT;
        
        // 21-16-3
        
          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);
        
          IF LastIteration = '21-16-3-10' THEN EXIT;
        
        // 21-16-4
          CLEAR(DateCompILE);
          CLEAR(EntrdDateComprReg);
          ILE.Reset();
          ILE.SETRANGE("Item No.",'80002');
          EntrdDateComprReg."Period Length" := 3;
          EntrdDateComprReg."Starting Date" := 010101D;
          EntrdDateComprReg."Ending Date" := 151201D;
          DateCompILE.SetHideDialog(TRUE);
          DateCompILE.InitializeReport(EntrdDateComprReg);
          DateCompILE.SETTABLEVIEW(ILE);
          DateCompILE.USEREQUESTPAGE(FALSE);
          DateCompILE.Run();
        
          IF LastIteration = '21-16-4-10' THEN EXIT;
        
          CLEAR(DateCompWE);
          WE.Reset();
          WE.SETRANGE("Item No.",'80002');
          EntrdDateComprReg."Period Length" := 3;
          EntrdDateComprReg."Starting Date" := 010101D;
          EntrdDateComprReg."Ending Date" := 151201D;
          DateCompWE.SetHideDialog(TRUE);
          DateCompWE.InitializeReport(EntrdDateComprReg,FALSE,TRUE);
          DateCompWE.SETTABLEVIEW(WE);
          DateCompWE.USEREQUESTPAGE(FALSE);
          DateCompWE.Run();
        
          IF LastIteration = '21-16-4-20' THEN EXIT;
        
        // 21-16-5
        
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);
        
          IF LastIteration = '21-16-5-10' THEN EXIT;
          Commit();
        
        END;
        */

    end;

    [Scope('OnPrem')]
    procedure PerformTestCase17()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '21-17-1-10' then exit;
        // 21-17-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '62000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS21-17-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 50, 'PCS', 750, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 50, 'PCS', 15.7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_TEST', '', 'WHITE', 50, 'PCS', 5.7, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B_TEST', '21', 'WHITE', 50, 'PCS', 25.7, false);

        if LastIteration = '21-17-2-10' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '21-17-2-20' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.SetFilter("Line No.", '>%1', 10000);
        WhseRcptLine.ModifyAll("Qty. to Receive", 0);

        if LastIteration = '21-17-2-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '21-17-2-40' then exit;
        // 21-17-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '21-17-3-10' then exit;
        // 21-17-4
        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        WhseRcptLine.AutofillQtyToReceive(WhseRcptLine);
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-17-4-10' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '62000', 20011130D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011130D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_TEST', '12', 10, 'PCS', 1150.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_TEST', '12', 5, 'PCS', 101.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_TEST', '21', 5, 'PCS', 91.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'A_TEST', '12', 7, 'PCS', 1150.2, 'WHITE', '');

        if LastIteration = '21-17-4-20' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '21-17-4-30' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '21-17-4-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '21-17-4-50' then exit;

        WhseShptLine.Reset();
        WhseShptLine.SetFilter("Line No.", '<>%1', 10000);
        WhseShptLine.ModifyAll("Qty. to Ship", 0);

        if LastIteration = '21-17-4-60' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '21-17-4-70' then exit;
        // 21-17-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '21-17-5-10' then exit;
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

