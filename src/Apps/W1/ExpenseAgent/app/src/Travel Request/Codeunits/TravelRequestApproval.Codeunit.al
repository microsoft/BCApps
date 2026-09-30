// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using System.Telemetry;
using System.Text;

codeunit 7133 "Travel Request Approval"
{
    Access = Internal;
    Permissions = tabledata "Spend Request" = rm,
                  tabledata Traveler = r,
                  tabledata "Expense Report Header" = ri,
                  tabledata "Posted Expense Report Header" = r,
                  tabledata "Posted Expense Report Line" = r;

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
        Submitter.SetLoadFields("Employee No.");
        Submitter.Get(SubmitterExpenseUserNo);
        Submitter.TestField("Employee No.");
        if Submitter."Employee No." <> SpendRequest."Requested By" then
            Error(NotTravelRequestOwnerErr, SubmitterExpenseUserNo, SpendRequest."No.");

        IsResubmission := IsTravelRequestResubmission(SpendRequest);
        SpendRequest."Submitted By Expense User No." := SubmitterExpenseUserNo;
        SpendRequest."Submitted At" := CurrentDateTime();
        // A new submission starts a new approval, so no decision from a previous rejection is kept.
        Clear(SpendRequest."Approved/Rejected At");
        Clear(SpendRequest."Approved/Rejected by User ID");
        Clear(SpendRequest."Approved/Rejected by User Name");
        Clear(SpendRequest."Approval Expense User No.");
        Clear(SpendRequest."Rejection Reason");
        SpendRequest."Submitter Comment" := CopyStr(SubmissionComment, 1, MaxStrLen(SpendRequest."Submitter Comment"));
        SpendRequest.Modify();
        // Log before releasing so that an automatic approval raised by the release is ordered after the submission.
        LogTravelRequestSubmission(SpendRequest, SubmitterExpenseUserNo, IsResubmission, SubmissionComment);
        ReleaseSpendRequest.Release(SpendRequest);
        FeatureTelemetry.LogUsage('0000VEY', ExpenseAgentSetup.GetFeatureName(), TravelRequestSubmittedLbl);
    end;

    internal procedure Approve(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    var
        Approver: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        CheckTravelRequest(SpendRequest);
        SpendRequest.TestStatus(SpendRequest.Status::Released);
        CheckApprover(SpendRequest, ApproverExpenseUserNo, Approver);
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

        ApproveInternal(SpendRequest, '');
        FeatureTelemetry.LogUsage('0000VF0', ExpenseAgentSetup.GetFeatureName(), TravelRequestAutoApprovedLbl);
    end;

    local procedure ApproveInternal(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20])
    begin
        SpendRequest.TestField("Requested For");
        SpendRequest.Status := SpendRequest.Status::Approved;
        SpendRequest."Approved/Rejected At" := CurrentDateTime();
        SpendRequest."Approved/Rejected by User ID" := UserSecurityId();
        SpendRequest."Approved/Rejected by User Name" := CopyStr(UserId(), 1, MaxStrLen(SpendRequest."Approved/Rejected by User Name"));
        SpendRequest."Approval Expense User No." := ApproverExpenseUserNo;
        Clear(SpendRequest."Rejection Reason");
        SpendRequest.Modify();
        LogTravelRequestCreatedIfMissing(SpendRequest);
        LogTravelRequestApproved(SpendRequest, ApproverExpenseUserNo);
        // A single entry covers all travelers' expense reports created by this approval.
        if CreateTravelerExpenseReports(SpendRequest) then
            ExpenseActivityLogMgt.LogTravelRequestExpenseReportsCreated(SpendRequest);
    end;

    local procedure CreateTravelerExpenseReports(SpendRequest: Record "Spend Request") AnyCreated: Boolean
    var
        Traveler: Record Traveler;
    begin
        AnyCreated := CreateTravelerExpenseReport(SpendRequest, SpendRequest."Requested For");

        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Traveler.SetFilter("Expense User No.", '<>%1&<>%2', '', SpendRequest."Requested For");
        Traveler.SetLoadFields("Expense User No.");
        if Traveler.FindSet() then
            repeat
                if CreateTravelerExpenseReport(SpendRequest, Traveler."Expense User No.") then
                    AnyCreated := true;
            until Traveler.Next() = 0;
    end;

    local procedure CreateTravelerExpenseReport(SpendRequest: Record "Spend Request"; TravelerExpenseUserNo: Code[20]) Created: Boolean
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if ExpenseReportHeader.HasPostedTravelRequestReport(SpendRequest, TravelerExpenseUserNo) then
            exit(false);

        Created := ExpenseReportHeader.CreateFromApprovedTravelRequestIfMissing(SpendRequest, TravelerExpenseUserNo);
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
        SpendRequest."Approved/Rejected by User ID" := UserSecurityId();
        SpendRequest."Approved/Rejected by User Name" := CopyStr(UserId(), 1, MaxStrLen(SpendRequest."Approved/Rejected by User Name"));
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
        // Reopened in the same transaction, so the submitter can edit and resubmit without an extra call. The Rejected entry explains the reopen.
        ReleaseSpendRequest.Reopen(SpendRequest);
        FeatureTelemetry.LogUsage('0000VF1', ExpenseAgentSetup.GetFeatureName(), TravelRequestRejectedLbl);
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
    begin
        if ApproverExpenseUserNo <> '' then
            ExpenseActivityLogMgt.LogTravelRequestEvent(
                SpendRequest,
                Enum::"Expense Activity Event Type"::Approved,
                Enum::"Expense Activity Actor Role"::Approver,
                ApproverExpenseUserNo,
                '')
        else
            ExpenseActivityLogMgt.LogTravelRequestEventByBCUser(
                SpendRequest,
                Enum::"Expense Activity Event Type"::Approved,
                Enum::"Expense Activity Actor Role"::" ",
                AutomaticallyApprovedCommentTxt);
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
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
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
                DefaultFilter.Append(SelectionFilterManagement.AddQuotes(ExpenseUser."No."));
            until ExpenseUser.Next() = 0;

        RequestedForFilter := DefaultFilter.ToText();
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
        NotTravelRequestApproverErr: Label 'Expense user %1 is not authorized to approve or reject travel request %2.', Comment = '%1 = Expense user number, %2 = Travel request number';
        TooManyTravelRequestSubmittersErr: Label 'Expense user %1 is configured to approve too many travel request submitters. Refine the approval setup before listing pending travel requests.', Comment = '%1 = Expense user number';
        ExpenseReportWasNotCreatedErr: Label 'An expense report was not created after approving travel request %1 for expense user %2.', Comment = '%1 = Travel Request No., %2 = Expense User No.';
        ExpenseReportCreationFailedLbl: Label 'Create expense report after travel request approval failed', Locked = true;
        ExpenseReportCreationFailedTelemetryErr: Label 'The approved travel request did not produce an expense report.', Locked = true;
}
