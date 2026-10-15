// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Inventory.Item.Catalog;

pagecustomization "PA Item Reference Entries" customizes "Item Reference Entries"
{
    ClearActions = true;
    ClearLayout = true;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        modify("Reference No.")
        {
            Visible = true;
        }
        modify("Reference Type No.")
        {
            Visible = true;
        }
        modify(Description)
        {
            Visible = true;
        }
    }
}
