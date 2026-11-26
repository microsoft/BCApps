// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Intercompany.Partner;

/// <summary>
/// Table extension for Applied Payment Entry to support IC Partner account type in payment applications.
/// Extends the Account No. field's TableRelation to allow IC Partner selection during payment reconciliation.
/// </summary>
tableextension 8415 "IC Applied Payment Entry" extends "Applied Payment Entry"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
    }
}
