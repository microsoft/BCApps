// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;

report 5209 "Employee - Birthdays"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeBirthdays.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Birthdays';
    UsageCategory = ReportsAndAnalysis;

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
            column(Employee__Birth_Date_; Format("Birth Date"))
            {
            }
            column(Employee___BirthdaysCaption; Employee___BirthdaysCaptionLbl)
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
            column(Employee__Birth_Date_Caption; Employee__Birth_Date_CaptionLbl)
            {
            }
        }
    }

    requestpage
    {
        Caption = 'Employee - Birthdays';

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
        Employee___BirthdaysCaptionLbl: Label 'Employee - Birthdays';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Full_NameCaptionLbl: Label 'Full Name';
        Employee__Birth_Date_CaptionLbl: Label 'Birth Date';
}

