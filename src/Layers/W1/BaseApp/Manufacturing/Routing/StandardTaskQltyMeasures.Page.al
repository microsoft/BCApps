// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

page 99000805 "Standard Task Qlty Measures"
{
    AutoSplitKey = true;
    Caption = 'Standard Task Qlty Measures';
    DataCaptionFields = "Standard Task Code";
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Standard Task Quality Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Qlty Measure Code"; Rec."Qlty Measure Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the quality measure.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the quality measure description.';
                }
                field("Min. Value"; Rec."Min. Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the minimum value that must be met.';
                }
                field("Max. Value"; Rec."Max. Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the maximum value that may be achieved.';
                }
                field("Mean Tolerance"; Rec."Mean Tolerance")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the mean tolerance.';
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

