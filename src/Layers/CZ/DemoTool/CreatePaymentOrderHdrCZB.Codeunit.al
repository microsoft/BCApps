codeunit 163506 "Create Payment Order Hdr. CZB"
{

    trigger OnRun()
    begin
        InsertData(CreateBankAccount.GetBankAccountCode('XNBL'), WorkDate());
        InsertData(CreateBankAccount.GetBankAccountCode('XNBL'), WorkDate());
    end;

    var
        PaymentOrderHeaderCZB: Record "Payment Order Header CZB";
        CreateBankAccount: Codeunit "Create Bank Account";

    procedure InsertData(BankAccountNo: Code[20]; DocumentDate: Date)
    begin
        PaymentOrderHeaderCZB.Init();
        PaymentOrderHeaderCZB."No." := '';
        PaymentOrderHeaderCZB.Validate("Bank Account No.", BankAccountNo);
        PaymentOrderHeaderCZB."Document Date" := DocumentDate;
        PaymentOrderHeaderCZB.Insert(true)
    end;
}
