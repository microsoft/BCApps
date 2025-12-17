// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item.Attribute;

pageextension 30127 "Shpfy Item Attributes" extends "Item Attributes"
{
    layout
    {
        addlast(Control1)
        {
            field("Shpfy Incl. in Product Sync"; Rec."Shpfy Incl. in Product Sync")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether to include this item attribute in product synchronization to Shopify. Select "As Option" to export the attribute as a Shopify Product Option.';
            }
        }
    }
}
