// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Manufacturing.Document;

tableextension 99000782 "Mfg. Whse. Pick Request" extends "Whse. Pick Request"
{
    fields
    {
        modify("Document No.")
        {
#pragma warning disable AL0603
            TableRelation = if ("Document Type" = const(Production)) "Production Order"."No." where(Status = field("Document Subtype"));
#pragma warning restore AL0603
        }

    }
}
