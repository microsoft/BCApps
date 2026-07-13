// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;

report 10149 "Location List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/LocationList.rdlc';
    Caption = 'Location List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Location; Location)
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code", Name;
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
            column(Location_TABLECAPTION__________LocationFilter; Location.TableCaption + ': ' + LocationFilter)
            {
            }
            column(LocationFilter; LocationFilter)
            {
            }
            column(Location_Code; Code)
            {
            }
            column(Location_Name; Name)
            {
            }
            column(Location__Tax_Area_Code_; "Tax Area Code")
            {
            }
            column(Location__Tax_Exemption_No__; "Tax Exemption No.")
            {
            }
            column(Location_Contact; Contact)
            {
            }
            column(Location__Phone_No__; "Phone No.")
            {
            }
            column(Location_ListCaption; Location_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Location_CodeCaption; FieldCaption(Code))
            {
            }
            column(Location_NameCaption; FieldCaption(Name))
            {
            }
            column(Location__Tax_Area_Code_Caption; FieldCaption("Tax Area Code"))
            {
            }
            column(Location__Tax_Exemption_No__Caption; FieldCaption("Tax Exemption No."))
            {
            }
            column(Location_ContactCaption; FieldCaption(Contact))
            {
            }
            column(Location__Phone_No__Caption; FieldCaption("Phone No."))
            {
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
        LocationFilter := Location.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        LocationFilter: Text;
        Location_ListCaptionLbl: Label 'Location List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

