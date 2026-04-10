// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Stores date-effective interest rates for finance charge terms to support varying rates over time.
/// </summary>
table 572 "Finance Charge Interest Rate"
{
    Caption = 'Fin. Charge Interest Rate';
    DataCaptionFields = "Fin. Charge Terms Code", "Start Date";
    LookupPageID = "Finance Charge Interest Rates";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the finance charge terms code that this interest rate entry belongs to.
        /// </summary>
        field(1; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            NotBlank = true;
            TableRelation = "Finance Charge Terms".Code;
        }
        /// <summary>
        /// Specifies the date from which this interest rate becomes effective.
        /// </summary>
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
            ToolTip = 'Specifies the start date for the interest rate.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the interest rate percentage to apply starting from the start date.
        /// </summary>
        field(3; "Interest Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Interest Rate';
            ToolTip = 'Specifies the interest rate percentage.';
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the number of days that define one interest calculation period for this rate.
        /// </summary>
        field(4; "Interest Period (Days)"; Integer)
        {
            Caption = 'Interest Period (Days)';
        }
    }

    keys
    {
        key(Key1; "Fin. Charge Terms Code", "Start Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

