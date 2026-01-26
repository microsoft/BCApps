// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

report 12174 "Issued Cust Bills Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/IssuedCustBillsReport.rdlc';
    Caption = 'Issued Cust Bills Report';

    dataset
    {
        dataitem("Issued Customer Bill Header"; "Issued Customer Bill Header")
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(ReportHdr_IssuedCustBillHdr; "Report Header")
            {
            }
            column(BankRcptBankInfo; StrSubstNo(Text000, BankAccount.Name, BankAccount."Bank Branch No.", BankAccount.ABI, BankAccount.CAB))
            {
            }
            column(Type_IssuedCustBillHdr; Type)
            {
            }
            column(CompInfoPostCodeCompInfoCity; CompanyInformation."Post Code" + ' ' + CompanyInformation.City)
            {
            }
            column(CompanyInfoCounty; CompanyInformation.County)
            {
            }
            column(ListDate_IssuedCustBillHdr; Format("List Date"))
            {
            }
            column(CompanyInfoAddress; CompanyInformation.Address)
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(TestReportText; TestreportText)
            {
            }
            column(No_IssuedCustBillHeader; "No.")
            {
            }
            column(PageNoCaption; PageCaptionLbl)
            {
            }
            column(TypeCaption_IssuedCustBillHdr; FieldCaption(Type))
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(ListNoCaption; ListNoCaptionLbl)
            {
            }
            dataitem("Issued Customer Bill Line"; "Issued Customer Bill Line")
            {
                DataItemLink = "Customer Bill No." = field("No.");
                DataItemTableView = sorting("Customer Bill No.", "Final Cust. Bill No.") order(ascending) where("Recalled by" = filter(''));
                column(CustPostCodeCustCity; Customer."Post Code" + ' ' + Customer.City)
                {
                }
                column(CustVATRegNo; Customer."VAT Registration No.")
                {
                }
                column(CustAddress; Customer.Address)
                {
                }
                column(CustBankAccBankBranchNo; CustBankAcc."Bank Branch No.")
                {
                }
                column(CustName; Customer.Name)
                {
                }
                column(DocNo_IssuedCustBillLine; "Document No.")
                {
                }
                column(DocDateFormat_IssuedCustBillLine; Format("Document Date"))
                {
                }
                column(DocOccurrence_IssuedCustBillLine; "Document Occurrence")
                {
                }
                column(Amount_IssuedCustBillLine; Amount)
                {
                    AutoFormatType = 1;
                }
                column(DueDateFormat_IssuedCustBillLine; Format("Due Date"))
                {
                }
                column(CustBankAccName; CustBankAcc.Name)
                {
                }
                column(CustBankAccABI; CustBankAcc.ABI)
                {
                }
                column(CustBankAccCAB; CustBankAcc.CAB)
                {
                }
                column(FinalCustBillNo_IssuedCustBillLine; "Final Cust. Bill No.")
                {
                }
                column(LastRecord; LastRecord)
                {
                }
                column(CumulativeBankRcpts_IssuedCustBillLine; "Cumulative Bank Receipts")
                {
                }
                column(CumulativeBankRcptCaption; CumulativeBankReceiptLbl)
                {
                }
                column(CustBillNo_IssuedCustBillLine; "Customer Bill No.")
                {
                }
                column(LineNo_IssuedCustBillLine; "Line No.")
                {
                }
                column(CABCaption; CABCaptionLbl)
                {
                }
                column(ABICaption; ABICaptionLbl)
                {
                }
                column(CustBankAccNameCaption; BankAccCaptionLbl)
                {
                }
                column(IssuedCustBillLineDueDateCaption; DueDateCaptionLbl)
                {
                }
                column(AmtCaption_IssuedCustBillLine; FieldCaption(Amount))
                {
                }
                column(IssuedCustBillLineDocOccurrenceCaption; PaymentNoCaptionLbl)
                {
                }
                column(IssuedCustBillLineDocumentDateCaption; DocumentDateCaptionLbl)
                {
                }
                column(IssuedCustBillLineDocNoCaption; InvoiceNoCaptionLbl)
                {
                }
                column(CustNameCaption; CustomerCaptionLbl)
                {
                }
                column(FinalCustBillNoCaption_IssuedCustBillLine; FieldCaption("Final Cust. Bill No."))
                {
                }
                column(BankBranchNoCaption; BankBranchNoCaptionLbl)
                {
                }
                column(CustVATRegNoCaption; VATNoCaptionLbl)
                {
                }
                column(MiscCaption; MiscCaptionLbl)
                {
                }
                column(TotalBankReceiptCaption; TotalBankReceiptCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Customer.Get("Customer No.");
                    if not CustBankAcc.Get("Customer No.", "Customer Bank Acc. No.") then
                        Clear(CustBankAcc);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                BankAccount.Get("Bank Account No.");
                TestreportText := Format("No.");
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
    end;

    var
        Customer: Record Customer;
        CustBankAcc: Record "Customer Bank Account";
        CompanyInformation: Record "Company Information";
        BankAccount: Record "Bank Account";
        LastRecord: Boolean;
        TestreportText: Text[30];
        Text000: Label 'List of bank receipts presented to: %1 - branch %2 - ABI: %3 - CAB: %4';
        PageCaptionLbl: Label 'Page';
        DateCaptionLbl: Label 'Date';
        ListNoCaptionLbl: Label 'List No.';
        CumulativeBankReceiptLbl: Label 'CUMULATIVE BANK RECEIPT';
        CABCaptionLbl: Label 'CAB';
        ABICaptionLbl: Label 'ABI';
        BankAccCaptionLbl: Label 'Bank Account';
        DueDateCaptionLbl: Label 'Due Date';
        PaymentNoCaptionLbl: Label 'Payment No.';
        DocumentDateCaptionLbl: Label 'Document Date';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        CustomerCaptionLbl: Label 'Customers';
        BankBranchNoCaptionLbl: Label 'Bank Branch No.';
        VATNoCaptionLbl: Label 'VAT No.';
        MiscCaptionLbl: Label 'Misc.';
        TotalBankReceiptCaptionLbl: Label 'TOTAL BANK RECEIPT';
}

