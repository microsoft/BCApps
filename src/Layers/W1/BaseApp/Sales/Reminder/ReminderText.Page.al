// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Manages the beginning and ending text lines displayed on reminder documents by level.
/// </summary>
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
                    Visible = false;
                }
                field("Reminder Level"; Rec."Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Text; Rec.Text)
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

    trigger OnOpenPage()
    begin
        PageCaptionVariable := Rec."Reminder Terms Code" + ' ' + Format(Rec."Reminder Level") + ' ' + Format(Rec.Position);
    end;

    var
        PageCaptionVariable: Text[250];
}

