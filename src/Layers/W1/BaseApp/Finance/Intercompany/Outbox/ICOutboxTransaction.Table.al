// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Journal;

/// <summary>
/// Stores intercompany transactions pending transmission to partner companies.
/// Manages outbound transaction staging, status tracking, and partner communication for intercompany operations.
/// </summary>
/// <remarks>
/// Primary staging table for outbound intercompany transactions. Integrates with partner setup, transaction processing, and status management.
/// Key relationships: IC Partner, IC Outbox Sales Header, IC Outbox Purchase Header, IC Outbox Jnl. Line.
/// Extensible via table extensions for custom transaction types and additional status tracking fields.
/// </remarks>
table 414 "IC Outbox Transaction"
{
    Caption = 'IC Outbox Transaction';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Unique identifier for the intercompany outbox transaction.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the intercompany partner for this outbound transaction.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Source type option indicating the origin of the intercompany transaction.
        /// </summary>
        field(3; "Source Type"; Option)
        {
            Caption = 'Source Type';
            Editable = false;
            OptionCaption = 'Journal Line,Sales Document,Purchase Document';
            OptionMembers = "Journal Line","Sales Document","Purchase Document";
            ObsoleteReason = 'Replaced by IC Source Type for Enum typing';
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
        }
#endif
        /// <summary>
        /// Source type enum indicating the origin of the intercompany transaction.
        /// </summary>
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        /// <summary>
        /// Document type classification for the intercompany transaction.
        /// </summary>
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number of the source transaction being processed for intercompany transmission.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Posting date of the source transaction for intercompany processing.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Source classification indicating whether transaction was created by current company or rejected by partner.
        /// </summary>
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Document date from the source transaction for intercompany transmission.
        /// </summary>
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Action to be performed on the outbox transaction line during processing.
        /// </summary>
        field(10; "Line Action"; Option)
        {
            Caption = 'Line Action';
            OptionCaption = 'No Action,Send to IC Partner,Return to Inbox,Cancel';
            OptionMembers = "No Action","Send to IC Partner","Return to Inbox",Cancel;
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// IC Partner G/L account number for the intercompany transaction.
        /// </summary>
        field(12; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            ObsoleteReason = 'Replaced by IC Account No.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        /// <summary>
        /// Source line number from the originating document for transaction traceability.
        /// </summary>
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// Account type for intercompany journal transactions.
        /// </summary>
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// Account number for intercompany journal transactions based on IC Account Type.
        /// </summary>
        field(15; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source", "Document Type")
        {
            Clustered = true;
        }
        key(Key2; "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
    }
}
#endif
