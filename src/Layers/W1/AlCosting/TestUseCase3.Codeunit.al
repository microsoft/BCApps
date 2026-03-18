codeunit 103404 "Test Use Case 3"
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
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 3-1-1
        if PerformIteration('3-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 3-1-2
        if PerformIteration('3-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS3-1-2', true);
            SetBalAccountNo('2910');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 3, 'PALLET', 1350.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 0, 0);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '6_AV_OV', '61', 3, 'PALLET', 1350.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '', 3, 'PALLET', 1200.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 15, 'PCS', 100.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '61', 15, 'PCS', 100.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 0, 0);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '', 15, 'PCS', 90.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 5, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 3-1-3
        if PerformIteration('3-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-1-4
        if PerformIteration('3-1-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, 'BLUE', 'TCS3-1-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 1, 1, 1200, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 1, 1, 1200, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 1, 1, 1050, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 5, 5, 80, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 5, 5, 80, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 5, 5, 70, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::"Charge (Item)", 'UPS', '', 24, '', 10);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 24, 24, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 1, '', 30);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-4-30') then begin
            TestScriptMgmt.ClearDimensions();
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 70000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchLine."Document Type", PurchLine."Document No.", 10000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 6);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchLine."Document Type", PurchLine."Document No.", 20000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 6);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchLine."Document Type", PurchLine."Document No.", 30000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 6);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, PurchLine."Document Type", PurchLine."Document No.", 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 2);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, PurchLine."Document Type", PurchLine."Document No.", 50000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 2);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, PurchLine."Document Type", PurchLine."Document No.", 60000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 2);

            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 80000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchLine."Document Type", PurchLine."Document No.", 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 3-1-5
        if PerformIteration('3-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-1-6
        if PerformIteration('3-1-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010103D, 'BLUE', 'TCS3-1-6');
            SetBalAccountNo('2910');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PALLET', 1200.0, 7);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '6_AV_OV', '61', 1, 'PALLET', 1200.0, 8);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '', 1, 'PALLET', 1050.0, 9);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 80.0, 10);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 80.0, 11);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 70.0, 12);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 70000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 1, '', 30, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.ClearDimensions();
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 70000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchLine."Document Type", PurchLine."Document No.", 50000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-6-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-1-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-1-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-1-7
        if PerformIteration('3-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 3-2-1
        if PerformIteration('3-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 3-1-2
        if PerformIteration('3-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '49989898', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 900.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 50, 'PCS', 360.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 15, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 3-2-3
        if PerformIteration('3-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-2-4
        if PerformIteration('3-2-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, 'BLUE', 'TCS3-2-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 3, 3, 1000, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 15, 15, 400, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'UPS', '', 4, '', 110);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 4, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-4-30') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchLine."Document Type", PurchLine."Document No.", 10000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchLine."Document Type", PurchLine."Document No.", 20000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);

            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 3-2-5
        if PerformIteration('3-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-2-6
        if PerformIteration('3-2-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '49989898', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010103D, '', 'TCS3-2-6');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 3, 'PALLET', 900.0, 1);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 3, 3);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 15, 'PCS', 360.0, 2);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 15, 15);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-6-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-2-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-2-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-2-7
        if PerformIteration('3-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 3-3-1
        if PerformIteration('3-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 3-3-2
        if PerformIteration('3-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 6, 'PALLET', 3000.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 30, 'PCS', 1200.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-3-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-3-3
        if PerformIteration('3-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-3-4
        if PerformIteration('3-3-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', 'TCS3-3-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 3, 3, 3333.33, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 15, 15, 1333.33, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-3-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-3-5
        if PerformIteration('3-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-3-6
        if PerformIteration('3-3-6-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS3-3-6', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 1, 3, 3000, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 5, 15, 1200, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-3-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-3-7
        if PerformIteration('3-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-3-8
        if PerformIteration('3-3-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010104D, '', 'TCS3-3-8');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 3, 'PALLET', 3333.33, 3);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 3, 3);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 15, 'PCS', 1333.33, 4);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 15, 15);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-8-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-8-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-3-8-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-3-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-3-9
        if PerformIteration('3-3-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 3-4-1
        if PerformIteration('3-4-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 3-4-2
        if PerformIteration('3-4-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 4, 'PALLET', 50.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '6_AV_OV', '61', 4, 'PALLET', 50.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '', 4, 'PALLET', 100.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 10.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 10.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 20.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS3-4-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-4-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-4-3
        if PerformIteration('3-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-4-4
        if PerformIteration('3-4-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', '', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 0, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 0, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 0, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 5, 0, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 5, 0, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 5, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS3-4-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-4-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-4-5
        if PerformIteration('3-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-4-6
        if PerformIteration('3-4-6-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS3-4-6', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 1, 100, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 1, 100, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 1, 200, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 5, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 5, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 5, 40, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::"Charge (Item)", 'UPS', '', 6, '', 10.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 6, 6, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-6-30') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);

            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 2);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 50000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 60000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-6-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS3-4-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-4-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-4-7
        if PerformIteration('3-4-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-4-8
        if PerformIteration('3-4-8-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010104D, '', 'TCS3-4-8', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 1, 1, 50, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 1, 1, 50, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 1, 1, 100, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 5, 5, 10, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 5, 5, 10, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 5, 5, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-8-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-8-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS3-4-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-4-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-4-9
        if PerformIteration('3-4-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 3-4-10
        if PerformIteration('3-4-10-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010105D, '', 'TCS3-4-10');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-10-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PALLET', 50.0, 1);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '6_AV_OV', '61', 1, 'PALLET', 50.0, 2);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '', 1, 'PALLET', 100.0, 3);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 10.0, 4);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 10.0, 5);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 20.0, 6);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-10-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-10-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('3-4-10-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS3-4-10', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-4-10.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 3-4-11
        if PerformIteration('3-4-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure SetBalAccountNo(NewBalAccountNo: Code[10]): Code[20]
    begin
        if PurchHeader."Bal. Account No." <> NewBalAccountNo then begin
            PurchHeader.Validate("Bal. Account No.", NewBalAccountNo);
            PurchHeader.Modify();
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

