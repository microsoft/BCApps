codeunit 103202 "Test Data - Date Compression"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        TestscriptMgt.InitializeOutput(103519);
        SetPreconditions();
        "Test 1"();

        TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        INVTUtil: Codeunit INVTUtil;

    local procedure SetPreconditions()
    var
        Item: Record Item;
    begin
        INVTUtil.CreateBasisItem('AVG', false, Item, Item."Costing Method"::Average, 0);
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        i: Integer;
    begin
        WorkDate := 19990101D;

        for i := 1 to 365 do begin
            PostEntries();
            PostEntries();
            WorkDate := CalcDate('<+1D>', WorkDate());
        end;

        INVTUtil.AdjustAndPostItemLedgEntries(true, false);
        ClearAppldEntryToAdjForConsump('AVG');
        SetCompletelyInvoicedForOutput('AVG');
        Commit();
        // "Date Compress Item Ledger".RunModal();
    end;

    [Scope('OnPrem')]
    procedure PostEntries()
    var
        ValueEntry: Record "Value Entry";
        LastEntry: Integer;
    begin
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", true, 0);
        LastEntry := FindLastItemLedgEntryNo();
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Indirect Cost", ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::Purchase, false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false, LastEntry);

        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false, 0);
        LastEntry := FindLastItemLedgEntryNo();
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false, LastEntry);

        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", true, 0);
        LastEntry := FindLastItemLedgEntryNo();
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false, LastEntry);

        PostItemJnl(ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false, 0);
        LastEntry := FindLastItemLedgEntryNo();
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false, LastEntry);

        PostItemJnl(ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false, 0);
        LastEntry := FindLastItemLedgEntryNo();
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false, LastEntry);

        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", true, 0);
        LastEntry := FindLastItemLedgEntryNo();
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Indirect Cost", ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::Material, false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::Capacity, false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::"Capacity Overhead", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::"Manufacturing Overhead", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false, LastEntry);

        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Consumption, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false, 0);
        LastEntry := FindLastItemLedgEntryNo();
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Consumption, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false, LastEntry);
        PostItemJnl(ValueEntry."Item Ledger Entry Type"::Consumption, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false, LastEntry);
    end;

    [Scope('OnPrem')]
    procedure PostItemJnl(ItemLedgEntryType: Enum "Item Ledger Entry Type"; ValueEntryType: Enum "Cost Entry Type"; VarianceType: Enum "Cost Variance Type"; ExpectedCost: Boolean; ItemEntryNo: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Item No.", 'AVG');
        ItemJnlLine."Posting Date" := WorkDate();
        ItemJnlLine."Document No." := ItemJnlLine."Item No.";
        ItemJnlLine."Entry Type" := ItemLedgEntryType;
        ItemJnlLine."Value Entry Type" := ValueEntryType;
        ItemJnlLine."Variance Type" := VarianceType;
        ItemJnlLine."Unit Cost" := 1;
        if ItemEntryNo = 0 then
            ItemJnlLine."Quantity (Base)" := 1;
        if ExpectedCost then
            ItemJnlLine."Invoiced Qty. (Base)" := 0
        else
            ItemJnlLine."Invoiced Qty. (Base)" := 1;
        if (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
           ((ItemJnlLine."Quantity (Base)" = 0) and (ItemJnlLine."Invoiced Qty. (Base)" <> 0))
        then
            ItemJnlLine."Item Shpt. Entry No." := ItemEntryNo
        else
            ItemJnlLine."Applies-to Entry" := ItemEntryNo;
        ItemJnlPostLine.Run(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure FindLastItemLedgEntryNo(): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure ClearAppldEntryToAdjForConsump(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
        ItemLedgEntry.ModifyAll("Applied Entry to Adjust", false);
    end;

    [Scope('OnPrem')]
    procedure SetCompletelyInvoicedForOutput(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
        ItemLedgEntry.ModifyAll("Completely Invoiced", true);
    end;
}

