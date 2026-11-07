codeunit 103403 "Test Use Case 2"
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
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Item: Record Item;
        SelectionForm: Page "Test Selection";
        CalcInvValue: Report "Calculate Inventory Value";
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
            4:
                PerformTestCase4();
            5:
                PerformTestCase5();
            6:
                PerformTestCase6();
            7:
                PerformTestCase7();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 2-1-1
        if PerformIteration('2-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 2-1-2
        if PerformIteration('2-1-2-10') then begin
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

        if PerformIteration('2-1-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 11, 'PALLET', 199.9);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-1-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-1-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase2-1-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-1-3
        if PerformIteration('2-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-1-4
        if PerformIteration('2-1-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS2-1-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 11, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-1-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-1-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase2-1-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-1-5
        if PerformIteration('2-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 2-2-1
        if PerformIteration('2-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 2-2-2
        if PerformIteration('2-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
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

        if PerformIteration('2-2-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 12, 'PALLET', 299.9);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 12, 'PALLET', 599.9);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 12, 'PCS', 50);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 12, 'PCS', 60);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::"Charge (Item)", 'UPS', '', 10, '', 33.33);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-2-3
        if PerformIteration('2-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-2-4
        if PerformIteration('2-2-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', 'TCS2-2-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 3, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-4-30') then begin
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchLine."Document Type", PurchLine."Document No.", 10000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchLine."Document Type", PurchLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchLine."Document Type", PurchLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-2-5
        if PerformIteration('2-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-2-6
        if PerformIteration('2-2-6-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS2-2-6', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 3, 350, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 3, 650, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 3, 60, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 3, 70, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 3, 3, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-6-30') then begin
            PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 50000);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-6-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-2-7
        if PerformIteration('2-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-2-8
        if PerformIteration('2-2-8-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010104D, '', 'TCS2-2-8', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 4, 4, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-8-30') then begin
            PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", 50000);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, PurchLine."Document Type", PurchLine."Document No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-2-8-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-2-9
        if PerformIteration('2-2-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 2-4-1
        if PerformIteration('2-4-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 2-4-2
        if PerformIteration('2-4-2-10') then begin
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

        if PerformIteration('2-4-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '61', 11, 'PALLET', 399.9);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '71', 11, 'PALLET', 899.9);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '61', 11, 'PCS', 70);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '7_ST_OV', '71', 11, 'PCS', 80);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS2-4-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase2-1-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-4-3
        if PerformIteration('2-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-4-4
        if PerformIteration('2-4-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', 'TCS2-4-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 3, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 3, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::"Charge (Item)", 'UPS', '', 24, '', 11);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 8, 8, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-4-30') then begin
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '7_ST_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 2);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 2);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchLine."Document Type", PurchLine."Document No.", 10000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 2);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, PurchLine."Document Type", PurchLine."Document No.", 40000, '7_ST_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 2);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-4-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS2-4-4-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase2-4-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-4-5
        if PerformIteration('2-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-4-6
        if PerformIteration('2-4-6-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS2-4-6', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 2, 500, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 2, 1000, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 2, 88.8, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 2, 99.9, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 4, 4, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-6-30') then begin
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 50000);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-6-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS2-4-6-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase2-4-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-4-7
        if PerformIteration('2-4-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-4-8
        if PerformIteration('2-4-8-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010104D, '', 'TCS2-4-8', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 5, 550, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 5, 1050, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 5, 98.8, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 5, 109.9, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 12, 12, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-8-30') then begin
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 50000);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 2);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 2);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 4);
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 4);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-8-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-4-8-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS2-4-8-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase2-4-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-4-9
        if PerformIteration('2-4-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        IterationActive := FirstIteration = '';
        // 2-5-1
        if PerformIteration('2-5-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 2-5-2
        if PerformIteration('2-5-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
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

        if PerformIteration('2-5-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PALLET', 90);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 250);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 50);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PALLET', 660);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 60);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-5-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-5-3
        if PerformIteration('2-5-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-5-4
        if PerformIteration('2-5-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', 'TCS2-5-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-5-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 10, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 10, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 10, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 10, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 10, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 10, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::"Charge (Item)", 'UPS', '', 6, '', 66.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 6, 6, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::"Charge (Item)", 'GPS', '', 3, '', 66.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 3, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-5-4-30') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 70000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 2);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 2);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 2);

            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 80000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchLine."Document Type", PurchHeader."No.", 10000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, PurchLine."Document Type", PurchHeader."No.", 50000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, PurchLine."Document Type", PurchHeader."No.", 60000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-5-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-5-5
        if PerformIteration('2-5-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    begin
        IterationActive := FirstIteration = '';
        // 2-6-1
        if PerformIteration('2-6-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 2-6-2
        if PerformIteration('2-6-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '49989898', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-6-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 100);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PALLET', 50);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-6-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-6-3
        if PerformIteration('2-6-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-6-4
        if PerformIteration('2-6-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', 'TCS2-6-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-6-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 10, 130, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 10, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 10, 60, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 10, 40, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::"Charge (Item)", 'UPS', '', 4, '', 100);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 4, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 4, '', 200);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 4, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-6-4-30') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 50000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);

            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 60000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, PurchLine."Document Type", PurchHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchLine."Document Type", PurchHeader."No.", 20000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchLine."Document Type", PurchHeader."No.", 30000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, PurchLine."Document Type", PurchHeader."No.", 40000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-6-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-6-5
        if PerformIteration('2-6-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    begin
        IterationActive := FirstIteration = '';
        // 2-7-1
        if PerformIteration('2-7-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 2-7-2
        if PerformIteration('2-7-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PALLET', 10);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-7-3
        if PerformIteration('2-7-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-7-4
        if PerformIteration('2-7-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', 'TCS2-7-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 5, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 10, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 2-7-5
        if PerformIteration('2-7-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-7-6
        if PerformIteration('2-7-6-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS2-7-6', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 5, 7, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-6-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('2-7-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS2-7-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase2-7-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-7-7
        if PerformIteration('2-7-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 2-7-8
        if PerformIteration('2-7-8-10') then begin
            Commit();
            Clear(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SetRange("No.", '1_FI_RE');
            CalcInvValue.SetTableView(Item);
            CalcInvValue.SetParameters(20010105D, 'TCS2-7-8', true, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", true);
            CalcInvValue.UseRequestPage(false);
            CalcInvValue.RunModal();
            Clear(CalcInvValue);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 2-7-9
        if PerformIteration('2-7-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
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

