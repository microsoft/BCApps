// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;

report 5202 "Employee - Misc. Article Info."
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeMiscArticleInfo.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Miscellaneous Article Information';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Misc. Article Information"; "Misc. Article Information")
        {
            DataItemTableView = sorting("Employee No.", "Misc. Article Code", "Line No.");
            RequestFilterFields = "Employee No.", "Misc. Article Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Misc__Article_Information__TABLECAPTION__________MiscArticleFilter; TableCaption + ': ' + MiscArticleFilter)
            {
            }
            column(MiscArticleFilter; MiscArticleFilter)
            {
            }
            column(Misc__Article_Information__Employee_No__; "Employee No.")
            {
            }
            column(Employee_FullName; Employee.FullName())
            {
            }
            column(Misc__Article_Information__Misc__Article_Code_; "Misc. Article Code")
            {
            }
            column(Misc__Article_Information_Description; Description)
            {
            }
            column(Misc__Article_Information__Serial_No__; "Serial No.")
            {
            }
            column(Employee___Misc__Article_Info_Caption; Employee___Misc__Article_Info_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Misc__Article_Information_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Misc__Article_Information__Misc__Article_Code_Caption; FieldCaption("Misc. Article Code"))
            {
            }
            column(Misc__Article_Information__Serial_No__Caption; FieldCaption("Serial No."))
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
        Caption = 'Employee - Misc. Article Info.';

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
        MiscArticleFilter := "Misc. Article Information".GetFilters();
    end;

    var
        Employee: Record Employee;
        MiscArticleFilter: Text;
        Employee___Misc__Article_Info_CaptionLbl: Label 'Employee - Misc. Article Info.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

