// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;

report 5210 "Employee - Phone Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeePhoneNos.rdlc';
    Caption = 'Employee - Phone Nos.';

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Code", "Global Dimension 2 Code";
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
            column(Employee__Phone_No__; "Phone No.")
            {
            }
            column(Employee__Mobile_Phone_No__; "Mobile Phone No.")
            {
            }
            column(Employee_Extension; Extension)
            {
            }
            column(Employee___Phone_Nos_Caption; Employee___Phone_Nos_CaptionLbl)
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
            column(Employee__Mobile_Phone_No__Caption; FieldCaption("Mobile Phone No."))
            {
            }
            column(Employee_ExtensionCaption; FieldCaption(Extension))
            {
            }
            column(Employee__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
        }
    }

    requestpage
    {
        Caption = 'Employee - Phone Nos.';

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
        EmployeeFilter: Text;
        Employee___Phone_Nos_CaptionLbl: Label 'Employee - Phone Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Full_NameCaptionLbl: Label 'Full Name';
}

