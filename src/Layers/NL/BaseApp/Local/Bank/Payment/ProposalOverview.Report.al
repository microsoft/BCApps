// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

report 11000001 "Proposal Overview"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/ProposalOverview.rdlc';
    Caption = 'Proposal Overview';

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            PrintOnlyIfDetail = true;
            column(NameNo; Name + ' (' + "No." + ')')
            {
            }
            column(IBAN_BankAcc; IBAN)
            {
            }
            column(Proposal_BankAcc; Proposal)
            {
            }
            column(PaymentHistory_BankAcc; "Payment History")
            {
            }
            column(CreditLimit_BankAcc; "Bank Account".GetCreditLimit())
            {
            }
            column(Balance_BankAcc; Balance)
            {
            }
            column(MinBalance_BankAcc; "Min. Balance")
            {
            }
            column(PageNo; PageNo)
            {
            }
            column(DateFormat; DateFormat)
            {
            }
            column(No_BankAcc; "No.")
            {
            }
            column(IBANCaption; FieldCaption(IBAN))
            {
            }
            column(OurBankCaption; OurBankCaptionLbl)
            {
            }
            column(TotalInProposalCaption; TotalInProposalCaptionLbl)
            {
            }
            column(OpenInPaymentRunCaption; OpenInPaymentRunCaptionLbl)
            {
            }
            column(CreditLimitCaption; CreditLimitCaptionLbl)
            {
            }
            column(BankAccountBalanceCaption; BankAccountBalanceCaptionLbl)
            {
            }
            column(MinBalanceCaption; FieldCaption("Min. Balance"))
            {
            }
            dataitem("Proposal Line"; "Proposal Line")
            {
                DataItemLink = "Our Bank No." = field("No.");
                DataItemTableView = sorting("Our Bank No.", Process, "Account Type", "Account No.", Bank, "Transaction Mode", "Currency Code", "Transaction Date");
                column(AccType_ProposalLine; "Account Type")
                {
                }
                column(AccNo_ProposalLine; "Account No.")
                {
                }
                column(BankAccNo_ProposalLine; "Bank Account No.")
                {
                }
                column(TransDate_ProposalLine; Format("Transaction Date"))
                {
                }
                column(Amount_ProposalLine; Amount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Description1_ProposalLine; "Description 1")
                {
                }
                column(Identification; Text1000002 + Identification)
                {
                }
                column(Description2_ProposalLine; "Description 2")
                {
                }
                column(Description3_ProposalLine; "Description 3")
                {
                }
                column(Description4_ProposalLine; "Description 4")
                {
                }
                column(PaymReceived; PaymReceived)
                {
                }
                column(AccHolderName_ProposalLine; "Account Holder Name")
                {
                }
                column(GetSourceName; GetSourceName())
                {
                }
                column(CurrCode_ProposalLine; "Currency Code")
                {
                }
                column(ErrorMsg_ProposalLine; "Error Message")
                {
                }
                column(Warning_ProposalLine; Warning)
                {
                }
                column(OurBankNo_ProposalLine; "Our Bank No.")
                {
                }
                column(LineNo_ProposalLine; "Line No.")
                {
                }
                column(TransactionDateCaption; TransactionDateCaptionLbl)
                {
                }
                column(BankCaption; BankCaptionLbl)
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(ErrorMsgCaption; FieldCaption("Error Message"))
                {
                }
                column(WarningCaption; FieldCaption(Warning))
                {
                }
                column(IBAN_PropLine; IBAN)
                {
                }
                dataitem("Detail Line"; "Detail Line")
                {
                    DataItemLink = "Our Bank" = field("Our Bank No."), "Connect Lines" = field("Line No.");
                    DataItemTableView = sorting("Our Bank", Status, "Connect Batches", "Connect Lines", Date) where(Status = const(Proposal));
                    column(CurrCode_DetailLine; "Currency Code")
                    {
                    }
                    column(Amount_DetailLine; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TransNo_DetailLine; "Transaction No.")
                    {
                    }
                    column(OurBank_DetailLine; "Our Bank")
                    {
                    }
                    column(ConnectLines_DetailLine; "Connect Lines")
                    {
                    }
                    column(SerialNoEntry_DetailLine; "Serial No. (Entry)")
                    {
                    }
                    column(OutstandingAmountCaption; OutstandingAmountCaptionLbl)
                    {
                    }
                    column(OriginalAmountCaption; OriginalAmountCaptionLbl)
                    {
                    }
                    column(DateCaption; DateCaptionLbl)
                    {
                    }
                    column(OurDocumentNoCaption; OurDocumentNoCaptionLbl)
                    {
                    }
                    column(YourDocumentNoCaption; YourDocumentNoCaptionLbl)
                    {
                    }
                    column(AmountPaidCaption; AmountpaidCaptionLbl)
                    {
                    }
                    column(CurrencyCaption; CurrencyCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                    {
                        CalcFields = Amount, "Remaining Amount";
                        DataItemLink = "Entry No." = field("Serial No. (Entry)");
                        DataItemTableView = sorting("Entry No.");
                        column(Description_CustLedgEntry; Description)
                        {
                        }
                        column(DetailLineAmount; "Detail Line".Amount)
                        {
                            AutoFormatExpression = "Detail Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(RemAmount_CustLedgEntry; "Remaining Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Amount_CustLedgEntry; Amount)
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(DocDate_CustLedgEntry; Format("Document Date"))
                        {
                        }
                        column(DocNo_CustLedgEntry; "Document No.")
                        {
                        }
                        column(ExternalDocNo_CustLedgEntry; "External Document No.")
                        {
                        }
                        column(DocType_CustLedgEntry; "Document Type")
                        {
                        }
                        column(CurrCode_CustLedgEntry; "Currency Code")
                        {
                        }
                        column(EntryNo_CustLedgEntry; "Entry No.")
                        {
                        }
                        column(ClosedByEntryNo_CustLedgEntry; "Closed by Entry No.")
                        {
                        }
                        dataitem(Customerhist1; "Cust. Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Closed by Entry No." = field("Entry No.");
                            DataItemTableView = sorting("Closed by Entry No.");
                            column(DescHist_CustLedgEntry; Description)
                            {
                            }
                            column(RemAmountHist_CustLedgEntry; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(AmountHist_CustLedgEntry; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocDateHist_CustLedgEntry; Format("Document Date"))
                            {
                            }
                            column(DocNoHist_CustLedgEntry; "Document No.")
                            {
                            }
                            column(ExtDocNoHist_CustLedgEntry; "External Document No.")
                            {
                            }
                            column(DocTypeHist_CustLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_CustLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_CustLedgEntry; "Entry No.")
                            {
                            }
                            column(ClosedByEntryNoHist_CustLedgEntry; "Closed by Entry No.")
                            {
                            }
                        }
                        dataitem(Customerhist2; "Cust. Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Entry No." = field("Closed by Entry No.");
                            DataItemTableView = sorting("Entry No.");
                            column(DescHist_CustomerLedgEntry; Description)
                            {
                            }
                            column(RemAmountHist_CustomerLedgEntry; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(AmountHist_CustomerLedgEntry; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocDateHist_CustomerLedgEntry; Format("Document Date"))
                            {
                            }
                            column(DocNoHist_CustomerLedgEntry; "Document No.")
                            {
                            }
                            column(ExDocNoHist_CustomerLedgEntry; "External Document No.")
                            {
                            }
                            column(DocTypeHist_CustomerLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_CustomerLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_CustomerLedgEntry; "Entry No.")
                            {
                            }
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Customer then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                    {
                        CalcFields = Amount, "Remaining Amount";
                        DataItemLink = "Entry No." = field("Serial No. (Entry)");
                        DataItemTableView = sorting("Entry No.");
                        column(Description_VendLedgEntry; Description)
                        {
                        }
                        column(DetailLineAmt; "Detail Line".Amount)
                        {
                            AutoFormatExpression = "Detail Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NegRemAmt_VendLedgEntry; -"Remaining Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NegAmt_VendLedgEntry; -Amount)
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(DocDate_VendLedgEntry; Format("Document Date"))
                        {
                        }
                        column(DocNo_VendLedgEntry; "Document No.")
                        {
                        }
                        column(ExtDocNo_VendLedgEntry; "External Document No.")
                        {
                        }
                        column(DocType_VendLedgEntry; "Document Type")
                        {
                        }
                        column(CurrCode_VendLedgEntry; "Currency Code")
                        {
                        }
                        column(EntryNo_VendLedgEntry; "Entry No.")
                        {
                        }
                        column(ClosedByEntryNo_VendLedgEntry; "Closed by Entry No.")
                        {
                        }
                        dataitem(Venhist1; "Vendor Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Closed by Entry No." = field("Entry No.");
                            DataItemTableView = sorting("Closed by Entry No.");
                            column(DescHist_VendLedgEntry; Description)
                            {
                            }
                            column(NegRemAmountHist_VendLedgEntry; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmountHist_VendLedgEntry; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocDateHist_VendLedgEntry; Format("Document Date"))
                            {
                            }
                            column(DocNoHist_VendLedgEntry; "Document No.")
                            {
                            }
                            column(ExtDocNoHist_VendLedgEntry; "External Document No.")
                            {
                            }
                            column(DocTypeHist_VendLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_VendLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_VendLedgEntry; "Entry No.")
                            {
                            }
                            column(ClosedByEntryNoHist_VendLedgEntry; "Closed by Entry No.")
                            {
                            }
                        }
                        dataitem(Venhist2; "Vendor Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Entry No." = field("Closed by Entry No.");
                            DataItemTableView = sorting("Entry No.");
                            column(DescHist_VendorLedgEntry; Description)
                            {
                            }
                            column(NegRemAmountHist_VendorLedgEntry; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmountHist_VendorLedgEntry; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocDateHist_VendorLedgEntry; Format("Document Date"))
                            {
                            }
                            column(DocNoHist_VendorLedgEntry; "Document No.")
                            {
                            }
                            column(ExtDocNoHist_VendorLedgEntry; "External Document No.")
                            {
                            }
                            column(DocTypeHist_VendorLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_VendorLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_VendorLedgEntry; "Entry No.")
                            {
                            }
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Vendor then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Employee Ledger Entry"; "Employee Ledger Entry")
                    {
                        CalcFields = Amount, "Remaining Amount";
                        DataItemLink = "Entry No." = field("Serial No. (Entry)");
                        DataItemTableView = sorting("Entry No.");
                        column(Description_EmplLedgEntry; Description)
                        {
                        }
                        column(DetailLineAmt_EmplLedgEntry; "Detail Line".Amount)
                        {
                            AutoFormatExpression = "Detail Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NegRemAmt_EmplLedgEntry; -"Remaining Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NegAmt_EmplLedgEntry; -Amount)
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(DocNo_EmplLedgEntry; "Document No.")
                        {
                        }
                        column(DocType_EmplLedgEntry; "Document Type")
                        {
                        }
                        column(CurrCode_EmplLedgEntry; "Currency Code")
                        {
                        }
                        column(EntryNo_EmplLedgEntry; "Entry No.")
                        {
                        }
                        column(ClosedByEntryNo_EmplLedgEntry; "Closed by Entry No.")
                        {
                        }
                        dataitem(Emphist1; "Employee Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Closed by Entry No." = field("Entry No.");
                            DataItemTableView = sorting("Closed by Entry No.");
                            column(DescHist_EmplLedgEntry; Description)
                            {
                            }
                            column(NegRemAmountHist_EmplLedgEntry; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmountHist_EmplLedgEntry; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocNoHist_EmplLedgEntry; "Document No.")
                            {
                            }
                            column(DocTypeHist_EmplLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_EmplLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_EmplLedgEntry; "Entry No.")
                            {
                            }
                            column(ClosedByEntryNoHist_EmplLedgEntry; "Closed by Entry No.")
                            {
                            }
                        }
                        dataitem(Emphist2; "Employee Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Entry No." = field("Closed by Entry No.");
                            DataItemTableView = sorting("Entry No.");
                            column(DescHist_EmployeeLedgEntry; Description)
                            {
                            }
                            column(NegRemAmountHist_EmployeeLedgEntry; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmountHist_EmployeeLedgEntry; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocNoHist_EmployeeLedgEntry; "Document No.")
                            {
                            }
                            column(DocTypeHist_EmployeeLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCodeHist_EmployeeLedgEntry; "Currency Code")
                            {
                            }
                            column(EntryNoHist_EmployeeLedgEntry; "Entry No.")
                            {
                            }
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Employee then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if "Proposal Line".Order = "Proposal Line".Order::Debit then
                        PaymReceived := Text1000000
                    else
                        PaymReceived := Text1000001;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PageNo := PageNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                PageNo := 0;
            end;
        }
    }

    requestpage
    {
        Caption = 'Proposal overview';

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
        Text1000000: Label 'Payment';
        Text1000001: Label 'Rec./Collection';
        Text1000002: Label 'Identification ';
        PaymReceived: Text[30];
        PageNo: Integer;
        DateFormat: Label 'dd-MM-yy';
        OurBankCaptionLbl: Label 'Our Bank';
        TotalInProposalCaptionLbl: Label 'Total in Proposal';
        OpenInPaymentRunCaptionLbl: Label 'Open in PaymentRun';
        CreditLimitCaptionLbl: Label 'Credit limit';
        BankAccountBalanceCaptionLbl: Label 'Bank Account Balance';
        TransactionDateCaptionLbl: Label 'Transaction Date';
        BankCaptionLbl: Label 'Bank';
        DescriptionCaptionLbl: Label 'Description';
        OutstandingAmountCaptionLbl: Label 'Outstanding Amount';
        OriginalAmountCaptionLbl: Label 'Original Amount';
        DateCaptionLbl: Label 'Date';
        OurDocumentNoCaptionLbl: Label 'Our Document No.';
        YourDocumentNoCaptionLbl: Label 'Your Document No.';
        AmountpaidCaptionLbl: Label 'Amount paid';
        CurrencyCaptionLbl: Label 'Currency';
        TotalCaptionLbl: Label 'Total';
}

