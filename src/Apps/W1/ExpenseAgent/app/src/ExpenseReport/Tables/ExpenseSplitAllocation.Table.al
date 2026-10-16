// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6940 "Expense Split Allocation"
{
    Access = Internal;
    Caption = 'Expense Split Allocation';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
