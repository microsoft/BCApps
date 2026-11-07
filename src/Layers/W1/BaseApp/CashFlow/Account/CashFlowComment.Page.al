// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Comment;

page 848 "Cash Flow Comment"
{
    AutoSplitKey = true;
    Caption = 'Cash Flow Comment';
    PageType = List;
    SourceTable = "Cash Flow Account Comment";

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the cash flow comment.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment for the record.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the record.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
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

