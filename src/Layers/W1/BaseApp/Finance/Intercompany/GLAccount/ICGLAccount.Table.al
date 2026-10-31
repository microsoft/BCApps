// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Stores shared intercompany general ledger account structure for cross-company transaction mapping.
/// Provides standardized chart of accounts that can be mapped to local G/L accounts for intercompany operations.
/// </summary>
table 410 "IC G/L Account"
{
    Caption = 'IC G/L Account';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Unique identifier for the intercompany G/L account used across all partner companies.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name of the intercompany G/L account for identification and reporting purposes.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Account type classification determining posting behavior and account structure.
        /// </summary>
        field(3; "Account Type"; Enum "G/L Account Type")
        {
            Caption = 'Account Type';
        }
        /// <summary>
        /// Report classification indicating whether account is income statement or balance sheet type.
        /// </summary>
        field(4; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
        }
        /// <summary>
        /// Indicates whether the intercompany account is blocked from use in transactions.
        /// </summary>
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Local G/L account number that maps to this intercompany account for transaction translation.
        /// </summary>
        field(6; "Map-to G/L Acc. No."; Code[20])
        {
            Caption = 'Map-to G/L Acc. No.';
            TableRelation = "G/L Account"."No.";
        }
        /// <summary>
        /// Visual indentation level for hierarchical display in chart of accounts reports.
        /// </summary>
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
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
        fieldgroup(DropDown; "No.", Name, "Income/Balance", Blocked, "Map-to G/L Acc. No.")
        {
        }
    }
}
#endif
