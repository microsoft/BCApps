codeunit 101092 "Create Cust. Posting Group"
{

    trigger OnRun()
    begin
        InsertData('62-1010', XAccountsReceivable + XRub,
          '62-1010', '90-1210', '91-2330', '91-1330', '91-1330', '91-1330', '91-1330', '91-2330', '91-1330', '91-2330',
          '91-1330', '91-2330', '91-1330', '62-1020');
        InsertData('62-1110', XAccountsReceivable + XCurrency,
          '62-1110', '90-1210', '91-2330', '91-1330', '91-1330', '91-1330', '91-1330', '91-2330', '91-1330', '91-2330',
          '91-1330', '91-2330', '91-1330', '62-1120');
        InsertData('62-1210', XAccountsReceivable + XCu,
          '62-1210', '90-1210', '91-2330', '91-1330', '91-1330', '91-1330', '91-1330', '91-2330', '91-1330', '91-2330',
          '91-1330', '91-2330', '91-1330', '62-1220');
        InsertData('62-2000', XBillsReceivedAsPaymentForGoods,
          '62-2000', '', '', '', '', '', '', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('62-3010', XAccReceivaleUnderComContracts,
          '62-3010', '', '', '91-1330', '', '', '', '', '', '91-2330', '91-1330', '', '', '62-3020');
        InsertData('76-2200', XCustomerClaims,
          '76-2200', '', '', '', '', '', '', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('76-5200', XSercuritiesSalesContracts,
          '76-5200', '', '', '91-1330', '', '', '', '', '', '91-2330', '91-1330', '', '', '');
        InsertData('76-5210', XPercentsOnSEcuritiesSalesContracts,
          '76-5210', '', '', '', '', '', '', '', '', '91-2330', '91-1330', '', '', '');

        //test automation
        InsertData(XTEST, XTEST,
          '62-1010', '90-1210', '91-2330', '91-1330', '91-1330', '91-1330', '91-1330', '91-2330', '91-1330', '91-2330',
          '91-1330', '91-2330', '91-1330', '62-1020');
    end;

    var
        XAccountsReceivable: Label 'Accounts receivable, ';
        XRub: Label ' rub.';
        XCurrency: Label ' currency';
        XCu: Label ' c.u.';
        XBillsReceivedAsPaymentForGoods: Label 'Bills received as payment for goods';
        XAccReceivaleUnderComContracts: Label 'Accounts receivable under comission contracts';
        XCustomerClaims: Label 'Customer claims';
        XSercuritiesSalesContracts: Label 'Securities sales contracts';
        XPercentsOnSEcuritiesSalesContracts: Label '%% on Securities sales contracts';
        XTEST: Label '_TEST';

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Receivables Account": Code[20]; "Service Charge Acc.": Code[20]; "Pmt. Disc. Debit Acc.": Code[20]; "Pmt. Disc. Credit Acc.": Code[20]; "Invoice Rounding Account": Code[20]; "Additional Fee Acc.": Code[20]; "Interest Acc.": Code[20]; "Debit Curr. Appln. Rndg. Acc.": Code[20]; "Credit Curr. Appln. Rndg. Acc.": Code[20]; "Debit Rounding Account": Code[20]; "Credit Rounding Account": Code[20]; "Payment Tolerance Debit Acc.": Code[20]; "Payment Tolerance Credit Acc.": Code[20]; "Prepayment Account": Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Validate(Code, Code);
        CustomerPostingGroup.Validate(Description, Description);
        CustomerPostingGroup.Validate("Receivables Account", MakeAdjustments.Convert("Receivables Account"));
        CustomerPostingGroup.Validate("Service Charge Acc.", MakeAdjustments.Convert("Service Charge Acc."));
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", MakeAdjustments.Convert("Pmt. Disc. Debit Acc."));
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", MakeAdjustments.Convert("Pmt. Disc. Credit Acc."));
        CustomerPostingGroup.Validate("Additional Fee Account", MakeAdjustments.Convert("Additional Fee Acc."));
        CustomerPostingGroup.Validate("Interest Account", MakeAdjustments.Convert("Interest Acc."));
        CustomerPostingGroup.Validate("Invoice Rounding Account", MakeAdjustments.Convert("Invoice Rounding Account"));
        CustomerPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Credit Curr. Appln. Rndg. Acc."));
        CustomerPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Debit Curr. Appln. Rndg. Acc."));
        CustomerPostingGroup.Validate("Debit Rounding Account", MakeAdjustments.Convert("Debit Rounding Account"));
        CustomerPostingGroup.Validate("Credit Rounding Account", MakeAdjustments.Convert("Credit Rounding Account"));
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert("Payment Tolerance Debit Acc."));
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert("Payment Tolerance Credit Acc."));
        CustomerPostingGroup.Validate("Prepayment Account", MakeAdjustments.Convert("Prepayment Account"));
        CustomerPostingGroup.Insert();
    end;
}

