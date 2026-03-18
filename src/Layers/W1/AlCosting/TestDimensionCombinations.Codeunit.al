codeunit 103522 "Test - Dimension Combinations"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103522);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 1"();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        ShowScriptResult: Boolean;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        InvtSetup: Record "Inventory Setup";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.AdjustAndPostItemLedgEntries(true, true);
        InvtSetup.ModifyAll("Automatic Cost Posting", false, true);
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        LastGLEntryNo: Integer;
    begin
        // since SQL and native have different sorting of item nos, the results were coming to be different.
        // Thats why the item nos have been changed as per this mapping:
        // ----------------------------
        // Old Items     New Items
        // ----------------------------
        // 12            ITEM1
        // 1ADM2         ITEM2
        // 1ADM2TOYOTA   ITEM3
        // 1ADM2VW       ITEM4
        // 1PROD2        ITEM5
        // 1PROD2TOYOTA  ITEM6
        // 1PROD2VW      ITEM7
        // 12TOYOTA      ITEM8
        // 12VW          ITEM9

        LastGLEntryNo := GLUtil.GetLastGLEntryNo();

        INVTUtil.CreateBasisItem('ITEM1', false, Item, Item."Costing Method"::FIFO, 0);

        INVTUtil.CreateBasisItem('ITEM8', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 2 Code", 'TOYOTA');
        Item.Modify(true);

        INVTUtil.CreateBasisItem('ITEM9', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 2 Code", 'VW');
        Item.Modify(true);

        INVTUtil.CreateBasisItem('ITEM2', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 1 Code", 'ADM');
        Item.Modify(true);

        INVTUtil.CreateBasisItem('ITEM3', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 1 Code", 'ADM');
        Item.Validate("Global Dimension 2 Code", 'TOYOTA');
        Item.Modify(true);

        INVTUtil.CreateBasisItem('ITEM4', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 1 Code", 'ADM');
        Item.Validate("Global Dimension 2 Code", 'VW');
        Item.Modify(true);

        INVTUtil.CreateBasisItem('ITEM5', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 1 Code", 'PROD');
        Item.Modify(true);

        INVTUtil.CreateBasisItem('ITEM6', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 1 Code", 'PROD');
        Item.Validate("Global Dimension 2 Code", 'TOYOTA');
        Item.Modify(true);

        INVTUtil.CreateBasisItem('ITEM7', false, Item, Item."Costing Method"::FIFO, 0);
        Item.Validate("Global Dimension 1 Code", 'PROD');
        Item.Validate("Global Dimension 2 Code", 'VW');
        Item.Modify(true);

        PostItemJnl(ItemJnlLine."Entry Type"::Purchase);
        PostItemJnl(ItemJnlLine."Entry Type"::Purchase);
        PostItemJnl(ItemJnlLine."Entry Type"::Sale);
        PostItemJnl(ItemJnlLine."Entry Type"::Sale);

        INVTUtil.AdjustInvtCost();
        INVTUtil.PostInvtCost(0, 'A');

        ValidateGLEntries(LastGLEntryNo);
    end;

    [Scope('OnPrem')]
    procedure PostItemJnl(EntryType: Enum "Item Ledger Entry Type")
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        INVTUtil.InitItemJournal(ItemJnlLine);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM1', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM8', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM9', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM2', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM3', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM4', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM5', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM6', 1, 1);
        InsertItemJnlLine(ItemJnlLine, EntryType, 'ITEM7', 1, 1);
        INVTUtil.ItemJnlPostBatch(ItemJnlLine);
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
    procedure ValidateGLEntries(EntryNo: Integer)
    begin
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', '', '', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', '', '', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'ADM', '', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'ADM', '', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'PROD', '', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'PROD', '', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'PROD', 'VW', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'PROD', 'VW', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', '', 'TOYOTA', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', '', 'TOYOTA', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', '', 'VW', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', '', 'VW', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'ADM', 'TOYOTA', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'ADM', 'TOYOTA', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'ADM', 'VW', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'ADM', 'VW', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'PROD', 'TOYOTA', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '2130', 'PROD', 'TOYOTA', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', '', '', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', 'ADM', '', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', 'PROD', '', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', 'PROD', 'VW', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', '', 'TOYOTA', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', '', 'VW', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', 'ADM', 'TOYOTA', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', 'ADM', 'VW', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7291', 'PROD', 'TOYOTA', -2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', '', '', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', 'ADM', '', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', 'PROD', '', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', 'PROD', 'VW', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', '', 'TOYOTA', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', '', 'VW', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', 'ADM', 'TOYOTA', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', 'ADM', 'VW', 2);
        ValidateGLEntry(GetNextEntryNo(EntryNo), '7290', 'PROD', 'TOYOTA', 2);
    end;

    [Scope('OnPrem')]
    procedure ValidateGLEntry(EntryNo: Integer; AccNo: Code[20]; Dim1: Code[20]; Dim2: Code[20]; Amt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(EntryNo);
        TestscriptMgt.TestTextValue(GLEntry.FieldName("G/L Account No."), GLEntry."G/L Account No.", AccNo);
        TestscriptMgt.TestTextValue(GLEntry.FieldName("Global Dimension 1 Code"), GLEntry."Global Dimension 1 Code", Dim1);
        TestscriptMgt.TestTextValue(GLEntry.FieldName("Global Dimension 2 Code"), GLEntry."Global Dimension 2 Code", Dim2);
        TestscriptMgt.TestNumberValue(GLEntry.FieldName(Amount), GLEntry.Amount, Amt);
    end;

    local procedure GetNextEntryNo(var LastEntryNo: Integer): Integer
    begin
        LastEntryNo := LastEntryNo + 1;
        exit(LastEntryNo);
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult;
    end;
}

