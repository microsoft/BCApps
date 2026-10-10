// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Extends Vendor Ledger Entry with Intercompany-specific fields.
/// </summary>
tableextension 8448 ICVendorLedgerEntry extends "Vendor Ledger Entry"
{
    fields
    {
        modify("IC Partner Code")
        {
            TableRelation = "IC Partner";
        }
    }
}
