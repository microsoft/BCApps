codeunit 101092 "Create Cust. Posting Group"
{

    trigger OnRun()
    var
        GetGLAccNo: Codeunit "Get G/L Account No. and Name";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            InsertData(
              DemoDataSetup.DomesticCode(), XDomesticCustomersTxt,
              '992310', '996810', '999250', '999255', '999140', '999120', '999120', '999150', '999260', '999270');
            InsertData(
              DemoDataSetup.ForeignCode(), XForeignCustomersTxt,
              '992320', '996810', '999250', '999255', '999140', '999120', '999120', '999150', '999260', '999270');
            InsertData(
              DemoDataSetup.EUCode(), XCustomersInEUTxt,
              '992320', '996810', '999250', '999255', '999140', '999120', '999120', '999150', '999260', '999270');
        end else begin
            InsertData(
              DemoDataSetup.DomesticCode(), XDomesticCustomersTxt,
              GetGLAccNo.CustomersDomesticCAD(), GetGLAccNo.FeesandChargesRecDom(), GetGLAccNo.PaymentDiscountGranted(), GetGLAccNo.PmtDiscGrantedDecreases(), GetGLAccNo.InvoiceRounding(), GetGLAccNo.FinanceChargesfromCustomers(), GetGLAccNo.ApplicationRounding(), GetGLAccNo.PaymentToleranceGranted(), GetGLAccNo.PmtTolGrantedDecreases());
            InsertData(
              DemoDataSetup.ForeignCode(), XForeignCustomersTxt,
              GetGLAccNo.CustomersForeignFCY(), GetGLAccNo.FeesandChargesRecDom(), GetGLAccNo.PaymentDiscountGranted(), GetGLAccNo.PmtDiscGrantedDecreases(), GetGLAccNo.InvoiceRounding(), GetGLAccNo.FinanceChargesfromCustomers(), GetGLAccNo.ApplicationRounding(), GetGLAccNo.PaymentToleranceGranted(), GetGLAccNo.PmtTolGrantedDecreases());

        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticCustomersTxt: Label 'Domestic customers';
        XCustomersInEUTxt: Label 'EU Customers';
        XForeignCustomersTxt: Label 'Foreign customers (not EU)';

    procedure InsertData(Code: Code[20]; PostingGroupDescription: Text[50]; ReceivablesAccount: Code[20]; ServiceChargeAcc: Code[20]; PmtDiscDebitAcc: Code[20]; PmtDiscCreditAcc: Code[20]; InvoiceRoundingAccount: Code[20]; AdditionalFeeAcc: Code[20]; InterestAcc: Code[20]; ApplicationRoundingAccount: Code[20]; PaymentToleranceDebitAcc: Code[20]; PaymentToleranceCreditAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Validate(Code, Code);
        CustomerPostingGroup.Validate(Description, PostingGroupDescription);
        CustomerPostingGroup.Validate("Receivables Account", MakeAdjustments.Convert(ReceivablesAccount));
        CustomerPostingGroup.Validate("Service Charge Acc.", MakeAdjustments.Convert(ServiceChargeAcc));
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", MakeAdjustments.Convert(PmtDiscDebitAcc));
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", MakeAdjustments.Convert(PmtDiscCreditAcc));
        CustomerPostingGroup.Validate("Additional Fee Account", MakeAdjustments.Convert(AdditionalFeeAcc));
        CustomerPostingGroup.Validate("Interest Account", MakeAdjustments.Convert(InterestAcc));
        CustomerPostingGroup.Validate("Invoice Rounding Account", MakeAdjustments.Convert(InvoiceRoundingAccount));
        CustomerPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert(ApplicationRoundingAccount));
        CustomerPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert(ApplicationRoundingAccount));
        CustomerPostingGroup.Validate("Debit Rounding Account", MakeAdjustments.Convert(ApplicationRoundingAccount));
        CustomerPostingGroup.Validate("Credit Rounding Account", MakeAdjustments.Convert(ApplicationRoundingAccount));
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert(PaymentToleranceDebitAcc));
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert(PaymentToleranceCreditAcc));
        CustomerPostingGroup.Insert();
    end;

    procedure GetRoundingAccount(): code[20]
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        exit(MakeAdjustments.Convert('999150'));
    end;

    procedure InsertData(Code: Code[20]; PostingGroupDescription: Text[50]; ReceivablesAccount: Code[20]; ServiceChargeAcc: Code[20]; PmtDiscDebitAcc: Code[20]; PmtDiscCreditAcc: Code[20]; InvoiceRoundingAccount: Code[20]; AdditionalFeeAcc: Code[20]; ApplicationRoundingAccount: Code[20]; PaymentToleranceDebitAcc: Code[20]; PaymentToleranceCreditAcc: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Validate(Code, Code);
        CustomerPostingGroup.Validate(Description, PostingGroupDescription);
        CustomerPostingGroup.Validate("Receivables Account", ReceivablesAccount);
        CustomerPostingGroup.Validate("Service Charge Acc.", ServiceChargeAcc);
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", PmtDiscDebitAcc);
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", PmtDiscCreditAcc);
        CustomerPostingGroup.Validate("Additional Fee Account", AdditionalFeeAcc);
        CustomerPostingGroup.Validate("Interest Account", AdditionalFeeAcc);
        CustomerPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingAccount);
        CustomerPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", ApplicationRoundingAccount);
        CustomerPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", ApplicationRoundingAccount);
        CustomerPostingGroup.Validate("Debit Rounding Account", ApplicationRoundingAccount);
        CustomerPostingGroup.Validate("Credit Rounding Account", ApplicationRoundingAccount);
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", PaymentToleranceDebitAcc);
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", PaymentToleranceCreditAcc);
        CustomerPostingGroup.Insert();
    end;
}

