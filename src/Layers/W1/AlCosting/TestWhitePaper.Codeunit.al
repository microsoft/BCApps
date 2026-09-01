codeunit 103525 "Test - White Paper"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103525);
        WMSTestscriptManagement.SetGlobalPreconditions();
        "Test 1"();
        "Test 2"();
        "Test 3"();
        "Test 4"();
        "Test 5"();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        PPUtil: Codeunit PPUtil;
        SRUtil: Codeunit SRUtil;
        MFGUtil: Codeunit MFGUtil;
        LastValueEntryNo: Integer;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        GLUtil.SetAddCurr('', 1, 1, 1, 1);

        PurchSetup.Get();
        PurchSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchSetup.Modify(true);

        INVTUtil.AdjustAndPostItemLedgEntries(true, true);
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        SetPreconditions();

        TestscriptMgt.TestBooleanValue('Revaluation of non-WIP inventory', true, true);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        WorkDate := 20030101D;

        INVTUtil.CreateBasisItem('RESALE', false, Item, Item."Costing Method"::FIFO, 0);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'RESALE', '', 2, 10);

        PPUtil.PostPurchase(PurchHeader, true, true);

        PurchRcptHeader.Get(GLUtil.GetLastDocNo(PurchSetup."Posted Receipt Nos."));

        WorkDate := 20030115D;

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::"Charge (Item)", 'P-FREIGHT', '', 1, 8);
        PPUtil.InsertItemChargeAssgntPurch(
          PurchLine, ItemChargeAssgntPurch, true,
          ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt, PurchRcptHeader."No.", 10000);
        ItemChargeAssgntPurch.Validate("Qty. to Assign", 1);
        ItemChargeAssgntPurch.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20030201D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        WorkDate := 20030301D;

        Clear(Item);
        Item.SetRange("No.", 'RESALE');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", 10);
        ItemJnlLine.Modify(true);
        ItemJnlPostBatch.Run(ItemJnlLine);

        WorkDate := 20030201D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030101D, 20030101D, 20, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030101D, 8, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, -4, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, -4, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030301D, -14, false);
    end;

    [Scope('OnPrem')]
    procedure "Test 2"()
    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        ProdOrder2: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
    begin
        SetPreconditions();

        TestscriptMgt.TestBooleanValue('Revaluation of WIP inventory', true, true);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('MFG', true, Item, Item."Costing Method"::FIFO, 0);

        MFGUtil.InsertPBOMHeader('MFG', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'COMP', '', 1, true);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);

        WorkDate := 20030101D;

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COMP', '', 2, 14);

        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20030201D;

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'MFG', 1);
        MFGUtil.PostConsump(ProdOrder."No.", 'COMP', 1);

        MFGUtil.CreateRelProdOrder(ProdOrder2, '', 'MFG', 1);
        MFGUtil.PostConsump(ProdOrder2."No.", 'COMP', 1);

        WorkDate := 20030215D;

        MFGUtil.PostOutput(ProdOrder, 'MFG', 1);
        MFGUtil.FinishProdOrder(ProdOrder."No.");

        INVTUtil.AdjustInvtCost();

        WorkDate := 20030131D;

        Clear(Item);
        Item.SetRange("No.", 'COMP');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", 10);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        WorkDate := 20030215D;

        MFGUtil.PostOutput(ProdOrder2, 'MFG', 1);
        MFGUtil.FinishProdOrder(ProdOrder2."No.");

        INVTUtil.AdjustInvtCost();

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030101D, 20030101D, 28, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, -14, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, -14, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030215D, 20030215D, 0, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030215D, 20030215D, 14, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030131D, 20030131D, -8, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030215D, 20030215D, 14, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, 4, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, 4, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030215D, 20030215D, -4, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030215D, 20030215D, 10, false);
    end;

    [Scope('OnPrem')]
    procedure "Test 3"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        SetPreconditions();

        TestscriptMgt.TestBooleanValue('Adjustment of non-WIP inventory (with revaluation)', true, true);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        WorkDate := 20030101D;

        INVTUtil.CreateBasisItem('RESALE', false, Item, Item."Costing Method"::FIFO, 0);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'RESALE', '', 6, 10);

        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20030201D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := 20030301D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := 20030401D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        WorkDate := 20030301D;

        Clear(Item);
        Item.SetRange("No.", 'RESALE');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", 8);
        ItemJnlLine.Modify(true);
        ItemJnlPostBatch.Run(ItemJnlLine);

        INVTUtil.AdjustInvtCost();

        WorkDate := 20030201D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := 20030301D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        WorkDate := 20030401D;

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '20000');
        SalesHeader.Modify(true);
        InsertSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, 'RESALE', '', 1);
        SRUtil.PostSales(SalesHeader, true, true);

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030101D, 20030101D, 60, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, -8, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, 2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030301D, -8, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, -8, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, -8, false);
    end;

    [Scope('OnPrem')]
    procedure "Test 4"()
    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: array[6] of Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        i: Integer;
        PostingDate: array[3] of Date;
    begin
        SetPreconditions();

        TestscriptMgt.TestBooleanValue('Adjustment of WIP inventory (with revaluation)', true, true);

        LastValueEntryNo := INVTUtil.GetLastValueEntryNo();

        PostingDate[1] := 20030201D;
        PostingDate[2] := 20030301D;
        PostingDate[3] := 20030401D;

        INVTUtil.CreateBasisItem('COMP', false, Item, Item."Costing Method"::FIFO, 0);
        INVTUtil.CreateBasisItem('MFG', true, Item, Item."Costing Method"::FIFO, 0);

        MFGUtil.InsertPBOMHeader('MFG', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'COMP', '', 1, true);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);

        WorkDate := 20030101D;

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'COMP', '', 6, 10);

        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := 20030115D;

        for i := 1 to 6 do begin
            MFGUtil.CreateRelProdOrder(ProdOrder[i], '', 'MFG', 1);
            MFGUtil.PostConsump(ProdOrder[i]."No.", 'COMP', 1);
        end;

        for i := 1 to 3 do begin
            WorkDate := PostingDate[i];

            MFGUtil.PostOutput(ProdOrder[i], 'MFG', 1);
            MFGUtil.FinishProdOrder(ProdOrder[i]."No.");

            INVTUtil.AdjustInvtCost();
        end;

        WorkDate := 20030110D;

        Clear(Item);
        Item.SetRange("No.", 'COMP');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", 8);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        for i := 1 to 3 do begin
            WorkDate := PostingDate[i];

            MFGUtil.PostOutput(ProdOrder[i + 3], 'MFG', 1);
            MFGUtil.FinishProdOrder(ProdOrder[i + 3]."No.");

            INVTUtil.AdjustInvtCost();
        end;

        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030101D, 20030101D, 60, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, -10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, 0, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, 10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, 10, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, 10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, 10, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, 10, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030110D, 20030110D, -12, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, 10, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, 2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, 2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, 2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, 2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, 2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030115D, 20030115D, 2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, -2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, -2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, -2, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030201D, 20030201D, 8, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, 8, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030301D, 20030301D, 8, false);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, 8, true);
        ValidateValueEntry(GetNextEntryNo(LastValueEntryNo), 20030401D, 20030401D, 8, false);
    end;

    [Scope('OnPrem')]
    procedure "Test 5"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        SetPreconditions();

        TestscriptMgt.TestBooleanValue('Setting Standard Cost', true, true);

        INVTUtil.CreateBasisItem('STD', false, Item, Item."Costing Method"::Standard, 10);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);
        InsertPurchLine(PurchHeader, PurchLine, PurchLine.Type::Item, 'STD', '', 1, 25);
        PPUtil.PostPurchase(PurchHeader, true, false);

        Item.Find();
        Item.Validate("Standard Cost", 12);
        Item.Modify(true);

        PurchHeader.Find();
        PPUtil.PostPurchase(PurchHeader, false, true);

        ItemLedgEntry.FindLast();
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName("Cost Amount (Actual)"), ItemLedgEntry."Cost Amount (Actual)", 12);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Location: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, Type);
        PurchLine.Validate("No.", No);
        PurchLine.Validate("Location Code", Location);
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Location: Code[20]; Qty: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, Type);
        SalesLine.Validate("No.", No);
        SalesLine.Validate("Location Code", Location);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateValueEntry(EntryNo: Integer; PostDate: Date; ValDate: Date; CostAmt: Decimal; ExpCost: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Get(EntryNo);
        TestscriptMgt.TestNumberValue(ValueEntry.FieldName("Entry No."), ValueEntry."Entry No.", EntryNo);
        TestscriptMgt.TestDateValue(ValueEntry.FieldName("Posting Date"), ValueEntry."Posting Date", PostDate);
        TestscriptMgt.TestDateValue(ValueEntry.FieldName("Valuation Date"), ValueEntry."Valuation Date", ValDate);
        TestscriptMgt.TestBooleanValue(ValueEntry.FieldName("Expected Cost"), ValueEntry."Expected Cost", ExpCost);
        if ValueEntry."Expected Cost" then
            TestscriptMgt.TestNumberValue(ValueEntry.FieldName("Cost Amount (Expected)"), ValueEntry."Cost Amount (Expected)", CostAmt)
        else
            TestscriptMgt.TestNumberValue(ValueEntry.FieldName("Cost Amount (Actual)"), ValueEntry."Cost Amount (Actual)", CostAmt);
    end;

    local procedure GetNextEntryNo(var LastEntryNo: Integer): Integer
    begin
        LastEntryNo := LastEntryNo + 1;
        exit(LastEntryNo);
    end;
}

