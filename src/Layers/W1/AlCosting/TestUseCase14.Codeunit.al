codeunit 103415 "Test Use Case 14"
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
            // Bug 37027 - 2 and 3
            //2: PerformTestCase2;
            //3: PerformTestCase3;
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
        // 14-1-1
        if PerformIteration('14-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 14-1-2
        if PerformIteration('14-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-1-2', '4_AV_RE', '', 'RED', '', 13, 'PALLET', 111.11, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-1-2', '4_AV_RE', '', 'RED', '', 65, 'PCS', 11.11, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-1-2', '4_AV_RE', '', 'BLUE', '', 13, 'PALLET', 222.22, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-1-2', '4_AV_RE', '', 'BLUE', '', 65, 'PCS', 22.22, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-1-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;
        // 14-1-3
        if PerformIteration('14-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-1-4
        if PerformIteration('14-1-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010103D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010103D, 'BLUE', true, true);
            SalesHeader."Payment Discount %" := 0;
            SetBalAccountNo('2910');
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 130, 'PCS', 66.66);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 130, 130, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-1-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 14-1-5
        if PerformIteration('14-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 14-2-1
        if PerformIteration('14-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 14-2-2
        if PerformIteration('14-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-2-2', '1_FI_RE', '', 'BLUE', '', 7, 'PALLET', 21.65, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-2-2', '2_LI_RA', '', 'BLUE', '', 30, 'PALLET', 6.66, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-2-2', '1_FI_RE', '', 'BLUE', '', 91, 'PCS', 3.33, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-2-2', '2_LI_RA', '', 'BLUE', '', 90, 'PCS', 4.44, 0);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS14-2-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-2-2.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-2-3
        if PerformIteration('14-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-2-4
        if PerformIteration('14-2-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '49858585', 20010104D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 130, 'PCS', 3);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 129, 0, 0, 11, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 141, 'PCS', 20);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 140, 0, 0, 13, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '1_FI_RE', '', 4, 'PALLET', 4);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 0, 0, 11, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '2_LI_RA', '', 13, 'PALLET', 5);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 0, 0, 13, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::"Charge (Item)", 'UPS', '', 14, '', 12);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 0, 0, 0, 0, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::"Charge (Item)", 'Insurance', '', 4, '', 14);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 0, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS14-2-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-2-4.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-2-5
        if PerformIteration('14-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-2-6
        if PerformIteration('14-2-6-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-6-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 43, 6, 11, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 47, 40, 13, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 8, 11, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 4, 10, 13, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 50000, 4, 4, 12, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 60000, 1, 1, 14, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-6-30') then begin
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 50000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::Order, SalesLine."Document No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::Order, SalesLine."Document No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::Order, SalesLine."Document No.", 30000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 40000, SalesLine."Document Type"::Order, SalesLine."Document No.", 40000, '2_LI_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 60000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::Order, SalesLine."Document No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-6-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS14-2-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-2-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-2-7
        if PerformIteration('14-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-2-8
        if PerformIteration('14-2-8-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010108D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-8-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 43, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 47, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 4, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 50000, 0, 0, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 60000, 0, 0, 0, 0, false);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-8-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS14-2-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-2-8.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-2-9
        if PerformIteration('14-2-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-2-10
        if PerformIteration('14-2-10-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010110D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-10-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 43, 12, 50, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 46, 80, 50, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 16, 50, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 4, 20, 50, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 50000, 4, 4, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 60000, 1, 1, 0, 0, false);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-10-30') then begin
            SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 50000);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);
            SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 60000);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-10-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-10-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-2-10-60') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-2-10.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-2-11
        if PerformIteration('14-2-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 14-3-1
        if PerformIteration('14-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 14-3-2
        if PerformIteration('14-3-2-10') then begin
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
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-3-2', '4_AV_RE', '', 'BLUE', '', 1, 'PALLET', 111.1, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-3-2', '4_AV_RE', '', 'BLUE', '', 1, 'PCS', 44.44, 0);

        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-3-2.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-3-3
        if PerformIteration('14-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-3-4
        if PerformIteration('14-3-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 34, 'PCS', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 34, 11, 0, 3, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '5_ST_RA', '', 34, 'PCS', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 34, 11, 0, 3, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::"Charge (Item)", 'UPS', '', 7, '', 10);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 7, 2, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-4-30') then begin
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::Order, SalesLine."Document No.", 10000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::Order, SalesLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-4-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-4-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-3-4.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-3-5
        if PerformIteration('14-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-3-6
        if PerformIteration('14-3-6-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-6-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 17, 0, 11, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 17, 0, 11, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 2, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-6-30') then begin
            SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 30000);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-6-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-3-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-3-7
        if PerformIteration('14-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-3-8
        if PerformIteration('14-3-8-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-8-20') then begin
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 5, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 5, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 2, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-8-30') then begin
            SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 30000);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-8-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-8-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-3-8.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-3-9
        if PerformIteration('14-3-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-3-10
        if PerformIteration('14-3-10-10') then begin
            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-3-10', '4_AV_RE', '', 'BLUE', '', 2, 'PALLET', 222.2, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-3-10', '4_AV_RE', '', 'BLUE', '', 17, 'PCS', 22.22, 0);

        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-10-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-10-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-3-10-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-3-10.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-3-11
        if PerformIteration('14-3-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 14-4-1
        if PerformIteration('14-4-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 14-4-2
        if PerformIteration('14-4-2-10') then begin
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
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-4-2', '6_AV_OV', '61', 'BLUE', '', 100, 'PALLET', 60, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-4-2', '7_ST_OV', '71', 'BLUE', '', 100, 'PALLET', 70, 0);

        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-4-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;
        // 14-4-3
        if PerformIteration('14-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-4-4
        if PerformIteration('14-4-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-4-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 100, 'PCS', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 100, 100, 0, 20, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '7_ST_OV', '', 100, 'PCS', 70);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 100, 100, 0, 20, true);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '6_AV_OV', '61', 100, 'PALLET', 600);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 100, 100, 0, 45, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '7_ST_OV', '71', 100, 'PALLET', 1540);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 100, 100, 0, 45, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::"Charge (Item)", 'Insurance', '', 4, '', 100);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 4, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-4-4-30') then begin
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesLine."Document Type"::Order, SalesLine."Document No.", 10000, '6_AV_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, SalesLine."Document Type"::Order, SalesLine."Document No.", 20000, '7_ST_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, SalesLine."Document Type"::Order, SalesLine."Document No.", 30000, '6_AV_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 40000, SalesLine."Document Type"::Order, SalesLine."Document No.", 40000, '7_ST_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-4-4-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 14-4-5
        if PerformIteration('14-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-4-6
        if PerformIteration('14-4-6-10') then begin
            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-4-6', '6_AV_OV', '', 'BLUE', '', 100, 'PALLET', 30, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS14-4-6', '6_AV_OV', '61', 'BLUE', '', 100, 'PALLET', 15, 0);

        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-4-6-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-4-6-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-4-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS14-4-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-4-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-4-7
        if PerformIteration('14-4-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        IterationActive := FirstIteration = '';
        // 14-5-1
        if PerformIteration('14-5-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then exit;
        // 14-5-2
        if PerformIteration('14-5-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::Purchase, 'TCS14-5-2', '1_FI_RE', '', 'BLUE', '', 100, 'PCS', 9, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::Purchase, 'TCS14-5-2', '2_LI_RA', '', 'BLUE', '', 100, 'PCS', 7, 0);

        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-5-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then exit;
        // 14-5-3
        if PerformIteration('14-5-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-5-4
        if PerformIteration('14-5-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-5-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 100);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-5-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;
        // 14-5-5
        if PerformIteration('14-5-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-5-6
        if PerformIteration('14-5-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'REVAL', 'DEFAULT', ItemJnlLineNo, 20010104D,
              ItemJnlLine."Entry Type"::Purchase, 'TCS14-5-6', '1_FI_RE', '', '', '', 0, '', 0, 0);
            ItemJnlLine.SetUpNewLine(ItemJnlLine);
            ItemJnlLine.Validate("Applies-to Entry", LastILENo + 1);
            ItemJnlLine.Validate("Inventory Value (Revalued)", 1100);
            ItemJnlLine.Modify();
        end;

        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-5-6-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-5-6-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;
        // 14-5-7
        if PerformIteration('14-5-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
        // 14-5-8
        if PerformIteration('14-5-8-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, '', false, true);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-5-8-20') then
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 10, 0, 0, true);
        if LastIteration = ActualIteration then exit;


        if PerformIteration('14-5-8-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then exit;


        if PerformIteration('14-5-8-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then exit;

        if PerformIteration('14-5-8-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS14-5-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase14-4-6.pdf');
        end;
        if LastIteration = ActualIteration then exit;
        // 14-5-9
        if PerformIteration('14-5-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then exit;
    end;

    [Scope('OnPrem')]
    procedure SetBalAccountNo(NewBalAccountNo: Code[10]): Code[20]
    begin
        if SalesHeader."Bal. Account No." <> NewBalAccountNo then begin
            SalesHeader.Validate("Bal. Account No.", NewBalAccountNo);
            SalesHeader.Modify();
        end;
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

