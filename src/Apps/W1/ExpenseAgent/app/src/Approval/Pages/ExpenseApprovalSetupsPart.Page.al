// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Utilities;

page 6947 "Expense Approval Setups Part"
{
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Approval Setup";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the expense user for expense approval setup.';
                }
                field("Expense User Name"; Rec."Expense User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the expense user.';
                    Editable = false;
                    DrillDown = false;
                }
            }
        }
    }

    var
        ExpenseSetupExistsErr: Label 'There is already a %1 for Expense User "%2".', Comment = '%1=Caption, %2=Expense User No.';
        AnotherApprovalSetErr: Label 'User "%1" already has user "%2" as an approver. Multiple approvers for the same user are not supported.', Comment = '%1, %2=Expense User names';
        ReplaceApproverQst: Label 'User "%1" already has user "%2" as an approver. Multiple approvers for the same user are not supported.\\Do you want to replace the approver with "%3"?', Comment = '%1, %2, %3=Expense User names';

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ApproverNo: Code[20];
    begin
        if Rec."Approver No." = '' then
            if GetApproverNoFromFilters(ApproverNo) then
                Rec."Approver No." := ApproverNo;

        if not ExpenseApprovalSetup.Get(Rec."Expense User No.") then
            exit(true);

        AssignApproverToExistingSetup(ExpenseApprovalSetup);
        Rec.Get(ExpenseApprovalSetup."Expense User No.");
        exit(false);
    end;

    local procedure AssignApproverToExistingSetup(var ExpenseApprovalSetup: Record "Expense Approval Setup")
    begin
        if Rec."Approver No." = '' then
            Error(ExpenseSetupExistsErr, ExpenseApprovalSetup.TableCaption(), ExpenseApprovalSetup."Expense User No.");

        if ExpenseApprovalSetup."Approver No." <> '' then begin
            ExpenseApprovalSetup.CalcFields("Expense User Name", "Approver Name");
            if not ConfirmReplaceApprover(ExpenseApprovalSetup) then
                Error(AnotherApprovalSetErr, ExpenseApprovalSetup."Expense User Name", ExpenseApprovalSetup."Approver Name");
        end;

        ExpenseApprovalSetup.Validate("Approver No.", Rec."Approver No.");
        ExpenseApprovalSetup.Modify(true);
    end;

    local procedure ConfirmReplaceApprover(ExpenseApprovalSetup: Record "Expense Approval Setup"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ExpenseApprovalSetup."Approver No." = Rec."Approver No." then
            exit(false);

        Rec.CalcFields("Approver Name");
        exit(ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(ReplaceApproverQst, ExpenseApprovalSetup."Expense User Name", ExpenseApprovalSetup."Approver Name", Rec."Approver Name"), false));
    end;

    [TryFunction]
    local procedure GetApproverNoFromFilters(var ApproverNo: Code[20])
    begin
        if Rec.GetRangeMax("Approver No.") = Rec.GetRangeMin("Approver No.") then
            ApproverNo := Rec.GetRangeMax("Approver No.");
    end;
}