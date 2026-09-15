// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Employee;

report 5213 "Employee - Alt. Addresses"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeAltAddresses.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Alternative Addresses';
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
            column(AlternativeAddr_Address; AlternativeAddr.Address)
            {
            }
            column(PostCodeCityText; PostCodeCityText)
            {
            }
            column(Employee___Alt__AddressesCaption; Employee___Alt__AddressesCaptionLbl)
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
            column(AddressCaption; AddressCaptionLbl)
            {
            }
            column(Post_Code_CityCaption; Post_Code_CityCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if (Today <= "Alt. Address End Date") and
                   (Today >= "Alt. Address Start Date") and
                   ("Alt. Address Code" <> '')
                then begin
                    AlternativeAddr.Get("No.", "Alt. Address Code");
                    FormatAddr.FormatPostCodeCity(
                      PostCodeCityText, CountyText, AlternativeAddr.City,
                      AlternativeAddr."Post Code", AlternativeAddr.County,
                      AlternativeAddr."Country/Region Code");
                end else
                    CurrReport.Skip();
            end;
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
        EmployeeFilter := Employee.GetFilters();
    end;

    var
        AlternativeAddr: Record "Alternative Address";
        FormatAddr: Codeunit "Format Address";
        PostCodeCityText: Text[50];
        CountyText: Text[50];
        EmployeeFilter: Text;
        Employee___Alt__AddressesCaptionLbl: Label 'Employee - Alt. Addresses';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Full_NameCaptionLbl: Label 'Full Name';
        AddressCaptionLbl: Label 'Address';
        Post_Code_CityCaptionLbl: Label 'Post Code/City';
}

