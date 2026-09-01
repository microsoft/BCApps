codeunit 103322 "WMS Test Use Case 28"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 28");

        QASetup.ModifyAll("Use Hardcoded Reference", true);
        Test(103331, 28, 0, '', 1);

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        Item: Record Item;
        TestCase: Record "Whse. Test Case";
        UseCase: Record "Whse. Use Case";
        SelectionForm: Page "Whse. Test Selection";
        TestScriptMgmt: Codeunit "WMS TestscriptManagement";
        CETAFTestscriptManagement: Codeunit _TestscriptManagement;
        LibraryManufacturing: Codeunit "Library - Manufacturing";
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
        //  5: PerformTestCase5;
        //  6: PerformTestCase6;
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
        WhseRcptLine2: Record "Warehouse Receipt Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ReturnRcptLine: Record "Return Receipt Line";
        ResEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        AutoReserv: Boolean;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '28-1-1-10' then exit;

        Item.Get('N_TEST');
        Item."Item Tracking Code" := 'FREEENTRY';
        Item.Modify(true);

        Item.Get('80100');
        Item."Item Tracking Code" := 'LOTALL';
        Item.Modify(true);

        Location.SetRange(Code, 'white');
        Location.Find('-');
        Location."Always Create Pick Line" := true;
        Location.Modify(true);

        if LastIteration = '28-1-1-20' then exit;
        // 28-1-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '62000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS28-1-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'BLUE', 2, 'PALLET', 30000, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 2, 0, 30000, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'BLUE', 3, 'PALLET', 133.35, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 3, 0, 133.35, 0);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'N_TEST', '', 'BLUE', 2, 'PCS', 58.23, false);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 1, 0, 58.23, 0);

        if LastIteration = '28-1-2-10' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'BLUE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 35, 70, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 39, 1, PurchHeader."No.", '', 0, 20000, 32, 96, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LT01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('N_TEST', '', 'BLUE', '', '', 39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, 'SN01', '', 0D, 0D);

        if LastIteration = '28-1-2-20' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '28-1-2-30' then exit;

        PurchRcptLine.SetRange("Line No.", 30000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);

        if LastIteration = '28-1-2-40' then exit;

        PurchHeader.Find('-');
        ReleasePurchDoc.Reopen(PurchHeader);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 2, 0, 58.23, 0);

        ResEntry.SetRange("Item No.", 'N_TEST');
        ResEntry.Find('-');
        ResEntry.Delete(true);

        if LastIteration = '28-1-2-50' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '28-1-2-60' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '62000', 20011129D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 3, 'PCS', 1120, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 3, 'BOX', 5.99, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80100', '', 3, 'PACK', 1.21, 'WHITE', '');

        if LastIteration = '28-1-2-70' then exit;

        TestScriptMgmt.InsertTransferHeader(TransHeader, 'BLUE', 'WHITE', 'OWN LOG.', 20011126D);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 10000, '80002', '', 'PCS', 3, 0, 3);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 20000, '80100', '', 'BOX', 3, 0, 3);
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", 30000, '80100', '', 'PACK', 3, 0, 3);

        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'BLUE', '', '', 5741, 0, TransLine."Document No.", '', 0, 10000, 1, 3, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 5741, 0, TransLine."Document No.", '', 0, 20000, 1, 3, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LT01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 5741, 0, TransLine."Document No.", '', 0, 30000, 1, 0.6, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LT01', 0D, 0D);

        if LastIteration = '28-1-2-80' then exit;

        SalesLine.Reset();
        if SalesLine.Find('-') then
            repeat
                ReservMgt.SetReservSource(SalesLine);
                ReservMgt.AutoReserve(AutoReserv, '', 20011129D, SalesLine.Quantity, SalesLine."Quantity (Base)");
            until SalesLine.Next() = 0;

        if LastIteration = '28-1-2-90' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-1-2-100' then exit;

        TestScriptMgmt.PostTransferOrder(TransHeader);

        if LastIteration = '28-1-2-110' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '62000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', '', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'WHITE', 3, 'PALLET', 30000, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'WHITE', 4, 'PALLET', 133.35, false);

        if LastIteration = '28-1-2-120' then exit;

        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LN03', 35, 35, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LN04', 35, 35, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80002', '', 'WHITE', '', 'LN05', 35, 35, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 10000, true);

        TestScriptMgmt.CreateItemTrackfromJnlLine('80100', '', 'WHITE', '', 'LT02', 32, 32, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80100', '', 'WHITE', '', 'LT03', 64, 32, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('80100', '', 'WHITE', '', 'LT04', 32, 32, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);

        if LastIteration = '28-1-2-130' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '28-1-2-140' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-1-2-150' then exit;

        Clear(WhseActivLine);
        WhseActivLine.SetFilter("Lot No.", '<>%1', 'LN03');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Qty. to Handle", 0);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Lot No.", 'LT03');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Qty. to Handle", 2);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-1-2-160' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-1-2-170' then exit;
        // 28-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '28-1-3-10' then exit;
        // 28-1-4
        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');

        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'CUST30000');

        if LastIteration = '28-1-4-10' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-1-4-20' then exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", 1);
        if WhseActivLine.Find('-') then
            repeat
                TestScriptMgmt.PostWhseActivity(WhseActivLine);
            until WhseActivLine.Next() = 0;

        if LastIteration = '28-1-4-30' then exit;

        Clear(WhseActivHeader);
        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Pick);
        WhseActivHeader.DeleteAll(true);

        if LastIteration = '28-1-4-40' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-1-4-50' then exit;

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LN01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.SetRange("Item No.", '80100');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LT01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-1-4-60' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '28-1-4-70' then exit;
        // 28-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '28-1-5-10' then exit;
        // 28-1-6
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '61000', 20011129D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 3, 'PCS', 1120, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 3, 'BOX', 5.99, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'GPS', '', 2, '', 100, 'WHITE', '');

        if LastIteration = '28-1-6-10' then exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 10000, "Reservation Status"::Surplus, 20011130D, '80002', '', '', 'LN03', 1, 1, 37, 1, SalesHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 10000, "Reservation Status"::Surplus, 20011130D, '80002', '', '', 'LN04', 1, 1, 37, 1, SalesHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 10000, "Reservation Status"::Surplus, 20011130D, '80002', '', '', 'LN05', 1, 1, 37, 1, SalesHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 20000, "Reservation Status"::Surplus, 20011130D, '80100', '', '', 'LT02', 1, 1, 37, 1, SalesHeader."No.", '', 20000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 20000, "Reservation Status"::Surplus, 20011130D, '80100', '', '', 'LT03', 2, 2, 37, 1, SalesHeader."No.", '', 20000, true);

        if LastIteration = '28-1-6-20' then exit;

        CETAFTestscriptManagement.InsertSalesChargeAssignLine(
          SalesLine, 10000, SalesLine."Document Type", SalesLine."Document No.", 10000, '80002');
        CETAFTestscriptManagement.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);

        CETAFTestscriptManagement.InsertSalesChargeAssignLine(
          SalesLine, 20000, SalesLine."Document Type", SalesLine."Document No.", 20000, '80100');
        CETAFTestscriptManagement.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);

        if LastIteration = '28-1-6-30' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-1-6-40' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('+');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-1-6-50' then exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-1-6-60' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '28-1-6-70' then exit;
        // 28-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '28-1-7-10' then exit;
        // 28-1-8
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '62000', 20011129D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 3, 'PCS', 1120, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 17, 'PACK', 1.21, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80100', '', 1, 'PALLET', 175, 'WHITE', '');

        if LastIteration = '28-1-8-10' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-1-8-20' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-1-8-30' then exit;

        Clear(WhseActivLine);

        WhseActivLine.SetFilter("Item No.", '%1', '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LN03');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        Clear(WhseActivLine);
        WhseActivLine.SetFilter("Item No.", '%1', '80100');
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SetRange("Unit of Measure Code", 'PACK');
            if WhseActivLine.Find('-') then
                repeat
                    WhseActivLine.Validate("Lot No.", 'LT03');
                    WhseActivLine.Validate("Qty. to Handle", 0);
                    WhseActivLine.Modify(true);
                until WhseActivLine.Next() = 0;

            WhseActivLine.SetRange("Unit of Measure Code", 'BOX');
            if WhseActivLine.Find('-') then
                repeat
                    WhseActivLine.Validate("Lot No.", 'LT03');
                    WhseActivLine.Validate("Qty. to Handle", 0);
                    WhseActivLine.Modify(true);
                until WhseActivLine.Next() = 0;

            WhseActivLine.SetRange("Unit of Measure Code", 'PALLET');
            if WhseActivLine.Find('-') then
                repeat
                    WhseActivLine.Validate("Lot No.", 'LT04');
                    WhseActivLine.Validate("Qty. to Handle", 0);
                    WhseActivLine.Modify(true);
                until WhseActivLine.Next() = 0;
        end;

        if LastIteration = '28-1-8-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-1-8-50' then exit;
        // 28-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '28-1-9-10' then exit;
        // 28-1-10
        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-1-10-10' then exit;

        WhseShptLine.Reset();
        WhseShptLine.SetFilter("Item No.", '%1', '80100');
        if WhseShptLine.Find('-') then
            repeat
                WhseShptLine.Validate("Qty. to Ship", 0);
                WhseShptLine.Modify(true);
            until WhseShptLine.Next() = 0;

        if LastIteration = '28-1-10-20' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '28-1-10-30' then exit;
        // 28-1-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '28-1-11-10' then exit;
        // 28-1-12
        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        WhseShptLine.AutofillQtyToHandle(WhseShptLine);
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '28-1-12-10' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011201D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011201D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80002', '', 1, 'PCS', 1120, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 1, 'PALLET', 175, 'WHITE', '');

        if LastIteration = '28-1-12-20' then exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 10000, "Reservation Status"::Surplus, 20011201D, '80002', '', '', 'LN03', 1, 1, 37, 5, SalesHeader."No.", '', 10000, true);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 20000, "Reservation Status"::Surplus, 20011201D, '80100', '', '', 'LT04', 1, 32, 37, 5, SalesHeader."No.", '', 20000, true);

        if LastIteration = '28-1-12-30' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '28-1-12-40' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.SetRange("Item No.", '80002');
        if WhseRcptLine.Find('-') then begin
            WhseRcptLine.Validate("Qty. to Receive", 0);
            WhseRcptLine.Modify(true);
        end;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        WhseRcptLine.Find('-');
        WhseRcptLine.AutofillQtyToReceive(WhseRcptLine);

        if LastIteration = '28-1-12-50' then exit;

        Clear(WhseActivHeader);
        if WhseActivHeader.Find('-') then
            WhseActivHeader.DeleteAll(true);

        if LastIteration = '28-1-12-60' then exit;

        Clear(UndoReturnReceiptLine);
        ReturnRcptLine.SetRange("Document No.", '107001');
        ReturnRcptLine.SetRange("Line No.", 20000);
        ReturnRcptLine.Find('-');
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);

        if LastIteration = '28-1-12-70' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');
        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'vend10000');

        if LastIteration = '28-1-12-80' then exit;

        WhseRcptLine.Reset();
        if WhseRcptLine.Find('-') then
            repeat
                WhseRcptLine2.Get(WhseRcptLine."No.", WhseRcptLine."Line No.");
                TestScriptMgmt.PostWhseReceipt(WhseRcptLine2);
            until WhseRcptLine.Next() = 0;

        if LastIteration = '28-1-12-90' then exit;

        Clear(WhseActivLine);
        if WhseActivLine.Find('-') then
            repeat
                TestScriptMgmt.PostWhseActivity(WhseActivLine);
            until WhseActivLine.Next() = 0;

        if LastIteration = '28-1-12-100' then exit;
        // 28-1-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo);

        if LastIteration = '28-1-13-10' then exit;
        // 28-1-14
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011203D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011203D, 'WHITE', '', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'WHITE', 4, 'PALLET', 30000, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'WHITE', 5, 'PALLET', 133.35, false);

        if LastIteration = '28-1-14-10' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 35, 140, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011203D, '', 'LN06', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 20000, 32, 160, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011203D, '', 'LT04', 0D, 0D);

        if LastIteration = '28-1-14-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '28-1-14-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.SetRange(WhseRcptLine."Item No.", '80100');
        if WhseRcptLine.Find('-') then begin
            WhseRcptLine.Validate("Qty. to Receive", 0);
            WhseRcptLine.Modify(true);
        end;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-1-14-40' then exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Put-away");
        if WhseActivHeader.Find('-') then
            WhseActivHeader.DeleteAll(true);

        if LastIteration = '28-1-14-50' then exit;

        Clear(UndoPurchaseReceiptLine);
        PurchRcptLine.SetRange("Document No.", '107004');
        PurchRcptLine.SetRange("Line No.", 10000);
        PurchRcptLine.Find('-');
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);

        if LastIteration = '28-1-14-60' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');
        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'Vend10000');

        if LastIteration = '28-1-14-70' then exit;

        WhseRcptLine.Reset();
        if WhseRcptLine.Find('-') then
            repeat
                WhseRcptLine.Validate("Qty. to Receive", 3);
                WhseRcptLine.Modify(true);
            until WhseRcptLine.Next() = 0;

        if LastIteration = '28-1-14-80' then exit;

        WhseRcptLine.Reset();
        if WhseRcptLine.Find('-') then
            repeat
                WhseRcptLine2.Get(WhseRcptLine."No.", WhseRcptLine."Line No.");
                TestScriptMgmt.PostWhseReceipt(WhseRcptLine2);
            until WhseRcptLine.Next() = 0;

        if LastIteration = '28-1-14-90' then exit;

        Clear(WhseActivLine);
        if WhseActivLine.Find('-') then
            repeat
                TestScriptMgmt.PostWhseActivity(WhseActivLine);
            until WhseActivLine.Next() = 0;

        if LastIteration = '28-1-14-100' then exit;
        // 28-1-15
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 15, LastILENo);

        if LastIteration = '28-1-15-10' then exit;
        // 28-1-16
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 20011204D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011204D, 'WHITE', '', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80002', '', 'WHITE', 1, 'PALLET', 1074, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'PALLET', 133.35, false);

        if LastIteration = '28-1-16-10' then exit;

        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 10000, "Reservation Status"::Surplus, 20011204D, '80002', '', '', 'LN06', -1, -35, 39, 5, PurchHeader."No.", '', 10000, false);
        TestScriptMgmt.InsertResEntry(
          ResEntry, 'WHITE', 20000, "Reservation Status"::Surplus, 20011204D, '80100', '', '', 'LT04', -1, -32, 39, 5, PurchHeader."No.", '', 20000, false);

        if LastIteration = '28-1-16-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromPurch(PurchHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-1-16-30' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-1-16-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-1-16-50' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '28-1-16-60' then exit;
        // 28-1-17
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 17, LastILENo);

        if LastIteration = '28-1-17-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
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
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemUnitofMeasure2: Record "Item Unit of Measure";
        WhseItemJnlLine: Record "Warehouse Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseIntPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseIntPutAwayOrderLine: Record "Whse. Internal Put-away Line";
        WhsePickOrderHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        CalculateWhseAdjustment: Report "Calculate Whse. Adjustment";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        ReservMgt: Codeunit "Reservation Management";
        AutoReserv: Boolean;
        WhseWkshLineNo: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '28-2-1-10' then exit;

        Item.Get('80100');
        Item."Item Tracking Code" := 'LOTALL';
        Item.Modify(true);
        ItemUnitofMeasure.Init();
        ItemUnitofMeasure."Item No." := Item."No.";
        ItemUnitofMeasure.Validate(Code, 'PCS');
        ItemUnitofMeasure.Validate("Qty. per Unit of Measure", 2.5);
        if not ItemUnitofMeasure.Insert() then
            ItemUnitofMeasure.Modify();

        Item.Get('N_TEST');
        ItemUnitofMeasure.Get(Item."No.", 'PCS');
        ItemUnitofMeasure2.Init();
        ItemUnitofMeasure2 := ItemUnitofMeasure;
        ItemUnitofMeasure2.Code := 'L';
        if not ItemUnitofMeasure2.Insert() then
            ItemUnitofMeasure2.Modify();
        ItemUnitofMeasure.Delete();

        ItemUnitofMeasure.Init();
        ItemUnitofMeasure."Item No." := Item."No.";
        ItemUnitofMeasure.Validate(Code, 'CAN');
        ItemUnitofMeasure.Validate("Qty. per Unit of Measure", 3.33333);
        if not ItemUnitofMeasure.Insert() then
            ItemUnitofMeasure.Modify();

        Item."Item Tracking Code" := 'LOTALL';
        Item.Validate("Purch. Unit of Measure", 'L');
        Item."Base Unit of Measure" := 'L';
        Item.Modify();

        if LastIteration = '28-2-1-20' then exit;
        // 28-2-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS28-2-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '80100', '', 'WHITE', 1, 'PCS', 33.35, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'N_TEST', '', 'WHITE', 0.5, 'CAN', 58.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A_TEST', '', 'WHITE', 1, 'PALLET', 123.12, false);

        if LastIteration = '28-2-2-10' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 1, 2.5, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('N_TEST', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 20000, 1, 1.66667, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LT01', 0D, 0D);

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        if LastIteration = '28-2-2-20' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '28-2-2-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-2-2-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-2-2-50' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '62000', 20011126D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011126D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A_TEST', '', 1, 'PCS', 120, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 0.5, 'PCS', 11.2, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, 'N_TEST', '', 0.25, 'CAN', 210, 'WHITE', '');

        if LastIteration = '28-2-2-60' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'WHITE', '', '', 37, 1, SalesHeader."No.", '', 0, 20000, 1, 1.25, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('N_TEST', '', 'WHITE', '', '', 37, 1, SalesHeader."No.", '', 0, 30000, 1, 0.83333, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LT01', 0D, 0D);

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '28-2-2-70' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-2-2-80' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-2-2-90' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-2-2-100' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '28-2-2-110' then exit;

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '62000', 20011126D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011126D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 1, 'BOX', 5.99, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'N_TEST', '', 0.25, 'CAN', 145, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80100', '', 1, 'PACK', 1.12, 'WHITE', '');

        if LastIteration = '28-2-2-120' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'WHITE', '', '', 37, 1, SalesHeader."No.", '', 0, 10000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('N_TEST', '', 'WHITE', '', '', 37, 1, SalesHeader."No.", '', 0, 20000, 1, 0.83333, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LT01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'WHITE', '', '', 37, 1, SalesHeader."No.", '', 0, 30000, 0.2, 0.2, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011126D, '', 'LN01', 0D, 0D);

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '28-2-2-130' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-2-2-140' then exit;

        Clear(WhseShptHeader);
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-2-2-150' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-2-2-160' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, false);

        if LastIteration = '28-2-2-170' then exit;
        // 28-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '28-2-3-10' then exit;
        // 28-2-4
        Commit();
        TestScriptMgmt.InsertAdjmtWhseJnlLine(
          WhseItemJnlLine, 'ADJMT', 'DEFAULT', 'White', 10000, 20011128D, '80100', '', 'PICK', 'W-03-0001', 3, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(
          WhseItemJnlLine, 'ADJMT', 'DEFAULT', 'White', 20000, 20011128D, '80100', '', 'PICK', 'W-03-0002', 3, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(
          WhseItemJnlLine, 'ADJMT', 'DEFAULT', 'White', 30000, 20011128D, '80100', '', 'PICK', 'W-03-0003', 3, 'PACK');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(
          WhseItemJnlLine, 'ADJMT', 'DEFAULT', 'White', 40000, 20011128D, '80002', '', 'PICK', 'W-04-0001', 3, 'PALLET');
        TestScriptMgmt.InsertAdjmtWhseJnlLine(
          WhseItemJnlLine, 'ADJMT', 'DEFAULT', 'White', 50000, 20011128D, '80002', '', 'PICK', 'W-04-0002', 3, 'PALLET');

        if LastIteration = '28-2-4-10' then exit;

        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN02', 96, 1, 7311, 0, 'DEFAULT', 'ADJMT', 0, 10000);
        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN03', 96, 1, 7311, 0, 'DEFAULT', 'ADJMT', 0, 20000);
        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN04', 0.6, 1, 7311, 0, 'DEFAULT', 'ADJMT', 0, 30000);
        TestScriptMgmt.CreateWhseItemTrack('80002', '', 'WHITE', '', 'LS01', 105, 1, 7311, 0, 'DEFAULT', 'ADJMT', 0, 40000);
        TestScriptMgmt.CreateWhseItemTrack('80002', '', 'WHITE', '', 'LS02', 105, 1, 7311, 0, 'DEFAULT', 'ADJMT', 0, 50000);

        if LastIteration = '28-2-4-20' then exit;

        WhseItemJnlLine.Reset();
        WhseItemJnlLine.Find('-');
        TestScriptMgmt.WhseJnlPostBatch(WhseItemJnlLine);

        if LastIteration = '28-2-4-30' then exit;

        ItemJnlLine."Journal Template Name" := 'ITEM';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalculateWhseAdjustment.SetItemJnlLine(ItemJnlLine);
        CalculateWhseAdjustment.InitializeRequest(20011128D, 'T-28-2-4');
        CalculateWhseAdjustment.UseRequestPage(false);
        CalculateWhseAdjustment.RunModal();
        Clear(CalculateWhseAdjustment);

        if LastIteration = '28-2-4-40' then exit;

        if LastIteration = '28-2-4-50' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '28-2-4-60' then exit;
        // 28-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '28-2-5-10' then exit;
        // 28-2-6
        WhseWkshLineNo := 10000;

        Commit();
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011129D,
          '80100', '', 'W-03-0001', 'W-01-0001', 3, 'PALLET');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011129D,
          '80100', '', 'W-03-0002', 'W-03-0003', 2, 'PALLET');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011129D,
          '80100', '', 'W-03-0002', 'W-01-0002', 1, 'PALLET');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011129D,
          '80100', '', 'W-03-0003', 'W-01-0003', 3, 'PACK');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011129D,
          '80002', '', 'W-04-0001', 'W-03-0003', 3, 'PALLET');
        TestScriptMgmt.InsertMovWkshLine(WhseWkshLine, 'MOVEMENT', 'DEFAULT', 'WHITE', TestScriptMgmt.GetNextNo(WhseWkshLineNo), 20011129D,
          '80002', '', 'W-04-0002', 'W-03-0003', 3, 'PALLET');

        if LastIteration = '28-2-6-10' then exit;

        WhseWkshLineNo := 10000;
        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN02', 96, 32, 7326, 0, 'DEFAULT', 'MOVEMENT', 0, TestScriptMgmt.GetNextNo(WhseWkshLineNo));
        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN03', 64, 32, 7326, 0, 'DEFAULT', 'MOVEMENT', 0, TestScriptMgmt.GetNextNo(WhseWkshLineNo));
        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN03', 32, 32, 7326, 0, 'DEFAULT', 'MOVEMENT', 0, TestScriptMgmt.GetNextNo(WhseWkshLineNo));
        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN04', 0.6, 0.2, 7326, 0, 'DEFAULT', 'MOVEMENT', 0, TestScriptMgmt.GetNextNo(WhseWkshLineNo));
        TestScriptMgmt.CreateWhseItemTrack('80002', '', 'WHITE', '', 'LS01', 105, 35, 7326, 0, 'DEFAULT', 'MOVEMENT', 0, TestScriptMgmt.GetNextNo(WhseWkshLineNo));
        TestScriptMgmt.CreateWhseItemTrack('80002', '', 'WHITE', '', 'LS02', 105, 35, 7326, 0, 'DEFAULT', 'MOVEMENT', 0, TestScriptMgmt.GetNextNo(WhseWkshLineNo));

        if LastIteration = '28-2-6-20' then exit;

        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::None, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '28-2-6-30' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-2-6-40' then exit;

        TestScriptMgmt.InsertWhseIntPutAwayOrderHead(WhseIntPutAwayHeader, 'WHITE', 'PICK', 'W-03-0003');
        TestScriptMgmt.InsertWhseIntPutAwayOrderLines(
          WhseIntPutAwayOrderLine, WhseIntPutAwayHeader, 10000, '80100', '', 'WHITE', 'PICK', 'W-03-0003', 1.5, 'PALLET');
        TestScriptMgmt.InsertWhseIntPutAwayOrderLines(
          WhseIntPutAwayOrderLine, WhseIntPutAwayHeader, 20000, '80100', '', 'WHITE', 'PICK', 'W-03-0003', 0.5, 'PALLET');
        TestScriptMgmt.InsertWhseIntPutAwayOrderLines(
          WhseIntPutAwayOrderLine, WhseIntPutAwayHeader, 30000, '80002', '', 'WHITE', 'PICK', 'W-03-0003', 6, 'PALLET');

        if LastIteration = '28-2-6-50' then exit;

        TestScriptMgmt.CreaPutAwayFromIntPutAwayOrder(WhseIntPutAwayHeader);

        if LastIteration = '28-2-6-60' then exit;

        Clear(WhseActivLine);

        WhseActivLine.SetFilter("Item No.", '%1', '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LS01');
                WhseActivLine.Validate("Qty. to Handle", 3);
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        Clear(WhseActivLine);
        WhseActivLine.SetFilter("Item No.", '%1', '80100');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LN03');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.Find('+');
        WhseActivLine.Validate("Bin Code", 'W-01-0002');
        WhseActivLine.Modify(true);

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LS02');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-2-6-70' then exit;

        TestScriptMgmt.InsertWhsePickOrderHeader(WhsePickOrderHeader, 'WHITE', 'PICK', 'W-02-0002');
        TestScriptMgmt.InsertWhsePickOrderLines(
          WhseInternalPickLine, WhsePickOrderHeader, 10000, '80100', '', 'WHITE', 'PICK', 'W-02-0002', 16, 'BOX');
        TestScriptMgmt.InsertWhsePickOrderLines(
          WhseInternalPickLine, WhsePickOrderHeader, 20000, '80002', '', 'WHITE', 'PICK', 'W-02-0002', 35, 'PCS');

        if LastIteration = '28-2-6-80' then exit;

        TestScriptMgmt.CreateWhseItemTrack('80100', '', 'WHITE', '', 'LN03', 16, 1, 7334, 0, 'WI000001', '', 0, 10000);
        TestScriptMgmt.CreateWhseItemTrack('80002', '', 'WHITE', '', 'LS01', 35, 1, 7334, 0, 'WI000001', '', 0, 20000);

        if LastIteration = '28-2-6-90' then exit;

        TestScriptMgmt.CreatePickFromPickOrder(WhsePickOrderHeader);

        if LastIteration = '28-2-6-100' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-2-6-110' then exit;
        // 28-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo);

        if LastIteration = '28-2-7-10' then exit;
        // 28-2-8
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '61000', 20011129D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 10, 'BOX', 12.6, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 2, 'PACK', 2.1, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80002', '', 10, 'PCS', 1260, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80002', '', 1, 'PALLET', 42300, 'WHITE', '');

        if LastIteration = '28-2-8-10' then exit;

        SalesLine.Reset();
        if SalesLine.Find('-') then
            repeat
                ReservMgt.SetReservSource(SalesLine);
                ReservMgt.AutoReserve(AutoReserv, '', 20011129D, SalesLine.Quantity, SalesLine."Quantity (Base)");
            until SalesLine.Next() = 0;

        if LastIteration = '28-2-8-20' then exit;

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '28-2-8-30' then exit;

        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-2-8-40' then exit;

        Clear(WhseShptHeader);
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-2-8-50' then exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Item No.", '80100');
        WhseActivLine.SetRange("Bin Code", 'W-01-0001');
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SetRange("Bin Code");
            repeat
                WhseActivLine.Validate("Lot No.", 'LN03');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        end;
        WhseActivLine.SetRange("Bin Code", 'W-01-0003');
        if WhseActivLine.Find('-') then begin
            WhseActivLine.SetRange("Bin Code");
            repeat
                WhseActivLine.Validate("Lot No.", 'LN04');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        end;
        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LS01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-2-8-60' then exit;

        Clear(WhseShptLine);
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '28-2-8-70' then exit;
        // 28-2-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo);

        if LastIteration = '28-2-9-10' then exit;
        // 28-2-10
        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '61000', 20011130D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011130D, 'WHITE', true, true);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 1, 'PACK', 2.1, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80100', '', 1, 'PACK', 2.1, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '80002', '', 1, 'PCS', 1260, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '80002', '', 2, 'PCS', 1260, 'WHITE', '');

        if LastIteration = '28-2-10-10' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'WHITE', '', '', 37, 5, SalesHeader."No.", '', 0, 10000, 1, 0.2, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LN02', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'WHITE', '', '', 37, 5, SalesHeader."No.", '', 0, 20000, 1, 0.2, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LN03', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'WHITE', '', '', 37, 5, SalesHeader."No.", '', 0, 30000, 1, 1, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LS01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'WHITE', '', '', 37, 5, SalesHeader."No.", '', 0, 40000, 1, 2, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011130D, '', 'LS02', 0D, 0D);

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '28-2-10-20' then exit;

        Clear(WhseReceiptHeader);
        TestScriptMgmt.CreateWhseRcptFromSales(SalesHeader, WhseReceiptHeader, 'WHITE');

        if LastIteration = '28-2-10-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-2-10-40' then exit;
        // 28-2-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo);

        if LastIteration = '28-2-11-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
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
        CalcPlan: Report "Calculate Plan - Plan. Wksh.";
        CarryOut: Report "Carry Out Action Msg. - Req.";
        i: Integer;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        Item.SetFilter("No.", '%1|%2', '80100', '80002');
        Item.ModifyAll("Purch. Unit of Measure", 'PALLET');
        Item.ModifyAll(Item."Item Tracking Code", 'LOTALL');

        if LastIteration = '28-3-1-10' then exit;

        TransRoute.Init();
        TransRoute."Transfer-from Code" := 'BLUE';
        TransRoute."Transfer-to Code" := 'WHITE';
        TransRoute."In-Transit Code" := 'OWN LOG.';
        if not TransRoute.Insert() then
            TransRoute.Modify();

        if LastIteration = '28-3-1-20' then exit;

        SKU.Init();
        SKU."Location Code" := 'WHITE';
        SKU."Item No." := '80100';
        SKU."Replenishment System" := SKU."Replenishment System"::Transfer;
        SKU."Transfer-from Code" := 'BLUE';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        SKU."Transfer-Level Code" := -1;
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'WHITE';
        SKU."Item No." := '80002';
        SKU."Replenishment System" := SKU."Replenishment System"::Transfer;
        SKU."Transfer-from Code" := 'BLUE';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        SKU."Transfer-Level Code" := -1;
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'BLUE';
        SKU."Item No." := '80100';
        SKU."Replenishment System" := SKU."Replenishment System"::" ";
        SKU."Vendor No." := '10000';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();
        SKU."Location Code" := 'BLUE';
        SKU."Item No." := '80002';
        SKU."Replenishment System" := SKU."Replenishment System"::" ";
        SKU."Vendor No." := '10000';
        SKU."Reordering Policy" := SKU."Reordering Policy"::"Lot-for-Lot";
        if not SKU.Insert() then
            SKU.Modify();
        SKU.Init();

        if LastIteration = '28-3-1-30' then exit;
        // 28-3-2
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '30000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 48, 'BOX', 30.7, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80002', '', 2, 'PALLET', 37000, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '20000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'WHITE', true, false);

        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '80100', '', 1, 'PALLET', 307.0, 'WHITE', '');
        TestScriptMgmt.InsertSalesLine(
          SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '80002', '', 70, 'PCS', 1370, 'WHITE', '');

        TestScriptMgmt.ReleaseSalesDocument(SalesHeader);

        if LastIteration = '28-3-2-10' then exit;

        Item.SetFilter("Location Filter", '<>%1', '');
        CalcPlan.SetTemplAndWorksheet('REQ', 'DEFAULT', true);
        CalcPlan.InitializeRequest(20011125D, 20011125D, false);
        CalcPlan.SetTableView(Item);
        CalcPlan.UseRequestPage := false;
        CalcPlan.RunModal();

        if LastIteration = '28-3-2-20' then exit;

        ReqWkshLine."Worksheet Template Name" := 'REQ';
        ReqWkshLine."Journal Batch Name" := 'DEFAULT';
        CarryOut.SetReqWkshLine(ReqWkshLine);
        CarryOut.SetHideDialog(true);
        CarryOut.InitializeRequest(20011125D, 20011125D, 20011125D, 20011125D, '');
        CarryOut.UseRequestPage := false;
        CarryOut.Run();

        if LastIteration = '28-3-2-30' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.Find('+');
        i := PurchLine."Line No." + 10000;
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, i, PurchLine.Type::Item, '80100', '', 'BLUE', 1, 'PALLET', 82, false);
        i := PurchLine."Line No." + 10000;
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, i, PurchLine.Type::Item, '80100', '', 'BLUE', 0.5, 'PALLET', 82, false);

        if LastIteration = '28-3-2-40' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'BLUE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 35, 140, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LS01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 39, 1, PurchHeader."No.", '', 0, 20000, 32, 80, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 39, 1, PurchHeader."No.", '', 0, 30000, 32, 32, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 39, 1, PurchHeader."No.", '', 0, 40000, 32, 16, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);

        if LastIteration = '28-3-2-50' then exit;

        PurchHeader.Find('-');
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 4, 0, 30000, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 2.5, 0, 82, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 1, 0, 82, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0.5, 0, 82, 0);

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '28-3-2-60' then exit;

        TransLine.Reset();
        TransLine.SetRange("Transfer-to Code", 'WHITE');
        TransLine.Find('-');
        TransLine.Validate(Quantity, 4);
        TransLine.Validate("Unit of Measure Code", 'PALLET');
        TransLine.Modify();
        TestScriptMgmt.SetSourceItemTrkgInfo('80002', '', 'BLUE', '', '', 5741, 0, TransLine."Document No.", '', 0, TransLine."Line No.", 35, 140, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LS01', 0D, 0D);

        TransLine.Reset();
        TransLine.SetRange("Transfer-to Code", 'WHITE');
        TransLine.Find('+');
        TransLine.Validate(Quantity, 2.5);
        TransLine.Validate("Unit of Measure Code", 'PALLET');
        TransLine.Modify();
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 5741, 0, TransLine."Document No.", '', 0, TransLine."Line No.", 32, 80, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);

        if LastIteration = '28-3-2-70' then exit;

        TransLine.Reset();
        TransLine.SetRange("Transfer-to Code", 'WHITE');
        TransLine.Find('+');
        i := TransLine."Line No." + 10000;

        TransHeader.Find('-');
        TestScriptMgmt.InsertTransferLine(TransLine, TransHeader."No.", i, '80100', '', 'PALLET', 1.5, 0, 1.5);
        TestScriptMgmt.SetSourceItemTrkgInfo('80100', '', 'BLUE', '', '', 5741, 0, TransLine."Document No.", '', 0, TransLine."Line No.", 32, 48, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);

        if LastIteration = '28-3-2-80' then exit;

        TestScriptMgmt.PostTransferOrder(TransHeader);

        if LastIteration = '28-3-2-90' then exit;

        Clear(WhseRcptHeader);
        TestScriptMgmt.InsertWhseRcptHeader(WhseRcptHeader, 'WHITE', 'RECEIVE', 'W-08-0001');

        if LastIteration = '28-3-2-100' then exit;

        TestScriptMgmt.CreateWhseRcptBySourceFilter(WhseRcptHeader, 'CUST30000');

        if LastIteration = '28-3-2-110' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-3-2-120' then exit;
        // 28-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '28-3-3-10' then exit;
        // 28-3-4
        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-3-4-10' then exit;

        Clear(SalesHeader);
        SalesHeader.Reset();
        SalesHeader.SetRange("Sell-to Customer No.", '30000');
        SalesHeader.Find('-');
        Clear(WhseShptHeader);
        TestScriptMgmt.CreateWhseShptFromSales(SalesHeader, WhseShptHeader, 'WHITE');

        if LastIteration = '28-3-4-20' then exit;

        WhseShptHeader.Reset();
        WhseShptHeader.SetRange("Location Code", 'WHITE');
        WhseShptHeader.Find('-');
        TestScriptMgmt.CreatePickFromWhseShipment(WhseShptHeader);

        if LastIteration = '28-3-4-30' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.SetRange("Item No.", '80002');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LS01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        WhseActivLine.SetRange("Item No.", '80100');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LN01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '28-3-4-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-3-4-50' then exit;

        WhseShptLine.Reset();
        WhseShptLine.Find('-');
        TestScriptMgmt.PostWhseShipment(WhseShptLine, true);

        if LastIteration = '28-3-4-60' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader."Vendor Invoice No." := 'TCS28-3-2';
        PurchHeader.Modify();

        if LastIteration = '28-3-4-70' then exit;

        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '28-3-4-80' then exit;
        // 28-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '28-3-5-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        WhseActivLine: Record "Warehouse Activity Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        ItemJnlLine: Record "Item Journal Line";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        CalcConsumption: Report "Calc. Consumption";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSourceType: Option " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '28-4-1-10' then exit;

        Item.SetFilter("No.", '%1|%2|%3|%4', 'A_TEST', 'B_TEST', 'D_PROD', 'E_PROD');
        Item.ModifyAll("Item Tracking Code", 'LOTALL');

        if LastIteration = '28-4-1-20' then exit;

        ProdBOMHeader.Get('E_PROD');
        ProdBOMHeader.Status := ProdBOMHeader.Status::New;
        ProdBOMHeader.Modify(true);

        ProdBOMLine.Reset();
        ProdBOMLine.SetRange("Production BOM No.", 'E_PROD');
        ProdBOMLine.Find('-');
        ProdBOMLine.Validate("Quantity per", 1);
        ProdBOMLine."Unit of Measure Code" := 'PALLET';
        ProdBOMLine.Modify(true);

        ProdBOMLine.Next();
        ProdBOMLine.Validate("Quantity per", 1);
        ProdBOMLine."Unit of Measure Code" := 'PALLET';
        ProdBOMLine.Modify(true);

        ProdBOMLine.Next();
        ProdBOMLine.Validate("Quantity per", 0.9);
        ProdBOMLine."Unit of Measure Code" := 'PALLET';
        ProdBOMLine.Modify(true);

        ProdBOMHeader.Get('E_PROD');
        ProdBOMHeader."Unit of Measure Code" := 'PALLET';
        ProdBOMHeader.Status := ProdBOMHeader.Status::Certified;
        ProdBOMHeader.Modify(true);


        if LastIteration = '28-4-1-30' then exit;
        // 28-4-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS28-4-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 6, 'PALLET', 300, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 5, 'PALLET', 133.35, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'D_PROD', '', 'WHITE', 7, 'PALLET', 58.23, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 3, 'PALLET', 133.35, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, 'D_PROD', '', 'WHITE', 3, 'PALLET', 58.23, false);

        if LastIteration = '28-4-2-10' then exit;

        TestScriptMgmt.SetSourceItemTrkgInfo('B_TEST', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 10000, 10, 60, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LN01', 0D, 0D);

        TestScriptMgmt.CreateItemTrackfromJnlLine('A_TEST', '12', 'WHITE', '', 'LT01', 39, 13, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);
        TestScriptMgmt.CreateItemTrackfromJnlLine('A_TEST', '12', 'WHITE', '', 'LT02', 26, 13, "Reservation Status"::Surplus, 39, 1, PurchHeader."No.", '', 0, 20000, true);

        TestScriptMgmt.SetSourceItemTrkgInfo('D_PROD', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 30000, 11, 77, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LS01', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('A_TEST', '12', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 40000, 13, 39, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LT02', 0D, 0D);
        TestScriptMgmt.SetSourceItemTrkgInfo('D_PROD', '', 'WHITE', '', '', 39, 1, PurchHeader."No.", '', 0, 50000, 11, 33, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LS02', 0D, 0D);


        if LastIteration = '28-4-2-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '28-4-2-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-4-2-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-4-2-50' then exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 3, 0, 'E_PROD', 5, 'WHITE');

        if LastIteration = '28-4-2-60' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        WhseProdRelease.Release(ProdOrder);

        ProdOrderLine.Find('-');
        ProdOrderLine.Validate(ProdOrderLine."Unit of Measure Code", 'Pallet');
        ProdOrderLine.Modify(true);

        TestScriptMgmt.SetSourceItemTrkgInfo('E_PROD', '', 'WHITE', '', '', 5406, 3, ProdOrder."No.", '', 10000, 0, 9, 45, '', '');
        TestScriptMgmt.InsertItemTrkgInfo(20011125D, '', 'LE01', 0D, 0D);

        if LastIteration = '28-4-2-70' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'A_TEST');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('A_TEST', '12', 'WHITE', '', '', 5407, 3, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 13, 65, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011124D, '', 'LT02', 0D, 0D);
        end;
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('B_TEST', '', 'WHITE', '', '', 5407, 3, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 10, 50, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011124D, '', 'LN01', 0D, 0D);
        end;
        ProdOrderComp.SetRange("Item No.", 'D_PROD');
        if ProdOrderComp.Find('-') then begin
            TestScriptMgmt.SetSourceItemTrkgInfo('D_PROD', '', 'WHITE', '', '', 5407, 3, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 11, 55, '', '');
            TestScriptMgmt.InsertItemTrkgInfo(20011124D, '', 'LS01', 0D, 0D);
        end;

        if LastIteration = '28-4-2-80' then exit;

        ProdOrder.Reset();
        ProdOrder.Find('-');
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComp.Find('-') then
            repeat
                ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                  "Warehouse Worksheet Document Type".FromInteger(WhseSourceType::Production), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", DATABASE::"Prod. Order Component",
                  ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.");
            until ProdOrderComp.Next() = 0;
        Commit();

        Clear(CreatePickFromWhseSource);
        ProdOrder.Reset();
        ProdOrder.Find('-');
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();
        Clear(CreatePickFromWhseSource);

        if LastIteration = '28-4-2-90' then exit;
        // 28-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '28-4-3-10' then exit;
        // 28-4-4
        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-4-4-10' then exit;

        ProdOrder.Find('-');
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '28-4-4-20' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '28-4-4-30' then exit;

        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.CreateOutputJnlLine(ItemJnlLine, 'Output', 'DEFAULT', ProdOrder."No.");

        if LastIteration = '28-4-4-40' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '28-4-4-50' then exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, 20011130D, false);

        if LastIteration = '28-4-4-60' then exit;
        // 28-4-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '28-4-5-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        BinContent: Record "Bin Content";
        ItemJnlLine: Record "Item Journal Line";
        ReplenishmtBatch: Report "Calculate Bin Replenishment";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        OutpExplRtng: Codeunit "Output Jnl.-Expl. Route";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '28-5-1-10' then exit;

        Item.SetFilter("No.", '%1', 'D_PROD');
        Item.ModifyAll("Flushing Method", 1);
        Item.SetFilter("No.", '%1|%2', 'A_TEST', 'B_TEST');
        Item.ModifyAll("Flushing Method", 2);

        Item.SetFilter("No.", '%1|%2|%3', 'A_TEST', 'B_TEST', 'D_PROD');
        Item.ModifyAll("Item Tracking Code", 'LOTALL');

        if LastIteration = '28-5-1-20' then exit;

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'A_TEST', '12', 'PALLET', 1, 6);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'B_TEST', '', 'PALLET', 1, 6);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'D_PROD', '', 'PALLET', 1, 6);

        if LastIteration = '28-5-1-40' then exit;
        // 28-5-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS28-5-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 10, 'PALLET', 133.35, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 10, 'PALLET', 300, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'D_PROD', '', 'WHITE', 10, 'PALLET', 58.23, false);

        if LastIteration = '28-5-2-10' then exit;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 13, 10, 130, '', 'LT01');
        CreateReservEntry.CreateEntry('A_TEST', '12', 'WHITE', '', 20011125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 10, 10, 100, '', 'LN01');
        CreateReservEntry.CreateEntry('B_TEST', '', 'WHITE', '', 20011125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 11, 10, 110, '', 'LS01');
        CreateReservEntry.CreateEntry('D_PROD', '', 'WHITE', '', 20011125D, 0D, 0, "Reservation Status"::Surplus);

        if LastIteration = '28-5-2-20' then exit;
        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '28-5-2-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-5-2-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-5-2-50' then exit;

        Clear(ReplenishmtBatch);
        BinContent.Reset();
        BinContent.Find('-');
        ReplenishmtBatch.UseRequestPage(false);
        ReplenishmtBatch.InitializeRequest('MOVEMENT', 'DEFAULT', 'WHITE', true, true, false);
        ReplenishmtBatch.SetTableView(BinContent);
        ReplenishmtBatch.RunModal();

        if LastIteration = '28-5-2-60' then exit;

        WhseWkshLine.Find('-');
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshLine."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, WhseWkshLine.Name);
        WhseWkshLine.SetRange("Location Code", WhseWkshLine."Location Code");
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.Initialize('', "Whse. Activity Sorting Method"::Item, false, false, false);
        CreateMovFromWhseSource.RunModal();
        Clear(CreateMovFromWhseSource);

        if LastIteration = '28-5-2-70' then exit;

        WhseActivLine.Reset();
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);

        WhseActivLine.SetRange("Item No.", 'A_TEST');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LT01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        WhseActivLine.SetRange("Item No.", 'B_TEST');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LN01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        WhseActivLine.SetRange("Item No.", 'D_PROD');
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine.Validate("Lot No.", 'LS01');
                WhseActivLine.Modify(true);
            until WhseActivLine.Next() = 0;

        if LastIteration = '28-5-2-80' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-5-2-90' then exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'E_PROD', 40, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Modify(true);
        WorkDate := 20011130D;

        if LastIteration = '28-5-2-100' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '28-5-2-110' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'A_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 52, 52, '', 'LT01');
            CreateReservEntry.CreateEntry('A_TEST', '12', 'WHITE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
        end;
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 50, 50, '', 'LN01');
            CreateReservEntry.CreateEntry('B_TEST', '', 'WHITE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
        end;
        ProdOrderComp.SetRange("Item No.", 'D_PROD');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000,
              ProdOrderComp."Line No.", 1, 60, 60, '', 'LS01');
            CreateReservEntry.CreateEntry('D_PROD', '', 'WHITE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = '28-5-2-120' then exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '28-5-2-130' then exit;
        // 28-5-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '28-5-3-10' then exit;
        // 28-5-4
        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011130D,
          ItemJnlLine."Entry Type"::Output, 'ProdOrder."No."', 'E_PROD', '', 'WHITE', '',
          40, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.");
        ItemJnlLine.Modify();

        if LastIteration = '28-5-4-10' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        OutpExplRtng.Run(ItemJnlLine);

        if LastIteration = '28-5-4-20' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '28-5-4-30' then exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, 20011130D, false);

        if LastIteration = '28-5-4-40' then exit;
        // 28-5-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '28-5-5-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ItemJnlLine: Record "Item Journal Line";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        OutpExplRtng: Codeunit "Output Jnl.-Expl. Route";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSourceType: Option " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production;
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '28-6-1-10' then exit;

        Item.SetFilter("No.", '%1', 'D_PROD');
        Item.ModifyAll("Flushing Method", 2);
        Item.SetFilter("No.", '%1|%2|%3', 'A_TEST', 'B_TEST', 'E_PROD');
        Item.ModifyAll("Flushing Method", 2);

        Item.SetFilter("No.", '%1|%2|%3', 'A_TEST', 'B_TEST', 'D_PROD');
        Item.ModifyAll("Item Tracking Code", 'LOTALL');
        //  IF LastIteration = '28-6-1-20' THEN EXIT;
        TestScriptMgmt.InsertRoutingHeader(RoutingHeader, 'TEST', RoutingHeader.Type::Serial);
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '010', RoutingLine.Type::"Work Center", '100', 20, 5, '100');
        TestScriptMgmt.InsertRoutingLine(RoutingLine, RoutingHeader, '', '020', RoutingLine.Type::"Work Center", '400', 30, 5, '');
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        WorkCenter.SetFilter("No.", '%1|%2', '100', '400');
        Clear(CalcWorkCenterCal);
        CalcWorkCenterCal.InitializeRequest(20010101D, 20011231D);
        CalcWorkCenterCal.UseRequestPage(false);
        CalcWorkCenterCal.SetTableView(WorkCenter);
        CalcWorkCenterCal.RunModal();

        Item.Get('E_PROD');
        Item.Validate("Routing No.", 'TEST');
        Item.Modify(true);

        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'A_TEST', '12', 'PCS', 1, 6);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'B_TEST', '', 'PCS', 1, 6);
        TestScriptMgmt.InsertDedicatedBin('WHITE', 'Production', 'W-07-0001', 'D_PROD', '', 'PCS', 1, 6);
        if LastIteration = '28-6-1-20' then exit;
        // 28-6-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'WHITE', 'TCS28-6-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'A_TEST', '12', 'WHITE', 100, 'Pcs', 133.35, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B_TEST', '', 'WHITE', 100, 'Pcs', 300, false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'D_PROD', '', 'WHITE', 100, 'Pcs', 58.23, false);

        if LastIteration = '28-6-2-10' then exit;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 100, 100, '', 'LT01');
        CreateReservEntry.CreateEntry('A_TEST', '12', 'WHITE', '', 20011125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 20000, 1, 100, 100, '', 'LN01');
        CreateReservEntry.CreateEntry('B_TEST', '', 'WHITE', '', 20011125D, 0D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 100, 100, '', 'LS01');
        CreateReservEntry.CreateEntry('D_PROD', '', 'WHITE', '', 20011125D, 0D, 0, "Reservation Status"::Surplus);

        if LastIteration = '28-6-2-20' then exit;

        TestScriptMgmt.ReleasePurchDocument(PurchHeader);

        Clear(WhseRcptHeader);
        TestScriptMgmt.CreateWhseRcptFromPurch(PurchHeader, WhseRcptHeader, 'WHITE');

        if LastIteration = '28-6-2-30' then exit;

        WhseRcptLine.Reset();
        WhseRcptLine.Find('-');
        TestScriptMgmt.PostWhseReceipt(WhseRcptLine);

        if LastIteration = '28-6-2-40' then exit;

        Clear(WhseActivLine);
        WhseActivLine.Reset();
        WhseActivLine.Find('-');
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-6-2-50' then exit;

        TestScriptMgmt.InsertProdOrder(ProdOrder, 2, 0, 'E_PROD', 40, 'WHITE');
        ProdOrder.Validate("Due Date", 20011130D);
        ProdOrder.Modify(true);
        WorkDate := 20011130D;

        if LastIteration = '28-6-2-60' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '28-6-2-70' then exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetRange("Item No.", 'A_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 52, 52, '', 'LT01');
            CreateReservEntry.CreateEntry('A_TEST', '12', 'WHITE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
        end;
        ProdOrderComp.SetRange("Item No.", 'B_TEST');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 50, 50, '', 'LN01');
            CreateReservEntry.CreateEntry('B_TEST', '', 'WHITE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
        end;
        ProdOrderComp.SetRange("Item No.", 'D_PROD');
        if ProdOrderComp.Find('-') then begin
            CreateReservEntryFor(5407, 2, ProdOrder."No.", '', 10000, ProdOrderComp."Line No.", 1, 60, 60, '', 'LS01');
            CreateReservEntry.CreateEntry('D_PROD', '', 'WHITE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
        end;

        if LastIteration = '28-6-2-80' then exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Released, 20011130D, false);

        if LastIteration = '28-6-2-90' then exit;
        // 28-6-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo);

        if LastIteration = '28-6-3-10' then exit;
        // 28-6-4
        ProdOrder.Reset();
        ProdOrder.Find('-');
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComp.Find('-') then
            repeat
                ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                  "Warehouse Worksheet Document Type".FromInteger(WhseSourceType::Production), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", DATABASE::"Prod. Order Component",
                  ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.",
                  ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.");
            until ProdOrderComp.Next() = 0;
        Commit();

        Clear(CreatePickFromWhseSource);
        Commit();
        ProdOrder.Reset();
        ProdOrder.Find('-');
        CreatePickFromWhseSource.SetProdOrder(ProdOrder);
        CreatePickFromWhseSource.SetHideValidationDialog(true);
        CreatePickFromWhseSource.UseRequestPage(false);
        CreatePickFromWhseSource.RunModal();

        if LastIteration = '28-6-4-10' then exit;

        Clear(WhseActivLine);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        WhseActivLine.Find('-');
        WhseActivLine.SetRange("No.", WhseActivLine."No.");
        TestScriptMgmt.PostWhseActivity(WhseActivLine);

        if LastIteration = '28-6-4-20' then exit;

        ProdOrder.Reset();
        ProdOrder.Find('-');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011130D,
          ItemJnlLine."Entry Type"::Output, 'ProdOrder."No."', 'E_PROD', '', 'WHITE', '',
          40, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Item No.");
        ItemJnlLine.Modify();

        if LastIteration = '28-6-4-30' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        OutpExplRtng.Run(ItemJnlLine);

        if LastIteration = '28-6-4-40' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '28-6-4-50' then exit;

        ProdOrder.Find('-');
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, 20011130D, false);

        if LastIteration = '28-6-4-60' then exit;
        // 28-6-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo);

        if LastIteration = '28-6-5-10' then exit;
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

