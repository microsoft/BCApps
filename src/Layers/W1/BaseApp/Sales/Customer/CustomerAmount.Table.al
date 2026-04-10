// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Stores customer amount information in local currency for ranking and sorting purposes.
/// </summary>
table 266 "Customer Amount"
{
    Caption = 'Customer Amount';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique identifier of the customer associated with this amount record.
        /// </summary>
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the primary amount in local currency used for ranking customers.
        /// </summary>
        field(2; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
        }
        /// <summary>
        /// Specifies a secondary amount in local currency used as an additional sorting criterion.
        /// </summary>
        field(3; "Amount 2 (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount 2 (LCY)';
        }
    }

    keys
    {
        key(Key1; "Amount (LCY)", "Amount 2 (LCY)", "Customer No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

