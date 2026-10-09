// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6984 "Release Exp. Report Document"
{
    Access = Internal;
    TableNo = "Expense Report Header";
    Permissions = TableData "Expense Report Header" = rm,
                  TableData "Expense Report Line" = r;

    trigger OnRun()
    begin
        ExpenseReportHeader.Copy(Rec);
        ExpenseReportHeader.SetHideValidationDialog(Rec.GetHideValidationDialog());
        ReleaseExpenseReport();
        Rec := ExpenseReportHeader;
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLineDoesNotExistErr: Label 'There is no expense report lines with the number %1.', Comment = '%1 - Document No.';
        ApprovalProcessMustBeCancelledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        RuleViolationPresentOnLineErr: Label 'There are one or more rule violations in this expense report. Check the expenses marked for review before submitting again.';
        CannotReleaseDocumentWithNothingToRefundErr: Label 'Cannot release the Expense Report No. %1 because there is nothing to refund for this Line No. %2.', Comment = '%1 - Expense No. , %2 - Line No.';
        PolicyEvaluationNotCurrentErr: Label 'One or more expense lines have a policy evaluation that is not up to date. Re-run policy evaluation and approve again.';
        PolicyEvaluationNotCurrentCodeTok: Label ' (PolicyEvaluationNotCurrent)', Locked = true;
        ReimbursementErr: Label 'Reimbursement type must be set to a value in expense report %1, line %2 with description %3.', Comment = '%1 - Expense No. , %2 - Line No., %3 - description';

    local procedure ReleaseExpenseReport()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        if ExpenseReportHeader.Status = ExpenseReportHeader.Status::Released then
            exit;

        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Open);
        ExpenseReportHeader.TestField("Expense User No.");

        CheckExpenseReportLines(ExpenseReportLine, ExpenseReportHeader);

        ExpenseReportLine.Reset();

        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Released;

        ExpenseReportHeader.Modify(true);

        OnAfterReleaseExpenseReport(ExpenseReportHeader);
    end;

    local procedure CheckExpenseReportLines(var ExpenseReportLine: Record "Expense Report Line"; ExpReportHeader: Record "Expense Report Header")
    begin
        ExpenseReportLine.SetRange("Document No.", ExpReportHeader."No.");
        if ExpenseReportLine.FindSet() then
            repeat
                CheckMandatoryFields(ExpenseReportLine);
            until ExpenseReportLine.Next() = 0
        else
            Error(ExpenseReportLineDoesNotExistErr, ExpReportHeader."No.");
    end;

    local procedure CheckMandatoryFields(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ExpenseReportLine.TestField("Expense Category");
        ExpenseCategory.Get(ExpenseReportLine."Expense Category");
        ExpenseCategory.TestField(Inactive, false);

        if ExpenseSubCategory.Get(ExpenseReportLine."Expense Category", ExpenseReportLine."Expense Subcategory Code") then
            ExpenseSubCategory.TestField(Inactive, false);

        ExpenseReportLine.TestField(Description);
        if ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::" " then
            Error(ReimbursementErr, ExpenseReportLine."Expense No.", ExpenseReportLine."Line No.", ExpenseReportLine.Description);

        if ExpenseReportLine."Job No." <> '' then
            ExpenseReportLine.TestField("Job Task No.");

        CheckBillableVendor(ExpenseReportLine);
        CheckBillableCustomer(ExpenseReportLine);

        if (not ExpenseReportLine.Refundable) and (ExpenseReportLine."Reimbursement Type" = ExpenseReportLine."Reimbursement Type"::"Employee Paid") then
            Error(CannotReleaseDocumentWithNothingToRefundErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        ExpenseAgentSetup.GetRecordOnce();
        if ExpenseAgentSetup."Use Rules" then begin
            ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
            ExpenseReportLine.CalcFields("Rule Violations");
            if ExpenseReportLine."Rule Violations" then
                Error(RuleViolationPresentOnLineErr);
        end;
    end;

    local procedure CheckBillableVendor(ExpenseReportLine: Record "Expense Report Line")
    begin
        if not ExpenseReportLine."Purchase Invoice" then
            exit;

        ExpenseReportLine.TestField("Vendor No.");
        ExpenseReportLine.TestField("Posted Purch. Invoice No.");
    end;

    local procedure CheckBillableCustomer(ExpenseReportLine: Record "Expense Report Line")
    begin
        if not ExpenseReportLine.Billable then
            exit;

        ExpenseReportLine.TestField("Billable to Customer");
        ExpenseReportLine.TestField("Account Type", ExpenseReportLine."Account Type"::"G/L Account");
        ExpenseReportLine.TestField("Account No.");
    end;

    procedure Reopen(var ExpReportHeader: Record "Expense Report Header")
    begin
        if ExpReportHeader.Status = ExpReportHeader.Status::Open then
            exit;

        ExpReportHeader.Status := ExpReportHeader.Status::Open;
        ExpReportHeader.Modify(true);
    end;

    procedure PerformManualRelease(var ExpReportHeader: Record "Expense Report Header")
    begin
        PerformManualCheckAndRelease(ExpReportHeader);
    end;

    procedure PerformManualCheckAndRelease(var ExpReportHeader: Record "Expense Report Header")
    begin
        Codeunit.Run(Codeunit::"Release Exp. Report Document", ExpReportHeader);
    end;

    procedure PerformManualReopen(var ExpReportHeader: Record "Expense Report Header")
    begin
        CheckReopenStatus(ExpReportHeader);

        Reopen(ExpReportHeader);
    end;

    local procedure CheckReopenStatus(ExpReportHeader: Record "Expense Report Header")
    begin
        if ExpReportHeader.Status in [ExpReportHeader.Status::"Pending Approval", ExpReportHeader.Status::"Interim Approved"] then
            Error(ApprovalProcessMustBeCancelledErr);
    end;

    procedure PerformManualPendingApproval(var ExpReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20])
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        CheckPendingApprovalStatus(ExpReportHeader);

        ExpenseReportApprovalMgmt.Submit(ExpReportHeader, SubmitterExpenseUserNo);
    end;

    procedure PerformManualReleaseAndPendingApproval(var ExpReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20])
    begin
        PerformManualReleaseAndPendingApproval(ExpReportHeader, SubmitterExpenseUserNo, '');
    end;

    procedure PerformManualReleaseAndPendingApproval(var ExpReportHeader: Record "Expense Report Header"; SubmitterExpenseUserNo: Code[20]; SubmissionComment: Text)
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        Codeunit.Run(Codeunit::"Release Exp. Report Document", ExpReportHeader);

        ExpReportHeader.Get(ExpReportHeader."No.");

        CheckPendingApprovalStatus(ExpReportHeader);
        ExpenseReportApprovalMgmt.Submit(ExpReportHeader, SubmitterExpenseUserNo, SubmissionComment);
    end;

    local procedure CheckPendingApprovalStatus(var ExpReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpReportHeader.TestField(Status, ExpReportHeader.Status::Released);
        ExpReportHeader.TestField("Expense User No.");

        CheckExpenseReportLines(ExpenseReportLine, ExpReportHeader);
    end;

    local procedure CheckPoliciesUpToDate(ExpReportHeader: Record "Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
        PolicyEvaluationNotCurrentMsg: Text;
    begin
        // Re-check policy currency in the approval transaction unless the caller explicitly overrides it.
        // Submission remains available so a report can enter approval while policy evaluation is pending.
        ExpenseAgentSetup.GetRecordOnce();
        if not ExpenseAgentSetup."Evaluate Policies" then
            exit;

        // Build the message before raising it: the human-readable label stays translatable while the
        // machine-detectable marker stays locked, and Error receives a single value (no inline
        // concatenation in the Error call).
        PolicyEvaluationNotCurrentMsg := PolicyEvaluationNotCurrentErr + PolicyEvaluationNotCurrentCodeTok;

        ExpenseReportLine.SetRange("Document No.", ExpReportHeader."No.");
        ExpenseReportLine.SetLoadFields("Expense Category", "Policies Evaluated At", "Policy Eval Version", "Evaluated Policy Version");
        if ExpenseReportLine.FindSet() then
            repeat
                if ExpenseReportLine.GetPolicyStatus() in
                    ["Expense Policy Status"::Stale, "Expense Policy Status"::"Not Evaluated"]
                then
                    Error(PolicyEvaluationNotCurrentMsg);
            until ExpenseReportLine.Next() = 0;
    end;

    procedure PerformManualApproved(var ExpReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20])
    begin
        PerformManualApproved(ExpReportHeader, ApproverExpenseUserNo, false);
    end;

    procedure PerformManualApproved(var ExpReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20]; SkipPolicyValidation: Boolean)
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        CheckApprovedStatus(ExpReportHeader, SkipPolicyValidation);

        ExpenseReportApprovalMgmt.Approve(ExpReportHeader, ApproverExpenseUserNo);
    end;

    local procedure CheckApprovedStatus(var ExpReportHeader: Record "Expense Report Header"; SkipPolicyValidation: Boolean)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpReportHeader.TestApprovalPending();
        ExpReportHeader.TestField("Expense User No.");

        CheckExpenseReportLines(ExpenseReportLine, ExpReportHeader);
        if not SkipPolicyValidation then
            CheckPoliciesUpToDate(ExpReportHeader);
    end;

    procedure PerformManualRejected(var ExpReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        CheckRejectedStatus(ExpReportHeader);

        ExpenseReportApprovalMgmt.Reject(ExpReportHeader, ApproverExpenseUserNo, RejectReason);
    end;

    procedure PerformManualRejectedAndReopen(var ExpReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        CheckRejectedStatus(ExpReportHeader);
        ExpenseReportApprovalMgmt.Reject(ExpReportHeader, ApproverExpenseUserNo, RejectReason);

        ExpReportHeader.Get(ExpReportHeader."No.");

        Reopen(ExpReportHeader);
    end;

    local procedure CheckRejectedStatus(var ExpReportHeader: Record "Expense Report Header")
    begin
        ExpReportHeader.TestApprovalPending();
        ExpReportHeader.TestField("Expense User No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    begin
    end;
}