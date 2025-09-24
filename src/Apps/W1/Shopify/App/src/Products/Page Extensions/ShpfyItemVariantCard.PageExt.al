// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;

/// <summary>
/// PageExtension Shpfy Item Variant Card (ID 30126) extends Page Item Variant
/// </summary>
pageextension 30126 "Shpfy Item Variant Card" extends "Item Variant Card"
{
    layout
    {
        addlast(factboxes)
        {
            part(ItemVariantPicture; "Shpfy Item Variant Picture")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = "Item No." = field("Item No."),
                              Code = field(Code);
            }
        }
    }
}