// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 11600 "Withholding Summary"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/WithholdingSummary.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Withholding Summary';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = where("Foreign Vend" = filter(false));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Vendor Posting Group", "Date Filter";
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(STRSUBSTNO___1_table___2__Vendor_TABLENAME_VendorFilter_; StrSubstNo('%1 table: %2', Vendor.TableName, VendorFilter))
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(VendorFilter; VendorFilter)
            {
            }
            column(Vendor_Date_Filter; "Date Filter")
            {
            }
            column(Page__Caption; Page__CaptionLbl)
            {
            }
            column(Withholding_SummaryCaption; Withholding_SummaryCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_Type_Caption; "Vendor Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; Vendor_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; "Vendor Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Vendor_Ledger_Entry_DescriptionCaption; "Vendor Ledger Entry".FieldCaption(Description))
            {
            }
            column(Vendor_Ledger_Entry_AmountCaption; "Vendor Ledger Entry".FieldCaption(Amount))
            {
            }
            column(Vendor_Ledger_Entry__WHT_Amount_Caption; "Vendor Ledger Entry".FieldCaption("WHT Amount"))
            {
            }
            column(Vendor_NameCaption; FieldCaption(Name))
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = field("No."), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code") where("WHT Amount" = filter(<> 0));
                column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Vendor_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Vendor_Ledger_Entry_Description; Description)
                {
                }
                column(Vendor_Ledger_Entry_Amount; Amount)
                {
                }
                column(Vendor_Ledger_Entry__WHT_Amount_; "WHT Amount")
                {
                }
                column(Vendor_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Vendor_Ledger_Entry__WHT_Amount__Control1450000; "WHT Amount")
                {
                }
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Vendor_Ledger_Entry_Vendor_No_; "Vendor No.")
                {
                }
                column(Vendor_Ledger_Entry_Posting_Date; "Posting Date")
                {
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

    trigger OnInitReport()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    trigger OnPreReport()
    begin
        VendorFilter := Vendor.GetFilters();
    end;

    var
        VendorFilter: Text[260];
        Page__CaptionLbl: Label 'Page :';
        Withholding_SummaryCaptionLbl: Label 'Withholding Summary';
        Vendor_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
}

