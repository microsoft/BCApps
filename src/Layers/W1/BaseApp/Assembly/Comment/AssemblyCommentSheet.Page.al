// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Comment;

page 907 "Assembly Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Assembly Comment Sheet';
    DataCaptionFields = "Document No.";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Assembly Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Assembly;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Assembly;
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

