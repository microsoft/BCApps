codeunit 119074 "Post Output Mfg. Order"
{

    trigger OnRun()
    begin
        InitOutputJnl();
        PostOutput('1011001', 19030908D);
        PostOutput('1011002', 19030909D);
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        CA: Codeunit "Make Adjustments";
        JnlTemplateName: Code[20];
        JnlBatchName: Code[20];
        PostingDate: Date;
        XProdOrder: Label 'ProdOrder';
        XProdOrderJournal: Label 'Prod. Order Journal';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournal: Label 'Default Journal';

    procedure InitOutputJnl()
    begin
        Clear(ItemJnlPostLine);

        ItemJnlTemplate.Reset();
        ItemJnlTemplate.SetRange(Recurring, false);
        ItemJnlTemplate.SetRange(Type, ItemJnlTemplate.Type::Output);
        if not ItemJnlTemplate.FindFirst() then begin
            ItemJnlTemplate.Init();
            ItemJnlTemplate.Validate(Type, ItemJnlTemplate.Type::Output);
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

    procedure PostOutput(MfgOrderNo: Code[20]; PostDate: Date)
    begin
        PostingDate := CA.AdjustDate(PostDate);

        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", MfgOrderNo);
        ProdOrderLine.SetFilter("Remaining Quantity", '<>0');

        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", MfgOrderNo);

        if ProdOrderLine.Find('-') then
            repeat
                ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                if ProdOrderRoutingLine.Find('-') then
                    repeat
                        CreateOutputJnlLine();
                        ItemJnlPostLine.Run(ItemJnlLine);
                    until ProdOrderRoutingLine.Next() = 0;
            until ProdOrderLine.Next() = 0;
    end;

    procedure CreateOutputJnlLine()
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := JnlTemplateName;
        ItemJnlLine."Journal Batch Name" := JnlBatchName;
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ItemJnlLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        ItemJnlLine."Document No." := ProdOrderRoutingLine."Prod. Order No.";
        ItemJnlLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");
        ItemJnlLine.Validate(
          "Run Time",
          ProdOrderLine."Remaining Quantity" *
          ProdOrderRoutingLine."Run Time" + ProdOrderRoutingLine."Setup Time");
        ItemJnlLine.Validate("Output Quantity",
          (1 + ProdOrderRoutingLine."Scrap Factor % (Accumulated)") *
          ProdOrderLine."Remaining Quantity" +
          ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)");
        ItemJnlLine.Finished := true;
    end;
}

