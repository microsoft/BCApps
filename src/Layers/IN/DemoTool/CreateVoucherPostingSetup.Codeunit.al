codeunit 101125 "Create Voucher Posting Setup"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('', "Gen. Journal Template Type"::"Cash Receipt Voucher", '', 1);
        InsertData('', "Gen. Journal Template Type"::"Cash Payment Voucher", '', 2);
        InsertData('', "Gen. Journal Template Type"::"Bank Receipt Voucher", '', 1);
        InsertData('', "Gen. Journal Template Type"::"Bank Payment Voucher", '', 2);
        InsertData('', "Gen. Journal Template Type"::"Contra Voucher", '', 0);
        InsertData('', "Gen. Journal Template Type"::"Journal Voucher", '', 0);

        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Receipt Voucher", 'CSHRCV-P', 1);
        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Payment Voucher", 'CSHPYV-P', 2);
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Receipt Voucher", 'BNKRCV-P', 1);
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Payment Voucher", 'BNKPYV-P', 2);
        InsertData('BLUE', "Gen. Journal Template Type"::"Contra Voucher", 'CNTRV-P', 0);
        InsertData('BLUE', "Gen. Journal Template Type"::"Journal Voucher", 'JRNLV-P', 0);

        InsertData('RED', "Gen. Journal Template Type"::"Cash Receipt Voucher", '', 1);
        InsertData('RED', "Gen. Journal Template Type"::"Cash Payment Voucher", '', 2);
        InsertData('RED', "Gen. Journal Template Type"::"Bank Receipt Voucher", '', 1);
        InsertData('RED', "Gen. Journal Template Type"::"Bank Payment Voucher", '', 2);
        InsertData('RED', "Gen. Journal Template Type"::"Contra Voucher", '', 0);
        InsertData('RED', "Gen. Journal Template Type"::"Journal Voucher", '', 0);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertMiniAppData()
    begin
        AddVoucherPostingSetupForMini();
    end;

    local procedure AddVoucherPostingSetupForMini()
    begin
        DemoDataSetup.Get();
        InsertData('', "Gen. Journal Template Type"::"Cash Receipt Voucher", '', 1);
        InsertData('', "Gen. Journal Template Type"::"Cash Payment Voucher", '', 2);
        InsertData('', "Gen. Journal Template Type"::"Bank Receipt Voucher", '', 1);
        InsertData('', "Gen. Journal Template Type"::"Bank Payment Voucher", '', 2);
        InsertData('', "Gen. Journal Template Type"::"Contra Voucher", '', 0);
        InsertData('', "Gen. Journal Template Type"::"Journal Voucher", '', 0);

        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Receipt Voucher", '', 1);
        InsertData('BLUE', "Gen. Journal Template Type"::"Cash Payment Voucher", '', 2);
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Receipt Voucher", '', 1);
        InsertData('BLUE', "Gen. Journal Template Type"::"Bank Payment Voucher", '', 2);
        InsertData('BLUE', "Gen. Journal Template Type"::"Contra Voucher", '', 0);
        InsertData('BLUE', "Gen. Journal Template Type"::"Journal Voucher", '', 0);

        InsertData('RED', "Gen. Journal Template Type"::"Cash Receipt Voucher", '', 1);
        InsertData('RED', "Gen. Journal Template Type"::"Cash Payment Voucher", '', 2);
        InsertData('RED', "Gen. Journal Template Type"::"Bank Receipt Voucher", '', 1);
        InsertData('RED', "Gen. Journal Template Type"::"Bank Payment Voucher", '', 2);
        InsertData('RED', "Gen. Journal Template Type"::"Contra Voucher", '', 0);
        InsertData('RED', "Gen. Journal Template Type"::"Journal Voucher", '', 0);
    end;

    procedure InsertData(LocationCode: Code[20]; JournalVoucherType: Enum "Gen. Journal Template Type"; PostingNoSeries: Code[20]; TransactionDirection: Integer)
    var
        JournalVoucherPostingSetup: Record "Journal Voucher Posting Setup";
    begin
        JournalVoucherPostingSetup.Init();
        JournalVoucherPostingSetup."Location Code" := LocationCode;
        JournalVoucherPostingSetup.Type := JournalVoucherType;
        JournalVoucherPostingSetup."Transaction Direction" := TransactionDirection;
        JournalVoucherPostingSetup."Posting No. Series" := PostingNoSeries;
        JournalVoucherPostingSetup.Insert();
    end;
}