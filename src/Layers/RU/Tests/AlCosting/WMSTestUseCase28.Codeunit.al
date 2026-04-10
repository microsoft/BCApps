codeunit 103322 "WMS Test Use Case 28"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        QASetup: Record Table103304;
        TestscriptMgt: Codeunit Codeunit103001;
    begin
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 28");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103331,28,0,'',1);

        TestscriptMgt.ShowTestscriptResult;
    end;

    var
        Item: Record Item;
        TestCase: Record Table103301;
        TestScriptResult: Record Table103303;
        UseCase: Record Table103300;
        SelectionForm: Page Page103317;
        GlobalPrecondition: Codeunit Codeunit103301;
        TestScriptMgmt: Codeunit Codeunit103303;
        CETAFTestscriptManagement: Codeunit Codeunit103492;
        ShowAlsoPassTests: Boolean;
        TestUseCase: array [50] of Boolean;
        ItemJnlLineNo: Integer;
        LastILENo: Integer;
        NoOfFields: array [20] of Integer;
        NoOfRecords: array [20] of Integer;
        ObjectNo: Integer;
        TestCaseNo: Integer;
        UseCaseNo: Integer;
        TestLevel: Option All,Selected;
        FirstIteration: Text[30];
        LastIteration: Text[30];
        TestCaseDesc: array [50] of Text[100];
        TestResultsPath: Text[250];

    [Scope('OnPrem')]
    procedure Test(NewObjectNo: Integer;NewUseCaseNo: Integer;NewTestLevel: Option All,Selected;NewLastIteration: Text[30];NewTestCaseNo: Integer): Boolean
    begin
        ObjectNo := NewObjectNo;
        UseCaseNo := NewUseCaseNo;
        TestLevel := NewTestLevel;
        LastIteration := NewLastIteration;
        TestCaseNo := NewTestCaseNo;

        UseCase.GET('WMS',UseCaseNo);
        TestScriptMgmt.InitializeOutput(ObjectNo,'');
        TestResultsPath := TestScriptMgmt.GetTestResultsPath;
        TestScriptMgmt.SetNumbers(NoOfRecords,NoOfFields);

        IF LastIteration <> '' THEN BEGIN
          TestCase.GET('WMS',UseCaseNo,TestCaseNo);
          TestCaseDesc[TestCaseNo] :=
            FORMAT(UseCaseNo) + '.' + FORMAT(TestCaseNo) + ' ' + TestCase.Description;
          HandleTestCases;
        END else BEGIN
          TestCaseNo := 0;
          CLEAR(TestUseCase);
          CLEAR(TestCaseDesc);

          TestCase.Reset();
          TestCase.SETRANGE("Project Code",'WMS');
          TestCase.SETRANGE("Use Case No.",UseCaseNo);
          TestCase.SETRANGE("Testscript Completed",TRUE);
          IF NOT TestCase.FIND('-') THEN
            EXIT(TRUE);
          REPEAT
            TestCaseNo := TestCase."Test Case No.";
            IF TestCaseNo <= ARRAYLEN(TestCaseDesc) THEN
              TestCaseDesc[TestCaseNo] :=
                FORMAT(UseCaseNo) + '.' + FORMAT(TestCaseNo) + ' ' + TestCase.Description;
          UNTIL TestCase.Next() = 0;

          IF TestLevel = TestLevel::Selected THEN BEGIN
            Commit();
            SelectionForm.SetSelection(TestCaseDesc,FALSE,UseCaseNo,
              'Select Test Case for Use Case ' + FORMAT(UseCaseNo) + '. ' + UseCase.Description);
            SelectionForm.LOOKUPMODE := TRUE;
            IF SelectionForm.RUNMODAL <> ACTION::LookupOK THEN
              EXIT(FALSE);
            SelectionForm.GetSelection(TestLevel,TestUseCase,ShowAlsoPassTests);
          END;

          FOR TestCaseNo := 1 TO ARRAYLEN(TestCaseDesc) DO
            IF TestCaseDesc[TestCaseNo] <> '' THEN
              HandleTestCases;
        END;

        TestScriptMgmt.GetNumbers(NoOfRecords,NoOfFields);
        EXIT(TRUE);
    end;

    [Scope('OnPrem')]
    procedure HandleTestCases()
    begin
        IF TestLevel = TestLevel::Selected THEN
          IF NOT TestUseCase[TestCaseNo] THEN
            EXIT;

        CASE TestCaseNo OF
          1: PerformTestCase1;
          2: PerformTestCase2;
          3: PerformTestCase3;
          4: PerformTestCase4;
        //  5: PerformTestCase5;
        //  6: PerformTestCase6;
        END;
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
        ResMgmt: Codeunit "Reservation Management";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        AutoReserv: Boolean;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 28-1-1

          SetGlobalPreconditions;

          IF LastIteration = '28-1-1-10' THEN EXIT;

          WITH Item DO BEGIN
            GET('N_TEST');
            "Item Tracking Code" := 'FREEENTRY';
            MODIFY(TRUE);

            GET('80100');
            "Item Tracking Code" := 'LOTALL';
            MODIFY(TRUE);
          END;

          Location.SETRANGE(Code,'white');
          Location.FIND('-');
          Location."Always Create Pick Line" :=TRUE;
          Location.MODIFY(TRUE);

          IF LastIteration = '28-1-1-20' THEN EXIT;

        // 28-1-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'62000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS28-1-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','BLUE',2,'PALLET',30000,FALSE);
          ModifyPurchLine(PurchHeader,10000,2,0,30000,0);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','BLUE',3,'PALLET',133.35,FALSE);
          ModifyPurchLine(PurchHeader,20000,3,0,133.35,0);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'N_TEST','','BLUE',2,'PCS',58.23,FALSE);
          ModifyPurchLine(PurchHeader,30000,1,0,58.23,0);

          IF LastIteration = '28-1-2-10' THEN EXIT;

          SetSourceItemTrkgInfo('80002','','BLUE','','',39,1,PurchHeader."No.",'',0,10000,35,70,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);
          SetSourceItemTrkgInfo('80100','','BLUE','','',39,1,PurchHeader."No.",'',0,20000,32,96,'','');
          InsertItemTrkgInfo(251101D,'','LT01',0D,0D);
          SetSourceItemTrkgInfo('N_TEST','','BLUE','','',39,1,PurchHeader."No.",'',0,30000,1,1,'','');
          InsertItemTrkgInfo(251101D,'SN01','',0D,0D);

          IF LastIteration = '28-1-2-20' THEN EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '28-1-2-30' THEN EXIT;

          PurchRcptLine.SETRANGE("Line No.",30000);
          PurchRcptLine.FIND('-');
          UndoPurchaseReceiptLine.SetHideDialog(TRUE);
          UndoPurchaseReceiptLine.RUN(PurchRcptLine);

          IF LastIteration = '28-1-2-40' THEN EXIT;

          PurchHeader.FIND('-');
          ReleasePurchDoc.Reopen(PurchHeader);
          ModifyPurchLine(PurchHeader,30000,2,0,58.23,0);

          ResEntry.SETRANGE("Item No.",'N_TEST');
          ResEntry.FIND('-');
          ResEntry.DELETE(TRUE);

          IF LastIteration = '28-1-2-50' THEN EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '28-1-2-60' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'62000',291101D);
          ModifySalesHeader(SalesHeader,291101D,'WHITE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80002','',3,'PCS',1120,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'80100','',3,'BOX',5.99,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::Item,'80100','',3,'PACK',1.21,'WHITE','');

          IF LastIteration = '28-1-2-70' THEN EXIT;

          InsertTransferHeader(TransHeader,'BLUE','WHITE','OWN LOG.',261101D);
          InsertTransferLine(TransLine,TransHeader."No.",10000,'80002','','PCS',3,0,3);
          InsertTransferLine(TransLine,TransHeader."No.",20000,'80100','','BOX',3,0,3);
          InsertTransferLine(TransLine,TransHeader."No.",30000,'80100','','PACK',3,0,3);

          SetSourceItemTrkgInfo('80002','','BLUE','','',5741,0,TransLine."Document No.",'',0,10000,1,3,'','');
          InsertItemTrkgInfo(261101D,'','LN01',0D,0D);
          SetSourceItemTrkgInfo('80100','','BLUE','','',5741,0,TransLine."Document No.",'',0,20000,1,3,'','');
          InsertItemTrkgInfo(261101D,'','LT01',0D,0D);
          SetSourceItemTrkgInfo('80100','','BLUE','','',5741,0,TransLine."Document No.",'',0,30000,1,0.6,'','');
          InsertItemTrkgInfo(261101D,'','LT01',0D,0D);

          IF LastIteration = '28-1-2-80' THEN EXIT;

          SalesLine.Reset();
          IF SalesLine.FIND('-') THEN
            REPEAT
              ResMgmt.SetSalesLine(SalesLine);
              ResMgmt.AutoReserve(AutoReserv,'',291101D,SalesLine.Quantity,SalesLine."Quantity (Base)");
            UNTIL SalesLine.Next() = 0;

          IF LastIteration = '28-1-2-90' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);

          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-1-2-100' THEN EXIT;

          PostTransferOrder(TransHeader);

          IF LastIteration = '28-1-2-110' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'62000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','WHITE',3,'PALLET',30000,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','WHITE',4,'PALLET',133.35,FALSE);

          IF LastIteration = '28-1-2-120' THEN EXIT;

          CreateItemTrackfromJnlLine('80002','','WHITE','','LN03',35,35,2,39,1,PurchHeader."No.",'',0,10000,TRUE);
          CreateItemTrackfromJnlLine('80002','','WHITE','','LN04',35,35,2,39,1,PurchHeader."No.",'',0,10000,TRUE);
          CreateItemTrackfromJnlLine('80002','','WHITE','','LN05',35,35,2,39,1,PurchHeader."No.",'',0,10000,TRUE);

          CreateItemTrackfromJnlLine('80100','','WHITE','','LT02',32,32,2,39,1,PurchHeader."No.",'',0,20000,TRUE);
          CreateItemTrackfromJnlLine('80100','','WHITE','','LT03',64,32,2,39,1,PurchHeader."No.",'',0,20000,TRUE);
          CreateItemTrackfromJnlLine('80100','','WHITE','','LT04',32,32,2,39,1,PurchHeader."No.",'',0,20000,TRUE);

          IF LastIteration = '28-1-2-130' THEN EXIT;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '28-1-2-140' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-1-2-150' THEN EXIT;

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN
            SETFILTER("Lot No.",'<>%1','LN03');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Qty. to Handle",0);
                MODIFY(TRUE);
              until Next() = 0;

            CLEAR(WhseActivLine);
            SETRANGE("Lot No.",'LT03');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Qty. to Handle",2);
                MODIFY(TRUE);
              until Next() = 0;
          END;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-1-2-160' THEN EXIT;

          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-1-2-170' THEN EXIT;

        // 28-1-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '28-1-3-10' THEN EXIT;

        // 28-1-4

          CLEAR(WhseRcptHeader);
          InsertWhseRcptHeader(WhseRcptHeader,'WHITE','RECEIVE','W-08-0001');

          CreateWhseRcptBySourceFilter(WhseRcptHeader,'CUST30000');

          IF LastIteration = '28-1-4-10' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-1-4-20' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.SETRANGE("Activity Type",1);
          IF WhseActivLine.FIND('-') THEN
            REPEAT
              PostWhseActivity(WhseActivLine);
            UNTIL WhseActivLine.Next() =0;

          IF LastIteration = '28-1-4-30' THEN EXIT;

          CLEAR(WhseActivHeader);
          WhseActivHeader.SETRANGE(Type,WhseActivHeader.Type::Pick);
          WhseActivHeader.DELETEALL(TRUE);

          IF LastIteration = '28-1-4-40' THEN EXIT;

          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-1-4-50' THEN EXIT;

          WITH WhseActivLine DO BEGIN
            SETRANGE("Activity Type","Activity Type"::Pick);
            SETRANGE("Item No.",'80002');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Lot No.",'LN01');
                MODIFY(TRUE);
              until Next() = 0;
            SETRANGE("Item No.",'80100');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Lot No.",'LT01');
                MODIFY(TRUE);
              until Next() = 0;
            Reset();
            FIND('-');
          END;
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-1-4-60' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);

          IF LastIteration = '28-1-4-70' THEN EXIT;

        // 28-1-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '28-1-5-10' THEN EXIT;

        // 28-1-6

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'61000',291101D);
          ModifySalesHeader(SalesHeader,291101D,'WHITE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80002','',3,'PCS',1120,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'80100','',3,'BOX',5.99,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::"Charge (Item)",'GPS','',2,'',100,'WHITE','');

          IF LastIteration = '28-1-6-10' THEN EXIT;

          InsertResEntry(
            ResEntry,'WHITE',10000,2,301101D,'80002','','','LN03',1,1,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(
            ResEntry,'WHITE',10000,2,301101D,'80002','','','LN04',1,1,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(
            ResEntry,'WHITE',10000,2,301101D,'80002','','','LN05',1,1,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(
            ResEntry,'WHITE',20000,2,301101D,'80100','','','LT02',1,1,37,1,SalesHeader."No.",'',20000,TRUE);
          InsertResEntry(
            ResEntry,'WHITE',20000,2,301101D,'80100','','','LT03',2,2,37,1,SalesHeader."No.",'',20000,TRUE);

          IF LastIteration = '28-1-6-20' THEN EXIT;

          WITH SalesLine DO BEGIN
            CETAFTestscriptManagement.InsertSalesChargeAssignLine(
              SalesLine,10000,"Document Type","Document No.",10000,'80002');
            CETAFTestscriptManagement.ModifySalesChargeAssignLine(SalesHeader,"Line No.",10000,1);

            CETAFTestscriptManagement.InsertSalesChargeAssignLine(
              SalesLine,20000,"Document Type","Document No.",20000,'80100');
            CETAFTestscriptManagement.ModifySalesChargeAssignLine(SalesHeader,"Line No.",20000,1);
          END;

          IF LastIteration = '28-1-6-30' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);

          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-1-6-40' THEN EXIT;

          WhseShptHeader.Reset();
          WhseShptHeader.FIND('+');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-1-6-50' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-1-6-60' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,TRUE);

          IF LastIteration = '28-1-6-70' THEN EXIT;

        // 28-1-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '28-1-7-10' THEN EXIT;

        // 28-1-8

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'62000',291101D);
          ModifySalesHeader(SalesHeader,291101D,'WHITE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80002','',3,'PCS',1120,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'80100','',17,'PACK',1.21,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::Item,'80100','',1,'PALLET',175,'WHITE','');

          IF LastIteration = '28-1-8-10' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);

          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-1-8-20' THEN EXIT;

          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-1-8-30' THEN EXIT;

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN

            SETFILTER("Item No.",'%1','80002');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Lot No.",'LN03');
                MODIFY(TRUE);
              until Next() = 0;

            CLEAR(WhseActivLine);
            SETFILTER("Item No.",'%1','80100');
            IF FIND('-') THEN BEGIN
              SETRANGE("Unit of Measure Code",'PACK');
              IF FIND('-') THEN
                REPEAT
                  VALIDATE("Lot No.",'LT03');
                  VALIDATE("Qty. to Handle",0);
                  MODIFY(TRUE);
                until Next() = 0;

              SETRANGE("Unit of Measure Code",'BOX');
              IF FIND('-') THEN
                REPEAT
                  VALIDATE("Lot No.",'LT03');
                  VALIDATE("Qty. to Handle",0);
                  MODIFY(TRUE);
                until Next() = 0;

              SETRANGE("Unit of Measure Code",'PALLET');
              IF FIND('-') THEN
                REPEAT
                  VALIDATE("Lot No.",'LT04');
                  VALIDATE("Qty. to Handle",0);
                  MODIFY(TRUE);
                until Next() = 0;
            END;
          END;

          IF LastIteration = '28-1-8-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-1-8-50' THEN EXIT;

        // 28-1-9

          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo);

          IF LastIteration = '28-1-9-10' THEN EXIT;

        // 28-1-10

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-1-10-10' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.SETFILTER("Item No.",'%1','80100');
          IF WhseShptLine.FIND('-') THEN
            REPEAT
              WhseShptLine.VALIDATE("Qty. to Ship",0);
              WhseShptLine.MODIFY(TRUE);
            UNTIL WhseShptLine.Next() = 0;

          IF LastIteration = '28-1-10-20' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);

          IF LastIteration = '28-1-10-30' THEN EXIT;

        // 28-1-11

          VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo);

          IF LastIteration = '28-1-11-10' THEN EXIT;

        // 28-1-12

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          WhseShptLine.AutofillQtyToHandle(WhseShptLine);
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,TRUE);

          IF LastIteration = '28-1-12-10' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',011201D);
          ModifySalesHeader(SalesHeader,011201D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80002','',1,'PCS',1120,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',1,'PALLET',175,'WHITE','');
          END;

          IF LastIteration = '28-1-12-20' THEN EXIT;

          InsertResEntry(
            ResEntry,'WHITE',10000,2,011201D,'80002','','','LN03',1,1,37,5,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(
            ResEntry,'WHITE',20000,2,011201D,'80100','','','LT04',1,32,37,5,SalesHeader."No.",'',20000,TRUE);

          IF LastIteration = '28-1-12-30' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '28-1-12-40' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.SETRANGE("Item No.",'80002');
          IF WhseRcptLine.FIND('-') THEN BEGIN
            WhseRcptLine.VALIDATE("Qty. to Receive",0);
            WhseRcptLine.MODIFY(TRUE);
          END;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WhseRcptLine.FIND('-');
          WhseRcptLine.AutofillQtyToReceive(WhseRcptLine);

          IF LastIteration = '28-1-12-50' THEN EXIT;

          CLEAR(WhseActivHeader);
          IF WhseActivHeader.FIND('-') THEN
            WhseActivHeader.DELETEALL(TRUE);

          IF LastIteration = '28-1-12-60' THEN EXIT;

          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Document No.",'107001');
          ReturnRcptLine.SETRANGE("Line No.",20000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          IF LastIteration = '28-1-12-70' THEN EXIT;

          CLEAR(WhseRcptHeader);
          InsertWhseRcptHeader(WhseRcptHeader,'WHITE','RECEIVE','W-08-0001');
          CreateWhseRcptBySourceFilter(WhseRcptHeader,'vend10000');

          IF LastIteration = '28-1-12-80' THEN EXIT;

          WhseRcptLine.Reset();
          IF WhseRcptLine.FIND('-') THEN
            REPEAT
              WhseRcptLine2.GET(WhseRcptLine."No.",WhseRcptLine."Line No.");
              PostWhseReceipt(WhseRcptLine2);
            UNTIL WhseRcptLine.Next() =0;

          IF LastIteration = '28-1-12-90' THEN EXIT;

          CLEAR(WhseActivLine);
          IF WhseActivLine.FIND('-') THEN
            REPEAT
              PostWhseActivity(WhseActivLine);
            UNTIL WhseActivLine.Next() =0;

          IF LastIteration = '28-1-12-100' THEN EXIT;

        // 28-1-13

          VerifyPostCondition(UseCaseNo,TestCaseNo,13,LastILENo);

          IF LastIteration = '28-1-13-10' THEN EXIT;

        // 28-1-14

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',031201D);
          ModifyPurchHeader(PurchHeader,031201D,'WHITE','',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','WHITE',4,'PALLET',30000,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','WHITE',5,'PALLET',133.35,FALSE);

          IF LastIteration = '28-1-14-10' THEN EXIT;

          SetSourceItemTrkgInfo('80002','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,35,140,'','');
          InsertItemTrkgInfo(031201D,'','LN06',0D,0D);
          SetSourceItemTrkgInfo('80100','','WHITE','','',39,1,PurchHeader."No.",'',0,20000,32,160,'','');
          InsertItemTrkgInfo(031201D,'','LT04',0D,0D);

          IF LastIteration = '28-1-14-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '28-1-14-30' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.SETRANGE(WhseRcptLine."Item No.",'80100');
          IF WhseRcptLine.FIND('-') THEN BEGIN
            WhseRcptLine.VALIDATE("Qty. to Receive",0);
            WhseRcptLine.MODIFY(TRUE);
          END;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-1-14-40' THEN EXIT;

          WhseActivHeader.SETRANGE(Type,WhseActivHeader.Type::"Put-away");
          IF WhseActivHeader.FIND('-') THEN
          WhseActivHeader.DELETEALL(TRUE);

          IF LastIteration = '28-1-14-50' THEN EXIT;

          CLEAR(UndoPurchaseReceiptLine);
          PurchRcptLine.SETRANGE("Document No.",'107004');
          PurchRcptLine.SETRANGE("Line No.",10000);
          PurchRcptLine.FIND('-');
          UndoPurchaseReceiptLine.SetHideDialog(TRUE);
          UndoPurchaseReceiptLine.RUN(PurchRcptLine);

          IF LastIteration = '28-1-14-60' THEN EXIT;

          CLEAR(WhseRcptHeader);
          InsertWhseRcptHeader(WhseRcptHeader,'WHITE','RECEIVE','W-08-0001');
          CreateWhseRcptBySourceFilter(WhseRcptHeader,'Vend10000');

          IF LastIteration = '28-1-14-70' THEN EXIT;

          WhseRcptLine.Reset();
          IF WhseRcptLine.FIND('-') THEN
            REPEAT
              WhseRcptLine.VALIDATE("Qty. to Receive",3);
              WhseRcptLine.MODIFY(TRUE);
            UNTIL WhseRcptLine.Next() =0;

          IF LastIteration = '28-1-14-80' THEN EXIT;

          WhseRcptLine.Reset();
          IF WhseRcptLine.FIND('-') THEN
            REPEAT
              WhseRcptLine2.GET(WhseRcptLine."No.",WhseRcptLine."Line No.");
              PostWhseReceipt(WhseRcptLine2);
            UNTIL WhseRcptLine.Next() =0;

          IF LastIteration = '28-1-14-90' THEN EXIT;

          CLEAR(WhseActivLine);
          IF WhseActivLine.FIND('-') THEN
            REPEAT
              PostWhseActivity(WhseActivLine);
            UNTIL WhseActivLine.Next() =0;

          IF LastIteration = '28-1-14-100' THEN EXIT;

        // 28-1-15

          VerifyPostCondition(UseCaseNo,TestCaseNo,15,LastILENo);

          IF LastIteration = '28-1-15-10' THEN EXIT;

        // 28-1-16

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'30000',041201D);
          ModifyPurchHeader(PurchHeader,041201D,'WHITE','',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','WHITE',1,'PALLET',1074,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','WHITE',1,'PALLET',133.35,FALSE);

          IF LastIteration = '28-1-16-10' THEN EXIT;

          InsertResEntry(
            ResEntry,'WHITE',10000,2,041201D,'80002','','','LN06',-1,-35,39,5,PurchHeader."No.",'',10000,FALSE);
          InsertResEntry(
            ResEntry,'WHITE',20000,2,041201D,'80100','','','LT04',-1,-32,39,5,PurchHeader."No.",'',20000,FALSE);

          IF LastIteration = '28-1-16-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseShptHeader);
          CreateWhseShptFromPurch(PurchHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-1-16-30' THEN EXIT;

          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-1-16-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-1-16-50' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);

          IF LastIteration = '28-1-16-60' THEN EXIT;

        // 28-1-17

          VerifyPostCondition(UseCaseNo,TestCaseNo,17,LastILENo);

          IF LastIteration = '28-1-17-10' THEN EXIT;

        END;
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
        ResEntry: Record "Reservation Entry";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemUnitofMeasure2: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
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
        ResMgmt: Codeunit "Reservation Management";
        AutoReserv: Boolean;
        WhseWkshLineNo: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 28-2-1

          SetGlobalPreconditions;

          IF LastIteration = '28-2-1-10' THEN EXIT;

          WITH Item DO BEGIN
            GET('80100');
            "Item Tracking Code" := 'LOTALL';
            MODIFY(TRUE);
            ItemUnitofMeasure.Init();
            ItemUnitofMeasure."Item No." := "No.";
            ItemUnitofMeasure.VALIDATE(Code,'PCS');
            ItemUnitofMeasure.VALIDATE("Qty. per Unit of Measure",2.5);
            IF NOT ItemUnitofMeasure.Insert() then
              ItemUnitofMeasure.Modify();

            GET('N_TEST');
            ItemUnitofMeasure.GET("No.",'PCS');
            ItemUnitofMeasure2.Init();
            ItemUnitofMeasure2 := ItemUnitofMeasure;
            ItemUnitofMeasure2.Code := 'L';
            IF NOT ItemUnitofMeasure2.Insert() then
              ItemUnitofMeasure2.Modify();
            ItemUnitofMeasure.Delete();

            ItemUnitofMeasure.Init();
            ItemUnitofMeasure."Item No." := "No.";
            ItemUnitofMeasure.VALIDATE(Code,'CAN');
            ItemUnitofMeasure.VALIDATE("Qty. per Unit of Measure",3.33333);
            IF NOT ItemUnitofMeasure.Insert() then
              ItemUnitofMeasure.Modify();

            "Item Tracking Code" := 'LOTALL';
            VALIDATE("Purch. Unit of Measure",'L');
            "Base Unit of Measure" := 'L';
            Modify();
          END;

          IF LastIteration = '28-2-1-20' THEN EXIT;

        // 28-2-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS28-2-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','WHITE',1,'PCS',33.35,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'N_TEST','','WHITE',0.5,'CAN',58.23,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_TEST','','WHITE',1,'PALLET',123.12,FALSE);

          IF LastIteration = '28-2-2-10' THEN EXIT;

          SetSourceItemTrkgInfo('80100','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,1,2.5,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);
          SetSourceItemTrkgInfo('N_TEST','','WHITE','','',39,1,PurchHeader."No.",'',0,20000,1,1.66667,'','');
          InsertItemTrkgInfo(251101D,'','LT01',0D,0D);

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '28-2-2-20' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '28-2-2-30' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-2-2-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-2-2-50' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'62000',261101D);
          ModifySalesHeader(SalesHeader,261101D,'WHITE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'A_TEST','',1,'PCS',120,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'80100','',0.5,'PCS',11.2,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::Item,'N_TEST','',0.25,'CAN',210,'WHITE','');

          IF LastIteration = '28-2-2-60' THEN EXIT;

          SetSourceItemTrkgInfo('80100','','WHITE','','',37,1,SalesHeader."No.",'',0,20000,1,1.25,'','');
          InsertItemTrkgInfo(261101D,'','LN01',0D,0D);
          SetSourceItemTrkgInfo('N_TEST','','WHITE','','',37,1,SalesHeader."No.",'',0,30000,1,0.83333,'','');
          InsertItemTrkgInfo(261101D,'','LT01',0D,0D);

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '28-2-2-70' THEN EXIT;

          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-2-2-80' THEN EXIT;

          WhseShptHeader.Reset();
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-2-2-90' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-2-2-100' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);

          IF LastIteration = '28-2-2-110' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'62000',261101D);
          ModifySalesHeader(SalesHeader,261101D,'WHITE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80100','',1,'BOX',5.99,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'N_TEST','',0.25,'CAN',145,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::Item,'80100','',1,'PACK',1.12,'WHITE','');

          IF LastIteration = '28-2-2-120' THEN EXIT;

          SetSourceItemTrkgInfo('80100','','WHITE','','',37,1,SalesHeader."No.",'',0,10000,1,1,'','');
          InsertItemTrkgInfo(261101D,'','LN01',0D,0D);
          SetSourceItemTrkgInfo('N_TEST','','WHITE','','',37,1,SalesHeader."No.",'',0,20000,1,0.83333,'','');
          InsertItemTrkgInfo(261101D,'','LT01',0D,0D);
          SetSourceItemTrkgInfo('80100','','WHITE','','',37,1,SalesHeader."No.",'',0,30000,0.2,0.2,'','');
          InsertItemTrkgInfo(261101D,'','LN01',0D,0D);

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '28-2-2-130' THEN EXIT;

          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-2-2-140' THEN EXIT;

          CLEAR(WhseShptHeader);
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-2-2-150' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-2-2-160' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,FALSE);

          IF LastIteration = '28-2-2-170' THEN EXIT;

        // 28-2-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '28-2-3-10' THEN EXIT;

        // 28-2-4

          Commit();
          InsertAdjmtWhseJnlLine(
            WhseItemJnlLine,'ADJMT','DEFAULT','White',10000,281101D,'80100','','PICK','W-03-0001',3,'PALLET');
          InsertAdjmtWhseJnlLine(
            WhseItemJnlLine,'ADJMT','DEFAULT','White',20000,281101D,'80100','','PICK','W-03-0002',3,'PALLET');
          InsertAdjmtWhseJnlLine(
            WhseItemJnlLine,'ADJMT','DEFAULT','White',30000,281101D,'80100','','PICK','W-03-0003',3,'PACK');
          InsertAdjmtWhseJnlLine(
            WhseItemJnlLine,'ADJMT','DEFAULT','White',40000,281101D,'80002','','PICK','W-04-0001',3,'PALLET');
          InsertAdjmtWhseJnlLine(
            WhseItemJnlLine,'ADJMT','DEFAULT','White',50000,281101D,'80002','','PICK','W-04-0002',3,'PALLET');

          IF LastIteration = '28-2-4-10' THEN EXIT;

          CreateWhseItemTrack('80100','','WHITE','','LN02',96,1,7311,0,'DEFAULT','ADJMT',0,10000);
          CreateWhseItemTrack('80100','','WHITE','','LN03',96,1,7311,0,'DEFAULT','ADJMT',0,20000);
          CreateWhseItemTrack('80100','','WHITE','','LN04',0.6,1,7311,0,'DEFAULT','ADJMT',0,30000);
          CreateWhseItemTrack('80002','','WHITE','','LS01',105,1,7311,0,'DEFAULT','ADJMT',0,40000);
          CreateWhseItemTrack('80002','','WHITE','','LS02',105,1,7311,0,'DEFAULT','ADJMT',0,50000);

          IF LastIteration = '28-2-4-20' THEN EXIT;

          WhseItemJnlLine.Reset();
          WhseItemJnlLine.FIND('-');
          WhseJnlPostBatch(WhseItemJnlLine);

          IF LastIteration = '28-2-4-30' THEN EXIT;

          ItemJnlLine."Journal Template Name" := 'ITEM';
          ItemJnlLine."Journal Batch Name" := 'DEFAULT';
          CalculateWhseAdjustment.SetItemJnlLine(ItemJnlLine);
          CalculateWhseAdjustment.InitializeRequest(281101D,'T-28-2-4');
          CalculateWhseAdjustment.USEREQUESTPAGE(FALSE);
          CalculateWhseAdjustment.RunModal();
          CLEAR(CalculateWhseAdjustment);

          IF LastIteration = '28-2-4-40' THEN EXIT;

          IF LastIteration = '28-2-4-50' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '28-2-4-60' THEN EXIT;

        // 28-2-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '28-2-5-10' THEN EXIT;

        // 28-2-6
          WhseWkshLineNo := 10000;

          Commit();
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',GetNextNo(WhseWkshLineNo),291101D,
            '80100','','W-03-0001','W-01-0001',3,'PALLET');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',GetNextNo(WhseWkshLineNo),291101D,
            '80100','','W-03-0002','W-03-0003',2,'PALLET');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',GetNextNo(WhseWkshLineNo),291101D,
            '80100','','W-03-0002','W-01-0002',1,'PALLET');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',GetNextNo(WhseWkshLineNo),291101D,
            '80100','','W-03-0003','W-01-0003',3,'PACK');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',GetNextNo(WhseWkshLineNo),291101D,
            '80002','','W-04-0001','W-03-0003',3,'PALLET');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',GetNextNo(WhseWkshLineNo),291101D,
            '80002','','W-04-0002','W-03-0003',3,'PALLET');

          IF LastIteration = '28-2-6-10' THEN EXIT;

          WhseWkshLineNo := 10000;
          CreateWhseItemTrack('80100','','WHITE','','LN02',96,32,7326,0,'DEFAULT','MOVEMENT',0,GetNextNo(WhseWkshLineNo));
          CreateWhseItemTrack('80100','','WHITE','','LN03',64,32,7326,0,'DEFAULT','MOVEMENT',0,GetNextNo(WhseWkshLineNo));
          CreateWhseItemTrack('80100','','WHITE','','LN03',32,32,7326,0,'DEFAULT','MOVEMENT',0,GetNextNo(WhseWkshLineNo));
          CreateWhseItemTrack('80100','','WHITE','','LN04',0.6,0.2,7326,0,'DEFAULT','MOVEMENT',0,GetNextNo(WhseWkshLineNo));
          CreateWhseItemTrack('80002','','WHITE','','LS01',105,35,7326,0,'DEFAULT','MOVEMENT',0,GetNextNo(WhseWkshLineNo));
          CreateWhseItemTrack('80002','','WHITE','','LS02',105,35,7326,0,'DEFAULT','MOVEMENT',0,GetNextNo(WhseWkshLineNo));

          IF LastIteration = '28-2-6-20' THEN EXIT;

          WhseWkshLine.SETRANGE("Worksheet Template Name",WhseWkshLine."Worksheet Template Name");
          WhseWkshLine.SETRANGE(Name,WhseWkshLine.Name);
          WhseWkshLine.SETRANGE("Location Code",WhseWkshLine."Location Code");
          CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
          CreateMovFromWhseSource.USEREQUESTPAGE(FALSE);
          CreateMovFromWhseSource.Initialize('',0,FALSE,FALSE,FALSE);
          CreateMovFromWhseSource.RunModal();
          CLEAR(CreateMovFromWhseSource);

          IF LastIteration = '28-2-6-30' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-2-6-40' THEN EXIT;

          InsertWhseIntPutAwayOrderHead(WhseIntPutAwayHeader,'WHITE','PICK','W-03-0003');
          InsertWhseIntPutAwayOrderLines(
            WhseIntPutAwayOrderLine,WhseIntPutAwayHeader,10000,'80100','','WHITE','PICK','W-03-0003',1.5,'PALLET');
          InsertWhseIntPutAwayOrderLines(
            WhseIntPutAwayOrderLine,WhseIntPutAwayHeader,20000,'80100','','WHITE','PICK','W-03-0003',0.5,'PALLET');
          InsertWhseIntPutAwayOrderLines(
            WhseIntPutAwayOrderLine,WhseIntPutAwayHeader,30000,'80002','','WHITE','PICK','W-03-0003',6,'PALLET');

          IF LastIteration = '28-2-6-50' THEN EXIT;

          CreaPutAwayFromIntPutAwayOrder(WhseIntPutAwayHeader);

          IF LastIteration = '28-2-6-60' THEN EXIT;

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN

            SETFILTER("Item No.",'%1','80002');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Lot No.",'LS01');
                VALIDATE("Qty. to Handle",3);
                MODIFY(TRUE);
              until Next() = 0;

            CLEAR(WhseActivLine);
            SETFILTER("Item No.",'%1','80100');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Lot No.",'LN03');
                MODIFY(TRUE);
              until Next() = 0;
            FIND('+');
            VALIDATE("Bin Code",'W-01-0002');
            MODIFY(TRUE);

            CLEAR(WhseActivLine);
            FIND('-');
            PostWhseActivity(WhseActivLine);

            IF FIND('-') THEN
              REPEAT
                VALIDATE("Lot No.",'LS02');
                MODIFY(TRUE);
              until Next() = 0;

            CLEAR(WhseActivLine);
            FIND('-');
            PostWhseActivity(WhseActivLine);
          END;

          IF LastIteration = '28-2-6-70' THEN EXIT;

          InsertWhsePickOrderHeader(WhsePickOrderHeader,'WHITE','PICK','W-02-0002');
          InsertWhsePickOrderLines(
            WhseInternalPickLine,WhsePickOrderHeader,10000,'80100','','WHITE','PICK','W-02-0002',16,'BOX');
          InsertWhsePickOrderLines(
            WhseInternalPickLine,WhsePickOrderHeader,20000,'80002','','WHITE','PICK','W-02-0002',35,'PCS');

          IF LastIteration = '28-2-6-80' THEN EXIT;

          CreateWhseItemTrack('80100','','WHITE','','LN03',16,1,7334,0,'WI000001','',0,10000);
          CreateWhseItemTrack('80002','','WHITE','','LS01',35,1,7334,0,'WI000001','',0,20000);

          IF LastIteration = '28-2-6-90' THEN EXIT;

          CreatePickFromPickOrder(WhsePickOrderHeader);

          IF LastIteration = '28-2-6-100' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-2-6-110' THEN EXIT;

        // 28-2-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '28-2-7-10' THEN EXIT;

        // 28-2-8

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'61000',291101D);
          ModifySalesHeader(SalesHeader,291101D,'WHITE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80100','',10,'BOX',12.6,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'80100','',2,'PACK',2.1,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::Item,'80002','',10,'PCS',1260,'WHITE','');
          InsertSalesLine(
            SalesLine,SalesHeader,40000,SalesLine.Type::Item,'80002','',1,'PALLET',42300,'WHITE','');

          IF LastIteration = '28-2-8-10' THEN EXIT;

          SalesLine.Reset();
          IF SalesLine.FIND('-') THEN
            REPEAT
              ResMgmt.SetSalesLine(SalesLine);
              ResMgmt.AutoReserve(AutoReserv,'',291101D,SalesLine.Quantity,SalesLine."Quantity (Base)");
            UNTIL SalesLine.Next() = 0;

          IF LastIteration = '28-2-8-20' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '28-2-8-30' THEN EXIT;

          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-2-8-40' THEN EXIT;

          CLEAR(WhseShptHeader);
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-2-8-50' THEN EXIT;

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN
            SETRANGE("Item No.",'80100');
            SETRANGE("Bin Code",'W-01-0001');
            IF FIND('-') THEN BEGIN
              SETRANGE("Bin Code");
              REPEAT
                VALIDATE("Lot No.",'LN03');
                MODIFY(TRUE);
              until Next() = 0;
            END;
            SETRANGE("Bin Code",'W-01-0003');
            IF FIND('-') THEN BEGIN
              SETRANGE("Bin Code");
              REPEAT
                VALIDATE("Lot No.",'LN04');
                MODIFY(TRUE);
              until Next() = 0;
            END;
            SETRANGE("Item No.",'80002');
            IF FIND('-') THEN
              REPEAT
                VALIDATE("Lot No.",'LS01');
                MODIFY(TRUE);
              until Next() = 0;
            Reset();
            FIND('-');
          END;
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-2-8-60' THEN EXIT;

          CLEAR(WhseShptLine);
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,TRUE);

          IF LastIteration = '28-2-8-70' THEN EXIT;

        // 28-2-9

          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo);

          IF LastIteration = '28-2-9-10' THEN EXIT;

        // 28-2-10

          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'61000',301101D);
          ModifySalesHeader(SalesHeader,301101D,'WHITE',TRUE,TRUE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'80100','',1,'PACK',2.1,'WHITE','');
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'80100','',1,'PACK',2.1,'WHITE','');
            InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'80002','',1,'PCS',1260,'WHITE','');
            InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'80002','',2,'PCS',1260,'WHITE','');
          END;

          IF LastIteration = '28-2-10-10' THEN EXIT;

          SetSourceItemTrkgInfo('80100','','WHITE','','',37,5,SalesHeader."No.",'',0,10000,1,0.2,'','');
          InsertItemTrkgInfo(301101D,'','LN02',0D,0D);
          SetSourceItemTrkgInfo('80100','','WHITE','','',37,5,SalesHeader."No.",'',0,20000,1,0.2,'','');
          InsertItemTrkgInfo(301101D,'','LN03',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',37,5,SalesHeader."No.",'',0,30000,1,1,'','');
          InsertItemTrkgInfo(301101D,'','LS01',0D,0D);
          SetSourceItemTrkgInfo('80002','','WHITE','','',37,5,SalesHeader."No.",'',0,40000,1,2,'','');
          InsertItemTrkgInfo(301101D,'','LS02',0D,0D);

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '28-2-10-20' THEN EXIT;

          CLEAR(WhseReceiptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseReceiptHeader,'WHITE');

          IF LastIteration = '28-2-10-30' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-2-10-40' THEN EXIT;

        // 28-2-11

          VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo);

          IF LastIteration = '28-2-11-10' THEN EXIT;

        END;
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
        WITH TestScriptMgmt DO BEGIN
        // 28-3-1

          SetGlobalPreconditions;

          WITH Item DO BEGIN
            SETFILTER("No.",'%1|%2','80100','80002');
            MODIFYALL("Purch. Unit of Measure",'PALLET');
            MODIFYALL(Item."Item Tracking Code",'LOTALL');
          END;

          IF LastIteration = '28-3-1-10' THEN EXIT;

          WITH TransRoute DO BEGIN
            Init();
            "Transfer-from Code" := 'BLUE';
            "Transfer-to Code" := 'WHITE';
            "In-Transit Code" := 'OWN LOG.';
            if not Insert() then
              Modify();
          END;

          IF LastIteration = '28-3-1-20' THEN EXIT;

          WITH SKU DO BEGIN
            Init();
            "Location Code" := 'WHITE';
            "Item No." := '80100';
            "Replenishment System" := 2;
            "Transfer-from Code" := 'BLUE';
            "Reordering Policy" := 4;
            "Transfer-Level Code" := -1;
            if not Insert() then
              Modify();
            Init();
            "Location Code" := 'WHITE';
            "Item No." := '80002';
            "Replenishment System" := 2;
            "Transfer-from Code" := 'BLUE';
            "Reordering Policy" := 4;
            "Transfer-Level Code" := -1;
            if not Insert() then
              Modify();
            Init();
            "Location Code" := 'BLUE';
            "Item No." := '80100';
            "Replenishment System" := 0;
            "Vendor No." := '10000';
            "Reordering Policy" := 4;
            if not Insert() then
              Modify();
            Init();
            "Location Code" := 'BLUE';
            "Item No." := '80002';
            "Replenishment System" := 0;
            "Vendor No." := '10000';
            "Reordering Policy" := 4;
            if not Insert() then
              Modify();
            Init();
          END;

          IF LastIteration = '28-3-1-30' THEN EXIT;

        // 28-3-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80100','',48,'BOX',30.7,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80002','',2,'PALLET',37000,'WHITE','');
           END;

          ReleaseSalesDocument(SalesHeader);

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80100','',1,'PALLET',307.0,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80002','',70,'PCS',1370,'WHITE','');
           END;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '28-3-2-10' THEN EXIT;

          Item.SETFILTER("Location Filter",'<>%1','');
          CalcPlan.SetTemplAndWorksheet('REQ','DEFAULT',TRUE);
          CalcPlan.InitializeRequest(251101D,251101D,FALSE);
          CalcPlan.SETTABLEVIEW(Item);
          CalcPlan.USEREQUESTPAGE := FALSE;
          CalcPlan.RunModal();

          IF LastIteration = '28-3-2-20' THEN EXIT;

          ReqWkshLine."Worksheet Template Name" := 'REQ';
          ReqWkshLine."Journal Batch Name" := 'DEFAULT';
          CarryOut.SetReqWkshLine(ReqWkshLine);
          CarryOut.SetHideDialog(TRUE);
          CarryOut.InitializeRequest(251101D,251101D,251101D,251101D,'');
          CarryOut.USEREQUESTPAGE := FALSE;
          CarryOut.Run();

          IF LastIteration = '28-3-2-30' THEN EXIT;

          PurchHeader.Reset();
          PurchHeader.FIND('-');
          PurchLine.SETRANGE("Document No.",PurchHeader."No.");
          PurchLine.FIND('+');
          i := PurchLine."Line No." + 10000;
          InsertPurchLine(
            PurchLine,PurchHeader,i,PurchLine.Type::Item,'80100','','BLUE',1,'PALLET',82,FALSE);
          i := PurchLine."Line No." + 10000;
          InsertPurchLine(
            PurchLine,PurchHeader,i,PurchLine.Type::Item,'80100','','BLUE',0.5,'PALLET',82,FALSE);

          IF LastIteration = '28-3-2-40' THEN EXIT;

          SetSourceItemTrkgInfo('80002','','BLUE','','',39,1,PurchHeader."No.",'',0,10000,35,140,'','');
          InsertItemTrkgInfo(251101D,'','LS01',0D,0D);
          SetSourceItemTrkgInfo('80100','','BLUE','','',39,1,PurchHeader."No.",'',0,20000,32,80,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);
          SetSourceItemTrkgInfo('80100','','BLUE','','',39,1,PurchHeader."No.",'',0,30000,32,32,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);
          SetSourceItemTrkgInfo('80100','','BLUE','','',39,1,PurchHeader."No.",'',0,40000,32,16,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);

          IF LastIteration = '28-3-2-50' THEN EXIT;

          PurchHeader.FIND('-');
          ModifyPurchLine(PurchHeader,10000,4,0,30000,0);
          ModifyPurchLine(PurchHeader,20000,2.5,0,82,0);
          ModifyPurchLine(PurchHeader,30000,1,0,82,0);
          ModifyPurchLine(PurchHeader,40000,0.5,0,82,0);

          PostPurchOrder(PurchHeader);

          IF LastIteration = '28-3-2-60' THEN EXIT;

          TransLine.Reset();
          TransLine.SETRANGE("Transfer-to Code",'WHITE');
          TransLine.FIND('-');
          TransLine.VALIDATE(Quantity,4);
          TransLine.VALIDATE("Unit of Measure Code",'PALLET');
          TransLine.Modify();
          SetSourceItemTrkgInfo('80002','','BLUE','','',5741,0,TransLine."Document No.",'',0,TransLine."Line No.",35,140,'','');
          InsertItemTrkgInfo(251101D,'','LS01',0D,0D);

          TransLine.Reset();
          TransLine.SETRANGE("Transfer-to Code",'WHITE');
          TransLine.FIND('+');
          TransLine.VALIDATE(Quantity,2.5);
          TransLine.VALIDATE("Unit of Measure Code",'PALLET');
          TransLine.Modify();
          SetSourceItemTrkgInfo('80100','','BLUE','','',5741,0,TransLine."Document No.",'',0,TransLine."Line No.",32,80,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);

          IF LastIteration = '28-3-2-70' THEN EXIT;

          TransLine.Reset();
          TransLine.SETRANGE("Transfer-to Code",'WHITE');
          TransLine.FIND('+');
          i := TransLine."Line No." + 10000;

          TransHeader.FIND('-');
          InsertTransferLine(TransLine,TransHeader."No.",i,'80100','','PALLET',1.5,0,1.5);
          SetSourceItemTrkgInfo('80100','','BLUE','','',5741,0,TransLine."Document No.",'',0,TransLine."Line No.",32,48,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);

          IF LastIteration = '28-3-2-80' THEN EXIT;

          PostTransferOrder(TransHeader);

          IF LastIteration = '28-3-2-90' THEN EXIT;

          CLEAR(WhseRcptHeader);
          InsertWhseRcptHeader(WhseRcptHeader,'WHITE','RECEIVE','W-08-0001');

          IF LastIteration = '28-3-2-100' THEN EXIT;

          CreateWhseRcptBySourceFilter(WhseRcptHeader,'CUST30000');

          IF LastIteration = '28-3-2-110' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-3-2-120' THEN EXIT;

        // 28-3-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '28-3-3-10' THEN EXIT;

        // 28-3-4

          CLEAR(WhseActivLine);
          WhseActivLine.Reset();
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-3-4-10' THEN EXIT;

          CLEAR(SalesHeader);
          SalesHeader.Reset();
          SalesHeader.SETRANGE("Sell-to Customer No.",'30000');
          SalesHeader.FIND('-');
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');

          IF LastIteration = '28-3-4-20' THEN EXIT;

          WhseShptHeader.Reset();
          WhseShptHeader.SETRANGE("Location Code",'WHITE');
          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '28-3-4-30' THEN EXIT;

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.SETRANGE("Item No.",'80002');
          IF WhseActivLine.FIND('-') THEN BEGIN
            REPEAT
              WhseActivLine.VALIDATE("Lot No.",'LS01');
              WhseActivLine.MODIFY(TRUE);
            UNTIL WhseActivLine.Next() = 0;
          END;

          WhseActivLine.SETRANGE("Item No.",'80100');
          IF WhseActivLine.FIND('-') THEN BEGIN
            REPEAT
              WhseActivLine.VALIDATE("Lot No.",'LN01');
              WhseActivLine.MODIFY(TRUE);
            UNTIL WhseActivLine.Next() = 0;
          END;

          IF LastIteration = '28-3-4-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.Reset();
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-3-4-50' THEN EXIT;

          WhseShptLine.Reset();
          WhseShptLine.FIND('-');
          PostWhseShipment(WhseShptLine,TRUE);

          IF LastIteration = '28-3-4-60' THEN EXIT;

          PurchHeader.Reset();
          PurchHeader.FIND('-');
          PurchHeader."Vendor Invoice No." := 'TCS28-3-2';
          PurchHeader.Modify();

          IF LastIteration = '28-3-4-70' THEN EXIT;

          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '28-3-4-80' THEN EXIT;

        // 28-3-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '28-3-5-10' THEN EXIT;

        END;
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
        ProdOrderStatMgmt: Codeunit "Prod. Order Status Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSourceType: Option " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 28-4-1

          SetGlobalPreconditions;

          IF LastIteration = '28-4-1-10' THEN EXIT;

          WITH Item DO BEGIN
            SETFILTER("No.",'%1|%2|%3|%4','A_TEST','B_TEST','D_PROD','E_PROD');
            MODIFYALL("Item Tracking Code",'LOTALL');
          END;

          IF LastIteration = '28-4-1-20' THEN EXIT;

          ProdBOMHeader.GET('E_PROD');
          ProdBOMHeader.Status := 0;
          ProdBOMHeader.MODIFY(TRUE);

          ProdBOMLine.Reset();
          ProdBOMLine.SETRANGE("Production BOM No.",'E_PROD');
          ProdBOMLine.FIND('-');
          ProdBOMLine.VALIDATE("Quantity per",1);
          ProdBOMLine."Unit of Measure Code"  := 'PALLET';
          ProdBOMLine.MODIFY(TRUE);

          ProdBOMLine.Next();
          ProdBOMLine.VALIDATE("Quantity per",1);
          ProdBOMLine."Unit of Measure Code"  := 'PALLET';
          ProdBOMLine.MODIFY(TRUE);

          ProdBOMLine.Next();
          ProdBOMLine.VALIDATE("Quantity per",0.9);
          ProdBOMLine."Unit of Measure Code"  := 'PALLET';
          ProdBOMLine.MODIFY(TRUE);

          ProdBOMHeader.GET('E_PROD');
          ProdBOMHeader."Unit of Measure Code" := 'PALLET';
          ProdBOMHeader.Status := 1;
          ProdBOMHeader.MODIFY(TRUE);


          IF LastIteration = '28-4-1-30' THEN EXIT;

        // 28-4-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS28-4-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'B_TEST','','WHITE',6,'PALLET',300,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','12','WHITE',5,'PALLET',133.35,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'D_PROD','','WHITE',7,'PALLET',58.23,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'A_TEST','12','WHITE',3,'PALLET',133.35,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'D_PROD','','WHITE',3,'PALLET',58.23,FALSE);

          IF LastIteration = '28-4-2-10' THEN EXIT;

          SetSourceItemTrkgInfo('B_TEST','','WHITE','','',39,1,PurchHeader."No.",'',0,10000,10,60,'','');
          InsertItemTrkgInfo(251101D,'','LN01',0D,0D);

          CreateItemTrackfromJnlLine('A_TEST','12','WHITE','','LT01',39,13,2,39,1,PurchHeader."No.",'',0,20000,TRUE);
          CreateItemTrackfromJnlLine('A_TEST','12','WHITE','','LT02',26,13,2,39,1,PurchHeader."No.",'',0,20000,TRUE);

          SetSourceItemTrkgInfo('D_PROD','','WHITE','','',39,1,PurchHeader."No.",'',0,30000,11,77,'','');
          InsertItemTrkgInfo(251101D,'','LS01',0D,0D);
          SetSourceItemTrkgInfo('A_TEST','12','WHITE','','',39,1,PurchHeader."No.",'',0,40000,13,39,'','');
          InsertItemTrkgInfo(251101D,'','LT02',0D,0D);
          SetSourceItemTrkgInfo('D_PROD','','WHITE','','',39,1,PurchHeader."No.",'',0,50000,11,33,'','');
          InsertItemTrkgInfo(251101D,'','LS02',0D,0D);


          IF LastIteration = '28-4-2-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '28-4-2-30' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-4-2-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.Reset();
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-4-2-50' THEN EXIT;

          InsertProdOrder(ProdOrder,3,0,'E_PROD',5,'WHITE');

          IF LastIteration = '28-4-2-60' THEN EXIT;

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          WhseProdRelease.Release(ProdOrder);

          ProdOrderLine.FIND('-');
          ProdOrderLine.VALIDATE(ProdOrderLine."Unit of Measure Code",'Pallet');
          ProdOrderLine.MODIFY(TRUE);

          SetSourceItemTrkgInfo('E_PROD','','WHITE','','',5406,3,ProdOrder."No.",'',10000,0,9,45,'','');
          InsertItemTrkgInfo(251101D,'','LE01',0D,0D);

          IF LastIteration = '28-4-2-70' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Item No.",'A_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            SetSourceItemTrkgInfo('A_TEST','12','WHITE','','',5407,3,ProdOrder."No.",'',10000,ProdOrderComp."Line No.",13,65,'','');
            InsertItemTrkgInfo(241101D,'','LT02',0D,0D);
          END;
          ProdOrderComp.SETRANGE("Item No.",'B_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            SetSourceItemTrkgInfo('B_TEST','','WHITE','','',5407,3,ProdOrder."No.",'',10000,ProdOrderComp."Line No.",10,50,'','');
            InsertItemTrkgInfo(241101D,'','LN01',0D,0D);
          END;
          ProdOrderComp.SETRANGE("Item No.",'D_PROD');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            SetSourceItemTrkgInfo('D_PROD','','WHITE','','',5407,3,ProdOrder."No.",'',10000,ProdOrderComp."Line No.",11,55,'','');
            InsertItemTrkgInfo(241101D,'','LS01',0D,0D);
          END;

          IF LastIteration = '28-4-2-80' THEN EXIT;

          ProdOrder.Reset();
          ProdOrder.FIND('-');
          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE(Status,ProdOrder.Status);
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          IF ProdOrderComp.FIND('-') THEN
            REPEAT
              ItemTrackingMgt.InitItemTrkgForTempWkshLine(
                WhseSourceType::Production,ProdOrderComp."Prod. Order No.",
                ProdOrderComp."Prod. Order Line No.",DATABASE::"Prod. Order Component",
                ProdOrderComp.Status,ProdOrderComp."Prod. Order No.",
                ProdOrderComp."Prod. Order Line No.",ProdOrderComp."Line No.");
            UNTIL ProdOrderComp.Next() = 0;
          Commit();

          CLEAR(CreatePickFromWhseSource);
          ProdOrder.Reset();
          ProdOrder.FIND('-');
          CreatePickFromWhseSource.SetProdOrder(ProdOrder);
          CreatePickFromWhseSource.SetHideValidationDialog(TRUE);
          CreatePickFromWhseSource.USEREQUESTPAGE(FALSE);
          CreatePickFromWhseSource.RunModal();
          CLEAR(CreatePickFromWhseSource);

          IF LastIteration = '28-4-2-90' THEN EXIT;

        // 28-4-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '28-4-3-10' THEN EXIT;

        // 28-4-4

          CLEAR(WhseActivLine);
          WhseActivLine.Reset();
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-4-4-10' THEN EXIT;

          ProdOrder.FIND('-');
          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          IF LastIteration = '28-4-4-20' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '28-4-4-30' THEN EXIT;

          ProdOrder.Reset();
          ProdOrder.FIND('-');
          CreateOutputJnlLine(ItemJnlLine,'Output','DEFAULT',ProdOrder."No.");

          IF LastIteration = '28-4-4-40' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '28-4-4-50' THEN EXIT;

          ProdOrder.FIND('-');
          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,4,301101D,FALSE);

          IF LastIteration = '28-4-4-60' THEN EXIT;

        // 28-4-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '28-4-5-10' THEN EXIT;

        END;
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
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        BinContent: Record "Bin Content";
        ItemJnlLine: Record "Item Journal Line";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        ReplenishmtBatch: Report "Calculate Bin Replenishment";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        CalcConsumption: Report "Calc. Consumption";
        CreateRes: Codeunit "Create Reserv. Entry";
        ResMgmt: Codeunit "Reservation Management";
        ProdOrderStatMgmt: Codeunit "Prod. Order Status Management";
        OutpExplRtng: Codeunit "Output Jnl.-Expl. Route";
    begin
        WITH TestScriptMgmt DO BEGIN
        // 28-5-1

          SetGlobalPreconditions;

          IF LastIteration = '28-5-1-10' THEN EXIT;

          WITH Item DO BEGIN
            SETFILTER("No.",'%1','D_PROD');
            MODIFYALL("Flushing Method",1);
            SETFILTER("No.",'%1|%2','A_TEST','B_TEST');
            MODIFYALL("Flushing Method",2);
          END;

          WITH Item DO BEGIN
            SETFILTER("No.",'%1|%2|%3','A_TEST','B_TEST','D_PROD');
            MODIFYALL("Item Tracking Code",'LOTALL');
          END;

          IF LastIteration = '28-5-1-20' THEN EXIT;

          InsertDedicatedBin('WHITE','Production','W-07-0001','A_TEST','12','PALLET',1,6);
          InsertDedicatedBin('WHITE','Production','W-07-0001','B_TEST','','PALLET',1,6);
          InsertDedicatedBin('WHITE','Production','W-07-0001','D_PROD','','PALLET',1,6);

          IF LastIteration = '28-5-1-40' THEN EXIT;

        // 28-5-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS28-5-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_TEST','12','WHITE',10,'PALLET',133.35,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'B_TEST','','WHITE',10,'PALLET',300,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'D_PROD','','WHITE',10,'PALLET',58.23,FALSE);

          IF LastIteration = '28-5-2-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,13,10,130,'','LT01','');
          CreateRes.CreateEntry('A_TEST','12','WHITE','',251101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,10,10,100,'','LN01','');
          CreateRes.CreateEntry('B_TEST','','WHITE','',251101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,11,10,110,'','LS01','');
          CreateRes.CreateEntry('D_PROD','','WHITE','',251101D,0D,0,2);

          IF LastIteration = '28-5-2-20' THEN EXIT;
          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '28-5-2-30' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-5-2-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.Reset();
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-5-2-50' THEN EXIT;

          CLEAR(ReplenishmtBatch);
          BinContent.Reset();
          BinContent.FIND('-');
          ReplenishmtBatch.USEREQUESTPAGE(FALSE);
          ReplenishmtBatch.InitializeRequest('MOVEMENT','DEFAULT','WHITE',TRUE,TRUE,FALSE);
          ReplenishmtBatch.SETTABLEVIEW(BinContent);
          ReplenishmtBatch.RunModal();

          IF LastIteration = '28-5-2-60' THEN EXIT;

          WhseWkshLine.FIND('-');
          WhseWkshLine.SETRANGE("Worksheet Template Name",WhseWkshLine."Worksheet Template Name");
          WhseWkshLine.SETRANGE(Name,WhseWkshLine.Name);
          WhseWkshLine.SETRANGE("Location Code",WhseWkshLine."Location Code");
          CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
          CreateMovFromWhseSource.USEREQUESTPAGE(FALSE);
          CreateMovFromWhseSource.Initialize('',1,FALSE,FALSE,FALSE);
          CreateMovFromWhseSource.RunModal();
          CLEAR(CreateMovFromWhseSource);

          IF LastIteration = '28-5-2-70' THEN EXIT;

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);

          WhseActivLine.SETRANGE("Item No.",'A_TEST');
          IF WhseActivLine.FIND('-') THEN
            REPEAT
              WhseActivLine.VALIDATE("Lot No.",'LT01');
              WhseActivLine.MODIFY(TRUE);
            UNTIL WhseActivLine.Next() = 0;

          WhseActivLine.SETRANGE("Item No.",'B_TEST');
          IF WhseActivLine.FIND('-') THEN
            REPEAT
              WhseActivLine.VALIDATE("Lot No.",'LN01');
              WhseActivLine.MODIFY(TRUE);
            UNTIL WhseActivLine.Next() = 0;

          WhseActivLine.SETRANGE("Item No.",'D_PROD');
          IF WhseActivLine.FIND('-') THEN
            REPEAT
              WhseActivLine.VALIDATE("Lot No.",'LS01');
              WhseActivLine.MODIFY(TRUE);
            UNTIL WhseActivLine.Next() = 0;

          IF LastIteration = '28-5-2-80' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.Reset();
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-5-2-90' THEN EXIT;

          InsertProdOrder(ProdOrder,2,0,'E_PROD',40,'WHITE');
          ProdOrder.VALIDATE("Due Date",301101D);
          ProdOrder.MODIFY(TRUE);
          WORKDATE := 301101D;

          IF LastIteration = '28-5-2-100' THEN EXIT;

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          IF LastIteration = '28-5-2-110' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Item No.",'A_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,52,52,'','LT01','');
            CreateRes.CreateEntry('A_TEST','12','WHITE','',0D,301101D,0,2);
          END;
          ProdOrderComp.SETRANGE("Item No.",'B_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,50,50,'','LN01','');
            CreateRes.CreateEntry('B_TEST','','WHITE','',0D,301101D,0,2);
          END;
          ProdOrderComp.SETRANGE("Item No.",'D_PROD');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,60,60,'','LS01','');
            CreateRes.CreateEntry('D_PROD','','WHITE','',0D,301101D,0,2);
          END;
          IF LastIteration = '28-5-2-120' THEN EXIT;

          ProdOrder.FIND('-');
          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,3,301101D,FALSE);

          IF LastIteration = '28-5-2-130' THEN EXIT;

        // 28-5-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '28-5-3-10' THEN EXIT;

        // 28-5-4

          ProdOrder.Reset();
          ProdOrder.FIND('-');
          InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',10000,301101D,
            ItemJnlLine."Entry Type"::Output,'ProdOrder."No."','E_PROD','','WHITE','',
            40,'PCS',0,0);
          ItemJnlLine.SetUpNewLine(ItemJnlLine);
          ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
          ItemJnlLine.VALIDATE("Order No.",ProdOrder."No.");
          ItemJnlLine.VALIDATE("Item No.");
          ItemJnlLine.Modify();

          IF LastIteration = '28-5-4-10' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          OutpExplRtng.RUN(ItemJnlLine);

          IF LastIteration = '28-5-4-20' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '28-5-4-30' THEN EXIT;

          ProdOrder.FIND('-');
          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,4,301101D,FALSE);

          IF LastIteration = '28-5-4-40' THEN EXIT;

        // 28-5-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '28-5-5-10' THEN EXIT;

        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ItemJnlLine: Record "Item Journal Line";
        CalcWorkCenterCal: Report "Calculate Work Center Calendar";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        CreateRes: Codeunit "Create Reserv. Entry";
        ResMgmt: Codeunit "Reservation Management";
        ProdOrderStatMgmt: Codeunit "Prod. Order Status Management";
        OutpExplRtng: Codeunit "Output Jnl.-Expl. Route";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSourceType: Option " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 28-6-1

          SetGlobalPreconditions;

          IF LastIteration = '28-6-1-10' THEN EXIT;

          WITH Item DO BEGIN
            SETFILTER("No.",'%1','D_PROD');
            MODIFYALL("Flushing Method",2);
            SETFILTER("No.",'%1|%2|%3','A_TEST','B_TEST','E_PROD');
            MODIFYALL("Flushing Method",2);
          END;

          WITH Item DO BEGIN
            SETFILTER("No.",'%1|%2|%3','A_TEST','B_TEST','D_PROD');
            MODIFYALL("Item Tracking Code",'LOTALL');
          END;

        //  IF LastIteration = '28-6-1-20' THEN EXIT;

          InsertRoutingHeader(RoutingHeader,'TEST',RoutingHeader.Type::Serial);
          InsertRoutingLine(RoutingLine,RoutingHeader,'','010',RoutingLine.Type::"Work Center",'100',20,5,'100');
          InsertRoutingLine(RoutingLine,RoutingHeader,'','020',RoutingLine.Type::"Work Center",'400',30,5,'');
          RoutingHeader.VALIDATE(Status,RoutingHeader.Status::Certified);
          RoutingHeader.Modify();

          WorkCenter.SETFILTER("No.",'%1|%2','100','400');
          CLEAR(CalcWorkCenterCal);
          CalcWorkCenterCal.InitializeRequest(010101D,311201D);
          CalcWorkCenterCal.USEREQUESTPAGE(FALSE);
          CalcWorkCenterCal.SETTABLEVIEW(WorkCenter);
          CalcWorkCenterCal.RunModal();

          Item.GET('E_PROD');
          Item.VALIDATE("Routing No.",'TEST');
          Item.MODIFY(TRUE);

          InsertDedicatedBin('WHITE','Production','W-07-0001','A_TEST','12','PCS',1,6);
          InsertDedicatedBin('WHITE','Production','W-07-0001','B_TEST','','PCS',1,6);
          InsertDedicatedBin('WHITE','Production','W-07-0001','D_PROD','','PCS',1,6);
          IF LastIteration = '28-6-1-20' THEN EXIT;

        // 28-6-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS28-6-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_TEST','12','WHITE',100,'Pcs',133.35,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'B_TEST','','WHITE',100,'Pcs',300,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'D_PROD','','WHITE',100,'Pcs',58.23,FALSE);

          IF LastIteration = '28-6-2-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,100,100,'','LT01','');
          CreateRes.CreateEntry('A_TEST','12','WHITE','',251101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,100,100,'','LN01','');
          CreateRes.CreateEntry('B_TEST','','WHITE','',251101D,0D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,100,100,'','LS01','');
          CreateRes.CreateEntry('D_PROD','','WHITE','',251101D,0D,0,2);

          IF LastIteration = '28-6-2-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '28-6-2-30' THEN EXIT;

          WhseRcptLine.Reset();
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '28-6-2-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.Reset();
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-6-2-50' THEN EXIT;

          InsertProdOrder(ProdOrder,2,0,'E_PROD',40,'WHITE');
          ProdOrder.VALIDATE("Due Date",301101D);
          ProdOrder.MODIFY(TRUE);
          WORKDATE := 301101D;

          IF LastIteration = '28-6-2-60' THEN EXIT;

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          IF LastIteration = '28-6-2-70' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Item No.",'A_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,52,52,'','LT01','');
            CreateRes.CreateEntry('A_TEST','12','WHITE','',0D,301101D,0,2);
          END;
          ProdOrderComp.SETRANGE("Item No.",'B_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,50,50,'','LN01','');
            CreateRes.CreateEntry('B_TEST','','WHITE','',0D,301101D,0,2);
          END;
          ProdOrderComp.SETRANGE("Item No.",'D_PROD');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,60,60,'','LS01','');
            CreateRes.CreateEntry('D_PROD','','WHITE','',0D,301101D,0,2);
          END;

          IF LastIteration = '28-6-2-80' THEN EXIT;

          ProdOrder.FIND('-');
          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,3,301101D,FALSE);

          IF LastIteration = '28-6-2-90' THEN EXIT;

        // 28-6-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '28-6-3-10' THEN EXIT;

        // 28-6-4

          ProdOrder.Reset();
          ProdOrder.FIND('-');
          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE(Status,ProdOrder.Status);
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          IF ProdOrderComp.FIND('-') THEN
            REPEAT
              ItemTrackingMgt.InitItemTrkgForTempWkshLine(
                WhseSourceType::Production,ProdOrderComp."Prod. Order No.",
                ProdOrderComp."Prod. Order Line No.",DATABASE::"Prod. Order Component",
                ProdOrderComp.Status,ProdOrderComp."Prod. Order No.",
                ProdOrderComp."Prod. Order Line No.",ProdOrderComp."Line No.");
            UNTIL ProdOrderComp.Next() = 0;
          Commit();

          CLEAR(CreatePickFromWhseSource);
          Commit();
          ProdOrder.Reset();
          ProdOrder.FIND('-');
          CreatePickFromWhseSource.SetProdOrder(ProdOrder);
          CreatePickFromWhseSource.SetHideValidationDialog(TRUE);
          CreatePickFromWhseSource.USEREQUESTPAGE(FALSE);
          CreatePickFromWhseSource.RunModal();

          IF LastIteration = '28-6-4-10' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FIND('-');
          WhseActivLine.SETRANGE("No.",WhseActivLine."No.");
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '28-6-4-20' THEN EXIT;

          ProdOrder.Reset();
          ProdOrder.FIND('-');
          InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',10000,301101D,
            ItemJnlLine."Entry Type"::Output,'ProdOrder."No."','E_PROD','','WHITE','',
            40,'PCS',0,0);
          ItemJnlLine.SetUpNewLine(ItemJnlLine);
          ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
          ItemJnlLine.VALIDATE("Order No.",ProdOrder."No.");
          ItemJnlLine.VALIDATE("Item No.");
          ItemJnlLine.Modify();

          IF LastIteration = '28-6-4-30' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          OutpExplRtng.RUN(ItemJnlLine);

          IF LastIteration = '28-6-4-40' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '28-6-4-50' THEN EXIT;

          ProdOrder.FIND('-');
          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,4,301101D,FALSE);

          IF LastIteration = '28-6-4-60' THEN EXIT;

        // 28-6-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '28-6-5-10' THEN EXIT;

        END;
    end;

    [Scope('OnPrem')]
    procedure GetLastILENo(): Integer
    begin
        LastILENo := TestScriptMgmt.GetLastItemLedgEntryNo;
    end;

    [Scope('OnPrem')]
    procedure GetNextNo(var LastNo: Integer): Integer
    begin
        EXIT(TestScriptMgmt.GetNextNo(LastNo));
    end;

    [Scope('OnPrem')]
    procedure SetFirstIteration(NewFirstUseCaseNo: Integer;NewFirstTestCaseNo: Integer;NewFirstIterationNo: Integer;NewFirstStepNo: Integer)
    begin
        UseCaseNo := NewFirstUseCaseNo;
        TestCaseNo := NewFirstTestCaseNo;
        FirstIteration := FORMAT(UseCaseNo) + '-' + FORMAT(TestCaseNo) + '-' +
          FORMAT(NewFirstIterationNo) + '-' + FORMAT(NewFirstStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetLastIteration(NewLastUseCaseNo: Integer;NewLastTestCaseNo: Integer;NewLastIterationNo: Integer;NewLastStepNo: Integer)
    begin
        LastIteration := FORMAT(NewLastUseCaseNo) + '-' + FORMAT(NewLastTestCaseNo) + '-' +
          FORMAT(NewLastIterationNo) + '-' + FORMAT(NewLastStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetNumbers(NewNoOfRecords: array [20] of Integer;NewNoOfFields: array [20] of Integer)
    begin
        COPYARRAY(NoOfRecords,NewNoOfRecords,1);
        COPYARRAY(NoOfFields,NewNoOfFields,1);
    end;

    [Scope('OnPrem')]
    procedure GetNumbers(var NewNoOfRecords: array [20] of Integer;var NewNoOfFields: array [20] of Integer)
    begin
        COPYARRAY(NewNoOfRecords,NoOfRecords,1);
        COPYARRAY(NewNoOfFields,NoOfFields,1);
    end;
}

