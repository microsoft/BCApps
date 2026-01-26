// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 10741 "Long Term Purchase Invoices"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/LongTermPurchaseInvoices.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Long Term Purchase Invoices';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(ComapnyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(LongTermPurchInvoicesCaption; LongTermPurchInvoicesCaptionLbl)
            {
            }
            dataitem(OpenInvoices; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.") where(Open = const(true), "Document Type" = const(Invoice));
                column(DocumentNo_OpenInvoices; "Document No.")
                {
                }
                column(VendorNo_OpenInvoices; "Vendor No.")
                {
                }
                column(PostingDateFormatted_OpenInvoices; Format("Posting Date"))
                {
                }
                column(DocumentDateFormatted_OpenInvoices; Format("Document Date"))
                {
                }
                column(DueDateFormatted_OpenInvoices; Format("Due Date"))
                {
                }
                column(RemainingAmt_OpenInvoices; "Remaining Amount")
                {
                }
                column(VendorName; VendorName)
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
                column(DoctNoCaption_OpenInvoices; FieldCaption("Document No."))
                {
                }
                column(VendorNoCaption_OpenInvoices; FieldCaption("Vendor No."))
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(DocumentDateCaption; DocumentDateCaptionLbl)
                {
                }
                column(DueDateCaption; DueDateCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(VendorNameCaption; VendorNameCaptionLbl)
                {
                }
                column(PaymentMethodCodeCaption; PaymentMethodCodeCaptionLbl)
                {
                }
                column(PaymentTermsCodeCaption; PaymentTermsCodeCaptionLbl)
                {
                }
                column(OpenPurchaseInvoicesCaption; OpenPurchaseInvoicesCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GetVendorName("Vendor No.");
                    GetPaymentMethodAndTermsCode("Document No.");

                    ShowregIn := ShowRegister("Posting Date", "Due Date");
                end;
            }
            dataitem(OpenBills; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.") where(Open = const(true), "Document Type" = const(Bill));
                column(DocumentNo_OpenBills; "Document No.")
                {
                }
                column(BillNo_OpenBills; "Bill No.")
                {
                }
                column(VendorNo_OpenBills; "Vendor No.")
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
                column(DocumentSituation_OpenBills; "Document Situation")
                {
                }
                column(DocumentStatus_OpenBills; "Document Status")
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
                column(DocNoCaption_OpenBills; FieldCaption("Document No."))
                {
                }
                column(BillNoCaption_OpenBills; FieldCaption("Bill No."))
                {
                }
                column(VendorNoCaption_OpenBills; FieldCaption("Vendor No."))
                {
                }
                column(VendorName_OpenBills; VendorName)
                {
                }
                column(PostingDateCaption_OpenBills; PostingDateCaptionLbl)
                {
                }
                column(DocumentDateCaption_OpenBills; DocumentDateCaptionLbl)
                {
                }
                column(DueDateCaption_OpenBills; DueDateCaptionLbl)
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
                column(OpenPurchaseBillsCaption; OpenPurchaseBillsCaptionLbl)
                {
                }
                column(VendorNameCaption_OpenBills; VendorNameCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GetVendorName("Vendor No.");

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
        Vendor: Record Vendor;
        PaymentMethodCode: Code[10];
        PaymentTermsCode: Code[10];
        VendorName: Text[30];
        DueDatePeriodLength: DateFormula;
        Text1100000: Label 'Due Date Period Length should be filled in to run this %1.';
        ShowregIn: Boolean;
        ShowregBi: Boolean;
        PageNoCaptionLbl: Label 'Page';
        LongTermPurchInvoicesCaptionLbl: Label 'Long Term Purchase Invoices';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocumentDateCaptionLbl: Label 'Document Date';
        DueDateCaptionLbl: Label 'Due Date';
        TotalCaptionLbl: Label 'Total';
        VendorNameCaptionLbl: Label 'Vendor Name';
        PaymentMethodCodeCaptionLbl: Label 'Payment Method Code';
        PaymentTermsCodeCaptionLbl: Label 'Payment Terms Code';
        OpenPurchaseInvoicesCaptionLbl: Label 'Open Purchase Invoices';
        OpenPurchaseBillsCaptionLbl: Label 'Open Purchase Bills';

    [Scope('OnPrem')]
    procedure ShowRegister(PostingDate: Date; DueDate: Date): Boolean
    begin
        if DueDate >= CalcDate(DueDatePeriodLength, PostingDate) then
            exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetVendorName(VendorNo: Code[20])
    begin
        if Vendor.Get(VendorNo) then
            VendorName := Vendor.Name;
    end;

    [Scope('OnPrem')]
    procedure GetPaymentMethodAndTermsCode(DocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if PurchInvHeader.Get(DocNo) then begin
            PaymentMethodCode := PurchInvHeader."Payment Method Code";
            PaymentTermsCode := PurchInvHeader."Payment Terms Code";
        end;
    end;
}

