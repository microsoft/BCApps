// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6941 "Expense Activities Cue"
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
            AllowInCustomizations = Never;
        }
        field(2; "Expense Reports - Open"; Integer)
        {
            Caption = 'Expense Reports - Open';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Open)));
            Editable = false;
            ToolTip = 'Specifies the number of open expense reports.';
        }
        field(3; "Expense Reports - Released"; Integer)
        {
            Caption = 'Expense Reports - Released';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Released)));
            Editable = false;
            ToolTip = 'Specifies the number of released expense reports.';
        }
        field(4; "Exp. Reports - Pending Appr."; Integer)
        {
            Caption = 'Expense Reports - Pending Approval';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const("Pending Approval")));
            Editable = false;
            ToolTip = 'Specifies the number of expense reports that are pending approval.';
        }
        field(5; "Expense Reports - Approved"; Integer)
        {
            Caption = 'Expense Reports - Approved';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Approved)));
            Editable = false;
            ToolTip = 'Specifies the number of approved expense reports.';
        }
        field(6; "Expense Reports - Rejected"; Integer)
        {
            Caption = 'Expense Reports - Rejected';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Rejected)));
            Editable = false;
            ToolTip = 'Specifies the number of rejected expense reports.';
        }
        field(7; "Exp. Reports - Processed Pay"; Integer)
        {
            Caption = 'Expense Reports - Processed for Payment';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const("Processed for Payment")));
            Editable = false;
            ToolTip = 'Specifies the number of expense reports that are processed for payment.';
        }
        field(8; "Expense Reports - Completed"; Integer)
        {
            Caption = 'Expense Reports - Completed';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const(Completed)));
            Editable = false;
            ToolTip = 'Specifies the number of completed expense reports.';
        }
        field(9; "Exp. Reports - Interim Appr."; Integer)
        {
            Caption = 'Expense Reports - Interim Approved';
            FieldClass = FlowField;
            CalcFormula = count("Expense Report Header" where(Status = const("Interim Approved")));
            Editable = false;
            ToolTip = 'Specifies the number of expense reports that are interim approved.';
        }
        field(20; "Expenses - Released"; Integer)
        {
            Caption = 'Expenses - Released';
            FieldClass = FlowField;
            CalcFormula = count(Expense where(Status = const(Released)));
            Editable = false;
            ToolTip = 'Specifies the number of released expenses.';
        }
        field(21; "Expenses - Policy Violated"; Integer)
        {
            Caption = 'Expenses - Policy Violated';
            FieldClass = FlowField;
            CalcFormula = count(Expense where("Rule Violations" = const(true)));
            Editable = false;
            ToolTip = 'Specifies the number of expenses with policy violations.';
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