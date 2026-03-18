// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;

report 5211 "Employee - Unions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeUnions.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Unions';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Union; Union)
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Union_TABLECAPTION__________UnionFilter; TableCaption + ': ' + UnionFilter)
            {
            }
            column(UnionFilter; UnionFilter)
            {
            }
            column(Union_Code; Code)
            {
            }
            column(Union_Name; Name)
            {
            }
            column(Employee___UnionsCaption; Employee___UnionsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Full_NameCaption; Full_NameCaptionLbl)
            {
            }
            column(Employee__No__Caption; Employee.FieldCaption("No."))
            {
            }
            dataitem(Employee; Employee)
            {
                DataItemLink = "Union Code" = field(Code);
                DataItemTableView = sorting(Status, "Union Code");
                column(Employee__No__; "No.")
                {
                }
                column(FullName; FullName())
                {
                }
            }
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
        UnionFilter := Union.GetFilters();
    end;

    var
        UnionFilter: Text;
        Employee___UnionsCaptionLbl: Label 'Employee - Unions';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Full_NameCaptionLbl: Label 'Full Name';
}

