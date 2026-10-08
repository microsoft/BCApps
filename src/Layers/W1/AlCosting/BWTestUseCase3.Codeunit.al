codeunit 103353 "BW Test Use Case 3"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 3");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103353, 3, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        GenPostSetup: Record "General Posting Setup";
        TestCase: Record "Whse. Test Case";
        ResEntry: Record "Reservation Entry";
        UseCase: Record "Whse. Use Case";
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
            4:
                PerformTestCase4();
            5:
                PerformTestCase5();
            6:
                PerformTestCase6();
            7:
                PerformTestCase7();
            12:
                PerformTestCase12();
            13:
                PerformTestCase13();
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
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        Loc.Get('BLUE');
        Loc."Bin Mandatory" := true;
        Loc.Modify();

        if LastIteration = '3-1-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-1-1', 'A_TEST', '', 'BLUE', '',
          30, 'PCS', 17, 0, 'A1');

        if LastIteration = '3-1-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-1-1-30' then
            exit;
        // 3-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS3-1-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '', 'BLUE', 10, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 'A1', 10, 10, 0, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '', 'BLUE', -3, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 20000, 'NONEED');
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 'A1', -3, -3, 0, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_Test', '', 'BLUE', -3, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 30000, 'NONEED');
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 'A1', -3, -3, 0, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'A_Test', '', 'BLUE', -1, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 40000, 'NONEED');
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 'A1', -1, -1, 0, 0);

        if LastIteration = '3-1-2-10' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '3-1-2-20' then
            exit;

        PurchHeader.Invoice := true;
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '3-1-2-30' then
            exit;
        // 3-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-1-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ResMgmt: Codeunit "Reservation Management";
        AutoReserv: Boolean;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '3-2-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-2-1', 'S_TEST', '42', 'SILVER', '',
          10, 'PALLET', 48, 0, 'S-02-0001');

        if LastIteration = '3-2-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-2-1-30' then
            exit;
        // 3-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchCrMemoHeader(PurchHeader, 20011125D, 'SILVER', 'TCS3-2-2');

        TestScriptMgmt.InsertPurchCrMemoLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'S_Test', '42', 31, 'PCS', 12, 0);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 10000, 'DAMAGED');
        TestScriptMgmt.ModifyPurchCrMemoLine(PurchHeader, 10000, 'S-02-0001', 11, 11);

        if LastIteration = '3-2-2-10' then
            exit;
        // 3-2-3
        ResMgmt.SetReservSource(PurchLine);
        ResMgmt.AutoReserve(AutoReserv, '', 20011125D, PurchLine.Quantity, PurchLine."Quantity (Base)");

        if LastIteration = '3-2-3-10' then
            exit;
        // 3-2-4
        PurchHeader.Invoice := true;
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '3-2-4-10' then
            exit;
        // 3-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '3-2-5-10' then
            exit;
        // 3-2-6
        TestScriptMgmt.ModifyPurchCrMemoLine(PurchHeader, 10000, 'S-02-0001', 2, 2);

        if LastIteration = '3-2-6-10' then
            exit;

        TestScriptMgmt.ModifyPurchCrMemoHeader(PurchHeader, 0D, '', 'TCS3-2-6');
        PurchHeader.Invoice := true;
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '3-2-6-20' then
            exit;
        // 3-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '3-2-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        GenPostSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Purch. Credit Memo Account", '7130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '3-3-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-3-1', 'T_TEST', '', 'SILVER', '',
          2, 'BOX', 80, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-3-1', 'L_TEST', '', 'SILVER', '',
          1, 'BOX', 60, 0, 'S-02-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-3-1', 'A_TEST', '12', 'SILVER', '',
          10, 'PCS', 55, 0, 'S-01-0001');

        if LastIteration = '3-3-1-20' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10001, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10001, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10001, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10001, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10002, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10002, true);

        if LastIteration = '3-3-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-3-1-40' then
            exit;
        // 3-3-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchCrMemoHeader(PurchHeader, 20011125D, 'SILVER', 'TCS3-3-2');

        TestScriptMgmt.InsertPurchCrMemoLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_Test', '', 2, 'BOX', 80, 0);
        TestScriptMgmt.ModifyPurchCrMemoLine(PurchHeader, 10000, 'S-02-0001', 2, 2);
        TestScriptMgmt.InsertPurchCrMemoLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'L_Test', '', 1, 'BOX', 80, 0);
        TestScriptMgmt.ModifyPurchCrMemoLine(PurchHeader, 20000, 'S-02-0002', 1, 1);
        TestScriptMgmt.InsertPurchCrMemoLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_Test', '12', 10, 'PCS', 55, 0);
        TestScriptMgmt.ModifyPurchCrMemoLine(PurchHeader, 30000, 'S-01-0001', 10, 10);
        TestScriptMgmt.InsertPurchCrMemoLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 3, '', 30, 0);

        if LastIteration = '3-3-2-10' then
            exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 10000, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 39, 3, PurchHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 10000, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN02', '', 1, 1, 39, 3, PurchHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 20000, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 39, 3, PurchHeader."No.", '', 20000, true);

        if LastIteration = '3-3-2-20' then
            exit;

        ItemChargeAssgntPurch.Init();
        ItemChargeAssgntPurch."Document Type" := PurchLine."Document Type";
        ItemChargeAssgntPurch."Document No." := PurchLine."Document No.";
        ItemChargeAssgntPurch."Document Line No." := 40000;
        ItemChargeAssgntPurch."Item Charge No." := 'INSURANCE';
        ItemChargeAssignt.CreateDocChargeAssgnt(ItemChargeAssgntPurch, PurchLine."Receipt No.");
        PurchLine.UpdateItemChargeAssgnt();
        ItemChargeAssignt.AssignItemCharges(PurchLine, 3, 90, 1);

        if LastIteration = '3-3-2-30' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '3-3-2-40' then
            exit;

        PurchHeader.Invoice := true;
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '3-3-2-50' then
            exit;
        // 3-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-3-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Sales Account", '6130');
            GenPostSetup.Modify();
        end;

        Loc.Get('SILVER');
        Loc."Require Shipment" := true;
        Loc.Modify();

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-4-1', 'C_TEST', '31', 'SILVER', '', 7, 'PCS', 16, 0, 'S-01-0001');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-4-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-4-1', 'C_TEST', '31', 'SILVER', '', 7, 'PCS', 16, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-4-1', 'L_TEST', '', 'SILVER', '', 2, 'BOX', 44, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-4-1', 'T_TEST', '', 'SILVER', '', 1, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '3-4-1-20' then
            exit;

        ItemJnlLineNo := 0;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10002, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10002, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10002, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10002, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10003, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10003, true);

        if LastIteration = '3-4-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-4-1-40' then
            exit;
        // 3-4-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'L_Test', '', 2, 'BOX', 44, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 'S-02-0001', 2, 2, 0, 0, false);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', '', 1, 'BOX', 45, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 'S-02-0003', 1, 1, 0, 0, false);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'C_Test', '31', 5, 'PCS', 16, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 'S-01-0001', 5, 5, 0, 0, false);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, '', 25, 'SILVER', '');

        if LastIteration = '3-4-2-10' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10000, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 37, 1, SalesHeader."No.", '', 10000, true);
        // Bug 254185 - set item tracking only for one PCS as one only will be shipped
        // InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'L_TEST','','','LN02',1,37,1,SalesHeader."No.",'',10000,TRUE);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 20000, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 37, 1, SalesHeader."No.", '', 20000, true);

        if LastIteration = '3-4-2-20' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '3-4-2-30' then
            exit;

        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, 'SILVER', '', '');

        if LastIteration = '3-4-2-40' then
            exit;

        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'SILVER');

        if LastIteration = '3-4-2-50' then
            exit;

        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 2, LastILENo);

        if LastIteration = '3-4-2-60' then
            exit;

        WhseShptLine.Get(WhseShptHeader."No.", 10000);
        WhseShptLine.Validate("Qty. to Ship", 1);
        WhseShptLine.Modify(true);
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '3-4-2-70' then
            exit;
        // 3-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-4-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '3-5-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-5-1', 'A_TEST', '', 'SILVER', '', 29, 'PCS', 29, 0, 'S-01-0001');

        if LastIteration = '3-5-1-20' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-5-1-30' then
            exit;
        // 3-5-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 10, 'PCS', 29, 'SILVER', '');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 10000, 'S-01-0001', 10, 10, 0, 0, 0);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '', -8, 'PCS', 29, 'SILVER', '');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 20000, 'S-01-0001', -8, -8, 0, 0, 0);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A_Test', '', -1, 'PCS', 29, 'SILVER', '');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 30000, 'S-01-0001', -1, -1, 0, 0, 0);

        if LastIteration = '3-5-2-10' then
            exit;

        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '3-5-2-20' then
            exit;
        // 3-5-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-5-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    var
        GenPostSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Sales Credit Memo Account", '6130');
            GenPostSetup.Modify();
        end;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-4-1', 'C_TEST', '31', 'SILVER', '', 7, 'PCS', 16, 0, 'S-01-0001');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-6-1-10' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-6-1', 'C_TEST', '32', 'SILVER', '', 20, 'PCS', 21, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-6-1', 'L_TEST', '', 'SILVER', '', 2, 'BOX', 40, 0, 'S-01-0002');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-6-1', 'T_TEST', '', 'SILVER', '', 1, 'BOX', 43, 0, 'S-01-0003');

        if LastIteration = '3-6-1-20' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10002, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10002, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10002, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10002, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10003, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10003, true);

        if LastIteration = '3-6-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-6-1-40' then
            exit;
        // 3-6-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', '', -1, 'BOX', 43, 'SILVER', '');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 10000, 'S-01-0003', -1, -1, 0, 0, 0);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'L_Test', '', -2, 'BOX', 40, 'SILVER', '');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 20000, 'S-01-0002', -2, -2, 0, 0, 0);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'C_Test', '32', -3, '', 30, 'SILVER', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::"Charge (Item)", 'GPS', '', 3, '', 78.78, 'SILVER', '');

        if LastIteration = '3-6-2-10' then
            exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 10000, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', -1, -1, 37, 3, SalesHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 20000, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', -1, -1, 37, 3, SalesHeader."No.", '', 20000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 20000, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', -1, -1, 37, 3, SalesHeader."No.", '', 20000, true);

        if LastIteration = '3-6-2-20' then
            exit;

        ItemChargeAssgntSales.Init();
        ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
        ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
        ItemChargeAssgntSales."Document Line No." := 40000;
        ItemChargeAssgntSales."Item Charge No." := 'GPS';
        ItemChargeAssignt.CreateDocChargeAssgn(ItemChargeAssgntSales, SalesLine."Shipment No.");
        SalesLine.UpdateItemChargeAssgnt();
        ItemChargeAssignt.AssignItemCharges(SalesLine, 3, 236.34, 1);

        if LastIteration = '3-6-2-30' then
            exit;

        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '3-6-2-30' then
            exit;
        // 3-6-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-6-3-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '3-7-1-10' then
            exit;
        // 3-7-2
        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-7-2', 'A_TEST', '', 'SILVER', '', 52, 'PCS', 14, 0, 'S-01-0001');

        if LastIteration = '3-7-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-7-2-20' then
            exit;
        // 3-7-3
        TestScriptMgmt.InsertTransferHeader(TransHeader, 'SILVER', 'RED', 'OWN LOG.', 20011125D);

        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 10000, 'A_TEST', '', 'PCS', 12, 0, 12);
        TestScriptMgmt.ModifyTransferLine(TransHeader."No.", 10000, 'S-01-0001', '', 12, 0);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 20000, 'A_TEST', '', 'PCS', 20, 0, 20);
        TestScriptMgmt.ModifyTransferLine(TransHeader."No.", 20000, 'S-01-0001', '', 20, 0);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 30000, 'A_TEST', '', 'PCS', 18, 0, 18);
        TestScriptMgmt.ModifyTransferLine(TransHeader."No.", 30000, 'S-01-0001', '', 18, 0);

        if LastIteration = '3-7-3-10' then
            exit;

        TestScriptMgmt.ReleaseTransferOrder(TransHeader);

        if LastIteration = '3-7-3-20' then
            exit;

        TestScriptMgmt.PostTransferOrder(TransHeader, true);

        if LastIteration = '3-7-3-30' then
            exit;
        // 3-7-4
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 4, LastILENo);

        if LastIteration = '3-7-4-10' then
            exit;
        // 3-7-5
        TestScriptMgmt.ModifyTransferLine(TransHeader."No.", 10000, 'S-01-0001', '', 0, 12);
        TestScriptMgmt.ModifyTransferLine(TransHeader."No.", 20000, 'S-01-0001', '', 0, 20);
        TestScriptMgmt.ModifyTransferLine(TransHeader."No.", 30000, 'S-01-0001', '', 0, 18);

        TestScriptMgmt.PostTransferOrder(TransHeader, false);

        if LastIteration = '3-7-5-10' then
            exit;
        // 3-7-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '3-7-6-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase12()
    var
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '3-12-1-10' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Pick" := true;
        Loc."Require Put-away" := true;
        Loc.Modify();

        if LastIteration = '3-12-1-20' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-12-1', 'A_TEST', '', 'SILVER', '',
          30, 'PCS', 17, 0, 'S-01-0001');

        if LastIteration = '3-12-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-12-1-40' then
            exit;
        // 3-12-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS3-12-2', false);

        if LastIteration = '3-12-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', 10, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 'S-01-0001', 10, 10, 0, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', -3, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 'S-01-0001', -3, -3, 0, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', -3, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 'S-01-0001', -3, -3, 0, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'A_Test', '', 'SILVER', -1, 'PCS', 17, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 'S-01-0001', -1, -1, 0, 0);

        if LastIteration = '3-12-2-20' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '3-12-2-30' then
            exit;

        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 5, 'SILVER');
        TestScriptMgmt.CreateInvPick(WhseActivHeader);

        if LastIteration = '3-12-2-40' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '3-12-2-50' then
            exit;
        // 3-12-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-12-3-10' then
            exit;
        // 3-12-4
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '3-12-4-10' then
            exit;

        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 4, 'SILVER');
        TestScriptMgmt.CreateInvPutAway(WhseActivHeader);

        if LastIteration = '3-12-4-20' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '3-12-4-30' then
            exit;

        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '3-12-4-40' then
            exit;

        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '3-12-4-50' then
            exit;
        // 3-12-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '3-12-5-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase13()
    var
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        ResMgmt: Codeunit "Reservation Management";
        AutoReserv: Boolean;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '3-13-1-10' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Pick" := true;
        Loc.Modify();

        if LastIteration = '3-13-1-20' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-13-1', 'S_TEST', '42', 'SILVER', '',
          10, 'PALLET', 48, 0, 'S-02-0001');

        if LastIteration = '3-13-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-13-1-40' then
            exit;
        // 3-13-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifyPurchCrMemoHeader(PurchHeader, 20011125D, 'SILVER', 'TCS3-13-2');

        if LastIteration = '3-13-2-10' then
            exit;

        TestScriptMgmt.InsertPurchCrMemoLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'S_Test', '42', 31, 'PCS', 12, 0);
        TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, 10000, 'DAMAGED');
        TestScriptMgmt.ModifyPurchCrMemoLine(PurchHeader, 10000, 'S-02-0001', 11, 11);

        if LastIteration = '3-13-2-20' then
            exit;
        // 3-13-3
        ResMgmt.SetReservSource(PurchLine);
        ResMgmt.AutoReserve(AutoReserv, '', 20011125D, PurchLine.Quantity, PurchLine."Quantity (Base)");

        if LastIteration = '3-13-3-10' then
            exit;
        // 3-13-4
        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '3-13-4-10' then
            exit;
        // 3-13-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '3-13-5-10' then
            exit;
        // 3-13-6
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Purchase Return Order", PurchHeader."No.");

        if LastIteration = '3-13-6-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '3-13-6-20' then
            exit;
        // 3-13-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '3-13-7-10' then
            exit;
        // 3-13-8
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '3-13-8-10' then
            exit;
        // 3-13-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '3-13-9-10' then
            exit;
        // 3-13-10
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 0D, '', '', true);

        if LastIteration = '3-13-10-10' then
            exit;

        TestScriptMgmt.ModifyPurchCrMemoHeader(PurchHeader, 0D, '', 'TCS3-13-10');
        TestScriptMgmt.ModifyPurchCrMemoLine(PurchHeader, 10000, 'S-02-0001', 2, 2);

        if LastIteration = '3-13-10-20' then
            exit;
        // 3-13-11
        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '3-13-11-10' then
            exit;
        // 3-13-12
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 12, LastILENo);

        if LastIteration = '3-13-12-10' then
            exit;
        // 3-13-13
        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 5, 'SILVER');
        TestScriptMgmt.CreateInvPick(WhseActivHeader);

        if LastIteration = '3-13-13-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '3-13-13-20' then
            exit;
        // 3-13-14
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 14, LastILENo);

        if LastIteration = '3-12-14-10' then
            exit;
        // 3-13-15
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '1-13-15-10' then
            exit;
        // 3-13-16
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 16, LastILENo);

        if LastIteration = '3-12-16-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase15()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '3-15-1-10' then
            exit;

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Sales Account", '6130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '3-15-1-20' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Pick" := true;
        Loc.Modify();

        ItemJnlLineNo := 1000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-13-1', 'S_TEST', '42', 'SILVER', '',
          10, 'PALLET', 48, 0, 'S-02-0001');

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-15-1-30' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-15-1', 'C_TEST', '31', 'SILVER', '', 7, 'PCS', 16, 0, 'S-01-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-15-1', 'L_TEST', '', 'SILVER', '', 2, 'BOX', 44, 0, 'S-02-0001');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-15-1', 'T_TEST', '', 'SILVER', '', 1, 'BOX', 45, 0, 'S-02-0003');

        if LastIteration = '3-15-1-40' then
            exit;

        ItemJnlLineNo := 0;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10002, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10002, true);
        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10002, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10002, true);

        if LastIteration = '3-15-1-50' then
            exit;

        TestScriptMgmt.InsertResEntry(ResEntry, 'SILVER', 10003, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 83, 0,
          'ITEM', 'DEFAULT', 10003, true);

        if LastIteration = '3-15-1-60' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-15-1-70' then
            exit;
        // 3-15-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '3-15-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'L_Test', '', 2, 'BOX', 44, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 'S-02-0001', 2, 2, 0, 0, false);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', '', 1, 'BOX', 45, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 'S-02-0003', 1, 1, 0, 0, false);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'C_Test', '31', 5, 'PCS', 16, 'SILVER', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 'S-01-0001', 5, 5, 0, 0, false);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, '', 25, '', '');

        if LastIteration = '3-15-2-20' then
            exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 10000, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN01', 1, 1, 37, 1, SalesHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 10000, "Reservation Status"::Prospect, 20011125D, 'L_TEST', '', '', 'LN02', 1, 1, 37, 1, SalesHeader."No.", '', 10000, true);

        if LastIteration = '3-15-2-30' then
            exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'SILVER', 20000, "Reservation Status"::Prospect, 20011125D, 'T_TEST', '', 'SN01', '', 1, 1, 37, 1, SalesHeader."No.", '', 20000, true);

        if LastIteration = '3-15-2-40' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '3-15-2-50' then
            exit;
        // 3-15-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-15-3-10' then
            exit;
        // 3-15-4
        TestScriptMgmt.CreateInvPutAwayPickBySrcFilt("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.");

        if LastIteration = '3-15-4-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);
        WhseActivLine.FindFirst();

        if LastIteration = '3-15-4-20' then
            exit;
        // 3-15-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '3-15-5-10' then
            exit;
        // 3-15-6
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '3-15-6-10' then
            exit;
        // 3-15-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '3-15-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase16()
    var
        Loc: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '3-16-1-10' then
            exit;

        Loc.Get('SILVER');
        Loc."Require Pick" := true;
        Loc.Modify();

        if LastIteration = '3-16-1-20' then
            exit;

        ItemJnlLineNo := 10000;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS3-16-1', 'A_TEST', '', 'SILVER', '', 29, 'PCS', 29, 0, 'S-01-0001');

        if LastIteration = '3-16-1-30' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-16-1-40' then
            exit;
        // 3-16-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'SILVER', true, false);

        if LastIteration = '3-16-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 10, 'PCS', 29, 'SILVER', 'WRONG');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 10000, 'S-01-0001', 10, 10, 0, 0, 0);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '', -8, 'PCS', 29, 'SILVER', 'WRONG');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 20000, 'S-01-0001', -8, -8, 0, 0, 0);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'A_Test', '', -1, 'PCS', 29, 'SILVER', 'DAMAGED');
        TestScriptMgmt.ModifySalesCrMemoLine(SalesHeader, 30000, 'S-01-0001', -1, -1, 0, 0, 0);

        if LastIteration = '3-16-2-20' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '3-16-2-30' then
            exit;
        // 3-16-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '3-16-3-10' then
            exit;
        // 3-16-4
        TestScriptMgmt.InsertWhseActHeader(WhseActivHeader, 5, 'SILVER');
        TestScriptMgmt.CreateInvPick(WhseActivHeader);

        if LastIteration = '3-16-4-10' then
            exit;

        WhseActivLine.FindFirst();
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '3-16-4-20' then
            exit;
        // 3-16-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '3-16-5-10' then
            exit;
        // 3-16-6
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostInvWhseActLine(WhseActivLine, false);

        if LastIteration = '3-16-6-10' then
            exit;

        SalesHeader.Find('-');
        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '3-16-6-20' then
            exit;
        // 3-16-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '3-16-7-10' then
            exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase17()
    var
        Loc: Record Location;
        BinCon: Record "Bin Content";
        BinTmp: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        CalcConsumption: Report "Calc. Consumption";
        CreateRes: Codeunit "Create Reserv. Entry";
        WMSManagement: Codeunit "WMS Management";
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        WMSGlobalPrecondition: Codeunit "WMS Set Global Preconditions";
        LNCode: Code[20];
        SNCode: Code[20];
        i: Integer;
        NextLineNo: Integer;
        Counter: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        ProdBOMHdr.Get('E_PROD');
        ProdBOMHdr.Status := ProdBOMHdr.Status::"Under Development";
        ProdBOMHdr.Modify();
        ProdBOMLine.SetRange("Production BOM No.", 'E_PROD');
        if ProdBOMLine.Find('-') then
            repeat
                ProdBOMLine.Delete();
            until ProdBOMLine.Next() = 0;
        WMSGlobalPrecondition.InsertProdBOMHdr('E_PROD', 'Product E', 'PCS');
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 10000, ProdBOMLine.Type::Item, 'D_PROD', '', 1);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 20000, ProdBOMLine.Type::Item, 'A_TEST', '12', 13);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 30000, ProdBOMLine.Type::Item, 'B_TEST', '', 12);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 40000, ProdBOMLine.Type::Item, 'T_TEST', '', 2);
        WMSGlobalPrecondition.InsertProdBOMLine('E_PROD', 50000, ProdBOMLine.Type::Item, 'L_TEST', '', 1);
        WMSGlobalPrecondition.ModifyProdBOMHdr('E_PROD', ProdBOMHdr.Status::Certified);

        if LastIteration = '3-17-1-10' then
            exit;

        BinCon.Init();
        BinCon."Location Code" := 'SILVER';
        BinCon."Bin Code" := 'S-07-0001';
        BinCon.Default := true;
        BinCon."Item No." := 'E_PROD';
        BinCon.Validate("Unit of Measure Code", 'PCS');
        BinCon.Insert(true);

        Loc.Get('SILVER');
        Loc."Require Receive" := true;
        Loc."Require Shipment" := true;
        Loc."Require Pick" := true;
        Loc."Require Put-away" := true;
        Loc.Modify();

        if GenPostSetup.Get('NATIONAL', 'MISC') then begin
            GenPostSetup.Validate("Sales Account", '6130');
            GenPostSetup.Validate("Purch. Account", '7130');
            GenPostSetup.Modify();
        end;

        if LastIteration = '3-17-1-20' then
            exit;
        // 3-17-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 0D, 'SILVER', true, false);

        if LastIteration = '3-17-2-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_TEST', '', 2, 'BOX', 65.43, 'SILVER', '');
        SalesLine."Planned Delivery Date" := 20011130D;
        SalesLine.Modify(true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'E_PROD', '', 3, 'PCS', 321.09, 'SILVER', '');
        SalesLine."Planned Delivery Date" := 20011130D;
        SalesLine.Modify(true);

        if LastIteration = '3-17-2-20' then
            exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '3-17-2-30' then
            exit;

        TestScriptMgmt.InsertWhseShptHeader(WhseShptHeader, 'SILVER', '', 'S-07-0001');

        if LastIteration = '3-17-2-40' then
            exit;

        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'SILVER');

        if LastIteration = '3-17-2-50' then
            exit;
        // 3-17-3
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'D_PROD', 4, 'SILVER');
        ProdOrder.Validate("Bin Code", 'S-04-0001');
        ProdOrder.Modify(true);

        if LastIteration = '3-17-3-10' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '3-17-3-20' then
            exit;
        // 3-17-4
        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 4, 'SILVER');

        if LastIteration = '3-17-4-10' then
            exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '3-17-4-20' then
            exit;
        // 3-17-5
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'SILVER', 'TCS3-17-5', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_Test', '12', 'SILVER', 60, 'PCS', 11.99, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_Test', '', 'SILVER', 50, 'PCS', 22.88, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'C_Test', '32', 'SILVER', 10, 'PCS', 33.77, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'L_Test', '', 'SILVER', 5, 'BOX', 44.66, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'T_Test', '', 'SILVER', 10, 'BOX', 55.55, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'A_Test', '', 'BLUE', 10, 'PCS', 9.99, false);

        if LastIteration = '3-17-5-10' then
            exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '3-17-5-20' then
            exit;

        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'SILVER', '', 'S-01-0001');

        if LastIteration = '3-17-5-30' then
            exit;

        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'SILVER');

        if LastIteration = '3-17-5-40' then
            exit;
        // 3-17-6
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, '', 'S-03-0001', 60);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, '', 'S-03-0002', 50);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, '', 'S-04-0001', 10);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 40000, '', 'S-01-0001', 5);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 50000, '', 'S-01-0001', 10);

        if LastIteration = '3-17-6-10' then
            exit;
        // 3-17-7
        LNCode := 'LN00';
        SNCode := 'SN00';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 50000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        for i := 1 to 2 do begin
            LNCode := IncStr(LNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 1, 1, 1, '', LNCode);
            CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        LNCode := IncStr(LNCode);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 3, 1, 3, '', LNCode);
        CreateRes.CreateEntry('L_TEST', '', 'SILVER', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '3-17-7-10' then
            exit;
        // 3-17-8
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '3-17-8-10' then
            exit;

        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '3-17-8-20' then
            exit;
        // 3-17-9
        TestScriptMgmt.InsertTransferHeader(TransHeader, 'BLUE', 'SILVER', 'OWN LOG.', 20011125D);

        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 10000, 'A_TEST', '', 'PCS', 9, 0, 9);
        TestScriptMgmt.ModifyTransferLine(TransHeader."No.", 10000, '', 'S-02-0001', 9, 0);

        if LastIteration = '3-17-9-10' then
            exit;

        TestScriptMgmt.ReleaseTransferOrder(TransHeader);

        if LastIteration = '3-17-9-20' then
            exit;

        TestScriptMgmt.PostTransferOrder(TransHeader, true);

        if LastIteration = '3-17-9-30' then
            exit;

        TestScriptMgmt.CreateWhseRcptFromTrans(TransHeader, WhseRcptHeader);

        if LastIteration = '3-17-9-40' then
            exit;

        Clear(WhseRcptLine);
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '3-17-9-50' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '3-17-9-60' then
            exit;
        // 3-17-10
        ProdOrder.Reset();
        ProdOrder.SetRange("Source No.", 'D_PROD');
        ProdOrder.Find('-');
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'C_TEST');
        ProdOrderComp.Find('-');
        ProdOrderComp.Validate("Bin Code", 'S-04-0001');
        // pointing the place bin code to a bin other than that at which the items are already found
        ProdOrderComp.Validate("Bin Code", IncStr(ProdOrderComp."Bin Code"));
        ProdOrderComp.Modify(true);
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.Find('+');
        ProdOrderComp2 := ProdOrderComp;
        NextLineNo := ProdOrderComp2."Line No." + 10000;
        ProdOrderComp2."Line No." := NextLineNo;
        ProdOrderComp2.Validate("Location Code", 'SILVER');
        ProdOrderComp2.Validate("Quantity per", 2);
        ProdOrderComp2.Validate("Due Date", WorkDate() - 1);
        ProdOrderComp2.Validate("Item No.", 'A_TEST');
        // pointing the place bin code to a bin other than that at which the items are already found
        ProdOrderComp2.Validate("Bin Code", IncStr(ProdOrderComp2."Bin Code"));
        ProdOrderComp2.Insert();

        if LastIteration = '3-17-10-10' then
            exit;

        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '3-17-10-20' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        if LastIteration = '3-17-10-30' then
            exit;

        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '3-17-10-40' then
            exit;
        // 3-17-11
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '3-17-11-10' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-17-11-20' then
            exit;
        // 3-17-12
        ProdOrder.Reset();
        ProdOrder.Find('-');
        WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '3-17-12-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-17-12-20' then
            exit;
        // 3-17-13
        ProdOrder.Reset();
        ProdOrder.SetRange("Source No.", 'E_PROD');
        ProdOrder.Find('-');
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.Find('-');
        repeat
            WMSManagement.GetDefaultBin(ProdOrderComp."Item No.", ProdOrderComp."Variant Code", ProdOrderComp."Location Code", ProdOrderComp."Bin Code");
            // pointing the place bin code to a bin other than that at which the items are already found
            GetDifferentBin(BinTmp, ProdOrderComp."Bin Code");
            ProdOrderComp.Validate("Bin Code", BinTmp.Code);
            ProdOrderComp.Modify(true);
        until ProdOrderComp.Next() = 0;
        Clear(CreatePickFromWhseSource);
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '3-17-13-10' then
            exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Source No.", ProdOrder."No.");
        WhseActivLine.SetRange("Item No.", 'L_TEST');
        WhseActivLine.FindSet();
        WhseActivLine.Validate("Qty. to Handle", 3);
        WhseActivLine.Validate("Lot No.", 'LN03');
        WhseActivLine.Modify(true);
        WhseActivLine.SplitLine(WhseActivLine);
        WhseActivLine.Find('>');
        WhseActivLine.Validate("Lot No.", 'LN01');
        WhseActivLine.Modify(true);
        WhseActivLine.Find('>');
        WhseActivLine.Validate("Qty. to Handle", 3);
        WhseActivLine.Validate("Lot No.", 'LN03');
        WhseActivLine.Modify(true);
        WhseActivLine.SplitLine(WhseActivLine);
        WhseActivLine.Find('>');
        WhseActivLine.Validate("Lot No.", 'LN01');
        WhseActivLine.Modify(true);
        WhseActivLine.SetRange("Lot No.");
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        WhseActivLine.FindSet();
        SNCode := 'SN01';
        Counter := 0;
        repeat
            Counter := Counter + 1;
            WhseActivLine.Validate("Serial No.", SNCode);
            WhseActivLine.Modify(true);
            if Counter > 1 then begin
                SNCode := IncStr(SNCode);
                Counter := 0;
            end;
        until WhseActivLine.Next() = 0;

        if LastIteration = '3-17-13-20' then
            exit;

        WhseActivLine.Reset();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '3-17-13-30' then
            exit;
        // 3-17-14
        Clear(CalcConsumption);
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '3-17-14-10' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-17-14-20' then
            exit;
        // 3-17-15
        ProdOrder.Reset();
        ProdOrder.Find('+');
        WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '3-17-15-10' then
            exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '3-17-15-20' then
            exit;
        // 3-17-16
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '3-17-16-10' then
            exit;

        Counter := 0;
        WhseActivLine.Reset();
        WhseActivLine.SetRange("Item No.", 'T_TEST');
        WhseActivLine.Find('-');
        SNCode := 'SN09';
        repeat
            Counter := Counter + 1;
            WhseActivLine.Validate("Serial No.", SNCode);
            WhseActivLine.Modify(true);
            if Counter > 1 then begin
                SNCode := IncStr(SNCode);
                Counter := 0;
            end;
        until WhseActivLine.Next() = 0;

        if LastIteration = '3-17-16-20' then
            exit;
        // 3-17-17
        WhseActivLine.Reset();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '3-17-17-10' then
            exit;

        WhseShptLine.FindFirst();
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '3-17-17-20' then
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

    [Scope('OnPrem')]
    procedure GetDifferentBin(var Bin: Record Bin; BinCode: Code[10])
    begin
        Bin.SetFilter(Code, '>%1', BinCode);
        Bin.FindSet();
        Bin.Next();
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

