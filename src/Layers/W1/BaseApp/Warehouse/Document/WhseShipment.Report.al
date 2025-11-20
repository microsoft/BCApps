// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Inventory.Location;
using System.Utilities;

report 7317 "Whse. - Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Document/WhseShipment.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Shipment';
    UsageCategory = Documents;
    WordMergeDataItem = "Warehouse Shipment Header";

    dataset
    {
        dataitem("Warehouse Shipment Header"; "Warehouse Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(HeaderNo_WhseShptHeader; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(AssUid__WhseShptHeader; "Warehouse Shipment Header"."Assigned User ID")
                {
                    IncludeCaption = true;
                }
                column(HrdLocCode_WhseShptHeader; "Warehouse Shipment Header"."Location Code")
                {
                    IncludeCaption = true;
                }
                column(HeaderNo1_WhseShptHeader; "Warehouse Shipment Header"."No.")
                {
                    IncludeCaption = true;
                }
                column(Show1; not Location."Bin Mandatory")
                {
                }
                column(Show2; Location."Bin Mandatory")
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(WarehouseShipmentCaption; WarehouseShipmentCaptionLbl)
                {
                }
                dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemLinkReference = "Warehouse Shipment Header";
                    DataItemTableView = sorting("No.", "Line No.");
                    column(ShelfNo_WhseShptLine; "Shelf No.")
                    {
                        IncludeCaption = true;
                    }
                    column(ItemNo_WhseShptLine; "Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Desc_WhseShptLine; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(UomCode_WhseShptLine; "Unit of Measure Code")
                    {
                        IncludeCaption = true;
                    }
                    column(LocCode_WhseShptLine; "Location Code")
                    {
                        IncludeCaption = true;
                    }
                    column(Qty_WhseShptLine; Quantity)
                    {
                        IncludeCaption = true;
                    }
                    column(SourceNo_WhseShptLine; "Source No.")
                    {
                        IncludeCaption = true;
                    }
                    column(SourceDoc_WhseShptLine; "Source Document")
                    {
                        IncludeCaption = true;
                    }
                    column(ZoneCode_WhseShptLine; "Zone Code")
                    {
                        IncludeCaption = true;
                    }
                    column(BinCode_WhseShptLine; "Bin Code")
                    {
                        IncludeCaption = true;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        this.GetLocation("Location Code");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                this.GetLocation("Location Code");
            end;
        }
    }

    requestpage
    {
        Caption = 'Warehouse Shipment';

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
        Location: Record Location;
        CurrReportPageNoCaptionLbl: Label 'Page';
        WarehouseShipmentCaptionLbl: Label 'Warehouse Shipment';

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;
}

