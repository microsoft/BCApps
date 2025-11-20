// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Table 983 "Document Search Result" stores search results for document lookup functionality.
/// Used as a temporary table to display matching documents during payment registration and document search operations.
/// </summary>
table 983 "Document Search Result"
{
    Caption = 'Document Search Result';
    DataCaptionFields = "Doc. No.", Description;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Document type identifier for the search result.
        /// </summary>
        field(1; "Doc. Type"; Integer)
        {
            Caption = 'Doc. Type';
        }
        /// <summary>
        /// Document number of the search result.
        /// </summary>
        field(2; "Doc. No."; Code[20])
        {
            Caption = 'Doc. No.';
        }
        /// <summary>
        /// Amount associated with the document.
        /// </summary>
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Table ID of the source table containing the document.
        /// </summary>
        field(4; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        /// <summary>
        /// Description of the document search result.
        /// </summary>
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Doc. Type", "Doc. No.", "Table ID")
        {
            Clustered = true;
        }
        key(Key2; Amount)
        {
        }
        key(Key3; Description)
        {
        }
        key(Key4; "Doc. No.")
        {
        }
    }

    fieldgroups
    {
    }
}
