codeunit 103405 "Test Use Case 4"
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 4-1-1
        if PerformIteration('4-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 4-1-2
        if PerformIteration('4-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS4-1-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 166.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 2, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PALLET', 566.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 2, 0, 0);
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 130, 'PCS', 13.33);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 39, 26, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 110, 'PCS', 53.33);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 33, 22, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS4-1-2', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-1-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 4-1-3
        if PerformIteration('4-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 4-1-4
        if PerformIteration('4-1-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, 'BLUE', 'TCS4-1-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 3, 0, 200, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 3, 0, 600, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 39, 0, 15, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 33, 0, 55, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS4-1-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-1-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 4-1-5
        if PerformIteration('4-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 4-1-6
        if PerformIteration('4-1-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010103D, 'BLUE', 'TCS4-1-6');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 2, 'PALLET', 166.66, 1);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 2, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 2, 'PALLET', 566.66, 3);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 2, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 26, 'PCS', 13.33, 5);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 26, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 22, 'PCS', 53.33, 7);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 22, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-6-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-1-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS4-1-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-1-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 4-1-7
        if PerformIteration('4-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 4-2-1
        if PerformIteration('4-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 4-2-2
        if PerformIteration('4-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-2-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 999.99);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 6, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 50, 'PCS', 99.99);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 30, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-2-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 4-2-3
        if PerformIteration('4-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 4-2-4
        if PerformIteration('4-2-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', '', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 3, 0, 1999.98, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 15, 0, 199.98, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-2-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 4-2-5
        if PerformIteration('4-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 4-2-6
        if PerformIteration('4-2-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '30000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010103D, '', '');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-2-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 6, 'PALLET', 999.99, 1);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 6, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 30, 'PCS', 99.99, 2);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 30, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-2-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 4-2-7
        if PerformIteration('4-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 4-3-1
        if PerformIteration('4-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 4-3-2
        if PerformIteration('4-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '49989898', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '7_ST_OV', '', 4, 'PALLET', 2500);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '', 44, 'PCS', 220);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '71', 44, 'PCS', 230);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '6_AV_OV', '', 4, 'PALLET', 1000);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 20, 'PCS', 100);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '61', 20, 'PCS', 200);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-3-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 4-3-3
        if PerformIteration('4-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 4-3-4
        if PerformIteration('4-3-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, 'BLUE', '', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 1, 0, 1500, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 11, 0, 120, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 11, 0, 130, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 1, 0, 500, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 5, 0, 50, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 5, 0, 100, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-3-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 4-3-5
        if PerformIteration('4-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 4-3-6
        if PerformIteration('4-3-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '49989898', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010103D, 'BLUE', '');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '7_ST_OV', '', 2, 'PALLET', 2500, 1);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 2, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '', 22, 'PCS', 220, 2);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 22, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '6_AV_OV', '', 2, 'PALLET', 1000, 4);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 2, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 100, 5);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 10, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('4-3-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-3-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 4-3-7
        if PerformIteration('4-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
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

