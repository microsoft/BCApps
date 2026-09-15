codeunit 103402 "Test Use Case 1"
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
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        CreateRes: Codeunit "Create Reserv. Entry";
        ItemChargeAssigntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        Item: Record Item;
        SelectionForm: Page Page103404;
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        DelInvSalesOrders: Report "Delete Invoiced Sales Orders";
        TestScriptMgmt: Codeunit Codeunit103492;
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
        ItemJnlLineNo: Integer;
        TestResultsPath: Text[250];
        FirstIteration: Text[30];
        LastIteration: Text[30];
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
          2:
            PerformTestCase2;
          3:
            PerformTestCase3;
          4:
            PerformTestCase4;
          5:
            PerformTestCase5;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-1-1
          SetGlobalPreconditions;

          IF LastIteration = '1-1-1-10' THEN
            EXIT;

          // 1-1-2
          SetAutoCostPost(TRUE);
          SetExpCostPost(FALSE);
          SetAddRepCurr('DEM');
          GetLastILENo;
          GetLastCLENo;
          GetLastGLENo;

          // Create and post Item Journal Lines
          ItemJnlLineNo := 10000;
          ClearDimensions;
          InsertDimension('AREA','30','');
          InsertDimension('DEPARTMENT','PROD','');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),200101D,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS1-1-2','7_ST_OV','','BLUE','',1,'PALLET',1100,0);

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),210101D,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS1-1-2','7_ST_OV','71','BLUE','',1,'PALLET',1200,0);

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),220101D,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",'TCS1-1-2','7_ST_OV','','BLUE','',1,'PALLET',1300,0);

          IF LastIteration = '1-1-2-10' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-1-2-20' THEN
            EXIT;

          // 1-1-3
          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-1-3-10' THEN
            EXIT;

          // 1-1-4
          ClearDimensions;
          InsertDimension('DEPARTMENT','SALES','');
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',230101D);
          ModifyPurchHeader(PurchHeader,230101D,'BLUE','',TRUE);

          IF LastIteration = '1-1-4-10' THEN
            EXIT;

          ClearDimensions;
          InsertDimension('AREA','30','');
          InsertDimension('DEPARTMENT','PROD','');
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'7_ST_OV','',11,'PCS',110);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'7_ST_OV','71',11,'PCS',120);
            ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'7_ST_OV','',11,'PCS',130);
            ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);
          END;

          IF LastIteration = '1-1-4-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-1-4-30' THEN
            EXIT;

          // 1-1-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-1-5-10' THEN
            EXIT;

          // 1-1-6
          ModifyPurchHeader(PurchHeader,240101D,'','',TRUE);

          IF LastIteration = '1-1-6-10' THEN
            EXIT;

          ModifyPurchLine(PurchHeader,10000,4,0,120,0);
          ModifyPurchLine(PurchHeader,20000,3,0,130,0);
          ModifyPurchLine(PurchHeader,30000,2,0,140,0);

          IF LastIteration = '1-1-6-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-1-6-30' THEN
            EXIT;

          // 1-1-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-1-7-10' THEN
            EXIT;

          // 1-1-8
          ModifyPurchHeader(PurchHeader,250101D,'','',TRUE);

          IF LastIteration = '1-1-8-10' THEN
            EXIT;

          ModifyPurchLine(PurchHeader,10000,5,0,150,0);
          ModifyPurchLine(PurchHeader,20000,5,0,150,0);
          ModifyPurchLine(PurchHeader,30000,5,0,150,0);

          IF LastIteration = '1-1-8-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-1-8-30' THEN
            EXIT;

          AdjustItem('','',FALSE);
          IF LastIteration = '1-1-8-40' THEN
            EXIT;

          CLEAR(PostInvtCostToGL);
          PostInvtCostToGL.InitializeRequest(0,'TCS1-1-8',TRUE);
          PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase1-1-8.pdf');
          IF LastIteration = '1-1-8-50' THEN
            EXIT;

          // 1-1-9
          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-1-9-10' THEN
            EXIT;

          // 1-1-10

          ClearDimensions;
          InsertDimension('DEPARTMENT','SALES','');
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',250101D);
          ModifyPurchHeader(PurchHeader,250101D,'BLUE','TCS1-1-10',TRUE);

          IF LastIteration = '1-1-10-10' THEN
            EXIT;

          ClearDimensions;
          InsertDimension('AREA','30','');
          InsertDimension('DEPARTMENT','PROD','');
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'7_ST_OV','',11,'PCS',110);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::"Charge (Item)",'UPS','',1,'',100);
            InsertPurchLine(PurchLine,PurchHeader,30000,Type::"Charge (Item)",'GPS','',1,'',100);

            IF LastIteration = '1-1-10-20' THEN
              EXIT;

            Reset();
            SETRANGE("Document No.",PurchHeader."No.");
            SETRANGE("Line No.",20000);
            FindFirst();
            InsertPurchChargeAssignLine(PurchLine,20000,PurchHeader."Document Type",PurchHeader."No.",
              10000,'7_ST_OV');
            ModifyPurchChargeAssignLine(PurchHeader,20000,20000,1);

            IF LastIteration = '1-1-10-30' THEN
              EXIT;

            SETRANGE("Line No.",30000);
            FindFirst();
            InsertPurchChargeAssignLine(PurchLine,30000,PurchHeader."Document Type",PurchHeader."No.",
              10000,'7_ST_OV');
            WITH PurchRcptHeader DO BEGIN
              FindLast();
              CLEAR(PurchRcptLine);
              ItemChargeAssgntPurch.FindLast();
              PurchRcptLine.SETRANGE("Document No.","No.");
              ItemChargeAssigntPurch.CreateRcptChargeAssgnt(PurchRcptLine,ItemChargeAssgntPurch);
              ItemChargeAssgntPurch.SETFILTER("Line No.",'%1..%2',30000,40000);
              ItemChargeAssgntPurch.DeleteAll();
              PurchLine.UpdateItemChargeAssgnt();
              ItemChargeAssigntPurch.AssignItemCharges(PurchLine,1,100,format(1));
            END;
          END;

          IF LastIteration = '1-1-10-40' THEN
            EXIT;

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-1-10-50' THEN
            EXIT;

          // 1-1-11
          VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-1-11-10' THEN
            EXIT;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-2-1
          SetGlobalPreconditions;

          IF LastIteration = '1-2-1-10' THEN
            EXIT;

          // 1-2-2
          SetAutoCostPost(FALSE);
          SetExpCostPost(TRUE);
          SetAddRepCurr('DEM');
          GetLastILENo;
          GetLastCLENo;
          GetLastGLENo;

          ClearDimensions;
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',010101D);
          ModifyPurchHeader(PurchHeader,010101D,'','',TRUE);
          IF LastIteration = '1-2-2-10' THEN
            EXIT;

          ClearDimensions;
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',11,'PCS',44.44);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);
          END;
          IF LastIteration = '1-2-2-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);
          IF LastIteration = '1-2-4-30' THEN
            EXIT;

          CLEAR(PostInvtCostToGL);
          PostInvtCostToGL.InitializeRequest(1,'',TRUE);
          PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase1-2-2.pdf');
          IF LastIteration = '1-2-2-40' THEN
            EXIT;

          // 1-2-3
          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = '1-2-3-10' THEN
            EXIT;

          // 1-2-4
          ModifyPurchHeader(PurchHeader,030101D,'','',TRUE);
          IF LastIteration = '1-2-4-10' THEN
            EXIT;

          ModifyPurchLine(PurchHeader,10000,3,0,55.55,0);
          IF LastIteration = '1-2-4-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);
          IF LastIteration = '1-2-4-30' THEN
            EXIT;

          CLEAR(PostInvtCostToGL);
          PostInvtCostToGL.InitializeRequest(1,'',TRUE);
          PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase1-2-4.pdf');
          IF LastIteration = '1-2-4-40' THEN
            EXIT;

          // 1-2-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = '1-2-5-10' THEN
            EXIT;

          // 1-2-6
          ModifyPurchHeader(PurchHeader,050101D,'','',TRUE);
          IF LastIteration = '1-2-6-10' THEN
            EXIT;

          ModifyPurchLine(PurchHeader,10000,5,0,66.66,0);
          IF LastIteration = '1-2-6-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);
          IF LastIteration = '1-2-6-30' THEN
            EXIT;

          CLEAR(PostInvtCostToGL);
          PostInvtCostToGL.InitializeRequest(1,'',TRUE);
          PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase1-2-6.pdf');
          IF LastIteration = '1-2-6-40' THEN
            EXIT;

          // 1-2-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo,LastCLENo,LastGLENo);
          IF LastIteration = '1-2-7-10' THEN
            EXIT;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-3-1
          SetGlobalPreconditions;

          IF LastIteration = '1-3-1-10' THEN
            EXIT;

          // 1-3-2
          SetAutoCostPost(FALSE);
          SetExpCostPost(TRUE);
          SetAddRepCurr('DEM');
          GetLastILENo;
          GetLastCLENo;
          GetLastGLENo;

          ClearDimensions;
          InsertDimension('DEPARTMENT','SALES','');
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',010101D);
          ModifyPurchHeader(PurchHeader,010101D,'BLUE','',TRUE);

          IF LastIteration = '1-3-2-10' THEN
            EXIT;

          ClearDimensions;
          InsertDimension('AREA','30','');
          InsertDimension('DEPARTMENT','PROD','');
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',14,'PCS',15.99);
            ModifyPurchLine(PurchHeader,"Line No.",13,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'2_LI_RA','',10,'PCS',25.77);
            ModifyPurchLine(PurchHeader,"Line No.",9,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'1_FI_RE','',2,'PALLET',166.66);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'2_LI_RA','',2,'PALLET',77.77);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;

          IF LastIteration = '1-3-2-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-3-2-30' THEN
            EXIT;

          CLEAR(PostInvtCostToGL);
          PostInvtCostToGL.InitializeRequest(0,'TCS1-3-2',TRUE);
          PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase1-3-2.pdf');
          IF LastIteration = '1-3-2-40' THEN
            EXIT;

          // 1-3-3
          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-3-3-10' THEN
            EXIT;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-4-1
          SetGlobalPreconditions;

          IF LastIteration = '1-4-1-10' THEN
            EXIT;

          // 1-4-2
          SetAutoCostPost(FALSE);
          SetExpCostPost(TRUE);
          SetAddRepCurr('DEM');
          GetLastILENo;
          GetLastCLENo;
          GetLastGLENo;

          // Create and post Item Journal Lines
          ItemJnlLineNo := 10000;
          ClearDimensions;
          InsertDimension('AREA','30','');
          InsertDimension('DEPARTMENT','PROD','');
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),010101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-4-2','4_AV_RE','','BLUE','',1,'PCS',55.55,0);

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),010101D,
            ItemJnlLine."Entry Type"::Purchase,'TCS1-4-2','6_AV_OV','','BLUE','',1,'PCS',66.66,0);

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),020101D,
            ItemJnlLine."Entry Type"::Sale,'TCS1-4-2','4_AV_RE','','BLUE','',1,'PALLET',1100,0);

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),020101D,
            ItemJnlLine."Entry Type"::Sale,'TCS1-4-2','5_ST_RA','','BLUE','',1,'PALLET',1200,0);

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),020101D,
            ItemJnlLine."Entry Type"::Sale,'TCS1-4-2','6_AV_OV','','BLUE','',1,'PALLET',1300,0);

          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',GetNextNo(ItemJnlLineNo),020101D,
            ItemJnlLine."Entry Type"::Sale,'TCS1-4-2','7_ST_OV','','BLUE','',1,'PALLET',1300,0);

          IF LastIteration = '1-4-2-10' THEN
            EXIT;

          ItemJnlPostBatch(ItemJnlLine);

          IF LastIteration = '1-4-2-20' THEN
            EXIT;

          // 1-4-3
          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-4-3-10' THEN
            EXIT;

          // 1-4-4
          ClearDimensions;
          InsertDimension('DEPARTMENT','SALES','');
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'30000',030101D);
          ModifyPurchHeader(PurchHeader,030101D,'BLUE','',TRUE);

          IF LastIteration = '1-4-4-10' THEN
            EXIT;

          ClearDimensions;
          InsertDimension('AREA','30','');
          InsertDimension('DEPARTMENT','PROD','');
          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'4_AV_RE','',14,'PCS',66.66);
            ModifyPurchLine(PurchHeader,"Line No.",4,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,20000,Type::Item,'5_ST_RA','',20,'PCS',60);
            ModifyPurchLine(PurchHeader,"Line No.",3,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,30000,Type::Item,'6_AV_OV','',14,'PCS',77.77);
            ModifyPurchLine(PurchHeader,"Line No.",2,0,0,0);

            InsertPurchLine(PurchLine,PurchHeader,40000,Type::Item,'7_ST_OV','',20,'PCS',88.88);
            ModifyPurchLine(PurchHeader,"Line No.",1,0,0,0);
          END;

          IF LastIteration = '1-4-4-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-4-4-30' THEN
            EXIT;

          // 1-4-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-4-5-10' THEN
            EXIT;

          // 1-4-6
          ModifyPurchHeader(PurchHeader,040101D,'','',TRUE);

          IF LastIteration = '1-4-6-10' THEN
            EXIT;

          ModifyPurchLine(PurchHeader,10000,1,0,60,0);
          ModifyPurchLine(PurchHeader,20000,2,0,66,0);
          ModifyPurchLine(PurchHeader,30000,3,0,70,0);
          ModifyPurchLine(PurchHeader,40000,4,0,80,0);

          IF LastIteration = '1-4-6-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-4-6-30' THEN
            EXIT;

          // 1-4-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-4-7-10' THEN
            EXIT;

          // 1-4-8
          ModifyPurchHeader(PurchHeader,050101D,'','',TRUE);

          IF LastIteration = '1-4-8-10' THEN
            EXIT;

          ModifyPurchLine(PurchHeader,10000,5,0,70,0);
          ModifyPurchLine(PurchHeader,20000,5,0,75,0);
          ModifyPurchLine(PurchHeader,30000,5,0,80,0);
          ModifyPurchLine(PurchHeader,40000,5,0,85,0);

          IF LastIteration = '1-4-8-20' THEN
            EXIT;

          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-4-8-30' THEN
            EXIT;

          AdjustItem('','',FALSE);

          IF LastIteration = '1-4-8-40' THEN
            EXIT;

          CLEAR(PostInvtCostToGL);
          PostInvtCostToGL.InitializeRequest(1,'',TRUE);
          PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase1-4-8.pdf');

          IF LastIteration = '1-4-8-50' THEN
            EXIT;

          // 1-4-9
          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-4-9-10' THEN
            EXIT;

          // 1-4-10

          ClearDimensions;
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',250101D);
          ModifyPurchHeader(PurchHeader,040101D,'BLUE','TCS1-4-10',TRUE);
          PurchHeader.VALIDATE("Order Date",040101D);
          PurchHeader.Modify();

          IF LastIteration = '1-4-10-10' THEN
            EXIT;

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'1_FI_RE','',10,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",10,10,10,0);
            VALIDATE("Indirect Cost %",10);
            Modify();
          END;

          IF LastIteration = '1-4-10-20' THEN
            EXIT;

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-4-10-30' THEN
            EXIT;

          // 1-4-11
          VerifyPostCondition(UseCaseNo,TestCaseNo,11,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-4-11-10' THEN
            EXIT;

          // 1-4-12

          CLEAR(PostInvtCostToGL);
          PostInvtCostToGL.InitializeRequest(1,'',TRUE);
          PostInvtCostToGL.SAVEASPDF(TestResultsPath + 'TestCase1-4-12.pdf');

          IF LastIteration = '1-4-12-10' THEN
            EXIT;

          // 1-4-13
          VerifyPostCondition(UseCaseNo,TestCaseNo,13,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-4-13-10' THEN
            EXIT;
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        WITH TestScriptMgmt DO BEGIN
          // 1-5-1
          SetGlobalPreconditions;

          SetAutoCostPost(TRUE);
          SetExpCostPost(TRUE);
          SetAddRepCurr('DEM');

          Item.GET('2_LI_RA');
          Item.VALIDATE("Item Tracking Code",'LOTALL');
          Item.Modify();

          GetLastILENo;
          GetLastCLENo;
          GetLastGLENo;

          IF LastIteration = '1-5-1-10' THEN
            EXIT;

          // 1-5-2

          ClearDimensions;
          CLEAR(PurchHeader);
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',030101D);
          ModifyPurchHeader(PurchHeader,030101D,'BLUE','TCS1-5-2',TRUE);
          PurchHeader.VALIDATE("Order Date",030101D);
          PurchHeader.Modify();

          IF LastIteration = '1-5-2-10' THEN
            EXIT;

          WITH PurchLine DO BEGIN
            InsertPurchLine(PurchLine,PurchHeader,10000,Type::Item,'2_LI_RA','',100,'PCS',10);
            ModifyPurchLine(PurchHeader,"Line No.",100,100,10,0);
            InsertPurchLine(PurchLine,PurchHeader,20000,Type::"Charge (Item)",'GPS','',1,'',50);
            ModifyPurchLine(PurchHeader,"Line No.",1,1,50,0);
          END;

          IF LastIteration = '1-5-2-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,10,10,'','LOT01','');
          CreateRes.CreateEntry('2_LI_RA','','BLUE','',030101D,030101D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,30,30,'','LOT02','');
          CreateRes.CreateEntry('2_LI_RA','','BLUE','',030101D,030101D,0,3);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,60,60,'','LOT03','');
          CreateRes.CreateEntry('2_LI_RA','','BLUE','',030101D,030101D,0,2);

          IF LastIteration = '1-5-2-30' THEN
            EXIT;

          InsertPurchChargeAssignLine(PurchLine,20000,PurchHeader."Document Type",PurchHeader."No.",10000,'2_LI_RA');
          ModifyPurchChargeAssignLine(PurchHeader,20000,20000,1);

          IF LastIteration = '1-5-2-40' THEN
            EXIT;

          PurchHeader.Receive := TRUE;
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '1-5-2-50' THEN
            EXIT;

          // 1-5-3

          VerifyPostCondition(UseCaseNo,TestCaseNo,3,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-5-3-10' THEN
            EXIT;

          // 1-5-4
          ClearDimensions;
          CLEAR(SalesHeader);
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'10000',040101D);
          ModifySalesHeader(SalesHeader,040101D,'BLUE',FALSE,TRUE);

          IF LastIteration = '1-5-4-10' THEN
            EXIT;

          WITH SalesLine DO BEGIN
            InsertSalesLine(SalesLine,SalesHeader,10000,Type::Item,'2_LI_RA','',20,'PCS',12);
            ModifySalesLine(SalesHeader,"Line No.",10,10,12,0,TRUE);
            InsertSalesLine(SalesLine,SalesHeader,20000,Type::"Charge (Item)",'GPS','',1,'',10);
            ModifySalesLine(SalesHeader,"Line No.",1,1,10,0,TRUE);
          END;

          IF LastIteration = '1-5-4-20' THEN
            EXIT;

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,10,10,'','LOT01','');
          CreateRes.CreateEntry('2_LI_RA','','BLUE','',040101D,040101D,0,2);
          // Bug 254185 change - set IT only for 10 as only 10 will be shipped.
          // CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,10,'','LOT02');
          // CreateRes.CreateEntry('2_LI_RA','','BLUE','',040101D,040101D,0,2);

          IF LastIteration = '1-5-4-30' THEN
            EXIT;

          WITH SalesLine DO BEGIN
            GET(SalesHeader."Document Type",SalesHeader."No.",20000);
            InsertSalesChargeAssignLine(SalesLine,10000,"Document Type"::Order,"Document No.",10000,'2_LI_RA');
            ModifySalesChargeAssignLine(SalesHeader,"Line No.",10000,1);
          END;

          IF LastIteration = '1-5-4-40' THEN
            EXIT;

          SalesHeader.Ship := TRUE;
          SalesHeader.Invoice := FALSE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-5-4-50' THEN
            EXIT;

          // 1-5-5

          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-5-5-10' THEN
            EXIT;

          // 1-5-6

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'10000',081101D);
          ModifySalesHeader(SalesHeader,080101D,'BLUE',TRUE,FALSE);

          IF LastIteration = '1-5-6-10' THEN
            EXIT;

          CLEAR(SalesShipmentLine);
          SalesShipmentLine.SETRANGE("Sell-to Customer No.",'10000');
          IF SalesShipmentLine.FindFirst() then BEGIN
            SalesGetShipment.SetSalesHeader(SalesHeader);
            SalesGetShipment.CreateInvLines(SalesShipmentLine);
          END;

          IF LastIteration = '1-5-6-20' THEN
            EXIT;

          PostSalesOrder(SalesHeader);

          IF LastIteration = '1-5-6-30' THEN
            EXIT;

          CLEAR(DelInvSalesOrders);
          DelInvSalesOrders.USEREQUESTPAGE(FALSE);
          DelInvSalesOrders.RunModal();

          IF LastIteration = '1-5-6-40' THEN
            EXIT;

          // 1-5-7

          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-5-7-10' THEN
            EXIT;

          // 1-5-8

          AdjustItem('','',FALSE);

          IF LastIteration = '1-5-8-10' THEN
            EXIT;

          // 1-5-9

          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo,LastCLENo,LastGLENo);

          IF LastIteration = '1-5-9-10' THEN
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

