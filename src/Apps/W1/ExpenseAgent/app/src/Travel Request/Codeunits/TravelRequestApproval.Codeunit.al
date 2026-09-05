// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using System.Text;

codeunit 7133 "Travel Request Approval"
{
    Access = Internal;
    Permissions = tabledata "Spend Request" = m;

    internal procedure Submit(var SpendRequest: Record "Spend Request"; SubmitterExpenseUserNo: Code[20])
    var
        Submitter: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Open);
        Submitter.SetLoadFields("Employee No.");
        Submitter.Get(SubmitterExpenseUserNo);
        Submitter.TestField("Employee No.");
        if Submitter."Employee No." <> SpendRequest."Requested By" then
            Error(NotTravelRequestOwnerErr, SubmitterExpenseUserNo, SpendRequest."No.");

        SpendRequest."Submitted By Expense User No." := SubmitterExpenseUserNo;
        SpendRequest."Submitted At" := CurrentDateTime();
        Clear(SpendRequest."Approval Expense User No.");
        Clear(SpendRequest."Rejection Reason");
        SpendRequest.Modify();
        ReleaseSpendRequest.Release(SpendRequest);
    end;

    internal procedure Approve(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        Approver: Record "Expense User";
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Released);
        CheckApprover(SpendRequest, ApproverExpenseUserNo, Approver);
        ApproveInternal(SpendRequest, ApproverExpenseUserNo);
    end;

    internal procedure ApproveAutomatically(var SpendRequest: Record "Spend Request")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Released);

        ExpenseAgentSetup.GetRecordOnce();
        if ExpenseAgentSetup."Enable Agent" then
            Error(AutomaticApprovalNotAllowedErr);

        ApproveInternal(SpendRequest, '');
    end;

    local procedure ApproveInternal(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        SpendRequest.TestField("Requested For");
        SpendRequest.Status := SpendRequest.Status::Approved;
        SpendRequest."Approved/Rejected At" := CurrentDateTime();
        SpendRequest."Approved/Rejected by User ID" := UserSecurityId();
        SpendRequest."Approval Expense User No." := ApproverExpenseUserNo;
        Clear(SpendRequest."Rejection Reason");
        SpendRequest.Modify();
        ExpenseReportHeader.CreateFromApprovedTravelRequest(SpendRequest);
    end;

    internal procedure Reject(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        Approver: Record "Expense User";
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Released);
        CheckApprover(SpendRequest, ApproverExpenseUserNo, Approver);
        SpendRequest.Status := SpendRequest.Status::Rejected;
        SpendRequest."Approved/Rejected At" := CurrentDateTime();
        SpendRequest."Approved/Rejected by User ID" := UserSecurityId();
        SpendRequest."Approval Expense User No." := ApproverExpenseUserNo;
        SpendRequest."Rejection Reason" := CopyStr(RejectReason, 1, MaxStrLen(SpendRequest."Rejection Reason"));
        SpendRequest.Modify();
    end;

    internal procedure ApplyApproverFilter(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        Approver: Record "Expense User";
        RequestedForFilter: Text;
    begin
        CheckApproverPermissions(ApproverExpenseUserNo, Approver);
        RequestedForFilter := GetRequestedForFilter(ApproverExpenseUserNo);

        SpendRequest.SetRange("Approver Expense User Filter");
        SpendRequest.SetRange(SystemId);
        if RequestedForFilter = '' then
            SpendRequest.SetRange(SystemId, CreateGuid())
        else
            SpendRequest.SetFilter("Requested For", RequestedForFilter);
    end;

    local procedure CheckTravelRequest(SpendRequest: Record "Spend Request")
    begin
        SpendRequest.TestField("Document Type", SpendRequest."Document Type"::"Travel Request");
    end;

    local procedure CheckApprover(SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20]; var Approver: Record "Expense User")
    var
        ExpectedApproverExpenseUserNo: Code[20];
    begin
        CheckApproverPermissions(ApproverExpenseUserNo, Approver);
        ExpectedApproverExpenseUserNo := GetApproverExpenseUserNo(SpendRequest."Requested For");
        if ApproverExpenseUserNo <> ExpectedApproverExpenseUserNo then
            Error(NotTravelRequestApproverErr, ApproverExpenseUserNo, SpendRequest."No.");
    end;

    local procedure CheckApproverPermissions(ApproverExpenseUserNo: Code[20]; var Approver: Record "Expense User")
    begin
        Approver.SetLoadFields("Can Approve", "User Id For Approvals");
        Approver.Get(ApproverExpenseUserNo);
        Approver.TestField("Can Approve", true);
        Approver.TestField("User Id For Approvals");
    end;

    local procedure GetApproverExpenseUserNo(RequestedForExpenseUserNo: Code[20]): Code[20]
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if ExpenseApprovalSetup.Get(RequestedForExpenseUserNo) then
            if ExpenseApprovalSetup."Approver No." <> '' then
                exit(ExpenseApprovalSetup."Approver No.");

        ExpenseAgentSetup.GetRecordOnce();
        exit(ExpenseAgentSetup."Default Approver No.");
    end;

    local procedure GetRequestedForFilter(ApproverExpenseUserNo: Code[20]) RequestedForFilter: Text
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        ExpenseApprovalSetup.SetCurrentKey("Approver No.");
        ExpenseApprovalSetup.SetRange("Approver No.", ApproverExpenseUserNo);
        RecRef.GetTable(ExpenseApprovalSetup);
        RequestedForFilter := SelectionFilterManagement.GetSelectionFilter(RecRef, ExpenseApprovalSetup.FieldNo("Expense User No."));

        ExpenseAgentSetup.GetRecordOnce();
        if ExpenseAgentSetup."Default Approver No." = ApproverExpenseUserNo then
            AppendDefaultSubmitters(RequestedForFilter);

        if StrLen(RequestedForFilter) > 2000 then
            Error(TooManyTravelRequestSubmittersErr, ApproverExpenseUserNo);
    end;

    local procedure AppendDefaultSubmitters(var RequestedForFilter: Text)
    var
        ExpenseUser: Record "Expense User";
        DefaultFilter: TextBuilder;
    begin
        if RequestedForFilter <> '' then
            DefaultFilter.Append(RequestedForFilter);

        ExpenseUser.SetAutoCalcFields("Approver No.");
        ExpenseUser.SetFilter("Approver No.", '%1', '');
        ExpenseUser.SetLoadFields("No.");
        if ExpenseUser.FindSet() then
            repeat
                if DefaultFilter.Length > 0 then
                    DefaultFilter.Append('|');
                DefaultFilter.Append(ExpenseUser."No.");
            until ExpenseUser.Next() = 0;

        RequestedForFilter := DefaultFilter.ToText();
    end;

    var
        AutomaticApprovalNotAllowedErr: Label 'Automatic travel request approval can be used only when the Expense Agent is disabled.';
        NotTravelRequestOwnerErr: Label 'Expense user %1 cannot submit travel request %2 because the user did not create it.', Comment = '%1 = Expense user number, %2 = Travel request number';
        NotTravelRequestApproverErr: Label 'Expense user %1 is not authorized to approve or reject travel request %2.', Comment = '%1 = Expense user number, %2 = Travel request number';
        TooManyTravelRequestSubmittersErr: Label 'Expense user %1 is configured to approve too many travel request submitters. Refine the approval setup before listing pending travel requests.', Comment = '%1 = Expense user number';
}
