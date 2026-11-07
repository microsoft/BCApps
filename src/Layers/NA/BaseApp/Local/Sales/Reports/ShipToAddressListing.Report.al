// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Sales.Customer;

report 10061 "Ship-To Address Listing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/ShipToAddressListing.rdlc';
    Caption = 'Ship-To Address Listing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name";
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
            column(TABLECAPTION__________FilterString; TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Ship_to_Address__TABLECAPTION__________FilterString2; "Ship-to Address".TableCaption + ': ' + FilterString2)
            {
            }
            column(FilterString2; FilterString2)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(Customer_Contact; Contact)
            {
            }
            column(Customer__Phone_No__; "Phone No.")
            {
            }
            column(Ship_To_Address_ListingCaption; Ship_To_Address_ListingCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Customer__No__Caption; Customer__No__CaptionLbl)
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            column(Ship_to_Address_ContactCaption; "Ship-to Address".FieldCaption(Contact))
            {
            }
            column(Ship_to_Address__UPS_Zone_Caption; "Ship-to Address".FieldCaption("UPS Zone"))
            {
            }
            column(Ship_to_Address__Shipment_Method_Code_Caption; Ship_to_Address__Shipment_Method_Code_CaptionLbl)
            {
            }
            column(Ship_to_Address_CodeCaption; Ship_to_Address_CodeCaptionLbl)
            {
            }
            column(ShiptoAddr_1_Caption; ShiptoAddr_1_CaptionLbl)
            {
            }
            column(Ship_to_Address__Phone_No__Caption; "Ship-to Address".FieldCaption("Phone No."))
            {
            }
            column(Ship_to_Address__Tax_Area_Code_Caption; Ship_to_Address__Tax_Area_Code_CaptionLbl)
            {
            }
            dataitem("Ship-to Address"; "Ship-to Address")
            {
                DataItemLink = "Customer No." = field("No.");
                DataItemTableView = sorting("Customer No.", Code);
                RequestFilterFields = "Code", "Shipment Method Code";
                column(Customer__No___Control24; Customer."No.")
                {
                }
                column(Customer_Name_Control25; Customer.Name)
                {
                }
                column(Ship_to_Address_Code; Code)
                {
                }
                column(ShiptoAddr_1_; ShipToAddr[1])
                {
                }
                column(Ship_to_Address_Contact; Contact)
                {
                }
                column(Ship_to_Address__Tax_Area_Code_; "Tax Area Code")
                {
                }
                column(Ship_to_Address__UPS_Zone_; "UPS Zone")
                {
                }
                column(Ship_to_Address__Shipment_Method_Code_; "Shipment Method Code")
                {
                }
                column(ShiptoAddr_2_; ShipToAddr[2])
                {
                }
                column(Ship_to_Address__Phone_No__; "Phone No.")
                {
                }
                column(TaxArea_Description; TaxArea.Description)
                {
                }
                column(ShipmentMethod_Description; ShipmentMethod.Description)
                {
                }
                column(ShiptoAddr_3_; ShipToAddr[3])
                {
                }
                column(ShiptoAddr_4_; ShipToAddr[4])
                {
                }
                column(ShiptoAddr_5_; ShipToAddr[5])
                {
                }
                column(ShiptoAddr_6_; ShipToAddr[6])
                {
                }
                column(ShiptoAddr_7_; ShipToAddr[7])
                {
                }
                column(ShiptoAddr_8_; ShipToAddr[8])
                {
                }
                column(Ship_to_Address_Customer_No_; "Customer No.")
                {
                }
                column(continued_Caption; continued_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    FormatAddress.FormatAddr(
                      ShipToAddr, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
                    if not ShipmentMethod.Get("Shipment Method Code") then
                        ShipmentMethod.Description := '';
                    if not TaxArea.Get("Tax Area Code") then
                        TaxArea.Description := '';
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
        FilterString := Customer.GetFilters();
        FilterString2 := "Ship-to Address".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ShipmentMethod: Record "Shipment Method";
        TaxArea: Record "Tax Area";
        FormatAddress: Codeunit "Format Address";
        ShipToAddr: array[8] of Text[100];
        FilterString: Text;
        FilterString2: Text;
        Ship_To_Address_ListingCaptionLbl: Label 'Ship-To Address Listing';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Customer__No__CaptionLbl: Label 'Customer No.';
        Customer_NameCaptionLbl: Label 'Bill-To Name';
        Ship_to_Address__Shipment_Method_Code_CaptionLbl: Label 'Shipment Method';
        Ship_to_Address_CodeCaptionLbl: Label 'Ship-To Code';
        ShiptoAddr_1_CaptionLbl: Label 'Ship-To Name and Address';
        Ship_to_Address__Tax_Area_Code_CaptionLbl: Label 'Sales Tax Area';
        continued_CaptionLbl: Label '(continued)';
}

