// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

using Microsoft.Inventory.Tracking;
using System.Security.User;

page 5893 "Phys. Invt. Item Track. List"
{
    Caption = 'Phys. Invt. Item Track. List';
    Editable = false;
    PageType = List;
    SourceTable = "Reservation Entry";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the location of the traced item.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number of the item that is being handled on the document line.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the package number of the item that is being handled on the document line.';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expiration date of the item that is being handled on the document line.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that the difference is positive.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity of the record.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies how many of the base unit of measure are contained in one unit of the item.';
                    Visible = false;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity on the line, expressed in base units of measure.';
                    Visible = false;
                }
                field("Qty. to Handle (Base)"; Rec."Qty. to Handle (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity of item, in the base unit of measure, to be handled in a warehouse activity.';
                    Visible = false;
                }
                field("Qty. to Invoice (Base)"; Rec."Qty. to Invoice (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity, in the base unit of measure, that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Reservation Status"; Rec."Reservation Status")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the status of the reservation.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the user who created the traced record.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Created By");
                    end;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies when the traced record was created.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number that is assigned to the entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(ItemTracking)
            {
                Caption = 'Item &Tracking Information';
                Image = Line;
                action("Serial No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Serial No." = field("Serial No.");
                    ToolTip = 'Show Serial No. Information Card';
                }
                action("Lot No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Lot No." = field("Lot No.");
                    ToolTip = 'Show Lot No. Information Card';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Item Tracking Information', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Serial No. Information Card_Promoted"; "Serial No. Information Card")
                {
                }
                actionref("Lot No. Information Card_Promoted"; "Lot No. Information Card")
                {
                }
            }
        }
    }
}

