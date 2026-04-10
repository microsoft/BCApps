// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

page 5720 "Item Substitutions"
{
    AutoSplitKey = false;
    Caption = 'Item Substitutions';
    DataCaptionFields = Interchangeable;
    Editable = false;
    PageType = List;
    SourceTable = "Item Substitution";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Substitute No."; Rec."Substitute No.")
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field(Interchangeable; Rec.Interchangeable)
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
                              "Substitute Type" = field("Substitute Type"),
                              "Substitute No." = field("Substitute No.");
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

