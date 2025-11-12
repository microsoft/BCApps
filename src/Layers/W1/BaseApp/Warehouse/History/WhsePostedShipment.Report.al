// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Inventory.Location;
using System.Utilities;

report 7309 "Whse. - Posted Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/History/WhsePostedShipment.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Posted Shipment';
    UsageCategory = Documents;
    WordMergeDataItem = "Posted Whse. Shipment Header";

    dataset
    {
        dataitem("Posted Whse. Shipment Header"; "Posted Whse. Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(AssgndUID_PostedWhseShptHeader; "Posted Whse. Shipment Header"."Assigned User ID")
                {
                }
                column(LocCode_PostedWhseShptHeader; "Posted Whse. Shipment Header"."Location Code")
                {
                }
                column(No_PostedWhseShptHeader; "Posted Whse. Shipment Header"."No.")
                {
                }
                column(BinMandatoryShow1; not Location."Bin Mandatory")
                {
                }
                column(BinMandatoryShow2; Location."Bin Mandatory")
                {
                }
                column(AssgndUID_PostedWhseShptHeaderCaption; "Posted Whse. Shipment Header".FieldCaption("Assigned User ID"))
                {
                }
                column(LocCode_PostedWhseShptHeaderCaption; "Posted Whse. Shipment Header".FieldCaption("Location Code"))
                {
                }
                column(No_PostedWhseShptHeaderCaption; "Posted Whse. Shipment Header".FieldCaption("No."))
                {
                }
                column(ShelfNo_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Shelf No."))
                {
                }
                column(ItemNo_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Item No."))
                {
                }
                column(Desc_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption(Description))
                {
                }
                column(UOM_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Unit of Measure Code"))
                {
                }
                column(Qty_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption(Quantity))
                {
                }
                column(SourceNo_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Source No."))
                {
                }
                column(SourceDoc_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Source Document"))
                {
                }
                column(ZoneCode_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Zone Code"))
                {
                }
                column(BinCode_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Bin Code"))
                {
                }
                column(LocCode_PostedWhseShptLineCaption; "Posted Whse. Shipment Line".FieldCaption("Location Code"))
                {
                }
                column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
                {
                }
                column(WarehousePostedShipmentCaption; WarehousePostedShipmentCaptionLbl)
                {
                }
                dataitem("Posted Whse. Shipment Line"; "Posted Whse. Shipment Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemLinkReference = "Posted Whse. Shipment Header";
                    DataItemTableView = sorting("No.", "Line No.");
                    column(ShelfNo_PostedWhseShptLine; "Shelf No.")
                    {
                    }
                    column(ItemNo_PostedWhseShptLine; "Item No.")
                    {
                    }
                    column(Desc_PostedWhseShptLine; Description)
                    {
                    }
                    column(UOM_PostedWhseShptLine; "Unit of Measure Code")
                    {
                    }
                    column(LocCode_PostedWhseShptLine; "Location Code")
                    {
                    }
                    column(Qty_PostedWhseShptLine; Quantity)
                    {
                    }
                    column(SourceNo_PostedWhseShptLine; "Source No.")
                    {
                    }
                    column(SourceDoc_PostedWhseShptLine; "Source Document")
                    {
                    }
                    column(ZoneCode_PostedWhseShptLine; "Zone Code")
                    {
                    }
                    column(BinCode_PostedWhseShptLine; "Bin Code")
                    {
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
        Caption = 'Warehouse Posted Shipment';

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
        CurrReportPAGENOCaptionLbl: Label 'Page';
        WarehousePostedShipmentCaptionLbl: Label 'Warehouse Posted Shipment';

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;
}

