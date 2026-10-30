// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Journal;

/// <summary>
/// Stores incoming intercompany transactions received from partner companies for processing and acceptance.
/// Serves as the main inbox for journal entries, sales documents, and purchase documents from IC partners.
/// </summary>
table 418 "IC Inbox Transaction"
{
    Caption = 'IC Inbox Transaction';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Unique identifier for the intercompany transaction in the inbox.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the intercompany partner that sent this transaction.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Source type for the intercompany transaction (obsolete, replaced by IC Source Type).
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
        /// Type of source document or transaction originating this IC transaction.
        /// </summary>
        field(4; "IC Source Type"; Enum "IC Transaction Source Type")
        {
            Caption = 'IC Source Type';
            Editable = false;
        }
        /// <summary>
        /// Document type for the intercompany transaction (e.g., Order, Invoice, Credit Memo).
        /// </summary>
        field(5; "Document Type"; Enum "IC Transaction Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number from the partner company for this intercompany transaction.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Posting date for the intercompany transaction in the partner company.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Source of the transaction indicating whether it was created by or returned by the partner.
        /// </summary>
        field(8; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Document date from the original transaction in the partner company.
        /// </summary>
        field(9; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Action to be taken on this transaction: Accept, Return, Cancel, or No Action.
        /// </summary>
        field(10; "Line Action"; Option)
        {
            Caption = 'Line Action';
            OptionCaption = 'No Action,Accept,Return to IC Partner,Cancel';
            OptionMembers = "No Action",Accept,"Return to IC Partner",Cancel;
        }
        /// <summary>
        /// Original document number if this transaction references another document.
        /// </summary>
        field(11; "Original Document No."; Code[20])
        {
            Caption = 'Original Document No.';
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// IC partner G/L account number (obsolete, replaced by IC Account No.).
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
        /// Source line number for referencing original document line.
        /// </summary>
        field(13; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        /// <summary>
        /// IC account type for intercompany transaction posting.
        /// </summary>
        field(14; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        /// <summary>
        /// IC account number for intercompany transaction posting.
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
