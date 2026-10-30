// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

/// <summary>
/// Extends Item Card with Intercompany-specific controls.
/// Shows the Common Item No. field retained on the base page for compatibility.
/// </summary>
pageextension 8515 ICItemCard extends "Item Card"
{
    layout
    {
        modify("Common Item No.")
        {
            Visible = true;
        }
    }
}
