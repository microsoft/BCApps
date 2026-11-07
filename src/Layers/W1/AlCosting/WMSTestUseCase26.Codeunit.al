codeunit 103311 "WMS Test Use Case 26"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 26");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103311, 26, 0, '', 1);

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
        TrackingSpecification: Record "Tracking Specification";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        Bin: Record Bin;
        CalcQtyOnHand: Report "Calculate Inventory";
        ConvertLocationToWMS: Report "Create Warehouse Location";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoSalesShipmentLine: Codeunit "Undo Sales Shipment Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '26-1-1-10' then exit;

        Item.Get('80100');
        Item."Put-away Unit of Measure Code" := 'Box';
        Item.Modify(true);
        if LastIteration = '26-1-1-20' then exit;
        // 26-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS26-1-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'Blue', 3, 'PALLET', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '', 'Blue', 10, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_TEST', '', 'Blue', 10, 'PALLET', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B_TEST', '', 'Blue', 11, 'PALLET', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'C_TEST', '31', 'Blue', 100, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'A_TEST', '11', 'Blue', 10, 'PALLET', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 70000, PurchLine.Type::Item, 'A_TEST', '12', 'Blue', 10, 'PALLET', 100, false);
        if LastIteration = '26-1-2-10' then exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '26-1-2-20' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Blue', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 3, 'PCS', 33.77, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 4, 'BOX', 1, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_Test', '', 3, 'PCS', 100, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'C_Test', '', 7, 'PCS', 100, 'Blue', '');
        if LastIteration = '26-1-2-30' then exit;

        SalesHeader.Receive := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '26-1-2-40' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Blue', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 3, 'PCS', 33.77, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 4, 'Pack', 1, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_Test', '', 5, 'PCS', 100, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'C_Test', '', 1, 'Pallet', 100, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 50000, SalesLine.Type::Item, 'A_Test', '', 5, 'Pallet', 100, 'Blue', '');
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst();
        SalesLine."Appl.-to Item Entry" := 3;
        SalesLine.Modify(true);
        if LastIteration = '26-1-2-50' then exit;

        SalesHeader.Ship := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '26-1-2-60' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS26-1-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T1', 'Blue', 5, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T2', 'Blue', 10, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'Blue', 10, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'C_TEST', '', 'Blue', 10, 'PALLET', 100, false);
        if LastIteration = '26-1-2-70' then exit;

        SNCode := 'SN00';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN10';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 10, 10, '', 'LOT01');
        CreateRes.CreateEntry('80002', '', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '26-1-2-80' then exit;

        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '26-1-2-90' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS26-1-4', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T1', 'Blue', 5, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T2', 'Blue', 10, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'Blue', 20, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'C_TEST', '32', 'Blue', 100, 'PCS', 100, false);
        if LastIteration = '26-1-2-100' then exit;

        SNCode := 'SN05';
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN20';
        for i := 1 to 7 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 20, 20, '', 'LOT02');
        CreateRes.CreateEntry('80002', '', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '26-1-2-110' then exit;

        Clear(PurchHeader);
        PurchHeader.SetRange("No.", '106003');
        PurchHeader.FindFirst();
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 3, 0, 0, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 7, 0, 0, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 13, 0, 0, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 40, 0, 0, 0);

        ResEntry.SetRange("Lot No.", 'LOT02');
        ResEntry.FindFirst();
        ResEntry.Validate("Qty. to Handle (Base)", 13);
        ResEntry.Validate("Qty. to Invoice (Base)", 0);
        ResEntry.Modify(true);

        ResEntry.SetRange("Item No.", 'T_TEST');
        if ResEntry.Find('-') then
            repeat
                ResEntry.Validate("Qty. to Invoice (Base)", 0);
                ResEntry.Modify(true);
            until ResEntry.Next() = 0;
        if LastIteration = '26-1-2-120' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '26-1-2-130' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Blue', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T1', 2, 'BOX', 96, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', 'T2', 2, 'BOX', 96, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80002', '', 5, 'PCS', 100, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'C_Test', '31', 100, 'PCS', 100, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 50000, SalesLine.Type::Item, 'B_Test', '', 100, 'PCS', 100, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '80100', '', 2, 'PALLET', 32, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 70000, SalesLine.Type::Item, 'A_Test', '12', 70, 'PCS', 100, 'Blue', '');
        if LastIteration = '26-1-2-140' then exit;

        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN07', '');
        CreateRes.CreateEntry('T_TEST', 'T1', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN27', '');
        CreateRes.CreateEntry('T_TEST', 'T2', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 3, 3, '', 'LOT02');
        CreateRes.CreateEntry('80002', '', 'Blue', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '26-1-2-150' then exit;

        TestScriptMgmt.CreateReservation
          ('C_Test', '31', 'Blue', '', '', 100, 1, "Reservation Status"::Reservation, 32, 0, 5, 20011125D, -100, 1, 37, 1, '1002', 40000);
        TestScriptMgmt.CreateReservation
          ('A_Test', '12', 'Blue', '', '', 70, 13, "Reservation Status"::Reservation, 32, 0, 7, 20011125D, -70, 1, 37, 1, '1002', 70000);
        if LastIteration = '26-1-2-160' then exit;

        Clear(SalesHeader);
        SalesHeader.SetRange("No.", '1002');
        SalesHeader.FindFirst();
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 1, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 1, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 3, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 50000, 100, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 60000, 1, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 70000, 39, 0, 0, 0, false);

        if TrackingSpecification.Find('-') then
            repeat
                TrackingSpecification.Validate("Qty. to Invoice (Base)", 0);
                TrackingSpecification.Modify(true);
            until TrackingSpecification.Next() = 0;
        if LastIteration = '26-1-2-170' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '26-1-2-180' then exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'D_PROD', 14, 'Blue');
        ProdOrder.Validate("Starting Date", 20011125D);
        ProdOrder.Validate("Ending Date", 20011125D);
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Modify(true);

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '26-1-2-190' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 'Blue', 20011125D, ProdOrder."No.", 'C_Test', '32', 7, 10000);
        if LastIteration = '26-1-2-200' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20011125D, ProdOrder."No.", 'D_Prod', 10, 'PCS');
        if LastIteration = '26-1-2-210' then exit;

        TestScriptMgmt.InsertTransferHeader(TransHeader, 'BLUE', 'RED', 'OWN LOG.', 20011125D);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 10000, '80100', '', 'BOX', 10, 0, 10);
        TestScriptMgmt.PostTransferOrder(TransHeader);
        if LastIteration = '26-1-2-220' then exit;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 10000, 20011125D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS26-1-5', 'C_TEST', '31', 'BLUE', '', 10, 'PCS', 100, 0);
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = '26-1-2-230' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '60000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Blue', 'TCS26-1-6', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '11', 'Blue', 15, 'PCS', 115, false);

        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '26-1-2-240' then exit;

        Commit();
        PurchRcptLine.SetRange("Document No.", '107004');
        PurchRcptLine.FindFirst();
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
        if LastIteration = '26-1-2-250' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Blue', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'C_Test', '32', 13, 'PCS', 96, 'Blue', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'A_Test', '11', 13, 'PCS', 96, 'Blue', '');
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 8, 0, 0, 0, false);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 13, 0, 0, 0, false);
        TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = '26-1-2-260' then exit;

        SalesShipmentLine.SetRange("Document No.", '102003');
        SalesShipmentLine.SetRange("Line No.", 10000, 20000);
        if SalesShipmentLine.Find('-') then begin
            UndoSalesShipmentLine.SetHideDialog(true);
            repeat
                UndoSalesShipmentLine.Run(SalesShipmentLine);
            until SalesShipmentLine.Next() = 0;
        end;
        if LastIteration = '26-1-2-270' then exit;

        Item.Get('A_TEST');
        Item.Blocked := true;
        Item.Modify(true);
        if LastIteration = '26-1-2-280' then exit;
        // 26-1-3
        Bin.Init();
        Bin."Location Code" := 'BLUE';
        Bin.Code := 'C1';
        if not Bin.Insert(true) then
            Bin.Modify(true);
        if LastIteration = '26-1-3-10' then exit;

        Commit();
        Clear(ConvertLocationToWMS);
        ConvertLocationToWMS.SetHideValidationDialog(true);
        ConvertLocationToWMS.InitializeRequest('Blue', 'C1');
        ConvertLocationToWMS.UseRequestPage(false);
        ConvertLocationToWMS.RunModal();
        Clear(ConvertLocationToWMS);
        if LastIteration = '26-1-3-20' then exit;
        // 26-1-4
        Item.Get('A_TEST');
        Item.Blocked := false;
        Item.Modify(true);
        if LastIteration = '26-1-4-10' then exit;

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
        if LastIteration = '26-1-4-20' then exit;
        // 26-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '26-1-5-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        Bin: Record Bin;
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        CalcQtyOnHand: Report "Calculate Inventory";
        WhseSrcCreateDoc: Report "Whse.-Source - Create Document";
        ConvertLocationToWMS: Report "Create Warehouse Location";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        WhseActivRegister: Codeunit "Whse.-Activity-Register";
        SNCode: Code[20];
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '26-2-1-10' then exit;

        Item.Get('80100');
        Item."Put-away Unit of Measure Code" := 'Box';
        Item.Modify(true);
        if LastIteration = '26-2-1-20' then exit;
        // 26-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', 'TCS26-2-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'Green', 3, 'PALLET', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '', 'Green', 10, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_TEST', '', 'Green', 10, 'PALLET', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'B_TEST', '', 'Green', 11, 'PALLET', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'C_TEST', '31', 'Green', 100, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 60000, PurchLine.Type::Item, 'A_TEST', '11', 'Green', 10, 'PALLET', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 70000, PurchLine.Type::Item, 'A_TEST', '12', 'Green', 10, 'PALLET', 100, false);
        if LastIteration = '26-2-2-10' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'Green');
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '26-2-2-20' then exit;

        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '26-2-2-30' then exit;

        PurchHeader.Find('-');
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '26-2-2-40' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Green', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 3, 'PCS', 33.77, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 4, 'BOX', 1, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_Test', '', 3, 'PCS', 100, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'C_Test', '', 7, 'PCS', 100, 'Green', '');
        if LastIteration = '26-2-2-50' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'Green');
        Clear(WhseRcptLine);
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '26-2-2-60' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '26-2-2-70' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Green', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 3, 'PCS', 33.77, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 4, 'Pack', 1, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'B_Test', '', 5, 'PCS', 100, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'C_Test', '', 1, 'Pallet', 100, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 50000, SalesLine.Type::Item, 'A_Test', '', 5, 'Pallet', 100, 'Green', '');
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst();
        SalesLine."Appl.-to Item Entry" := 3;
        SalesLine.Modify(true);
        if LastIteration = '26-2-2-80' then exit;

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.FindFirst();
        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);
        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'Green');
        WhseShptHeader.FindFirst();
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);
        if LastIteration = '26-2-2-90' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        WhseShptLine.FindFirst();
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);
        if LastIteration = '26-2-2-100' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', 'TCS26-2-3', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T1', 'Green', 5, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T2', 'Green', 10, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'Green', 10, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'C_TEST', '', 'Green', 10, 'PALLET', 100, false);
        if LastIteration = '26-2-2-110' then exit;

        SNCode := 'SN00';
        for i := 1 to 5 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN10';
        for i := 1 to 10 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 10, 10, '', 'LOT01');
        CreateRes.CreateEntry('80002', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '26-2-2-120' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'Green');
        Clear(WhseRcptLine);
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        if LastIteration = '26-2-2-130' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '26-2-2-140' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', 'TCS26-2-4', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'T_TEST', 'T1', 'Green', 5, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'T_TEST', 'T2', 'Green', 10, 'BOX', 96, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '80002', '', 'Green', 20, 'PCS', 100, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'C_TEST', '32', 'Green', 100, 'PCS', 100, false);
        if LastIteration = '26-2-2-150' then exit;

        SNCode := 'SN05';
        for i := 1 to 3 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        SNCode := 'SN20';
        for i := 1 to 7 do begin
            SNCode := IncStr(SNCode);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 1, 1, SNCode, '');
            CreateRes.CreateEntry('T_TEST', 'T2', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        end;
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 20, 20, '', 'LOT02');
        CreateRes.CreateEntry('80002', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '26-2-2-160' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'Green');
        Clear(WhseRcptLine);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'Re000004', 10000, '', '', 3);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'Re000004', 20000, '', '', 7);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'Re000004', 30000, '', '', 13);
        TestScriptMgmt.ModifyWhseRcptLine(WhseRcptLine, 'Re000004', 40000, '', '', 40);
        if LastIteration = '26-2-2-170' then exit;

        Clear(WhseRcptLine);
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseRcptHeader.FindFirst();
        WhseRcptHeader.DeleteRelatedLines(false);
        WhseRcptHeader.Delete(false);
        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        if LastIteration = '26-2-2-180' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Green', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'T_Test', 'T1', 2, 'BOX', 96, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'T_Test', 'T2', 2, 'BOX', 96, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80002', '', 5, 'PCS', 100, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, 'C_Test', '31', 100, 'PCS', 100, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 50000, SalesLine.Type::Item, 'B_Test', '', 100, 'PCS', 100, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '80100', '', 2, 'PALLET', 32, 'Green', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 70000, SalesLine.Type::Item, 'A_Test', '12', 70, 'PCS', 100, 'Green', '');
        if LastIteration = '26-2-2-190' then exit;

        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN07', '');
        CreateRes.CreateEntry('T_TEST', 'T1', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN27', '');
        CreateRes.CreateEntry('T_TEST', 'T2', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 3, 3, '', 'LOT02');
        CreateRes.CreateEntry('80002', '', 'Green', '', 20011125D, 20011125D, 0, "Reservation Status"::Surplus);
        if LastIteration = '26-2-2-200' then exit;

        TestScriptMgmt.CreateReservation
          ('C_Test', '31', 'Green', '', '', 100, 1, "Reservation Status"::Reservation, 32, 0, 5, 20011125D, -100, 1, 37, 1, '1002', 40000);
        TestScriptMgmt.CreateReservation
          ('A_Test', '12', 'Green', '', '', 70, 13, "Reservation Status"::Reservation, 32, 0, 7, 20011125D, -70, 1, 37, 1, '1002', 70000);
        if LastIteration = '26-2-2-210' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);
        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'Green');
        WhseShptHeader.FindFirst();
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);
        if LastIteration = '26-2-2-220' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 40000, '', '', 0);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 60000, '', '', 1);
        TestScriptMgmt.ModifyWhseActLine(WhseActivLine, WhseActivLine."Activity Type", WhseActivLine."No.", 70000, '', '', 39);
        if LastIteration = '26-2-2-230' then exit;

        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        Clear(WhseShptLine);
        WhseShptLine.FindFirst();
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);
        if LastIteration = '26-2-2-240' then exit;

        WhseActivHeader.Find('-');
        WhseActivHeader.DeleteAll(true);
        WhseShptHeader.FindFirst();
        WhseShptHeader.Status := WhseShptHeader.Status::Open;
        WhseShptHeader.Modify(true);
        WhseShptHeader.DeleteAll(true);
        if LastIteration = '26-2-2-250' then exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'D_PROD', 14, 'Green');
        ProdOrder.Validate("Starting Date", 20011125D);
        ProdOrder.Validate("Ending Date", 20011125D);
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Modify(true);

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        if LastIteration = '26-2-2-260' then exit;

        WhseSrcCreateDoc.SetProdOrder(ProdOrder);
        WhseSrcCreateDoc.SetHideValidationDialog(true);
        WhseSrcCreateDoc.UseRequestPage(false);
        WhseSrcCreateDoc.RunModal();

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WhseActivLine.SetRange("Source Subtype", ProdOrder.Status);
        WhseActivLine.SetRange("Source No.", ProdOrder."No.");
        WhseActivLine.FindFirst();
        WhseActivRegister.Run(WhseActivLine);

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 'Green', 20011125D, ProdOrder."No.", 'C_Test', '32', 7, 10000);
        if LastIteration = '26-2-2-270' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20011125D, ProdOrder."No.", 'D_Prod', 10, 'PCS');
        if LastIteration = '26-2-2-280' then exit;

        TestScriptMgmt.InsertTransferHeader(TransHeader, 'Green', 'RED', 'OWN LOG.', 20011125D);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 10000, '80100', '', 'BOX', 10, 0, 10);
        TestScriptMgmt.ReleaseTransferOrder(TransHeader);
        TestScriptMgmt.CreateWhseShptFromTrans(TransHeader, WhseShptHeader);
        WhseShptHeader.FindFirst();
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);
        Clear(WhseActivLine);
        WhseActivLine.FindFirst();
        TestScriptMgmt.PostWhseActivity(WhseActivLine);
        Clear(WhseShptLine);
        WhseShptLine.FindFirst();
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);
        if LastIteration = '26-2-2-290' then exit;

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 10000, 20011125D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS26-2-5', 'C_TEST', '31', 'Green', '', 10, 'PCS', 100, 0);
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = '26-2-2-300' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '60000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'Green', 'TCS26-2-6', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '11', 'Green', 15, 'PCS', 115, false);
        TestScriptMgmt.ReleasePurchDocument(PurchHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'GREEN');
        Clear(WhseRcptLine);
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivHeader.FindFirst();
        WhseActivHeader.DeleteAll(true);
        if LastIteration = '26-2-2-310' then exit;

        Commit();
        PurchRcptLine.SetRange("Document No.", '107004');
        PurchRcptLine.FindFirst();
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
        if LastIteration = '26-2-2-320' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'Green', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_Test', '', 3, 'PCS', 33.77, 'Green', '');
        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);
        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'Green');
        Clear(WhseRcptLine);
        WhseRcptLine.FindFirst();
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);
        WhseActivHeader.Find('-');
        WhseActivHeader.DeleteAll(true);
        if LastIteration = '26-2-2-330' then exit;

        ReturnRcptLine.SetRange("Document No.", '107002');
        ReturnRcptLine.FindFirst();
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);
        if LastIteration = '26-2-2-340' then exit;

        Item.Get('A_TEST');
        Item.Blocked := true;
        Item.Modify(true);
        if LastIteration = '26-2-2-350' then exit;
        // 26-2-3
        Bin.Init();
        Bin."Location Code" := 'Green';
        Bin.Code := 'C1';
        if not Bin.Insert(true) then
            Bin.Modify(true);
        if LastIteration = '26-2-3-10' then exit;

        Commit();
        Clear(ConvertLocationToWMS);
        ConvertLocationToWMS.SetHideValidationDialog(true);
        ConvertLocationToWMS.InitializeRequest('Green', 'C1');
        ConvertLocationToWMS.UseRequestPage(false);
        ConvertLocationToWMS.RunModal();
        Clear(ConvertLocationToWMS);
        if LastIteration = '26-2-3-20' then exit;
        // 26-2-4
        Item.Get('A_TEST');
        Item.Blocked := false;
        Item.Modify(true);
        if LastIteration = '26-2-4-10' then exit;

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
        if LastIteration = '26-2-4-20' then exit;
        // 26-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '26-2-5-10' then exit;
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

