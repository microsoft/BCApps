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
        ExpenseUser.Validate("Entra Id", CreateGuid());
        ExpenseUser.Modify();
    end;

    local procedure CreateSubmittedExpenseReport(Submitter: Record "Expense User"; var ExpenseReportHeader: Record "Expense Report Header")
    begin
        CreateAndReleaseExpenseReport(Submitter, ExpenseReportHeader);
        ExpenseReportHeader.PerformManualPendingApproval(Submitter."No.");
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
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
