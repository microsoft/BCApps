codeunit 103518 "Test - Avg. Cost Calc. Type"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103518);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 1"();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        INVTUtil: Codeunit INVTUtil;
        MFGUtil: Codeunit MFGUtil;
        ShowScriptResult: Boolean;

    local procedure SetPreconditions()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        WorkDate := 20010101D;

        INVTUtil.CreateBasisItem('AVG-TEST', false, Item, Item."Costing Method"::Average, 0);
        ItemVariant.Init();
        ItemVariant.Validate("Item No.", Item."No.");
        ItemVariant.Validate(Code, 'GOLD');
        ItemVariant.Insert(true);

        INVTUtil.CreateBasisItem('AVG-TEST-MFG', true, Item, Item."Costing Method"::Average, 0);
        MFGUtil.InsertPBOMHeader(Item."No.", ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'AVG-TEST', '', 2, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, 'AVG-TEST', '', 1, false);
        ProdBOMComponent.Validate("Variant Code", 'GOLD');
        ProdBOMComponent.Modify(true);
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        ProdOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        CostingTestScriptMgmt: Codeunit _TestscriptManagement;
    begin
        PostItemJnlLine(ItemJnlLine."Entry Type"::Purchase, 'AVG-TEST', '', 'BLUE', 1, 10);
        PostItemJnlLine(ItemJnlLine."Entry Type"::Purchase, 'AVG-TEST', '', 'BLUE', 1, 20);
        PostItemJnlLine(ItemJnlLine."Entry Type"::Purchase, 'AVG-TEST', '', 'BLUE', 1, 300);
        PostItemJnlLine(ItemJnlLine."Entry Type"::Purchase, 'AVG-TEST', 'GOLD', 'BLUE', 1, 100);
        PostItemJnlLine(ItemJnlLine."Entry Type"::Purchase, 'AVG-TEST', 'GOLD', 'BLUE', 1, 200);
        PostItemJnlLine(ItemJnlLine."Entry Type"::Sale, 'AVG-TEST', '', 'BLUE', 1, 200);
        PostItemJnlLine(ItemJnlLine."Entry Type"::Sale, 'AVG-TEST', 'GOLD', 'BLUE', 1, 200);

        MFGUtil.CreateRelProdOrder(ProdOrder, '', 'AVG-TEST-MFG', 1);
        MFGUtil.PostOutput(ProdOrder, 'AVG-TEST-MFG', 1);
        MFGUtil.CalcAndPostConsump(WorkDate(), 0, 'BLUE');
        MFGUtil.FinishProdOrder(ProdOrder."No.");

        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        INVTUtil.AdjustAndPostItemLedgEntries(true, false);
        ValidateItemLedgEntries(true);

        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::"Item & Location & Variant");
        INVTUtil.AdjustAndPostItemLedgEntries(true, false);
        ValidateItemLedgEntries(false);

        CostingTestScriptMgmt.SetAverageCostCalcType("Average Cost Calculation Type"::Item);
        INVTUtil.AdjustAndPostItemLedgEntries(true, false);
        ValidateItemLedgEntries(true);
    end;

    [Scope('OnPrem')]
    procedure PostItemJnlLine(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[20]; Qty: Decimal; UnitAmount: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlLine.Validate("Entry Type", EntryType);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Document No.", ItemNo);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Variant Code", VariantCode);
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Unit Amount", UnitAmount);
        ItemJnlPostLine.Run(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ValidateItemLedgEntries(TypeIsItem: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", 'AVG-TEST');
        ItemLedgEntry.FindFirst();
        if TypeIsItem then begin
            ValidateItemLedgEntry(ItemLedgEntry, 10);
            ValidateItemLedgEntry(ItemLedgEntry, 20);
            ValidateItemLedgEntry(ItemLedgEntry, 300);
            ValidateItemLedgEntry(ItemLedgEntry, 100);
            ValidateItemLedgEntry(ItemLedgEntry, 200);
            ValidateItemLedgEntry(ItemLedgEntry, -126);
            ValidateItemLedgEntry(ItemLedgEntry, -126);
            ValidateItemLedgEntry(ItemLedgEntry, -252);
            ValidateItemLedgEntry(ItemLedgEntry, -126);
        end else begin
            ValidateItemLedgEntry(ItemLedgEntry, 10);
            ValidateItemLedgEntry(ItemLedgEntry, 20);
            ValidateItemLedgEntry(ItemLedgEntry, 300);
            ValidateItemLedgEntry(ItemLedgEntry, 100);
            ValidateItemLedgEntry(ItemLedgEntry, 200);
            ValidateItemLedgEntry(ItemLedgEntry, -110);
            ValidateItemLedgEntry(ItemLedgEntry, -150);
            ValidateItemLedgEntry(ItemLedgEntry, -220);
            ValidateItemLedgEntry(ItemLedgEntry, -150);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; ExpectedActCostAmt: Decimal)
    begin
        ItemLedgEntry.CalcFields("Cost Amount (Actual)");
        TestscriptMgt.TestNumberValue(ItemLedgEntry.FieldName("Cost Amount (Actual)"), ItemLedgEntry."Cost Amount (Actual)", ExpectedActCostAmt);
        ItemLedgEntry.Next();
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult;
    end;
}

