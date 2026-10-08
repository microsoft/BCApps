// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Assembly.Document;

tableextension 979 "Asm. Whse. Worksheet Line" extends "Whse. Worksheet Line"
{
    fields
    {
        modify("Whse. Document No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Assembly)) "Assembly Header"."No." where("Document Type" = const(Order),
                                                                                                       "No." = field("Whse. Document No."));
        }
        modify("Whse. Document Line No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Assembly)) "Assembly Line"."Line No." where("Document Type" = const(Order),
                                                                                                           "Document No." = field("Whse. Document No."),
                                                                                                           "Line No." = field("Whse. Document Line No."));
        }
    }
}
