// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 10740 "Long Term Sales Invoices"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/LongTermSalesInvoices.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Long Term Sales Invoices';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(LongTermSalesInvoicesCaption; LongTermSalesInvoicesLbl)
            {
            }
            dataitem(OpenInvoices; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.") where(Open = const(true), "Document Type" = const(Invoice));
                column(DocumentNo_OpenInvoices; "Document No.")
                {
                }
                column(CustomerNo_OpenInvoices; "Customer No.")
                {
                }
                column(PostingDateFormat_OpenInvoices; Format("Posting Date"))
                {
                }
                column(DocumentDateFormat_OpenInvoices; Format("Document Date"))
                {
                }
                column(DueDateFormat_OpenInvoices; Format("Due Date"))
                {
                }
                column(RemainingAmt_OpenInvoices; "Remaining Amount")
                {
                }
                column(CustomerName; CustomerName)
                {
                }
                column(PaymentMethodCode; PaymentMethodCode)
                {
                }
                column(PaymentTermsCode; PaymentTermsCode)
                {
                }
                column(ShowregIn; ShowregIn)
                {
                }
                column(EntryNo_OpenInvoices; "Entry No.")
                {
                }
                column(DocumentNoCaption_OpenInvoices; FieldCaption("Document No."))
                {
                }
                column(CustomerNoCaption_OpenInvoices; FieldCaption("Customer No."))
                {
                }
                column(PostingDateCaption_OpenInvoices; PostingDateCaptionLbl)
                {
                }
                column(DocumentDateCaption_OpenInvoices; DocumentDateCaptionLbl)
                {
                }
                column(DueDateCaption_OpenInvoices; DueDateCaptionLbl)
                {
                }
                column(TotalCaption_OpenInvoices; TotalCaptionLbl)
                {
                }
                column(CustomerNameCaption; CustomerNameCaptionLbl)
                {
                }
                column(PaymentMethodCodeCaption; PaymentMethodCodeCaptionLbl)
                {
                }
                column(PaymentTermsCodeCaption; PaymentTermsCodeCaptionLbl)
                {
                }
                column(Open_Sales_InvoicesCaption; OpenSalesInvoicesCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GetCustomerName("Customer No.");
                    GetPaymentMethodAndTermsCode("Document No.");

                    ShowregIn := ShowRegister("Posting Date", "Due Date");
                end;
            }
            dataitem(OpenBills; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.") where(Open = const(true), "Document Type" = const(Bill));
                column(DocumentNo_OpenBills; "Document No.")
                {
                }
                column(BillNo_OpenBills; "Bill No.")
                {
                }
                column(CustomerNo_OpenBills; "Customer No.")
                {
                }
                column(CustomerName_OpenBills; CustomerName)
                {
                }
                column(PostingDateFormat_OpenBills; Format("Posting Date"))
                {
                }
                column(DocumentDateFormat_OpenBills; Format("Document Date"))
                {
                }
                column(DueDateFormat_OpenBills; Format("Due Date"))
                {
                }
                column(DocSituation_OpenBills; "Document Situation")
                {
                }
                column(DocuStatus_OpenBills; "Document Status")
                {
                }
                column(RemainingAmt_OpenBills; "Remaining Amount")
                {
                }
                column(ShowregBi; ShowregBi)
                {
                }
                column(EntryNo_OpenBills; "Entry No.")
                {
                }
                column(DocumentNoCaption_OpenBills; FieldCaption("Document No."))
                {
                }
                column(BillNoCaption_OpenBills; FieldCaption("Bill No."))
                {
                }
                column(CustomerNoCaption_OpenBills; FieldCaption("Customer No."))
                {
                }
                column(CustomerNameCaption_OpenBills; CustomerNameCaptionLbl)
                {
                }
                column(PostingDateCaption_OpenBills; PostingDateCaptionLbl)
                {
                }
                column(DueDateCaption_OpenBills; DueDateCaptionLbl)
                {
                }
                column(DocumentDateCaption_OpenBills; DocumentDateCaptionLbl)
                {
                }
                column(DocSituationCaption_OpenBills; FieldCaption("Document Situation"))
                {
                }
                column(DocStatusCaption_OpenBills; FieldCaption("Document Status"))
                {
                }
                column(TotalCaption_OpenBills; TotalCaptionLbl)
                {
                }
                column(OpenSalesBillsCaption; OpenSalesBillsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GetCustomerName("Customer No.");

                    ShowregBi := ShowRegister("Posting Date", "Due Date");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Due Date Period Length"; DueDatePeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due Date Period Length';
                        ToolTip = 'Specifies the length of the due date period.';
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

    trigger OnPreReport()
    begin
        if Format(DueDatePeriodLength) = '' then
            Error(Text1100000, CurrReport.ObjectId());
    end;

    var
        Customer: Record Customer;
        PaymentMethodCode: Code[10];
        PaymentTermsCode: Code[10];
        CustomerName: Text[30];
        DueDatePeriodLength: DateFormula;
        Text1100000: Label 'Due Date Period Length should be filled in to run this %1.';
        ShowregBi: Boolean;
        ShowregIn: Boolean;
        PageNoCaptionLbl: Label 'Page';
        LongTermSalesInvoicesLbl: Label 'Long Term Sales Invoices';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocumentDateCaptionLbl: Label 'Document Date';
        DueDateCaptionLbl: Label 'Due Date';
        TotalCaptionLbl: Label 'Total';
        CustomerNameCaptionLbl: Label 'Customer Name';
        PaymentMethodCodeCaptionLbl: Label 'Payment Method Code';
        PaymentTermsCodeCaptionLbl: Label 'Payment Terms Code';
        OpenSalesInvoicesCaptionLbl: Label 'Open Sales Invoices';
        OpenSalesBillsCaptionLbl: Label 'Open Sales Bills';

    [Scope('OnPrem')]
    procedure ShowRegister(PostingDate: Date; DueDate: Date): Boolean
    begin
        if DueDate >= CalcDate(DueDatePeriodLength, PostingDate) then
            exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetCustomerName(CustomerNo: Code[20])
    begin
        if Customer.Get(CustomerNo) then
            CustomerName := Customer.Name;
    end;

    [Scope('OnPrem')]
    procedure GetPaymentMethodAndTermsCode(DocNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if SalesInvHeader.Get(DocNo) then begin
            PaymentMethodCode := SalesInvHeader."Payment Method Code";
            PaymentTermsCode := SalesInvHeader."Payment Terms Code";
        end;
    end;
}

