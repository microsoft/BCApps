// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;

report 12135 "Fiscal Inventory Valuation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/FiscalInventoryValuation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Fiscal Inventory Valuation';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Date Filter", "Location Filter", "Net Change";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(FORMAT_CostType____Text12101___FORMAT_GETRANGEMAX__Date_Filter___; StrSubstNo(Text12101, CostType, GetRangeMax("Date Filter")))
            {
            }
            column(Filters; Filters)
            {
            }
            column(CostType; CostType)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item__Net_Change_; "Net Change")
            {
            }
            column(InvValMethod; InvValMethod)
            {
            }
            column(UnitCost; UnitCost)
            {
            }
            column(InvValue; InvValue)
            {
            }
            column(Item__Net_Change__Control1130017; "Net Change")
            {
            }
            column(InvValue_Control1130020; InvValue)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_No_Caption; Item_No_CaptionLbl)
            {
            }
            column(Item_DescriptionCaption; Item_DescriptionCaptionLbl)
            {
            }
            column(InventoryCaption; InventoryCaptionLbl)
            {
            }
            column(Inventory_ValuationCaption; Inventory_ValuationCaptionLbl)
            {
            }
            column(ValueCaption; ValueCaptionLbl)
            {
            }
            column(Total_QuantityCaption; Total_QuantityCaptionLbl)
            {
            }
            column(Inventory_ValueCaption; Inventory_ValueCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                InvValMethod := '';
                CalcFields("Net Change");
                if ItemCostHistory.Get("No.", CompetenceDate) then begin
                    case CostType of
                        CostType::"Fiscal Cost":
                            begin
                                case "Inventory Valuation" of
                                    "Inventory Valuation"::Average:
                                        UnitCost := ItemCostHistory."Year Average Cost";
                                    "Inventory Valuation"::"Weighted Average":
                                        UnitCost := ItemCostHistory."Weighted Average Cost";
                                    "Inventory Valuation"::FIFO:
                                        UnitCost := ItemCostHistory."FIFO Cost";
                                    "Inventory Valuation"::LIFO:
                                        UnitCost := ItemCostHistory."LIFO Cost";
                                    "Inventory Valuation"::"Discrete LIFO":
                                        UnitCost := ItemCostHistory."Discrete LIFO Cost";
                                end;
                                InvValMethod := Format("Inventory Valuation");
                            end;
                        CostType::"Average Cost":
                            UnitCost := ItemCostHistory."Year Average Cost";
                        CostType::"Weighted Average Cost":
                            UnitCost := ItemCostHistory."Weighted Average Cost";
                        CostType::"FIFO Cost":
                            UnitCost := ItemCostHistory."FIFO Cost";
                        CostType::"LIFO Cost":
                            UnitCost := ItemCostHistory."LIFO Cost";
                        CostType::"Discrete LIFO Cost":
                            UnitCost := ItemCostHistory."Discrete LIFO Cost";
                    end;
                    InvValue := "Net Change" * UnitCost;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Date Filter") <> '' then
                    SetFilter("Date Filter", '..%1', GetRangeMax("Date Filter"));
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CompetenceDate; CompetenceDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Competence Date';
                        ToolTip = 'Specifies the competence date.';
                    }
                    field(CostType; CostType)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Cost Type';
                        OptionCaption = 'Fiscal Cost,Average Cost,Weighted Average Cost,FIFO Cost,LIFO Cost,Discrete LIFO Cost';
                        ToolTip = 'Specifies the cost type.';
                    }
                }
            }
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
        if CompetenceDate = 0D then
            Error(Text12100);

        if Item.GetFilter("Date Filter") = '' then
            Error(DateFilterErr);

        if Item.GetFilters <> '' then
            Filters := 'Filters: ' + Item.GetFilters + ', Competence Year: ' + Format(CompetenceDate)
        else
            Filters := 'Filters: ' + Item.GetFilters + ' Competence Year: ' + Format(CompetenceDate)
    end;

    var
        ItemCostHistory: Record "Item Cost History";
        Filters: Text;
        InvValMethod: Text[30];
        CostType: Option "Fiscal Cost","Average Cost","Weighted Average Cost","FIFO Cost","LIFO Cost","Discrete LIFO Cost";
        Text12100: Label 'Invalid Date.';
        UnitCost: Decimal;
        InvValue: Decimal;
        CompetenceDate: Date;
        Text12101: Label '%1 Inventory Value to %2', Comment = '%1 - CostType (Option);%2 - Date Filter.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_No_CaptionLbl: Label 'Item No.';
        Item_DescriptionCaptionLbl: Label 'Item Description';
        InventoryCaptionLbl: Label 'Inventory';
        Inventory_ValuationCaptionLbl: Label 'Inventory Valuation';
        ValueCaptionLbl: Label 'Value';
        Total_QuantityCaptionLbl: Label 'Total Quantity';
        Inventory_ValueCaptionLbl: Label 'Inventory Value';
        DateFilterErr: Label 'You must specify a date range in the Date Filter field in the request page, such as the past quarter or the current year.';
}

