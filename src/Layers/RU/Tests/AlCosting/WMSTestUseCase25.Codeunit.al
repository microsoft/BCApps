codeunit 103334 "WMS Test Use Case 25"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 25");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103334,25,0,'',1);

        TestscriptMgt.ShowTestscriptResult;
    end;

    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        TestCase: Record Table103301;
        TestScriptResult: Record Table103303;
        UseCase: Record Table103300;
        ResEntry: Record "Reservation Entry";
        WhseWkshLine: Record "Whse. Worksheet Line";
        SelectionForm: Page Page103317;
        GlobalPrecondition: Codeunit Codeunit103301;
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
          3: PerformTestCase3;
          4: PerformTestCase4;
          5: PerformTestCase5;
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
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssignPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssignSales: Record "Item Charge Assignment (Sales)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnRcptLine: Record "Return Receipt Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
    begin
        WITH TestScriptMgmt DO BEGIN
        // 25-1-1
          SetGlobalPreconditions;

          IF LastIteration = '25-1-1-10' THEN EXIT;

          Location.GET('White');
          Location."Use Put-away Worksheet" := TRUE;
          Location.MODIFY(TRUE);

          IF LastIteration = '25-1-1-20' THEN EXIT;

        // 25-1-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS25-1-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','WHITE',3,'PALLET',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::"Charge (Item)",'UPS','','WHITE',1,'',100,FALSE);
          IF LastIteration = '25-1-2-10' THEN EXIT;

          WITH ItemChargeAssignPurch DO BEGIN
            Init();
            "Document Type" := "Document Type"::Order;
            "Document No." := '106001';
            "Document Line No." := 20000;
            "Line No." := 10000;
            "Item Charge No.":= 'UPS';
            "Item No." := '80100';
            "Qty. to Assign" := 1;
            "Unit Cost" := 100;
            "Amount to Assign" := 100;
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Order;
            "Applies-to Doc. No." := '106001';
            "Applies-to Doc. Line No." := 10000;
            INSERT(TRUE);
          END;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '25-1-2-20' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '25-1-2-30' THEN EXIT;

          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",10000,'Receive','W-08-0001',2);

          IF LastIteration = '25-1-2-40' THEN EXIT;

          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '25-1-2-50' THEN EXIT;

        // 25-1-3
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',3,'PCS',33.77,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::"Charge (Item)",'UPS','',1,'PCS',100,'WHITE','');
          END;

          IF LastIteration = '25-1-3-10' THEN EXIT;

          WITH ItemChargeAssignSales DO BEGIN
            Init();
            "Document Type" := "Document Type"::"Return Order";
            "Document No." := '1001';
            "Document Line No." := 20000;
            "Line No." := 10000;
            "Item Charge No.":= 'UPS';
            "Item No." := 'A_TEST';
            "Qty. to Assign" := 1;
            "Unit Cost" := 100;
            "Amount to Assign" := 100;
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::"Return Order";
            "Applies-to Doc. No." := '1001';
            "Applies-to Doc. Line No." := 10000;
            INSERT(TRUE);
          END;
          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '25-1-3-20' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'WHITE');

          IF LastIteration = '25-1-3-30' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000002');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000002',10000,'Receive','W-08-0001',1);

          IF LastIteration = '25-1-3-40' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '25-1-3-50' THEN EXIT;

        // 25-1-4
          PurchRcptLine.SETRANGE("Line No.",10000);
          PurchRcptLine.FIND('-');
          UndoPurchaseReceiptLine.SetHideDialog(TRUE);
          UndoPurchaseReceiptLine.RUN(PurchRcptLine);
          IF LastIteration = '25-1-4-10' THEN EXIT;

        // 25-1-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '25-1-5-10' THEN EXIT;

        // 25-1-6
          ReturnRcptLine.SETRANGE("Line No.",10000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          IF LastIteration = '25-1-6-10' THEN EXIT;

        // 25-1-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '25-1-7-10' THEN EXIT;
        END;
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
        WITH TestScriptMgmt DO BEGIN
        // 25-2-1
          SetGlobalPreconditions;

          IF LastIteration = '25-2-1-10' THEN EXIT;

          Item.GET('80100');
          Item."Put-away Unit of Measure Code" := 'Box';
          Item.MODIFY(TRUE);
          IF LastIteration = '25-2-1-20' THEN EXIT;

        // 25-2-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS25-2-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','WHITE',4,'PALLET',96,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','WHITE',3,'Box',3,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80100','','WHITE',4,'PALLET',96,FALSE);

          ReleasePurchDocument(PurchHeader);
          IF LastIteration = '25-2-2-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '25-2-2-20' THEN EXIT;

          WITH WhseActivLine DO BEGIN
            SETRANGE("Activity Type","Activity Type"::"Put-away");
            FIND('-');
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",30000,'Receive','W-08-0001',2);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",40000,'Pick','W-01-0002',2);
          END;
          WhseActivLine.SETRANGE("Line No.",30000,40000);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '25-2-2-30' THEN EXIT;

          CLEAR(PurchHeader);
          PurchHeader.SETRANGE("No.",'106001');
          PurchHeader.FIND('-');
          ReleasePurchDoc.Reopen(PurchHeader);
          ModifyPurchLine(PurchHeader,10000,0,1,0,0);
          ModifyPurchLine(PurchHeader,20000,0,0,0,0);
          ModifyPurchLine(PurchHeader,30000,0,0,0,0);
          PostPurchOrder(PurchHeader);
          IF LastIteration = '25-2-2-40' THEN EXIT;

          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETE(TRUE);
          IF LastIteration = '25-2-2-50' THEN EXIT;

        // 25-2-3
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T1',2,'BOX',11.99,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'T_Test','T2',2,'Box',12.88,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'80100','',5,'PALLET',96,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'C_Test','31',4,'PCS',5.78,'','');
          END;

          SNCode := 'SN00';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','WHITE','',251101D,251101D,0,2);
          END;

          SNCode := 'SN02';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
          END;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '25-2-3-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'WHITE');

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'Green');

          IF LastIteration = '25-2-3-20' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000002');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000002',20000,'Receive','W-08-0001',1);
          ResEntry.SETRANGE("Serial No.",'SN04');
          ResEntry.FIND('-');
          ResEntry."Qty. to Handle (Base)" :=0;
          ResEntry."Qty. to Invoice (Base)" :=0;
          ResEntry.MODIFY(TRUE);

          WhseRcptHeader.SETRANGE("No.",'RE000003');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000003',10000,'','',3);

          IF LastIteration = '25-2-3-30' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WhseRcptLine.SETRANGE("No.",'RE000003');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '25-2-3-40' THEN EXIT;

          CLEAR(SalesHeader);
          SalesHeader.SETRANGE("No.",'1001');
          SalesHeader.FIND('-');
          ReleaseSalesDoc.Reopen(SalesHeader);
          ModifySalesLine(SalesHeader,10000,0,2,0,0,FALSE);
          ModifySalesLine(SalesHeader,20000,0,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,30000,0,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,40000,0,0,0,0,FALSE);

          TrackingSpecification.SETRANGE("Serial No.",'SN03');
          TrackingSpecification.FIND('-');
          TrackingSpecification.VALIDATE("Qty. to Invoice (Base)",0);
          TrackingSpecification.MODIFY(TRUE);

          SalesHeader.Receive := TRUE;
          PostSalesOrder(SalesHeader);
          IF LastIteration = '25-2-3-50' THEN EXIT;

          IF WhseActivHeader.FIND('-') THEN
            REPEAT
              WhseActivHeader.DELETE(TRUE);
            UNTIL WhseActivHeader.Next() =0;
          IF LastIteration = '25-2-3-60' THEN EXIT;

        // 25-2-4
          PurchRcptLine.SETRANGE("Line No.",30000);
          PurchRcptLine.FIND('-');
          UndoPurchaseReceiptLine.SetHideDialog(TRUE);
          UndoPurchaseReceiptLine.RUN(PurchRcptLine);
          IF LastIteration = '25-2-4-10' THEN EXIT;

        // 25-2-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '25-2-5-10' THEN EXIT;

        // 25-2-6
          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Document No.",'107001');
          ReturnRcptLine.SETRANGE("Line No.",20000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Document No.",'107002');
          ReturnRcptLine.SETRANGE("Line No.",30000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Document No.",'107003');
          ReturnRcptLine.SETRANGE("Line No.",40000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          IF LastIteration = '25-2-6-10' THEN EXIT;

        // 25-2-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '25-2-7-10' THEN EXIT;
        END;
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
        WITH TestScriptMgmt DO BEGIN
        // 25-3-1

          SetGlobalPreconditions;

          IF LastIteration = '25-3-1-10' THEN EXIT;

        // 25-3-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS25-3-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T1','WHITE',2,'Box',6.25,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'T_TEST','T2','WHITE',2,'Box',6.75,FALSE);

          SNCode := 'SN00';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','WHITE','',251101D,251101D,0,2);
          END;
          SNCode := 'SN02';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
          END;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '25-3-2-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '25-3-2-20' THEN EXIT;

          PurchHeader.FIND('-');
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '25-3-2-30' THEN EXIT;

          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETE(TRUE);

          IF LastIteration = '25-3-2-40' THEN EXIT;

        // 25-3-3
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'20000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS25-3-3',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80216-T','','WHITE',3,'PCS',0.5,FALSE);

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,3,3,'','LOT01','');
          CreateRes.CreateEntry('80216-T','','WHITE','',251101D,251101D,0,2);

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '25-3-3-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
          WhseRcptLine.SETRANGE("No.",'RE000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '25-3-3-20' THEN EXIT;

          WITH WhseActivLine DO BEGIN
            SETRANGE("Activity Type","Activity Type"::"Put-away");
            FIND('-');
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",10000,'Receive','W-08-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",20000,'Pick','W-01-0002',1);
          END;
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '25-3-3-30' THEN EXIT;

          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETE(TRUE);

          IF LastIteration = '25-3-3-40' THEN EXIT;

        // 25-3-4
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T2',2,'BOX',11.99,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80216-T','',2,'PCS',0.5,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'T_Test','',2,'Box',12.88,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'80216-T','',2,'PCS',0.5,'WHITE','');
          END;

          SNCode := 'SN06';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
          END;
          SNCode := 'SN08';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,30000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','','WHITE','',251101D,251101D,0,2);
          END;

            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,2,2,'','LOT01','');
            CreateRes.CreateEntry('80216-T','','WHITE','',251101D,251101D,0,2);

            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,40000,1,2,2,'','LOT02','');
            CreateRes.CreateEntry('80216-T','','WHITE','',251101D,251101D,0,2);

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '25-3-4-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'WHITE');
          CLEAR(WhseRcptLine);
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '25-3-4-20' THEN EXIT;

          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETE(TRUE);

          IF LastIteration = '25-3-4-30' THEN EXIT;

        // 25-3-5
          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Line No.",10000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Line No.",20000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Line No.",30000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Line No.",40000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);

          IF LastIteration = '25-3-5-10' THEN EXIT;

        // 25-3-6
          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '25-3-6-10' THEN EXIT;
        END;
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
        WhseActivLine: Record "Warehouse Activity Line";
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
        WITH TestScriptMgmt DO BEGIN
        // 25-4-1

          SetGlobalPreconditions;

          IF LastIteration = '25-4-1-10' THEN EXIT;

          Location.GET('White');
          Location."Use Put-away Worksheet" := TRUE;
          Location.MODIFY(TRUE);

          IF LastIteration = '25-4-1-20' THEN EXIT;
        // 25-4-2
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T2',2,'BOX',65.43,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'D_PROD','',3,'PCS',321.09,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'80216-T','',4,'PCS',0.8,'WHITE','');
           END;
          IF LastIteration = '25-4-2-10' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);

          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'WHITE');
          IF LastIteration = '25-4-2-20' THEN EXIT;

        // 25-4-3
          InsertProdOrder(ProdOrder,2,0,'D_PROD',4,'WHITE');
          ProdOrder.VALIDATE("Starting Date",251101D);
          ProdOrder.VALIDATE("Ending Date",251101D);
          ProdOrder.VALIDATE("Due Date",251101D);
          ProdOrder.MODIFY(TRUE);

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          IF LastIteration = '22-4-3-10' THEN EXIT;

        // 25-4-4
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'White','TCS25-4-4',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'C_TEST','32','White',3,'PCS',33.77,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','','WHITE',2,'PCS',12.27,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80216-T','','WHITE',3,'PCS',0.5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'T_TEST','T2','WHITE',2,'Box',65.43,FALSE);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'','LOT01','');
            CreateRes.CreateEntry('80216-t','','WHITE','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,2,2,'','LOT02','');
            CreateRes.CreateEntry('80216-t','','WHITE','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,1,1,'SN02','','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '25-4-4-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
          IF LastIteration = '25-4-4-20' THEN EXIT;

          CrossDockMgt.CalculateCrossDockLines(CrossDockOpp,'','RE000001','WHITE');

          CrossDockOpp.SETRANGE("Source Name/No.",'RE000001');
          CrossDockOpp.SETRANGE("Source Line No.",30000);
          CrossDockOpp.SETRANGE("Line No.",10000);
          CrossDockOpp.FIND('-');
          CrossDockOpp."Qty. to Cross-Dock" :=3;
          CrossDockOpp.MODIFY(TRUE);

          CrossDockOpp.SETRANGE("Source Name/No.",'RE000001');
          CrossDockOpp.SETRANGE("Source Line No.",40000);
          CrossDockOpp.SETRANGE("Line No.",20000);
          CrossDockOpp.FIND('-');
          CrossDockOpp."Qty. to Cross-Dock" :=2;
          CrossDockOpp.MODIFY(TRUE);
          IF LastIteration = '25-4-4-30' THEN EXIT;

          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '25-4-4-40' THEN EXIT;

        // 25-4-5
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'C_Test','32',3,'PCS',33.77,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'T_Test','T2',2,'Box',65.43,'WHITE','');
          END;

          SNCode := 'SN02';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
          END;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '25-4-5-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'WHITE');
          IF LastIteration = '25-4-5-20' THEN EXIT;

          CrossDockMgt.CalculateCrossDockLines(CrossDockOpp,'','RE000002','WHITE');
          CrossDockOpp.SETRANGE("Source Name/No.",'RE000002');
          CrossDockOpp.SETRANGE("Source Line No.",20000);
          CrossDockOpp.SETRANGE("Line No.",30000);
          CrossDockOpp.FIND('-');
          CrossDockOpp."Qty. to Cross-Dock" :=1;
          CrossDockOpp.MODIFY(TRUE);

          IF LastIteration = '25-4-5-30' THEN EXIT;

          CLEAR(WhseRcptLine);
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '25-4-5-40' THEN EXIT;

        // 25-4-6
           CLEAR(UndoPurchaseReceiptLine);
           PurchRcptLine.SETRANGE("Line No.",10000);
           PurchRcptLine.FIND('-');
           UndoPurchaseReceiptLine.SetHideDialog(TRUE);
           UndoPurchaseReceiptLine.RUN(PurchRcptLine);

           CLEAR(UndoPurchaseReceiptLine);
           PurchRcptLine.SETRANGE("Line No.",20000);
           PurchRcptLine.FIND('-');
           UndoPurchaseReceiptLine.SetHideDialog(TRUE);
           UndoPurchaseReceiptLine.RUN(PurchRcptLine);

           CLEAR(UndoPurchaseReceiptLine);
           PurchRcptLine.SETRANGE("Line No.",30000);
           PurchRcptLine.FIND('-');
           UndoPurchaseReceiptLine.SetHideDialog(TRUE);
           UndoPurchaseReceiptLine.RUN(PurchRcptLine);

           CLEAR(UndoPurchaseReceiptLine);
           PurchRcptLine.SETRANGE("Line No.",40000);
           PurchRcptLine.FIND('-');
           UndoPurchaseReceiptLine.SetHideDialog(TRUE);
           UndoPurchaseReceiptLine.RUN(PurchRcptLine);

          IF LastIteration = '25-4-6-10' THEN EXIT;

        // 25-4-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '25-4-7-10' THEN EXIT;

        // 25-4-8
           CLEAR(UndoReturnReceiptLine);
           ReturnRcptLine.SETRANGE("Line No.",10000);
           ReturnRcptLine.FIND('-');
           UndoReturnReceiptLine.SetHideDialog(TRUE);
           UndoReturnReceiptLine.RUN(ReturnRcptLine);

           CLEAR(UndoReturnReceiptLine);
           ReturnRcptLine.SETRANGE("Line No.",20000);
           ReturnRcptLine.FIND('-');
           UndoReturnReceiptLine.SetHideDialog(TRUE);
           UndoReturnReceiptLine.RUN(ReturnRcptLine);

          IF LastIteration = '25-4-6-10' THEN EXIT;

        // 25-4-9
          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo);

          IF LastIteration = '25-4-9-10' THEN EXIT;
        END;
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
        WITH TestScriptMgmt DO BEGIN
        // 25-5-1
          SetGlobalPreconditions;

          IF LastIteration = '25-5-1-10' THEN EXIT;

        // 25-5-2
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',100,'PCS',17,'WHITE','');
          END;

          ReleaseSalesDocument(SalesHeader);
          IF LastIteration = '25-5-2-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'WHITE');
          IF LastIteration = '25-5-2-20' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000001');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000001',10000,'Receive','W-08-0001',20);
          IF LastIteration = '25-5-2-30' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000001');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '25-5-2-40' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000001');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000001',10000,'Receive','W-08-0001',10);
          IF LastIteration = '25-5-2-50' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000001');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '25-5-2-60' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000001');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000001',10000,'Receive','W-08-0001',25);
          IF LastIteration = '25-5-2-70' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000001');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          WhseActivHeader.FIND('+');
          WhseActivHeader.DELETE(TRUE);
          IF LastIteration = '25-5-2-80' THEN EXIT;

          CreatePutAwayWorksheet(WhseWkshLine,'PUT-AWAY','DEFAULT','WHITE',0,'R_000003');
          IF LastIteration = '25-5-2-90' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000001');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000001',10000,'Receive','W-08-0001',31);
          IF LastIteration = '25-5-2-100' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000001');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          WhseActivHeader.FIND('+');
          WhseActivHeader.DELETE(TRUE);
          IF LastIteration = '25-5-2-110' THEN EXIT;

        // 25-5-3
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS25-5-3',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'B_TEST','','WHITE',100,'PCS',15,FALSE);

          ReleasePurchDocument(PurchHeader);
          IF LastIteration = '25-5-3-10' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
          IF LastIteration = '25-5-3-20' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000002');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000002',10000,'Receive','W-08-0001',20);
          IF LastIteration = '25-5-3-30' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          WhseActivLine.SETRANGE("Source No.",'106001');
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '25-5-3-40' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000002');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000002',10000,'Receive','W-08-0001',10);
          IF LastIteration = '25-5-3-50' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '25-5-3-60' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000002');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000002',10000,'Receive','W-08-0001',25);
          IF LastIteration = '25-5-3-70' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          WhseActivHeader.FIND('+');
          WhseActivHeader.DELETE(TRUE);
          IF LastIteration = '25-5-3-80' THEN EXIT;

          CreatePutAwayWorksheet(WhseWkshLine,'PUT-AWAY','DEFAULT','WHITE',0,'R_000007');
          IF LastIteration = '25-5-3-90' THEN EXIT;

          WhseRcptHeader.SETRANGE("No.",'RE000002');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,'RE000002',10000,'Receive','W-08-0001',31);
          IF LastIteration = '25-5-3-100' THEN EXIT;

          WhseRcptLine.SETRANGE("No.",'RE000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);
          WhseActivHeader.FIND('+');
          WhseActivHeader.DELETE(TRUE);
          IF LastIteration = '25-5-3-110' THEN EXIT;

        // 25-5-4
          CLEAR(UndoPurchaseReceiptLine);
          PurchRcptLine.SETRANGE("Document No.",'107004');
          PurchRcptLine.SETRANGE("Line No.",10000);
          PurchRcptLine.FIND('-');
          UndoPurchaseReceiptLine.SetHideDialog(TRUE);
          UndoPurchaseReceiptLine.RUN(PurchRcptLine);
          IF LastIteration = '25-5-4-10' THEN EXIT;

        // 25-5-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '25-5-5-10' THEN EXIT;

        // 25-5-6
          CLEAR(UndoReturnReceiptLine);
          ReturnRcptLine.SETRANGE("Document No.",'107004');
          ReturnRcptLine.SETRANGE("Line No.",10000);
          ReturnRcptLine.FIND('-');
          UndoReturnReceiptLine.SetHideDialog(TRUE);
          UndoReturnReceiptLine.RUN(ReturnRcptLine);
          IF LastIteration = '25-5-6-10' THEN EXIT;
        // 25-5-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '25-5-7-10' THEN EXIT;
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

