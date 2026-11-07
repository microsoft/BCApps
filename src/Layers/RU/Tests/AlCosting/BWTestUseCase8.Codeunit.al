codeunit 103358 "BW Test Use Case 8"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"BW Test Use Case 8");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103358,8,0,'',1);

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
          1: PerformTestCase1;
          2: PerformTestCase2;
          3: PerformTestCase3;
          7: PerformTestCase7;
          8: PerformTestCase8;
          9: PerformTestCase9;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        EntrySum: Record "Entry Summary";
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        CreateRes: Codeunit "Create Reserv. Entry";
        ResMgmt: Codeunit "Reservation Management";
        ProdOrderStatMgmt: Codeunit "Prod. Order Status Management";
        ProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        WITH TestScriptMgmt DO BEGIN
        // 8-1-1

          SetGlobalPreconditions;
          ModifyProdBom;

          IF LastIteration = '8-1-1-10' THEN EXIT;

        // 8-1-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-1-2','A_TEST','12','SILVER','',
            39,'PCS',10,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-1-2','B_TEST','','SILVER','',
            25,'PCS',11.5,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-1-2','D_PROD','','SILVER','',
            18,'PCS',16.25,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-1-2','E_PROD','','SILVER','',
            5,'PCS',111.11,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-1-2','L_TEST','','SILVER','',
            2,'BOX',44.4,0,'S-02-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-1-2','T_TEST','','SILVER','',
            4,'BOX',45,0,'S-02-0003');

          IF LastIteration = '8-1-2-10' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);
          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN03','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN04','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);

          IF LastIteration = '8-1-2-20' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-1-2-30' THEN EXIT;

        // 8-1-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '8-1-3-10' THEN EXIT;

        // 8-1-4

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'E_PROD','',2,'PCS',123.45,'SILVER','');
          ModifySalesLine(SalesHeader,10000,'S-03-0001',2,2,0,0,FALSE);

          IF LastIteration = '8-1-4-10' THEN EXIT;

          ProdOrderFromSale.SetHideValidationDialog(TRUE);
          ProdOrderFromSale.CreateProductionOrder(SalesLine,0,0);

          IF LastIteration = '8-1-4-20' THEN EXIT;

        // 8-1-5

          ProdOrder.FIND('-');
          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,3,SalesHeader."Posting Date",FALSE);

          Commit();

          IF LastIteration = '8-1-5-10' THEN EXIT;

          ProdOrderLine.FIND('-');
          ProdOrderLine.VALIDATE(Quantity,1);
          ProdOrderLine.VALIDATE("Ending Time");
          ProdOrderLine.Modify();

          IF LastIteration = '8-1-5-20' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrderLine."Prod. Order No.");
          ProdOrderComp.SETRANGE("Prod. Order Line No.",ProdOrderLine."Line No.");
          ProdOrderComp.SETRANGE("Item No.",'T_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrderLine."Prod. Order No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrderLine."Prod. Order No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN04','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          ProdOrderComp.SETRANGE("Item No.",'L_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrderLine."Prod. Order No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'','LN02','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-1-5-30' THEN EXIT;

          EntrySum.Init();
          EntrySum."Entry No." := 1;
          EntrySum."Table ID" := DATABASE::"Item Ledger Entry";
          EntrySum."Summary Type" := 'Item Ledger Entry';
          EntrySum."Total Quantity" := 1;
          ResMgmt.SetReservSource(ProdOrderComp);
          ResMgmt.SetSerialLotNo('','LN02','');
          ResMgmt.SetItemTrackingHandling(2);
          ResMgmt.AutoReserveOneLine(EntrySum."Entry No.",EntrySum."Total Quantity",EntrySum."Total Quantity",'',251101D);

          IF LastIteration = '8-1-5-40' THEN EXIT;

        // 8-1-6

          ProdOrder.FIND('-');
          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          IF LastIteration = '8-1-6-10' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-1-6-20' THEN EXIT;

        // 8-1-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '8-1-7-10' THEN EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        ProdOrderStatMgmt: Codeunit "Prod. Order Status Management";
        CreateRes: Codeunit "Create Reserv. Entry";
        ResMgmt: Codeunit "Reservation Management";
        NextLineNo: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 8-2-1

          SetGlobalPreconditions;
          ModifyProdBom;

          IF LastIteration = '8-2-1-10' THEN EXIT;

        // 8-2-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-2-2','A_TEST','12','SILVER','',
            39,'PCS',10,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-2-2','B_TEST','','SILVER','',
            25,'PCS',11.5,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-2-2','C_TEST','','SILVER','',
            10,'PCS',13.13,0,'S-01-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-2-2','D_PROD','','SILVER','',
            18,'PCS',16.25,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-2-2','E_PROD','','SILVER','',
            5,'PCS',111.11,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-2-2','L_TEST','','SILVER','',
            2,'BOX',44.4,0,'S-02-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-2-2','T_TEST','','SILVER','',
            4,'BOX',45,0,'S-02-0003');

          IF LastIteration = '8-2-2-10' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);
          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);
          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN03','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);
          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN04','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);

          IF LastIteration = '8-2-2-20' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-2-2-30' THEN EXIT;

        // 8-2-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '8-2-3-10' THEN EXIT;

        // 8-2-4

          InsertProdOrder(ProdOrder,2,0,'E_PROD',2,'SILVER');

          IF LastIteration = '8-2-4-10' THEN EXIT;

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          ProdOrderComp.Reset();
          ProdOrderComp.FIND('+');
          ProdOrderComp2 := ProdOrderComp;
          NextLineNo := ProdOrderComp2."Line No." + 10000;
          ProdOrderComp2."Line No." := NextLineNo;
          ProdOrderComp2.VALIDATE("Location Code",'SILVER');
          ProdOrderComp2.VALIDATE("Item No.",'B_TEST');
          ProdOrderComp2.VALIDATE("Unit of Measure Code",'PCS');
          ProdOrderComp2.VALIDATE("Quantity per",-12);
          ProdOrderComp2.VALIDATE("Due Date",WORKDATE-1);
          ProdOrderComp2.Insert();
          ProdOrderComp2."Line No." := NextLineNo + 10000;
          ProdOrderComp2.VALIDATE("Item No.",'C_TEST');
          ProdOrderComp2.VALIDATE("Quantity per",4);
          ProdOrderComp2.Insert();

          IF LastIteration = '8-2-4-20' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Prod. Order Line No.",10000);
          ProdOrderComp.SETRANGE("Item No.",'T_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN02','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN03','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN04','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          ProdOrderComp.SETRANGE("Item No.",'L_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'','LN01','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,2,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'','LN02','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-2-4-30' THEN EXIT;

          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,3,SalesHeader."Posting Date",FALSE);

          IF LastIteration = '8-2-4-40' THEN EXIT;

        // 8-2-5

          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          IF LastIteration = '8-2-5-10' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-2-5-20' THEN EXIT;

        // 8-2-6

          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '8-2-6-10' THEN EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        CreateRes: Codeunit "Create Reserv. Entry";
        ResMgmt: Codeunit "Reservation Management";
        ProdOrderStatMgmt: Codeunit "Prod. Order Status Management";
        ProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        WITH TestScriptMgmt DO BEGIN
        // 8-3-1

          SetGlobalPreconditions;
          ModifyProdBom;

          IF LastIteration = '8-3-1-10' THEN EXIT;

        // 8-3-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-3-2','A_TEST','12','SILVER','',
            39,'PCS',10,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-3-2','B_TEST','','SILVER','',
            25,'PCS',11.5,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-3-2','D_PROD','','SILVER','',
            18,'PCS',16.25,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-3-2','E_PROD','','SILVER','',
            5,'PCS',111.11,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-3-2','L_TEST','','SILVER','',
            2,'BOX',44.4,0,'S-02-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-3-2','T_TEST','','SILVER','',
            4,'BOX',45,0,'S-02-0003');

          IF LastIteration = '8-3-2-10' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);
          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN03','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN04','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);

          IF LastIteration = '8-3-2-20' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-3-2-30' THEN EXIT;

        // 8-3-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '8-3-3-10' THEN EXIT;

        // 8-3-4

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'30000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'SILVER',TRUE,FALSE);

          InsertSalesLine(SalesLine,SalesHeader,10000,SalesLine.Type::Item,'E_PROD','',2,'PCS',123.45,'SILVER','');
          ModifySalesLine(SalesHeader,10000,'S-03-0001',2,2,0,0,FALSE);

          IF LastIteration = '8-3-4-10' THEN EXIT;

          CLEAR(ProdOrderFromSale);
          ProdOrderFromSale.SetHideValidationDialog(TRUE);
          ProdOrderFromSale.CreateProductionOrder(SalesLine,0,0);

          IF LastIteration = '8-3-4-20' THEN EXIT;

        // 8-3-5

          ProdOrder.FIND('-');
          ProdOrderStatMgmt.ChangeStatusOnProdOrder(ProdOrder,3,SalesHeader."Posting Date",FALSE);

          IF LastIteration = '8-3-5-10' THEN EXIT;

          ProdOrderLine.FIND('-');
          ProdOrderLine.VALIDATE(Quantity,1);
          ProdOrderLine.VALIDATE("Ending Time");
          ProdOrderLine.Modify();
          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrderLine."Prod. Order No.");
          ProdOrderComp.SETRANGE("Prod. Order Line No.",ProdOrderLine."Line No.");
          ProdOrderComp.SETRANGE("Item No.",'T_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrderLine."Prod. Order No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrderLine."Prod. Order No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN04','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          ProdOrderComp.SETRANGE("Item No.",'L_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrderLine."Prod. Order No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'','LN02','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-3-5-20' THEN EXIT;

        // 8-3-6

          ProdOrder.FIND('-');
          CalcConsumption.InitializeRequest(WORKDATE,1);
          CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
          CalcConsumption.SETTABLEVIEW(ProdOrder);
          CalcConsumption.USEREQUESTPAGE(FALSE);
          CalcConsumption.RunModal();

          IF LastIteration = '8-3-6-10' THEN EXIT;

          ItemJnlLine.Reset();
          ItemJnlLine.FIND('-');
          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-3-6-20' THEN EXIT;

          ItemJnlLine.Init();
          ItemJnlLine.VALIDATE("Journal Template Name",'CONSUMP');
          ItemJnlLine.VALIDATE("Journal Batch Name",'DEFAULT');
          ItemJnlLine.SetUpNewLine(ItemJnlLine);
          ItemJnlLine."Line No." := 10000;
          ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Consumption;
          ItemJnlLine."Posting Date" := 251101D;
          ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
          ItemJnlLine.VALIDATE("Order No.",ProdOrder."No.");
          ItemJnlLine.VALIDATE("Item No.",'B_TEST');
          ItemJnlLine.VALIDATE("Unit of Measure Code",'PCS');
          ItemJnlLine.VALIDATE(Quantity,2);
          ItemJnlLine.INSERT(TRUE);

          IF LastIteration = '8-3-6-30' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-3-6-40' THEN EXIT;

        // 8-3-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '8-3-7-10' THEN EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    var
        Loc: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        EntrySum: Record "Entry Summary";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateInvPutPick: Report "Create Invt Put-away/Pick/Mvmt";
        CreateRes: Codeunit "Create Reserv. Entry";
        ResMgmt: Codeunit "Reservation Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        WITH TestScriptMgmt DO BEGIN
        // 8-7-1

          SetGlobalPreconditions;
          ModifyProdBom;

          IF LastIteration = '8-7-1-10' THEN EXIT;

          Loc.GET('SILVER');
          Loc."Require Pick" := TRUE;
          Loc.Modify();

          IF LastIteration = '8-7-1-20' THEN EXIT;

        // 8-7-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-7-2','A_TEST','12','SILVER','',
            39,'PCS',10,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-7-2','B_TEST','','SILVER','',
            25,'PCS',11.5,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-7-2','D_PROD','','SILVER','',
            18,'PCS',16.25,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-7-2','E_PROD','','SILVER','',
            5,'PCS',111.11,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-7-2','L_TEST','','SILVER','',
            2,'BOX',44.4,0,'S-02-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-7-2','T_TEST','','SILVER','',
            4,'BOX',45,0,'S-02-0003');

          IF LastIteration = '8-7-2-10' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);
          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);

          IF LastIteration = '8-7-2-20' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN03','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN04','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);

          IF LastIteration = '8-7-2-30' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-7-2-40' THEN EXIT;

        // 8-7-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '8-7-3-10' THEN EXIT;

        // 8-7-4

          InsertProdOrder(ProdOrder,3,0,'E_PROD',1,'SILVER');

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          WhseProdRelease.Release(ProdOrder);

          IF LastIteration = '8-7-4-10' THEN EXIT;

          ProdOrderLine.Reset();
          ProdOrderLine.FIND('-');
          ProdOrderComp.SETRANGE("Item No.",'T_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN04','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-7-4-20' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Prod. Order Line No.",ProdOrderLine."Line No.");
          ProdOrderComp.SETRANGE("Item No.",'L_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'','LN02','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-7-4-30' THEN EXIT;

          EntrySum.Init();
          EntrySum."Entry No." := 1;
          EntrySum."Table ID" := DATABASE::"Item Ledger Entry";
          EntrySum."Summary Type" := 'Item Ledger Entry';
          EntrySum."Total Quantity" := 1;
          ResMgmt.SetReservSource(ProdOrderComp);
          ResMgmt.SetSerialLotNo('','LN02','');
          ResMgmt.SetItemTrackingHandling(2);
          ResMgmt.AutoReserveOneLine(EntrySum."Entry No.",EntrySum."Total Quantity",EntrySum."Total Quantity",'',251101D);

          IF LastIteration = '8-7-4-40' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.FIND('+');
          ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
          ProdOrderComp.VALIDATE("Item No.",'A_TEST');
          ProdOrderComp.VALIDATE("Variant Code",'11');
          ProdOrderComp.VALIDATE("Quantity per", -1);
          ProdOrderComp.VALIDATE("Location Code",'SILVER');
          ProdOrderComp.VALIDATE("Bin Code",'S-01-0002');
          ProdOrderComp.INSERT(TRUE);
          ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
          ProdOrderComp.INSERT(TRUE);
          ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
          ProdOrderComp.VALIDATE("Item No.",'L_TEST');
          ProdOrderComp.VALIDATE("Quantity per", -1);
          ProdOrderComp.VALIDATE("Location Code",'SILVER');
          ProdOrderComp.VALIDATE("Bin Code",'S-01-0002');
          ProdOrderComp.INSERT(TRUE);
          CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
            ProdOrderComp."Line No.",1,-1,-1,'','LN03','');
          CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
          ProdOrderComp.VALIDATE("Item No.",'T_TEST');
          ProdOrderComp.VALIDATE("Quantity per", -1);
          ProdOrderComp.VALIDATE("Location Code",'SILVER');
          ProdOrderComp.VALIDATE("Bin Code",'S-01-0002');
          ProdOrderComp.INSERT(TRUE);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,-1,-1,'SN06','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          ProdOrderComp."Line No." := ProdOrderComp."Line No." + 10000;
          ProdOrderComp.VALIDATE("Item No.",'T_TEST');
          ProdOrderComp.VALIDATE("Quantity per", -1);
          ProdOrderComp.VALIDATE("Location Code",'SILVER');
          ProdOrderComp.VALIDATE("Bin Code",'S-04-0001');
          ProdOrderComp.INSERT(TRUE);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,-1,-1,'SN07','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);

          IF LastIteration = '8-7-4-50' THEN EXIT;

        // 8-7-5

          InsertWhseActHeader(WhseActivHeader,5,'SILVER');
          CreateInvPick(WhseActivHeader);
          InsertWhseActHeader(WhseActivHeader,4,'SILVER');
          CreateInvPutAway(WhseActivHeader);

          IF LastIteration = '8-7-5-10' THEN EXIT;

          WITH WhseActivLine DO BEGIN
            FIND('-');
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '8-7-5-20' THEN EXIT;

        // 8-7-6

          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '8-7-6-10' THEN EXIT;

        // 8-7-7

          WhseActivLine.Reset();

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",5);
          WhseActivLine.FIND('-');
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '8-7-7-10' THEN EXIT;

        // 8-7-8

          VerifyPostCondition(UseCaseNo,TestCaseNo,8,LastILENo);

          IF LastIteration = '8-7-8-10' THEN EXIT;

        // 8-7-9

          WhseActivLine.Reset();

          WhseActivLine.Reset();
          WhseActivLine.SETRANGE("Activity Type",4);
          WhseActivLine.FIND('-');
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '8-7-9-10' THEN EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase8()
    var
        Loc: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        WhseActivLine: Record "Warehouse Activity Line";
        CreateRes: Codeunit "Create Reserv. Entry";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        NextLineNo: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 8-8-1

          SetGlobalPreconditions;
          ModifyProdBom;

          IF LastIteration = '8-8-1-10' THEN EXIT;

          Loc.GET('SILVER');
          Loc."Require Pick" := TRUE;
          Loc."Require Put-away" := TRUE;
          Loc.Modify();

          IF LastIteration = '8-8-1-20' THEN EXIT;

        // 8-8-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-8-2','A_TEST','12','SILVER','',
            39,'PCS',10,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-8-2','B_TEST','','SILVER','',
            25,'PCS',11.5,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-8-2','C_TEST','','SILVER','',
            10,'PCS',13.13,0,'S-01-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-8-2','D_PROD','','SILVER','',
            18,'PCS',16.25,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-8-2','E_PROD','','SILVER','',
            5,'PCS',111.11,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-8-2','L_TEST','','SILVER','',
            2,'BOX',44.4,0,'S-02-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-8-2','T_TEST','','SILVER','',
            4,'BOX',45,0,'S-02-0003');

          IF LastIteration = '8-8-2-10' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);

          IF LastIteration = '8-8-2-20' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);
          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);
          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN03','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);
          InsertResEntry(ResEntry,'SILVER',10007,3,251101D,'T_TEST','','SN04','',1,1,83,0,
            'ITEM','DEFAULT',10007,TRUE);

          IF LastIteration = '8-8-2-30' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-8-2-40' THEN EXIT;

        // 8-8-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '8-8-3-10' THEN EXIT;

        // 8-8-4

          InsertProdOrder(ProdOrder,3,0,'E_PROD',2,'SILVER');

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          WhseProdRelease.Release(ProdOrder);

          IF LastIteration = '8-8-4-10' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.FIND('+');
          ProdOrderComp2 := ProdOrderComp;
          NextLineNo := ProdOrderComp2."Line No." + 10000;
          ProdOrderComp2."Line No." := NextLineNo;
          ProdOrderComp2.VALIDATE("Location Code",'SILVER');
          ProdOrderComp2.VALIDATE("Item No.",'B_TEST');
          ProdOrderComp2.VALIDATE("Unit of Measure Code",'PCS');
          ProdOrderComp2.VALIDATE("Quantity per",-12);
          ProdOrderComp2.VALIDATE("Due Date",WORKDATE-1);
          ProdOrderComp2.INSERT(TRUE);
          ProdOrderComp2."Line No." := NextLineNo + 10000;
          ProdOrderComp2.VALIDATE("Item No.",'C_TEST');
          ProdOrderComp2.VALIDATE("Quantity per",4);
          ProdOrderComp2.INSERT(TRUE);

          IF LastIteration = '8-8-4-20' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Prod. Order Line No.",10000);
          ProdOrderComp.SETRANGE("Item No.",'T_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN02','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN03','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'SN04','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-8-4-30' THEN EXIT;

          ProdOrderComp.SETRANGE("Item No.",'L_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'','LN01','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',10000,
              ProdOrderComp."Line No.",1,1,1,'','LN02','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-8-4-40' THEN EXIT;

        // 8-8-5

          CreateInvPutAwayPickBySrcFilt(11,ProdOrder."No.");

          IF LastIteration = '8-8-5-10' THEN EXIT;

          WITH WhseActivLine DO BEGIN
            FIND('-');
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '8-8-5-20' THEN EXIT;

        // 8-8-6

          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '8-8-6-10' THEN EXIT;

        // 8-8-7

          WhseActivLine.FIND('+');
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type");
          WhseActivLine.SETRANGE("No.",WhseActivLine."No.");
          PostInvWhseActLine(WhseActivLine,FALSE);

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          WhseActivLine.SETRANGE("Activity Type",WhseActivLine."Activity Type");
          WhseActivLine.SETRANGE("No.",WhseActivLine."No.");
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '8-8-7-10' THEN EXIT;

        // 8-8-8

          VerifyPostCondition(UseCaseNo,TestCaseNo,8,LastILENo);

          IF LastIteration = '8-8-8-10' THEN EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase9()
    var
        Loc: Record Location;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderComp2: Record "Prod. Order Component";
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        EntrySum: Record "Entry Summary";
        CreateRes: Codeunit "Create Reserv. Entry";
        ResMgmt: Codeunit "Reservation Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        NextLineNo: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN

        // 8-9-1

          SetGlobalPreconditions;
          ModifyProdBom;

          IF LastIteration = '8-9-1-10' THEN EXIT;

          Loc.GET('SILVER');
          Loc."Require Pick" := TRUE;
          Loc.Modify();

          IF LastIteration = '8-9-1-20' THEN EXIT;

        // 8-9-2

          ItemJnlLineNo := 10000;

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-9-2','A_TEST','12','SILVER','',
            39,'PCS',10,0,'S-01-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-9-2','B_TEST','','SILVER','',
            25,'PCS',11.5,0,'S-02-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-9-2','D_PROD','','SILVER','',
            18,'PCS',16.25,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-9-2','E_PROD','','SILVER','',
            5,'PCS',111.11,0,'S-03-0001');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-9-2','L_TEST','','SILVER','',
            2,'BOX',44.4,0,'S-02-0002');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),251101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS8-9-2','T_TEST','','SILVER','',
            4,'BOX',45,0,'S-02-0003');

          IF LastIteration = '8-9-2-10' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN01',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);
          InsertResEntry(ResEntry,'SILVER',10005,3,251101D,'L_TEST','','','LN02',1,1,83,0,
            'ITEM','DEFAULT',10005,TRUE);

          IF LastIteration = '8-9-2-20' THEN EXIT;

          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN01','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN02','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN03','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);
          InsertResEntry(ResEntry,'SILVER',10006,3,251101D,'T_TEST','','SN04','',1,1,83,0,
            'ITEM','DEFAULT',10006,TRUE);

          IF LastIteration = '8-9-2-30' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '8-9-2-40' THEN EXIT;

        // 8-9-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo);

          IF LastIteration = '8-9-3-10' THEN EXIT;

        // 8-9-4

          InsertProdOrder(ProdOrder,3,0,'E_PROD',1,'SILVER');

          IF LastIteration = '8-9-4-10' THEN EXIT;

          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
          REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
          ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
          Commit();
          CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;

          WhseProdRelease.Release(ProdOrder);

          IF LastIteration = '8-9-4-20' THEN EXIT;

          ProdOrderLine.Reset();
          ProdOrderLine.FIND('-');
          ProdOrderComp.SETRANGE("Item No.",'T_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN01','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'SN04','','');
            CreateRes.CreateEntry('T_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-9-4-30' THEN EXIT;

          ProdOrderComp.Reset();
          ProdOrderComp.SETRANGE("Prod. Order No.",ProdOrder."No.");
          ProdOrderComp.SETRANGE("Prod. Order Line No.",ProdOrderLine."Line No.");
          ProdOrderComp.SETRANGE("Item No.",'L_TEST');
          IF ProdOrderComp.FIND('-') THEN BEGIN
            CreateRes.CreateReservEntryFor(5407,3,ProdOrder."No.",'',ProdOrderLine."Line No.",
              ProdOrderComp."Line No.",1,1,1,'','LN02','');
            CreateRes.CreateEntry('L_TEST','','SILVER','',251101D,251101D,0,2);
          END;

          IF LastIteration = '8-9-4-40' THEN EXIT;

          EntrySum.Init();
          EntrySum."Entry No." := 1;
          EntrySum."Table ID" := DATABASE::"Item Ledger Entry";
          EntrySum."Summary Type" := 'Item Ledger Entry';
          EntrySum."Total Quantity" := 1;
          ResMgmt.SetReservSource(ProdOrderComp);
          ResMgmt.SetSerialLotNo('','LN02','');
          ResMgmt.SetItemTrackingHandling(2);
          ResMgmt.AutoReserveOneLine(EntrySum."Entry No.",EntrySum."Total Quantity",EntrySum."Total Quantity",'',251101D);

          IF LastIteration = '8-9-4-50' THEN EXIT;

        // 8-9-5

          CreateInvPutAwayPickBySrcFilt(11,ProdOrder."No.");

          IF LastIteration = '8-9-5-10' THEN EXIT;

          WITH WhseActivLine DO BEGIN
            FIND('-');
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '8-9-5-20' THEN EXIT;

        // 8-9-6

          VerifyPostCondition(UseCaseNo,TestCaseNo,6,LastILENo);

          IF LastIteration = '8-9-6-10' THEN EXIT;

        // 8-9-7

          WhseActivLine.FindFirst();
          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '8-9-7-10' THEN EXIT;

        // 8-9-8

          VerifyPostCondition(UseCaseNo,TestCaseNo,8,LastILENo);

          IF LastIteration = '8-9-8-10' THEN EXIT;

        // 8-9-9

          ProdOrderComp.Reset();
          ProdOrderComp.FIND('+');
          ProdOrderComp2 := ProdOrderComp;
          NextLineNo := ProdOrderComp2."Line No." + 10000;
          ProdOrderComp2."Line No." := NextLineNo;
          ProdOrderComp2.VALIDATE("Location Code",'SILVER');
          ProdOrderComp2.VALIDATE("Quantity per",2);
          ProdOrderComp2.VALIDATE("Due Date",WORKDATE-1);
          ProdOrderComp2.VALIDATE("Item No.",'A_TEST');
          ProdOrderComp2.VALIDATE("Variant Code",'12');
          ProdOrderComp2.Insert();

          IF LastIteration = '8-9-9-10' THEN EXIT;

          CreateInvPutAwayPickBySrcFilt(11,ProdOrder."No.");

          IF LastIteration = '8-9-9-20' THEN EXIT;

          WITH WhseActivLine DO BEGIN
            FIND('-');
            AutofillQtyToHandle(WhseActivLine);
          END;

          IF LastIteration = '8-9-9-30' THEN EXIT;

          PostInvWhseActLine(WhseActivLine,FALSE);

          IF LastIteration = '8-9-9-40' THEN EXIT;

        // 8-9-10

          VerifyPostCondition(UseCaseNo,TestCaseNo,10,LastILENo);

          IF LastIteration = '8-9-10-10' THEN EXIT;


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

    local procedure ModifyProdBom()
    var
        ProdBOMHdr: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        WMSGlobalPrecondition: Codeunit Codeunit103301;
    begin
        WITH WMSGlobalPrecondition DO BEGIN
          ProdBOMHdr.GET('E_PROD');
          ProdBOMHdr.Status := ProdBOMHdr.Status::"Under Development";
          ProdBOMHdr.Modify();
          ProdBOMLine.SETRANGE(ProdBOMLine."Production BOM No.",'E_PROD');
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
    end;
}

