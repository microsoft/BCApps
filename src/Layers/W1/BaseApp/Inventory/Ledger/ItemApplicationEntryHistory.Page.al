// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

page 523 "Item Application Entry History"
{
    Caption = 'Item Application Entry History';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Item Application Entry History";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Primary Entry No."; Rec."Primary Entry No.")
                {
                    ApplicationArea = Suite;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                }
                field("Item Ledger Entry No."; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = Suite;
                }
                field("Inbound Item Entry No."; Rec."Inbound Item Entry No.")
                {
                    ApplicationArea = Suite;
                }
                field("Outbound Item Entry No."; Rec."Outbound Item Entry No.")
                {
                    ApplicationArea = Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Transferred-from Entry No."; Rec."Transferred-from Entry No.")
                {
                    ApplicationArea = Suite;
                }
                field("Cost Application"; Rec."Cost Application")
                {
                    ApplicationArea = Suite;
                }
                field("Output Completely Invd. Date"; Rec."Output Completely Invd. Date")
                {
                    ApplicationArea = Manufacturing;
                }
            }
        }
    }

    actions
    {
    }
}

