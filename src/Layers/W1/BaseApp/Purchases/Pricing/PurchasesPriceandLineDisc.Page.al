// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

using Microsoft.Inventory.Item;

page 1346 "Purchases Price and Line Disc."
{
    Caption = 'Purchase Prices';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Purch. Price Line Disc. Buff.";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Suite;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Suite;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Suite;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Suite;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Suite;
                }
            }
        }
    }

    actions
    {
    }

    procedure LoadItem(Item: Record Item)
    begin
        Clear(Rec);

        Rec.LoadDataForItem(Item);
    end;
}
