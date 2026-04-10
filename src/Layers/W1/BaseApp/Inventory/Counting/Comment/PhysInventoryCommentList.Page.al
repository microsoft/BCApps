// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Comment;

page 5892 "Phys. Inventory Comment List"
{
    Caption = 'Phys. Inventory Comment List';
    DataCaptionFields = "Document Type", "Order No.", "Recording No.";
    Editable = false;
    PageType = List;
    SourceTable = "Phys. Invt. Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Recording No."; Rec."Recording No.")
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

