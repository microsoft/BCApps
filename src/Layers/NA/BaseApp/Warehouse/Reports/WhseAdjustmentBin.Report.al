// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Utilities;

report 7320 "Whse. Adjustment Bin"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/WhseAdjustmentBin.rdlc';
    AccessByPermission = TableData Bin = R;
    AdditionalSearchTerms = 'synchronize inventory';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Adjustment Bin';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Warehouse Entry"; "Warehouse Entry")
        {
            DataItemTableView = sorting("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code");
            RequestFilterFields = "Location Code", "Item No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormated; Format(Today, 0, 4))
            {
            }
            column(Details; Details)
            {
            }
            column(WarehouseEntryTableCaption; TableCaption + ': ' + WhseEntryFilter)
            {
            }
            column(WhseEntryFilter; WhseEntryFilter)
            {
            }
            column(LocCode_WarehouseEntry; "Location Code")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(WarehouseAdjBinCaption; WarehouseAdjBinCaptionLbl)
            {
            }
            column(WhseEntry2UOMCodeCaption; WhseEntry2.FieldCaption("Unit of Measure Code"))
            {
            }
            column(WhseEntry2QtyPerUOMCaption; WhseEntry2.FieldCaption("Qty. per Unit of Measure"))
            {
            }
            column(WhseEntry2QtyBaseCaption; WhseEntry2.FieldCaption("Qty. (Base)"))
            {
            }
            column(WhseEntry2QuantityCaption; WhseEntry2.FieldCaption(Quantity))
            {
            }
            column(WhseEntry2VariantCodeCaption; WhseEntry2.FieldCaption("Variant Code"))
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(WarehouseEntryLocCode; "Warehouse Entry"."Location Code")
                {
                }
                column(WarehouseEntryBinCode; "Warehouse Entry"."Bin Code")
                {
                }
                column(WarehouseEntryZoneCode; "Warehouse Entry"."Zone Code")
                {
                }
                column(IntHdr1; WhseEntry."Location Code" <> "Warehouse Entry"."Location Code")
                {
                }
                column(WarehouseEntryItemNo; "Warehouse Entry"."Item No.")
                {
                }
                column(IntHdr2; WhseEntry."Item No." <> "Warehouse Entry"."Item No.")
                {
                }
                column(WhseEntryQuantity; WhseEntry.Quantity)
                {
                    DecimalPlaces = 2 : 2;
                }
                column(WhseEntryQtyBase; WhseEntry."Qty. (Base)")
                {
                    DecimalPlaces = 2 : 2;
                }
                column(WarehouseEntryQtyPerUOM; "Warehouse Entry"."Qty. per Unit of Measure")
                {
                }
                column(WarehouseEntryUOMCode; "Warehouse Entry"."Unit of Measure Code")
                {
                }
                column(WarehouseEntryVariantCode; "Warehouse Entry"."Variant Code")
                {
                }
                column(WarehouseEntryLocCodeCaption; WarehouseEntryLocCodeCaptionLbl)
                {
                }
                column(WarehouseEntryBinCodeCaption; WarehouseEntryBinCodeCaptionLbl)
                {
                }
                column(WarehouseEntryZoneCodeCaption; WarehouseEntryZoneCodeCaptionLbl)
                {
                }
                column(WarehouseEntryItemNoCaption; WarehouseEntryItemNoCaptionLbl)
                {
                }

                trigger OnPostDataItem()
                begin
                    WhseEntry.FindLast();
                    "Warehouse Entry" := WhseEntry;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(WhseEntry);
                    if Details then
                        CurrReport.Break();

                    WhseEntry.Reset();
                    WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code");
                    WhseEntry.SetRange("Item No.", "Warehouse Entry"."Item No.");
                    WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
                    WhseEntry.SetRange("Location Code", "Warehouse Entry"."Location Code");
                    WhseEntry.SetRange("Variant Code", "Warehouse Entry"."Variant Code");
                    WhseEntry.SetRange("Unit of Measure Code", "Warehouse Entry"."Unit of Measure Code");
                    WhseEntry.CalcSums("Qty. (Base)", Quantity);
                    if (WhseEntry."Qty. (Base)" = 0) and not ZeroQty then
                        CurrReport.Break();
                end;
            }
            dataitem(WhseEntry2; "Warehouse Entry")
            {
                DataItemLink = "Location Code" = field("Location Code"), "Bin Code" = field("Bin Code"), "Item No." = field("Item No."), "Variant Code" = field("Variant Code"), "Unit of Measure Code" = field("Unit of Measure Code");
                DataItemTableView = sorting("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code");
                column(WhseEntry2LocCode; "Location Code")
                {
                }
                column(WhseEntry2BinCode; "Bin Code")
                {
                }
                column(WhseEntry2ZoneCode; "Zone Code")
                {
                }
                column(WhseEntry2ItemNo; "Item No.")
                {
                }
                column(WhseEntry2Quantity; Quantity)
                {
                }
                column(WhseEntry2QtyPerUOM; "Qty. per Unit of Measure")
                {
                }
                column(WhseEntry2UOMCode; "Unit of Measure Code")
                {
                }
                column(WhseEntry2QtyBase; "Qty. (Base)")
                {
                }
                column(WhseEntry2VariantCode; "Variant Code")
                {
                }
                column(TotalForItemNo; Text000 + FieldCaption("Item No."))
                {
                }
                column(TotalForLocCode; Text000 + FieldCaption("Location Code"))
                {
                }
                column(WhseEntry2LocationCodeCaption; FieldCaption("Location Code"))
                {
                }
                column(WhseEntry2BinCodeCaption; FieldCaption("Bin Code"))
                {
                }
                column(WhseEntry2ZoneCodeCaption; FieldCaption("Zone Code"))
                {
                }
                column(WhseEntry2ItemNoCaption; FieldCaption("Item No."))
                {
                }

                trigger OnPostDataItem()
                begin
                    if "Bin Code" <> '' then
                        "Warehouse Entry" := WhseEntry2;
                end;

                trigger OnPreDataItem()
                begin
                    if not Details then
                        CurrReport.Break();
                    if not Find('-') then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Location.Code <> "Location Code" then begin
                    Location.Get("Location Code");
                    if Location."Adjustment Bin Code" = '' then
                        CurrReport.Skip();

                    SetRange("Bin Code", Location."Adjustment Bin Code");
                    if not Find('-') then
                        CurrReport.Break();
                end;
            end;

            trigger OnPreDataItem()
            begin
                Clear(Location);
                if not Find('-') then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Warehouse Adjustment Bin';
        AboutText = 'Get an overview of adjustment bin usage (for advanced warehouse scenarios).';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ZeroQty; ZeroQty)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Show Zero Quantity';
                        ToolTip = 'Specifies that items that have been stored in the adjustment bin, but currently have no quantity in the bin, should be included in the report.';
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
        WhseEntryFilter := "Warehouse Entry".GetFilters();
    end;

    var
        Location: Record Location;
        WhseEntry: Record "Warehouse Entry";
        WhseEntryFilter: Text;
#pragma warning disable AA0074
        Text000: Label 'Total for ';
#pragma warning restore AA0074
        Details: Boolean;
        ZeroQty: Boolean;
        CurrReportPageNoCaptionLbl: Label 'Page';
        WarehouseAdjBinCaptionLbl: Label 'Warehouse Adjustment Bin';
        WarehouseEntryLocCodeCaptionLbl: Label 'Location Code';
        WarehouseEntryBinCodeCaptionLbl: Label 'Bin No';
        WarehouseEntryZoneCodeCaptionLbl: Label 'Zone Code';
        WarehouseEntryItemNoCaptionLbl: Label 'Item No.';
}

