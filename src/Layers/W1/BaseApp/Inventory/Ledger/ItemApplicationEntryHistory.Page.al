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
                    ToolTip = 'Specifies a unique identifying number for each item application entry history record.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Item Ledger Entry No."; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the entry number of the item ledger entry, for which the item application entry was recorded.';
                }
                field("Inbound Item Entry No."; Rec."Inbound Item Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory increase or positive quantity in inventory for this entry.';
                }
                field("Outbound Item Entry No."; Rec."Outbound Item Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory decrease for this entry.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item quantity being applied from the inventory decrease in the Outbound Item Entry No. field, to the inventory increase in the Inbound Item Entry No. field.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date that corresponds to the posting date of the item ledger entry, for which this item application entry was created.';
                }
                field("Transferred-from Entry No."; Rec."Transferred-from Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item ledger entry number of the inventory increase, if an item application entry originates from an item location transfer.';
                }
                field("Cost Application"; Rec."Cost Application")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which application entries should have the cost forwarded, or simply included, in an average cost calculation.';
                }
                field("Output Completely Invd. Date"; Rec."Output Completely Invd. Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the outbound item entries have been completely invoiced.';
                }
            }
        }
    }

    actions
    {
    }
}

