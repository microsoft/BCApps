// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Journal;

/// <summary>
/// Stores processed intercompany outbox transactions after successful transmission to partners.
/// Maintains historical archive of completed intercompany transactions for audit and tracking purposes.
/// </summary>
/// <remarks>
/// Historical archive table for completed intercompany outbox transactions.
/// Supports transaction tracking, status monitoring, and comprehensive audit trails for intercompany operations.
/// Integration points: IC Partner, transaction source documents, G/L accounts, journal processing.
/// </remarks>
table 416 "Handled IC Outbox Trans."
{
    Caption = 'Handled IC Outbox Trans.';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Unique transaction number for intercompany transaction identification.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner code identifying the receiving company.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Source type of the intercompany transaction for legacy transaction categorization.
        /// </summary>
        field(3; "Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
            ObsoleteReason = 'Replaced by IC Source Type for Enum typing';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
#pragma warning disable AS0072 // Bug 647877: temporary v30 suppression, restore ObsoleteTag to 30.0
            ObsoleteTag = '29.0';
#pragma warning restore AS0072
#endif
        }
#endif
        /// <summary>
        /// Source type of the intercompany transaction for classification and routing.
        /// </summary>
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        /// <summary>
        /// Document type for the intercompany transaction processing.
        /// </summary>
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number for transaction identification and reference.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Date when the intercompany transaction was posted for accounting and audit purposes.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Source of the transaction indicating whether created by current company or rejected by partner.
        /// </summary>
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Document date from the source transaction for chronological tracking and reporting.
        /// </summary>
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Current status of the handled intercompany transaction indicating transmission and processing state.
        /// </summary>
        field(11; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Sent to IC Partner,Rejection Sent to IC Partner,Cancelled';
            OptionMembers = "Sent to IC Partner","Rejection Sent to IC Partner",Cancelled;
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// IC partner G/L account number for legacy transaction mapping and compatibility.
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
        /// Source line number from the originating document for detailed transaction traceability.
        /// </summary>
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// Type of intercompany account used for transaction classification and posting.
        /// </summary>
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// Intercompany account number for transaction posting and partner reconciliation.
        /// </summary>
        field(15; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif
