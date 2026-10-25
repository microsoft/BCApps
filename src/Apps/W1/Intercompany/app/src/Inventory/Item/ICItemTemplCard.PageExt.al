// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

/// <summary>
/// Extends Item Templ. Card with Intercompany-specific controls.
/// Adds the Common Item No. field used to map items across intercompany partners.
/// </summary>
pageextension 8516 ICItemTemplCard extends "Item Templ. Card"
{
    layout
    {
        addafter("Automatic Ext. Texts")
        {
            field("Common Item No."; Rec."Common Item No.")
            {
                ApplicationArea = Intercompany;
                Importance = Additional;
                Visible = false;
            }
        }
    }
}
