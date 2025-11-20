// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

page 99000837 "Routing Quality Measures"
{
    AutoSplitKey = true;
    Caption = 'Routing Quality Measures';
    DataCaptionExpression = Rec.Caption();
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Routing Quality Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Qlty Measure Code"; Rec."Qlty Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quality measure code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the quality measure.';
                }
                field("Min. Value"; Rec."Min. Value")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the minimum value that must be met.';
                }
                field("Max. Value"; Rec."Max. Value")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the maximum value that may be achieved.';
                }
                field("Mean Tolerance"; Rec."Mean Tolerance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the acceptable mean tolerance.';
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

