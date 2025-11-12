// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Inventory.Location;
using System.Utilities;

report 7308 "Whse. - Posted Receipt"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/History/WhsePostedReceipt.rdlc';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Posted Receipt';
    UsageCategory = Documents;
    WordMergeDataItem = "Posted Whse. Receipt Header";

    dataset
    {
        dataitem("Posted Whse. Receipt Header"; "Posted Whse. Receipt Header")
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
                column(Assgnd_PostedWhseRcpHeader; "Posted Whse. Receipt Header"."Assigned User ID")
                {
                    IncludeCaption = true;
                }
                column(LocCode_PostedWhseRcpHeader; "Posted Whse. Receipt Header"."Location Code")
                {
                    IncludeCaption = true;
                }
                column(No_PostedWhseRcpHeader; "Posted Whse. Receipt Header"."No.")
                {
                    IncludeCaption = true;
                }
                column(BinMandatoryShow1; not Location."Bin Mandatory")
                {
                }
                column(BinMandatoryShow2; Location."Bin Mandatory")
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(WarehousePostedReceiptCaption; WarehousePostedReceiptCaptionLbl)
                {
                }
                dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemLinkReference = "Posted Whse. Receipt Header";
                    DataItemTableView = sorting("No.", "Line No.");
                    column(ShelfNo_PostedWhseRcpLine; "Shelf No.")
                    {
                        IncludeCaption = true;
                    }
                    column(ItemNo_PostedWhseRcpLine; "Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Desc_PostedWhseRcptLine; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(UOM_PostedWhseRcpLine; "Unit of Measure Code")
                    {
                        IncludeCaption = true;
                    }
                    column(LocCode_PostedWhseRcpLine; "Location Code")
                    {
                        IncludeCaption = true;
                    }
                    column(Qty_PostedWhseRcpLine; Quantity)
                    {
                        IncludeCaption = true;
                    }
                    column(SourceNo_PostedWhseRcpLine; "Source No.")
                    {
                        IncludeCaption = true;
                    }
                    column(SourceDoc_PostedWhseRcpLine; "Source Document")
                    {
                        IncludeCaption = true;
                    }
                    column(ZoneCode_PostedWhseRcpLine; "Zone Code")
                    {
                        IncludeCaption = true;
                    }
                    column(BinCode_PostedWhseRcpLine; "Bin Code")
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
        Caption = 'Warehouse Posted Receipt';

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
        WarehousePostedReceiptCaptionLbl: Label 'Warehouse - Posted Receipt';

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;
}

