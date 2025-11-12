// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Represents currency-specific amounts for a given date.
/// This table is used to store historical or calculated amounts in different currencies,
/// typically for reporting, analysis, or currency conversion purposes.
/// </summary>
table 264 "Currency Amount"
{
    Caption = 'Currency Amount';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Currency code identifying the currency for this amount entry.
        /// Must reference a valid currency record in the Currency table.
        /// </summary>
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        /// <summary>
        /// Date associated with this currency amount entry.
        /// Used to track when the amount was recorded or is effective from.
        /// </summary>
        field(2; Date; Date)
        {
            Caption = 'Date';
        }
        /// <summary>
        /// Monetary amount in the specified currency.
        /// Automatically formatted according to the currency's display settings.
        /// </summary>
        field(3; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Currency Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

