// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Stores related entries for payment reconciliation tracking.
/// Links reconciliation lines to corresponding ledger entries and applications.
/// </summary>
table 184 "Payment Rec. Related Entry"
{
    Caption = 'Payment Reconciliation Related Entry';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the related entry record.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the Entry No. that was created by the Posted Payment Reconciliation Journal.';
        }
        /// <summary>
        /// Type of ledger entry being referenced.
        /// </summary>
        field(2; "Entry Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the type of the entry that was created by the posted payment reconciliation journal.';
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
        /// Indicates if the related entry has been unapplied.
        /// </summary>
        field(6; Unapplied; Boolean)
        {
            Caption = 'Unapplied';
        }
        field(7; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(8; ToUnapply; Boolean)
        {
            Caption = 'To Unapply';
            ToolTip = 'Specifies if the entry created by the posted payment reconciliation journal will be unapplied.';
        }
        field(9; ToReverse; Boolean)
        {
            Caption = 'To Reverse';
            ToolTip = 'Specifies if the entry created by the posted payment reconciliation journal will be reversed.';
        }
    }
    keys
    {
        key(Key1; "Entry No.", "Entry Type", "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
        }
    }
}
