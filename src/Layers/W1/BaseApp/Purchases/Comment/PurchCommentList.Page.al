// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Comment;

page 68 "Purch. Comment List"
{
    Caption = 'Comment List';
    DataCaptionFields = "Document Type", "No.";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Purch. Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Comments;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Comments;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                }
            }
        }
    }

    actions
    {
    }
}

