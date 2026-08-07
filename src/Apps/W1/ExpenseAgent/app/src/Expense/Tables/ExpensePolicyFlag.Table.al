// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7096 "Expense Policy Flag"
{
    Access = Internal;
    Caption = 'Expense Policy Flag';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Subject System Id"; Guid)
        {
            Caption = 'Subject System Id';
        }
        field(2; "Policy System Id"; Guid)
        {
            Caption = 'Policy System Id';
            TableRelation = "Expense Policy".SystemId;
        }
        field(3; "Subject Version"; Integer)
        {
            Caption = 'Subject Version';
            Editable = false;
        }
        field(4; "Policy Version"; Integer)
        {
            Caption = 'Policy Version';
            Editable = false;
        }
        field(5; "Subject Type"; Enum "Expense Policy Subject")
        {
            Caption = 'Subject Type';
        }
        field(6; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
        }
        field(7; "Reason"; Text[2048])
        {
            Caption = 'Reason';
        }
        field(8; "Policy Text"; Text[2048])
        {
            Caption = 'Policy Text';
        }
        field(9; "Flagged At"; DateTime)
        {
            Caption = 'Flagged At';
        }
        field(10; "Compliant"; Boolean)
        {
            Caption = 'Compliant';
        }
        field(12; "Is Current"; Boolean)
        {
            Caption = 'Is Current';
            FieldClass = FlowField;
            CalcFormula = exist("Expense Policy" where(SystemId = field("Policy System Id"), "Version" = field("Policy Version")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Subject System Id", "Policy System Id", "Subject Version", "Policy Version")
        {
            Clustered = true;
        }
        key(Category; "Expense Category Code")
        {
        }
    }

    trigger OnInsert()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpenseReportLine: Record "Expense Report Line";
        ExistingFlag: Record "Expense Policy Flag";
    begin
        if "Flagged At" = 0DT then
            "Flagged At" := CurrentDateTime();

        // A flag is an immutable evaluation record. It must reference a real report line and a real,
        // enabled policy that actually applies to that line; otherwise a caller could record a verdict
        // against a subject or policy that the evaluation model would never pair.
        if "Subject Type" <> "Subject Type"::"Expense Report Line" then
            Error(UnsupportedSubjectTypeErr);
        if not ExpenseReportLine.GetBySystemId("Subject System Id") then
            Error(UnknownSubjectErr);
        if not ExpensePolicy.GetBySystemId("Policy System Id") then
            Error(UnknownPolicyErr);
        if not ExpensePolicy.Enabled then
            Error(DisabledPolicyErr);
        if not PolicyAppliesToLine(ExpensePolicy, ExpenseReportLine) then
            Error(InapplicablePolicyErr);

        // Snapshot the subject and policy state as evaluated. Subject Version comes from the parent
        // line's current Policy Eval Version; Policy Version records the policy's version at flag time
        // so Is Current can tell whether the policy has changed since.
        "Subject Version" := ExpenseReportLine."Policy Eval Version";
        "Policy Text" := ExpensePolicy."Policy Text";
        "Expense Category Code" := ExpensePolicy."Expense Category Code";
        "Policy Version" := ExpensePolicy."Version";

        // Block duplicate evaluations for the same subject+policy version combination.
        if ExistingFlag.Get("Subject System Id", "Policy System Id", "Subject Version", "Policy Version") then
            Error(DuplicateEvaluationErr);
    end;

    local procedure PolicyAppliesToLine(ExpensePolicy: Record "Expense Policy"; ExpenseReportLine: Record "Expense Report Line"): Boolean
    begin
        // Mirrors the applicability rule used by the policies-to-evaluate endpoint: an enabled
        // report-line policy whose category matches the line or is blank (blank applies to every
        // category).
        if ExpensePolicy."Subject Type" <> ExpensePolicy."Subject Type"::"Expense Report Line" then
            exit(false);
        exit((ExpensePolicy."Expense Category Code" = ExpenseReportLine."Expense Category") or (ExpensePolicy."Expense Category Code" = ''));
    end;

    var
        DuplicateEvaluationErr: Label 'Policy evaluation already ran for this version of the record and policy.';
        UnsupportedSubjectTypeErr: Label 'Only expense report line policy flags are supported.';
        UnknownSubjectErr: Label 'The expense report line referenced by the policy flag does not exist.';
        UnknownPolicyErr: Label 'The expense policy referenced by the policy flag does not exist.';
        DisabledPolicyErr: Label 'A policy flag cannot be recorded for a disabled policy.';
        InapplicablePolicyErr: Label 'The referenced policy does not apply to the expense report line''s category.';
}
