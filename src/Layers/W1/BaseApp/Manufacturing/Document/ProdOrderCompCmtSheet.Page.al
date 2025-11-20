// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

page 99000842 "Prod. Order Comp. Cmt. Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    DataCaptionExpression = Rec.Caption();
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Prod. Order Comp. Cmt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual comment text.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a code for the comments.';
                    Visible = false;
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

