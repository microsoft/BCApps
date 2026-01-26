codeunit 101128 "Create Voucher Posting Credit"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('', "Gen. Journal Template Type"::"Cash Payment Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('', "Gen. Journal Template Type"::"Bank Payment Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Payment Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Payment Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('RED', "Gen. Journal Template Type"::"Cash Payment Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('RED', "Gen. Journal Template Type"::"Bank Payment Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO')
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
        InsertData('', "Gen. Journal Template Type"::"Cash Payment Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('', "Gen. Journal Template Type"::"Bank Payment Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Payment Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Payment Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO');
        InsertData('RED', "Gen. Journal Template Type"::"Cash Payment Voucher", "Gen. Journal Account Type"::"G/L Account", '2910');
        InsertData('RED', "Gen. Journal Template Type"::"Bank Payment Voucher", "Gen. Journal Account Type"::"Bank Account", 'GIRO')
    end;

    procedure InsertData(LocationCode: Code[20]; JournalVoucherType: Enum "Gen. Journal Template Type"; JournalAccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    var
        VoucherPostingCreditAccount: Record "Voucher Posting Credit Account";
    begin
        VoucherPostingCreditAccount.Init();
        VoucherPostingCreditAccount."Location Code" := LocationCode;
        VoucherPostingCreditAccount.Type := JournalVoucherType;
        VoucherPostingCreditAccount."Account Type" := JournalAccType;
        VoucherPostingCreditAccount."Account No." := AccNo;
        VoucherPostingCreditAccount.Insert();
    end;
}