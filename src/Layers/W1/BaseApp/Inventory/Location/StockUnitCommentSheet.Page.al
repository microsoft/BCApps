// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

page 5704 "Stock. Unit Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Stock. Unit Comment Sheet';
    DataCaptionFields = "Location Code", "Item No.", "Variant Code";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Stockkeeping Unit Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Comments;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Comments;
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

