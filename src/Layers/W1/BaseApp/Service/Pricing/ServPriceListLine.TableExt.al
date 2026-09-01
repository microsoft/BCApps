#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Worksheet;

using Microsoft.Service.Pricing;

// Replaced by table extension ServPriceListLineExt which extends PriceListLine table
// This is duplicate for table extension ServPriceWorksheetLine do excactly the same
tableextension 6474 "Serv. Price List Line" extends "Price Worksheet Line"
{
    fields
    {
        modify("Product No.")
        {
            TableRelation = if ("Asset Type" = const("Service Cost")) "Service Cost";
        }
    }
}
#endif
