// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

page 7189 "Get Purchase Line Disc."
{
    Caption = 'Get Purchase Line Disc.';
    Editable = false;
    PageType = List;
    SourceTable = "Purchase Line Discount";

    layout
    {
        area(content)
        {
            repeater(Control1102628000)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the purchase line discount price.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
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
                    ToolTip = 'Specifies the discount percentage to use to calculate the purchase line discount.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Suite;
                }
            }
        }
    }

    actions
    {
    }
}
