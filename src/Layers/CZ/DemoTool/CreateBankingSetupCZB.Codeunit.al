codeunit 163505 "Create Banking Setup CZB"
{

    trigger OnRun()
    begin
        if BankAccount.Get(CreateBankAccount.GetBankAccountCode('XNBL')) then begin
            CreateNoSeries.InitBaseSeries2(BankAccount."Payment Order Nos. CZB", XPORDER, XPaymentOrder, 'BPRI0001', 'BPRI9999', '', '', 1);
            CreateNoSeries.InitBaseSeries2(BankAccount."Issued Payment Order Nos. CZB", XPORDERPlus, XIssuedPaymentOrder, 'BPRI00001', 'BPRI99999', '', '', 1);
            CreateNoSeries.InitBaseSeries2(BankAccount."Bank Statement Nos. CZB", XBSTMT, XBankStatement, 'BVYP0001', 'BVYP9999', '', '', 1);
            CreateNoSeries.InitBaseSeries2(BankAccount."Issued Bank Statement Nos. CZB", XBSTMTPlus, XIssuedBankStatement, 'BVYP00001', 'BVYP99999', '', '', 1);
            BankAccount.Modify();
        end;
    end;

    var
        BankAccount: Record "Bank Account";
        CreateNoSeries: Codeunit "Create No. Series";
        CreateBankAccount: Codeunit "Create Bank Account";
        XBSTMT: Label 'B-STMT', Comment = 'Code of no. series for bank statement';
        XBSTMTPlus: Label 'B-STMT+', Comment = 'Code of no. series for issued bank statement';
        XPORDER: Label 'P-ORDER', Comment = 'Code of no. series for payment order';
        XPORDERPlus: Label 'P-ORDER+', Comment = 'Code of no. series for issued payment order';
        XBankStatement: Label 'Bank Statement';
        XIssuedBankStatement: Label 'Issued Bank Statement';
        XPaymentOrder: Label 'Payment Order';
        XIssuedPaymentOrder: Label 'Issued Payment Order';
}
