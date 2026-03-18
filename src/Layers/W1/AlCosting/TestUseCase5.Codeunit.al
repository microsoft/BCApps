codeunit 103406 "Test Use Case 5"
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
        SavePurchHeader: Record "Purchase Header";
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
        // 5-1-1
        if PerformIteration('5-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 5-1-2
        if PerformIteration('5-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            TestScriptMgmt.SetPurchCalcInvDisc(true);
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS5-1-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 166.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 2, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PALLET', 566.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 2, 0, 7);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 130, 'PCS', 13.33);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 39, 26, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 110, 'PCS', 53.33);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 33, 22, 0, 7);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 5-1-3
        if PerformIteration('5-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 5-1-4
        if PerformIteration('5-1-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, 'BLUE', 'TCS5-1-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 2, 3, 200, 7);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 2, 3, 600, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 26, 39, 15, 7);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 22, 33, 55, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 5-1-5
        if PerformIteration('5-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 5-1-6
        if PerformIteration('5-1-6-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, 'BLUE', 'TCS5-1-6', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 4, 4, 288.86, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 4, 4, 733.26, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 52, 52, 22.22, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 44, 44, 66.66, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 5-1-7
        if PerformIteration('5-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 5-1-8
        if PerformIteration('5-1-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010104D, 'BLUE', 'TCS5-1-8');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 5, '', 11.11, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 4, 4);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'GPS', '', 5, '', 22.22, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 4, 4);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'INSURANCE', '', 5, '', 33.33, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 4, 4);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-8-30') then begin
            TestScriptMgmt.ClearDimensions();
            SavePurchHeader := PurchHeader;
            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('-');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchHeader := SavePurchHeader;
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 10000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);

            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('-');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 2);
            PurchHeader := SavePurchHeader;
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 20000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);

            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('-');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 3);
            PurchHeader := SavePurchHeader;
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 30000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-8-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-1-8-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 5-1-9
        if PerformIteration('5-1-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;

        // Clean-up
        TestScriptMgmt.SetAutoCostPost(false);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 5-3-1
        if PerformIteration('5-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 5-3-2
        if PerformIteration('5-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            TestScriptMgmt.SetPurchCalcInvDisc(true);
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS5-3-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '7_ST_OV', '', 6, 'PALLET', 110);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 2, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '', 66, 'PCS', 10);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 33, 22, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '71', 66, 'PCS', 20);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 33, 22, 0, 11);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '6_AV_OV', '', 6, 'PALLET', 100);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 2, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 30, 'PCS', 20);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 15, 10, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '61', 30, 'PCS', 40);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 15, 10, 0, 11);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase5-3-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 5-3-3
        if PerformIteration('5-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 5-3-4
        if PerformIteration('5-3-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, 'BLUE', 'TCS5-3-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 2, 3, 220, 11);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 22, 33, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 22, 33, 40, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 2, 3, 200, 11);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 10, 15, 40, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 10, 15, 80, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS5-3-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase5-3-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 5-3-5
        if PerformIteration('5-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 5-3-6
        if PerformIteration('5-3-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010105D, 'BLUE', 'TCS5-3-6');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '7_ST_OV', '', 1, 'PALLET', 55, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '7_ST_OV', '', 11, 'PCS', 5, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 11, 11);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '71', 11, 'PCS', 10, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 11, 11);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '6_AV_OV', '', 1, 'PALLET', 50, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 10, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '6_AV_OV', '61', 5, 'PCS', 20, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 5, 5);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-6-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-6-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-3-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS5-3-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase5-3-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 5-3-7
        if PerformIteration('5-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 5-4-1
        if PerformIteration('5-4-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 5-4-2
        if PerformIteration('5-4-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '49989898', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'TCS5-4-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-4-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 143, 'PCS', 10);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 143, 143, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 33, 'PCS', 20);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 33, 33, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 11, 'PALLET', 130);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 11, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 11, 'PALLET', 60);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 11, 11, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-4-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 5-4-3
        if PerformIteration('5-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 5-4-4
        if PerformIteration('5-4-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '49989898', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010102D, '', 'TCS5-4-4');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-4-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 143, 'PCS', 10, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 143, 143);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 33, 'PCS', 20, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 33, 33);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 11, 'PALLET', 130, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 11, 11);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '2_LI_RA', '', 11, 'PALLET', 60, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 11, 11);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-4-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-4-4-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-4-4-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase5-4-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 5-4-5
        if PerformIteration('5-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        IterationActive := FirstIteration = '';
        // 5-5-1
        if PerformIteration('5-5-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 5-5-2
        if PerformIteration('5-5-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS5-5-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 22.22, '', 22.22);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 22.22, 22.22, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 50.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 40.4);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 10, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::"Charge (Item)", 'GPS', '', 2, '', 10);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 2, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-2-30') then begin
            TestScriptMgmt.ClearDimensions();
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 10000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Invoice, PurchLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 11.11);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Invoice, PurchLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 11.11);
            TestScriptMgmt.ClearDimensions();
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 40000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Invoice, PurchLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Invoice, PurchLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-2-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 5-5-3
        if PerformIteration('5-5-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 5-5-4
        if PerformIteration('5-5-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '10000', 0D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20010102D, 'BLUE', 'TCS5-5-4');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 44.44, '', 22.22, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 22.22, 22.22);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 20, 'PCS', 50.5, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 10, 10);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 40.4, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 10, 10);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::"Charge (Item)", 'GPS', '', 4, '', 10, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 2, 2);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-4-30') then begin
            TestScriptMgmt.ClearDimensions();
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 10000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchLine."Document Type"::"Return Order", PurchLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 11.11);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchLine."Document Type"::"Return Order", PurchLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 11.11);
            TestScriptMgmt.ClearDimensions();
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 40000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchLine."Document Type"::"Return Order", PurchLine."Document No.", 20000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, PurchLine."Document Type"::"Return Order", PurchLine."Document No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-4-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('5-5-4-60') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase5-5-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 5-5-5
        if PerformIteration('5-5-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
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

