// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Employee;

report 5207 "Employee - Addresses"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeAddresses.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Addresses';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Employee_TABLECAPTION__________EmployeeFilter; TableCaption + ': ' + EmployeeFilter)
            {
            }
            column(EmployeeFilter; EmployeeFilter)
            {
            }
            column(Employee__No__; "No.")
            {
            }
            column(FullName; FullName())
            {
            }
            column(Employee_Address; Address)
            {
            }
            column(PostCodeCityText; PostCodeCityText)
            {
            }
            column(Employee___AddressesCaption; Employee___AddressesCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Employee__No__Caption; FieldCaption("No."))
            {
            }
            column(Full_NameCaption; Full_NameCaptionLbl)
            {
            }
            column(Employee_AddressCaption; FieldCaption(Address))
            {
            }
            column(Post_Code_CityCaption; Post_Code_CityCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.FormatPostCodeCity(
                  PostCodeCityText, CountyText, City, "Post Code", County, "Country/Region Code");
            end;
        }
    }

    requestpage
    {
        Caption = 'Employee - Addresses';

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
        EmployeeFilter := Employee.GetFilters();
    end;

    var
        FormatAddr: Codeunit "Format Address";
        PostCodeCityText: Text[50];
        CountyText: Text[50];
        EmployeeFilter: Text;
        Employee___AddressesCaptionLbl: Label 'Employee - Addresses';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Full_NameCaptionLbl: Label 'Full Name';
        Post_Code_CityCaptionLbl: Label 'Post Code/City';
}

