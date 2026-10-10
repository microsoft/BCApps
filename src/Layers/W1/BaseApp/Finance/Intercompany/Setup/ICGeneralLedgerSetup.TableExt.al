// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Extends General Ledger Setup with Intercompany-specific fields.
/// Tracks the last transaction number used for intercompany transactions to ensure unique numbering.
/// </summary>
tableextension 8501 "IC General Ledger Setup" extends "General Ledger Setup"
{
    fields
    {
        /// <summary>
        /// Tracks the last transaction number used for intercompany transactions to ensure unique numbering.
        /// </summary>
        field(102; "Last IC Transaction No."; Integer)
        {
            Caption = 'Last IC Transaction No.';
            DataClassification = SystemMetadata;
        }
    }
}
