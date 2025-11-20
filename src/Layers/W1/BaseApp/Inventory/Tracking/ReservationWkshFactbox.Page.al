// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 330 "Reservation Wksh. Factbox"
{
    PageType = CardPart;
    ApplicationArea = Reservation;
    SourceTable = "Reservation Wksh. Line";
    Caption = 'Details';

    layout
    {
        area(Content)
        {
            group(Demand)
            {
                Caption = 'Demand';

                field("Source Ref. No."; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    ToolTip = 'Specifies the line number of the source document.';

                    trigger OnDrillDown()
                    begin
                        ReservationWorksheetMgt.ShowSourceDocument(Rec);
                    end;
                }
                field(Priority; Rec.Priority)
                {
                    Caption = 'Priority';
                    Visible = false;
                    ToolTip = 'Specifies the priority of the customer.';
                }
                field("Outstanding Qty."; OutstandingQty)
                {
                    Caption = 'Outstanding quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity that has not yet been handled for this source document line.';
                }
                field("Total Reserved Qty."; TotalReservedQty)
                {
                    Caption = 'Reserved quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity that has been reserved for this source document line.';

                    trigger OnDrillDown()
                    begin
                        ReservationWorksheetMgt.ShowReservationEntries(Rec);
                    end;
                }
                field("Reserved From Stock Qty."; ReservedFromStockQty)
                {
                    Caption = 'Reserved from stock';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity that has been reserved from stock for this source document line.';
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';

                field("Qty. in Stock"; Rec."Qty. in Stock")
                {
                    Caption = 'Current stock';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the current stock quantity for the item.';
                }
                field("Qty. Reserved in Stock"; Rec."Qty. Reserved in Stock")
                {
                    Caption = 'Reserved quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity that has been reserved from stock for this item.';
                }
                field("Qty. in Whse. Handling"; Rec."Qty. in Whse. Handling")
                {
                    Caption = 'Qty. in warehouse handling';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity that is currently in warehouse handling for this item.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Statistics)
            {
                Caption = 'Statistics';
                Image = Statistics;
                ToolTip = 'Show statistics for the source document.';

                trigger OnAction()
                begin
                    ReservationWorksheetMgt.ShowStatistics(Rec);
                end;
            }
        }
    }

    var
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        OutstandingQty, TotalReservedQty, ReservedFromStockQty : Decimal;

    trigger OnAfterGetRecord()
    begin
        ReservationWorksheetMgt.GetSourceDocumentLineQuantities(Rec, OutstandingQty, TotalReservedQty, ReservedFromStockQty);
    end;

    trigger OnOpenPage()
    begin
        OutstandingQty := 0;
        TotalReservedQty := 0;
        ReservedFromStockQty := 0;
    end;
}
