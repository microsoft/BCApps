// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Assembly.Document;

tableextension 904 "Asm. Whse. Pick Request" extends "Whse. Pick Request"
{
    fields
    {
        modify("Document No.")
        {
#pragma warning disable AL0603
            TableRelation = if ("Document Type" = const(Assembly)) "Assembly Header"."No." where("Document Type" = field("Document Subtype"));
#pragma warning restore AL0603
        }

    }
}
