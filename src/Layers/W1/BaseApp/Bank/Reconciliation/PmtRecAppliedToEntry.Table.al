// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Tracks payment reconciliation applied-to entry relationships.
/// Maintains linkage between payment lines and specific ledger entry applications.
/// </summary>
table 185 "Pmt. Rec. Applied-to Entry"
{
    Caption = 'Payment Reconciliation Applied-to Entry';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Entry number of the ledger entry being applied to.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Type of ledger entry being applied to.
        /// </summary>
        field(2; "Entry Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Entry Type';
        }
        /// <summary>
        /// Bank account identifier for the reconciliation.
        /// </summary>
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
        }
        /// <summary>
        /// Statement number for the reconciliation.
        /// </summary>
        field(4; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
        }
        /// <summary>
        /// Line number within the reconciliation statement.
        /// </summary>
        field(5; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        /// <summary>
        /// Entry number that performed the application.
        /// </summary>
        field(6; "Applied by Entry No."; Integer)
        {
            Caption = 'Applied by Entry No.';
        }
        field(7; "Amount"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
        }
    }
    keys
    {
        key(Key1; "Entry No.", "Entry Type", "Bank Account No.", "Statement No.", "Statement Line No.", "Applied by Entry No.")
        {
            Clustered = true;
        }
    }
}
