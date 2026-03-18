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
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Employee_Relative__TABLECAPTION__________RelativeFilter; TableCaption + ': ' + RelativeFilter)
            {
            }
            column(RelativeFilter; RelativeFilter)
            {
            }
            column(Employee_Relative__Employee_No__; "Employee No.")
            {
            }
            column(Employee_FullName; Employee.FullName())
            {
            }
            column(Employee_Relative__Relative_Code_; "Relative Code")
            {
            }
            column(Employee_Relative__First_Name_; "First Name")
            {
            }
            column(Employee_Relative__Last_Name_; "Last Name")
            {
            }
            column(Employee_Relative__Birth_Date_; Format("Birth Date"))
            {
            }
            column(Employee___RelativesCaption; Employee___RelativesCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Employee_Relative__Birth_Date_Caption; Employee_Relative__Birth_Date_CaptionLbl)
            {
            }
            column(Employee_Relative__Last_Name_Caption; FieldCaption("Last Name"))
            {
            }
            column(Employee_Relative__First_Name_Caption; FieldCaption("First Name"))
            {
            }
            column(Employee_Relative__Relative_Code_Caption; FieldCaption("Relative Code"))
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
        Employee___RelativesCaptionLbl: Label 'Employee - Relatives';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Employee_Relative__Birth_Date_CaptionLbl: Label 'Birth Date';

    protected var
        Employee: Record Employee;
}

