// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

using System.Globalization;

/// <summary>
/// Stores translated descriptions for VAT clauses in different languages for multilingual VAT compliance.
/// Enables localized VAT clause text display on documents based on customer, vendor, or system language settings.
/// </summary>
/// <remarks>
/// Translation table supporting VAT clause localization across multiple languages.
/// Links to VAT Clause master data and Language configuration for comprehensive multilingual support.
/// </remarks>
table 561 "VAT Clause Translation"
{
    Caption = 'VAT Clause Translation';
    DrillDownPageID = "VAT Clause Translations";
    LookupPageID = "VAT Clause Translations";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the VAT clause being translated, linking to the master VAT clause record.
        /// </summary>
        field(1; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Language code identifying the target language for the translated VAT clause description.
        /// </summary>
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
            TableRelation = Language;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Translated primary description text of the VAT clause in the specified language.
        /// </summary>
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the translation of the VAT clause description. The translated version of the description is displayed as the VAT clause, based on the Language Code setting on the Customer card.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Additional translated description text providing extended VAT clause information in the specified language.
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
        key(Key1; "VAT Clause Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

