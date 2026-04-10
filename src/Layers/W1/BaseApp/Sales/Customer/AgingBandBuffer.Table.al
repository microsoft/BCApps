// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Stores aging band amounts by currency for customer aging reports and analysis.
/// </summary>
table 47 "Aging Band Buffer"
{
    Caption = 'Aging Band Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the currency code for grouping aging band amounts.
        /// </summary>
        field(1; "Currency Code"; Code[20])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the total amount for the first aging period column.
        /// </summary>
        field(2; "Column 1 Amt."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Column 1 Amt.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the total amount for the second aging period column.
        /// </summary>
        field(3; "Column 2 Amt."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Column 2 Amt.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the total amount for the third aging period column.
        /// </summary>
        field(4; "Column 3 Amt."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Column 3 Amt.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the total amount for the fourth aging period column.
        /// </summary>
        field(5; "Column 4 Amt."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Column 4 Amt.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the total amount for the fifth aging period column.
        /// </summary>
        field(6; "Column 5 Amt."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Column 5 Amt.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

