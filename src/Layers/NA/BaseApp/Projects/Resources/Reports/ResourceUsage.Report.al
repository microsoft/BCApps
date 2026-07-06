// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Foundation.Company;

report 10200 "Resource Usage"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Resources/Reports/ResourceUsage.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource Usage';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = "No.", Type, "Base Unit of Measure", "Date Filter";
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
            column(ResFilter; ResFilter)
            {
            }
            column(Resource_TABLECAPTION__________ResFilter; Resource.TableCaption + ': ' + ResFilter)
            {
            }
            column(Resource__No__; "No.")
            {
            }
            column(Resource_Type; Type)
            {
            }
            column(Resource_Name; Name)
            {
            }
            column(Resource__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(Resource_Capacity; Capacity)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Resource__Usage__Qty___; "Usage (Qty.)")
            {
                DecimalPlaces = 2 : 5;
            }
            column(Capacity____Usage__Qty___; Capacity - "Usage (Qty.)")
            {
                DecimalPlaces = 2 : 5;
            }
            column(Resource_Capacity_Control17; Capacity)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Resource__Usage__Qty____Control18; "Usage (Qty.)")
            {
                DecimalPlaces = 2 : 5;
            }
            column(Capacity____Usage__Qty____Control19; Capacity - "Usage (Qty.)")
            {
                DecimalPlaces = 2 : 5;
            }
            column(Resource_UsageCaption; Resource_UsageCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Resource__No__Caption; FieldCaption("No."))
            {
            }
            column(Resource_TypeCaption; FieldCaption(Type))
            {
            }
            column(Resource_NameCaption; FieldCaption(Name))
            {
            }
            column(Resource__Base_Unit_of_Measure_Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(Resource_CapacityCaption; FieldCaption(Capacity))
            {
            }
            column(Resource__Usage__Qty___Caption; FieldCaption("Usage (Qty.)"))
            {
            }
            column(Capacity____Usage__Qty___Caption; Capacity____Usage__Qty___CaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Unit of Measure Filter", "Base Unit of Measure");
                CalcFields(Capacity, "Usage (Qty.)");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Resource Utilization';
        AboutText = 'View the resource utilization that has taken place. The report includes the resource capacity, quantity of usage, and the remaining balance.';
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
        Resource_UsageCaptionLbl: Label 'Resource Usage';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Capacity____Usage__Qty___CaptionLbl: Label 'Balance';
        Report_TotalCaptionLbl: Label 'Report Total';
}

