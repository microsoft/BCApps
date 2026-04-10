// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

enumextension 7014 "Serv. Price Asset Type" extends "Price Asset Type"
{
    value(50; "Service Cost")
    {
        Caption = 'Service Cost';
        Implementation = "Price Asset" = "Price Asset - Service Cost";
    }
}