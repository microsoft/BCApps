// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Journal;

page 5785 "Warehouse Activity Lines"
{
    Caption = 'Warehouse Activity Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Activity Line";

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
                field("Activity Type"; Rec."Activity Type")
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
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
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
                    ApplicationArea = Suite;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
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
                    Editable = false;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item to be handled, in the base unit of measure.';
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Outstanding (Base)"; Rec."Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items, expressed in the base unit of measure, that have not yet been handled for this warehouse activity line.';
                }
                field("Qty. to Handle"; Rec."Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. to Handle (Base)"; Rec."Qty. to Handle (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items to be handled in this warehouse activity.';
                }
                field("Qty. Handled"; Rec."Qty. Handled")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Handled (Base)"; Rec."Qty. Handled (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
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
                field("Whse. Document Type"; Rec."Whse. Document Type")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Whse. Document Line No."; Rec."Whse. Document Line No.")
                {
                    ApplicationArea = Warehouse;
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
                action(ShowDocument)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Document';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowActivityDoc();
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
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Card_Promoted; ShowDocument)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        WMSManagement.CheckUserIsWhseEmployee();

        Rec.FilterGroup(2); // set group of filters user cannot change
        Rec.SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId()));
        Rec.FilterGroup(0); // set filter group back to standard
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := FormCaption();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Warehouse Put-away Lines';
        Text001: Label 'Warehouse Pick Lines';
        Text002: Label 'Warehouse Movement Lines';
        Text003: Label 'Warehouse Activity Lines';
        Text004: Label 'Inventory Put-away Lines';
        Text005: Label 'Inventory Pick Lines';
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
            Rec."Activity Type"::"Invt. Put-away":
                exit(Text004);
            Rec."Activity Type"::"Invt. Pick":
                exit(Text005);
            else
                exit(Text003);
        end;
    end;
}

