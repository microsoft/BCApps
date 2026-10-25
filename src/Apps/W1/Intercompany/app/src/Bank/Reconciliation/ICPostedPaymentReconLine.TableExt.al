// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Table extension for Posted Payment Recon. Line to support IC Partner account type in posted reconciliation lines.
/// Extends the Account No. field's TableRelation to allow IC Partner selection in posted payment reconciliation history.
/// </summary>
tableextension 8417 "IC Posted Payment Recon Line" extends "Posted Payment Recon. Line"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
    }
}
