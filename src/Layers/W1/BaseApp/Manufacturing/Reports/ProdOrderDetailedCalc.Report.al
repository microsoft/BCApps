// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.Document;
using System.Utilities;

report 99000768 "Prod. Order - Detailed Calc."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/ProdOrderDetailedCalc.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order - Detailed Calc.';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.", "Source Type", "Source No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ProdOrderTableCaptionFilter; TableCaption + ':' + ProdOrderFilter)
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(No_ProdOrder; "No.")
            {
            }
            column(Desc_ProdOrder; Description)
            {
            }
            column(SourceNo_ProdOrder; "Source No.")
            {
                IncludeCaption = true;
            }
            column(Qty_ProdOrder; Quantity)
            {
                IncludeCaption = true;
            }
            column(ProdOrderDetailedCalcCaption; ProdOrderDetailedCalcCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.") where("Planning Level Code" = const(0));
                column(LineNo_ProdOrderLine; "Line No.")
                {
                }
                dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
                {
                    DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Routing Reference No." = field("Line No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
                    column(OPNo_ProdOrderRtngLine; "Operation No.")
                    {
                        IncludeCaption = false;
                    }
                    column(OPNo_ProdOrderRtngLineCaption; FieldCaption("Operation No."))
                    {
                    }
                    column(Type_ProdOrderRtngLine; Type)
                    {
                        IncludeCaption = true;
                    }
                    column(No_ProdOrderRtngLine; "No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Desc_ProdOrderRtngLine; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(InputQty_ProdOrderRtngLine; "Input Quantity")
                    {
                        IncludeCaption = true;
                    }
                    column(ExpecOPCostAmt_ProdOrderRtngLine; "Expected Operation Cost Amt.")
                    {
                        IncludeCaption = true;
                    }
                    column(TotalProductionCostCaption; TotalProductionCostCaptionLbl)
                    {
                    }
                }
                dataitem("Prod. Order Component"; "Prod. Order Component")
                {
                    DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Prod. Order Line No." = field("Line No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                    column(ItemNo_ProdOrderComp; "Item No.")
                    {
                        IncludeCaption = false;
                    }
                    column(ItemNo_ProdOrderCompCaption; FieldCaption("Item No."))
                    {
                    }
                    column(Desc_ProdOrderComp; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(RtngLinkCode_ProdOrderComp; "Routing Link Code")
                    {
                        IncludeCaption = true;
                    }
                    column(ExpectedQty_ProdOrderComp; "Expected Quantity")
                    {
                        IncludeCaption = true;
                    }
                    column(CostAmt_ProdOrderComp; "Cost Amount")
                    {
                        IncludeCaption = true;
                    }
                    column(UnitCost_ProdOrderComp; "Unit Cost")
                    {
                        IncludeCaption = true;
                    }
                    column(TotalMaterialCostCaption; TotalMaterialCostCaptionLbl)
                    {
                    }
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(ProdOrderCompOPCostAmt; "Prod. Order Component"."Cost Amount" + "Prod. Order Routing Line"."Expected Operation Cost Amt.")
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalProdCostCaption; TotalProdCostCaptionLbl)
                    {
                    }
                    column(TotalMterlCostCaption; TotalMterlCostCaptionLbl)
                    {
                    }
                    column(TotalCostCaption; TotalCostCaptionLbl)
                    {
                    }
                }
            }

            trigger OnPreDataItem()
            begin
                ProdOrderFilter := GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Prod. Order - Detailed Calc.';
        AboutText = 'Get a comprehensive analysis of the costs associated with production orders broken down to costs by material, capacity, overhead, and other cost components.';

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
        ProdOrderDetailedCalcCaptionLbl: Label 'Prod. Order - Detailed Calc.';
        CurrReportPageNoCaptionLbl: Label 'Page';
        TotalProductionCostCaptionLbl: Label 'Total Production Cost';
        TotalMaterialCostCaptionLbl: Label 'Total Material Cost';
        TotalProdCostCaptionLbl: Label 'Total Production Cost';
        TotalMterlCostCaptionLbl: Label 'Total Material Cost';
        TotalCostCaptionLbl: Label 'Total Cost';
}

