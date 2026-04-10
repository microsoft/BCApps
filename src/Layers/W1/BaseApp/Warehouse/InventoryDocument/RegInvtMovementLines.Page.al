// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InventoryDocument;

using Microsoft.Warehouse.Journal;

page 7387 "Reg. Invt. Movement Lines"
{
    Caption = 'Reg. Invt. Movement Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Registered Invt. Movement Line";

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
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source Subtype"; Rec."Source Subtype")
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
                field("Source Subline No."; Rec."Source Subline No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
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
                    ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Line table.';
                    Visible = false;
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Warehouse;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                }
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
                action("Show Registered Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Registered Document';
                    Image = ViewRegisteredOrder;
                    RunObject = Page "Registered Invt. Movement";
                    RunPageLink = "No." = field("No.");
                    RunPageView = sorting("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the related completed warehouse document.';
                }
                action("Show Source Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Source Document';
                    Image = ViewOrder;
                    ToolTip = 'View the related source document.';

                    trigger OnAction()
                    var
                        WMSMgt: Codeunit "WMS Management";
                    begin
                        WMSMgt.ShowSourceDocCard(Rec."Source Type", Rec."Source Subtype", Rec."Source No.");
                    end;
                }
            }
        }
    }
}

