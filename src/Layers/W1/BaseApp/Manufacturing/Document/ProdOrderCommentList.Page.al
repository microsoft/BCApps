// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

page 99000839 "Prod. Order Comment List"
{
    Caption = 'Comment List';
    DataCaptionFields = Status, "Prod. Order No.";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Prod. Order Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the comment.';
                }
            }
        }
    }

    actions
    {
    }
}

