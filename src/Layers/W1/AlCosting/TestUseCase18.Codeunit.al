codeunit 103419 "Test Use Case 18"
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
        SaveSalesHeader: Record "Sales Header";
        SaleShipHeader: Record "Sales Shipment Header";
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
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 18-1-1
        if PerformIteration('18-1-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 18-1-2
        if PerformIteration('18-1-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-1-2', '1_FI_RE', '', 'BLUE', '', 200, 'PCS', 10, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-1-2', '2_LI_RA', '', 'BLUE', '', 200, 'PCS', 20, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-1-2', '4_AV_RE', '', 'BLUE', '', 200, 'PCS', 40, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-1-2', '5_ST_RA', '', 'BLUE', '', 200, 'PCS', 50, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;
        // 18-1-3
        if PerformIteration('18-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-1-4
        if PerformIteration('18-1-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PALLET', 1300);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PALLET', 600);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 50, 'PCS', 400);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 50, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 50, 'PCS', 500);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 50, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 18-1-5
        if PerformIteration('18-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-1-6
        if PerformIteration('18-1-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '49858585', 20010103D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010103D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 50, 'PCS', 100);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 50, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 50, 'PCS', 200);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 50, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PALLET', 2000);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PALLET', 5500);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 18-1-7
        if PerformIteration('18-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-1-8
        if PerformIteration('18-1-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '49858585', WorkDate());
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, '', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 8, '', 10);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-8-30') then begin
            SaveSalesHeader := SalesHeader;
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.Find('-');
            SalesHeader.SetRange("Document Type");
            TestScriptMgmt.RetrieveSaleShipHeader(SalesHeader, SaleShipHeader, 1);
            SalesHeader := SaveSalesHeader;
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 40000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 40000, 1);

            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.Find('+');
            SalesHeader.SetRange("Document Type");
            TestScriptMgmt.RetrieveSaleShipHeader(SalesHeader, SaleShipHeader, 1);
            SalesHeader := SaveSalesHeader;
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 50000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 50000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 60000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 60000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 70000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 70000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 80000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 40000, '5_ST_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 80000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-8-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-8-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-1-8-60') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-1-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-1-9
        if PerformIteration('18-1-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 18-2-1
        if PerformIteration('18-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 18-2-2
        if PerformIteration('18-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-2-2', '1_FI_RE', '', '', '', 200, 'PCS', 10, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-2-2', '6_AV_OV', '61', '', '', 200, 'PCS', 60, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-2-2', '7_ST_OV', '71', '', '', 200, 'PCS', 70, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-2-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-2-3
        if PerformIteration('18-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-2-4
        if PerformIteration('18-2-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010103D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010103D, '', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PALLET', 100);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 3, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '6_AV_OV', '61', 5, 'PALLET', 600);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 3, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '7_ST_OV', '71', 5, 'PALLET', 700);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 3, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-2-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-2-5
        if PerformIteration('18-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-2-6
        if PerformIteration('18-2-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '49858585', 20010105D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010105D, '', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 50, 'PCS', 10);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 40, 30, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '6_AV_OV', '61', 50, 'PCS', 60);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 40, 30, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '7_ST_OV', '71', 50, 'PCS', 70);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 40, 30, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-2-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-2-7
        if PerformIteration('18-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-2-8
        if PerformIteration('18-2-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '30000', WorkDate());
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010107D, '', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 6, '', 10);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 6, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::"Charge (Item)", 'Insurance', '', 6, '', 20);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 6, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-8-30') then begin
            SaveSalesHeader := SalesHeader;
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.Find('-');
            SalesHeader.SetRange("Document Type");
            TestScriptMgmt.RetrieveSaleShipHeader(SalesHeader, SaleShipHeader, 1);
            SalesHeader := SaveSalesHeader;
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 10000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 2);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 20000, '6_AV_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 2);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 30000, '7_ST_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 2);

            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.Find('+');
            SalesHeader.SetRange("Document Type");
            TestScriptMgmt.RetrieveSaleShipHeader(SalesHeader, SaleShipHeader, 1);
            SalesHeader := SaveSalesHeader;
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 20000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 2);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 20000, '6_AV_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 2);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 30000, '7_ST_OV');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 2);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-8-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-8-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-2-8-60') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-2-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-2-9
        if PerformIteration('18-2-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 18-3-1
        if PerformIteration('18-3-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 18-3-2
        if PerformIteration('18-3-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(false);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-3-2', '1_FI_RE', '', 'BLUE', '', 1, 'PCS', 11.11, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-3-2', '2_LI_RA', '', 'BLUE', '', 1, 'PCS', 22.22, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-3-2', '4_AV_RE', '', 'BLUE', '', 1, 'PCS', 44.44, 0);

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-3-2', '5_ST_RA', '', 'BLUE', '', 1, 'PCS', 55.55, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-2-30') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(1, '', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-3-2.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-3-3
        if PerformIteration('18-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-3-4
        if PerformIteration('18-3-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010102D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PALLET', 100);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 4, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 10, 'PALLET', 200);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 4, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 40);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 0, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 50);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 0, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-4-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-4-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS18-3-4', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-3-4.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-3-5
        if PerformIteration('18-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-3-6
        if PerformIteration('18-3-6-10') then
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010104D, '', false, true);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 2, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 2, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 0, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 0, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-6-30') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-6-40') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS18-3-6', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-3-6.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-3-7
        if PerformIteration('18-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-3-8
        if PerformIteration('18-3-8-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '30000', WorkDate());
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010106D, '', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-8-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 4, '', 11.11);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 4, 4, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-8-30') then begin
            SaveSalesHeader := SalesHeader;
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.Find('-');
            SalesHeader.SetRange("Document Type");
            TestScriptMgmt.RetrieveSaleShipHeader(SalesHeader, SaleShipHeader, 1);
            SalesHeader := SaveSalesHeader;
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 20000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 20000, '2_LI_RA');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 30000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 30000, '4_AV_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 30000, 2);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-8-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-8-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-3-8-60') then begin
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.InitializeRequest(0, 'TCS18-3-8', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase18-3-8.pdf');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-3-9
        if PerformIteration('18-3-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase4()
    begin
        IterationActive := FirstIteration = '';
        // 18-4-1
        if PerformIteration('18-4-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 18-4-2
        if PerformIteration('18-4-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ItemJnlLineNo := 10000;
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS18-4-2', '1_FI_RE', '', 'BLUE', '', 3, 'PCS', 11.11, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-4-2-20') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;
        // 18-4-3
        if PerformIteration('18-4-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-4-4
        if PerformIteration('18-4-4-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', WorkDate());
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010102D, 'BLUE', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-4-4-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 3, 'PCS', 13.33);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-4-4-30') then begin
            TestScriptMgmt.PostSalesOrder(SalesHeader);
            SaleShipHeader.Find('+');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 18-4-5
        if PerformIteration('18-4-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 18-4-6
        if PerformIteration('18-4-6-10') then begin
            TestScriptMgmt.ClearDimensions();
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', WorkDate());
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010103D, '', true, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-4-6-20') then begin
            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertDimension('AREA', '30', '');
            TestScriptMgmt.InsertDimension('DEPARTMENT', 'Sales', '');
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::"Charge (Item)", 'UPS', '', 1, '', 15);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::"Charge (Item)", 'GPS', '', 1, '', 17);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-4-6-30') then begin
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 10000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);

            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 20000);
            TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, "Sales Applies-to Document Type"::Shipment, SaleShipHeader."No.", 10000, '1_FI_RE');
            TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, SalesLine."Line No.", 10000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('18-4-6-40') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 18-4-7
        if PerformIteration('18-4-7-10') then
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

