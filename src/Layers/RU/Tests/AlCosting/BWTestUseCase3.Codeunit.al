codeunit 103353 "BW Test Use Case 3"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 3");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103353,3,0,'',1);

        TestscriptMgt.ShowTestscriptResult;
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        GenPostSetup: Record "General Posting Setup";
        TestCase: Record Table103301;
        ResEntry: Record "Reservation Entry";
        UseCase: Record Table103300;
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
          12:
            PerformTestCase12;
          13:
            PerformTestCase13;
          15:
            PerformTestCase15;
          16:
            PerformTestCase16;
          17:
            PerformTestCase17;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-1-1

          SetGlobalPreconditions;

          Loc.GET('BLUE');
          Loc."Bin Mandatory" := TRUE;
          Loc.Modify();

          IF LastIteration = '3-1-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-1-1','A_TEST','','BLUE','',
            30,'PCS',17,0,'A1');

          IF LastIteration = '3-1-1-20' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-1-1-30' THEN
            EXIT;

          // 3-1-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'BLUE','TCS3-1-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_Test','','BLUE',10,'PCS',17,FALSE);
          ModifyPurchLine(PurchHeader,10000,'A1',10,10,0,0);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_Test','','BLUE',-3,'PCS',17,FALSE);
          ModifyPurchReturnLine(PurchHeader,20000,'NONEED');
          ModifyPurchLine(PurchHeader,20000,'A1',-3,-3,0,0);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_Test','','BLUE',-3,'PCS',17,FALSE);
          ModifyPurchReturnLine(PurchHeader,30000,'NONEED');
          ModifyPurchLine(PurchHeader,30000,'A1',-3,-3,0,0);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'A_Test','','BLUE',-1,'PCS',17,FALSE);
          ModifyPurchReturnLine(PurchHeader,40000,'NONEED');
          ModifyPurchLine(PurchHeader,40000,'A1',-1,-1,0,0);

          IF LastIteration = '3-1-2-10' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '3-1-2-20' THEN
            EXIT;

          PurchHeader.Invoice := TRUE;
          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '3-1-2-30' THEN
            EXIT;

          // 3-1-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-1-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ResMgmt: Codeunit "Reservation Management";
        AutoReserv: Boolean;
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-2-1

          SetGlobalPreconditions;

          IF LastIteration = '3-2-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-2-1','S_TEST','42','SILVER','',
            10,'PALLET',48,0,'S-02-0001');

          IF LastIteration = '3-2-1-20' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-2-1-30' THEN
            EXIT;

          // 3-2-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'30000',251101D);
          ModifyPurchCrMemoHeader(PurchHeader,251101D,'SILVER','TCS3-2-2');

          InsertPurchCrMemoLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'S_Test','42',31,'PCS',12,0);
          ModifyPurchReturnLine(PurchHeader,10000,'DAMAGED');
          ModifyPurchCrMemoLine(PurchHeader,10000,'S-02-0001',11,11);

          IF LastIteration = '3-2-2-10' THEN
            EXIT;

          // 3-2-3

          ResMgmt.SetPurchLine(PurchLine);
          ResMgmt.AutoReserve(AutoReserv,'',251101D,PurchLine.Quantity,PurchLine."Quantity (Base)");

          IF LastIteration = '3-2-3-10' THEN
            EXIT;

          // 3-2-4

          PurchHeader.Invoice := TRUE;
          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '3-2-4-10' THEN
            EXIT;

          // 3-2-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '3-2-5-10' THEN
            EXIT;

          // 3-2-6

          ModifyPurchCrMemoLine(PurchHeader,10000,'S-02-0001',2,2);

          IF LastIteration = '3-2-6-10' THEN
            EXIT;

          ModifyPurchCrMemoHeader(PurchHeader,0D,'','TCS3-2-6');
          PurchHeader.Invoice := TRUE;
          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '3-2-6-20' THEN
            EXIT;

          // 3-2-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '3-2-7-10' THEN
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
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-3-1

          SetGlobalPreconditions;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Purch. Credit Memo Account",'7130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '3-3-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-3-1','T_TEST','','SILVER','',
            2,'BOX',80,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-3-1','L_TEST','','SILVER','',
            1,'BOX',60,0,'S-02-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-3-1','A_TEST','12','SILVER','',
            10,'PCS',55,0,'S-01-0001');

          IF LastIteration = '3-3-1-20' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',10001,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10001,TRUE);
          InsertResEntry(ResEntry,'SILVER',10001,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',10001,TRUE);
          InsertResEntry(ResEntry,'SILVER',10002,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10002,TRUE);

          IF LastIteration = '3-3-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-3-1-40' THEN
            EXIT;

          // 3-3-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Credit Memo",'30000',251101D);
          ModifyPurchCrMemoHeader(PurchHeader,251101D,'SILVER','TCS3-3-2');

          InsertPurchCrMemoLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'T_Test','',2,'BOX',80,0);
          ModifyPurchCrMemoLine(PurchHeader,10000,'S-02-0001',2,2);
          InsertPurchCrMemoLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'L_Test','',1,'BOX',80,0);
          ModifyPurchCrMemoLine(PurchHeader,20000,'S-02-0002',1,1);
          InsertPurchCrMemoLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_Test','12',10,'PCS',55,0);
          ModifyPurchCrMemoLine(PurchHeader,30000,'S-01-0001',10,10);
          InsertPurchCrMemoLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::"Charge (Item)",'INSURANCE','',3,'',30,0);

          IF LastIteration = '3-3-2-10' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'T_TEST','','SN01','',1,1,39,3,PurchHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'T_TEST','','SN02','',1,1,39,3,PurchHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'SILVER',20000,3,251101D,'L_TEST','','','LN01',1,1,39,3,PurchHeader."No.",'',20000,TRUE);

          IF LastIteration = '3-3-2-20' THEN
            EXIT;

          ItemChargeAssgntPurch.Init();
          ItemChargeAssgntPurch."Document Type" := PurchLine."Document Type";
          ItemChargeAssgntPurch."Document No." := PurchLine."Document No.";
          ItemChargeAssgntPurch."Document Line No." := 40000;
          ItemChargeAssgntPurch."Item Charge No." := 'INSURANCE';
          ItemChargeAssignt.CreateDocChargeAssgnt(ItemChargeAssgntPurch,PurchLine."Receipt No.");
          PurchLine.UpdateItemChargeAssgnt();
          ItemChargeAssignt.AssignItemCharges(PurchLine,3,90,format(1));

          IF LastIteration = '3-3-2-30' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '3-3-2-40' THEN
            EXIT;

          PurchHeader.Invoice := TRUE;
          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '3-3-2-50' THEN
            EXIT;

          // 3-3-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-3-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-4-1

          SetGlobalPreconditions;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Sales Account",'6130');
            GenPostSetup.Modify();
          END;

          Loc.GET('SILVER');
          Loc."Require Shipment" := TRUE;
          Loc.Modify();

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-4-1','C_TEST','31','SILVER','',7,'PCS',16,0,'S-01-0001');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-4-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-4-1','C_TEST','31','SILVER','',7,'PCS',16,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-4-1','L_TEST','','SILVER','',2,'BOX',44,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-4-1','T_TEST','','SILVER','',1,'BOX',45,0,'S-02-0003');

          IF LastIteration = '3-4-1-20' THEN
            EXIT;

          ItemJnlLineNo := 0;

          InsertResEntry(ResEntry,'SILVER',10002,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10002,TRUE);
          InsertResEntry(ResEntry,'SILVER',10002,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10002,TRUE);
          InsertResEntry(ResEntry,'SILVER',10003,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10003,TRUE);

          IF LastIteration = '3-4-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-4-1-40' THEN
            EXIT;

          // 3-4-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'L_Test','',2,'BOX',44,'SILVER','');
          ModifySalesLine(SalesHeader,10000,'S-02-0001',2,2,0,0,FALSE);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'T_Test','',1,'BOX',45,'SILVER','');
          ModifySalesLine(SalesHeader,20000,'S-02-0003',1,1,0,0,FALSE);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'C_Test','31',5,'PCS',16,'SILVER','');
          ModifySalesLine(SalesHeader,30000,'S-01-0001',5,5,0,0,FALSE);
          InsertSalesLine(SalesLine,SalesHeader,40000,SalesLine.Type::"Charge (Item)",'UPS','',1,'',25,'SILVER','');

          IF LastIteration = '3-4-2-10' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'L_TEST','','','LN01',1,1,37,1,SalesHeader."No.",'',10000,TRUE);
          // Bug 254185 - set item tracking only for one PCS as one only will be shipped
          // InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'L_TEST','','','LN02',1,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'SILVER',20000,3,251101D,'T_TEST','','SN01','',1,1,37,1,SalesHeader."No.",'',20000,TRUE);

          IF LastIteration = '3-4-2-20' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '3-4-2-30' THEN
            EXIT;

          InsertWhseShptHeader(WhseShptHeader,'SILVER','','');

          IF LastIteration = '3-4-2-40' THEN
            EXIT;

          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'SILVER');

          IF LastIteration = '3-4-2-50' THEN
            EXIT;

          VerifyPostCondition(UseCaseNo,TestCaseNo,2,LastILENo);

          IF LastIteration = '3-4-2-60' THEN
            EXIT;

          WhseShptLine.GET(WhseShptHeader."No.",10000);
          WhseShptLine.VALIDATE("Qty. to Ship",1);
          WhseShptLine.MODIFY(TRUE);
          PostWhseShipment(WhseShptLine,TRUE);

          IF LastIteration = '3-4-2-70' THEN
            EXIT;

          // 3-4-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-4-3-10' THEN
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
          // 3-5-1

          SetGlobalPreconditions;

          IF LastIteration = '3-5-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-5-1','A_TEST','','SILVER','',29,'PCS',29,0,'S-01-0001');

          IF LastIteration = '3-5-1-20' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-5-1-30' THEN
            EXIT;

          // 3-5-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'A_Test','',10,'PCS',29,'SILVER','');
          ModifySalesCrMemoLine(SalesHeader,10000,'S-01-0001',10,10,0,0,0);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'A_Test','',-8,'PCS',29,'SILVER','');
          ModifySalesCrMemoLine(SalesHeader,20000,'S-01-0001',-8,-8,0,0,0);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'A_Test','',-1,'PCS',29,'SILVER','');
          ModifySalesCrMemoLine(SalesHeader,30000,'S-01-0001',-1,-1,0,0,0);

          IF LastIteration = '3-5-2-10' THEN
            EXIT;

          SalesHeader.Invoice := TRUE;
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '3-5-2-20' THEN
            EXIT;

          // 3-5-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-5-3-10' THEN
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
        ItemChargeAssignt: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-6-1

          SetGlobalPreconditions;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Sales Credit Memo Account",'6130');
            GenPostSetup.Modify();
          END;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-4-1','C_TEST','31','SILVER','',7,'PCS',16,0,'S-01-0001');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-6-1-10' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-6-1','C_TEST','32','SILVER','',20,'PCS',21,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-6-1','L_TEST','','SILVER','',2,'BOX',40,0,'S-01-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-6-1','T_TEST','','SILVER','',1,'BOX',43,0,'S-01-0003');

          IF LastIteration = '3-6-1-20' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',10002,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10002,TRUE);
          InsertResEntry(ResEntry,'SILVER',10002,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10002,TRUE);
          InsertResEntry(ResEntry,'SILVER',10003,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10003,TRUE);

          IF LastIteration = '3-6-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-6-1-40' THEN
            EXIT;

          // 3-6-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Credit Memo",'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'T_Test','',-1,'BOX',43,'SILVER','');
          ModifySalesCrMemoLine(SalesHeader,10000,'S-01-0003',-1,-1,0,0,0);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'L_Test','',-2,'BOX',40,'SILVER','');
          ModifySalesCrMemoLine(SalesHeader,20000,'S-01-0002',-2,-2,0,0,0);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'C_Test','32',-3,'',30,'SILVER','');
          InsertSalesLine(
            SalesLine,SalesHeader,40000,SalesLine.Type::"Charge (Item)",'GPS','',3,'',78.78,'SILVER','');

          IF LastIteration = '3-6-2-10' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'T_TEST','','SN01','',-1,-1,37,3,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'SILVER',20000,3,251101D,'L_TEST','','','LN01',-1,-1,37,3,SalesHeader."No.",'',20000,TRUE);
          InsertResEntry(ResEntry,'SILVER',20000,3,251101D,'L_TEST','','','LN02',-1,-1,37,3,SalesHeader."No.",'',20000,TRUE);

          IF LastIteration = '3-6-2-20' THEN
            EXIT;

          ItemChargeAssgntSales.Init();
          ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
          ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
          ItemChargeAssgntSales."Document Line No." := 40000;
          ItemChargeAssgntSales."Item Charge No." := 'GPS';
          ItemChargeAssignt.CreateDocChargeAssgn(ItemChargeAssgntSales,SalesLine."Shipment No.");
          SalesLine.UpdateItemChargeAssgnt();
          ItemChargeAssignt.AssignItemCharges(SalesLine, 3, 236.34, Format(1));

          IF LastIteration = '3-6-2-30' THEN
            EXIT;

          SalesHeader.Invoice := TRUE;
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '3-6-2-30' THEN
            EXIT;

          // 3-6-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-6-3-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-7-1

          SetGlobalPreconditions;

          IF LastIteration = '3-7-1-10' THEN
            EXIT;

          // 3-7-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-7-2','A_TEST','','SILVER','',52,'PCS',14,0,'S-01-0001');

          IF LastIteration = '3-7-2-10' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-7-2-20' THEN
            EXIT;

          // 3-7-3

          InsertTransferHeader(TransHeader,'SILVER','RED','OWN LOG.',251101D);

          InsertTransferLine(TransLine,TransHeader."No.",10000,'A_TEST','','PCS',12,0,12);
          ModifyTransferLine(TransHeader."No.",10000,'S-01-0001','',12,0);
          InsertTransferLine(TransLine,TransHeader."No.",20000,'A_TEST','','PCS',20,0,20);
          ModifyTransferLine(TransHeader."No.",20000,'S-01-0001','',20,0);
          InsertTransferLine(TransLine,TransHeader."No.",30000,'A_TEST','','PCS',18,0,18);
          ModifyTransferLine(TransHeader."No.",30000,'S-01-0001','',18,0);

          IF LastIteration = '3-7-3-10' THEN
            EXIT;

          ReleaseTransferOrder(TransHeader);

          IF LastIteration = '3-7-3-20' THEN
            EXIT;

          PostTransferOrder(TransHeader,TRUE);

          IF LastIteration = '3-7-3-30' THEN
            EXIT;

          // 3-7-4

          VerifyPostCondition(UseCaseNo,TestCaseNo,4,LastILENo);

          IF LastIteration = '3-7-4-10' THEN
            EXIT;

          // 3-7-5

          ModifyTransferLine(TransHeader."No.",10000,'S-01-0001','',0,12);
          ModifyTransferLine(TransHeader."No.",20000,'S-01-0001','',0,20);
          ModifyTransferLine(TransHeader."No.",30000,'S-01-0001','',0,18);

          PostTransferOrder(TransHeader,FALSE);

          IF LastIteration = '3-7-5-10' THEN
            EXIT;

          // 3-7-6

          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '3-7-6-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase12()
    var
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-12-1

          SetGlobalPreconditions;

          IF LastIteration = '3-12-1-10' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Pick" := TRUE;
          Loc."Require Put-away" := TRUE;
          Loc.Modify();

          IF LastIteration = '3-12-1-20' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-12-1','A_TEST','','SILVER','',
            30,'PCS',17,0,'S-01-0001');

          IF LastIteration = '3-12-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-12-1-40' THEN
            EXIT;

          // 3-12-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS3-12-2',FALSE);

          IF LastIteration = '3-12-2-10' THEN
            EXIT;

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_Test','','SILVER',10,'PCS',17,FALSE);
          ModifyPurchLine(PurchHeader,10000,'S-01-0001',10,10,0,0);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'A_Test','','SILVER',-3,'PCS',17,FALSE);
          ModifyPurchLine(PurchHeader,20000,'S-01-0001',-3,-3,0,0);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'A_Test','','SILVER',-3,'PCS',17,FALSE);
          ModifyPurchLine(PurchHeader,30000,'S-01-0001',-3,-3,0,0);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'A_Test','','SILVER',-1,'PCS',17,FALSE);
          ModifyPurchLine(PurchHeader,40000,'S-01-0001',-1,-1,0,0);

          IF LastIteration = '3-12-2-20' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '3-12-2-30' THEN
            EXIT;

          InsertWhseActHeader(WhseActivHeader,5,'SILVER');
          CreateInvPick(WhseActivHeader);

          IF LastIteration = '3-12-2-40' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '3-12-2-50' THEN
            EXIT;

          // 3-12-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-12-3-10' THEN
            EXIT;

          // 3-12-4

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '3-12-4-10' THEN
            EXIT;

          InsertWhseActHeader(WhseActivHeader,4,'SILVER');
          CreateInvPutAway(WhseActivHeader);

          IF LastIteration = '3-12-4-20' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '3-12-4-30' THEN
            EXIT;

          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '3-12-4-40' THEN
            EXIT;

          PurchHeader.GET(PurchHeader."Document Type",PurchHeader."No.");
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '3-12-4-50' THEN
            EXIT;

          // 3-12-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '3-12-5-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase13()
    var
        Loc: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        ResMgmt: Codeunit "Reservation Management";
        AutoReserv: Boolean;
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-13-1

          SetGlobalPreconditions;

          IF LastIteration = '3-13-1-10' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Pick" := TRUE;
          Loc.Modify();

          IF LastIteration = '3-13-1-20' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-13-1','S_TEST','42','SILVER','',
            10,'PALLET',48,0,'S-02-0001');

          IF LastIteration = '3-13-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-13-1-40' THEN
            EXIT;

          // 3-13-2

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'30000',251101D);
          ModifyPurchCrMemoHeader(PurchHeader,251101D,'SILVER','TCS3-13-2');

          IF LastIteration = '3-13-2-10' THEN
            EXIT;

          InsertPurchCrMemoLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'S_Test','42',31,'PCS',12,0);
          ModifyPurchReturnLine(PurchHeader,10000,'DAMAGED');
          ModifyPurchCrMemoLine(PurchHeader,10000,'S-02-0001',11,11);

          IF LastIteration = '3-13-2-20' THEN
            EXIT;

          // 3-13-3

          ResMgmt.SetPurchLine(PurchLine);
          ResMgmt.AutoReserve(AutoReserv,'',251101D,PurchLine.Quantity,PurchLine."Quantity (Base)");

          IF LastIteration = '3-13-3-10' THEN
            EXIT;

          // 3-13-4

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '3-13-4-10' THEN
            EXIT;

          // 3-13-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '3-13-5-10' THEN
            EXIT;

          // 3-13-6

          CreateInvPutAwayPickBySrcFilt(8,PurchHeader."No.");

          IF LastIteration = '3-13-6-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '3-13-6-20' THEN
            EXIT;

          // 3-13-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '3-13-7-10' THEN
            EXIT;

          // 3-13-8

          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '3-13-8-10' THEN
            EXIT;

          // 3-13-9

          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo);

          IF LastIteration = '3-13-9-10' THEN
            EXIT;

          // 3-13-10

          ModifyPurchHeader(PurchHeader,0D,'','',TRUE);

          IF LastIteration = '3-13-10-10' THEN
            EXIT;

          ModifyPurchCrMemoHeader(PurchHeader,0D,'','TCS3-13-10');
          ModifyPurchCrMemoLine(PurchHeader,10000,'S-02-0001',2,2);

          IF LastIteration = '3-13-10-20' THEN
            EXIT;

          // 3-13-11

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '3-13-11-10' THEN
            EXIT;

          // 3-13-12

          VerifyPostCondition(UseCaseNo,TestCaseNo,12,LastILENo);

          IF LastIteration = '3-13-12-10' THEN
            EXIT;

          // 3-13-13

          InsertWhseActHeader(WhseActivHeader,5,'SILVER');
          CreateInvPick(WhseActivHeader);

          IF LastIteration = '3-13-13-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '3-13-13-20' THEN
            EXIT;

          // 3-13-14

          VerifyPostCondition(UseCaseNo,TestCaseNo,14,LastILENo);

          IF LastIteration = '3-12-14-10' THEN
            EXIT;

          // 3-13-15

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '1-13-15-10' THEN
            EXIT;

          // 3-13-16

          VerifyPostCondition(UseCaseNo,TestCaseNo,16,LastILENo);

          IF LastIteration = '3-12-16-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase15()
    var
        Loc: Record Location;
        GenPostSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-15-1

          SetGlobalPreconditions;

          IF LastIteration = '3-15-1-10' THEN
            EXIT;

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Sales Account",'6130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '3-15-1-20' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Pick" := TRUE;
          Loc.Modify();

          ItemJnlLineNo := 1000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-13-1','S_TEST','42','SILVER','',
            10,'PALLET',48,0,'S-02-0001');

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-15-1-30' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-15-1','C_TEST','31','SILVER','',7,'PCS',16,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-15-1','L_TEST','','SILVER','',2,'BOX',44,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-15-1','T_TEST','','SILVER','',1,'BOX',45,0,'S-02-0003');

          IF LastIteration = '3-15-1-40' THEN
            EXIT;

          ItemJnlLineNo := 0;

          InsertResEntry(ResEntry,'SILVER',10002,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10002,TRUE);
          InsertResEntry(ResEntry,'SILVER',10002,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10002,TRUE);

          IF LastIteration = '3-15-1-50' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',10003,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10003,TRUE);

          IF LastIteration = '3-15-1-60' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-15-1-70' THEN
            EXIT;

          // 3-15-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '3-15-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'L_Test','',2,'BOX',44,'SILVER','');
          ModifySalesLine(SalesHeader,10000,'S-02-0001',2,2,0,0,FALSE);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'T_Test','',1,'BOX',45,'SILVER','');
          ModifySalesLine(SalesHeader,20000,'S-02-0003',1,1,0,0,FALSE);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'C_Test','31',5,'PCS',16,'SILVER','');
          ModifySalesLine(SalesHeader,30000,'S-01-0001',5,5,0,0,FALSE);
          InsertSalesLine(SalesLine,SalesHeader,40000,SalesLine.Type::"Charge (Item)",'UPS','',1,'',25,'','');

          IF LastIteration = '3-15-2-20' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'L_TEST','','','LN01',1,1,37,1,SalesHeader."No.",'',10000,TRUE);
          InsertResEntry(ResEntry,'SILVER',10000,3,251101D,'L_TEST','','','LN02',1,1,37,1,SalesHeader."No.",'',10000,TRUE);

          IF LastIteration = '3-15-2-30' THEN
            EXIT;

          InsertResEntry(ResEntry,'SILVER',20000,3,251101D,'T_TEST','','SN01','',1,1,37,1,SalesHeader."No.",'',20000,TRUE);

          IF LastIteration = '3-15-2-40' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '3-15-2-50' THEN
            EXIT;

          // 3-15-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-15-3-10' THEN
            EXIT;

          // 3-15-4

          CreateInvPutAwayPickBySrcFilt(1,SalesHeader."No.");

          IF LastIteration = '3-15-4-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;
          WhseActivLine.FindFirst();

          IF LastIteration = '3-15-4-20' THEN
            EXIT;

          // 3-15-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '3-15-5-10' THEN
            EXIT;

          // 3-15-6

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '3-15-6-10' THEN
            EXIT;

          // 3-15-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '3-15-7-10' THEN
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
          // 3-16-1

          SetGlobalPreconditions;

          IF LastIteration = '3-16-1-10' THEN
            EXIT;

          Loc.GET('SILVER');
          Loc."Require Pick" := TRUE;
          Loc.Modify();

          IF LastIteration = '3-16-1-20' THEN
            EXIT;

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS3-16-1','A_TEST','','SILVER','',29,'PCS',29,0,'S-01-0001');

          IF LastIteration = '3-16-1-30' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-16-1-40' THEN
            EXIT;

          // 3-16-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          IF LastIteration = '3-16-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'A_Test','',10,'PCS',29,'SILVER','WRONG');
          ModifySalesCrMemoLine(SalesHeader,10000,'S-01-0001',10,10,0,0,0);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'A_Test','',-8,'PCS',29,'SILVER','WRONG');
          ModifySalesCrMemoLine(SalesHeader,20000,'S-01-0001',-8,-8,0,0,0);
          InsertSalesLine(SalesLine,SalesHeader,30000,SalesLine.Type::Item,'A_Test','',-1,'PCS',29,'SILVER','DAMAGED');
          ModifySalesCrMemoLine(SalesHeader,30000,'S-01-0001',-1,-1,0,0,0);

          IF LastIteration = '3-16-2-20' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '3-16-2-30' THEN
            EXIT;

          // 3-16-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '3-16-3-10' THEN
            EXIT;

          // 3-16-4

          InsertWhseActHeader(WhseActivHeader,5,'SILVER');
          CreateInvPick(WhseActivHeader);

          IF LastIteration = '3-16-4-10' THEN
            EXIT;

          WITH WhseActivLine DO BEGIN
            FindFirst();
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '3-16-4-20' THEN
            EXIT;

          // 3-16-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '3-16-5-10' THEN
            EXIT;

          // 3-16-6

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '3-16-6-10' THEN
            EXIT;

          SalesHeader.FIND('-');
          SalesHeader.Invoice := TRUE;
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '3-16-6-20' THEN
            EXIT;

          // 3-16-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '3-16-7-10' THEN
            EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase17()
    var
        Loc: Record Location;
        BinCon: Record "Bin Content";
        BinTmp: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ProdOrder: Record "Production Order";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        CalcConsumption: Report "Calc. Consumption";
        CreateRes: Codeunit "Create Reserv. Entry";
        WMSManagement: Codeunit "WMS Management";
        WMSTestscriptManagement: Codeunit Codeunit103303;
        WMSGlobalPrecondition: Codeunit Codeunit103301;
        LNCode: Code[20];
        SNCode: Code[20];
        i: Integer;
        NextLineNo: Integer;
        Counter: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
          // 3-17-1

          SetGlobalPreconditions;
          WITH WMSGlobalPrecondition DO BEGIN
            ProdBOMHdr.GET('E_PROD');
            ProdBOMHdr.Status := ProdBOMHdr.Status::"Under Development";
            ProdBOMHdr.Modify();
            ProdBOMLine.SETRANGE("Production BOM No.",'E_PROD');
            IF ProdBOMLine.FIND('-') THEN
              REPEAT
                ProdBOMLine.DELETE
              UNTIL ProdBOMLine.Next() = 0;
            InsertProdBOMHdr('E_PROD','Product E','PCS');
            InsertProdBOMLine('E_PROD',10000,ProdBOMLine.Type::Item,'D_PROD','',1);
            InsertProdBOMLine('E_PROD',20000,ProdBOMLine.Type::Item,'A_TEST','12',13);
            InsertProdBOMLine('E_PROD',30000,ProdBOMLine.Type::Item,'B_TEST','',12);
            InsertProdBOMLine('E_PROD',40000,ProdBOMLine.Type::Item,'T_TEST','',2);
            InsertProdBOMLine('E_PROD',50000,ProdBOMLine.Type::Item,'L_TEST','',1);
            ModifyProdBOMHdr('E_PROD',ProdBOMHdr.Status::Certified);
          END;

          IF LastIteration = '3-17-1-10' THEN
            EXIT;

          BinCon.Init();
          BinCon."Location Code" := 'SILVER';
          BinCon."Bin Code" := 'S-07-0001';
          BinCon.Default := TRUE;
          BinCon."Item No." := 'E_PROD';
          BinCon.VALIDATE("Unit of Measure Code",'PCS');
          BinCon.INSERT(TRUE);

          Loc.GET('SILVER');
          Loc."Require Receive" := TRUE;
          Loc."Require Shipment" := TRUE;
          Loc."Require Pick" := TRUE;
          Loc."Require Put-away" := TRUE;
          Loc.Modify();

          IF GenPostSetup.GET('NATIONAL','MISC') THEN BEGIN
            GenPostSetup.VALIDATE("Sales Account",'6130');
            GenPostSetup.VALIDATE("Purch. Account",'7130');
            GenPostSetup.Modify();
          END;

          IF LastIteration = '3-17-1-20' THEN
            EXIT;

          // 3-17-2

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,0D,'SILVER',TRUE,FALSE);

          IF LastIteration = '3-17-2-10' THEN
            EXIT;

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'T_TEST','',2,'BOX',65.43,'SILVER','');
          SalesLine."Planned Delivery Date" := 301101D;
          SalesLine.MODIFY(TRUE);
          InsertSalesLine(SalesLine,SalesHeader,20000,SalesLine.Type::Item,'E_PROD','',3,'PCS',321.09,'SILVER','');
          SalesLine."Planned Delivery Date" := 301101D;
          SalesLine.MODIFY(TRUE);

          IF LastIteration = '3-17-2-20' THEN
            EXIT;

          ReleaseSalesDocument(SalesHeader);

          IF LastIteration = '3-17-2-30' THEN
            EXIT;

          InsertWhseShptHeader(WhseShptHeader,'SILVER','','S-07-0001');

          IF LastIteration = '3-17-2-40' THEN
            EXIT;

          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'SILVER');

          IF LastIteration = '3-17-2-50' THEN
            EXIT;

          // 3-17-3

          InsertProdOrder(ProdOrder,3,0,'D_PROD',4,'SILVER');
          ProdOrder.VALIDATE("Bin Code",'S-04-0001');
          ProdOrder.MODIFY(TRUE);

          IF LastIteration = '3-17-3-10' THEN
            EXIT;

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          IF LastIteration = '3-17-3-20' THEN
            EXIT;

          // 3-17-4

          InsertProdOrder(ProdOrder,3,0,'E_PROD',4,'SILVER');

          IF LastIteration = '3-17-4-10' THEN
            EXIT;

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          IF LastIteration = '3-17-4-20' THEN
            EXIT;

          // 3-17-5

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'SILVER','TCS3-17-5',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'A_Test','12','SILVER',60,'PCS',11.99,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'B_Test','','SILVER',50,'PCS',22.88,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'C_Test','32','SILVER',10,'PCS',33.77,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'L_Test','','SILVER',5,'BOX',44.66,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'T_Test','','SILVER',10,'BOX',55.55,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,60000,PurchLine.Type::Item,'A_Test','','BLUE',10,'PCS',9.99,FALSE);

          IF LastIteration = '3-17-5-10' THEN
            EXIT;

          ReleasePurchDocument(PurchHeader);

          IF LastIteration = '3-17-5-20' THEN
            EXIT;

          InsertWhseRcptHeader(WhseRcptHeader,'SILVER','','S-01-0001');

          IF LastIteration = '3-17-5-30' THEN
            EXIT;

          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'SILVER');

          IF LastIteration = '3-17-5-40' THEN
            EXIT;

          // 3-17-6

          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",10000,'','S-03-0001',60);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",20000,'','S-03-0002',50);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",30000,'','S-04-0001',10);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",40000,'','S-01-0001',5);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",50000,'','S-01-0001',10);

          IF LastIteration = '3-17-6-10' THEN
            EXIT;

          // 3-17-7

          LNCode := 'LN00';
          SNCode := 'SN00';
          FOR i := 1 TO 10 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,50000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          END;
          FOR i := 1 TO 2 DO BEGIN
            LNCode := INCSTR(LNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,1,1,'',LNCode,'');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          END;
          LNCode := INCSTR(LNCode);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,3,1,3,'',LNCode,'');
          CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);

          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '3-17-7-10' THEN
            EXIT;

          // 3-17-8

          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '3-17-8-10' THEN
            EXIT;

          PurchHeader.GET(PurchHeader."Document Type",PurchHeader."No.");
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '3-17-8-20' THEN
            EXIT;

          // 3-17-9

          InsertTransferHeader(TransHeader,'BLUE','SILVER','OWN LOG.',251101D);

          InsertTransferLine(TransLine,TransHeader."No.",10000,'A_TEST','','PCS',9,0,9);
          ModifyTransferLine(TransHeader."No.",10000,'','S-02-0001',9,0);

          IF LastIteration = '3-17-9-10' THEN
            EXIT;

          ReleaseTransferOrder(TransHeader);

          IF LastIteration = '3-17-9-20' THEN
            EXIT;

          PostTransferOrder(TransHeader,TRUE);

          IF LastIteration = '3-17-9-30' THEN
            EXIT;

          CreateWhseRcptFromTrans(TransHeader,WhseRcptHeader);

          IF LastIteration = '3-17-9-40' THEN
            EXIT;

          CLEAR(WhseRcptLine);
          WhseRcptLine.FIND('-');
          PostWhseReceipt(WhseRcptLine);

          IF LastIteration = '3-17-9-50' THEN
            EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '3-17-9-60' THEN
            EXIT;

          // 3-17-10

          ProdOrder.Reset();
          ProdOrder.SETRANGE("Source No.",'D_PROD');
          ProdOrder.FIND('-');
          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Item No.",'C_TEST');
          ProdOrderComp.FIND('-');
          ProdOrderComp.VALIDATE("Bin Code",'S-04-0001');
          // pointing the place bin code to a bin other than that at which the items are already found
          ProdOrderComp.VALIDATE("Bin Code",INCSTR(ProdOrderComp."Bin Code"));
          ProdOrderComp.MODIFY(TRUE);
          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.FIND('+');
          ProdOrderComp2 := ProdOrderComp;
          NextLineNo := ProdOrderComp2."Line No." + 10000;
          ProdOrderComp2."Line No." := NextLineNo;
          ProdOrderComp2.VALIDATE("Location Code",'SILVER');
          ProdOrderComp2.VALIDATE("Quantity per",2);
          ProdOrderComp2.VALIDATE("Due Date",WorkDate() - 1);
          ProdOrderComp2.VALIDATE("Item No.",'A_TEST');
          // pointing the place bin code to a bin other than that at which the items are already found
          ProdOrderComp2.VALIDATE("Bin Code",INCSTR(ProdOrderComp2."Bin Code"));
          ProdOrderComp2.Insert();

          IF LastIteration = '3-17-10-10' THEN
            EXIT;

          CreatePickFromWhseSource.SetProdOrder(ProdOrder);
          CreatePickFromWhseSource.SetHideValidationDialog(TRUE);
          CreatePickFromWhseSource.USEREQUESTPAGE(FALSE);
          CreatePickFromWhseSource.RunModal();
          CLEAR(CreatePickFromWhseSource);

          IF LastIteration = '3-17-10-20' THEN
            EXIT;

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN
            FIND('-');
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '3-17-10-30' THEN
            EXIT;

          PostWhseActivity(WhseActivLine);

          IF LastIteration = '3-17-10-40' THEN
            EXIT;

          // 3-17-11

          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          IF LastIteration = '3-17-11-10' THEN
            EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-17-11-20' THEN
            EXIT;

          // 3-17-12

          ProdOrder.Reset();
          ProdOrder.FIND('-');
          WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine,'Output','DEFAULT',ProdOrder."No.");

          IF LastIteration = '3-17-12-10' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-17-12-20' THEN
            EXIT;

          // 3-17-13

          ProdOrder.Reset();
          ProdOrder.SETRANGE("Source No.",'E_PROD');
          ProdOrder.FIND('-');
          WITH ProdOrderComp DO BEGIN
            Reset();
            SETRANGE("Prod. Order No.",ProdOrder."No.");
            FIND('-');
            REPEAT
              WMSManagement.GetDefaultBin("Item No.","Variant Code","Location Code","Bin Code");
              // pointing the place bin code to a bin other than that at which the items are already found
              GetDifferentBin(BinTmp,"Bin Code");
              VALIDATE("Bin Code",BinTmp.Code);
              MODIFY(TRUE);
            until Next() = 0;
          END;
          CLEAR(CreatePickFromWhseSource);
          CreatePickFromWhseSource.SetProdOrder(ProdOrder);
          CreatePickFromWhseSource.SetHideValidationDialog(TRUE);
          CreatePickFromWhseSource.USEREQUESTPAGE(FALSE);
          CreatePickFromWhseSource.RunModal();
          CLEAR(CreatePickFromWhseSource);

          IF LastIteration = '3-17-13-10' THEN
            EXIT;

          CLEAR(WhseActivLine);
          WITH WhseActivLine DO BEGIN
            SETRANGE("Source No.",ProdOrder."No.");
            SETRANGE("Item No.",'L_TEST');
            FindSet();
            VALIDATE("Qty. to Handle",3);
            VALIDATE("Lot No.",'LN03');
            MODIFY(TRUE);
            SplitLine(WhseActivLine);
            FIND('>');
            VALIDATE("Lot No.",'LN01');
            MODIFY(TRUE);
            FIND('>');
            VALIDATE("Qty. to Handle",3);
            VALIDATE("Lot No.",'LN03');
            MODIFY(TRUE);
            SplitLine(WhseActivLine);
            FIND('>');
            VALIDATE("Lot No.",'LN01');
            MODIFY(TRUE);
            SETRANGE("Lot No.");
            SETRANGE("Item No.",'T_TEST');
            FindSet();
            SNCode := 'SN01';
            Counter := 0;
            REPEAT
              Counter := Counter + 1;
              VALIDATE("Serial No.",SNCode);
              MODIFY(TRUE);
              IF Counter > 1 THEN BEGIN
                SNCode := INCSTR(SNCode);
                Counter := 0;
              END;
            until Next() = 0;
          END;

          IF LastIteration = '3-17-13-20' THEN
            EXIT;

          WhseActivLine.Reset();
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '3-17-13-30' THEN
            EXIT;

          // 3-17-14

          CLEAR(CalcConsumption);
          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          IF LastIteration = '3-17-14-10' THEN
            EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-17-14-20' THEN
            EXIT;

          // 3-17-15

          ProdOrder.Reset();
          ProdOrder.FIND('+');
          WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine,'Output','DEFAULT',ProdOrder."No.");

          IF LastIteration = '3-17-15-10' THEN
            EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '3-17-15-20' THEN
            EXIT;

          // 3-17-16

          WhseShptHeader.FIND('-');
          CreatePickFromWhseShipment(WhseShptHeader);

          IF LastIteration = '3-17-16-10' THEN
            EXIT;

          Counter := 0;
          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Item No.",'T_TEST');
          WhseActivLine.FIND('-');
          SNCode := 'SN09';
          REPEAT
            Counter := Counter + 1;
            WhseActivLine.VALIDATE("Serial No.",SNCode);
            WhseActivLine.MODIFY(TRUE);
            IF Counter > 1 THEN BEGIN
              SNCode := INCSTR(SNCode);
              Counter := 0;
            END;
          UNTIL WhseActivLine.Next() = 0;

          IF LastIteration = '3-17-16-20' THEN
            EXIT;

          // 3-17-17

          WhseActivLine.Reset();
          PostWhseActivity(WhseActivLine);

          IF LastIteration = '3-17-17-10' THEN
            EXIT;

          WhseShptLine.FindFirst();
          PostWhseShipment(WhseShptLine,TRUE);

          IF LastIteration = '3-17-17-20' THEN
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

    [Scope('OnPrem')]
    procedure GetDifferentBin(var Bin: Record Bin;BinCode: Code[10])
    begin
        Bin.SETFILTER(Code,'>%1',BinCode);
        Bin.FindSet();
        Bin.Next();
    end;
}

