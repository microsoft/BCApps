// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.CRM.Team;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;
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
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        IsInitialized: Boolean;
        InterimApproverAgentRequiredErr: Label 'An interim approver can only be assigned when the agent is enabled in %1.', Comment = '%1 = Expense Agent Setup table caption';
        InterimApproverStatusErr: Label 'You can only assign an interim approver while the expense report is %1 or %2.', Comment = '%1 = Released status caption, %2 = Pending Approval status caption';
        InterimApproverActorErr: Label 'Only the expense report owner %1 can assign an interim approver.', Comment = '%1 = Expense User No. of the report owner';
        InterimApproverRequiredErr: Label 'Select an interim approver from the available approvers.';
        InterimApproverConflictErr: Label 'The %1 cannot be the same as the %2 (value: %3).', Comment = '%1 = Interim Approver No. caption, %2 = conflicting field caption, %3 = conflicting field value';
        InterimApproverCannotFinalizeErr: Label '%1 %2 cannot give final approval. Final approval must be completed by a different approver.', Comment = '%1 = Interim Approver No. caption, %2 = Interim Approver No.';
        AlternateApproverStatusErr: Label 'An alternate approver can only be assigned while the expense report is %1 or %2.', Comment = '%1 = Pending Approval status caption, %2 = Interim Approved status caption';
        NoActiveAlternateApproverForDateErr: Label 'No active alternate approver is configured for final approver %1 on %2.', Comment = '%1 = final approver no., %2 = reference date';
        ActorNotActiveApproverErr: Label 'This expense report is awaiting approval from %1. Only that approver can approve or reject it.', Comment = '%1 = Expense User No. of the approver the report is currently assigned to';
        ApprovalLimitMustNotBeNegativeErr: Label '%1 must not be negative.', Comment = '%1 = Approval Limit field caption';
        AlternateApproverDateRangeErr: Label '%1 cannot be after %2.', Comment = '%1 = Effective Start Date field caption, %2 = Effective End Date field caption';
        AlternateApproverOverlappingCoverageErr: Label 'Overlapping alternate coverage exists for primary approver %1.', Comment = '%1 = Primary approver number';
        ApproverRequiredErr: Label 'Expense report %1 exceeds the %2 for approver %3. Configure the approver in Expense Approval Setup.', Comment = '%1 = Expense report number, %2 = Approval Limit field caption, %3 = Expense User number';
        CannotRemovePendingApproverErr: Label 'You cannot remove approval rights from expense user %1 because this user is an interim or final approver for expense report %2 that is pending approval. Complete or reassign the pending approval first.', Comment = '%1 = Expense User No., %2 = Expense Report No.';
        ApproverMustBeEnabledInExpenseUserErr: Label '%1 must be enabled to approve or reject expense reports in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';
        ApproverApprovalLimitErr: Label 'Expense report %1 exceeds the %2 for approver %3.', Comment = '%1 = Expense report number, %2 = Approval Limit field caption, %3 = Expense User number';
        NotAuthorizedToRecallExpReportErr: Label 'Only the original submitter or a user with %1 can recall a submitted expense report.', Comment = '%1 = Unlimited Approval field caption';
        ExpenseUserConfiguredForDifferentUserErr: Label '%1 must be %2 to select this %3 %4.', Comment = '%1 = Field Caption, %2 = User Id, %3 = Table Caption, %4 = Field Value';
        InterimApproverOverwriteNotAllowedErr: Label 'You cannot assign an interim approver because %1 is turned off in %2. The interim approver is assigned from the %3.', Comment = '%1 = Can Overwrite Interim Approver field caption, %2 = Expense Agent Setup table caption, %3 = Expense Approval Setup table caption';
        ApprovalSetupInterimApproverConflictErr: Label '%1 cannot be the same as %2.', Comment = '%1 = Interim Approver field caption, %2 = conflicting field caption';
        InterimApproverRemoveQst: Label 'Expense user %1 was an interim approver for some users. These users will now have no interim approver. Continue?', Comment = '%1 = Expense User No.';
        InterimAlternateAssignedCommentTxt: Label 'Interim approver set to %1 (%2) as alternate for %3 (%4).', Comment = '%1 = Alternate interim approver No., %2 = Alternate interim approver name, %3 = Primary interim approver No., %4 = Primary interim approver name';

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
    procedure AssignInterimApproverBeforeSubmissionKeepsReleasedStatus()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ApproverExpenseUserNoBeforeAssignment: Code[20];
        ApproverExpenseUserIDBeforeAssignment: Code[50];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 657870] An interim approver assigned to a released report is configured without submitting the report.
        Initialize();

        // [GIVEN] Agent is enabled and a released (not submitted) expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ApproverExpenseUserNoBeforeAssignment := ExpenseReportHeader."Approver Expense User No.";
        ApproverExpenseUserIDBeforeAssignment := ExpenseReportHeader."Approver Expense User ID";

        // [WHEN] An interim approver is assigned before submission.
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] The interim approver is configured, the report stays Released and is not awaiting any approver.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Released);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
        ExpenseReportHeader.TestField("Approver Expense User No.", ApproverExpenseUserNoBeforeAssignment);
        ExpenseReportHeader.TestField("Approver Expense User ID", ApproverExpenseUserIDBeforeAssignment);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitWithPreassignedInterimRoutesToInterimFirst()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 657870] Submitting a report with a preassigned interim approver routes it directly to the interim approver, then to the final approver.
        Initialize();

        // [GIVEN] Agent is enabled and a released report with an interim approver assigned before submission.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [WHEN] The report is submitted.
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");

        // [THEN] The report is Pending Approval with the interim approver as the active approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");

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
    procedure AssignInterimApproverOnOpenReportIsBlocked()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 657870] An interim approver cannot be assigned to an open report.
        Initialize();

        // [GIVEN] Agent is enabled and an open expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateOpenExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // Preserve the report when the expected validation error rolls back its transaction.
        Commit();

        // [WHEN] An interim approver is assigned to the open report.
        asserterror ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] The status error is raised and the report stays Open without an interim approver.
        VerifyInterimApproverStatusError();
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Open);
        VerifyInterimApprover(ExpenseReportHeader, '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignInterimApproverBeforeSubmissionChecksConflictAndActor()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 657870] Assigning an interim approver before submission keeps the conflict and owner checks.
        Initialize();

        // [GIVEN] Agent is enabled and a released (not submitted) expense report.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // Preserve the report when the expected validation errors roll back their transactions.
        Commit();

        // [WHEN] The final approver is assigned as interim approver before submission.
        asserterror ExpenseReportHeader.AssignInterimApprover(FinalApprover."No.", Submitter."No.");

        // [THEN] The conflict error is raised.
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverConflictErr,
                ExpenseReportHeader.FieldCaption("Interim Approver No."),
                ExpenseReportHeader.FieldCaption("Final Approver No."),
                ExpenseReportHeader."Final Approver No."));

        // [WHEN] Someone other than the report owner assigns an interim approver before submission.
        asserterror ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", FinalApprover."No.");

        // [THEN] The owner error is raised and no interim approver is configured.
        Assert.ExpectedError(StrSubstNo(InterimApproverActorErr, Submitter."No."));
        VerifyInterimApprover(ExpenseReportHeader, '');
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignInterimApproverBlockedAfterInterimApproval()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        OtherApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 657870] An interim approver cannot be assigned once the report is Interim Approved or Approved.
        Initialize();

        // [GIVEN] Agent is enabled and a report approved by its interim approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(OtherApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");

        // Preserve the report when the expected validation error rolls back its transaction.
        Commit();

        // [WHEN] An interim approver is assigned to the Interim Approved report.
        asserterror ExpenseReportHeader.AssignInterimApprover(OtherApprover."No.", Submitter."No.");

        // [THEN] The status error is raised.
        VerifyInterimApproverStatusError();

        // [WHEN] The final approver approves and an interim approver is assigned to the Approved report.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        asserterror ExpenseReportHeader.AssignInterimApprover(OtherApprover."No.", Submitter."No.");

        // [THEN] The status error is raised.
        VerifyInterimApproverStatusError();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitAppliesActiveAlternateApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] Submitting within an active alternate window assigns the alternate approver.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] Agent is enabled, a pending submission flow, and active alternate coverage for the final approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(AlternateApprover);
        CreateAlternateApproverCoverage(
            FinalApprover."No.",
            AlternateApprover."No.",
            WorkDate(),
            WorkDate());
        SetCurrentUser(Submitter);
        CreateAndReleaseExpenseReportWithAmount(Submitter, ExpenseReportHeader, 100);

        // [WHEN] The submitter submits the report for approval.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report remains pending and the alternate becomes the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, AlternateApprover, AlternateApprover);
        ExpenseReportHeader.TestField("Alternate Approver No.", AlternateApprover."No.");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::AlternateApproverAssigned);
        Assert.RecordCount(ExpenseActivityLogEntry, 1);
        ExpenseActivityLogEntry.FindFirst();
        ExpenseActivityLogEntry.TestField("Actor Role", Enum::"Expense Activity Actor Role"::Administrator);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitSkipsInactiveAlternateApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] Submitting outside the configured coverage window does not assign an alternate approver.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] Agent is enabled and alternate coverage starts after the current work date.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(AlternateApprover);
        CreateAlternateApproverCoverage(
            FinalApprover."No.",
            AlternateApprover."No.",
            CalcDate('<+1D>', WorkDate()),
            0D);
        SetCurrentUser(Submitter);
        CreateAndReleaseExpenseReportWithAmount(Submitter, ExpenseReportHeader, 100);

        // [WHEN] The submitter submits the report for approval.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report routes to the final approver because alternate coverage is inactive.
        VerifyApprovalRouting(ExpenseReportHeader, FinalApprover, FinalApprover);
        ExpenseReportHeader.TestField("Alternate Approver No.", '');
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignAlternateApproverFailsWithoutActiveCoverage()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] Assign Alternate Approver fails when no active coverage exists for the final approver on work date.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A pending report with no configured active alternate approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [WHEN] Assign Alternate Approver is invoked.
        asserterror ExpenseReportHeader.AssignAlternateApprover('');

        // [THEN] The expected validation error is raised and routing remains unchanged.
        Assert.ExpectedError(StrSubstNo(NoActiveAlternateApproverForDateErr, FinalApprover."No.", WorkDate()));
        VerifyApprovalRouting(ExpenseReportHeader, FinalApprover, FinalApprover);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ApprovalAdministratorCanAssignAlternateApprover()
    var
        Submitter: Record "Expense User";
        AlternateApprover: Record "Expense User";
        Administrator: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] An approval administrator can assign alternate coverage for another submitter's report.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A pending report with active alternate coverage and an unrelated unlimited approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(AlternateApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        CreateAlternateApproverCoverage(
            FinalApprover."No.",
            AlternateApprover."No.",
            WorkDate(),
            WorkDate());
        CreateApproverExpenseUser(Administrator);
        SetCurrentUser(Administrator);

        // [WHEN] The approval administrator assigns the active alternate.
        ExpenseReportHeader.AssignAlternateApprover('');

        // [THEN] The alternate is active and the event identifies an administrator actor.
        VerifyApprovalRouting(ExpenseReportHeader, AlternateApprover, AlternateApprover);
        ExpenseReportHeader.TestField("Alternate Approver No.", AlternateApprover."No.");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::AlternateApproverAssigned);
        Assert.RecordCount(ExpenseActivityLogEntry, 1);
        ExpenseActivityLogEntry.FindFirst();
        ExpenseActivityLogEntry.TestField("Actor Role", Enum::"Expense Activity Actor Role"::Administrator);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignAlternateApproverKeepsInterimAsActiveApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] Assigning an alternate keeps the interim as active approver and replaces the final approver.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A pending report has an interim approver and active alternate coverage.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(AlternateApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        CreateAlternateApproverCoverage(
            FinalApprover."No.",
            AlternateApprover."No.",
            WorkDate(),
            WorkDate());
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        SetCurrentUser(Submitter);

        // [WHEN] Assign Alternate Approver is invoked.
        ExpenseReportHeader.AssignAlternateApprover('');

        // [THEN] The interim remains active and the alternate becomes the final approver.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, AlternateApprover);
        ExpenseReportHeader.TestField("Alternate Approver No.", AlternateApprover."No.");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::AlternateApproverAssigned);
        ExpenseActivityLogEntry.FindFirst();
        ExpenseActivityLogEntry.TestField("Actor Role", Enum::"Expense Activity Actor Role"::Submitter);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    procedure InvalidAlternateCoverageEditsAreRejected()
    var
        PrimaryApprover: Record "Expense User";
        FirstAlternateApprover: Record "Expense User";
        SecondAlternateApprover: Record "Expense User";
        FirstCoverage: Record "Expense Alternate Approver";
        SecondCoverage: Record "Expense Alternate Approver";
        OriginalWorkDate: Date;
        FirstCoverageEndDate: Date;
        SecondCoverageStartDate: Date;
        SecondCoverageEndDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] Invalid date ranges and overlapping edits are rejected.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] One valid coverage range and a second non-overlapping range for the same primary approver.
        CreateApproverExpenseUser(PrimaryApprover);
        CreateApproverExpenseUser(FirstAlternateApprover);
        CreateApproverExpenseUser(SecondAlternateApprover);
        FirstCoverageEndDate := CalcDate('<+1D>', WorkDate());
        SecondCoverageStartDate := CalcDate('<+2D>', WorkDate());
        SecondCoverageEndDate := CalcDate('<+3D>', WorkDate());
        CreateAlternateApproverCoverage(
            PrimaryApprover."No.",
            FirstAlternateApprover."No.",
            WorkDate(),
            FirstCoverageEndDate);
        CreateAlternateApproverCoverage(
            PrimaryApprover."No.",
            SecondAlternateApprover."No.",
            SecondCoverageStartDate,
            SecondCoverageEndDate);

        // Preserve both rows when the expected validation error rolls back its transaction.
        Commit();

        // [WHEN] The first coverage end is moved before its start.
        FirstCoverage.Get(PrimaryApprover."No.", FirstAlternateApprover."No.", WorkDate());
        asserterror FirstCoverage.Validate("Effective End Date", CalcDate('<-1D>', WorkDate()));

        // [THEN] The inverted date range is rejected.
        Assert.ExpectedError(StrSubstNo(AlternateApproverDateRangeErr, FirstCoverage.FieldCaption("Effective Start Date"), FirstCoverage.FieldCaption("Effective End Date")));

        // [WHEN] The second coverage is edited to overlap the first.
        SecondCoverage.Get(PrimaryApprover."No.", SecondAlternateApprover."No.", SecondCoverageStartDate);
        asserterror SecondCoverage.Rename(PrimaryApprover."No.", SecondAlternateApprover."No.", FirstCoverageEndDate);

        // [THEN] The overlapping key rename is rejected and the original date range remains unchanged.
        Assert.ExpectedError(StrSubstNo(AlternateApproverOverlappingCoverageErr, PrimaryApprover."No."));
        SecondCoverage.Get(PrimaryApprover."No.", SecondAlternateApprover."No.", SecondCoverageStartDate);
        SecondCoverage.TestField("Effective Start Date", SecondCoverageStartDate);
        SecondCoverage.TestField("Effective End Date", SecondCoverageEndDate);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimAlternateCanCompleteInterimStage()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        InterimAlternate: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] An active alternate assigned for the interim approver can complete the interim stage.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A pending report with active alternate coverage for the selected interim approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(InterimAlternate);
        CreateAlternateApproverCoverage(
            InterimApprover."No.",
            InterimAlternate."No.",
            WorkDate(),
            WorkDate());
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [WHEN] The submitter assigns the interim approver and the interim alternate approves.
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        VerifyInterimApprover(ExpenseReportHeader, InterimAlternate."No.");
        VerifyActiveApprover(ExpenseReportHeader, InterimAlternate);
        ExpenseReportHeader.PerformManualApproved(InterimAlternate."No.", true);

        // [THEN] The report advances to the final approver, who can complete approval.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");
        VerifyActiveApprover(ExpenseReportHeader, FinalApprover);
        ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignAlternateApproverRequiresPendingApproval()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] Assign Alternate Approver is only allowed while the report is pending approval.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A released report (not yet submitted) with configured alternate coverage.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(AlternateApprover);
        CreateAlternateApproverCoverage(
            FinalApprover."No.",
            AlternateApprover."No.",
            CalcDate('<-1D>', WorkDate()),
            CalcDate('<+1D>', WorkDate()));
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        SetCurrentUser(Submitter);

        // [WHEN] Assign Alternate Approver is invoked before submission.
        asserterror ExpenseReportHeader.AssignAlternateApprover('');

        // [THEN] A status validation error is raised.
        Assert.ExpectedError(
            StrSubstNo(
                AlternateApproverStatusErr,
                Format(ExpenseReportHeader.Status::"Pending Approval"),
                Format(ExpenseReportHeader.Status::"Interim Approved")));
        WorkDate(OriginalWorkDate);
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
        Assert.ExpectedError(StrSubstNo(ApproverRequiredErr, ExpenseReportHeader."No.", Approver.FieldCaption("Approval Limit (LCY)"), Approver."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitWithInsufficientNextApproverFails()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] Submission continues through the approver chain when the next approver's approval limit is insufficient.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" has next approver "A2" with a limit of 100, "A2" has next approver "A3" with unlimited approval, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        SetApprovalLimit(NextApprover, 100);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");
        CreateApproverExpenseUser(FinalApprover);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, NextApprover."No.", FinalApprover."No.");

        // [WHEN] "S" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] The report is pending approval with "A3" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, FinalApprover, FinalApprover);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure InterimApproverWithInsufficientLimitCanApprove()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An interim approver can approve even when the report exceeds their approval limit.
        Initialize();

        // [GIVEN] A submitted report for 200 has final approver "A2", and interim approver "I" has an approval limit of 100.
        CreateSubmittedUnlimitedApprovalScenario(Submitter, FinalApprover, ExpenseReportHeader, 200);
        CreateApproverExpenseUser(InterimApprover);
        SetApprovalLimit(InterimApprover, 100);

        // [WHEN] Submitter "S" assigns "I" as interim approver and "I" approves.
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);

        // [THEN] The report advances to the final approver.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");
        VerifyActiveApprover(ExpenseReportHeader, FinalApprover);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ActiveAlternateCanApproveAboveOwnLimit()
    var
        Submitter: Record "Expense User";
        FinalApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An active alternate approver can approve above their own approval limit.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A submitted report for 200 and an active alternate with an approval limit of 100.
        CreateSubmittedUnlimitedApprovalScenario(Submitter, FinalApprover, ExpenseReportHeader, 200);
        CreateApproverExpenseUser(AlternateApprover);
        SetApprovalLimit(AlternateApprover, 100);
        CreateAlternateApproverCoverage(
            FinalApprover."No.",
            AlternateApprover."No.",
            WorkDate(),
            WorkDate());
        ExpenseReportHeader.AssignAlternateApprover('');

        // [WHEN] The alternate approves the report.
        ExpenseReportHeader.PerformManualApproved(AlternateApprover."No.", true);

        // [THEN] The report is approved without applying the alternate's personal limit.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        WorkDate(OriginalWorkDate);
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
        Assert.ExpectedError(StrSubstNo(ApproverApprovalLimitErr, ExpenseReportHeader."No.", Approver.FieldCaption("Approval Limit (LCY)"), Approver."No."));
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
        Approver.Validate("Unlimited Approval", false);

        // [WHEN] The approval limit of "A1" is set to -100.
        asserterror Approver.Validate("Approval Limit (LCY)", -100);

        // [THEN] An error explains that the approval limit must not be negative.
        Assert.ExpectedError(StrSubstNo(ApprovalLimitMustNotBeNegativeErr, Approver.FieldCaption("Approval Limit (LCY)")));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure SettingApprovalLimitWhileUnlimitedApprovalIsEnabledFails()
    var
        Approver: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 640938] An approver cannot have both an approval limit and unlimited approval.
        Initialize();

        // [GIVEN] Approver "A1" has unlimited approval.
        CreateApproverExpenseUser(Approver);

        // [WHEN] The approval limit of "A1" is set to 100.
        asserterror Approver.Validate("Approval Limit (LCY)", 100);

        // [THEN] An error explains that the two settings are mutually exclusive.
        Assert.ExpectedError('You cannot have both a Approval Limit (LCY) and Unlimited Approval.');
        Assert.ExpectedErrorCode('Dialog');
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
        Approver.Validate("Unlimited Approval", false);
        Approver.Validate("Approval Limit (LCY)", 100);

        // [WHEN] Unlimited approval is enabled for "A1".
        Approver.Validate("Unlimited Approval", true);
        Approver.Modify();

        // [THEN] Unlimited approval is enabled and the approval limit is 0.
        Approver.Get(Approver."No.");
        Approver.TestField("Unlimited Approval", true);
        Approver.TestField("Approval Limit (LCY)", 0);
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
        // [SCENARIO 640938] Submission fails when the current approver is configured as their own next approver and no unlimited default approver exists.
        Initialize();

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" is configured as their own next approver, no default approver is configured, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", Approver."No.");

        // [WHEN] "S" submits the expense report.
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] An error explains that a different next approver must be configured for "A1".
        Assert.ExpectedError(StrSubstNo(ApproverRequiredErr, ExpenseReportHeader."No.", Approver.FieldCaption("Approval Limit (LCY)"), Approver."No."));
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
        EnableAgent(true);

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
        Submitter."User Id For Approvals" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Submitter."User Id For Approvals"));
        Submitter.Modify();
        ExpenseReportHeader."Submitter Expense User Id" := Submitter."User Id For Approvals";
        ExpenseReportHeader.Modify();
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
        Submitter."User Id For Approvals" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Submitter."User Id For Approvals"));
        Submitter.Modify();
        ExpenseReportHeader."Submitter Expense User Id" := Submitter."User Id For Approvals";
        ExpenseReportHeader.Modify();
        CreateApproverExpenseUser(Approver);
        SetApprovalLimit(Approver, 100);
        SetCurrentUser(Approver);

        // [WHEN] "A1" recalls the expense report.
        asserterror ExpenseReportApprovalMgmt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] An authorization error explains that only the submitter or an unlimited approver can recall it.
        Assert.ExpectedError(StrSubstNo(NotAuthorizedToRecallExpReportErr, Approver.FieldCaption("Unlimited Approval")));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ProcessingReportAssignsAlternatesToFilteredAndAllPendingReports()
    var
        SubmitterOne: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        InterimAlternate: Record "Expense User";
        FinalAlternate: Record "Expense User";
        ExpenseReportOne: Record "Expense Report Header";
        SubmitterTwo: Record "Expense User";
        ExpenseReportTwo: Record "Expense Report Header";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ReportFilter: Record "Expense Report Header";
        AssignExpenseReportAlternates: Report "Delegate Expense Approval Req";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] The processing report applies active interim and final alternates to filtered or all pending reports.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] Two pending reports with active alternate coverage for both approvers.
        EnableAgent(true);
        CreateInterimApprovalSetup(SubmitterOne, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(SubmitterOne, ExpenseReportOne);
        ExpenseReportOne.AssignInterimApprover(InterimApprover."No.", SubmitterOne."No.");
        CreateSubmitterExpenseUser(SubmitterTwo);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, SubmitterTwo."No.", FinalApprover."No.");
        CreateSubmittedExpenseReport(SubmitterTwo, ExpenseReportTwo);
        ExpenseReportTwo.AssignInterimApprover(InterimApprover."No.", SubmitterTwo."No.");

        CreateApproverExpenseUser(InterimAlternate);
        CreateApproverExpenseUser(FinalAlternate);
        CreateAlternateApproverCoverage(InterimApprover."No.", InterimAlternate."No.", WorkDate(), WorkDate());
        CreateAlternateApproverCoverage(FinalApprover."No.", FinalAlternate."No.", WorkDate(), WorkDate());

        // [WHEN] The processing report runs with a filter for the first report only.
        ReportFilter.SetRange("No.", ExpenseReportOne."No.");
        AssignExpenseReportAlternates.SetTableView(ReportFilter);
        AssignExpenseReportAlternates.UseRequestPage(false);
        AssignExpenseReportAlternates.RunModal();

        // [THEN] Only the filtered report is routed through its interim and final alternates.
        VerifyInterimApprover(ExpenseReportOne, InterimAlternate."No.");
        VerifyApprovalRouting(ExpenseReportOne, InterimAlternate, FinalAlternate);
        ExpenseReportOne.TestField("Alternate Approver No.", FinalAlternate."No.");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportOne.SystemId);
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::InterimApproverAssigned);
        ExpenseActivityLogEntry.FindLast();
        ExpenseActivityLogEntry.TestField("Actor Role", Enum::"Expense Activity Actor Role"::Administrator);
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::AlternateApproverAssigned);
        ExpenseActivityLogEntry.FindLast();
        ExpenseActivityLogEntry.TestField("Actor Role", Enum::"Expense Activity Actor Role"::Administrator);
        VerifyInterimApprover(ExpenseReportTwo, InterimApprover."No.");
        VerifyApprovalRouting(ExpenseReportTwo, InterimApprover, FinalApprover);

        // [WHEN] The report runs again with no report-number filter.
        Clear(AssignExpenseReportAlternates);
        AssignExpenseReportAlternates.UseRequestPage(false);
        AssignExpenseReportAlternates.RunModal();

        // [THEN] The remaining eligible pending report is also routed through both alternates.
        VerifyInterimApprover(ExpenseReportTwo, InterimAlternate."No.");
        VerifyApprovalRouting(ExpenseReportTwo, InterimAlternate, FinalAlternate);
        ExpenseReportTwo.TestField("Alternate Approver No.", FinalAlternate."No.");
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ProcessingReportDelegatesFinalStageAfterInterimApproval()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        FinalAlternate: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ReportFilter: Record "Expense Report Header";
        DelegateExpenseApprovalRequest: Report "Delegate Expense Approval Req";
        OriginalWorkDate: Date;
    begin
        // [SCENARIO 626975] An alternate can take the final stage after interim approval without restarting that stage.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A report whose interim stage is complete and whose final approver has active alternate coverage.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);
        CreateApproverExpenseUser(FinalAlternate);
        CreateAlternateApproverCoverage(FinalApprover."No.", FinalAlternate."No.", WorkDate(), WorkDate());
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");

        // [WHEN] The delegation report runs for this report.
        ReportFilter.SetRange("No.", ExpenseReportHeader."No.");
        DelegateExpenseApprovalRequest.SetTableView(ReportFilter);
        DelegateExpenseApprovalRequest.UseRequestPage(false);
        DelegateExpenseApprovalRequest.RunModal();

        // [THEN] The interim stage remains complete while the alternate owns the final stage.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::"Interim Approved");
        ExpenseReportHeader.TestField("Interim Approver No.", InterimApprover."No.");
        ExpenseReportHeader.TestField("Final Approver No.", FinalAlternate."No.");
        ExpenseReportHeader.TestField("Approver Expense User No.", FinalAlternate."No.");
        ExpenseReportHeader.TestField("Alternate Approver No.", FinalAlternate."No.");

        // [WHEN] The final alternate approves the report.
        ExpenseReportHeader.PerformManualApproved(FinalAlternate."No.", true);

        // [THEN] The report completes approval.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ProcessingReportRevertsFinalApproverWhenCoverageEnds()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        FinalAlternate: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        OriginalWorkDate: Date;
    begin
        // [SCENARIO 626975] A report still unapproved after the alternate's coverage ends returns to the original final approver.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A pending report delegated to the final approver's alternate for today only.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        CreateApproverExpenseUser(FinalAlternate);
        CreateAlternateApproverCoverage(FinalApprover."No.", FinalAlternate."No.", WorkDate(), WorkDate());
        RunDelegationReport(ExpenseReportHeader."No.");
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField("Alternate Approver No.", FinalAlternate."No.");

        // [WHEN] The coverage has ended and the delegation report runs again.
        WorkDate(Today() + 1);
        RunDelegationReport(ExpenseReportHeader."No.");

        // [THEN] The report is back with the original final approver and the revert is logged.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField("Alternate Approver No.", '');
        ExpenseReportHeader.TestField("Primary Final Approver No.", '');
        VerifyApprovalRouting(ExpenseReportHeader, FinalApprover, FinalApprover);
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::AlternateApproverReverted);
        Assert.RecordCount(ExpenseActivityLogEntry, 1);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ProcessingReportRevertsInterimApproverWhenCoverageEnds()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        InterimAlternate: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [SCENARIO 626975] A report still awaiting interim approval after the interim alternate's coverage ends returns to the original interim approver.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A report whose interim approver is covered by an alternate for today only.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(InterimAlternate);
        CreateAlternateApproverCoverage(InterimApprover."No.", InterimAlternate."No.", WorkDate(), WorkDate());
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        VerifyInterimApprover(ExpenseReportHeader, InterimAlternate."No.");

        // [WHEN] The coverage has ended and the delegation report runs.
        WorkDate(Today() + 1);
        RunDelegationReport(ExpenseReportHeader."No.");

        // [THEN] The interim stage is back with the original interim approver.
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
        ExpenseReportHeader.TestField("Primary Interim Approver No.", '');
        ExpenseReportHeader.TestField("Approver Expense User No.", InterimApprover."No.");
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Pending Approval");
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ProcessingReportStopsOnFailingReport()
    var
        SubmitterFailing: Record "Expense User";
        InterimApproverFailing: Record "Expense User";
        FinalApproverFailing: Record "Expense User";
        InterimAlternateFailing: Record "Expense User";
        ExpenseReportFailing: Record "Expense Report Header";
        SubmitterValid: Record "Expense User";
        InterimApproverValid: Record "Expense User";
        FinalApproverValid: Record "Expense User";
        InterimAlternateValid: Record "Expense User";
        FinalAlternateValid: Record "Expense User";
        ExpenseReportValid: Record "Expense Report Header";
        AssignExpenseReportAlternates: Report "Delegate Expense Approval Req";
        OriginalWorkDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 626975] An alternate assignment error is shown and stops processing the remaining reports.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] A first pending report whose interim approver lost approval rights after alternate coverage was set up.
        EnableAgent(true);
        CreateInterimApprovalSetup(SubmitterFailing, InterimApproverFailing, FinalApproverFailing);
        CreateSubmittedExpenseReport(SubmitterFailing, ExpenseReportFailing);
        ExpenseReportFailing.AssignInterimApprover(InterimApproverFailing."No.", SubmitterFailing."No.");
        CreateApproverExpenseUser(InterimAlternateFailing);
        CreateAlternateApproverCoverage(InterimApproverFailing."No.", InterimAlternateFailing."No.", WorkDate(), WorkDate());
        InterimApproverFailing."Can Approve" := false;
        InterimApproverFailing.Modify();

        // [GIVEN] A second pending report created later with valid alternate coverage for both approvers.
        CreateInterimApprovalSetup(SubmitterValid, InterimApproverValid, FinalApproverValid);
        CreateSubmittedExpenseReport(SubmitterValid, ExpenseReportValid);
        ExpenseReportValid.AssignInterimApprover(InterimApproverValid."No.", SubmitterValid."No.");
        CreateApproverExpenseUser(InterimAlternateValid);
        CreateApproverExpenseUser(FinalAlternateValid);
        CreateAlternateApproverCoverage(InterimApproverValid."No.", InterimAlternateValid."No.", WorkDate(), WorkDate());
        CreateAlternateApproverCoverage(FinalApproverValid."No.", FinalAlternateValid."No.", WorkDate(), WorkDate());

        // [WHEN] The processing report runs without a filter.
        AssignExpenseReportAlternates.UseRequestPage(false);
        asserterror AssignExpenseReportAlternates.RunModal();

        // [THEN] The approval permission error is shown.
        Assert.ExpectedError(StrSubstNo(ApproverMustBeEnabledInExpenseUserErr, InterimApproverFailing.FieldCaption("Can Approve"), InterimApproverFailing.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');

        // [THEN] The failing report is left unchanged.
        VerifyInterimApprover(ExpenseReportFailing, InterimApproverFailing."No.");
        VerifyApprovalRouting(ExpenseReportFailing, InterimApproverFailing, FinalApproverFailing);

        // [THEN] The other report is not processed.
        VerifyInterimApprover(ExpenseReportValid, InterimApproverValid."No.");
        VerifyApprovalRouting(ExpenseReportValid, InterimApproverValid, FinalApproverValid);
        ExpenseReportValid.TestField("Alternate Approver No.", '');
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ProcessingReportSwitchesFinalAlternateWhenCoverageChanges()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        FirstAlternate: Record "Expense User";
        SecondAlternate: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
        SecondCoverageStartDate: Date;
    begin
        // [SCENARIO 626975] A pending report switches to the alternate whose coverage is active on the processing date.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());
        SecondCoverageStartDate := WorkDate() + 1;

        // [GIVEN] Two consecutive, non-overlapping coverage windows for the final approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        CreateApproverExpenseUser(FirstAlternate);
        CreateApproverExpenseUser(SecondAlternate);
        CreateAlternateApproverCoverage(FinalApprover."No.", FirstAlternate."No.", WorkDate(), WorkDate());
        CreateAlternateApproverCoverage(FinalApprover."No.", SecondAlternate."No.", SecondCoverageStartDate, 0D);

        // [WHEN] The delegation report runs within the first coverage window.
        RunDelegationReport(ExpenseReportHeader."No.");

        // [THEN] The first alternate is assigned.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField("Alternate Approver No.", FirstAlternate."No.");
        VerifyApprovalRouting(ExpenseReportHeader, FirstAlternate, FirstAlternate);

        // [WHEN] The work date advances into the second coverage window and the report runs again.
        WorkDate(SecondCoverageStartDate);
        RunDelegationReport(ExpenseReportHeader."No.");

        // [THEN] The report is reassigned to the second alternate.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.TestField("Alternate Approver No.", SecondAlternate."No.");
        VerifyApprovalRouting(ExpenseReportHeader, SecondAlternate, SecondAlternate);
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CannotDisableApproverAssignedToPendingExpenseReport()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 652243] An approver assigned to an expense report awaiting approval cannot have approval rights removed.
        Initialize();

        // [GIVEN] A pending report with both a final approver and an assigned interim approver.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetCurrentUser(Submitter);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [WHEN] Approval rights are removed from either approver.
        asserterror InterimApprover.Validate("Can Approve", false);
        Assert.ExpectedError(StrSubstNo(CannotRemovePendingApproverErr, InterimApprover."No.", ExpenseReportHeader."No."));

        FinalApprover.Get(FinalApprover."No.");
        asserterror FinalApprover.Validate("Can Approve", false);
        Assert.ExpectedError(StrSubstNo(CannotRemovePendingApproverErr, FinalApprover."No.", ExpenseReportHeader."No."));

        // [WHEN] The report is Interim Approved and assigned to the final approver.
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::"Interim Approved";
        ExpenseReportHeader.Modify(false);
        FinalApprover.Get(FinalApprover."No.");
        asserterror FinalApprover.Validate("Can Approve", false);

        // [THEN] Approval rights remain protected while the report is Interim Approved.
        Assert.ExpectedError(StrSubstNo(CannotRemovePendingApproverErr, FinalApprover."No.", ExpenseReportHeader."No."));
    end;

    [Test]
    procedure FixtureCreatesIndependentApproversAndCoverage()
    var
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        Fixture: JsonObject;
        PrimaryApprover: JsonObject;
        InterimApprover: JsonObject;
        AlternateApprover: JsonObject;
    begin
        // [FEATURE] [Approval Fixture]
        // [SCENARIO] The fixture creates independently valid approvers and explicit coverage dates.
        Initialize();

        // [GIVEN] An enabled agent with the standard approval workflow disabled.
        EnableAgent(true);

        // [WHEN] An interim and alternate approver fixture is created.
        Fixture.ReadFrom(ExpenseTestHandlerAPI.CreateInterimAndAlternateApproverFixture(WorkDate() - 1, WorkDate() + 1));

        // [THEN] All identities are valid, independently bound, and covered by the requested dates.
        VerifyApproverFixture(Fixture, WorkDate() - 1, WorkDate() + 1);
        PrimaryApprover := Fixture.GetObject('primaryApprover');
        InterimApprover := Fixture.GetObject('interimApprover');
        AlternateApprover := Fixture.GetObject('alternateApprover');
        Assert.AreNotEqual(GetFixtureGuid(PrimaryApprover, 'userId'), GetFixtureGuid(InterimApprover, 'userId'), 'Primary and interim approvers must have different BC users.');
        Assert.AreNotEqual(GetFixtureGuid(PrimaryApprover, 'userId'), GetFixtureGuid(AlternateApprover, 'userId'), 'Primary and alternate approvers must have different BC users.');
        Assert.AreNotEqual(GetFixtureGuid(InterimApprover, 'userId'), GetFixtureGuid(AlternateApprover, 'userId'), 'Interim and alternate approvers must have different BC users.');
    end;

    [Test]
    procedure SecondFixturePreservesExistingApprovers()
    var
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        FirstFixture: JsonObject;
        SecondFixture: JsonObject;
    begin
        // [FEATURE] [Approval Fixture]
        // [SCENARIO] Creating another fixture doesn't invalidate previously configured approvers.
        Initialize();

        // [GIVEN] An enabled agent and an existing approver fixture.
        EnableAgent(true);
        FirstFixture.ReadFrom(ExpenseTestHandlerAPI.CreateInterimAndAlternateApproverFixture(WorkDate() - 1, WorkDate() + 1));

        // [WHEN] A second approver fixture with open-ended coverage is created.
        SecondFixture.ReadFrom(ExpenseTestHandlerAPI.CreateInterimAndAlternateApproverFixture(WorkDate(), 0D));

        // [THEN] Both fixtures retain their valid bindings and independent coverage.
        VerifyApproverFixture(FirstFixture, WorkDate() - 1, WorkDate() + 1);
        VerifyApproverFixture(SecondFixture, WorkDate(), 0D);
    end;

    [Test]
    procedure FixtureCleanupPreservesOtherFixturesAndUsers()
    var
        UnrelatedApprover: Record "Expense User";
        CurrentUser: Record User;
        UserBeforeCleanup: Record User;
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        FirstFixture: JsonObject;
        SecondFixture: JsonObject;
        FirstFixtureText: Text;
        UnrelatedApprovalUserId: Code[50];
    begin
        // [FEATURE] [Approval Fixture]
        // [SCENARIO] Cleanup deletes only the fixture's records, not other fixtures or the caller.
        Initialize();

        // [GIVEN] Two approver fixtures, an unrelated approver, and the current service user.
        EnableAgent(true);
        FirstFixtureText := ExpenseTestHandlerAPI.CreateInterimAndAlternateApproverFixture(WorkDate() - 1, WorkDate() + 1);
        FirstFixture.ReadFrom(FirstFixtureText);
        SecondFixture.ReadFrom(ExpenseTestHandlerAPI.CreateInterimAndAlternateApproverFixture(WorkDate(), 0D));
        CreateApproverExpenseUser(UnrelatedApprover);
        UnrelatedApprovalUserId := UnrelatedApprover."User Id For Approvals";
        UserBeforeCleanup.Get(UserSecurityId());

        // [WHEN] The first fixture is deleted.
        ExpenseTestHandlerAPI.DeleteInterimAndAlternateApproverFixture(FirstFixtureText);

        // [THEN] Its records are removed and the other identities remain unchanged.
        VerifyApproverFixtureDeleted(FirstFixture);
        VerifyApproverFixture(SecondFixture, WorkDate(), 0D);
        UnrelatedApprover.Get(UnrelatedApprover."No.");
        UnrelatedApprover.TestField("Can Approve", true);
        UnrelatedApprover.TestField("User Id For Approvals", UnrelatedApprovalUserId);
        CurrentUser.Get(UserSecurityId());
        CurrentUser.TestField("User Name", UserBeforeCleanup."User Name");
        CurrentUser.TestField("Authentication Email", UserBeforeCleanup."Authentication Email");
    end;

    [Test]
    procedure FixtureCleanupCanBeRepeated()
    var
        ExpenseTestHandlerAPI: Codeunit "Expense Test Handler API";
        Fixture: JsonObject;
        FixtureText: Text;
    begin
        // [FEATURE] [Approval Fixture]
        // [SCENARIO] Repeating cleanup for the same fixture succeeds without deleting other records.
        Initialize();

        // [GIVEN] An approver fixture that has already been deleted.
        EnableAgent(true);
        FixtureText := ExpenseTestHandlerAPI.CreateInterimAndAlternateApproverFixture(WorkDate(), 0D);
        Fixture.ReadFrom(FixtureText);
        ExpenseTestHandlerAPI.DeleteInterimAndAlternateApproverFixture(FixtureText);

        // [WHEN] The fixture is deleted again.
        ExpenseTestHandlerAPI.DeleteInterimAndAlternateApproverFixture(FixtureText);

        // [THEN] All fixture records remain absent.
        VerifyApproverFixtureDeleted(Fixture);
    end;

    local procedure VerifyApproverFixture(Fixture: JsonObject; StartDate: Date; EndDate: Date)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseAlternateApprover: Record "Expense Alternate Approver";
        Submitter: JsonObject;
        PrimaryApprover: JsonObject;
        AlternateApprover: JsonObject;
    begin
        Submitter := Fixture.GetObject('submitter');
        PrimaryApprover := Fixture.GetObject('primaryApprover');
        AlternateApprover := Fixture.GetObject('alternateApprover');
        VerifyApproverFixtureIdentity(Submitter, false);
        VerifyApproverFixtureIdentity(PrimaryApprover, true);
        VerifyApproverFixtureIdentity(Fixture.GetObject('interimApprover'), true);
        VerifyApproverFixtureIdentity(AlternateApprover, true);
        ExpenseApprovalSetup.Get(Submitter.GetText('number'));
        ExpenseApprovalSetup.TestField("Approver No.", PrimaryApprover.GetText('number'));
        ExpenseAlternateApprover.GetBySystemId(GetFixtureGuid(Fixture, 'coverageId'));
        ExpenseAlternateApprover.TestField("Primary Approver No.", PrimaryApprover.GetText('number'));
        ExpenseAlternateApprover.TestField("Alternate Approver No.", AlternateApprover.GetText('number'));
        ExpenseAlternateApprover.TestField("Effective Start Date", StartDate);
        ExpenseAlternateApprover.TestField("Effective End Date", EndDate);
        Assert.AreEqual(CompanyName(), Fixture.GetText('companyName'), 'The fixture must identify its company.');
        Assert.AreEqual(WorkDate(), Fixture.GetDate('workDate'), 'The fixture must return the BC work date.');
        Assert.AreEqual(StartDate, Fixture.GetDate('coverageStartDate'), 'The fixture must return the requested start date.');
        Assert.AreEqual(EndDate, Fixture.GetDate('coverageEndDate'), 'The fixture must return the requested end date.');
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.TestField("Enable Agent", true);
        ExpenseAgentSetup.TestField("Enable Approval Workflow", false);
    end;

    local procedure VerifyApproverFixtureIdentity(Identity: JsonObject; CanApprove: Boolean)
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        User: Record User;
        UserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        ExpenseUser.GetBySystemId(GetFixtureGuid(Identity, 'id'));
        ExpenseUser.TestField("No.", Identity.GetText('number'));
        ExpenseUser.TestField("E-mail", Identity.GetText('email'));
        ExpenseUser.TestField("Can Approve", CanApprove);
        Employee.GetBySystemId(GetFixtureGuid(Identity, 'employeeId'));
        ExpenseUser.TestField("Employee No.", Employee."No.");
        User.Get(GetFixtureGuid(Identity, 'userId'));
        User.TestField("Authentication Email", ExpenseUser."E-mail");
        UserSetup.GetBySystemId(GetFixtureGuid(Identity, 'userSetupId'));
        UserSetup.TestField("User ID", User."User Name");
        SalespersonPurchaser.GetBySystemId(GetFixtureGuid(Identity, 'salespersonId'));
        UserSetup.TestField("Salespers./Purch. Code", SalespersonPurchaser.Code);
        if CanApprove then begin
            ExpenseUser.TestField("Unlimited Approval", true);
            ExpenseUser.TestField("User Id For Approvals", User."User Name");
        end;
    end;

    local procedure VerifyApproverFixtureDeleted(Fixture: JsonObject)
    var
        ExpenseAlternateApprover: Record "Expense Alternate Approver";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        Submitter: JsonObject;
    begin
        Assert.IsFalse(ExpenseAlternateApprover.GetBySystemId(GetFixtureGuid(Fixture, 'coverageId')), 'Fixture coverage must be deleted.');
        Submitter := Fixture.GetObject('submitter');
        Assert.IsFalse(ExpenseApprovalSetup.Get(Submitter.GetText('number')), 'The fixture approval setup must be deleted.');
        VerifyApproverFixtureIdentityDeleted(Submitter);
        VerifyApproverFixtureIdentityDeleted(Fixture.GetObject('primaryApprover'));
        VerifyApproverFixtureIdentityDeleted(Fixture.GetObject('interimApprover'));
        VerifyApproverFixtureIdentityDeleted(Fixture.GetObject('alternateApprover'));
    end;

    local procedure VerifyApproverFixtureIdentityDeleted(Identity: JsonObject)
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        User: Record User;
        UserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Assert.IsFalse(ExpenseUser.GetBySystemId(GetFixtureGuid(Identity, 'id')), 'The fixture expense user must be deleted.');
        Assert.IsFalse(Employee.GetBySystemId(GetFixtureGuid(Identity, 'employeeId')), 'The fixture employee must be deleted.');
        Assert.IsFalse(User.Get(GetFixtureGuid(Identity, 'userId')), 'The fixture BC user must be deleted.');
        Assert.IsFalse(UserSetup.GetBySystemId(GetFixtureGuid(Identity, 'userSetupId')), 'The fixture user setup must be deleted.');
        Assert.IsFalse(SalespersonPurchaser.GetBySystemId(GetFixtureGuid(Identity, 'salespersonId')), 'The fixture salesperson must be deleted.');
    end;

    local procedure GetFixtureGuid(Fixture: JsonObject; PropertyName: Text) Value: Guid
    begin
        Evaluate(Value, Fixture.GetText(PropertyName));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ApproveConfirmHandler')]
    procedure OwnerCanSelfApproveReportBelowOwnApprovalLimit()
    var
        Owner: Record "Expense User";
        DefaultApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] An owner configured as their own approver can approve a report below their approval limit.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is their own approver, "B" is the unlimited default approver, and "A" has a released report for 49.99.
        CreateSelfApprovalScenario(Owner, DefaultApprover, 50);
        CreateAndReleaseExpenseReportWithAmount(Owner, ExpenseReportHeader, 49.99);

        // [WHEN] "A" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Owner."No.");

        // [THEN] The report is pending approval with "A" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Owner, Owner);

        // [WHEN] "A" approves the expense report from the card.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        Assert.IsTrue(ExpenseReportPage.Approve.Visible(), 'The owner must see Approve below their approval limit.');
        Assert.IsTrue(ExpenseReportPage.Approve.Enabled(), 'The owner must be able to approve below their approval limit.');
        ExpenseReportPage.Approve.Invoke();
        ExpenseReportPage.Close();

        // [THEN] The report is approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        ExpenseReportHeader.TestField("Approved/Rejected Exp.User No.", Owner."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ApproveConfirmHandler')]
    procedure OwnerCanSelfApproveReportEqualToOwnApprovalLimit()
    var
        Owner: Record "Expense User";
        DefaultApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] An owner configured as their own approver can approve a report equal to their approval limit.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is their own approver, "B" is the unlimited default approver, and "A" has a released report for 50.
        CreateSelfApprovalScenario(Owner, DefaultApprover, 50);
        CreateAndReleaseExpenseReportWithAmount(Owner, ExpenseReportHeader, 50);

        // [WHEN] "A" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Owner."No.");

        // [THEN] The report is pending approval with "A" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Owner, Owner);

        // [WHEN] "A" approves the expense report from the card.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        Assert.IsTrue(ExpenseReportPage.Approve.Visible(), 'The owner must see Approve at their approval limit.');
        Assert.IsTrue(ExpenseReportPage.Approve.Enabled(), 'The owner must be able to approve at their approval limit.');
        ExpenseReportPage.Approve.Invoke();
        ExpenseReportPage.Close();

        // [THEN] The report is approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        ExpenseReportHeader.TestField("Approved/Rejected Exp.User No.", Owner."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure OwnerReportAboveOwnApprovalLimitRoutesToUnlimitedDefaultApprover()
    var
        Owner: Record "Expense User";
        DefaultApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] A report above the self-approving owner's limit is handed off to the unlimited default approver.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is their own approver, "B" is the unlimited default approver, and "A" has a released report for 50.01.
        CreateSelfApprovalScenario(Owner, DefaultApprover, 50);
        CreateAndReleaseExpenseReportWithAmount(Owner, ExpenseReportHeader, 50.01);

        // [WHEN] "A" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Owner."No.");

        // [THEN] The report is pending approval with "B" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, DefaultApprover, DefaultApprover);
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        Assert.IsFalse(ExpenseReportPage.Approve.Visible(), 'The owner must not see Approve above their approval limit.');
        ExpenseReportPage.Close();

        // Preserve the report when the expected validation error rolls back its transaction.
        Commit();

        // [WHEN] "A" tries to approve the expense report.
        asserterror ExpenseReportHeader.PerformManualApproved(Owner."No.");

        // [THEN] An error explains that the report exceeds "A"'s approval limit.
        Assert.ExpectedError(StrSubstNo(ApproverApprovalLimitErr, ExpenseReportHeader."No.", Owner.FieldCaption("Approval Limit (LCY)"), Owner."No."));
        Assert.ExpectedErrorCode('Dialog');
        VerifyApprovalRouting(ExpenseReportHeader, DefaultApprover, DefaultApprover);

        // [WHEN] "B" approves the expense report.
        ExpenseReportHeader.PerformManualApproved(DefaultApprover."No.");

        // [THEN] The report is approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        ExpenseReportHeader.TestField("Approved/Rejected Exp.User No.", DefaultApprover."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SelfApprovalSetupRoutesOwnerReportsByAmountWithoutSetupChanges()
    var
        Owner: Record "Expense User";
        DefaultApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        WithinLimitExpenseReportHeader: Record "Expense Report Header";
        AboveLimitExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] One self-approval setup routes reports within the owner's limit to the owner and reports above it to the unlimited default approver.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is their own approver and "B" is the unlimited default approver.
        CreateSelfApprovalScenario(Owner, DefaultApprover, 50);

        // [WHEN] "A" submits a report for 50 and then a report for 50.01 without changing the approval setup.
        CreateAndReleaseExpenseReportWithAmount(Owner, WithinLimitExpenseReportHeader, 50);
        ExpenseReportApprovalMgmt.Submit(WithinLimitExpenseReportHeader, Owner."No.");
        CreateAndReleaseExpenseReportWithAmount(Owner, AboveLimitExpenseReportHeader, 50.01);
        ExpenseReportApprovalMgmt.Submit(AboveLimitExpenseReportHeader, Owner."No.");

        // [THEN] The report for 50 is assigned to "A", the report for 50.01 is assigned to "B", and "A" remains their own approver.
        VerifyApprovalRouting(WithinLimitExpenseReportHeader, Owner, Owner);
        VerifyApprovalRouting(AboveLimitExpenseReportHeader, DefaultApprover, DefaultApprover);
        ExpenseApprovalSetup.Get(Owner."No.");
        ExpenseApprovalSetup.TestField("Approver No.", Owner."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ApproveConfirmHandler')]
    procedure OwnerMappedToOtherApproverCanSelfApproveReportBelowOwnApprovalLimit()
    var
        Owner: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] An approver-capable owner mapped to another approver can approve their own report below their approval limit.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is mapped to unlimited approver "B", and "A" has a released report for 49.99.
        CreateOwnerMappedToApproverScenario(Owner, Approver, 50);
        CreateAndReleaseExpenseReportWithAmount(Owner, ExpenseReportHeader, 49.99);

        // [WHEN] "A" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Owner."No.");

        // [THEN] The report is pending approval with "A" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Owner, Owner);

        // [WHEN] "A" approves the expense report from the card.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        Assert.IsTrue(ExpenseReportPage.Approve.Visible(), 'The owner must see Approve below their approval limit.');
        Assert.IsTrue(ExpenseReportPage.Approve.Enabled(), 'The owner must be able to approve below their approval limit.');
        ExpenseReportPage.Approve.Invoke();
        ExpenseReportPage.Close();

        // [THEN] The report is approved by "A".
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        ExpenseReportHeader.TestField("Approved/Rejected Exp.User No.", Owner."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ApproveConfirmHandler')]
    procedure OwnerMappedToOtherApproverCanSelfApproveReportEqualToOwnApprovalLimit()
    var
        Owner: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] An approver-capable owner mapped to another approver can approve their own report equal to their approval limit.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is mapped to unlimited approver "B", and "A" has a released report for 50.
        CreateOwnerMappedToApproverScenario(Owner, Approver, 50);
        CreateAndReleaseExpenseReportWithAmount(Owner, ExpenseReportHeader, 50);

        // [WHEN] "A" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Owner."No.");

        // [THEN] The report is pending approval with "A" as both the active and final approver.
        VerifyApprovalRouting(ExpenseReportHeader, Owner, Owner);

        // [WHEN] "A" approves the expense report from the card.
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        Assert.IsTrue(ExpenseReportPage.Approve.Visible(), 'The owner must see Approve at their approval limit.');
        Assert.IsTrue(ExpenseReportPage.Approve.Enabled(), 'The owner must be able to approve at their approval limit.');
        ExpenseReportPage.Approve.Invoke();
        ExpenseReportPage.Close();

        // [THEN] The report is approved by "A".
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        ExpenseReportHeader.TestField("Approved/Rejected Exp.User No.", Owner."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure OwnerMappedToOtherApproverReportAboveOwnApprovalLimitRoutesToMappedApprover()
    var
        Owner: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPage: TestPage "Expense Report";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] A report above the owner's approval limit is handed off to the owner's mapped approver.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is mapped to unlimited approver "B", and "A" has a released report for 50.01.
        CreateOwnerMappedToApproverScenario(Owner, Approver, 50);
        CreateAndReleaseExpenseReportWithAmount(Owner, ExpenseReportHeader, 50.01);

        // [WHEN] "A" submits the expense report.
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Owner."No.");

        // [THEN] The report is pending approval with "B" as both the active and final approver, and "A" does not see Approve.
        VerifyApprovalRouting(ExpenseReportHeader, Approver, Approver);
        ExpenseReportPage.OpenView();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        Assert.IsFalse(ExpenseReportPage.Approve.Visible(), 'The owner must not see Approve above their approval limit.');
        ExpenseReportPage.Close();

        // Preserve the report when the expected validation error rolls back its transaction.
        Commit();

        // [WHEN] "A" tries to approve the expense report.
        asserterror ExpenseReportHeader.PerformManualApproved(Owner."No.");

        // [THEN] An error explains that the report exceeds "A"'s approval limit.
        Assert.ExpectedError(StrSubstNo(ApproverApprovalLimitErr, ExpenseReportHeader."No.", Owner.FieldCaption("Approval Limit (LCY)"), Owner."No."));
        Assert.ExpectedErrorCode('Dialog');
        VerifyApprovalRouting(ExpenseReportHeader, Approver, Approver);

        // [WHEN] "B" approves the expense report.
        ExpenseReportHeader.PerformManualApproved(Approver."No.");

        // [THEN] The report is approved by "B".
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
        ExpenseReportHeader.TestField("Approved/Rejected Exp.User No.", Approver."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure OwnerMappedToOtherApproverRoutesReportsByAmountWithoutSetupChanges()
    var
        Owner: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        WithinLimitExpenseReportHeader: Record "Expense Report Header";
        AboveLimitExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] One A-to-B setup routes reports within the owner's limit to the owner and reports above it to the mapped approver.
        Initialize();

        // [GIVEN] Owner "A" with an approval limit of 50 is mapped to unlimited approver "B".
        CreateOwnerMappedToApproverScenario(Owner, Approver, 50);

        // [WHEN] "A" submits a report for 50 and then a report for 50.01 without changing the approval setup.
        CreateAndReleaseExpenseReportWithAmount(Owner, WithinLimitExpenseReportHeader, 50);
        ExpenseReportApprovalMgmt.Submit(WithinLimitExpenseReportHeader, Owner."No.");
        CreateAndReleaseExpenseReportWithAmount(Owner, AboveLimitExpenseReportHeader, 50.01);
        ExpenseReportApprovalMgmt.Submit(AboveLimitExpenseReportHeader, Owner."No.");

        // [THEN] The report for 50 is assigned to "A", the report for 50.01 is assigned to "B", and "A" remains mapped to "B".
        VerifyApprovalRouting(WithinLimitExpenseReportHeader, Owner, Owner);
        VerifyApprovalRouting(AboveLimitExpenseReportHeader, Approver, Approver);
        ExpenseApprovalSetup.Get(Owner."No.");
        ExpenseApprovalSetup.TestField("Approver No.", Approver."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmissionExceedingLimitWithCircularApproverChainFails()
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        NextApprover: Record "Expense User";
        DefaultApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 658633] Submission still fails when escalation between different approvers loops back, even with an unlimited default approver.
        Initialize();
        EnableAgent(true);

        // [GIVEN] Submitter "S" has approver "A1" with a limit of 100, "A1" escalates to "A2" with a limit of 100, "A2" escalates back to "A1", "B" is the unlimited default approver, and the released report amount is 200.
        CreateApprovalLimitScenario(Submitter, Approver, ExpenseReportHeader, 200, 100);
        CreateApproverExpenseUser(NextApprover);
        SetApprovalLimit(NextApprover, 100);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", NextApprover."No.");
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, NextApprover."No.", Approver."No.");
        CreateApproverExpenseUser(DefaultApprover);
        SetDefaultApprover(DefaultApprover."No.");

        // [WHEN] "S" submits the expense report.
        asserterror ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");

        // [THEN] An error explains that a next approver must be configured for "A2".
        Assert.ExpectedError(StrSubstNo(ApproverRequiredErr, ExpenseReportHeader."No.", NextApprover.FieldCaption("Approval Limit (LCY)"), NextApprover."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure InterimApproverPrepopulatedFromApprovalSetup()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 638116] The interim approver from the Expense Approval Setup is prepopulated on a new expense report.
        Initialize();

        // [GIVEN] Agent is enabled and the submitter has interim approver "I" in the Expense Approval Setup.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");

        // [WHEN] An expense report is created for the submitter.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Submitter."No.", '', '');

        // [THEN] The interim approver is "I" and the final approver is the submitter's approver.
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
        ExpenseReportHeader.TestField("Final Approver No.", FinalApprover."No.");
    end;

    [Test]
    procedure InterimApproverNotPrepopulatedWhenAgentDisabled()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 638116] The interim approver from the Expense Approval Setup is not prepopulated when the agent is disabled.
        Initialize();

        // [GIVEN] The submitter has interim approver "I" in the Expense Approval Setup, and the agent is disabled.
        EnableAgent(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");
        EnableAgent(false);

        // [WHEN] An expense report is created for the submitter.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Submitter."No.", '', '');

        // [THEN] No interim approver is set.
        VerifyInterimApprover(ExpenseReportHeader, '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitRoutesThroughInterimApproverFromApprovalSetup()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 638116] A report whose interim approver comes from the Expense Approval Setup is approved sequentially by the interim and final approvers.
        Initialize();

        // [GIVEN] Agent is enabled, overwriting is not allowed, and the submitter has interim approver "I" and final approver "F".
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");

        // [WHEN] The submitter submits an expense report.
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [THEN] The report is Pending Approval with "I" as the active approver and "F" as the final approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");

        // [WHEN] "I" approves.
        ExpenseReportHeader.PerformManualApproved(InterimApprover."No.", true);

        // [THEN] The report is Interim Approved and routed to "F".
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::"Interim Approved");
        VerifyActiveApprover(ExpenseReportHeader, FinalApprover);

        // [WHEN] "F" approves.
        ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);

        // [THEN] The report is Approved.
        VerifyStatus(ExpenseReportHeader, ExpenseReportHeader.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure FinalApproverCannotApproveBeforeInterimApproverFromApprovalSetup()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 638116] The final approver cannot approve before the interim approver from the Expense Approval Setup has approved.
        Initialize();

        // [GIVEN] A submitted report whose interim approver "I" comes from the Expense Approval Setup.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [WHEN] The final approver "F" tries to approve.
        asserterror ExpenseReportHeader.PerformManualApproved(FinalApprover."No.", true);

        // [THEN] An error states that the report is awaiting "I".
        Assert.ExpectedError(StrSubstNo(ActorNotActiveApproverErr, InterimApprover."No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignInterimApproverBlockedWhenOverwriteNotAllowed()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        OtherApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 638116] The submitter cannot assign an interim approver when Can Overwrite Interim Approver is turned off.
        Initialize();

        // [GIVEN] Agent is enabled, overwriting is not allowed, and the submitter has interim approver "I" in the Expense Approval Setup.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(OtherApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");

        // [GIVEN] A released expense report.
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");

        // Preserve the report when the expected validation error rolls back its transaction.
        Commit();

        // [WHEN] The submitter assigns another approver "O" as interim approver.
        asserterror ExpenseReportHeader.AssignInterimApprover(OtherApprover."No.", Submitter."No.");

        // [THEN] An error is raised and the interim approver stays "I".
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverOverwriteNotAllowedErr,
                ExpenseAgentSetup.FieldCaption("Can Overwrite Interim Approver"),
                ExpenseAgentSetup.TableCaption(),
                ExpenseApprovalSetup.TableCaption()));
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure AssignInterimApproverWithoutApprovalSetupBlockedWhenOverwriteNotAllowed()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 638116] Without overwriting allowed, the submitter cannot assign an interim approver even when none is configured in the Expense Approval Setup.
        Initialize();

        // [GIVEN] Agent is enabled, overwriting is not allowed, and no interim approver is configured for the submitter.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [WHEN] The submitter assigns interim approver "I".
        asserterror ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [THEN] An error is raised.
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverOverwriteNotAllowedErr,
                ExpenseAgentSetup.FieldCaption("Can Overwrite Interim Approver"),
                ExpenseAgentSetup.TableCaption(),
                ExpenseApprovalSetup.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitterCanOverwriteInterimApproverWhenAllowed()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        OtherApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 638116] With overwriting allowed, the submitter's interim approver replaces the one from the Expense Approval Setup and is kept on submission.
        Initialize();

        // [GIVEN] Agent is enabled, overwriting is allowed, and the submitter has interim approver "I" in the Expense Approval Setup.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(OtherApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");

        // [GIVEN] A released expense report prepopulated with "I".
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");

        // [WHEN] The submitter assigns another approver "O" as interim approver and submits the report.
        ExpenseReportHeader.AssignInterimApprover(OtherApprover."No.", Submitter."No.");
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");

        // [THEN] The report is Pending Approval with "O" as interim and active approver.
        VerifyApprovalRouting(ExpenseReportHeader, OtherApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, OtherApprover."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitAssignsInterimApproverConfiguredAfterReportCreation()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 638116] An interim approver added to the Expense Approval Setup after the report was created is assigned on submission.
        Initialize();

        // [GIVEN] Agent is enabled and a released report created before an interim approver was configured.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        VerifyInterimApprover(ExpenseReportHeader, '');

        // [GIVEN] Interim approver "I" is configured for the submitter.
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");

        // [WHEN] The report is submitted.
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");

        // [THEN] "I" is the interim and active approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitAppliesChangedInterimApproverWhenOverwriteNotAllowed()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        NewInterimApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 638116] Without overwriting allowed, submission applies the current interim approver from the Expense Approval Setup.
        Initialize();

        // [GIVEN] Agent is enabled, overwriting is not allowed, and a released report prepopulated with interim approver "I".
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateApproverExpenseUser(NewInterimApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");

        // [GIVEN] The interim approver in the Expense Approval Setup is changed to "N".
        SetInterimApproverInApprovalSetup(Submitter."No.", NewInterimApprover."No.");

        // [WHEN] The report is submitted.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");

        // [THEN] "N" is the interim and active approver.
        VerifyApprovalRouting(ExpenseReportHeader, NewInterimApprover, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, NewInterimApprover."No.");
    end;

    [Test]
    procedure ApprovalSetupInterimApproverCannotBeApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 638116] The interim approver in the Expense Approval Setup cannot be the same as the approver.
        Initialize();

        // [GIVEN] An Expense Approval Setup for a submitter with approver "F".
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        ExpenseApprovalSetup.Get(Submitter."No.");

        // [WHEN] The interim approver is set to "F".
        asserterror ExpenseApprovalSetup.Validate("Exp. Rep. Interim Approver No.", FinalApprover."No.");

        // [THEN] A conflict error is raised.
        Assert.ExpectedError(
            StrSubstNo(ApprovalSetupInterimApproverConflictErr, ExpenseApprovalSetup.FieldCaption("Exp. Rep. Interim Approver No."), ExpenseApprovalSetup.FieldCaption("Approver No.")));
    end;

    [Test]
    procedure ApprovalSetupInterimApproverCannotBeExpenseUser()
    var
        Approver: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 638116] The interim approver in the Expense Approval Setup cannot be the expense user.
        Initialize();

        // [GIVEN] An Expense Approval Setup for approver-capable expense user "A" with approver "F".
        CreateApproverExpenseUser(Approver);
        CreateApproverExpenseUser(FinalApprover);
        if ExpenseApprovalSetup.Get(Approver."No.") then begin
            ExpenseApprovalSetup.Validate("Approver No.", FinalApprover."No.");
            ExpenseApprovalSetup.Modify(true);
        end else
            LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Approver."No.", FinalApprover."No.");

        // [WHEN] The interim approver of "A" is set to "A".
        asserterror ExpenseApprovalSetup.Validate("Exp. Rep. Interim Approver No.", Approver."No.");

        // [THEN] A conflict error is raised.
        Assert.ExpectedError(
            StrSubstNo(ApprovalSetupInterimApproverConflictErr, ExpenseApprovalSetup.FieldCaption("Exp. Rep. Interim Approver No."), ExpenseApprovalSetup.FieldCaption("Expense User No.")));
    end;

    [Test]
    [HandlerFunctions('InterimApproverRemoveConfirmHandler')]
    procedure RemovingCanApproveClearsInterimApproverInApprovalSetup()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 638116] Removing approval rights from an interim approver clears it from the Expense Approval Setup.
        Initialize();

        // [GIVEN] The submitter has interim approver "I" in the Expense Approval Setup.
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");

        // [WHEN] "Can Approve" is turned off for "I" and the removal is confirmed.
        LibraryVariableStorage.Enqueue(StrSubstNo(InterimApproverRemoveQst, InterimApprover."No."));
        InterimApprover.Validate("Can Approve", false);
        InterimApprover.Modify(true);

        // [THEN] The submitter no longer has an interim approver.
        ExpenseApprovalSetup.Get(Submitter."No.");
        ExpenseApprovalSetup.TestField("Exp. Rep. Interim Approver No.", '');
        ExpenseApprovalSetup.TestField("Approver No.", FinalApprover."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitAppliesAlternateForInterimApproverFromApprovalSetup()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        InterimAlternate: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [SCENARIO 638116] On submission, an active alternate replaces the interim approver prefilled from the Expense Approval Setup, also when overwriting is allowed.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] Agent is enabled, overwriting is allowed, and the submitter has interim approver "I" in the Expense Approval Setup.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");

        // [GIVEN] A released report prefilled with "I".
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");

        // [GIVEN] Active alternate coverage "A" for "I".
        CreateApproverExpenseUser(InterimAlternate);
        CreateAlternateApproverCoverage(InterimApprover."No.", InterimAlternate."No.", WorkDate(), WorkDate());

        // [WHEN] The report is submitted.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");

        // [THEN] "A" is the interim and active approver, and "I" is kept as the primary interim approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimAlternate, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimAlternate."No.");
        ExpenseReportHeader.TestField("Primary Interim Approver No.", InterimApprover."No.");
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitAppliesAlternateForInterimApproverFromApprovalSetupWithoutOverwrite()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        InterimAlternate: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [SCENARIO 638116] Without overwriting allowed, an active alternate replaces the interim approver from the Expense Approval Setup on submission.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] Agent is enabled, overwriting is not allowed, the submitter has interim approver "I", and "I" has active alternate coverage "A".
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");
        CreateApproverExpenseUser(InterimAlternate);
        CreateAlternateApproverCoverage(InterimApprover."No.", InterimAlternate."No.", WorkDate(), WorkDate());

        // [WHEN] The submitter submits an expense report.
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);

        // [THEN] "A" is the interim and active approver, and "I" is kept as the primary interim approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimAlternate, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimAlternate."No.");
        ExpenseReportHeader.TestField("Primary Interim Approver No.", InterimApprover."No.");
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ProcessingReportAssignsInterimAlternateWhenOverwriteNotAllowed()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        InterimAlternate: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalWorkDate: Date;
    begin
        // [SCENARIO 638116] The delegation report assigns an active alternate for the interim approver even when submitters cannot overwrite the interim approver.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] Agent is enabled, overwriting is not allowed, and a report pending interim approval by "I" from the Expense Approval Setup.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(false);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        SetInterimApproverInApprovalSetup(Submitter."No.", InterimApprover."No.");
        CreateSubmittedExpenseReport(Submitter, ExpenseReportHeader);
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, FinalApprover);

        // [GIVEN] Alternate coverage "A" for "I" starts after submission.
        CreateApproverExpenseUser(InterimAlternate);
        CreateAlternateApproverCoverage(InterimApprover."No.", InterimAlternate."No.", WorkDate(), WorkDate());

        // [WHEN] The delegation report runs for the report.
        RunDelegationReport(ExpenseReportHeader."No.");

        // [THEN] "A" is the interim and active approver, and "I" is kept as the primary interim approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimAlternate, FinalApprover);
        VerifyInterimApprover(ExpenseReportHeader, InterimAlternate."No.");
        ExpenseReportHeader.TestField("Primary Interim Approver No.", InterimApprover."No.");
        WorkDate(OriginalWorkDate);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitClearsManualInterimApproverThatBecameFinalApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 638116] An interim approver that is the final approver at submission is cleared, and the report goes directly to the final approver.
        Initialize();

        // [GIVEN] Agent is enabled, overwriting is allowed, and the submitter assigns interim approver "I" to a released report.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");
        VerifyInterimApprover(ExpenseReportHeader, InterimApprover."No.");

        // [GIVEN] "I" becomes the submitter's approver in the Expense Approval Setup.
        ExpenseApprovalSetup.Get(Submitter."No.");
        ExpenseApprovalSetup.Validate("Approver No.", InterimApprover."No.");
        ExpenseApprovalSetup.Modify(true);

        // [WHEN] The report is submitted.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");

        // [THEN] No interim approver is set and "I" is the final and active approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimApprover, InterimApprover);
        VerifyInterimApprover(ExpenseReportHeader, '');
        ExpenseReportHeader.TestField("Primary Interim Approver No.", '');
    end;

    [Test]
    [HandlerFunctions('ReplyFromQueueConfirmHandler')]
    procedure DecliningInterimApproverRemovalKeepsApproverReferences()
    var
        Submitter: Record "Expense User";
        OtherSubmitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 638116] Declining the interim approver removal leaves both approver and interim approver references unchanged.
        Initialize();

        // [GIVEN] "F" is the approver of submitter "S1" and the interim approver of submitter "S2".
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateSubmitterExpenseUser(OtherSubmitter);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, OtherSubmitter."No.", InterimApprover."No.");
        SetInterimApproverInApprovalSetup(OtherSubmitter."No.", FinalApprover."No.");

        // [WHEN] The approver reassignment for "F" is confirmed, but the interim approver removal is declined.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        Assert.IsFalse(FinalApprover.ConfirmApproverReassignment(), 'Declining the interim approver removal must cancel the reassignment.');

        // [THEN] "F" is still the approver of "S1" and the interim approver of "S2".
        ExpenseApprovalSetup.Get(Submitter."No.");
        ExpenseApprovalSetup.TestField("Approver No.", FinalApprover."No.");
        ExpenseApprovalSetup.Get(OtherSubmitter."No.");
        ExpenseApprovalSetup.TestField("Exp. Rep. Interim Approver No.", FinalApprover."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure SubmitLogsAlternateForSubmitterInterimApprover()
    var
        Submitter: Record "Expense User";
        InterimApprover: Record "Expense User";
        InterimAlternate: Record "Expense User";
        FinalApprover: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        OriginalWorkDate: Date;
    begin
        // [SCENARIO 638116] When the submitter's interim approver is replaced by an active alternate on submission, the log names the alternate and the covered approver.
        Initialize();
        OriginalWorkDate := WorkDate();
        WorkDate(Today());

        // [GIVEN] Agent is enabled, overwriting is allowed, and the submitter assigns interim approver "I" to a released report.
        EnableAgent(true);
        SetCanOverwriteInterimApprover(true);
        CreateInterimApprovalSetup(Submitter, InterimApprover, FinalApprover);
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.AssignInterimApprover(InterimApprover."No.", Submitter."No.");

        // [GIVEN] Alternate coverage "A" for "I" starts after the assignment.
        CreateApproverExpenseUser(InterimAlternate);
        CreateAlternateApproverCoverage(InterimApprover."No.", InterimAlternate."No.", WorkDate(), WorkDate());

        // [WHEN] The report is submitted.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");

        // [THEN] "A" is the interim and active approver, and "I" is kept as the primary interim approver.
        VerifyApprovalRouting(ExpenseReportHeader, InterimAlternate, FinalApprover);
        ExpenseReportHeader.TestField("Primary Interim Approver No.", InterimApprover."No.");

        // [THEN] The system logs that "A" was assigned as alternate for "I".
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::InterimApproverAssigned);
        ExpenseActivityLogEntry.FindLast();
        ExpenseActivityLogEntry.TestField("Actor Role", Enum::"Expense Activity Actor Role"::Administrator);
        ExpenseActivityLogEntry.TestField(
            Comment,
            StrSubstNo(InterimAlternateAssignedCommentTxt, InterimAlternate."No.", InterimAlternate.Name, InterimApprover."No.", InterimApprover.Name));
        WorkDate(OriginalWorkDate);
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
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        // Most scenarios assign the interim approver manually, which requires overwriting to be allowed.
        SetCanOverwriteInterimApprover(true);
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
    begin
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(ExpenseUser, false);
    end;

    local procedure CreateApproverExpenseUser(var ExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(ExpenseUser, true);
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

    local procedure CreateAlternateApproverCoverage(PrimaryApproverNo: Code[20]; AlternateApproverNo: Code[20]; StartDate: Date; EndDate: Date)
    begin
        LibraryExpense.CreateAlternateApproverCoverage(PrimaryApproverNo, AlternateApproverNo, StartDate, EndDate);
    end;

    local procedure RunDelegationReport(ExpenseReportNo: Code[20])
    var
        ReportFilter: Record "Expense Report Header";
        DelegateExpenseApprovalRequest: Report "Delegate Expense Approval Req";
    begin
        ReportFilter.SetRange("No.", ExpenseReportNo);
        DelegateExpenseApprovalRequest.SetTableView(ReportFilter);
        DelegateExpenseApprovalRequest.UseRequestPage(false);
        DelegateExpenseApprovalRequest.RunModal();
    end;

    local procedure CreateSubmittedUnlimitedApprovalScenario(var Submitter: Record "Expense User"; var Approver: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header"; Amount: Decimal)
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CreateSubmitterExpenseUser(Submitter);
        CreateApproverExpenseUser(Approver);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Submitter."No.", Approver."No.");
        SetCurrentUser(Submitter);
        EnableAgent(true);
        CreateAndReleaseExpenseReportWithAmount(Submitter, ExpenseReportHeader, Amount);
        ExpenseReportApprovalMgmt.Submit(ExpenseReportHeader, Submitter."No.");
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
    end;

    local procedure SetApprovalLimit(var Approver: Record "Expense User"; ApprovalLimit: Decimal)
    begin
        Approver.Validate("Unlimited Approval", false);
        Approver.Validate("Approval Limit (LCY)", ApprovalLimit);
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
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
    begin
        CreateOpenExpenseReport(Submitter, ExpenseReportHeader);
        ReleaseExpenseReportDocument.PerformManualCheckAndRelease(ExpenseReportHeader);
    end;

    local procedure CreateOpenExpenseReport(Submitter: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header")
    var
        Expense: Record Expense;
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        CreateExpense(Expense, Submitter, LibraryRandom.RandIntInRange(5000, 10000));
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Submitter."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
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

    local procedure SetCanOverwriteInterimApprover(CanOverwrite: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.Validate("Can Overwrite Interim Approver", CanOverwrite);
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure SetInterimApproverInApprovalSetup(ExpenseUserNo: Code[20]; InterimApproverNo: Code[20])
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        ExpenseApprovalSetup.Get(ExpenseUserNo);
        ExpenseApprovalSetup.Validate("Exp. Rep. Interim Approver No.", InterimApproverNo);
        ExpenseApprovalSetup.Modify(true);
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

    local procedure VerifyInterimApproverStatusError()
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        Assert.ExpectedError(
            StrSubstNo(
                InterimApproverStatusErr,
                Format(ExpenseReportHeader.Status::Released),
                Format(ExpenseReportHeader.Status::"Pending Approval")));
    end;

    local procedure EnableSaaS(IsSaaS: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);
    end;

    local procedure CreateSelfApprovalScenario(var Owner: Record "Expense User"; var DefaultApprover: Record "Expense User"; ApprovalLimit: Decimal)
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        EnableAgent(true);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := 'DKK';
        GeneralLedgerSetup.Modify(true);

        CreateApproverExpenseUser(Owner);
        SetApprovalLimit(Owner, ApprovalLimit);
        SetCurrentUser(Owner);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Owner."No.", Owner."No.");
        CreateApproverExpenseUser(DefaultApprover);
        SetDefaultApprover(DefaultApprover."No.");
    end;

    local procedure CreateOwnerMappedToApproverScenario(var Owner: Record "Expense User"; var Approver: Record "Expense User"; ApprovalLimit: Decimal)
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CreateSelfApprovalScenario(Owner, Approver, ApprovalLimit);
        ExpenseApprovalSetup.Get(Owner."No.");
        ExpenseApprovalSetup.Validate("Approver No.", Approver."No.");
        ExpenseApprovalSetup.Modify(true);
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ApproveConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage('Do you want to approve submitted Expense Report?', Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure InterimApproverRemoveConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ReplyFromQueueConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
