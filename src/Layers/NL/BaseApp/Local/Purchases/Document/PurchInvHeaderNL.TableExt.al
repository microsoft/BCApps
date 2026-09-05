// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Bank.Payment;
using Microsoft.Purchases.Vendor;

tableextension 11313 PurchInvHeaderNL extends "Purch. Inv. Header"
{
    fields
    {
        field(11000000; "Transaction Mode"; Code[20])
        {
            Caption = 'Transaction Mode';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Vendor));
        }
        field(11000001; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Buy-from Vendor No."));
        }
    }
}
