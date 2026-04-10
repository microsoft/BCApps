// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using System.Globalization;

/// <summary>
/// Stores localized descriptions for tax jurisdictions in multiple languages.
/// Enables tax jurisdiction descriptions to be displayed in users' preferred languages.
/// </summary>
table 327 "Tax Jurisdiction Translation"
{
    Caption = 'Tax Jurisdiction Translation';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Tax jurisdiction code this translation applies to.
        /// </summary>
        field(1; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
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
        key(Key1; "Tax Jurisdiction Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

