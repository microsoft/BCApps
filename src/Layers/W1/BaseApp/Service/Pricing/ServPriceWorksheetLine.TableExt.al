// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Worksheet;

using Microsoft.Service.Pricing;

tableextension 6475 "Serv. Price Worksheet Line" extends "Price Worksheet Line"
{
    fields
    {
        modify("Product No.")
        {
            TableRelation = if ("Asset Type" = const("Service Cost")) "Service Cost";
        }
    }
}
