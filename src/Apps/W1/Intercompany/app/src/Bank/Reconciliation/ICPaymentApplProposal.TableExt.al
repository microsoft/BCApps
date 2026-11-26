// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Table extension for Payment Application Proposal to support IC Partner account type in payment proposals.
/// Extends the Account No. field's TableRelation to allow IC Partner selection during payment application.
/// </summary>
tableextension 8416 "IC Payment Appl. Proposal" extends "Payment Application Proposal"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
    }
}
