// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Ledger;

report 7303 "Warehouse Register - Quantity"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/WarehouseRegisterQuantity.rdlc';
    AccessByPermission = TableData Location = R;
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Register - Quantity';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Warehouse Register"; "Warehouse Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(WhseRegisterCaptionWithFilter; TableCaption + ': ' + WhseRegFilter)
            {
            }
            column(WhseRegFilter; WhseRegFilter)
            {
            }
            column(No_WarehouseRegister; "No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(WarehouseRegisterQuantityCaption; WarehouseRegisterQuantityCaptionLbl)
            {
            }
            column(WarehouseEntryRegisteringDateCaption; WarehouseEntryRegisteringDateCaptionLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(WarehouseRegisterNoCaption; WarehouseRegisterNoCaptionLbl)
            {
            }
            dataitem("Warehouse Entry"; "Warehouse Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(EntryNo_WarehouseEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(Quantity_WarehouseEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(ItemNo_WarehouseEntry; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(WhseDocNo_WarehouseEntry; "Whse. Document No.")
                {
                    IncludeCaption = true;
                }
                column(RegDate_WarehouseEntry; Format("Registering Date"))
                {
                }
                column(ZoneCode_WarehouseEntry; "Zone Code")
                {
                    IncludeCaption = true;
                }
                column(BinCode_WarehouseEntry; "Bin Code")
                {
                    IncludeCaption = true;
                }
                column(Cubage_WarehouseEntry; Cubage)
                {
                    IncludeCaption = true;
                }
                column(Weight_WarehouseEntry; Weight)
                {
                    IncludeCaption = true;
                }
                column(UOMCode_WarehouseEntry; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(VariantCode_WarehouseEntry; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(ItemDescription; ItemDescription)
                {
                }
                column(SerialNo_WarehouseEntry; "Serial No.")
                {
                    IncludeCaption = true;
                }
                column(LotNo_WarehouseEntry; "Lot No.")
                {
                    IncludeCaption = true;
                }
                column(EntryType_WarehouseEntry; "Entry Type")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    if Item."No." <> "Item No." then begin
                        if not Item.Get("Item No.") then
                            Item.Init();
                        ItemDescription := Item.Description;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "Warehouse Register"."From Entry No.", "Warehouse Register"."To Entry No.");
                end;
            }
        }
    }

    requestpage
    {

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
        WhseRegFilter := "Warehouse Register".GetFilters();
    end;

    var
        Item: Record Item;
        WhseRegFilter: Text;
        ItemDescription: Text[100];
        CurrReportPageNoCaptionLbl: Label 'Page';
        WarehouseRegisterQuantityCaptionLbl: Label 'Warehouse Register - Quantity';
        WarehouseEntryRegisteringDateCaptionLbl: Label 'Registering Date';
        ItemDescriptionCaptionLbl: Label 'Description';
        WarehouseRegisterNoCaptionLbl: Label 'Register No.';
}

