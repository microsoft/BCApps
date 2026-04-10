// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using System.Globalization;

/// <summary>
/// Stores localized descriptions for tax areas in multiple languages.
/// Enables tax area descriptions to be displayed in users' preferred languages.
/// </summary>
table 316 "Tax Area Translation"
{
    Caption = 'Tax Area Translation';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Tax area code this translation applies to.
        /// </summary>
        field(1; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            NotBlank = true;
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Language code for the translated description.
        /// </summary>
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Translated description text in the specified language.
        /// </summary>
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Tax Area Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

