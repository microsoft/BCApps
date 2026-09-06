namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;

tableextension 11349 "Payment Export Data NL" extends "Payment Export Data"
{
    [Scope('OnPrem')]
    procedure CollectDataFromLocalSource(GenJnlLine: Record "Gen. Journal Line")
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        if PaymentHistoryLine.Get(GenJnlLine."Bal. Account No.", GenJnlLine."Document No.", GenJnlLine."Line No.") then begin
            Rec."Recipient Name" := PaymentHistoryLine."Account Holder Name";
            Rec."Recipient Address" := PaymentHistoryLine."Account Holder Address";
            Rec."Recipient City" := PaymentHistoryLine."Account Holder City";
            Rec."Recipient Post Code" := PaymentHistoryLine."Account Holder Post Code";
            Rec."Recipient Country/Region Code" := PaymentHistoryLine."Acc. Hold. Country/Region Code";

            if PaymentHistoryLine.Urgent then
                Rec.Validate("SEPA Instruction Priority", Rec."SEPA Instruction Priority"::HIGH)
            else
                Rec.Validate("SEPA Instruction Priority", Rec."SEPA Instruction Priority"::NORMAL);
        end;
    end;
}
