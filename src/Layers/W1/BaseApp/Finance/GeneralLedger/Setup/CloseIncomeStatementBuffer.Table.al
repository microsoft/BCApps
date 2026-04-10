// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Temporary buffer used during closing of the income statement.
/// Stores G/L accounts per accounting period closing date for residual adjustment processing.
/// </summary>
table 347 "Close Income Statement Buffer"
{
    Caption = 'Close Income Statement Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Posting date marked as an accounting period closing date.
        /// Used to group residual adjustments by fiscal year end.
        /// </summary>
        field(1; "Closing Date"; Date)
        {
            Caption = 'Closing Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L account associated with the closing date entry.
        /// Links to the G/L Account used for residual postings in ARC adjustments.
        /// </summary>
        field(2; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Closing Date", "G/L Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

