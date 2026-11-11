// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

/// <summary>
/// Extends Item Templ. Card with Intercompany-specific controls.
/// Configures the Common Item No. field retained on the base page for compatibility.
/// </summary>
pageextension 8516 ICItemTemplCard extends "Item Templ. Card"
{
    layout
    {
        modify("Common Item No.")
        {
            Visible = false;
        }
    }
}
