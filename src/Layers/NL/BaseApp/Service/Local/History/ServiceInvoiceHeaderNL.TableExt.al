// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Bank.Payment;
using Microsoft.Sales.Customer;

tableextension 11454 "Service Invoice Header NL" extends "Service Invoice Header"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));

            trigger OnValidate()
            var
                TrMode: Record "Transaction Mode";
            begin
                if "Transaction Mode Code" <> '' then begin
                    TrMode.Get(TrMode."Account Type"::Customer, "Transaction Mode Code");
                    if TrMode."Payment Method Code" <> '' then
                        Validate("Payment Method Code", TrMode."Payment Method Code");
                    if TrMode."Payment Terms Code" <> '' then
                        Validate("Payment Terms Code", TrMode."Payment Terms Code");
                end;
            end;
        }
        field(11000001; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
    }
}
