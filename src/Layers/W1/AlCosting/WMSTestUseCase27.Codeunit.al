codeunit 103310 "WMS Test Use Case 27"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 27");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103310, 27, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        ItemChargeAssignPurch: Record "Item Charge Assignment (Purch)";
        ItemJnlLine: Record "Item Journal Line";
        CalcQtyOnHand: Report "Calculate Inventory";
        CreateRes: Codeunit "Create Reserv. Entry";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        // this is code added later to change the item no. so that sorting is same in the reference data for both native as well as SQL.
        // this test shall use an item called 80100-T instead of T_TEST
        TestScriptMgmt.CreateRenamedItem('T_TEST', '80100-T');

        if LastIteration = '27-1-1-10' then exit;
        // 27-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '40000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', 'TCS27-1-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80102-T', '', 'Green', 11, 'PCS', 6.3, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100-T', 'T1', 'Green', 11, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'Green', 3, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80002', '', 'Green', 2, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '80002', '', 'Green', 1, 'PCS', 0.5, false);
        if LastIteration = '27-1-2-10' then exit;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, 'SN01', 'LOT01');
        CreateRes.CreateEntry('80100-T', 'T1', 'GREEN', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '27-1-2-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'Green');
        if LastIteration = '27-1-2-30' then exit;
        //27-1-3
        WhseRcptHeader.SetRange("Location Code", 'Green');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, '', '', 6);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, '', '', 6);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, '', '', 3);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 40000, '', '', 2);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 50000, '', '', 1);
        if LastIteration = '27-1-3-10' then exit;

        SNCode := 'ST00';
        for i := 1 to 6 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80102-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN01';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, 'LOT02');
            CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 3, 3, '', 'LT01');
        CreateRes.CreateEntry('80002', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 1, 2, 2, '', 'LT02');
        CreateRes.CreateEntry('80002', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 50000, 1, 1, 1, '', 'LT03');
        CreateRes.CreateEntry('80002', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '27-1-3-20' then exit;

        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '27-1-3-30' then exit;

        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '27-1-3-40' then exit;
        //27-1-4
        WhseRcptHeader.SetRange("Location Code", 'Green');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, '', '', 5);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, '', '', 5);
        if LastIteration = '27-1-4-10' then exit;

        SNCode := 'ST06';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80102-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN06';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, 'LOT03');
            CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = '27-1-4-20' then exit;

        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '27-1-4-30' then exit;

        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '27-1-4-40' then exit;
        //27-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '27-1-5-10' then exit;
        //27-1-6
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '40000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Green', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100-T', 'T1', 2, 'BOX', 15.05, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100-T', 'T1', 3, 'BOX', 15.05, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80100-T', 'T1', 4, 'BOX', 15.05, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80216-T', '', 14, 'PCS', 0.8, 'Green', '');
        if LastIteration = '27-1-6-10' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'Green');
        if LastIteration = '27-1-6-20' then exit;
        //27-1-7
        WhseRcptHeader.SetRange("Location Code", 'Green');
        WhseRcptHeader.FindFirst();
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, '', '', 1);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, '', '', 1);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, '', '', 1);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 40000, '', '', 14);
        if LastIteration = '27-1-7-10' then exit;

        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN12', 'LOT04');
        CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN13', 'LOT05');
        CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN14', 'LOT06');
        CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 40000, 1, 9, 9, '', 'LN01');
        CreateRes.CreateEntry('80216-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 40000, 1, 5, 5, '', 'LN02');
        CreateRes.CreateEntry('80216-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '27-1-7-20' then exit;

        Clear(WhseRcptLine);
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '27-1-7-30' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '27-1-7-40' then exit;
        //27-1-8
        WhseRcptHeader.SetRange("Location Code", 'Green');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, '', '', 1);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 20000, '', '', 2);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 30000, '', '', 3);
        if LastIteration = '27-1-8-10' then exit;

        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN15', 'LOT07');
        CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        SNCode := 'SN15';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, 'LOT08'
        );
            CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN17';
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 30000, 1, 1, 1, SNCode, 'LOT09');
            CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = '27-1-8-20' then exit;

        Clear(WhseRcptLine);
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '27-1-8-30' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '27-1-8-40' then exit;
        // 27-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '27-1-9-10' then exit;
        // 27-1-10
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '40000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', 'TCS27-1-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80102-T', '', 'Green', 11, 'PCS', 6.3, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100-T', 'T1', 'Green', 11, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80216-T', '', 'Green', 3, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80216-T', '', 'Green', 2, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '80216-T', '', 'Green', 1, 'PCS', 0.5, false);
        if LastIteration = '27-1-10-10' then exit;

        SNCode := 'ST11';
        for i := 1 to 11 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80102-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN20';
        for i := 1 to 11 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, 'LOT02');
            CreateRes.CreateEntry('80100-T', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 3, 3, '', 'LN03');
        CreateRes.CreateEntry('80216-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 1, 2, 2, '', 'LN04');
        CreateRes.CreateEntry('80216-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 50000, 1, 1, 1, '', 'LN05');
        CreateRes.CreateEntry('80216-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '27-1-10-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'Green');
        if LastIteration = '27-1-10-30' then exit;

        Clear(WhseRcptLine);
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '27-1-10-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '27-1-10-50' then exit;
        // 27-1-11
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '40000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', 'TCS27-1-4', false);

        if PurchRcptLine.Find('-') then begin
            PurchGetReceipt.SetPurchHeader(PurchHeader);
            repeat
                PurchGetReceipt.CreateInvLines(PurchRcptLine)
            until PurchRcptLine.Next() = 0;
        end;
        if LastIteration = '27-1-11-10' then exit;

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 160000, PurchLine.Type::"Charge (Item)", 'UPS', '', 'Green', 1, 'PCS', 100, false);

        ItemChargeAssignPurch.Init();
        ItemChargeAssignPurch."Document Type" := ItemChargeAssignPurch."Document Type"::Invoice;
        ItemChargeAssignPurch."Document No." := '1001';
        ItemChargeAssignPurch."Document Line No." := 160000;
        ItemChargeAssignPurch."Line No." := 10000;
        ItemChargeAssignPurch."Item Charge No." := 'UPS';
        ItemChargeAssignPurch."Item No." := '80100-T';
        ItemChargeAssignPurch."Qty. to Assign" := 1;
        ItemChargeAssignPurch."Unit Cost" := 100;
        ItemChargeAssignPurch."Amount to Assign" := 100;
        ItemChargeAssignPurch."Applies-to Doc. Type" := ItemChargeAssignPurch."Applies-to Doc. Type"::Receipt;
        ItemChargeAssignPurch."Applies-to Doc. No." := '107001';
        ItemChargeAssignPurch."Applies-to Doc. Line No." := 20000;
        ItemChargeAssignPurch.Insert(true);
        if LastIteration = '27-1-11-20' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '27-1-11-30' then exit;
        //27-1-12
        ItemJnlLine.DeleteAll();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcQtyOnHand.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        CalcQtyOnHand.SetTableView(Item);
        CalcQtyOnHand.InitializeRequest(20011125D, ItemJnlLine."Document No.", true, false);
        CalcQtyOnHand.UseRequestPage(false);
        CalcQtyOnHand.RunModal();
        Clear(CalcQtyOnHand);
        if LastIteration = '27-1-12-10' then exit;
        // 27-1-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo);

        if LastIteration = '27-1-13-10' then exit;
        // 27-1-14
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS27-1-14', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'BLUE', 11, 'PCS', 630, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100-T', 'T2', 'BLUE', 7, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'BLUE', 19, 'PCS', 630, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80100-T', 'T2', 'BLUE', 6, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '80100-T', 'T1', 'BLUE', 3, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '80100-T', 'T1', 'BLUE', 4, 'BOX', 10.01, false);

        if LastIteration = '27-1-14-10' then exit;

        SNCode := 'SX00';
        for i := 1 to 7 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SX07';
        for i := 1 to 6 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'ST00';
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 50000, 1, 1, 1, SNCode, 'LX01');
            CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'ST03';
        for i := 1 to 4 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 60000, 1, 1, 1, SNCode, 'LX01');
            CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 11, 11, '', 'LT01');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 19, 19, '', 'LT02');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '27-1-14-20' then exit;

        PurchHeader.Reset();
        PurchHeader.FindLast();
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '27-1-14-30' then exit;

        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 10000);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 20000);
        PurchLine.Validate("Qty. to Invoice", 7);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 30000);
        PurchLine.Validate("Qty. to Invoice", 19);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 40000);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 50000);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 60000);
        PurchLine.Validate("Qty. to Invoice", 4);
        PurchLine.Modify();

        if LastIteration = '27-1-14-40' then exit;

        PurchHeader.Reset();
        PurchHeader.FindLast();
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '27-1-14-50' then exit;
        // 27-1-15
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 15, LastILENo);

        if LastIteration = '27-1-15-10' then exit;
        // 27-1-16
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '40000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'BLUE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 11, 'PCS', 930, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100-T', 'T2', 7, 'BOX', 10.01, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80002', '', 19, 'PCS', 630, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80100-T', 'T2', 6, 'BOX', 10.01, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '80100-T', 'T1', 3, 'BOX', 10.01, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '80100-T', 'T1', 4, 'BOX', 10.01, 'BLUE', '');

        if LastIteration = '27-1-16-10' then exit;

        SNCode := 'SX00';
        for i := 1 to 7 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SX07';
        for i := 1 to 6 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 40000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'ST00';
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 50000, 1, 1, 1, SNCode, 'LX01');
            CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'ST03';
        for i := 1 to 4 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 60000, 1, 1, 1, SNCode, 'LX01');
            CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 11, 11, '', 'LT01');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 19, 19, '', 'LT02');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '27-1-16-20' then exit;

        SalesHeader.Reset();
        SalesHeader.FindFirst();
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '27-1-16-30' then exit;

        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        SalesLine."Qty. to Invoice" := 0;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 20000);
        SalesLine."Qty. to Invoice" := 7;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 30000);
        SalesLine."Qty. to Invoice" := 19;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 40000);
        SalesLine."Qty. to Invoice" := 0;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 50000);
        SalesLine."Qty. to Invoice" := 0;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 60000);
        SalesLine."Qty. to Invoice" := 4;
        SalesLine.Modify();

        if LastIteration = '27-1-16-40' then exit;

        SalesHeader.Reset();
        SalesHeader.FindFirst();
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '27-1-16-50' then exit;
        // 27-1-17
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 17, LastILENo);

        if LastIteration = '27-1-17-10' then exit;
        // 27-1-18
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '40000', 20011126D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011126D, 'BLUE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 3, 'PCS', 930, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100-T', 'T2', 2, 'BOX', 10.01, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80002', '', 7, 'PCS', 630, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80100-T', 'T2', 1, 'BOX', 10.01, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '80100-T', 'T1', 1, 'BOX', 10.01, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '80100-T', 'T1', 1, 'BOX', 10.01, 'BLUE', '');

        if LastIteration = '27-1-18-10' then exit;

        SNCode := 'SX00';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011126D, 20011126D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 40000, 1, 1, 1, 'SX08', '');
        CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011126D, 20011126D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 50000, 1, 1, 1, 'ST01', 'LX01');
        CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011126D, 20011126D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST04', 'LX01');
        CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011126D, 20011126D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 3, 3, '', 'LT01');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011126D, 20011126D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 30000, 1, 7, 7, '', 'LT02');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011126D, 20011126D, 0, "Reservation Status"::Surplus);

        if LastIteration = '27-1-18-20' then exit;

        SalesHeader.Reset();
        SalesHeader.FindLast();
        SalesHeader.Receive := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '27-1-18-30' then exit;

        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        SalesLine."Qty. to Invoice" := 3;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 20000);
        SalesLine."Qty. to Invoice" := 0;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 30000);
        SalesLine."Qty. to Invoice" := 0;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 40000);
        SalesLine."Qty. to Invoice" := 1;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 50000);
        SalesLine."Qty. to Invoice" := 1;
        SalesLine.Modify();
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 60000);
        SalesLine."Qty. to Invoice" := 0;
        SalesLine.Modify();

        if LastIteration = '27-1-18-40' then exit;

        SalesHeader.Reset();
        SalesHeader.FindLast();
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '27-1-18-50' then exit;
        // 27-1-19
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 19, LastILENo);

        if LastIteration = '27-1-19-10' then exit;
        // 27-1-20
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '10000', 20011127D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011127D, 'BLUE', 'TCS27-1-20', false);
        PurchHeader.Validate("Vendor Cr. Memo No.", 'TCS27-1-20');
        PurchHeader.Modify();

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'BLUE', 3, 'PCS', 630, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100-T', 'T2', 'BLUE', 2, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'BLUE', 7, 'PCS', 630, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '80100-T', 'T2', 'BLUE', 1, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '80100-T', 'T1', 'BLUE', 1, 'BOX', 10.01, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '80100-T', 'T1', 'BLUE', 1, 'BOX', 10.01, false);

        if LastIteration = '27-1-20-10' then exit;

        SNCode := 'SX00';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011127D, 20011127D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 40000, 1, 1, 1, 'SX08', '');
        CreateRes.CreateEntry('80100-T', 'T2', 'BLUE', '', 20011127D, 20011127D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 50000, 1, 1, 1, 'ST01', 'LX01');
        CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011127D, 20011127D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 60000, 1, 1, 1, 'ST04', 'LX01');
        CreateRes.CreateEntry('80100-T', 'T1', 'BLUE', '', 20011127D, 20011127D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 10000, 1, 3, 3, '', 'LT01');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011127D, 20011127D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 30000, 1, 7, 7, '', 'LT02');
        CreateRes.CreateEntry('80002', '', 'BLUE', '', 20011127D, 20011127D, 0, "Reservation Status"::Surplus);

        if LastIteration = '27-1-20-20' then exit;

        PurchHeader.Reset();
        PurchHeader.FindLast();
        PurchHeader.Ship := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '27-1-20-30' then exit;

        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 10000);
        PurchLine.Validate("Qty. to Invoice", 3);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 20000);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 30000);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 40000);
        PurchLine.Validate("Qty. to Invoice", 1);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 50000);
        PurchLine.Validate("Qty. to Invoice", 1);
        PurchLine.Modify();
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 60000);
        PurchLine.Validate("Qty. to Invoice", 0);
        PurchLine.Modify();

        if LastIteration = '27-1-20-40' then exit;

        PurchHeader.Reset();
        PurchHeader.FindLast();
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '27-1-20-50' then exit;
        // 27-1-21
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 21, LastILENo);

        if LastIteration = '27-1-21-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLine: Record "Item Journal Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        PickWkshLine: Record "Whse. Worksheet Line";
        WkshName: Record "Whse. Worksheet Name";
        ItemChargeAssignSales: Record "Item Charge Assignment (Sales)";
        CalcQtyOnHand: Report "Calculate Inventory";
        CreateRes: Codeunit "Create Reserv. Entry";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();
        // this is code added later to change the item no. so that sorting is same in the reference data for both native as well as SQL.
        // this test shall use an item called 80100-T instead of T_TEST
        TestScriptMgmt.CreateRenamedItem('T_TEST', '80100-T');

        if LastIteration = '27-2-1-10' then exit;

        WkshName.Init();
        WkshName.Validate("Worksheet Template Name", 'PICK');
        WkshName.Validate(Name, 'DEFAULT');
        WkshName.Validate(Description, 'Default Pick Worksheet');
        WkshName.Validate("Location Code", 'GREEN');
        if not WkshName.Insert(true) then
            WkshName.Modify(true);
        if LastIteration = '27-2-1-20' then exit;
        // 27-2-2
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 10000, 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS27-2-2', '80102-T', '', 'GREEN', '', 10, 'PCS', 6.3, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 20000, 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS27-2-2', '80100-T', 'T2', 'GREEN', '', 10, 'BOX', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 30000, 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS27-2-2', '80100-T', 'T2', 'BLUE', '', 11, 'BOX', 10, 0);
        if LastIteration = '27-2-2-10' then exit;

        SNCode := 'ST00';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(83, 2, 'ITEM', 'DEFAULT', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('80102-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);
        end;
        SNCode := 'SN00';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(83, 2, 'ITEM', 'DEFAULT', 0, 20000, 1, 1, 1, SNCode, 'LN1');
            CreateRes.CreateEntry('80100-T', 'T2', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);
        end;
        SNCode := 'SN10';
        for i := 1 to 11 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(83, 2, 'ITEM', 'DEFAULT', 0, 30000, 1, 1, 1, SNCode, 'LN2');
            CreateRes.CreateEntry('80100-T', 'T2', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = '27-2-2-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = '27-2-2-30' then exit;
        //27-2-3
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '40000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Green', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80102-T', '', 5, 'PCS', 6.3, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100-T', 'T2', 5, 'BOX', 19.87, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80100-T', 'T2', 5, 'BOX', 19.87, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80100-T', 'T2', 4, 'BOX', 19.87, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '80100-T', 'T2', 2, 'BOX', 19.87, 'BLUE', '');
        if LastIteration = '27-2-3-10' then exit;

        SNCode := 'SN10';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, SNCode, 'LN2');
            CreateRes.CreateEntry('80100-T', 'T2', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN15';
        for i := 1 to 4 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 40000, 1, 1, 1, SNCode, 'LN2');
            CreateRes.CreateEntry('80100-T', 'T2', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN19';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 50000, 1, 1, 1, SNCode, 'LN2');
            CreateRes.CreateEntry('80100-T', 'T2', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = '27-2-3-20' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);
        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'Green');
        WhseShptHeader.Find('-');
        TestScriptMgmt.ReleaseWhseShipment(WhseShptHeader);
        if LastIteration = '27-2-3-30' then exit;
        //27-2-4
        TestScriptMgmt.CreatePickWorksheet(PickWkshLine, 'PICK', 'DEFAULT', 'Green', 0, 'SH000001');
        if LastIteration = '27-2-4-10' then exit;

        PickWkshLine.AutofillQtyToHandle(PickWkshLine);
        PickWkshLine.SetRange("Line No.", 20000);
        PickWkshLine.Find('-');
        PickWkshLine."Qty. to Handle" := 3;
        PickWkshLine.Modify(true);
        if LastIteration = '27-2-4-20' then exit;

        TestScriptMgmt.CreatePickFromWksh(
          PickWkshLine, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        if LastIteration = '27-2-4-30' then exit;

        WhseActivLine.SetRange("Location Code", 'Green');
        WhseActivLine.SetRange("Item No.", '80102-T');
        if WhseActivLine.Find('-') then begin
            SNCode := 'ST00';
            for i := 1 to 5 do begin
                SNCode := IncStr(SNCode);
                WhseActivLine."Serial No." := SNCode;
                WhseActivLine."Lot No." := '';
                WhseActivLine.Modify(true);
                if WhseActivLine.Next() = 0 then;
            end;
        end;

        WhseActivLine.SetRange("Location Code", 'Green');
        WhseActivLine.SetRange("Item No.", '80100-T');
        if WhseActivLine.Find('-') then begin
            SNCode := 'SN06';
            for i := 1 to 3 do begin
                SNCode := IncStr(SNCode);
                WhseActivLine."Serial No." := SNCode;
                WhseActivLine."Lot No." := 'LN1';
                WhseActivLine.Modify(true);
                if WhseActivLine.Next() = 0 then;
            end;
        end;
        if LastIteration = '27-2-4-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '27-2-4-50' then exit;
        //27-2-5
        PickWkshLine.Find('-');
        PickWkshLine.AutofillQtyToHandle(PickWkshLine);
        if LastIteration = '27-2-5-10' then exit;

        TestScriptMgmt.CreatePickFromWksh(
          PickWkshLine, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        if LastIteration = '27-2-5-20' then exit;

        WhseActivLine.SetRange("Location Code", 'Green');
        WhseActivLine.SetRange("Item No.", '80100-T');
        if WhseActivLine.FindFirst() then begin
            WhseActivLine."Serial No." := 'SN06';
            WhseActivLine."Lot No." := 'LN1';
            WhseActivLine.Modify(true);
        end;
        if WhseActivLine.FindLast() then begin
            WhseActivLine."Serial No." := 'SN10';
            WhseActivLine."Lot No." := 'LN1';
            WhseActivLine.Modify(true);
        end;
        if LastIteration = '27-2-5-30' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '27-2-5-40' then exit;
        //27-2-6
        WhseShptLine.FindFirst();
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);
        if LastIteration = '27-2-6-10' then exit;

        SalesHeader.FindFirst();
        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '27-2-6-20' then exit;
        //27-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '27-2-7-10' then exit;
        //27-2-8
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 10000, 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS27-2-3', '80216-T', '', 'Blue', '', 11, 'PCS', 6.3, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 20000, 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS27-2-3', '80100-T', 'T1', 'Blue', '', 11, 'BOX', 10, 0);
        if LastIteration = '27-2-8-10' then exit;

        CreateReservEntryFor(83, 2, 'ITEM', 'DEFAULT', 0, 10000, 1, 11, 11, '', 'LN3');
        CreateRes.CreateEntry('80216-T', '', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);

        SNCode := 'SN29';
        for i := 1 to 6 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(83, 2, 'ITEM', 'DEFAULT', 0, 20000, 1, 1, 1, SNCode, 'LN4');
            CreateRes.CreateEntry('80100-T', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);
        end;
        SNCode := 'SN35';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(83, 2, 'ITEM', 'DEFAULT', 0, 20000, 1, 1, 1, SNCode, 'LN5');
            CreateRes.CreateEntry('80100-T', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = '27-2-8-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = '27-2-8-30' then exit;
        //27-2-9
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '40000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Blue', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80216-T', '', 11, 'PCS', 6.3, 'BLUE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100-T', 'T1', 11, 'BOX', 19.87, 'BLUE', '');
        if LastIteration = '27-2-9-10' then exit;

        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 5, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 6, 0, 0, 0, false);
        if LastIteration = '27-2-9-20' then exit;

        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 5, 5, '', 'LN3');
        CreateRes.CreateEntry('80216-T', '', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        SNCode := 'SN29';
        for i := 1 to 6 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, 'LN4');
            CreateRes.CreateEntry('80100-T', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        SNCode := 'SN35';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, 'LN5');
            CreateRes.CreateEntry('80100-T', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        ReservationEntry.SetRange("Serial No.", 'SN34', 'SN38');
        if ReservationEntry.Find('-') then
            repeat
                ReservationEntry.Validate("Qty. to Handle (Base)", 0);
                ReservationEntry.Modify(true);
            until ReservationEntry.Next() = 0;
        if LastIteration = '27-2-9-30' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '27-2-9-40' then exit;
        // 27-2-10
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 10, LastILENo);

        if LastIteration = '27-2-10-10' then exit;
        // 27-2-11
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 6, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 5, 0, 0, 0, false);
        if LastIteration = '27-2-11-10' then exit;

        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 6, 6, '', 'LN3');
        CreateRes.CreateEntry('80216-T', '', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '27-2-11-20' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '27-2-11-30' then exit;
        // 27-2-12
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 12, LastILENo);

        if LastIteration = '27-2-12-10' then exit;
        // 27-2-13
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '40000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', '', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80102-T', '', 'Green', 1, 'PCS', 6.3, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100-T', 'T2', 'Green', 1, 'BOX', 19.87, false);

        PurchLine.SetRange("Line No.", 10000);
        PurchLine.FindFirst();
        PurchLine."Appl.-to Item Entry" := 6;
        PurchLine.Modify(true);

        PurchLine.SetRange("Line No.", 20000);
        PurchLine.FindFirst();
        PurchLine."Appl.-to Item Entry" := 11;
        PurchLine.Modify(true);

        if LastIteration = '27-2-13-10' then exit;

        CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 10000, 1, 1, 1, 'ST06', '');
        CreateRes.CreateEntry('80102-T', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 20000, 1, 1, 1, 'SN01', 'LN1');
        CreateRes.CreateEntry('80100-T', 'T2', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        if LastIteration = '27-2-13-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromPurch(PurchHeader, WhseShptHeader, 'GREEN');
        WhseShptHeader.FindFirst();
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);
        if LastIteration = '27-2-13-30' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        Clear(WhseShptLine);
        WhseShptLine.FindFirst();
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);
        if LastIteration = '27-2-13-40' then exit;
        // 27-2-14
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '40000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Blue', true, false);

        if SalesShipmentLine.Find('-') then begin
            SalesGetShipment.SetSalesHeader(SalesHeader);
            repeat
                SalesGetShipment.CreateInvLines(SalesShipmentLine)
            until SalesShipmentLine.Next() = 0;
        end;
        if LastIteration = '27-2-14-10' then exit;

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 140000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, '', 100, 'BLUE', '');


        ItemChargeAssignSales.Init();
        ItemChargeAssignSales."Document Type" := ItemChargeAssignSales."Document Type"::Invoice;
        ItemChargeAssignSales."Document No." := '1001';
        ItemChargeAssignSales."Document Line No." := 140000;
        ItemChargeAssignSales."Line No." := 20000;
        ItemChargeAssignSales."Item Charge No." := 'UPS';
        ItemChargeAssignSales."Item No." := '80100-T';
        ItemChargeAssignSales."Qty. to Assign" := 1;
        ItemChargeAssignSales."Unit Cost" := 100;
        ItemChargeAssignSales."Amount to Assign" := 100;
        ItemChargeAssignSales."Applies-to Doc. Type" := ItemChargeAssignSales."Applies-to Doc. Type"::Invoice;
        ItemChargeAssignSales."Applies-to Doc. No." := '1001';
        ItemChargeAssignSales."Applies-to Doc. Line No." := 30000;
        ItemChargeAssignSales.Insert(true);
        if LastIteration = '27-2-14-20' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '27-2-14-30' then exit;
        //27-2-15
        ItemJnlLine.DeleteAll();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcQtyOnHand.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        CalcQtyOnHand.SetTableView(Item);
        CalcQtyOnHand.InitializeRequest(20011125D, ItemJnlLine."Document No.", true, false);
        CalcQtyOnHand.UseRequestPage(false);
        CalcQtyOnHand.RunModal();
        Clear(CalcQtyOnHand);
        if LastIteration = '27-2-15-10' then exit;
        // 27-2-16
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 16, LastILENo);

        if LastIteration = '27-2-16-10' then exit;
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

