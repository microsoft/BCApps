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
    end;

    trigger OnModify()
    begin
        // Bump the policy version on every change so evaluations against an earlier
        // version can be detected as no longer current (see the evaluation's Is Current FlowField).
        "Version" += 1;
    end;

    internal procedure SetApplicableToLineFilter(ExpenseReportLine: Record "Expense Report Line")
    begin
        // Report-line policies apply when enabled and scoped to either the line's category or every category.
        Rec.SetCurrentKey("Subject Type", Enabled, "Expense Category Code");
        Rec.SetRange("Subject Type", Rec."Subject Type"::"Expense Report Line");
        Rec.SetRange(Enabled, true);
        Rec.SetFilter("Expense Category Code", '%1|%2', ExpenseReportLine."Expense Category", '');
    end;

    internal procedure AppliesToLine(ExpenseReportLine: Record "Expense Report Line"): Boolean
    begin
        exit(
            Rec.Enabled and
            (Rec."Subject Type" = Rec."Subject Type"::"Expense Report Line") and
            ((Rec."Expense Category Code" = ExpenseReportLine."Expense Category") or (Rec."Expense Category Code" = '')));
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
