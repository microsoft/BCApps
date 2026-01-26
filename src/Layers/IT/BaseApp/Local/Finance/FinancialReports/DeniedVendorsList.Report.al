// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 12111 "Denied Vendors List"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = WordLayout;
    UseRequestPage = false;

    dataset
    {
        dataitem(CountryRegion; "Country/Region")
        {
            DataItemTableView = sorting("Code") where("On Deny List" = const(true));

            column(CompanyName; CompanyName)
            {

            }
            column(CurrentDate; Format(Today(), 0, 4))
            {

            }
            column(ReportTitle; ReportTitleTxt)
            {

            }
            dataitem(Vendor; Vendor)
            {
                DataItemTableView = sorting("No.");
                DataItemLink = "Country/Region Code" = field("Code");
                DataItemLinkReference = CountryRegion;

                column(VendorName; Vendor.Name)
                {
                    IncludeCaption = true;
                }
                column(VendorNo; Vendor."No.")
                {
                    IncludeCaption = true;
                }
                column(VendorAddress; Vendor.Address)
                {
                    IncludeCaption = true;
                }
                column(VendorCity; Vendor.City)
                {
                    IncludeCaption = true;
                }
                column(VendorCountryRegion; Vendor."Country/Region Code")
                {
                    IncludeCaption = true;
                }
                column(VendorPurchasesLCY; Vendor."Purchases (LCY)")
                {
                    IncludeCaption = true;
                }
                column(VendorBalanceLCY; Vendor."Balance (LCY)")
                {
                    IncludeCaption = true;
                }
            }
        }
    }

    rendering
    {
        layout(WordLayout)
        {
            Type = Word;
            LayoutFile = '.\Local\Finance\FinancialReports\DeniedVendorsList.Docx';
        }
    }

    var
        CompanyName: Text;
        ReportTitleTxt: Label 'Denied Vendors List';

    trigger OnPreReport()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyName := CompanyInformation.Name;
    end;

}
