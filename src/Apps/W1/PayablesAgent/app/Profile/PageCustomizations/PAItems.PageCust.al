// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Inventory.Item;

pagecustomization "PA Items" customizes "Item List"
{
    ClearActions = true;
    ClearLayout = true;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        modify("No.")
        {
            Visible = true;
        }
        modify(Description)
        {
            Visible = true;
        }
        modify("Description 2")
        {
            Visible = true;
        }
        modify("Base Unit of Measure")
        {
            Visible = true;
        }
        modify("Item Category Code")
        {
            Visible = true;
        }
        modify(Type)
        {
            Visible = true;
        }
        modify("Inventory Posting Group")
        {
            Visible = true;
        }
        modify("Gen. Prod. Posting Group")
        {
            Visible = true;
        }
    }
}
