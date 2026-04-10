// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

using System.Globalization;

/// <summary>
/// Stores multilingual translations for document-type-specific VAT clause descriptions.
/// Enables localized VAT clause text for different document types across multiple languages.
/// </summary>
/// <remarks>
/// Supports international business operations requiring VAT clause text in customer languages.
/// Links document-type-specific VAT clauses with language-specific translations.
/// </remarks>
table 563 "VAT Clause by Doc. Type Trans."
{
    Caption = 'VAT Clause by Document Type Translation';
    DataCaptionFields = "VAT Clause Code", "Document Type";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the VAT clause for which multilingual document-specific translations are defined.
        /// </summary>
        field(1; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Document type for which the translated VAT clause description applies.
        /// </summary>
        field(2; "Document Type"; Enum "VAT Clause Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Language code for the translated VAT clause description text.
        /// </summary>
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
            TableRelation = Language;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Translated description text for the VAT clause in the specified language and document type.
        /// </summary>
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the translation of the VAT clause description. The translated version of the description is displayed as the VAT clause, based on the Language Code setting on the customer card.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Additional translated description text for extended VAT clause information in the specified language.
        /// </summary>
        field(5; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies the translation of the additional VAT clause description.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "VAT Clause Code", "Document Type", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

