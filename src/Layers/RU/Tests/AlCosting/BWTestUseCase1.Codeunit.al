codeunit 103351 "BW Test Use Case 1"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 1");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103351,1,0,'',1);

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
          5:
            PerformTestCase5;
          6:
            PerformTestCase6;
          7:
            PerformTestCase7;
          13:
            PerformTestCase13;
          14:
            PerformTestCase14;
          16:
            PerformTestCase16;
          17:
            PerformTestCase17;
          19:
            PerformTestCase19;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-1-1

          SetGlobalPreconditions;

          IF LastIteration = '1-1-1-10' THEN
            EXIT;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Purch. Account",'7130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '1-1-1-20' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Receive" := TRUE;
          Loc.Modify();

          IF LastIteration = '1-1-1-30' THEN
            EXIT;

          // 1-1-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS1-1-2',FALSE);

          IF LastIteration = '1-1-2-10' THEN
            EXIT;

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_Test','','SILVER',2,'BOX',100,FALSE);
          InsertPurchLine(PurchLine,PurchHeader,20000,PurchLine.Type::Item,'C_Test','31','SILVER',7,'PCS',22,FALSE);
          InsertPurchLine(PurchLine,PurchHeader,30000,PurchLine.Type::"Charge (Item)",'GPS','','',1,'',15,FALSE);
          PurchLine.VALIDATE("Qty. to Receive",1);
          PurchLine.MODIFY(TRUE);

          IF LastIteration = '1-1-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);

          IF LastIteration = '1-1-2-30' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '1-1-2-40' THEN
            EXIT;

          InsertWhseRcptHeader(WhseRcptHeader,'SILVER','','S-01-0001');

          IF LastIteration = '1-1-2-50' THEN
            EXIT;

          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'SILVER');

          IF LastIteration = '1-1-2-60' THEN
            EXIT;

          VerifyPostCondition(UseCaseNo,TestCaseNo,2,LastILENo);

          IF LastIteration = '1-1-2-70' THEN
            EXIT;

          WhseRcptLine."No." := WhseRcptHeader."No.";
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '1-1-2-80' THEN
            EXIT;

          // 1-1-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-1-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-2-1

          SetGlobalPreconditions;

          IF LastIteration = '1-2-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-2-1','A_TEST','','SILVER','',10,'PCS',10,0,'S-01-0001');

          IF LastIteration = '1-2-1-20' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-2-1-30' THEN
            EXIT;

          // 1-2-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS1-2-2',FALSE);
          PurchHeader.VALIDATE("Vendor Cr. Memo No.",'TCS1-2-2');

          IF LastIteration = '1-2-2-10' THEN
            EXIT;

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_Test','','SILVER',4,'PCS',12,FALSE);
          PurchLine.VALIDATE("Return Reason Code",'NONEED');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_Test','','SILVER',-3,'PCS',12,FALSE);
          PurchLine.VALIDATE("Return Reason Code",'WRONG');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_Test','','SILVER',-1,'PCS',12,FALSE);
          PurchLine.VALIDATE("Return Reason Code",'DAMAGED');
          PurchLine.MODIFY(TRUE);

          IF LastIteration = '1-2-2-20' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '1-2-2-30' THEN
            EXIT;

          PurchHeader.Invoice := TRUE;
          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-2-2-40' THEN
            EXIT;

          // 1-2-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-2-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        GenPostSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        CreateRes: Codeunit "Create Reserv. Entry";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-3-1

          SetGlobalPreconditions;

          IF LastIteration = '1-3-1-10' THEN
            EXIT;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Purch. Credit Memo Account",'7130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '1-3-1-20' THEN
            EXIT;

          // 1-3-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Credit Memo",'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS1-3-2',FALSE);
          PurchHeader.VALIDATE("Vendor Cr. Memo No.",'TCS1-3-2');
          PurchHeader.MODIFY(TRUE);

          IF LastIteration = '1-3-2-10' THEN
            EXIT;

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_Test','','SILVER',-2,'BOX',12,FALSE);
          PurchLine.VALIDATE("Bin Code",'S-03-0001');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_Test','11','SILVER',-3,'PCS',11,FALSE);
          PurchLine.VALIDATE("Bin Code",'S-01-0001');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,30000,PurchLine.Type::"Charge (Item)",'P-RESTOCK','','SILVER',2,'',32,FALSE);

          IF LastIteration = '1-3-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(39,3,PurchHeader."No.",'',0,10000,1,-1,-1,'SN01','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,3);
          CreateRes.CreateReservEntryFor(39,3,PurchHeader."No.",'',0,10000,1,-1,-1,'SN02','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,3);

          IF LastIteration = '1-3-2-30' THEN
            EXIT;

          ItemChargeAssgntPurch.Init();
          ItemChargeAssgntPurch."Document Type" := PurchLine."Document Type";
          ItemChargeAssgntPurch."Document No." := PurchLine."Document No.";
          ItemChargeAssgntPurch."Document Line No." := 30000;
          ItemChargeAssgntPurch."Item Charge No." := 'P-RESTOCK';
          ItemChargeAssignt.CreateDocChargeAssgnt(ItemChargeAssgntPurch,PurchLine."Receipt No.");
          PurchLine.UpdateItemChargeAssgnt();
          ItemChargeAssignt.AssignItemCharges(PurchLine,2,64,format(1));

          IF LastIteration = '1-3-2-40' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '1-3-2-50' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-3-2-60' THEN
            EXIT;

          // 1-3-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-3-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        InvSetup: Record "Inventory Setup";
        Loc: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-4-1

          SetGlobalPreconditions;

          Loc.GET('BLUE');
          Loc."Bin Mandatory" := TRUE;
          Loc.Modify();

          InvSetup.Get();
          InvSetup."Location Mandatory" := TRUE;
          InvSetup.Modify();

          IF LastIteration = '1-4-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-4-1','B_TEST','','SILVER','',10,'PCS',12,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS1-4-1','80216-T','','BLUE','',5,'PCS',1.23,0,'A1');

          InsertResEntry(ResEntry,'BLUE',10002,3,251101D,'80216-T','','','LN0001',3,3,83,2,
            'ITEM','DEFAULT',10002,TRUE);
          InsertResEntry(ResEntry,'BLUE',10002,3,251101D,'80216-T','','','LN01',1,1,83,2,
            'ITEM','DEFAULT',10002,TRUE);
          InsertResEntry(ResEntry,'BLUE',10002,3,251101D,'80216-T','','','LN02',1,1,83,2,
            'ITEM','DEFAULT',10002,TRUE);

          IF LastIteration = '1-4-1-20' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-4-1-30' THEN
            EXIT;

          // 1-4-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '1-4-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'B_Test','',8,'PCS',12,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-01-0001');
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'B_Test','',-2,'PCS',12,'SILVER','WRONG');
          SalesLine.VALIDATE("Bin Code",'S-01-0002');
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'B_Test','',-3,'PCS',12,'SILVER','WRONG');
          SalesLine.VALIDATE("Bin Code",'S-01-0003');
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,40000,SalesLine.Type::Item,'B_Test','',-1,'PCS',12,'BLUE','WRONG');
          SalesLine.VALIDATE("Bin Code",'A1');
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,50000,SalesLine.Type::Item,'80216-T','',3,'PCS',1.23,'BLUE','');
          SalesLine.VALIDATE("Bin Code",'A1');
          SalesLine.VALIDATE("Unit Price",1.23);
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,60000,SalesLine.Type::Item,'80216-T','',2,'PCS',1.23,'BLUE','');
          SalesLine.VALIDATE("Bin Code",'A1');
          SalesLine.VALIDATE("Unit Price",1.23);
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,70000,SalesLine.Type::"Charge (Item)",'JB-FREIGHT','',1,'',2,'BLUE','');

          IF LastIteration = '1-4-2-20' THEN
            EXIT;

          InsertResEntry(ResEntry,'BLUE',50000,3,251101D,'80216-T','','','LN0001',3,3,37,1,SalesHeader."No.",'',50000,TRUE);
          InsertResEntry(ResEntry,'BLUE',60000,3,251101D,'80216-T','','','LN01',1,1,37,1,SalesHeader."No.",'',60000,TRUE);
          InsertResEntry(ResEntry,'BLUE',60000,3,251101D,'80216-T','','','LN02',1,1,37,1,SalesHeader."No.",'',60000,TRUE);

          IF LastIteration = '1-4-2-30' THEN
            EXIT;

          ItemChargeAssgntSales.Init();
          ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
          ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
          ItemChargeAssgntSales."Document Line No." := 70000;
          ItemChargeAssgntSales."Item Charge No." := 'JB-FREIGHT';
          ItemChargeAssignt.CreateDocChargeAssgn(ItemChargeAssgntSales,'');
          ItemChargeAssgntSales.Reset();
          ItemChargeAssgntSales.SETRANGE("Item No.",'B_TEST');
          ItemChargeAssgntSales.DeleteAll();
          ItemChargeAssgntSales.Reset();
          SalesLine.UpdateItemChargeAssgnt();
          ItemChargeAssignt.AssignItemCharges(SalesLine, 1, 2, Format(1));

          IF LastIteration = '1-4-2-40' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '1-4-2-50' THEN
            EXIT;

          SalesHeader.Invoice := TRUE;
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-4-2-60' THEN
            EXIT;

          // 1-4-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-4-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-5-1

          SetGlobalPreconditions;

          IF LastIteration = '1-5-1-10' THEN
            EXIT;

          // 1-5-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'30000',241101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '1-5-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'S_Test','42',20,'PCS',0,'SILVER','NONEED');
          SalesLine.VALIDATE("Bin Code",'S-01-0003');
          SalesLine.VALIDATE("Return Qty. to Receive",13);
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '1-5-2-20' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '1-5-2-30' THEN
            EXIT;

          SalesHeader.Invoice := TRUE;
          SalesHeader.Receive := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-5-2-40' THEN
            EXIT;

          // 1-5-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-5-3-10' THEN
            EXIT;

          // 1-5-4

          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",10000);
          SalesLine.VALIDATE("Return Qty. to Receive",5);
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '1-5-4-10' THEN
            EXIT;

          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-5-4-20' THEN
            EXIT;

          // 1-5-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '1-5-5-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    var
        GenPostSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        CreateRes: Codeunit "Create Reserv. Entry";
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-6-1

          SetGlobalPreconditions;

          IF LastIteration = '1-6-1-10' THEN
            EXIT;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Sales Credit Memo Account",'6130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '1-6-1-20' THEN
            EXIT;

          // 1-6-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Credit Memo",'30000',0D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '1-6-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'T_Test','',2,'BOX',80,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-02-0001');
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'A_Test','12',5,'PCS',55,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-01-0001');
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::"Charge (Item)",'UPS','',2,'',30,'SILVER','');

          IF LastIteration = '1-6-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(37,3,SalesHeader."No.",'',0,10000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,3);
          CreateRes.CreateReservEntryFor(37,3,SalesHeader."No.",'',0,10000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,3);

          IF LastIteration = '1-6-2-30' THEN
            EXIT;

          ItemChargeAssgntSales.Init();
          ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
          ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
          ItemChargeAssgntSales."Document Line No." := 30000;
          ItemChargeAssgntSales."Item Charge No." := 'UPS';
          ItemChargeAssignt.CreateDocChargeAssgn(ItemChargeAssgntSales,SalesLine."Return Receipt No.");
          SalesLine.UpdateItemChargeAssgnt();
          ItemChargeAssignt.AssignItemCharges(SalesLine, 2, 60, Format(1));

          IF LastIteration = '1-6-2-40' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '1-6-2-50' THEN
            EXIT;

          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-6-2-60' THEN
            EXIT;

          // 1-6-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-6-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        Loc: Record Location;
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        BC: Record "Bin Content";
        GetBC: Report "Whse. Get Bin Content";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-7-1

          SetGlobalPreconditions;

          Loc.GET('BLUE');
          Loc."Bin Mandatory" := TRUE;
          Loc.Modify();

          IF LastIteration = '1-7-1-10' THEN
            EXIT;

          // 1-7-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-7-2','A_TEST','','BLUE','',52,'PCS',14,0,'A1');

          IF LastIteration = '1-7-2-10' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-7-2-20' THEN
            EXIT;

          // 1-7-3

          InsertTransferHeader(TransHeader,'BLUE','SILVER','OWN LOG.',251101D);

          IF LastIteration = '1-7-3-10' THEN
            EXIT;

          BC.Reset();
          BC.SETRANGE("Location Code",'BLUE');
          BC.SETRANGE("Item No.",'A_TEST');
          GetBC.SETTABLEVIEW(BC);
          GetBC.USEREQUESTPAGE(FALSE);
          GetBC.InitializeTransferHeader(TransHeader);
          GetBC.RunModal();
          CLEAR(GetBC);

          IF LastIteration = '1-7-3-20' THEN
            EXIT;

          TransLine.GET(TransHeader."No.",10000);
          TransLine.VALIDATE(Quantity,12);
          TransLine.MODIFY(TRUE);

          IF LastIteration = '1-7-3-30' THEN
            EXIT;

          InsertTransferLine(TransLine,TransHeader."No.",20000,'A_TEST','','PCS',20,0,20);
          InsertTransferLine(TransLine,TransHeader."No.",30000,'A_TEST','','PCS',18,0,18);
          TransLine.SETRANGE("Document No.",TransHeader."No.");
          TransLine.MODIFYALL("Transfer-from Bin Code",'A1',TRUE);
          TransLine.MODIFYALL("Transfer-To Bin Code",'S-01-0001',TRUE);
          TransLine.GET(TransHeader."No.",20000);
          TransLine.VALIDATE("Transfer-To Bin Code",'S-01-0002');
          TransLine.MODIFY(TRUE);

          IF LastIteration = '1-7-3-40' THEN
            EXIT;

          ReleaseTransferOrder(TransHeader);

          IF LastIteration = '1-7-3-50' THEN
            EXIT;

          PostTransferOrder(TransHeader,TRUE);

          IF LastIteration = '1-7-3-60' THEN
            EXIT;

          // 1-7-4

          VerifyPostCondition(UseCaseNo,TestCaseNo,4,LastILENo);

          IF LastIteration = '1-7-4-10' THEN
            EXIT;

          // 1-7-5

          PostTransferOrder(TransHeader,FALSE);

          IF LastIteration = '1-7-5-10' THEN
            EXIT;

          // 1-7-6

          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '1-7-6-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase13()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateRes: Codeunit "Create Reserv. Entry";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-13-1

          SetGlobalPreconditions;

          IF LastIteration = '1-13-1-10' THEN
            EXIT;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Purch. Account",'7130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '1-13-1-20' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Put-away" := TRUE;
          Loc."Require Pick" := TRUE;
          Loc.Modify();

          IF LastIteration = '1-13-1-30' THEN
            EXIT;

          // 1-13-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS1-13-2',FALSE);

          IF LastIteration = '1-13-2-10' THEN
            EXIT;

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_Test','','SILVER',2,'BOX',100,FALSE);
          PurchLine.VALIDATE("Bin Code",'S-01-0001');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,20000,PurchLine.Type::Item,'C_Test','31','SILVER',7,'PCS',22,FALSE);
          PurchLine.VALIDATE("Bin Code",'S-01-0001');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,40000,PurchLine.Type::"Charge (Item)",'GPS','','',1,'',15,FALSE);
          PurchLine.VALIDATE("Qty. to Receive",1);
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','SILVER',10,'PCS',22,FALSE);

          IF LastIteration = '1-13-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN01','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,'SN02','','');
          CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,10,1,10,'','LOT01','');
          CreateRes.CreateEntry('80002','','SILVER','',251101D,251101D,0,2);

          IF LastIteration = '1-13-2-30' THEN
            EXIT;

          PurchLine.VALIDATE("Bin Code",'S-01-0002');
          PurchLine.MODIFY(TRUE);

          IF LastIteration = '1-13-2-40' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '1-13-2-50' THEN
            EXIT;

          CLEAR(PurchHeader);
          PurchHeader."No." := '123456789012345';
          PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
          PurchHeader.INSERT(TRUE);
          PurchHeader.VALIDATE("Buy-from Vendor No.",'20000');
          PurchHeader.VALIDATE("Order Date",251101D);
          PurchHeader.VALIDATE("Posting Date",251101D);
          PurchHeader.VALIDATE("Location Code",'SILVER');
          PurchHeader.VALIDATE("Vendor Invoice No.",'TCS1-13-2-B');
          PurchHeader.Modify();

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'B_Test','','SILVER',5,'PCS',4.2,FALSE);
          PurchLine.VALIDATE("Bin Code",'S-01-0003');
          PurchLine.VALIDATE("Qty. to Receive",5);
          PurchLine.MODIFY(TRUE);

          IF LastIteration = '1-13-2-60' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '1-13-2-70' THEN
            EXIT;

          // 1-13-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-13-3-10' THEN
            EXIT;

          // 1-13-4

          CLEAR(PurchHeader);
          PurchHeader.FIND('-');
          CreateInvPutAwayPickBySrcFilt(5,PurchHeader."No.");
          PurchHeader.FIND('+');
          CreateInvPutAwayPickBySrcFilt(5,PurchHeader."No.");

          IF LastIteration = '1-13-4-10' THEN
            EXIT;

          // 1-13-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '1-13-5-10' THEN
            EXIT;

          // 1-13-6

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
            FindFirst();
            GET("Activity Type","No.",30000);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",30000,'','S-01-0001',6);
            SplitLine(WhseActivLine);
            GET("Activity Type","No.",40000);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",40000,'','S-01-0002',5);
            SplitLine(WhseActivLine);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",50000,'','S-01-0003',5);
          END;

          IF LastIteration = '1-13-6-10' THEN
            EXIT;

          // 1-13-7

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);
          IF WhseActivLine.FindFirst() then
            PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '1-13-7-10' THEN
            EXIT;

          PurchHeader.FIND('-');
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-13-7-20' THEN
            EXIT;

          // 1-13-8

          VerifyPostCondition(UseCaseNo,TestCaseNo,8,LastILENo);

          IF LastIteration = '1-13-8-10' THEN
            EXIT;

          // 1-13-9

          CLEAR(SalesHeader);
          SalesHeader."No." := '123456789012345';
          SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
          SalesHeader.INSERT(TRUE);
          SalesHeader.VALIDATE("Sell-to Customer No.",'20000');
          SalesHeader.VALIDATE("Order Date",251101D);
          SalesHeader.VALIDATE("Posting Date",251101D);
          SalesHeader.VALIDATE("Location Code",'SILVER');
          SalesHeader.Modify();

          IF LastIteration = '1-13-9-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80002','',4,'PCS',12,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-01-0002');
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '1-13-9-20' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '1-13-9-30' THEN
            EXIT;

          CreateInvPutAwayPickBySrcFilt(1,SalesHeader."No.");

          IF LastIteration = '1-13-9-40' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
            GET("Activity Type","No.",10000);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",10000,'','S-01-0002',2);
            "Lot No." := 'LOT01';
            Modify();
            SplitLine(WhseActivLine);
            ModifyWhseActLine(WhseActivLine,"Activity Type","No.",20000,'','S-01-0003',2);
          END;

          IF LastIteration = '1-13-9-50' THEN
            EXIT;

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '1-13-9-60' THEN
            EXIT;

          SalesHeader.FIND('-');
          SalesHeader.Invoice := TRUE;
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-13-9-70' THEN
            EXIT;

          // 1-13-10

          VerifyPostCondition(UseCaseNo,TestCaseNo,10,LastILENo);

          IF LastIteration = '1-13-10-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase14()
    var
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-14-1

          SetGlobalPreconditions;

          IF LastIteration = '1-14-1-10' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Put-away" := TRUE;
          Loc.Modify();

          IF LastIteration = '1-14-1-20' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-14-1','A_TEST','','SILVER','',10,'PCS',10,0,'S-01-0001');

          IF LastIteration = '1-14-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-14-1-40' THEN
            EXIT;

          // 1-14-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS1-14-2',FALSE);
          PurchHeader.VALIDATE("Vendor Cr. Memo No.",'TCS1-14-2');

          IF LastIteration = '1-14-2-10' THEN
            EXIT;

          InsertPurchLine(PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_Test','','SILVER',4,'PCS',10,FALSE);
          PurchLine.VALIDATE("Return Reason Code",'NONEED');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_Test','','SILVER',-3,'PCS',10,FALSE);
          PurchLine.VALIDATE("Return Reason Code",'WRONG');
          PurchLine.MODIFY(TRUE);
          InsertPurchLine(PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_Test','','SILVER',-1,'PCS',10,FALSE);
          PurchLine.VALIDATE("Return Reason Code",'DAMAGED');
          PurchLine.MODIFY(TRUE);

          IF LastIteration = '1-14-2-20' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '1-14-2-30' THEN
            EXIT;

          // 1-14-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-14-3-10' THEN
            EXIT;

          // 1-14-4

          InsertWhseActHeader(WhseActivHeader,4,'SILVER');
          CreateInvPutAway(WhseActivHeader);

          IF LastIteration = '1-14-4-10' THEN
            EXIT;

          // 1-14-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '1-14-5-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '1-14-5-20' THEN
            EXIT;

          // 1-14-6

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '1-14-6-10' THEN
            EXIT;

          PurchHeader.FIND('-');
          PurchHeader.Invoice := TRUE;
          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-14-6-20' THEN
            EXIT;

          // 1-14-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '1-14-7-10' THEN
            EXIT;

          Commit();
        END;
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
        WITH TestScriptMgmt DO BEGIN
          // 1-16-1

          SetGlobalPreconditions;

          IF LastIteration = '1-16-1-10' THEN
            EXIT;

          Loc.GET('BLUE');
          Loc."Bin Mandatory" := TRUE;
          Loc.Modify();
          Loc.GET('SILVER');
          Loc."Require Put-away" := TRUE;
          Loc.Modify();

          IF LastIteration = '1-16-1-20' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-16-1','B_TEST','','SILVER','',10,'PCS',12,0,'S-01-0001');

          IF LastIteration = '1-16-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-16-1-40' THEN
            EXIT;

          // 1-16-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '1-16-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'B_Test','',8,'PCS',12,'SILVER','');
          SalesLine.VALIDATE("Bin Code",'S-01-0001');
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'B_Test','',-2,'PCS',12,'SILVER','WRONG');
          SalesLine.VALIDATE("Bin Code",'S-01-0002');
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'B_Test','',-3,'PCS',12,'SILVER','WRONG');
          SalesLine.VALIDATE("Bin Code",'S-01-0003');
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,40000,SalesLine.Type::Item,'B_Test','',-1,'PCS',12,'BLUE','WRONG');
          SalesLine.VALIDATE("Bin Code",'A1');
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '1-16-2-20' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '1-16-2-30' THEN
            EXIT;

          // 1-16-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-16-3-10' THEN
            EXIT;

          // 1-16-4

          InsertWhseActHeader(WhseActivHeader,4,'SILVER');
          CreateInvPutAway(WhseActivHeader);

          IF LastIteration = '1-16-4-10' THEN
            EXIT;

          // 1-16-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '1-16-5-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '1-16-5-20' THEN
            EXIT;

          // 1-16-6

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '1-16-6-10' THEN
            EXIT;

          SalesHeader.FIND('-');
          SalesHeader.Invoice := TRUE;
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-16-6-20' THEN
            EXIT;

          // 1-16-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '1-16-7-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase17()
    var
        Loc: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-17-1

          SetGlobalPreconditions;

          IF LastIteration = '1-17-1-10' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Put-away" := TRUE;
          Loc.Modify();

          IF LastIteration = '1-17-1-20' THEN
            EXIT;

          // 1-17-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '1-17-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'S_Test','42',20,'PCS',0,'SILVER','NONEED');
          SalesLine.VALIDATE("Bin Code",'S-01-0003');
          SalesLine.VALIDATE("Return Qty. to Receive",13);
          SalesLine.VALIDATE("Unit Price",12);
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '1-17-2-20' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '1-17-2-30' THEN
            EXIT;

          // 1-17-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '1-17-3-10' THEN
            EXIT;

          // 1-17-4

          CreateInvPutAwayPickBySrcFilt(4,SalesHeader."No.");

          IF LastIteration = '1-17-4-10' THEN
            EXIT;

          // 1-17-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '1-17-5-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '1-17-5-20' THEN
            EXIT;

          // 1-17-6

          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '1-17-6-10' THEN
            EXIT;

          Commit();
          SalesHeader.GET(SalesHeader."Document Type",SalesHeader."No.");
          SalesHeader.Receive := FALSE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-17-6-20' THEN
            EXIT;

          // 1-17-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '1-17-7-10' THEN
            EXIT;

          // 1-17-8

          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",10000);
          SalesLine.VALIDATE("Return Qty. to Receive",5);
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '1-17-8-10' THEN
            EXIT;

          // 1-17-9

          CreateInvPutAwayPickBySrcFilt(4,SalesHeader."No.");

          IF LastIteration = '1-17-9-10' THEN
            EXIT;

          // 1-17-10

          VerifyPostCondition(UseCaseNo,TestCaseNo,10,LastILENo);

          IF LastIteration = '1-17-10-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '1-17-10-20' THEN
            EXIT;

          // 1-17-11

          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '1-17-11-10' THEN
            EXIT;

          Commit();
          SalesHeader.GET(SalesHeader."Document Type",SalesHeader."No.");
          SalesHeader.Receive := FALSE;
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-17-11-20' THEN
            EXIT;

          // 1-17-12

          VerifyPostCondition(UseCaseNo,TestCaseNo,12,LastILENo);

          IF LastIteration = '1-17-12-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase19()
    var
        Loc: Record Location;
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        BC: Record "Bin Content";
        GetBC: Report "Whse. Get Bin Content";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-19-1

          SetGlobalPreconditions;

          IF LastIteration = '1-19-1-10' THEN
            EXIT;

          Loc.GET('BLUE');
          Loc."Bin Mandatory" := TRUE;
          Loc."Require Pick" := TRUE;
          Loc.Modify();
          Loc.GET('SILVER');
          Loc."Require Put-away" := TRUE;
          Loc.Modify();

          IF LastIteration = '1-19-1-20' THEN
            EXIT;

          // 1-19-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-19-2','A_TEST','','BLUE','',52,'PCS',14,0,'A1');

          IF LastIteration = '1-19-2-10' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-19-2-20' THEN
            EXIT;

          // 1-19-3

          InsertTransferHeader(TransHeader,'BLUE','SILVER','OWN LOG.',251101D);

          IF LastIteration = '1-19-3-10' THEN
            EXIT;

          BC.Reset();
          BC.SETRANGE("Location Code",'BLUE');
          BC.SETRANGE("Item No.",'A_TEST');
          GetBC.SETTABLEVIEW(BC);
          GetBC.USEREQUESTPAGE(FALSE);
          GetBC.InitializeTransferHeader(TransHeader);
          GetBC.RunModal();
          CLEAR(GetBC);

          IF LastIteration = '1-19-3-20' THEN
            EXIT;

          TransLine.GET(TransHeader."No.",10000);
          TransLine.VALIDATE(Quantity,12);
          TransLine.MODIFY(TRUE);

          InsertTransferLine(TransLine,TransHeader."No.",20000,'A_TEST','','PCS',20,0,20);
          InsertTransferLine(TransLine,TransHeader."No.",30000,'A_TEST','','PCS',18,0,18);
          TransLine.SETRANGE("Document No.",TransHeader."No.");
          TransLine.MODIFYALL("Transfer-from Bin Code",'A1',TRUE);
          TransLine.MODIFYALL("Transfer-To Bin Code",'S-01-0001',TRUE);
          TransLine.GET(TransHeader."No.",20000);
          TransLine.VALIDATE("Transfer-To Bin Code",'S-01-0002');
          TransLine.MODIFY(TRUE);

          IF LastIteration = '1-19-3-30' THEN
            EXIT;

          ReleaseTransferOrder(TransHeader);

          IF LastIteration = '1-19-3-40' THEN
            EXIT;

          // 1-19-4

          VerifyPostCondition(UseCaseNo,TestCaseNo,4,LastILENo);

          IF LastIteration = '1-19-4-10' THEN
            EXIT;

          // 1-19-5

          CreateInvPutAwayPickBySrcFilt(10,TransHeader."No.");

          IF LastIteration = '1-19-5-10' THEN
            EXIT;

          // 1-19-6

          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '1-19-6-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '1-19-6-20' THEN
            EXIT;

          // 1-19-7

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,TRUE);

          IF LastIteration = '1-19-7-10' THEN
            EXIT;

          // 1-19-8

          VerifyPostCondition(UseCaseNo,TestCaseNo,8,LastILENo);

          IF LastIteration = '1-19-8-10' THEN
            EXIT;

          // 1-19-9

          InsertWhseActHeader(WhseActivHeader,4,'SILVER');
          CreateInvPutAway(WhseActivHeader);

          IF LastIteration = '1-19-9-10' THEN
            EXIT;

          // 1-19-10

          VerifyPostCondition(UseCaseNo,TestCaseNo,10,LastILENo);

          IF LastIteration = '1-19-10-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '1-19-10-20' THEN
            EXIT;

          // 1-19-11

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,TRUE);

          IF LastIteration = '1-19-11-10' THEN
            EXIT;

          // 1-19-12

          VerifyPostCondition(UseCaseNo,TestCaseNo,12,LastILENo);

          IF LastIteration = '1-19-12-10' THEN
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

