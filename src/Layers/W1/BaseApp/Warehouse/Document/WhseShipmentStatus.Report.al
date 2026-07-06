// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Inventory.Location;

report 7313 "Whse. Shipment Status"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Document/WhseShipmentStatus.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Shipment Status';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Warehouse Shipment Header";

    dataset
    {
        dataitem("Warehouse Shipment Header"; "Warehouse Shipment Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Document Status", "Location Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(WhseShipmentLineCaption; "Warehouse Shipment Line".TableCaption + ':' + WhseShipmentLine)
            {
            }
            column(WhseShipmentLine; WhseShipmentLine)
            {
            }
            column(No_WhseShipmentHeader; "No.")
            {
            }
            column(WarehouseShipmentStatusCaption; WarehouseShipmentStatusCaptionLbl)
            {
            }
            column(CurrReportPAGENOCaption; CurrReportPAGENOCaptionLbl)
            {
            }
            dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("No.", "Line No.");
                RequestFilterFields = Status;
                column(LocCode_WhseShipmentLine; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(No_WarehouseShipmentLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(DocStatus_WhseShipmentHdr; "Warehouse Shipment Header"."Document Status")
                {
                    IncludeCaption = true;
                }
                column(LocationBinMandatory; Location."Bin Mandatory")
                {
                }
                column(SourceNo_WhseShipmentLine; "Source No.")
                {
                    IncludeCaption = true;
                }
                column(SourceDoc_WhseShptLine; "Source Document")
                {
                    IncludeCaption = true;
                }
                column(BinCode_WhseShipmentLine; "Bin Code")
                {
                    IncludeCaption = true;
                }
                column(ZoneCode_WhseShipmentLine; "Zone Code")
                {
                    IncludeCaption = true;
                }
                column(ItemNo_WhseShipmentLine; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(Quantity_WhseShipmentLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(UOMCode_WhseShipmentLine; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(QtyperUOM_WhseShptLine; "Qty. per Unit of Measure")
                {
                    IncludeCaption = true;
                }
                column(Status_WhseShipmentLine; Status)
                {
                    IncludeCaption = true;
                }
                column(QtytoShip_WhseShipmentLine; "Qty. to Ship")
                {
                    IncludeCaption = true;
                }
                column(QtyShipped_WhseShptLine; "Qty. Shipped")
                {
                    IncludeCaption = true;
                }
                column(QtyOutstdg_WhseShptLine; "Qty. Outstanding")
                {
                    IncludeCaption = true;
                }
                column(ShelfNo_WhseShipmentLine; "Shelf No.")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    this.GetLocation("Location Code");
                end;
            }
        }
    }

    requestpage
    {
        Caption = 'Warehouse Shipment Status';
        AboutTitle = 'Warehouse Shipment Status';
        AboutText = 'Get an overview of source documents that are open, have items that are shipped, or are due to ship for each location.';

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
        WhseShipmentLine := "Warehouse Shipment Line".GetFilters();
    end;

    var
        Location: Record Location;
        WhseShipmentLine: Text;
        WarehouseShipmentStatusCaptionLbl: Label 'Warehouse Shipment Status';
        CurrReportPAGENOCaptionLbl: Label 'Page';


    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;
}

