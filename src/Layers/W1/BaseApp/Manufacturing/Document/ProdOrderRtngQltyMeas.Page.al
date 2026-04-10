// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

page 99000834 "Prod. Order Rtng Qlty Meas."
{
    AutoSplitKey = true;
    Caption = 'Prod. Order Rtng Qlty Meas.';
    DataCaptionExpression = Rec.Caption();
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Prod. Order Rtng Qlty Meas.";

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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Min. Value"; Rec."Min. Value")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Max. Value"; Rec."Max. Value")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Mean Tolerance"; Rec."Mean Tolerance")
                {
                    ApplicationArea = Manufacturing;
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

