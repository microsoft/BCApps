// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Temporary table for calculating and displaying G/L account net changes during journal posting preview and validation.
/// Shows impact of pending journal entries on G/L account balances before actual posting occurs.
/// </summary>
/// <remarks>
/// Temporary calculation table for journal posting impact analysis and preview functionality.
/// Displays net change calculations and projected balances for G/L accounts affected by journal entries.
/// Key features: Net change calculation, balance projection, posting preview support, validation assistance.
/// Usage: Journal posting preview, balance verification, impact analysis before posting execution.
/// </remarks>
table 269 "G/L Account Net Change"
{
    Tabletype = temporary;
    Caption = 'G/L Account Net Change';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// G/L account number identifying the account affected by journal entries.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the bank account that is being reconciled.';
        }
        /// <summary>
        /// G/L account name for identification and display purposes.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the record.';
        }
        /// <summary>
        /// Net change amount that will be applied to the G/L account from pending journal entries.
        /// </summary>
        field(3; "Net Change in Jnl."; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Net Change in Jnl.';
            ToolTip = 'Specifies the net change that will occur on the bank when you post the journal.';
        }
        /// <summary>
        /// Projected G/L account balance after posting the pending journal entries.
        /// </summary>
        field(4; "Balance after Posting"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance after Posting';
            ToolTip = 'Specifies the current balance on the bank account.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
