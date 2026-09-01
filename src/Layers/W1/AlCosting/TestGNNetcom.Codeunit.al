codeunit 103524 "Test - GN Netcom"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103524);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 1"();
        "Test 2"();
        "Test 3"();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        PPUtil: Codeunit PPUtil;
        INVTUtil: Codeunit INVTUtil;
        MFGUtil: Codeunit MFGUtil;
        CRPUtil: Codeunit CRPUtil;
        PostDate1: Date;
        PostDate2: Date;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        WorkDate := 20020201D;

        GLUtil.SetAddCurr('EUR', 10, 3, 0.01, 0.00001);

        SalesSetup.Get();
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup.Modify();

        PurchSetup.Get();
        PurchSetup."Ext. Doc. No. Mandatory" := false;
        PurchSetup.Modify();

        INVTUtil.AdjustAndPostItemLedgEntries(true, true);
        CreateItemRtngAndPBOMs();
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test that only the standard cost is updated for the item in the filter.

        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        Item.SetRange("No.", 'TEST5');
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::"Standard Cost - Manufacturing");

        Clear(Item);
        Item.Get('TEST3');
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', Item."No.", Item.FieldName("Standard Cost")),
          Item."Standard Cost", 0);
        Item.Get('TEST5');
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2', Item."No.", Item.FieldName("Standard Cost")),
          Item."Standard Cost", 1);
    end;

    [Scope('OnPrem')]
    procedure "Test 2"()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ProdOrder: Record "Production Order";
        Item: Record Item;
        RtngLine: Record "Routing Line";
        PBOMLine: Record "Production BOM Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // Test that revaluation amount of a manufactured item is posted to the right account.

        PostDate1 := GLUtil.GetLastestPostingDate() + 4;
        PostDate2 := GLUtil.GetLastestPostingDate() + 15;

        INVTUtil.CalcStandardCost('TEST3');

        WorkDate := PostDate2;

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '30000');
        PurchHeader.Modify(true);

        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", 'TEST1');
        PurchLine.Validate(Quantity, 9700);
        PurchLine.Validate("Direct Unit Cost", 0.07);
        PurchLine.Modify(true);

        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", 'TEST2');
        PurchLine.Validate(Quantity, 1800);
        PurchLine.Validate("Direct Unit Cost", 0.11);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        WorkDate := PostDate1;

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'TEST3', 300);
        PostOutput(ProdOrder, 'TEST3', 300);

        WorkDate := PostDate2;

        PostConsumption(ProdOrder."No.", PostDate2, 1, '');
        MFGUtil.FinishProdOrder(ProdOrder."No.");

        INVTUtil.AdjustInvtCost();
        INVTUtil.PostInvtCost(1, '');

        Item.Get('TEST1');
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);
        Item.Get('TEST2');
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);

        MFGUtil.UncertifyPBOM('TEST3', '');
        PBOMLine.SetRange("Production BOM No.", 'TEST3');
        PBOMLine.Find('-');
        repeat
            PBOMLine.Validate("Routing Link Code", '100');
            PBOMLine.Modify(true);
        until PBOMLine.Next() = 0;

        CRPUtil.UncertifyRouting('TEST3', '');
        RtngLine.Get('TEST3', '', '10');
        RtngLine.Validate("Routing Link Code", '100');
        RtngLine.Modify(true);

        CRPUtil.CertifyRouting('TEST3', '');
        MFGUtil.CertifyPBOM('TEST3', '');

        WorkDate := PostDate1;

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'TEST3', 200);
        PostOutput(ProdOrder, 'TEST3', 200);

        WorkDate := PostDate2;

        INVTUtil.AdjustInvtCost();
        INVTUtil.PostInvtCost(1, '');

        Clear(Item);
        Item.SetRange("No.", 'TEST1');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, PostDate2, '', "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit Cost (Revalued)", 0.08);
        ItemJnlLine.Modify(true);
        ItemJnlPostBatch.Run(ItemJnlLine);

        Clear(Item);
        Item.SetRange("No.", 'TEST3');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, PostDate2, '', "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::"Standard Cost - Manufacturing");
        ItemJnlPostBatch.Run(ItemJnlLine);

        WorkDate := PostDate1;

        PostOutput(ProdOrder, 'TEST3', 400);

        WorkDate := PostDate2;

        MFGUtil.FinishProdOrder(ProdOrder."No.");

        INVTUtil.AdjustInvtCost();
        INVTUtil.PostInvtCost(1, '');

        ValidateNetChange('2120', 3, 10);
        ValidateNetChange('2130', 882, 2939.97);
        ValidateNetChange('2140', 87, 290);
        ValidateNetChange('7170', -3, -10);
        ValidateNetChange('7270', -92, -306.64);
    end;

    [Scope('OnPrem')]
    procedure "Test 3"()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test that the cost adjustment does not run in to a never-ending loop.

        INVTUtil.CreateBasisItem('C001', false, Item, Item."Costing Method"::Standard, 0);
        INVTUtil.CreateBasisItem('P001', true, Item, Item."Costing Method"::Standard, 0);

        MFGUtil.InsertPBOMHeader('P001', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'C001', '', 10, true);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);

        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'C001', 19, 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'P001', 2);
        MFGUtil.PostOutput(ProdOrder, 'P001', 1);
        MFGUtil.PostConsump(ProdOrder."No.", 'C001', 10);
        MFGUtil.PostConsump(ProdOrder."No.", 'C001', -1);

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'P001', 1);
        MFGUtil.PostOutput(ProdOrder, 'P001', 1);
        MFGUtil.PostConsump(ProdOrder."No.", 'C001', 10);
        MFGUtil.FinishProdOrder(ProdOrder."No.");

        INVTUtil.AdjustInvtCost();
    end;

    [Scope('OnPrem')]
    procedure CreateItemRtngAndPBOMs()
    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
        WorkCenter: Record "Work Center";
        MachCenter: Record "Machine Center";
        RtngHeader: Record "Routing Header";
    begin
        WorkCenter.Validate("No.", '100');
        WorkCenter.Insert(true);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Unit of Measure Code", 'MINUTES');
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Validate("Gen. Prod. Posting Group", 'MANUFACT');
        WorkCenter.Modify(true);

        MachCenter.Validate("No.", '110');
        MachCenter.Insert(true);
        MachCenter.Validate("Work Center No.", WorkCenter."No.");
        MachCenter.Modify(true);

        CRPUtil.CalcWrkCntrCal(WorkDate() - 100, WorkDate() + 100);

        InsertRtngHeader('TEST3', RtngHeader);
        InsertRntgLine(RtngHeader."No.", '', '10', '', '110');

        INVTUtil.CreateBasisItem('TEST1', false, Item, Item."Costing Method"::Standard, 0.07);
        INVTUtil.CreateBasisItem('TEST2', false, Item, Item."Costing Method"::Standard, 0.11);
        INVTUtil.CreateBasisItem('TEST3', true, Item, Item."Costing Method"::Standard, 0);

        MFGUtil.InsertPBOMHeader('TEST3', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'TEST1', '', 1, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'TEST2', '', 2, false);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);
        CRPUtil.CertifyRtngAndConnectToItem(RtngHeader, Item);

        INVTUtil.CreateBasisItem('TEST4', false, Item, Item."Costing Method"::Standard, 0.13);
        INVTUtil.CreateBasisItem('TEST5', true, Item, Item."Costing Method"::Standard, 0);

        MFGUtil.InsertPBOMHeader('TEST5', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'TEST3', '', 3, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'TEST4', '', 1, false);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);
        CRPUtil.CertifyRtngAndConnectToItem(RtngHeader, Item);
    end;

    local procedure ValidateNetChange(AccountNo: Code[20]; Amount: Decimal; AmountACY: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 %2', GLAccount."No.", GLAccount.Name),
          GLUtil.GetGLBalanceAtDate(AccountNo, WorkDate(), false), Amount);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 %2 (ACY)', GLAccount."No.", GLAccount.Name),
          GLUtil.GetGLBalanceAtDate(AccountNo, WorkDate(), true), AmountACY);
    end;

    local procedure InsertRtngHeader(RtngNo: Code[20]; var RtngHeader: Record "Routing Header")
    begin
        Clear(RtngHeader);
        RtngHeader.Init();
        RtngHeader.Validate("No.", RtngNo);
        RtngHeader.Insert(true);
    end;

    local procedure InsertRntgLine(RtngNo: Code[20]; VersionCode: Code[10]; OperationNo: Code[10]; WorkCenterNo: Code[20]; MachineCenterNo: Code[20])
    var
        RtngLine: Record "Routing Line";
    begin
        Clear(RtngLine);
        RtngLine.Init();
        RtngLine.Validate(RtngLine."Routing No.", RtngNo);
        RtngLine.Validate(RtngLine."Version Code", VersionCode);
        RtngLine.Validate(RtngLine."Operation No.", OperationNo);
        if WorkCenterNo <> '' then begin
            RtngLine.Validate(RtngLine.Type, RtngLine.Type::"Work Center");
            RtngLine.Validate(RtngLine."No.", WorkCenterNo);
        end else begin
            RtngLine.Validate(RtngLine.Type, RtngLine.Type::"Machine Center");
            RtngLine.Validate(RtngLine."No.", MachineCenterNo);
        end;
        RtngLine.Insert(true);
    end;

    local procedure InsertItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Qty: Decimal; UnitAmt: Decimal)
    begin
        INVTUtil.InsertItemJnlLine(ItemJnlLine, EntryType, ItemNo);
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Unit Amount", UnitAmt);
        ItemJnlLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PostOutput(var ProdOrder: Record "Production Order"; ItemNo: Code[20]; OutputQuantity: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        InitOutputJnlLine(ItemJnlLine);
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.Find('-') then
            repeat
                InsertOutputJnlLine(
                  ItemJnlLine, ProdOrder."No.", ItemNo, '10', 0, 0, OutputQuantity,
                  ProdOrderLine."Line No.", ProdOrder."Gen. Prod. Posting Group");
            until ProdOrderLine.Next() = 0;
        ItemJnlPostBatch.Run(ItemJnlLine);
    end;

    local procedure InitOutputJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine."Journal Template Name" := 'OUTPUT';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    local procedure InsertOutputJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; OperationNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; OutputQuantity: Decimal; ProdOrdLineNo: Integer; GenProdPostingGroup: Code[20])
    begin
        ItemJnlLine.LockTable();
        if ItemJnlLine.Find('+') then;
        GLUtil.IncrLineNo(ItemJnlLine."Line No.");
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        ItemJnlLine.Validate("Order Line No.", ProdOrdLineNo);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Operation No.", OperationNo);
        if SetupTime <> 0 then
            ItemJnlLine.Validate("Setup Time", SetupTime);
        if RunTime <> 0 then
            ItemJnlLine.Validate("Run Time", RunTime);
        ItemJnlLine.Validate("Output Quantity", OutputQuantity);
        ItemJnlLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemJnlLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure PostConsumption(ProdOrderNo: Code[20]; PostDate: Date; CalcBasedOn: Option; PickLocCode: Code[20])
    var
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        ProdOrder: Record "Production Order";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        InitConsumpJnlLine(ItemJnlLine);
        CalcConsumption.InitializeRequest(PostDate, CalcBasedOn);
        ProdOrder.SetRange("No.", ProdOrderNo);
        CalcConsumption.SetTableView(ProdOrder);
        CalcConsumption.SetTemplateAndBatchName(
          ItemJnlLine."Journal Template Name",
          ItemJnlLine."Journal Batch Name");
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
        if ItemJnlLine.Find('-') then
            repeat
                ItemJnlLine."Posting Date" := PostDate;
                ItemJnlLine."Location Code" := PickLocCode;
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;
        ItemJnlPostBatch.Run(ItemJnlLine);
    end;

    local procedure InitConsumpJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine."Journal Template Name" := 'CONSUMP';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;
}

