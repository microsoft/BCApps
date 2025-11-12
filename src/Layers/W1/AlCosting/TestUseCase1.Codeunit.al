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
        UseCase: Record "Use Case";
        TestCase: Record "Test Case";
        ItemJnlLine: Record "Item Journal Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemChargeAssigntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        Item: Record Item;
        SelectionForm: Page "Test Selection";
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        DelInvSalesOrders: Report "Delete Invoiced Sales Orders";
        TestScriptMgmt: Codeunit _TestscriptManagement;
        ObjectNo: Integer;
        UseCaseNo: Integer;
        TestLevel: Option All,Selected;
        TestCaseNo: Integer;
        TestUseCase: array[50] of Boolean;
        TestCaseDesc: array[50] of Text[100];
        ShowAlsoPassTests: Boolean;
        LastILENo: Integer;
        LastCLENo: Integer;
        LastGLENo: Integer;
        ItemJnlLineNo: Integer;
        TestResultsPath: Text[250];
        FirstIteration: Text[30];
        LastIteration: Text[30];
        NoOfRecords: array[20] of Integer;
        NoOfFields: array[20] of Integer;

    [Scope('OnPrem')]
    procedure Test(NewObjectNo: Integer; NewUseCaseNo: Integer; NewTestLevel: Option All,Selected; NewLastIteration: Text[30]; NewTestCaseNo: Integer): Boolean
    begin
        ObjectNo := NewObjectNo;
        UseCaseNo := NewUseCaseNo;
        TestLevel := NewTestLevel;
        LastIteration := NewLastIteration;
        TestCaseNo := NewTestCaseNo;

        UseCase.Get(UseCaseNo);
        TestScriptMgmt.InitializeOutput(ObjectNo, '');
        TestResultsPath := TestScriptMgmt.GetTestResultsPath();
        TestScriptMgmt.SetNumbers(NoOfRecords, NoOfFields);

        if LastIteration <> '' then begin
            TestCase.Get(UseCaseNo, TestCaseNo);
            TestCaseDesc[TestCaseNo] :=
              Format(UseCaseNo) + '.' + Format(TestCaseNo) + ' ' + TestCase.Description;
            HandleTestCases();
        end else begin
            TestCaseNo := 0;
            Clear(TestUseCase);
            Clear(TestCaseDesc);

            TestCase.Reset();
            TestCase.SetRange("Use Case No.", UseCaseNo);
            TestCase.SetRange("Testscript Completed", true);
            if not TestCase.Find('-') then
                exit(true);
            repeat
                TestCaseNo := TestCase."Test Case No.";
                if TestCaseNo <= ArrayLen(TestCaseDesc) then
                    TestCaseDesc[TestCaseNo] :=
                      Format(UseCaseNo) + '.' + Format(TestCaseNo) + ' ' + TestCase.Description;
            until TestCase.Next() = 0;

            if TestLevel = TestLevel::Selected then begin
                Commit();
                SelectionForm.SetSelection(TestCaseDesc, false, UseCaseNo,
                  'Select Test Case for Use Case ' + Format(UseCaseNo) + '. ' + UseCase.Description);
                SelectionForm.LookupMode := true;
                if SelectionForm.RunModal() <> ACTION::LookupOK then
                    exit(false);
                SelectionForm.GetSelection(TestLevel, TestUseCase, ShowAlsoPassTests);
            end;

            for TestCaseNo := 1 to ArrayLen(TestCaseDesc) do
                if TestCaseDesc[TestCaseNo] <> '' then
                    HandleTestCases();
        end;

        TestScriptMgmt.GetNumbers(NoOfRecords, NoOfFields);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure HandleTestCases()
    begin
        if TestLevel = TestLevel::Selected then
            if not TestUseCase[TestCaseNo] then
                exit;

        case TestCaseNo of
            1:
                PerformTestCase1();
            2:
                PerformTestCase2();
            3:
                PerformTestCase3();
            4:
                PerformTestCase4();
            5:
                PerformTestCase5();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-1-1-10' then
            exit;
        // 1-1-2
        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010120D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS1-1-2', '7_ST_OV', '', 'BLUE', '', 1, 'PALLET', 1100, 0);

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010121D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS1-1-2', '7_ST_OV', '71', 'BLUE', '', 1, 'PALLET', 1200, 0);

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010122D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS1-1-2', '7_ST_OV', '', 'BLUE', '', 1, 'PALLET', 1300, 0);

        if LastIteration = '1-1-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-1-2-20' then
            exit;
        // 1-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-1-3-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
        Clear(PurchHeader);
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010123D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010123D, 'BLUE', '', true);

        if LastIteration = '1-1-4-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '7_ST_OV', '', 11, 'PCS', 110);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '71', 11, 'PCS', 120);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '', 11, 'PCS', 130);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 0, 0, 0);

        if LastIteration = '1-1-4-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-1-4-30' then
            exit;
        // 1-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-1-5-10' then
            exit;
        // 1-1-6
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010124D, '', '', true);

        if LastIteration = '1-1-6-10' then
            exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 4, 0, 120, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 3, 0, 130, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 2, 0, 140, 0);

        if LastIteration = '1-1-6-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-1-6-30' then
            exit;
        // 1-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-1-7-10' then
            exit;
        // 1-1-8
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010125D, '', '', true);

        if LastIteration = '1-1-8-10' then
            exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 5, 0, 150, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 5, 0, 150, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 5, 0, 150, 0);

        if LastIteration = '1-1-8-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-1-8-30' then
            exit;

        TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = '1-1-8-40' then
            exit;

        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS1-1-8', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-1-8.pdf');
        if LastIteration = '1-1-8-50' then
            exit;
        // 1-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-1-9-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
        Clear(PurchHeader);
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010125D, 'BLUE', 'TCS1-1-10', true);

        if LastIteration = '1-1-10-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '7_ST_OV', '', 11, 'PCS', 110);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'UPS', '', 1, '', 100);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'GPS', '', 1, '', 100);

        if LastIteration = '1-1-10-20' then
            exit;

        PurchLine.Reset();
        PurchLine.SetRange(PurchLine."Document No.", PurchHeader."No.");
        PurchLine.SetRange(PurchLine."Line No.", 20000);
        PurchLine.FindFirst();
        TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchHeader."Document Type", PurchHeader."No.",
          10000, '7_ST_OV');
        TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, 20000, 20000, 1);

        if LastIteration = '1-1-10-30' then
            exit;

        PurchLine.SetRange(PurchLine."Line No.", 30000);
        PurchLine.FindFirst();
        TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchHeader."Document Type", PurchHeader."No.",
          10000, '7_ST_OV');
        PurchRcptHeader.FindLast();
        Clear(PurchRcptLine);
        ItemChargeAssgntPurch.FindLast();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        ItemChargeAssigntPurch.CreateRcptChargeAssgnt(PurchRcptLine, ItemChargeAssgntPurch);
        ItemChargeAssgntPurch.SetFilter("Line No.", '%1..%2', 30000, 40000);
        ItemChargeAssgntPurch.DeleteAll();
        PurchLine.UpdateItemChargeAssgnt();
        ItemChargeAssigntPurch.AssignItemCharges(PurchLine, 1, 100, 1);

        if LastIteration = '1-1-10-40' then
            exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-1-10-50' then
            exit;
        // 1-1-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-1-11-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-2-1-10' then
            exit;
        // 1-2-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        TestScriptMgmt.ClearDimensions();
        Clear(PurchHeader);
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', '', true);
        if LastIteration = '1-2-2-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 11, 'PCS', 44.44);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
        if LastIteration = '1-2-2-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '1-2-4-30' then
            exit;

        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-2-2.pdf');
        if LastIteration = '1-2-2-40' then
            exit;
        // 1-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = '1-2-3-10' then
            exit;
        // 1-2-4
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', '', true);
        if LastIteration = '1-2-4-10' then
            exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 3, 0, 55.55, 0);
        if LastIteration = '1-2-4-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '1-2-4-30' then
            exit;

        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-2-4.pdf');
        if LastIteration = '1-2-4-40' then
            exit;
        // 1-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = '1-2-5-10' then
            exit;
        // 1-2-6
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010105D, '', '', true);
        if LastIteration = '1-2-6-10' then
            exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 5, 0, 66.66, 0);
        if LastIteration = '1-2-6-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = '1-2-6-30' then
            exit;

        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-2-6.pdf');
        if LastIteration = '1-2-6-40' then
            exit;
        // 1-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = '1-2-7-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-3-1-10' then
            exit;
        // 1-3-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
        Clear(PurchHeader);
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', '', true);

        if LastIteration = '1-3-2-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 14, 'PCS', 15.99);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 13, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 25.77);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 2, 'PALLET', 166.66);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 2, 'PALLET', 77.77);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);

        if LastIteration = '1-3-2-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-3-2-30' then
            exit;

        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS1-3-2', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-3-2.pdf');
        if LastIteration = '1-3-2-40' then
            exit;
        // 1-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-3-3-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '1-4-1-10' then
            exit;
        // 1-4-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-4-2', '4_AV_RE', '', 'BLUE', '', 1, 'PCS', 55.55, 0);

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS1-4-2', '6_AV_OV', '', 'BLUE', '', 1, 'PCS', 66.66, 0);

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS1-4-2', '4_AV_RE', '', 'BLUE', '', 1, 'PALLET', 1100, 0);

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS1-4-2', '5_ST_RA', '', 'BLUE', '', 1, 'PALLET', 1200, 0);

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS1-4-2', '6_AV_OV', '', 'BLUE', '', 1, 'PALLET', 1300, 0);

        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS1-4-2', '7_ST_OV', '', 'BLUE', '', 1, 'PALLET', 1300, 0);

        if LastIteration = '1-4-2-10' then
            exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '1-4-2-20' then
            exit;
        // 1-4-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-4-3-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
        Clear(PurchHeader);
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010103D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, 'BLUE', '', true);

        if LastIteration = '1-4-4-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 14, 'PCS', 66.66);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 60);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '', 14, 'PCS', 77.77);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '7_ST_OV', '', 20, 'PCS', 88.88);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);

        if LastIteration = '1-4-4-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-4-4-30' then
            exit;
        // 1-4-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-4-5-10' then
            exit;
        // 1-4-6
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010104D, '', '', true);

        if LastIteration = '1-4-6-10' then
            exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 1, 0, 60, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 2, 0, 66, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 3, 0, 70, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 4, 0, 80, 0);

        if LastIteration = '1-4-6-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-4-6-30' then
            exit;
        // 1-4-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-4-7-10' then
            exit;
        // 1-4-8
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010105D, '', '', true);

        if LastIteration = '1-4-8-10' then
            exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 5, 0, 70, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 5, 0, 75, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 5, 0, 80, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 5, 0, 85, 0);

        if LastIteration = '1-4-8-20' then
            exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-4-8-30' then
            exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '1-4-8-40' then
            exit;

        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-4-8.pdf');

        if LastIteration = '1-4-8-50' then
            exit;
        // 1-4-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-4-9-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        Clear(PurchHeader);
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010104D, 'BLUE', 'TCS1-4-10', true);
        PurchHeader.Validate("Order Date", 20010104D);
        PurchHeader.Modify();

        if LastIteration = '1-4-10-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 10, 0);
        PurchLine.Validate("Indirect Cost %", 10);
        PurchLine.Modify();

        if LastIteration = '1-4-10-20' then
            exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-4-10-30' then
            exit;
        // 1-4-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-4-11-10' then
            exit;
        // 1-4-12
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase1-4-12.pdf');

        if LastIteration = '1-4-12-10' then
            exit;
        // 1-4-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-4-13-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');

        Item.Get('2_LI_RA');
        Item.Validate("Item Tracking Code", 'LOTALL');
        Item.Modify();
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '1-5-1-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        Clear(PurchHeader);
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010103D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, 'BLUE', 'TCS1-5-2', true);
        PurchHeader.Validate("Order Date", 20010103D);
        PurchHeader.Modify();

        if LastIteration = '1-5-2-10' then
            exit;

        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '2_LI_RA', '', 100, 'PCS', 10);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 100, 10, 0);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'GPS', '', 1, '', 50);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 50, 0);

        if LastIteration = '1-5-2-20' then
            exit;

        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOT01');
        CreateReservEntry.CreateEntry('2_LI_RA', '', 'BLUE', '', 20010103D, 20010103D, 0, "Reservation Status"::Surplus);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 30, 30, '', 'LOT02');
        CreateReservEntry.CreateEntry('2_LI_RA', '', 'BLUE', '', 20010103D, 20010103D, 0, "Reservation Status"::Prospect);
        CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 10000, 1, 60, 60, '', 'LOT03');
        CreateReservEntry.CreateEntry('2_LI_RA', '', 'BLUE', '', 20010103D, 20010103D, 0, "Reservation Status"::Surplus);

        if LastIteration = '1-5-2-30' then
            exit;

        TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchHeader."Document Type", PurchHeader."No.", 10000, '2_LI_RA');
        TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, 20000, 20000, 1);

        if LastIteration = '1-5-2-40' then
            exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '1-5-2-50' then
            exit;
        // 1-5-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-5-3-10' then
            exit;
        TestScriptMgmt.ClearDimensions();
        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010104D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, 'BLUE', false, true);

        if LastIteration = '1-5-4-10' then
            exit;

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '2_LI_RA', '', 20, 'PCS', 12);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 12, 0, true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::"Charge (Item)", 'GPS', '', 1, '', 10);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 10, 0, true);

        if LastIteration = '1-5-4-20' then
            exit;

        CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 10000, 1, 10, 10, '', 'LOT01');
        CreateReservEntry.CreateEntry('2_LI_RA', '', 'BLUE', '', 20010104D, 20010104D, 0, "Reservation Status"::Surplus);
        // Bug 254185 change - set IT only for 10 as only 10 will be shipped.
        // CreateRes.CreateReservEntryFor(37,1,SalesHeader."No.",'',0,10000,1,10,'','LOT02');
        // CreateRes.CreateEntry('2_LI_RA','','BLUE','',040101D,040101D,0, "Reservation Status"::Surplus);
        if LastIteration = '1-5-4-30' then
            exit;

        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 20000);
        TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::Order, SalesLine."Document No.", 10000, '2_LI_RA');
        TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);

        if LastIteration = '1-5-4-40' then
            exit;

        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-5-4-50' then
            exit;
        // 1-5-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-5-5-10' then
            exit;
        // 1-5-6
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', 20011108D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010108D, 'BLUE', true, false);

        if LastIteration = '1-5-6-10' then
            exit;

        Clear(SalesShipmentLine);
        SalesShipmentLine.SetRange("Sell-to Customer No.", '10000');
        if SalesShipmentLine.FindFirst() then begin
            SalesGetShipment.SetSalesHeader(SalesHeader);
            SalesGetShipment.CreateInvLines(SalesShipmentLine);
        end;

        if LastIteration = '1-5-6-20' then
            exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '1-5-6-30' then
            exit;

        Clear(DelInvSalesOrders);
        DelInvSalesOrders.UseRequestPage(false);
        DelInvSalesOrders.RunModal();

        if LastIteration = '1-5-6-40' then
            exit;
        // 1-5-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-5-7-10' then
            exit;
        // 1-5-8
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '1-5-8-10' then
            exit;
        // 1-5-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '1-5-9-10' then
            exit;
    end;

    [Scope('OnPrem')]
    procedure GetLastILENo(): Integer
    begin
        LastILENo := TestScriptMgmt.GetLastItemLedgEntryNo();
    end;

    [Scope('OnPrem')]
    procedure GetLastCLENo(): Integer
    begin
        LastCLENo := TestScriptMgmt.GetLastValuEntryNo();
    end;

    [Scope('OnPrem')]
    procedure GetLastGLENo(): Integer
    begin
        LastGLENo := TestScriptMgmt.GetLastGLEntryNo();
    end;

    [Scope('OnPrem')]
    procedure GetNextNo(var LastNo: Integer): Integer
    begin
        exit(TestScriptMgmt.GetNextNo(LastNo));
    end;

    [Scope('OnPrem')]
    procedure SetFirstIteration(NewFirstUseCaseNo: Integer; NewFirstTestCaseNo: Integer; NewFirstIterationNo: Integer; NewFirstStepNo: Integer)
    begin
        UseCaseNo := NewFirstUseCaseNo;
        TestCaseNo := NewFirstTestCaseNo;
        FirstIteration := Format(UseCaseNo) + '-' + Format(TestCaseNo) + '-' +
          Format(NewFirstIterationNo) + '-' + Format(NewFirstStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetLastIteration(NewLastUseCaseNo: Integer; NewLastTestCaseNo: Integer; NewLastIterationNo: Integer; NewLastStepNo: Integer)
    begin
        LastIteration := Format(NewLastUseCaseNo) + '-' + Format(NewLastTestCaseNo) + '-' +
          Format(NewLastIterationNo) + '-' + Format(NewLastStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetNumbers(NewNoOfRecords: array[20] of Integer; NewNoOfFields: array[20] of Integer)
    begin
        CopyArray(NoOfRecords, NewNoOfRecords, 1);
        CopyArray(NoOfFields, NewNoOfFields, 1);
    end;

    [Scope('OnPrem')]
    procedure GetNumbers(var NewNoOfRecords: array[20] of Integer; var NewNoOfFields: array[20] of Integer)
    begin
        CopyArray(NewNoOfRecords, NoOfRecords, 1);
        CopyArray(NewNoOfFields, NoOfFields, 1);
    end;

    local procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntry.CreateReservEntryFor(
            ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;
}

