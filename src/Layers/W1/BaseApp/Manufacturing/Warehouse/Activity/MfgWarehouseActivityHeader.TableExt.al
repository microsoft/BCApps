// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Manufacturing.Family;

tableextension 99000770 "Mfg. Warehouse Activity Header" extends "Warehouse Activity Header"
{
    fields
    {
        modify("Destination No.")
        {
            TableRelation = if ("Destination Type" = const(Family)) Family;
        }
    }
}