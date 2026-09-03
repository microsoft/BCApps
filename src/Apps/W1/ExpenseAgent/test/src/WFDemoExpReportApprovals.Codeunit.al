// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Environment;
using System.TestLibraries.Utilities;

// Requires Windows Authentication: Codeunit "Library - Document Approvals" filters User by Windows SID,
// which is empty under UserPassword auth and binds the wrong User Setup.
codeunit 148304 "WF Demo Exp. Report Approvals"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Expense Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        IsInitialized: Boolean;
        InvalidApprovalStatusErr: Label 'Status must be Released or Rejected for Expense Report No. %1.', Comment = '%1 - Expense Report No.';
        ReOpenMustBeDisabledErr: Label 'Reopen action must be disabled.';
        ReOpenMustBeEnabledErr: Label 'Reopen action must be Enabled.';
        SubmitMustBeDisabledErr: Label 'Submit action must be disabled.';
        SubmitMustBeEnabledErr: Label 'Submit action must be enabled.';
        ReleaseMustBeDisabledErr: Label 'Release action must be disabled.';
        ReleaseMustBeEnabledErr: Label 'Release action must be enabled.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        OnlyBCUserCanApproveErr: Label 'In order to be an expense approver there must be a user in Business Central for email %1 for expense user %2.', Comment = '%1 - Email, %2 - Expense User No.';
        CannotDisableApprovalWorkflowErr: Label 'You cannot disable approval workflow because there are expense reports pending approval. Please complete or cancel the approval process for those expense reports before disabling this feature.';
        ApproveActionMustBeVisibleErr: Label 'Approve action must be visible for the assigned approver.';
        RejectActionMustBeVisibleErr: Label 'Reject action must be visible for the assigned approver.';
        ApproveActionMustNotBeVisibleErr: Label 'Approve action must not be visible when the user is not the assigned approver.';
        MissingUserSetupErr: Label 'Please configure your user ''%1'' on the User Setup, as the approval workflow for expenses is enabled.', Comment = '%1 = current user ID';

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ApproveExpenseReport()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the user can approve an Expense Report when submitted for approval.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [THEN] Verify Approver in Expense Report.
        VerifyApproverInExpenseReport(ExpenseReportHeader, ExpenseUser[2]."No.", FinalApproverUserSetup."User ID");

        // [WHEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Approved");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReopenApprovedExpenseReport()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the user can reopen an Approved Expense Report.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Approved");

        // [WHEN] Reopen Approved Expense Report.
        ReopenApprovedExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure RejectExpenseReport()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the user can reject an Expense Report when submitted for approval.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Reject Expense Report.
        RejectExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Rejected.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Rejected");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReopenSubmittedExpenseReport()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the user can reopen a Expense Report.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Reopen Expense Report.
        ReopenSubmittedExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Reopened.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Open);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReSubmitExpenseReportWhenExpenseReportIsRejected()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the user can resubmit an Expense Report when rejected.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Reject Expense Report.
        RejectExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Rejected.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Rejected");

        // [WHEN] Submit Expense Report for Approval.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReOpenSubmitExpenseReportWhenExpenseReportIsRejected()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the user can reopen an Expense Report when rejected.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Reject Expense Report.
        RejectExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Rejected.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Rejected");

        // [WHEN] Reopen Submitted Expense Report.
        ReopenSubmittedExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Open.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Open);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ApproveCannotBeExecutedWhenExpenseReportIsRejected()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the Approve action cannot be executed when Expense Report is rejected.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Reject Expense Report.
        RejectExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Rejected.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Rejected");

        // [WHEN] Approve Expense Report.
        asserterror ExpenseReportApprovalMgmt.Approve(ExpenseReportHeader);

        // [THEN] Verify Approve action cannot be executed when Expense Report is rejected.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::"Pending Approval"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ApproveCannotBeExecutedWhenExpenseReportIsNotSubmitted()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the Approve action cannot be executed when Expense Report is not submitted.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Approve Expense Report.
        asserterror ExpenseReportApprovalMgmt.Approve(ExpenseReportHeader);

        // [THEN] Verify Approve action cannot be executed when Expense Report is not submitted.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::"Pending Approval"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure RejectCannotBeExecutedWhenExpenseReportIsNotSubmitted()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the Reject action cannot be executed when Expense Report is not submitted.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Reject Expense Report.
        asserterror ExpenseReportApprovalMgmt.Reject(ExpenseReportHeader);

        // [THEN] Verify Reject action cannot be executed when Expense Report is not submitted.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::"Pending Approval"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReopenSubmittedCanBeExecutedWhenExpenseReportIsApproved()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the Reopen action can be executed when Expense Report is approved.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Approved");

        // [WHEN] Reopen Submitted Expense Report.
        ExpenseReportApprovalMgmt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] Verify Reopen action can be executed when Expense Report is approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Open);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure SubmitCannotBeExecutedWhenExpenseReportIsApproved()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the Submit action cannot be executed when Expense Report is approved.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Approved");

        // [WHEN] Submit Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader);

        // [THEN] Verify Submit action cannot be executed when Expense Report is approved.
        Assert.ExpectedError(StrSubstNo(InvalidApprovalStatusErr, ExpenseReportHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure RejectCannotBeExecutedWhenExpenseReportIsApproved()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 580546] Verify that the Reject action cannot be executed when Expense Report is approved.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Approved");

        // [WHEN] Reject Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        asserterror ExpenseReportApprovalMgmt.Reject(ExpenseReportHeader);

        // [THEN] Verify Reject action cannot be executed when Expense Report is approved.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::"Pending Approval"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ActionMustBeDisabledAndEnabledWhenSubmitExpenseReport()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 580546] Verify that the actions are enabled/disabled correctly when Expense Report is submitted for approval.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] Verify ReopenSubmitted action is disabled.
        Assert.IsFalse(ExpenseReportPage.ReopenSubmitted.Enabled(), ReOpenMustBeDisabledErr);

        // [WHEN] Submit Expense Report for Approval.
        ExpenseReportPage.Submit.Invoke();

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [THEN] "Reopen" is enabled.
        Assert.IsTrue(ExpenseReportPage.ReopenSubmitted.Enabled(), ReOpenMustBeEnabledErr);

        // [THEN] "Submit" is disabled.
        Assert.IsFalse(ExpenseReportPage.Submit.Enabled(), SubmitMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ActionMustBeDisabledAndEnabledWhenReOpenSubmitExpenseReport()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 580546] Verify that the actions are enabled/disabled correctly when Expense Report is ReOpen Submit for approval.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Open Expense Report Page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        ExpenseReportPage.Submit.Invoke();

        // [THEN] "Submit" is disabled.
        Assert.IsFalse(ExpenseReportPage.Submit.Enabled(), SubmitMustBeDisabledErr);

        // [WHEN] ReopenSubmitted Expense Report.
        ExpenseReportPage.ReopenSubmitted.Invoke();

        // [THEN] Verify Expense Report status is set to Open.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Open);

        // [WHEN] Release Expense Report.
        ExpenseReportPage.Release.Invoke();

        // [THEN] Action "Submit" is enabled.
        Assert.IsTrue(ExpenseReportPage.Submit.Enabled(), SubmitMustBeEnabledErr);

        // [THEN] Action "Reopen" is disabled.
        Assert.IsFalse(ExpenseReportPage.ReopenSubmitted.Enabled(), ReOpenMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReleaseActionIsDisabledWhenExpReportIsSubmittedForApproval()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629915] Release action is disabled when Expense Report is submitted for approval
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Open Expense Report Page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [WHEN] Submit Expense Report for Approval.
        ExpenseReportPage.Submit.Invoke();

        // [THEN] Verify Expense Report status is set to Pending Approval.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [THEN] Release action is disabled.
        Assert.IsFalse(ExpenseReportPage.Release.Enabled(), ReleaseMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReleaseActionIsDisabledWhenExpReportIsApproved()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629915] Release action is disabled when Expense Report is approved
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [GIVEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [WHEN] Open Expense Report Page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] Release action is disabled.
        Assert.IsFalse(ExpenseReportPage.Release.Enabled(), ReleaseMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReleaseActionIsEnabledWhenExpReportIsOpen()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629915] Release action is enabled when Expense Report is reopened to Open status
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Open Expense Report Page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        ExpenseReportPage.Submit.Invoke();

        // [WHEN] Reopen Submitted Expense Report.
        ExpenseReportPage.ReopenSubmitted.Invoke();

        // [THEN] Verify Expense Report status is set to Open.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Open);

        // [THEN] Release action is enabled.
        Assert.IsTrue(ExpenseReportPage.Release.Enabled(), ReleaseMustBeEnabledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReleaseActionIsDisabledOnManagerPageWhenPendingApproval()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ManagerExpenseReportPage: TestPage "Manager Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629915] Release action is disabled on Manager Expense Report page when status is Pending Approval
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [WHEN] Open Manager Expense Report Page.
        ManagerExpenseReportPage.OpenView();
        ManagerExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] Release action is disabled.
        Assert.IsFalse(ManagerExpenseReportPage.Release.Enabled(), ReleaseMustBeDisabledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ReleaseActionIsDisabledOnManagerPageWhenApproved()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ManagerExpenseReportPage: TestPage "Manager Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629915] Release action is disabled on Manager Expense Report page when status is Approved
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [GIVEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [WHEN] Open Manager Expense Report Page.
        ManagerExpenseReportPage.OpenView();
        ManagerExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] Release action is disabled.
        Assert.IsFalse(ManagerExpenseReportPage.Release.Enabled(), ReleaseMustBeDisabledErr);
    end;

    [Test]
    procedure UserIdForApprovalMustBeUpdatedWhenCanApproveEnabledAndBCUserExists()
    var
        ExpenseUser: Record "Expense User";
        UserName: Code[50];
        UserEmail: Text[80];
    begin
        // [SCENARIO 623831] Verify that the User ID for Approval is updated when Can Approve is enabled and BC user with same email exists.
        Initialize();

        // [GIVEN] Create a BC user with email.
        UserName := CopyStr(LibraryRandom.RandText(50), 1, 50);
        UserEmail := UserName + '@' + 'example.com';

        // [GIVEN] Create a user with Email.
        CreateUserWithEmail(UserName, UserEmail);

        // [WHEN] Create an expense user with same email and Can Approve enabled.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Validate("Can Approve", true);
        ExpenseUser.Modify(true);

        // [THEN] Verify that the user ID for approvals is set to the BC user name.
        Assert.AreEqual(
            UserName,
            ExpenseUser."User Id For Approvals",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("User Id For Approvals"), UserName, ExpenseUser.TableCaption()));
    end;

    [Test]
    procedure SystemMustThrowAnErrorWhenCanApproveEnabledAndNoBCUserExists()
    var
        ExpenseUser: Record "Expense User";
        UserEmail: Text[80];
    begin
        // [SCENARIO 623831] Verify that the system throws an error when Can Approve is enabled and no BC user with same email exists.
        Initialize();

        // [GIVEN] Create a user with Email.
        UserEmail := CopyStr(LibraryRandom.RandText(50), 1, 50) + '@' + 'example.com';

        // [WHEN] Create an expense user with same email and Can Approve enabled.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        asserterror ExpenseUser.Validate("Can Approve", true);

        // [THEN] Verify that the system throws an error.
        Assert.ExpectedError(StrSubstNo(OnlyBCUserCanApproveErr, UserEmail, ExpenseUser."No."));
    end;

    [Test]
    procedure SystemMustThrowAnErrorWhenEmailChangesToNoBCUserAndCanApproveEnabled()
    var
        ExpenseUser: Record "Expense User";
        UserName: Code[50];
        UserEmail: Text[80];
    begin
        // [SCENARIO 623831] Verify that the system throws an error when email changes to no BC user and Can Approve is enabled.
        Initialize();

        // [GIVEN] Create a BC user with email.
        UserName := CopyStr(LibraryRandom.RandText(50), 1, 50);
        UserEmail := UserName + '@' + 'example.com';

        // [GIVEN] Create a user with Email.
        CreateUserWithEmail(UserName, UserEmail);

        // [WHEN] Create an expense user with same email and Can Approve enabled.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Validate("Can Approve", true);
        ExpenseUser.Modify(true);

        // [THEN] Verify that the user ID for approvals is set to the BC user name.
        Assert.AreEqual(
            UserName,
            ExpenseUser."User Id For Approvals",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("User Id For Approvals"), UserName, ExpenseUser.TableCaption()));

        // [WHEN] Change email to another email with no BC user and Can Approve enabled.
        UserEmail := CopyStr(LibraryRandom.RandText(50), 1, 50) + '@' + 'example.com';
        asserterror ExpenseUser.Validate("E-mail", UserEmail);

        // [THEN] Verify that the system throws an error.
        Assert.ExpectedError(StrSubstNo(OnlyBCUserCanApproveErr, UserEmail, ExpenseUser."No."));
    end;

    [Test]
    procedure SystemMustThrowAnErrorWhenCanApproveEnabledAndEmailIsBlank()
    var
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 623831] Verify that the system throws an error when Can Approve is enabled and email is blank.
        Initialize();

        // [WHEN] Create an expense user with blank email and Can Approve enabled.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        asserterror ExpenseUser.Validate("Can Approve", true);

        // [THEN] Verify that the system throws an error.
        Assert.ExpectedTestFieldError(ExpenseUser.FieldCaption("E-mail"), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenExpenseReportIsApproved()
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 580546] Verify that the Expense Report is posted when Expense Report is approved.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [WHEN] Approve Expense Report.
        ApproveExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report status is set to Approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Approved");

        // [WHEN] Post Expense Report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report is posted.
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseReportHeader."Expense User No.");
        Assert.RecordIsNotEmpty(PostedExpenseReportHeader);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure CannotDisableApprovalWorkflow_WhenPendingApprovalExists()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ExpenseUser: array[2] of Record "Expense User";
    begin
        // [SCENARIO 621999] Approval workflow cannot be disabled if there are expense reports pending approval.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create and Release Expense Report.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        SubmitExpenseReportForApproval(ExpenseReportHeader);

        // [WHEN] Try to disable approval workflow.
        ExpenseAgentSetup.GetRecordOnce();
        asserterror ExpenseAgentSetup.Validate("Enable Approval Workflow", false);

        // [THEN] Verify that an error is thrown when trying to disable approval workflow.
        Assert.ExpectedError(CannotDisableApprovalWorkflowErr);
    end;

    [Test]
    procedure CanDisableApprovalWorkflow_WhenNoPendingApproval()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 621999] Verify Approval workflow can be disabled if no expense reports are pending approval.
        Initialize();

        // [GIVEN] Enable Approval Workflow.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [WHEN] Try to disable approval workflow.
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.Validate("Enable Approval Workflow", false);
        ExpenseAgentSetup.Modify(true);

        // [THEN] Verify that approval workflow is disabled successfully.
        Assert.IsFalse(
            ExpenseAgentSetup."Enable Approval Workflow",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Enable Approval Workflow"), false, ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure MissingUserSetupThrowsActionableErrorForApproval()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO 645040] Resolving the current user's setup for approval raises an actionable error when the user is not on the User Setup page.
        Initialize();

        // [GIVEN] Approval workflow is enabled.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [WHEN] Resolving the current user's setup for approval.
        asserterror ExpenseReportApprovalMgmt.GetCurrentUserSetupForApproval(UserSetup);

        // [THEN] The actionable missing-User-Setup error is raised for the current user.
        Assert.ExpectedError(StrSubstNo(MissingUserSetupErr, UserId()));
    end;

    [Test]
    procedure CurrentUserSetupIsReturnedWhenPresentForApproval()
    var
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO 645040] Resolving the current user's setup for approval returns the record when the user is on the User Setup page.
        Initialize();

        // [GIVEN] Approval workflow is enabled.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] The current user has a User Setup record.
        UserSetup.Init();
        UserSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID"));
        UserSetup.Insert();
        Clear(UserSetup);

        // [WHEN] Resolving the current user's setup for approval.
        ExpenseReportApprovalMgmt.GetCurrentUserSetupForApproval(UserSetup);

        // [THEN] The current user's User Setup record is returned without error.
        UserSetup.TestField("User ID", CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID")));
    end;

    [Test]
    procedure ManagerExpenseReportSurfacesMissingUserSetupError()
    var
        ManagerExpenseReportPage: TestPage "Manager Expense Report";
    begin
        // [SCENARIO 645040] Opening Manager Expense Report raises the actionable error when approval workflow is enabled and the current user is not on the User Setup page.
        Initialize();

        // [GIVEN] Approval workflow is enabled.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [WHEN] Opening the Manager Expense Report page.
        asserterror ManagerExpenseReportPage.OpenView();

        // [THEN] The actionable missing-User-Setup error is raised for the current user.
        Assert.ExpectedError(StrSubstNo(MissingUserSetupErr, UserId()));
    end;

    // [Test] // Disabled - will be re-enabled in work item 629484
    procedure ExpenseApprovalSetup_MissingEntraId_ThrowsError()
    var
        ExpenseUser: Record "Expense User";
        ApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 624749] Verify Creating Expense Approval Setup for user without Entra Id throws error.
        Initialize();

        // [GIVEN] Enable SaaS feature.
        EnableSaaS(true);

        // [GIVEN] Create Expense User without Entra Id.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Try to create Expense Approval Setup.
        ApprovalSetup.Init();
        asserterror ApprovalSetup.Validate("Expense User No.", ExpenseUser."No.");

        // [THEN] Verify that an error is thrown when trying to create Expense Approval Setup for user without Entra Id.
        Assert.ExpectedError(ExpenseUser.FieldCaption("Entra Id"));
    end;

    [Test]
    procedure CannotEnableApprovalWorkflow_WhenAgentIsEnabled()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 621999] Verify that approval workflow cannot be enabled if agent is enabled.
        Initialize();

        // [GIVEN] Set "Enable Agent" to true in "Expense Agent Setup".
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Enable Agent" := true;
        ExpenseAgentSetup.Modify(true);

        // [WHEN] Enable Approval Workflow.
        asserterror LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [THEN] Verify that an error is thrown when trying to enable approval workflow.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("Enable Agent"), Format(false));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ApproveExpenseReportFromExpenseReportCardInAgentMode()
    var
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 642008] Assigned approver can approve an expense report from the Expense Report card page in agent mode.
        Initialize();

        // [GIVEN] Enable Agent.
        EnableAgent(true);

        // [GIVEN] Setup where the current user is the assigned approver.
        CreateSetupWhereCurrentUserIsApprover(ExpenseUser);

        // [GIVEN] Create and Release Expense Report for the submitter.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser[1]."No.");

        // [GIVEN] Expense Report is pending approval with the current user as approver.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
        VerifyApproverInExpenseReport(ExpenseReportHeader, ExpenseUser[2]."No.", CopyStr(UserId(), 1, 50));

        // [WHEN] Open the Expense Report card page and invoke Approve.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);
        Assert.IsTrue(ExpenseReportPage.Approve.Visible(), ApproveActionMustBeVisibleErr);
        ExpenseReportPage.Approve.Invoke();
        ExpenseReportPage.Close();

        // [THEN] Expense Report status is set to Approved.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Approved");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure RejectExpenseReportFromExpenseReportCardInAgentMode()
    var
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 642008] Assigned approver can reject an expense report from the Expense Report card page in agent mode.
        Initialize();

        // [GIVEN] Enable Agent.
        EnableAgent(true);

        // [GIVEN] Setup where the current user is the assigned approver.
        CreateSetupWhereCurrentUserIsApprover(ExpenseUser);

        // [GIVEN] Create and Release Expense Report for the submitter.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);

        // [GIVEN] Submit Expense Report for Approval.
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser[1]."No.");

        // [GIVEN] Expense Report is pending approval with the current user as approver.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
        VerifyApproverInExpenseReport(ExpenseReportHeader, ExpenseUser[2]."No.", CopyStr(UserId(), 1, 50));

        // [WHEN] Open the Expense Report card page and invoke Reject.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);
        Assert.IsTrue(ExpenseReportPage.Reject.Visible(), RejectActionMustBeVisibleErr);
        ExpenseReportPage.Reject.Invoke();
        ExpenseReportPage.Close();

        // [THEN] Expense Report status is set to Rejected.
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Rejected");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ApproveActionNotVisibleWhenAgentDisabledOnExpenseReportCard()
    var
        ExpenseUser: array[2] of Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [SCENARIO 642008] Approve/Reject actions are not visible on the Expense Report card page when Agent is not enabled.
        Initialize();

        // [GIVEN] Enable Agent to set up the approver and submit the report.
        EnableAgent(true);

        // [GIVEN] Setup where the current user is the assigned approver.
        CreateSetupWhereCurrentUserIsApprover(ExpenseUser);

        // [GIVEN] Create, Release and Submit Expense Report for Approval.
        CreateAndReleaseExpenseReport(ExpenseUser, ExpenseReportHeader);
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser[1]."No.");
        VerifyExpenseReportDocumentStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [GIVEN] Disable Agent.
        EnableAgent(false);

        // [WHEN] Open the Expense Report card page.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);

        // [THEN] Approve action is not visible.
        Assert.IsFalse(ExpenseReportPage.Approve.Visible(), ApproveActionMustNotBeVisibleErr);
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        User: Record User;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"WF Demo Exp. Report Approvals");
        LibraryVariableStorage.Clear();
        EnableSaaS(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        ResetApprovalAndAgentSetup();
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        // Remove test-created users to stay within the CI license user cap; keep the current session user.
        User.SetFilter("User Security ID", '<>%1', UserSecurityId());
        User.DeleteAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"WF Demo Exp. Report Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"WF Demo Exp. Report Approvals");
    end;

    local procedure CreateExpense(var Expense: Record Expense; ExpenseUser: Record "Expense User"; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
    begin
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', Refundable, CurrencyCode, Amount);
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, ExpenseCategory.Code, ExpenseUser."No.");
    end;

    local procedure CreateAndReleaseExpenseReport(ExpenseUser: array[2] of Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header")
    var
        Expense: Record Expense;
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
    begin
        CreateExpense(Expense, ExpenseUser[1], true, '', LibraryRandom.RandIntInRange(5000, 10000));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser[1]."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        ReleaseExpenseReportDocument.PerformManualCheckAndRelease(ExpenseReportHeader);
    end;

    local procedure SubmitExpenseReportForApproval(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportPage: TestPage "Expense Report";
    begin
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);
        ExpenseReportPage.Submit.Invoke();
        ExpenseReportPage.Close();
    end;

    local procedure ApproveExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ManagerExpenseReportPage: TestPage "Manager Expense Report";
    begin
        ManagerExpenseReportPage.OpenView();
        ManagerExpenseReportPage.GotoRecord(ExpenseReportHeader);
        ManagerExpenseReportPage.Approve.Invoke();
        ManagerExpenseReportPage.Close();
    end;

    local procedure ReopenApprovedExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ManagerExpenseReportPage: TestPage "Manager Expense Report";
    begin
        ManagerExpenseReportPage.OpenView();
        ManagerExpenseReportPage.GotoRecord(ExpenseReportHeader);
        ManagerExpenseReportPage.ReopenApproved.Invoke();
        ManagerExpenseReportPage.Close();
    end;

    local procedure RejectExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ManagerExpenseReportPage: TestPage "Manager Expense Report";
    begin
        ManagerExpenseReportPage.OpenView();
        ManagerExpenseReportPage.GotoRecord(ExpenseReportHeader);
        ManagerExpenseReportPage.Reject.Invoke();
        ManagerExpenseReportPage.Close();
    end;

    local procedure ReopenSubmittedExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportPage: TestPage "Expense Report";
    begin
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GotoRecord(ExpenseReportHeader);
        ExpenseReportPage.ReopenSubmitted.Invoke();
        ExpenseReportPage.Close();
    end;

    local procedure VerifyExpenseReportDocumentStatus(ExpenseReportHeader: Record "Expense Report Header"; Status: Enum "Expense Report Status")
    begin
        ExpenseReportHeader.SetRecFilter();
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.TestField(Status, Status);
    end;

    local procedure CreateUserSetupsAndChainOfApprovers(var CurrentUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var ExpenseUser: array[2] of Record "Expense User")
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        UserEmail: Text[80];
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, CopyStr(UserId, 1, 50));

        UserEmail := GenerateUniqueEmail();
        CreateAndUpdateUserWithEmail(CurrentUserSetup."User ID", UserEmail);

        LibraryExpense.CreateExpenseUser(ExpenseUser[1]);
        ExpenseUser[1].Validate("E-mail", UserEmail);
        ExpenseUser[1].Validate("Can Approve", true);
        ExpenseUser[1].Validate("Entra Id", CreateGuid());
        ExpenseUser[1].Modify();

        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        UserEmail := FinalApproverUserSetup."User ID" + '@' + 'example.com';
        CreateAndUpdateUserWithEmail(FinalApproverUserSetup."User ID", UserEmail);

        LibraryExpense.CreateExpenseUser(ExpenseUser[2]);
        ExpenseUser[2].Validate("E-mail", UserEmail);
        ExpenseUser[2].Validate("Can Approve", true);
        ExpenseUser[2].Validate("Entra Id", CreateGuid());
        ExpenseUser[2].Modify();

        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser[1]."No.", ExpenseUser[2]."No.");
    end;

    local procedure CreateSetupWhereCurrentUserIsApprover(var ExpenseUser: array[2] of Record "Expense User")
    var
        CurrentUserSetup: Record "User Setup";
        SubmitterUserSetup: Record "User Setup";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        UserEmail: Text[80];
    begin
        // [1] Submitter / report owner - a different user than the current one.
        LibraryDocumentApprovals.CreateMockupUserSetup(SubmitterUserSetup);
        UserEmail := SubmitterUserSetup."User ID" + '@' + 'example.com';
        CreateAndUpdateUserWithEmail(SubmitterUserSetup."User ID", UserEmail);

        LibraryExpense.CreateExpenseUser(ExpenseUser[1]);
        ExpenseUser[1].Validate("E-mail", UserEmail);
        ExpenseUser[1].Validate("Entra Id", CreateGuid());
        ExpenseUser[1].Modify();

        // [2] Approver - the current user.
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, CopyStr(UserId, 1, 50));
        UserEmail := GenerateUniqueEmail();
        CreateAndUpdateUserWithEmail(CopyStr(UserId(), 1, 50), UserEmail);

        LibraryExpense.CreateExpenseUser(ExpenseUser[2]);
        ExpenseUser[2].Validate("E-mail", UserEmail);
        ExpenseUser[2].Validate("Can Approve", true);
        ExpenseUser[2].Validate("Entra Id", CreateGuid());
        ExpenseUser[2]."User Id For Approvals" := CopyStr(UserId(), 1, 50);
        ExpenseUser[2].Modify();

        // Submitter's approver is the current user.
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser[1]."No.", ExpenseUser[2]."No.");
    end;

    local procedure EnableAgent(Enable: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Enable Agent" := Enable;
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure ResetApprovalAndAgentSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Enable Approval Workflow" := false;
        ExpenseAgentSetup."Enable Agent" := false;
        ExpenseAgentSetup.Modify();
    end;

    local procedure CreateAndUpdateUserWithEmail(UserName: Code[50]; UserEmail: Text[80])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            User."Authentication Email" := UserEmail;
            User.Modify();
        end else
            CreateUserWithEmail(UserName, UserEmail);
    end;

    local procedure CreateUserWithEmail(UserName: Code[50]; UserEmail: Text[80])
    var
        User: Record User;
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := UserName;
        User."Authentication Email" := UserEmail;
        User.Insert(true);
    end;

    local procedure GenerateUniqueEmail(): Text[80]
    begin
        // A globally unique authentication email. LibraryUtility.GenerateRandomEmail() is deterministic per test
        // (the framework resets the random seed each test), which causes duplicate authentication email collisions
        // across tests when the session user record is reused.
        exit(CopyStr(DelChr(LowerCase(Format(CreateGuid())), '=', '{}-') + '@test.local', 1, 80));
    end;

    local procedure VerifyApproverInExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ApproverExpenseUserNo: Code[20]; ApproverExpenseUserID: Code[50])
    begin
        ExpenseReportHeader.SetRecFilter();
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.TestField("Approver Expense User No.", ApproverExpenseUserNo);
        ExpenseReportHeader.TestField("Approver Expense User ID", ApproverExpenseUserID);
    end;

    local procedure UpdateExpenseAccountInEmployeePostingGroup(var ExpenseUser: Record "Expense User"; CategoryCode: Code[20]; ExpenseUserNo: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
    begin
        ExpenseCategory.Get(CategoryCode);
        ExpenseUser.Get(ExpenseUserNo);
        Employee.Get(ExpenseUser."Employee No.");

        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure EnableSaaS(IsSaaS: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}