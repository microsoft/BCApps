// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6901 "Expense Report Approval Mgmt"
{
    Access = Internal;
    Permissions = TableData "Expense User" = r;

    var
        ExpenseApprovalSetupDoesNotExistErr: Label '%1 does not exist with filters %2.', Comment = '%1 = Expense Approval Setup, %2 = Filters';
        SubmitConfirmQst: Label 'Do you want to Submit Expense Report?';
        ReopenConfirmQst: Label 'Do you want to Reopen submitted Expense Report?';
        ApproveConfirmQst: Label 'Do you want to approve submitted Expense Report?';
        RejectConfirmQst: Label 'Do you want to reject submitted Expense Report?';
        ReopenApprovedConfirmQst: Label 'Do you want to reopen approved Expense Report?';
        NoExpenseReportLinesToProcessErr: Label 'There are no Expense Report Lines to process in %1 action.', Comment = '%1 = Action';
        NotAuthorizedToOpenExpReportErr: Label 'You are not authorized to open expense reports. Please configure your %1 in the %2.', Comment = '%1 = Field Caption,%2 = Table Caption';
        ApproverMustBeEnabledInExpenseUserErr: Label '%1 must be enabled to approve or reject expense reports in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';
        UserIdForApprovalMustNotBeBlankInExpenseUserErr: Label '%1 must not be blank in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';

    procedure ProcessAction(var ExpenseReportHeader: Record "Expense Report Header"; ActionType: Enum "Expense Approval Action")
    begin
        case ActionType of
            ActionType::Submit:
                Submit(ExpenseReportHeader);
            ActionType::"Reopen Submitted":
                ReopenSubmitted(ExpenseReportHeader);
            ActionType::Approve:
                Approve(ExpenseReportHeader);
            ActionType::"Reopen Approved":
                ReopenApproved(ExpenseReportHeader);
            ActionType::Reject:
                Reject(ExpenseReportHeader);
        end;
    end;

    procedure FilterExpenseReports(var ExpenseReportHeader: Record "Expense Report Header"; FieldNo: Integer)
    begin
        ExpenseReportHeader.FilterGroup(2);

        case FieldNo of
            ExpenseReportHeader.FieldNo("Created By"):
                ExpenseReportHeader.SetRange("Created By", UserId);
            ExpenseReportHeader.FieldNo("Approver Expense User ID"):
                ExpenseReportHeader.SetRange("Approver Expense User ID", UserId);
        end;

        ExpenseReportHeader.FilterGroup(0);
    end;

    procedure CanPerformApprovalAction(var ExpenseReportHeader: Record "Expense Report Header"; ActionType: Enum "Expense Approval Action"): Boolean
    begin
        case ActionType of
            ActionType::Submit:
                exit(ExpenseReportHeader.Status = ExpenseReportHeader.Status::Released);
            ActionType::"Reopen Submitted":
                exit((ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval") or (ExpenseReportHeader.Status = ExpenseReportHeader.Status::Rejected));
            ActionType::Reject,
            ActionType::Approve:
                exit(ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval");
            ActionType::"Reopen Approved":
                exit((ExpenseReportHeader.Status = ExpenseReportHeader.Status::Approved) or (ExpenseReportHeader.Status = ExpenseReportHeader.Status::Rejected));
        end;
    end;

    procedure Submit(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseUser: Record "Expense User";
        IsResubmission: Boolean;
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval" then
            exit;

        IsResubmission := ExpenseReportHeader."Submission DateTime" <> 0DT;
        ExpenseUser.Get(GetExpenseUserNo());
        ExpenseReportHeader.TestApprovalStatus();

        ExpenseReportHeader.UpdateApproverID();

        SetApprovalStatusToPendingApprovalInExpenseReport(ExpenseReportHeader, ExpenseUser."No.", ExpenseUser."User Id For Approvals");
        LogExpenseReportSubmission(ExpenseReportHeader, ExpenseUser."No.", IsResubmission);
    end;

    internal procedure Submit(var ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20])
    var
        ExpenseUser: Record "Expense User";
        IsResubmission: Boolean;
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval" then
            exit;

        IsResubmission := ExpenseReportHeader."Submission DateTime" <> 0DT;
        ExpenseUser.Get(SubmitterExpenseUserNo);
        ExpenseReportHeader.TestApprovalStatus();

        ExpenseReportHeader.UpdateApproverID();

        SetApprovalStatusToPendingApprovalInExpenseReport(ExpenseReportHeader, SubmitterExpenseUserNo, ExpenseUser."User Id For Approvals");
        LogExpenseReportSubmission(ExpenseReportHeader, SubmitterExpenseUserNo, IsResubmission);
    end;

    procedure ReopenSubmitted(var ExpenseReportHeader: Record "Expense Report Header")
    var
        SubmitterExpenseUserNo: Code[20];
        IsRecall: Boolean;
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::Open then
            exit;

        IsRecall := ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval";
        if IsRecall then
            SubmitterExpenseUserNo := GetExpenseUserNo();

        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Open;
        ExpenseReportHeader.Modify(true);
        if IsRecall then
            LogExpenseReportRecalled(ExpenseReportHeader, SubmitterExpenseUserNo);
    end;

    procedure ReopenApproved(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ApproverExpenseUserNo: Code[20];
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval" then
            exit;

        CheckApproverPermissions(ExpenseReportHeader);
        ApproverExpenseUserNo := GetExpenseUserNo();
        ReopenApprovedAfterAuthorization(ExpenseReportHeader, ApproverExpenseUserNo);
    end;

    local procedure ReopenApprovedAfterAuthorization(
        var ExpenseReportHeader: Record "Expense Report Header";
        ApproverExpenseUserNo: Code[20]
    )
    begin
        ExpenseReportHeader.UpdateApproverID();
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::"Pending Approval";
        ExpenseReportHeader.Modify(true);
        LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::ReopenedByApprover,
            Enum::"Expense Activity Actor Role"::Approver,
            ApproverExpenseUserNo,
            '');
    end;

    procedure Reject(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ApproverExpenseUserNo: Code[20];
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::Rejected then
            exit;

        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::"Pending Approval");
        CheckApproverPermissions(ExpenseReportHeader);
        ApproverExpenseUserNo := GetExpenseUserNo();

        SetApprovalStatusInExpenseReport(ExpenseReportHeader, ExpenseReportHeader.Status::Rejected, ApproverExpenseUserNo, CopyStr(UserId(), 1, 50));
        LogExpenseReportRejected(ExpenseReportHeader, ApproverExpenseUserNo, '');
    end;

    internal procedure Reject(var ExpenseReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        ExpenseUser: Record "Expense User";
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::Rejected then
            exit;

        ExpenseUser.Get(ApproverExpenseUserNo);
        CheckApproverPermissions(ExpenseUser);

        UpdateApproverComment(ExpenseReportHeader, RejectReason);
        SetApprovalStatusInExpenseReport(ExpenseReportHeader, ExpenseReportHeader.Status::Rejected, ApproverExpenseUserNo, ExpenseUser."User Id For Approvals");
        LogExpenseReportRejected(ExpenseReportHeader, ApproverExpenseUserNo, RejectReason);
    end;

    procedure Approve(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ApproverExpenseUserNo: Code[20];
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::Approved then
            exit;

        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::"Pending Approval");
        CheckApproverPermissions(ExpenseReportHeader);
        ApproverExpenseUserNo := GetExpenseUserNo();

        SetApprovalStatusInExpenseReport(ExpenseReportHeader, ExpenseReportHeader.Status::Approved, ApproverExpenseUserNo, CopyStr(UserId(), 1, 50));
        LogExpenseReportApproved(ExpenseReportHeader, ApproverExpenseUserNo);
    end;

    internal procedure Approve(var ExpenseReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20])
    var
        ExpenseUser: Record "Expense User";
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::Approved then
            exit;

        ExpenseUser.Get(ApproverExpenseUserNo);
        CheckApproverPermissions(ExpenseUser);

        SetApprovalStatusInExpenseReport(ExpenseReportHeader, ExpenseReportHeader.Status::Approved, ApproverExpenseUserNo, ExpenseUser."User Id For Approvals");
        LogExpenseReportApproved(ExpenseReportHeader, ApproverExpenseUserNo);
    end;

    local procedure SetApprovalStatusInExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportStatus: Enum "Expense Report Status"; ApproverExpenseUserNo: Code[20]; ApproverUserId: Code[50])
    begin
        ExpenseReportHeader.Status := ExpenseReportStatus;
        ExpenseReportHeader."Approved/Rejected By" := ApproverUserId;
        ExpenseReportHeader."Approved/Rejected Exp.User No." := ApproverExpenseUserNo;
        ExpenseReportHeader."Approved/Rejected DateTime" := CurrentDateTime();
        ExpenseReportHeader.Modify(true);
    end;

    local procedure SetApprovalStatusToPendingApprovalInExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20]; SubmitterUserId: Code[50])
    begin
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::"Pending Approval";
        ExpenseReportHeader."Submission DateTime" := CurrentDateTime();
        ExpenseReportHeader."Submitter Expense User No." := SubmitterExpenseUserNo;
        ExpenseReportHeader."Submitter Expense User Id" := SubmitterUserId;
        ExpenseReportHeader.Modify(true);
    end;

    local procedure UpdateApproverComment(var ExpenseReportHeader: Record "Expense Report Header"; Comment: Text)
    var
        OutStream: OutStream;
    begin
        ExpenseReportHeader."Approver Comment".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Comment);
        ExpenseReportHeader.Modify(true);
    end;

    local procedure LogExpenseReportSubmission(ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20]; IsResubmission: Boolean)
    var
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EventType: Enum "Expense Activity Event Type";
    begin
        // Start tracking with the earlier Created event, including reports first acted on after upgrade.
        if not ExpenseActivityLogMgt.HasEntriesForSource(Database::"Expense Report Header", ExpenseReportHeader.SystemId) then
            ExpenseActivityLogMgt.LogExpenseReportCreatedEvent(ExpenseReportHeader);

        if IsResubmission then
            EventType := EventType::Resubmitted
        else
            EventType := EventType::Submitted;

        ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            EventType,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            SubmitterExpenseUserNo,
            '');
    end;

    local procedure LogExpenseReportEvent(
        ExpenseReportHeader: Record "Expense Report Header";
        EventType: Enum "Expense Activity Event Type";
        ActorRole: Enum "Expense Activity Actor Role";
        ActorExpenseUserNo: Code[20];
        EventComment: Text
    )
    var
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            EventType,
            Enum::"Expense Activity Initiator"::User,
            ActorRole,
            ActorExpenseUserNo,
            EventComment);
    end;

    local procedure LogExpenseReportApproved(ExpenseReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20])
    begin
        LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Approved,
            Enum::"Expense Activity Actor Role"::Approver,
            ApproverExpenseUserNo,
            '');
    end;

    local procedure LogExpenseReportRejected(ExpenseReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    begin
        LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Rejected,
            Enum::"Expense Activity Actor Role"::Approver,
            ApproverExpenseUserNo,
            RejectReason);
    end;

    local procedure LogExpenseReportRecalled(ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20])
    begin
        LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Recalled,
            Enum::"Expense Activity Actor Role"::Submitter,
            SubmitterExpenseUserNo,
            '');
    end;

    internal procedure NoExpenseLinesToProcess(ExpenseApprovalAction: Enum "Expense Approval Action")
    begin
        if not GuiAllowed() then
            exit;

        Error(NoExpenseReportLinesToProcessErr, ExpenseApprovalAction);
    end;

    internal procedure GetExpenseUserNo(): Code[20]
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.SetRange("User Id For Approvals", UserId());
        if not ExpenseUser.FindFirst() then
            Error(NotAuthorizedToOpenExpReportErr, ExpenseUser.FieldCaption("User Id For Approvals"), ExpenseUser.TableCaption());

        exit(ExpenseUser."No.");
    end;

    local procedure CheckApproverPermissions(ExpenseUser: Record "Expense User")
    begin
        if not ExpenseUser."Can Approve" then
            Error(ApproverMustBeEnabledInExpenseUserErr, ExpenseUser.FieldCaption("Can Approve"), ExpenseUser.TableCaption());

        if ExpenseUser."User Id For Approvals" = '' then
            Error(UserIdForApprovalMustNotBeBlankInExpenseUserErr, ExpenseUser.FieldCaption("User Id For Approvals"), ExpenseUser.TableCaption());
    end;

    local procedure CheckApproverPermissions(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseUser.SetRange("User Id For Approvals", UserId());
        if not ExpenseUser.FindFirst() then
            Error(NotAuthorizedToOpenExpReportErr, ExpenseUser.FieldCaption("User Id For Approvals"), ExpenseUser.TableCaption());

        if ExpenseUser."Can Approve" then
            exit;

        ExpenseAgentSetup.GetRecordOnce();
        if ExpenseAgentSetup."Default Approver No." = ExpenseUser."No." then
            exit;

        ExpenseApprovalSetup.SetRange("Approver No.", ExpenseUser."No.");
        ExpenseApprovalSetup.SetRange("Expense User No.", ExpenseReportHeader."Expense User No.");
        if ExpenseApprovalSetup.IsEmpty() then
            Error(ExpenseApprovalSetupDoesNotExistErr, ExpenseApprovalSetup.TableCaption(), ExpenseApprovalSetup.GetFilters());
    end;

    procedure ConfirmAction(ActionType: Enum "Expense Approval Action"): Boolean
    begin
        exit(Confirm(GetConfirmInstructions(ActionType)));
    end;

    local procedure GetConfirmInstructions(ActionType: Enum "Expense Approval Action"): Text
    begin
        case ActionType of
            ActionType::Submit:
                exit(SubmitConfirmQst);
            ActionType::"Reopen Submitted":
                exit(ReopenConfirmQst);
            ActionType::"Reopen Approved":
                exit(ReopenApprovedConfirmQst);
            ActionType::Approve:
                exit(ApproveConfirmQst);
            ActionType::Reject:
                exit(RejectConfirmQst);
        end;
    end;
}