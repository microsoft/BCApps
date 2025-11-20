// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 433 "Reminder Text"
{
    AutoSplitKey = true;
    Caption = 'Reminder Text';
    DataCaptionExpression = PageCaptionVariable;
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Reminder Text";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder terms code this text applies to.';
                    Visible = false;
                }
                field("Reminder Level"; Rec."Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder level this text applies to.';
                    Visible = false;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will appear at the beginning or the end of the reminder.';
                    Visible = false;
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that you want to insert in the reminder.';
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

    trigger OnOpenPage()
    begin
        PageCaptionVariable := Rec."Reminder Terms Code" + ' ' + Format(Rec."Reminder Level") + ' ' + Format(Rec.Position);
    end;

    var
        PageCaptionVariable: Text[250];
}

