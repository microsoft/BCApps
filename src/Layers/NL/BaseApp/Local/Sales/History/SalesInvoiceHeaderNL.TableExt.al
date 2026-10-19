// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Bank.Payment;
using Microsoft.Sales.Customer;

/// <summary>
/// Extends the Sales Invoice Header table with NL-specific telebanking fields.
/// </summary>
tableextension 11466 "Sales Invoice Header NL" extends "Sales Invoice Header"
{
    fields
    {
        /// <summary>
        /// Specifies the transaction mode used in telebanking for this posted sales invoice.
        /// </summary>
        field(11000000; "Transaction Mode"; Code[20])
        {
            Caption = 'Transaction Mode';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));
        }
        /// <summary>
        /// Specifies the customer's bank account used for payments and collections through telebanking.
        /// </summary>
        field(11000001; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Sell-to Customer No."));
        }
    }
}
