// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 319 "Payments on Hold"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/PaymentsonHold.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Payments on Hold';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date") where(Open = const(true), "On Hold" = filter(<> ''));
            RequestFilterFields = "Due Date";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Vendor_Ledger_Entry__TABLECAPTION__________VendLedgEntryFilter; TableCaption + ': ' + VendLedgEntryFilter)
            {
            }
            column(VendLedgEntryFilter; VendLedgEntryFilter)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_; Format("Due Date"))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_; Format("Posting Date"))
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
            {
            }
            column(Vendor_Ledger_Entry__Document_No__; "Document No.")
            {
            }
            column(Vendor_Ledger_Entry_Description; Description)
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
            {
            }
            column(Vend_Name; Vend.Name)
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amount_; "Remaining Amount")
            {
            }
            column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
            {
            }
            column(Vendor_Ledger_Entry__On_Hold_; "On Hold")
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
            {
            }
            column(Payments_on_HoldCaption; Payments_on_HoldCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Due_Date_Caption; Vendor_Ledger_Entry__Due_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; Vendor_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; Vendor_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(Vendor_Ledger_Entry_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; FieldCaption("Vendor No."))
            {
            }
            column(Vend_NameCaption; Vend_NameCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amount_Caption; FieldCaption("Remaining Amount"))
            {
            }
            column(Vendor_Ledger_Entry__On_Hold_Caption; FieldCaption("On Hold"))
            {
            }
            column(Vendor_Ledger_Entry__Remaining_Amt___LCY__Caption; Vendor_Ledger_Entry__Remaining_Amt___LCY__CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Remaining Amt. (LCY)");
                Vend.Get("Vendor No.");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Payments on Hold';
        AboutText = 'Print a checklist of all vendor ledger entries where the invoice is in dispute and the On Hold field isn''''t blank.';

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
        VendLedgEntryFilter := "Vendor Ledger Entry".GetFilters();
    end;

    var
        Vend: Record Vendor;
        VendLedgEntryFilter: Text;
        Payments_on_HoldCaptionLbl: Label 'Payments on Hold';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vendor_Ledger_Entry__Due_Date_CaptionLbl: Label 'Due Date';
        Vendor_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Vendor_Ledger_Entry__Document_Type_CaptionLbl: Label 'Document Type';
        Vend_NameCaptionLbl: Label 'Name';
        Vendor_Ledger_Entry__Remaining_Amt___LCY__CaptionLbl: Label 'Total (LCY)';
}

