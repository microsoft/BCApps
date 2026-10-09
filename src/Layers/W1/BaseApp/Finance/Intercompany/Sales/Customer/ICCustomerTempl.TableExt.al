// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Extends Customer Template with Intercompany-specific fields.
/// </summary>
tableextension 8470 ICCustomerTempl extends "Customer Templ."
{
    fields
    {
        modify("IC Partner Code")
        {
            TableRelation = "IC Partner";
        }
    }
}
