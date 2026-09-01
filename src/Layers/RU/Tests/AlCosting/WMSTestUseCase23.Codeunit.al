codeunit 103333 "WMS Test Use Case 23"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 23");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103333,23,0,'',1);

        TestscriptMgt.ShowTestscriptResult;
    end;

    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
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
          5: PerformTestCase5;
          6: PerformTestCase6;
          7: PerformTestCase7;
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
        WhseActivLine: Record "Warehouse Activity Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 23-1-1

          SetGlobalPreconditions;

          IF LastIteration = '23-1-1-10' THEN EXIT;

          Location.SETRANGE(Code,'WHITE');
          Location.FIND('-');
          Location."Always Create Pick Line" := TRUE;
          Location.MODIFY(TRUE);

          IF LastIteration = '23-1-1-20' THEN EXIT;

          InsertDedicatedBin('WHITE','PICK','W-01-0001','A_TEST','','PCS',10,100);
          InsertDedicatedBin('WHITE','PICK','W-01-0002','B_TEST','','PCS',10,100);
          InsertDedicatedBin('WHITE','PICK','W-01-0003','T_TEST','T2','BOX',10,100);

          IF LastIteration = '23-1-1-30' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS23-1-1',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T2','WHITE',10,'BOX',1.23,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_TEST','','WHITE',7,'PCS',5.67,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'B_TEST','','WHITE',5,'PCS',5.67,FALSE);

          SNCode := 'SN00';
          FOR i := 1 TO 10 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
          END;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '23-1-1-40' THEN EXIT;

        // 23-1-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T2',3,'BOX',44.11,'WHITE','');
          END;

          IF LastIteration = '23-1-2-10' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'B_Test','',3,'PCS',12.22,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'T_Test','T2',4,'BOX',44.11,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'A_Test','',4,'PCS',9.75,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::"Charge (Item)",'UPS','',1,'',50,'WHITE','');
          END;

          IF LastIteration = '23-1-2-20' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS23-1-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'B_TEST','','WHITE',1,'Pcs',12.22,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'B_TEST','','WHITE',1,'PCS',12.22,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'T_TEST','T2','WHITE',5,'BOX',44.11,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'B_TEST','','WHITE',2,'PCS',12.22,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'A_TEST','','WHITE',4,'PCS',9.75,FALSE);

          IF LastIteration = '23-1-2-30' THEN EXIT;
        END;
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
        WhseJnlLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        PutAwayWkshLine: Record "Whse. Worksheet Line";
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 23-2-1

          SetGlobalPreconditions;

          IF LastIteration = '23-2-1-10' THEN EXIT;

          Location.SETRANGE(Code,'WHITE');
          Location.FIND('-');
          Location."Allow Breakbulk" := FALSE;
          Location.MODIFY(TRUE);

          IF LastIteration = '23-2-1-20' THEN EXIT;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',10000,251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS23-2-1','A_TEST','','WHITE','',1,'PCS',10,0);
          ItemJnlPostBatch(ItemJnlLine);

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS23-2-1',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','WHITE',10,'Pack',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','WHITE',13,'Box',5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80100','','WHITE',10,'Pallet',10,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'80216-T','','WHITE',4,'PCS',10,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'T_TEST','T1','WHITE',4,'BOX',1.23,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,60000,PurchLine.Type::Item,'A_TEST','','WHITE',23,'PCS',5.67,FALSE);

          SNCode := 'SN00';
          FOR i := 1 TO 3 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,50000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','WHITE','',251101D,251101D,0,2);
          END;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,50000,1,1,1,'SN-09-0001','','');
          CreateRes.CreateEntry('T_TEST','T1','WHITE','',251101D,251101D,0,2);

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,4,4,'','LOT01','');
          CreateRes.CreateEntry('80216-T','','WHITE','',251101D,251101D,0,2);

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WITH WhseActivLine DO BEGIN
            SETRANGE("Activity Type","Activity Type"::"Put-away");
            FIND('-');
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",20000,'Pick','W-01-0002',10);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",40000,'PICK','W-01-0001',13);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",60000,'Pick','W-01-0003',10);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",80000,'Pick','W-01-0001',4);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",100000,'PICK','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",120000,'Pick','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",140000,'Pick','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",160000,'Ship','W-09-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",170000,'Receive','W-08-0001',22);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",180000,'Pick','W-02-0001',10);
            SplitLine(WhseActivLine);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",190000,'Pick','W-02-0002',1);
            SplitLine(WhseActivLine);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",200000,'Cross-Dock','W-14-0002',10);
            SplitLine(WhseActivLine);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",210000,'QC','W-10-0001',1);
          END;

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETE(TRUE);

          IF LastIteration = '23-2-1-30' THEN EXIT;

          Bin.SETRANGE("Location Code",'WHITE');
          Bin.SETRANGE(Code,'W-02-0002');
          Bin.FIND('-');
          Bin."Block Movement":=Bin."Block Movement"::All;
          Bin.MODIFY(TRUE);
          BinContent.Reset();
          BinContent.SETRANGE("Location Code",Bin."Location Code");
          BinContent.SETRANGE("Bin Code",Bin.Code);
          BinContent.MODIFYALL("Block Movement",Bin."Block Movement"::All);

          IF LastIteration = '23-2-1-40' THEN EXIT;

        // 23-2-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_Test','',3,'PCS',4.55,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',3,'BOX',5.7,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'T_Test','T1',3,'BOX',15.7,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'80216-T','',3,'PCS',0.8,'WHITE','');
           END;

          IF LastIteration = '23-2-2-10' THEN EXIT;

        // 23-2-3

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS23-2-4',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T1','WHITE',1,'Box',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80216-T','','WHITE',1,'PCS',0.5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_TEST','','WHITE',1,'PCs',0.73,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'80100','','WHITE',1,'Box',3.0,FALSE);

          IF LastIteration = '23-2-3-10' THEN EXIT;

          SNCode := 'SN04';
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','WHITE','',251101D,251101D,0,2);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'','LOT02','');
            CreateRes.CreateEntry('80216-T','','WHITE','',251101D,251101D,0,2);

          IF LastIteration = '23-2-3-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '23-2-3-30' THEN EXIT;

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          WhseRcptLine.SETRANGE(WhseRcptLine."No.",'Re000002');
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '23-2-3-40' THEN EXIT;

          WhseActivHeader.SETRANGE(Type,WhseActivHeader.Type::"Put-away");
          WhseActivHeader.SETRANGE("No.",'PU000002');
          WhseActivHeader.FIND('-');
          WhseActivHeader.DELETE(TRUE);

          CreatePutAwayWorksheet(PutAwayWkshLine,'Put-away','Default','WHITE',0,'R_000002');

          IF LastIteration = '23-2-3-50' THEN EXIT;

        // 23-2-4

          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',10000,251101D,
            '80100','','W-01-0001','W-01-0002',2,'Box');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',20000,251101D,
           '80100','','W-01-0001','W-05-0001',1,'Box');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',30000,251101D,
           'T_TEST','T1','W-01-0001','W-01-0002',1,'Box');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',40000,251101D,
           'T_TEST','T1','W-01-0001','W-07-0001',2,'Box');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',50000,251101D,
           '80216-T','','W-01-0001','W-01-0002',2,'PCS');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',60000,251101D,
           '80216-T','','W-01-0001','W-07-0002',1,'PCS');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',70000,251101D,
           'A_TEST','','W-02-0001','W-01-0002',2,'PCS');
          InsertMovWkshLine(WhseWkshLine,'MOVEMENT','DEFAULT','WHITE',80000,251101D,
           'A_TEST','','W-02-0001','W-07-0003',1,'PCS');

          WhseWkshLine.Reset();
          WhseWkshLine.SETRANGE(WhseWkshLine."Line No.",10000);
          WhseWkshLine.FIND('-');
          WhseWkshLine.VALIDATE("Qty. to Handle",1);
          WhseWkshLine.MODIFY(TRUE);

          WhseWkshLine.Reset();
          WhseWkshLine.SETRANGE(WhseWkshLine."Line No.",40000);
          WhseWkshLine.FIND('-');
          WhseWkshLine."Qty. to Handle" := 1;
          WhseWkshLine.MODIFY(TRUE);

          WhseWkshLine.Reset();
          WhseWkshLine.SETRANGE(WhseWkshLine."Line No.",50000);
          WhseWkshLine.FIND('-');
          WhseWkshLine.VALIDATE("Qty. to Handle",1);
          WhseWkshLine.MODIFY(TRUE);

          WhseWkshLine.Reset();
          WhseWkshLine.SETRANGE(WhseWkshLine."Line No.",70000);
          WhseWkshLine.FIND('-');
          WhseWkshLine.VALIDATE("Qty. to Handle",1);
          WhseWkshLine.MODIFY(TRUE);

          IF LastIteration = '23-2-4-10' THEN EXIT;

          WhseWkshLine.Reset();
          WhseWkshLine.SETRANGE("Worksheet Template Name",WhseWkshLine."Worksheet Template Name");
          WhseWkshLine.SETRANGE(Name,WhseWkshLine.Name);
          WhseWkshLine.SETRANGE("Location Code",WhseWkshLine."Location Code");
          CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
          CreateMovFromWhseSource.USEREQUESTPAGE(FALSE);
          CreateMovFromWhseSource.Initialize('',0,FALSE,FALSE,FALSE);
          CreateMovFromWhseSource.RunModal();
          CLEAR(CreateMovFromWhseSource);

          IF LastIteration = '23-2-4-20' THEN EXIT;

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",50000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Serial No.",'SN02');
          WhseActivLine.MODIFY(TRUE);

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",60000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Serial No.",'SN02');
          WhseActivLine.MODIFY(TRUE);

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",70000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Serial No.",'SN03');
          WhseActivLine.MODIFY(TRUE);

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",80000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Serial No.",'SN03');
          WhseActivLine.MODIFY(TRUE);

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",110000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Lot No.",'LOT01');
          WhseActivLine.MODIFY(TRUE);

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",120000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Lot No.",'LOT01');
          WhseActivLine.MODIFY(TRUE);

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",90000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Lot No.",'LOT01');
          WhseActivLine.MODIFY(TRUE);

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Movement);
          WhseActivLine.SETRANGE("Line No.",100000);
          WhseActivLine.FIND('-');
          WhseActivLine.VALIDATE("Lot No.",'LOT01');
          WhseActivLine.MODIFY(TRUE);

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '23-2-4-30' THEN EXIT;

        // 23-2-5

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80100','',331,'BOX',5.11,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'T_TEST','T1',1,'BOX',15.7,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'80216-T','',2,'PCS',0.8,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'A_TEST','',20,'PCS',4.55,'WHITE','');
           END;

          SalesLine.Reset();
          SalesLine.SETRANGE("Document No.",'1002');
          IF SalesLine.FIND('-') THEN BEGIN
            REPEAT
              SalesLine."Planned Delivery Date" :=301101D;
              SalesLine.MODIFY(TRUE);
            UNTIL SalesLine.Next() =0;
          END;

          IF LastIteration = '23-2-5-10' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_TEST','',20,'PCS',4.55,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',10,'PACK',5.7,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'T_TEST','T1',1,'BOX',15.7,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'80216-T','',1,'PCS',0.8,'WHITE','');
           END;

          SalesLine.Reset();
          SalesLine.SETRANGE("Document No.",'1003');
          IF SalesLine.FIND('-') THEN BEGIN
            REPEAT
              SalesLine."Planned Delivery Date" :=301101D;
              SalesLine.MODIFY(TRUE);
            UNTIL SalesLine.Next() =0;
          END;

          IF LastIteration = '23-2-5-20' THEN EXIT;

        END;
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
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 23-3-1

          SetGlobalPreconditions;

          IF LastIteration = '23-3-1-10' THEN EXIT;

          Location.SETRANGE(Code,'WHITE');
          Location.FIND('-');
          Location."Always Create Pick Line" := TRUE;
          Location.MODIFY(TRUE);

          IF LastIteration = '23-3-1-20' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'WHITE','TCS23-3-1-W',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','WHITE',3,'Pack',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','WHITE',1,'Pack',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80100','','WHITE',1,'Pack',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'80100','','WHITE',1,'Pack',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'80100','','WHITE',1,'Pack',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,60000,PurchLine.Type::Item,'T_TEST','T1','WHITE',5,'Box',5,FALSE);

          SNCode := 'SN00';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,60000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','WHITE','',251101D,251101D,0,2);
          END;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WITH WhseActivLine DO BEGIN
            SETRANGE("Activity Type","Activity Type"::"Put-away");
            FIND('-');
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",20000,'PICK','W-01-0001',3);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",40000,'PICK','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",60000,'PICK','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",80000,'PICK','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",100000,'PICK','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",120000,'Pick','W-02-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",140000,'Pick','W-02-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",160000,'Pick','W-02-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",180000,'Pick','W-02-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",200000,'Pick','W-02-0001',1);
          END;

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS23-3-1-B',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80100','','Blue',3,'Box',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'T_TEST','T1','Blue',3,'Box',5,FALSE);

          SNCode := 'SN05';
          FOR i := 1 TO 3 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T1','Blue','',251101D,251101D,0,2);
          END;

          PurchHeader.SETRANGE("No.",'106002');
          PurchHeader.FIND('-');
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '23-3-1-30' THEN EXIT;

        // 23-3-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80100','',10,'Pack',1.07,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'T_TEST','T1',3,'BOX',44.11,'WHITE','');
           END;

          IF LastIteration = '23-3-2-10' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_TEST','T1',5,'BOX',44.11,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',10,'Pack',1.07,'WHITE','');
           END;

          IF LastIteration = '23-3-2-20' THEN EXIT;

        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        WITH TestScriptMgmt DO BEGIN
        // 23-4-1

          SetGlobalPreconditions;

          IF LastIteration = '23-4-1-10' THEN EXIT;

          WITH Item DO BEGIN
            GET('80100');
            Item."Replenishment System" := Item."Replenishment System"::Purchase;
            Item."Put-away Unit of Measure Code" := 'BOX';
            MODIFY(TRUE);
            Reset();
            GET('D_PROD');
            Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
            MODIFY(TRUE);
          END;

          IF LastIteration = '23-4-1-20' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS23-4-1',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T1','Blue',1,'Box',5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100','','Blue',1,'Pallet',1,FALSE);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','T1','Blue','',251101D,251101D,0,2);

          PurchHeader.FIND('-');
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '23-4-1-30' THEN EXIT;

        // 23-4-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T1',1,'BOX',44.11,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100','',1,'Pallet',1.07,'WHITE','');
           END;

          IF LastIteration = '23-4-2-10' THEN EXIT;

        // 23-4-3

          InsertTransferHeader(TransHeader,'BLUE','WHITE','OWN LOG.',251101D);
          InsertTransferLine(TransLine,TransHeader."No.",10000,'T_TEST','T1','BOX',1,0,1);
          InsertTransferLine(TransLine,TransHeader."No.",20000,'80100','','Pallet',1,0,1);

          IF LastIteration = '23-4-3-10' THEN EXIT;

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
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        WITH TestScriptMgmt DO BEGIN
        // 23-5-1

          SetGlobalPreconditions;

          IF LastIteration = '23-5-1-10' THEN EXIT;

          InsertDedicatedBin('WHITE','Production','W-07-0001','T_TEST','T2','Box',2,5);

          IF LastIteration = '23-5-1-20' THEN EXIT;

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS23-5-1',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T2','White',2,'Box',5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80216-T','','White',2,'PCS',1,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'C_TEST','32','White',3,'PCS',1,FALSE);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','T2','White','',251101D,251101D,0,2);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN02','','');
            CreateRes.CreateEntry('T_TEST','T2','White','',251101D,251101D,0,2);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,2,2,'','LOT01','');
            CreateRes.CreateEntry('80216-T','','White','',251101D,251101D,0,2);

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WITH WhseActivLine DO BEGIN
            SETRANGE("Activity Type","Activity Type"::"Put-away");
            FIND('-');
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",20000,'PICK','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",40000,'Pick','W-01-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",60000,'Pick','W-01-0001',2);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",80000,'PICK','W-01-0001',3);
          END;

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '23-5-1-30' THEN EXIT;

        END;
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
        CreateRes: Codeunit "Create Reserv. Entry";
        SNCode: Code[20];
        i: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 23-6-1

          SetGlobalPreconditions;

          IF LastIteration = '23-6-1-10' THEN EXIT;

        // 23-6-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS23-6-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_TEST','T2','White',4,'Box',5,FALSE);

          SNCode := 'SN00';
          FOR i := 1 TO 4 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','T2','WHITE','',251101D,251101D,0,2);
          END;

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WITH WhseActivLine DO BEGIN
            SETRANGE("Activity Type","Activity Type"::"Put-away");
            FIND('-');
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",20000,'PICK','W-04-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",40000,'Pick','W-04-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",60000,'Pick','W-04-0001',1);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",80000,'PICK','W-04-0001',1);
          END;

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '23-6-2-10' THEN EXIT;


        // 23-6-3

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T2',3,'BOX',12.27,'WHITE','');
           END;

          IF LastIteration = '23-6-3-10' THEN EXIT;

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'20000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'T_Test','T2',2,'BOX',12.27,'WHITE','');
           END;

          IF LastIteration = '23-6-3-20' THEN EXIT;

        END;
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
        WITH TestScriptMgmt DO BEGIN
        // 23-7-1

          SetGlobalPreconditions;

          IF LastIteration = '23-7-1-10' THEN EXIT;

        // 23-7-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Blue','TCS23-7-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'C_TEST','32','White',3,'PCS',5,FALSE);

          ReleasePurchDocument(PurchHeader);

          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'WHITE');

          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '23-7-2-10' THEN EXIT;

        // 23-7-3

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'White','TCS23-7-3',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_TEST','','White',12,'PCS',9.27,FALSE);

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '23-7-3-10' THEN EXIT;

        // 23-7-4

          InsertProdOrder(ProdOrder,3,0,'D_PROD',4,'WHITE');
          ProdOrder.VALIDATE("Due Date",261101D);
          ProdOrder.MODIFY(TRUE);
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          IF LastIteration = '23-7-4-10' THEN EXIT;

        // 23-7-5

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'WHITE',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'A_TEST','12',3,'PCS',12.27,'WHITE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'D_PROD','',2,'PCS',50.01,'WHITE','');
           END;

          SalesLine.Reset();
          SalesLine.SETRANGE("Document No.",'1001');
          IF SalesLine.FIND('-') THEN BEGIN
            REPEAT
              SalesLine."Planned Delivery Date" :=301101D;
              SalesLine.MODIFY(TRUE);
            UNTIL SalesLine.Next() =0;
          END;
          IF LastIteration = '23-7-5-10' THEN EXIT;

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

