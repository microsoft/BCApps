codeunit 101850 "Post Revaluation"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InvtAdjustment.SetProperties(false, false);
        InvtAdjustment.MakeMultiLevelAdjmt();
        Clear(InvtAdjustment);
        FillRevalJnl();

        ItemJnlLine.SetRange("Journal Template Name", XREVAL);
        ItemJnlLine.SetRange("Journal Batch Name", XDEFAULT);
        if ItemJnlLine.Find('-') then
            repeat
                DepreciateItem();
            until ItemJnlLine.Next() = 0;

        ItemJnlPost.Run(ItemJnlLine);
        Clear(Item);
        InvtAdjustment.SetProperties(false, false);
        InvtAdjustment.MakeMultiLevelAdjmt();
        Clear(InvtAdjustment);
        PostCostToGL();
    end;

    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        ItemJnlBatch: Record "Item Journal Batch";
        DemoDataSetup: Record "Demo Data Setup";
        CalcInvtValue: Report "Calculate Inventory Value";
        PostInvtCostToGL: Report "Post Inventory Cost to G/L";
        InvtAdjustment: Codeunit "Inventory Adjustment";
        ItemJnlPost: Codeunit "Item Jnl.-Post Batch";
        XREVAL: Label 'REVAL';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournal: Label 'Default Journal';

    procedure FillRevalJnl()
    begin
        ItemJnlBatch.Init();
        ItemJnlBatch."Journal Template Name" := XREVAL;
        ItemJnlBatch.SetupNewBatch();
        ItemJnlBatch.Name := XDEFAULT;
        ItemJnlBatch.Description := XDefaultJournal;
        ItemJnlBatch.Insert(true);

        ItemJnlLine."Journal Template Name" := XREVAL;
        ItemJnlLine."Journal Batch Name" := XDEFAULT;

        Item.SetRange("No.", '1900');

        CalcInvtValue.SetParameters(
            DMY2Date(31, 12, DemoDataSetup."Starting Year"), '', true, "Inventory Value Calc. Per"::Item,
            false, false, false, "Inventory Value Calc. Base"::" ", true);
        CalcInvtValue.SetItemJnlLine(ItemJnlLine);
        CalcInvtValue.SetTableView(Item);
        CalcInvtValue.UseRequestPage(false);
        CalcInvtValue.RunModal();
    end;

    procedure DepreciateItem()
    begin
        CalcNewUnitCost(ItemJnlLine."Inventory Value (Calculated)", ItemJnlLine."Inventory Value (Revalued)");
        ItemJnlLine.Validate("Inventory Value (Revalued)");
        ItemJnlLine.Modify();
    end;

    procedure CalcNewUnitCost(OldAmount: Decimal; var NewAmount: Decimal)
    begin
        NewAmount := OldAmount - Round(OldAmount * 0.05, 0.01);
    end;

    procedure PostCostToGL()
    begin
        ValueEntry.SetRange("Posting Date", 0D, DMY2Date(31, 12, DemoDataSetup."Starting Year"));
        PostInvtCostToGL.InitializeRequest(0, 'ADJ00003', true);
        PostInvtCostToGL.SetTableView(ValueEntry);
        PostInvtCostToGL.UseRequestPage(false);
        PostInvtCostToGL.SaveAsPdf(TemporaryPath + Format(CreateGuid()) + '.pdf');
    end;
}

