// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InventoryDocument;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;

tableextension 99000775 "Mfg. Posted InvtPutaway Header" extends "Posted Invt. Put-away Header"
{
    fields
    {
        modify("Source No.")
        {
            TableRelation = if ("Source Type" = const(5405)) "Production Order"."No." where(Status = filter(Released | Finished),
                                                                                            "No." = field("Source No."));
        }
        modify("Destination No.")
        {
            TableRelation = if ("Destination Type" = const(Family)) Family;
        }
    }
}