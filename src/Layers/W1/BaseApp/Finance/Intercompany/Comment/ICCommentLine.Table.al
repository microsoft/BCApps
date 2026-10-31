// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Comment;

/// <summary>
/// Stores comment lines for intercompany transactions enabling detailed communication between partner companies.
/// Supports annotations on inbox, outbox, and handled transactions for audit trail and collaboration purposes.
/// </summary>
table 424 "IC Comment Line"
{
    Caption = 'IC Comment Line';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Identifies the type of intercompany transaction table this comment belongs to.
        /// </summary>
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'IC Inbox Transaction,IC Outbox Transaction,Handled IC Inbox Transaction,Handled IC Outbox Transaction';
            OptionMembers = "IC Inbox Transaction","IC Outbox Transaction","Handled IC Inbox Transaction","Handled IC Outbox Transaction";
        }
        /// <summary>
        /// Transaction number linking this comment to a specific intercompany transaction.
        /// </summary>
        field(2; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Code identifying the intercompany partner associated with this transaction comment.
        /// </summary>
        field(3; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
        }
        /// <summary>
        /// Sequential line number for organizing multiple comments within a transaction.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Date when the comment was created or last modified.
        /// </summary>
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        /// <summary>
        /// Text content of the comment providing additional information or notes about the transaction.
        /// </summary>
        field(6; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        /// <summary>
        /// Indicates whether the comment relates to a rejected or newly created transaction.
        /// </summary>
        field(7; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected,Created';
            OptionMembers = Rejected,Created;
        }
        /// <summary>
        /// Code of the intercompany partner who created this comment for tracking authorship.
        /// </summary>
        field(8; "Created By IC Partner Code"; Code[20])
        {
            Caption = 'Created By IC Partner Code';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif
