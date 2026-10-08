#pragma warning disable AA0247
codeunit 17301 "Tax Diff.-Post Jnl. Line"
{
    Permissions = TableData "FA Ledger Entry" = rm,
                  TableData "Tax Diff. Register" = imd,
                  TableData "Tax Diff. Ledger Entry" = imd;

    trigger OnRun()
    begin
    end;

    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffReg: Record "Tax Diff. Register";
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
        FE: Record "Fixed Asset";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        NextEntryNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1003: Label '=%1 can not be less than %2=%3';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1004: Label 'Wrong posting order. Start balance of tax difference changed.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1005: Label 'must be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1006: Label 'Depr. bonus for %1 has been already recovered.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        TaxDiffPostGroup: Record "Tax Diff. Posting Group";
        PostingDate: Date;
    begin
        CheckJnlLine();

        if NextEntryNo = 0 then begin
            TaxDiffEntry.LockTable();
            NextEntryNo := TaxDiffEntry.GetLastEntryNo();

            TaxDiffReg.LockTable();
            TaxDiffReg."No." := TaxDiffReg.GetLastEntryNo() + 1;
            TaxDiffReg.Init();
            TaxDiffReg."Journal Batch Name" := TaxDiffJnlLine."Journal Batch Name";
            TaxDiffReg."Creation Date" := Today;
            TaxDiffReg."User ID" := UserId;
            TaxDiffReg.Insert();
        end;
        NextEntryNo := NextEntryNo + 1;

        TaxDiffEntry.Init();
        TaxDiffEntry.TransferFields(TaxDiffJnlLine, false);
        TaxDiffEntry."Journal Batch Name" := TaxDiffJnlLine."Journal Batch Name";
        TaxDiffEntry."Transaction No." := 0;
        TaxDiffEntry."Entry No." := NextEntryNo;

        TaxDiffPostGroup.Get(TaxDiffJnlLine."Tax Diff. Posting Group");

        PostingDate := TaxDiffJnlLine."Posting Date";
        case TaxDiffJnlLine."Tax Diff. Type" of
            TaxDiffJnlLine."Tax Diff. Type"::Constant:
                begin
                    if TaxDiffJnlLine."Asset Tax Amount" <> 0 then begin
                        TaxDiffPostGroup.TestField("CTA Tax Account");
                        TaxDiffPostGroup.TestField("CTA Account");
                        GenJnlLineCreate(
                          TaxDiffPostGroup."CTA Tax Account",
                          TaxDiffPostGroup."CTA Account",
                          TaxDiffJnlLine."Asset Tax Amount", PostingDate);
                    end;
                    if TaxDiffJnlLine."Liability Tax Amount" <> 0 then begin
                        TaxDiffPostGroup.TestField("CTL Tax Account");
                        TaxDiffPostGroup.TestField("CTL Account");
                        GenJnlLineCreate(
                          TaxDiffPostGroup."CTL Account",
                          TaxDiffPostGroup."CTL Tax Account",
                          TaxDiffJnlLine."Liability Tax Amount", PostingDate);
                    end;
                end;
            TaxDiffJnlLine."Tax Diff. Type"::"Temporary":
                begin
                    if TaxDiffJnlLine."Asset Tax Amount" <> 0 then begin
                        TaxDiffPostGroup.TestField("DTA Tax Account");
                        TaxDiffPostGroup.TestField("DTA Account");
                        GenJnlLineCreate(
                          TaxDiffPostGroup."DTA Account",
                          TaxDiffPostGroup."DTA Tax Account",
                          TaxDiffJnlLine."Asset Tax Amount", PostingDate);
                    end;
                    if TaxDiffJnlLine."Liability Tax Amount" <> 0 then begin
                        TaxDiffPostGroup.TestField("DTL Tax Account");
                        TaxDiffPostGroup.TestField("DTL Account");
                        GenJnlLineCreate(
                          TaxDiffPostGroup."DTL Tax Account",
                          TaxDiffPostGroup."DTL Account",
                          TaxDiffJnlLine."Liability Tax Amount", PostingDate);
                    end;
                    if TaxDiffJnlLine."Disposal Date" <> 0D then
                        PostingDate := TaxDiffJnlLine."Disposal Date";
                    if TaxDiffJnlLine."Disposal Mode" = TaxDiffJnlLine."Disposal Mode"::"Write Down" then begin
                        if TaxDiffJnlLine."Disposal Tax Amount" > 0 then begin
                            TaxDiffJnlLine.TestField("DTL Ending Balance", 0);
                            TaxDiffPostGroup.TestField("DTA Disposal Account");
                            TaxDiffPostGroup.TestField("DTA Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."DTA Disposal Account",
                              TaxDiffPostGroup."DTA Account",
                              TaxDiffJnlLine."Disposal Tax Amount", PostingDate);
                        end;
                        if TaxDiffJnlLine."Disposal Tax Amount" < 0 then begin
                            TaxDiffJnlLine.TestField("DTA Ending Balance", 0);
                            TaxDiffPostGroup.TestField("DTL Disposal Account");
                            TaxDiffPostGroup.TestField("DTL Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."DTL Account",
                              TaxDiffPostGroup."DTL Disposal Account",
                              -TaxDiffJnlLine."Disposal Tax Amount", PostingDate);
                        end;
                    end;
                    if TaxDiffJnlLine."Disposal Mode" = TaxDiffJnlLine."Disposal Mode"::Transform then begin
                        if TaxDiffJnlLine."Disposal Tax Amount" > 0 then begin
                            TaxDiffJnlLine.TestField("DTL Ending Balance", 0);
                            TaxDiffPostGroup.TestField("DTA Transfer Bal. Account");
                            TaxDiffPostGroup.TestField("DTA Account");
                            TaxDiffPostGroup.TestField("CTL Transfer Tax Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."DTA Transfer Bal. Account",
                              TaxDiffPostGroup."DTA Account",
                              TaxDiffJnlLine."Disposal Tax Amount", PostingDate);
                            GenJnlLineCreate(
                              TaxDiffPostGroup."CTL Transfer Tax Account",
                              TaxDiffPostGroup."DTA Transfer Bal. Account",
                              TaxDiffJnlLine."Disposal Tax Amount", PostingDate);
                        end;
                        if TaxDiffJnlLine."Disposal Tax Amount" < 0 then begin
                            TaxDiffJnlLine.TestField("DTA Ending Balance", 0);
                            TaxDiffPostGroup.TestField("DTL Transfer Bal. Account");
                            TaxDiffPostGroup.TestField("DTL Account");
                            TaxDiffPostGroup.TestField("CTA Transfer Tax Account");
                            GenJnlLineCreate(
                              TaxDiffPostGroup."DTL Account",
                              TaxDiffPostGroup."DTL Transfer Bal. Account",
                              -TaxDiffJnlLine."Disposal Tax Amount", PostingDate);
                            GenJnlLineCreate(
                              TaxDiffPostGroup."DTL Transfer Bal. Account",
                              TaxDiffPostGroup."CTA Transfer Tax Account",
                              -TaxDiffJnlLine."Disposal Tax Amount", PostingDate);
                        end;
                    end;
                end;
        end;

        TaxDiffEntry.Insert();

        TaxDiffReg.Get(TaxDiffReg."No.");
        if TaxDiffReg."From Entry No." = 0 then
            TaxDiffReg."From Entry No." := NextEntryNo;
        TaxDiffReg."To Entry No." := NextEntryNo;
        TaxDiffReg.Modify();
    end;

    local procedure GenJnlLineCreate(AccountNo: Code[20]; BalAccountNo: Code[20]; PostingAmount: Decimal; PostingDate: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLReg: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GenJnlLine.Init();
        GenJnlLine."Journal Batch Name" := TaxDiffJnlLine."Journal Batch Name";
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Date" := PostingDate;
        GenJnlLine.Description := TaxDiffJnlLine.Description;
        GenJnlLine."Reason Code" := TaxDiffJnlLine."Reason Code";
        GenJnlLine."Document No." := TaxDiffJnlLine."Document No.";
        GenJnlLine."Account No." := AccountNo;
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine.Amount := PostingAmount;
        GenJnlLine."Shortcut Dimension 1 Code" := TaxDiffJnlLine."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := TaxDiffJnlLine."Shortcut Dimension 2 Code";
        GenJnlLine."Source Code" := TaxDiffJnlLine."Source Code";
        GenJnlLine."Bal. Account No." := BalAccountNo;
        GenJnlLine."Dimension Set ID" := TaxDiffJnlLine."Dimension Set ID";

        GenJnlPostLine.RunWithCheck(GenJnlLine);

        if TaxDiffEntry."Transaction No." = 0 then begin
            GenJnlPostLine.GetGLReg(GLReg);
            GLEntry.Get(GLReg."To Entry No.");
            TaxDiffEntry."Transaction No." := GLEntry."Transaction No.";
        end;
    end;

    local procedure CheckJnlLine()
    var
        TaxDiffJnlLine0: Record "Tax Diff. Journal Line";
    begin
        TaxDiffJnlLine.TestField("Posting Date");
        TaxDiffJnlLine.TestField("Document No.");
        TaxDiffJnlLine.TestField("Tax Diff. Code");
        TaxDiffJnlLine.TestField("Tax Factor");
        TaxDiffJnlLine.TestField("Tax Diff. Posting Group");

        if TaxDiffJnlLine."Source Type" <> TaxDiffJnlLine."Source Type"::" " then
            TaxDiffJnlLine.TestField("Source No.");

        if (TaxDiffJnlLine."Source Type" = TaxDiffJnlLine."Source Type"::"Future Expense") and (TaxDiffJnlLine."Source No." <> '') then begin
            FE.Get(TaxDiffJnlLine."Source No.");
            FE.TestField("Tax Difference Code");
            TaxDiffJnlLine.TestField("Tax Diff. Code", FE."Tax Difference Code");
        end;

        if TaxDiffJnlLine."Source No." <> '' then
            DeprBonusRecover();

        if TaxDiffJnlLine."Disposal Date" <> 0D then
            if TaxDiffJnlLine."Disposal Mode" = TaxDiffJnlLine."Disposal Mode"::" " then
                TaxDiffJnlLine.TestField("Disposal Date", 0D)
            else
                if TaxDiffJnlLine."Disposal Date" < TaxDiffJnlLine."Posting Date" then
                    TaxDiffJnlLine.FieldError(
                      "Disposal Date", StrSubstNo(Text1003, TaxDiffJnlLine."Disposal Date", TaxDiffJnlLine.FieldCaption("Posting Date"), TaxDiffJnlLine."Posting Date"));

        if TaxDiffJnlLine."Partial Disposal" then
            TaxDiffJnlLine.TestField("Disposal Mode");

        TaxDiffJnlLine0 := TaxDiffJnlLine;
        TaxDiffJnlLine0."DTA Starting Balance" := 0;
        TaxDiffJnlLine0."DTL Starting Balance" := 0;
        TaxDiffJnlLine0."Partial Disposal" := false;
        TaxDiffJnlLine0.GetStartingAmount();
        if TaxDiffJnlLine."Partial Disposal" then
            PreparePartiotionalDisposal()
        else
            if (TaxDiffJnlLine0."DTA Starting Balance" <> TaxDiffJnlLine."DTA Starting Balance") or
               (TaxDiffJnlLine0."DTL Starting Balance" <> TaxDiffJnlLine."DTL Starting Balance")
            then
                Error(Text1004);
    end;

    [Scope('OnPrem')]
    procedure RunWithCheck(var Rec: Record "Tax Diff. Journal Line")
    begin
        TaxDiffJnlLine.Copy(Rec);
        Code();
        Rec := TaxDiffJnlLine;
    end;

    local procedure PreparePartiotionalDisposal()
    begin
        if TaxDiffJnlLine."Disposal Tax Amount" < 0 then
            TaxDiffJnlLine."DTL Ending Balance" := -TaxDiffJnlLine."Disposal Tax Amount"
        else
            TaxDiffJnlLine."DTA Ending Balance" := TaxDiffJnlLine."Disposal Tax Amount";
    end;

    local procedure DeprBonusRecover()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        if TaxDiffJnlLine."Depr. Bonus Recovery" then begin
            TaxRegisterSetup.Get();
            TaxRegisterSetup.TestField("Tax Depreciation Book");
            FALedgerEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
            FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
            FALedgerEntry.SetRange("FA No.", TaxDiffJnlLine."Source No.");
            FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
            FALedgerEntry.SetRange("Depr. Bonus", true);
            FALedgerEntry.CalcSums(Amount);

            if TaxDiffJnlLine."Amount (Tax)" <> -FALedgerEntry.Amount then
                TaxDiffJnlLine.FieldError("Amount (Tax)", StrSubstNo(Text1005, -FALedgerEntry.Amount));

            if FALedgerEntry.FindSet() then
                repeat
                    if FALedgerEntry."Depr. Bonus Recovery Date" <> 0D then
                        Error(Text1006, TaxDiffJnlLine."Source No.");
                until FALedgerEntry.Next() = 0;
            FALedgerEntry.ModifyAll("Depr. Bonus Recovery Date", TaxDiffJnlLine."Posting Date");
        end;
    end;
}

