codeunit 103334 "WMS Test Use Case 25"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 25");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103334, 25, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        ResEntry: Record "Reservation Entry";
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
        ItemChargeAssignPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssignSales: Record "Item Charge Assignment (Sales)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnRcptLine: Record "Return Receipt Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '25-1-1-10' then exit;

        Location.Get('White');
        Location."Use Put-away Worksheet" := true;
        Location.Modify(true);

        if LastIteration = '25-1-1-20' then exit;
        // 25-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS25-1-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'WHITE', 3, 'PALLET', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'UPS', '', 'WHITE', 1, '', 100, false);
        if LastIteration = '25-1-2-10' then exit;

        ItemChargeAssignPurch.Init();
        ItemChargeAssignPurch."Document Type" := ItemChargeAssignPurch."Document Type"::Order;
        ItemChargeAssignPurch."Document No." := '106001';
        ItemChargeAssignPurch."Document Line No." := 20000;
        ItemChargeAssignPurch."Line No." := 10000;
        ItemChargeAssignPurch."Item Charge No." := 'UPS';
        ItemChargeAssignPurch."Item No." := '80100';
        ItemChargeAssignPurch."Qty. to Assign" := 1;
        ItemChargeAssignPurch."Unit Cost" := 100;
        ItemChargeAssignPurch."Amount to Assign" := 100;
        ItemChargeAssignPurch."Applies-to Doc. Type" := ItemChargeAssignPurch."Applies-to Doc. Type"::Order;
        ItemChargeAssignPurch."Applies-to Doc. No." := '106001';
        ItemChargeAssignPurch."Applies-to Doc. Line No." := 10000;
        ItemChargeAssignPurch.Insert(true);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '25-1-2-20' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '25-1-2-30' then exit;

        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, WhseRcptHeader."No.", 10000, 'Receive', 'W-08-0001', 2);

        if LastIteration = '25-1-2-40' then exit;

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '25-1-2-50' then exit;
        // 25-1-3
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 3, 'PCS', 33.77, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, 'PCS', 100, 'WHITE', '');

        if LastIteration = '25-1-3-10' then exit;

        ItemChargeAssignSales.Init();
        ItemChargeAssignSales."Document Type" := ItemChargeAssignSales."Document Type"::"Return Order";
        ItemChargeAssignSales."Document No." := '1001';
        ItemChargeAssignSales."Document Line No." := 20000;
        ItemChargeAssignSales."Line No." := 10000;
        ItemChargeAssignSales."Item Charge No." := 'UPS';
        ItemChargeAssignSales."Item No." := 'A_TEST';
        ItemChargeAssignSales."Qty. to Assign" := 1;
        ItemChargeAssignSales."Unit Cost" := 100;
        ItemChargeAssignSales."Amount to Assign" := 100;
        ItemChargeAssignSales."Applies-to Doc. Type" := ItemChargeAssignSales."Applies-to Doc. Type"::"Return Order";
        ItemChargeAssignSales."Applies-to Doc. No." := '1001';
        ItemChargeAssignSales."Applies-to Doc. Line No." := 10000;
        ItemChargeAssignSales.Insert(true);
        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '25-1-3-20' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '25-1-3-30' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000002');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000002', 10000, 'Receive', 'W-08-0001', 1);

        if LastIteration = '25-1-3-40' then exit;

        WhseRcptLine.SetRange("No.", 'RE000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '25-1-3-50' then exit;
        // 25-1-4
        PurchRcptLine.SetRange("Line No.", 10000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
        if LastIteration = '25-1-4-10' then exit;
        // 25-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '25-1-5-10' then exit;
        // 25-1-6
        ReturnRcptLine.SetRange("Line No.", 10000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        if LastIteration = '25-1-6-10' then exit;
        // 25-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '25-1-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnRcptLine: Record "Return Receipt Line";
        TrackingSpecification: Record "Tracking Specification";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '25-2-1-10' then exit;

        Item.Get('80100');
        Item."Put-away Unit of Measure Code" := 'Box';
        Item.Modify(true);
        if LastIteration = '25-2-1-20' then exit;
        // 25-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS25-2-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'WHITE', 4, 'PALLET', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'WHITE', 3, 'Box', 3, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80100', '', 'WHITE', 4, 'PALLET', 96, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        if LastIteration = '25-2-2-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '25-2-2-20' then exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.Find('-');
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 30000, 'Receive', 'W-08-0001', 2);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, 'Pick', 'W-01-0002', 2);
        WhseActivLine.SetRange("Line No.", 30000, 40000);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '25-2-2-30' then exit;

        Clear(PurchHeader);
        PurchHeader.SetRange("No.", '106001');
        PurchHeader.Find('-');
        ReleasePurchDoc.Reopen(PurchHeader);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 1, 0, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 0, 0, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 0, 0, 0);
        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '25-2-2-40' then exit;

        WhseActivHeader.Find('-');
        WhseActivHeader.Delete(true);
        if LastIteration = '25-2-2-50' then exit;
        // 25-2-3
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T1', 2, 'BOX', 11.99, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', 'T2', 2, 'Box', 12.88, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80100', '', 5, 'PALLET', 96, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'C_Test', '31', 4, 'PCS', 5.78, '', '');

        SNCode := 'SN00';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T1', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        SNCode := 'SN02';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '25-2-3-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'Green');

        if LastIteration = '25-2-3-20' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000002');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000002', 20000, 'Receive', 'W-08-0001', 1);
        ResEntry.SetRange("Serial No.", 'SN04');
        ResEntry.Find('-');
        ResEntry."Qty. to Handle (Base)" := 0;
        ResEntry."Qty. to Invoice (Base)" := 0;
        ResEntry.Modify(true);

        WhseRcptHeader.SetRange("No.", 'RE000003');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000003', 10000, '', '', 3);

        if LastIteration = '25-2-3-30' then exit;

        WhseRcptLine.SetRange("No.", 'RE000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseRcptLine.SetRange("No.", 'RE000003');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '25-2-3-40' then exit;

        Clear(SalesHeader);
        SalesHeader.SetRange("No.", '1001');
        SalesHeader.Find('-');
        ReleaseSalesDoc.Reopen(SalesHeader);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 0, 0, 0, false);

        TrackingSpecification.SetRange("Serial No.", 'SN03');
        TrackingSpecification.Find('-');
        TrackingSpecification.Validate("Qty. to Invoice (Base)", 0);
        TrackingSpecification.Modify(true);

        SalesHeader.Receive := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '25-2-3-50' then exit;

        if WhseActivHeader.Find('-') then
            repeat
                WhseActivHeader.Delete(true);
            until WhseActivHeader.Next() = 0;
        if LastIteration = '25-2-3-60' then exit;
        // 25-2-4
        PurchRcptLine.SetRange("Line No.", 30000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
        if LastIteration = '25-2-4-10' then exit;
        // 25-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '25-2-5-10' then exit;
        // 25-2-6
        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Document No.", '107001');
        ReturnRcptLine.SetRange("Line No.", 20000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Document No.", '107002');
        ReturnRcptLine.SetRange("Line No.", 30000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Document No.", '107003');
        ReturnRcptLine.SetRange("Line No.", 40000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        if LastIteration = '25-2-6-10' then exit;
        // 25-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '25-2-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        ReturnRcptLine: Record "Return Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '25-3-1-10' then exit;
        // 25-3-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS25-3-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T1', 'WHITE', 2, 'Box', 6.25, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 2, 'Box', 6.75, false);

        SNCode := 'SN00';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T1', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN02';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '25-3-2-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '25-3-2-20' then exit;

        PurchHeader.Find('-');
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '25-3-2-30' then exit;

        WhseActivHeader.Find('-');
        WhseActivHeader.Delete(true);

        if LastIteration = '25-3-2-40' then exit;
        // 25-3-3
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS25-3-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80216-T', '', 'WHITE', 3, 'PCS', 0.5, false);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 3, 3, '', 'LOT01');
        CreateRes.CreateEntry('80216-T', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '25-3-3-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        WhseRcptLine.SetRange("No.", 'RE000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '25-3-3-20' then exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        WhseActivLine.Find('-');
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 10000, 'Receive', 'W-08-0001', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 20000, 'Pick', 'W-01-0002', 1);
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '25-3-3-30' then exit;

        WhseActivHeader.Find('-');
        WhseActivHeader.Delete(true);

        if LastIteration = '25-3-3-40' then exit;
        // 25-3-4
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T2', 2, 'BOX', 11.99, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80216-T', '', 2, 'PCS', 0.5, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'T_Test', '', 2, 'Box', 12.88, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80216-T', '', 2, 'PCS', 0.5, 'WHITE', '');

        SNCode := 'SN06';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN08';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 30000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, 2, 2, '', 'LOT01');
        CreateRes.CreateEntry('80216-T', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 40000, 1, 2, 2, '', 'LOT02');
        CreateRes.CreateEntry('80216-T', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '25-3-4-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');
        Clear(WhseRcptLine);
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '25-3-4-20' then exit;

        WhseActivHeader.Find('-');
        WhseActivHeader.Delete(true);

        if LastIteration = '25-3-4-30' then exit;
        // 25-3-5
        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Line No.", 10000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Line No.", 20000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Line No.", 30000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Line No.", 40000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        if LastIteration = '25-3-5-10' then exit;
        // 25-3-6
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 6, LastILENo);

        if LastIteration = '25-3-6-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        ProdOrder: Record "Production Order";
        ReturnRcptLine: Record "Return Receipt Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CrossDockOpp: Record "Whse. Cross-Dock Opportunity";
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '25-4-1-10' then exit;

        Location.Get('White');
        Location."Use Put-away Worksheet" := true;
        Location.Modify(true);

        if LastIteration = '25-4-1-20' then exit;
        // 25-4-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T2', 2, 'BOX', 65.43, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'D_PROD', '', 3, 'PCS', 321.09, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80216-T', '', 4, 'PCS', 0.8, 'WHITE', '');
        if LastIteration = '25-4-2-10' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');
        if LastIteration = '25-4-2-20' then exit;
        // 25-4-3
        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'D_PROD', 4, 'WHITE');
        ProdOrder.Validate("Starting Date", 20011125D);
        ProdOrder.Validate("Ending Date", 20011125D);
        ProdOrder.Validate("Due Date", 20011125D);
        ProdOrder.Modify(true);

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '22-4-3-10' then exit;
        // 25-4-4
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'White', 'TCS25-4-4', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C_TEST', '32', 'White', 3, 'PCS', 33.77, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '', 'WHITE', 2, 'PCS', 12.27, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80216-T', '', 'WHITE', 3, 'PCS', 0.5, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'T_TEST', 'T2', 'WHITE', 2, 'Box', 65.43, false);

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, '', 'LOT01');
        CreateRes.CreateEntry('80216-t', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 2, 2, '', 'LOT02');
        CreateRes.CreateEntry('80216-t', '', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 1, 1, 1, 'SN01', '');
        CreateRes.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 40000, 1, 1, 1, 'SN02', '');
        CreateRes.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '25-4-4-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        if LastIteration = '25-4-4-20' then exit;

        CrossDockMgt.CalculateCrossDockLines(CrossDockOpp, '', 'RE000001', 'WHITE');

        CrossDockOpp.SetRange("Source Name/No.", 'RE000001');
        CrossDockOpp.SetRange("Source Line No.", 30000);
        CrossDockOpp.SetRange("Line No.", 10000);
        CrossDockOpp.Find('-');
        CrossDockOpp."Qty. to Cross-Dock" := 3;
        CrossDockOpp.Modify(true);

        CrossDockOpp.SetRange("Source Name/No.", 'RE000001');
        CrossDockOpp.SetRange("Source Line No.", 40000);
        CrossDockOpp.SetRange("Line No.", 20000);
        CrossDockOpp.Find('-');
        CrossDockOpp."Qty. to Cross-Dock" := 2;
        CrossDockOpp.Modify(true);
        if LastIteration = '25-4-4-30' then exit;

        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '25-4-4-40' then exit;
        // 25-4-5
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'C_Test', '32', 3, 'PCS', 33.77, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', 'T2', 2, 'Box', 65.43, 'WHITE', '');

        SNCode := 'SN02';
        for i := 1 to 2 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'WHITE', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '25-4-5-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');
        if LastIteration = '25-4-5-20' then exit;

        CrossDockMgt.CalculateCrossDockLines(CrossDockOpp, '', 'RE000002', 'WHITE');
        CrossDockOpp.SetRange("Source Name/No.", 'RE000002');
        CrossDockOpp.SetRange("Source Line No.", 20000);
        CrossDockOpp.SetRange("Line No.", 30000);
        CrossDockOpp.Find('-');
        CrossDockOpp."Qty. to Cross-Dock" := 1;
        CrossDockOpp.Modify(true);

        if LastIteration = '25-4-5-30' then exit;

        Clear(WhseRcptLine);
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '25-4-5-40' then exit;
        // 25-4-6
        Clear(UndoPurchaseReceiptLine);
        PurchRcptLine.SetRange("Line No.", 10000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);

        Clear(UndoPurchaseReceiptLine);
        PurchRcptLine.SetRange("Line No.", 20000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);

        Clear(UndoPurchaseReceiptLine);
        PurchRcptLine.SetRange("Line No.", 30000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);

        Clear(UndoPurchaseReceiptLine);
        PurchRcptLine.SetRange("Line No.", 40000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);

        if LastIteration = '25-4-6-10' then exit;
        // 25-4-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '25-4-7-10' then exit;
        // 25-4-8
        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Line No.", 10000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Line No.", 20000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        if LastIteration = '25-4-6-10' then exit;
        // 25-4-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '25-4-9-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnRcptLine: Record "Return Receipt Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '25-5-1-10' then exit;
        // 25-5-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 100, 'PCS', 17, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);
        if LastIteration = '25-5-2-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');
        if LastIteration = '25-5-2-20' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000001');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000001', 10000, 'Receive', 'W-08-0001', 20);
        if LastIteration = '25-5-2-30' then exit;

        WhseRcptLine.SetRange("No.", 'RE000001');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '25-5-2-40' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000001');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000001', 10000, 'Receive', 'W-08-0001', 10);
        if LastIteration = '25-5-2-50' then exit;

        WhseRcptLine.SetRange("No.", 'RE000001');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '25-5-2-60' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000001');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000001', 10000, 'Receive', 'W-08-0001', 25);
        if LastIteration = '25-5-2-70' then exit;

        WhseRcptLine.SetRange("No.", 'RE000001');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivHeader.Find('+');
        WhseActivHeader.Delete(true);
        if LastIteration = '25-5-2-80' then exit;

        TestScriptMgmt.CreatePutAwayWorksheet(WhseWkshLine, 'PUT-AWAY', 'DEFAULT', 'WHITE', 0, 'R_000003');
        if LastIteration = '25-5-2-90' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000001');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000001', 10000, 'Receive', 'W-08-0001', 31);
        if LastIteration = '25-5-2-100' then exit;

        WhseRcptLine.SetRange("No.", 'RE000001');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivHeader.Find('+');
        WhseActivHeader.Delete(true);
        if LastIteration = '25-5-2-110' then exit;
        // 25-5-3
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS25-5-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 100, 'PCS', 15, false);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        if LastIteration = '25-5-3-10' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');
        if LastIteration = '25-5-3-20' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000002');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000002', 10000, 'Receive', 'W-08-0001', 20);
        if LastIteration = '25-5-3-30' then exit;

        WhseRcptLine.SetRange("No.", 'RE000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivLine.SetRange("Source No.", '106001');
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '25-5-3-40' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000002');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000002', 10000, 'Receive', 'W-08-0001', 10);
        if LastIteration = '25-5-3-50' then exit;

        WhseRcptLine.SetRange("No.", 'RE000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '25-5-3-60' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000002');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000002', 10000, 'Receive', 'W-08-0001', 25);
        if LastIteration = '25-5-3-70' then exit;

        WhseRcptLine.SetRange("No.", 'RE000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivHeader.Find('+');
        WhseActivHeader.Delete(true);
        if LastIteration = '25-5-3-80' then exit;

        TestScriptMgmt.CreatePutAwayWorksheet(WhseWkshLine, 'PUT-AWAY', 'DEFAULT', 'WHITE', 0, 'R_000007');
        if LastIteration = '25-5-3-90' then exit;

        WhseRcptHeader.SetRange("No.", 'RE000002');
        WhseRcptHeader.Find('-');
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'RE000002', 10000, 'Receive', 'W-08-0001', 31);
        if LastIteration = '25-5-3-100' then exit;

        WhseRcptLine.SetRange("No.", 'RE000002');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivHeader.Find('+');
        WhseActivHeader.Delete(true);
        if LastIteration = '25-5-3-110' then exit;
        // 25-5-4
        Clear(UndoPurchaseReceiptLine);
        PurchRcptLine.SetRange("Document No.", '107004');
        PurchRcptLine.SetRange("Line No.", 10000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
        if LastIteration = '25-5-4-10' then exit;
        // 25-5-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '25-5-5-10' then exit;
        // 25-5-6
        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Document No.", '107004');
        ReturnRcptLine.SetRange("Line No.", 10000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);
        if LastIteration = '25-5-6-10' then exit;
        // 25-5-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '25-5-7-10' then exit;
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

