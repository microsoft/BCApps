codeunit 101127 "Create Voucher Posting Debit"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('', "Gen. Journal Template Type"::"Cash Receipt Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('', "Gen. Journal Template Type"::"Bank Receipt Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Receipt Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Receipt Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('RED', "Gen. Journal Template Type"::"Cash Receipt Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('RED', "Gen. Journal Template Type"::"Bank Receipt Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertMiniAppData()
    begin
        AddVoucherPostingDebitForMini();
    end;

    local procedure AddVoucherPostingDebitForMini()
    begin
        DemoDataSetup.Get();
        InsertData('', "Gen. Journal Template Type"::"Cash Receipt Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('', "Gen. Journal Template Type"::"Bank Receipt Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Receipt Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Receipt Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('RED', "Gen. Journal Template Type"::"Cash Receipt Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('RED', "Gen. Journal Template Type"::"Bank Receipt Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
    end;

    procedure InsertData(LocationCode: Code[20]; JournalVoucherType: Enum "Gen. Journal Template Type"; JournalAccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    var
        VoucherPostingDebitAccount: Record "Voucher Posting Debit Account";
    begin
        VoucherPostingDebitAccount.Init();
        VoucherPostingDebitAccount."Location Code" := LocationCode;
        VoucherPostingDebitAccount.Type := JournalVoucherType;
        VoucherPostingDebitAccount."Account Type" := JournalAccType;
        VoucherPostingDebitAccount."Account No." := AccNo;
        VoucherPostingDebitAccount.Insert();
    end;
}