// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

page 394 "Entry/Exit Points"
{
    ApplicationArea = BasicEU, BasicNO;
    Caption = 'Entry/Exit Points';
    PageType = List;
    SourceTable = "Entry/Exit Point";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the code for the shipping location (Entry/Exit Point).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies a description of the shipping location (Entry/Exit Point).';
                }
                field("Group Code"; Rec."Group Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the group code that corresponds with the code used for shipping locations in the Entry/Exit Point table.';
                }
                field("Reduce Statistical Value"; Rec."Reduce Statistical Value")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if the statistical value of the items shipped through the entry or exit point has been reduced.';
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