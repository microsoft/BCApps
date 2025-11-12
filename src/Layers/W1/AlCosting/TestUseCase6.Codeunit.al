codeunit 103407 "Test Use Case 6"
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
        // 6-1-1
        if PerformIteration('6-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 6-1-2
        if PerformIteration('6-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
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

        if PerformIteration('6-1-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 3, 'PALLET', 188.88);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 3, 'PALLET', 77.77);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 55.55);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 3, 'PCS', 66.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-1-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 6-1-3
        if PerformIteration('6-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 6-1-4
        if PerformIteration('6-1-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '49989898', 20010102D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, 'RED', '', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 3, 'PALLET', 500.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 3, 'PALLET', 400.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 200.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 3, 'PCS', 100.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-1-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 6-1-5
        if PerformIteration('6-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 6-1-6
        if PerformIteration('6-1-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '30000', 0D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS6-1-6', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-1-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 8, '', 6.66);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 8, 8, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-1-6-30') then begin
            SavePurchHeader := PurchHeader;
            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('-');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchHeader := SavePurchHeader;
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);

            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('+');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchHeader := SavePurchHeader;
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 70000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 70000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 80000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 80000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-1-6-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 6-1-7
        if PerformIteration('6-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 6-3-1
        if PerformIteration('6-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 6-3-2
        if PerformIteration('6-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'TCS6-3-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 179.55);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 8, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 65.55);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 8, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '71', 10, 'PCS', 75.55);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 8, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase6-3-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 6-3-3
        if PerformIteration('6-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 6-3-4
        if PerformIteration('6-3-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '49989898', 20010103D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS6-3-4', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 500.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 8, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '6_AV_OV', '61', 10, 'PCS', 300.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 8, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '7_ST_OV', '71', 10, 'PCS', 200.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 9, 8, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS6-3-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase6-3-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 6-3-5
        if PerformIteration('6-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 6-3-6
        if PerformIteration('6-3-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '49989898', 0D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010105D, '', 'TCS6-3-6', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 6, '', 10.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 6, 6, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'GPS', '', 6, '', 20.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 6, 6, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-6-30') then begin
            SavePurchHeader := PurchHeader;
            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('-');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchHeader := SavePurchHeader;
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 10000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 2);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 2);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '7_ST_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 2);

            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('+');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchHeader := SavePurchHeader;
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 20000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 2);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '6_AV_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 2);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '7_ST_OV');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 2);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-6-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-3-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS6-3-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase6-3-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 6-3-7
        if PerformIteration('6-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 6-4-1
        if PerformIteration('6-4-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 6-4-2
        if PerformIteration('6-4-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS6-4-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 11.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 4, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 12.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 4, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PALLET', 110.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PALLET', 120.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 0, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-2-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase6-4-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 6-4-3
        if PerformIteration('6-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 6-4-4
        if PerformIteration('6-4-4-10') then
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010103D, '', 'TCS6-4-4', true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 2, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 2, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 0, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-4-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS6-4-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase6-4-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 6-4-5
        if PerformIteration('6-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 6-4-6
        if PerformIteration('6-4-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '30000', 0D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010105D, 'RED', 'TCS6-4-6', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 4, '', 11.11);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 4, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-6-30') then begin
            SavePurchHeader := PurchHeader;
            PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.Find('-');
            PurchHeader.SetRange("Document Type");
            TestScriptMgmt.RetrievePurchRcptHeader(PurchHeader, PurchRcptHeader, 1);
            PurchHeader := SavePurchHeader;
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);

            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 2);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-6-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-4-6-50') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS6-4-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase6-4-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 6-4-7
        if PerformIteration('6-4-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        IterationActive := FirstIteration = '';
        // 6-5-1
        if PerformIteration('6-5-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 6-5-2
        if PerformIteration('6-5-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '30000', 20010101D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS6-5-2', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-5-2-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 3, 'PCS', 10.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 3, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-5-2-30') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 6-5-3
        if PerformIteration('6-5-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 6-5-4
        if PerformIteration('6-5-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '30000', 0D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, '', 'TCS6-5-4', true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-5-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'SALES', '');
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'UPS', '', 1, '', 5.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'GPS', '', 1, '', 7.0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 1, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-5-4-30') then begin
            Clear(SavePurchHeader);
            TestScriptMgmt.RetrievePurchRcptHeader(SavePurchHeader, PurchRcptHeader, 1);
            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 10000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);

            PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", 20000);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, PurchRcptHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('6-5-4-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 6-5-5
        if PerformIteration('6-5-5-10') then
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

