// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;

report 99000755 "Single-level Cost Shares"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/SinglelevelCostShares.rdlc';
    AdditionalSearchTerms = 'rolled-up cost,cost breakdown';
    ApplicationArea = Manufacturing;
    Caption = 'Single-level Cost Shares';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TableCaptionItemFilt_Item; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(Show1; CostOption = CostOption::"Single-Level")
            {
            }
            column(Show2; CostOption = CostOption::"Rolled-Up")
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(LastUnitCostCalcDate_Item; Format("Last Unit Cost Calc. Date"))
            {
            }
            column(SingleLevelMaterCost_Item; "Single-Level Material Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLevelCpctyCost_Item; "Single-Level Capacity Cost")
            {
                IncludeCaption = true;
            }
            column(SinglLvlSbcontrdCost_Item; "Single-Level Subcontrd. Cost")
            {
                IncludeCaption = true;
            }
            column(SinglLvlCapOvhdCost_Item; "Single-Level Cap. Ovhd Cost")
            {
                IncludeCaption = true;
            }
            column(UnitCost_Item; "Unit Cost")
            {
                AutoFormatType = 2;
                IncludeCaption = true;
            }
            column(SinglLvlMfgOvhdCost_Item; "Single-Level Mfg. Ovhd Cost")
            {
                IncludeCaption = true;
            }
            column(RolledupMaterialCost_Item; "Rolled-up Material Cost")
            {
                IncludeCaption = true;
            }
            column(RolledupCapacityCost_Item; "Rolled-up Capacity Cost")
            {
                IncludeCaption = true;
            }
            column(RolldupSubcntrctCost_Item; "Rolled-up Subcontracted Cost")
            {
                IncludeCaption = true;
            }
            column(RolledupMfgOvhdCost_Item; "Rolled-up Mfg. Ovhd Cost")
            {
                IncludeCaption = true;
            }
            column(RolldupCapOverhdCost_Item; "Rolled-up Cap. Overhead Cost")
            {
                IncludeCaption = true;
            }
            column(SinglelevelCostSharesCapt; SinglelevelCostSharesCaptLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ItemLastUnitCostCalcDateCapt; ItemLastUnitCostCalcDateCaptLbl)
            {
            }

            trigger OnPreDataItem()
            begin
                ItemFilter := GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Single-level Cost Shares';
        AboutText = 'Get a detailed breakdown of the costs associated with manufactured items at each level of the bill of materials (BOM). The report shows the cost of materials, labor, and overhead for each component in the BOM.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CostOption; CostOption)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Cost';
                        OptionCaption = 'Single-Level,Rolled-Up';
                        ToolTip = 'Specifies whether the cost amount is single-level or rolled-up.';
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

    var
        ItemFilter: Text;
        CostOption: Option "Single-Level","Rolled-Up";
        SinglelevelCostSharesCaptLbl: Label 'Single-level Cost Shares';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ItemLastUnitCostCalcDateCaptLbl: Label 'Last Unit Cost Calc. Date';
}

