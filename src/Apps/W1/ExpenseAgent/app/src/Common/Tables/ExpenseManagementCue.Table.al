// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7449 "EA Expense Management Cue"
{
    Access = Internal;
    Caption = 'Expense Management Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Open Expense Reports"; Integer)
        {
            CalcFormula = count("Expense Report Header" where(Status = const(Open)));
            Caption = 'Open Expense Reports';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Pending Approval"; Integer)
        {
            CalcFormula = count("Expense Report Header" where(Status = filter("Pending Approval" | "Interim Approved")));
            Caption = 'Pending Approval';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Approved Reports"; Integer)
        {
            CalcFormula = count("Expense Report Header" where(Status = const(Approved)));
            Caption = 'Approved';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Rejected Reports"; Integer)
        {
            CalcFormula = count("Expense Report Header" where(Status = const(Rejected)));
            Caption = 'Rejected';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Open Expenses"; Integer)
        {
            CalcFormula = count(Expense where(Status = const(Open)));
            Caption = 'Open Expenses';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Unresolved Card Exceptions"; Integer)
        {
            CalcFormula = count("EA Corp Card Exception" where(Resolved = const(false)));
            Caption = 'Unresolved Card Exceptions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Card Transactions to Review"; Integer)
        {
            CalcFormula = count("EA Corp Card Trans" where(Status = filter(Imported | Matched | Exception)));
            Caption = 'Card Transactions to Review';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
