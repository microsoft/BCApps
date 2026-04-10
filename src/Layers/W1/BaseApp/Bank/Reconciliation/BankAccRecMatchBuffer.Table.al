// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Buffer table for managing many-to-one matching relationships in bank account reconciliation processes.
/// This table temporarily stores matching combinations where multiple bank statement lines correspond
/// to a single bank account ledger entry, enabling complex reconciliation scenarios such as split
/// transactions, fees, and multi-line bank statement entries that relate to one ledger posting.
/// Used during automatic matching to track and process these complex matching relationships.
/// </summary>
/// <remarks>
/// Key features include match ID grouping for related entries, processing status tracking,
/// and integration with bank reconciliation matching algorithms. The table supports scenarios
/// where bank statements contain multiple lines for charges, fees, or split amounts that should
/// be matched against a single ledger entry. Enables sophisticated matching logic while maintaining
/// clear audit trails and processing control.
/// </remarks>
table 2711 "Bank Acc. Rec. Match Buffer"
{
    Caption = 'Bank Account Reconciliation Many-to-One Matchings';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Bank account ledger entry number being matched in many-to-one relationships.
        /// References the target ledger entry that multiple statement lines should match against.
        /// </summary>
        field(1; "Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            Editable = false;
        }
        /// <summary>
        /// Statement number identifying the bank reconciliation session.
        /// Groups related matching entries under a single reconciliation process.
        /// </summary>
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            Editable = false;
        }
        /// <summary>
        /// Statement line number participating in the many-to-one match.
        /// Identifies specific bank statement lines that contribute to the complex match.
        /// </summary>
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            Editable = false;
        }
        /// <summary>
        /// Bank account number for the reconciliation process.
        /// Ensures matching relationships are contained within the correct bank account context.
        /// </summary>
        field(4; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            Editable = false;
        }
        /// <summary>
        /// Unique identifier grouping related statement lines in many-to-one matches.
        /// Multiple buffer entries with the same Match ID represent lines that collectively match one ledger entry.
        /// </summary>
        field(5; "Match ID"; Integer)
        {
            Caption = 'Match ID';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this matching relationship has been processed and applied.
        /// Used to track completion status and prevent duplicate processing of match groups.
        /// </summary>
        field(6; "Is Processed"; Boolean)
        {
            Caption = 'Is Processed';
            Editable = false;
        }
    }

    keys
    {
        key(key1; "Statement No.", "Statement Line No.", "Bank Account No.", "Match ID")
        {
            Clustered = true;
        }
        key(Key2; "Ledger Entry No.")
        {

        }
        key(Key3; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
        }
    }

    trigger OnDelete()
    begin

    end;
}
