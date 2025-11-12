// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;

report 7319 "Warehouse Bin List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/WarehouseBinList.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Bin List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Bin; Bin)
        {
            DataItemTableView = sorting("Location Code", Code);
            RequestFilterFields = "Location Code", "Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(BinCaption; TableCaption + ': ' + BinFilter)
            {
            }
            column(BinFilter; BinFilter)
            {
            }
            column(BinContent; BinCont)
            {
            }
            column(LocationCode_Bin; "Location Code")
            {
                IncludeCaption = true;
            }
            column(Code_Bin; Code)
            {
                IncludeCaption = true;
            }
            column(Description_Bin; Description)
            {
                IncludeCaption = true;
            }
            column(BinTypeCode_Code; "Bin Type Code")
            {
                IncludeCaption = true;
            }
            column(WarehouseClassCode_Bin; "Warehouse Class Code")
            {
                IncludeCaption = true;
            }
            column(BlockMovement_Bin; "Block Movement")
            {
                IncludeCaption = true;
            }
            column(SpecialEquipmentCode_Bin; "Special Equipment Code")
            {
                IncludeCaption = true;
            }
            column(BinRanking_Bin; "Bin Ranking")
            {
                IncludeCaption = true;
            }
            column(MaximumCubage_Bin; "Maximum Cubage")
            {
                IncludeCaption = true;
            }
            column(MaximumWeight_Bin; "Maximum Weight")
            {
                IncludeCaption = true;
            }
            column(WarehouseBinListCaption; WarehouseBinListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(PutawayQtyCaption; PutawayQtyCaptionLbl)
            {
            }
            column(PickQuantityCaption; PickQuantityCaptionLbl)
            {
            }
            dataitem("Bin Content"; "Bin Content")
            {
                CalcFields = "Quantity (Base)", "Pick Quantity (Base)", "Put-away Quantity (Base)";
                DataItemLink = "Location Code" = field("Location Code"), "Bin Code" = field(Code);
                DataItemTableView = sorting("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
                column(ItemNo_BinContent; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(Quantity_BinContent; Round("Quantity (Base)" / ItemUOM."Qty. per Unit of Measure"))
                {
                }
                column(MinQty_BinContent; "Min. Qty.")
                {
                    IncludeCaption = true;
                }
                column(MaxQty_BinContent; "Max. Qty.")
                {
                    IncludeCaption = true;
                }
                column(VariantCode_BinContent; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(QtyperUOM_BinContent; "Qty. per Unit of Measure")
                {
                    IncludeCaption = true;
                }
                column(UOMCode_BinContent; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(ItemDescription; ItemDescription)
                {
                }
                column(PutawayQty_BinContent; "Put-away Quantity (Base)" * "Qty. per Unit of Measure")
                {
                }
                column(PickQty_BinContent; "Pick Quantity (Base)" * "Qty. per Unit of Measure")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GetItemDescr("Item No.", "Variant Code", ItemDescription);
                end;

                trigger OnPreDataItem()
                begin
                    if not BinCont then
                        CurrReport.Break();

                    if not ItemUOM.Get("Item No.", "Unit of Measure Code") then
                        ItemUOM.Init();
                end;
            }
        }
    }

    requestpage
    {
        Caption = 'Whse. Structure List';
        AboutTitle = 'About Warehouse Bin List';
        AboutText = 'Get an overview of warehouse bins, their setup, and the quantity of items in them.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowBinContents; BinCont)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Show Bin Contents';
                        ToolTip = 'Specifies if you want the report to also include the item quantities of the bins.';
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
        BinFilter := Bin.GetFilters();
    end;

    var
        ItemUOM: Record "Item Unit of Measure";
        BinFilter: Text;
        ItemDescription: Text[100];
        BinCont: Boolean;
        WarehouseBinListCaptionLbl: Label 'Warehouse Bin List';
        PageCaptionLbl: Label 'Page';
        ItemDescriptionCaptionLbl: Label 'Item Description';
        QuantityCaptionLbl: Label 'Quantity';
        PutawayQtyCaptionLbl: Label 'Put-away Quantity';
        PickQuantityCaptionLbl: Label 'Pick Quantity';
}

