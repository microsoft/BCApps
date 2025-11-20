// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using System.Globalization;

/// <summary>
/// Stores multi-language translations for payment method descriptions.
/// Enables localized payment method names for international business operations.
/// </summary>
/// <remarks>
/// Links to Payment Method and Language tables. Used by Payment Method for description translation.
/// </remarks>
table 466 "Payment Method Translation"
{
    Caption = 'Payment Method Translation';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Payment method code being translated.
        /// </summary>
        field(1; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        /// <summary>
        /// Language code for the translation.
        /// </summary>
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Translated description text for the payment method in the specified language.
        /// </summary>
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Payment Method Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

