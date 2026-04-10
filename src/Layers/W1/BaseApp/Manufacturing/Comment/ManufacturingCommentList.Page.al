// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Comment;

page 99000785 "Manufacturing Comment List"
{
    AutoSplitKey = true;
    Caption = 'Comment List';
    DataCaptionFields = "No.";
    Editable = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Manufacturing Comment Line";

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
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

