// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6932 "Expense Approval Setup"
{
    Access = Internal;
    Caption = 'Expense Approval Setup';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Approval Setup";
    DrillDownPageId = "Expense Approval Setup";
    ReplicateData = false;

    fields
    {
        field(1; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";

            trigger OnValidate()
            var
                ExpenseUser: Record "Expense User";
                PrevFilterGroup: Integer;
            begin
                if Rec."Expense User No." = xRec."Expense User No." then
                    exit;

                if ExpenseUser.Get(Rec."Expense User No.") then begin
                    Rec.Validate("Entra Id", ExpenseUser."Entra Id");

                    PrevFilterGroup := Rec.FilterGroup(4);
                    if Rec.GetFilter("Approver No.") = '' then
                        if (ExpenseUser."Expense Team Code" <> '') and not ExpenseUser."Team Manager" then
                            SetTeamManagerAsApprover(ExpenseUser."Expense Team Code");
                    Rec.FilterGroup(PrevFilterGroup);
                end else
                    Rec.Validate("Entra Id", '');
            end;
        }
        field(2; "Entra Id"; Guid)
        {
            Caption = 'Entra Id';
        }
        field(3; "Approver No."; Code[20])
        {
            Caption = 'Approver No.';
            TableRelation = "Expense User"."No." where("Can Approve" = const(true));

            trigger OnValidate()
            begin
                Rec.TestField("Expense User No.");
                if (Rec."Approver No." <> '') and (Rec."Approver No." = Rec."Exp. Rep. Interim Approver No.") then
                    Error(InterimApproverConflictErr, Rec.FieldCaption("Exp. Rep. Interim Approver No."), Rec.FieldCaption("Approver No."));
            end;
        }
        field(4; "Expense User Name"; Text[100])
        {
            Caption = 'Expense User Name';
            ToolTip = 'Specifies the name of the expense user.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Expense User No.")));
            Editable = false;
        }
        field(5; "Approver Name"; Text[100])
        {
            Caption = 'Approver Name';
            ToolTip = 'Specifies the name of the approver.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Approver No.")));
            Editable = false;
        }
        field(6; "Exp. Rep. Interim Approver No."; Code[20])
        {
            Caption = 'Expense Report Interim Approver No.';
            ToolTip = 'Specifies the expense user who must approve the expense user''s expense reports before they are routed to the final approver. The interim approver is automatically assigned to the expense report.';
            TableRelation = "Expense User"."No." where("Can Approve" = const(true));

            trigger OnValidate()
            begin
                if Rec."Exp. Rep. Interim Approver No." <> '' then
                    CheckExpRepInterimApprover();
            end;
        }
        field(7; "Exp. Rep. Interim Appr. Name"; Text[100])
        {
            Caption = 'Expense Report Interim Approver Name';
            ToolTip = 'Specifies the name of the interim approver for expense reports.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Exp. Rep. Interim Approver No.")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Expense User No.")
        {
            Clustered = true;
        }
        key(ApproverNo; "Approver No.")
        {
        }
        key(InterimApproverNo; "Exp. Rep. Interim Approver No.")
        {
        }
    }

    var
        InterimApproverConflictErr: Label '%1 cannot be the same as %2.', Comment = '%1 = Interim Approver field caption, %2 = conflicting field caption';

    local procedure CheckExpRepInterimApprover()
    begin
        Rec.TestField("Expense User No.");
        if Rec."Exp. Rep. Interim Approver No." = Rec."Expense User No." then
            Error(InterimApproverConflictErr, Rec.FieldCaption("Exp. Rep. Interim Approver No."), Rec.FieldCaption("Expense User No."));
        if Rec."Exp. Rep. Interim Approver No." = Rec."Approver No." then
            Error(InterimApproverConflictErr, Rec.FieldCaption("Exp. Rep. Interim Approver No."), Rec.FieldCaption("Approver No."));
    end;

    local procedure SetTeamManagerAsApprover(ExpenseTeamCode: Code[20])
    var
        ApproverExpenseUserNo: Code[20];
    begin
        ApproverExpenseUserNo := GetExpenseUserNoOfTeamManager(ExpenseTeamCode);
        if ApproverExpenseUserNo <> '' then
            Rec.Validate("Approver No.", ApproverExpenseUserNo);
    end;

    local procedure GetExpenseUserNoOfTeamManager(ExpenseTeamCode: Code[20]): Code[20]
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.SetRange("Expense Team Code", ExpenseTeamCode);
        ExpenseUser.SetRange("Team Manager", true);
        ExpenseUser.SetRange("Can Approve", true);
        if ExpenseUser.FindFirst() then
            exit(ExpenseUser."No.");
    end;
}