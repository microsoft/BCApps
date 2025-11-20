// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

report 301 "Vendor - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Vendor_TABLECAPTION__________VendFilter; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(VendAddr_1_; VendAddr[1])
            {
            }
            column(Vendor__Vendor_Posting_Group_; "Vendor Posting Group")
            {
            }
            column(Vendor__Invoice_Disc__Code_; "Invoice Disc. Code")
            {
            }
            column(Vendor__Payment_Terms_Code_; "Payment Terms Code")
            {
            }
            column(Vendor__Payment_Method_Code_; "Payment Method Code")
            {
            }
            column(Vendor_Priority; Priority)
            {
            }
            column(Vendor__Currency_Code_; "Currency Code")
            {
            }
            column(Vendor__Balance__LCY__; "Balance (LCY)")
            {
            }
            column(VendAddr_2_; VendAddr[2])
            {
            }
            column(VendAddr_3_; VendAddr[3])
            {
            }
            column(VendAddr_4_; VendAddr[4])
            {
            }
            column(VendAddr_5_; VendAddr[5])
            {
            }
            column(Vendor_Contact; Contact)
            {
            }
            column(Vendor__Phone_No__; "Phone No.")
            {
            }
            column(VendAddr_6_; VendAddr[6])
            {
            }
            column(VendAddr_7_; VendAddr[7])
            {
            }
            column(Vendor___ListCaption; Vendor___ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(VendAddr_1_Caption; VendAddr_1_CaptionLbl)
            {
            }
            column(Vendor__Vendor_Posting_Group_Caption; Vendor__Vendor_Posting_Group_CaptionLbl)
            {
            }
            column(Vendor__Invoice_Disc__Code_Caption; Vendor__Invoice_Disc__Code_CaptionLbl)
            {
            }
            column(Vendor__Payment_Terms_Code_Caption; Vendor__Payment_Terms_Code_CaptionLbl)
            {
            }
            column(Vendor__Payment_Method_Code_Caption; Vendor__Payment_Method_Code_CaptionLbl)
            {
            }
            column(Vendor_PriorityCaption; FieldCaption(Priority))
            {
            }
            column(Vendor__Currency_Code_Caption; Vendor__Currency_Code_CaptionLbl)
            {
            }
            column(Vendor__Balance__LCY__Caption; FieldCaption("Balance (LCY)"))
            {
            }
            column(Vendor_ContactCaption; FieldCaption(Contact))
            {
            }
            column(Vendor__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Total__LCY_Caption; Total__LCY_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Balance (LCY)");
                FormatAddr.FormatAddr(
                  VendAddr, Name, "Name 2", '', Address, "Address 2",
                  City, "Post Code", County, "Country/Region Code");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Vendor List';
        AboutText = 'This is a legacy report for vendor analysis. See report documentation for alternatives.';
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
    end;

    var
        FormatAddr: Codeunit "Format Address";
        VendFilter: Text;
        VendAddr: array[8] of Text[100];
        Vendor___ListCaptionLbl: Label 'Vendor - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VendAddr_1_CaptionLbl: Label 'Name and Address';
        Vendor__Vendor_Posting_Group_CaptionLbl: Label 'Vendor Posting Group';
        Vendor__Invoice_Disc__Code_CaptionLbl: Label 'Invoice Disc. Code';
        Vendor__Payment_Terms_Code_CaptionLbl: Label 'Payment Terms Code';
        Vendor__Payment_Method_Code_CaptionLbl: Label 'Payment Method';
        Vendor__Currency_Code_CaptionLbl: Label 'Currency Code';
        Total__LCY_CaptionLbl: Label 'Total (LCY)';
}

