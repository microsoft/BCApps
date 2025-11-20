// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Comment;

page 620 "IC Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'IC Comment Sheet';
    DataCaptionFields = "Table Name", "Transaction No.", "IC Partner Code";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "IC Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field("Created By IC Partner Code"; Rec."Created By IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Created By';
                    ToolTip = 'The IC Partner Code of the company that created the comment.';
                    Editable = false;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the comment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;
}

