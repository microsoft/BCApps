// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity.History;

using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Document;

tableextension 99000762 "Mfg. Reg. Whse. Activity Line" extends "Registered Whse. Activity Line"
{
    fields
    {
        modify("Destination No.")
        {
            TableRelation = if ("Destination Type" = const(Family)) Family;
        }
        modify("Whse. Document No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Production)) "Production Order"."No." where("No." = field("Whse. Document No."));
        }
        modify("Whse. Document Line No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Production)) "Prod. Order Line"."Line No." where("Prod. Order No." = field("No."),
                                                                                                                "Line No." = field("Line No."));
        }
    }
}