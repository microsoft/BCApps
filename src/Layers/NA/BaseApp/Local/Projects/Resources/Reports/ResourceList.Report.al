// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Resources.Resource;

report 10197 "Resource List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Resources/Reports/ResourceList.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = "No.", Type, "Resource Group No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Resource_TABLECAPTION__________ResFilter; Resource.TableCaption + ': ' + ResFilter)
            {
            }
            column(ResFilter; ResFilter)
            {
            }
            column(Resource__No__; "No.")
            {
            }
            column(Resource_Name; Name)
            {
            }
            column(Resource__Resource_Group_No__; "Resource Group No.")
            {
            }
            column(Resource__Gen__Prod__Posting_Group_; "Gen. Prod. Posting Group")
            {
            }
            column(Resource__Direct_Unit_Cost_; "Direct Unit Cost")
            {
            }
            column(Resource__Unit_Cost_; "Unit Cost")
            {
            }
            column(Resource__Unit_Price_; "Unit Price")
            {
            }
            column(Resource_Type; Type)
            {
            }
            column(Resource_ListCaption; Resource_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Resource__No__Caption; FieldCaption("No."))
            {
            }
            column(Resource_NameCaption; FieldCaption(Name))
            {
            }
            column(Resource__Resource_Group_No__Caption; FieldCaption("Resource Group No."))
            {
            }
            column(Resource__Gen__Prod__Posting_Group_Caption; FieldCaption("Gen. Prod. Posting Group"))
            {
            }
            column(Resource__Direct_Unit_Cost_Caption; FieldCaption("Direct Unit Cost"))
            {
            }
            column(Resource__Unit_Cost_Caption; FieldCaption("Unit Cost"))
            {
            }
            column(Resource__Unit_Price_Caption; FieldCaption("Unit Price"))
            {
            }
            column(Resource_TypeCaption; FieldCaption(Type))
            {
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
        CompanyInformation.Get();
        ResFilter := Resource.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ResFilter: Text;
        Resource_ListCaptionLbl: Label 'Resource List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

