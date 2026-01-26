// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;

report 10611 "Customer - Address List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerAddressList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Address List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(No_Customer; "No.")
            {
            }
            column(Name_Customer; Name)
            {
            }
            column(Address_Customer; Address)
            {
            }
            column(PostCode_Customer; "Post Code")
            {
            }
            column(City_Customer; City)
            {
            }
            column(Contact_Customer; Contact)
            {
            }
            column(PhoneNo_Customer; "Phone No.")
            {
            }
            column(FaxNo_Customer; "Fax No.")
            {
            }
            column(CustomerAddressListCaption; CustomerAddressListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(NoCaption_Customer; FieldCaption("No."))
            {
            }
            column(NameCaption_Customer; FieldCaption(Name))
            {
            }
            column(AddressCaption_Customer; FieldCaption(Address))
            {
            }
            column(PostCodeCaption_Customer; FieldCaption("Post Code"))
            {
            }
            column(CityCaption_Customer; FieldCaption(City))
            {
            }
            column(ContactCaption_Customer; FieldCaption(Contact))
            {
            }
            column(PhoneNoCaption_Customer; FieldCaption("Phone No."))
            {
            }
            column(FaxNoCaption_Customer; FieldCaption("Fax No."))
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
        CustomerAddressListCaptionLbl: Label 'Customer - Address List';
        PageCaptionLbl: Label 'Page';
}

