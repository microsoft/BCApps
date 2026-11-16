// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7096 "Expense Policy Evaluation"
{
    Access = Internal;
    Caption = 'Expense Policy Evaluation';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Subject System Id"; Guid)
        {
            Caption = 'Subject System Id';
            DataClassification = CustomerContent;
        }
        field(2; "Policy System Id"; Guid)
        {
            Caption = 'Policy System Id';
            DataClassification = CustomerContent;
            TableRelation = "Expense Policy".SystemId;
        }
        field(3; "Subject Version"; Integer)
        {
            Caption = 'Subject Version';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Policy Version"; Integer)
        {
            Caption = 'Policy Version';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Subject Type"; Enum "Expense Policy Subject")
        {
            Caption = 'Subject Type';
            DataClassification = CustomerContent;
        }
        field(6; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            DataClassification = CustomerContent;
        }
        field(7; "Reason"; Text[2048])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
        }
        field(8; "Policy Text"; Text[2048])
        {
            Caption = 'Policy Text';
            DataClassification = CustomerContent;
        }
        field(9; "Evaluated At"; DateTime)
        {
            Caption = 'Evaluated At';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Compliant"; Boolean)
        {
            Caption = 'Compliant';
            DataClassification = CustomerContent;
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
        key(PK; "Subject Type", "Subject System Id", "Policy System Id", "Subject Version", "Policy Version")
        {
            Clustered = true;
        }
        key(Category; "Expense Category Code")
        {
        }
        key(EvaluatedAt; "Evaluated At")
        {
        }
    }

    trigger OnInsert()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpenseReportLine: Record "Expense Report Line";
        ExistingEvaluation: Record "Expense Policy Evaluation";
    begin
        "Evaluated At" := CurrentDateTime();

        // An evaluation is immutable. It must reference a real report line and a real,
        // enabled policy that actually applies to that line; otherwise a caller could record a verdict
        // against a subject or policy that the evaluation model would never pair.
        if "Subject Type" <> "Subject Type"::"Expense Report Line" then
            Error(UnsupportedSubjectTypeErr);
        if not ExpenseReportLine.GetBySystemId("Subject System Id") then
            Error(UnknownSubjectErr);
        if not ExpensePolicy.GetBySystemId("Policy System Id") then
            Error(UnknownPolicyErr);
        if not ExpensePolicy.AppliesToLine(ExpenseReportLine) then begin
            if not ExpensePolicy.Enabled then
                Error(DisabledPolicyErr);
            Error(InapplicablePolicyErr);
        end;

        // Reject results produced from an older subject or policy snapshot. The caller must echo the
        // versions returned by policiesToEvaluate so an evaluation cannot be stamped as current after
        // either record changes while the model is working.
        if "Subject Version" <> ExpenseReportLine."Policy Eval Version" then
            Error(SubjectVersionChangedErr);
        if "Policy Version" <> ExpensePolicy."Version" then
            Error(PolicyVersionChangedErr);

        // Snapshot server-owned policy details after the supplied versions have been validated.
        "Policy Text" := ExpensePolicy."Policy Text";
        "Expense Category Code" := ExpensePolicy."Expense Category Code";

        // Block duplicate evaluations for the same subject+policy version combination.
        if ExistingEvaluation.Get("Subject Type", "Subject System Id", "Policy System Id", "Subject Version", "Policy Version") then
            Error(DuplicateEvaluationErr);
    end;

    var
        DuplicateEvaluationErr: Label 'Policy evaluation already ran for this version of the record and policy.';
        UnsupportedSubjectTypeErr: Label 'Only expense report line policy evaluations are supported.';
        UnknownSubjectErr: Label 'The expense report line referenced by the policy evaluation does not exist.';
        UnknownPolicyErr: Label 'The expense policy referenced by the policy evaluation does not exist.';
        DisabledPolicyErr: Label 'A policy evaluation cannot be recorded for a disabled policy.';
        InapplicablePolicyErr: Label 'The referenced policy does not apply to the expense report line''s category.';
        SubjectVersionChangedErr: Label 'The expense report line changed after policy evaluation started. Refresh the line and evaluate it again.';
        PolicyVersionChangedErr: Label 'The expense policy changed after policy evaluation started. Refresh the policy and evaluate it again.';
}
