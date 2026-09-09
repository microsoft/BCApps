// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.SpendRequest;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.TestLibraries.Security.AccessControl;

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
        UserPermissionsLibrary: Codeunit "User Permissions Library";
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
    procedure ExpenseMgmtReadRetainsAppPermissions()
    begin
        // [SCENARIO] The read role retains app-owned reads without granting BaseApp request access.
        VerifyExpenseMgmtPermissions('Expense Mgmt. Read', false);
    end;

    [Test]
    procedure ExpenseMgmtEditRetainsAppPermissions()
    begin
        // [SCENARIO] The edit role retains app-owned writes without granting BaseApp request access.
        VerifyExpenseMgmtPermissions('Expense Mgmt. Edit', true);
    end;

    [Test]
    procedure ExpenseMgmtAdminRetainsAppPermissions()
    begin
        // [SCENARIO] The admin role retains app-owned writes without granting BaseApp request access.
        VerifyExpenseMgmtPermissions('Expense Mgmt. Admin', true);
    end;

    [Test]
    procedure D365BasicCanUpdateTravelRequestDetailsIndirectly()
    begin
        VerifyTravelRequestDetailUpdateIndirectly(D365BasicPermissionSetTok);
    end;

    [Test]
    procedure ExpenseAgentCanUpdateTravelRequestDetailsIndirectly()
    begin
        VerifyTravelRequestDetailUpdateIndirectly(ExpenseAgentPermissionSetTok);
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
    procedure EntraAppPermissionFromOtherCompanyDoesNotApplyToCurrentCompany()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OtherCompanyName: Text[30];
        PermissionExists: Boolean;
    begin
        // [SCENARIO 640454] An Entra app permission for another company does not satisfy the current company
        Initialize();

        // [GIVEN] Entra app user "EA" has the Expense Agent permission only for company "B"
        AadApplication."User ID" := CreateGuid();
        OtherCompanyName := CopyStr('Other ' + CompanyName(), 1, MaxStrLen(OtherCompanyName));
        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", ExpenseAgentPermissionSetTok, OtherCompanyName);

        // [WHEN] Checking whether "EA" has the permission for the current company
        PermissionExists := ExpenseAgentEntraApp.HasPermissionForCurrentCompany(AadApplication);

        // [THEN] The permission is not considered assigned for the current company
        Assert.IsFalse(PermissionExists, 'A permission assigned to another company must not satisfy the current company.');
    end;

    [Test]
    procedure EntraAppPermissionFromCurrentCompanyAppliesToCurrentCompany()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        PermissionExists: Boolean;
    begin
        // [SCENARIO 640454] An Entra app permission for the current company satisfies the current company
        Initialize();

        // [GIVEN] Entra app user "EA" has the Expense Agent permission for the current company
        AadApplication."User ID" := CreateGuid();
        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", ExpenseAgentPermissionSetTok, CompanyName());

        // [WHEN] Checking whether "EA" has the permission for the current company
        PermissionExists := ExpenseAgentEntraApp.HasPermissionForCurrentCompany(AadApplication);

        // [THEN] The permission is considered assigned for the current company
        Assert.IsTrue(PermissionExists, 'A permission assigned to the current company must satisfy the current company.');
    end;

    [Test]
    procedure AddingEntraAppPermissionCreatesCurrentCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Adding the Entra app permission creates it for the current company
        Initialize();

        // [GIVEN] Entra app user "EA" has no Expense Agent permission for the current company
        AadApplication."User ID" := UserSecurityId();
        ExpenseAgentEntraApp.RemovePermissionForCurrentCompany(AadApplication);

        // [WHEN] Adding the permission for the current company
        ExpenseAgentEntraApp.AddPermissionForCurrentCompany(AadApplication);

        // [THEN] The current company permission exists
        Assert.IsTrue(ExpenseAgentEntraApp.HasPermissionForCurrentCompany(AadApplication), 'The current company permission must be added.');
    end;

    [Test]
    procedure RemovingCurrentCompanyPermissionKeepsOtherCompanyPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OtherCompanyName: Text[30];
    begin
        // [SCENARIO 640454] Removing the current company permission preserves another company's permission
        Initialize();

        // [GIVEN] Entra app user "EA" has the Expense Agent permission for the current company and company "B"
        AadApplication."User ID" := CreateGuid();
        OtherCompanyName := CopyStr('Other ' + CompanyName(), 1, MaxStrLen(OtherCompanyName));
        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", ExpenseAgentPermissionSetTok, CompanyName());
        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", ExpenseAgentPermissionSetTok, OtherCompanyName);

        // [WHEN] Removing the permission for the current company
        ExpenseAgentEntraApp.RemovePermissionForCurrentCompany(AadApplication);

        // [THEN] The current company permission is removed and another company permission remains
        Assert.IsFalse(ExpenseAgentEntraApp.HasPermissionForCurrentCompany(AadApplication), 'The current company permission must be removed.');
        Assert.IsTrue(ExpenseAgentEntraApp.HasAnyPermission(AadApplication), 'Another company permission must be preserved.');
    end;

    [Test]
    procedure RemovingLastCompanyPermissionLeavesNoPermission()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Removing the last company permission leaves no Expense Agent permission
        Initialize();

        // [GIVEN] Entra app user "EA" has the Expense Agent permission only for the current company
        AadApplication."User ID" := CreateGuid();
        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", ExpenseAgentPermissionSetTok, CompanyName());

        // [WHEN] Removing the permission for the current company
        ExpenseAgentEntraApp.RemovePermissionForCurrentCompany(AadApplication);

        // [THEN] No Expense Agent permission remains
        Assert.IsFalse(ExpenseAgentEntraApp.HasAnyPermission(AadApplication), 'No Expense Agent permission must remain.');
    end;

    [Test]
    procedure DisablingEntraAppWithOtherCompanyPermissionKeepsApplicationEnabled()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        OtherCompanyName: Text[30];
    begin
        // [SCENARIO 640454] Deactivation keeps the Entra application enabled when another company permission remains
        Initialize();

        // [GIVEN] The Expense Agent Entra application is enabled for the current company and company "B"
        PrepareExpenseAgentAadApplication(AadApplication);
        ExpenseAgentEntraApp.AddPermissionForCurrentCompany(AadApplication);
        OtherCompanyName := CopyStr('Other ' + CompanyName(), 1, MaxStrLen(OtherCompanyName));
        UserPermissionsLibrary.AssignPermissionSetToUser(AadApplication."User ID", ExpenseAgentPermissionSetTok, OtherCompanyName);

        // [WHEN] Disabling the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] The Entra application remains enabled for company "B"
        AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId());
        Assert.AreEqual(AadApplication.State::Enabled, AadApplication.State, 'The Entra application must remain enabled for another company.');
        Assert.IsFalse(ExpenseAgentEntraApp.HasPermissionForCurrentCompany(AadApplication), 'The current company permission must be removed.');
        Assert.IsTrue(ExpenseAgentEntraApp.HasAnyPermission(AadApplication), 'Another company permission must remain.');
    end;

    [Test]
    procedure DisablingEntraAppAfterLastCompanyPermissionDisablesApplication()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // [SCENARIO 640454] Deactivation disables the Entra application after its last company permission is removed
        Initialize();

        // [GIVEN] The Expense Agent Entra application is enabled only for the current company
        PrepareExpenseAgentAadApplication(AadApplication);
        ExpenseAgentEntraApp.AddPermissionForCurrentCompany(AadApplication);

        // [WHEN] Disabling the Expense Agent for the current company
        ExpenseAgentEntraApp.DisableAadApplicationForCurrentCompany();

        // [THEN] The Entra application is disabled and no Expense Agent permission remains
        AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId());
        Assert.AreEqual(AadApplication.State::Disabled, AadApplication.State, 'The Entra application must be disabled after its last company permission is removed.');
        Assert.IsFalse(ExpenseAgentEntraApp.HasAnyPermission(AadApplication), 'No Expense Agent permission must remain.');
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

    local procedure VerifyExpenseMgmtPermissions(PermissionSetId: Code[20]; CanEdit: Boolean)
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        SpendRequestToGLLink: Record "Spend Request To G/L Link";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        Initialize();

        // [GIVEN] Only the selected Expense Management role.
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet(PermissionSetId);

        // [WHEN] The effective table permissions are evaluated.
        // [THEN] BaseApp rights are not added to these roles; app-owned rights follow the role level.
        Assert.IsFalse(SpendRequest.ReadPermission(), 'The role must not grant direct BaseApp request access.');
        Assert.IsFalse(SpendRequestDetail.ReadPermission(), 'The role must not grant direct BaseApp detail access.');
        Assert.IsFalse(SpendRequestToGLLink.ReadPermission(), 'The role must not grant direct BaseApp ledger-link access.');
        Assert.IsFalse(SpendRequest.WritePermission(), 'The role must not grant direct BaseApp request writes.');
        Assert.IsFalse(SpendRequestDetail.WritePermission(), 'The role must not grant direct BaseApp detail writes.');
        Assert.IsTrue(ExpenseUser.ReadPermission(), 'The role must retain read access to app-owned expense users.');
        Assert.IsTrue(ExpenseReportHeader.ReadPermission(), 'The role must retain read access to app-owned reports.');
        Assert.AreEqual(CanEdit, ExpenseUser.WritePermission(), 'Expense user write access must follow the role level.');
        Assert.AreEqual(CanEdit, ExpenseReportHeader.WritePermission(), 'Expense report write access must follow the role level.');
        RestoreFullPermissions();
        LibraryLowerPermissions.StopLoggingNAVPermissions();
    end;

    local procedure VerifyTravelRequestDetailUpdateIndirectly(PermissionSetId: Code[20])
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        TravelRequestSubform: TestPage "Travel Request Subform";
    begin
        // [SCENARIO] Editing a detail through its page can update both the line and its header total.
        Initialize();
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", 10);

        // [GIVEN] The caller has indirect writes only, not direct access to change either table.
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet(PermissionSetId);
        Assert.IsFalse(SpendRequest.WritePermission(), 'The caller must not have direct request write permission.');
        Assert.IsFalse(SpendRequestDetail.WritePermission(), 'The caller must not have direct detail write permission.');

        // [WHEN] A detail amount is increased through the page with the required object permissions.
        TravelRequestSubform.OpenEdit();
        TravelRequestSubform.GoToRecord(SpendRequestDetail);
        TravelRequestSubform.Amount.SetValue(20);
        TravelRequestSubform.Close();
        RestoreFullPermissions();
        LibraryLowerPermissions.StopLoggingNAVPermissions();

        // [THEN] Both the line change and the base table's header update are persisted.
        SpendRequestDetail.Get(SpendRequestDetail."Spend Request No.", SpendRequestDetail."Line No.");
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(20, SpendRequestDetail."Expected Amount", 'The detail amount must be updated through indirect permissions.');
        Assert.AreEqual(20, SpendRequest."Total Expected Amount (LCY)", 'The detail update must also update the header total.');
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

    local procedure PrepareExpenseAgentAadApplication(var AadApplication: Record "AAD Application")
    var
        AccessControl: Record "Access Control";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId());
        if AadApplication.State <> AadApplication.State::Enabled then begin
            AadApplication.Validate(State, AadApplication.State::Enabled);
            AadApplication.Modify(true);
        end;

        AccessControl.SetRange("User Security ID", AadApplication."User ID");
        AccessControl.SetRange("Role ID", ExpenseAgentPermissionSetTok);
        AccessControl.DeleteAll(true);
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
