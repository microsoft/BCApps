// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

page 5736 "Item References"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item References';
    DataCaptionFields = "Reference Type No.";
    Editable = true;
    PageType = List;
    SourceTable = "Item Reference";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reference Type No."; Rec."Reference Type No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Description 2"; Rec."Description 2")
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
    }
}

