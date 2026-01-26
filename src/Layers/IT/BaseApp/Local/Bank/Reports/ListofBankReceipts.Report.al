// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

report 12170 "List of Bank Receipts"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Reports/ListofBankReceipts.rdlc';
    Caption = 'List of Bank Receipts';

    dataset
    {
        dataitem("Customer Bill Header"; "Customer Bill Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(ReportHdr_CustBillHdr; "Report Header")
            {
            }
            column(Type_CustBillHdr; Type)
            {
            }
            column(ListOfRcptPresentedToBank; StrSubstNo(ListOfRcptPresentedToBankTxt, BankAccount.Name, BankAccount."Bank Branch No.", BankAccount.ABI, BankAccount.CAB))
            {
            }
            column(CompCounty; Company.County)
            {
            }
            column(CompanyPostCodeCity; Company."Post Code" + ' ' + Company.City)
            {
            }
            column(ListDateFormat_CustBillHdr; Format("List Date"))
            {
            }
            column(CompanyAddress; Company.Address)
            {
            }
            column(CompanyName; Company.Name)
            {
            }
            column(TestReportText; TestreportText)
            {
            }
            column(No_CustBillHdr; "No.")
            {
            }
            column(PageNoCaption; PageCaptionLbl)
            {
            }
            column(TypeCaption_CustBillHdr; FieldCaption(Type))
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(ListNoCaption; ListNoCaptionLbl)
            {
            }
            dataitem("Customer Bill Line"; "Customer Bill Line")
            {
                DataItemLink = "Customer Bill No." = field("No.");
                DataItemTableView = sorting("Customer No.", "Due Date", "Customer Bank Acc. No.", "Cumulative Bank Receipts") order(ascending);
                column(ReceiptNo; ReceiptNo)
                {
                }
                column(CustRecName; CustomerRec.Name)
                {
                }
                column(DocNo_CustBillLine; "Document No.")
                {
                }
                column(DocDateFormat_CustBillLine; Format("Document Date"))
                {
                }
                column(DocOccurrence_CustBillLine; "Document Occurrence")
                {
                }
                column(Amt_CustBillLine; Amount)
                {
                    AutoFormatType = 1;
                }
                column(DueDateFormat_CustBillLine; Format("Due Date"))
                {
                }
                column(CustBankAccName; CustBankAcc.Name)
                {
                }
                column(IsLine1; ShowLine)
                {
                }
                column(CustRecAddress; CustomerRec.Address)
                {
                }
                column(CustBankAccCAB; CustBankAcc.CAB)
                {
                }
                column(CustRecPostCodeCity; CustomerRec."Post Code" + ' ' + CustomerRec.City)
                {
                }
                column(CustBankAccABI; CustBankAcc.ABI)
                {
                }
                column(CustBankAccBankBranchNo; CustBankAcc."Bank Branch No.")
                {
                }
                column(IsLine2; not "Cumulative Bank Receipts")
                {
                }
                column(CumulativeBankRcptCaption; CumulativeBankRcptCaptionLbl)
                {
                }
                column(IsFooter; "Cumulative Bank Receipts")
                {
                }
                column(CustBillHdrTestReport; "Customer Bill Header"."Test Report")
                {
                }
                column(TotalBankRcptCaption; TotalBankRcptCaptionLbl)
                {
                }
                column(CustBillNo_CustBillLine; "Customer Bill No.")
                {
                }
                column(LineNo_CustBillLine; "Line No.")
                {
                }
                column(CustNo_CustBillLine; "Customer No.")
                {
                }
                column(DueDate_CustBillLine; "Due Date")
                {
                }
                column(CustBankAccNo_CustBillLine; "Customer Bank Acc. No.")
                {
                }
                column(CumulativeBankRcpts_CustBillLine; "Cumulative Bank Receipts")
                {
                }
                column(ReceiptNoCaption; ReceiptNoCaptionLbl)
                {
                }
                column(CustomerCaption; CustomerCaptionLbl)
                {
                }
                column(InvoiceNoCaption; InvoiceNoCaptionLbl)
                {
                }
                column(DocDateCaption; DocDateCaptionLbl)
                {
                }
                column(PaymentNoCaption; PaymentNoCaptionLbl)
                {
                }
                column(AmountCaption_CustBillLine; FieldCaption(Amount))
                {
                }
                column(DueDateCaption; DueDateCaptionLbl)
                {
                }
                column(BankAccCaption; BankAccCaptionLbl)
                {
                }
                column(MiscCaption; MiscCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ShowLine := true;

                    CustomerRec.Get("Customer No.");
                    if not CustBankAcc.Get("Customer No.", "Customer Bank Acc. No.") then
                        Clear(CustBankAcc);

                    if "Customer Bill Header"."Test Report" = true then
                        ReceiptNo := "Temporary Cust. Bill No."
                    else begin
                        ReceiptNo := "Customer Bill No.";
                        ShowLine := true;
                        if "Cumulative Bank Receipts" then
                            ShowLine := false;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Company.Get();

                BankAccount.Get("Bank Account No.");
                if "Test Report" then
                    TestreportText := Text000
                else
                    TestreportText := Format("Customer Bill List");
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
    }

    labels
    {
    }

    var
        Text000: Label 'Testreport';
        ListOfRcptPresentedToBankTxt: Label 'List of bank receipts presented to: %1 - branch %2  - ABI: %3 - CAB: %4.', Comment = '%1 - bank name, %2 - bank branch number, %3 - bank ABI code, %4 - bank CAB code.';
        CustomerRec: Record Customer;
        CustBankAcc: Record "Customer Bank Account";
        Company: Record "Company Information";
        BankAccount: Record "Bank Account";
        TestreportText: Text[30];
        ReceiptNo: Code[20];
        ShowLine: Boolean;
        PageCaptionLbl: Label 'Page';
        DateCaptionLbl: Label 'Date';
        ListNoCaptionLbl: Label 'List No.';
        CumulativeBankRcptCaptionLbl: Label 'CUMULATIVE BANK RECEIPT';
        TotalBankRcptCaptionLbl: Label 'TOTAL BANK RECEIPT';
        ReceiptNoCaptionLbl: Label 'Receipt No.';
        CustomerCaptionLbl: Label 'Customers';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        DocDateCaptionLbl: Label 'Document Date';
        PaymentNoCaptionLbl: Label 'Payment No.';
        DueDateCaptionLbl: Label 'Due Date';
        BankAccCaptionLbl: Label 'Bank Account';
        MiscCaptionLbl: Label 'Misc.';
}

