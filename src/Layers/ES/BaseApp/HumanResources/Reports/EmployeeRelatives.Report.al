// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;

report 5208 "Employee - Relatives"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeRelatives.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Relatives';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Employee Relative"; "Employee Relative")
        {
            DataItemTableView = sorting("Employee No.", "Line No.");
            RequestFilterFields = "Employee No.", "Relative Code";
            column(TodayFormat; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Filter_EmployeeRelative; "Employee Relative".TableCaption + ': ' + RelativeFilter)
            {
            }
            column(RelativeFilter; RelativeFilter)
            {
            }
            column(EmpNo_EmployeeRelative; "Employee No.")
            {
            }
            column(EmployeeFullName; Employee.FullName())
            {
            }
            column(RelativeCode_EmployeeRelative; "Relative Code")
            {
                IncludeCaption = true;
            }
            column(Name_EmployeeRelative; Name)
            {
                IncludeCaption = true;
            }
            column(FirstFamilyName_EmployeeRelative; "First Family Name")
            {
                IncludeCaption = true;
            }
            column(BirthDate_EmployeeRelative; Format("Birth Date"))
            {
            }
            column(EmployeeRelativesCaption; EmployeeRelativesCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(BirthDateCaption; BirthDateCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Employee.Get("Employee No.");
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
        RelativeFilter := "Employee Relative".GetFilters();
    end;

    var
        RelativeFilter: Text;
        EmployeeRelativesCaptionLbl: Label 'Employee - Relatives';
        PageNoCaptionLbl: Label 'Page';
        BirthDateCaptionLbl: Label 'Birth Date';

    protected var
        Employee: Record Employee;
}

