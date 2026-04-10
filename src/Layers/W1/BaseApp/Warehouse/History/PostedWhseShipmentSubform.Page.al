// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

page 7338 "Posted Whse. Shipment Subform"
{
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Posted Whse. Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Destination Type"; Rec."Destination Type")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Destination No."; Rec."Destination No.")
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
                field("Shelf No."; Rec."Shelf No.")
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
                    ApplicationArea = Warehouse;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
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
                action("Posted Source Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Source Document';
                    Image = PostedOrder;
                    ToolTip = 'Open the list of posted source documents.';

                    trigger OnAction()
                    begin
                        ShowPostedSourceDoc();
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
                        ShowWhseLine();
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
        }
    }

    var
        WMSMgt: Codeunit "WMS Management";

    local procedure ShowPostedSourceDoc()
    begin
        WMSMgt.ShowPostedSourceDocument(Rec."Posted Source Document", Rec."Posted Source No.", Rec."Source Document");
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", Rec."Bin Code");
    end;

    local procedure ShowWhseLine()
    begin
        WMSMgt.ShowPostedWhseShptLine(Rec."Whse. Shipment No.", Rec."Whse Shipment Line No.");
    end;
}

