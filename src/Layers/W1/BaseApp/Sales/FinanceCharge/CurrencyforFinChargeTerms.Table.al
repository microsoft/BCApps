// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.Currency;

/// <summary>
/// Stores currency-specific additional fee amounts for finance charge terms to support multi-currency finance charges.
/// </summary>
table 328 "Currency for Fin. Charge Terms"
{
    Caption = 'Currency for Fin. Charge Terms';
    DataCaptionFields = "Fin. Charge Terms Code";
    DrillDownPageID = "Currencies for Fin. Chrg Terms";
    LookupPageID = "Currencies for Fin. Chrg Terms";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the finance charge terms code that this currency entry belongs to.
        /// </summary>
        field(1; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Finance Charge Terms";
        }
        /// <summary>
        /// Specifies the currency code for which the additional fee amount is defined.
        /// </summary>
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the code for the currency in which you want to define finance charge terms.';
            NotBlank = true;
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the additional fee amount in the specified currency for finance charge memos.
        /// </summary>
        field(4; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Additional Fee';
            ToolTip = 'Specifies a fee amount in foreign currency. The currency of this amount is determined by the currency code.';
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Fin. Charge Terms Code", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

