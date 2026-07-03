codeunit 101277 "Create Bank Acc. Posting Group"
{

    trigger OnRun()
    begin
        InsertData('50-1000', XCashDesk1, '50-1000');
        InsertData('50-1004', XCashDesk2, '50-1004');
        InsertData('50-1001', XCashDeskUSD, '50-1001');
        InsertData('50-1002', XCashDeskEUR, '50-1002');
        InsertData('50-2000', XOperationCash, '50-2000');
        InsertData('50-3000', XMDoc, '50-3000');
        InsertData('52-1001', XWorldWideBankUSD, '52-1001');
        InsertData('51-1001', XNationalBankRUR, '51-1001');
        InsertData('51-1002', XWorldWideBankRUR, '51-1002');
        InsertData('52-2001', XWorldWideBankUSD2, '52-2001');
        InsertData('52-2002', XWorldWideBankEUR2, '52-2002');
        InsertData('55-1000', XLetterOfCredit, '55-1000');
        InsertData('55-2000', XChequeBooks, '55-2000');
        InsertData('55-3010', XDepositAccSP, '55-3010');
        InsertData('55-3020', XDepositAccLP, '55-3020');
        InsertData('55-4000', XSpecialBankAccCur, '55-4000');
    end;

    var
        "Bank Acc. Posting Group": Record "Bank Account Posting Group";
        CA: Codeunit "Make Adjustments";
        XCashDesk1: Label 'Cash Desk 1';
        XCashDesk2: Label 'Cash Desk 2';
        XWorldWideBankUSD: Label 'World Wide Bank USD';
        XWorldWideBankRUR: Label 'World Wide Bank RUR';
        XNationalBankRUR: Label 'National Bank RUR';
        XCashDeskUSD: Label 'Cash Desk USD';
        XCashDeskEUR: Label 'Cash Desk EUR';
        XOperationCash: Label 'Operation Cash Desk';
        XMDoc: Label 'Monetary documents';
        XWorldWideBankUSD2: Label 'World Wide Bank USD overseas';
        XWorldWideBankEUR2: Label 'World Wide Bank EUR overseas';
        XLetterOfCredit: Label 'Letters of credit';
        XChequeBooks: Label 'Cheque Books';
        XDepositAccSP: Label 'Deposit Accounts short period';
        XDepositAccLP: Label 'Deposit Accounts long period';
        XSpecialBankAccCur: Label 'Special Bank Accounts in currency';

    procedure InsertData("Code": Code[20]; Description: Text[50]; "G/L Account No.": Code[20])
    begin
        "Bank Acc. Posting Group".Init();
        "Bank Acc. Posting Group".Validate(Code, Code);
        "Bank Acc. Posting Group".Validate(Description, Description);
        "Bank Acc. Posting Group".Validate("G/L Account No.", CA.Convert("G/L Account No."));
        "Bank Acc. Posting Group".Insert();
    end;
}

