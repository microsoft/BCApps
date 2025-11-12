codeunit 103420 "Test Use Case 19"
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
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        TempProdBOMHeader: Record "Production BOM Header" temporary;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        ConsumpItemJnlLine: Record "Item Journal Line";
        OutputItemJnlLine: Record "Item Journal Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        SelectionForm: Page "Test Selection";
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        CalcInvValue: Report "Calculate Inventory Value";
        CalcConsumption: Report "Calc. Consumption";
        RefreshProductionOrder: Report "Refresh Production Order";
        TestScriptMgmt: Codeunit _TestscriptManagement;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
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
            // Bug 37027
            // 2: PerformTestCase2;
            3:
                PerformTestCase3();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        IterationActive := FirstIteration = '';
        // 19-1-1
        if PerformIteration('19-1-1-10') then begin
            TestScriptMgmt.SetGlobalPreconditions();
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(false);
            TestScriptMgmt.SetAddRepCurr('DEM');
        end;
        if LastIteration = ActualIteration then
            exit;
        // 19-1-2
        if PerformIteration('19-1-2-10') then begin
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', 20011125D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS19-1-2', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 2, 'PALLET', 130);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 3, 'PALLET', 90);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '3_SP_RE', '', 1, 'PALLET', 187);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 19);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '4_AV_RE', '', 3, 'PALLET', 135);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '5_ST_RA', '', 1, 'PALLET', 100);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '1_FI_RE', '11', 2, 'PALLET', 136.5);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 3, 'PALLET', 94.5);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '3_SP_RE', '31', 1, 'PALLET', 195.5);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 19.5);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 110000, PurchLine.Type::Item, '4_AV_RE', '41', 3, 'PALLET', 143.5);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 120000, PurchLine.Type::Item, '5_ST_RA', '51', 1, 'PALLET', 110);

            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-2-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-2-30') then begin
            WMSTestscriptManagement.InsertTransferHeader(TransHeader, 'Blue', 'RED', 'OWN LOG.', 20011129D);

            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 10000, '1_FI_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 20000, '2_LI_RA', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 30000, '3_SP_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 40000, '4_AV_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 50000, '4_AV_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 60000, '5_ST_RA', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 70000, '1_FI_RE', '11', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 80000, '2_LI_RA', '21', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 90000, '3_SP_RE', '31', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 100000, '4_AV_RE', '41', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 110000, '4_AV_RE', '41', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 120000, '5_ST_RA', '51', 'PCS', 1, 0, 1);

            CreateReservEntryFor(5741, 0, TransHeader."No.", '', 0, 30000, 1, 1, 1, 'SN11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011129D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5741, 1, TransHeader."No.", '', 0, 30000, 1, 1, 1, 'SN11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'RED', '', 20011129D, 0D, 0, "Reservation Status"::Surplus);

            CreateReservEntryFor(5741, 0, TransHeader."No.", '', 0, 90000, 1, 1, 1, 'ST11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011129D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5741, 1, TransHeader."No.", '', 0, 90000, 1, 1, 1, 'ST11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'RED', '', 20011129D, 0D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-2-40') then
            WMSTestscriptManagement.PostTransferOrder(TransHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-2-50') then
            WMSTestscriptManagement.PostTransferOrderRcpt(TransHeader)
            ;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-2-60') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', 20011130D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011130D, 'BLUE', true, true);

            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 28, 'PCS', 150);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 8, 'PCS', 151);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '3_SP_RE', '', 10, 'PCS', 152);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 153);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 7, 'PCS', 154);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '5_ST_RA', '', 12, 'PCS', 155);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 151);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '1_FI_RE', '11', 28, 'PCS', 160);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '2_LI_RA', '21', 8, 'PCS', 161);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 100000, SalesLine.Type::Item, '3_SP_RE', '31', 10, 'PCS', 162);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 110000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 163);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 120000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 164);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 130000, SalesLine.Type::Item, '5_ST_RA', '51', 12, 'PCS', 165);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 140000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 161);

            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-2-70') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-3
        if PerformIteration('19-1-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-4
        if PerformIteration('19-1-4-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', 20011126D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011126D, 'BLUE', 'TCS-19-1-4', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 20);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 20);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '3_SP_RE', '', 5, 'PCS', 20);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 20);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 5, 'PCS', 22);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 22);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '3_SP_RE', '31', 5, 'PCS', 22);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 22);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '5_ST_RA', '51', 5, 'PCS', 110);

            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(39, 2, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011126D, 0D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-4-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-5
        if PerformIteration('19-1-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-6
        if PerformIteration('19-1-6-10') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-7
        if PerformIteration('19-1-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-8
        if PerformIteration('19-1-8-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011127D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010127D, 'BLUE', 'TCS-19-1-8', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'GPS', '', 12, '', 100);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 12, 12, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'UPS', '', 10, '', 80);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 10, 10, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'Insurance', '', 1, '', 295.78);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 1, 0, 0, 0);

            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            PurchLine.SetRange("Line No.", 10000);
            PurchLine.Find('-');
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107001', 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107001', 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, '107001', 30000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, '107001', 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, '107001', 50000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, '107001', 60000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 70000, "Purchase Applies-to Document Type"::Receipt, '107001', 70000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 70000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 80000, "Purchase Applies-to Document Type"::Receipt, '107001', 80000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 80000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 90000, "Purchase Applies-to Document Type"::Receipt, '107001', 90000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 90000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 100000, "Purchase Applies-to Document Type"::Receipt, '107001', 100000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 100000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 110000, "Purchase Applies-to Document Type"::Receipt, '107001', 110000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 110000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 120000, "Purchase Applies-to Document Type"::Receipt, '107001', 120000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 120000, 1);

            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            PurchLine.SetRange("Line No.", 20000);
            PurchLine.Find('-');
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107002', 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107002', 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, '107002', 30000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, '107002', 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, '107002', 50000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, '107002', 60000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 70000, "Purchase Applies-to Document Type"::Receipt, '107002', 70000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 70000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 80000, "Purchase Applies-to Document Type"::Receipt, '107002', 80000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 80000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 90000, "Purchase Applies-to Document Type"::Receipt, '107002', 90000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 90000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 100000, "Purchase Applies-to Document Type"::Receipt, '107002', 100000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 100000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-8-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-8-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-9
        if PerformIteration('19-1-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-10
        if PerformIteration('19-1-10-10') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', 20011202D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011202D, 'BLUE', true, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 150);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 10000, 1, 1, 150, 0, 93);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 20000, 1, 1, 151, 0, 94);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '3_SP_RE', '', 1, 'PCS', 152);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 153);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 40000, 2, 2, 153, 0, 105);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 154);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 50000, 1, 1, 154, 0, 106);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 155);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 60000, 1, 1, 155, 0, 107);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 70000, 1, 1, 151, 0, 108);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '1_FI_RE', '11', 1, 'PCS', 160);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 80000, 1, 1, 160, 0, 109);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 90000, 1, 1, 161, 0, 110);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 100000, SalesLine.Type::Item, '3_SP_RE', '31', 1, 'PCS', 162);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 110000, SalesLine.Type::Item, '4_AV_RE', '41', 2, 'PCS', 163);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 110000, 2, 2, 163, 0, 121);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 120000, SalesLine.Type::Item, '4_AV_RE', '41', 1, 'PCS', 164);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 120000, 1, 1, 164, 0, 122);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 130000, SalesLine.Type::Item, '5_ST_RA', '51', 1, 'PCS', 165);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 130000, 1, 1, 165, 0, 123);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 140000, SalesLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161);
            WMSTestscriptManagement.ModifySalesCrMemoLine(SalesHeader, 140000, 1, 1, 161, 0, 124);

            CreateReservEntryFor(37, 3, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.SetApplyFromEntryNo(95);
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011202D, 0D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(37, 3, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.SetApplyFromEntryNo(111);
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011202D, 0D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-10-20') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-11
        if PerformIteration('19-1-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-12
        if PerformIteration('19-1-12-10') then begin
            Commit();
            Clear(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SetFilter("Location Filter", 'BLUE');
            Item.SetFilter("Variant Filter", '<>%1', '');
            CalcInvValue.SetTableView(Item);
            CalcInvValue.SetParameters(20011128D, 'TCS-19-1-12', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
            CalcInvValue.UseRequestPage(false);
            CalcInvValue.RunModal();
            Clear(CalcInvValue);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-12-20') then begin
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 1000, true, 0);
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 1000, true, 0);
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 1000, true, 0);
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 40000, 1000, true, 0);
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 50000, 1000, true, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-12-30') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-12-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-12-50') then begin
            TestScriptMgmt.ItemJnlDelete(ItemJnlLine);

            ValueEntry.Reset();
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.SetTableView(ValueEntry);
            PostInvtCostToGL.InitializeRequest(0, 'TCS-19-1-12', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase19-1-12.pdf');
            Clear(PostInvtCostToGL);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 19-1-13
        if PerformIteration('19-1-13-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-1-14
        if PerformIteration('19-1-14-10') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', 20011205D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011205D, 'BLUE', true, true);

            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 150);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '3_SP_RE', '', 11, 'PCS', 152);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 14, 'PCS', 153);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 3, 'PCS', 155);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '1_FI_RE', '11', 2, 'PCS', 160);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '3_SP_RE', '31', 11, 'PCS', 162);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 14, 'PCS', 164);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '5_ST_RA', '51', 3, 'PCS', 165);

            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011205D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-14-20') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-14-30') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", '10000', 20011203D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20011203D, 'BLUE', 'TCS-19-1-14');

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 150);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '3_SP_RE', '', 1, 'PCS', 152);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 153);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 154);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 155);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '1_FI_RE', '11', 1, 'PCS', 160);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '3_SP_RE', '31', 1, 'PCS', 162);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 110000, PurchLine.Type::Item, '4_AV_RE', '41', 2, 'PCS', 163);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 120000, PurchLine.Type::Item, '4_AV_RE', '41', 1, 'PCS', 164);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 130000, PurchLine.Type::Item, '5_ST_RA', '51', 1, 'PCS', 165);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 140000, PurchLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161);

            CreateReservEntryFor(39, 3, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011203D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(39, 3, PurchHeader."No.", '', 0, 100000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011203D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-14-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-14-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-1-14-60') then begin
            Commit();
            Clear(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SetRange("Location Filter", 'RED');
            Item.SetRange("Variant Filter");
            CalcInvValue.SetTableView(Item);
            CalcInvValue.SetParameters(20011206D, 'TCS-19-1-14', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
            CalcInvValue.UseRequestPage(false);
            CalcInvValue.RunModal();
            Clear(CalcInvValue);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 19-1-15
        if PerformIteration('19-1-15-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 15, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        IterationActive := FirstIteration = '';
        // 19-2-1
        if PerformIteration('19-2-1-10') then
            TestScriptMgmt.SetGlobalPreconditions();
        if LastIteration = ActualIteration then
            exit;
        // 19-2-2
        if PerformIteration('19-2-2-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS19-2-2', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 2, 'PALLET', 200);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 3, 'PALLET', 120);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '3_SP_RE', '', 1, 'PALLET', 230);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 25);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '4_AV_RE', '', 3, 'PALLET', 155);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '5_ST_RA', '', 1, 'PALLET', 115);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '1_FI_RE', '11', 2, 'PALLET', 186.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '2_LI_RA', '21', 3, 'PALLET', 114.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '3_SP_RE', '31', 1, 'PALLET', 225.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 29.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 110000, PurchLine.Type::Item, '4_AV_RE', '41', 3, 'PALLET', 170.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 120000, PurchLine.Type::Item, '5_ST_RA', '51', 1, 'PALLET', 130);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);

            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);

            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 90000, 1, 1, 1, 'ST17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010125D, 0D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-2-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-2-30') then begin
            WMSTestscriptManagement.InsertTransferHeader(TransHeader, 'BLUE', 'RED', 'OWN LOG.', 20011129D);

            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 10000, '1_FI_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 20000, '2_LI_RA', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 30000, '3_SP_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 40000, '4_AV_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 50000, '4_AV_RE', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 60000, '5_ST_RA', '', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 70000, '1_FI_RE', '11', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 80000, '2_LI_RA', '21', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 90000, '3_SP_RE', '31', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 100000, '4_AV_RE', '41', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 110000, '4_AV_RE', '41', 'PCS', 1, 0, 1);
            WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 120000, '5_ST_RA', '51', 'PCS', 1, 0, 1);

            CreateReservEntryFor(5741, 0, TransHeader."No.", '', 0, 30000, 1, 1, 1, 'SN11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011129D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5741, 1, TransHeader."No.", '', 0, 30000, 1, 1, 1, 'SN11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'RED', '', 20011129D, 0D, 0, "Reservation Status"::Surplus);

            CreateReservEntryFor(5741, 0, TransHeader."No.", '', 0, 90000, 1, 1, 1, 'ST11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011129D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(5741, 1, TransHeader."No.", '', 0, 90000, 1, 1, 1, 'ST11', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'RED', '', 20011129D, 0D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-2-40') then
            WMSTestscriptManagement.PostTransferOrder(TransHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-2-50') then
            WMSTestscriptManagement.PostTransferOrderRcpt(TransHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-2-60') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011130D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011130D, 'BLUE', true, true);

            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 28, 'PCS', 150);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 28, 28, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 8, 'PCS', 151);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '3_SP_RE', '', 10, 'PCS', 152);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '', 3, 'PCS', 153);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 7, 'PCS', 154);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 7, 7, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '5_ST_RA', '', 12, 'PCS', 155);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 151);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '1_FI_RE', '11', 28, 'PCS', 160);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 28, 28, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '2_LI_RA', '21', 8, 'PCS', 161);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 8, 8, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 100000, SalesLine.Type::Item, '3_SP_RE', '31', 10, 'PCS', 162);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 110000, SalesLine.Type::Item, '4_AV_RE', '41', 3, 'PCS', 163);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 3, 3, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 120000, SalesLine.Type::Item, '4_AV_RE', '41', 7, 'PCS', 164);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 7, 7, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 130000, SalesLine.Type::Item, '5_ST_RA', '51', 12, 'PCS', 165);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 12, 12, 0, 0, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 140000, SalesLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 161);
            TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 0, 0, true);

            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);

            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST02', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST03', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST04', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST05', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST06', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST07', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST08', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST09', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(37, 1, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST10', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 0D, 20011130D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-2-70') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-3
        if PerformIteration('19-2-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-4
        if PerformIteration('19-2-4-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011126D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011126D, 'BLUE', 'TCS19-2-4', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 20);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 20);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '3_SP_RE', '', 5, 'PCS', 20);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 20);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '1_FI_RE', '11', 5, 'PCS', 22);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '2_LI_RA', '21', 5, 'PCS', 22);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '3_SP_RE', '31', 5, 'PCS', 22);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 5, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '4_AV_RE', '41', 5, 'PCS', 22);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '5_ST_RA', '51', 5, 'PCS', 110);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);

            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);

            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
            CreateReservEntryFor(39, 1, PurchHeader."No.", '', 0, 80000, 1, 1, 1, 'ST22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20010126D, 0D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-4-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-5
        if PerformIteration('19-2-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-6
        if PerformIteration('19-2-6-10') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-7
        if PerformIteration('19-2-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-8
        if PerformIteration('19-2-8-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011127D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011127D, 'BLUE', 'TCS19-2-8', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::"Charge (Item)", 'GPS', '', 12, '', 100);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 12, 12, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::"Charge (Item)", 'UPS', '', 10, '', 80);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 10, 10, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'Insurance', '', 1, '', 295.78);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 1, 0, 0, 0);

            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            PurchLine.SetRange("Line No.", 10000);
            PurchLine.Find('-');
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107001', 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107001', 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, '107001', 30000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, '107001', 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, '107001', 50000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, '107001', 60000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 70000, "Purchase Applies-to Document Type"::Receipt, '107001', 70000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 70000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 80000, "Purchase Applies-to Document Type"::Receipt, '107001', 80000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 80000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 90000, "Purchase Applies-to Document Type"::Receipt, '107001', 90000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 90000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 100000, "Purchase Applies-to Document Type"::Receipt, '107001', 100000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 100000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 110000, "Purchase Applies-to Document Type"::Receipt, '107001', 110000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 110000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 120000, "Purchase Applies-to Document Type"::Receipt, '107001', 120000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 120000, 1);

            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            PurchLine.SetRange("Line No.", 20000);
            PurchLine.Find('-');
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 10000, "Purchase Applies-to Document Type"::Receipt, '107002', 10000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 10000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, "Purchase Applies-to Document Type"::Receipt, '107002', 20000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 20000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 30000, "Purchase Applies-to Document Type"::Receipt, '107002', 30000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 30000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 40000, "Purchase Applies-to Document Type"::Receipt, '107002', 40000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 40000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 50000, "Purchase Applies-to Document Type"::Receipt, '107002', 50000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 50000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 60000, "Purchase Applies-to Document Type"::Receipt, '107002', 60000, '1_FI_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 60000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 70000, "Purchase Applies-to Document Type"::Receipt, '107002', 70000, '2_LI_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 70000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 80000, "Purchase Applies-to Document Type"::Receipt, '107002', 80000, '3_SP_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 80000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 90000, "Purchase Applies-to Document Type"::Receipt, '107002', 90000, '4_AV_RE');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 90000, 1);
            TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 100000, "Purchase Applies-to Document Type"::Receipt, '107002', 100000, '5_ST_RA');
            TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, PurchLine."Line No.", 100000, 1);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-8-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-8-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-9
        if PerformIteration('19-2-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-10
        if PerformIteration('19-2-10-10') then begin
            PurchHeader.Find('-');
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011201D, '', 'TCS19-2-2', true);

            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 0, 200, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 0, 120, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 0, 230, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 4, 0, 50, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 1, 0, 310, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 0, 115, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 0, 186.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 0, 114.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 90000, 0, 0, 225.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 100000, 4, 0, 59, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 110000, 1, 0, 341, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 120000, 0, 0, 130, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-10-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-10-30') then begin
            PurchHeader.SetRange("Vendor Invoice No.", 'TCS19-2-4');
            PurchHeader.Find('+');
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011202D, '', 'TCS19-2-4', true);

            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 3, 0, 40, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 0, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 0, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 4, 0, 40, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 4, 0, 200, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 3, 0, 44, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 0, 22, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 0, 22, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 90000, 4, 0, 44, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 100000, 4, 0, 220, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-10-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-10-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-11
        if PerformIteration('19-2-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-12
        if PerformIteration('19-2-12-10') then begin
            PurchHeader.Reset();
            PurchHeader.Find('-');
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011203D, '', 'TCS19-2-2', true);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 2, 130, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 3, 90, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 1, 187, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 5, 19, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 3, 135, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 1, 100, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 2, 136.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 3, 94.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 90000, 0, 1, 195.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 100000, 0, 5, 19.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 110000, 0, 3, 143.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 120000, 0, 1, 110, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-12-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-12-30') then begin
            PurchHeader.SetRange("Vendor Invoice No.", 'TCS19-2-4');
            PurchHeader.Find('+');
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011204D, '', 'TCS19-2-4', true);

            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 5, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 5, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 5, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 5, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 5, 100, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 5, 22, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 5, 22, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 5, 22, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 90000, 0, 5, 22, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 100000, 0, 5, 110, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-12-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-12-50') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-13
        if PerformIteration('19-2-13-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-14
        if PerformIteration('19-2-14-10') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', 20011202D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011202D, 'BLUE', true, true);

            TestScriptMgmt.ClearDimensions();
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 150);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 10000, 1, 0, 150, 0, 93);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 20000, 1, 0, 151, 0, 94);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '3_SP_RE', '', 1, 'PCS', 152);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 30000, 1, 0, 152, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 153);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 40000, 2, 0, 153, 0, 105);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 154);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 50000, 1, 0, 154, 0, 106);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 155);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 60000, 1, 0, 155, 0, 107);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 70000, 1, 0, 151, 0, 108);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '1_FI_RE', '11', 1, 'PCS', 160);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 80000, 1, 0, 160, 0, 109);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 90000, SalesLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 90000, 1, 0, 161, 0, 110);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 100000, SalesLine.Type::Item, '3_SP_RE', '31', 1, 'PCS', 162);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 100000, 1, 0, 162, 0, 0);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 110000, SalesLine.Type::Item, '4_AV_RE', '41', 2, 'PCS', 163);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 110000, 2, 0, 163, 0, 121);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 120000, SalesLine.Type::Item, '4_AV_RE', '41', 1, 'PCS', 164);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 120000, 1, 0, 164, 0, 122);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 130000, SalesLine.Type::Item, '5_ST_RA', '51', 1, 'PCS', 165);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 130000, 1, 0, 165, 0, 123);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 140000, SalesLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161);
            TestScriptMgmt.ModifySalesReturnLine(SalesHeader, 140000, 1, 0, 161, 0, 124);

            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.SetApplyFromEntryNo(95);
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011202D, 0D, 0, "Reservation Status"::Surplus);

            CreateReservEntryFor(37, 5, SalesHeader."No.", '', 0, 100000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.SetApplyFromEntryNo(111);
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011202D, 0D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-14-20') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-15
        if PerformIteration('19-2-15-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 15, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-16
        if PerformIteration('19-2-16-10') then begin
            TestScriptMgmt.AdjustItem('', '', false);

            Commit();
            Clear(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SetFilter("Location Filter", 'BLUE');
            Item.SetFilter("Variant Filter", '<>%1', '');
            CalcInvValue.SetTableView(Item);
            CalcInvValue.SetParameters(20011205D, 'TCS-19-2-16', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
            CalcInvValue.UseRequestPage(false);
            CalcInvValue.RunModal();
            Clear(CalcInvValue);
        end;
        if LastIteration = ActualIteration then
            exit;
        if PerformIteration('19-2-16-20') then begin
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 1000, true, 0);
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 1000, true, 0);
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 1000, true, 0);
            TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 40000, 1000, true, 0);
        end;
        if LastIteration = ActualIteration then
            exit;
        if PerformIteration('19-2-16-30') then
            TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        if LastIteration = ActualIteration then
            exit;
        if PerformIteration('19-2-16-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-16-50') then begin
            TestScriptMgmt.ItemJnlDelete(ItemJnlLine);
            ValueEntry.Reset();
            Clear(PostInvtCostToGL);
            PostInvtCostToGL.SetTableView(ValueEntry);
            PostInvtCostToGL.InitializeRequest(0, 'TCS-19-2-17', true);
            PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase19-2-17.pdf');
            Clear(PostInvtCostToGL);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-16-60') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '10000', 20011206D);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20011206D, 'BLUE', 'TCS-19-2-16');

            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 150, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '3_SP_RE', '', 1, 'PCS', 152, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 2, 'PCS', 153, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 2, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 154, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 155, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 151, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '1_FI_RE', '11', 1, 'PCS', 160, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 90000, PurchLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 100000, PurchLine.Type::Item, '3_SP_RE', '31', 1, 'PCS', 162, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 110000, PurchLine.Type::Item, '4_AV_RE', '41', 2, 'PCS', 163, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 2, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 120000, PurchLine.Type::Item, '4_AV_RE', '41', 1, 'PCS', 164, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 130000, PurchLine.Type::Item, '5_ST_RA', '51', 1, 'PCS', 165, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);
            TestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 140000, PurchLine.Type::Item, '2_LI_RA', '21', 1, 'PCS', 161, 0);
            TestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 0);

            CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 30000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Surplus);

            CreateReservEntryFor(39, 5, PurchHeader."No.", '', 0, 100000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Surplus);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-16-70') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-17
        if PerformIteration('19-2-17-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 17, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-2-18
        if PerformIteration('19-2-18-10') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', 20011206D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011206D, 'BLUE', true, true);

            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 2, 'PCS', 150);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '3_SP_RE', '', 11, 'PCS', 152);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '4_AV_RE', '', 14, 'PCS', 153);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 3, 'PCS', 155);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '1_FI_RE', '11', 2, 'PCS', 160);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 60000, SalesLine.Type::Item, '3_SP_RE', '31', 11, 'PCS', 162);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 70000, SalesLine.Type::Item, '4_AV_RE', '41', 14, 'PCS', 164);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 80000, SalesLine.Type::Item, '5_ST_RA', '51', 3, 'PCS', 165);

            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'SN22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST12', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST13', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST14', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST15', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST16', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST17', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST18', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST19', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST20', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST21', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 60000, 1, 1, 1, 'ST22', '');
            CreateReservEntry.CreateEntry('3_SP_RE', '31', 'BLUE', '', 20011206D, 0D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-18-20') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-18-30') then begin
            ReleasePurchDoc.Reopen(PurchHeader);
            TestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, 20011207D, 'BLUE', 'TCS-19-2-18');

            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 2, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 90000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 100000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 110000, 0, 2, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 120000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 130000, 0, 1, 0, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 140000, 0, 1, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-18-40') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-18-50') then begin
            Clear(SalesHeader);
            SalesHeader.Find('-');
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011208D, 'BLUE', true, true);

            TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 20000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 30000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 40000, 0, 2, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 50000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 60000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 70000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 80000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 90000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 100000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 110000, 0, 2, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 120000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 130000, 0, 1, 0, 0, true);
            TestScriptMgmt.ModifySalesLine(SalesHeader, 140000, 0, 1, 0, 0, true);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-18-60') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-18-70') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-2-18-80') then begin
            Commit();
            Clear(ItemJnlLine);
            ItemJnlLine."Journal Template Name" := 'REVAL';
            ItemJnlLine."Journal Batch Name" := 'DEFAULT';
            CalcInvValue.SetItemJnlLine(ItemJnlLine);
            Item.Reset();
            Item.SetRange("Location Filter", 'RED');
            Item.SetRange("Variant Filter");
            CalcInvValue.SetTableView(Item);
            CalcInvValue.SetParameters(20011209D, 'TCS-19-2-18', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
            CalcInvValue.UseRequestPage(false);
            CalcInvValue.RunModal();
            Clear(CalcInvValue);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 19-2-19
        if PerformIteration('19-2-19-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 19, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        IterationActive := FirstIteration = '';
        // 19-3-1
        if PerformIteration('19-3-1-10') then begin
            TestScriptMgmt.SetGlobalPreconditions();
            // this is code added later to change the item no. so that sorting is same in the reference data for both native as well as SQL.
            // this test shall use an item called A4_AV_RE instead of 4_AV_RE.
            TestScriptMgmt.RenameItem('4_AV_RE', 'A4_AV_RE');
            // this test shall use an item called D3_SP_RE instead of 3_SP_RE.
            TestScriptMgmt.RenameItem('3_SP_RE', 'D3_SP_RE');
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-1-10') then begin
            TestScriptMgmt.SetAutoCostPost(true);
            TestScriptMgmt.SetExpCostPost(true);
            TestScriptMgmt.SetAddRepCurr('DEM');
            GetLastILENo();
            GetLastCLENo();
            GetLastGLENo();

            ProdBOMHeader.Reset();
            ProdBOMHeader.SetRange("No.", 'A');
            ProdBOMHeader.FindFirst();
            TempProdBOMHeader := ProdBOMHeader;
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify();

            ProdBOMLine.Reset();
            ProdBOMLine.SetRange("Production BOM No.", 'A');
            ProdBOMLine.SetRange("No.", 'B');
            if ProdBOMLine.FindFirst() then begin
                ProdBOMLine.Validate("No.", '1_FI_RE');
                ProdBOMLine.Validate("Quantity per", 1.5);
                ProdBOMLine.Modify();
            end;
            ProdBOMLine.SetRange("No.", 'C');
            if ProdBOMLine.FindFirst() then begin
                ProdBOMLine.Validate("No.", '2_LI_RA');
                ProdBOMLine.Validate("Quantity per", 2);
                ProdBOMLine.Modify();
            end;
            ProdBOMHeader.Status := TempProdBOMHeader.Status;
            ProdBOMHeader.Modify();

            ProdBOMHeader.Reset();
            ProdBOMHeader.SetRange("No.", 'B');
            ProdBOMHeader.FindFirst();
            TempProdBOMHeader := ProdBOMHeader;
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify();

            ProdBOMLine.Reset();
            ProdBOMLine.SetRange("Production BOM No.", 'B');
            ProdBOMLine.SetRange("No.", 'C');
            if ProdBOMLine.FindFirst() then begin
                ProdBOMLine.Validate("No.", '5_ST_RA');
                ProdBOMLine.Validate("Quantity per", 1.5);
                ProdBOMLine.Modify();
            end;

            ProdBOMLine.Reset();
            ProdBOMLine.Init();
            ProdBOMLine.Validate("Production BOM No.", 'B');
            ProdBOMLine.Validate("Line No.", 20000);
            ProdBOMLine.Validate(Type, ProdBOMLine.Type::Item);
            ProdBOMLine.Validate("No.", 'A4_AV_RE');
            ProdBOMLine.Validate("Quantity per", 3);
            ProdBOMLine.Insert();

            ProdBOMHeader.Status := TempProdBOMHeader.Status;
            ProdBOMHeader.Modify();

            ProdBOMHeader.Init();
            ProdBOMHeader.Validate("No.", 'D3_SP_RE');
            ProdBOMHeader.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.Validate("Production BOM No.", 'D3_SP_RE');
            ProdBOMLine.Validate("Line No.", 10000);
            ProdBOMLine.Validate(Type, ProdBOMLine.Type::Item);
            ProdBOMLine.Validate("No.", 'A');
            ProdBOMLine.Validate("Quantity per", 2);
            ProdBOMLine.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.Validate("Production BOM No.", 'D3_SP_RE');
            ProdBOMLine.Validate("Line No.", 20000);
            ProdBOMLine.Validate(Type, ProdBOMLine.Type::Item);
            ProdBOMLine.Validate("No.", 'B');
            ProdBOMLine.Validate("Quantity per", 2);
            ProdBOMLine.Insert();

            ProdBOMHeader.Validate("Unit of Measure Code", 'PCS');
            ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
            ProdBOMHeader.Modify();
            Item.Get('D3_SP_RE');
            Item.Validate("Production BOM No.", 'D3_SP_RE');
            Item.Modify();

            ProdBOMHeader.Init();
            ProdBOMHeader.Validate("No.", 'C');
            ProdBOMHeader.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.Validate("Production BOM No.", 'C');
            ProdBOMLine.Validate("Line No.", 10000);
            ProdBOMLine.Validate(Type, ProdBOMLine.Type::Item);
            ProdBOMLine.Validate("No.", '1_FI_RE');
            ProdBOMLine.Validate("Quantity per", 1.5);
            ProdBOMLine.Validate("Variant Code", '11');
            ProdBOMLine.Insert();

            ProdBOMLine.Init();
            ProdBOMLine.Validate("Production BOM No.", 'C');
            ProdBOMLine.Validate("Line No.", 20000);
            ProdBOMLine.Validate(Type, ProdBOMLine.Type::Item);
            ProdBOMLine.Validate("No.", '2_LI_RA');
            ProdBOMLine.Validate("Quantity per", 2);
            ProdBOMLine.Validate("Variant Code", '21');
            ProdBOMLine.Insert();

            ProdBOMHeader.Validate("Unit of Measure Code", 'PCS');
            ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
            ProdBOMHeader.Modify();
            Item.Get('C');
            Item.Validate("Production BOM No.", 'C');
            Item.Modify();

            ProdBOMHeader.Reset();
            ProdBOMHeader.SetRange("No.", 'D');
            ProdBOMHeader.FindFirst();
            TempProdBOMHeader := ProdBOMHeader;
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify();

            ProdBOMLine.Reset();
            ProdBOMLine.SetRange("Production BOM No.", 'D');
            ProdBOMLine.SetRange("No.", 'B');
            if ProdBOMLine.FindFirst() then begin
                ProdBOMLine.Validate("No.", '5_ST_RA');
                ProdBOMLine.Validate("Quantity per", 1.5);
                ProdBOMLine.Validate("Variant Code", '51');
                ProdBOMLine.Modify();
            end;
            ProdBOMLine.Reset();
            ProdBOMLine.SetRange("Production BOM No.", 'D');
            ProdBOMLine.SetRange("No.", 'A4_AV_RE');
            if ProdBOMLine.FindFirst() then begin
                ProdBOMLine.Validate("Quantity per", 3);
                ProdBOMLine.Validate("Variant Code", '41');
                ProdBOMLine.Modify();
            end;
            ProdBOMHeader.Status := TempProdBOMHeader.Status;
            ProdBOMHeader.Modify();
        end;
        if LastIteration = ActualIteration then
            exit;
        // 19-3-2
        if PerformIteration('19-3-2-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS19-3-2', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 2, 'PALLET', 200);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 3, 'PALLET', 120);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A4_AV_RE', '', 3, 'PALLET', 155);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 1, 'PALLET', 115);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '1_FI_RE', '11', 2, 'PALLET', 186.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '2_LI_RA', '21', 3, 'PALLET', 114.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, 'A4_AV_RE', '41', 3, 'PALLET', 170.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '5_ST_RA', '51', 1, 'PALLET', 130);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-30') then begin
            WorkDate := 20011205D;
            Clear(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'D3_SP_RE', 1, 'BLUE');
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::Update;
            REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
            ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-40') then begin
            WorkDate := 20011206D;
            Clear(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'D3_SP_RE', 1, 'BLUE');
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::Update;
            REPORT.Run(REPORT::"Refresh Production Order", false, false, ProdOrder);
            ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-50') then begin
            ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrder."No.", 10000);
            ProdOrderLine.Validate("Variant Code", '31');
            ProdOrderLine.Modify();

            ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
            ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderComponent.SetRange("Prod. Order Line No.", 10000);
            ProdOrderComponent.SetRange("Item No.", 'A');
            ProdOrderComponent.FindFirst();
            ProdOrderComponent.Validate("Item No.", 'C');
            ProdOrderComponent.Modify();

            ProdOrderComponent.SetRange("Item No.", 'B');
            ProdOrderComponent.FindFirst();
            ProdOrderComponent.Validate("Item No.", 'D');
            ProdOrderComponent.Modify();
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-60') then begin
            WorkDate := 20011204D;
            Clear(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'A', 2, 'BLUE');

            ProdOrder.Reset();
            Clear(RefreshProductionOrder);
            ProdOrder.SetRange("No.", '101003');
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SetTableView(ProdOrder);
            RefreshProductionOrder.UseRequestPage(false);
            RefreshProductionOrder.RunModal();
            ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-70') then begin
            WorkDate := 20011204D;
            Clear(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'B', 2, 'BLUE');

            ProdOrder.Reset();
            Clear(RefreshProductionOrder);
            ProdOrder.SetRange("No.", '101004');
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SetTableView(ProdOrder);
            RefreshProductionOrder.UseRequestPage(false);
            RefreshProductionOrder.RunModal();
            ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-80') then begin
            WorkDate := 20011204D;
            Clear(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'C', 2, 'BLUE');
            ProdOrder.Reset();
            Clear(RefreshProductionOrder);
            ProdOrder.SetRange("No.", '101005');
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SetTableView(ProdOrder);
            RefreshProductionOrder.UseRequestPage(false);
            RefreshProductionOrder.RunModal();
            ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-90') then begin
            WorkDate := 20011205D;
            Clear(ProdOrder);
            WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'D', 2, 'BLUE');
            ProdOrder.Reset();
            Clear(RefreshProductionOrder);
            ProdOrder.SetRange("No.", '101006');
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::Update;
            RefreshProductionOrder.SetTableView(ProdOrder);
            RefreshProductionOrder.UseRequestPage(false);
            RefreshProductionOrder.RunModal();
            ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
            Commit();
            CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-2-100') then begin
            WorkDate := 20010125D;
            ProdOrder.Reset();
            ProdOrder.SetRange("Location Code", 'BLUE');
            ProdOrder.SetFilter("Source No.", '%1|%2|%3|%4', 'A', 'B', 'C', 'D');
            CalcConsumption.InitializeRequest(20011126D, 1);
            CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
            CalcConsumption.SetTableView(ProdOrder);
            CalcConsumption.UseRequestPage(false);
            CalcConsumption.RunModal();

            ConsumpItemJnlLine.Reset();
            ConsumpItemJnlLine.SetRange("Journal Template Name", 'CONSUMP');
            ConsumpItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
            ConsumpItemJnlLine.FindFirst();
            TestScriptMgmt.ItemJnlPostBatch(ConsumpItemJnlLine);
        end;
        if LastIteration = ActualIteration then
            exit;
        // 19-3-3
        if PerformIteration('19-3-3-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-4
        if PerformIteration('19-3-4-10') then begin
            Clear(PurchHeader);
            TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011129D);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011129D, 'BLUE', 'TCS19-3-4', true);

            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 1, 'PALLET', 250);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '2_LI_RA', '', 3, 'PALLET', 153);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, 'A4_AV_RE', '', 4, 'PALLET', 300);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 1, 'PALLET', 125);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '1_FI_RE', '11', 2, 'PALLET', 146.5);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 2, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 60000, PurchLine.Type::Item, '2_LI_RA', '21', 3, 'PALLET', 90);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 3, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 70000, PurchLine.Type::Item, 'A4_AV_RE', '41', 4, 'PALLET', 300);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 4, 0, 0, 0);
            TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 80000, PurchLine.Type::Item, '5_ST_RA', '51', 1, 'PALLET', 150);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 1, 0, 0, 0);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-4-20') then
            TestScriptMgmt.PostPurchOrder(PurchHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-4-30') then begin
            ItemJnlLine.Reset();
            ProdOrder.Reset();
            ProdOrder.Find('-');
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011128D,
              ItemJnlLine."Entry Type"::Output, '101003', 'A', '', 'BLUE', '',
              2, 'PCS', 0, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", '101003');
            ItemJnlLine.Validate("Order Line No.", 10000);
            ItemJnlLine.Validate("Source No.", 'A');
            ItemJnlLine.Validate("Output Quantity", 2);
            ItemJnlLine.Modify();

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 20000, 20011128D,
              ItemJnlLine."Entry Type"::Output, '101004', 'B', '', 'BLUE', '',
              2, 'PCS', 0, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", '101004');
            ItemJnlLine.Validate("Order Line No.", 10000);
            ItemJnlLine.Validate("Source No.", 'B');
            ItemJnlLine.Validate("Output Quantity", 2);
            ItemJnlLine.Modify();

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 30000, 20011128D,
              ItemJnlLine."Entry Type"::Output, '101005', 'C', '', 'BLUE', '',
              2, 'PCS', 0, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", '101005');
            ItemJnlLine.Validate("Order Line No.", 10000);
            ItemJnlLine.Validate("Source No.", 'C');
            ItemJnlLine.Validate("Output Quantity", 2);
            ItemJnlLine.Modify();

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 40000, 20011128D,
              ItemJnlLine."Entry Type"::Output, '101006', 'D', '', 'BLUE', '',
              2, 'PCS', 0, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", '101006');
            ItemJnlLine.Validate("Order Line No.", 10000);
            ItemJnlLine.Validate("Source No.", 'D');
            ItemJnlLine.Validate("Output Quantity", 2);
            ItemJnlLine.Modify();

            OutputItemJnlLine.Reset();
            OutputItemJnlLine.SetRange("Journal Template Name", 'OUTPUT');
            OutputItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
            OutputItemJnlLine.FindFirst();
            TestScriptMgmt.ItemJnlPostBatch(OutputItemJnlLine);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-4-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-5
        if PerformIteration('19-3-5-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-6
        if PerformIteration('19-3-6-10') then begin
            Clear(CalcConsumption);
            ProdOrder.Reset();
            ProdOrder.SetRange("Location Code", 'BLUE');
            ProdOrder.SetFilter("Source No.", '%1', 'D3_SP_RE');
            CalcConsumption.InitializeRequest(20011205D, 1);
            CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
            CalcConsumption.SetTableView(ProdOrder);
            CalcConsumption.UseRequestPage(false);
            CalcConsumption.RunModal();

            ConsumpItemJnlLine.Reset();
            ConsumpItemJnlLine.SetRange("Journal Template Name", 'CONSUMP');
            ConsumpItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
            ConsumpItemJnlLine.FindFirst();
            TestScriptMgmt.ItemJnlPostBatch(ConsumpItemJnlLine);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-6-20') then begin
            ItemJnlLine.Reset();
            ProdOrder.Reset();
            ProdOrder.Find('-');
            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011205D,
              ItemJnlLine."Entry Type"::Output, '101001', 'D3_SP_RE', '', 'BLUE', '',
              2, 'PCS', 0, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", '101001');
            ItemJnlLine.Validate("Order Line No.", 10000);
            ItemJnlLine.Validate("Source No.", 'D3_SP_RE');
            ItemJnlLine.Validate("Output Quantity", 1);
            ItemJnlLine.Modify();

            TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 20000, 20011205D,
              ItemJnlLine."Entry Type"::Output, '101002', 'D3_SP_RE', '', 'BLUE', '',
              1, 'PCS', 0, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", '101002');
            ItemJnlLine.Validate("Order Line No.", 10000);
            ItemJnlLine.Validate("Source No.", 'D3_SP_RE');
            ItemJnlLine.Validate("Variant Code", '31');
            ItemJnlLine.Validate("Output Quantity", 1);
            ItemJnlLine.Modify();

            CreateReservEntryFor(83, 6, 'OUTPUT', 'DEFAULT', 0, 10000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('D3_SP_RE', '', 'BLUE', '', 20011205D, 0D, 0, "Reservation Status"::Prospect);
            CreateReservEntryFor(83, 6, 'OUTPUT', 'DEFAULT', 0, 20000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('D3_SP_RE', '31', 'BLUE', '', 20011205D, 0D, 0, "Reservation Status"::Prospect);

            OutputItemJnlLine.Reset();
            OutputItemJnlLine.SetRange("Journal Template Name", 'output');
            OutputItemJnlLine.SetRange("Journal Batch Name", 'default');
            OutputItemJnlLine.FindFirst();
            TestScriptMgmt.ItemJnlPostBatch(OutputItemJnlLine);

            ProdOrder.Reset();
            ProdOrder.SetFilter(Status, '<>%1', ProdOrder.Status::Finished);
            ProdOrder.Find('-');
            repeat
                FinishProdOrder(ProdOrder, 20011205D, false);
            until ProdOrder.Next() = 0;
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-6-30') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-7
        if PerformIteration('19-3-7-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-8
        if PerformIteration('19-3-8-10') then begin
            Clear(SalesHeader);
            TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', 20011206D);
            TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011206D, 'BLUE', true, true);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'D3_SP_RE', '', 1, 'PCS', 150);
            TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, 'D3_SP_RE', '31', 1, 'PCS', 152);
            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 10000, 1, 1, 1, 'SN01', '');
            CreateReservEntry.CreateEntry('D3_SP_RE', '', 'BLUE', '', 0D, 20011206D, 0, "Reservation Status"::Prospect);

            CreateReservEntryFor(37, 2, SalesHeader."No.", '', 0, 20000, 1, 1, 1, 'ST01', '');
            CreateReservEntry.CreateEntry('D3_SP_RE', '31', 'BLUE', '', 0D, 20011206D, 0, "Reservation Status"::Prospect);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-8-20') then
            TestScriptMgmt.PostSalesOrder(SalesHeader);
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-8-30') then begin
            PurchHeader.Find('-');
            ReleasePurchDoc.Reopen(PurchHeader);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011207D, 'BLUE', 'TCS19-3-2', false);

            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 2, 234, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 3, 33, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 3, 20, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 1, 105, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 2, 240.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 3, 34.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 3, 35, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 1, 120, 0);

            TestScriptMgmt.PostPurchOrder(PurchHeader);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-8-40') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-9
        if PerformIteration('19-3-9-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-10
        if PerformIteration('19-3-10-10') then begin
            PurchHeader.Find('-');
            ReleasePurchDoc.Reopen(PurchHeader);
            TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011208D, 'BLUE', 'TCS19-3-4', false);

            TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 0, 1, 247, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 0, 3, 45, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 0, 4, 30, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 0, 1, 115, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 0, 2, 260.5, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 0, 3, 48, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 70000, 0, 4, 45, 0);
            TestScriptMgmt.ModifyPurchLine(PurchHeader, 80000, 0, 1, 140, 0);

            TestScriptMgmt.PostPurchOrder(PurchHeader);
        end;
        if LastIteration = ActualIteration then
            exit;

        if PerformIteration('19-3-10-20') then
            TestScriptMgmt.AdjustItem('', '', false);
        if LastIteration = ActualIteration then
            exit;
        // 19-3-11
        if PerformIteration('19-3-11-10') then
            TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);
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

    [Scope('OnPrem')]
    procedure FinishProdOrder(ProdOrder: Record "Production Order"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    var
        ToProdOrder: Record "Production Order";
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, NewPostingDate, NewUpdateUnitCost);
        WhseProdRelease.FinishedDelete(ToProdOrder);
    end;

    local procedure CreateReservEntryFor(ForType: Option; ForSubtype: Integer; ForID: Code[20]; ForBatchName: Code[10]; ForProdOrderLine: Integer; ForRefNo: Integer; ForQtyPerUOM: Decimal; Quantity: Decimal; QuantityBase: Decimal; ForSerialNo: Code[50]; ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := ForSerialNo;
        ForReservEntry."Lot No." := ForLotNo;
        CreateReservEntry.CreateReservEntryFor(
            ForType, ForSubtype, ForID, ForBatchName, ForProdOrderLine, ForRefNo, ForQtyPerUOM, Quantity, QuantityBase, ForReservEntry);
    end;
}

