// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

/// <summary>
/// Temporary buffer table for staging intercompany comment line data during API-based data exchange.
/// Facilitates comment validation and transformation before posting to target partner systems.
/// </summary>
table 603 "Buffer IC Comment Line"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

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
        /// <summary>
        /// Unique identifier linking this comment to a specific data exchange operation.
        /// </summary>
        field(8100; "Operation ID"; Guid)
        {
            Editable = false;
            Caption = 'Operation ID';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }
}
