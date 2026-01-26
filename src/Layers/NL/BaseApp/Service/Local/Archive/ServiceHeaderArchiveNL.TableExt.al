// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Bank.Payment;
using Microsoft.Sales.Customer;

tableextension 11460 "Service Header Archive NL" extends "Service Header Archive"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the transaction mode code for the service header.';
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));
        }
        field(11000001; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the bank account code for the service header.';
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
    }
}