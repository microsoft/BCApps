// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

page 7380 "Phys. Invt. Item Selection"
{
    Caption = 'Phys. Invt. Item Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Phys. Invt. Item Selection";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Phys Invt Counting Period Code"; Rec."Phys Invt Counting Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Counting Date"; Rec."Last Counting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Next Counting Start Date"; Rec."Next Counting Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Next Counting End Date"; Rec."Next Counting End Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Count Frequency per Year"; Rec."Count Frequency per Year")
                {
                    ApplicationArea = Basic, Suite;
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
                action("Item Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Card';
                    Image = Item;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the item.';
                }
                action("SKU Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'SKU Card';
                    Image = SKU;
                    RunObject = Page "Stockkeeping Unit List";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Location Code" = field("Location Code");
                    ToolTip = 'View or edit detailed information for the stockkeeping unit.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    local procedure LookupOKOnPush()
    begin
        CurrPage.SetSelectionFilter(Rec);
        Rec.ModifyAll(Selected, true);
    end;
}

