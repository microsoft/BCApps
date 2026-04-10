// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

page 5702 "Stockkeeping Unit Comment List"
{
    AutoSplitKey = true;
    Caption = 'Stockkeeping Unit Comment List';
    DataCaptionFields = "Location Code", "Item No.", "Variant Code";
    Editable = false;
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Planning;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Planning;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Planning;
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

