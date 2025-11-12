codeunit 103517 "Test - Inventory Posting"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103517);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 1"();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        LastEntryNo: Integer;
        ShowScriptResult: Boolean;

    local procedure SetPreconditions()
    var
        InvtSetup: Record "Inventory Setup";
        GenPostSetup: Record "General Posting Setup";
        InvtPostSetup: Record "Inventory Posting Setup";
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        InvtSetup.ModifyAll("Expected Cost Posting to G/L", true);

        GenPostSetup."Gen. Bus. Posting Group" := 'TEST';
        GenPostSetup."Gen. Prod. Posting Group" := 'TEST';
        GenPostSetup."COGS Account" := InsertAccount('GOGS');
        GenPostSetup."Inventory Adjmt. Account" := InsertAccount('INVTADJMT');
        GenPostSetup."Invt. Accrual Acc. (Interim)" := InsertAccount('INVTADJMT (I)');
        GenPostSetup."COGS Account (Interim)" := InsertAccount('GOGS (I)');
        GenPostSetup."Direct Cost Applied Account" := InsertAccount('DIRCOST');
        GenPostSetup."Overhead Applied Account" := InsertAccount('OVHDCOST');
        GenPostSetup."Purchase Variance Account" := InsertAccount('PURCHVAR');
        if GenPostSetup.Insert() then;

        InvtPostSetup."Location Code" := '';
        InvtPostSetup."Invt. Posting Group Code" := 'TEST';
        InvtPostSetup."Inventory Account" := InsertAccount('INVT');
        InvtPostSetup."Inventory Account (Interim)" := InsertAccount('INVT (I)');
        InvtPostSetup."WIP Account" := InsertAccount('WIP');
        InvtPostSetup."Material Variance Account" := InsertAccount('MATVAR');
        InvtPostSetup."Capacity Variance Account" := InsertAccount('CAPVAR');
        InvtPostSetup."Mfg. Overhead Variance Account" := InsertAccount('MFGOVHDVAR');
        InvtPostSetup."Cap. Overhead Variance Account" := InsertAccount('CAPOVHDVAR');
        InvtPostSetup."Subcontracted Variance Account" := InsertAccount('SUBCONVAR');
        if InvtPostSetup.Insert() then;
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        ValueEntry: Record "Value Entry";
        LastGLEntryNo: Integer;
    begin
        LastGLEntryNo := GLUtil.GetLastGLEntryNo();

        PostToGL(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", true);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::"Indirect Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::Purchase, false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", true);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Transfer, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::Consumption, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Consumption, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Consumption, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", true);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::"Indirect Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::Material, false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::Capacity, false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::"Capacity Overhead", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::"Manufacturing Overhead", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Variance, ValueEntry."Variance Type"::Subcontracted, false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Revaluation, ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::Output, ValueEntry."Entry Type"::Rounding, ValueEntry."Variance Type"::" ", false);

        PostToGL(ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Variance Type"::" ", false);
        PostToGL(ValueEntry."Item Ledger Entry Type"::" ", ValueEntry."Entry Type"::"Indirect Cost", ValueEntry."Variance Type"::" ", false);

        ValidateGLEntries(LastGLEntryNo);
    end;

    [Scope('OnPrem')]
    procedure ValidateGLEntries(EntryNo: Integer)
    begin
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT (I)', 'Purchase,Direct Cost, ,Yes', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT (I)', 'Purchase,Direct Cost, ,Yes', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Purchase,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'DIRCOST', 'Purchase,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Purchase,Indirect Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'OVHDCOST', 'Purchase,Indirect Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Purchase,Variance,Purchase,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'PURCHVAR', 'Purchase,Variance,Purchase,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Purchase,Revaluation, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Purchase,Revaluation, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Purchase,Rounding, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Purchase,Rounding, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT (I)', 'Sale,Direct Cost, ,Yes', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'GOGS (I)', 'Sale,Direct Cost, ,Yes', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Sale,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'GOGS', 'Sale,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Sale,Revaluation, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Sale,Revaluation, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Sale,Rounding, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Sale,Rounding, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Positive Adjmt.,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Positive Adjmt.,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Positive Adjmt.,Revaluation, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Positive Adjmt.,Revaluation, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Positive Adjmt.,Rounding, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Positive Adjmt.,Rounding, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Negative Adjmt.,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Negative Adjmt.,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Negative Adjmt.,Revaluation, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Negative Adjmt.,Revaluation, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Negative Adjmt.,Rounding, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Negative Adjmt.,Rounding, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Transfer,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Transfer,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Transfer,Revaluation, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Transfer,Revaluation, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Transfer,Rounding, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Transfer,Rounding, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Consumption,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'WIP', 'Consumption,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Consumption,Revaluation, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Consumption,Revaluation, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Consumption,Rounding, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Consumption,Rounding, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT (I)', 'Output,Direct Cost, ,Yes', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'WIP', 'Output,Direct Cost, ,Yes', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'WIP', 'Output,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Indirect Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'OVHDCOST', 'Output,Indirect Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Variance,Material,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'MATVAR', 'Output,Variance,Material,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Variance,Capacity,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'CAPVAR', 'Output,Variance,Capacity,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Variance,Capacity Overhead,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'CAPOVHDVAR', 'Output,Variance,Capacity Overhead,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Variance,Manufacturing Overhead,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'MFGOVHDVAR', 'Output,Variance,Manufacturing Overhead,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Variance,Subcontracted,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'SUBCONVAR', 'Output,Variance,Subcontracted,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Revaluation, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Output,Revaluation, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVT', 'Output,Rounding, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'INVTADJMT', 'Output,Rounding, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'WIP', ' ,Direct Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'DIRCOST', ' ,Direct Cost, ,No', -3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'WIP', ' ,Indirect Cost, ,No', 3.14);
        ValidateGLEntry(GetNextEntryNo(EntryNo), 'OVHDCOST', ' ,Indirect Cost, ,No', -3.14);
    end;

    [Scope('OnPrem')]
    procedure ValidateGLEntry(EntryNo: Integer; AccNo: Code[20]; Descr: Text[50]; Amt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(EntryNo);
        TestscriptMgt.TestTextValue(GLEntry.FieldName("G/L Account No."), GLEntry."G/L Account No.", AccNo);
        TestscriptMgt.TestTextValue(GLEntry.FieldName(Description), GLEntry.Description, Descr);
        TestscriptMgt.TestNumberValue(GLEntry.FieldName(Amount), GLEntry.Amount, Amt);
    end;

    local procedure PostToGL(ItemLedgEntryType: Enum "Item Ledger Entry Type"; ValueEntryType: Enum "Cost Entry Type"; VarianceType: Enum "Cost Variance Type"; ExpectedCost: Boolean)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        GLEntry: Record "G/L Entry";
        InvtPost: Codeunit "Inventory Posting To G/L";
        Desc: Text[50];
        Account: Integer;
        BalAccount: Integer;
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := GetNextEntryNo(LastEntryNo);
        ValueEntry."Item Ledger Entry Type" := ItemLedgEntryType;
        ValueEntry."Entry Type" := ValueEntryType;
        ValueEntry."Variance Type" := VarianceType;
        ValueEntry."Document No." := 'A';
        ValueEntry."Gen. Bus. Posting Group" := 'TEST';
        ValueEntry."Gen. Prod. Posting Group" := 'TEST';
        ValueEntry."Inventory Posting Group" := 'TEST';
        ValueEntry."Location Code" := '';
        ValueEntry."Posting Date" := WorkDate();
        if ExpectedCost then begin
            if ItemLedgEntry.FindLast() then;
            ItemLedgEntry."Entry No." := ItemLedgEntry."Entry No." + 1;
            ItemLedgEntry.Quantity := 1;
            ItemLedgEntry."Invoiced Quantity" := 0;
            ItemLedgEntry.Insert();
            ValueEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
            ValueEntry."Expected Cost" := true;
            ValueEntry."Cost Amount (Expected)" := 3.14;
        end else
            ValueEntry."Cost Amount (Actual)" := 3.14;
        ValueEntry.Insert();
        InvtPost.BufferInvtPosting(ValueEntry);
        InvtPost.PostInvtPostBufPerEntry(ValueEntry);

        GLEntry.FindLast();
        Account := GLEntry."Entry No." - 1;
        BalAccount := GLEntry."Entry No.";
        Desc := StrSubstNo('%1,%2,%3,%4', ValueEntry."Item Ledger Entry Type", ValueEntry."Entry Type", ValueEntry."Variance Type", ValueEntry."Expected Cost");
        GLEntry.Get(Account);
        GLEntry.Description := Desc;
        GLEntry.Modify();
        GLEntry.Get(BalAccount);
        GLEntry.Description := Desc;
        GLEntry.Modify();
    end;

    [Scope('OnPrem')]
    procedure InsertAccount(AccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := AccountNo;
        if not GLAccount.Find() then
            GLAccount.Insert();
        exit(GLAccount."No.");
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

