// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

page 5718 "Item Substitution Entries"
{
    Caption = 'Item Substitution Entries';
    DataCaptionFields = "No.", Description;
    DelayedInsert = true;
    Editable = false;
    PageType = Worksheet;
    SourceTable = "Item Substitution";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Suite;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Substitute No."; Rec."Substitute No.")
                {
                    ApplicationArea = Suite;
                }
                field("Substitute Variant Code"; Rec."Substitute Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Suite;
                    DecimalPlaces = 0 : 5;
                }
                field("Quantity Avail. on Shpt. Date"; Rec."Quantity Avail. on Shpt. Date")
                {
                    ApplicationArea = Suite;
                }
                field(Condition; Rec.Condition)
                {
                    ApplicationArea = Basic, Suite;
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
        area(processing)
        {
            action("&Condition")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Condition';
                Image = ViewComments;
                RunObject = Page "Sub. Conditions";
                RunPageLink = Type = field(Type),
                              "No." = field("No."),
                              "Variant Code" = field("Variant Code"),
                              "Substitute Type" = field("Substitute Type"),
                              "Substitute No." = field("Substitute No."),
                              "Substitute Variant Code" = field("Substitute Variant Code");
                ToolTip = 'Specify a condition for the item substitution, which is for information only and does not affect the item substitution.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Condition_Promoted"; "&Condition")
                {
                }
            }
        }
    }
}

