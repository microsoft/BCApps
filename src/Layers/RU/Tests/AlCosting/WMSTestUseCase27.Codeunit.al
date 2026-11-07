codeunit 103310 "WMS Test Use Case 27"
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
        TestscriptMgt.InitializeOutput(CODEUNIT::"WMS Test Use Case 27");

        QASetup.MODIFYALL("Use Hardcoded Reference",TRUE);
        Test(103310,27,0,'',1);

        TestscriptMgt.ShowTestscriptResult;
    end;

    var
        Item: Record Item;
        TestCase: Record Table103301;
        UseCase: Record Table103300;
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
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseActivLine: Record "Warehouse Activity Line";
        ItemChargeAssignPurch: Record "Item Charge Assignment (Purch)";
        ItemJnlLine: Record "Item Journal Line";
        CalcQtyOnHand: Report "Calculate Inventory";
        CreateRes: Codeunit "Create Reserv. Entry";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        SNCode: Code[20];
        i: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 27-1-1
          SetGlobalPreconditions;
          // this is code added later to change the item no. so that sorting is same in the reference data for both native as well as SQL.
          // this test shall use an item called 80100-T instead of T_TEST
          CreateRenamedItem('T_TEST', '80100-T');

          IF LastIteration = '27-1-1-10' THEN EXIT;

        // 27-1-2
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'40000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','TCS27-1-2',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80102-T','','Green',11,'PCS',6.3,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100-T','T1','Green',11,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','Green',3,'PCS',0.5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'80002','','Green',2,'PCS',0.5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'80002','','Green',1,'PCS',0.5,FALSE);
          IF LastIteration = '27-1-2-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,'SN01','LOT01','');
          CreateRes.CreateEntry('80100-T','T1','GREEN','',251101D,251101D,0,2);
          IF LastIteration = '27-1-2-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'Green');
          IF LastIteration = '27-1-2-30' THEN EXIT;

        //27-1-3
          WhseRcptHeader.SETRANGE("Location Code",'Green');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",10000,'','',6);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",20000,'','',6);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",30000,'','',3);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",40000,'','',2);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",50000,'','',1);
          IF LastIteration = '27-1-3-10' THEN EXIT;

          SNCode := 'ST00';
          FOR i := 1 TO 6 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80102-T','','Green','',251101D,251101D,0,2);
          END;
          SNCode := 'SN01';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'LOT02','');
            CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          END;
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,3,3,'','LT01','');
            CreateRes.CreateEntry('80002','','Green','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,2,2,'','LT02','');
            CreateRes.CreateEntry('80002','','Green','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,50000,1,1,1,'','LT03','');
            CreateRes.CreateEntry('80002','','Green','',251101D,251101D,0,2);
          IF LastIteration = '27-1-3-20' THEN EXIT;

          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '27-1-3-30' THEN EXIT;

          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '27-1-3-40' THEN EXIT;

        //27-1-4
          WhseRcptHeader.SETRANGE("Location Code",'Green');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",10000,'','',5);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",20000,'','',5);
          IF LastIteration = '27-1-4-10' THEN EXIT;

          SNCode := 'ST06';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80102-T','','Green','',251101D,251101D,0,2);
          END;
          SNCode := 'SN06';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'LOT03','');
            CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          END;
          IF LastIteration = '27-1-4-20' THEN EXIT;

          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '27-1-4-30' THEN EXIT;

          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '27-1-4-40' THEN EXIT;

        //27-1-5
          VerifyPostCondition(UseCaseNo,TestCaseNo,5,LastILENo);

          IF LastIteration = '27-1-5-10' THEN EXIT;

        //27-1-6
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'40000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Green',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80100-T','T1',2,'BOX',15.05,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100-T','T1',3,'BOX',15.05,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'80100-T','T1',4,'BOX',15.05,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'80216-T','',14,'PCS',0.8,'Green','');
          END;
          IF LastIteration = '27-1-6-10' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromSales(SalesHeader,WhseRcptHeader,'Green');
          IF LastIteration = '27-1-6-20' THEN EXIT;

        //27-1-7
          WhseRcptHeader.SETRANGE("Location Code",'Green');
          WhseRcptHeader.FindFirst();
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",10000,'','',1);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",20000,'','',1);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",30000,'','',1);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",40000,'','',14);
          IF LastIteration = '27-1-7-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,'SN12','LOT04','');
          CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,1,1,'SN13','LOT05','');
          CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,30000,1,1,1,'SN14','LOT06','');
          CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,40000,1,9,9,'','LN01','');
          CreateRes.CreateEntry('80216-T','','Green','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,40000,1,5,5,'','LN02','');
          CreateRes.CreateEntry('80216-T','','Green','',251101D,251101D,0,2);
          IF LastIteration = '27-1-7-20' THEN EXIT;

          CLEAR(WhseRcptLine);
          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '27-1-7-30' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '27-1-7-40' THEN EXIT;

        //27-1-8
          WhseRcptHeader.SETRANGE("Location Code",'Green');
          WhseRcptHeader.FIND('-');
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",10000,'','',1);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",20000,'','',2);
          ModifyWhseRcptLine(WhseRcptLine,WhseRcptHeader."No.",30000,'','',3);
          IF LastIteration = '27-1-8-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,1,1,'SN15','LOT07','');
          CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          SNCode := 'SN15';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,1,1,SNCode,'LOT08','');
            CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          END;
          SNCode := 'SN17';
          FOR i := 1 TO 3 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,30000,1,1,1,SNCode,'LOT09','');
            CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          END;
          IF LastIteration = '27-1-8-20' THEN EXIT;

          CLEAR(WhseRcptLine);
          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '27-1-8-30' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '27-1-8-40' THEN EXIT;

        // 27-1-9
          VerifyPostCondition(UseCaseNo,TestCaseNo,9,LastILENo);

          IF LastIteration = '27-1-9-10' THEN EXIT;

        // 27-1-10
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'40000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','TCS27-1-3',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80102-T','','Green',11,'PCS',6.3,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100-T','T1','Green',11,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80216-T','','Green',3,'PCS',0.5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'80216-T','','Green',2,'PCS',0.5,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'80216-T','','Green',1,'PCS',0.5,FALSE);
          IF LastIteration = '27-1-10-10' THEN EXIT;

          SNCode := 'ST11';
          FOR i := 1 TO 11 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80102-T','','Green','',251101D,251101D,0,2);
          END;
          SNCode := 'SN20';
          FOR i := 1 TO 11 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'LOT02','');
            CreateRes.CreateEntry('80100-T','T1','Green','',251101D,251101D,0,2);
          END;
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,3,3,'','LN03','');
            CreateRes.CreateEntry('80216-T','','Green','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,2,2,'','LN04','');
            CreateRes.CreateEntry('80216-T','','Green','',251101D,251101D,0,2);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,50000,1,1,1,'','LN05','');
            CreateRes.CreateEntry('80216-T','','Green','',251101D,251101D,0,2);
          IF LastIteration = '27-1-10-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);
          CLEAR(WhseRcptHeader);
          CreateWhseRcptFromPurch(PurchHeader,WhseRcptHeader,'Green');
          IF LastIteration = '27-1-10-30' THEN EXIT;

          CLEAR(WhseRcptLine);
          WhseRcptLine.FindFirst();
          PostWhseReceipt(WhseRcptLine);
          IF LastIteration = '27-1-10-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '27-1-10-50' THEN EXIT;

        // 27-1-11
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Invoice,'40000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','TCS27-1-4',FALSE);

          IF PurchRcptLine.FIND('-') THEN BEGIN
            PurchGetReceipt.SetPurchHeader(PurchHeader);
            REPEAT
              PurchGetReceipt.CreateInvLines(PurchRcptLine)
            UNTIL PurchRcptLine.Next() =0;
          END;
          IF LastIteration = '27-1-11-10' THEN EXIT;

          InsertPurchLine(
            PurchLine,PurchHeader,160000,PurchLine.Type::"Charge (Item)",'UPS','','Green',1,'PCS',100,FALSE);

          WITH ItemChargeAssignPurch DO BEGIN
            Init();
            "Document Type" := "Document Type"::Invoice;
            "Document No." := '1001';
            "Document Line No." := 160000;
            "Line No." := 10000;
            "Item Charge No.":= 'UPS';
            "Item No." := '80100-T';
            "Qty. to Assign" := 1;
            "Unit Cost" := 100;
            "Amount to Assign" := 100;
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Receipt;
            "Applies-to Doc. No." := '107001';
            "Applies-to Doc. Line No." := 20000;
            INSERT(TRUE);
          END;
          IF LastIteration = '27-1-11-20' THEN EXIT;

          PostPurchOrder(PurchHeader);
          IF LastIteration = '27-1-11-30' THEN EXIT;

        //27-1-12
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
          IF LastIteration = '27-1-12-10' THEN EXIT;

        // 27-1-13
          VerifyPostCondition(UseCaseNo,TestCaseNo,13,LastILENo);

          IF LastIteration = '27-1-13-10' THEN EXIT;

        // 27-1-14

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::Order,'10000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'BLUE','TCS27-1-14',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','BLUE',11,'PCS',630,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100-T','T2','BLUE',7,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','BLUE',19,'PCS',630,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'80100-T','T2','BLUE',6,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'80100-T','T1','BLUE',3,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,60000,PurchLine.Type::Item,'80100-T','T1','BLUE',4,'BOX',10.01,FALSE);

          IF LastIteration = '27-1-14-10' THEN EXIT;

          SNCode := 'SX00';
          FOR i := 1 TO 7 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80100-T','T2','BLUE','',251101D,251101D,0,2);
          END;
          SNCode := 'SX07';
          FOR i := 1 TO 6 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,40000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80100-T','T2','BLUE','',251101D,251101D,0,2);
          END;
          SNCode := 'ST00';
          FOR i := 1 TO 3 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,50000,1,1,1,SNCode,'LX01','');
            CreateRes.CreateEntry('80100-T','T1','BLUE','',251101D,251101D,0,2);
          END;
          SNCode := 'ST03';
          FOR i := 1 TO 4 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,60000,1,1,1,SNCode,'LX01','');
            CreateRes.CreateEntry('80100-T','T1','BLUE','',251101D,251101D,0,2);
          END;
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,10000,1,11,11,'','LT01','');
          CreateRes.CreateEntry('80002','','BLUE','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(39,1,PurchHeader."No.",'',0,30000,1,19,19,'','LT02','');
          CreateRes.CreateEntry('80002','','BLUE','',251101D,251101D,0,2);

          IF LastIteration = '27-1-14-20' THEN EXIT;

          PurchHeader.Reset();
          PurchHeader.FindLast();
          PurchHeader.Receive := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '27-1-14-30' THEN EXIT;

          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",10000);
          PurchLine.VALIDATE("Qty. to Invoice",0);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",20000);
          PurchLine.VALIDATE("Qty. to Invoice",7);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",30000);
          PurchLine.VALIDATE("Qty. to Invoice",19);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",40000);
          PurchLine.VALIDATE("Qty. to Invoice",0);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",50000);
          PurchLine.VALIDATE("Qty. to Invoice",0);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",60000);
          PurchLine.VALIDATE("Qty. to Invoice",4);
          PurchLine.Modify();

          IF LastIteration = '27-1-14-40' THEN EXIT;

          PurchHeader.Reset();
          PurchHeader.FindLast();
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '27-1-14-50' THEN EXIT;

        // 27-1-15

          VerifyPostCondition(UseCaseNo,TestCaseNo,15,LastILENo);

          IF LastIteration = '27-1-15-10' THEN EXIT;

        // 27-1-16

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'40000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'BLUE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80002','',11,'PCS',930,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'80100-T','T2',7,'BOX',10.01,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::Item,'80002','',19,'PCS',630,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,40000,SalesLine.Type::Item,'80100-T','T2',6,'BOX',10.01,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,50000,SalesLine.Type::Item,'80100-T','T1',3,'BOX',10.01,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,60000,SalesLine.Type::Item,'80100-T','T1',4,'BOX',10.01,'BLUE','');

          IF LastIteration = '27-1-16-10' THEN EXIT;

          SNCode := 'SX00';
          FOR i := 1 TO 7 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80100-T','T2','BLUE','',251101D,251101D,0,2);
          END;
          SNCode := 'SX07';
          FOR i := 1 TO 6 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,40000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80100-T','T2','BLUE','',251101D,251101D,0,2);
          END;
          SNCode := 'ST00';
          FOR i := 1 TO 3 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,50000,1,1,1,SNCode,'LX01','');
            CreateRes.CreateEntry('80100-T','T1','BLUE','',251101D,251101D,0,2);
          END;
          SNCode := 'ST03';
          FOR i := 1 TO 4 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,60000,1,1,1,SNCode,'LX01','');
            CreateRes.CreateEntry('80100-T','T1','BLUE','',251101D,251101D,0,2);
          END;
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,11,11,'','LT01','');
          CreateRes.CreateEntry('80002','','BLUE','',251101D,251101D,0,2);
          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,19,19,'','LT02','');
          CreateRes.CreateEntry('80002','','BLUE','',251101D,251101D,0,2);

          IF LastIteration = '27-1-16-20' THEN EXIT;

          SalesHeader.Reset();
          SalesHeader.FindFirst();
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '27-1-16-30' THEN EXIT;

          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",10000);
          SalesLine."Qty. to Invoice" := 0;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",20000);
          SalesLine."Qty. to Invoice" := 7;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",30000);
          SalesLine."Qty. to Invoice" := 19;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",40000);
          SalesLine."Qty. to Invoice" := 0;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",50000);
          SalesLine."Qty. to Invoice" := 0;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",60000);
          SalesLine."Qty. to Invoice" := 4;
          SalesLine.Modify();

          IF LastIteration = '27-1-16-40' THEN EXIT;

          SalesHeader.Reset();
          SalesHeader.FindFirst();
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '27-1-16-50' THEN EXIT;

        // 27-1-17

          VerifyPostCondition(UseCaseNo,TestCaseNo,17,LastILENo);

          IF LastIteration = '27-1-17-10' THEN EXIT;

        // 27-1-18

          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::"Return Order",'40000',261101D);
          ModifySalesHeader(SalesHeader,261101D,'BLUE',TRUE,FALSE);

          InsertSalesLine(
            SalesLine,SalesHeader,10000,SalesLine.Type::Item,'80002','',3,'PCS',930,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,20000,SalesLine.Type::Item,'80100-T','T2',2,'BOX',10.01,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,30000,SalesLine.Type::Item,'80002','',7,'PCS',630,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,40000,SalesLine.Type::Item,'80100-T','T2',1,'BOX',10.01,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,50000,SalesLine.Type::Item,'80100-T','T1',1,'BOX',10.01,'BLUE','');
          InsertSalesLine(
            SalesLine,SalesHeader,60000,SalesLine.Type::Item,'80100-T','T1',1,'BOX',10.01,'BLUE','');

          IF LastIteration = '27-1-18-10' THEN EXIT;

          SNCode := 'SX00';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80100-T','T2','BLUE','',261101D,261101D,0,2);
          END;
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,40000,1,1,1,'SX08','','');
          CreateRes.CreateEntry('80100-T','T2','BLUE','',261101D,261101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,50000,1,1,1,'ST01','LX01','');
          CreateRes.CreateEntry('80100-T','T1','BLUE','',261101D,261101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,60000,1,1,1,'ST04','LX01','');
          CreateRes.CreateEntry('80100-T','T1','BLUE','',261101D,261101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,10000,1,3,3,'','LT01','');
          CreateRes.CreateEntry('80002','','BLUE','',261101D,261101D,0,2);
          CreateRes.CreateReservEntryFor(37,5,SalesHeader."No.",'',0,30000,1,7,7,'','LT02','');
          CreateRes.CreateEntry('80002','','BLUE','',261101D,261101D,0,2);

          IF LastIteration = '27-1-18-20' THEN EXIT;

          SalesHeader.Reset();
          SalesHeader.FindLast();
          SalesHeader.Receive := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '27-1-18-30' THEN EXIT;

          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",10000);
          SalesLine."Qty. to Invoice" := 3;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",20000);
          SalesLine."Qty. to Invoice" := 0;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",30000);
          SalesLine."Qty. to Invoice" := 0;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",40000);
          SalesLine."Qty. to Invoice" := 1;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",50000);
          SalesLine."Qty. to Invoice" := 1;
          SalesLine.Modify();
          SalesLine.GET(SalesHeader."Document Type",SalesHeader."No.",60000);
          SalesLine."Qty. to Invoice" := 0;
          SalesLine.Modify();

          IF LastIteration = '27-1-18-40' THEN EXIT;

          SalesHeader.Reset();
          SalesHeader.FindLast();
          SalesHeader.Invoice := TRUE;
          PostSalesOrder(SalesHeader);

          IF LastIteration = '27-1-18-50' THEN EXIT;

        // 27-1-19

          VerifyPostCondition(UseCaseNo,TestCaseNo,19,LastILENo);

          IF LastIteration = '27-1-19-10' THEN EXIT;

        // 27-1-20

          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'10000',271101D);
          ModifyPurchHeader(PurchHeader,271101D,'BLUE','TCS27-1-20',FALSE);
          PurchHeader.VALIDATE("Vendor Cr. Memo No.",'TCS27-1-20');
          PurchHeader.Modify();

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80002','','BLUE',3,'PCS',630,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100-T','T2','BLUE',2,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,30000,PurchLine.Type::Item,'80002','','BLUE',7,'PCS',630,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,40000,PurchLine.Type::Item,'80100-T','T2','BLUE',1,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,50000,PurchLine.Type::Item,'80100-T','T1','BLUE',1,'BOX',10.01,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,60000,PurchLine.Type::Item,'80100-T','T1','BLUE',1,'BOX',10.01,FALSE);

          IF LastIteration = '27-1-20-10' THEN EXIT;

          SNCode := 'SX00';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,20000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80100-T','T2','BLUE','',271101D,271101D,0,2);
          END;
          CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,40000,1,1,1,'SX08','','');
          CreateRes.CreateEntry('80100-T','T2','BLUE','',271101D,271101D,0,2);
          CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,50000,1,1,1,'ST01','LX01','');
          CreateRes.CreateEntry('80100-T','T1','BLUE','',271101D,271101D,0,2);
          CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,60000,1,1,1,'ST04','LX01','');
          CreateRes.CreateEntry('80100-T','T1','BLUE','',271101D,271101D,0,2);
          CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,10000,1,3,3,'','LT01','');
          CreateRes.CreateEntry('80002','','BLUE','',271101D,271101D,0,2);
          CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,30000,1,7,7,'','LT02','');
          CreateRes.CreateEntry('80002','','BLUE','',271101D,271101D,0,2);

          IF LastIteration = '27-1-20-20' THEN EXIT;

          PurchHeader.Reset();
          PurchHeader.FindLast();
          PurchHeader.Ship := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '27-1-20-30' THEN EXIT;

          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",10000);
          PurchLine.VALIDATE("Qty. to Invoice",3);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",20000);
          PurchLine.VALIDATE("Qty. to Invoice",0);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",30000);
          PurchLine.VALIDATE("Qty. to Invoice",0);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",40000);
          PurchLine.VALIDATE("Qty. to Invoice",1);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",50000);
          PurchLine.VALIDATE("Qty. to Invoice",1);
          PurchLine.Modify();
          PurchLine.GET(PurchHeader."Document Type",PurchHeader."No.",60000);
          PurchLine.VALIDATE("Qty. to Invoice",0);
          PurchLine.Modify();

          IF LastIteration = '27-1-20-40' THEN EXIT;

          PurchHeader.Reset();
          PurchHeader.FindLast();
          PurchHeader.Invoice := TRUE;
          PostPurchOrder(PurchHeader);

          IF LastIteration = '27-1-20-50' THEN EXIT;

        // 27-1-21

          VerifyPostCondition(UseCaseNo,TestCaseNo,21,LastILENo);

          IF LastIteration = '27-1-21-10' THEN EXIT;

          Commit();
        END;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLine: Record "Item Journal Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        PickWkshLine: Record "Whse. Worksheet Line";
        WkshName: Record "Whse. Worksheet Name";
        ItemChargeAssignSales: Record "Item Charge Assignment (Sales)";
        CalcQtyOnHand: Report "Calculate Inventory";
        CreateRes: Codeunit "Create Reserv. Entry";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        SNCode: Code[20];
        i: Integer;
    begin
        WITH TestScriptMgmt DO BEGIN
        // 27-2-1
          SetGlobalPreconditions;
          // this is code added later to change the item no. so that sorting is same in the reference data for both native as well as SQL.
          // this test shall use an item called 80100-T instead of T_TEST
          CreateRenamedItem('T_TEST', '80100-T');

          IF LastIteration = '27-2-1-10' THEN EXIT;

          WkshName.Init();
          WkshName.VALIDATE("Worksheet Template Name",'PICK');
          WkshName.VALIDATE(Name,'DEFAULT');
          WkshName.VALIDATE(Description,'Default Pick Worksheet');
          WkshName.VALIDATE("Location Code",'GREEN');
          IF NOT WkshName.INSERT(TRUE) THEN
            WkshName.MODIFY(TRUE);
          IF LastIteration = '27-2-1-20' THEN EXIT;

        // 27-2-2
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',10000,251101D,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS27-2-2','80102-T','','GREEN','',10,'PCS',6.3,0);
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',20000,251101D,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS27-2-2','80100-T','T2','GREEN','',10,'BOX',10,0);
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',30000,251101D,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS27-2-2','80100-T','T2','BLUE','',11,'BOX',10,0);
          IF LastIteration = '27-2-2-10' THEN EXIT;

          SNCode := 'ST00';
          FOR i := 1 TO 10 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(83,2,'ITEM','DEFAULT',0,10000,1,1,1,SNCode,'','');
            CreateRes.CreateEntry('80102-T','','Green','',251101D,251101D,0,3);
          END;
          SNCode := 'SN00';
          FOR i := 1 TO 10 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(83,2,'ITEM','DEFAULT',0,20000,1,1,1,SNCode,'LN1','');
            CreateRes.CreateEntry('80100-T','T2','Green','',251101D,251101D,0,3);
          END;
          SNCode := 'SN10';
          FOR i := 1 TO 11 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(83,2,'ITEM','DEFAULT',0,30000,1,1,1,SNCode,'LN2','');
            CreateRes.CreateEntry('80100-T','T2','Blue','',251101D,251101D,0,3);
          END;
          IF LastIteration = '27-2-2-20' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);
          IF LastIteration = '27-2-2-30' THEN EXIT;

        //27-2-3
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'40000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Green',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80102-T','',5,'PCS',6.3,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100-T','T2',5,'BOX',19.87,'Green','');
            InsertSalesLine(
              SalesLine,SalesHeader,30000,Type::Item,'80100-T','T2',5,'BOX',19.87,'BLUE','');
            InsertSalesLine(
              SalesLine,SalesHeader,40000,Type::Item,'80100-T','T2',4,'BOX',19.87,'BLUE','');
            InsertSalesLine(
              SalesLine,SalesHeader,50000,Type::Item,'80100-T','T2',2,'BOX',19.87,'BLUE','');
          END;
          IF LastIteration = '27-2-3-10' THEN EXIT;

          SNCode := 'SN10';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,30000,1,1,1,SNCode,'LN2','');
            CreateRes.CreateEntry('80100-T','T2','Blue','',251101D,251101D,0,2);
          END;
          SNCode := 'SN15';
          FOR i := 1 TO 4 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,40000,1,1,1,SNCode,'LN2','');
            CreateRes.CreateEntry('80100-T','T2','Blue','',251101D,251101D,0,2);
          END;
          SNCode := 'SN19';
          FOR i := 1 TO 2 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,50000,1,1,1,SNCode,'LN2','');
            CreateRes.CreateEntry('80100-T','T2','Blue','',251101D,251101D,0,2);
          END;
          IF LastIteration = '27-2-3-20' THEN EXIT;

          ReleaseSalesDocument(SalesHeader);
          CLEAR(WhseShptHeader);
          CreateWhseShptFromSales(SalesHeader,WhseShptHeader,'Green');
          WhseShptHeader.FIND('-');
          ReleaseWhseShipment(WhseShptHeader);
          IF LastIteration = '27-2-3-30' THEN EXIT;

        //27-2-4
          CreatePickWorksheet(PickWkshLine,'PICK','DEFAULT','Green',0,'SH000001');
          IF LastIteration = '27-2-4-10' THEN EXIT;

          PickWkshLine.AutofillQtyToHandle(PickWkshLine);
          PickWkshLine.SETRANGE("Line No.",20000);
          PickWkshLine.FIND('-');
          PickWkshLine."Qty. to Handle" := 3;
          PickWkshLine.MODIFY(TRUE);
          IF LastIteration = '27-2-4-20' THEN EXIT;

          CreatePickFromWksh(
            PickWkshLine,'',0,0,0,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);
          IF LastIteration = '27-2-4-30' THEN EXIT;

          WhseActivLine.SETRANGE("Location Code",'Green');
          WhseActivLine.SETRANGE("Item No.",'80102-T');
          IF WhseActivLine.FIND('-') THEN BEGIN
            SNCode := 'ST00';
            FOR i := 1 TO 5 DO BEGIN
              SNCode := INCSTR(SNCode);
              WhseActivLine."Serial No." := SNCode;
              WhseActivLine."Lot No." := '';
              WhseActivLine.MODIFY(TRUE);
              IF WhseActivLine.Next() =0 THEN;
            END;
          END;

          WhseActivLine.SETRANGE("Location Code",'Green');
          WhseActivLine.SETRANGE("Item No.",'80100-T');
          IF WhseActivLine.FIND('-') THEN BEGIN
            SNCode := 'SN06';
            FOR i := 1 TO 3 DO BEGIN
              SNCode := INCSTR(SNCode);
              WhseActivLine."Serial No." := SNCode;
              WhseActivLine."Lot No." := 'LN1';
              WhseActivLine.MODIFY(TRUE);
              IF WhseActivLine.Next() =0 THEN;
            END;
          END;
          IF LastIteration = '27-2-4-40' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FIND('-');
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '27-2-4-50' THEN EXIT;

        //27-2-5
          PickWkshLine.FIND('-');
          PickWkshLine.AutofillQtyToHandle(PickWkshLine);
          IF LastIteration = '27-2-5-10' THEN EXIT;

          CreatePickFromWksh(
            PickWkshLine,'',0,0,0,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);
          IF LastIteration = '27-2-5-20' THEN EXIT;

          WhseActivLine.SETRANGE("Location Code",'Green');
          WhseActivLine.SETRANGE("Item No.",'80100-T');
          IF WhseActivLine.FindFirst() then BEGIN
            WhseActivLine."Serial No." := 'SN06';
            WhseActivLine."Lot No." := 'LN1';
            WhseActivLine.MODIFY(TRUE);
          END;
          IF WhseActivLine.FindLast() then BEGIN
            WhseActivLine."Serial No." := 'SN10';
            WhseActivLine."Lot No." := 'LN1';
            WhseActivLine.MODIFY(TRUE);
          END;
          IF LastIteration = '27-2-5-30' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          IF LastIteration = '27-2-5-40' THEN EXIT;

        //27-2-6
          WhseShptLine.FindFirst();
          PostWhseShipment(WhseShptLine,FALSE);
          IF LastIteration = '27-2-6-10' THEN EXIT;

          SalesHeader.FindFirst();
          SalesHeader.Ship := TRUE;
          PostSalesOrder(SalesHeader);
          IF LastIteration = '27-2-6-20' THEN EXIT;

        //27-2-7
          VerifyPostCondition(UseCaseNo,TestCaseNo,7,LastILENo);

          IF LastIteration = '27-2-7-10' THEN EXIT;

        //27-2-8
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',10000,251101D,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS27-2-3','80216-T','','Blue','',11,'PCS',6.3,0);
          InsertItemJnlLine(ItemJnlLine,'ITEM','DEFAULT',20000,251101D,
            ItemJnlLine."Entry Type"::"Positive Adjmt.",'TCS27-2-3','80100-T','T1','Blue','',11,'BOX',10,0);
          IF LastIteration = '27-2-8-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(83,2,'ITEM','DEFAULT',0,10000,1,11,11,'','LN3','');
          CreateRes.CreateEntry('80216-T','','Blue','',251101D,251101D,0,3);

          SNCode := 'SN29';
          FOR i := 1 TO 6 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(83,2,'ITEM','DEFAULT',0,20000,1,1,1,SNCode,'LN4','');
            CreateRes.CreateEntry('80100-T','T1','Blue','',251101D,251101D,0,3);
          END;
          SNCode := 'SN35';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(83,2,'ITEM','DEFAULT',0,20000,1,1,1,SNCode,'LN5','');
            CreateRes.CreateEntry('80100-T','T1','Blue','',251101D,251101D,0,3);
          END;
          IF LastIteration = '27-2-8-20' THEN EXIT;

          ItemJnlPostBatch(ItemJnlLine);
          IF LastIteration = '27-2-8-30' THEN EXIT;

        //27-2-9
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Order,'40000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Blue',TRUE,FALSE);

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,10000,Type::Item,'80216-T','',11,'PCS',6.3,'BLUE','');
            InsertSalesLine(
              SalesLine,SalesHeader,20000,Type::Item,'80100-T','T1',11,'BOX',19.87,'BLUE','');
          END;
          IF LastIteration = '27-2-9-10' THEN EXIT;

          ModifySalesLine(SalesHeader,10000,5,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,20000,6,0,0,0,FALSE);
          IF LastIteration = '27-2-9-20' THEN EXIT;

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,5,5,'','LN3','');
          CreateRes.CreateEntry('80216-T','','Blue','',251101D,251101D,0,2);

          SNCode := 'SN29';
          FOR i := 1 TO 6 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,SNCode,'LN4','');
            CreateRes.CreateEntry('80100-T','T1','Blue','',251101D,251101D,0,2);
          END;

          SNCode := 'SN35';
          FOR i := 1 TO 5 DO BEGIN
            SNCode := INCSTR(SNCode);
            CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,20000,1,1,1,SNCode,'LN5','');
            CreateRes.CreateEntry('80100-T','T1','Blue','',251101D,251101D,0,2);
          END;

          ReservationEntry.SETRANGE("Serial No.",'SN34','SN38');
          IF ReservationEntry.FIND('-') THEN REPEAT
            ReservationEntry.VALIDATE("Qty. to Handle (Base)",0);
            ReservationEntry.MODIFY(TRUE);
          UNTIL ReservationEntry.Next() =0;
          IF LastIteration = '27-2-9-30' THEN EXIT;

          PostSalesOrder(SalesHeader);
          IF LastIteration = '27-2-9-40' THEN EXIT;

        // 27-2-10
          VerifyPostCondition(UseCaseNo,TestCaseNo,10,LastILENo);

          IF LastIteration = '27-2-10-10' THEN EXIT;

        // 27-2-11
          ModifySalesLine(SalesHeader,10000,6,0,0,0,FALSE);
          ModifySalesLine(SalesHeader,20000,5,0,0,0,FALSE);
          IF LastIteration = '27-2-11-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,6,6,'','LN3','');
          CreateRes.CreateEntry('80216-T','','Blue','',251101D,251101D,0,2);

          IF LastIteration = '27-2-11-20' THEN EXIT;

          PostSalesOrder(SalesHeader);
          IF LastIteration = '27-2-11-30' THEN EXIT;

        // 27-2-12
          VerifyPostCondition(UseCaseNo,TestCaseNo,12,LastILENo);

          IF LastIteration = '27-2-12-10' THEN EXIT;

        // 27-2-13
          InsertPurchHeader(PurchHeader,PurchHeader."Document Type"::"Return Order",'40000',251101D);
          ModifyPurchHeader(PurchHeader,251101D,'Green','',FALSE);

          InsertPurchLine(
            PurchLine,PurchHeader,10000,PurchLine.Type::Item,'80102-T','','Green',1,'PCS',6.3,FALSE);
          InsertPurchLine(
            PurchLine,PurchHeader,20000,PurchLine.Type::Item,'80100-T','T2','Green',1,'BOX',19.87,FALSE);

          PurchLine.SETRANGE("Line No.",10000);
          PurchLine.FindFirst();
          PurchLine."Appl.-to Item Entry" :=6;
          PurchLine.MODIFY(TRUE);

          PurchLine.SETRANGE("Line No.",20000);
          PurchLine.FindFirst();
          PurchLine."Appl.-to Item Entry" :=11;
          PurchLine.MODIFY(TRUE);

          IF LastIteration = '27-2-13-10' THEN EXIT;

          CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,10000,1,1,1,'ST06','','');
          CreateRes.CreateEntry('80102-T','','Green','',251101D,251101D,0,2);

          CreateRes.CreateReservEntryFor(39,5,PurchHeader."No.",'',0,20000,1,1,1,'SN01','LN1','');
          CreateRes.CreateEntry('80100-T','T2','Green','',251101D,251101D,0,2);

          IF LastIteration = '27-2-13-20' THEN EXIT;

          ReleasePurchDocument(PurchHeader);
          CLEAR(WhseShptHeader);
          CreateWhseShptFromPurch(PurchHeader,WhseShptHeader,'GREEN');
          WhseShptHeader.FindFirst();
          CreatePickFromWhseShipment(WhseShptHeader);
          IF LastIteration = '27-2-13-30' THEN EXIT;

          CLEAR(WhseActivLine);
          WhseActivLine.FindFirst();
          PostWhseActivity(WhseActivLine);
          CLEAR(WhseShptLine);
          WhseShptLine.FindFirst();
          PostWhseShipment(WhseShptLine,FALSE);
          IF LastIteration = '27-2-13-40' THEN EXIT;

        // 27-2-14
          InsertSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,'40000',251101D);
          ModifySalesHeader(SalesHeader,251101D,'Blue',TRUE,FALSE);

          IF SalesShipmentLine.FIND('-') THEN BEGIN
            SalesGetShipment.SetSalesHeader(SalesHeader);
            REPEAT
              SalesGetShipment.CreateInvLines(SalesShipmentLine)
            UNTIL SalesShipmentLine.Next() =0;
          END;
          IF LastIteration = '27-2-14-10' THEN EXIT;

          WITH SalesLine DO BEGIN
            InsertSalesLine(
              SalesLine,SalesHeader,140000,Type::"Charge (Item)",'UPS','',1,'',100,'BLUE','');
          END;


          WITH ItemChargeAssignSales DO BEGIN
            Init();
            "Document Type" := "Document Type"::Invoice;
            "Document No." := '1001';
            "Document Line No." := 140000;
            "Line No." := 20000;
            "Item Charge No.":= 'UPS';
            "Item No." := '80100-T';
            "Qty. to Assign" := 1;
            "Unit Cost" := 100;
            "Amount to Assign" := 100;
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
            "Applies-to Doc. No." := '1001';
            "Applies-to Doc. Line No." := 30000;
            INSERT(TRUE);
          END;
          IF LastIteration = '27-2-14-20' THEN EXIT;

          PostSalesOrder(SalesHeader);
          IF LastIteration = '27-2-14-30' THEN EXIT;

        //27-2-15
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
          IF LastIteration = '27-2-15-10' THEN EXIT;

        // 27-2-16
          VerifyPostCondition(UseCaseNo,TestCaseNo,16,LastILENo);

          IF LastIteration = '27-2-16-10' THEN EXIT;
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

