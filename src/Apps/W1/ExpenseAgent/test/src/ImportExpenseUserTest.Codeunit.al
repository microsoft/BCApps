// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;
using System.TestLibraries.Utilities;

codeunit 148316 "Import Expense User Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AddExistingEmployeesCreatesExpenseUsersForActiveEmployees()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ImportExpenseUser: Codeunit "Import Expense User";
        InitialCount: Integer;
    begin
        // [SCENARIO 605142] AddExistingEmployees creates one Expense User per active Employee that is not yet linked.
        Initialize();

        // [GIVEN] No Expense Users and no active employees.
        DeleteAllActiveEmployees();
        LibraryExpense.CleanUpBeforeTesting();
        InitialCount := ExpenseUser.Count();

        // [GIVEN] Two active employees.
        CreateActiveEmployeeWithCompanyEmail(Employee);
        CreateActiveEmployeeWithCompanyEmail(Employee);

        // [WHEN] AddExistingEmployees is called without confirmation.
        LibraryVariableStorage.Enqueue('Number of expense users created');
        ImportExpenseUser.AddExistingEmployees(false);

        // [THEN] Two new Expense Users were created.
        Assert.AreEqual(InitialCount + 2, ExpenseUser.Count(), 'AddExistingEmployees should create one Expense User per active Employee.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AddExistingEmployeesSkipsEmployeesAlreadyLinkedToExpenseUsers()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ImportExpenseUser: Codeunit "Import Expense User";
        InitialCount: Integer;
    begin
        // [SCENARIO 605142] AddExistingEmployees does not create a duplicate Expense User for an already-linked Employee.
        Initialize();

        // [GIVEN] An active Employee already linked to an Expense User.
        DeleteAllActiveEmployees();
        LibraryExpense.CleanUpBeforeTesting();
        CreateActiveEmployeeWithCompanyEmail(Employee);

        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser.Insert(true);

        InitialCount := ExpenseUser.Count();

        // [WHEN] AddExistingEmployees is called.
        LibraryVariableStorage.Enqueue('Number of expense users created');
        ImportExpenseUser.AddExistingEmployees(false);

        // [THEN] No additional Expense User is created.
        Assert.AreEqual(InitialCount, ExpenseUser.Count(), 'Already-linked Employee must not get a second Expense User.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AddExistingEmployeesUsesPersonalEmailWhenCompanyEmailIsEmpty()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ImportExpenseUser: Codeunit "Import Expense User";
        EmployeeNo: Code[20];
        PersonalEmail: Text[80];
    begin
        // [SCENARIO 605142] AddExistingEmployees uses the personal "E-Mail" when the Employee has no "Company E-Mail".
        Initialize();

        // [GIVEN] Exactly one active Employee in the system, with personal E-Mail and no Company E-Mail.
        DeleteAllActiveEmployees();
        LibraryExpense.CleanUpBeforeTesting();

        EmployeeNo := LibraryUtility.GenerateRandomCode(Employee.FieldNo("No."), Database::Employee);
        LibraryExpense.CreateEmployee(EmployeeNo);
        Employee.Get(EmployeeNo);
        PersonalEmail := CopyStr(LibraryUtility.GenerateRandomEmail(), 1, MaxStrLen(Employee."E-Mail"));
        Employee."E-Mail" := PersonalEmail;
        Employee."Company E-Mail" := '';
        Employee.Status := Employee.Status::Active;
        Employee.Modify();

        // [WHEN] AddExistingEmployees is called.
        LibraryVariableStorage.Enqueue('Number of expense users created');
        ImportExpenseUser.AddExistingEmployees(false);

        // [THEN] Exactly one Expense User exists, with the personal E-Mail.
        Assert.AreEqual(1, ExpenseUser.Count(), 'Exactly one Expense User should be created.');
        ExpenseUser.FindFirst();
        Assert.AreEqual(PersonalEmail, ExpenseUser."E-mail", 'Personal E-Mail should be used when Company E-Mail is empty.');
    end;

    [Test]
    procedure DeletingEmployeeDeletesLinkedExpenseUser()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        InitialCount: Integer;
    begin
        // [SCENARIO 605142] When an Employee is deleted, the linked Expense User is deleted by the OnBeforeDelete subscriber.
        Initialize();

        // [GIVEN] An Employee linked to an Expense User.
        LibraryExpense.CleanUpBeforeTesting();
        InitialCount := ExpenseUser.Count();
        CreateActiveEmployeeWithCompanyEmail(Employee);

        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser.Insert(true);
        Assert.AreEqual(InitialCount + 1, ExpenseUser.Count(), 'Setup: Expense User should have been created.');

        // [WHEN] The Employee is deleted.
        Employee.Delete(true);

        // [THEN] The linked Expense User is also deleted.
        Assert.AreEqual(InitialCount, ExpenseUser.Count(), 'Linked Expense User should be deleted with the Employee.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AddExistingEmployeesAssignsDefaultApproverFromSetup()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ImportExpenseUser: Codeunit "Import Expense User";
    begin
        // [SCENARIO 633650] When a Default Approver is configured, AddExistingEmployees creates an Expense Approval Setup pointing to that approver for every new Expense User.
        Initialize();

        // [GIVEN] No active employees, an approver Expense User and Expense Agent Setup with that user as Default Approver.
        DeleteAllActiveEmployees();
        LibraryExpense.CleanUpBeforeTesting();
        CreateApproverExpenseUser(ApproverExpenseUser);
        SetDefaultApproverNoOnSetup(ApproverExpenseUser."No.");

        // [GIVEN] Two active employees that are not yet linked to Expense Users.
        CreateActiveEmployeeWithCompanyEmail(Employee);
        CreateActiveEmployeeWithCompanyEmail(Employee);

        // [WHEN] AddExistingEmployees is called.
        LibraryVariableStorage.Enqueue('Number of expense users created');
        ImportExpenseUser.AddExistingEmployees(false);

        // [THEN] Each newly created Expense User has an Expense Approval Setup pointing to the Default Approver.
        ExpenseUser.SetFilter("No.", '<>%1', ApproverExpenseUser."No.");
        Assert.AreEqual(2, ExpenseUser.Count(), 'Two Expense Users should have been created for the active employees.');
        ExpenseUser.FindSet();
        repeat
            Assert.IsTrue(ExpenseApprovalSetup.Get(ExpenseUser."No."), 'Expense Approval Setup should have been created for ' + ExpenseUser."No.");
            Assert.AreEqual(ApproverExpenseUser."No.", ExpenseApprovalSetup."Approver No.", 'Approver No. on Expense Approval Setup should match the Default Approver.');
        until ExpenseUser.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AddExistingEmployeesCreatesNoApprovalSetupWhenNoDefaultApprover()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ImportExpenseUser: Codeunit "Import Expense User";
    begin
        // [SCENARIO 633650] When no Default Approver is configured, AddExistingEmployees does not create any Expense Approval Setup rows.
        Initialize();

        // [GIVEN] No active employees, no Default Approver and no Expense Approval Setup rows.
        DeleteAllActiveEmployees();
        LibraryExpense.CleanUpBeforeTesting();
        SetDefaultApproverNoOnSetup('');
        ExpenseApprovalSetup.DeleteAll();

        // [GIVEN] One active employee.
        CreateActiveEmployeeWithCompanyEmail(Employee);

        // [WHEN] AddExistingEmployees is called.
        LibraryVariableStorage.Enqueue('Number of expense users created');
        ImportExpenseUser.AddExistingEmployees(false);

        // [THEN] One Expense User is created and no Expense Approval Setup row exists.
        Assert.AreEqual(1, ExpenseUser.Count(), 'Exactly one Expense User should have been created.');
        Assert.RecordIsEmpty(ExpenseApprovalSetup);
    end;

    [Test]
    procedure DeletingExpenseUserDeletesItsApprovalSetup()
    var
        ExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseUserNo: Code[20];
    begin
        // [SCENARIO 633650] Deleting an Expense User also deletes its Expense Approval Setup row.
        Initialize();

        // [GIVEN] An approver Expense User configured as Default Approver.
        CreateApproverExpenseUser(ApproverExpenseUser);
        SetDefaultApproverNoOnSetup(ApproverExpenseUser."No.");

        // [GIVEN] An Expense User which gets an Expense Approval Setup auto-created on insert.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUserNo := ExpenseUser."No.";
        Assert.IsTrue(ExpenseApprovalSetup.Get(ExpenseUserNo), 'Expense Approval Setup should be auto-created on Expense User insert.');

        // [WHEN] The Expense User is deleted.
        ExpenseUser.Delete(true);

        // [THEN] The linked Expense Approval Setup row is also gone.
        Assert.IsFalse(ExpenseApprovalSetup.Get(ExpenseUserNo), 'Expense Approval Setup should be deleted together with the Expense User.');
    end;

    [Test]
    procedure SettingDefaultApproverFromBlankCreatesApprovalSetupForUsersWithoutApprover()
    var
        ExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 633650] Setting the Default Approver while previously blank creates an Expense Approval Setup for every Expense User that has no approver.
        Initialize();

        // [GIVEN] An Expense User created with no Default Approver, so no approval setup exists.
        SetDefaultApproverNoOnSetup('');
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Assert.IsFalse(ExpenseApprovalSetup.Get(ExpenseUser."No."), 'Precondition: no Expense Approval Setup should exist for the Expense User yet.');

        // [GIVEN] An approver Expense User.
        CreateApproverExpenseUser(ApproverExpenseUser);

        // [WHEN] Default Approver No. is validated from blank to the approver.
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.Validate("Default Approver No.", ApproverExpenseUser."No.");
        ExpenseAgentSetup.Modify();

        // [THEN] The previously approver-less Expense User has an Expense Approval Setup pointing to the new Default Approver.
        Assert.IsTrue(ExpenseApprovalSetup.Get(ExpenseUser."No."), 'Expense Approval Setup should be created for the Expense User without approver.');
        Assert.AreEqual(ApproverExpenseUser."No.", ExpenseApprovalSetup."Approver No.", 'Approver No. should be the new Default Approver.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ChangingDefaultApproverReassignsExistingApprovalSetupsToNewApprover()
    var
        ExpenseUser: Record "Expense User";
        FirstApprover: Record "Expense User";
        SecondApprover: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        // [SCENARIO 633650] Changing the Default Approver reassigns existing Expense Approval Setup rows from the old approver to the new approver after user confirmation.
        Initialize();

        // [GIVEN] A first approver configured as Default Approver and an Expense User auto-pointing to it.
        CreateApproverExpenseUser(FirstApprover);
        SetDefaultApproverNoOnSetup(FirstApprover."No.");
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Assert.IsTrue(ExpenseApprovalSetup.Get(ExpenseUser."No."), 'Precondition: Expense Approval Setup should exist for the Expense User.');
        Assert.AreEqual(FirstApprover."No.", ExpenseApprovalSetup."Approver No.", 'Precondition: Approver No. should be the first approver.');

        // [GIVEN] A second approver Expense User.
        CreateApproverExpenseUser(SecondApprover);

        // [WHEN] Default Approver No. is validated to the second approver and the user confirms.
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup.Validate("Default Approver No.", SecondApprover."No.");
        ExpenseAgentSetup.Modify();

        // [THEN] The Expense Approval Setup for the existing Expense User now points to the second approver.
        ExpenseApprovalSetup.Get(ExpenseUser."No.");
        Assert.AreEqual(SecondApprover."No.", ExpenseApprovalSetup."Approver No.", 'Approver No. should have been reassigned to the new Default Approver.');
    end;

    local procedure CreateApproverExpenseUser(var ApproverExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(ApproverExpenseUser);
        ApproverExpenseUser."Can Approve" := true;
        ApproverExpenseUser."Entra Id" := CreateGuid();
        ApproverExpenseUser.Modify(false);
    end;

    local procedure SetDefaultApproverNoOnSetup(DefaultApproverNo: Code[20])
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Default Approver No." := DefaultApproverNo;
        ExpenseAgentSetup.Modify();
    end;

    local procedure CreateActiveEmployeeWithCompanyEmail(var Employee: Record Employee)
    var
        EmployeeNo: Code[20];
    begin
        EmployeeNo := LibraryUtility.GenerateRandomCode(Employee.FieldNo("No."), Database::Employee);
        LibraryExpense.CreateEmployee(EmployeeNo);
        Employee.Get(EmployeeNo);
        Employee."First Name" := CopyStr('First' + Format(LibraryRandom.RandIntInRange(1, 100000)), 1, MaxStrLen(Employee."First Name"));
        Employee."Last Name" := CopyStr('Last' + Format(LibraryRandom.RandIntInRange(1, 100000)), 1, MaxStrLen(Employee."Last Name"));
        Employee."Company E-Mail" := CopyStr(LibraryUtility.GenerateRandomEmail(), 1, MaxStrLen(Employee."Company E-Mail"));
        Employee.Status := Employee.Status::Active;
        Employee.Modify();
    end;

    local procedure DeleteAllActiveEmployees()
    var
        Employee: Record Employee;
    begin
        Employee.SetRange(Status, Employee.Status::Active);
        if Employee.FindSet() then
            Employee.DeleteAll(true);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        if ExpenseAgentSetup.Get() and (ExpenseAgentSetup."Default Approver No." <> '') then begin
            ExpenseAgentSetup."Default Approver No." := '';
            ExpenseAgentSetup.Modify();
        end;
        ExpenseApprovalSetup.DeleteAll();
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Msg);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
