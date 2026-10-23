// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Extends Purchases &amp; Payables Setup with Intercompany-specific fields.
/// Stores the general journal templates used when posting intercompany purchase invoices and credit memos.
/// </summary>
tableextension 8508 ICPurchasesPayablesSetup extends "Purchases & Payables Setup"
{
    fields
    {
        /// <summary>
        /// Specifies the intercompany journal template to use for purchase invoices.
        /// </summary>
        field(204; "IC Purch. Invoice Templ. Name"; Code[10])
        {
            Caption = 'IC Jnl. Templ. Purch. Invoice';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the intercompany journal template to use for purchase invoices.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
        /// <summary>
        /// Specifies the intercompany journal template to use for posting purchase credit memos.
        /// </summary>
        field(205; "IC Purch. Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'IC Jnl. Templ. Purch. Cr. Memo';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the intercompany journal template to use for posting purchase credit memos.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
    }
}
