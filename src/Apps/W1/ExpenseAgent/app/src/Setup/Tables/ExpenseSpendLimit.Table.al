// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6939 "Expense Spend Limit"
{
    Caption = 'Expense Spend Limit';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Limit Scope"; Enum "Expense Spend Limit Scope")
        {
            Caption = 'Limit Scope';
        }
        field(3; "Applies-to Code"; Code[20])
        {
            Caption = 'Applies-to Code';
        }
        field(4; "Period Type"; Enum "Expense Spend Limit Period")
        {
            Caption = 'Period Type';
        }
        field(5; "Limit Amount"; Decimal)
        {
            Caption = 'Limit Amount';
            AutoFormatType = 1;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Scope; "Limit Scope", "Applies-to Code", "Period Type")
        {
        }
    }
}
