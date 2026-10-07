// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

report 10054 "Open Sales Invoices by Job"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Project/Reports/OpenSalesInvoicesbyJob.rdlc';
    Caption = 'Open Sales Invoices by Job';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", Description, "Bill-to Customer No.", "Person Responsible";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Job_TABLECAPTION__________FilterString; Job.TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(TABLECAPTION___________No__; TableCaption + ': ' + "No.")
            {
            }
            column(Job_Description; Description)
            {
            }
            column(Job_No_; "No.")
            {
            }
            column(Open_Sales_Invoices_by_JobCaption; Open_Sales_Invoices_by_JobCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(SalesInvoiceHeader__Bill_to_Name_Caption; SalesInvoiceHeader__Bill_to_Name_CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Posting_Date_Caption; "Cust. Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Cust__Ledger_Entry__Due_Date_Caption; "Cust. Ledger Entry".FieldCaption("Due Date"))
            {
            }
            column(Cust__Ledger_Entry__Amount__LCY__Caption; Cust__Ledger_Entry__Amount__LCY__CaptionLbl)
            {
            }
            column(Amount__LCY______Remaining_Amt___LCY__Caption; Amount__LCY______Remaining_Amt___LCY__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Remaining_Amt___LCY__Caption; Cust__Ledger_Entry__Remaining_Amt___LCY__CaptionLbl)
            {
            }
            column(Cust__Ledger_Entry__Customer_No__Caption; "Cust. Ledger Entry".FieldCaption("Customer No."))
            {
            }
            column(Cust__Ledger_Entry__Currency_Code_Caption; "Cust. Ledger Entry".FieldCaption("Currency Code"))
            {
            }
            dataitem("Sales Invoice Line"; "Sales Invoice Line")
            {
                DataItemLink = "Job No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");
                PrintOnlyIfDetail = true;
                column(Job_TABLECAPTION__________Job__No________Total_____; Job.TableCaption + ': ' + Job."No." + '  Total ($)')
                {
                }
                column(Cust__Ledger_Entry___Amount__LCY__; "Cust. Ledger Entry"."Amount (LCY)")
                {
                }
                column(Cust__Ledger_Entry___Amount__LCY______Cust__Ledger_Entry___Remaining_Amt___LCY__; "Cust. Ledger Entry"."Amount (LCY)" - "Cust. Ledger Entry"."Remaining Amt. (LCY)")
                {
                }
                column(Cust__Ledger_Entry___Remaining_Amt___LCY__; "Cust. Ledger Entry"."Remaining Amt. (LCY)")
                {
                }
                column(Sales_Invoice_Line_Document_No_; "Document No.")
                {
                }
                column(Sales_Invoice_Line_Line_No_; "Line No.")
                {
                }
                column(Sales_Invoice_Line_Job_No_; "Job No.")
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemLink = "Document No." = field("Document No.");
                    DataItemTableView = sorting("Document No.", "Document Type", "Customer No.") where("Document Type" = const(Invoice), Open = const(true));
                    column(Cust__Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(SalesInvoiceHeader__Bill_to_Name_; SalesInvoiceHeader."Bill-to Name")
                    {
                    }
                    column(Cust__Ledger_Entry__Posting_Date_; "Posting Date")
                    {
                    }
                    column(Cust__Ledger_Entry__Due_Date_; "Due Date")
                    {
                    }
                    column(Cust__Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                    {
                    }
                    column(Amount__LCY______Remaining_Amt___LCY__; "Amount (LCY)" - "Remaining Amt. (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                    {
                    }
                    column(Cust__Ledger_Entry__Currency_Code_; "Currency Code")
                    {
                    }
                    column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    SetRange("Document No.", "Document No.");
                    Find('+');
                    SetRange("Document No.");
                    SalesInvoiceHeader.Get("Document No.");
                end;

                trigger OnPreDataItem()
                begin
                    if not SetCurrentKey("Job No.", "Document No.") then begin
                        SetCurrentKey("Document No.");
                        if not AlreadyDisplayedMessage then begin
                            Message(Text000 + Text001,
                              TableCaption, FieldCaption("Job No."), FieldCaption("Document No."));
                            AlreadyDisplayedMessage := true;
                        end;
                    end;
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

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
        FilterString := Job.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilterString: Text;
        AlreadyDisplayedMessage: Boolean;
        Text000: Label 'This report will run much faster next time if you add a key to';
        Text001: Label ' the %1 table (113) which starts with %2,%3';
        Open_Sales_Invoices_by_JobCaptionLbl: Label 'Open Sales Invoices by Job';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SalesInvoiceHeader__Bill_to_Name_CaptionLbl: Label 'Customer Name';
        Cust__Ledger_Entry__Amount__LCY__CaptionLbl: Label 'Invoice Amount';
        Amount__LCY______Remaining_Amt___LCY__CaptionLbl: Label 'Payments or Adjustments';
        Cust__Ledger_Entry__Remaining_Amt___LCY__CaptionLbl: Label 'Balance Due';
}

