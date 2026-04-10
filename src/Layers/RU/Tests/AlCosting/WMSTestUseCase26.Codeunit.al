codeunit 103311 "WMS Test Use Case 26"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 26");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103311,26,0,'',1);

        TestscriptMgt.ShowTestscriptResult;
    end;

    var
        Item: Record Item;
        TestCase: Record Table103301;
        UseCase: Record Table103300;
        ResEntry: Record "Reservation Entry";
        SelectionForm: Page Page103317;
        TestScriptMgmt: Codeunit Codeunit103303;
        ShowAlsoPassTests: Boolean;
        TestUseCase: array [50] of Boolean;
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
        END;
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
        Zone: Record Zone;
        CalcQtyOnHand: Report "Calculate Inventory";
        ConvertLocationToWMS: Report "Create Warehouse Location";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoSalesShipmentLine: Codeunit "Undo Sales Shipment Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 26-1-1
          SetGlobalPreconditions;

          IF LastIteration = '26-1-1-10' THEN EXIT;

          Item.GET('80100');
          Item."Put-away Unit of Measure Code" := 'Box';
          Item.MODIFY(TRUE);
          IF LastIteration = '26-1-1-20' THEN EXIT;

        // 26-1-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS26-1-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','Blue',3,'PALLET',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','','Blue',10,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_TEST','','Blue',10,'PALLET',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'B_TEST','','Blue',11,'PALLET',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'C_TEST','31','Blue',100,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,60000,PurchLine.Type::Item,'A_TEST','11','Blue',10,'PALLET',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,70000,PurchLine.Type::Item,'A_TEST','12','Blue',10,'PALLET',100,FALSE);
          IF LastIteration = '26-1-2-10' THEN EXIT;

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);
          IF LastIteration = '26-1-2-20' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Blue',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',3,'PCS',33.77,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',4,'BOX',1,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'B_Test','',3,'PCS',100,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'C_Test','',7,'PCS',100,'Blue','');
          END;
          IF LastIteration = '26-1-2-30' THEN EXIT;

          SalesHeader.Receive := TRUE;
          PostSalesOrder(SalesHeader);
          IF LastIteration = '26-1-2-40' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Blue',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',3,'PCS',33.77,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',4,'Pack',1,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'B_Test','',5,'PCS',100,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'C_Test','',1,'Pallet',100,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,50000,Type::Item,'A_Test','',5,'Pallet',100,'Blue','');
          END;
          SalesLine.SETRANGE("Document Type",SalesLine."Document Type"::Order);
          SalesLine.FindFirst();
          SalesLine."Appl.-to Item Entry" := 3;
          SalesLine.MODIFY(TRUE);
          IF LastIteration = '26-1-2-50' THEN EXIT;

          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);
          IF LastIteration = '26-1-2-60' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS26-1-3',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T1','Blue',5,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'T_TEST','T2','Blue',10,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','Blue',10,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'C_TEST','','Blue',10,'PALLET',100,FALSE);
          IF LastIteration = '26-1-2-70' THEN EXIT;

          SNCode := 'SN00';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','Blue','',251101D,251101D,0,2);
          END;
          SNCode := 'SN10';
          FOR i := 1 TO 10 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','Blue','',251101D,251101D,0,2);
          END;
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,10,10,'','LOT01','');
            CreateRes.CreateEntry('80002','','Blue','',251101D,251101D,0,2);
          IF LastIteration = '26-1-2-80' THEN EXIT;

          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);
          IF LastIteration = '26-1-2-90' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS26-1-4',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T1','Blue',5,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'T_TEST','T2','Blue',10,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','Blue',20,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'C_TEST','32','Blue',100,'PCS',100,FALSE);
          IF LastIteration = '26-1-2-100' THEN EXIT;

          SNCode := 'SN05';
          FOR i := 1 TO 3 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','Blue','',251101D,251101D,0,2);
          END;
          SNCode := 'SN20';
          FOR i := 1 TO 7 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','Blue','',251101D,251101D,0,2);
          END;
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,20,20,'','LOT02','');
            CreateRes.CreateEntry('80002','','Blue','',251101D,251101D,0,2);
          IF LastIteration = '26-1-2-110' THEN EXIT;

          CLEAR(PurchHeader);
          PurchHeader.SETRANGE("No.",'106003');
          PurchHeader.FindFirst();
          ModifyPurchLine(PurchHeader,10000,3,0,0,0);
          ModifyPurchLine(PurchHeader,20000,7,0,0,0);
          ModifyPurchLine(PurchHeader,30000,13,0,0,0);
          ModifyPurchLine(PurchHeader,40000,40,0,0,0);

          ResEntry.SETRANGE("Lot No.",'LOT02');
          ResEntry.FindFirst();
          ResEntry.VALIDATE("Qty. to Handle (Base)",13);
          ResEntry.VALIDATE("Qty. to Invoice (Base)",0);
          ResEntry.MODIFY(TRUE);

          ResEntry.SETRANGE("Item No.",'T_TEST');
          IF ResEntry.FIND('-') THEN BEGIN
            REPEAT
              ResEntry.VALIDATE("Qty. to Invoice (Base)",0);
              ResEntry.MODIFY(TRUE);
            UNTIL ResEntry.Next() =0;
          END;
          IF LastIteration = '26-1-2-120' THEN EXIT;

          PostPurchOrder(PurchHeader);
          IF LastIteration = '26-1-2-130' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Blue',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T1',2,'BOX',96,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'T_Test','T2',2,'BOX',96,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'80002','',5,'PCS',100,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'C_Test','31',100,'PCS',100,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,50000,Type::Item,'B_Test','',100,'PCS',100,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,60000,Type::Item,'80100','',2,'PALLET',32,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,70000,Type::Item,'A_Test','12',70,'PCS',100,'Blue','');
          END;
          IF LastIteration = '26-1-2-140' THEN EXIT;

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'SN07','','');
          CreateRes.CreateEntry('T_TEST','T1','Blue','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN27','','');
          CreateRes.CreateEntry('T_TEST','T2','Blue','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,3,3,'','LOT02','');
          CreateRes.CreateEntry('80002','','Blue','',251101D,251101D,0,2);
          IF LastIteration = '26-1-2-150' THEN EXIT;

          CreateReservation
            ('C_Test','31','Blue','','',100,1,0,32,0,5,251101D,-100,1,37,1,'1002',40000);
          CreateReservation
            ('A_Test','12','Blue','','',70,13,0,32,0,7,251101D,-70,1,37,1,'1002',70000);
          IF LastIteration = '26-1-2-160' THEN EXIT;

          CLEAR(SalesHeader);
          SalesHeader.SETRANGE("No.",'1002');
          SalesHeader.FindFirst();
          ModifySalesLine(SalesHeader,10000,1,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,20000,1,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,30000,3,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,40000,0,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,50000,100,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,60000,1,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,70000,39,0,0,0,FALSE);

          IF TrackingSpecification.FIND('-') THEN BEGIN
            REPEAT
              TrackingSpecification.VALIDATE("Qty. to Invoice (Base)",0);
              TrackingSpecification.MODIFY(TRUE);
            UNTIL TrackingSpecification.Next() =0;
          END;
          IF LastIteration = '26-1-2-170' THEN EXIT;

          PostSalesOrder(SalesHeader);
          IF LastIteration = '26-1-2-180' THEN EXIT;

          InsertProdOrder(ProdOrder,3,0,'D_PROD',14,'Blue');
          ProdOrder.VALIDATE("Starting Date",251101D);
          ProdOrder.VALIDATE("Ending Date",251101D);
          ProdOrder.VALIDATE("Due Date",301101D);
          ProdOrder.MODIFY(TRUE);

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          IF LastIteration = '26-1-2-190' THEN EXIT;

          PostConsumption('CONSUMP','DEFAULT',10000,'Blue',251101D,ProdOrder."No.",'C_Test','32',7,10000);
          IF LastIteration = '26-1-2-200' THEN EXIT;

          PostOutput('OUTPUT','DEFAULT',10000,251101D,ProdOrder."No.",'D_Prod',10,'PCS');
          IF LastIteration = '26-1-2-210' THEN EXIT;

          InsertTransferHeader(TransHeader,'BLUE','RED','OWN LOG.',251101D);
          InsertTransferLine(TransLine,TransHeader."No.",10000,'80100','','BOX',10,0,10);
          PostTransferOrder(TransHeader);
          IF LastIteration = '26-1-2-220' THEN EXIT;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',10000,251101D,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS26-1-5','C_TEST','31','BLUE','',10,'PCS',100,0);
          ItemJnlPostBatch(ItemJnlLine);
          IF LastIteration = '26-1-2-230' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'60000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS26-1-6',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_TEST','11','Blue',15,'PCS',115,FALSE);

          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);
          IF LastIteration = '26-1-2-240' THEN EXIT;

          Commit();
          PurchRcptLine.SETRANGE("Document No.",'107004');
          PurchRcptLine.FindFirst();
          UndoPurchaseReceiptLine.SetHideDialog(TRUE);
          UndoPurchaseReceiptLine.RUN(PurchRcptLine);
          IF LastIteration = '26-1-2-250' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Blue',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'C_Test','32',13,'PCS',96,'Blue','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'A_Test','11',13,'PCS',96,'Blue','');
          END;
          ModifySalesLine(SalesHeader,10000,8,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,20000,13,0,0,0,FALSE);
          PostSalesOrder(SalesHeader);
          IF LastIteration = '26-1-2-260' THEN EXIT;

          SalesShipmentLine.SETRANGE("Document No.",'102003');
          SalesShipmentLine.SETRANGE("Line No.",10000,20000);
          IF SalesShipmentLine.FIND('-') THEN BEGIN
            UndoSalesShipmentLine.SetHideDialog(TRUE);
            REPEAT
              UndoSalesShipmentLine.RUN(SalesShipmentLine);
            UNTIL SalesShipmentLine.Next() =0;
          END;
          IF LastIteration = '26-1-2-270' THEN EXIT;

          Item.GET('A_TEST');
          Item.Blocked := TRUE;
          Item.MODIFY(TRUE);
          IF LastIteration = '26-1-2-280' THEN EXIT;

        // 26-1-3
          WITH Bin DO BEGIN
            Init();
            "Location Code" := 'BLUE';
            Code:= 'C1';
            IF NOT INSERT(TRUE) THEN
            MODIFY(TRUE);
          END;
          IF LastIteration = '26-1-3-10' THEN EXIT;

          Commit();
          CLEAR(ConvertLocationToWMS);
          ConvertLocationToWMS.SetHideValidationDialog(TRUE);
          ConvertLocationToWMS.InitializeRequest('Blue','C1');
          ConvertLocationToWMS.USEREQUESTPAGE(FALSE);
          ConvertLocationToWMS.RunModal();
          CLEAR(ConvertLocationToWMS);
          IF LastIteration = '26-1-3-20' THEN EXIT;

        // 26-1-4

          Item.GET('A_TEST');
          Item.Blocked := FALSE;
          Item.MODIFY(TRUE);
          IF LastIteration = '26-1-4-10' THEN EXIT;

          ItemJnlLine.DeleteAll();
          CLEAR(ItemJnlLine);
          ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
          ItemJnlLine."Journal Batch Name" := 'DEFAULT';
          CalcQtyOnHand.SetItemJnlLine(ItemJnlLine);
          Item.Reset();
          CalcQtyOnHand.SETTABLEVIEW(Item);
          CalcQtyOnHand.InitializeRequest(251101D,ItemJnlLine."Document No.",TRUE,FALSE);
          CalcQtyOnHand.USEREQUESTPAGE(FALSE);
          CalcQtyOnHand.RunModal();
          CLEAR(CalcQtyOnHand);
          IF LastIteration = '26-1-4-20' THEN EXIT;

        // 26-1-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '26-1-5-10' THEN EXIT;

        END;
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
        Zone: Record Zone;
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
        WITH TestScriptMgmt DO BEGIN
        // 26-2-1
          SetGlobalPreconditions;

          IF LastIteration = '26-2-1-10' THEN EXIT;

          Item.GET('80100');
          Item."Put-away Unit of Measure Code" := 'Box';
          Item.MODIFY(TRUE);
          IF LastIteration = '26-2-1-20' THEN EXIT;

        // 26-2-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','TCS26-2-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','Green',3,'PALLET',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','','Green',10,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_TEST','','Green',10,'PALLET',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'B_TEST','','Green',11,'PALLET',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'C_TEST','31','Green',100,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,60000,PurchLine.Type::Item,'A_TEST','11','Green',10,'PALLET',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,70000,PurchLine.Type::Item,'A_TEST','12','Green',10,'PALLET',100,FALSE);
          IF LastIteration = '26-2-2-10' THEN EXIT;

          ReleasePurchDocument(PurchHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'Green');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '26-2-2-20' THEN EXIT;

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '26-2-2-30' THEN EXIT;

          PurchHeader.FIND('-');
          PurchHeader.Invoice:=TRUE;
          PostPurchOrder(PurchHeader);
          IF LastIteration = '26-2-2-40' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Green',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',3,'PCS',33.77,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',4,'BOX',1,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'B_Test','',3,'PCS',100,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'C_Test','',7,'PCS',100,'Green','');
          END;
          IF LastIteration = '26-2-2-50' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'Green');
          CLEAR(WhseRcptLine);
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '26-2-2-60' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '26-2-2-70' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Green',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',3,'PCS',33.77,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',4,'Pack',1,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'B_Test','',5,'PCS',100,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'C_Test','',1,'Pallet',100,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,50000,Type::Item,'A_Test','',5,'Pallet',100,'Green','');
          END;
          SalesLine.SETRANGE("Document Type",SalesLine."Document Type"::Order);
          SalesLine.FindFirst();
          SalesLine."Appl.-to Item Entry" := 3;
          SalesLine.MODIFY(TRUE);
          IF LastIteration = '26-2-2-80' THEN EXIT;

          SalesHeader.SETRANGE("Document Type",SalesHeader."Document Type"::Order);
          SalesHeader.FindFirst();
          ReleaseSalesDocument(SalesHeader);
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'Green');
          WhseShptHeader.FindFirst();
          CreatePickFromWhseShipment(WhseShptHeader);
          IF LastIteration = '26-2-2-90' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          WhseShptLine.FindFirst();
          PostWhseShipment(WhseShptLine,TRUE);
          IF LastIteration = '26-2-2-100' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','TCS26-2-3',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T1','Green',5,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'T_TEST','T2','Green',10,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','Green',10,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'C_TEST','','Green',10,'PALLET',100,FALSE);
          IF LastIteration = '26-2-2-110' THEN EXIT;

          SNCode := 'SN00';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','Green','',251101D,251101D,0,2);
          END;
          SNCode := 'SN10';
          FOR i := 1 TO 10 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','Green','',251101D,251101D,0,2);
          END;
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,10,10,'','LOT01','');
            CreateRes.CreateEntry('80002','','Green','',251101D,251101D,0,2);
          IF LastIteration = '26-2-2-120' THEN EXIT;

          ReleasePurchDocument(PurchHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'Green');
          CLEAR(WhseRcptLine);
          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '26-2-2-130' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '26-2-2-140' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','TCS26-2-4',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T1','Green',5,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'T_TEST','T2','Green',10,'BOX',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','Green',20,'PCS',100,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'C_TEST','32','Green',100,'PCS',100,FALSE);
          IF LastIteration = '26-2-2-150' THEN EXIT;

          SNCode := 'SN05';
          FOR i := 1 TO 3 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','Green','',251101D,251101D,0,2);
          END;
          SNCode := 'SN20';
          FOR i := 1 TO 7 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','Green','',251101D,251101D,0,2);
          END;
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,20,20,'','LOT02','');
            CreateRes.CreateEntry('80002','','Green','',251101D,251101D,0,2);
          IF LastIteration = '26-2-2-160' THEN EXIT;

          ReleasePurchDocument(PurchHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'Green');
          CLEAR(WhseRcptLine);
          ModifyWhseRcptLine(WhseRcptLine,'Re000004',10000,'','',3);
          ModifyWhseRcptLine(WhseRcptLine,'Re000004',20000,'','',7);
          ModifyWhseRcptLine(WhseRcptLine,'Re000004',30000,'','',13);
          ModifyWhseRcptLine(WhseRcptLine,'Re000004',40000,'','',40);
          IF LastIteration = '26-2-2-170' THEN EXIT;

          CLEAR(WhseRcptLine);
          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          WhseRcptHeader.FindFirst();
          WhseRcptHeader.DeleteRelatedLines(FALSE);
          WhseRcptHeader.DELETE(FALSE);
          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '26-2-2-180' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Green',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T1',2,'BOX',96,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'T_Test','T2',2,'BOX',96,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'80002','',5,'PCS',100,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'C_Test','31',100,'PCS',100,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,50000,Type::Item,'B_Test','',100,'PCS',100,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,60000,Type::Item,'80100','',2,'PALLET',32,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,70000,Type::Item,'A_Test','12',70,'PCS',100,'Green','');
          END;
          IF LastIteration = '26-2-2-190' THEN EXIT;

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'SN07','','');
          CreateRes.CreateEntry('T_TEST','T1','Green','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,'SN27','','');
          CreateRes.CreateEntry('T_TEST','T2','Green','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,3,3,'','LOT02','');
          CreateRes.CreateEntry('80002','','Green','',251101D,251101D,0,2);
          IF LastIteration = '26-2-2-200' THEN EXIT;

          CreateReservation
            ('C_Test','31','Green','','',100,1,0,32,0,5,251101D,-100,1,37,1,'1002',40000);
          CreateReservation
            ('A_Test','12','Green','','',70,13,0,32,0,7,251101D,-70,1,37,1,'1002',70000);
          IF LastIteration = '26-2-2-210' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'Green');
          WhseShptHeader.FindFirst();
          CreatePickFromWhseShipment(WhseShptHeader);
          IF LastIteration = '26-2-2-220' THEN EXIT;

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN
            FIND('-');
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",40000,'','',0);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",60000,'','',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",70000,'','',39);
          END;
          IF LastIteration = '26-2-2-230' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          CLEAR(WhseShptLine);
          WhseShptLine.FindFirst();
          PostWhseShipment(WhseShptLine,TRUE);
          IF LastIteration = '26-2-2-240' THEN EXIT;

          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETEALL(TRUE);
          WhseShptHeader.FindFirst();
          WhseShptHeader.Status := WhseShptHeader.Status::Open;
          WhseShptHeader.MODIFY(TRUE);
          WhseShptHeader.DELETEALL(TRUE);
          IF LastIteration = '26-2-2-250' THEN EXIT;

          InsertProdOrder(ProdOrder,3,0,'D_PROD',14,'Green');
          ProdOrder.VALIDATE("Starting Date",251101D);
          ProdOrder.VALIDATE("Ending Date",251101D);
          ProdOrder.VALIDATE("Due Date",301101D);
          ProdOrder.MODIFY(TRUE);

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          IF LastIteration = '26-2-2-260' THEN EXIT;

          WhseSrcCreateDoc.SetProdOrder(ProdOrder);
          WhseSrcCreateDoc.SetHideValidationDialog(TRUE);
          WhseSrcCreateDoc.USEREQUESTPAGE(FALSE);
          WhseSrcCreateDoc.RunModal();

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Source Type",DATABASE::"Prod. Order Component");
          WhseActivLine.SETRANGE("Source Subtype",ProdOrder.Status);
          WhseActivLine.SETRANGE("Source No.",ProdOrder."No.");
          WhseActivLine.FindFirst();
          WhseActivRegister.RUN(WhseActivLine);

          PostConsumption('CONSUMP','DEFAULT',10000,'Green',251101D,ProdOrder."No.",'C_Test','32',7,10000);
          IF LastIteration = '26-2-2-270' THEN EXIT;

          PostOutput('OUTPUT','DEFAULT',10000,251101D,ProdOrder."No.",'D_Prod',10,'PCS');
          IF LastIteration = '26-2-2-280' THEN EXIT;

          InsertTransferHeader(TransHeader,'Green','RED','OWN LOG.',251101D);
          InsertTransferLine(TransLine,TransHeader."No.",10000,'80100','','BOX',10,0,10);
          ReleaseTransferOrder(TransHeader);
          CreateWhseShptFromTrans(TransHeader,WhseShptHeader);
          WhseShptHeader.FindFirst();
          CreatePickFromWhseShipment(WhseShptHeader);
          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          CLEAR(WhseShptLine);
          WhseShptLine.FindFirst();
          PostWhseShipment(WhseShptLine,FALSE);
          IF LastIteration = '26-2-2-290' THEN EXIT;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',10000,251101D,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS26-2-5','C_TEST','31','Green','',10,'PCS',100,0);
          ItemJnlPostBatch(ItemJnlLine);
          IF LastIteration = '26-2-2-300' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'60000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','TCS26-2-6',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_TEST','11','Green',15,'PCS',115,FALSE);
          ReleasePurchDocument(PurchHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'GREEN');
          CLEAR(WhseRcptLine);
          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          WhseActivHeader.FindFirst();
          WhseActivHeader.DELETEALL(TRUE);
          IF LastIteration = '26-2-2-310' THEN EXIT;

          Commit();
          PurchRcptLine.SETRANGE("Document No.",'107004');
          PurchRcptLine.FindFirst();
          UndoPurchaseReceiptLine.SetHideDialog(TRUE);
          UndoPurchaseReceiptLine.RUN(PurchRcptLine);
          IF LastIteration = '26-2-2-320' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Green',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',3,'PCS',33.77,'Green','');
          END;
          ReleaseSalesDocument(SalesHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'Green');
          CLEAR(WhseRcptLine);
          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETEALL(TRUE);
          IF LastIteration = '26-2-2-330' THEN EXIT;

          ReturnRcptLine.SETRANGE("Document No.",'107002');
          ReturnRcptLine.FindFirst();
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);
          IF LastIteration = '26-2-2-340' THEN EXIT;

          Item.GET('A_TEST');
          Item.Blocked := TRUE;
          Item.MODIFY(TRUE);
          IF LastIteration = '26-2-2-350' THEN EXIT;

        // 26-2-3
          WITH Bin DO BEGIN
            Init();
            "Location Code" := 'Green';
            Code:= 'C1';
            IF NOT INSERT(TRUE) THEN
            MODIFY(TRUE);
          END;
          IF LastIteration = '26-2-3-10' THEN EXIT;

          Commit();
          CLEAR(ConvertLocationToWMS);
          ConvertLocationToWMS.SetHideValidationDialog(TRUE);
          ConvertLocationToWMS.InitializeRequest('Green','C1');
          ConvertLocationToWMS.USEREQUESTPAGE(FALSE);
          ConvertLocationToWMS.RunModal();
          CLEAR(ConvertLocationToWMS);
          IF LastIteration = '26-2-3-20' THEN EXIT;

        // 26-2-4

          Item.GET('A_TEST');
          Item.Blocked := FALSE;
          Item.MODIFY(TRUE);
          IF LastIteration = '26-2-4-10' THEN EXIT;

          ItemJnlLine.DeleteAll();
          CLEAR(ItemJnlLine);
          ItemJnlLine."Journal Template Name" := 'PHYS. INV.';
          ItemJnlLine."Journal Batch Name" := 'DEFAULT';
          CalcQtyOnHand.SetItemJnlLine(ItemJnlLine);
          Item.Reset();
          CalcQtyOnHand.SETTABLEVIEW(Item);
          CalcQtyOnHand.InitializeRequest(251101D,ItemJnlLine."Document No.",TRUE,FALSE);
          CalcQtyOnHand.USEREQUESTPAGE(FALSE);
          CalcQtyOnHand.RunModal();
          CLEAR(CalcQtyOnHand);
          IF LastIteration = '26-2-4-20' THEN EXIT;

        // 26-2-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '26-2-5-10' THEN EXIT;

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

