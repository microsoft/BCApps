// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using System.Telemetry;

codeunit 7133 "Travel Request Approval"
{
    Access = Internal;
    Permissions = tabledata "Spend Request" = rm,
                  tabledata "Expense Report Header" = ri,
                  tabledata "Posted Expense Report Header" = r,
                  tabledata "Posted Expense Report Line" = r;

    internal procedure Submit(var SpendRequest: Record "Spend Request"; SubmitterExpenseUserNo: Code[20])
    var
        Submitter: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
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
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        SpendRequest.TestField("Requested For");
        SpendRequest.Status := SpendRequest.Status::Approved;
        SpendRequest."Approved/Rejected At" := CurrentDateTime();
        SpendRequest."Approved/Rejected by User ID" := UserSecurityId();
        SpendRequest."Approval Expense User No." := ApproverExpenseUserNo;
        Clear(SpendRequest."Rejection Reason");
        SpendRequest.Modify();
        if ExpenseReportHeader.HasPostedTravelRequestReport(SpendRequest) then
            exit;

        ExpenseReportHeader.CreateFromApprovedTravelRequest(SpendRequest);
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.SetRange("Expense User No.", SpendRequest."Requested For");
        if ExpenseReportHeader.IsEmpty() then begin
            FeatureTelemetry.LogError('0000VEX', ExpenseAgentSetup.GetFeatureName(), ExpenseReportCreationFailedLbl, ExpenseReportCreationFailedTelemetryErr);
            Error(GetExpenseReportWasNotCreatedError(SpendRequest));
        end;
    end;

    internal procedure Reject(var SpendRequest: Record "Spend Request"; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        Approver: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
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
        FeatureTelemetry.LogUsage('0000VF1', ExpenseAgentSetup.GetFeatureName(), TravelRequestRejectedLbl);
    end;

    local procedure GetExpenseReportWasNotCreatedError(SpendRequest: Record "Spend Request"): ErrorInfo
    var
        ExpenseReportWasNotCreatedError: ErrorInfo;
    begin
        ExpenseReportWasNotCreatedError.Message := StrSubstNo(
            ExpenseReportWasNotCreatedErr, SpendRequest."No.", SpendRequest."Requested For");
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
