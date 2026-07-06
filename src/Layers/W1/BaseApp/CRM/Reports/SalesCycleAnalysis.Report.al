// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Opportunity;

report 5062 "Sales Cycle - Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/SalesCycleAnalysis.rdlc';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Sales Cycle - Analysis';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Sales Cycle"; "Sales Cycle")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code", Blocked;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(TblCptnSalesCycleFilter; TableCaption + ': ' + SalesCycleFilter)
            {
            }
            column(Code_SalesCycle; Code)
            {
            }
            column(Description_SalesCycle; Description)
            {
            }
            column(SalesFilter; SalesCycleFilter)
            {
            }
            column(NoOfOpportunities; NoOfOpportunities)
            {
                DecimalPlaces = 0 : 0;
            }
            column(EstdValueLCY_SalesCycle; "Estimated Value (LCY)")
            {
            }
            column(CalcCurrValLCY_SalesCycle; "Calcd. Current Value (LCY)")
            {
            }
            column(AverageNoOfDays; AverageNoOfDays)
            {
                DecimalPlaces = 0 : 2;
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(SalesCycleAnalysisCaption; SalesCycleAnalysisCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Sales Cycle Stage"; "Sales Cycle Stage")
            {
                DataItemLink = "Sales Cycle Code" = field(Code);
                DataItemTableView = sorting("Sales Cycle Code", Stage);
                column(Stage_SalesCycleStage; Stage)
                {
                    IncludeCaption = true;
                }
                column(Descriptn_SalesCycleStage; Description)
                {
                    IncludeCaption = true;
                }
                column(ActyCode_SalesCycleStage; "Activity Code")
                {
                    IncludeCaption = true;
                }
                column(NoOfOppt_SalesCycleStage; "No. of Opportunities")
                {
                    IncludeCaption = true;
                }
                column(EstValLCY_SalesCycleStage; "Estimated Value (LCY)")
                {
                    IncludeCaption = true;
                }
                column(CurValLCY_SalesCycleStage; "Calcd. Current Value (LCY)")
                {
                    IncludeCaption = true;
                }
                column(AvgNoOfDay_SalesCycleStage; "Average No. of Days")
                {
                    IncludeCaption = true;
                }
                column(NoOfOpportunities2; NoOfOpportunities)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(SalCyclCd_SalesCycleStage; "Sales Cycle Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    NoOfOpportunities := "No. of Opportunities";
                    AverageNoOfDays := "Average No. of Days";
                end;

                trigger OnPreDataItem()
                begin
                    Clear(NoOfOpportunities);
                    Clear(AverageNoOfDays);
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear(NoOfOpportunities);
                Clear(AverageNoOfDays);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Sales Cycle - Analysis';
        AboutText = 'Get an overview of your sales cycles, including the number of opportunities currently at that stage and the estimated and calculated current values of opportunities.';

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
        SalesCycleFilter := "Sales Cycle".GetFilters();
    end;

    var
        SalesCycleFilter: Text;
        NoOfOpportunities: Decimal;
        AverageNoOfDays: Decimal;
        CurrReportPageNoCaptionLbl: Label 'Page';
        SalesCycleAnalysisCaptionLbl: Label 'Sales Cycle - Analysis';
        TotalCaptionLbl: Label 'Total';
}

