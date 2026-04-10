// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

/// <summary>
/// Stores document-type-specific descriptions for VAT clauses enabling customized text per document scenario.
/// Allows different VAT clause descriptions for invoices, credit memos, reminders, and finance charge memos.
/// </summary>
/// <remarks>
/// Enables document-type-specific VAT clause variations for business and regulatory requirements.
/// Provides specialized VAT clause text based on the type of document being processed.
/// </remarks>
table 562 "VAT Clause by Doc. Type"
{
    Caption = 'VAT Clause by Document Type';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the VAT clause for which document-specific description is defined.
        /// </summary>
        field(1; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Document type for which specialized VAT clause description applies.
        /// </summary>
        field(2; "Document Type"; Enum "VAT Clause Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type, which is used to provide a VAT description associated with a sales line on a sales invoice, credit memo, or other sales document.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Document-specific description text for the VAT clause to be printed on the specified document type.
        /// </summary>
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the translation of the VAT clause description. The translated version of the description is displayed as the VAT clause, based on the Language Code setting on the customer card.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Additional description text for extended VAT clause information on the specified document type.
        /// </summary>
        field(4; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the translation of the additional VAT clause description.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "VAT Clause Code", "Document Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

