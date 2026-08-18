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
            DataClassification = CustomerContent;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(10; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            DataClassification = CustomerContent;
            TableRelation = "Expense Category";
        }
        field(11; "Description"; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; "Policy Text"; Text[2048])
        {
            Caption = 'Policy Text';
            DataClassification = CustomerContent;
        }
        field(20; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(21; "Version"; Integer)
        {
            Caption = 'Version';
            DataClassification = CustomerContent;
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
        key(Applicable; "Subject Type", Enabled, "Expense Category Code")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Line No." = 0 then
            "Line No." := GetNextLineNo();
        InvalidateAffectedReportLines("Subject Type", "Expense Category Code");
    end;

    trigger OnModify()
    var
        StoredExpensePolicy: Record "Expense Policy";
    begin
        // Bump the policy version on every change so flags evaluated against an earlier
        // version can be detected as no longer current (see the flag's Is Current FlowField).
        "Version" += 1;

        // Invalidate the previous scope as well as the new one. Moving a policy to a different
        // category - or disabling it - changes which lines it affects, so lines in the old scope
        // must be re-checked too; otherwise they keep a verdict from a policy that no longer
        // applies to them and stay incorrectly Current.
        // xRec is unreliable here (it has been observed to compare equal to Rec at runtime, see
        // Expense Report Line.PolicyRelevantFieldChanged), so read the committed pre-modify image
        // by primary key to get the old category. Subject Type is part of the primary key and
        // cannot change on modify, so only the category can move.
        if StoredExpensePolicy.Get("Subject Type", "Line No.") then begin
            InvalidateAffectedReportLines("Subject Type", StoredExpensePolicy."Expense Category Code");
            if StoredExpensePolicy."Expense Category Code" <> "Expense Category Code" then
                InvalidateAffectedReportLines("Subject Type", "Expense Category Code");
        end else
            InvalidateAffectedReportLines("Subject Type", "Expense Category Code");
    end;

    trigger OnDelete()
    begin
        // Removing a policy also alters the effective policy set for its category, so evaluated
        // lines must be re-checked. Existing flags for the deleted policy are intentionally kept
        // as history; the flag's Is Current FlowField already reports false once the policy is
        // gone, and re-staling the lines lets the frontend re-evaluate and drop the stale verdict.
        InvalidateAffectedReportLines("Subject Type", "Expense Category Code");
    end;

    local procedure InvalidateAffectedReportLines(SubjectType: Enum "Expense Policy Subject"; CategoryCode: Code[20])
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // Adding, changing, or removing a policy alters the effective policy set for its category,
        // so any report line already evaluated against the old set must be re-checked. Bumping each
        // evaluated line's Policy Eval Version flips its status to Stale (Needs Recheck).
        // A blank category means the policy applies to every category, so invalidate all lines.
        // The scan is served by the report line's PolicyInvalidation key (Expense Category,
        // Policies Evaluated At). Policies change rarely, so the per-line write cost is acceptable.
        if SubjectType <> SubjectType::"Expense Report Line" then
            exit;

        ExpenseReportLine.SetCurrentKey("Expense Category", "Policies Evaluated At");
        if CategoryCode <> '' then
            ExpenseReportLine.SetRange("Expense Category", CategoryCode);
        ExpenseReportLine.SetFilter("Policies Evaluated At", '<>%1', 0DT);
        if ExpenseReportLine.FindSet(true) then
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
