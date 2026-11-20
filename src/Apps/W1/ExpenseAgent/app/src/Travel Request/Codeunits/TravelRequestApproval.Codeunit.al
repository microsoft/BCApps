// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using System.Security.AccessControl;
using System.Telemetry;

codeunit 7133 "Travel Request Approval"
{
    Access = Internal;
    Permissions = tabledata User = r,
                  tabledata "Spend Request" = rm,
                  tabledata Traveler = r,
                  tabledata "Expense Report Header" = ri,
                  tabledata "Posted Expense Report Header" = r,
                  tabledata "Posted Expense Report Line" = r;

    /// <summary>
    /// Runs an approval action on a travel request on behalf of the current Business Central user.
    /// </summary>
    internal procedure ProcessAction(var SpendRequest: Record "Spend Request"; ActionType: Enum "Expense Approval Action")
    begin
        case ActionType of
            ActionType::Submit:
                Submit(SpendRequest);
            ActionType::"Reopen Submitted":
                ReopenSubmitted(SpendRequest);
            ActionType::Approve:
                Approve(SpendRequest);
            ActionType::"Reopen Approved":
                ReopenApproved(SpendRequest);
            ActionType::Reject:
                Reject(SpendRequest);
        end;
    end;

    internal procedure CanPerformApprovalAction(SpendRequest: Record "Spend Request"; ActionType: Enum "Expense Approval Action"): Boolean
    begin
        if SpendRequest."Document Type" <> SpendRequest."Document Type"::"Travel Request" then
            exit(false);

        case ActionType of
            ActionType::Submit:
                exit(SpendRequest.Status = SpendRequest.Status::Open);
            ActionType::"Reopen Submitted",
            ActionType::Approve,
            ActionType::Reject:
                exit(SpendRequest.Status = SpendRequest.Status::Released);
            ActionType::"Reopen Approved":
                exit(SpendRequest.Status = SpendRequest.Status::Approved);
        end;
    end;

    internal procedure ConfirmAction(ActionType: Enum "Expense Approval Action"): Boolean
    begin
        exit(Confirm(GetConfirmInstructions(ActionType)));
    end;

    /// <summary>
    /// Submits a travel request for approval on behalf of the current Business Central user.
    /// </summary>
    internal procedure Submit(var SpendRequest: Record "Spend Request")
    var
        ExpenseUser: Record "Expense User";
    begin
        if SpendRequest.Status = SpendRequest.Status::Released then
            exit;

        GetCurrentExpenseUser(ExpenseUser);
        Submit(SpendRequest, ExpenseUser."No.", '');
    end;

    /// <summary>
    /// Approves a travel request on behalf of the current Business Central user.
    /// </summary>
    internal procedure Approve(var SpendRequest: Record "Spend Request")
    var
        ExpenseUser: Record "Expense User";
    begin
        if SpendRequest.Status = SpendRequest.Status::Approved then
            exit;

        GetCurrentExpenseUser(ExpenseUser);
        Approve(SpendRequest, ExpenseUser."No.");
    end;

    /// <summary>
    /// Rejects a travel request on behalf of the current Business Central user.
    /// </summary>
    internal procedure Reject(var SpendRequest: Record "Spend Request")
    var
        ExpenseUser: Record "Expense User";
    begin
        GetCurrentExpenseUser(ExpenseUser);
        Reject(SpendRequest, ExpenseUser."No.", '');
    end;

    /// <summary>
    /// Recalls a submitted travel request on behalf of the current Business Central user.
    /// The owner of the travel request or an approval administrator can recall it.
    /// </summary>
    internal procedure ReopenSubmitted(var SpendRequest: Record "Spend Request")
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        if SpendRequest.Status = SpendRequest.Status::Open then
            exit;

        CheckTravelRequest(SpendRequest);
        CheckPendingApproval(SpendRequest);
        if FindCurrentExpenseUser(ExpenseUser) then
            if IsTravelRequestOwner(SpendRequest, ExpenseUser."No.") then begin
                Recall(SpendRequest, ExpenseUser."No.");
                exit;
            end;

        if not ExpenseReportApprovalMgmt.IsApprovalAdministrator() then
            Error(NotAuthorizedToRecallTravelRequestErr, ExpenseUser.FieldCaption("Unlimited Approval"));

        ReopenForRecall(SpendRequest);
        LogTravelRequestEvent(SpendRequest, Enum::"Expense Activity Event Type"::Recalled, Enum::"Expense Activity Actor Role"::Administrator, '', '');
    end;

    /// <summary>
    /// Reopens an approved travel request for a new approval on behalf of the current Business Central user.
    /// </summary>
    internal procedure ReopenApproved(var SpendRequest: Record "Spend Request")
    var
        ExpenseUser: Record "Expense User";
    begin
        if SpendRequest.Status = SpendRequest.Status::Released then
            exit;

        GetCurrentExpenseUser(ExpenseUser);
        ReopenApproved(SpendRequest, ExpenseUser."No.");
    end;

    /// <summary>
    /// Assigns the active alternate approver of the primary approver to a submitted travel request on behalf of the current Business Central user.
    /// </summary>
    internal procedure AssignAlternateApprover(var SpendRequest: Record "Spend Request")
    begin
        AssignAlternateApprover(SpendRequest, '');
    end;

    internal procedure Submit(var SpendRequest: Record "Spend Request"; SubmitterExpenseUserNo: Code[20])
    begin
        Submit(SpendRequest, SubmitterExpenseUserNo, '');
    end;

    /// <summary>
    /// Submits a travel request on behalf of an expense user with an optional submitter comment, for example a justification when resubmitting a rejected travel request.
    /// </summary>
    internal procedure Submit(var SpendRequest: Record "Spend Request"; SubmitterExpenseUserNo: Code[20]; SubmissionComment: Text)
    var
        Submitter: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
        IsResubmission: Boolean;
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Open);
        Submitter.Get(SubmitterExpenseUserNo);
        if Submitter."No." <> SpendRequest."Requested For" then
            Error(NotTravelRequestOwnerErr, SubmitterExpenseUserNo, SpendRequest."No.");

        IsResubmission := IsTravelRequestResubmission(SpendRequest);
        SpendRequest."Submitted By Expense User No." := SubmitterExpenseUserNo;
        SpendRequest."Submitted At" := CurrentDateTime();
        ClearPreviousDecision(SpendRequest);
        SpendRequest."Submitter Comment" := CopyStr(SubmissionComment, 1, MaxStrLen(SpendRequest."Submitter Comment"));
        SpendRequest.Modify();
        // Log before releasing so that an automatic approval raised by the release is ordered after the submission.
        LogTravelRequestSubmission(SpendRequest, SubmitterExpenseUserNo, IsResubmission, SubmissionComment);
        ReleaseSpendRequest.Release(SpendRequest);
        // Without the agent the release approves the request automatically, so only a request that waits for approval is routed.
        if SpendRequest.Status = SpendRequest.Status::Released then
            RouteForApproval(SpendRequest);
        FeatureTelemetry.LogUsage('0000VEY', ExpenseAgentSetup.GetFeatureName(), TravelRequestSubmittedLbl);
    end;

    /// <summary>
    /// Starts a new approval for an open travel request released from the Business Central client, like a submission without a comment.
    /// The decision and the submitter comment of an earlier approval, for example a rejection, are cleared.
    /// </summary>
    internal procedure PrepareManualRelease(var SpendRequest: Record "Spend Request")
    begin
        if SpendRequest."Document Type" <> SpendRequest."Document Type"::"Travel Request" then
            exit;
        if SpendRequest.Status <> SpendRequest.Status::Open then
            exit;

        ClearPreviousDecision(SpendRequest);
        Clear(SpendRequest."Submitter Comment");
        SpendRequest.Modify();
    end;

    local procedure ClearPreviousDecision(var SpendRequest: Record "Spend Request")
    begin
        // A new approval starts, so no decision from an earlier rejection is kept.
        Clear(SpendRequest."Approved/Rejected At");
        Clear(SpendRequest."Approved/Rejected by User ID");
        Clear(SpendRequest."Approved/Rejected by User Name");
        Clear(SpendRequest."Approval Expense User No.");
        Clear(SpendRequest."Rejection Reason");
        ClearApprovalRouting(SpendRequest);
    end;

    internal procedure Approve(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        Approver: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Released);
        CheckApprover(SpendRequest, ApproverExpenseUserNo, Approver);
        CheckApproverApprovalLimit(SpendRequest, ApproverExpenseUserNo);
        SetDecisionUser(SpendRequest, Approver);
        ApproveInternal(SpendRequest, ApproverExpenseUserNo);
        FeatureTelemetry.LogUsage('0000VEZ', ExpenseAgentSetup.GetFeatureName(), TravelRequestApprovedLbl);
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

        // Without the agent there is no approver, so the user who released the request is recorded.
        SpendRequest."Approved/Rejected by User ID" := UserSecurityId();
        SpendRequest."Approved/Rejected by User Name" := CopyStr(UserId(), 1, MaxStrLen(SpendRequest."Approved/Rejected by User Name"));
        ApproveInternal(SpendRequest, '');
        FeatureTelemetry.LogUsage('0000VF0', ExpenseAgentSetup.GetFeatureName(), TravelRequestAutoApprovedLbl);
    end;

    local procedure ApproveInternal(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    begin
        SpendRequest.TestField("Requested For");
        SpendRequest.Status := SpendRequest.Status::Approved;
        SpendRequest."Approved/Rejected At" := CurrentDateTime();
        SpendRequest."Approval Expense User No." := ApproverExpenseUserNo;
        Clear(SpendRequest."Rejection Reason");
        SpendRequest.Modify();
        LogTravelRequestCreatedIfMissing(SpendRequest);
        LogTravelRequestApproved(SpendRequest, ApproverExpenseUserNo);
        CreateTravelerExpenseReports(SpendRequest);
    end;

    local procedure CreateTravelerExpenseReports(SpendRequest: Record "Spend Request")
    var
        Traveler: Record Traveler;
    begin
        CreateTravelerExpenseReport(SpendRequest, SpendRequest."Requested For");

        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Traveler.SetFilter("Expense User No.", '<>%1&<>%2', '', SpendRequest."Requested For");
        Traveler.SetLoadFields("Expense User No.");
        if Traveler.FindSet() then
            repeat
                CreateTravelerExpenseReport(SpendRequest, Traveler."Expense User No.");
            until Traveler.Next() = 0;
    end;

    local procedure CreateTravelerExpenseReport(SpendRequest: Record "Spend Request"; TravelerExpenseUserNo: Code[20])
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if ExpenseReportHeader.HasPostedTravelRequestReport(SpendRequest, TravelerExpenseUserNo) then
            exit;

        ExpenseReportHeader.CreateFromApprovedTravelRequestIfMissing(SpendRequest, TravelerExpenseUserNo);
        ExpenseReportHeader.Reset();
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.SetRange("Expense User No.", TravelerExpenseUserNo);
        if ExpenseReportHeader.IsEmpty() then begin
            FeatureTelemetry.LogError('0000VEX', ExpenseAgentSetup.GetFeatureName(), ExpenseReportCreationFailedLbl, ExpenseReportCreationFailedTelemetryErr);
            Error(GetExpenseReportWasNotCreatedError(SpendRequest, TravelerExpenseUserNo));
        end;
    end;

    /// <summary>
    /// Rejects a travel request and reopens it, so that the submitter can change and resubmit it, like a rejected expense report.
    /// The rejection reason and the approver are kept until the travel request is resubmitted.
    /// </summary>
    internal procedure Reject(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        Approver: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Released);
        CheckApprover(SpendRequest, ApproverExpenseUserNo, Approver);
        SpendRequest.Status := SpendRequest.Status::Rejected;
        SpendRequest."Approved/Rejected At" := CurrentDateTime();
        SetDecisionUser(SpendRequest, Approver);
        SpendRequest."Approval Expense User No." := ApproverExpenseUserNo;
        SpendRequest."Rejection Reason" := CopyStr(RejectReason, 1, MaxStrLen(SpendRequest."Rejection Reason"));
        SpendRequest.Modify();
        LogTravelRequestCreatedIfMissing(SpendRequest);
        ExpenseActivityLogMgt.LogTravelRequestEvent(
            SpendRequest,
            Enum::"Expense Activity Event Type"::Rejected,
            Enum::"Expense Activity Actor Role"::Approver,
            ApproverExpenseUserNo,
            RejectReason);
        // Reopened in the same transaction so the submitter can edit and resubmit without an extra call.
        ReleaseSpendRequest.Reopen(SpendRequest);
        ExpenseActivityLogMgt.LogTravelRequestEvent(
            SpendRequest,
            Enum::"Expense Activity Event Type"::ReopenedByApprover,
            Enum::"Expense Activity Actor Role"::Approver,
            ApproverExpenseUserNo,
            '');
        FeatureTelemetry.LogUsage('0000VF1', ExpenseAgentSetup.GetFeatureName(), TravelRequestRejectedLbl);
    end;

    /// <summary>
    /// Recalls a submitted travel request on behalf of its owner, so that it can be changed and resubmitted.
    /// </summary>
    internal procedure Recall(var SpendRequest: Record "Spend Request"; SubmitterExpenseUserNo: Code[20])
    begin
        CheckTravelRequest(SpendRequest);
        CheckPendingApproval(SpendRequest);
        if not IsTravelRequestOwner(SpendRequest, SubmitterExpenseUserNo) then
            Error(NotTravelRequestOwnerRecallErr, SubmitterExpenseUserNo, SpendRequest."No.");

        ReopenForRecall(SpendRequest);
        LogTravelRequestEvent(SpendRequest, Enum::"Expense Activity Event Type"::Recalled, Enum::"Expense Activity Actor Role"::Submitter, SubmitterExpenseUserNo, '');
    end;

    /// <summary>
    /// Reopens an approved travel request for a new approval. The approver is assigned again from the approval setup, the approval limits, and active alternate approvers.
    /// </summary>
    internal procedure ReopenApproved(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        Approver: Record "Expense User";
    begin
        if SpendRequest.Status = SpendRequest.Status::Released then
            exit;

        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Approved);
        CheckApproverPermissions(ApproverExpenseUserNo, Approver);
        SpendRequest.CalcFields("Total Spent Amount (LCY)");
        if SpendRequest."Total Spent Amount (LCY)" <> 0 then
            Error(ReopenApprovedWithExpensesErr, SpendRequest."No.");

        ClearPreviousDecision(SpendRequest);
        SpendRequest.Status := SpendRequest.Status::Released;
        RouteForApproval(SpendRequest);
        LogTravelRequestEvent(SpendRequest, Enum::"Expense Activity Event Type"::ReopenedByApprover, Enum::"Expense Activity Actor Role"::Approver, ApproverExpenseUserNo, '');
    end;

    /// <summary>
    /// Assigns the active alternate approver of the primary approver to a submitted travel request.
    /// When an actor is given, only the owner of the travel request can assign the alternate approver.
    /// </summary>
    internal procedure AssignAlternateApprover(var SpendRequest: Record "Spend Request"; ActorExpenseUserNo: Code[20])
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        AlternateApproverExpenseUserNo: Code[20];
    begin
        CheckTravelRequest(SpendRequest);
        CheckAlternateApproverStatus(SpendRequest);
        CheckAlternateApproverActor(SpendRequest, ActorExpenseUserNo);
        EnsureApprovalRouted(SpendRequest);

        AlternateApproverExpenseUserNo := ExpenseReportApprovalMgmt.GetActiveAlternateApproverNo(GetPrimaryApproverNo(SpendRequest), WorkDate());
        if AlternateApproverExpenseUserNo = '' then
            Error(NoActiveAlternateApproverForDateErr, GetPrimaryApproverNo(SpendRequest), WorkDate());

        // The active alternate approver can already be assigned, for example on submission.
        if (AlternateApproverExpenseUserNo = SpendRequest."Alternate Approver No.") and
           (AlternateApproverExpenseUserNo = SpendRequest."Approver Expense User No.")
        then
            exit;

        AssignAlternateApprover(SpendRequest, AlternateApproverExpenseUserNo, ActorExpenseUserNo);
    end;

    internal procedure AssignAlternateApprover(var SpendRequest: Record "Spend Request"; NewApproverExpenseUserNo: Code[20]; ActorExpenseUserNo: Code[20])
    var
        AlternateApprover: Record "Expense User";
    begin
        CheckTravelRequest(SpendRequest);
        CheckAlternateApproverStatus(SpendRequest);
        if NewApproverExpenseUserNo = '' then
            Error(AlternateApproverRequiredErr);

        CheckAlternateApproverActor(SpendRequest, ActorExpenseUserNo);
        EnsureApprovalRouted(SpendRequest);
        if (NewApproverExpenseUserNo = SpendRequest."Requested For") or
           (NewApproverExpenseUserNo = SpendRequest."Approver Expense User No.") or
           (NewApproverExpenseUserNo = GetPrimaryApproverNo(SpendRequest))
        then
            Error(AlternateApproverConflictErr);

        AlternateApprover.Get(NewApproverExpenseUserNo);
        CheckApproverPermissions(AlternateApprover);
        SetAlternateApprover(SpendRequest, AlternateApprover);
        SpendRequest.Modify();
        LogAlternateApproverAssigned(SpendRequest, AlternateApprover, ActorExpenseUserNo, GetAlternateAssignmentActorRole(SpendRequest, ActorExpenseUserNo));
    end;

    /// <summary>
    /// Returns a submitted travel request to its primary approver when the alternate coverage has ended,
    /// and assigns the alternate approver whose coverage is active today.
    /// </summary>
    internal procedure AssignActiveAlternateApproverForTravelRequest(var SpendRequest: Record "Spend Request")
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        AlternateApproverExpenseUserNo: Code[20];
    begin
        if SpendRequest."Document Type" <> SpendRequest."Document Type"::"Travel Request" then
            exit;
        if SpendRequest.Status <> SpendRequest.Status::Released then
            exit;

        EnsureApprovalRouted(SpendRequest);
        if SpendRequest."Approver Expense User No." = '' then
            exit;

        RevertEndedCoverage(SpendRequest);

        AlternateApproverExpenseUserNo := ExpenseReportApprovalMgmt.GetActiveAlternateApproverNo(GetPrimaryApproverNo(SpendRequest), WorkDate());
        if (AlternateApproverExpenseUserNo <> '') and
           (AlternateApproverExpenseUserNo <> SpendRequest."Approver Expense User No.") and
           (AlternateApproverExpenseUserNo <> SpendRequest."Requested For")
        then begin
            CheckAndAssignAlternateApproval(SpendRequest);
            SpendRequest.Modify();
        end;
    end;

    /// <summary>
    /// Clears the assigned approvers when a travel request is reopened, so that the next submission routes it again.
    /// </summary>
    internal procedure ClearApprovalRoutingOnReopen(var SpendRequest: Record "Spend Request")
    begin
        if SpendRequest."Document Type" <> SpendRequest."Document Type"::"Travel Request" then
            exit;
        if SpendRequest.Status <> SpendRequest.Status::Open then
            exit;
        if (SpendRequest."Approver Expense User No." = '') and
           (SpendRequest."Alternate Approver No." = '') and
           (SpendRequest."Primary Approver No." = '')
        then
            exit;

        ClearApprovalRouting(SpendRequest);
        SpendRequest.Modify();
    end;

    local procedure ReopenForRecall(var SpendRequest: Record "Spend Request")
    var
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        ReleaseSpendRequest.Reopen(SpendRequest);
    end;

    local procedure RouteForApproval(var SpendRequest: Record "Spend Request")
    begin
        SetApproverBasedOnApprovalLimit(SpendRequest);
        CheckAndAssignAlternateApproval(SpendRequest);
        SpendRequest.Modify();
    end;

    local procedure EnsureApprovalRouted(var SpendRequest: Record "Spend Request")
    var
        ApproverExpenseUserNo: Code[20];
    begin
        if SpendRequest."Approver Expense User No." <> '' then
            exit;

        // Requests released directly in the client, or before approval routing was introduced, keep the approver from the approval setup,
        // which is also the approver that the approver filter lists them for.
        ApproverExpenseUserNo := GetApproverExpenseUserNo(SpendRequest."Requested For");
        if ApproverExpenseUserNo = '' then
            exit;

        SpendRequest."Approver Expense User No." := ApproverExpenseUserNo;
        SpendRequest.Modify();
    end;

    local procedure ClearApprovalRouting(var SpendRequest: Record "Spend Request")
    begin
        Clear(SpendRequest."Approver Expense User No.");
        Clear(SpendRequest."Alternate Approver No.");
        Clear(SpendRequest."Primary Approver No.");
    end;

    local procedure SetApproverBasedOnApprovalLimit(var SpendRequest: Record "Spend Request")
    var
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        ApproverExpenseUserNo: Code[20];
        NextApproverNo: Code[20];
        ProcessedApproverNos: List of [Code[20]];
    begin
        SpendRequest.TestField("Requested For");
        ClearApprovalRouting(SpendRequest);

        if CanOwnerApproveOwnRequest(SpendRequest) then
            ApproverExpenseUserNo := SpendRequest."Requested For"
        else
            ApproverExpenseUserNo := GetApproverExpenseUserNo(SpendRequest."Requested For");
        if ApproverExpenseUserNo = '' then
            Error(NoApproverConfiguredErr, SpendRequest."No.", SpendRequest."Requested For");

        ApproverExpenseUser.Get(ApproverExpenseUserNo);
        while not ApproverExpenseUser."Unlimited Approval" and (SpendRequest."Total Expected Amount (LCY)" > ApproverExpenseUser."Approval Limit (LCY)") do begin
            ProcessedApproverNos.Add(ApproverExpenseUser."No.");
            NextApproverNo := ExpenseReportApprovalMgmt.GetNextApproverNo(ApproverExpenseUser."No.");
            if (NextApproverNo = '') or ProcessedApproverNos.Contains(NextApproverNo) then
                Error(ApproverRequiredErr, SpendRequest."No.", ApproverExpenseUser.FieldCaption("Approval Limit (LCY)"), ApproverExpenseUser."No.");

            ApproverExpenseUser.Get(NextApproverNo);
            if not ApproverExpenseUser."Can Approve" then
                Error(ApproverMustBeEnabledErr, ApproverExpenseUser.FieldCaption("Can Approve"), ApproverExpenseUser.TableCaption());
        end;

        ApproverExpenseUser.TestField("User Id For Approvals");
        SpendRequest."Approver Expense User No." := ApproverExpenseUser."No.";
    end;

    // An approver-capable traveler approves their own travel request when it fits within their own limit; otherwise the configured approver chain applies.
    local procedure CanOwnerApproveOwnRequest(SpendRequest: Record "Spend Request"): Boolean
    var
        OwnerExpenseUser: Record "Expense User";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        if not OwnerExpenseUser.Get(SpendRequest."Requested For") then
            exit(false);
        if not ExpenseReportApprovalMgmt.IsApproverEligible(OwnerExpenseUser) then
            exit(false);

        exit(OwnerExpenseUser."Unlimited Approval" or (SpendRequest."Total Expected Amount (LCY)" <= OwnerExpenseUser."Approval Limit (LCY)"));
    end;

    local procedure CheckAndAssignAlternateApproval(var SpendRequest: Record "Spend Request")
    var
        AlternateApprover: Record "Expense User";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        AlternateApproverExpenseUserNo: Code[20];
    begin
        AlternateApproverExpenseUserNo := ExpenseReportApprovalMgmt.GetActiveAlternateApproverNo(GetPrimaryApproverNo(SpendRequest), WorkDate());
        if (AlternateApproverExpenseUserNo = '') or (AlternateApproverExpenseUserNo = SpendRequest."Approver Expense User No.") then
            exit;

        AlternateApprover.Get(AlternateApproverExpenseUserNo);
        ValidateAlternateApprover(SpendRequest, AlternateApprover);
        SetAlternateApprover(SpendRequest, AlternateApprover);
        LogAlternateApproverAssigned(SpendRequest, AlternateApprover, '', Enum::"Expense Activity Actor Role"::Administrator);
    end;

    local procedure ValidateAlternateApprover(SpendRequest: Record "Spend Request"; AlternateApprover: Record "Expense User")
    begin
        if (AlternateApprover."No." = SpendRequest."Requested For") or
           (AlternateApprover."No." = GetPrimaryApproverNo(SpendRequest))
        then
            Error(AlternateApproverConflictErr);

        CheckApproverPermissions(AlternateApprover);
    end;

    local procedure SetAlternateApprover(var SpendRequest: Record "Spend Request"; AlternateApprover: Record "Expense User")
    begin
        SpendRequest."Primary Approver No." := GetPrimaryApproverNo(SpendRequest);
        SpendRequest."Alternate Approver No." := AlternateApprover."No.";
        SpendRequest."Approver Expense User No." := AlternateApprover."No.";
    end;

    local procedure RevertEndedCoverage(var SpendRequest: Record "Spend Request")
    var
        PrimaryApprover: Record "Expense User";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        if (SpendRequest."Alternate Approver No." = '') or (SpendRequest."Primary Approver No." = '') then
            exit;
        if not ExpenseReportApprovalMgmt.IsCoverageEnded(SpendRequest."Primary Approver No.", SpendRequest."Alternate Approver No.") then
            exit;
        if not PrimaryApprover.Get(SpendRequest."Primary Approver No.") then
            exit;
        if not ExpenseReportApprovalMgmt.IsApproverEligible(PrimaryApprover) then
            exit;

        SpendRequest."Approver Expense User No." := PrimaryApprover."No.";
        SpendRequest."Alternate Approver No." := '';
        SpendRequest."Primary Approver No." := '';
        SpendRequest.Modify();
        LogTravelRequestEvent(
            SpendRequest,
            Enum::"Expense Activity Event Type"::AlternateApproverReverted,
            Enum::"Expense Activity Actor Role"::Administrator,
            '',
            StrSubstNo(ApproverRevertedCommentTxt, PrimaryApprover."No.", PrimaryApprover.Name));
    end;

    local procedure GetPrimaryApproverNo(SpendRequest: Record "Spend Request"): Code[20]
    begin
        if SpendRequest."Primary Approver No." <> '' then
            exit(SpendRequest."Primary Approver No.");

        exit(SpendRequest."Approver Expense User No.");
    end;

    local procedure CheckPendingApproval(SpendRequest: Record "Spend Request")
    begin
        SpendRequest.TestStatus(SpendRequest.Status::Released);
    end;

    local procedure CheckAlternateApproverStatus(SpendRequest: Record "Spend Request")
    begin
        if SpendRequest.Status <> SpendRequest.Status::Released then
            Error(AlternateApproverStatusErr, Format(SpendRequest.Status::Released));
    end;

    local procedure CheckAlternateApproverActor(SpendRequest: Record "Spend Request"; ActorExpenseUserNo: Code[20])
    begin
        if ActorExpenseUserNo = '' then
            exit;

        if not IsTravelRequestOwner(SpendRequest, ActorExpenseUserNo) then
            Error(AlternateApproverActorErr);
    end;

    local procedure GetAlternateAssignmentActorRole(SpendRequest: Record "Spend Request"; ActorExpenseUserNo: Code[20]): Enum "Expense Activity Actor Role"
    var
        ExpenseUser: Record "Expense User";
    begin
        if ActorExpenseUserNo <> '' then
            exit(Enum::"Expense Activity Actor Role"::Submitter);

        if FindCurrentExpenseUser(ExpenseUser) then
            if IsTravelRequestOwner(SpendRequest, ExpenseUser."No.") then
                exit(Enum::"Expense Activity Actor Role"::Submitter);

        exit(Enum::"Expense Activity Actor Role"::Administrator);
    end;

    local procedure IsTravelRequestOwner(SpendRequest: Record "Spend Request"; ExpenseUserNo: Code[20]): Boolean
    var
        ExpenseUser: Record "Expense User";
    begin
        if ExpenseUserNo = '' then
            exit(false);

        if not ExpenseUser.Get(ExpenseUserNo) then
            exit(false);

        exit(ExpenseUser."No." = SpendRequest."Requested For");
    end;

    local procedure CheckApproverApprovalLimit(SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        ApproverExpenseUser: Record "Expense User";
    begin
        if SpendRequest."Alternate Approver No." = ApproverExpenseUserNo then
            exit;

        ApproverExpenseUser.SetLoadFields("Unlimited Approval", "Approval Limit (LCY)");
        ApproverExpenseUser.Get(ApproverExpenseUserNo);
        if ApproverExpenseUser."Unlimited Approval" then
            exit;

        if SpendRequest."Total Expected Amount (LCY)" > ApproverExpenseUser."Approval Limit (LCY)" then
            Error(ApproverApprovalLimitErr, SpendRequest."No.", ApproverExpenseUser.FieldCaption("Approval Limit (LCY)"), ApproverExpenseUserNo);
    end;

    local procedure LogAlternateApproverAssigned(SpendRequest: Record "Spend Request"; AlternateApprover: Record "Expense User"; ActorExpenseUserNo: Code[20]; ActorRole: Enum "Expense Activity Actor Role")
    begin
        LogTravelRequestEvent(
            SpendRequest,
            Enum::"Expense Activity Event Type"::AlternateApproverAssigned,
            ActorRole,
            ActorExpenseUserNo,
            StrSubstNo(AlternateApproverAssignedCommentTxt, AlternateApprover."No.", AlternateApprover.Name));
    end;

    local procedure LogTravelRequestEvent(SpendRequest: Record "Spend Request"; EventType: Enum "Expense Activity Event Type"; ActorRole: Enum "Expense Activity Actor Role"; ActorExpenseUserNo: Code[20]; EventComment: Text)
    begin
        LogTravelRequestCreatedIfMissing(SpendRequest);
        ExpenseActivityLogMgt.LogTravelRequestEvent(SpendRequest, EventType, ActorRole, ActorExpenseUserNo, EventComment);
    end;

    local procedure GetCurrentExpenseUser(var ExpenseUser: Record "Expense User")
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        ExpenseReportApprovalMgmt.GetCurrentExpenseUserForApproval(ExpenseUser);
    end;

    local procedure FindCurrentExpenseUser(var ExpenseUser: Record "Expense User"): Boolean
    begin
        ExpenseUser.SetRange("User Id For Approvals", UserId());
        exit(ExpenseUser.FindFirst());
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

    local procedure LogTravelRequestSubmission(SpendRequest: Record "Spend Request"; SubmitterExpenseUserNo: Code[20]; IsResubmission: Boolean; SubmissionComment: Text)
    var
        EventType: Enum "Expense Activity Event Type";
    begin
        LogTravelRequestCreatedIfMissing(SpendRequest);

        if IsResubmission then
            EventType := EventType::Resubmitted
        else
            EventType := EventType::Submitted;

        ExpenseActivityLogMgt.LogTravelRequestEvent(
            SpendRequest, EventType, Enum::"Expense Activity Actor Role"::Submitter, SubmitterExpenseUserNo, SubmissionComment);
    end;

    /// <summary>
    /// Records the closure of a travel request as its final state in the activity history.
    /// The current Business Central user is logged as the actor.
    /// </summary>
    internal procedure LogTravelRequestClosed(SpendRequest: Record "Spend Request"; EventComment: Text)
    begin
        if SpendRequest."Document Type" <> SpendRequest."Document Type"::"Travel Request" then
            exit;
        if SpendRequest.Status <> SpendRequest.Status::Closed then
            exit;

        LogTravelRequestCreatedIfMissing(SpendRequest);
        ExpenseActivityLogMgt.LogTravelRequestEvent(
            SpendRequest, Enum::"Expense Activity Event Type"::Closed, Enum::"Expense Activity Actor Role"::" ", '', EventComment);
    end;

    local procedure LogTravelRequestCreatedIfMissing(SpendRequest: Record "Spend Request")
    begin
        // Start tracking with the earlier Created event, including requests first acted on after upgrade
        // and requests released directly in the client, where the first tracked action is the approval or rejection.
        if not ExpenseActivityLogMgt.HasEntriesForSource(Database::"Spend Request", SpendRequest.SystemId) then
            ExpenseActivityLogMgt.LogTravelRequestCreatedEvent(SpendRequest);
    end;

    local procedure IsTravelRequestResubmission(SpendRequest: Record "Spend Request"): Boolean
    begin
        if SpendRequest."Submitted At" <> 0DT then
            exit(true);
        exit(ExpenseActivityLogMgt.HasSubmissionForSource(Database::"Spend Request", SpendRequest.SystemId));
    end;

    local procedure LogTravelRequestApproved(SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        ActorRole: Enum "Expense Activity Actor Role";
        EventComment: Text;
    begin
        // Without an approver, the request was approved automatically and the Business Central user is logged as the actor.
        if ApproverExpenseUserNo <> '' then
            ActorRole := ActorRole::Approver
        else
            EventComment := AutomaticallyApprovedCommentTxt;

        ExpenseActivityLogMgt.LogTravelRequestEvent(
            SpendRequest, Enum::"Expense Activity Event Type"::Approved, ActorRole, ApproverExpenseUserNo, EventComment);
    end;

    local procedure GetExpenseReportWasNotCreatedError(SpendRequest: Record "Spend Request"; TravelerExpenseUserNo: Code[20]): ErrorInfo
    var
        ExpenseReportWasNotCreatedError: ErrorInfo;
    begin
        ExpenseReportWasNotCreatedError.Message := StrSubstNo(
            ExpenseReportWasNotCreatedErr, SpendRequest."No.", TravelerExpenseUserNo);
        ExpenseReportWasNotCreatedError.DataClassification := DataClassification::EndUserIdentifiableInformation;
        ExpenseReportWasNotCreatedError.ErrorType := ErrorType::Internal;
        exit(ExpenseReportWasNotCreatedError);
    end;

    internal procedure ApplyOwnerFilter(var SpendRequest: Record "Spend Request"; OwnerSystemId: Guid): Code[20]
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.SetLoadFields("Employee No.");
        ExpenseUser.GetBySystemId(OwnerSystemId);
        ExpenseUser.TestField("Employee No.");
        // API ownership uses the expense user's GUID; the base table stores the linked employee number.
        SpendRequest.SetRange("Requested By", ExpenseUser."Employee No.");
        exit(ExpenseUser."Employee No.");
    end;

    internal procedure ApplyApproverFilter(var SpendRequest: Record "Spend Request"; ApproverSystemId: Guid)
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.SetLoadFields("No.");
        ExpenseUser.GetBySystemId(ApproverSystemId);
        ApplyApproverFilter(SpendRequest, ExpenseUser."No.");
    end;

    internal procedure ApplyApproverFilter(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        Approver: Record "Expense User";
        RequestedForFilter: Text;
        OriginalFilterGroup: Integer;
    begin
        CheckApproverPermissions(ApproverExpenseUserNo, Approver);
        RequestedForFilter := GetRequestedForFilter(ApproverExpenseUserNo);

        SpendRequest.SetRange("Approver Expense User Filter");
        SpendRequest.SetRange(SystemId);
        SpendRequest.SetRange("Requested For");
        OriginalFilterGroup := SpendRequest.FilterGroup();
        SpendRequest.FilterGroup(-1);
        SpendRequest.SetRange("Approver Expense User No.");
        SpendRequest.SetRange("Requested For");
        SpendRequest.FilterGroup(OriginalFilterGroup);

        if RequestedForFilter = '' then begin
            SpendRequest.SetRange("Approver Expense User No.", ApproverExpenseUserNo);
            exit;
        end;

        // A routed request belongs to its assigned approver, for example after escalation by approval limit or delegation to an alternate approver.
        // A request without an assigned approver, released directly in the client or before approval routing, belongs to the approver from the approval setup.
        SpendRequest.SetFilter("Approver Expense User No.", '%1|%2', '', ApproverExpenseUserNo);
        SpendRequest.FilterGroup(-1);
        SpendRequest.SetRange("Approver Expense User No.", ApproverExpenseUserNo);
        SpendRequest.SetFilter("Requested For", RequestedForFilter);
        SpendRequest.FilterGroup(OriginalFilterGroup);
    end;

    local procedure CheckTravelRequest(SpendRequest: Record "Spend Request")
    begin
        SpendRequest.TestField("Document Type", SpendRequest."Document Type"::"Travel Request");
    end;

    local procedure CheckApprover(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20]; var Approver: Record "Expense User")
    begin
        CheckApproverPermissions(ApproverExpenseUserNo, Approver);
        EnsureApprovalRouted(SpendRequest);
        if ApproverExpenseUserNo <> SpendRequest."Approver Expense User No." then
            Error(NotTravelRequestApproverErr, ApproverExpenseUserNo, SpendRequest."No.");
    end;

    local procedure CheckApproverPermissions(ApproverExpenseUserNo: Code[20]; var Approver: Record "Expense User")
    begin
        Approver.SetLoadFields("Can Approve", "User Id For Approvals");
        Approver.Get(ApproverExpenseUserNo);
        Approver.TestField("Can Approve", true);
        Approver.TestField("User Id For Approvals");
    end;

    local procedure CheckApproverPermissions(Approver: Record "Expense User")
    begin
        Approver.TestField("Can Approve", true);
        Approver.TestField("User Id For Approvals");
    end;

    local procedure SetDecisionUser(var SpendRequest: Record "Spend Request"; Approver: Record "Expense User")
    var
        User: Record User;
    begin
        // The decision belongs to the approver, not to the session that called the API on the approver's behalf.
        User.SetRange("User Name", Approver."User Id For Approvals");
        User.SetLoadFields("User Security ID", "User Name");
        if not User.FindFirst() then
            Error(ApproverUserNotFoundErr, Approver."No.", Approver."User Id For Approvals");
        SpendRequest."Approved/Rejected by User ID" := User."User Security ID";
        SpendRequest."Approved/Rejected by User Name" := CopyStr(User."User Name", 1, MaxStrLen(SpendRequest."Approved/Rejected by User Name"));
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
        AssignedFilter: TextBuilder;
    begin
        ExpenseApprovalSetup.SetCurrentKey("Approver No.");
        ExpenseApprovalSetup.SetRange("Approver No.", ApproverExpenseUserNo);
        ExpenseApprovalSetup.SetLoadFields("Expense User No.");
        // Ranges between setup rows could include expense users without any approval setup.
        if ExpenseApprovalSetup.FindSet() then
            repeat
                AppendSubmitterFilter(AssignedFilter, ExpenseApprovalSetup."Expense User No.");
            until ExpenseApprovalSetup.Next() = 0;
        RequestedForFilter := AssignedFilter.ToText();

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
                AppendSubmitterFilter(DefaultFilter, ExpenseUser."No.");
            until ExpenseUser.Next() = 0;

        RequestedForFilter := DefaultFilter.ToText();
    end;

    local procedure AppendSubmitterFilter(var SubmitterFilter: TextBuilder; ExpenseUserNo: Code[20])
    var
        ExpenseUserFilter: Record "Expense User";
    begin
        // Serialize an exact value so filter operators in user numbers remain literal.
        ExpenseUserFilter.SetRange("No.", ExpenseUserNo);
        if SubmitterFilter.Length > 0 then
            SubmitterFilter.Append('|');
        SubmitterFilter.Append(ExpenseUserFilter.GetFilter("No."));
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        AutomaticallyApprovedCommentTxt: Label 'Approved automatically because the Expense Agent is disabled.';
        AutomaticApprovalNotAllowedErr: Label 'Automatic travel request approval can be used only when the Expense Agent is disabled.';
        TravelRequestSubmittedLbl: Label 'Travel request submitted.', Locked = true;
        TravelRequestApprovedLbl: Label 'Travel request approved.', Locked = true;
        TravelRequestAutoApprovedLbl: Label 'Travel request automatically approved.', Locked = true;
        TravelRequestRejectedLbl: Label 'Travel request rejected.', Locked = true;
        NotTravelRequestOwnerErr: Label 'Expense user %1 cannot submit travel request %2 because the user did not create it.', Comment = '%1 = Expense user number, %2 = Travel request number';
        ApproverUserNotFoundErr: Label 'Expense user %1 cannot approve or reject travel requests because the user ID for approvals, %2, does not match a Business Central user.', Comment = '%1 = Expense user number, %2 = User ID for approvals';
        NotTravelRequestApproverErr: Label 'Expense user %1 is not authorized to approve or reject travel request %2.', Comment = '%1 = Expense user number, %2 = Travel request number';
        TooManyTravelRequestSubmittersErr: Label 'Expense user %1 is configured to approve too many travel request submitters. Refine the approval setup before listing pending travel requests.', Comment = '%1 = Expense user number';
        ExpenseReportWasNotCreatedErr: Label 'An expense report was not created after approving travel request %1 for expense user %2.', Comment = '%1 = Travel Request No., %2 = Expense User No.';
        ExpenseReportCreationFailedLbl: Label 'Create expense report after travel request approval failed', Locked = true;
        ExpenseReportCreationFailedTelemetryErr: Label 'The approved travel request did not produce an expense report.', Locked = true;
        SubmitConfirmQst: Label 'Do you want to submit the travel request?';
        ReopenConfirmQst: Label 'Do you want to reopen the submitted travel request?';
        ApproveConfirmQst: Label 'Do you want to approve the submitted travel request?';
        RejectConfirmQst: Label 'Do you want to reject the submitted travel request?';
        ReopenApprovedConfirmQst: Label 'Do you want to reopen the approved travel request?';
        NotTravelRequestOwnerRecallErr: Label 'Expense user %1 cannot recall travel request %2 because the user did not create it.', Comment = '%1 = Expense user number, %2 = Travel request number';
        NotAuthorizedToRecallTravelRequestErr: Label 'Only the owner of the travel request or a user with %1 can recall a submitted travel request.', Comment = '%1 = Unlimited Approval field caption';
        ReopenApprovedWithExpensesErr: Label 'You cannot reopen travel request %1 because expenses have been posted against it.', Comment = '%1 = Travel request number';
        NoApproverConfiguredErr: Label 'Travel request %1 cannot be submitted because no approver is configured for expense user %2. Configure the approver in Expense Approval Setup or set a default approver.', Comment = '%1 = Travel request number, %2 = Expense user number';
        ApproverRequiredErr: Label 'Travel request %1 exceeds the %2 for approver %3. Configure the approver in Expense Approval Setup.', Comment = '%1 = Travel request number, %2 = Approval Limit field caption, %3 = Expense user number';
        ApproverApprovalLimitErr: Label 'Travel request %1 exceeds the %2 for approver %3.', Comment = '%1 = Travel request number, %2 = Approval Limit field caption, %3 = Expense user number';
        ApproverMustBeEnabledErr: Label '%1 must be enabled to approve or reject travel requests in %2.', Comment = '%1 = Can Approve field caption, %2 = Expense User table caption';
        AlternateApproverStatusErr: Label 'An alternate approver can only be assigned while the travel request is %1.', Comment = '%1 = Submitted status caption';
        AlternateApproverRequiredErr: Label 'Select an alternate approver from the available approvers.';
        AlternateApproverConflictErr: Label 'The alternate approver cannot be the same as the traveler or the approver of the travel request.';
        AlternateApproverActorErr: Label 'Only the owner of the travel request or an approval administrator can assign an alternate approver.';
        NoActiveAlternateApproverForDateErr: Label 'No active alternate approver is configured for approver %1 on %2.', Comment = '%1 = Approver number, %2 = Reference date';
        AlternateApproverAssignedCommentTxt: Label 'Alternate approver set to %1 (%2).', Comment = '%1 = Alternate Approver No., %2 = Alternate Approver Name';
        ApproverRevertedCommentTxt: Label 'Alternate coverage ended. Approval returned to %1 (%2).', Comment = '%1 = Expense User No., %2 = Expense User Name';
}
