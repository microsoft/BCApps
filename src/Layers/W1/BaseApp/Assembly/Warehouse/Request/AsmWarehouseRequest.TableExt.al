// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Assembly.Document;

tableextension 903 "Asm. Warehouse Request" extends "Warehouse Request"
{
    fields
    {
        modify("Source No.")
        {
            TableRelation = if ("Source Type" = filter(901)) "Assembly Header"."No." where("Document Type" = const(Order),
                                                                                           "No." = field("Source No."));
        }
    }
}
