// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6940 "Expense Activities Cue"
{
    Access = Internal;
    Caption = 'Expense Activities Cue';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Opened Expense Reports"; Integer)
        {
            Caption = 'Opened Expense Reports';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Open)));
            Editable = false;
        }
        field(3; "Released Expense Reports"; Integer)
        {
            Caption = 'Released Expense Reports';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Released)));
            Editable = false;
        }
        field(4; "Pending Approval Exp. Reports"; Integer)
        {
            Caption = 'Expense Reports Pending Approvals';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const("Pending Approval")));
            Editable = false;
        }
        field(5; "Approved Expense Reports"; Integer)
        {
            Caption = 'Approved Expense Reports';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Approved)));
            Editable = false;
        }
        field(6; "Rejected Expense Reports"; Integer)
        {
            Caption = 'Rejected Expense Reports';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Rejected)));
            Editable = false;
        }
        field(7; "Processed for Payment Exp."; Integer)
        {
            Caption = 'Processed for Payment Exp. Rep.';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const("Processed for Payment")));
            Editable = false;
        }
        field(8; "Completed Expense Reports"; Integer)
        {
            Caption = 'Completed Expense Reports';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Completed)));
            Editable = false;
        }
        field(9; "Released Expenses"; Integer)
        {
            Caption = 'Released Expenses';
            FieldClass = FlowField;
            CalcFormula = count(Expense where(Status = const(Released)));
            Editable = false;
        }
        field(10; "Policy Violated Expenses"; Integer)
        {
            Caption = 'Policy Violated Expenses';
            FieldClass = FlowField;
            CalcFormula = count(Expense where("Rule Violations" = const(true)));
            Editable = false;
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
