// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity.History;

using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

page 5799 "Registered Pick Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Registered Whse. Activity Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Action Type"; Rec."Action Type")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Source &Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source &Document Line';
                    Image = SourceDocLine;
                    ToolTip = 'View the line on a released source document that the warehouse activity is for. ';

                    trigger OnAction()
                    begin
                        ShowSourceLine();
                    end;
                }
                action("Whse. Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Document Line';
                    Image = Line;
                    ToolTip = 'View the line on another warehouse document that the warehouse activity is for.';

                    trigger OnAction()
                    begin
                        WMSMgt.ShowWhseActivityDocLine(Rec."Whse. Document Type", Rec."Whse. Document No.", Rec."Whse. Document Line No.");
                    end;
                }
                action("Posted Warehouse Shipment Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Warehouse Shipment Line';
                    Image = PostedShipment;
                    ToolTip = 'View the related line on the posted warehouse shipment.';

                    trigger OnAction()
                    begin
                        ShowPostedWhseShptLine();
                    end;
                }
                action("Bin Contents List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents List';
                    Image = BinContent;
                    ToolTip = 'View the contents of the selected bin and the parameters that define how items are routed through the bin.';

                    trigger OnAction()
                    begin
                        ShowBinContents();
                    end;
                }
            }
            group("P&ick")
            {
                Caption = 'P&ick';
                Image = CreateInventoryPickup;
                action("&Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Warehouse Entries';
                    Image = BinLedger;
                    ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';

                    trigger OnAction()
                    var
                        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
                    begin
                        RegisteredWhseActivityHdr.Get(Rec."Activity Type", Rec."No.");
                        Rec.ShowWhseEntries(RegisteredWhseActivityHdr."Registering Date");
                    end;
                }
            }
        }
    }

    var
        WMSMgt: Codeunit "WMS Management";

    local procedure ShowSourceLine()
    begin
        WMSMgt.ShowSourceDocLine(
          Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.", Rec."Source Subline No.");
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", Rec."Bin Code");
    end;

    local procedure ShowPostedWhseShptLine()
    begin
        WMSMgt.ShowPostedWhseShptLine(Rec."Whse. Document No.", Rec."Whse. Document Line No.");
    end;
}

