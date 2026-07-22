// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.BE;

using Microsoft.Integration.Shopify;

enumextension 30461 "Shpfy Comp. Tax Id Mapping BE" extends "Shpfy Comp. Tax Id Mapping"
{
    value(30461; "Enterprise No.")
    {
        Caption = 'Enterprise No.';
        Implementation = "Shpfy Tax Registration Id Mapping" = "Shpfy Enterprise No. BE";
    }
}
