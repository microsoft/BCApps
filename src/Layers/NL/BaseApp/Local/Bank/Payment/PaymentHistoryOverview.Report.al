// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

report 11000002 "Payment History Overview"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/PaymentHistoryOverview.rdlc';
    Caption = 'Payment History Overview';

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            PrintOnlyIfDetail = true;
            column(CreditLimit_BankAcc; "Bank Account".GetCreditLimit())
            {
            }
            column(IBAN_BankAcc; IBAN)
            {
            }
            column(PaymentHistory_BankAcc; "Payment History")
            {
            }
            column(MinBalance_BankAcc; "Min. Balance")
            {
            }
            column(NameNo; Name + ' (' + "No." + ')')
            {
            }
            column(Proposal_BankAcc; Proposal)
            {
            }
            column(Balance_BankAcc; Balance)
            {
            }
            column(PageNo; PageNo)
            {
            }
            column(No_BankAcc; "No.")
            {
            }
            column(CreditLimitCaption; CreditLimitCaptionLbl)
            {
            }
            column(OpenInPaymentRunCaption; OpenInPaymentRunCaptionLbl)
            {
            }
            column(MinBalanceCaption_BankAcc; FieldCaption("Min. Balance"))
            {
            }
            column(TotalInProposalCaption; TotalInProposalCaptionLbl)
            {
            }
            column(BankAccountBalanceCaption; BankAccountBalanceCaptionLbl)
            {
            }
            column(IBANCaption_BankAcc; FieldCaption(IBAN))
            {
            }
            column(OurBankCaption; OurBankCaptionLbl)
            {
            }
            dataitem("Payment History"; "Payment History")
            {
                DataItemLink = "Our Bank" = field("No.");
                DataItemTableView = sorting("Our Bank", "Run No.");
                RequestFilterFields = "Run No.", "Creation Date", "User ID", "Sent On", "Sent By", "Export Protocol", Export;
                column(RunNo_PaymentHistory; "Run No.")
                {
                }
                column(Status_PaymentHistory; Status)
                {
                }
                column(SentOn_PaymentHistory; "Sent On")
                {
                }
                column(ExportProtocol_PaymentHistory; "Export Protocol")
                {
                }
                column(SentBy_PaymentHistory; "Sent By")
                {
                }
                column(FileOnDisk_PaymentHistory; "File on Disk")
                {
                }
                column(Currency_PaymentHistory; Currency)
                {
                }
                column(OurBank_PaymentHistory; "Our Bank")
                {
                }
                column(RunNoCaption_PaymentHistory; FieldCaption("Run No."))
                {
                }
                column(StatusCaption_PaymentHistory; FieldCaption(Status))
                {
                }
                column(SentOnCaptionPaymentHistory; FieldCaption("Sent On"))
                {
                }
                column(ExportProtocolCaption_PaymentHistory; FieldCaption("Export Protocol"))
                {
                }
                column(SentByCaption_PaymentHistory; FieldCaption("Sent By"))
                {
                }
                column(FileOnDiskCaption_PaymentHistory; FieldCaption("File on Disk"))
                {
                }
                column(CurrencyCaption; CurrencyCaptionLbl)
                {
                }
                dataitem("Payment History Line"; "Payment History Line")
                {
                    DataItemLink = "Our Bank" = field("Our Bank"), "Run No." = field("Run No.");
                    DataItemTableView = sorting("Our Bank", "Run No.", "Line No.");
                    column(Desc4_PaymentHistoryLine; "Description 4")
                    {
                    }
                    column(Desc3_PaymentHistoryLine; "Description 3")
                    {
                    }
                    column(AccHolderName_PaymentHistoryLine; "Account Holder Name")
                    {
                    }
                    column(GetSourceName; GetSourceName())
                    {
                    }
                    column(Desc2_PaymentHistoryLine; "Description 2")
                    {
                    }
                    column(Desc1_PaymentHistoryLine; "Description 1")
                    {
                    }
                    column(Identification_PaymentHistoryLine; Identification)
                    {
                    }
                    column(AccNo_PaymentHistoryLine; "Account No.")
                    {
                    }
                    column(BankAccNo_PaymentHistoryLine; "Bank Account No.")
                    {
                    }
                    column(DateFormatted; Format(Date))
                    {
                    }
                    column(Amount_PaymentHistoryLine; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AccType_PaymentHistoryLine; "Account Type")
                    {
                    }
                    column(PaymReceived; PaymReceived)
                    {
                    }
                    column(Status_PaymentHistoryLine; Status)
                    {
                    }
                    column(CurrCode_PaymentHistoryLine; "Currency Code")
                    {
                    }
                    column(TotalRunNo; "Payment History"."Run No.")
                    {
                    }
                    column(TotalAmount1; TotalAmount1)
                    {
                    }
                    column(OurBank_PaymentHistoryLine; "Our Bank")
                    {
                    }
                    column(RunNo_PaymentHistoryLine; "Run No.")
                    {
                    }
                    column(LineNo_PaymentHistoryLine; "Line No.")
                    {
                    }
                    column(DateCaption; DateCaptionLbl)
                    {
                    }
                    column(BankCaption; BankCaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(TotalStatusCaption; TotalStatusCaptionLbl)
                    {
                    }
                    column(IBAN_PaymentHistoryLine; IBAN)
                    {
                    }
                    dataitem("Detail Line"; "Detail Line")
                    {
                        DataItemLink = "Our Bank" = field("Our Bank"), "Connect Batches" = field("Run No."), "Connect Lines" = field("Line No.");
                        DataItemTableView = sorting("Our Bank", Status, "Connect Batches", "Connect Lines", Date) where(Status = filter("In process" | Posted | Correction));
                        column(CurrCode_DetailLine; "Currency Code")
                        {
                        }
                        column(TotalAmount; TotalAmount)
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
                        column(ConnectBatches_DetailLine; "Connect Batches")
                        {
                        }
                        column(ConnectLines_DetailLine; "Connect Lines")
                        {
                        }
                        column(SerialNoEntry_DetailLine; "Serial No. (Entry)")
                        {
                        }
                        column(AmountPaidCaption; AmountPaidCaptionLbl)
                        {
                        }
                        column(OutstandingAmountCaption; OutstandingAmountCaptionLbl)
                        {
                        }
                        column(OriginalAmountCaption; OriginalAmountCaptionLbl)
                        {
                        }
                        column(OurDocumentNoCaption; OurDocumentNoCaptionLbl)
                        {
                        }
                        column(YourDocumentNoCaption; YourDocumentNoCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalStatusCaptionLbl)
                        {
                        }
                        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                        {
                            CalcFields = Amount, "Remaining Amount";
                            DataItemLink = "Entry No." = field("Serial No. (Entry)");
                            DataItemTableView = sorting("Entry No.");
                            column(Desc_CustLedgEntry; Description)
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
                            column(DocType_CustLedgEntry; "Document Type")
                            {
                            }
                            column(DocDate_CustLedgEntry; Format("Document Date"))
                            {
                            }
                            column(DocNo_CustLedgEntry; "Document No.")
                            {
                            }
                            column(ExtDocNo_CustLedgEntry; "External Document No.")
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
                                column(Desc_Customerhist1; Description)
                                {
                                }
                                column(RemAmount_Customerhist1; "Remaining Amount")
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(Amount_Customerhist1; Amount)
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(DocType_Customerhist1; "Document Type")
                                {
                                }
                                column(CurrCode_Customerhist1; "Currency Code")
                                {
                                }
                                column(DocDate_Customerhist1; Format("Document Date"))
                                {
                                }
                                column(DocNo_Customerhist1; "Document No.")
                                {
                                }
                                column(ExtDocNo_Customerhist1; "External Document No.")
                                {
                                }
                                column(EntryNo_Customerhist1; "Entry No.")
                                {
                                }
                                column(ClosedByEntryNo_Customerhist1; "Closed by Entry No.")
                                {
                                }
                            }
                            dataitem(Customerhist2; "Cust. Ledger Entry")
                            {
                                CalcFields = Amount, "Remaining Amount";
                                DataItemLink = "Entry No." = field("Closed by Entry No.");
                                DataItemTableView = sorting("Entry No.");
                                column(Desc_Customerhist2; Description)
                                {
                                }
                                column(RemAmount_Customerhist2; "Remaining Amount")
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(Amount_Customerhist2; Amount)
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(DocType_Customerhist2; "Document Type")
                                {
                                }
                                column(CurrCode_Customerhist2; "Currency Code")
                                {
                                }
                                column(DocDate_Customerhist2; Format("Document Date"))
                                {
                                }
                                column(DocNo_Customerhist2; "Document No.")
                                {
                                }
                                column(ExtDoc_Customerhist2; "External Document No.")
                                {
                                }
                                column(EntryNo_Customerhist2; "Entry No.")
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
                            column(Desc_VendLedgEntry; Description)
                            {
                            }
                            column(DetailLineAmt; "Detail Line".Amount)
                            {
                                AutoFormatExpression = "Detail Line"."Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegRemAmount_VendLedgEntry; -"Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(NegAmt_VendLedgEntry; -Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(DocType_VendLedgEntry; "Document Type")
                            {
                            }
                            column(CurrCode_VendLedgEntry; "Currency Code")
                            {
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
                                column(Desc_Venhist1; Description)
                                {
                                }
                                column(NegRemAmt_Venhist1; -"Remaining Amount")
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(NegAmt_Venhist1; -Amount)
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(DocType_Venhist1; "Document Type")
                                {
                                }
                                column(CurrCode_Venhist1; "Currency Code")
                                {
                                }
                                column(DocDate_Venhist1; Format("Document Date"))
                                {
                                }
                                column(DocNo_Venhist1; "Document No.")
                                {
                                }
                                column(ExtDocNo_Venhist1; "External Document No.")
                                {
                                }
                                column(EntryNo_Venhist1; "Entry No.")
                                {
                                }
                                column(ClosedByEntryNo_Venhist1; "Closed by Entry No.")
                                {
                                }
                            }
                            dataitem(Venhist2; "Vendor Ledger Entry")
                            {
                                CalcFields = Amount, "Remaining Amount";
                                DataItemLink = "Entry No." = field("Closed by Entry No.");
                                DataItemTableView = sorting("Entry No.");
                                column(Desc_Venhist2; Description)
                                {
                                }
                                column(NegRemAmt_Venhist2; -"Remaining Amount")
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(NegAmt_Venhist2; -Amount)
                                {
                                    AutoFormatExpression = "Currency Code";
                                    AutoFormatType = 1;
                                }
                                column(DocType_Venhist2; "Document Type")
                                {
                                }
                                column(CurrCode_Venhist2; "Currency Code")
                                {
                                }
                                column(DocDate_Venhist2; Format("Document Date"))
                                {
                                }
                                column(DocNo_Venhist2; "Document No.")
                                {
                                }
                                column(ExtDocNo_Venhist2; "External Document No.")
                                {
                                }
                                column(EntryNo_Venhist2; "Entry No.")
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

                        trigger OnAfterGetRecord()
                        begin
                            TotalAmount := TotalAmount + Amount;
                        end;

                        trigger OnPreDataItem()
                        begin
                            TotalAmount := 0;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Order = Order::Debit then
                            PaymReceived := Text1000000
                        else
                            PaymReceived := Text1000001;

                        TotalAmount1 := Amount + TotalAmount1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalAmount1 := 0;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    "Payment History Line".SetRange("Our Bank", "Our Bank");
                    "Payment History Line".SetRange("Run No.", "Run No.");
                    if "Payment History Line".FindFirst() then
                        Currency := "Payment History Line"."Currency Code";
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
        Caption = 'Payment history overview';

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
        PaymReceived: Text[30];
        Currency: Code[10];
        PageNo: Integer;
        TotalAmount: Decimal;
        TotalAmount1: Decimal;
        CreditLimitCaptionLbl: Label 'Credit limit';
        OpenInPaymentRunCaptionLbl: Label 'PaymentRun';
        TotalInProposalCaptionLbl: Label 'Total in Proposal';
        BankAccountBalanceCaptionLbl: Label 'Balance';
        OurBankCaptionLbl: Label 'Our Bank';
        CurrencyCaptionLbl: Label 'Currency';
        DateCaptionLbl: Label 'Date';
        BankCaptionLbl: Label 'Bank';
        DescriptionCaptionLbl: Label 'Description';
        TotalStatusCaptionLbl: Label 'Total';
        AmountPaidCaptionLbl: Label 'Amount paid';
        OutstandingAmountCaptionLbl: Label 'Outstanding Amount';
        OriginalAmountCaptionLbl: Label 'Original Amount';
        OurDocumentNoCaptionLbl: Label 'Our Document No.';
        YourDocumentNoCaptionLbl: Label 'Your Document No.';
}

