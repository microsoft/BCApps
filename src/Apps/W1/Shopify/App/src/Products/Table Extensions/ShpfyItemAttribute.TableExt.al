// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item.Attribute;

tableextension 30112 "Shpfy Item Attribute" extends "Item Attribute"
{
    fields
    {
        field(30100; "Shpfy Incl. in Product Sync"; Enum "Shpfy Incl. in Product Sync")
        {
            Caption = 'Include in Product Sync';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether to include this item attribute in product synchronization to Shopify. Select "As Option" to export the attribute as a Shopify Product Option.';
        }
    }
}
