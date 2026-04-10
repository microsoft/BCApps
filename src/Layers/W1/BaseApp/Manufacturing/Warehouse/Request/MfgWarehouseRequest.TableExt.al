// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;

tableextension 99000780 "Mfg. Warehouse Request" extends "Warehouse Request"
{
    fields
    {
        modify("Source No.")
        {
            TableRelation = if ("Source Type" = filter(5406 | 5407)) "Production Order"."No." where(Status = const(Released),
                                                                                                    "No." = field("Source No."));
        }
        modify("Destination No.")
        {
            TableRelation = if ("Destination Type" = const(Family)) Family;
        }
    }
}
