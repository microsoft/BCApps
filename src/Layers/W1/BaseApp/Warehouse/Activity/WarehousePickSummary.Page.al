// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

page 5772 "Warehouse Pick Summary"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Warehouse Pick Summary";
    SourceTableTemporary = true;
    Editable = false;
    Caption = 'Create Warehouse Pick Summary';
    Description = 'Shows the available quantities in the warehouse used for calculating the pick quantity.';

    layout
    {
        area(Content)
        {
            field("Message"; Message)
            {
                Caption = 'Message';
                ToolTip = 'Specifies a message that indicates the result of creation of warehouse pick.';
            }
            group(Lines)
            {
                Caption = 'Lines';
                repeater(Lines_Repeater)
                {
                    field("Source Document"; Rec."Source Document")
                    {
                        ToolTip = 'Specifies the type of document that the line relates to.';
                    }
                    field("Source Type"; Rec."Source Type")
                    {
                        ToolTip = 'Specifies the type of source document to which the warehouse activity line relates, such as sales, purchase, and production.';
                        Visible = false;
                    }
                    field("Source No."; Rec."Source No.")
                    {
                        ToolTip = 'Specifies the number of the source document that the entry originates from.';
                    }
                    field("Source Line No."; Rec."Source Line No.")
                    {
                        ToolTip = 'Specifies the line number of the source document';
                    }
                    field("Source Subline No."; Rec."Source Subline No.")
                    {
                        ToolTip = 'Specifies the subline number of the source document';
                        Visible = false;
                    }
                    field("Location Code"; Rec."Location Code")
                    {
                        ToolTip = 'Specifies the code for the location where the pick activity occurs.';
                        Visible = false;
                    }
                    field("Item No."; Rec."Item No.")
                    {
                        ToolTip = 'Specifies the item number of the item to be picked.';
                    }
                    field("Variant Code"; Rec."Variant Code")
                    {
                        ToolTip = 'Specifies the variant of the item on the line.';
                        Visible = false;
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                        Visible = false;
                    }
                    field("Qty. to Handle"; Rec."Qty. to Handle")
                    {
                        ToolTip = 'Specifies how many units to handle in this warehouse activity.';
                        Visible = false;
                    }
                    field("Qty. to Handle (Base)"; Rec."Qty. to Handle (Base)")
                    {
                        ToolTip = 'Specifies how many units to handle (base unit of measure) in this warehouse activity.';
                    }
                    field("Qty. Handled"; Rec."Qty. Handled")
                    {
                        ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
                        Visible = false;
                    }
                    field("Qty. Handled (Base)"; Rec."Qty. Handled (Base)")
                    {
                        ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
                        StyleExpr = Style;
                    }
                }
            }
        }
        area(FactBoxes)
        {
            part(SummaryPart; "Warehouse Pick Summary Part")
            {
                Caption = 'Summary';
                SubPageLink = "Source Document" = field("Source Document"), "Source No." = field("Source No."), "Source Line No." = field("Source Line No."), "Source Subline No." = field("Source Subline No.");
            }
            part(LocationPart; "Location Card Part")
            {
                Caption = 'Location';
                SubPageLink = Code = field("Location Code");
            }
            part(ItemWarehouseFactBox; "Item Warehouse FactBox")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = field("Item No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Bin Content")
            {
                ApplicationArea = Warehouse;
                Caption = 'Bin Contents';
                Image = BinContent;
                RunObject = Page "Bin Contents";
                RunPageLink = "Item No." = field("Item No."), "Variant Code" = field("Variant Code");
                RunPageView = sorting("Item No.");
                ToolTip = 'View the quantities of the item in each bin where it exists. You can see all the important parameters relating to bin content, and you can modify certain bin content parameters in this window.';
            }
            action("Reservation Entries")
            {
                ApplicationArea = Warehouse, Reservation;
                Caption = 'Reservation Entries';
                Image = ReservationLedger;
                ToolTip = 'View all reservation entries for the selected line.';

                trigger OnAction()
                begin
                    Rec.ShowReservationEntries();
                end;
            }
        }
        area(Promoted)
        {
            actionref(BinContentPromoted; "Bin Content")
            {
            }
            actionref(ReservationEntriesPromoted; "Reservation Entries")
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Style := Rec.SetQtyToHandleStyle();
    end;

    var
        Style: Text;
        Message: Text;

    internal procedure SetRecords(var NewWarehousePickSummary: Record "Warehouse Pick Summary" temporary; NewMessage: Text; CalledFromMovementWorksheet: Boolean)
    begin
        SetRecords(NewWarehousePickSummary);
        SetMessage(NewMessage);
        SetCalledFromMovementWorksheet(CalledFromMovementWorksheet);
    end;

    local procedure SetRecords(var NewWarehousePickSummary: Record "Warehouse Pick Summary" temporary)
    begin
        if NewWarehousePickSummary.FindFirst() then
            Rec.Copy(NewWarehousePickSummary, true);

        CurrPage.SummaryPart.Page.SetRecords(NewWarehousePickSummary);
    end;

    local procedure SetMessage(NewMessage: Text)
    begin
        Message := NewMessage;
    end;

    local procedure SetCalledFromMovementWorksheet(CalledFromMovementWorksheet: Boolean)
    begin
        CurrPage.SummaryPart.Page.SetCalledFromMovementWorksheet(CalledFromMovementWorksheet);
    end;
}
