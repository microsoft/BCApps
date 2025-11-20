// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity.History;

page 7364 "Registered Whse. Act.-Lines"
{
    Caption = 'Registered Whse. Act.-Lines';
    Editable = false;
    PageType = List;
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
                    ToolTip = 'Specifies the action you must perform for the items on the line.';
                    Visible = false;
                }
                field("Activity Type"; Rec."Activity Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of activity that the warehouse performed on the line, such as put-away, pick, or movement.';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the registered warehouse activity line.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of transaction the source document is associated with, such as sales, purchase, and production.';
                    Visible = false;
                }
                field("Source Subtype"; Rec."Source Subtype")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the source subtype of the document related to the registered activity line.';
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the line number of the source document that the entry originates from.';
                }
                field("Source Subline No."; Rec."Source Subline No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document subline related to this activity line.';
                    Visible = false;
                }
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location at which the activity occurs.';
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone in which the bin on this line is located.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item on the line for information use.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item number of the item to be handled, such as picked or put away.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity per unit of measure of the item on the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item on the line.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item that was put-away, picked or moved.';
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item that was put-away, picked or moved.';
                    Visible = false;
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the equipment required when you perform the action on the line.';
                    Visible = false;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shipping advice about whether a partial delivery was acceptable to the order recipient.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                }
                field("Whse. Document Type"; Rec."Whse. Document Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line originated from.';
                    Visible = false;
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document that is the basis for the action on the line.';
                    Visible = false;
                }
                field("Whse. Document Line No."; Rec."Whse. Document Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line in the warehouse document that is the basis for the action on the line.';
                    Visible = false;
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
                action("Show Registered Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Registered Document';
                    Image = ViewRegisteredOrder;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the related completed warehouse document.';

                    trigger OnAction()
                    begin
                        Rec.ShowRegisteredActivityDoc();
                    end;
                }
                action("Show &Whse. Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show &Whse. Document';
                    Image = ViewOrder;
                    ToolTip = 'View the related warehouse document.';

                    trigger OnAction()
                    begin
                        Rec.ShowWhseDoc();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Registered Document_Promoted"; "Show Registered Document")
                {
                }
                actionref("Show &Whse. Document_Promoted"; "Show &Whse. Document")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := FormCaption();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Registered Whse. Put-away Lines';
        Text001: Label 'Registered Whse. Pick Lines';
        Text002: Label 'Registered Whse. Movement Lines';
        Text003: Label 'Registered Whse. Activity Lines';
#pragma warning restore AA0074

    local procedure FormCaption(): Text[250]
    begin
        case Rec."Activity Type" of
            Rec."Activity Type"::"Put-away":
                exit(Text000);
            Rec."Activity Type"::Pick:
                exit(Text001);
            Rec."Activity Type"::Movement:
                exit(Text002);
            else
                exit(Text003);
        end;
    end;
}

