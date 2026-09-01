codeunit 103414 "Test Use Case 13"
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
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptLine: Record "Sales Shipment Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        SelectionForm: Page "Test Selection";
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        TestScriptMgmt: Codeunit _TestscriptManagement;
        ItemChargeAssigntSales: Codeunit "Item Charge Assgnt. (Sales)";
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
        ActualIteration: Text[30];
        LastIteration: Text[30];
        IterationActive: Boolean;
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
            6:
                PerformTestCase6();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 13-1-1
        if PerformIteration('13-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 13-1-2
        if PerformIteration('13-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-1-2', '7_ST_OV', '', '', '', 3, 'PALLET', 110, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-1-2', '7_ST_OV', '71', '', '', 3, 'PALLET', 121, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-1-2', '7_ST_OV', '', '', '', 33, 'PCS', 12, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;
        // 13-1-3
        if PerformIteration('13-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-1-4
        if PerformIteration('13-1-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010104D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, '', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 66, 'PCS', 22);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 22, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 13-1-5
        if PerformIteration('13-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-1-6
        if PerformIteration('13-1-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010105D, '', false, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 22, 0, 23, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 13-1-7
        if PerformIteration('13-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-1-8
        if PerformIteration('13-1-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, '', false, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 22, 0, 24, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-8-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-1-8-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS13-1-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase13-1-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-1-9
        if PerformIteration('13-1-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 13-2-1
        if PerformIteration('13-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 13-2-2
        if PerformIteration('13-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-2-2', '4_AV_RE', '', 'BLUE', '', 3, 'PALLET', 433.3, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-2-2', '4_AV_RE', '', 'BLUE', '', 3, 'PALLET', 866.6, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-2-2', '4_AV_RE', '', 'BLUE', '', 15, 'PCS', 43.33, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-2-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;
        // 13-2-3
        if PerformIteration('13-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-2-4
        if PerformIteration('13-2-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '49858585', 20010104D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 4, 'PALLET', 1600);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 320);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 21, 'PCS', 640);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-2-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-2-4-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 13-2-5
        if PerformIteration('13-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 13-3-1
        if PerformIteration('13-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 13-3-2
        if PerformIteration('13-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-3-2', '1_FI_RE', '', 'BLUE', '', 9, 'PALLET', 259.74, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-3-2', '2_LI_RA', '', 'BLUE', '', 9, 'PALLET', 199.98, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-3-2', '1_FI_RE', '', 'BLUE', '', 117, 'PCS', 9.99, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-3-2', '2_LI_RA', '', 'BLUE', '', 27, 'PCS', 33.33, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS13-3-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase13-3-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-3-3
        if PerformIteration('13-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-3-4
        if PerformIteration('13-3-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010103D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010103D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 195, 'PCS', 44.44);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 60, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 45, 'PCS', 99.99);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 13, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 4, 'PALLET', 577.72);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 4, 'PALLET', 102.99);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS13-3-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase13-3-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-3-5
        if PerformIteration('13-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-3-6
        if PerformIteration('13-3-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, '', false, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 60, 0, 50, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 13, 0, 110, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 1, 0, 600, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 1, 0, 100, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS13-3-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase13-3-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-3-7
        if PerformIteration('13-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-3-8
        if PerformIteration('13-3-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010105D, '', false, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 75, 0, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 19, 0, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 1, 0, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 1, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-8-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-3-8-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase13-3-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-3-9
        if PerformIteration('13-3-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 13-4-1
        if PerformIteration('13-4-1-10') then begin
            TestScriptMgmt.SetGlobalPreconditions();
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-4-2
        if PerformIteration('13-4-2-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS13-4-2', true);
            PurchHeader."Prices Including VAT" := true;
            PurchHeader.Modify();
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-4-2-20') then begin
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 1.25);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 20, 0, 1.25, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 30, 'PCS', 125);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 30, 0, 125, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PALLET', 37.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 0, 37.5, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 30, 'PCS', 62.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 30, 0, 62.5, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-4-2-30') then begin
            PurchHeader.Receive := true;
            PurchHeader.Invoice := false;
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-4-3
        if PerformIteration('13-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-4-4
        if PerformIteration('13-4-4-10') then begin
            PurchHeader.Invoice := true;
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-4-5
        if PerformIteration('13-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-4-6
        if PerformIteration('13-4-6-10') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011127D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011127D, 'BLUE', true, true);
            SalesHeader."Prices Including VAT" := true;
            SalesHeader.Modify();
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-4-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 15, 'PCS', 25);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 15, 0, 25, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 250);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 250, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 4, 'PALLET', 75);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 0, 75, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 6, 'PCS', 125);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 0, 125, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-4-6-30') then begin
            SalesHeader.Ship := true;
            SalesHeader.Invoice := false;
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-4-7
        if PerformIteration('13-4-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-4-8
        if PerformIteration('13-4-8-10') then begin
            SalesHeader.Invoice := true;
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-4-9
        if PerformIteration('13-4-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        IterationActive := FirstIteration = '';
        // 13-5-1
        if PerformIteration('13-5-1-10') then begin
            TestScriptMgmt.SetGlobalPreconditions();
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            SalesSetup.Get();
            SalesSetup.Validate("Exact Cost Reversing Mandatory", true);
            SalesSetup.Modify();
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-5-2
        if PerformIteration('13-5-2-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS13-5-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-2-20') then begin
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 2000.011, 'PCS', 1.25);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 30, 'PCS', 125);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PALLET', 37.5);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::"Charge (Item)", 'GPS', '', 1, '', 20000);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-2-30') then begin
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchHeader."Document Type", PurchHeader."No.",
              10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, 40000, 10000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-2-40') then begin
            PurchHeader.Receive := true;
            PurchHeader.Invoice := true;
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-5-3
        if PerformIteration('13-5-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 13-5-4
        if PerformIteration('13-5-4-10') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011127D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011127D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 50);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 50, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 100);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 0, 100, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-4-30') then begin
            SalesHeader.Ship := true;
            SalesHeader.Invoice := false;
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-4-40') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011129D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-4-50') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 5, 0, 0, 0, 4);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::"Charge (Item)", 'S-RESTOCK', '', 5, '', 2.5);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 0, 5, 2.5, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'S-ALLOWANCE', '', 2, '', 15);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 0, 2, 15, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-4-60') then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange("Line No.", 20000);
            SalesLine.FindFirst();
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesHeader."Document Type", SalesHeader."No.",
              10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, 20000, 10000, 5);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-4-70') then begin
            Clear(ItemChargeAssigntSales);
            SalesShptHeader.Reset();
            SalesShptLine.Reset();
            ItemChargeAssgntSales.Reset();
            SalesLine.SetRange("Line No.", 30000);
            SalesLine.FindFirst();
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesHeader."Document Type", SalesHeader."No.",
              10000, '1_FI_RE');
            SalesShptHeader.FindLast();
            Clear(SalesShptLine);
            ItemChargeAssgntSales.FindLast();
            SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
            SalesShptLine.SetRange("No.", '2_LI_RA');
            ItemChargeAssigntSales.CreateShptChargeAssgnt(SalesShptLine, ItemChargeAssgntSales);
            ItemChargeAssgntSales.SetFilter("Line No.", '%1..%2', 30000, 40000);
            ItemChargeAssgntSales.DeleteAll();
            SalesLine.UpdateItemChargeAssgnt();
            ItemChargeAssigntSales.AssignItemCharges(SalesLine, 2, 42.5, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-5-4-80') then begin
            SalesHeader.Ship := true;
            SalesHeader.Invoice := true;
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-5-5
        if PerformIteration('13-5-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    begin
        IterationActive := FirstIteration = '';
        // 13-6-1
        if PerformIteration('13-6-1-10') then begin
            TestScriptMgmt.SetGlobalPreconditions();
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
        end;
        if LastIteration = ActualIteration then
            exit;
        // 13-6-2
        if PerformIteration('13-6-2-10') then begin
            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS13-6-2', '1_FI_RE', '', 'BLUE', '', 50, 'PCS', 110, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-6-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-6-2-30') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011127D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011127D, 'BLUE', true, true);
        end;

        if PerformIteration('13-6-2-40') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 250);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 250, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-6-2-50') then begin
            SalesHeader.Ship := true;
            SalesHeader.Invoice := true;
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-6-2-60') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', 20011129D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011129D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-6-2-70') then
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'GPS', '', 1, '', 20);

        if PerformIteration('13-6-2-80') then begin
            Clear(ItemChargeAssigntSales);
            Clear(SalesShptHeader);
            Clear(SalesShptLine);
            SalesShptHeader.Reset();
            SalesShptLine.Reset();
            ItemChargeAssgntSales.Reset();
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesHeader."Document Type", SalesHeader."No.",
              10000, 'GPS');
            SalesShptHeader.FindLast();
            ItemChargeAssgntSales.FindLast();
            SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
            SalesShptLine.SetRange("No.", '1_FI_RE');
            ItemChargeAssigntSales.CreateShptChargeAssgnt(SalesShptLine, ItemChargeAssgntSales);
            ItemChargeAssgntSales.SetFilter("Line No.", '%1..%2', 10000, 20000);
            ItemChargeAssgntSales.DeleteAll();
            SalesLine.UpdateItemChargeAssgnt();
            ItemChargeAssigntSales.AssignItemCharges(SalesLine, 1, 20, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('13-6-2-90') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 13-6-3
        if PerformIteration('13-6-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
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
    procedure PerformIteration(NewActualIteration: Text[30]): Boolean
    begin
        ActualIteration := NewActualIteration;
        IterationActive := IterationActive or (ActualIteration = FirstIteration);
        exit(IterationActive);
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
}

