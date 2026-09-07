// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.SpendRequest;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;

codeunit 148338 "Expense Permissions Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        EmployeeOnlyPermissionSetTok: Label 'Exp. Emp. Only Test', Locked = true;
        HREditPermissionSetTok: Label 'Exp. HR Edit Test', Locked = true;
        AutomationPermissionSetTok: Label 'Exp. Auto Test', Locked = true;
        D365BasicPermissionSetTok: Label 'D365 BASIC', Locked = true;
        ExpenseAgentPermissionSetTok: Label 'Expense Agent', Locked = true;
        PermissionDeniedErr: Label 'You do not have the following permissions', Locked = true;
        CannotDeleteEmployeeWithExpenseErr: Label 'You cannot delete Employee %1 because they have active expense.', Comment = '%1 = Employee No.';
        CannotDeleteEmployeeWithExpenseReportErr: Label 'You cannot delete Employee %1 because they have active expense report.', Comment = '%1 = Employee No.';
        CannotDeleteEmployeeWithPostedExpenseReportErr: Label 'You cannot delete Employee %1 because they have posted expense report.', Comment = '%1 = Employee No.';

    [Test]
    procedure ExpenseMgmtReadCanReadTravelRequests()
    begin
        // [SCENARIO] The read role can read travel data but cannot modify requests or details.
        VerifyTravelRequestPermissions('Expense Mgmt. Read', false);
    end;

    [Test]
    procedure ExpenseMgmtEditCanWriteTravelRequests()
    begin
        // [SCENARIO] The edit role includes the table access required by its travel-request pages.
        VerifyTravelRequestPermissions('Expense Mgmt. Edit', true);
    end;

    [Test]
    procedure ExpenseMgmtAdminInheritsTravelRequestPermissions()
    begin
        // [SCENARIO] The admin role inherits travel-request access from the edit and read roles.
        VerifyTravelRequestPermissions('Expense Mgmt. Admin', true);
    end;

    [Test]
    procedure D365BasicCanInsertActivityIndirectly()
    begin
        VerifyPermissionSetCanInsertActivity(D365BasicPermissionSetTok);
    end;

    [Test]
    procedure D365BasicCanGetExpensePolicyStatus()
    var
        ExpenseReportLine: Record "Expense Report Line";
        PolicyStatus: Enum "Expense Policy Status";
    begin
        Initialize();

        ExpenseReportLine.Init();
        ExpenseReportLine."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExpenseReportLine."Document No."));
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine.Insert(false);

        LibraryLowerPermissions.SetExactPermissionSet(D365BasicPermissionSetTok);
        PolicyStatus := ExpenseReportLine.GetPolicyStatus();
        RestoreFullPermissions();

        Assert.AreEqual("Expense Policy Status"::"No Policies", PolicyStatus, 'A D365 BASIC user must be able to get the expense policy status.');
    end;

    [Test]
    procedure ExpenseAgentCanInsertActivityIndirectly()
    begin
        VerifyPermissionSetCanInsertActivity(ExpenseAgentPermissionSetTok);
    end;

    [Test]
    procedure ExpenseAgentCanApproveTravelRequestIndirectly()
    var
        SpendRequest: Record "Spend Request";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        // [SCENARIO] The agent role grants only indirect request modification through the approval codeunit.
        Initialize();
        CreateTravelRequestApprovalScenario(SpendRequest, ExpenseUser, Approver);

        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet(ExpenseAgentPermissionSetTok);
        Assert.IsFalse(SpendRequest.WritePermission(), 'The agent must not have direct write permission on Spend Request.');
        TravelRequestApproval.Approve(SpendRequest, Approver."No.");
        RestoreFullPermissions();
        LibraryLowerPermissions.StopLoggingNAVPermissions();

        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Approved, SpendRequest.Status, 'The authorized agent must approve the travel request.');
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.FindFirst();
        Assert.AreEqual(ExpenseUser."No.", ExpenseReportHeader."Expense User No.", 'Approval must create the report for the requested user.');
    end;

    [Test]
    procedure TravelRequestApprovalFailsWithoutExpensePermissions()
    var
        SpendRequest: Record "Spend Request";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        // [SCENARIO] An employee-only caller cannot approve requests without access to Expense User data.
        Initialize();
        CreateTravelRequestApprovalScenario(SpendRequest, ExpenseUser, Approver);

        LibraryLowerPermissions.StartLoggingNAVPermissions();
        SetCallerPermissions(EmployeeOnlyPermissionSetTok, ExpenseUser);
        asserterror TravelRequestApproval.Approve(SpendRequest, Approver."No.");
        Assert.ExpectedErrorCode('DB:ClientReadDenied');
        Assert.ExpectedError(PermissionDeniedErr);
        Assert.ExpectedError(ExpenseUser.TableCaption());
        RestoreFullPermissions();
        LibraryLowerPermissions.StopLoggingNAVPermissions();

        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Released, SpendRequest.Status, 'A denied approval must preserve the request status.');
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordIsEmpty(ExpenseReportHeader);
    end;

    [Test]
    procedure CompanyEmailSyncsWithEmployeeOnlyPermissions()
    begin
        VerifyCompanyEmailSynchronization(EmployeeOnlyPermissionSetTok);
    end;

    [Test]
    procedure CompanyEmailSyncsWithHREditPermissions()
    begin
        VerifyCompanyEmailSynchronization(HREditPermissionSetTok);
    end;

    [Test]
    procedure CompanyEmailSyncsWithAutomationPermissions()
    begin
        VerifyCompanyEmailSynchronization(AutomationPermissionSetTok);
    end;

    [Test]
    procedure EmployeeDetailsSyncWithEmployeeOnlyPermissions()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        FirstName: Text[30];
        MiddleName: Text[30];
        LastName: Text[30];
        JobTitle: Text[30];
        ExpectedFullName: Text[100];
    begin
        Initialize();

        // [SCENARIO] Employee details synchronize when the caller cannot access Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        FirstName := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(Employee."First Name"));
        MiddleName := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(Employee."Middle Name"));
        LastName := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(Employee."Last Name"));
        JobTitle := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(Employee."Job Title"));

        SetCallerPermissions(EmployeeOnlyPermissionSetTok, ExpenseUser);

        Employee.Validate("First Name", FirstName);
        Employee.Validate("Middle Name", MiddleName);
        Employee.Validate("Last Name", LastName);
        // Some localizations map the compatibility name fields during OnModify, after these subscribers run.
        ExpectedFullName := Employee.FullName();
        Employee.Validate("Job Title", JobTitle);
        Employee.Modify(true);

        RestoreFullPermissions();
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpectedFullName, ExpenseUser.Name, 'Employee name must synchronize to Expense User.');
        Assert.AreEqual(JobTitle, ExpenseUser."Job Title", 'Employee job title must synchronize to Expense User.');
    end;

    [Test]
    procedure DeletingEmployeeDeletesExpenseUserWithEmployeeOnlyPermissions()
    var
        Employee: Record Employee;
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseUser: Record "Expense User";
        ExpenseUserNo: Code[20];
    begin
        Initialize();

        // [SCENARIO] Deleting an Employee also deletes the linked Expense User when the caller cannot access it.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", '');
        Employee.Get(ExpenseUser."Employee No.");
        ExpenseUserNo := ExpenseUser."No.";

        SetCallerPermissions(EmployeeOnlyPermissionSetTok, ExpenseUser);

        Employee.Delete(true);

        RestoreFullPermissions();
        Assert.IsFalse(ExpenseUser.Get(ExpenseUserNo), 'Expense User must be deleted with its Employee.');
        Assert.IsFalse(
            ExpenseApprovalSetup.Get(ExpenseUserNo),
            'Expense Approval Setup must be deleted with its Expense User.');
    end;

    [Test]
    procedure DeletingEmployeeWithExpenseFailsWithEmployeeOnlyPermissions()
    var
        Employee: Record Employee;
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
    begin
        Initialize();

        // [SCENARIO] Expense history still prevents Employee deletion for a caller without Expense User access.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateExpenseForDeletionGuard(Expense, ExpenseUser."No.");
        Employee.Get(ExpenseUser."Employee No.");

        SetCallerPermissions(EmployeeOnlyPermissionSetTok, ExpenseUser);

        asserterror Employee.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteEmployeeWithExpenseErr, Employee."No."));

        RestoreFullPermissions();
    end;

    [Test]
    procedure DeletingEmployeeWithExpenseReportFailsWithEmployeeOnlyPermissions()
    var
        Employee: Record Employee;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
    begin
        Initialize();

        // [SCENARIO] Active expense reports still prevent Employee deletion without Expense User access.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateExpenseReportForDeletionGuard(ExpenseReportHeader, ExpenseUser."No.");
        Employee.Get(ExpenseUser."Employee No.");

        SetCallerPermissions(EmployeeOnlyPermissionSetTok, ExpenseUser);

        asserterror Employee.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteEmployeeWithExpenseReportErr, Employee."No."));

        RestoreFullPermissions();
    end;

    [Test]
    procedure DeletingEmployeeWithPostedExpenseReportFailsWithEmployeeOnlyPermissions()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        Initialize();

        // [SCENARIO] Posted expense reports still prevent Employee deletion without Expense User access.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreatePostedExpenseReportForDeletionGuard(PostedExpenseReportHeader, ExpenseUser."No.");
        Employee.Get(ExpenseUser."Employee No.");

        SetCallerPermissions(EmployeeOnlyPermissionSetTok, ExpenseUser);

        asserterror Employee.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteEmployeeWithPostedExpenseReportErr, Employee."No."));

        RestoreFullPermissions();
    end;

    local procedure VerifyTravelRequestPermissions(PermissionSetId: Code[20]; CanEdit: Boolean)
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        SpendRequestToGLLink: Record "Spend Request To G/L Link";
    begin
        Initialize();

        // [GIVEN] Only the selected Expense Management role.
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet(PermissionSetId);

        // [WHEN] The effective table permissions are evaluated.
        // [THEN] Reads are available and write access follows the role's intended level.
        Assert.IsTrue(SpendRequest.ReadPermission(), 'The role must be able to read travel requests.');
        Assert.IsTrue(SpendRequestDetail.ReadPermission(), 'The role must be able to read travel-request details.');
        Assert.IsTrue(SpendRequestToGLLink.ReadPermission(), 'The role must be able to read travel-request spent amounts.');
        Assert.AreEqual(CanEdit, SpendRequest.WritePermission(), 'Request write access must follow the role level.');
        Assert.AreEqual(CanEdit, SpendRequestDetail.WritePermission(), 'Detail write access must follow the role level.');
        RestoreFullPermissions();
        LibraryLowerPermissions.StopLoggingNAVPermissions();
    end;

    local procedure VerifyCompanyEmailSynchronization(PermissionSetId: Code[20])
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        NewEmail: Text[80];
    begin
        Initialize();

        // [SCENARIO] Company E-Mail synchronizes when the caller cannot access Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        NewEmail :=
            CopyStr(
                LowerCase(DelChr(Format(CreateGuid()), '=', '{}-')) + '@example.com',
                1,
                MaxStrLen(Employee."Company E-Mail"));

        SetCallerPermissions(PermissionSetId, ExpenseUser);

        Employee.Validate("Company E-Mail", NewEmail);
        Employee.Modify(true);

        RestoreFullPermissions();
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(NewEmail, ExpenseUser."E-mail", 'Employee Company E-Mail must synchronize to Expense User.');
    end;

    local procedure CreateTravelRequestApprovalScenario(var SpendRequest: Record "Spend Request"; var ExpenseUser: Record "Expense User"; var Approver: Record "Expense User")
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(Approver);
        Approver."Can Approve" := true;
        Approver."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(Approver."User Id For Approvals"));
        Approver.Modify(true);
        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", Approver."No.");
        LibraryExpense.CreateSpendRequest(SpendRequest);
        SpendRequest.Validate("Requested By", ExpenseUser."Employee No.");
        SpendRequest.Validate("Requested For", ExpenseUser."No.");
        SpendRequest.Modify(true);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);
    end;

    local procedure CreateExpenseForDeletionGuard(var Expense: Record Expense; ExpenseUserNo: Code[20])
    begin
        Expense.Init();
        Expense."No." := CopyStr(LowerCase(DelChr(Format(CreateGuid()), '=', '{}-')), 1, MaxStrLen(Expense."No."));
        Expense."Expense User No." := ExpenseUserNo;
        Expense.Insert(false);
    end;

    local procedure CreateExpenseReportForDeletionGuard(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20])
    begin
        ExpenseReportHeader.Init();
        ExpenseReportHeader."No." :=
            CopyStr(LowerCase(DelChr(Format(CreateGuid()), '=', '{}-')), 1, MaxStrLen(ExpenseReportHeader."No."));
        ExpenseReportHeader."Expense User No." := ExpenseUserNo;
        ExpenseReportHeader.Insert(false);
    end;

    local procedure CreatePostedExpenseReportForDeletionGuard(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpenseUserNo: Code[20])
    begin
        PostedExpenseReportHeader.Init();
        PostedExpenseReportHeader."No." :=
            CopyStr(LowerCase(DelChr(Format(CreateGuid()), '=', '{}-')), 1, MaxStrLen(PostedExpenseReportHeader."No."));
        PostedExpenseReportHeader."Expense User No." := ExpenseUserNo;
        PostedExpenseReportHeader.Insert(false);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Permissions Test");
        RestoreFullPermissions();
        LibraryExpense.CleanTransactionalData();
        LibraryExpense.CleanUpBeforeTesting();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Permissions Test");
        EnsureSetupRecordsExist();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Permissions Test");
    end;

    local procedure VerifyPermissionSetCanInsertActivity(PermissionSetId: Code[20])
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
    begin
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        LibraryLowerPermissions.SetExactPermissionSet(PermissionSetId);
        Assert.IsFalse(
            ExpenseActivityLogEntry.WritePermission(),
            'The caller must not have direct write permission on the activity log.');
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        RestoreFullPermissions();

        Assert.IsTrue(EntryNo > 0, 'The activity entry must be inserted through indirect permissions.');
        ExpenseActivityLogEntry.Get(EntryNo);
    end;

    local procedure EnsureSetupRecordsExist()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;

        if not HumanResourcesSetup.Get() then begin
            HumanResourcesSetup.Init();
            HumanResourcesSetup.Insert();
        end;
    end;

    local procedure SetCallerPermissions(PermissionSetId: Code[20]; ExpenseUser: Record "Expense User")
    begin
        LibraryLowerPermissions.SetExactPermissionSet(PermissionSetId);
        Assert.IsFalse(ExpenseUser.ReadPermission(), 'The caller must not have direct access to Expense User.');
    end;

    local procedure RestoreFullPermissions()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;
}
