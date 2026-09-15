codeunit 103416 "Test Use Case 15"
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
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SelectionForm: Page "Test Selection";
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 15-1-1
        if PerformIteration('15-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 15-1-2
        if PerformIteration('15-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-1-2', '1_FI_RE', '', 'BLUE', '', 300, 'PCS', 13.78, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-1-2', '5_ST_RA', '', 'BLUE', '', 300, 'PCS', 53.46, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-1-2', '1_FI_RE', '', 'BLUE', '', 300, 'PCS', 100.0, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-1-2', '5_ST_RA', '', 'BLUE', '', 300, 'PCS', 200.0, 0);

        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-1-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-3-8.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-1-3
        if PerformIteration('15-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-1-4
        if PerformIteration('15-1-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 358.28);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 2, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PALLET', 1176.12);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 2, 0, 0, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 130, 'PCS', 27.56);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 39, 26, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 110, 'PCS', 106.92);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 33, 22, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-1-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-1-4.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-1-5
        if PerformIteration('15-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-1-6
        if PerformIteration('15-1-6-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-6-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 3, 0, 200, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 3, 0, 600, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 39, 0, 15, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 33, 0, 55, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-1-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-1-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-1-7
        if PerformIteration('15-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-1-8
        if PerformIteration('15-1-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 3, 'PALLET', 358.28);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 3, 0, 0, 0, 13);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 3, 'PALLET', 1176.12);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 3, 0, 0, 0, 14);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 39, 'PCS', 27.56);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 39, 0, 0, 0, 15);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 33, 'PCS', 106.92);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 33, 0, 0, 0, 16);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::"Charge (Item)", 'UPS', '', 4, '', 40);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 4, 4, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-8-30') then begin
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 2);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 2);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-8-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-8-50') then;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-1-8-60') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-1-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-1-8.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-1-9
        if PerformIteration('15-1-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 15-2-1
        if PerformIteration('15-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 15-2-2
        if PerformIteration('15-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-2-2', '4_AV_RE', '', '', '', 300, 'PCS', 11.11, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-2-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;
        // 15-2-3
        if PerformIteration('15-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-2-4
        if PerformIteration('15-2-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, '', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 499.95);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 0, 0, 0, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 50, 'PCS', 99.99);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 30, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-2-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 15-2-5
        if PerformIteration('15-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-2-6
        if PerformIteration('15-2-6-10') then begin
            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-2-6', '4_AV_RE', '', '', '', 300, 'PCS', 22.22, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-2-6-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;
        // 15-2-7
        if PerformIteration('15-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-2-8
        if PerformIteration('15-2-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, '', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-2-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 499.95);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 6, 0, 0, 0, 2);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 50, 'PCS', 99.99);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 30, 0, 0, 0, 3);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-2-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 15-2-9
        if PerformIteration('15-2-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 15-3-1
        if PerformIteration('15-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 15-3-2
        if PerformIteration('15-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-2', '7_ST_OV', '', 'BLUE', '', 45, 'PALLET', 880.0, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-2', '7_ST_OV', '71', 'BLUE', '', 495, 'PCS', 80.0, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-2', '6_AV_OV', '', 'BLUE', '', 100, 'PALLET', 250.0, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-2', '6_AV_OV', '61', 'BLUE', '', 500, 'PCS', 50.0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-3-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-3-2.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-3-3
        if PerformIteration('15-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-3-4
        if PerformIteration('15-3-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '49858585', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 495, 'PCS', 80.0);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 110, 0, 0, 0, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '71', 45, 'PALLET', 880.0);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 0, 0, 0, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '', 500, 'PCS', 50.0);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 50, 0, 0, 0, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '6_AV_OV', '61', 100, 'PALLET', 250.0);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-3-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-3-4.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-3-5
        if PerformIteration('15-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-3-6
        if PerformIteration('15-3-6-10') then begin
            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-6', '7_ST_OV', '', 'BLUE', '', 45, 'PALLET', 440.0, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-6', '7_ST_OV', '71', 'BLUE', '', 495, 'PCS', 40.0, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-6', '6_AV_OV', '', 'BLUE', '', 100, 'PALLET', 125.0, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS15-3-6', '6_AV_OV', '61', 'BLUE', '', 500, 'PCS', 25.0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-6-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-6-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-3-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-3-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-3-7
        if PerformIteration('15-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-3-8
        if PerformIteration('15-3-8-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-8-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 110, 0, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 10, 0, 0, 0, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 50, 0, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 10, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-8-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-3-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-3-8.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-3-9
        if PerformIteration('15-3-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 15-3-10
        if PerformIteration('15-3-10-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '49858585', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010108D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-10-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 495, 'PCS', 80);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 110, 0, 0, 0, 5);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '71', 45, 'PALLET', 880);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 10, 0, 0, 0, 6);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '', 500, 'PCS', 50);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 50, 0, 0, 0, 7);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '6_AV_OV', '61', 100, 'PALLET', 250);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 10, 0, 0, 0, 8);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::"Charge (Item)", 'UPS', '', 4, '', 40);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 4, 4, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-10-30') then begin
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 10000, '7_ST_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 20000, '7_ST_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 30000, '6_AV_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 40000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 40000, '6_AV_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-10-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-10-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('15-3-10-60') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS15-3-10', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase15-3-10.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 15-3-11
        if PerformIteration('15-3-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
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

