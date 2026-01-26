// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Bank.Payment;
using Microsoft.Sales.Customer;

tableextension 11455 "Filed Serv. Contract Header NL" extends "Filed Service Contract Header"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));
        }
        field(11000001; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
    }
}