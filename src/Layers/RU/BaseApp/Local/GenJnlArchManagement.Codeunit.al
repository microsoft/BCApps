#pragma warning disable AA0247
codeunit 12413 GenJnlArchManagement
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure SelectionFromBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlLineArch: Record "Gen. Journal Line Archive";
    begin
        GenJnlLineArch.FilterGroup := 2;
        GenJnlLineArch.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLineArch.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLineArch.FilterGroup := 0;
        PAGE.Run(PAGE::"Posted Gen. Journals", GenJnlLineArch);
    end;

    [Scope('OnPrem')]
    procedure GetAccounts(var GenJnlLineArch: Record "Gen. Journal Line Archive"; var AccName: Text[100]; var BalAccName: Text[100])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        IC: Record "IC Partner";
    begin
        AccName := '';
        if GenJnlLineArch."Account No." <> '' then
            case GenJnlLineArch."Account Type" of
                GenJnlLineArch."Account Type"::"G/L Account":
                    if GLAcc.Get(GenJnlLineArch."Account No.") then
                        AccName := GLAcc.Name;
                GenJnlLineArch."Account Type"::Customer:
                    if Cust.Get(GenJnlLineArch."Account No.") then
                        AccName := Cust.Name;
                GenJnlLineArch."Account Type"::Vendor:
                    if Vend.Get(GenJnlLineArch."Account No.") then
                        AccName := Vend.Name;
                GenJnlLineArch."Account Type"::"Bank Account":
                    if BankAcc.Get(GenJnlLineArch."Account No.") then
                        AccName := BankAcc.Name;
                GenJnlLineArch."Account Type"::"Fixed Asset":
                    if FA.Get(GenJnlLineArch."Account No.") then
                        AccName := FA.Description;
                GenJnlLineArch."Account Type"::"IC Partner":
                    if IC.Get(GenJnlLineArch."Account No.") then
                        AccName := IC.Name;
            end;

        BalAccName := '';
        if GenJnlLineArch."Bal. Account No." <> '' then
            case GenJnlLineArch."Bal. Account Type" of
                GenJnlLineArch."Bal. Account Type"::"G/L Account":
                    if GLAcc.Get(GenJnlLineArch."Bal. Account No.") then
                        BalAccName := GLAcc.Name;
                GenJnlLineArch."Bal. Account Type"::Customer:
                    if Cust.Get(GenJnlLineArch."Bal. Account No.") then
                        BalAccName := Cust.Name;
                GenJnlLineArch."Bal. Account Type"::Vendor:
                    if Vend.Get(GenJnlLineArch."Bal. Account No.") then
                        BalAccName := Vend.Name;
                GenJnlLineArch."Bal. Account Type"::"Bank Account":
                    if BankAcc.Get(GenJnlLineArch."Bal. Account No.") then
                        BalAccName := BankAcc.Name;
                GenJnlLineArch."Bal. Account Type"::"Fixed Asset":
                    if FA.Get(GenJnlLineArch."Bal. Account No.") then
                        BalAccName := FA.Description;
                GenJnlLineArch."Bal. Account Type"::"IC Partner":
                    if IC.Get(GenJnlLineArch."Bal. Account No.") then
                        BalAccName := IC.Name;
            end;
    end;

    [Scope('OnPrem')]
    procedure CalcBalance(GenJnlLineArch: Record "Gen. Journal Line Archive"; var TotalBalance: Decimal)
    var
        TempGenJnlLineArch: Record "Gen. Journal Line Archive";
    begin
        TempGenJnlLineArch.CopyFilters(GenJnlLineArch);
        TempGenJnlLineArch.CalcSums("Balance (LCY)");
        TotalBalance := TempGenJnlLineArch."Balance (LCY)";
    end;
}

