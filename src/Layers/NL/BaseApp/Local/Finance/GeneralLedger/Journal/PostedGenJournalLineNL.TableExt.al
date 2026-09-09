// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Payment;

tableextension 11387 "Posted Gen. Journal Line NL" extends "Posted Gen. Journal Line"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = if ("Account Type" = const(Customer)) "Transaction Mode".Code where("Account Type" = const(Customer))
            else
            if ("Account Type" = const(Vendor)) "Transaction Mode".Code where("Account Type" = const(Vendor))
            else
            if ("Account Type" = const(Employee)) "Transaction Mode".Code where("Account Type" = const(Employee))
            else
            if ("Bal. Account Type" = const(Customer)) "Transaction Mode".Code where("Account Type" = const(Customer))
            else
            if ("Bal. Account Type" = const(Vendor)) "Transaction Mode".Code where("Account Type" = const(Vendor))
            else
            if ("Bal. Account Type" = const(Employee)) "Transaction Mode".Code where("Account Type" = const(Employee));
        }
    }
}

