// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Service.Document;
using Microsoft.Service.History;

tableextension 10019 "Serv. Sales Tax Amount Diff." extends "Sales Tax Amount Difference"
{
    fields
    {
        modify("Document No.")
        {
            TableRelation =
#pragma warning disable AL0603
            if ("Document Product Area" = const(Service)) "Service Header"."No." where("Document Type" = field("Document Type"))
#pragma warning restore AL0603
            else
            if ("Document Type" = const(Invoice), "Document Product Area" = const("Posted Service")) "Service Invoice Header"
            else
            if ("Document Type" = const("Credit Memo"), "Document Product Area" = const("Posted Service")) "Service Cr.Memo Header";
        }
    }
}