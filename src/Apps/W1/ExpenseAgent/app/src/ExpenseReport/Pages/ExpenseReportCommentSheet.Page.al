// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6977 "Expense Report Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    ApplicationArea = Comments;
    DataCaptionFields = "No.";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Expense Report Comment Line";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ToolTip = 'Specifies the date of the comment.';
                }
                field(Comment; Rec.Comment)
                {
                    ToolTip = 'Specifies the comment text.';
                }

            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;
}
