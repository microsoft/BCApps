// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Vendor;

report 10612 "Vendor - Address List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorAddressList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Address List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(Addr_Vendor; Address)
            {
            }
            column(PostCode_Vendor; "Post Code")
            {
            }
            column(City_Vendor; City)
            {
            }
            column(Contact_Vendor; Contact)
            {
            }
            column(PhoneNo_Vendor; "Phone No.")
            {
            }
            column(FaxNo_Vendor; "Fax No.")
            {
            }
            column(VendAddrListCaption; VendAddrListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(NoCaption_Vendor; FieldCaption("No."))
            {
            }
            column(NameCaption_Vendor; FieldCaption(Name))
            {
            }
            column(AddressCaption_Vendor; FieldCaption(Address))
            {
            }
            column(PostCodeCaption_Vendor; FieldCaption("Post Code"))
            {
            }
            column(CityCaption_Vendor; FieldCaption(City))
            {
            }
            column(ContactCaption_Vendor; FieldCaption(Contact))
            {
            }
            column(PhoneNoCaption_Vendor; FieldCaption("Phone No."))
            {
            }
            column(FaxNoCaption_Vendor; FieldCaption("Fax No."))
            {
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

    var
        VendAddrListCaptionLbl: Label 'Vendor - Address List';
        PageCaptionLbl: Label 'Page';
}

