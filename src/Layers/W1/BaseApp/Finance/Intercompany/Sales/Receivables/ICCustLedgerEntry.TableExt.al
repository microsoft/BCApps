// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Extends Customer Ledger Entry with Intercompany-specific fields.
/// </summary>
tableextension 8475 ICCustLedgerEntry extends "Cust. Ledger Entry"
{
    fields
    {
        modify("IC Partner Code")
        {
            TableRelation = "IC Partner";
        }
    }
}
