codeunit 103426 Corsica_TracingCost_VE_GL
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        WMSTestscriptManagement.SetGlobalPreconditions();
        TestResultsPath := CostingTestScriptMgmt.GetTestResultsPath();
        "TCS-1"();
        // Automatic Cost Posting"TCS-3-1"();
        // Normal Case"TCS-3-2"();
        // Posting Errors exist"TCS-3-3"();
        // Posting Manually without Expected Cost Posting"TCS-4-1"();
        // Normal Case"TCS-4-2"();
        // Posting Errors exist"TCS-4-3"();      // Posting Manually without Expected Cost Posting

        // "TCS-2";      //Closing Inventory Period and Allow From Posting Date - manual test, only data preparation
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        CurrTest: Text[80];
        TEXT001: Label 'Error';
        TEXT002: Label '- Records in Table =';
        TEXT003: Label '-  Posting Date Value Entry  = Posting Date G/L Entry =';
        TEXT004: Label '- Test failed, Entry number does not exist =';
        TEXT005: Label '-  Relation Error, not all relations between G/L and Value Entry established =';
        Text008: Label '- Table is empty -';
        Text009: Label '- Test succeeds -';
        TestResultsPath: Text[250];

    local procedure Test("Code": Code[20]; PostPerEntry: Boolean; PostingError: Boolean; ExpectedCostPosting: Boolean)
    var
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        GLItemLedgerRelation: Record "G/L - Item Ledger Relation";
        ValueEntryCounter: Integer;
        GLEntryNonInvtRecords: Integer;
        GLEntryRecords: Integer;
        GLItemLedgerRelationRecords: Integer;
        RelationCounter: Integer;
        LastEntryNo: Integer;
    begin
        GLItemLedgerRelationRecords := GLItemLedgerRelation.Count();
        GLItemLedgerRelation.Reset();
        if PostPerEntry then begin
            GLEntry.SetFilter("Document Type", '<>%1', 0);
            GLEntryNonInvtRecords := GLEntry.Count;
            GLEntry.Reset();
            GLEntry.FindLast();
            LastEntryNo := GLEntry."Entry No.";
            GLEntry.SetFilter("Entry No.", '<=%1', LastEntryNo);
            GLEntryRecords := GLEntry.Count;
            GLEntry.Reset();
            GLEntryRecords := GLEntryRecords - GLEntryNonInvtRecords;
            TestscriptMgt.TestNumberValue(
              MakeName(Code, GLItemLedgerRelation.TableCaption(), TEXT002), GLItemLedgerRelationRecords, GLEntryRecords);
        end;

        if not ExpectedCostPosting then
            ValueEntry.SetRange("Expected Cost", false);
        if ValueEntry.FindSet() then begin
            GLItemLedgerRelation.SetCurrentKey("Value Entry No.");
            repeat
                GLItemLedgerRelation.SetRange("Value Entry No.", ValueEntry."Entry No.");
                if GLItemLedgerRelation.FindSet() then begin
                    repeat
                        Code := IncStr(Code);
                        GLEntry.Get(GLItemLedgerRelation."G/L Entry No.");
                        TestscriptMgt.TestDateValue(MakeName(Code, ValueEntry.TableCaption(), TEXT003), GLEntry."Posting Date", ValueEntry."Posting Date");
                        RelationCounter := RelationCounter + 1;
                        ValueEntryCounter := ValueEntryCounter + 1;
                    until GLItemLedgerRelation.Next() = 0;
                    if not ((RelationCounter = 2) or (RelationCounter = 4)) then begin
                        Code := IncStr(Code);
                        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT005), ValueEntry."Entry No.", 999999);
                    end;
                    RelationCounter := 0;
                end else
                    if not PostingError then begin
                        Code := IncStr(Code);
                        TestscriptMgt.TestNumberValue(MakeName(Code, ValueEntry.TableCaption(), TEXT004), ValueEntry."Entry No.", 999999);
                    end;
            until ValueEntry.Next() = 0;
            Code := IncStr(Code);
            TestscriptMgt.TestNumberValue(
              MakeName(Code, GLItemLedgerRelation.TableCaption(), TEXT002), GLItemLedgerRelationRecords, ValueEntryCounter);
        end else begin
            Code := IncStr(Code);
            TestscriptMgt.TestTextValue(MakeName(Code, ValueEntry.TableCaption(), Text008), TEXT001, '');
        end;

        GLItemLedgerRelation.Reset();
        GLEntry.SetRange("Document Type", 0);
        if GLEntry.FindSet() then begin
            GLItemLedgerRelation.SetCurrentKey("G/L Entry No.");
            repeat
                GLItemLedgerRelation.SetRange("G/L Entry No.", GLEntry."Entry No.");
                if GLItemLedgerRelation.IsEmpty() then begin
                    Code := IncStr(Code);
                    TestscriptMgt.TestNumberValue(MakeName(Code, GLEntry.TableCaption(), TEXT004), GLEntry."Entry No.", 999999);
                    RelationCounter := RelationCounter + 1;
                end;
            until GLEntry.Next() = 0;
            if RelationCounter = 0 then begin
                Code := IncStr(Code);
                TestscriptMgt.TestTextValue(MakeName(Code, GLEntry.TableCaption(), Text009), '', '');
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure "TCS-1"()
    var
        "Code": Code[20];
    begin
        CreateTestData(true, true, true);
        Code := '103426-TC-1-1-';
        Test(Code, true, false, true);
    end;

    [Scope('OnPrem')]
    procedure "TCS-2"()
    begin
        CreateTestData(false, true, true);
    end;

    [Scope('OnPrem')]
    procedure "TCS-3-1"()
    var
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        "Code": Code[20];
    begin
        CreateTestData(false, true, false);
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase9-2-5.pdf');
        Code := '103426-TC-3-1-1-';
        Test(Code, true, false, true);
    end;

    [Scope('OnPrem')]
    procedure "TCS-3-2"()
    var
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        "Code": Code[20];
    begin
        CreateTestData(false, true, false);
        BlockAccount();
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-2.pdf');
        Code := '103426-TC-3-2-1-';
        Test(Code, true, true, true);
    end;

    [Scope('OnPrem')]
    procedure "TCS-3-3"()
    var
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        "Code": Code[20];
    begin
        CreateTestData(false, false, false);
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(1, '', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase3-2.pdf');
        Code := '103426-TC-3-3-1-';
        Test(Code, true, false, false);
    end;

    [Scope('OnPrem')]
    procedure "TCS-4-1"()
    var
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        "Code": Code[20];
    begin
        CreateTestData(false, true, false);
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS-4-1', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-1.pdf');
        Code := '103426-TC-4-1-1-';
        Test(Code, false, false, true);
    end;

    [Scope('OnPrem')]
    procedure "TCS-4-2"()
    var
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        "Code": Code[20];
    begin
        CreateTestData(false, true, false);
        BlockAccount();
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS-4-2', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-2.pdf');
        Code := '103426-TC-4-2-1-';
        Test(Code, false, true, true);
    end;

    [Scope('OnPrem')]
    procedure "TCS-4-3"()
    var
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        "Code": Code[20];
    begin
        CreateTestData(false, false, false);
        Clear(PostInvtCostToGL);
        PostInvtCostToGL.InitializeRequest(0, 'TCS-4-3', true);
        PostInvtCostToGL.SaveAsPdf(TestResultsPath + 'TestCase4-3.pdf');
        Code := '103426-TC-4-3-1-';
        Test(Code, false, false, false);
    end;

    local procedure CreateTestData(AutoCostPost: Boolean; ExpcostPost: Boolean; OnlineAdjust: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ProdOrder: Record "Production Order";
    begin
        CostingTestScriptMgmt.SetGlobalPreconditions();

        if AutoCostPost then
            CostingTestScriptMgmt.SetAutoCostPost(true);
        if ExpcostPost then
            CostingTestScriptMgmt.SetExpCostPost(true);
        if OnlineAdjust then
            CostingTestScriptMgmt.SetAutoCostAdjmt("Automatic Cost Adjustment Type"::Always);

        Item.Get('6_AV_OV');
        Item.Validate("Indirect Cost %", 10);
        Item.Validate("Overhead Rate", 2);
        Item.Modify(true);

        WorkDate := 20010120D;
        CreatePurchOrder('BLUE');
        CreatePurchOrder('BLUE');
        CreatePurchOrder('RED');
        CreatePurchOrder('RED');
        CreateSalesOrder('BLUE');
        CreateSalesOrder('RED');
        WorkDate := 20010121D;
        CreateSalesOrder('BLUE');
        CreateSalesOrder('RED');
        CreatePurchOrder('BLUE');
        CreatePurchOrder('RED');

        WorkDate := 20010122D;
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 1, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesReturnLine(SalesHeader, SalesLine."Line No.", 1, 1, 100, 0, 0);
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010123D;
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchReturnHeader(PurchHeader, WorkDate(), 'BLUE', '');
        CostingTestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 1, 'PCS', 10, 0);
        CostingTestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
        CostingTestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 1, 'PCS', 20, 0);
        CostingTestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
        CostingTestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 1, 'PCS', 30, 0);
        CostingTestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
        CostingTestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 1, 'PCS', 40, 0);
        CostingTestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
        CostingTestScriptMgmt.InsertPurchReturnLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 1, 'PCS', 50, 0);
        CostingTestScriptMgmt.ModifyPurchReturnLine(PurchHeader, PurchLine."Line No.", 1, 1);
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010124D;
        InvoiceOrders();
        WorkDate := 20010125D;

        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), 'RED', '', true);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, 'B', '', 100, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, 'C', '', 100, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 100, 0, 20, 0);
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);

        WorkDate := 20010126D;
        Clear(TransHeader);
        WMSTestscriptManagement.InsertTransferHeader(TransHeader, 'RED', 'Blue', 'OWN LOG.', WorkDate());
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 10000, 'B', '', 'PCS', 100, 0, 100);
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 20000, 'C', '', 'PCS', 100, 0, 100);
        WMSTestscriptManagement.PostTransferOrder(TransHeader);
        WMSTestscriptManagement.PostTransferOrderRcpt(TransHeader);

        WorkDate := 20010127D;
        Clear(ProdOrder);
        WMSTestscriptManagement.InsertProdOrder(ProdOrder, 3, ProdOrder."Source Type"::Item.AsInteger(), 'A', 40, 'BLUE');

        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, false, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;

        WorkDate := 20010128D;
        ProdOrder.FindFirst();
        PostConsumptionOutput(ProdOrder);
        WorkDate := 20010129D;
        FinishProdOrder(ProdOrder, WorkDate(), false);

        WorkDate := 20010130D;
        Clear(TransHeader);
        WMSTestscriptManagement.InsertTransferHeader(TransHeader, 'Blue', 'RED', 'OWN LOG.', WorkDate());
        WMSTestscriptManagement.InsertTransferLine(TransLine, TransHeader."No.", 10000, 'A', '', 'PCS', 40, 0, 40);
        WMSTestscriptManagement.PostTransferOrder(TransHeader);
        WMSTestscriptManagement.PostTransferOrderRcpt(TransHeader);

        WorkDate := 20010131D;
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'RED', true, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, 'A', '', 40, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 40, 40, 100, 0, false);
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
        WorkDate := 20010201D;
        CreatePurchOrder('BLUE');
        WorkDate := 20010202D;
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', true, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 4, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 4, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 4, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 4, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 6, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 6, 4, 100, 0, false);
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);

        WorkDate := 20010203D;
        ModifyUnitCost();
        InvoiceOrders();
        WorkDate := 20010204D;
        if not OnlineAdjust then
            CostingTestScriptMgmt.AdjustItem('', '', false);
    end;

    local procedure CreatePurchOrder(LocationCode: Code[10])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        Clear(PurchHeader);
        CostingTestScriptMgmt.InsertPurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifyPurchHeader(PurchHeader, WorkDate(), LocationCode, '', true);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 10000, PurchLine.Type::Item, '1_FI_RE', '', 10, 'PCS', 10);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 10, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 20000, PurchLine.Type::Item, '4_AV_RE', '', 10, 'PCS', 20);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 20, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 30000, PurchLine.Type::Item, '2_LI_RA', '', 10, 'PCS', 30);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 30, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 40000, PurchLine.Type::Item, '5_ST_RA', '', 10, 'PCS', 40);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 40, 0);
        CostingTestScriptMgmt.InsertPurchLine(PurchLine, PurchHeader, 50000, PurchLine.Type::Item, '6_AV_OV', '', 10, 'PCS', 50);
        CostingTestScriptMgmt.ModifyPurchLine(PurchHeader, PurchLine."Line No.", 10, 0, 50, 0);
        CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
    end;

    local procedure CreateSalesOrder(LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);
        CostingTestScriptMgmt.InsertSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '10000', WorkDate());
        CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), LocationCode, true, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 10000, SalesLine.Type::Item, '1_FI_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 20000, SalesLine.Type::Item, '4_AV_RE', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 30000, SalesLine.Type::Item, '2_LI_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 40000, SalesLine.Type::Item, '5_ST_RA', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.InsertSalesLine(SalesLine, SalesHeader, 50000, SalesLine.Type::Item, '6_AV_OV', '', 5, 'PCS', 100);
        CostingTestScriptMgmt.ModifySalesLine(SalesHeader, SalesLine."Line No.", 5, 0, 100, 0, false);
        CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
    end;

    local procedure ModifyUnitCost()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TempUnitCost: Decimal;
    begin
        PurchHeader.Reset();
        if PurchHeader.FindSet() then
            repeat
                ReleasePurchDoc.Reopen(PurchHeader);
                PurchLine.Reset();
                PurchLine.SetRange(PurchLine."Document No.", PurchHeader."No.");
                if PurchLine.FindSet() then
                    repeat
                        TempUnitCost := PurchLine."Direct Unit Cost" + 10;
                        PurchLine.Validate(PurchLine."Direct Unit Cost", TempUnitCost);
                        PurchLine.Modify(true);
                    until PurchLine.Next() = 0;
            until PurchHeader.Next() = 0;
    end;

    local procedure InvoiceOrders()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
    begin
        if PurchHeader.FindSet() then
            repeat
                PurchHeader."Posting Date" := WorkDate();
                PurchHeader.Invoice := true;
                PurchHeader.Modify();
                CostingTestScriptMgmt.PostPurchOrder(PurchHeader);
            until PurchHeader.Next() = 0;
        if SalesHeader.FindSet() then
            repeat
                CostingTestScriptMgmt.ModifySalesHeader(SalesHeader, WorkDate(), 'BLUE', false, true);
                SalesHeader.Invoice := true;
                CostingTestScriptMgmt.PostSalesOrder(SalesHeader);
            until SalesHeader.Next() = 0;
    end;

    local procedure PostConsumptionOutput(var ProdOrder: Record "Production Order")
    var
        MFGUtil: Codeunit MFGUtil;
    begin
        MFGUtil.PostConsump(ProdOrder."No.", 'b', 60);
        MFGUtil.PostConsump(ProdOrder."No.", 'C', 92);
        MFGUtil.PostOutput(ProdOrder, 'A', 40);
    end;

    [Scope('OnPrem')]
    procedure BlockAccount()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get('2111');
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
    end;

    local procedure MakeName(TextPar1: Variant; TextPar2: Variant; TextPar3: Text[250]): Text[250]
    begin
        exit(StrSubstNo('%1 - %2 %3 %4', CurrTest, TextPar1, TextPar2, TextPar3));
    end;

    local procedure FinishProdOrder(ProdOrder: Record "Production Order"; NewPostingDate: Date; NewUpdateUnitCost: Boolean)
    var
        ToProdOrder: Record "Production Order";
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        LibraryManufacturing.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, NewPostingDate, NewUpdateUnitCost);
        WhseProdRelease.FinishedDelete(ToProdOrder);
    end;

    [Scope('OnPrem')]
    procedure SetTestResultsPath(NewTestResultsPath: Text[250])
    begin
        TestResultsPath := NewTestResultsPath;
    end;
}

