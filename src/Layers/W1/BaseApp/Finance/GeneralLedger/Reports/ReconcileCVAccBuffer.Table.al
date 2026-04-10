// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Temporary buffer table for customer and vendor account reconciliation data aggregation.
/// Stores mapping between posting groups, currencies, and G/L accounts for reconciliation report generation.
/// </summary>
/// <remarks>
/// Used exclusively by the Reconcile Customer and Vendor Accounts report for data processing.
/// Provides structured storage for posting group analysis across different currencies and account configurations.
/// Table data is not replicated and serves as a temporary buffer for report calculations.
/// </remarks>
table 384 "Reconcile CV Acc Buffer"
{
    Caption = 'Reconcile CV Acc Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifies the source table type for reconciliation analysis (Customer or Vendor table).
        /// Links buffer records to their originating table for proper data categorization.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Currency code for multi-currency reconciliation analysis and G/L account mapping.
        /// Enables currency-specific reconciliation calculations and posting group analysis.
        /// </summary>
        field(2; "Currency code"; Code[10])
        {
            Caption = 'Currency code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        /// <summary>
        /// Customer or vendor posting group code for account reconciliation and G/L mapping.
        /// Groups similar accounts for consolidated reconciliation analysis and reporting.
        /// </summary>
        field(3; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Field number identifier for specific posting group account field mapping.
        /// Specifies which posting group field (receivables, payables, discounts, etc.) is being reconciled.
        /// </summary>
        field(6; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L Account number associated with the posting group and field combination.
        /// Target account for reconciliation analysis and balance verification procedures.
        /// </summary>
        field(7; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Table ID", "Currency code", "Posting Group", "Field No.")
        {
            Clustered = true;
        }
        key(Key2; "G/L Account No.")
        {
        }
    }

    fieldgroups
    {
    }
}

