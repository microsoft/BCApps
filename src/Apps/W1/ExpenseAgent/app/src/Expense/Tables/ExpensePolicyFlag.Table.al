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
        field(7; "Description"; Text[2048])
        {
            Caption = 'Description';
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
        field(11; "Policy Line No."; Integer)
        {
            Caption = 'Policy Line No.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense Policy"."Line No." where(SystemId = field("Policy System Id")));
            Editable = false;
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

        // Resolve subject version from the current state of the subject record.
        if not IsNullGuid("Subject System Id") then
            case "Subject Type" of
                "Subject Type"::"Expense Report Line":
                    if ExpenseReportLine.GetBySystemId("Subject System Id") then
                        "Subject Version" := ExpenseReportLine."Policy Eval Version";
            end;

        // Capture a snapshot of the policy as evaluated. Policy Version records the policy's
        // version at flag time so Is Current can tell whether the policy has changed since.
        if not IsNullGuid("Policy System Id") then
            if ExpensePolicy.GetBySystemId("Policy System Id") then begin
                "Policy Text" := ExpensePolicy."Policy Text";
                "Expense Category Code" := ExpensePolicy."Expense Category Code";
                "Policy Version" := ExpensePolicy."Version";
            end;

        // Block duplicate evaluations for the same subject+policy version combination.
        if ExistingFlag.Get("Subject System Id", "Policy System Id", "Subject Version", "Policy Version") then
            Error(DuplicateEvaluationErr);
    end;

    var
        DuplicateEvaluationErr: Label 'Policy evaluation already ran for this version of the record and policy.';
}
