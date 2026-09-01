codeunit 119073 "Post Consumption Mfg. Order"
{

    trigger OnRun()
    begin
        InitConsumpJnl();
        PostConsumption('1011001', 19030908D);
        PostConsumption('1011002', 19030909D);
        PostConsumption('1011003', 19030910D);
    end;

    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        CA: Codeunit "Make Adjustments";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        JnlTemplateName: Code[20];
        JnlBatchName: Code[20];
        NeededQty: Decimal;
        PostingDate: Date;
        XProdOrder: Label 'ProdOrder';
        XProdOrderJournal: Label 'Prod. Order Journal';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournal: Label 'Default Journal';

    procedure InitConsumpJnl()
    begin
        Clear(ItemJnlPostLine);

        ItemJnlTemplate.Reset();
        ItemJnlTemplate.SetRange(Recurring, false);
        ItemJnlTemplate.SetRange(Type, ItemJnlTemplate.Type::Consumption);
        if not ItemJnlTemplate.FindFirst() then begin
            ItemJnlTemplate.Init();
            ItemJnlTemplate.Validate(Type, ItemJnlTemplate.Type::Consumption);
            ItemJnlTemplate.Name := XProdOrder;
            ItemJnlTemplate.Description := XProdOrderJournal;
            ItemJnlTemplate.Validate("Page ID");
            ItemJnlTemplate.Insert();
        end;
        JnlTemplateName := ItemJnlTemplate.Name;

        ItemJnlBatch.SetRange("Journal Template Name", JnlTemplateName);
        if not ItemJnlBatch.FindFirst() then begin
            ItemJnlBatch.Init();
            ItemJnlBatch."Journal Template Name" := ItemJnlTemplate.Name;
            ItemJnlBatch.SetupNewBatch();
            ItemJnlBatch.Name := XDEFAULT;
            ItemJnlBatch.Description := XDefaultJournal;
            ItemJnlBatch."Reason Code" := ItemJnlTemplate."Reason Code";
            ItemJnlBatch.Insert();
        end;
        JnlBatchName := ItemJnlBatch.Name;
    end;

    procedure PostConsumption(MfgOrderNo: Code[20]; PostDate: Date)
    begin
        PostingDate := CA.AdjustDate(PostDate);

        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", MfgOrderNo);
        if ProdOrderComponent.Find('-') then
            repeat
                Item.Get(ProdOrderComponent."Item No.");
                ProdOrderLine.Get(
                  ProdOrderComponent.Status,
                  ProdOrderComponent."Prod. Order No.",
                  ProdOrderComponent."Prod. Order Line No.");
                NeededQty := ProdOrderComponent.GetNeededQty(1, true);  // Consumption based on expected
                if NeededQty <> 0 then
                    CreateConsumpJnlLine(
                      ProdOrderComponent."Location Code",
                      ProdOrderComponent."Bin Code", NeededQty);
                ItemJnlPostLine.Run(ItemJnlLine);
            until ProdOrderComponent.Next() = 0;
    end;

    procedure CreateConsumpJnlLine(LocationCode: Code[10]; BinCode: Code[20]; QtyToPost: Decimal)
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := JnlTemplateName;
        ItemJnlLine."Journal Batch Name" := JnlBatchName;
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Order No.", ProdOrderComponent."Prod. Order No.");
        ItemJnlLine.Validate("Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemJnlLine."Document No." := ProdOrderComponent."Prod. Order No.";
        ItemJnlLine.Validate("Source Type", ItemJnlLine."Source Type"::Item);
        ItemJnlLine.Validate("Source No.", ProdOrderLine."Item No.");
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate("Item No.", ProdOrderComponent."Item No.");
        ItemJnlLine.Validate("Unit of Measure Code", ProdOrderComponent."Unit of Measure Code");
        ItemJnlLine.Description := ProdOrderComponent.Description;
        ItemJnlLine.Validate(Quantity, QtyToPost * ProdOrderComponent."Qty. per Unit of Measure");
        ItemJnlLine."Unit Cost" := ProdOrderComponent."Unit Cost";
        ItemJnlLine."Location Code" := LocationCode;
        ItemJnlLine."Bin Code" := BinCode;
        ItemJnlLine."Variant Code" := ProdOrderComponent."Variant Code";
    end;
}

