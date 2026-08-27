// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Approval workflow management for corporate card expense reports.
/// Integrates with Business Central's standard Expense Report approval framework.
/// Note: Individual expenses transition to "Released" status, but actual approval 
/// happens at the Expense Report level using the standard approval workflow.
/// </summary>
codeunit 7218 "EA Corp Card Approval Mgt"
{
    Access = Internal;

    var
        ReportNotFoundErr: Label 'Expense Report %1 not found.', Comment = '%1 = Report No.';
        ReportNotInOpenStatusErr: Label 'Expense Report %1 is not in Open status. Current status: %2.', Comment = '%1 = Report No., %2 = Status';
        ReportHasNoExpensesErr: Label 'Expense Report %1 has no expenses to submit for approval.', Comment = '%1 = Report No.';

    /// <summary>
    /// Submits an expense report for approval.
    /// Changes status from Open to Pending Approval and integrates with standard approval workflow.
    /// </summary>
    internal procedure SubmitReportForApproval(ReportNo: Code[20])
    var
        ExpenseReportHeader: Record "Expense Report Header";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
    begin
        if not ExpenseReportHeader.Get(ReportNo) then
            Error(ReportNotFoundErr, ReportNo);

        if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::Open then
            Error(ReportNotInOpenStatusErr, ReportNo, ExpenseReportHeader.Status);

        // Validate report has lines
        ValidateReportHasExpenses(ExpenseReportHeader);

        // Update status to Pending Approval
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::"Pending Approval";
        ExpenseReportHeader.Modify();

        AuditSubscribers.LogReportSubmittedForApproval(ReportNo, UserSecurityId());
    end;

    /// <summary>
    /// Releases an expense report for posting.
    /// Changes status from Pending Approval to Released.
    /// Called after approval workflow is complete.
    /// GL posting happens via standard ExpenseReportPost codeunit when user posts the report.
    /// </summary>
    internal procedure ReleaseReportForPosting(ReportNo: Code[20])
    var
        ExpenseReportHeader: Record "Expense Report Header";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
    begin
        if not ExpenseReportHeader.Get(ReportNo) then
            Error(ReportNotFoundErr, ReportNo);

        if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::"Pending Approval" then
            Error(ReportNotInOpenStatusErr, ReportNo, ExpenseReportHeader.Status);

        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Released;
        ExpenseReportHeader.Modify();

        AuditSubscribers.LogReportApprovedForPosting(ReportNo, UserSecurityId());
    end;

    /// <summary>
    /// Rejects an expense report and returns it to Open status for revision.
    /// </summary>
    internal procedure RejectReport(ReportNo: Code[20]; RejectionReason: Text)
    var
        ExpenseReportHeader: Record "Expense Report Header";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
    begin
        if not ExpenseReportHeader.Get(ReportNo) then
            Error(ReportNotFoundErr, ReportNo);

        if ExpenseReportHeader.Status <> ExpenseReportHeader.Status::"Pending Approval" then
            Error(ReportNotInOpenStatusErr, ReportNo, ExpenseReportHeader.Status);

        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Open;
        ExpenseReportHeader.Modify();

        AuditSubscribers.LogReportRejected(ReportNo, UserSecurityId(), RejectionReason);
    end;

    /// <summary>
    /// Validates that an expense report has at least one line item (expense).
    /// </summary>
    local procedure ValidateReportHasExpenses(ExpenseReportHeader: Record "Expense Report Header")
    var
        Expense: Record Expense;
    begin
        Expense.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        if Expense.IsEmpty() then
            Error(ReportHasNoExpensesErr, ExpenseReportHeader."No.");
    end;
}
