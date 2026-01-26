// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.GeneralLedger.Journal;

report 11000003 "Paymt. History - Change Status"
{
    Caption = 'Paymt. History - Change Status';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payment History Line"; "Payment History Line")
        {
            DataItemTableView = sorting("Our Bank", Status, "Run No.", Order, Date);
            RequestFilterFields = "Our Bank", "Run No.", "Line No.", Status, Identification, Date;

            trigger OnAfterGetRecord()
            var
                PaymentHistLine: Record "Payment History Line";
                "Financial interface": Codeunit "Financial Interface Telebank";
                GenJnlLine: Record "Gen. Journal Line" temporary;
            begin
                if Status <> Newstatus then begin
                    PaymentHistLine := "Payment History Line";

                    if Status in [Status::Rejected, Status::Cancelled, Status::Posted] then
                        Error(Text1000000 +
                          Text1000001, "Line No.");

                    case Newstatus of
                        Newstatus::New:
                            Error(Text1000002, FieldCaption(Status), Status::New);
                        Newstatus::Transmitted, Newstatus::"Request for Cancellation":
                            begin
                                PaymentHistLine.Status := Newstatus;
                                PaymentHistLine.Modify();
                            end;
                        Newstatus::Rejected, Newstatus::Cancelled:
                            begin
                                "Financial interface".ReversePaymReceived(GenJnlLine, PaymentHistLine, Newstatus, PaymHist);
                                "Financial interface".PostFDBR(GenJnlLine);
                                UpdateDirectDebitMandate(PaymentHistLine);
                            end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                PaymHist.Get(GetFilter("Our Bank"), GetFilter("Run No."));
            end;
        }
    }

    requestpage
    {
        Caption = 'Change status paym. hist. line';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewStatus; Newstatus)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Status';
                        OptionCaption = 'New,Transmitted,Request for Cancellation,Rejected,Cancelled';
                        ToolTip = 'Specifies the status that the payment history line will be changed to.';
                    }
                    label(Control1)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19009884;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Newstatus := Newstatus::Transmitted;
    end;

    var
        Text1000000: Label 'Once Rejected, Cancelled and Posted Entries cannot be modified anymore.\';
        Text1000001: Label 'Line %1';
        Text1000002: Label '%1 cannot be changed back to %2';
        PaymHist: Record "Payment History";
        Text19009884: Label 'The status of all payment history lines in the present filter will be modified into the new status mentioned below. The necessary ledger entries will be created automatically.';

    protected var
        Newstatus: Option New,Transmitted,"Request for Cancellation",Rejected,Cancelled;

    procedure UpdateDirectDebitMandate(var PaymentHistoryLine: Record "Payment History Line")
    var
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        MandatePaymentHistoryLine: Record "Payment History Line";
        CurrentMandateCounter: Integer;
    begin
        if DirectDebitMandate.Get(PaymentHistoryLine."Direct Debit Mandate ID") then begin
            DirectDebitMandate.Validate("Debit Counter", DirectDebitMandate."Debit Counter" - 1);
            DirectDebitMandate.Modify(true);

            MandatePaymentHistoryLine.SetRange("Direct Debit Mandate ID", PaymentHistoryLine."Direct Debit Mandate ID");
            MandatePaymentHistoryLine.SetFilter("Direct Debit Mandate Counter", '>%1', PaymentHistoryLine."Direct Debit Mandate Counter");
            if MandatePaymentHistoryLine.FindSet() then
                repeat
                    CurrentMandateCounter := MandatePaymentHistoryLine."Direct Debit Mandate Counter";
                    MandatePaymentHistoryLine.Validate("Direct Debit Mandate Counter", CurrentMandateCounter - 1);
                    MandatePaymentHistoryLine.Modify(true);
                until MandatePaymentHistoryLine.Next() = 0;

            PaymentHistoryLine.Validate("Direct Debit Mandate Counter", 0);
            PaymentHistoryLine.Modify(true);
        end;
    end;
}

