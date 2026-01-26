// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using System.Utilities;

report 15000006 "Rem. payment order status"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Payables/Rempaymentorderstatus.rdlc';
    Caption = 'Remittance payment order status';

    dataset
    {
        dataitem("Remittance Payment Order"; "Remittance Payment Order")
        {
            DataItemTableView = sorting(ID);
            RequestFilterFields = ID;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ID_RemittancePmtOrder; ID)
            {
            }
            column(Comment_RemittancePmtOrder; Comment)
            {
            }
            column(Type_RemittancePmtOrder; Type)
            {
            }
            column(Date_RemittancePmtOrder; Date)
            {
            }
            column(Time_RemittancePmtOrder; Time)
            {
            }
            column(Canceled_RemittancePmtOrder; Canceled)
            {
            }
            column(NumberSent_RemittancePmtOrder; "Number Sent")
            {
            }
            column(NumberApproved_RemittancePmtOrder; "Number Approved")
            {
            }
            column(NumberSettled_RemittancePmtOrder; "Number Settled")
            {
            }
            column(NumberRejected_RemittancePmtOrder; "Number Rejected")
            {
            }
            column(RemittancePmtOrderStatusCaption; RemittancePmtOrderStatusCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AmtLCYCaption_WaitingJournal; "Waiting Journal".FieldCaption("Amount (LCY)"))
            {
            }
            column(AmtCaption_WaitingJournal; "Waiting Journal".FieldCaption(Amount))
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            column(DescCaption_WaitingJournal; "Waiting Journal".FieldCaption(Description))
            {
            }
            column(AccNoCaption_WaitingJournal; "Waiting Journal".FieldCaption("Account No."))
            {
            }
            column(DocNoCaption_WaitingJournal; "Waiting Journal".FieldCaption("Document No."))
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(RefCaption_WaitingJournal; "Waiting Journal".FieldCaption(Reference))
            {
            }
            column(CommentCaption_RemittancePmtOrder; FieldCaption(Comment))
            {
            }
            column(IDCaption_RemittancePmtOrder; FieldCaption(ID))
            {
            }
            column(TypeCaption_RemittancePmtOrder; FieldCaption(Type))
            {
            }
            column(DateCaption_RemittancePmtOrder; FieldCaption(Date))
            {
            }
            column(TimeCaption_RemittancePmtOrder; FieldCaption(Time))
            {
            }
            column(CanceledCaption_RemittancePmtOrder; FieldCaption(Canceled))
            {
            }
            column(NumberSentCaption_RemittancePmtOrder; FieldCaption("Number Sent"))
            {
            }
            column(NumberApprovedCaption_RemittancePmtOrder; FieldCaption("Number Approved"))
            {
            }
            column(NumberSettledCaption_RemittancePmtOrder; FieldCaption("Number Settled"))
            {
            }
            column(NumberRejectedCaption_RemittancePmtOrder; FieldCaption("Number Rejected"))
            {
            }
            dataitem(WaitingJournalStatus; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 .. 4));
                column(Number; Number)
                {
                }
                dataitem("Waiting Journal"; "Waiting Journal")
                {
                    DataItemLinkReference = WaitingJournalStatus;
                    DataItemTableView = sorting(Reference);
                    column(Title; Title)
                    {
                    }
                    column(DocNo_WaitingJournal; "Document No.")
                    {
                    }
                    column(AccNo_WaitingJournal; "Account No.")
                    {
                    }
                    column(Desc_WaitingJournal; Description)
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
                    column(PostingDate_WaitingJournal; "Posting Date")
                    {
                    }
                    column(Reference_WaitingJournal; Reference)
                    {
                    }
                    column(TitleWithNegTotalLCYCaption; Title + NegTotalLCYCaptionLbl)
                    {
                    }
                    dataitem("Return Error"; "Return Error")
                    {
                        DataItemLink = "Waiting Journal Reference" = field(Reference);
                        DataItemTableView = sorting("Waiting Journal Reference", "Serial Number");
                        column(MsgText_ReturnError; "Message Text")
                        {
                        }
                        column(WaitingJnlRef_ReturnError; "Waiting Journal Reference")
                        {
                        }
                        column(SerialNo_ReturnError; "Serial Number")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Waiting Journal"."Remittance Status" <> "Waiting Journal"."Remittance Status"::Rejected then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        case WaitingJournalStatus.Number of
                            1:
                                begin
                                    Title := Text000;
                                    SetCurrentKey("Payment Order ID - Sent");
                                    SetRange("Payment Order ID - Sent", "Remittance Payment Order".ID);
                                end;
                            2:
                                begin
                                    Title := Text001;
                                    SetCurrentKey("Payment Order ID - Approved");
                                    SetRange("Payment Order ID - Approved", "Remittance Payment Order".ID);
                                end;
                            3:
                                begin
                                    Title := Text002;
                                    SetCurrentKey("Payment Order ID - Settled");
                                    SetRange("Payment Order ID - Settled", "Remittance Payment Order".ID);
                                end;
                            4:
                                begin
                                    Title := Text003;
                                    SetCurrentKey("Payment Order ID - Rejected");
                                    SetRange("Payment Order ID - Rejected", "Remittance Payment Order".ID);
                                end;
                        end;
                    end;
                }
            }
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
    }

    labels
    {
    }

    var
        Text000: Label 'Sent payments';
        Text001: Label 'Approved payments';
        Text002: Label 'Settled payments';
        Text003: Label 'Rejected payments';
        NegTotalLCYCaptionLbl: Label ' - total (LCY)';
        Title: Text[30];
        RemittancePmtOrderStatusCaptionLbl: Label 'Remittance payment order status';
        PageCaptionLbl: Label 'Page';
        CurrCodeCaptionLbl: Label 'Currency- code';
        PostingDateCaptionLbl: Label 'Posting- date';
}

