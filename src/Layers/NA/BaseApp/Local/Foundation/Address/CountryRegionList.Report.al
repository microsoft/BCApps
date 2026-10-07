// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Foundation.Company;

report 10307 "Country/Region List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Foundation/Address/CountryRegionList.rdlc';
    Caption = 'Country/Region List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code", "Address Format";
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
            column(Country_Region__TABLECAPTION__________CountryFilter; "Country/Region".TableCaption + ': ' + CountryFilter)
            {
            }
            column(CountryFilter; CountryFilter)
            {
            }
            column(Country_Region_Code; Code)
            {
            }
            column(Country_Region_Name; Name)
            {
            }
            column(Country_Region__Address_Format_; "Address Format")
            {
            }
            column(Country_Region__Contact_Address_Format_; "Contact Address Format")
            {
            }
            column(Country_Region__EU_Country_Region_Code_; "EU Country/Region Code")
            {
            }
            column(Country_Region_ListCaption; Country_Region_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Country_Region_CodeCaption; FieldCaption(Code))
            {
            }
            column(Country_Region_NameCaption; FieldCaption(Name))
            {
            }
            column(Country_Region__Address_Format_Caption; FieldCaption("Address Format"))
            {
            }
            column(Country_Region__Contact_Address_Format_Caption; FieldCaption("Contact Address Format"))
            {
            }
            column(Country_Region__EU_Country_Region_Code_Caption; FieldCaption("EU Country/Region Code"))
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        CountryFilter := "Country/Region".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        CountryFilter: Text;
        Country_Region_ListCaptionLbl: Label 'Country/Region List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

