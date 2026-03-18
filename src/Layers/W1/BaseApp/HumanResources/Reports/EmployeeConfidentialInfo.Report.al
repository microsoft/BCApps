// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;

report 5203 "Employee - Confidential Info."
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeConfidentialInfo.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Confidential Information';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Confidential Information"; "Confidential Information")
        {
            DataItemTableView = sorting("Employee No.", "Confidential Code", "Line No.");
            RequestFilterFields = "Employee No.", "Confidential Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Confidential_Information__TABLECAPTION__________ConfidentialInformationFilter; TableCaption + ': ' + ConfidentialInformationFilter)
            {
            }
            column(ConfidentialInformationFilter; ConfidentialInformationFilter)
            {
            }
            column(Confidential_Information__Employee_No__; "Employee No.")
            {
            }
            column(Employee_FullName; Employee.FullName())
            {
            }
            column(Confidential_Information__Confidential_Code_; "Confidential Code")
            {
            }
            column(Confidential_Information_Description; Description)
            {
            }
            column(Employee___Confidential_Info_Caption; Employee___Confidential_Info_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Confidential_Information_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Confidential_Information__Confidential_Code_Caption; FieldCaption("Confidential Code"))
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
        ConfidentialInformationFilter := "Confidential Information".GetFilters();
    end;

    var
        Employee: Record Employee;
        ConfidentialInformationFilter: Text;
        Employee___Confidential_Info_CaptionLbl: Label 'Employee - Confidential Info.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

