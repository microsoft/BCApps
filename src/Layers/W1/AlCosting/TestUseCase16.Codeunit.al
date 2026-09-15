codeunit 103417 "Test Use Case 16"
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
            4:
                PerformTestCase4();
            5:
                PerformTestCase5();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 16-1-1
        if PerformIteration('16-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 16-1-2
        if PerformIteration('16-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            TestScriptMgmt.SetSalesCalcInvDisc(true);
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-1-2', '2_LI_RA', '', 'BLUE', '', 18, 'PALLET', 71.33, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-1-2', '4_AV_RE', '', 'BLUE', '', 18, 'PALLET', 217.78, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-1-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-1-2.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-1-3
        if PerformIteration('16-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-1-4
        if PerformIteration('16-1-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '2_LI_RA', '', 10, 'PALLET', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 9, 6, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 200);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 9, 6, 0, 7, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 30, 'PCS', 20);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 27, 18, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '', 50, 'PCS', 40);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 45, 30, 0, 7, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-1-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-1-4.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-1-5
        if PerformIteration('16-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-1-6
        if PerformIteration('16-1-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 5, '', 10);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 4, 0, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 10, 'PALLET', 60);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 9, 0, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 200);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 9, 0, 0, 7, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 30, 'PCS', 20);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 27, 0, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 50, 'PCS', 40);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 50000, 45, 0, 0, 7, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-1-7
        if PerformIteration('16-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-1-8
        if PerformIteration('16-1-8-10') then begin
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, 'BLUE', true, true);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 10000, 0, 4, 0, 0, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 20000, 0, 9, 0, 0, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 30000, 0, 9, 0, 7, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 40000, 0, 27, 0, 0, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 50000, 0, 45, 0, 7, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-8-20') then begin
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 10000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 40000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 40000, '2_LI_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 50000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 50000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 50000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-1-8-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-1-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-1-8.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-1-9
        if PerformIteration('16-1-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 16-2-1
        if PerformIteration('16-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 16-2-2
        if PerformIteration('16-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            TestScriptMgmt.SetSalesCalcInvDisc(true);
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-2-2', '1_FI_RE', '', 'BLUE', '', 18, 'PALLET', 144.43, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-2-2', '5_ST_RA', '', 'BLUE', '', 18, 'PALLET', 575.8, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;
        // 16-2-3
        if PerformIteration('16-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-2-4
        if PerformIteration('16-2-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 130);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 2, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PALLET', 660);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 2, 0, 7, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 130, 'PCS', 10);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 39, 26, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 110, 'PCS', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 33, 22, 0, 7, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-2-5
        if PerformIteration('16-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-2-6
        if PerformIteration('16-2-6-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010103D, 'BLUE', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-6-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 2, 3, 260, 7, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 2, 3, 770, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 26, 39, 20, 7, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 22, 33, 70, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-2-7
        if PerformIteration('16-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-2-8
        if PerformIteration('16-2-8-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, 'BLUE', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-8-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 4, 4, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 4, 4, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 52, 52, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 44, 44, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-2-9
        if PerformIteration('16-2-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-2-10
        if PerformIteration('16-2-10-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010105D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-10-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 9, 'PALLET', 260);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 9, 0, 0, 7, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 9, 'PALLET', 770);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 9, 0, 0, 7, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 117, 'PCS', 20);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 117, 0, 0, 7, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 99, 'PCS', 70);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 99, 0, 0, 7, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::"Charge (Item)", 'UPS', '', 4, '', 10);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 50000, 4, 0, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-10-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-2-11
        if PerformIteration('16-2-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-2-12
        if PerformIteration('16-2-12-10') then begin
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010105D, 'BLUE', true, true);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 10000, 0, 9, 0, 7, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 20000, 0, 9, 0, 7, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 30000, 0, 117, 0, 7, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 40000, 0, 99, 0, 7, 0);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 50000, 0, 4, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-12-20') then begin
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 30000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 40000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-12-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-12-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-2-13-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-2-12.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-2-13
        if PerformIteration('16-2-13-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 16-3-1
        if PerformIteration('16-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 16-3-2
        if PerformIteration('16-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            TestScriptMgmt.SetSalesCalcInvDisc(true);
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-3-2', '7_ST_OV', '', 'BLUE', '', 9, 'PALLET', 880, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-3-2', '7_ST_OV', '71', 'BLUE', '', 99, 'PCS', 80, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-3-2', '6_AV_OV', '', 'BLUE', '', 20, 'PALLET', 250, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-3-2', '6_AV_OV', '61', 'BLUE', '', 100, 'PCS', 50, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-3-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-3-2.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-3-3
        if PerformIteration('16-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-3-4
        if PerformIteration('16-3-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 9, 'PALLET', 990);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 9, 6, 0, 3, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '71', 99, 'PCS', 90);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 99, 66, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '', 20, 'PALLET', 300);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 20, 18, 0, 3, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '6_AV_OV', '61', 100, 'PCS', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 100, 90, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-3-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-3-2.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-3-5
        if PerformIteration('16-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-3-6
        if PerformIteration('16-3-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '7_ST_OV', '', 9, 'PALLET', 990);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 9, 6, 0, 3, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '71', 99, 'PCS', 90);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 99, 66, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '', 20, 'PALLET', 300);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 20, 18, 0, 3, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '6_AV_OV', '61', 100, 'PCS', 60);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 100, 90, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::"Charge (Item)", 'UPS', '', 4, '', 10);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 4, 4, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-6-30') then begin
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

        if PerformIteration('16-3-6-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-3-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-3-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-3-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-3-7
        if PerformIteration('16-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 16-4-1
        if PerformIteration('16-4-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 16-4-2
        if PerformIteration('16-4-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '49858585', 20010101D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010101D, '', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-4-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 143, 'PCS', 10);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 143, 143, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 33, 'PCS', 20);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 33, 33, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 11, 'PALLET', 130);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 11, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 11, 'PALLET', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 11, 11, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-4-2-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-4-3
        if PerformIteration('16-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-4-4
        if PerformIteration('16-4-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '49858585', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, '', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-4-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 130, 'PCS', 10);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 130, 130, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 30, 'PCS', 20);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 30, 30, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 130);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 10, 10, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 10, 'PALLET', 60);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 10, 10, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-4-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-4-5
        if PerformIteration('16-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-4-6
        if PerformIteration('16-4-6-10') then begin
            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-4-6', '1_FI_RE', '', '', '', 65, 'PCS', 11.11, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-4-6', '2_LI_RA', '', '', '', 44, 'PCS', 22.22, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-4-6', '1_FI_RE', '', '', '', 78, 'PCS', 22.22, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-4-6', '2_LI_RA', '', '', '', 22, 'PCS', 44.44, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-4-6-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-4-6-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-4-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-4-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-4-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-4-7
        if PerformIteration('16-4-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        IterationActive := FirstIteration = '';
        // 16-5-1
        if PerformIteration('16-5-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 16-5-2
        if PerformIteration('16-5-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-5-2', '5_ST_RA', '', 'BLUE', '', 10, 'PCS', 5.55, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-5-2', '4_AV_RE', '', 'BLUE', '', 10, 'PCS', 4.44, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;
        // 16-5-3
        if PerformIteration('16-5-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-5-4
        if PerformIteration('16-5-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', 20010101D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010101D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 22.22, '', 22.22);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 22.22, 22.22, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 55.55);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 44.44);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::"Charge (Item)", 'GPS', '', 2, '', 10);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 2, 2, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-4-30') then begin
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 10000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::Invoice, SalesLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 11.11);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::Invoice, SalesLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 11.11);

            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 40000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::Invoice, SalesLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::Invoice, SalesLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-4-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-5-5
        if PerformIteration('16-5-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-5-6
        if PerformIteration('16-5-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 44.44, 'PCS', 10);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 44.44, 22.22, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 20);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 20, 10, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PALLET', 130);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 20, 10, 0, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::"Charge (Item)", 'GPS', '', 4, 'PCS', 10);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 4, 2, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-6-30') then begin
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 10000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 11.11);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 11.11);
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 40000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::"Return Order", SalesLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-6-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 16-5-7
        if PerformIteration('16-5-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 16-5-8
        if PerformIteration('16-5-8-10') then begin
            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-5-8', '5_ST_RA', '', 'BLUE', '', 10, 'PCS', 11.1, 0);
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS16-5-8', '4_AV_RE', '', 'BLUE', '', 10, 'PCS', 8.88, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-8-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-8-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('16-5-8-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS16-5-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase16-5-8.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 16-5-9
        if PerformIteration('16-5-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
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

