// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Bank.Payment;

/// <summary>
/// Extends the Customer Templ. table with NL-specific telebanking fields.
/// </summary>
tableextension 11464 "Customer Templ. NL" extends "Customer Templ."
{
    fields
    {
        /// <summary>
        /// Specifies the transaction mode commonly used in telebanking for customers created from this template.
        /// </summary>
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));
        }
    }
}
