// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

page 5719 "Sub. Conditions"
{
    AutoSplitKey = true;
    Caption = 'Sub. Conditions';
    Editable = false;
    PageType = List;
    SourceTable = "Substitution Condition";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Condition; Rec.Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the condition for item substitution.';
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

