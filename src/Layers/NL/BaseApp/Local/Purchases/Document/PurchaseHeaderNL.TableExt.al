// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Bank.Payment;
using Microsoft.Purchases.Vendor;

tableextension 11306 PurchaseHeaderNL extends "Purchase Header"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Vendor));

            trigger OnValidate()
            var
                TransactionMode: Record "Transaction Mode";
            begin
                if "Transaction Mode Code" <> '' then begin
                    TransactionMode.Get(TransactionMode."Account Type"::Vendor, "Transaction Mode Code");
                    if TransactionMode."Payment Method Code" <> '' then
                        Validate("Payment Method Code", TransactionMode."Payment Method Code");
                    if TransactionMode."Payment Terms Code" <> '' then
                        Validate("Payment Terms Code", TransactionMode."Payment Terms Code");
                end;
            end;
        }
        field(11000001; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Pay-to Vendor No."));
        }
    }
}

