// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InventoryDocument;

using Microsoft.Manufacturing.Family;

tableextension 99000778 "Mfg. Reg. Invt. Movement Line" extends "Registered Invt. Movement Line"
{
    fields
    {
        modify("Destination No.")
        {
            TableRelation = if ("Destination Type" = const(Family)) Family;
        }
    }
}