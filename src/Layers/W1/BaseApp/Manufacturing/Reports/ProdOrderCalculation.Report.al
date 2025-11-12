#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.Document;

report 99000767 "Prod. Order - Calculation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/ProdOrderCalculation.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order - Calculation (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'This report has been replaced by the "Production Order Statistics" report and will be removed in a future release.';
    ObsoleteTag = '27.0';

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.", "Source Type", "Source No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Production_Order__TABLECAPTION_________ProdOrderFilter; TableCaption + ':' + ProdOrderFilter)
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(Prod__Order_Line___Expected_Operation_Cost_Amt__; "Prod. Order Line"."Expected Operation Cost Amt.")
            {
            }
            column(Prod__Order_Line___Expected_Component_Cost_Amt__; "Prod. Order Line"."Expected Component Cost Amt.")
            {
            }
            column(TotalCost; TotalCost)
            {
                AutoFormatType = 1;
            }
            column(Production_Order_No_; "No.")
            {
            }
            column(Prod__Order___CalculationCaption; Prod__Order___CalculationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Prod__Order_No_Caption; Prod__Order_No_CaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Item_No_Caption; Item_No_CaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(Expected_Operation_Cost_Amt_Caption; Expected_Operation_Cost_Amt_CaptionLbl)
            {
            }
            column(Expected_Component_Cost_Amt_Caption; Expected_Component_Cost_Amt_CaptionLbl)
            {
            }
            column(Total_CostCaption; Total_CostCaptionLbl)
            {
            }
            column(Total_CostsCaption; Total_CostsCaptionLbl)
            {
            }
            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.") where("Planning Level Code" = const(0));
                column(Prod__Order_Line__Prod__Order_No__; "Prod. Order No.")
                {
                }
                column(Prod__Order_Line_Description; Description)
                {
                }
                column(Prod__Order_Line__Item_No__; "Item No.")
                {
                }
                column(Prod__Order_Line_Quantity; Quantity)
                {
                }
                column(Prod__Order_Line__Expected_Operation_Cost_Amt__; "Expected Operation Cost Amt.")
                {
                }
                column(Prod__Order_Line__Expected_Component_Cost_Amt__; "Expected Component Cost Amt.")
                {
                }
                column(TotalCost_Control29; TotalCost)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(
                      "Expected Operation Cost Amt.",
                      "Expected Component Cost Amt.");

                    TotalCost :=
                      "Expected Operation Cost Amt." +
                      "Expected Component Cost Amt.";
                end;
            }

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters();
                Clear(TotalCost);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Prod. Order - Calculation (Obsolete)';
        AboutText = 'Get a list of your production orders and their costs. ** This report is obsolete and will be removed in a future release.** Please refer to the report documentation for alternative ways to retrieve this information.';
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

    var
        ProdOrderFilter: Text;
        TotalCost: Decimal;
        Prod__Order___CalculationCaptionLbl: Label 'Prod. Order - Calculation';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Prod__Order_No_CaptionLbl: Label 'Prod. Order No.';
        DescriptionCaptionLbl: Label 'Description';
        Item_No_CaptionLbl: Label 'Item No.';
        QuantityCaptionLbl: Label 'Quantity';
        Expected_Operation_Cost_Amt_CaptionLbl: Label 'Expected Operation Cost Amt.';
        Expected_Component_Cost_Amt_CaptionLbl: Label 'Expected Component Cost Amt.';
        Total_CostCaptionLbl: Label 'Total Cost';
        Total_CostsCaptionLbl: Label 'Total Costs';
}
#endif