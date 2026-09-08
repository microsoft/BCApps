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

codeunit 148346 "Expense Interim Approval Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Interim Approval] [Expense Report]
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
        InterimApproverAgentRequiredErr: Label 'An interim approver can only be assigned when the agent is enabled in %1.', Comment = '%1 = Expense Agent Setup table caption';
        InterimApproverStatusErr: Label 'You can only assign an interim approver while the expense report is %1.', Comment = '%1 = Pending Approval status caption';
        InterimApproverRequiredErr: Label 'Select an interim approver from the available approvers.';
        InterimApproverConflictErr: Label 'The %1 cannot be the same as the %2 (value: %3).', Comment = '%1 = Interim Approver No. caption, %2 = conflicting field caption, %3 = conflicting field value';
        InterimApproverCannotFinalizeErr: Label '%1 %2 cannot give final approval. Final approval must be completed by a different approver.', Comment = '%1 = Interim Approver No. caption, %2 = Interim Approver No.';
        ActorNotActiveApproverErr: Label 'This expense report is awaiting approval from %1. Only that approver can approve or reject it.', Comment = '%1 = Expense User No. of the approver the report is currently assigned to';
        ApprovalLimitMustNotBeNegativeErr: Label '%1 must not be negative.', Comment = '%1 = Approval Limit field caption';
        ApproverRequiredErr: Label 'Expense report %1 exceeds the %2 for approver %3. Configure the approver in Expense Approval Setup.', Comment = '%1 = Expense report number, %2 = Approval Limit field caption, %3 = Expense User number';
        ApproverMustBeEnabledInExpenseUserErr: Label '%1 must be enabled to approve or reject expense reports in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';
        ApproverApprovalLimitErr: Label 'Expense report %1 exceeds the %2 for approver %3.', Comment = '%1 = Expense report number, %2 = Approval Limit field caption, %3 = Expense User number';
        NotAuthorizedToRecallExpReportErr: Label 'Only the original submitter or a user with %1 can recall a submitted expense report.', Comment = '%1 = Unlimited Approval field caption';
        ExpenseUserConfiguredForDifferentUserErr: Label '%1 must be %2 to select this %3 %4.', Comment = '%1 = Field Caption, %2 = User Id, %3 = Table Caption, %4 = Field Value';

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure FinalApproverPrepopulatedFromExpenseUser()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] The Final Approver is prepopulated on the expense report header from the expense user's approver.
        Initialize();

        // [GIVEN] Agent is enabled and a submitter whose designated approver is the final approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);

        // [WHEN] An expense report is created for the submitter.
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);

        // [THEN] The Final Approver No. is prepopulated with the submitter's approver and no interim approver is set.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField("Final Approver No.", FinalApprover."No.");
        ExpenseReportHeader.TestField("Interim Approver No.", '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverRoutesReportThroughFinalApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] With an interim approver assigned, the report goes Pending Approval -> Interim Approved -> Approved.
        Initialize();

        // [GIVEN] Agent is enabled, a submitter, an interim and a final approver, and a submitted expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [THEN] The report is Pending Approval with the final approver as active approver.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
        VerifyActiveApprover(ExpenseReportHeader, FinalApprover);

        // [WHEN] The submitter assigns an interim approver.
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] The interim approver becomes the active approver, status stays Pending Approval.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
        VerifyActiveApprover(ExpenseReportHeader, InterimApprover);

        // [WHEN] The interim approver approves.
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);

        // [THEN] The report moves to Interim Approved and is routed to the final approver.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");
        VerifyActiveApprover(ExpenseReportHeader, FinalApprover);

        // [WHEN] The final approver approves.
        ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);

        // [THEN] The report is Approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ReportWithoutInterimGoesStraightToApproved()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] Without an interim approver, the report goes Pending Approval -> Approved in a single step.
        Initialize();

        // [GIVEN] Agent is enabled and a submitted expense report with no interim approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");

        // [WHEN] The final approver approves.
        ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);

        // [THEN] The report is Approved without passing through Interim Approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignInterimApproverRequiresApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] Assigning a blank interim approver is rejected.
        Initialize();

        // [GIVEN] Agent is enabled and a submitted expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [WHEN] A blank interim approver is assigned.
        asserterror ExpenseReportHeader.AssignInterimApprover('', Submitter."No.");

        // [THEN] An error is raised.
        Assert.ExpectedError(InterimApproverRequiredErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverCannotBeSubmitter()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] The interim approver cannot be the same as the expense user (submitter).
        Initialize();

        // [GIVEN] Agent is enabled and a submitted expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [WHEN] The submitter is assigned as interim approver.
        asserterror ExpenseReportHeader.AssignInterimApprover(Submitter."No.", Submitter."No.");

        // [THEN] An error is raised.
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverConflictErr,
                ExpenseReportHeader.FieldCaption("Interim Approver No."),
                ExpenseReportHeader.FieldCaption("Expense User No."),
                ExpenseReportHeader."Expense User No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverCannotBeFinalApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] The interim approver cannot be the same as the final approver.
        Initialize();

        // [GIVEN] Agent is enabled and a submitted expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [WHEN] The final approver is assigned as interim approver.
        asserterror ExpenseReportHeader.AssignInterimApprover(FinalApprover."No.", Submitter."No.");

        // [THEN] An error is raised.
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverConflictErr,
                ExpenseReportHeader.FieldCaption("Interim Approver No."),
                ExpenseReportHeader.FieldCaption("Final Approver No."),
                ExpenseReportHeader."Final Approver No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignInterimApproverRequiresAgentEnabled()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] An interim approver can only be assigned when the agent is enabled.
        Initialize();

        // [GIVEN] A submitted expense report created while agent was enabled.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [GIVEN] Agent is disabled.
        EnableAgent(false);

        // [WHEN] An interim approver is assigned.
        asserterror ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] An error is raised.
        Assert.ExpectedError(StrSubstNo(InterimApproverAgentRequiredErr, ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignInterimApproverRequiresPendingApproval()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] An interim approver can only be assigned while the report is Pending Approval.
        Initialize();

        // [GIVEN] Agent is enabled and a released (not submitted) expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // [WHEN] An interim approver is assigned before submission.
        asserterror ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] An error is raised.
        Assert.ExpectedError(StrSubstNo(InterimApproverStatusErr, Format(ExpenseReportHeader.Status::"Pending Approval")));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverCannotGiveFinalApproval()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] The interim approver cannot complete the final approval of a report they already interim-approved.
        Initialize();

        // [GIVEN] A report that has been interim approved and is now routed to the final approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");

        // [WHEN] The interim approver tries to give the final approval.
        asserterror ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);

        // [THEN] An error is raised.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverCannotFinalizeErr,
                ExpenseReportHeader.FieldCaption("Interim Approver No."),
                ExpenseReportHeader."Interim Approver No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverCannotRejectAfterInterimApproval()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] The interim approver cannot reject a report they already interim-approved.
        Initialize();

        // [GIVEN] A report that has been interim approved and is now routed to the final approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");

        // [WHEN] The interim approver tries to reject the report.
        asserterror ExpenseReportHeader.PerformManualRejected(InterimApprover."No.", 'Rejected by interim approver.');

        // [THEN] An error is raised.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverCannotFinalizeErr,
                ExpenseReportHeader.FieldCaption("Interim Approver No."),
                ExpenseReportHeader."Interim Approver No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure FinalApproverCannotApproveWhileInterimPending()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] While the report waits for interim approval, an approver other than the interim approver cannot approve it.
        Initialize();

        // [GIVEN] A submitted report with an interim approver assigned and awaiting interim approval.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        VerifyActiveApprover(ExpenseReportHeader, InterimApprover);

        // [WHEN] The final approver tries to approve before the interim approver has acted.
        asserterror ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);

        // [THEN] An error is raised.
        Assert.ExpectedError(StrSubstNo(ActorNotActiveApproverErr, InterimApprover."No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure FinalApproverCannotRejectWhileInterimPending()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] While the report waits for interim approval, an approver other than the interim approver cannot reject it.
        Initialize();

        // [GIVEN] A submitted report with an interim approver assigned and awaiting interim approval.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        VerifyActiveApprover(ExpenseReportHeader, InterimApprover);

        // [WHEN] The final approver tries to reject before the interim approver has acted.
        asserterror ExpenseReportHeader.PerformManualRejected(FinalApprover."No.", 'Rejected by final approver.');

        // [THEN] An error is raised.
        Assert.ExpectedError(StrSubstNo(ActorNotActiveApproverErr, InterimApprover."No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ResubmitAfterRejectRoutesBackToInterim()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 638097] After an interim approver rejects, resubmitting routes the report back to the interim approver.
        Initialize();

        // [GIVEN] A submitted report with an interim approver assigned.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [WHEN] The interim approver rejects the report.
        ExpenseReportHeader.PerformManualRejected(InterimApprover."No.", 'Rejected by interim approver.');

        // [THEN] The report is Rejected.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Rejected);

        // [WHEN] The report is resubmitted.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is Pending Approval again and routed back to the interim approver.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
        VerifyActiveApprover(ExpenseReportHeader, InterimApprover);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionWithinLimitUsesConfiguredApprover()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A report equal to the configured approver's approval limit does not escalate.
        Initialize();

        // [GIVEN] Submitter "S" has configured approver "A1" with an approval limit of 100 and a released expense report for 100.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 100, 100);

        // [WHEN] "S" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is pending approval with "A1" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Approver, Approver);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitRoutesToUnlimitedNextApprover()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A report above the configured approver's limit escalates to an unlimited next approver.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" has next approver "A2" with unlimited approval, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");

        // [WHEN] "S" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is pending approval with "A2" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, NextApprover, NextApprover);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitRoutesToSufficientLimitedNextApprover()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A report above the configured approver's limit routes to a next approver whose limit covers the amount.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" has next approver "A2" with a limit of 200, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        SetApprovalLimit(NextApprover, 200);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");

        // [WHEN] "S" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is pending approval with "A2" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, NextApprover, NextApprover);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitWithoutNextApproverFails()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Submission fails when a report exceeds the configured approver's limit and no next approver exists.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, no next or default approver is configured, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);

        // [WHEN] "S" submits the expense report.
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] An error explains that a next approver must be configured for "A1".
        Assert.ExpectedError(StrSubstNo(ApproverRequiredErr, ExpenseReportHeader."No.", Approver.FieldCaption("Approval Limit"), Approver."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitWithInsufficientNextApproverFails()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Submission fails when the next approver's approval limit is insufficient.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" has next approver "A2" with a limit of 100, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        SetApprovalLimit(NextApprover, 100);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");

        // [WHEN] "S" submits the expense report.
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] An error explains that another approver must be configured for "A2".
        Assert.ExpectedError(StrSubstNo(ApproverRequiredErr, ExpenseReportHeader."No.", NextApprover.FieldCaption("Approval Limit"), NextApprover."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverWithInsufficientLimitCannotBeAssigned()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An interim approver cannot be assigned when the report exceeds their approval limit.
        Initialize();

        // [GIVEN] A submitted report for 200 has final approver "A2", and interim approver "I" has an approval limit of 100.
        CreateSubmittedUnlimitedApprovalScenario(Submitter, FinalApprover, ExpenseReportHeader, 200);
        CreateApproverExpenseUser(InterimApprover);
        SetApprovalLimit(InterimApprover, 100);

        // [WHEN] Submitter "S" assigns "I" as the interim approver.
        asserterror ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] An error explains that the report exceeds "I"'s approval limit.
        Assert.ExpectedError(StrSubstNo(ApproverApprovalLimitErr, ExpenseReportHeader."No.", InterimApprover.FieldCaption("Approval Limit"), InterimApprover."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ApproverWhoseLimitWasReducedCannotApprove()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An active approver cannot approve a report after their approval limit is reduced below its amount.
        Initialize();

        // [GIVEN] A report for 100 is pending approval with active approver "A1", whose approval limit is then reduced from 200 to 50.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 100, 200);
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");
        SetApprovalLimit(Approver, 50);

        // [WHEN] "A1" approves the expense report.
        asserterror ExpenseReportHeader.PerformManualApproved(Approver."No.", true);

        // [THEN] An error explains that the report exceeds "A1"'s approval limit.
        Assert.ExpectedError(StrSubstNo(ApproverApprovalLimitErr, ExpenseReportHeader."No.", Approver.FieldCaption("Approval Limit"), Approver."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ReopenApprovedRecalculatesEscalatedApprover()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Reopening an approved report recalculates escalation using the current approval limits.
        Initialize();

        // [GIVEN] Approver "A1" approved a report for 200 with a limit of 300, then "A1"'s limit is reduced to 100 and unlimited next approver "A2" is configured.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 300);
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(Approver."No.", true);
        SetApprovalLimit(Approver, 100);
        CreateApproverExpenseUser(NextApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");
        SetCurrentUser(Approver);

        // [WHEN] The approved expense report is reopened.
        ExpenseReportApprovalMgmt.ReopenApproved(ExpenseReportHeader);

        // [THEN] The report is pending approval with "A2" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, NextApprover, NextApprover);
    end;

    [Test]
    procedure UnlimitedApprovalWithoutCanApproveIsNotAdministrator()
    var
        Approver: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Unlimited approval alone does not grant approval-administrator access.
        Initialize();

        // [GIVEN] Expense user "A1" has unlimited approval and approval rights are removed.
        CreateApproverExpenseUser(Approver);
        SetCurrentUser(Approver);
        Approver."Can Approve" := false;
        Approver.Modify();

        // [WHEN] Approval-administrator access is evaluated for "A1".

        // [THEN] "A1" is not an approval administrator.
        Assert.IsFalse(ExpenseReportApprovalMgmt.IsApprovalAdministrator(), 'Unlimited approval without approval rights must not grant administrator access.');
    end;

    [Test]
    procedure NegativeApprovalLimitCannotBeSet()
    var
        Approver: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An approval limit cannot be negative.
        Initialize();

        // [GIVEN] Approver "A1" exists.
        CreateApproverExpenseUser(Approver);

        // [WHEN] The approval limit of "A1" is set to -100.
        asserterror Approver.Validate("Approval Limit", -100);

        // [THEN] An error explains that the approval limit must not be negative.
        Assert.ExpectedError(StrSubstNo(ApprovalLimitMustNotBeNegativeErr, Approver.FieldCaption("Approval Limit")));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SettingApprovalLimitClearsUnlimitedApproval()
    var
        Approver: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Setting a positive approval limit removes unlimited approval.
        Initialize();

        // [GIVEN] Approver "A1" has unlimited approval.
        CreateApproverExpenseUser(Approver);

        // [WHEN] The approval limit of "A1" is set to 100.
        Approver.Validate("Approval Limit", 100);
        Approver.Modify();

        // [THEN] The approval limit is 100 and unlimited approval is disabled.
        Approver.Get(Approver."No.");
        Approver.TestField("Approval Limit", 100);
        Approver.TestField("Unlimited Approval", false);
    end;

    [Test]
    procedure EnablingUnlimitedApprovalClearsApprovalLimit()
    var
        Approver: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Enabling unlimited approval clears an existing approval limit.
        Initialize();

        // [GIVEN] Approver "A1" has an approval limit of 100.
        CreateApproverExpenseUser(Approver);
        Approver.Validate("Approval Limit", 100);

        // [WHEN] Unlimited approval is enabled for "A1".
        Approver.Validate("Unlimited Approval", true);
        Approver.Modify();

        // [THEN] Unlimited approval is enabled and the approval limit is 0.
        Approver.Get(Approver."No.");
        Approver.TestField("Unlimited Approval", true);
        Approver.TestField("Approval Limit", 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionBelowLimitUsesConfiguredApprover()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A report below the configured approver's approval limit does not escalate.
        Initialize();

        // [GIVEN] Submitter "S" has configured approver "A1" with a limit of 200 and a released expense report for 100.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 100, 200);

        // [WHEN] "S" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is pending approval with "A1" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Approver, Approver);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionWithUnlimitedConfiguredApproverDoesNotEscalate()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A configured approver with unlimited approval receives the report without escalation.
        Initialize();

        // [GIVEN] Submitter "S" has unlimited configured approver "A1" and a released expense report for 200.
        CreateSubmitterExpenseUser(Submitter);
        CreateApproverExpenseUser(Approver);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Submitter."No.", Approver."No.");
        CreateAndReleaseExpenseReportWithAmount(Submitter, ExpenseReportHeader, 200);

        // [WHEN] "S" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is pending approval with "A1" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Approver, Approver);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitUsesUnlimitedDefaultApprover()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        DefaultApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Escalation uses the unlimited default approver when the current approver has no configured next approver.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" has no next approver, default approver "A2" has unlimited approval, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(DefaultApprover);
        SetDefaultApprover(DefaultApprover."No.");

        // [WHEN] "S" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is pending approval with "A2" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, DefaultApprover, DefaultApprover);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitWithCurrentApproverAsNextFails()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Submission fails when escalation resolves back to the current approver.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" is configured as their own next approver, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", Approver."No.");

        // [WHEN] "S" submits the expense report.
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] An error explains that a different next approver must be configured for "A1".
        Assert.ExpectedError(StrSubstNo(ApproverRequiredErr, ExpenseReportHeader."No.", Approver.FieldCaption("Approval Limit"), Approver."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitWithNextApproverWithoutUserIdFails()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Submission fails when the unlimited next approver has no approval user ID.
        Initialize();

        // [GIVEN] Submitter "S" has limited approver "A1", whose unlimited next approver "A2" has no user ID for approvals, and the released report amount exceeds "A1"'s limit.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        NextApprover."User Id For Approvals" := '';
        NextApprover.Modify();
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");

        // [WHEN] "S" submits the expense report.
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] An error explains that the user ID for approvals must be configured for "A2".
        Assert.ExpectedError(NextApprover.FieldCaption("User Id For Approvals"));
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitWithIneligibleNextApproverFails()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Submission fails when the unlimited next approver no longer has approval rights.
        Initialize();

        // [GIVEN] Submitter "S" has limited approver "A1", whose unlimited next approver "A2" cannot approve, and the released report amount exceeds "A1"'s limit.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");
        NextApprover."Can Approve" := false;
        NextApprover.Modify();

        // [WHEN] "S" submits the expense report.
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] An error explains that approval rights must be enabled for "A2".
        Assert.ExpectedError(StrSubstNo(ApproverMustBeEnabledInExpenseUserErr, NextApprover.FieldCaption("Can Approve"), NextApprover.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverAtLimitCanBeAssigned()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An interim approver can be assigned when the report amount equals their approval limit.
        Initialize();

        // [GIVEN] A submitted report for 100 has final approver "A2", and interim approver "I" has an approval limit of 100.
        CreateSubmittedUnlimitedApprovalScenario(Submitter, FinalApprover, ExpenseReportHeader, 100);
        CreateApproverExpenseUser(InterimApprover);
        SetApprovalLimit(InterimApprover, 100);

        // [WHEN] Submitter "S" assigns "I" as the interim approver.
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] "I" becomes the active interim approver and the report remains pending approval.
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure UnlimitedInterimApproverCanBeAssignedAboveAmount()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An interim approver with unlimited approval can be assigned for any report amount.
        Initialize();

        // [GIVEN] A submitted report for 200 has final approver "A2", and interim approver "I" has unlimited approval.
        CreateSubmittedUnlimitedApprovalScenario(Submitter, FinalApprover, ExpenseReportHeader, 200);
        CreateApproverExpenseUser(InterimApprover);

        // [WHEN] Submitter "S" assigns "I" as the interim approver.
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] "I" becomes the active interim approver and the report remains pending approval.
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ApproverAtLimitCanApprove()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An active approver can approve a report equal to their approval limit.
        Initialize();

        // [GIVEN] A report for 100 is pending approval with active approver "A1", whose approval limit is 100.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 100, 100);
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [WHEN] "A1" approves the expense report.
        ExpenseReportHeader.PerformManualApproved(Approver."No.", true);

        // [THEN] The expense report is approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure UnlimitedApproverCanApproveAboveAmount()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An active approver with unlimited approval can approve any report amount.
        Initialize();

        // [GIVEN] A report for 200 is pending approval with unlimited active approver "A1".
        CreateSubmittedUnlimitedApprovalScenario(Submitter, Approver, ExpenseReportHeader, 200);

        // [WHEN] "A1" approves the expense report.
        ExpenseReportHeader.PerformManualApproved(Approver."No.", true);

        // [THEN] The expense report is approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure LimitedApproverCanRejectAfterLimitReduction()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Approval limits do not prevent an active approver from rejecting a report.
        Initialize();

        // [GIVEN] A report for 100 is pending approval with active approver "A1", whose approval limit is then reduced from 200 to 50.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 100, 200);
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");
        SetApprovalLimit(Approver, 50);

        // [WHEN] "A1" rejects the expense report.
        ExpenseReportHeader.PerformManualRejected(Approver."No.", 'Limit reduced.');

        // [THEN] The expense report is rejected.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ReopenApprovedUsesConfiguredApproverAfterLimitIncrease()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Reopening an approved report removes escalation when the configured approver's limit now covers the amount.
        Initialize();

        // [GIVEN] Unlimited approver "A2" approved a report for 200 after escalation from "A1", then "A1"'s approval limit is increased to 300.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(NextApprover."No.", true);
        SetApprovalLimit(Approver, 300);
        SetCurrentUser(NextApprover);

        // [WHEN] The approved expense report is reopened.
        ExpenseReportApprovalMgmt.ReopenApproved(ExpenseReportHeader);

        // [THEN] The report is pending approval with configured approver "A1" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Approver, Approver);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ReopenApprovedRoutesToInterimBeforeEscalatedFinalApprover()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Reopening an approved report restarts its interim stage before the recalculated final approver.
        Initialize();

        // [GIVEN] A report for 200 has assigned interim approver "I", limited configured approver "A1", unlimited final approver "A2", and status Approved.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(FinalApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", FinalApprover."No.");
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");
        CreateApproverExpenseUser(InterimApprover);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);
        ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);
        SetCurrentUser(FinalApprover);

        // [WHEN] The approved expense report is reopened.
        ExpenseReportApprovalMgmt.ReopenApproved(ExpenseReportHeader);

        // [THEN] The report is pending approval with "I" active and "A2" retained as final approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
    end;

    [Test]
    procedure UnlimitedApproverIsAdministrator()
    var
        Approver: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An approver with unlimited approval is an approval administrator.
        Initialize();

        // [GIVEN] Expense user "A1" can approve and has unlimited approval.
        CreateApproverExpenseUser(Approver);
        SetCurrentUser(Approver);

        // [WHEN] Approval-administrator access is evaluated for "A1".

        // [THEN] "A1" is an approval administrator.
        Assert.IsTrue(ExpenseReportApprovalMgmt.IsApprovalAdministrator(), 'An unlimited approver must have administrator access.');
    end;

    [Test]
    procedure LimitedApproverIsNotAdministrator()
    var
        Approver: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A limited approver is not an approval administrator.
        Initialize();

        // [GIVEN] Expense user "A1" can approve and has an approval limit of 100.
        CreateApproverExpenseUser(Approver);
        SetApprovalLimit(Approver, 100);
        SetCurrentUser(Approver);

        // [WHEN] Approval-administrator access is evaluated for "A1".

        // [THEN] "A1" is not an approval administrator.
        Assert.IsFalse(ExpenseReportApprovalMgmt.IsApprovalAdministrator(), 'A limited approver must not have administrator access.');
    end;

    [Test]
    procedure UnlimitedApproverCanCreateReportForAnotherExpenseUser()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An unlimited approver can create an expense report for another expense user while approval workflow is enabled.
        Initialize();

        // [GIVEN] Approval workflow is enabled, expense user "A1" can approve with unlimited approval, and expense user "S" exists.
        EnableApprovalWorkflow();
        CreateApproverExpenseUser(Approver);
        SetCurrentUser(Approver);
        CreateSubmitterExpenseUser(Submitter);

        // [WHEN] "A1" creates an expense report for "S".
        ExpenseReportHeader.Init();
        ExpenseReportHeader.Validate("Expense User No.", Submitter."No.");
        ExpenseReportHeader.Insert(true);

        // [THEN] The expense report is created for "S" without an authorization error.
        ExpenseReportHeader.TestField("Expense User No.", Submitter."No.");
    end;

    [Test]
    procedure LimitedApproverCannotCreateReportForAnotherExpenseUser()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A limited approver cannot create an expense report for another expense user while approval workflow is enabled.
        Initialize();

        // [GIVEN] Approval workflow is enabled, expense user "A1" has an approval limit of 100, and expense user "S" exists.
        EnableApprovalWorkflow();
        CreateApproverExpenseUser(Approver);
        SetApprovalLimit(Approver, 100);
        SetCurrentUser(Approver);
        CreateSubmitterExpenseUser(Submitter);

        // [WHEN] "A1" creates an expense report for "S".
        ExpenseReportHeader.Init();
        asserterror ExpenseReportHeader.Validate("Expense User No.", Submitter."No.");

        // [THEN] An authorization error explains that "S" is configured for a different user.
        Assert.ExpectedError(StrSubstNo(ExpenseUserConfiguredForDifferentUserErr, Submitter.FieldCaption("User Id For Approvals"), UserId(), Submitter.TableCaption(), Submitter."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure UnlimitedApproverCanRecallAnotherUsersReport()
    var
        Submitter: Record "Expense User";
        ReportApprover: Record "Expense User";
        Administrator: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An unlimited approver can recall another expense user's submitted report as administrator.
        Initialize();

        // [GIVEN] Expense user "A1" can approve with unlimited approval and submitter "S" has a pending expense report.
        CreateSubmittedUnlimitedApprovalScenario(Submitter, ReportApprover, ExpenseReportHeader, 100);
        CreateApproverExpenseUser(Administrator);
        SetCurrentUser(Administrator);

        // [WHEN] "A1" recalls the expense report.
        ExpenseReportApprovalMgmt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] The report is open and the recall is logged with the administrator role.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Open);
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.FindLast();
        ExpenseActivityLogEntry.TestField("Event Type", Enum::"Expense Activity Event Type"::Recalled);
        ExpenseActivityLogEntry.TestField("Actor Role", Enum::"Expense Activity Actor Role"::Administrator);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure LimitedApproverCannotRecallAnotherUsersReport()
    var
        Submitter: Record "Expense User";
        ReportApprover: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] A limited approver cannot recall another expense user's submitted report.
        Initialize();

        // [GIVEN] Expense user "A1" has an approval limit of 100 and submitter "S" has a pending expense report.
        CreateSubmittedUnlimitedApprovalScenario(Submitter, ReportApprover, ExpenseReportHeader, 100);
        CreateApproverExpenseUser(Approver);
        SetApprovalLimit(Approver, 100);
        SetCurrentUser(Approver);

        // [WHEN] "A1" recalls the expense report.
        asserterror ExpenseReportApprovalMgmt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] An authorization error explains that only the submitter or an unlimited approver can recall it.
        Assert.ExpectedError(StrSubstNo(NotAuthorizedToRecallExpReportErr, Approver.FieldCaption("Unlimited Approval")));
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        User: Record User;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Interim Approval Test");
        LibraryVariableStorage.Clear();
        EnableSaaS(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        // Remove test-created users to stay within the CI license user cap; keep the current session user.
        User.SetFilter("User Security ID", '<>%1', UserSecurityId());
        User.DeleteAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Interim Approval Test");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Interim Approval Test");
    end;

    local procedure CreateInterimApprovalSetup(var Submitter: Record "Expense User"; var InterimApprover: Record "Expense User"; var FinalApprover: Record "Expense User")
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CreateSubmitterExpenseUser(Submitter);
        CreateApproverExpenseUser(InterimApprover);
        CreateApproverExpenseUser(FinalApprover);
        // The submitter's designated approver is the final approver, so the Final Approver No. prepopulates to it.
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Submitter."No.", FinalApprover."No.");
    end;

    local procedure CreateSubmitterExpenseUser(var ExpenseUser: Record "Expense User")
    var
        UserSetup: Record "User Setup";
        UserEmail: Text[80];
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        UserEmail := GenerateUniqueEmail();
        CreateAndUpdateUserWithEmail(UserSetup."User ID", UserEmail);

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Validate("Entra Id", CreateGuid());
        ExpenseUser.Modify();
    end;

    local procedure CreateApproverExpenseUser(var ExpenseUser: Record "Expense User")
    var
        UserSetup: Record "User Setup";
        UserEmail: Text[80];
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        UserEmail := GenerateUniqueEmail();
        CreateAndUpdateUserWithEmail(UserSetup."User ID", UserEmail);

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("E-mail", UserEmail);
        ExpenseUser.Validate("Can Approve", true);
        ExpenseUser.Validate("Unlimited Approval", true);
        ExpenseUser.Validate("Entra Id", CreateGuid());
        ExpenseUser.Modify();
    end;

    local procedure CreateSubmittedExpenseReport(Submitter: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header")
    begin
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
    end;

    local procedure CreateApprovalLimitScenario(var Submitter: Record "Expense User"; var Approver: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header"; Amount: Decimal; ApprovalLimit: Decimal)
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CreateSubmitterExpenseUser(Submitter);
        CreateApproverExpenseUser(Approver);
        SetApprovalLimit(Approver, ApprovalLimit);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Submitter."No.", Approver."No.");
        CreateAndReleaseExpenseReportWithAmount(Submitter, ExpenseReportHeader, Amount);
    end;

    local procedure CreateSubmittedUnlimitedApprovalScenario(var Submitter: Record "Expense User"; var Approver: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header"; Amount: Decimal)
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CreateSubmitterExpenseUser(Submitter);
        CreateApproverExpenseUser(Approver);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Submitter."No.", Approver."No.");
        CreateAndReleaseExpenseReportWithAmount(Submitter, ExpenseReportHeader, Amount);
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
    end;

    local procedure SetApprovalLimit(var Approver: Record "Expense User"; ApprovalLimit: Decimal)
    begin
        Approver.Validate("Approval Limit", ApprovalLimit);
        Approver.Modify();
    end;

    local procedure SetDefaultApprover(ApproverNo: Code[20])
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.Validate("Default Approver No.", ApproverNo);
        ExpenseAgentSetup.Modify();
    end;

    local procedure SetCurrentUser(var ExpenseUser: Record "Expense User")
    begin
        ExpenseUser."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(ExpenseUser."User Id For Approvals"));
        ExpenseUser.Modify();
    end;

    local procedure EnableApprovalWorkflow()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Enable Approval Workflow" := true;
        ExpenseAgentSetup.Modify();
    end;

    local procedure CreateAndReleaseExpenseReportWithAmount(Submitter: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header"; Amount: Decimal)
    var
        Expense: Record Expense;
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
    begin
        CreateExpense(Expense, Submitter, Amount);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Submitter."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        ReleaseExpenseReportDocument.PerformManualCheckAndRelease(ExpenseReportHeader);
        ExpenseReportHeader.CalcFields("Amount (LCY)");
        Assert.AreEqual(Amount, ExpenseReportHeader."Amount (LCY)", 'The expense report amount must match the scenario amount.');
    end;

    local procedure CreateAndReleaseExpenseReport(Submitter: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header")
    var
        Expense: Record Expense;
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
    begin
        CreateExpense(Expense, Submitter, LibraryRandom.RandIntInRange(5000, 10000));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Submitter."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        ReleaseExpenseReportDocument.PerformManualCheckAndRelease(ExpenseReportHeader);
    end;

    local procedure CreateExpense(var Expense: Record Expense; ExpenseUser: Record "Expense User"; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
    begin
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', Amount);
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, ExpenseCategory.Code);
    end;

    local procedure UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser: Record "Expense User"; CategoryCode: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
    begin
        ExpenseCategory.Get(CategoryCode);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure EnableAgent(Enable: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Enable Agent" := Enable;
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure CreateAndUpdateUserWithEmail(UserName: Code[50]; UserEmail: Text[80])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            User."Authentication Email" := UserEmail;
            User.Modify();
        end else begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := UserName;
            User."Authentication Email" := UserEmail;
            User.Insert(true);
        end;
    end;

    local procedure GenerateUniqueEmail(): Text[80]
    begin
        // A globally unique authentication email to avoid duplicate authentication email collisions across tests.
        exit(CopyStr(DelChr(LowerCase(Format(CreateGuid())), '=', '{}-') + '@test.local', 1, 80));
    end;

    local procedure VerifyStatus(var ExpenseReportHeader: Record "Expense Report Header"; ExpectedStatus: Enum "Expense Report Status")
    begin
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField(Status, ExpectedStatus);
    end;

    local procedure VerifyActiveApprover(var ExpenseReportHeader: Record "Expense Report Header"; Approver: Record "Expense User")
    begin
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField("Approver Expense User No.", Approver."No.");
        ExpenseReportHeader.TestField("Approver Expense User ID", Approver."User Id For Approvals");
    end;

    local procedure VerifyApprovalRouting(var ExpenseReportHeader: Record "Expense Report Header"; ActiveApprover: Record "Expense User"; FinalApprover: Record "Expense User")
    begin
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
        VerifyActiveApprover(ExpenseReportHeader, ActiveApprover);
        ExpenseReportHeader.TestField("Final Approver No.", FinalApprover."No.");
    end;

    local procedure VerifyInterimApprover(var ExpenseReportHeader: Record "Expense Report Header"; ExpectedInterimNo: Code[20])
    begin
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField("Interim Approver No.", ExpectedInterimNo);
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
}
