// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

page 65 "Rounding Methods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Rounding Methods';
    PageType = List;
    SourceTable = "Rounding Method";
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
                    ApplicationArea = Basic, Suite;
                }
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount Added Before"; Rec."Amount Added Before")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Precision; Rec.Precision)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount Added After"; Rec."Amount Added After")
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
    }
}

