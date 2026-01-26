// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 10614 "Cust. Ledger Entries on Hold"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustLedgerEntriesonHold.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Cust. Ledger Entries on Hold';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date") where(Open = const(true), "On Hold" = filter(<> ''));
            RequestFilterFields = "Due Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustLedgEntryCustLedgEntryFilter; "Cust. Ledger Entry".TableName + ': ' + CustLedgEntryFilter)
            {
            }
            column(CustLedgEntryFilter; CustLedgEntryFilter)
            {
            }
            column(DueDate_CustLedgerEntry; Format("Due Date"))
            {
            }
            column(PostingDate_CustLedgerEntry; Format("Posting Date"))
            {
            }
            column(DocumentType_CustLedgerEntry; "Document Type")
            {
            }
            column(DocumentNo_CustLedgerEntry; "Document No.")
            {
            }
            column(Description_CustLedgerEntry; Description)
            {
            }
            column(CustomerNo_CustLedgerEntry; "Customer No.")
            {
            }
            column(CustName_CustLedgerEntry; Cust.Name)
            {
            }
            column(RemainingAmount_CustLedgerEntry; "Remaining Amount")
            {
            }
            column(CurrencyCode_CustLedgerEntry; "Currency Code")
            {
            }
            column(OnHold_CustLedgerEntry; "On Hold")
            {
            }
            column(RemainingAmtLCY_CustLedgerEntry; "Remaining Amt. (LCY)")
            {
            }
            column(CustLedgerEntriesonHoldCaption; CustLedgerEntriesonHoldCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(DocumentNoCaption_CustLedgerEntry; FieldCaption("Document No."))
            {
            }
            column(DescriptionCaption_CustLedgerEntry; FieldCaption(Description))
            {
            }
            column(CustomerNoCaption_CustLedgerEntry; FieldCaption("Customer No."))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(RemainingAmountCaption_CustLedgerEntry; FieldCaption("Remaining Amount"))
            {
            }
            column(OnHoldCaption_CustLedgerEntry; FieldCaption("On Hold"))
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Cust.Get("Customer No.");
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
        CustLedgEntryFilter := "Cust. Ledger Entry".GetFilters();
    end;

    var
        Cust: Record Customer;
        CustLedgEntryFilter: Text[250];
        CustLedgerEntriesonHoldCaptionLbl: Label 'Cust. Ledger Entries on Hold';
        PageCaptionLbl: Label 'Page';
        DueDateCaptionLbl: Label 'Due Date';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocumentTypeCaptionLbl: Label 'Document Type';
        NameCaptionLbl: Label 'Name';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
}

