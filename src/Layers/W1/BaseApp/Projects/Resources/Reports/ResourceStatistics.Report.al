// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

report 1105 "Resource Statistics"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Statistics';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(Resource; Resource)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Date Filter";
            column(TodayFormatted; Format(Today))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TableCaptionResFilter; TableCaption + ': ' + ResFilter)
            {
            }
            column(ResFilter; ResFilter)
            {
            }
            column(No_Resource; "No.")
            {
                IncludeCaption = true;
            }
            column(Name_Resource; Name)
            {
                IncludeCaption = true;
            }
            column(InvdPct; InvdPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(SalesPrice_Resource; "Sales (Price)")
            {
                IncludeCaption = true;
            }
            column(UsagePrice_Resource; "Usage (Price)")
            {
                IncludeCaption = true;
            }
            column(ResourceStatisticsCaption; ResourceStatisticsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(InvdPctCaption; InvdPctCaptionLbl)
            {
            }
            column(ResUsageTotalPriceCaption; ResUsageTotalPriceCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Usage (Price)", "Sales (Price)");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Resource Statistics';
        AboutText = 'View detailed, historical information for the resource.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Projects/Resources/Reports/ResourceStatistics.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ResFilter := Resource.GetFilters();
    end;

    var
        InvdPct: Decimal;
        ResFilter: Text;
        ResourceStatisticsCaptionLbl: Label 'Resource Statistics';
        CurrReportPageNoCaptionLbl: Label 'Page';
        InvdPctCaptionLbl: Label 'Invoiced %';
        ResUsageTotalPriceCaptionLbl: Label 'Total';
}

