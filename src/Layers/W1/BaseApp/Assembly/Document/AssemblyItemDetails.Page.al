// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Item;

page 910 "Assembly Item - Details"
{
    Caption = 'Assembly Item - Details';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Assembly;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the item.';
            }
            field("Standard Cost"; Rec."Standard Cost")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary.';
            }
            field("Unit Price"; Rec."Unit Price")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
            }
        }
    }

    actions
    {
    }
}

