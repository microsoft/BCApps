codeunit 103408 "Test Use Case 7"
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
        DefDim: Record "Default Dimension";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdBOMLine: Record "Production BOM Line";
        Item: Record Item;
        TempItem: Record Item temporary;
        ValueEntry: Record "Value Entry";
        ProdOrderB1: Record "Production Order";
        ProdOrderA1: Record "Production Order";
        ProdOrderD1: Record "Production Order";
        Location: Record Location;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ItemCostMgt: Codeunit ItemCostManagement;
        OutpExplRtng: Codeunit "Output Jnl.-Expl. Route";
        SelectionForm: Page "Test Selection";
        CalcConsumption: Report "Calc. Consumption";
        CalcInvValue: Report "Calculate Inventory Value";
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        TestScriptMgmt: Codeunit _TestscriptManagement;
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
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
        ItemJnlLineNo: Integer;
        TestResultsPath: Text[250];
        FirstIteration: Text[30];
        LastIteration: Text[30];
        NoOfRecords: array[20] of Integer;
        NoOfFields: array[20] of Integer;
        SaveWorkDate: Date;

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
            5:
                PerformTestCase5();
            6:
                PerformTestCase6();
            7:
                PerformTestCase7();
            8:
                PerformTestCase8();
            9, 10, 11, 12, 13, 14, 15, 17:
                begin
                    SaveWorkDate := WorkDate();
                    case TestCaseNo of
                        9:
                            PerformTestCase9();
                        10:
                            PerformTestCase10();
                        11:
                            PerformTestCase11();
                        12:
                            PerformTestCase12();
                        13:
                            PerformTestCase13();
                        14:
                            PerformTestCase14();
                        15:
                            PerformTestCase15();
                        17:
                            PerformTestCase17();
                    end;
                    WorkDate(SaveWorkDate);
                end;
            18:
                PerformTestCase18();
            19:
                PerformTestCase19();
            20:
                PerformTestCase20();
            21:
                PerformTestCase21();
            22:
                PerformTestCase22();
            23:
                PerformTestCase23();
            24:
                PerformTestCase24();
            //Bug 37027
            //25: PerformTestCase25;
            26:
                PerformTestCase26();
        end;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase1()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-1-1-10' then exit;
        // 7-1-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010201D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '1_FI_RE', '', 'BLUE', '', 111, 'PCS', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010201D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '2_LI_RA', '', 'BLUE', '', 222, 'PCS', 20, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010201D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '4_AV_RE', '', 'BLUE', '', 333, 'PCS', 40, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010201D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '1_FI_RE', '', 'RED', '', 3, 'PALLET', 130, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010201D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '2_LI_RA', '', 'RED', '', 3, 'PALLET', 60, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010201D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '4_AV_RE', '', 'RED', '', 3, 'PALLET', 200, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010202D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '1_FI_RE', '', 'BLUE', '', 89, 'PCS', 11, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010202D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '2_LI_RA', '', 'BLUE', '', 78, 'PCS', 21, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010202D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '4_AV_RE', '', 'BLUE', '', 67, 'PCS', 41, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010203D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-1-2', '1_FI_RE', '', 'BLUE', '', 1, 'PALLET', 260, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010203D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-1-2', '2_LI_RA', '', 'BLUE', '', 1, 'PALLET', 90, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010203D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-1-2', '4_AV_RE', '', 'BLUE', '', 1, 'PALLET', 250, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010204D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '1_FI_RE', '', 'BLUE', '', 2, 'PCS', 12, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010204D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '2_LI_RA', '', 'BLUE', '', 2, 'PCS', 22, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010204D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-1-2', '4_AV_RE', '', 'BLUE', '', 2, 'PCS', 42, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010210D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-1-2', '1_FI_RE', '', 'BLUE', '', 1, 'PALLET', 260, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010210D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-1-2', '2_LI_RA', '', 'BLUE', '', 1, 'PALLET', 90, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010210D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-1-2', '4_AV_RE', '', 'BLUE', '', 1, 'PALLET', 250, 0);

        if LastIteration = '7-1-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-1-2-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-1-2-30' then exit;
        // 7-1-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-1-3-10' then exit;
        // 7-1-4
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("Location Filter", 'BLUE');
        Item.SetRange("Variant Filter", '');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010204D, 'TCS7-1-4', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-1-4-10' then exit;
        // 7-1-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-1-5-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 2362.5, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 6727.5, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 16872.5, true, 0);

        if LastIteration = '7-1-6-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-1-6-20' then exit;
        // 7-1-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-1-7-10' then exit;
        // 7-1-8
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-1-8-10' then exit;

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("Location Filter", 'BLUE');
        Item.SetRange("Variant Filter", '');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010204D, 'TCS7-1-8', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-1-8-20' then exit;
        // 7-1-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-1-9-10' then exit;
        // 7-1-10
        TestScriptMgmt.ItemJnlDelete(ItemJnlLine);

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-1-10', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-1-10.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-1-10-10' then exit;
        // 7-1-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-1-11-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase2()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-2-1-10' then exit;
        // 7-2-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', ItemJnlLineNo, 20010211D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-2-2', '1_FI_RE', '', '', '', 11, 'PCS', 18.5, 0);
        ItemJnlLineNo := 20000;
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', ItemJnlLineNo, 20010215D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-2-2', '1_FI_RE', '', '', '', 3, 'PCS', 33.3, 0);

        if LastIteration = '7-2-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-2-2-20' then exit;
        // 7-2-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-2-3-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'REVAL', 'DEFAULT', ItemJnlLineNo, 20010211D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-2-4', '1_FI_RE', '', '', '', 0, '', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Applies-to Entry", LastILENo + 1);
        ItemJnlLine.Validate("Inventory Value (Revalued)", 110);
        ItemJnlLine.Modify();

        if LastIteration = '7-2-4-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-2-4-20' then exit;
        // 7-2-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-2-5-10' then exit;
        // 7-2-6
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-2-6-10' then exit;

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", '1_FI_RE');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010215D, 'TCS7-2-6', true, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-2-6-20' then exit;
        // 7-2-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-2-7-10' then exit;
        // 7-2-8
        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        //TCS7-2-8
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-2-8.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-2-8-10' then exit;
        // 7-2-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-2-9-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase3()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-3-1-10' then exit;
        // 7-3-2
        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-3-2', '5_ST_RA', '', 'BLUE', '', 3, 'PALLET', 666.66, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-3-2', '5_ST_RA', '', 'BLUE', '', 5, 'PALLET', 599.88, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-3-2', '5_ST_RA', '', 'RED', '', 10, 'PCS', 71.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-3-2', '5_ST_RA', '', 'BLUE', '', 23, 'PCS', 80.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-3-2', '5_ST_RA', '', 'BLUE', '', 22, 'PCS', 90.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010105D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-3-2', '5_ST_RA', '', 'BLUE', '', 11, 'PCS', 67.9, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-3-2', '5_ST_RA', '', 'BLUE', '', 2, 'PALLET', 700.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010120D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-3-2', '5_ST_RA', '', 'BLUE', '', 13, 'PCS', 99.9, 0);

        if LastIteration = '7-3-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-3-2-20' then exit;
        // 7-3-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-3-3-10' then exit;
        // 7-3-4
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-3-4-10' then exit;

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", '5_ST_RA');
        Item.SetRange("Location Filter", 'BLUE');
        Item.SetRange("Variant Filter", '');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010106D, 'TCS7-3-4', true, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-3-4-20' then exit;
        // 7-3-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-3-5-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 2000, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 500, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 2000, true, 0);

        if LastIteration = '7-3-6-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-3-6-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-3-6-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-3-6.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-3-6-40' then exit;
        // 7-3-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        TestScriptMgmt.ItemJnlDelete(ItemJnlLine);

        if LastIteration = '7-3-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase5()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-5-1-10' then exit;
        // 7-5-2
        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-5-2', '5_ST_RA', '', '', '', 10, 'PCS', 60.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-5-2', '2_LI_RA', '', '', '', 7, 'PCS', 24.4, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-5-2', '2_LI_RA', '', '', '', 3, 'PCS', 27.5, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-5-2', '2_LI_RA', '', '', '', 11, 'PCS', 40.9, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-5-2', '4_AV_RE', '', '', '', 20, 'PCS', 66.6, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010105D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-5-2', '4_AV_RE', '', '', '', 5, 'PCS', 40.4, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-5-2', '4_AV_RE', '', '', '', 5, 'PCS', 50.5, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-5-2', '4_AV_RE', '', '', '', 10, 'PCS', 60.5, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-5-2', '4_AV_RE', '', '', '', 1, 'PCS', 100.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010105D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-5-2', '4_AV_RE', '', '', '', 1, 'PCS', 299.9, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-5-2', '5_ST_RA', '', '', '', 5, 'PCS', 90.9, 0);

        if LastIteration = '7-5-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-5-2-20' then exit;
        // 7-5-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-5-3-10' then exit;
        // 7-5-4
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-5-4-10' then exit;

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010105D, 'TCS7-5-4', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-5-4-20' then exit;
        // 7-5-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-5-5-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 260, true, 0);

        if LastIteration = '7-5-6-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-5-6-20' then exit;
        // 7-5-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-5-7-10' then exit;
        // 7-5-8
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-5-8-10' then exit;

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("Location Filter", '');
        Item.SetRange("Variant Filter", '');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010105D, 'TCS7-5-8', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-5-8-20' then exit;
        // 7-5-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-5-9-10' then exit;

        TestScriptMgmt.ItemJnlDelete(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase6()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-6-1-10' then exit;
        // 7-6-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '7_ST_OV', '', '', '', 10, 'PCS', 100, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '7_ST_OV', '71', 'BLUE', '', 10, 'PCS', 110, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '7_ST_OV', '71', 'RED', '', 10, 'PCS', 120, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '7_ST_OV', '', '', '', 2, 'PCS', 200, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '7_ST_OV', '71', 'BLUE', '', 4, 'PCS', 210, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '7_ST_OV', '71', 'RED', '', 6, 'PCS', 220, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010105D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '6_AV_OV', '', '', '', 10, 'PCS', 200, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010105D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '6_AV_OV', '61', 'BLUE', '', 10, 'PCS', 210, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010105D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '6_AV_OV', '61', 'RED', '', 10, 'PCS', 220, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '6_AV_OV', '', '', '', 12, 'PCS', 100, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '6_AV_OV', '61', 'BLUE', '', 14, 'PCS', 110, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '6_AV_OV', '61', 'RED', '', 16, 'PCS', 120, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '6_AV_OV', '', '', '', 6, 'PCS', 160, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '6_AV_OV', '61', 'BLUE', '', 4, 'PCS', 170, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-6-2', '6_AV_OV', '61', 'RED', '', 2, 'PCS', 180, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '7_ST_OV', '', '', '', 2, 'PCS', 200, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '7_ST_OV', '71', 'BLUE', '', 2, 'PCS', 210, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '7_ST_OV', '71', 'RED', '', 2, 'PCS', 220, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '6_AV_OV', '', '', '', 2, 'PCS', 200, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '6_AV_OV', '61', 'BLUE', '', 2, 'PCS', 210, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-6-2', '6_AV_OV', '61', 'RED', '', 2, 'PCS', 220, 0);

        if LastIteration = '7-6-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-6-2-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-6-2-30' then exit;
        // 7-6-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-3-10' then exit;
        // 7-6-4
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010105D, 'TCS7-6-4', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-6-4-10' then exit;
        // 7-6-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-5-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', '');
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 400, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 400, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 400, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 40000, 300, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 50000, 200, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 60000, 400, true, 0);

        if LastIteration = '7-6-6-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-6-6-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-6-6-30' then exit;
        // 7-6-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-7-10' then exit;
        // 7-6-8
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010105D, 'TCS7-6-8', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-6-8-10' then exit;
        // 7-6-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-9-10' then exit;
        // 7-6-10
        TestScriptMgmt.ItemJnlDelete(ItemJnlLine);

        ValueEntry.Reset();
        ValueEntry.SetRange("Posting Date", 20010101D, 20010110D);
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-6-10', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-6-10.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-6-10-10' then exit;
        // 7-6-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-11-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertDimension('AREA', '30', '30');
        TestScriptMgmt.InsertDimension('DEPARTMENT', 'PROD', 'SALES');
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010112D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-6-12', '6_AV_OV', '', '', 'BLUE', 6, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010112D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-6-12', '6_AV_OV', '61', 'RED', 'BLUE', 6, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010112D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-6-12', '7_ST_OV', '', '', 'BLUE', 6, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010112D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-6-12', '7_ST_OV', '71', 'RED', 'BLUE', 2, 'PCS', 0, 0);

        if LastIteration = '7-6-12-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-6-12-20' then exit;
        // 7-6-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-13-10' then exit;
        // 7-6-14
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-6-14-10' then exit;

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010112D, 'TCS7-6-14', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-6-14-20' then exit;
        // 7-6-15
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 15, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-15-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 300, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 150, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 150, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 40000, 150, true, 0);

        if LastIteration = '7-6-16-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-6-16-20' then exit;
        // 7-6-17
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 17, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-17-10' then exit;
        // 7-6-18
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-6-18-10' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-6-18', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-6-18.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-6-18-20' then exit;
        // 7-6-19
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 19, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-6-19-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase7()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-7-1-10' then exit;
        // 7-7-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '7_ST_OV', '', '', '', 10, 'PCS', 100.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '7_ST_OV', '71', 'BLUE', '', 10, 'PCS', 110.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '7_ST_OV', '71', 'RED', '', 10, 'PCS', 120.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '6_AV_OV', '', '', '', 10, 'PCS', 100.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '6_AV_OV', '61', 'BLUE', '', 10, 'PCS', 110.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '6_AV_OV', '61', 'RED', '', 10, 'PCS', 120.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '6_AV_OV', '', '', '', 2, 'PALLET', 1000.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '6_AV_OV', '61', 'BLUE', '', 2, 'PALLET', 1100.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-7-2', '6_AV_OV', '61', 'RED', '', 2, 'PALLET', 1200.0, 0);

        if LastIteration = '7-7-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-7-2-20' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-7-2', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-7-2.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-7-2-30' then exit;
        // 7-7-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-7-3-10' then exit;
        // 7-7-4
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-4', '6_AV_OV', '', '', 'RED', 10, 'PCS', 0, 4);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-4', '6_AV_OV', '61', 'BLUE', 'RED', 10, 'PCS', 0, 5);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-4', '6_AV_OV', '', '', 'RED', 10, 'PCS', 0, 7);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-4', '6_AV_OV', '61', 'BLUE', 'RED', 10, 'PCS', 0, 8);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-4', '7_ST_OV', '', '', 'RED', 10, 'PCS', 0, 1);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-4', '7_ST_OV', '71', 'BLUE', 'RED', 10, 'PCS', 0, 2);

        if LastIteration = '7-7-4-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-7-4-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-7-4-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-7-4', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-7-4.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-7-4-40' then exit;
        // 7-7-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-7-5-10' then exit;
        // 7-7-6
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-6', '6_AV_OV', '', 'RED', 'BLUE', 20, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-6', '6_AV_OV', '61', 'RED', 'BLUE', 40, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-6', '7_ST_OV', '', 'RED', 'BLUE', 10, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-7-6', '7_ST_OV', '71', 'RED', 'BLUE', 20, 'PCS', 0, 0);

        if LastIteration = '7-7-6-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-7-6-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-7-6-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-7-6', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-7-6.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-7-6-40' then exit;
        // 7-7-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-7-7-10' then exit;
        // 7-7-8
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-8', '7_ST_OV', '', 'BLUE', '', 10, 'PCS', 200.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-8', '7_ST_OV', '71', 'BLUE', '', 20, 'PCS', 220.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-8', '6_AV_OV', '', 'BLUE', '', 20, 'PCS', 2000.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-8', '6_AV_OV', '61', 'BLUE', '', 8, 'PALLET', 2200.0, 0);

        if LastIteration = '7-7-8-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-7-8-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-7-8-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-7-8', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-7-8.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-7-8-40' then exit;
        // 7-7-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-7-9-10' then exit;
        // 7-7-10
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-10', '7_ST_OV', '', 'BLUE', '', -5, 'PCS', 100.0, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", 0, false, 31);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-10', '7_ST_OV', '71', 'BLUE', '', -10, 'PCS', 110.0, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", 0, false, 32);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-10', '6_AV_OV', '', 'BLUE', '', -10, 'PCS', 1000.0, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", 0, false, 33);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-7-10', '6_AV_OV', '61', 'BLUE', '', -4, 'PALLET', 1100.0, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Line No.", 0, false, 34);

        if LastIteration = '7-7-10-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-7-10-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-7-10-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-7-10', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-7-10.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-7-10-40' then exit;
        // 7-7-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-7-11-10' then exit;
        // 7-7-12
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010101D, 'TCS7-7-12', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-7-12-10' then exit;
        // 7-7-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-7-13-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 1000.0, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 1000.0, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 1000.0, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 40000, 1000.0, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 50000, 1000.0, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 60000, 1000.0, true, 0);

        if LastIteration = '7-7-14-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-7-14-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-7-14-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-7-14', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-7-14.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-7-14-40' then exit;
        // 7-7-15
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 15, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-7-15-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase8()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-8-1-10' then exit;
        // 7-8-2
        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-8-2', '1_FI_RE', '', '', '', 3, 'PCS', 3.333, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-8-2', '1_FI_RE', '', '', '', 1, 'PCS', 10.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-8-2', '1_FI_RE', '', '', '', 1, 'PCS', 10.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-8-2', '1_FI_RE', '', '', '', 1, 'PCS', 10.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010105D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-8-2', '4_AV_RE', '', '', '', 1, 'PCS', 10.0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-8-2', '4_AV_RE', '', '', '', 1, 'PCS', 20.0, 0);

        if LastIteration = '7-8-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-8-2-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-8-2-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-8-2', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-8-2.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-8-2-40' then exit;
        // 7-8-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-8-3-10' then exit;
        // 7-8-4
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-8-4', '4_AV_RE', '', '', 'BLUE', 1, 'PCS', 0, 5);

        if LastIteration = '7-8-4-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-8-4-20' then exit;
        // 7-8-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-8-5-10' then exit;
        // 7-8-6
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010109D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-8-6', '4_AV_RE', '', 'BLUE', 'RED', 1, 'PCS', 0, 8);

        if LastIteration = '7-8-6-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-8-6-20' then exit;
        // 7-8-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-8-7-10' then exit;
        // 7-8-8
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-8-8', '4_AV_RE', '', 'RED', '', 1, 'PCS', 0, 10);

        if LastIteration = '7-8-8-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-8-8-20' then exit;
        // 7-8-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-8-9-10' then exit;
        // 7-8-10
        TestScriptMgmt.AdjustItem('', '', false);
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'REVAL', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 0D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-8-10', '1_FI_RE', '', '', '', 0, '', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Applies-to Entry", 1);
        ItemJnlLine.Validate("Inventory Value (Revalued)", 12);
        ItemJnlLine.Modify();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'REVAL', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 0D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-8-10', '4_AV_RE', '', '', '', 0, '', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Applies-to Entry", 8);
        ItemJnlLine.Validate("Inventory Value (Revalued)", 30);
        ItemJnlLine.Modify();

        if LastIteration = '7-8-10-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-8-10-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-8-10-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-8-10', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-8-10.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-8-10-40' then exit;
        // 7-8-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-8-11-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase9()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-9-1-10' then exit;
        // 7-9-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-9-2-10' then exit;
        // 7-9-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-9-3-10' then exit;
        // 7-9-4
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 75, 0);

        if LastIteration = '7-9-4-10' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-9-4-20' then exit;

        FinishProdOrder(ProdOrderB1, 20010105D, false);

        if LastIteration = '7-9-4-30' then exit;
        // 7-9-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-9-5-10' then exit;
        // 7-9-6
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-9-6-10' then exit;
        // 7-9-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-9-7-10' then exit;
        // 7-9-8
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010115D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010115D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-9-8-10' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-9-8-20' then exit;

        FinishProdOrder(ProdOrderA1, 20010120D, false);

        if LastIteration = '7-9-8-30' then exit;
        // 7-9-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-9-9-10' then exit;
        // 7-9-10
        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-9-10-10' then exit;
        // 7-9-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-9-11-10' then exit;
        // 7-9-12
        SellWIPItemA(20010130D);

        if LastIteration = '7-9-12-10' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-9-12', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-9-12.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-9-12-20' then exit;
        // 7-9-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-9-13-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase10()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-10-1-10' then exit;
        // 7-10-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-10-2-10' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 75, 0);

        if LastIteration = '7-10-2-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-10-2-30' then exit;
        // 7-10-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-10-3-10' then exit;
        // 7-10-4
        FinishProdOrder(ProdOrderB1, 20010112D, false);

        if LastIteration = '7-10-4-10' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-10-4-20' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-10-4-30' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010130D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-10-4-40' then exit;

        FinishProdOrder(ProdOrderA1, 20010130D, false);

        if LastIteration = '7-10-4-50' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-10-4-60' then exit;

        SellWIPItemA(20010210D);

        if LastIteration = '7-10-4-70' then exit;
        // 7-10-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-10-5-10' then exit;
        // 7-10-6
        TestScriptMgmt.AdjustItem('', '', false);
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010102D, 'TCS7-10-6', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-10-6-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 525 * 10, true, 0);

        if LastIteration = '7-10-6-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-10-6-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-10-6-40' then exit;
        // 7-10-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-10-7-10' then exit;
        // 7-10-8
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010116D, 'TCS7-10-8', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-10-8-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 450 * 17, true, 0);

        if LastIteration = '7-10-8-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-10-8-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-10-8-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-10-8-50', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-10-8.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-10-8-50' then exit;
        // 7-10-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-10-9-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase11()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-11-1-10' then exit;
        // 7-11-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-11-2-10' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 75, 0);

        if LastIteration = '7-11-2-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-11-2-30' then exit;

        FinishProdOrder(ProdOrderB1, 20010112D, false);

        if LastIteration = '7-11-2-40' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-11-2-50' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-11-2-60' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010130D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-11-2-70' then exit;

        FinishProdOrder(ProdOrderA1, 20010130D, false);

        if LastIteration = '7-11-2-80' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-11-2-90' then exit;

        SellWIPItemA(20010210D);

        if LastIteration = '7-11-2-100' then exit;
        // 7-11-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-11-3-10' then exit;
        // 7-11-4
        TestScriptMgmt.AdjustItem('', '', false);
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010102D, 'TCS7-11-4', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-11-4-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 525 * 10, true, 0);

        if LastIteration = '7-11-4-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-11-4-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-11-4-40' then exit;
        // 7-11-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-11-5-10' then exit;
        // 7-11-6
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010116D, 'TCS7-11-6', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-11-6-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 450 * 22, true, 0);

        if LastIteration = '7-11-6-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-11-6-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-11-6-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-11-6-50', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-11-6.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-11-6-50' then exit;
        // 7-11-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-11-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase12()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-12-1-10' then exit;
        // 7-12-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-12-2-10' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 75, 0);

        if LastIteration = '7-12-2-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-12-2-30' then exit;

        FinishProdOrder(ProdOrderB1, 20010105D, false);

        if LastIteration = '7-12-2-40' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-12-2-50' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010115D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010115D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-12-2-60' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-12-2-70' then exit;

        FinishProdOrder(ProdOrderA1, 20010120D, false);

        if LastIteration = '7-12-2-80' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-12-2-90' then exit;

        SellWIPItemA(20010130D);

        if LastIteration = '7-12-2-100' then exit;
        // 7-12-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-12-3-10' then exit;
        // 7-12-4
        TestScriptMgmt.AdjustItem('', '', false);
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010110D, 'TCS7-12-4', true, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-12-4-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 25 * 3.3, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 30000, 150 * 3.3, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 40000, 75 * 3.3, true, 0);

        if LastIteration = '7-12-4-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-12-4-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-12-4-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-12-4-50', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-12-4.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-12-4-50' then exit;
        // 7-12-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-12-5-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase13()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-13-1-10' then exit;
        // 7-13-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-13-2-10' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 85, 0);

        if LastIteration = '7-13-2-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-13-2-30' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010115D, ProdOrderB1."No.", 'C', -10, 7);

        if LastIteration = '7-13-2-40' then exit;

        FinishProdOrder(ProdOrderB1, 20010115D, false);

        if LastIteration = '7-13-2-50' then exit;
        // 7-13-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-13-3-10' then exit;
        // 7-13-4
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-13-4-10' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010125D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-13-4-20' then exit;

        FinishProdOrder(ProdOrderA1, 20010125D, false);

        if LastIteration = '7-13-4-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-13-4-40' then exit;

        SellWIPItemA(20010205D);

        if LastIteration = '7-13-4-50' then exit;
        // 7-13-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-13-5-10' then exit;
        // 7-13-6
        TestScriptMgmt.AdjustItem('', '', false);
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010102D, 'TCS7-13-6', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-13-6-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 525 * 7, true, 0);

        if LastIteration = '7-13-6-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-13-6-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-13-6-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-13-6-50', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-13-6.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-13-6-50' then exit;
        // 7-13-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-13-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase14()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-14-1-10' then exit;
        // 7-14-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-14-2-10' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 75, 0);

        if LastIteration = '7-14-2-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-14-2-30' then exit;

        FinishProdOrder(ProdOrderB1, 20010105D, false);

        if LastIteration = '7-14-2-40' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010110D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010110D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-14-2-50' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010110D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-14-2-60' then exit;

        FinishProdOrder(ProdOrderA1, 20010110D, false);

        if LastIteration = '7-14-2-70' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-14-2-80' then exit;

        SellWIPItemA(20010130D);

        if LastIteration = '7-14-2-90' then exit;
        // 7-14-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-14-3-10' then exit;
        // 7-14-4
        TestScriptMgmt.AdjustItem('', '', false);
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010121D, 'TCS7-14-4', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-14-4-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 174 * 11, true, 0);

        if LastIteration = '7-14-4-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-14-4-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-14-4-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-14-4-50', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-14-4.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-14-4-50' then exit;
        // 7-14-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-14-5-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase15()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-15-1-10' then exit;
        // 7-15-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-15-2-10' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 75, 0);

        if LastIteration = '7-15-2-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-15-2-30' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010110D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010110D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-15-2-40' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010120D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-15-2-50' then exit;

        FinishProdOrder(ProdOrderA1, 20010120D, false);

        if LastIteration = '7-15-2-60' then exit;

        FinishProdOrder(ProdOrderB1, 20010120D, false);

        if LastIteration = '7-15-2-70' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-15-2-80' then exit;

        SellWIPItemA(20010130D);

        if LastIteration = '7-15-2-90' then exit;
        // 7-15-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-15-3-10' then exit;
        // 7-15-4
        TestScriptMgmt.AdjustItem('', '', false);
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010102D, 'TCS7-15-4', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-15-4-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 525 * 0, true, 0);

        if LastIteration = '7-15-4-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-15-4-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-15-4-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-15-4-50', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-15-4.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-15-4-50' then exit;
        // 7-15-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-15-5-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase17()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-17-1-10' then exit;
        // 7-17-2
        WorkDate(20010601D);
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();
        PurchaseWIPItemC();
        CreateProdOrders();

        if LastIteration = '7-17-2-10' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 25, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010110D, ProdOrderB1."No.", 'C', 32, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010115D, ProdOrderB1."No.", 'C', 18, 0);

        if LastIteration = '7-17-2-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010115D, ProdOrderB1."No.", 'B', 150);

        if LastIteration = '7-17-2-30' then exit;

        FinishProdOrder(ProdOrderB1, 20010115D, false);

        if LastIteration = '7-17-2-40' then exit;
        // 7-17-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-17-3-10' then exit;
        // 7-17-4
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010125D, ProdOrderA1."No.", 'C', 276, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010125D, ProdOrderA1."No.", 'B', 150, 0);

        if LastIteration = '7-17-4-10' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010130D, ProdOrderA1."No.", 'A', 120);

        if LastIteration = '7-17-4-20' then exit;

        FinishProdOrder(ProdOrderA1, 20010130D, false);

        if LastIteration = '7-17-4-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-17-4-40' then exit;

        SellWIPItemA(20010205D);

        if LastIteration = '7-17-4-50' then exit;
        // 7-17-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-17-5-10' then exit;
        // 7-17-6
        TestScriptMgmt.AdjustItem('', '', false);
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010106D, 'TCS7-17-6', true, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-17-6-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 20000, 50 * 1111, true, 0);
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 50000, 75 * 1111, true, 0);

        if LastIteration = '7-17-6-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-17-6-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-17-6-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-17-6-50', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-17-6.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-17-6-50' then exit;
        // 7-17-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-17-7-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase18()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        if LastIteration = '7-18-1-10' then exit;
        // 7-18-2
        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        TestScriptMgmt.InsertProdOrder(
          ProdOrderB1, ProdOrderB1.Status::Released, ProdOrderB1."Source Type"::Item, 'B', 250);
        TestScriptMgmt.InsertProdOrder(
          ProdOrderD1, ProdOrderD1.Status::Released, ProdOrderD1."Source Type"::Item, 'D', 120);

        if LastIteration = '7-18-2-10' then exit;
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-2', 'C', '', '', '', 50, 'PCS', 5, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010101D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-2', 'C', '', '', '', 50, 'PCS', 7, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010102D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-2', 'C', '', '', '', 200, 'PCS', 5, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010103D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-2', 'C', '', '', '', 150, 'PCS', 4, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010104D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-2', 'C', '', '', '', 75, 'PCS', 6, 0);

        if LastIteration = '7-18-2-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-2-30' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 125, 0);

        if LastIteration = '7-18-2-40' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-18-2-50' then exit;
        // 7-18-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-3-10' then exit;
        // 7-18-4
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010107D, 'TCS7-18-4', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-18-4-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 525 * 4, true, 0);

        if LastIteration = '7-18-4-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-4-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-18-4-40' then exit;
        // 7-18-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-5-10' then exit;
        // 7-18-6
        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010106D, ProdOrderB1."No.", 'B', 250);

        if LastIteration = '7-18-6-10' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'C');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010102D, 'TCS7-18-6', true, "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-18-6-20' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 300 * 3, true, 0);

        if LastIteration = '7-18-6-30' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-6-40' then exit;
        // 7-18-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-7-10' then exit;
        // 7-18-8
        FinishProdOrder(ProdOrderB1, 20010109D, false);

        if LastIteration = '7-18-8-10' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-18-8-20' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-18-8', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-18-8.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-18-8-30' then exit;
        // 7-18-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-9-10' then exit;
        // 7-18-10
        // Create and post Item Journal Lines
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010111D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-10', '4_AV_RE', '', '', '', 250, 'PCS', 5, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010112D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-10', '4_AV_RE', '', '', '', 150, 'PCS', 7, 0);

        if LastIteration = '7-18-10-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-10-20' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010113D, ProdOrderD1."No.", '4_AV_RE', 360, 0);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 20000, 20010113D, ProdOrderD1."No.", 'B', 150, 0);

        if LastIteration = '7-18-10-30' then exit;
        // 7-18-11
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 11, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-11-10' then exit;
        // 7-18-12
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010113D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-12', '4_AV_RE', '', '', '', 100, 'PCS', 6.5, 0);

        if LastIteration = '7-18-12-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-12-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-18-12-30' then exit;
        // 7-18-13
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 13, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-13-10' then exit;
        // 7-18-14
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", '4_AV_RE');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010117D, 'TCS7-18-14', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-18-14-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 500 * 7, true, 0);

        if LastIteration = '7-18-14-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-14-30' then exit;

        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010118D,
          ItemJnlLine."Entry Type"::Purchase, 'TCS7-18-14', '4_AV_RE', '', '', '', 100, 'PCS', 8, 0);

        if LastIteration = '7-18-14-40' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-14-50' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-18-14-60' then exit;
        // 7-18-15
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 15, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-15-10' then exit;
        // 7-18-16
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010119D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-18-16', '4_AV_RE', '', '', '', 100, 'PCS', 50, 0);

        if LastIteration = '7-18-16-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-16-20' then exit;

        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010120D, ProdOrderD1."No.", 'D', 120);

        if LastIteration = '7-18-16-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", '4_AV_RE');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20010119D, 'TCS7-18-16', true, "Inventory Value Calc. Per"::Item, true, true, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-18-16-40' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.ModifyItemJnlLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 10000, 500 * 10, true, 0);

        if LastIteration = '7-18-16-50' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-16-60' then exit;
        // 7-18-17
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 17, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-17-10' then exit;
        // 7-18-18
        FinishProdOrder(ProdOrderD1, 20010122D, false);

        if LastIteration = '7-18-18-10' then exit;

        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010123D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-18-18', '4_AV_RE', '', '', '', 140, 'PCS', 50, 0);

        if LastIteration = '7-18-18-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-18-18-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-18-18-40' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-18-18', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase7-18-18.pdf');
        Clear(PostInvtCostToGL);

        if LastIteration = '7-18-18-50' then exit;
        // 7-18-19
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 19, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-18-19-10' then exit;
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase19()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        Item.Get('C');
        Item.Validate("Costing Method", 3);
        Item.Modify();
        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '7-19-1-10' then exit;

        TestScriptMgmt.InsertProdOrder(
          ProdOrderB1, ProdOrderB1.Status::Released, ProdOrderB1."Source Type"::Item, 'B', 250);

        if LastIteration = '7-19-1-20' then exit;
        // 7-19-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS7-19-2', false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 100, 'PCS', 5);
        PurchLine."Location Code" := '';
        PurchLine.Modify();

        if LastIteration = '7-19-2-10' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-19-2-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010102D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010102D, 'BLUE', 'TCS7-19-3', false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 100, 'PCS', 7);
        PurchLine."Location Code" := '';
        PurchLine.Modify();

        if LastIteration = '7-19-2-30' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('+');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-19-2-40' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010131D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010131D, 'BLUE', 'TCS7-19-4', false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 200, 'PCS', 5);
        PurchLine."Location Code" := '';
        PurchLine.Modify();

        if LastIteration = '7-19-2-50' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('+');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-19-2-60' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 125, 0);

        if LastIteration = '7-19-2-70' then exit;
        // 7-19-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-19-3-10' then exit;
        // 7-19-4
        TestScriptMgmt.PostOutput('OUTPUT', 'DEFAULT', 10000, 20010106D, ProdOrderB1."No.", 'B', 250);

        if LastIteration = '7-19-4-10' then exit;

        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010106D,
          ItemJnlLine."Entry Type"::Sale, 'TCS7-19-S', 'B', '', '', '', 50, 'PCS', 10, 0);

        if LastIteration = '7-19-4-20' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-19-4-30' then exit;

        PurchHeader.Reset();
        if PurchHeader.Find('-') then
            repeat
                PurchHeader.Invoice := true;
                TestScriptMgmt.PostPurchOrder(PurchHeader);
            until PurchHeader.Next() = 0;

        if LastIteration = '7-19-4-40' then exit;

        FinishProdOrder(ProdOrderB1, 20010109D, false);

        if LastIteration = '7-19-4-50' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-19-4-60' then exit;
        // 7-19-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-19-5-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase20()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        Item.Get('C');
        Item.Validate("Costing Method", 4);
        Item.Validate("Standard Cost", 2);
        Item.Modify();
        Item.Get('B');
        Item.Validate("Costing Method", 4);
        Item.Validate("Standard Cost", 5);
        Item.Modify();
        Item.Get('A');
        Item.Validate("Costing Method", 4);
        Item.Validate("Standard Cost", 4);
        Item.Modify();

        if LastIteration = '7-20-1-10' then exit;

        Item.Reset();
        Item.SetFilter("No.", '%1..%2', 'A', 'C');
        CalculateStdCost.SetProperties(WorkDate(), false, true, false, '', false);
        CalculateStdCost.CalcItems(Item, TempItem);
        if TempItem.Find('-') then
            repeat
                ItemCostMgt.UpdateStdCostShares(TempItem);
            until TempItem.Next() = 0;
        Item.Reset();

        if LastIteration = '7-20-1-20' then exit;

        ProdBOMLine.Reset();
        ProdBOMLine.SetRange("Production BOM No.", 'A');
        ProdBOMLine.SetRange("No.", 'C');
        if ProdBOMLine.FindFirst() then begin
            ProdBOMLine.Validate("Quantity per", 0.75);
            ProdBOMLine.Modify();
        end;
        ProdBOMLine.SetRange("No.", 'B');
        if ProdBOMLine.FindFirst() then begin
            ProdBOMLine.Validate("Quantity per", 0.5);
            ProdBOMLine.Modify();
        end;

        if LastIteration = '7-20-1-30' then exit;

        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '7-20-1-40' then exit;
        // 7-20-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, 'BLUE', 'TCS7-20-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 100, 'PCS', 2);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'B', '', 100, 'PCS', 5);

        if LastIteration = '7-20-2-10' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-20-2-20' then exit;

        TestScriptMgmt.InsertProdOrder(
          ProdOrderA1, ProdOrderA1.Status::Released, ProdOrderA1."Source Type"::Item, 'A', 100);
        ProdOrderA1.Validate("Location Code", 'BLUE');
        ProdOrderA1.Modify();

        if LastIteration = '7-20-2-30' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrderA1);
        ProdOrderA1.Get(ProdOrderA1.Status, ProdOrderA1."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '7-20-2-40' then exit;

        ProdOrderA1.FindFirst();
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrderA1);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '7-20-2-50' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'CONSUMP');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.SetRange("Item No.", 'C');
        if ItemJnlLine.Find('-') then begin
            ItemJnlLine.Validate("Posting Date", 20010105D);
            ItemJnlLine.Validate(Quantity, 50);
            ItemJnlLine.Modify();
        end;
        ItemJnlLine.SetRange("Item No.", 'B');
        if ItemJnlLine.Find('-') then begin
            ItemJnlLine.Validate("Posting Date", 20010105D);
            ItemJnlLine.Validate(Quantity, 25);
            ItemJnlLine.Modify();
        end;

        if LastIteration = '7-20-2-60' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-20-2-60' then exit;

        ProdOrderA1.Reset();
        ProdOrderA1.FindFirst();
        WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', ProdOrderA1."No.");

        if LastIteration = '7-20-2-80' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Output Quantity", 50);
        ItemJnlLine.Validate("Posting Date", 20010105D);
        ItemJnlLine.Modify();
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-20-2-90' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-20-2', true);
        Clear(PostInvtCostToGL);

        if LastIteration = '7-20-2-100' then exit;
        // 7-20-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-20-3-10' then exit;
        // 7-20-4
        Item.Get('C');
        Item.Validate("Costing Method", 4);
        Item.Validate("Standard Cost", 3);
        Item.Modify();
        Item.Get('B');
        Item.Validate("Costing Method", 4);
        Item.Validate("Standard Cost", 6);
        Item.Modify();

        if LastIteration = '7-20-4-10' then exit;

        ProdOrderA1.FindFirst();
        Clear(CalcConsumption);
        CalcConsumption.InitializeRequest(WorkDate(), 1);
        CalcConsumption.SetTemplateAndBatchName('CONSUMP', 'DEFAULT');
        CalcConsumption.SetTableView(ProdOrderA1);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();

        if LastIteration = '7-20-4-20' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'CONSUMP');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.SetRange("Item No.", 'C');
        if ItemJnlLine.Find('-') then begin
            ItemJnlLine.Validate("Posting Date", 20010107D);
            ItemJnlLine.Validate(Quantity, -50);
            ItemJnlLine.Modify();
        end;
        ItemJnlLine.SetRange("Item No.", 'B');
        if ItemJnlLine.Find('-') then begin
            ItemJnlLine.Validate("Posting Date", 20010107D);
            ItemJnlLine.Validate(Quantity, -25);
            ItemJnlLine.Modify();
        end;

        if LastIteration = '7-20-4-30' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-20-4-40' then exit;

        ProdOrderA1.Reset();
        ProdOrderA1.FindFirst();
        WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', ProdOrderA1."No.");

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Output Quantity", -50);
        ItemJnlLine.Validate("Posting Date", 20010107D);
        ItemJnlLine.Validate("Applies-to Entry", 5);
        ItemJnlLine.Modify();

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-20-4-50' then exit;

        ProdOrderA1.Reset();
        ProdOrderA1.FindFirst();
        WMSTestscriptManagement.CreateOutputJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', ProdOrderA1."No.");

        if LastIteration = '7-20-4-60' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Posting Date", 20010107D);
        ItemJnlLine.Validate("Output Quantity", 0.00001);
        ItemJnlLine.Modify();

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-20-4-70' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-20-4-90' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-20-4-100' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-20-4', true);
        Clear(PostInvtCostToGL);

        if LastIteration = '7-20-4-110' then exit;

        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010127D,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TCS7-20-N', 'A', '', 'BLUE', '', 0.00001, 'PCS', 0, 0);

        if LastIteration = '7-20-4-120' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-20-4-130' then exit;
        // 7-20-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-20-5-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase21()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '7-21-1-10' then exit;
        // 7-21-2
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'TCS7-21-2', false);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 9, 'PCS', 3.333);
        PurchLine.Validate("Qty. to Receive", 9);
        PurchLine.Modify();
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 11, 'PCS', 53.555);
        PurchLine.Validate("Qty. to Receive", 11);
        PurchLine.Modify();
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 7, 'PCS', 1.111);
        PurchLine.Validate("Qty. to Receive", 7);
        PurchLine.Modify();
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 7);
        PurchLine.Validate("Qty. to Receive", 1);
        PurchLine.Modify();
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 5);
        PurchLine.Validate("Qty. to Receive", 1);
        PurchLine.Modify();

        if LastIteration = '7-21-2-10' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-21-2-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-21-2-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-21-2', true);
        Clear(PostInvtCostToGL);

        if LastIteration = '7-21-2-40' then exit;
        // 7-21-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-21-3-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-4', '4_AV_RE', '', '', 'BLUE', 1, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-4', '1_FI_RE', '', '', 'BLUE', 1, 'PCS', 0, 1);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-4', '5_ST_RA', '', '', 'BLUE', 1, 'PCS', 0, 2);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010108D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-4', '2_LI_RA', '', '', 'BLUE', 1, 'PCS', 0, 3);

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-21-4-10' then exit;
        // 7-21-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-21-5-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-6', '4_AV_RE', '', 'BLUE', 'RED', 1, 'PCS', 0, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-6', '1_FI_RE', '', 'BLUE', 'RED', 1, 'PCS', 0, 9);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-6', '5_ST_RA', '', 'BLUE', 'RED', 1, 'PCS', 0, 11);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20010110D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-21-6', '2_LI_RA', '', 'BLUE', 'RED', 1, 'PCS', 0, 13);

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-21-6-10' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-21-6-20' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-21-6', true);
        Clear(PostInvtCostToGL);

        if LastIteration = '7-21-6-30' then exit;
        // 7-21-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-21-7-10' then exit;
        // 7-21-8
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', 20010125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010125D, '', 'TCS7-21-8', false);

        if LastIteration = '7-21-8-10' then exit;

        PurchRcptLine.Reset();
        PurchGetRcpLine.SetPurchHeader(PurchHeader);
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        PurchGetRcpLine.CreateInvLines(PurchRcptLine);

        if LastIteration = '7-21-8-20' then exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 9, 9, 3.335, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 30000, 11, 11, 53.535, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 40000, 7, 7, 1.115, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 50000, 1, 1, 8, 0);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 60000, 1, 1, 5, 0);

        if LastIteration = '7-21-8-30' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-21-8-40' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-21-8-50' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-21-8', true);
        Clear(PostInvtCostToGL);

        if LastIteration = '7-21-8-60' then exit;
        // 7-21-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-21-9-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase22()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '7-22-1-10' then exit;
        // 7-22-2
        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 50);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 50, 0, true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, true);

        if LastIteration = '7-22-2-10' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-22-2-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, '', 'TCS7-22-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 10);

        if LastIteration = '7-22-2-30' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-22-2-40' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '10000', 20011130D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011130D, '', true, true);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 10);

        if LastIteration = '7-22-2-50' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-22-2-60' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', 20011125D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011125D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 50);
        SalesLine.Validate("Appl.-from Item Entry", 1);
        SalesLine.Modify();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        SalesLine.Validate("Appl.-from Item Entry", 2);
        SalesLine.Modify();

        if LastIteration = '7-22-2-70' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-22-2-80' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', 20011130D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011130D, '', true, true);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 7, 'PCS', 10);
        SalesLine.Validate("Appl.-from Item Entry", 4);
        SalesLine.Modify();

        if LastIteration = '7-22-2-90' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-22-2-100' then exit;
        // 7-22-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-22-3-10' then exit;
        // 7-22-4
        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011127D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-22-4', '1_FI_RE', '', 'BLUE', '', 1, 'PCS', 10, 0);
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011127D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-22-4', '4_AV_RE', '', 'BLUE', '', 1, 'PCS', 10, 0);

        if LastIteration = '7-22-4-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-22-4-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-22-4-30' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'Reval', 'DEFAULT', 10000, 20011127D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-22-4-2', '6_AV_OV', '', '', '', 0, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Applies-to Entry", 7);
        ItemJnlLine.Validate("Inventory Value (Revalued)", 11);
        ItemJnlLine.Modify();

        if LastIteration = '7-22-4-40' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-22-4-50' then exit;
        // 7-22-5
        TestScriptMgmt.InsertProdOrder(
          ProdOrderB1, ProdOrderB1.Status::Released, ProdOrderB1."Source Type"::Item, 'B', 10);
        ProdOrderB1.Validate("Location Code", 'BLUE');
        ProdOrderB1.Validate("Due Date", 20011128D);
        ProdOrderB1.Modify();
        WorkDate := 20011128D;

        if LastIteration = '7-22-5-10' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrderB1);
        ProdOrderB1.Get(ProdOrderB1.Status, ProdOrderB1."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '7-22-5-20' then exit;

        ProdOrderB1.Reset();
        ProdOrderB1.FindFirst();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011128D,
          ItemJnlLine."Entry Type"::Output, ProdOrderB1."No.", 'B', '', 'BLUE', '',
          0, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderB1."No.");
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate("Item No.");
        ItemJnlLine.Modify();

        if LastIteration = '7-22-5-30' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        OutpExplRtng.Run(ItemJnlLine);
        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Output Quantity", 120);
        ItemJnlLine.Modify();

        if LastIteration = '7-22-5-40' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-22-5-50' then exit;

        ProdOrderB1.Reset();
        ProdOrderB1.FindFirst();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011128D,
          ItemJnlLine."Entry Type"::Output, ProdOrderB1."No.", 'B', '', 'BLUE', '',
          0, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderB1."No.");
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate("Item No.");
        ItemJnlLine.Validate("Output Quantity", -110);
        ItemJnlLine.Validate("Applies-to Entry", 10);
        ItemJnlLine.Modify();

        if LastIteration = '7-22-5-60' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-22-5-70' then exit;
        // 7-22-6
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', 10000, 20011128D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-22-6', 'C', '', 'BLUE', '', 5, 'PCS', 10, 0);
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);
        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20010105D, ProdOrderB1."No.", 'C', 5, 0);
        FinishProdOrder(ProdOrderB1, 20011128D, false);

        if LastIteration = '7-22-6-10' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-21-6-20' then exit;
        // 7-22-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-22-7-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase23()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        TestScriptMgmt.SetAutoCostPost(true);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');

        Location.Get('BLUE');
        Location."Bin Mandatory" := true;
        Location.Modify(true);

        Bin.Init();
        Bin.Validate("Location Code", 'BLUE');
        Bin.Validate(Code, 'A2');
        if not Bin.Insert(true) then
            Bin.Modify(true);
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '7-23-1-10' then exit;
        // 7-23-2
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011125D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-23-2', '4_AV_RE', '', 'BLUE', '', 2250, 'PCS', 1.10784, 0);
        ItemJnlLine.Validate("Bin Code", 'A1');
        ItemJnlLine.Modify();

        if LastIteration = '7-23-2-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-23-2-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '01254796', 20011129D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011129D, 'BLUE', '', false);
        PurchHeader.Validate("Currency Code", 'DEM');
        PurchHeader.Modify();

        if LastIteration = '7-23-2-30' then exit;

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 2250, 'PCS', 0.993);
        PurchLine.Validate("Bin Code", 'A2');
        PurchLine.Modify();

        if LastIteration = '7-23-2-40' then exit;

        PurchHeader.Reset();
        PurchHeader.Find('-');
        PurchHeader.Receive := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-23-2-50' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'RECLASS', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011129D,
          ItemJnlLine."Entry Type"::Transfer, 'TCS7-23-2-2', '4_AV_RE', '', 'BLUE', 'BLUE', 2250, 'PCS', 0, 0);
        ItemJnlLine.Validate("Bin Code", 'A2');
        ItemJnlLine.Validate("New Bin Code", 'A1');
        ItemJnlLine.Modify();

        if LastIteration = '7-23-2-60' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-23-2-70' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '01254796', 20011126D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011129D, 'BLUE', 'TCS7-23-2-3', false);
        PurchHeader.Validate("Currency Code", 'DEM');
        PurchHeader.Modify();

        if LastIteration = '7-23-2-80' then exit;

        Clear(PurchGetRcpLine);
        PurchRcptLine.Reset();
        PurchGetRcpLine.SetPurchHeader(PurchHeader);
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        PurchGetRcpLine.CreateInvLines(PurchRcptLine);

        if LastIteration = '7-23-2-90' then exit;

        TestScriptMgmt.ModifyPurchLine(PurchHeader, 20000, 2250, 2250, 0.9927, 0);
        TestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::"Charge (Item)", 'UPS', '', 1, '', 7.9443);
        TestScriptMgmt.InsertPurchChargeAssignLine(PurchLine, 20000, PurchHeader."Document Type", PurchHeader."No.",
        20000, '4_AV_RE');
        TestScriptMgmt.ModifyPurchChargeAssignLine(PurchHeader, 30000, 20000, 1);

        if LastIteration = '7-23-2-100' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-23-2-110' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-23-2-120' then exit;
        // 7-23-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-23-3-10' then exit;
        // 7-23-4
        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011225D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011225D, 'GREEN', true, true);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 10);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 10, 10, 0, 0, false);

        if LastIteration = '7-23-4-10' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-23-4-20' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011225D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011225D, 'GREEN', 'TCS7-23-4', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 52, 'PCS', 10);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 10, 10, 0, 0);

        if LastIteration = '7-23-4-30' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-23-4-40' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", '10000', 20011227D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011227D, 'RED', 'TCS7-23-4-C', false);
        PurchHeader."Vendor Cr. Memo No." := 'TCS7-23-4-C';
        PurchHeader.Modify(true);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 7);

        if LastIteration = '7-23-4-50' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-23-4-60' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '10000', 20011230D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011230D, 'RED', true, true);

        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 0);
        SalesLine.Validate("Appl.-from Item Entry", 3);
        SalesLine.Modify();

        if LastIteration = '7-23-4-70' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-23-4-80' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-23-4-90' then exit;
        // 7-23-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-23-5-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase24()
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(false);
        TestScriptMgmt.SetAddRepCurr('DEM');

        Item.Get('5_ST_RA');
        Item.Validate("Inventory Value Zero", true);
        Item.Modify();
        TestScriptMgmt.ClearDimensions();
        DefDim.Init();
        DefDim.Validate("Table ID", 27);
        DefDim.Validate("No.", '4_AV_RE');
        DefDim.Validate("Dimension Code", 'AREA');
        DefDim.Validate("Dimension Value Code", '30');
        DefDim.Validate("Value Posting", 2);
        DefDim.Insert(true);
        DefDim.Validate("Dimension Code", 'DEPARTMENT');
        DefDim.Validate("Dimension Value Code", 'ADM');
        DefDim.Insert(true);
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '7-24-1-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS7-24-2', false);

        if LastIteration = '7-24-2-10' then exit;

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 100, 'PCS', 10);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 60);
        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '1_FI_RE', '', 100, 'PCS', 100);
        PurchLine.Validate("Line Discount %", 35);
        PurchLine.Modify();

        if LastIteration = '7-24-2-20' then exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-24-2-30' then exit;
        // 7-24-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-24-3-10' then exit;
        // 7-24-4
        TransferHeader.Init();
        TransferHeader.Insert(true);
        TransferHeader.Validate("Transfer-from Code", 'BLUE');
        TransferHeader.Validate("Transfer-to Code", 'RED');
        TransferHeader.Validate("Posting Date", 20011127D);
        TransferHeader.Validate("Shipment Date", 20011127D);
        TransferHeader.Validate("Receipt Date", 20011127D);
        TransferHeader.Modify(true);

        if LastIteration = '7-24-4-10' then exit;

        Clear(TransferLine);
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine.Insert(true);
        TransferLine.Validate("Item No.", '4_AV_RE');
        TransferLine.Validate(Quantity, 10);
        TransferLine.Validate("Unit of Measure Code", 'PCS');
        TransferLine.Validate("Qty. to Ship", 10);
        TransferLine.Modify();

        if LastIteration = '7-24-4-20' then exit;

        TransferPostShipment.SetHideValidationDialog(true);
        TransferPostShipment.Run(TransferHeader);
        TransferPostReceipt.SetHideValidationDialog(true);
        TransferPostReceipt.Run(TransferHeader);

        if LastIteration = '7-24-4-30' then exit;

        ItemJnlLineNo := 10000;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011129D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-24-4', '4_AV_RE', '', 'BLUE', '', 100, 'PCS', 5, 0);

        if LastIteration = '7-24-4-40' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-24-4-50' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-24-4-60' then exit;
        // 7-24-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-24-5-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'ITEM', 'DEFAULT', TestScriptMgmt.GetNextNo(ItemJnlLineNo), 20011201D,
          ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TCS7-24-6', '1_FI_RE', '', 'BLUE', '', 1, 'PCS', 0, 0);

        if LastIteration = '7-24-6-10' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-24-6-20' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011202D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011202D, 'BLUE', true, true);

        if LastIteration = '7-24-6-30' then exit;

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 500);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 10, 10, 0, 10, true);
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::"Charge (Item)", 'GPS', '', 1, '', 100);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 0, 10, true);
        SalesLine."Unit Price" := 90;

        if LastIteration = '7-24-6-40' then exit;

        TestScriptMgmt.InsertSalesChargeAssignLine(SalesLine, 10000, SalesHeader."Document Type", SalesHeader."No.",
        10000, '1_FI_RE');
        TestScriptMgmt.ModifySalesChargeAssignLine(SalesHeader, 20000, 10000, 1);

        if LastIteration = '7-24-6-50' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-24-6-60' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-24-6-70' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-24-7', true);
        Clear(PostInvtCostToGL);

        if LastIteration = '7-24-6-80' then exit;
        // 7-24-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-24-7-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase25()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpLine: Codeunit "Purch.-Get Receipt";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        if LastIteration = '7-25-1-10' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011125D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011125D, 'BLUE', 'TCS7-25-2', false);

        if LastIteration = '7-25-2-10' then exit;

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 2, 'PCS', 10);

        if LastIteration = '7-25-2-20' then exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := false;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-25-2-30' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20011126D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011126D, 'BLUE', 'TCS7-25-3', false);

        if LastIteration = '7-25-2-40' then exit;

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 3, 'PCS', 11);

        if LastIteration = '7-25-2-50' then exit;

        PurchHeader.Receive := true;
        PurchHeader.Invoice := false;
        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-25-2-60' then exit;
        // 7-25-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-25-3-10' then exit;
        // 7-25-4
        TestScriptMgmt.InsertProdOrder(
          ProdOrderB1, ProdOrderB1.Status::Released, ProdOrderB1."Source Type"::Item, 'B', 6);
        ProdOrderB1.Validate("Location Code", 'BLUE');
        ProdOrderB1.Validate("Due Date", 20011130D);
        ProdOrderB1.Modify();
        WorkDate := 20011130D;

        if LastIteration = '7-25-4-10' then exit;

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrderB1);
        ProdOrderB1.Get(ProdOrderB1.Status, ProdOrderB1."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        if LastIteration = '7-25-4-20' then exit;

        TestScriptMgmt.PostConsumption('CONSUMP', 'DEFAULT', 10000, 20011127D, ProdOrderB1."No.", 'C', 3, 0);

        if LastIteration = '7-25-4-30' then exit;

        ProdOrderB1.Reset();
        ProdOrderB1.FindFirst();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011128D,
          ItemJnlLine."Entry Type"::Output, ProdOrderB1."No.", 'B', '', 'BLUE', '',
          0, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderB1."No.");
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate("Item No.");
        ItemJnlLine.Modify();

        if LastIteration = '7-25-4-40' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        OutpExplRtng.Run(ItemJnlLine);

        if LastIteration = '7-25-4-50' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Output Quantity", 2);
        ItemJnlLine.Modify();

        if LastIteration = '7-25-4-60' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-25-4-70' then exit;

        ProdOrderB1.Reset();
        ProdOrderB1.FindFirst();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011130D,
          ItemJnlLine."Entry Type"::Output, ProdOrderB1."No.", 'B', '', 'BLUE', '',
          0, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderB1."No.");
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate("Item No.");
        ItemJnlLine.Modify();

        if LastIteration = '7-25-4-80' then exit;

        ItemJnlLine.Validate("Output Quantity", -2);
        ItemJnlLine.Validate("Applies-to Entry", 4);
        ItemJnlLine.Modify();

        if LastIteration = '7-25-4-90' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-25-4-100' then exit;

        ProdOrderB1.Reset();
        ProdOrderB1.FindFirst();
        TestScriptMgmt.InsertItemJnlLine(ItemJnlLine, 'OUTPUT', 'DEFAULT', 10000, 20011130D,
          ItemJnlLine."Entry Type"::Output, ProdOrderB1."No.", 'B', '', 'BLUE', '',
          0, 'PCS', 0, 0);
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderB1."No.");
        ItemJnlLine.Validate("Location Code", 'BLUE');
        ItemJnlLine.Validate("Item No.");
        ItemJnlLine.Modify();

        if LastIteration = '7-25-4-110' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        OutpExplRtng.Run(ItemJnlLine);

        if LastIteration = '7-25-4-120' then exit;

        ItemJnlLine.Reset();
        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Output Quantity", 4);
        ItemJnlLine.Modify();

        if LastIteration = '7-25-4-130' then exit;

        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-25-4-140' then exit;

        ProdOrderLine.Get(ProdOrderB1.Status, ProdOrderB1."No.", 10000);
        ProdOrderLine.Validate(Quantity, 4);
        ProdOrderLine.Modify();
        FinishProdOrder(ProdOrderB1, 20011130D, false);

        if LastIteration = '7-25-4-150' then exit;

        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '10000', 20011129D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20011129D, 'BLUE', 'TCS7-25-4', false);

        if LastIteration = '7-25-4-160' then exit;

        PurchRcptLine.Reset();
        PurchGetRcpLine.SetPurchHeader(PurchHeader);
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        PurchGetRcpLine.CreateInvLines(PurchRcptLine);

        if LastIteration = '7-25-4-170' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-25-4-180' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-25-4-190' then exit;
        // 7-25-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-25-5-10' then exit;
        // 7-25-6
        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20011204D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20011204D, 'BLUE', true, true);

        if LastIteration = '7-25-6-10' then exit;

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'B', '', 5, 'PCS', 50);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 5, 0, 0, true);

        if LastIteration = '7-25-6-20' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-25-6-30' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-25-6-40' then exit;
        // 7-25-7
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 7, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-25-7-10' then exit;
        // 7-25-8
        Commit();
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        CalcInvValue.SetItemJnlLine(ItemJnlLine);
        Item.Reset();
        Item.SetRange("No.", 'B');
        CalcInvValue.SetTableView(Item);
        CalcInvValue.SetParameters(20011201D, 'TCS7-25-8', true, "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false);
        CalcInvValue.UseRequestPage(false);
        CalcInvValue.RunModal();
        Clear(CalcInvValue);

        if LastIteration = '7-25-8-10' then exit;

        ItemJnlLine.Find('-');
        ItemJnlLine.Validate("Inventory Value (Revalued)", 1.08);
        ItemJnlLine.Modify();
        TestScriptMgmt.ItemJnlPostBatch(ItemJnlLine);

        if LastIteration = '7-25-8-20' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-25-8-30' then exit;

        ValueEntry.Reset();
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.InitializeRequest(0, 'TCS7-25-9', true);
        Clear(PostInvtCostToGL);

        if LastIteration = '7-25-8-40' then exit;
        // 7-25-9
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 9, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-25-9-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PerformTestCase26()
    var
        SalesShptLine: Record "Sales Shipment Line";
        UndoSalesShptLine: Codeunit "Undo Sales Shipment Line";
    begin
        TestScriptMgmt.SetGlobalPreconditions();

        TestScriptMgmt.SetAutoCostPost(false);
        TestScriptMgmt.SetExpCostPost(true);
        TestScriptMgmt.SetAddRepCurr('DEM');
        GetLastILENo();
        GetLastCLENo();
        GetLastGLENo();

        Item.Get('1_Fi_RE');
        Item.Validate("Unit Cost", 326.48);
        Item.Validate("Last Direct Cost", 323);
        Item.Validate("Indirect Cost %", 6);
        Item.Validate("Unit Price", 500);
        Item.Modify(true);

        Item.Get('4_AV_RE');
        Item.Validate("Unit Cost", 326.48);
        Item.Validate("Last Direct Cost", 323);
        Item.Validate("Indirect Cost %", 6);
        Item.Validate("Unit Price", 500);
        Item.Modify(true);

        if LastIteration = '7-26-1-10' then exit;
        // 7-26-2
        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010123D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010123D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 4, 'PCS', 500);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 4, 4, 0, 0, true);

        if LastIteration = '7-26-2-10' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-2-20' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010130D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010130D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 20, 'PCS', 500);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 20, 0, 0, 0, true);

        if LastIteration = '7-26-2-30' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-2-40' then exit;

        Clear(UndoSalesShptLine);
        SalesShptLine.SetRange("Document No.", '102002');
        SalesShptLine.FindFirst();
        UndoSalesShptLine.SetHideDialog(true);
        UndoSalesShptLine.Run(SalesShptLine);

        if LastIteration = '7-26-2-50' then exit;

        SalesHeader.Find('-');
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-2-60' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010214D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010214D, 'BLUE', 'TCS7-26-2', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 432, 'PCS', 323);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 432, 432, 0, 0);

        if LastIteration = '7-26-2-70' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-26-2-80' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010221D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010221D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 408, 'PCS', 500);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 408, 408, 0, 0, true);

        if LastIteration = '7-26-2-90' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-2-100' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-26-2-110' then exit;
        // 7-26-3
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 3, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-26-3-10' then exit;
        // 7-26-4
        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010223D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010223D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 4, 'PCS', 500);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 4, 4, 0, 0, true);

        if LastIteration = '7-26-4-10' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-4-20' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010228D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010228D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 20, 'PCS', 500);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 20, 0, 0, 0, true);

        if LastIteration = '7-26-4-30' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-4-40' then exit;

        Clear(UndoSalesShptLine);
        SalesShptLine.SetRange("Document No.", '102006');
        SalesShptLine.Find('-');
        UndoSalesShptLine.SetHideDialog(true);
        UndoSalesShptLine.Run(SalesShptLine);

        if LastIteration = '7-26-4-50' then exit;

        SalesHeader.Find('-');
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-4-60' then exit;
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010314D);
        TestScriptMgmt.ModifyPurchHeader(PurchHeader, 20010314D, 'BLUE', 'TCS 7-26-4', false);

        TestScriptMgmt.InsertPurchLine(
          PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '4_AV_RE', '', 432, 'PCS', 323);
        TestScriptMgmt.ModifyPurchLine(PurchHeader, 10000, 432, 432, 0, 0);

        if LastIteration = '7-26-4-70' then exit;

        TestScriptMgmt.PostPurchOrder(PurchHeader);

        if LastIteration = '7-26-4-80' then exit;

        Clear(SalesHeader);
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', 20010321D);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, 20010321D, 'BLUE', true, true);

        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '4_AV_RE', '', 408, 'PCS', 500);
        TestScriptMgmt.ModifySalesLine(SalesHeader, 10000, 408, 408, 0, 0, true);

        if LastIteration = '7-26-4-90' then exit;

        TestScriptMgmt.PostSalesOrder(SalesHeader);

        if LastIteration = '7-26-4-100' then exit;

        TestScriptMgmt.AdjustItem('', '', false);

        if LastIteration = '7-26-4-110' then exit;
        // 7-26-5
        TestScriptMgmt.VerifyPostCondition(UseCaseNo, TestCaseNo, 5, LastILENo, LastCLENo, LastGLENo);

        if LastIteration = '7-26-5-10' then exit;

        Commit();
    end;

    [Scope('OnPrem')]
    procedure PurchaseWIPItemC()
    var
        TestscriptMgmt: Codeunit _TestscriptManagement;
    begin
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestscriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'P1', true);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 50, 'PCS', 5);
        TestscriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 50, 50, 0, 0);
        TestscriptMgmt.PostPurchOrder(PurchHeader);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestscriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'P2', true);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 50, 'PCS', 5);
        TestscriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 50, 50, 0, 0);
        TestscriptMgmt.PostPurchOrder(PurchHeader);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestscriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'P3', true);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 200, 'PCS', 5);
        TestscriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 200, 200, 0, 0);
        TestscriptMgmt.PostPurchOrder(PurchHeader);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestscriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'P4', true);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 150, 'PCS', 5);
        TestscriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 150, 150, 0, 0);
        TestscriptMgmt.PostPurchOrder(PurchHeader);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', 20010101D);
        TestscriptMgmt.ModifyPurchHeader(PurchHeader, 20010101D, '', 'P5', true);
        TestscriptMgmt.ClearDimensions();
        TestscriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'C', '', 75, 'PCS', 5);
        TestscriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 75, 75, 0, 0);
        TestscriptMgmt.PostPurchOrder(PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure SellWIPItemA(PostingDate: Date)
    begin
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', PostingDate);
        TestScriptMgmt.ModifySalesHeader(SalesHeader, PostingDate, '', true, false);
        TestScriptMgmt.ClearDimensions();
        TestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A', '', 1, 'PCS', 100);
        TestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 1, 1, 0, 0, true);

        TestScriptMgmt.PostSalesOrder(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateProdOrders()
    begin
        TestScriptMgmt.InsertProdOrder(
          ProdOrderB1, ProdOrderB1.Status::Released, ProdOrderB1."Source Type"::Item, 'B', 150);
        TestScriptMgmt.InsertProdOrder(
          ProdOrderA1, ProdOrderA1.Status::Released, ProdOrderA1."Source Type"::Item, 'A', 120);
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

