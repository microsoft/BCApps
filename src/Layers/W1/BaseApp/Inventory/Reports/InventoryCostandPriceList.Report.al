// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 716 "Inventory Cost and Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryCostandPriceList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Cost and Price List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Location Filter", "Variant Filter", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemFilterCopyCaption; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(InventPostingGr_Item; "Inventory Posting Group")
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_Item; Description)
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; Format("Assembly BOM"))
            {
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(AverageCost; AverageCost)
            {
                AutoFormatType = 1;
            }
            column(StandardCost_Item; "Standard Cost")
            {
                IncludeCaption = true;
            }
            column(LastDirectCost_Item; "Last Direct Cost")
            {
                IncludeCaption = true;
            }
            column(UnitPrice_Item; "Unit Price")
            {
                IncludeCaption = true;
            }
            column(Profit_Item; "Profit %")
            {
                DecimalPlaces = 1 : 1;
                IncludeCaption = true;
            }
            column(UnitPriceUnitCost_Item; "Unit Price" - "Unit Cost")
            {
            }
            column(UseStockkeepingUnitBody; UseStockkeepingUnitReq)
            {
            }
            column(LocationFilter_Item; "Location Filter")
            {
            }
            column(VariantFilter_Item; "Variant Filter")
            {
            }
            column(InvCostAndPriceListCaption; InvCostAndPriceListCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(BOMCaption; BOMCaptionLbl)
            {
            }
            column(AvgCostCaption; AvgCostCaptionLbl)
            {
            }
            column(ProfitCaption; ProfitCaptionLbl)
            {
            }
            column(LastDirCostCaption; LastDirCostCaptionLbl)
            {
            }
            column(LocationCodeCaption; LocationCodeCaptionLbl)
            {
            }
            column(VariantCodeCaption; VariantCodeCaptionLbl)
            {
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");
                column(ItemUnitPriceUnitCostDiff; Item."Unit Price" - Item."Unit Cost")
                {
                }
                column(LastDirCost_StockKeepingUnit; "Last Direct Cost")
                {
                }
                column(StandardCost_StockKeepingUnit; "Standard Cost")
                {
                }
                column(AverageCost_StockKeepingUnit; AverageCost)
                {
                    AutoFormatType = 1;
                }
                column(ItemBaseUOM; Item."Base Unit of Measure")
                {
                }
                column(ItemAssemblyBOM; Format(Item."Assembly BOM"))
                {
                }
                column(LocationCode_StockKeepingUnit; "Location Code")
                {
                }
                column(VariantCode_StockKeepingUnit; "Variant Code")
                {
                }
                column(UseStockkeepingUnit; UseStockkeepingUnitReq)
                {
                }
                column(SKUPrintLoop; SKUPrintLoop)
                {
                }

                trigger OnAfterGetRecord()
                var
                    Item2: Record Item;
                begin
                    SKUPrintLoop := SKUPrintLoop + 1;
                    if Item2.Get("Item No.") then begin
                        Item2.SetFilter("Location Filter", "Location Code");
                        Item2.SetFilter("Variant Filter", "Variant Code");
                        ItemCostManagement.CalculateAverageCost(Item2, AverageCost, AverageCostACY);
                        AverageCost := Round(AverageCost, GeneralLedgerSetup."Unit-Amount Rounding Precision");
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not UseStockkeepingUnitReq then
                        CurrReport.Break();

                    SKUPrintLoop := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemCostManagement.CalculateAverageCost(Item, AverageCost, AverageCostACY);
                AverageCost := Round(AverageCost, GeneralLedgerSetup."Unit-Amount Rounding Precision");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Cost and Price List';
        AboutText = 'Analyze and manage your inventory costs and pricing strategies.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UseStockkeepingUnit; UseStockkeepingUnitReq)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want the report to be based on stockkeeping units rather than items.';
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
        ItemFilter := Item.GetFilters();
        GetGLSetup();
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemCostManagement: Codeunit ItemCostManagement;
        ItemFilter: Text;
        AverageCost: Decimal;
        AverageCostACY: Decimal;
        GLSetupRead: Boolean;
        UseStockkeepingUnitReq: Boolean;
        SKUPrintLoop: Integer;
        InvCostAndPriceListCaptionLbl: Label 'Inventory Cost and Price List';
        PageNoCaptionLbl: Label 'Page';
        BOMCaptionLbl: Label 'BOM';
        AvgCostCaptionLbl: Label 'Average Cost';
        ProfitCaptionLbl: Label 'Profit';
        LastDirCostCaptionLbl: Label 'Last Direct Cost';
        LocationCodeCaptionLbl: Label 'Location Code';
        VariantCodeCaptionLbl: Label 'Variant Code';

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GeneralLedgerSetup.Get();
        GLSetupRead := true;
    end;

    procedure InitializeRequest(NewUseStockkeepingUnit: Boolean)
    begin
        UseStockkeepingUnitReq := NewUseStockkeepingUnit;
    end;
}

