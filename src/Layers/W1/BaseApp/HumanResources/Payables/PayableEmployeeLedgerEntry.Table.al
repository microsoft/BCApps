// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Finance.Currency;
using Microsoft.HumanResources.Employee;

table 5224 "Payable Employee Ledger Entry"
{
    Caption = 'Payable Employee Ledger Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Employee Ledg. Entry No."; Integer)
        {
            Caption = 'Employee Ledg. Entry No.';
            TableRelation = "Employee Ledger Entry";
        }
        field(5; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(8; Positive; Boolean)
        {
            Caption = 'Positive';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

