// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Extends Bank Acc. Reconciliation Line with Intercompany-specific functionality.
/// Adds IC Partner as a valid account type in the Account No. field table relation
/// for payment reconciliation lines.
/// </summary>
tableextension 8493 "IC Bank Acc. Recon. Line" extends "Bank Acc. Reconciliation Line"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
    }
}
