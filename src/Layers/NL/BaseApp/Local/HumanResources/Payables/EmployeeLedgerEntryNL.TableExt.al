// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Bank.Payment;

tableextension 11362 "Employee Ledger Entry NL" extends "Employee Ledger Entry"
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Employee));
        }
        field(11000002; "Payments in Process"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            BlankZero = true;
            CalcFormula = sum("Detail Line"."Amount (Entry)" where("Serial No. (Entry)" = field("Entry No."),
                            Status = const("In process"),
                            "Account Type" = const(Employee),
                            "Connect Batches" = field("Connect Batches Filter"),
                            "Connect Lines" = field("Connect Lines Filter"),
                            "Our Bank" = field("Our Bank Filter")));
            Caption = 'Payments in Process';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11000003; "Connect Batches Filter"; Code[20])
        {
            Caption = 'Connect Batches Filter';
            FieldClass = FlowFilter;
        }
        field(11000004; "Connect Lines Filter"; Integer)
        {
            Caption = 'Connect Lines Filter';
            FieldClass = FlowFilter;
        }
        field(11000005; "Our Bank Filter"; Code[20])
        {
            Caption = 'Our Bank Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(TransactionMode; "Transaction Mode Code")
        {
        }
    }
}

