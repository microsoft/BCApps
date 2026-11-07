// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

/// <summary>
/// Temporary buffer table for processing direct debit collection entries during export and validation operations.
/// Stores essential collection entry information for batch processing and intermediate calculations
/// without modifying the permanent collection entry records.
/// </summary>
table 1255 "Direct Debit Collection Buffer"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        /// <summary>
        /// Reference to the parent direct debit collection.
        /// </summary>
        field(1; "Direct Debit Collection No."; Integer)
        {
            Caption = 'Direct Debit Collection No.';
            TableRelation = "Direct Debit Collection";
        }
        /// <summary>
        /// Entry number within the direct debit collection.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Customer ledger entry that this collection entry applies to.
        /// </summary>
        field(4; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
        }
        /// <summary>
        /// Unique transaction identifier used in SEPA XML files.
        /// </summary>
        field(8; "Transaction ID"; Text[35])
        {
            Caption = 'Transaction ID';
            Editable = false;
        }
        /// <summary>
        /// Current processing status of the collection entry.
        /// </summary>
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'New,File Created,Rejected,Posted';
            OptionMembers = New,"File Created",Rejected,Posted;
        }
    }

    keys
    {
        key(Key1; "Direct Debit Collection No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Applies-to Entry No.", Status)
        {
        }
    }
}
