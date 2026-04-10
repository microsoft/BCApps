// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Manufacturing.Document;

tableextension 99000779 "Mfg. Whse. Worksheet Line" extends "Whse. Worksheet Line"
{
    fields
    {
        modify("Whse. Document No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Production)) "Production Order"."No." where("No." = field("Whse. Document No."));
        }
        modify("Whse. Document Line No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Production)) "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                                                                "Prod. Order No." = field("Whse. Document No."),
                                                                                                                "Line No." = field("Line No."));
        }
    }
}
