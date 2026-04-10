// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

page 7363 "Posted Whse. Receipt Lines"
{
    Caption = 'Posted Whse. Receipt Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Whse. Receipt Line";

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
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
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
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that was received, in the base unit of measure.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                }
                field("Posted Source Document"; Rec."Posted Source Document")
                {
                    ApplicationArea = Warehouse;
                }
                field("Posted Source No."; Rec."Posted Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Posted Whse. Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Posted Whse. Document';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the related completed warehouse shipment.';

                    trigger OnAction()
                    var
                        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
                    begin
                        PostedWhseRcptHeader.Get(Rec."No.");
                        PAGE.Run(PAGE::"Posted Whse. Receipt", PostedWhseRcptHeader);
                    end;
                }
            }
        }
    }
}

