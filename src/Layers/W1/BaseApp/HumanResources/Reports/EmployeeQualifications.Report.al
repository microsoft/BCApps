// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;

report 5206 "Employee - Qualifications"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeQualifications.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Qualifications';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Employee Qualification"; "Employee Qualification")
        {
            DataItemTableView = sorting("Employee No.", "Line No.");
            RequestFilterFields = "Employee No.", "Qualification Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Employee_Qualification__TABLECAPTION__________EmployeeQualificationFilter; TableCaption + ': ' + EmployeeQualificationFilter)
            {
            }
            column(EmployeeQualificationFilter; EmployeeQualificationFilter)
            {
            }
            column(Employee_Qualification__Employee_No__; "Employee No.")
            {
            }
            column(Employee_FullName; Employee.FullName())
            {
            }
            column(Employee_Qualification__Qualification_Code_; "Qualification Code")
            {
            }
            column(Employee_Qualification__From_Date_; Format("From Date"))
            {
            }
            column(Employee_Qualification__To_Date_; Format("To Date"))
            {
            }
            column(Employee_Qualification_Type; Type)
            {
            }
            column(Employee_Qualification_Description; Description)
            {
            }
            column(Employee_Qualification__Institution_Company_; "Institution/Company")
            {
            }
            column(Employee___QualificationsCaption; Employee___QualificationsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Employee_Qualification__Institution_Company_Caption; FieldCaption("Institution/Company"))
            {
            }
            column(Employee_Qualification_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Employee_Qualification_TypeCaption; FieldCaption(Type))
            {
            }
            column(Employee_Qualification__To_Date_Caption; Employee_Qualification__To_Date_CaptionLbl)
            {
            }
            column(Employee_Qualification__From_Date_Caption; Employee_Qualification__From_Date_CaptionLbl)
            {
            }
            column(Employee_Qualification__Qualification_Code_Caption; FieldCaption("Qualification Code"))
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
        EmployeeQualificationFilter := "Employee Qualification".GetFilters();
    end;

    var
        Employee: Record Employee;
        EmployeeQualificationFilter: Text;
        Employee___QualificationsCaptionLbl: Label 'Employee - Qualifications';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Employee_Qualification__To_Date_CaptionLbl: Label 'To Date';
        Employee_Qualification__From_Date_CaptionLbl: Label 'From Date';
}

