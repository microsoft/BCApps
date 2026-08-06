// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7092 "Expense Policy"
{
    Access = Internal;
    Caption = 'Expense Policy';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Subject Type"; Enum "Expense Policy Subject")
        {
            Caption = 'Subject Type';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category";
        }
        field(11; "Description"; Text[50])
        {
            Caption = 'Description';
        }
        field(12; "Policy Text"; Text[2048])
        {
            Caption = 'Policy Text';
        }
        field(20; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(21; "Version"; Integer)
        {
            Caption = 'Version';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Subject Type", "Line No.")
        {
            Clustered = true;
        }
        key(Category; "Expense Category Code")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Line No." = 0 then
            "Line No." := GetNextLineNo();
        InvalidateAffectedReportLines();
    end;

    trigger OnModify()
    begin
        // Bump the policy version on every change so flags evaluated against an earlier
        // version can be detected as no longer current (see the flag's Is Current FlowField).
        "Version" += 1;
        InvalidateAffectedReportLines();
    end;

    trigger OnDelete()
    begin
        // Removing a policy also alters the effective policy set for its category, so evaluated
        // lines must be re-checked. Existing flags for the deleted policy are intentionally kept
        // as history; the flag's Is Current FlowField already reports false once the policy is
        // gone, and re-staling the lines lets the frontend re-evaluate and drop the stale verdict.
        InvalidateAffectedReportLines();
    end;

    local procedure InvalidateAffectedReportLines()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // Adding, changing, or removing a policy alters the effective policy set for its category,
        // so any report line already evaluated against the old set must be re-checked. Bumping each
        // evaluated line's Policy Eval Version flips its status to Stale (Needs Recheck).
        // A blank category means the policy applies to every category, so invalidate all lines.
        if "Subject Type" <> "Subject Type"::"Expense Report Line" then
            exit;

        if "Expense Category Code" <> '' then
            ExpenseReportLine.SetRange("Expense Category", "Expense Category Code");
        ExpenseReportLine.SetFilter("Policies Evaluated At", '<>%1', 0DT);
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseReportLine.InvalidatePolicyEvaluation();
            until ExpenseReportLine.Next() = 0;
    end;

    local procedure GetNextLineNo(): Integer
    var
        ExpensePolicy: Record "Expense Policy";
    begin
        ExpensePolicy.SetRange("Subject Type", "Subject Type");
        if ExpensePolicy.FindLast() then
            exit(ExpensePolicy."Line No." + 10000)
        else
            exit(10000);
    end;
}
