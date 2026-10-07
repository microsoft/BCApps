codeunit 101031 "Create Payment Reg. Setup"
{

    trigger OnRun()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.DeleteAll();

        PaymentRegistrationSetup.Init();
        PaymentRegistrationSetup.Validate("Journal Template Name", XPaymentTxt);
        PaymentRegistrationSetup.Validate("Journal Batch Name", XPmtRegTxt);
        PaymentRegistrationSetup."Auto Fill Date Received" := true;
        PaymentRegistrationSetup.Insert();
    end;

    var
        XPmtRegTxt: Label 'PMT REG', Comment = 'Payment Registration';
        XPaymentTxt: Label 'PAYMENT', Comment = 'Payment';
}

