codeunit 103513 "Test - Flushing"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103513);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 1"();
        "Test 2"();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        INVTUtil: Codeunit INVTUtil;
        CRPUtil: Codeunit CRPUtil;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        InvtSetup: Record "Inventory Setup";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        RtngHeader: Record "Routing Header";
        RtngLine: Record "Routing Line";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        WorkDate := 20010125D;

        InvtSetup.ModifyAll("Automatic Cost Posting", true);

        WorkCenter.Validate("No.", '100');
        WorkCenter.Insert(true);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Unit of Measure Code", 'MINUTES');
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Validate("Gen. Prod. Posting Group", 'MANUFACT');
        WorkCenter.Modify(true);

        WorkCenter.Validate("No.", '300');
        WorkCenter.Insert(true);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Unit of Measure Code", 'MINUTES');
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Validate("Gen. Prod. Posting Group", 'MANUFACT');
        WorkCenter.Modify(true);

        CRPUtil.CalcWrkCntrCal(WorkDate() - 100, WorkDate() + 100);

        InsertRtngHeader(RtngHeader, '1');
        InsertRntgLine(RtngLine, RtngHeader."No.", '', '10', '100', '');
        RtngLine.Validate("Routing Link Code", '100');
        RtngLine.Validate("Run Time", 30);
        RtngLine.Modify(true);
        InsertRntgLine(RtngLine, RtngHeader."No.", '', '20', '300', '');
        RtngLine.Validate("Routing Link Code", '100');
        RtngLine.Validate("Run Time", 60);
        RtngLine.Modify(true);

        INVTUtil.CreateBasisItem('1120', false, Item, Item."Costing Method"::Standard, 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);

        INVTUtil.CreateBasisItem('1155', false, Item, Item."Costing Method"::Standard, 2);
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);

        INVTUtil.InitItemJournal(ItemJnlLine);
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", '1120');
        ItemJnlLine.Validate(Quantity, 100);
        ItemJnlLine.Modify(true);
        INVTUtil.InsertItemJnlLine(ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", '1155');
        ItemJnlLine.Validate(Quantity, 100);
        ItemJnlLine.Modify(true);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);

        InsertPBOMHeader('1', ProdBOMHeader);
        InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '1120', '', 2, true);
        InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '1155', '', 1, false);
        ProdBOMComponent.Validate("Routing Link Code", '100');
        ProdBOMComponent.Modify(true);

        InsertItem('1', true, Item, Item."Costing Method"::FIFO, 0);
        CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);
        CertifyRtngAndConnectToItem(RtngHeader, Item);

        InsertRtngHeader(RtngHeader, '2');
        InsertRntgLine(RtngLine, RtngHeader."No.", '', '10', '100', '');

        InsertItem('2', true, Item, Item."Costing Method"::Standard, 10);
        CertifyRtngAndConnectToItem(RtngHeader, Item);
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        ProdOrder: Record "Production Order";
    begin
        ReleaseProdOrder(ProdOrder, '1', 5, 1);
        ReleaseProdOrder(ProdOrder, '1', 5, 1);
        FinishAllProdOrders();
    end;

    [Scope('OnPrem')]
    procedure "Test 2"()
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        ReleaseProdOrder(ProdOrder, '2', 2, 1);

        ProdOrder.Find('+');
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.FindFirst();

        InitOutputJnlLine(ItemJnlLine);
        InsertOutputJnlLine(
          ItemJnlLine, ProdOrder."No.", '2', '10', 0, 1, 1,
          ProdOrderLine."Line No.", ProdOrder."Gen. Prod. Posting Group");
        InsertOutputJnlLine(
          ItemJnlLine, ProdOrder."No.", '2', '10', 0, 1, 1,
          ProdOrderLine."Line No.", ProdOrder."Gen. Prod. Posting Group");
        ItemJnlPostBatch.Run(ItemJnlLine);
    end;

    local procedure InsertRtngHeader(var RtngHeader: Record "Routing Header"; RtngNo: Code[20])
    begin
        Clear(RtngHeader);
        RtngHeader.Init();
        RtngHeader.Validate("No.", RtngNo);
        RtngHeader.Insert(true);
    end;

    local procedure InsertRntgLine(var RtngLine: Record "Routing Line"; RtngNo: Code[20]; VersionCode: Code[10]; OperationNo: Code[10]; WorkCenterNo: Code[20]; MachineCenterNo: Code[20])
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

    local procedure FinishAllProdOrders()
    var
        ProdOrder: Record "Production Order";
        ProdOrder2: Record "Production Order";
    begin
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        if ProdOrder.Find('-') then
            repeat
                ProdOrder2 := ProdOrder;
                LibraryManufacturing.ChangeProdOrderStatus(ProdOrder2, ProdOrder.Status::Finished, WorkDate(), false);
            until ProdOrder.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertPBOMHeader(PBOMNo: Code[20]; var ProdBOMHeader: Record "Production BOM Header")
    begin
        Clear(ProdBOMHeader);
        ProdBOMHeader.Init();
        ProdBOMHeader.Validate("No.", PBOMNo);
        ProdBOMHeader.Insert(true);
        ProdBOMHeader.Validate("Unit of Measure Code", 'PCS');
        ProdBOMHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPBOMComponent(var ProdBOMComponent: Record "Production BOM Line"; ProdBOMNo: Code[20]; VersionCode: Code[20]; StartingDate: Date; ItemNo: Code[20]; PhantomBOMNo: Code[20]; QtyPer: Decimal; IsFirstLine: Boolean)
    begin
        if IsFirstLine then
            Clear(ProdBOMComponent);
        ProdBOMComponent.Init();
        ProdBOMComponent."Production BOM No." := ProdBOMNo;
        ProdBOMComponent."Version Code" := VersionCode;
        ProdBOMComponent."Starting Date" := StartingDate;
        IncrLineNo(ProdBOMComponent."Line No.");
        ProdBOMComponent.Insert(true);
        if ItemNo <> '' then begin
            ProdBOMComponent.Validate(Type, ProdBOMComponent.Type::Item);
            ProdBOMComponent.Validate("No.", ItemNo);
        end else begin
            ProdBOMComponent.Validate(Type, ProdBOMComponent.Type::"Production BOM");
            ProdBOMComponent.Validate("No.", PhantomBOMNo);
        end;
        ProdBOMComponent.Validate("Quantity per", QtyPer);
        ProdBOMComponent.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CertifyPBOMAndConnectToItem(var ProdBOMHeader: Record "Production BOM Header"; var Item: Record Item)
    begin
        ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
        ProdBOMHeader.Modify(true);
        Item.Validate("Production BOM No.", ProdBOMHeader."No.");
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CertifyRtngAndConnectToItem(var RtngHeader: Record "Routing Header"; var Item: Record Item)
    begin
        RtngHeader.Validate(Status, RtngHeader.Status::Certified);
        RtngHeader.Modify(true);
        Item.Validate("Routing No.", RtngHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProdOrder(var ProdOrder: Record "Production Order"; ItemNo: Code[1]; OutputQuantity: Decimal)
    begin
        Clear(ProdOrder);
        ProdOrder.Init();
        ProdOrder.Status := ProdOrder.Status::Released;
        ProdOrder.Insert(true);
        ProdOrder.Validate("Source Type", ProdOrder."Source Type"::Item);
        ProdOrder.Validate("Source No.", ItemNo);
        ProdOrder.Validate(Quantity, OutputQuantity);
        ProdOrder.Modify(true);
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange("No.", ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        REPORT.RunModal(REPORT::"Refresh Production Order", false, true, ProdOrder);
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
    end;

    local procedure CreateProdOrderLine(ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; Quantity: Decimal; IsFirstLine: Boolean)
    begin
        if IsFirstLine then
            Clear(ProdOrderLine);
        ProdOrderLine.Init();
        ProdOrderLine.Status := ProdOrder.Status;
        ProdOrderLine."Prod. Order No." := ProdOrder."No.";
        IncrLineNo(ProdOrderLine."Line No.");
        ProdOrderLine.Insert(true);
        ProdOrderLine.Validate("Item No.", ItemNo);
        ProdOrderLine.Validate(Quantity, Quantity);
        ProdOrderLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ReleaseProdOrder(var ProdOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; NoOfLinePerProdOrder: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
        i: Integer;
    begin
        CreateProdOrder(ProdOrder, ItemNo, Quantity);
        if NoOfLinePerProdOrder > 1 then begin
            ProdOrderLine.SetRange(Status, ProdOrder.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
            ProdOrderLine.DeleteAll(true);
            for i := 1 to NoOfLinePerProdOrder do
                CreateProdOrderLine(ProdOrder, ProdOrderLine, ItemNo, Quantity, i = 1);
            CalcRoutingsAndComponents(ProdOrder);
        end;
    end;

    local procedure CalcRoutingsAndComponents(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        CalcProdOrder: Codeunit "Calculate Prod. Order";
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.Find('-') then
            repeat
                ProdOrderLine."Due Date" := ProdOrder."Due Date";
                ProdOrderLine."Ending Date" := ProdOrder."Due Date";
                CalcProdOrder.Calculate(ProdOrderLine, 1, true, true, false, true);
            until ProdOrderLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertItem(ItemNo: Code[20]; IsMfgItem: Boolean; var Item: Record Item; CostingMethod: Enum "Costing Method"; StandardCost: Decimal)
    begin
        if Item.Get(ItemNo) then
            exit;
        Clear(Item);
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        InsertItemUOM(Item."No.", 'PCS', 1);
        Item.Validate("Base Unit of Measure", 'PCS');

        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Rounding Precision", 0.00001);
        Item.Validate("Standard Cost", StandardCost);
        Item.Validate("Unit Cost", StandardCost);
        if IsMfgItem then begin
            Item."Inventory Posting Group" := 'FINISHED';
            Item."Gen. Prod. Posting Group" := 'RETAIL';
            Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        end else begin
            Item."Inventory Posting Group" := 'RAW MAT';
            Item."Gen. Prod. Posting Group" := 'RAW MAT';
        end;
        Item."VAT Prod. Posting Group" := 'VAT25';
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertItemUOM(ItemNo: Code[20]; UOMCode: Code[20]; BaseQtyPerUOM: Decimal)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, UOMCode);
        if UnitOfMeasure.Insert(true) then;

        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.Validate("Item No.", ItemNo);
        ItemUnitOfMeasure.Validate(Code, UOMCode);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", BaseQtyPerUOM);
        ItemUnitOfMeasure.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure IncrLineNo(var LineNo: Integer)
    begin
        LineNo := LineNo + 10000;
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
        IncrLineNo(ItemJnlLine."Line No.");
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
}

