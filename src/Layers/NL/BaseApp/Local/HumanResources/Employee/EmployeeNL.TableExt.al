// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Bank.Payment;

tableextension 11352 "Employee NL" extends "Employee"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Employee));

            trigger OnValidate()
            var
                TransactionMode: Record "Transaction Mode";
            begin
                if "Transaction Mode Code" <> '' then
                    TransactionMode.Get(TransactionMode."Account Type"::Employee, "Transaction Mode Code");
            end;
        }
        field(11000001; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
            DataClassification = CustomerContent;
        }
        field(11000002; "Bank City"; Text[30])
        {
            Caption = 'Bank City';
            DataClassification = CustomerContent;
        }
    }
}

