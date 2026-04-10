// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;

report 5205 "Employee - Absences by Causes"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeAbsencesbyCauses.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Absences by Causes';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Employee Absence"; "Employee Absence")
        {
            DataItemTableView = sorting("Cause of Absence Code", "From Date");
            RequestFilterFields = "Employee No.", "From Date", "Cause of Absence Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Employee_Absence__TABLECAPTION__________EmployeeAbsenceFilter; TableCaption + ': ' + EmployeeAbsenceFilter)
            {
            }
            column(EmployeeAbsenceFilter; EmployeeAbsenceFilter)
            {
            }
            column(Employee_Absence_Description; Description)
            {
            }
            column(Employee_Absence__Cause_of_Absence_Code_; "Cause of Absence Code")
            {
            }
            column(Employee_Absence__From_Date_; Format("From Date"))
            {
            }
            column(Employee_Absence__To_Date_; Format("To Date"))
            {
            }
            column(Employee_Absence__Quantity__Base__; "Quantity (Base)")
            {
            }
            column(HumanResSetup__Base_Unit_of_Measure_; HumanResSetup."Base Unit of Measure")
            {
            }
            column(Employee_Absence__Employee_No__; "Employee No.")
            {
            }
            column(Employee_FullName; Employee.FullName())
            {
            }
            column(TotalAbsence; TotalAbsence)
            {
                DecimalPlaces = 0 : 2;
            }
            column(Employee___Absences_by_CausesCaption; Employee___Absences_by_CausesCaptionLbl)
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
            column(Employee_Absence__Employee_No__Caption; FieldCaption("Employee No."))
            {
            }
            column(Full_NameCaption; Full_NameCaptionLbl)
            {
            }
            column(Employee_Absence__Quantity__Base__Caption; FieldCaption("Quantity (Base)"))
            {
            }
            column(HumanResSetup__Base_Unit_of_Measure_Caption; HumanResSetup__Base_Unit_of_Measure_CaptionLbl)
            {
            }
            column(Total_AbsenceCaption; Total_AbsenceCaptionLbl)
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
        EmployeeAbsenceFilter := "Employee Absence".GetFilters();
        HumanResSetup.Get();
        HumanResSetup.TestField("Base Unit of Measure");
    end;

    var
        Employee: Record Employee;
        HumanResSetup: Record "Human Resources Setup";
        EmployeeAbsenceFilter: Text;
        TotalAbsence: Decimal;
        Employee___Absences_by_CausesCaptionLbl: Label 'Employee - Absences by Causes';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Employee_Absence__From_Date_CaptionLbl: Label 'From Date';
        Employee_Absence__To_Date_CaptionLbl: Label 'To Date';
        Full_NameCaptionLbl: Label 'Full Name';
        HumanResSetup__Base_Unit_of_Measure_CaptionLbl: Label 'Base Unit of Measure';
        Total_AbsenceCaptionLbl: Label 'Total Absence';
}

