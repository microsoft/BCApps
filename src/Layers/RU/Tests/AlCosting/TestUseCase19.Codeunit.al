codeunit 103420 "Test Use Case 19"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    var
        UseCase: Record Table103401;
        TestCase: Record Table103402;
        ItemJnlLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        TempProdBOMHeader: Record "Production BOM Header" temporary;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        ConsumpItemJnlLine: Record "Item Journal Line";
        OutputItemJnlLine: Record "Item Journal Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        SelectionForm: Page Page103404;
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        CalcInvValue: Report "Calculate Inventory Value";
        CalcConsumption: Report "Calc. Consumption";
        RefreshProductionOrder: Report "Refresh Production Order";
        TestScriptMgmt: Codeunit Codeunit103492;
        CreateRes: Codeunit "Create Reserv. Entry";
        WMSTestscriptManagement: Codeunit Codeunit103303;
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        ObjectNo: Integer;
        UseCaseNo: Integer;
        TestLevel: Option All,Selected;
        TestCaseNo: Integer;
        TestUseCase: array [50] of Boolean;
        TestCaseDesc: array [50] of Text[100];
        ShowAlsoPassTests: Boolean;
        LastILENo: Integer;
        LastCLENo: Integer;
        LastGLENo: Integer;
        TestResultsPath: Text[250];
        FirstIteration: Text[30];
        ActualIteration: Text[30];
        LastIteration: Text[30];
        IterationActive: Boolean;
        NoOfRecords: array [20] of Integer;
        NoOfFields: array [20] of Integer;

    [Scope('OnPrem')]
    procedure Test(NewObjectNo: Integer;NewUseCaseNo: Integer;NewTestLevel: Option All,Selected;NewLastIteration: Text[30];NewTestCaseNo: Integer): Boolean
    begin
        ObjectNo := NewObjectNo;
        UseCaseNo := NewUseCaseNo;
        TestLevel := NewTestLevel;
        LastIteration := NewLastIteration;
        TestCaseNo := NewTestCaseNo;

        UseCase.GET(UseCaseNo);
        TestScriptMgmt.InitializeOutput(ObjectNo,'');
        TestResultsPath := TestScriptMgmt.GetTestResultsPath;
        TestScriptMgmt.SetNumbers(NoOfRecords,NoOfFields);

        IF LastIteration <> '' THEN BEGIN
          TestCase.GET(UseCaseNo,TestCaseNo);
          TestCaseDesc[TestCaseNo] :=
            FORMAT(UseCaseNo) + '.' + FORMAT(TestCaseNo) + ' ' + TestCase.Description;
          HandleTestCases;
        END else BEGIN
          TestCaseNo := 0;
          CLEAR(TestUseCase);
          CLEAR(TestCaseDesc);

          TestCase.Reset();
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
          // Bug 37027
          // 2: PerformTestCase2;
          3:
            PerformTestCase3;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        WITH TestScriptMgmt DO BEGIN
          // 19-1-1
          IF PerformIteration('19-1-1-10') THEN BEGIN
            SetGlobalPreconditions;
            SetAutoCostPost(TRUE);
            SetExpCostPost(FALSE);
            SetAddRepCurr('DEM');
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-2
          IF PerformIteration('19-1-2-10') THEN BEGIN
            GetLastILENo;
            GetLastCLENo;
            GetLastGLENo;

            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',251101D);
            ModifyPurchHeader(PurchHeader,251101D,'BLUE','TCS19-1-2',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',2,'PALLET',130);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',3,'PALLET',90);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'3_SP_RE','',1,'PALLET',187);
              InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',5,'PCS',19);
              InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'4_AV_RE','',3,'PALLET',135);
              InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'5_ST_RA','',1,'PALLET',100);
              InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'1_FI_RE','11',2,'PALLET',136.5);
              InsertPurchLine(PurchLine,PurchHeader,80000,Type::Item,'2_LI_RA','21',3,'PALLET',94.5);
              InsertPurchLine(PurchLine,PurchHeader,90000,Type::Item,'3_SP_RE','31',1,'PALLET',195.5);
              InsertPurchLine(PurchLine,PurchHeader,100000,Type::Item,'4_AV_RE','41',5,'PCS',19.5);
              InsertPurchLine(PurchLine,PurchHeader,110000,Type::Item,'4_AV_RE','41',3,'PALLET',143.5);
              InsertPurchLine(PurchLine,PurchHeader,120000,Type::Item,'5_ST_RA','51',1,'PALLET',110);
            END;

            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN02','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN03','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN04','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN05','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN06','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN07','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN08','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN09','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN10','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN11','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN12','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN13','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN14','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN15','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN16','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN17','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,3);

            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST02','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST03','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST04','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST05','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST06','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST07','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST08','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST09','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST10','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST11','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST12','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST13','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST14','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST15','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST16','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,90000,1,1,1,'ST17','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-2-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-2-30') THEN BEGIN
            WMSTestscriptManagement.InsertTransferHeader(TransHeader,'Blue','RED','OWN LOG.',291101D);

            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",10000,'1_FI_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",20000,'2_LI_RA','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",30000,'3_SP_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",40000,'4_AV_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",50000,'4_AV_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",60000,'5_ST_RA','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",70000,'1_FI_RE','11','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",80000,'2_LI_RA','21','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",90000,'3_SP_RE','31','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",100000,'4_AV_RE','41','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",110000,'4_AV_RE','41','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",120000,'5_ST_RA','51','PCS',1,0,1);

            CreateRes.CreateReservEntryFor(5741,0,TransHeader."No.",'',0,30000,1,1,1,'SN11','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,291101D,0,2);
            CreateRes.CreateReservEntryFor(5741,1,TransHeader."No.",'',0,30000,1,1,1,'SN11','','');
            CreateRes.CreateEntry('3_SP_RE','','RED','',291101D,0D,0,2);

            CreateRes.CreateReservEntryFor(5741,0,TransHeader."No.",'',0,90000,1,1,1,'ST11','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,291101D,0,2);
            CreateRes.CreateReservEntryFor(5741,1,TransHeader."No.",'',0,90000,1,1,1,'ST11','','');
            CreateRes.CreateEntry('3_SP_RE','31','RED','',291101D,0D,0,2);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-2-40') THEN
            WMSTestscriptManagement.PostTransferOrder(TransHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-2-50') THEN
            WMSTestscriptManagement.PostTransferOrderRcpt(TransHeader)
            ;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-2-60') THEN BEGIN
            CLEAR(SalesHeader);
            InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',301101D);
            ModifySalesHeader(SalesHeader,301101D,'BLUE',TRUE,TRUE);

            WITH SalesLine DO BEGIN
              InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',28,'PCS',150);
              InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'2_LI_RA','',8,'PCS',151);
              InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'3_SP_RE','',10,'PCS',152);
              InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','',3,'PCS',153);
              InsertSalesLine(SalesLine,SalesHeader,50000,Type::Item,'4_AV_RE','',7,'PCS',154);
              InsertSalesLine(SalesLine,SalesHeader,60000,Type::Item,'5_ST_RA','',12,'PCS',155);
              InsertSalesLine(SalesLine,SalesHeader,70000,Type::Item,'2_LI_RA','',5,'PCS',151);
              InsertSalesLine(SalesLine,SalesHeader,80000,Type::Item,'1_FI_RE','11',28,'PCS',160);
              InsertSalesLine(SalesLine,SalesHeader,90000,Type::Item,'2_LI_RA','21',8,'PCS',161);
              InsertSalesLine(SalesLine,SalesHeader,100000,Type::Item,'3_SP_RE','31',10,'PCS',162);
              InsertSalesLine(SalesLine,SalesHeader,110000,Type::Item,'4_AV_RE','41',3,'PCS',163);
              InsertSalesLine(SalesLine,SalesHeader,120000,Type::Item,'4_AV_RE','41',7,'PCS',164);
              InsertSalesLine(SalesLine,SalesHeader,130000,Type::Item,'5_ST_RA','51',12,'PCS',165);
              InsertSalesLine(SalesLine,SalesHeader,140000,Type::Item,'2_LI_RA','21',5,'PCS',161);
            END;

            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN02','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN03','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN04','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN05','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN06','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN07','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN08','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN09','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,30000,1,1,1,'SN10','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,3);

            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST02','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST03','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST04','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST05','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST06','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST07','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST08','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST09','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,100000,1,1,1,'ST10','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-2-70') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-3
          IF PerformIteration('19-1-3-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-4
          IF PerformIteration('19-1-4-10') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'10000',261101D);
            ModifyPurchHeader(PurchHeader,261101D,'BLUE','TCS-19-1-4',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',5,'PCS',20);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',5,'PCS',20);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'3_SP_RE','',5,'PCS',20);
              InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',5,'PCS',20);
              InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'5_ST_RA','',5,'PCS',100);
              InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'1_FI_RE','11',5,'PCS',22);
              InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'2_LI_RA','21',5,'PCS',22);
              InsertPurchLine(PurchLine,PurchHeader,80000,Type::Item,'3_SP_RE','31',5,'PCS',22);
              InsertPurchLine(PurchLine,PurchHeader,90000,Type::Item,'4_AV_RE','41',5,'PCS',22);
              InsertPurchLine(PurchLine,PurchHeader,100000,Type::Item,'5_ST_RA','51',5,'PCS',110);
            END;

            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN18','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN19','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN20','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN21','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,30000,1,1,1,'SN22','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',261101D,0D,0,3);

            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,80000,1,1,1,'ST18','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,80000,1,1,1,'ST19','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,80000,1,1,1,'ST20','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,80000,1,1,1,'ST21','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',261101D,0D,0,3);
            CreateRes.CreateReservEntryFor(39,2,PurchHeader."No.",'',0,80000,1,1,1,'ST22','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',261101D,0D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-4-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-5
          IF PerformIteration('19-1-5-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-6
          IF PerformIteration('19-1-6-10') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-7
          IF PerformIteration('19-1-7-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-8
          IF PerformIteration('19-1-8-10') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',271101D);
            ModifyPurchHeader(PurchHeader,270101D,'BLUE','TCS-19-1-8',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::"Charge (Item)",'GPS','',12,'',100);
              ModifyPurchLine(PurchHeader,10000,12,12,0,0);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::"Charge (Item)",'UPS','',10,'',80);
              ModifyPurchLine(PurchHeader,20000,10,10,0,0);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::"Charge (Item)",'Insurance','',1,'',295.78);
              ModifyPurchLine(PurchHeader,30000,1,0,0,0);
            END;

            PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Order);
            PurchLine.SETRANGE("Document No.",PurchHeader."No.");
            PurchLine.SETRANGE("Line No.",10000);
            PurchLine.FIND('-');
            InsertPurchChargeAssignLine(PurchLine,10000,6,'107001',10000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",10000,1);
            InsertPurchChargeAssignLine(PurchLine,20000,6,'107001',20000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",20000,1);
            InsertPurchChargeAssignLine(PurchLine,30000,6,'107001',30000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",30000,1);
            InsertPurchChargeAssignLine(PurchLine,40000,6,'107001',40000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",40000,1);
            InsertPurchChargeAssignLine(PurchLine,50000,6,'107001',50000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",50000,1);
            InsertPurchChargeAssignLine(PurchLine,60000,6,'107001',60000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",60000,1);
            InsertPurchChargeAssignLine(PurchLine,70000,6,'107001',70000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",70000,1);
            InsertPurchChargeAssignLine(PurchLine,80000,6,'107001',80000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",80000,1);
            InsertPurchChargeAssignLine(PurchLine,90000,6,'107001',90000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",90000,1);
            InsertPurchChargeAssignLine(PurchLine,100000,6,'107001',100000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",100000,1);
            InsertPurchChargeAssignLine(PurchLine,110000,6,'107001',110000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",110000,1);
            InsertPurchChargeAssignLine(PurchLine,120000,6,'107001',120000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",120000,1);

            PurchLine.Reset();
            PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Order);
            PurchLine.SETRANGE("Document No.",PurchHeader."No.");
            PurchLine.SETRANGE("Line No.",20000);
            PurchLine.FIND('-');
            InsertPurchChargeAssignLine(PurchLine,10000,6,'107002',10000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",10000,1);
            InsertPurchChargeAssignLine(PurchLine,20000,6,'107002',20000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",20000,1);
            InsertPurchChargeAssignLine(PurchLine,30000,6,'107002',30000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",30000,1);
            InsertPurchChargeAssignLine(PurchLine,40000,6,'107002',40000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",40000,1);
            InsertPurchChargeAssignLine(PurchLine,50000,6,'107002',50000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",50000,1);
            InsertPurchChargeAssignLine(PurchLine,60000,6,'107002',60000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",60000,1);
            InsertPurchChargeAssignLine(PurchLine,70000,6,'107002',70000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",70000,1);
            InsertPurchChargeAssignLine(PurchLine,80000,6,'107002',80000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",80000,1);
            InsertPurchChargeAssignLine(PurchLine,90000,6,'107002',90000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",90000,1);
            InsertPurchChargeAssignLine(PurchLine,100000,6,'107002',100000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",100000,1);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-8-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-8-30') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-9
          IF PerformIteration('19-1-9-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-10
          IF PerformIteration('19-1-10-10') THEN BEGIN
            CLEAR(SalesHeader);
            InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Credit Memo",'10000',021201D);
            ModifySalesHeader(SalesHeader,021201D,'BLUE',TRUE,TRUE);
            WITH SalesLine DO BEGIN
              InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',150);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,10000,1,1,150,0,93);
              InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'2_LI_RA','',1,'PCS',151);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,20000,1,1,151,0,94);
              InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'3_SP_RE','',1,'PCS',152);
              InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','',2,'PCS',153);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,40000,2,2,153,0,105);
              InsertSalesLine(SalesLine,SalesHeader,50000,Type::Item,'4_AV_RE','',1,'PCS',154);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,50000,1,1,154,0,106);
              InsertSalesLine(SalesLine,SalesHeader,60000,Type::Item,'5_ST_RA','',1,'PCS',155);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,60000,1,1,155,0,107);
              InsertSalesLine(SalesLine,SalesHeader,70000,Type::Item,'2_LI_RA','',1,'PCS',151);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,70000,1,1,151,0,108);
              InsertSalesLine(SalesLine,SalesHeader,80000,Type::Item,'1_FI_RE','11',1,'PCS',160);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,80000,1,1,160,0,109);
              InsertSalesLine(SalesLine,SalesHeader,90000,Type::Item,'2_LI_RA','21',1,'PCS',161);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,90000,1,1,161,0,110);
              InsertSalesLine(SalesLine,SalesHeader,100000,Type::Item,'3_SP_RE','31',1,'PCS',162);
              InsertSalesLine(SalesLine,SalesHeader,110000,Type::Item,'4_AV_RE','41',2,'PCS',163);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,110000,2,2,163,0,121);
              InsertSalesLine(SalesLine,SalesHeader,120000,Type::Item,'4_AV_RE','41',1,'PCS',164);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,120000,1,1,164,0,122);
              InsertSalesLine(SalesLine,SalesHeader,130000,Type::Item,'5_ST_RA','51',1,'PCS',165);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,130000,1,1,165,0,123);
              InsertSalesLine(SalesLine,SalesHeader,140000,Type::Item,'2_LI_RA','21',1,'PCS',161);
              WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader,140000,1,1,161,0,124);
            END;

            CreateRes.CreateReservEntryFor(37,3,SalesHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.SetApplyFromEntryNo(95);
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',021201D,0D,0,3);

            CreateRes.CreateReservEntryFor(37,3,SalesHeader."No.",'',0,100000,1,1,1,'ST01','','');
            CreateRes.SetApplyFromEntryNo(111);
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',021201D,0D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-10-20') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-11
          IF PerformIteration('19-1-11-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-12
          IF PerformIteration('19-1-12-10') THEN BEGIN
            Commit();
            CLEAR(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SETFILTER("Location Filter",'BLUE');
            Item.SETFILTER("Variant Filter",'<>%1','');
            CalcInvValue.SETTABLEVIEW(Item);
            CalcInvValue.InitializeRequest(281101D,'TCS-19-1-12',TRUE,1,FALSE,FALSE,FALSE,0,TRUE);
            CalcInvValue.USEREQUESTPAGE(FALSE);
            CalcInvValue.RunModal();
            CLEAR(CalcInvValue);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-12-20') THEN
            WITH ItemJnlLine DO BEGIN
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",10000,1000,TRUE,0);
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",20000,1000,TRUE,0);
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",30000,1000,TRUE,0);
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",40000,1000,TRUE,0);
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",50000,1000,TRUE,0);
            END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-12-30') THEN
            ItemJnlPostBatch(ItemJnlLine);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-12-40') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-12-50') THEN BEGIN
            ItemJnlDelete(ItemJnlLine);

            ValueEntry.Reset();
            CLEAR(PostInvtCostToGL);
            PostInvtCostToGL.SETTABLEVIEW(ValueEntry);
            PostInvtCostToGL.InitializeRequest(0,'TCS-19-1-12',TRUE);
            PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase19-1-12.pdf');
            CLEAR(PostInvtCostToGL);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-13
          IF PerformIteration('19-1-13-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,13,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-14
          IF PerformIteration('19-1-14-10') THEN BEGIN
            CLEAR(SalesHeader);
            InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',051201D);
            ModifySalesHeader(SalesHeader,051201D,'BLUE',TRUE,TRUE);

            WITH SalesLine DO BEGIN
              InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',150);
              InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'3_SP_RE','',11,'PCS',152);
              InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',14,'PCS',153);
              InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'5_ST_RA','',3,'PCS',155);
              InsertSalesLine(SalesLine,SalesHeader,50000,Type::Item,'1_FI_RE','11',2,'PCS',160);
              InsertSalesLine(SalesLine,SalesHeader,60000,Type::Item,'3_SP_RE','31',11,'PCS',162);
              InsertSalesLine(SalesLine,SalesHeader,70000,Type::Item,'4_AV_RE','41',14,'PCS',164);
              InsertSalesLine(SalesLine,SalesHeader,80000,Type::Item,'5_ST_RA','51',3,'PCS',165);
            END;

            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN12','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN13','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN14','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN15','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN16','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN17','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN18','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN19','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN20','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN21','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN22','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,051201D,0,3);

            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST12','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST13','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST14','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST15','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST16','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST17','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST18','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST19','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST20','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST21','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST22','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,051201D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-14-20') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-14-30') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Credit Memo",'10000',031201D);
            ModifyPurchReturnHeader(PurchHeader,031201D,'BLUE','TCS-19-1-14');

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',150);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',1,'PCS',151);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'3_SP_RE','',1,'PCS',152);
              InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',2,'PCS',153);
              InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'4_AV_RE','',1,'PCS',154);
              InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'5_ST_RA','',1,'PCS',155);
              InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'2_LI_RA','',1,'PCS',151);
              InsertPurchLine(PurchLine,PurchHeader,80000,Type::Item,'1_FI_RE','11',1,'PCS',160);
              InsertPurchLine(PurchLine,PurchHeader,90000,Type::Item,'2_LI_RA','21',1,'PCS',161);
              InsertPurchLine(PurchLine,PurchHeader,100000,Type::Item,'3_SP_RE','31',1,'PCS',162);
              InsertPurchLine(PurchLine,PurchHeader,110000,Type::Item,'4_AV_RE','41',2,'PCS',163);
              InsertPurchLine(PurchLine,PurchHeader,120000,Type::Item,'4_AV_RE','41',1,'PCS',164);
              InsertPurchLine(PurchLine,PurchHeader,130000,Type::Item,'5_ST_RA','51',1,'PCS',165);
              InsertPurchLine(PurchLine,PurchHeader,140000,Type::Item,'2_LI_RA','21',1,'PCS',161);
            END;

            CreateRes.CreateReservEntryFor(39,3,PurchHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,031201D,0,3);

            CreateRes.CreateReservEntryFor(39,3,PurchHeader."No.",'',0,100000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,031201D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-14-40') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-14-50') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-1-14-60') THEN BEGIN
            Commit();
            CLEAR(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SETRANGE("Location Filter",'RED');
            Item.SETRANGE("Variant Filter");
            CalcInvValue.SETTABLEVIEW(Item);
            CalcInvValue.InitializeRequest(061201D,'TCS-19-1-14',TRUE,1,TRUE,TRUE,FALSE,0,TRUE);
            CalcInvValue.USEREQUESTPAGE(FALSE);
            CalcInvValue.RunModal();
            CLEAR(CalcInvValue);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-1-15
          IF PerformIteration('19-1-15-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,15,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        WITH TestScriptMgmt DO BEGIN
          // 19-2-1
          IF PerformIteration('19-2-1-10') THEN
            SetGlobalPreconditions;
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-2
          IF PerformIteration('19-2-2-10') THEN BEGIN
            SetAutoCostPost(TRUE);
            SetExpCostPost(TRUE);
            SetAddRepCurr('DEM');
            GetLastILENo;
            GetLastCLENo;
            GetLastGLENo;

            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
            ModifyPurchHeader(PurchHeader,251101D,'BLUE','TCS19-2-2',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',2,'PALLET',200);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',3,'PALLET',120);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'3_SP_RE','',1,'PALLET',230);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',5,'PCS',25);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'4_AV_RE','',3,'PALLET',155);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'5_ST_RA','',1,'PALLET',115);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'1_FI_RE','11',2,'PALLET',186.5);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,80000,Type::Item,'2_LI_RA','21',3,'PALLET',114.5);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,90000,Type::Item,'3_SP_RE','31',1,'PALLET',225.5);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,100000,Type::Item,'4_AV_RE','41',5,'PCS',29.5);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,110000,Type::Item,'4_AV_RE','41',3,'PALLET',170.5);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,120000,Type::Item,'5_ST_RA','51',1,'PALLET',130);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            END;

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN02','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN03','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN04','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN05','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN06','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN07','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN08','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN09','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN10','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN11','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN12','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN13','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN14','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN15','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN16','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN17','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',250101D,0D,0,2);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST02','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST03','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST04','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST05','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST06','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST07','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST08','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST09','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST10','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST11','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST12','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST13','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST14','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST15','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST16','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,90000,1,1,1,'ST17','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',250101D,0D,0,2);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-2-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-2-30') THEN BEGIN
            WMSTestscriptManagement.InsertTransferHeader(TransHeader,'BLUE','RED','OWN LOG.',291101D);

            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",10000,'1_FI_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",20000,'2_LI_RA','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",30000,'3_SP_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",40000,'4_AV_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",50000,'4_AV_RE','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",60000,'5_ST_RA','','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",70000,'1_FI_RE','11','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",80000,'2_LI_RA','21','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",90000,'3_SP_RE','31','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",100000,'4_AV_RE','41','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",110000,'4_AV_RE','41','PCS',1,0,1);
            WMSTestscriptManagement.InsertTransferLine(TransLine,TransHeader."No.",120000,'5_ST_RA','51','PCS',1,0,1);

            CreateRes.CreateReservEntryFor(5741,0,TransHeader."No.",'',0,30000,1,1,1,'SN11','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,291101D,0,2);
            CreateRes.CreateReservEntryFor(5741,1,TransHeader."No.",'',0,30000,1,1,1,'SN11','','');
            CreateRes.CreateEntry('3_SP_RE','','RED','',291101D,0D,0,2);

            CreateRes.CreateReservEntryFor(5741,0,TransHeader."No.",'',0,90000,1,1,1,'ST11','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,291101D,0,2);
            CreateRes.CreateReservEntryFor(5741,1,TransHeader."No.",'',0,90000,1,1,1,'ST11','','');
            CreateRes.CreateEntry('3_SP_RE','31','RED','',291101D,0D,0,2);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-2-40') THEN
            WMSTestscriptManagement.PostTransferOrder(TransHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-2-50') THEN
            WMSTestscriptManagement.PostTransferOrderRcpt(TransHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-2-60') THEN BEGIN
            CLEAR(SalesHeader);
            InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',301101D);
            ModifySalesHeader(SalesHeader,301101D,'BLUE',TRUE,TRUE);

            WITH SalesLine DO BEGIN
              ClearDimensions;
              InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',28,'PCS',150);
              ModifySalesLine(SalesHeader,"Line No.",28,28,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'2_LI_RA','',8,'PCS',151);
              ModifySalesLine(SalesHeader,"Line No.",8,8,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'3_SP_RE','',10,'PCS',152);
              ModifySalesLine(SalesHeader,"Line No.",10,10,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','',3,'PCS',153);
              ModifySalesLine(SalesHeader,"Line No.",3,3,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,50000,Type::Item,'4_AV_RE','',7,'PCS',154);
              ModifySalesLine(SalesHeader,"Line No.",7,7,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,60000,Type::Item,'5_ST_RA','',12,'PCS',155);
              ModifySalesLine(SalesHeader,"Line No.",12,12,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,70000,Type::Item,'2_LI_RA','',5,'PCS',151);
              ModifySalesLine(SalesHeader,"Line No.",5,5,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,80000,Type::Item,'1_FI_RE','11',28,'PCS',160);
              ModifySalesLine(SalesHeader,"Line No.",28,28,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,90000,Type::Item,'2_LI_RA','21',8,'PCS',161);
              ModifySalesLine(SalesHeader,"Line No.",8,8,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,100000,Type::Item,'3_SP_RE','31',10,'PCS',162);
              ModifySalesLine(SalesHeader,"Line No.",10,10,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,110000,Type::Item,'4_AV_RE','41',3,'PCS',163);
              ModifySalesLine(SalesHeader,"Line No.",3,3,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,120000,Type::Item,'4_AV_RE','41',7,'PCS',164);
              ModifySalesLine(SalesHeader,"Line No.",7,7,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,130000,Type::Item,'5_ST_RA','51',12,'PCS',165);
              ModifySalesLine(SalesHeader,"Line No.",12,12,0,0,TRUE);
              InsertSalesLine(SalesLine,SalesHeader,140000,Type::Item,'2_LI_RA','21',5,'PCS',161);
              ModifySalesLine(SalesHeader,"Line No.",5,5,0,0,TRUE);
            END;

            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN02','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN03','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN04','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN05','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN06','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN07','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN08','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN09','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,'SN10','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',0D,301101D,0,2);

            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST02','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST03','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST04','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST05','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST06','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST07','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST08','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST09','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,100000,1,1,1,'ST10','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',0D,301101D,0,2);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-2-70') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-3
          IF PerformIteration('19-2-3-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-4
          IF PerformIteration('19-2-4-10') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',261101D);
            ModifyPurchHeader(PurchHeader,261101D,'BLUE','TCS19-2-4',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',5,'PCS',20);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',5,'PCS',20);
              ModifyPurchLine(PurchHeader,"Line No.",5,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'3_SP_RE','',5,'PCS',20);
              ModifyPurchLine(PurchHeader,"Line No.",5,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',5,'PCS',20);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'5_ST_RA','',5,'PCS',100);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'1_FI_RE','11',5,'PCS',22);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'2_LI_RA','21',5,'PCS',22);
              ModifyPurchLine(PurchHeader,"Line No.",5,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,80000,Type::Item,'3_SP_RE','31',5,'PCS',22);
              ModifyPurchLine(PurchHeader,"Line No.",5,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,90000,Type::Item,'4_AV_RE','41',5,'PCS',22);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,100000,Type::Item,'5_ST_RA','51',5,'PCS',110);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            END;

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN18','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN19','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN20','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN21','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,1,1,'SN22','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',260101D,0D,0,2);

            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,80000,1,1,1,'ST18','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,80000,1,1,1,'ST19','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,80000,1,1,1,'ST20','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,80000,1,1,1,'ST21','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',260101D,0D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,80000,1,1,1,'ST22','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',260101D,0D,0,2);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-4-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-5
          IF PerformIteration('19-2-5-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-6
          IF PerformIteration('19-2-6-10') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-7
          IF PerformIteration('19-2-7-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-8
          IF PerformIteration('19-2-8-10') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',271101D);
            ModifyPurchHeader(PurchHeader,271101D,'BLUE','TCS19-2-8',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::"Charge (Item)",'GPS','',12,'',100);
              ModifyPurchLine(PurchHeader,10000,12,12,0,0);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::"Charge (Item)",'UPS','',10,'',80);
              ModifyPurchLine(PurchHeader,20000,10,10,0,0);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::"Charge (Item)",'Insurance','',1,'',295.78);
              ModifyPurchLine(PurchHeader,30000,1,0,0,0);
            END;

            PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Order);
            PurchLine.SETRANGE("Document No.",PurchHeader."No.");
            PurchLine.SETRANGE("Line No.",10000);
            PurchLine.FIND('-');
            InsertPurchChargeAssignLine(PurchLine,10000,6,'107001',10000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",10000,1);
            InsertPurchChargeAssignLine(PurchLine,20000,6,'107001',20000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",20000,1);
            InsertPurchChargeAssignLine(PurchLine,30000,6,'107001',30000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",30000,1);
            InsertPurchChargeAssignLine(PurchLine,40000,6,'107001',40000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",40000,1);
            InsertPurchChargeAssignLine(PurchLine,50000,6,'107001',50000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",50000,1);
            InsertPurchChargeAssignLine(PurchLine,60000,6,'107001',60000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",60000,1);
            InsertPurchChargeAssignLine(PurchLine,70000,6,'107001',70000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",70000,1);
            InsertPurchChargeAssignLine(PurchLine,80000,6,'107001',80000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",80000,1);
            InsertPurchChargeAssignLine(PurchLine,90000,6,'107001',90000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",90000,1);
            InsertPurchChargeAssignLine(PurchLine,100000,6,'107001',100000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",100000,1);
            InsertPurchChargeAssignLine(PurchLine,110000,6,'107001',110000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",110000,1);
            InsertPurchChargeAssignLine(PurchLine,120000,6,'107001',120000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",120000,1);

            PurchLine.Reset();
            PurchLine.SETRANGE("Document Type",PurchLine."Document Type"::Order);
            PurchLine.SETRANGE("Document No.",PurchHeader."No.");
            PurchLine.SETRANGE("Line No.",20000);
            PurchLine.FIND('-');
            InsertPurchChargeAssignLine(PurchLine,10000,6,'107002',10000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",10000,1);
            InsertPurchChargeAssignLine(PurchLine,20000,6,'107002',20000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",20000,1);
            InsertPurchChargeAssignLine(PurchLine,30000,6,'107002',30000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",30000,1);
            InsertPurchChargeAssignLine(PurchLine,40000,6,'107002',40000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",40000,1);
            InsertPurchChargeAssignLine(PurchLine,50000,6,'107002',50000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",50000,1);
            InsertPurchChargeAssignLine(PurchLine,60000,6,'107002',60000,'1_FI_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",60000,1);
            InsertPurchChargeAssignLine(PurchLine,70000,6,'107002',70000,'2_LI_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",70000,1);
            InsertPurchChargeAssignLine(PurchLine,80000,6,'107002',80000,'3_SP_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",80000,1);
            InsertPurchChargeAssignLine(PurchLine,90000,6,'107002',90000,'4_AV_RE');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",90000,1);
            InsertPurchChargeAssignLine(PurchLine,100000,6,'107002',100000,'5_ST_RA');
            ModifyPurchChargeAssignLine(PurchHeader,PurchLine."Line No.",100000,1);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-8-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-8-30') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-9
          IF PerformIteration('19-2-9-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-10
          IF PerformIteration('19-2-10-10') THEN BEGIN
            PurchHeader.FIND('-');
            ModifyPurchHeader(PurchHeader,011201D,'','TCS19-2-2',TRUE);

            ModifyPurchLine(PurchHeader,10000,0,0,200,0);
            ModifyPurchLine(PurchHeader,20000,0,0,120,0);
            ModifyPurchLine(PurchHeader,30000,0,0,230,0);
            ModifyPurchLine(PurchHeader,40000,4,0,50,0);
            ModifyPurchLine(PurchHeader,50000,1,0,310,0);
            ModifyPurchLine(PurchHeader,60000,0,0,115,0);
            ModifyPurchLine(PurchHeader,70000,0,0,186.5,0);
            ModifyPurchLine(PurchHeader,80000,0,0,114.5,0);
            ModifyPurchLine(PurchHeader,90000,0,0,225.5,0);
            ModifyPurchLine(PurchHeader,100000,4,0,59,0);
            ModifyPurchLine(PurchHeader,110000,1,0,341,0);
            ModifyPurchLine(PurchHeader,120000,0,0,130,0);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-10-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-10-30') THEN BEGIN
            PurchHeader.SETRANGE("Vendor Invoice No.",'TCS19-2-4');
            PurchHeader.FIND('+');
            ModifyPurchHeader(PurchHeader,021201D,'','TCS19-2-4',TRUE);

            ModifyPurchLine(PurchHeader,10000,3,0,40,0);
            ModifyPurchLine(PurchHeader,20000,0,0,20,0);
            ModifyPurchLine(PurchHeader,30000,0,0,20,0);
            ModifyPurchLine(PurchHeader,40000,4,0,40,0);
            ModifyPurchLine(PurchHeader,50000,4,0,200,0);
            ModifyPurchLine(PurchHeader,60000,3,0,44,0);
            ModifyPurchLine(PurchHeader,70000,0,0,22,0);
            ModifyPurchLine(PurchHeader,80000,0,0,22,0);
            ModifyPurchLine(PurchHeader,90000,4,0,44,0);
            ModifyPurchLine(PurchHeader,100000,4,0,220,0);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-10-40') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-10-50') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-11
          IF PerformIteration('19-2-11-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-12
          IF PerformIteration('19-2-12-10') THEN BEGIN
            PurchHeader.Reset();
            PurchHeader.FIND('-');
            ModifyPurchHeader(PurchHeader,031201D,'','TCS19-2-2',TRUE);
            ModifyPurchLine(PurchHeader,10000,0,2,130,0);
            ModifyPurchLine(PurchHeader,20000,0,3,90,0);
            ModifyPurchLine(PurchHeader,30000,0,1,187,0);
            ModifyPurchLine(PurchHeader,40000,0,5,19,0);
            ModifyPurchLine(PurchHeader,50000,0,3,135,0);
            ModifyPurchLine(PurchHeader,60000,0,1,100,0);
            ModifyPurchLine(PurchHeader,70000,0,2,136.5,0);
            ModifyPurchLine(PurchHeader,80000,0,3,94.5,0);
            ModifyPurchLine(PurchHeader,90000,0,1,195.5,0);
            ModifyPurchLine(PurchHeader,100000,0,5,19.5,0);
            ModifyPurchLine(PurchHeader,110000,0,3,143.5,0);
            ModifyPurchLine(PurchHeader,120000,0,1,110,0);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-12-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-12-30') THEN BEGIN
            PurchHeader.SETRANGE("Vendor Invoice No.",'TCS19-2-4');
            PurchHeader.FIND('+');
            ModifyPurchHeader(PurchHeader,041201D,'','TCS19-2-4',TRUE);

            ModifyPurchLine(PurchHeader,10000,0,5,20,0);
            ModifyPurchLine(PurchHeader,20000,0,5,20,0);
            ModifyPurchLine(PurchHeader,30000,0,5,20,0);
            ModifyPurchLine(PurchHeader,40000,0,5,20,0);
            ModifyPurchLine(PurchHeader,50000,0,5,100,0);
            ModifyPurchLine(PurchHeader,60000,0,5,22,0);
            ModifyPurchLine(PurchHeader,70000,0,5,22,0);
            ModifyPurchLine(PurchHeader,80000,0,5,22,0);
            ModifyPurchLine(PurchHeader,90000,0,5,22,0);
            ModifyPurchLine(PurchHeader,100000,0,5,110,0);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-12-40') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-12-50') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-13
          IF PerformIteration('19-2-13-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,13,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-14
          IF PerformIteration('19-2-14-10') THEN BEGIN
            CLEAR(SalesHeader);
            InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'10000',021201D);
            ModifySalesHeader(SalesHeader,021201D,'BLUE',TRUE,TRUE);

            WITH SalesLine DO BEGIN
              ClearDimensions;
              InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',150);
              ModifySalesReturnLine(SalesHeader,10000,1,0,150,0,93);
              InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'2_LI_RA','',1,'PCS',151);
              ModifySalesReturnLine(SalesHeader,20000,1,0,151,0,94);
              InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'3_SP_RE','',1,'PCS',152);
              ModifySalesReturnLine(SalesHeader,30000,1,0,152,0,0);
              InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'4_AV_RE','',2,'PCS',153);
              ModifySalesReturnLine(SalesHeader,40000,2,0,153,0,105);
              InsertSalesLine(SalesLine,SalesHeader,50000,Type::Item,'4_AV_RE','',1,'PCS',154);
              ModifySalesReturnLine(SalesHeader,50000,1,0,154,0,106);
              InsertSalesLine(SalesLine,SalesHeader,60000,Type::Item,'5_ST_RA','',1,'PCS',155);
              ModifySalesReturnLine(SalesHeader,60000,1,0,155,0,107);
              InsertSalesLine(SalesLine,SalesHeader,70000,Type::Item,'2_LI_RA','',1,'PCS',151);
              ModifySalesReturnLine(SalesHeader,70000,1,0,151,0,108);
              InsertSalesLine(SalesLine,SalesHeader,80000,Type::Item,'1_FI_RE','11',1,'PCS',160);
              ModifySalesReturnLine(SalesHeader,80000,1,0,160,0,109);
              InsertSalesLine(SalesLine,SalesHeader,90000,Type::Item,'2_LI_RA','21',1,'PCS',161);
              ModifySalesReturnLine(SalesHeader,90000,1,0,161,0,110);
              InsertSalesLine(SalesLine,SalesHeader,100000,Type::Item,'3_SP_RE','31',1,'PCS',162);
              ModifySalesReturnLine(SalesHeader,100000,1,0,162,0,0);
              InsertSalesLine(SalesLine,SalesHeader,110000,Type::Item,'4_AV_RE','41',2,'PCS',163);
              ModifySalesReturnLine(SalesHeader,110000,2,0,163,0,121);
              InsertSalesLine(SalesLine,SalesHeader,120000,Type::Item,'4_AV_RE','41',1,'PCS',164);
              ModifySalesReturnLine(SalesHeader,120000,1,0,164,0,122);
              InsertSalesLine(SalesLine,SalesHeader,130000,Type::Item,'5_ST_RA','51',1,'PCS',165);
              ModifySalesReturnLine(SalesHeader,130000,1,0,165,0,123);
              InsertSalesLine(SalesLine,SalesHeader,140000,Type::Item,'2_LI_RA','21',1,'PCS',161);
              ModifySalesReturnLine(SalesHeader,140000,1,0,161,0,124);
            END;

            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.SetApplyFromEntryNo(95);
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',021201D,0D,0,2);

            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,100000,1,1,1,'ST01','','');
            CreateRes.SetApplyFromEntryNo(111);
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',021201D,0D,0,2);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-14-20') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-15
          IF PerformIteration('19-2-15-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,15,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-16
          IF PerformIteration('19-2-16-10') THEN BEGIN
            AdjustItem('','',FALSE);

            Commit();
            CLEAR(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SETFILTER("Location Filter",'BLUE');
            Item.SETFILTER("Variant Filter",'<>%1','');
            CalcInvValue.SETTABLEVIEW(Item);
            CalcInvValue.InitializeRequest(051201D,'TCS-19-2-16',TRUE,1,FALSE,FALSE,FALSE,0,TRUE);
            CalcInvValue.USEREQUESTPAGE(FALSE);
            CalcInvValue.RunModal();
            CLEAR(CalcInvValue);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;
          IF PerformIteration('19-2-16-20') THEN
            WITH ItemJnlLine DO BEGIN
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",10000,1000,TRUE,0);
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",20000,1000,TRUE,0);
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",30000,1000,TRUE,0);
              ModifyItemJnlLine("Journal Template Name","Journal Batch Name",40000,1000,TRUE,0);
            END;
          IF LastIteration = ActualIteration THEN
            EXIT;
          IF PerformIteration('19-2-16-30') THEN
            ItemJnlPostBatch(ItemJnlLine);
          IF LastIteration = ActualIteration THEN
            EXIT;
          IF PerformIteration('19-2-16-40') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-16-50') THEN BEGIN
            ItemJnlDelete(ItemJnlLine);
            ValueEntry.Reset();
            CLEAR(PostInvtCostToGL);
            PostInvtCostToGL.SETTABLEVIEW(ValueEntry);
            PostInvtCostToGL.InitializeRequest(0,'TCS-19-2-17',TRUE);
            PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase19-2-17.pdf');
            CLEAR(PostInvtCostToGL);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-16-60') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'10000',061201D);
            ModifyPurchReturnHeader(PurchHeader,061201D,'BLUE','TCS-19-2-16');

            WITH PurchLine DO BEGIN
              InsertPurchReturnLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1,'PCS',150,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',1,'PCS',151,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,30000,Type::Item,'3_SP_RE','',1,'PCS',152,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,40000,Type::Item,'4_AV_RE','',2,'PCS',153,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",2,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,50000,Type::Item,'4_AV_RE','',1,'PCS',154,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,60000,Type::Item,'5_ST_RA','',1,'PCS',155,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,70000,Type::Item,'2_LI_RA','',1,'PCS',151,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,80000,Type::Item,'1_FI_RE','11',1,'PCS',160,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,90000,Type::Item,'2_LI_RA','21',1,'PCS',161,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,100000,Type::Item,'3_SP_RE','31',1,'PCS',162,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,110000,Type::Item,'4_AV_RE','41',2,'PCS',163,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",2,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,120000,Type::Item,'4_AV_RE','41',1,'PCS',164,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,130000,Type::Item,'5_ST_RA','51',1,'PCS',165,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
              InsertPurchReturnLine(PurchLine,PurchHeader,140000,Type::Item,'2_LI_RA','21',1,'PCS',161,0);
              ModifyPurchReturnLine(PurchHeader,"Line No.",1,0);
            END;

            CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,30000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,2);

            CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,100000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,2);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-16-70') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-17
          IF PerformIteration('19-2-17-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,17,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-18
          IF PerformIteration('19-2-18-10') THEN BEGIN
            CLEAR(SalesHeader);
            InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',061201D);
            ModifySalesHeader(SalesHeader,061201D,'BLUE',TRUE,TRUE);

            WITH SalesLine DO BEGIN
              InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'1_FI_RE','',2,'PCS',150);
              InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'3_SP_RE','',11,'PCS',152);
              InsertSalesLine(SalesLine,SalesHeader,30000,Type::Item,'4_AV_RE','',14,'PCS',153);
              InsertSalesLine(SalesLine,SalesHeader,40000,Type::Item,'5_ST_RA','',3,'PCS',155);
              InsertSalesLine(SalesLine,SalesHeader,50000,Type::Item,'1_FI_RE','11',2,'PCS',160);
              InsertSalesLine(SalesLine,SalesHeader,60000,Type::Item,'3_SP_RE','31',11,'PCS',162);
              InsertSalesLine(SalesLine,SalesHeader,70000,Type::Item,'4_AV_RE','41',14,'PCS',164);
              InsertSalesLine(SalesLine,SalesHeader,80000,Type::Item,'5_ST_RA','51',3,'PCS',165);
            END;

            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN12','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN13','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN14','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN15','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN16','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN17','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN18','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN19','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN20','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN21','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'SN22','','');
            CreateRes.CreateEntry('3_SP_RE','','BLUE','',061201D,0D,0,3);

            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST12','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST13','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST14','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST15','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST16','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST17','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST18','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST19','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST20','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST21','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,60000,1,1,1,'ST22','','');
            CreateRes.CreateEntry('3_SP_RE','31','BLUE','',061201D,0D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-18-20') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-18-30') THEN BEGIN
            ReleasePurchDoc.Reopen(PurchHeader);
            ModifyPurchReturnHeader(PurchHeader,071201D,'BLUE','TCS-19-2-18');

            WITH PurchLine DO BEGIN
              ModifyPurchLine(PurchHeader,10000,0,1,0,0);
              ModifyPurchLine(PurchHeader,20000,0,1,0,0);
              ModifyPurchLine(PurchHeader,30000,0,1,0,0);
              ModifyPurchLine(PurchHeader,40000,0,2,0,0);
              ModifyPurchLine(PurchHeader,50000,0,1,0,0);
              ModifyPurchLine(PurchHeader,60000,0,1,0,0);
              ModifyPurchLine(PurchHeader,70000,0,1,0,0);
              ModifyPurchLine(PurchHeader,80000,0,1,0,0);
              ModifyPurchLine(PurchHeader,90000,0,1,0,0);
              ModifyPurchLine(PurchHeader,100000,0,1,0,0);
              ModifyPurchLine(PurchHeader,110000,0,2,0,0);
              ModifyPurchLine(PurchHeader,120000,0,1,0,0);
              ModifyPurchLine(PurchHeader,130000,0,1,0,0);
              ModifyPurchLine(PurchHeader,140000,0,1,0,0);
            END;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-18-40') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-18-50') THEN BEGIN
            CLEAR(SalesHeader);
            SalesHeader.FIND('-');
            ModifySalesHeader(SalesHeader,081201D,'BLUE',TRUE,TRUE);

            ModifySalesLine(SalesHeader,10000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,20000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,30000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,40000,0,2,0,0,TRUE);
            ModifySalesLine(SalesHeader,50000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,60000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,70000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,80000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,90000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,100000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,110000,0,2,0,0,TRUE);
            ModifySalesLine(SalesHeader,120000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,130000,0,1,0,0,TRUE);
            ModifySalesLine(SalesHeader,140000,0,1,0,0,TRUE);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-18-60') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-18-70') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-2-18-80') THEN BEGIN
            Commit();
            CLEAR(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SETRANGE("Location Filter",'RED');
            Item.SETRANGE("Variant Filter");
            CalcInvValue.SETTABLEVIEW(Item);
            CalcInvValue.InitializeRequest(091201D,'TCS-19-2-18',TRUE,1,TRUE,TRUE,FALSE,0,TRUE);
            CalcInvValue.USEREQUESTPAGE(FALSE);
            CalcInvValue.RunModal();
            CLEAR(CalcInvValue);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-2-19
          IF PerformIteration('19-2-19-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,19,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        WITH TestScriptMgmt DO BEGIN
          // 19-3-1
          IF PerformIteration('19-3-1-10') THEN BEGIN
            SetGlobalPreconditions;
            // this is code added later to change the item no. so that sorting is same in the reference data for both native as well as SQL.
            // this test shall use an item called A4_AV_RE instead of 4_AV_RE.
            RenameItem('4_AV_RE','A4_AV_RE');
            // this test shall use an item called D3_SP_RE instead of 3_SP_RE.
            RenameItem('3_SP_RE','D3_SP_RE');
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-1-10') THEN BEGIN
            SetAutoCostPost(TRUE);
            SetExpCostPost(TRUE);
            SetAddRepCurr('DEM');
            GetLastILENo;
            GetLastCLENo;
            GetLastGLENo;

            ProdBOMHeader.Reset();
            ProdBOMHeader.SETRANGE("No.",'A');
            ProdBOMHeader.FindFirst();
            TempProdBOMHeader := ProdBOMHeader;
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify();

            ProdBOMLine.Reset();
            ProdBOMLine.SETRANGE("Production BOM No.",'A');
            ProdBOMLine.SETRANGE("No.",'B');
            IF ProdBOMLine.FindFirst() then BEGIN
              ProdBOMLine.VALIDATE("No.",'1_FI_RE');
              ProdBOMLine.VALIDATE("Quantity per",1.5);
              ProdBOMLine.Modify();
            END;
            ProdBOMLine.SETRANGE("No.",'C');
            IF ProdBOMLine.FindFirst() then BEGIN
              ProdBOMLine.VALIDATE("No.",'2_LI_RA');
              ProdBOMLine.VALIDATE("Quantity per",2);
              ProdBOMLine.Modify();
            END;
            ProdBOMHeader.Status := TempProdBOMHeader.Status;
            ProdBOMHeader.Modify();

            ProdBOMHeader.Reset();
            ProdBOMHeader.SETRANGE("No.",'B');
            ProdBOMHeader.FindFirst();
            TempProdBOMHeader := ProdBOMHeader;
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify();

            ProdBOMLine.Reset();
            ProdBOMLine.SETRANGE("Production BOM No.",'B');
            ProdBOMLine.SETRANGE("No.",'C');
            IF ProdBOMLine.FindFirst() then BEGIN
              ProdBOMLine.VALIDATE("No.",'5_ST_RA');
              ProdBOMLine.VALIDATE("Quantity per",1.5);
              ProdBOMLine.Modify();
            END;

            ProdBOMLine.Reset();
            ProdBOMLine.Init();
            ProdBOMLine.VALIDATE("Production BOM No.",'B');
            ProdBOMLine.VALIDATE("Line No.",20000);
            ProdBOMLine.VALIDATE(Type,ProdBOMLine.Type::Item);
            ProdBOMLine.VALIDATE("No.",'A4_AV_RE');
            ProdBOMLine.VALIDATE("Quantity per",3);
            ProdBOMLine.Insert();

            ProdBOMHeader.Status := TempProdBOMHeader.Status;
            ProdBOMHeader.Modify();

            ProdBOMHeader.Init();
            ProdBOMHeader.VALIDATE("No.",'D3_SP_RE');
            ProdBOMHeader.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.VALIDATE("Production BOM No.",'D3_SP_RE');
            ProdBOMLine.VALIDATE("Line No.",10000);
            ProdBOMLine.VALIDATE(Type,ProdBOMLine.Type::Item);
            ProdBOMLine.VALIDATE("No.",'A');
            ProdBOMLine.VALIDATE("Quantity per",2);
            ProdBOMLine.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.VALIDATE("Production BOM No.",'D3_SP_RE');
            ProdBOMLine.VALIDATE("Line No.",20000);
            ProdBOMLine.VALIDATE(Type,ProdBOMLine.Type::Item);
            ProdBOMLine.VALIDATE("No.",'B');
            ProdBOMLine.VALIDATE("Quantity per",2);
            ProdBOMLine.Insert();

            ProdBOMHeader.VALIDATE("Unit of Measure Code",'PCS');
            ProdBOMHeader.VALIDATE(Status,ProdBOMHeader.Status::Certified);
            ProdBOMHeader.Modify();
            Item.GET('D3_SP_RE');
            Item.VALIDATE("Production BOM No.",'D3_SP_RE');
            Item.Modify();

            ProdBOMHeader.Init();
            ProdBOMHeader.VALIDATE("No.",'C');
            ProdBOMHeader.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.VALIDATE("Production BOM No.",'C');
            ProdBOMLine.VALIDATE("Line No.",10000);
            ProdBOMLine.VALIDATE(Type,ProdBOMLine.Type::Item);
            ProdBOMLine.VALIDATE("No.",'1_FI_RE');
            ProdBOMLine.VALIDATE("Quantity per",1.5);
            ProdBOMLine.VALIDATE("Variant Code",'11');
            ProdBOMLine.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.VALIDATE("Production BOM No.",'C');
            ProdBOMLine.VALIDATE("Line No.",20000);
            ProdBOMLine.VALIDATE(Type,ProdBOMLine.Type::Item);
            ProdBOMLine.VALIDATE("No.",'2_LI_RA');
            ProdBOMLine.VALIDATE("Quantity per",2);
            ProdBOMLine.VALIDATE("Variant Code",'21');
            ProdBOMLine.Insert();

            ProdBOMHeader.VALIDATE("Unit of Measure Code",'PCS');
            ProdBOMHeader.VALIDATE(Status,ProdBOMHeader.Status::Certified);
            ProdBOMHeader.Modify();
            Item.GET('C');
            Item.VALIDATE("Production BOM No.",'C');
            Item.Modify();

            ProdBOMHeader.Reset();
            ProdBOMHeader.SETRANGE("No.",'D');
            ProdBOMHeader.FindFirst();
            TempProdBOMHeader := ProdBOMHeader;
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify();

            ProdBOMLine.Reset();
            ProdBOMLine.SETRANGE("Production BOM No.",'D');
            ProdBOMLine.SETRANGE("No.",'B');
            IF ProdBOMLine.FindFirst() then BEGIN
              ProdBOMLine.VALIDATE("No.",'5_ST_RA');
              ProdBOMLine.VALIDATE("Quantity per",1.5);
              ProdBOMLine.VALIDATE("Variant Code",'51');
              ProdBOMLine.Modify();
            END;
            ProdBOMLine.Reset();
            ProdBOMLine.SETRANGE("Production BOM No.",'D');
            ProdBOMLine.SETRANGE("No.",'A4_AV_RE');
            IF ProdBOMLine.FindFirst() then BEGIN
              ProdBOMLine.VALIDATE("Quantity per",3);
              ProdBOMLine.VALIDATE("Variant Code",'41');
              ProdBOMLine.Modify();
            END;
            ProdBOMHeader.Status := TempProdBOMHeader.Status;
            ProdBOMHeader.Modify();
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-2
          IF PerformIteration('19-3-2-10') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
            ModifyPurchHeader(PurchHeader,251101D,'BLUE','TCS19-3-2',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',2,'PALLET',200);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',3,'PALLET',120);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'A4_AV_RE','',3,'PALLET',155);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'5_ST_RA','',1,'PALLET',115);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'1_FI_RE','11',2,'PALLET',186.5);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'2_LI_RA','21',3,'PALLET',114.5);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'A4_AV_RE','41',3,'PALLET',170.5);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,80000,Type::Item,'5_ST_RA','51',1,'PALLET',130);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            END;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-30') THEN BEGIN
            WORKDATE := 051201D;
            CLEAR(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder,3,ProdOrder."Source Type"::Item,'D3_SP_RE',1,'BLUE');
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
            REPORT.RUNMODAL(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
            ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-40') THEN BEGIN
            WORKDATE := 061201D;
            CLEAR(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder,3,ProdOrder."Source Type"::Item,'D3_SP_RE',1,'BLUE');
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
            REPORT.RUN(REPORT::"Refresh Production Order",FALSE,FALSE,ProdOrder);
            ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-50') THEN BEGIN
            ProdOrderLine.GET(ProdOrderLine.Status::Released,ProdOrder."No.",10000);
            ProdOrderLine.VALIDATE("Variant Code",'31');
            ProdOrderLine.Modify();

            ProdOrderComponent.SETRANGE(Status,ProdOrderComponent.Status::Released);
            ProdOrderComponent.SETRANGE("Prod. Order No.",ProdOrder."No.");
            ProdOrderComponent.SETRANGE("Prod. Order Line No.",10000);
            ProdOrderComponent.SETRANGE("Item No.",'A');
            ProdOrderComponent.FindFirst();
            ProdOrderComponent.VALIDATE("Item No.",'C');
            ProdOrderComponent.Modify();

            ProdOrderComponent.SETRANGE("Item No.",'B');
            ProdOrderComponent.FindFirst();
            ProdOrderComponent.VALIDATE("Item No.",'D');
            ProdOrderComponent.Modify();
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-60') THEN BEGIN
            WORKDATE := 041201D;
            CLEAR(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder,3,ProdOrder."Source Type"::Item,'A',2,'BLUE');

            ProdOrder.Reset();
            CLEAR(RefreshProductionOrder);
            ProdOrder.SETRANGE("No.",'101003');
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SETTABLEVIEW(ProdOrder);
            RefreshProductionOrder.USEREQUESTPAGE(FALSE);
            RefreshProductionOrder.RunModal();
            ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-70') THEN BEGIN
            WORKDATE := 041201D;
            CLEAR(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder,3,ProdOrder."Source Type"::Item,'B',2,'BLUE');

            ProdOrder.Reset();
            CLEAR(RefreshProductionOrder);
            ProdOrder.SETRANGE("No.",'101004');
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SETTABLEVIEW(ProdOrder);
            RefreshProductionOrder.USEREQUESTPAGE(FALSE);
            RefreshProductionOrder.RunModal();
            ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-80') THEN BEGIN
            WORKDATE := 041201D;
            CLEAR(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder,3,ProdOrder."Source Type"::Item,'C',2,'BLUE');
            ProdOrder.Reset();
            CLEAR(RefreshProductionOrder);
            ProdOrder.SETRANGE("No.",'101005');
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SETTABLEVIEW(ProdOrder);
            RefreshProductionOrder.USEREQUESTPAGE(FALSE);
            RefreshProductionOrder.RunModal();
            ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-90') THEN BEGIN
            WORKDATE := 051201D;
            CLEAR(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder,3,ProdOrder."Source Type"::Item,'D',2,'BLUE');
            ProdOrder.Reset();
            CLEAR(RefreshProductionOrder);
            ProdOrder.SETRANGE("No.",'101006');
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SETTABLEVIEW(ProdOrder);
            RefreshProductionOrder.USEREQUESTPAGE(FALSE);
            RefreshProductionOrder.RunModal();
            ProdOrder.GET(ProdOrder.Status,ProdOrder."No.");
            Commit();
            CURRENTTRANSACTIONTYPE := TRANSACTIONTYPE::UpdateNoLocks;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-2-100') THEN BEGIN
            WORKDATE := 250101D;
            ProdOrder.Reset();
            ProdOrder.SETRANGE("Location Code",'BLUE');
            ProdOrder.SETFILTER("Source No.",'%1|%2|%3|%4','A','B','C','D');
            CalcConsumption.InitializeRequest(261101D,1);
            CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
            CalcConsumption.SETTABLEVIEW(ProdOrder);
            CalcConsumption.USEREQUESTPAGE(FALSE);
            CalcConsumption.RunModal();

            ConsumpItemJnlLine.Reset();
            ConsumpItemJnlLine.SETRANGE("Journal Template Name",'CONSUMP');
            ConsumpItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
            ConsumpItemJnlLine.FindFirst();
            ItemJnlPostBatch(ConsumpItemJnlLine);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-3
          IF PerformIteration('19-3-3-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-4
          IF PerformIteration('19-3-4-10') THEN BEGIN
            CLEAR(PurchHeader);
            InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',291101D);
            ModifyPurchHeader(PurchHeader,291101D,'BLUE','TCS19-3-4',TRUE);

            WITH PurchLine DO BEGIN
              InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',1,'PALLET',250);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',3,'PALLET',153);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'A4_AV_RE','',4,'PALLET',300);
              ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'5_ST_RA','',1,'PALLET',125);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,50000,Type::Item,'1_FI_RE','11',2,'PALLET',146.5);
              ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,60000,Type::Item,'2_LI_RA','21',3,'PALLET',90);
              ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,70000,Type::Item,'A4_AV_RE','41',4,'PALLET',300);
              ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
              InsertPurchLine(PurchLine,PurchHeader,80000,Type::Item,'5_ST_RA','51',1,'PALLET',150);
              ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
            END;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-4-20') THEN
            PostPurchOrder(PurchHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-4-30') THEN BEGIN
            ItemJnlLine.Reset();
            ProdOrder.Reset();
            ProdOrder.FIND('-');
            InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',10000,281101D,
              ItemJnlLine."Entry Type"::Output,'101003','A','','BLUE','',
              2,'PCS',0,0);
            ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.",'101003');
            ItemJnlLine.VALIDATE("Order Line No.",10000);
            ItemJnlLine.VALIDATE("Source No.",'A');
            ItemJnlLine.VALIDATE("Output Quantity",2);
            ItemJnlLine.Modify();

            InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',20000,281101D,
              ItemJnlLine."Entry Type"::Output,'101004','B','','BLUE','',
              2,'PCS',0,0);
            ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.",'101004');
            ItemJnlLine.VALIDATE("Order Line No.",10000);
            ItemJnlLine.VALIDATE("Source No.",'B');
            ItemJnlLine.VALIDATE("Output Quantity",2);
            ItemJnlLine.Modify();

            InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',30000,281101D,
              ItemJnlLine."Entry Type"::Output,'101005','C','','BLUE','',
              2,'PCS',0,0);
            ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.",'101005');
            ItemJnlLine.VALIDATE("Order Line No.",10000);
            ItemJnlLine.VALIDATE("Source No.",'C');
            ItemJnlLine.VALIDATE("Output Quantity",2);
            ItemJnlLine.Modify();

            InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',40000,281101D,
              ItemJnlLine."Entry Type"::Output,'101006','D','','BLUE','',
              2,'PCS',0,0);
            ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.",'101006');
            ItemJnlLine.VALIDATE("Order Line No.",10000);
            ItemJnlLine.VALIDATE("Source No.",'D');
            ItemJnlLine.VALIDATE("Output Quantity",2);
            ItemJnlLine.Modify();

            OutputItemJnlLine.Reset();
            OutputItemJnlLine.SETRANGE("Journal Template Name",'OUTPUT');
            OutputItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
            OutputItemJnlLine.FindFirst();
            ItemJnlPostBatch(OutputItemJnlLine);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-4-40') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-5
          IF PerformIteration('19-3-5-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-6
          IF PerformIteration('19-3-6-10') THEN BEGIN
            CLEAR(CalcConsumption);
            ProdOrder.Reset();
            ProdOrder.SETRANGE("Location Code",'BLUE');
            ProdOrder.SETFILTER("Source No.",'%1','D3_SP_RE');
            CalcConsumption.InitializeRequest(051201D,1);
            CalcConsumption.SetTemplateAndBatchName('CONSUMP','DEFAULT');
            CalcConsumption.SETTABLEVIEW(ProdOrder);
            CalcConsumption.USEREQUESTPAGE(FALSE);
            CalcConsumption.RunModal();

            ConsumpItemJnlLine.Reset();
            ConsumpItemJnlLine.SETRANGE("Journal Template Name",'CONSUMP');
            ConsumpItemJnlLine.SETRANGE("Journal Batch Name",'DEFAULT');
            ConsumpItemJnlLine.FindFirst();
            ItemJnlPostBatch(ConsumpItemJnlLine);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-6-20') THEN BEGIN
            ItemJnlLine.Reset();
            ProdOrder.Reset();
            ProdOrder.FIND('-');
            InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',10000,051201D,
              ItemJnlLine."Entry Type"::Output,'101001','D3_SP_RE','','BLUE','',
              2,'PCS',0,0);
            ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.",'101001');
            ItemJnlLine.VALIDATE("Order Line No.",10000);
            ItemJnlLine.VALIDATE("Source No.",'D3_SP_RE');
            ItemJnlLine.VALIDATE("Output Quantity",1);
            ItemJnlLine.Modify();

            InsertItemJnlLine(ItemJnlLine,'OUTPUT','DEFAULT',20000,051201D,
              ItemJnlLine."Entry Type"::Output,'101002','D3_SP_RE','','BLUE','',
              1,'PCS',0,0);
            ItemJnlLine.VALIDATE("Order Type",ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.",'101002');
            ItemJnlLine.VALIDATE("Order Line No.",10000);
            ItemJnlLine.VALIDATE("Source No.",'D3_SP_RE');
            ItemJnlLine.VALIDATE("Variant Code",'31');
            ItemJnlLine.VALIDATE("Output Quantity",1);
            ItemJnlLine.Modify();

            CreateRes.CreateReservEntryFor(83,6,'OUTPUT','DEFAULT',0,10000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('D3_SP_RE','','BLUE','',051201D,0D,0,3);
            CreateRes.CreateReservEntryFor(83,6,'OUTPUT','DEFAULT',0,20000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('D3_SP_RE','31','BLUE','',051201D,0D,0,3);

            OutputItemJnlLine.Reset();
            OutputItemJnlLine.SETRANGE("Journal Template Name",'output');
            OutputItemJnlLine.SETRANGE("Journal Batch Name",'default');
            OutputItemJnlLine.FindFirst();
            ItemJnlPostBatch(OutputItemJnlLine);

            ProdOrder.Reset();
            ProdOrder.SETFILTER(Status,'<>%1',ProdOrder.Status::Finished);
            ProdOrder.FIND('-');
            REPEAT
              FinishProdOrder(ProdOrder,051201D,FALSE);
            UNTIL ProdOrder.Next() = 0;
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-6-30') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-7
          IF PerformIteration('19-3-7-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-8
          IF PerformIteration('19-3-8-10') THEN BEGIN
            CLEAR(SalesHeader);
            InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',061201D);
            ModifySalesHeader(SalesHeader,061201D,'BLUE',TRUE,TRUE);
            WITH SalesLine DO BEGIN
              InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'D3_SP_RE','',1,'PCS',150);
              InsertSalesLine(SalesLine,SalesHeader,20000,Type::Item,'D3_SP_RE','31',1,'PCS',152);
            END;
            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,10000,1,1,1,'SN01','','');
            CreateRes.CreateEntry('D3_SP_RE','','BLUE','',0D,061201D,0,3);

            CreateRes.CreateReservEntryFor(37,2,SalesHeader."No.",'',0,20000,1,1,1,'ST01','','');
            CreateRes.CreateEntry('D3_SP_RE','31','BLUE','',0D,061201D,0,3);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-8-20') THEN
            PostSalesOrder(SalesHeader);
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-8-30') THEN BEGIN
            PurchHeader.FIND('-');
            ReleasePurchDoc.Reopen(PurchHeader);
            ModifyPurchHeader(PurchHeader,071201D,'BLUE','TCS19-3-2',FALSE);

            ModifyPurchLine(PurchHeader,10000,0,2,234,0);
            ModifyPurchLine(PurchHeader,20000,0,3,33,0);
            ModifyPurchLine(PurchHeader,30000,0,3,20,0);
            ModifyPurchLine(PurchHeader,40000,0,1,105,0);
            ModifyPurchLine(PurchHeader,50000,0,2,240.5,0);
            ModifyPurchLine(PurchHeader,60000,0,3,34.5,0);
            ModifyPurchLine(PurchHeader,70000,0,3,35,0);
            ModifyPurchLine(PurchHeader,80000,0,1,120,0);

            PostPurchOrder(PurchHeader);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-8-40') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-9
          IF PerformIteration('19-3-9-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-10
          IF PerformIteration('19-3-10-10') THEN BEGIN
            PurchHeader.FIND('-');
            ReleasePurchDoc.Reopen(PurchHeader);
            ModifyPurchHeader(PurchHeader,081201D,'BLUE','TCS19-3-4',FALSE);

            ModifyPurchLine(PurchHeader,10000,0,1,247,0);
            ModifyPurchLine(PurchHeader,20000,0,3,45,0);
            ModifyPurchLine(PurchHeader,30000,0,4,30,0);
            ModifyPurchLine(PurchHeader,40000,0,1,115,0);
            ModifyPurchLine(PurchHeader,50000,0,2,260.5,0);
            ModifyPurchLine(PurchHeader,60000,0,3,48,0);
            ModifyPurchLine(PurchHeader,70000,0,4,45,0);
            ModifyPurchLine(PurchHeader,80000,0,1,140,0);

            PostPurchOrder(PurchHeader);
          END;
          IF LastIteration = ActualIteration THEN
            EXIT;

          IF PerformIteration('19-3-10-20') THEN
            AdjustItem('','',FALSE);
          IF LastIteration = ActualIteration THEN
            EXIT;

          // 19-3-11
          IF PerformIteration('19-3-11-10') THEN
            VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = ActualIteration THEN
            EXIT;
        END;
    end;

    [Scope('OnPrem')]
    procedure GetLastILENo(): Integer
    begin
        LastILENo := TestScriptMgmt.GetLastItemLedgEntryNo;
    end;

    [Scope('OnPrem')]
    procedure GetLastCLENo(): Integer
    begin
        LastCLENo := TestScriptMgmt.GetLastValuEntryNo;
    end;

    [Scope('OnPrem')]
    procedure GetLastGLENo(): Integer
    begin
        LastGLENo := TestScriptMgmt.GetLastGLEntryNo;
    end;

    [Scope('OnPrem')]
    procedure GetNextNo(var LastNo: Integer): Integer
    begin
        EXIT(TestScriptMgmt.GetNextNo(LastNo));
    end;

    [Scope('OnPrem')]
    procedure PerformIteration(NewActualIteration: Text[30]): Boolean
    begin
        ActualIteration := NewActualIteration;
        IterationActive := IterationActive OR (ActualIteration = FirstIteration);
        EXIT(IterationActive);
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
    procedure FinishProdOrder(ProdOrder: Record "Production Order";NewPostingDate: Date;NewUpdateUnitCost: Boolean)
    var
        ToProdOrder: Record "Production Order";
        ChgStatOnProdOrder: Codeunit "Prod. Order Status Management";
        WhseProdRelease: Codeunit "Whse.-Production Release";
        Status: Option Quote,Planned,"Firm Planned",Released,Finished;
    begin
        WITH ChgStatOnProdOrder DO BEGIN
          ChangeStatusOnProdOrder(ProdOrder,Status::Finished,NewPostingDate,NewUpdateUnitCost);

          WhseProdRelease.FinishedDelete(ToProdOrder);
        END;
    end;
}

