// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Comment;

page 5777 "Warehouse Comment List"
{
    Caption = 'Comment List';
    DataCaptionExpression = Rec.FormCaption();
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Warehouse Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Warehouse;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Warehouse;
                }
            }
        }
    }

    actions
    {
    }
}

