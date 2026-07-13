codeunit 103028 MFGUtil
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    var
        GLUtil: Codeunit GLUtil;

    [Scope('OnPrem')]
    procedure CertifyPBOM(PBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if VersionCode = '' then begin
            ProdBOMHeader.Get(PBOMNo);
            ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
            ProdBOMHeader.Modify(true);
        end else begin
            ProdBOMVersion.Get(PBOMNo, VersionCode);
            ProdBOMVersion.Validate(Status, ProdBOMHeader.Status::Certified);
            ProdBOMVersion.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UncertifyPBOM(PBOMNo: Code[20]; VersionCode: Code[20])
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if VersionCode = '' then begin
            ProdBOMHeader.Get(PBOMNo);
            ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::New);
            ProdBOMHeader.Modify(true);
        end else begin
            ProdBOMVersion.Get(PBOMNo, VersionCode);
            ProdBOMVersion.Validate(Status, ProdBOMHeader.Status::New);
            ProdBOMVersion.Modify(true);
        end;
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
    procedure InsertPBOMVersion(PBOMNo: Code[20]; VersionCode: Code[20]; StartingDate: Date; UOMCode: Code[20]; var ProdBOMVersion: Record "Production BOM Version")
    begin
        Clear(ProdBOMVersion);
        ProdBOMVersion.Init();
        ProdBOMVersion.Validate("Production BOM No.", PBOMNo);
        ProdBOMVersion.Validate("Version Code", VersionCode);
        ProdBOMVersion.Insert(true);
        ProdBOMVersion.Validate("Starting Date", StartingDate);
        ProdBOMVersion.Validate("Unit of Measure Code", UOMCode);
        ProdBOMVersion.Modify(true);
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
        GLUtil.IncrLineNo(ProdBOMComponent."Line No.");
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
                  ItemJnlLine, ProdOrder."No.", ItemNo, '', 0, 0, OutputQuantity,
                  ProdOrderLine."Line No.", ProdOrder."Gen. Prod. Posting Group");
            until ProdOrderLine.Next() = 0;
        ItemJnlPostBatch.Run(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PostConsump(ProdOrderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        InitConsumpJnlLine(ItemJnlLine);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Insert(true);
        ItemJnlPostBatch.Run(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CalcAndPostConsump(PostDate: Date; CalcBasedOn: Option; PickLocCode: Code[20])
    var
        ItemJnlLine: Record "Item Journal Line";
        CalcConsumption: Report "Calc. Consumption";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        InitConsumpJnlLine(ItemJnlLine);
        CalcConsumption.InitializeRequest(PostDate, CalcBasedOn);
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

    [Scope('OnPrem')]
    procedure FinishProdOrder(ProdOrderNo: Code[20])
    var
        ProdOrder: Record "Production Order";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrderNo);
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProdOrder, ProdOrder.Status::Finished, WorkDate(), false);
    end;

    [Scope('OnPrem')]
    procedure CreateRelProdOrder(var ProdOrder: Record "Production Order"; ProdOrderNo: Code[20]; ItemNo: Code[20]; OutputQuantity: Decimal)
    begin
        Clear(ProdOrder);
        ProdOrder.Init();
        ProdOrder.Status := ProdOrder.Status::Released;
        ProdOrder.Validate("No.", ProdOrderNo);
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

    local procedure InitConsumpJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.DeleteAll();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine."Journal Template Name" := 'CONSUMP';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;
}

