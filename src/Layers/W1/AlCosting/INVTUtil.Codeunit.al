codeunit 103026 INVTUtil
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure InsertItem(var Item: Record Item; ItemNo: Code[20])
    begin
        Clear(Item);
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertItemVariant(ItemNo: Code[20]; VariantCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Validate("Item No.", ItemNo);
        ItemVariant.Validate(Code, VariantCode);
        ItemVariant.Insert(true);
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
    procedure InsertItemDiscGrp(GroupCode: Code[10])
    var
        ItemDiscGrp: Record "Item Discount Group";
    begin
        ItemDiscGrp.Init();
        ItemDiscGrp.Validate(Code, GroupCode);
        ItemDiscGrp.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CalcStandardCost(ItemNoFilter: Code[250])
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        CalcStdCost: Codeunit "Calculate Standard Cost";
    begin
        Item.SetFilter("No.", ItemNoFilter);
        CalcStdCost.SetProperties(WorkDate(), true, false, false, '', true);
        CalcStdCost.CalcItems(Item, TempItem);

        if TempItem.Find('-') then
            repeat
                Item := TempItem;
                Item.Modify();
            until TempItem.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateBasisItem(ItemNo: Code[20]; IsMfgItem: Boolean; var Item: Record Item; CostingMethod: Enum "Costing Method"; UnitCost: Decimal)
    begin
        if Item.Get(ItemNo) then
            exit;

        InsertItem(Item, ItemNo);

        InsertItemUOM(Item."No.", 'PCS', 1);
        Item.Validate("Base Unit of Measure", 'PCS');

        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Rounding Precision", 0.00001);
        Item.Validate("Unit Cost", UnitCost);
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
    procedure CreateRevaluationJnlLines(ItemJnlLine: Record "Item Journal Line"; var Item: Record Item; PostingDate: Date; DocNo: Code[20]; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; UpdStdCost: Boolean; ReCalcStdCost: Enum "Inventory Value Calc. Base")
    var
        CalcInvtValue: Report "Calculate Inventory Value";
    begin
        ItemJnlLine.DeleteAll();
        CalcInvtValue.SetItemJnlLine(ItemJnlLine);
        CalcInvtValue.SetTableView(Item);
        CalcInvtValue.SetParameters(PostingDate, DocNo, true, CalculatePer, ByLocation, ByVariant, UpdStdCost, ReCalcStdCost, true);
        CalcInvtValue.UseRequestPage(false);
        CalcInvtValue.RunModal();
    end;

    [Scope('OnPrem')]
    procedure AdjustAndPostItemLedgEntries(Adjust: Boolean; Post: Boolean)
    begin
        if Adjust then
            AdjustInvtCost();
        if Post then
            PostInvtCost(1, '');
    end;

    [Scope('OnPrem')]
    procedure AdjustInvtCost()
    var
        Item: Record Item;
        InvSetup: Record "Inventory Setup";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        PostToGL: Boolean;
    begin
        InvSetup.FindFirst();
        PostToGL := InvSetup."Automatic Cost Posting";
        InvtAdjmt.SetProperties(false, PostToGL);
        InvtAdjmt.SetFilterItem(Item);
        InvtAdjmt.MakeMultiLevelAdjmt();
    end;

    [Scope('OnPrem')]
    procedure PostInvtCost(PostMethod: Option; DocNo: Code[20])
    var
        "Post Inventory Cost to G/L": Report "Post Inventory Cost to G/L";
        TestScriptMgmt: Codeunit _TestscriptManagement;
    begin
        "Post Inventory Cost to G/L".UseRequestPage(false);
        "Post Inventory Cost to G/L".InitializeRequest(PostMethod, DocNo, true);
        "Post Inventory Cost to G/L".SaveAsPdf(TestScriptMgmt.GetTestResultsPath() + '\1.pdf');
    end;

    [Scope('OnPrem')]
    procedure InitItemJournal(var ItemJnlLine: Record "Item Journal Line")
    begin
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'ITEM';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    [Scope('OnPrem')]
    procedure InsertItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        Commit();

        ItemJnlLine."Line No." += 10000;
        ItemJnlLine.Init();
        ItemJnlLine.SetUpNewLine(ItemJnlLine);
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Entry Type", EntryType);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InitItemRevalJnl(var ItemJnlLine: Record "Item Journal Line")
    begin
        Clear(ItemJnlLine);
        ItemJnlLine."Journal Template Name" := 'REVAL';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
    end;

    [Scope('OnPrem')]
    procedure InsertRevalJnlLine(var ItemJnlLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer; UnitCostRevalued: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        Commit();

        ItemJnlLine."Line No." += 10000;
        ItemJnlLine.Init();
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::Revaluation;
        ItemJnlLine.SetUpNewLine(ItemJnlLine);

        ItemLedgEntry.Get(ItemLedgEntryNo);

        ItemJnlLine.Validate("Item No.", ItemLedgEntry."Item No.");
        ItemJnlLine.Validate("Applies-to Entry", ItemLedgEntry."Entry No.");
        ItemJnlLine.Validate("Unit Cost (Revalued)", UnitCostRevalued);
        ItemJnlLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ItemJnlPostBatch(ItemJnlLine: Record "Item Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJnlLine);

        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        ItemJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure GetLastItemLedgEntryNo(): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgEntry.FindLast() then;
        exit(ItemLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure GetLastValueEntryNo(): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        if ValueEntry.FindLast() then;
        exit(ValueEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure InsertTransHeader(var TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line")
    begin
        Clear(TransHeader);
        Clear(TransLine);
        TransHeader.Init();
        TransHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTransLine(TransHeader: Record "Transfer Header"; var TransLine: Record "Transfer Line")
    var
        GLUtil: Codeunit GLUtil;
    begin
        TransLine.Init();
        TransLine."Document No." := TransHeader."No.";
        GLUtil.IncrLineNo(TransLine."Line No.");
        TransLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure PostTransOrder(TransHeader: Record "Transfer Header"; Ship: Boolean; Receive: Boolean)
    var
        PostTransShip: Codeunit "TransferOrder-Post Shipment";
        PostTransRcv: Codeunit "TransferOrder-Post Receipt";
    begin
        if Ship then begin
            TransHeader.Find();
            PostTransShip.Run(TransHeader)
        end;

        PostTransRcv.SetHideValidationDialog(true);

        if Receive then begin
            TransHeader.Find();
            PostTransRcv.Run(TransHeader);
        end;
    end;
}

