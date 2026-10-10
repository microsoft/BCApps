// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Extends Sales &amp; Receivables Setup with Intercompany-specific fields.
/// Stores the general journal templates used when posting intercompany sales invoices and credit memos.
/// </summary>
tableextension 8509 ICSalesReceivablesSetup extends "Sales & Receivables Setup"
{
    fields
    {
        /// <summary>
        /// Specifies the intercompany journal template used for posting intercompany sales invoices.
        /// </summary>
        field(205; "IC Sales Invoice Template Name"; Code[10])
        {
            Caption = 'IC Sales Invoice Template Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
            ToolTip = 'Specifies the intercompany journal template to use for sales invoices.';
        }
        /// <summary>
        /// Specifies the intercompany journal template used for posting intercompany sales credit memos.
        /// </summary>
        field(206; "IC Sales Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'IC Sales Cr. Memo Template Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
            ToolTip = 'Specifies the intercompany journal template to use for sales credit memos.';
        }
    }
}
