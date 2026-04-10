codeunit 103357 "BW Test Use Case 7"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 7");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103357,7,0,'',1);

        TestscriptMgt.ShowTestscriptResult;
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        TestCase: Record Table103301;
        UseCase: Record Table103300;
        ResEntry: Record "Reservation Entry";
        SelectionForm: Page Page103317;
        TestScriptMgmt: Codeunit Codeunit103307;
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

        UseCase.GET('BW',UseCaseNo);
        TestScriptMgmt.InitializeOutput(ObjectNo,'');
        TestResultsPath := TestScriptMgmt.GetTestResultsPath;
        TestScriptMgmt.SetNumbers(NoOfRecords,NoOfFields);

        IF LastIteration <> '' THEN BEGIN
          TestCase.GET('BW',UseCaseNo,TestCaseNo);
          TestCaseDesc[TestCaseNo] :=
            FORMAT(UseCaseNo) + '.' + FORMAT(TestCaseNo) + ' ' + TestCase.Description;
          HandleTestCases;
        END else BEGIN
          TestCaseNo := 0;
          CLEAR(TestUseCase);
          CLEAR(TestCaseDesc);

          TestCase.Reset();
          TestCase.SETRANGE("Project Code",'BW');
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
          1:
            PerformTestCase1;
          2:
            PerformTestCase2;
          3:
            PerformTestCase3;
          4:
            PerformTestCase4;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        GenPostSetup: Record "General Posting Setup";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 7-1-1

          SetGlobalPreconditions;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Purch. Account",'7130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '7-1-1-10' THEN
            EXIT;

          GetLastILENo;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS7-1-1','A_TEST','11','SILVER','',5,'PCS',46,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS7-1-1','B_TEST','','SILVER','',1,'PCS',12,0,'S-03-0001');

          IF LastIteration = '7-1-1-20' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '7-1-1-30' THEN
            EXIT;

          // 7-1-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS7-1-2',FALSE);

          IF LastIteration = '7-1-2-10' THEN
            EXIT;

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_Test','','SILVER',2,'BOX',55,FALSE);
          PurchLine.VALIDATE("Bin Code",'S-01-0001');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_Test','11','SILVER',-4,'PCS',46,FALSE);

          IF LastIteration = '7-1-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);

          IF LastIteration = '7-1-2-30' THEN
            EXIT;

          // 7-1-3

          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '7-1-3-10' THEN
            EXIT;

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '7-1-3-20' THEN
            EXIT;

          // 7-1-4

          CLEAR(UndoPurchRcptLine);
          PurchRcptLine.Reset();
          PurchRcptLine.SETCURRENTKEY("Order No.");
          PurchRcptLine.SETRANGE("Order No.",PurchHeader."No.");
          PurchRcptLine.SETRANGE("Line No.",20000);
          PurchRcptLine.FindFirst();
          UndoPurchRcptLine.SetHideDialog(TRUE);
          UndoPurchRcptLine.RUN(PurchRcptLine);

          IF LastIteration = '7-1-4-10' THEN
            EXIT;

          // 7-1-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '7-1-5-10' THEN
            EXIT;

          // 7-1-6

          CLEAR(UndoPurchRcptLine);
          PurchRcptLine.Reset();
          PurchRcptLine.SETCURRENTKEY("Order No.");
          PurchRcptLine.SETRANGE("Order No.",PurchHeader."No.");
          PurchRcptLine.SETRANGE("Line No.",10000);
          PurchRcptLine.FindFirst();
          UndoPurchRcptLine.SetHideDialog(TRUE);
          UndoPurchRcptLine.RUN(PurchRcptLine);

          IF LastIteration = '7-1-6-10' THEN
            EXIT;

          // 7-1-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '7-1-7-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ReturnShptLine: Record "Return Shipment Line";
        UndoRtrnShptLine: Codeunit "Undo Return Shipment Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 7-2-1

          SetGlobalPreconditions;

          IF LastIteration = '7-2-1-10' THEN
            EXIT;

          GetLastILENo;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS7-2-1','A_TEST','12','SILVER','',10,'PCS',9.87,0,'S-01-0001');

          IF LastIteration = '7-2-1-20' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '7-2-1-30' THEN
            EXIT;

          // 7-2-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS7-2-2',FALSE);
          PurchHeader.VALIDATE("Vendor Cr. Memo No.",'TCS7-2-2');
          PurchHeader.Modify();

          IF LastIteration = '7-2-2-10' THEN
            EXIT;

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_Test','12','SILVER',4,'PCS',9.87,FALSE);
          ModifyPurchReturnLine(PurchHeader,10000,'NONEED');
          InsertPurchLine(PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_Test','12','SILVER',-3,'PCS',9.87,FALSE);
          ModifyPurchReturnLine(PurchHeader,20000,'WRONG');
          InsertPurchLine(PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_Test','12','SILVER',-1,'PCS',9.87,FALSE);
          ModifyPurchReturnLine(PurchHeader,30000,'DAMAGED');

          IF LastIteration = '7-2-2-20' THEN
            EXIT;

          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '7-2-2-30' THEN
            EXIT;

          // 7-2-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '7-2-3-10' THEN
            EXIT;

          // 7-2-4

          CLEAR(UndoRtrnShptLine);
          ReturnShptLine.Reset();
          ReturnShptLine.SETCURRENTKEY("Return Order No.");
          ReturnShptLine.SETRANGE("Return Order No.",PurchHeader."No.");
          ReturnShptLine.SETRANGE("Return Order Line No.",20000);
          ReturnShptLine.FindFirst();
          UndoRtrnShptLine.SetHideDialog(TRUE);
          UndoRtrnShptLine.RUN(ReturnShptLine);

          IF LastIteration = '7-2-4-10' THEN
            EXIT;

          // 7-2-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '7-2-5-10' THEN
            EXIT;

          // 7-2-6

          CLEAR(UndoRtrnShptLine);
          ReturnShptLine.Reset();
          ReturnShptLine.SETCURRENTKEY("Return Order No.");
          ReturnShptLine.SETRANGE("Return Order No.",PurchHeader."No.");
          ReturnShptLine.SETRANGE("Return Order Line No.",10000);
          ReturnShptLine.FindFirst();
          UndoRtrnShptLine.SetHideDialog(TRUE);
          UndoRtrnShptLine.RUN(ReturnShptLine);

          IF LastIteration = '7-2-6-10' THEN
            EXIT;

          // 7-2-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '7-2-7-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        UndoShptLine: Codeunit "Undo Sales Shipment Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 7-3-1

          SetGlobalPreconditions;

          IF LastIteration = '7-3-1-10' THEN
            EXIT;

          GetLastILENo;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS7-3-1','A_TEST','12','WHITE','',10,'PCS',12.34,0,'');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS7-3-1','B_TEST','','SILVER','',1,'PCS',10,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS7-3-1','L_TEST','','SILVER','',3,'BOX',43.21,0,'S-02-0001');

          IF LastIteration = '7-3-1-20' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',1,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);
          InsertResEntry(ResEntry,'SILVER',2,3,251101D,'L_TEST','','','LN02',2,2,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);

          IF LastIteration = '7-3-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '7-3-1-40' THEN
            EXIT;

          Commit();
          InsertAdjmtWhseJnlLine(WhseJnlLine,'ADJMT','DEFAULT','WHITE',10000,251101D,'A_TEST','12','','W-01-0001',9,'PCS');

          IF LastIteration = '7-3-1-50' THEN
            EXIT;

          WhseJnlPostBatch(WhseJnlLine);

          IF LastIteration = '7-2-1-60' THEN
            EXIT;

          // 7-3-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '7-3-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'L_Test','',3,'BOX',45.67,'SILVER','');
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'A_Test','12',8,'PCS',21.34,'WHITE','');
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'A_Test','12',-5,'PCS',21.34,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-03-0001');
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '7-3-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,1,1,'','LN01','');
          CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,2,2,'','LN02','');
          CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);

          IF LastIteration = '7-3-2-30' THEN
            EXIT;

          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '7-3-2-40' THEN
            EXIT;

          // 7-3-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '7-3-3-10' THEN
            EXIT;

          // 7-3-4

          CLEAR(WhseShptHeader);
          InsertWhseShptHeader(WhseShptHeader,'','','');
          WhseShptHeader.VALIDATE("Location Code",'WHITE');
          WhseShptHeader.Modify();

          IF LastIteration = '7-3-4-10' THEN
            EXIT;

          CreateWhseShptBySourceFilter(WhseShptHeader,'CUST30000');

          IF LastIteration = '7-3-4-20' THEN
            EXIT;

          Commit();
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '7-3-4-30' THEN
            EXIT;

          // 7-3-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '7-3-5-10' THEN
            EXIT;

          // 7-3-6

          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type"::Pick);
          WhseActivLine.FindFirst();
          WhseActivLine.SETRANGE("No.",WhseActivLine."No.");
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '7-3-6-10' THEN
            EXIT;

          WhseShptLine.FindFirst();
          PostWhseShipment(WhseShptLine,FALSE);

          IF LastIteration = '7-3-6-20' THEN
            EXIT;

          // 7-3-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '7-3-7-10' THEN
            EXIT;

          // 7-3-8

          CLEAR(UndoShptLine);
          SalesShptLine.Reset();
          SalesShptLine.SETRANGE("No.",'A_TEST');
          SalesShptLine.SETFILTER(Quantity,'=%1',-5);
          SalesShptLine.FindFirst();
          UndoShptLine.SetHideDialog(TRUE);
          UndoShptLine.RUN(SalesShptLine);

          IF LastIteration = '7-3-8-10' THEN
            EXIT;

          // 7-3-9

          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo);

          IF LastIteration = '7-3-9-10' THEN
            EXIT;

          // 7-3-10

          CLEAR(UndoShptLine);
          SalesShptLine.Reset();
          SalesShptLine.SETRANGE("No.",'L_TEST');
          SalesShptLine.SETFILTER(Quantity,'<>%1',0);
          SalesShptLine.FindFirst();
          UndoShptLine.SetHideDialog(TRUE);
          UndoShptLine.RUN(SalesShptLine);

          IF LastIteration = '7-3-10-10' THEN
            EXIT;

          // 7-3-11

          VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo);

          IF LastIteration = '7-3-11-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RtrnRcptLine: Record "Return Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        UndoSalesRcptLine: Codeunit "Undo Return Receipt Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 7-4-1

          SetGlobalPreconditions;

          IF LastIteration = '7-4-1-10' THEN
            EXIT;

          GetLastILENo;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS7-4-1','T_TEST','','SILVER','',7,'BOX',100,0,'S-01-0001');

          IF LastIteration = '7-4-1-20' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',1,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);
          InsertResEntry(ResEntry,'SILVER',2,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);
          InsertResEntry(ResEntry,'SILVER',3,3,251101D,'T_TEST','','SN03','',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);
          InsertResEntry(ResEntry,'SILVER',4,3,251101D,'T_TEST','','SN04','',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);
          InsertResEntry(ResEntry,'SILVER',5,3,251101D,'T_TEST','','SN05','',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);
          InsertResEntry(ResEntry,'SILVER',6,3,251101D,'T_TEST','','SN06','',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);
          InsertResEntry(ResEntry,'SILVER',7,3,251101D,'T_TEST','','SN07','',1,1,83,0,
            'ITEM','DEFAULT',ItemJnlLine."Line No.",TRUE);

          IF LastIteration = '7-4-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '7-4-1-40' THEN
            EXIT;

          // 7-4-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '7-4-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'T_Test','',4,'BOX',100,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-01-0001');
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'T_Test','',-2,'BOX',100,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-01-0001');
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '7-4-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,'SN00008','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,'SN00009','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,'SN00010','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,'SN00011','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);

          IF LastIteration = '7-4-2-30' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,-1,-1,'SN01','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,-1,-1,'SN03','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);

          IF LastIteration = '7-4-2-40' THEN
            EXIT;

          SalesHeader.Receive := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '7-4-2-50' THEN
            EXIT;

          // 7-4-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '7-4-3-10' THEN
            EXIT;

          // 7-4-4

          CLEAR(UndoSalesRcptLine);
          RtrnRcptLine.Reset();
          RtrnRcptLine.SETRANGE("Line No.",10000);
          RtrnRcptLine.FindFirst();
          UndoSalesRcptLine.SetHideDialog(TRUE);
          UndoSalesRcptLine.RUN(RtrnRcptLine);

          IF LastIteration = '7-4-4-10' THEN
            EXIT;

          // 7-4-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '7-4-5-10' THEN
            EXIT;

          // 7-4-6

          CLEAR(UndoSalesRcptLine);
          RtrnRcptLine.Reset();
          RtrnRcptLine.SETRANGE("Line No.",20000);
          RtrnRcptLine.FindFirst();
          UndoSalesRcptLine.SetHideDialog(TRUE);
          UndoSalesRcptLine.RUN(RtrnRcptLine);

          IF LastIteration = '7-4-6-10' THEN
            EXIT;

          // 7-4-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '7-4-7-10' THEN
            EXIT;

          Commit();
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

