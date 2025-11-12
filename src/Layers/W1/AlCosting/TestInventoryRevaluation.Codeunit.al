codeunit 103541 "Test - Inventory Revaluation"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103541);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        TestFIFO();
        TestAverage();
        TestStandard();
        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        TestscriptMgt: Codeunit TestscriptManagement;
        SRUtil: Codeunit SRUtil;
        PPUtil: Codeunit PPUtil;
        INVTUtil: Codeunit INVTUtil;
        MFGUtil: Codeunit MFGUtil;
        InvdInvtIncr: array[8] of Integer;
        i: Integer;
        CurrTest: Text[30];

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        NoSeries: Record "No. Series";
    begin
        SalesSetup.Get();
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup.Modify();

        PurchSetup.Get();
        PurchSetup."Ext. Doc. No. Mandatory" := false;
        PurchSetup.Modify();

        NoSeries.ModifyAll("Manual Nos.", true);

        InvtSetup.ModifyAll("Average Cost Calc. Type", InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant");

        InvdInvtIncr[1] := 1;
        InvdInvtIncr[2] := 3;
        InvdInvtIncr[3] := 5;
        InvdInvtIncr[4] := 6;
        InvdInvtIncr[5] := 10;
        InvdInvtIncr[6] := 13;
        InvdInvtIncr[7] := 14;
        InvdInvtIncr[8] := 20;
    end;

    [Scope('OnPrem')]
    procedure TestFIFO()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        CurrTest := 'FIFO';

        MakeStandardScenario(Item."Costing Method"::FIFO);
        WorkDate := 20030101D;

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::Item);
        TestAndSetInvtVal(0, 24, 88, 80);
        ItemJnlPostBatch.Run(ItemJnlLine);

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::"Item Ledger Entry");
        for i := 1 to 8 do
            TestAndSetInvtVal(InvdInvtIncr[i], 3, 10, 11);
        ItemJnlPostBatch.Run(ItemJnlLine);

        WorkDate := 20030115D;

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::"Item Ledger Entry");

        TestAndSetInvtVal(InvdInvtIncr[8], 3, 11, 3.67);

        TestItemLedgEntry(InvdInvtIncr[1], 11);
        TestItemLedgEntry(InvdInvtIncr[2], 11);
        TestItemLedgEntry(InvdInvtIncr[3], 11.01);
        TestItemLedgEntry(InvdInvtIncr[4], 11.01);
        TestItemLedgEntry(InvdInvtIncr[5], 11.01);
        TestItemLedgEntry(InvdInvtIncr[6], 11.01);
        TestItemLedgEntry(InvdInvtIncr[7], 11.01);
        TestItemLedgEntry(InvdInvtIncr[8], 11);
    end;

    [Scope('OnPrem')]
    procedure TestAverage()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        CurrTest := 'AVG';

        MakeStandardScenario(Item."Costing Method"::Average);

        WorkDate := 20030101D;

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::Item);
        // The invoiced quantity from the non-invoiced transfer entry affects the unit cost
        // Bug 37027
        // TestAndSetInvtVal(0,24,96,80);
        ItemJnlPostBatch.Run(ItemJnlLine);

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::Item);
        // Bug 37027
        // TestAndSetInvtVal(0,24,84.36,88);
        ItemJnlPostBatch.Run(ItemJnlLine);

        WorkDate := 20030115D;

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::Item);
        // Bug 37027
        // TestAndSetInvtVal(0,3,10.02,22);

        // Bug 37027 - all below
        // TestItemLedgEntry(InvdInvtIncr[1],9.46);
        // TestItemLedgEntry(InvdInvtIncr[2],9.45);
        // TestItemLedgEntry(InvdInvtIncr[3],9.46);
        // TestItemLedgEntry(InvdInvtIncr[4],9.45);
        // TestItemLedgEntry(InvdInvtIncr[5],9.46);
        // TestItemLedgEntry(InvdInvtIncr[6],9.45);
        // TestItemLedgEntry(InvdInvtIncr[7],9.46);
        // TestItemLedgEntry(InvdInvtIncr[8],9.45);
    end;

    [Scope('OnPrem')]
    procedure TestStandard()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        CurrTest := 'STD';

        MakeStandardScenario(Item."Costing Method"::Standard);

        WorkDate := 20030101D;

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::Item);
        TestAndSetInvtVal(0, 36, 120, 88);
        ItemJnlPostBatch.Run(ItemJnlLine);

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::"Item Ledger Entry");
        for i := 1 to 7 do
            if i <> 3 then
                TestAndSetInvtVal(InvdInvtIncr[i], 3, 7.33, 10);
        TestAndSetInvtVal(InvdInvtIncr[3], 3, 7.34, 10);
        TestAndSetInvtVal(InvdInvtIncr[8], 3, 7.34, 10);

        ItemJnlPostBatch.Run(ItemJnlLine);

        WorkDate := 20030115D;

        CalcInvtValAndQty(ItemJnlLine, "Inventory Value Calc. Per"::"Item Ledger Entry");

        TestAndSetInvtVal(InvdInvtIncr[8], 3, 10, 3.33);

        TestItemLedgEntry(InvdInvtIncr[1], 10);
        TestItemLedgEntry(InvdInvtIncr[2], 10);
        TestItemLedgEntry(InvdInvtIncr[3], 9.99);
        TestItemLedgEntry(InvdInvtIncr[4], 9.99);
        TestItemLedgEntry(InvdInvtIncr[5], 9.99);
        TestItemLedgEntry(InvdInvtIncr[6], 9.99);
        TestItemLedgEntry(InvdInvtIncr[7], 9.99);
        TestItemLedgEntry(InvdInvtIncr[8], 10);
    end;

    [Scope('OnPrem')]
    procedure MakeStandardScenario(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        InsertItem('TEST', false, Item, CostingMethod, 3.33333, 10);
        InsertItem('COMP', false, Item, CostingMethod, 0, 0);
        InsertItem('MFG', true, Item, CostingMethod, 0, 0);
        PostInvtIncr();
        PostInvtDecr();
    end;

    [Scope('OnPrem')]
    procedure PostInvtIncr()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        i: Integer;
    begin
        WorkDate := 20030101D;

        // Purchase Order
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '30000');
        InsertPurchLine(PurchHeader, PurchLine, 'TEST', 'BLUE', 3, 3.33333, 3, 3);
        InsertPurchLine(PurchHeader, PurchLine, 'TEST', 'BLUE', 3, 3.33333, 3, 0);
        PPUtil.PostPurchase(PurchHeader, true, true);
        INVTUtil.AdjustInvtCost();

        // Sales Return Order
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '10000');
        InsertSalesLine(SalesHeader, SalesLine, 'TEST', 'BLUE', 3, 3.66666, 3, 3);
        InsertSalesLine(SalesHeader, SalesLine, 'TEST', 'BLUE', 3, 3.66666, 3, 0);
        SRUtil.PostSales(SalesHeader, true, true);
        INVTUtil.AdjustInvtCost();

        // Inventory Adjustments
        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TEST', 'BLUE', 3, 3.66666);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TEST', 'BLUE', -3, 3.66666);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        INVTUtil.AdjustInvtCost();

        // Transfer
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '30000');
        InsertPurchLine(PurchHeader, PurchLine, 'TEST', '', 3, 3.33333, 3, 3);
        InsertPurchLine(PurchHeader, PurchLine, 'TEST', '', 3, 3.33333, 3, 0);
        PPUtil.PostPurchase(PurchHeader, true, true);

        INVTUtil.InitItemJournal(ItemJnlLine);
        for i := 1 to 2 do begin
            InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Transfer, 'TEST', '', 3, 0);
            ItemJnlLine.Validate("New Location Code", 'BLUE');
            ItemJnlLine.Modify(true);
        end;
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        INVTUtil.AdjustInvtCost();

        // Consumption
        MFGUtil.CreateRelProdOrder(ProdOrder, 'INCR_C_FNSHD', 'MFG', 1);
        MFGUtil.CreateRelProdOrder(ProdOrder, 'INCR_C_NON-FNSHD', 'MFG', 1);

        InitConsumpJnlLine(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, 'TEST', 'BLUE', -3, 3.66666);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", 'INCR_C_FNSHD');
        ItemJnlLine.Modify(true);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, 'TEST', 'BLUE', -3, 3.66666);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", 'INCR_C_NON-FNSHD');
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputItemJnlLine(ItemJnlLine, 'INCR_C_FNSHD', 'MFG', 'BLUE', 1);
        InsertOutputItemJnlLine(ItemJnlLine, 'INCR_C_NON-FNSHD', 'MFG', 'BLUE', 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('INCR_C_FNSHD');
        INVTUtil.AdjustInvtCost();

        // Output
        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'COMP', 'BLUE', 2, 10);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'INCR_O_INV', 'TEST', 1);
        MFGUtil.CreateRelProdOrder(ProdOrder, 'INCR_O_NON-INV', 'TEST', 1);

        InitConsumpJnlLine(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, 'COMP', 'BLUE', 1, 0);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", 'INCR_O_INV');
        ItemJnlLine.Modify(true);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, 'COMP', 'BLUE', 1, 0);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", 'INCR_O_NON-INV');
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputItemJnlLine(ItemJnlLine, 'INCR_O_INV', 'TEST', 'BLUE', 3);
        InsertOutputItemJnlLine(ItemJnlLine, 'INCR_O_NON-INV', 'TEST', 'BLUE', 3);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('INCR_O_INV');

        INVTUtil.AdjustInvtCost();
    end;

    [Scope('OnPrem')]
    procedure PostInvtDecr()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        i: Integer;
        INT: Integer;
    begin
        WorkDate := 20030115D;

        // Purchase Return Order
        InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '30000');
        for i := 1 to 3 do begin
            InsertPurchLine(PurchHeader, PurchLine, 'TEST', 'BLUE', 1, 0, 0, 1);
            InsertPurchLine(PurchHeader, PurchLine, 'TEST', 'BLUE', 1, 0, 0, 0);
        end;
        PurchLine.SetRange("Line No.", 10000, 30000);
        PurchLine.ModifyAll("Appl.-to Item Entry", InvdInvtIncr[1]);
        PPUtil.PostPurchase(PurchHeader, true, true);

        // Sales Order
        InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '10000');
        for i := 1 to 3 do begin
            InsertSalesLine(SalesHeader, SalesLine, 'TEST', 'BLUE', 1, 0, 0, 1);
            InsertSalesLine(SalesHeader, SalesLine, 'TEST', 'BLUE', 1, 0, 0, 0);
        end;
        SRUtil.PostSales(SalesHeader, true, true);
        INVTUtil.AdjustInvtCost();

        // Inventory Adjustments
        INVTUtil.InitItemJournal(ItemJnlLine);
        for i := 1 to 3 do begin
            InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'TEST', 'BLUE', -1, 0);
            InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Negative Adjmt.", 'TEST', 'BLUE', 1, 0);
        end;
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        INVTUtil.AdjustInvtCost();

        // Transfer
        INVTUtil.InitItemJournal(ItemJnlLine);
        for i := 1 to 6 do begin
            InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Transfer, 'TEST', 'BLUE', 1, 0);
            ItemJnlLine.Validate("New Location Code", '');
            ItemJnlLine.Modify(true);
        end;
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
        INVTUtil.AdjustInvtCost();

        // Consumption
        MFGUtil.CreateRelProdOrder(ProdOrder, 'DECR_C_INV', 'MFG', 1);
        MFGUtil.CreateRelProdOrder(ProdOrder, 'DECR_C_NON-INV', 'MFG', 1);

        InitConsumpJnlLine(ItemJnlLine);
        for i := 1 to 3 do begin
            InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, 'TEST', 'BLUE', 1, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", 'DECR_C_INV');
            ItemJnlLine.Modify(true);
        end;
        for i := 1 to 3 do begin
            InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, 'TEST', 'BLUE', 1, 0);
            ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.Validate("Order No.", 'DECR_C_NON-INV');
            ItemJnlLine.Modify(true);
        end;
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputItemJnlLine(ItemJnlLine, 'DECR_C_INV', 'MFG', 'BLUE', 1);
        InsertOutputItemJnlLine(ItemJnlLine, 'DECR_C_NON-INV', 'MFG', 'BLUE', 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('DECR_C_INV');
        INVTUtil.AdjustInvtCost();

        // Output
        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", 'COMP', 'BLUE', 2, 10);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.CreateRelProdOrder(ProdOrder, 'DECR_O_INV', 'TEST', 1);
        MFGUtil.CreateRelProdOrder(ProdOrder, 'DECR_O_NON-INV', 'TEST', 1);

        InitConsumpJnlLine(ItemJnlLine);
        InsertConsumpItemJnlLine(ItemJnlLine, 'DECR_O_INV', 'COMP', 'BLUE', 1);
        InsertConsumpItemJnlLine(ItemJnlLine, 'DECR_O_NON-INV', 'COMP', 'BLUE', 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InitOutputJnlLine(ItemJnlLine);
        for i := 1 to 3 do begin
            InsertOutputItemJnlLine(ItemJnlLine, 'DECR_O_INV', 'TEST', '', 2);
            InsertOutputItemJnlLine(ItemJnlLine, 'DECR_O_NON-INV', 'TEST', '', 2);
        end;
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        for i := 1 to 3 do begin
            InsertOutputItemJnlLine(ItemJnlLine, 'DECR_O_INV', 'TEST', 'BLUE', -1);
            InsertOutputItemJnlLine(ItemJnlLine, 'DECR_O_NON-INV', 'TEST', 'BLUE', -1);
        end;

        ItemJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        if ItemJnlLine.Find('-') then begin
            INT := 63;
            repeat
                ItemJnlLine.Validate("Applies-to Entry", INT);
                ItemJnlLine.Modify();
                INT := INT + 1;
            until ItemJnlLine.Next() = 0;
        end;
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        MFGUtil.FinishProdOrder('DECR_O_INV');

        INVTUtil.AdjustInvtCost();
    end;

    [Scope('OnPrem')]
    procedure InsertItem(ItemNo: Code[20]; IsMfgItem: Boolean; var Item: Record Item; CostingMethod: Enum "Costing Method"; StdCost: Decimal; IndirCostPct: Decimal)
    begin
        INVTUtil.CreateBasisItem(ItemNo, IsMfgItem, Item, CostingMethod, 0);
        Item.Validate("Standard Cost", StdCost);
        Item.Validate("Indirect Cost %", IndirCostPct);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, DocType);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
    end;

    local procedure InsertPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemNo: Code[20]; LocCode: Code[10]; Qty: Decimal; DirectUnitCost: Decimal; QtyToRcv: Decimal; QtyToInv: Decimal)
    begin
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", ItemNo);
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Location Code", LocCode);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Validate("Qty. to Receive", QtyToRcv);
        PurchLine.Validate("Qty. to Invoice", QtyToInv);
        PurchLine.Modify(true);
    end;

    local procedure InsertSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20])
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, DocType);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Modify(true);
        Clear(SalesLine);
    end;

    local procedure InsertSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocCode: Code[10]; Qty: Decimal; UnitCostLCY: Decimal; QtyToRcv: Decimal; QtyToInv: Decimal)
    begin
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Location Code", LocCode);
        SalesLine.Validate("Unit Cost (LCY)", UnitCostLCY);
        SalesLine.Validate("Return Qty. to Receive", QtyToRcv);
        SalesLine.Validate("Qty. to Invoice", QtyToInv);
        SalesLine.Modify(true);
    end;

    local procedure InsertItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocCode: Code[10]; Qty: Decimal; UnitCost: Decimal)
    begin
        INVTUtil.InsertItemJnlLine(ItemJnlLine, EntryType, ItemNo);
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate("Location Code", LocCode);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Unit Cost", UnitCost);
        ItemJnlLine.Modify(true);
    end;

    local procedure InitOutputJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine."Journal Template Name" := 'OUTPUT';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    local procedure InsertOutputItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; LocCode: Code[10]; OutputQty: Decimal)
    begin
        ItemJnlLine."Line No." += 10000;
        ItemJnlLine.Init();
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        if not ItemJnlLine.Insert() then
            ItemJnlLine.Modify();
        ItemJnlLine.Validate("Item No.", ItemNo);

        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Document No.", ProdOrderNo);
        ItemJnlLine.Validate("Item No.");  // *** Should be fixed in the application code!
        ItemJnlLine.Validate("Location Code", LocCode);
        ItemJnlLine.Validate("Output Quantity", OutputQty);
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Modify(true);
    end;

    local procedure InitConsumpJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine."Journal Template Name" := 'CONSUMP';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    local procedure InsertConsumpItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; LocCode: Code[10]; Qty: Decimal)
    begin
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::Consumption, ItemNo);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        ItemJnlLine.Validate("Document No.", ProdOrderNo);
        ItemJnlLine.Validate("Item No.");  // *** Should be fixed in the application code!
        ItemJnlLine.Validate("Location Code", LocCode);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CalcInvtValAndQty(var ItemJnlLine: Record "Item Journal Line"; CalculatePer: Enum "Inventory Value Calc. Per")
    var
        Item: Record Item;
    begin
        INVTUtil.AdjustInvtCost();
        Clear(Item);
        Clear(ItemJnlLine);
        Item.SetRange("No.", 'TEST');
        Item.SetRange("Location Filter", 'BLUE');
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        INVTUtil.CreateRevaluationJnlLines(ItemJnlLine, Item, WorkDate(), '', CalculatePer, true, true, false, "Inventory Value Calc. Base"::" ");
    end;

    [Scope('OnPrem')]
    procedure TestAndSetInvtVal(ItemLedgEntryNo: Integer; RevalQty: Decimal; InvtValCalcd: Decimal; InvtValRevald: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Applies-to Entry", ItemLedgEntryNo);
        ItemJnlLine.FindFirst();
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, ItemJnlLine.TableName, ItemLedgEntryNo, ItemJnlLine.FieldName(Quantity)),
          ItemJnlLine.Quantity, RevalQty);
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, ItemJnlLine.TableName, ItemLedgEntryNo, ItemJnlLine.FieldName("Inventory Value (Calculated)")),
          ItemJnlLine."Inventory Value (Calculated)", InvtValCalcd);
        ItemJnlLine.Validate("Inventory Value (Revalued)", InvtValRevald);
        ItemJnlLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure TestItemLedgEntry(EntryNo: Integer; CostAmtAct: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(EntryNo);
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3 %4', CurrTest, ItemLedgEntry.TableName, EntryNo, ItemLedgEntry.FieldName("Cost Amount (Actual)")),
          ItemLedgEntry."Cost Amount (Actual)", CostAmtAct);
    end;
}

