codeunit 163508 "Create Bank Statement Hdr. CZB"
{

    trigger OnRun()
    begin
        InsertData(CreateBankAccount.GetBankAccountCode('XNBL'), WorkDate(), '1');
        InsertData(CreateBankAccount.GetBankAccountCode('XNBL'), WorkDate(), '2');
    end;

    var
        BankStatementHeaderCZB: Record "Bank Statement Header CZB";
        CreateBankAccount: Codeunit "Create Bank Account";

    procedure InsertData(BankAccountNo: Code[20]; DocumentDate: Date; ExternalDocumentNo: Code[35])
    begin
        BankStatementHeaderCZB.Init();
        BankStatementHeaderCZB."No." := '';
        BankStatementHeaderCZB.Validate("Bank Account No.", BankAccountNo);
        BankStatementHeaderCZB."Document Date" := DocumentDate;
        BankStatementHeaderCZB."External Document No." := ExternalDocumentNo;
        BankStatementHeaderCZB.Insert(true);
    end;
}
