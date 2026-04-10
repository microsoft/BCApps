// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;

report 5204 "Employee - Staff Absences"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeStaffAbsences.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Staff Absences';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Employee Absence"; "Employee Absence")
        {
            DataItemTableView = sorting("Employee No.", "From Date");
            RequestFilterFields = "Employee No.", "From Date", "Cause of Absence Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Employee_Absence__TABLECAPTION__________AbsenceFilter; TableCaption + ': ' + AbsenceFilter)
            {
            }
            column(AbsenceFilter; AbsenceFilter)
            {
            }
            column(Employee_Absence__Employee_No__; "Employee No.")
            {
            }
            column(Employee_FullName; Employee.FullName())
            {
            }
            column(Employee_Absence__From_Date_; Format("From Date"))
            {
            }
            column(Employee_Absence__To_Date_; Format("To Date"))
            {
            }
            column(Employee_Absence__Cause_of_Absence_Code_; "Cause of Absence Code")
            {
            }
            column(Employee_Absence_Description; Description)
            {
            }
            column(Employee_Absence_Quantity; Quantity)
            {
            }
            column(Employee_Absence__Unit_of_Measure_Code_; "Unit of Measure Code")
            {
            }
            column(Employee___Staff_AbsencesCaption; Employee___Staff_AbsencesCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Employee_Absence__From_Date_Caption; Employee_Absence__From_Date_CaptionLbl)
            {
            }
            column(Employee_Absence__To_Date_Caption; Employee_Absence__To_Date_CaptionLbl)
            {
            }
            column(Employee_Absence__Cause_of_Absence_Code_Caption; FieldCaption("Cause of Absence Code"))
            {
            }
            column(Employee_Absence_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Employee_Absence_QuantityCaption; FieldCaption(Quantity))
            {
            }
            column(Employee_Absence__Unit_of_Measure_Code_Caption; FieldCaption("Unit of Measure Code"))
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
        AbsenceFilter := "Employee Absence".GetFilters();
    end;

    var
        Employee: Record Employee;
        AbsenceFilter: Text;
        Employee___Staff_AbsencesCaptionLbl: Label 'Employee - Staff Absences';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Employee_Absence__From_Date_CaptionLbl: Label 'From Date';
        Employee_Absence__To_Date_CaptionLbl: Label 'To Date';
}

