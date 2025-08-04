// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;

/// <summary>
/// TableExtension Shpfy Item Variant (ID 30112) extends Record Item Variant.
/// </summary>
tableextension 30112 "Shpfy Item Variant" extends "Item Variant"
{
    fields
    {
        field(30100; Picture; MediaSet)
        {
            Caption = 'Picture';
            ToolTip = 'Specifies the picture that has been inserted for the item variant.';
            DataClassification = CustomerContent;
        }
    }
    fieldgroups
    {
        addlast(Brick; Code, Description, Picture) { }
    }
}
