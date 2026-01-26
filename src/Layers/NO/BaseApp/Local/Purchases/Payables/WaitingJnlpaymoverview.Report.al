// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

report 15000005 "Waiting Jnl - paym. overview"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Payables/WaitingJnlpaymoverview.rdlc';
    Caption = 'Waiting Journal - payment overview';

    dataset
    {
        dataitem("Waiting Journal"; "Waiting Journal")
        {
            DataItemTableView = sorting("Payment Order ID - Sent");
            RequestFilterFields = "Posting Date", "Document No.", "Remittance Status";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PymntOrderIDSent_WaitingJournal; "Payment Order ID - Sent")
            {
            }
            column(PaymOrderDate; PaymOrder.Date)
            {
            }
            column(PaymOrderTime; PaymOrder.Time)
            {
            }
            column(PostingDate_WaitingJournal; "Posting Date")
            {
            }
            column(DocumentNo_WaitingJournal; "Document No.")
            {
            }
            column(AccountNo_WaitingJournal; "Account No.")
            {
            }
            column(Description_WaitingJournal; Description)
            {
            }
            column(CurrCode_WaitingJournal; "Currency Code")
            {
            }
            column(Amount_WaitingJournal; Amount)
            {
            }
            column(AmountLCY_WaitingJournal; "Amount (LCY)")
            {
            }
            column(RemittanceStatus_WaitingJournal; "Remittance Status")
            {
            }
            column(Reference_WaitingJournal; Reference)
            {
            }
            column(ApprovedDate; ApprovedDate)
            {
            }
            column(TotalForPmtOrderLCYCaption; TotalForPmtOrderLCYCaptionLbl)
            {
            }
            column(TotalNOKCaption; TotalNOKCaptionLbl)
            {
            }
            column(WaitingJournalPaymentOverviewCaption; WaitingJournalPaymentOverviewCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(DocNoCaption_WaitingJournal; FieldCaption("Document No."))
            {
            }
            column(DescriptionCaption_WaitingJournal; FieldCaption(Description))
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            column(AmountCaption_WaitingJournal; FieldCaption(Amount))
            {
            }
            column(AmountLCYCaption_WaitingJournal; FieldCaption("Amount (LCY)"))
            {
            }
            column(AccountNoCaption_WaitingJournal; FieldCaption("Account No."))
            {
            }
            column(RemittanceStatusCaption; RemittanceStatusCaptionLbl)
            {
            }
            column(ReferenceCaption; ReferenceCaptionLbl)
            {
            }
            column(ApprovedDateCaption; ApprovedDateCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(PaymentOrderIDCaption; PaymentOrderIDCaptionLbl)
            {
            }
            column(ExportDateTimeCaption; ExportDateTimeCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if PaymOrder.Get("Payment Order ID - Approved") then
                    ApprovedDate := PaymOrder.Date
                else
                    ApprovedDate := 0D;
                PaymOrder.Get("Payment Order ID - Sent");
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("Payment Order ID - Sent");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }

        trigger OnInit()
        begin
            "Waiting Journal".SetFilter(
              "Remittance Status", '%1|%2',
              "Waiting Journal"."Remittance Status"::Sent, "Waiting Journal"."Remittance Status"::Approved);
        end;
    }

    labels
    {
    }

    var
        TotalForPmtOrderLCYCaptionLbl: Label 'Total for payment order (LCY)';
        TotalNOKCaptionLbl: Label 'Total (NOK)';
        PaymOrder: Record "Remittance Payment Order";
        ApprovedDate: Date;
        LastFieldNo: Integer;
        WaitingJournalPaymentOverviewCaptionLbl: Label 'Waiting journal - payment overview';
        PageCaptionLbl: Label 'Page';
        CurrCodeCaptionLbl: Label 'Currency- code';
        RemittanceStatusCaptionLbl: Label 'Remittance status';
        ReferenceCaptionLbl: Label 'Reference';
        ApprovedDateCaptionLbl: Label 'Approved date';
        PostingDateCaptionLbl: Label 'Posting date';
        PaymentOrderIDCaptionLbl: Label 'Payment order ID';
        ExportDateTimeCaptionLbl: Label 'Export date/time';
}

