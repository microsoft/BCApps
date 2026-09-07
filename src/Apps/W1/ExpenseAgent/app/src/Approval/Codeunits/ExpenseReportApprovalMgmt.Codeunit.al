// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.Security.User;

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
        NotAuthorizedToRecallExpReportErr: Label 'Only the original submitter or a user with %1 can recall a submitted expense report.', Comment = '%1 = User Setup field caption';
        ApproverMustBeEnabledInExpenseUserErr: Label '%1 must be enabled to approve or reject expense reports in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';
        UserIdForApprovalMustNotBeBlankInExpenseUserErr: Label '%1 must not be blank in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';
        InterimApproverAgentRequiredErr: Label 'An interim approver can only be assigned when the agent is enabled in %1.', Comment = '%1 = Expense Agent Setup table caption';
        InterimApproverStatusErr: Label 'You can only assign an interim approver while the expense report is %1.', Comment = '%1 = Pending Approval status caption';
        InterimApproverRequiredErr: Label 'Select an interim approver from the available approvers.';
        InterimApproverConflictErr: Label 'The %1 cannot be the same as the %2 (value: %3).', Comment = '%1 = Interim Approver No. caption, %2 = conflicting field caption, %3 = conflicting field value';
        InterimApproverCannotFinalizeErr: Label '%1 %2 cannot give final approval. Final approval must be completed by a different approver.', Comment = '%1 = Interim Approver No. caption, %2 = Interim Approver No.';
        ActorNotActiveApproverErr: Label 'This expense report is awaiting approval from %1. Only that approver can approve or reject it.', Comment = '%1 = Expense User No. of the approver the report is currently assigned to';
        InterimApproverActorErr: Label 'Only the expense report owner %1 can assign an interim approver.', Comment = '%1 = Expense User No. of the report owner';
        InterimApproverAssignedCommentTxt: Label 'Interim approver set to %1 (%2).', Comment = '%1 = Interim Approver No., %2 = Interim Approver Name';

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
                exit((ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval") or (ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Interim Approved") or (ExpenseReportHeader.Status = ExpenseReportHeader.Status::Rejected));
            ActionType::Reject,
            ActionType::Approve:
                exit((ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval") or (ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Interim Approved"));
            ActionType::"Reopen Approved":
                exit((ExpenseReportHeader.Status = ExpenseReportHeader.Status::Approved) or (ExpenseReportHeader.Status = ExpenseReportHeader.Status::Rejected));
        end;
    end;

    procedure Submit(var ExpenseReportHeader: Record "Expense Report Header")
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::"Pending Approval" then
            exit;

        Submit(ExpenseReportHeader, GetExpenseUserNo(), '');
    end;

    internal procedure Submit(var ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20])
    begin
        Submit(ExpenseReportHeader, SubmitterExpenseUserNo, '');
    end;

    internal procedure Submit(var ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20]; SubmissionComment: Text)
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
        ExpenseReportHeader."Final Approver No." := ExpenseReportHeader."Approver Expense User No.";
        RouteToInterimIfAssigned(ExpenseReportHeader);

        UpdateSubmitterComment(ExpenseReportHeader, SubmissionComment);
        SetApprovalStatusToPendingApprovalInExpenseReport(ExpenseReportHeader, SubmitterExpenseUserNo, ExpenseUser."User Id For Approvals");
        LogExpenseReportSubmission(ExpenseReportHeader, SubmitterExpenseUserNo, IsResubmission, SubmissionComment);
    end;

    procedure ReopenSubmitted(var ExpenseReportHeader: Record "Expense Report Header")
    var
        SubmitterExpenseUserNo: Code[20];
        RecallActorRole: Enum "Expense Activity Actor Role";
        IsRecall: Boolean;
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::Open then
            exit;

        IsRecall := ExpenseReportHeader.Status in [ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status::"Interim Approved"];
        if IsRecall then begin
            RecallActorRole := GetRecallActorRole(ExpenseReportHeader);
            SubmitterExpenseUserNo := ExpenseReportHeader."Submitter Expense User No.";
        end;

        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Open;
        ExpenseReportHeader.Modify(true);
        if IsRecall then
            if RecallActorRole = RecallActorRole::Administrator then
                LogExpenseReportRecalledByAdministrator(ExpenseReportHeader)
            else
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
        ExpenseReportHeader."Final Approver No." := ExpenseReportHeader."Approver Expense User No.";
        RouteToInterimIfAssigned(ExpenseReportHeader);
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

        ExpenseReportHeader.TestApprovalPending();
        CheckApproverPermissions(ExpenseReportHeader);
        ApproverExpenseUserNo := GetExpenseUserNo();
        CheckActorIsNotInterimApprover(ExpenseReportHeader, ApproverExpenseUserNo);
        CheckActorIsActiveApprover(ExpenseReportHeader, ApproverExpenseUserNo);

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
        CheckActorIsNotInterimApprover(ExpenseReportHeader, ApproverExpenseUserNo);
        CheckActorIsActiveApprover(ExpenseReportHeader, ApproverExpenseUserNo);

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

        ExpenseReportHeader.TestApprovalPending();
        CheckApproverPermissions(ExpenseReportHeader);
        ApproverExpenseUserNo := GetExpenseUserNo();
        CheckActorIsNotInterimApprover(ExpenseReportHeader, ApproverExpenseUserNo);
        CheckActorIsActiveApprover(ExpenseReportHeader, ApproverExpenseUserNo);

        if ShouldRouteToFinalApprover(ExpenseReportHeader) then begin
            RouteToFinalApprover(ExpenseReportHeader, ApproverExpenseUserNo);
            exit;
        end;

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
        CheckActorIsNotInterimApprover(ExpenseReportHeader, ApproverExpenseUserNo);
        CheckActorIsActiveApprover(ExpenseReportHeader, ApproverExpenseUserNo);

        if ShouldRouteToFinalApprover(ExpenseReportHeader) then begin
            RouteToFinalApprover(ExpenseReportHeader, ApproverExpenseUserNo);
            exit;
        end;

        SetApprovalStatusInExpenseReport(ExpenseReportHeader, ExpenseReportHeader.Status::Approved, ApproverExpenseUserNo, ExpenseUser."User Id For Approvals");
        LogExpenseReportApproved(ExpenseReportHeader, ApproverExpenseUserNo);
    end;

    internal procedure AssignInterimApprover(var ExpenseReportHeader: Record "Expense Report Header"; NewApproverExpenseUserNo: Code[20]; ActorExpenseUserNo: Code[20])
    var
        InterimApprover: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if not ExpenseAgentSetup."Enable Agent" then
            Error(InterimApproverAgentRequiredErr, ExpenseAgentSetup.TableCaption());

        if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::"Pending Approval" then
            Error(InterimApproverStatusErr, Format(ExpenseReportHeader.Status::"Pending Approval"));

        if NewApproverExpenseUserNo = '' then
            Error(InterimApproverRequiredErr);

        if NewApproverExpenseUserNo = ExpenseReportHeader."Expense User No." then
            Error(InterimApproverConflictErr, ExpenseReportHeader.FieldCaption("Interim Approver No."), ExpenseReportHeader.FieldCaption("Expense User No."), ExpenseReportHeader."Expense User No.");

        if NewApproverExpenseUserNo = ExpenseReportHeader."Final Approver No." then
            Error(InterimApproverConflictErr, ExpenseReportHeader.FieldCaption("Interim Approver No."), ExpenseReportHeader.FieldCaption("Final Approver No."), ExpenseReportHeader."Final Approver No.");

        if (ActorExpenseUserNo <> '') and (ActorExpenseUserNo <> ExpenseReportHeader."Expense User No.") then
            Error(InterimApproverActorErr, ExpenseReportHeader."Expense User No.");

        InterimApprover.Get(NewApproverExpenseUserNo);
        CheckApproverPermissions(InterimApprover);

        SetInterimApproverInExpenseReport(ExpenseReportHeader, InterimApprover);
        LogInterimApproverAssigned(ExpenseReportHeader, InterimApprover, ActorExpenseUserNo);
    end;

    local procedure SetInterimApproverInExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; InterimApprover: Record "Expense User")
    begin
        ExpenseReportHeader."Interim Approver No." := InterimApprover."No.";
        ExpenseReportHeader."Approver Expense User No." := InterimApprover."No.";
        ExpenseReportHeader."Approver Expense User ID" := InterimApprover."User Id For Approvals";
        ExpenseReportHeader.Modify(true);
    end;

    local procedure LogInterimApproverAssigned(ExpenseReportHeader: Record "Expense Report Header"; InterimApprover: Record "Expense User"; ActorExpenseUserNo: Code[20])
    var
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        LogComment: Text;
    begin
        LogComment := StrSubstNo(InterimApproverAssignedCommentTxt, InterimApprover."No.", InterimApprover.Name);
        if ActorExpenseUserNo <> '' then
            LogExpenseReportEvent(
                ExpenseReportHeader,
                Enum::"Expense Activity Event Type"::InterimApproverAssigned,
                Enum::"Expense Activity Actor Role"::Submitter,
                ActorExpenseUserNo,
                LogComment)
        else
            ExpenseActivityLogMgt.LogExpenseReportEventByBCUser(
                ExpenseReportHeader,
                Enum::"Expense Activity Event Type"::InterimApproverAssigned,
                Enum::"Expense Activity Actor Role"::Submitter,
                LogComment);
    end;

    local procedure IsApproverEligible(ExpenseUser: Record "Expense User"): Boolean
    begin
        exit(ExpenseUser."Can Approve" and (ExpenseUser."User Id For Approvals" <> ''));
    end;

    // Restarts the two-stage flow at a still-assigned interim on resubmit or reopen (no-op when no interim is set).
    local procedure RouteToInterimIfAssigned(var ExpenseReportHeader: Record "Expense Report Header")
    var
        InterimApprover: Record "Expense User";
    begin
        if ExpenseReportHeader."Interim Approver No." = '' then
            exit;

        if ExpenseReportHeader."Interim Approver No." = ExpenseReportHeader."Final Approver No." then
            exit;

        InterimApprover.Get(ExpenseReportHeader."Interim Approver No.");
        if not IsApproverEligible(InterimApprover) then
            exit; // interim no longer qualifies; leave the final approver as the active approver

        ExpenseReportHeader."Approver Expense User No." := InterimApprover."No.";
        ExpenseReportHeader."Approver Expense User ID" := InterimApprover."User Id For Approvals";
    end;

    local procedure ShouldRouteToFinalApprover(ExpenseReportHeader: Record "Expense Report Header"): Boolean
    begin
        exit(
            (ExpenseReportHeader."Interim Approver No." <> '') and
            (ExpenseReportHeader."Approver Expense User No." = ExpenseReportHeader."Interim Approver No.") and
            (ExpenseReportHeader."Final Approver No." <> '') and
            (ExpenseReportHeader."Final Approver No." <> ExpenseReportHeader."Interim Approver No."));
    end;

    local procedure RouteToFinalApprover(var ExpenseReportHeader: Record "Expense Report Header"; InterimApproverExpenseUserNo: Code[20])
    var
        FinalApprover: Record "Expense User";
    begin
        FinalApprover.Get(ExpenseReportHeader."Final Approver No.");
        CheckApproverPermissions(FinalApprover);
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::"Interim Approved";
        ExpenseReportHeader."Approver Expense User No." := FinalApprover."No.";
        ExpenseReportHeader."Approver Expense User ID" := FinalApprover."User Id For Approvals";
        ExpenseReportHeader.Modify(true);
        LogInterimApproved(ExpenseReportHeader, InterimApproverExpenseUserNo);
    end;

    local procedure LogInterimApproved(ExpenseReportHeader: Record "Expense Report Header"; InterimApproverExpenseUserNo: Code[20])
    begin
        LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::InterimApproved,
            Enum::"Expense Activity Actor Role"::Approver,
            InterimApproverExpenseUserNo,
            '');
    end;

    local procedure CheckActorIsNotInterimApprover(ExpenseReportHeader: Record "Expense Report Header"; ActingApproverExpenseUserNo: Code[20])
    begin
        if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::"Interim Approved" then
            exit;

        if ActingApproverExpenseUserNo = '' then
            exit;

        if ActingApproverExpenseUserNo = ExpenseReportHeader."Interim Approver No." then
            Error(InterimApproverCannotFinalizeErr, ExpenseReportHeader.FieldCaption("Interim Approver No."), ExpenseReportHeader."Interim Approver No.");
    end;

    local procedure CheckActorIsActiveApprover(ExpenseReportHeader: Record "Expense Report Header"; ActingApproverExpenseUserNo: Code[20])
    begin
        if ExpenseReportHeader."Interim Approver No." = '' then
            exit;

        if ActingApproverExpenseUserNo = '' then
            exit;

        if ActingApproverExpenseUserNo <> ExpenseReportHeader."Approver Expense User No." then
            Error(ActorNotActiveApproverErr, ExpenseReportHeader."Approver Expense User No.");
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
        Clear(ExpenseReportHeader."Approver Comment");
        ExpenseReportHeader."Approver Comment".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Comment);
    end;

    local procedure UpdateSubmitterComment(var ExpenseReportHeader: Record "Expense Report Header"; Comment: Text)
    var
        OutStream: OutStream;
    begin
        Clear(ExpenseReportHeader."Submitter Comment");
        ExpenseReportHeader."Submitter Comment".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Comment);
    end;

    local procedure LogExpenseReportSubmission(ExpenseReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20]; IsResubmission: Boolean; EventComment: Text)
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
            EventComment);
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

    local procedure LogExpenseReportRecalledByAdministrator(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        ExpenseActivityLogMgt.LogExpenseReportEventByBCUser(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Recalled,
            Enum::"Expense Activity Actor Role"::Administrator,
            '');
    end;

    local procedure GetRecallActorRole(ExpenseReportHeader: Record "Expense Report Header"): Enum "Expense Activity Actor Role"
    var
        UserSetup: Record "User Setup";
    begin
        if ExpenseReportHeader."Submitter Expense User Id" = UserId() then
            exit(Enum::"Expense Activity Actor Role"::Submitter);

        UserSetup.SetLoadFields("Unlimited Expense Approval");
        if UserSetup.Get(UserId()) and UserSetup."Unlimited Expense Approval" then
            exit(Enum::"Expense Activity Actor Role"::Administrator);

        Error(NotAuthorizedToRecallExpReportErr, UserSetup.FieldCaption("Unlimited Expense Approval"));
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