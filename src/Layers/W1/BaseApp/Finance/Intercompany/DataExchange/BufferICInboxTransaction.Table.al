// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Journal;

/// <summary>
/// Temporary buffer table for staging intercompany inbox transaction data during API-based data exchange.
/// Facilitates transaction validation and transformation before posting to target partner systems.
/// </summary>
table 610 "Buffer IC Inbox Transaction"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Unique transaction number identifying the intercompany transaction in the buffer.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the source intercompany partner for this buffered transaction.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Source type classification for the intercompany transaction (Journal, Sales Document, Purchase Document).
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
            ObsoleteTag = '29.0';
#endif
        }
#endif
        /// <summary>
        /// Intercompany source type for the transaction using enhanced enum typing.
        /// </summary>
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        /// <summary>
        /// Document type for the intercompany transaction (Order, Invoice, Credit Memo, etc.).
        /// </summary>
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number for the intercompany transaction from the originating partner system.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Date when the intercompany transaction will be posted to the general ledger.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction indicating creation origin (Partner or Current Company).
        /// </summary>
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Original document date when the transaction was created in the source system.
        /// </summary>
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Action to be taken on the transaction line (No Action, Send to IC Partner, Accept, etc.).
        /// </summary>
        field(10; "Line Action"; Option)
        {
            Caption = 'Line Action';
            OptionCaption = 'No Action,Accept,Return to IC Partner,Cancel';
            OptionMembers = "No Action",Accept,"Return to IC Partner",Cancel;
        }
        /// <summary>
        /// Original document number from the source system before intercompany processing.
        /// </summary>
        field(11; "Original Document No."; Code[20])
        {
            Caption = 'Original Document No.';
        }
        /// <summary>
        /// Source line number from the originating document for detailed transaction tracking.
        /// </summary>
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// Intercompany account type for the transaction (G/L Account, Item, etc.).
        /// </summary>
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// Intercompany account number corresponding to the specified account type.
        /// </summary>
        field(15; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
        }
        /// <summary>
        /// Unique operation identifier for tracking API-based data exchange processes and error resolution.
        /// </summary>
        field(8100; "Operation ID"; Guid)
        {
            Editable = false;
            Caption = 'Operation ID';
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
}
