// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;

codeunit 148307 "Expense Test Handler API"
{
    /// <summary>
    /// Resets expense transactional data so tests can start from a clean slate.
    /// Example: curl.exe -X POST "http://localhost:7047/Navision_NAV/ODataV4/ExpenseTestHandler_Initialize?company=4d77b30a-3dc5-f011-9c12-7ced8d9e45e7" -u username:password -H "Content-Type: application/json" -H "Accept: application/json" -d "{}"
    /// </summary>
    [ServiceEnabled]
    procedure Initialize(): Text[30]
    var
        LibraryExpense: Codeunit "Library - Expense";
    begin
        LibraryExpense.CleanTransactionalData();
        exit('Initialize completed');
    end;

    /// <summary>
    /// Creates a test Expense User with the specified parameters.
    /// Example: curl.exe -X POST "http://localhost:7047/Navision_NAV/ODataV4/ExpenseTestHandler_CreateExpenseUser?company=4d77b30a-3dc5-f011-9c12-7ced8d9e45e7" -u username:password -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"no\": \"EMP001\", \"name\": \"John Doe\", \"email\": \"john.doe@contoso.com\"}"
    /// </summary>
    /// <param name="no">The expense user no (optional - auto-generated based on No. Series)</param>
    /// <param name="name">The expense user name (optional)</param>
    /// <param name="email">The expense user email (optional)</param>
    /// <returns>The SystemId of the created expense user</returns>
    [ServiceEnabled]
    procedure CreateExpenseUser(No: Code[20]; name: Text[100]; email: Text[80]): Guid
    var
        ExpenseUser: Record "Expense User";
        LibraryExpense: Codeunit "Library - Expense";
        IsModified: Boolean;
    begin
        if No = '' then
            // Use library to create with auto-generated values
            LibraryExpense.CreateExpenseUser(ExpenseUser)
        else
            if not ExpenseUser.Get(No) then
                CreateExpenseUser(ExpenseUser, No);

        // Override with provided values if specified
        if ExpenseUser."Employee No." = '' then begin
            ExpenseUser.Validate("Employee No.", GetEmployeeNo(No));
            IsModified := true;
        end;

        if name <> '' then begin
            ExpenseUser.Validate(Name, name);
            IsModified := true;
        end;

        if email <> '' then begin
            ExpenseUser.Validate("E-mail", email);
            IsModified := true;
        end;

        if IsModified then
            ExpenseUser.Modify(true);

        exit(ExpenseUser.SystemId);
    end;

    local procedure CreateExpenseUser(var ExpenseUser: Record "Expense User"; No: Code[20])
    begin
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", No);
        ExpenseUser.Validate("Employee No.", GetEmployeeNo(No));
        ExpenseUser.Insert(true);
    end;

    local procedure GetEmployeeNo(EmployeeNo: Code[20]): Code[20]
    var
        ExpenseUser: Record "Expense User";
        LibraryExpense: Codeunit "Library - Expense";
    begin
        ExpenseUser.SetFilter("Employee No.", '%1', EmployeeNo);
        if ExpenseUser.FindFirst() then
            exit(ExpenseUser."Employee No.")
        else
            exit(LibraryExpense.CreateEmployee(EmployeeNo));
    end;

    /// <summary>
    /// Enables or disables the project/task fields and configures visibility scope on the Expense Agent Setup.
    /// Example: curl.exe -X POST ".../ExpenseTestHandler_SetProjectFields?company=..." -d "{\"enabled\": true, \"allProjects\": false}"
    /// </summary>
    /// <param name="enabled">Whether project fields are enabled for submitters.</param>
    /// <param name="allProjects">When true sets visibility to "All projects"; otherwise "Assigned projects".</param>
    [ServiceEnabled]
    procedure SetProjectFields(enabled: Boolean; allProjects: Boolean): Text[50]
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup.Validate("Enable Project Fields", enabled);
        if allProjects then
            ExpenseAgentSetup.Validate("Project Visibility", ExpenseAgentSetup."Project Visibility"::"All projects")
        else
            ExpenseAgentSetup.Validate("Project Visibility", ExpenseAgentSetup."Project Visibility"::"Assigned projects");
        ExpenseAgentSetup.Modify(true);
        exit('SetProjectFields completed');
    end;

    /// <summary>
    /// Resolves the Expense User by SystemId and ensures a Resource is linked to its Employee.
    /// Returns the Resource No. so the caller can plan jobs against it without a follow-up lookup.
    /// </summary>
    [ServiceEnabled]
    procedure EnsureResourceForExpenseUser(expenseUserId: Guid; resourceNo: Code[20]): Code[20]
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.GetBySystemId(expenseUserId);
        exit(EnsureResourceForEmployee(ExpenseUser."Employee No.", resourceNo));
    end;

    /// <summary>
    /// Clears the Resource No. on the Employee linked to the given Expense User. Returns the
    /// affected Employee No. (or '' when the user has no employee link). Used by the
    /// empty-resource-join scenario where the user must appear with an empty Resource No.
    /// </summary>
    [ServiceEnabled]
    procedure ClearResourceForExpenseUser(expenseUserId: Guid): Code[20]
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
    begin
        ExpenseUser.GetBySystemId(expenseUserId);
        if (ExpenseUser."Employee No." <> '') and Employee.Get(ExpenseUser."Employee No.") then begin
            Employee.Validate("Resource No.", '');
            Employee.Modify(true);
        end;
        exit(ExpenseUser."Employee No.");
    end;

    /// <summary>
    /// Ensures a Resource exists and is linked to the given Employee. Returns the Resource No.
    /// Example: -d "{\"employeeNo\": \"EMP001\", \"resourceNo\": \"RES001\"}"
    /// </summary>
    [ServiceEnabled]
    procedure EnsureResourceForEmployee(employeeNo: Code[20]; resourceNo: Code[20]): Code[20]
    var
        Resource: Record Resource;
        Employee: Record Employee;
        LibraryResource: Codeunit "Library - Resource";
        ResNo: Code[20];
    begin
        ResNo := resourceNo;
        if ResNo = '' then begin
            LibraryResource.CreateResourceNew(Resource);
            ResNo := Resource."No.";
        end else
            if not Resource.Get(ResNo) then begin
                Resource.Init();
                Resource.Validate("No.", ResNo);
                Resource.Insert(true);
            end;

        if (employeeNo <> '') and Employee.Get(employeeNo) then begin
            Employee.Validate("Resource No.", ResNo);
            Employee.Modify(true);
        end;
        exit(ResNo);
    end;

    /// <summary>
    /// Creates a Job (Project) with the requested fields. PersonResponsible must be a Resource No.
    /// Example: -d "{\"no\":\"PRJ001\",\"description\":\"Test\",\"personResponsibleResourceNo\":\"RES001\",\"status\":\"Open\"}"
    /// </summary>
    [ServiceEnabled]
    procedure CreateProject(no: Code[20]; description: Text[100]; personResponsibleResourceNo: Code[20]; status: Text[20]): Guid
    var
        Job: Record Job;
        BillToCustomerNo: Code[20];
    begin
        if Job.Get(no) then
            exit(Job.SystemId);

        Job.Init();
        Job.Validate("No.", no);
        Job.Insert(true);

        if description <> '' then
            Job.Validate(Description, description);
        if personResponsibleResourceNo <> '' then
            Job.Validate("Person Responsible", personResponsibleResourceNo);

        BillToCustomerNo := FindAnyCustomer();
        if BillToCustomerNo <> '' then
            Job.Validate("Bill-to Customer No.", BillToCustomerNo);

        case UpperCase(status) of
            'OPEN':
                Job.Validate(Status, Job.Status::Open);
            'PLANNING':
                Job.Validate(Status, Job.Status::Planning);
            'QUOTE':
                Job.Validate(Status, Job.Status::Quote);
            'COMPLETED':
                Job.Validate(Status, Job.Status::Completed);
            else
                Job.Validate(Status, Job.Status::Open);
        end;
        Job.Modify(true);
        exit(Job.SystemId);
    end;

    /// <summary>
    /// Creates a Job Task under a Job. Returns the SystemId of the task.
    /// </summary>
    [ServiceEnabled]
    procedure CreateProjectTask(jobNo: Code[20]; taskNo: Code[20]; description: Text[100]): Guid
    var
        JobTask: Record "Job Task";
    begin
        if JobTask.Get(jobNo, taskNo) then
            exit(JobTask.SystemId);

        JobTask.Init();
        JobTask.Validate("Job No.", jobNo);
        JobTask.Validate("Job Task No.", taskNo);
        JobTask.Insert(true);
        if description <> '' then begin
            JobTask.Validate(Description, description);
            JobTask.Modify(true);
        end;
        exit(JobTask.SystemId);
    end;

    /// <summary>
    /// Creates a Job Planning Line assigning a Resource (user) to a Job Task on a given date.
    /// Line Type defaults to "Both Budget and Billable" so the task surfaces in user-assigned queries.
    /// </summary>
    [ServiceEnabled]
    procedure CreatePlanningLineForUser(jobNo: Code[20]; taskNo: Code[20]; resourceNo: Code[20]; planningDateText: Text[30]): Guid
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanningDate: Date;
    begin
        JobTask.Get(jobNo, taskNo);

        if planningDateText <> '' then
            Evaluate(PlanningDate, planningDateText);
        if PlanningDate = 0D then
            PlanningDate := WorkDate();

        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", jobNo);
        JobPlanningLine.Validate("Job Task No.", taskNo);
        JobPlanningLine."Line No." := GetNextPlanningLineNo(jobNo, taskNo);
        JobPlanningLine.Insert(true);

        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Validate("Planning Date", PlanningDate);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.Validate("No.", resourceNo);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Modify(true);
        exit(JobPlanningLine.SystemId);
    end;

    /// <summary>
    /// Assigns a Resource to a Project (blank taskNo -> whole-project assignment) or to a
    /// specific posting Project Task, via a Job Assigned Resource record. Returns the
    /// SystemId of the assignment.
    /// Example: -d "{\"jobNo\":\"PRJ001\",\"taskNo\":\"\",\"resourceNo\":\"RES001\"}"
    /// </summary>
    [ServiceEnabled]
    procedure CreateJobAssignedResource(jobNo: Code[20]; taskNo: Code[20]; resourceNo: Code[20]): Guid
    var
        JobAssignedResource: Record "Job Assigned Resource";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJobAssignedResource(jobNo, taskNo, resourceNo, JobAssignedResource);
        exit(JobAssignedResource.SystemId);
    end;

    /// <summary>
    /// Deletes all Job Planning Lines, Job Assigned Resources, Job Tasks, and Jobs - cleans up project fixtures between tests.
    /// </summary>
    [ServiceEnabled]
    procedure CleanupProjects(): Text[30]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobAssignedResource: Record "Job Assigned Resource";
    begin
        JobPlanningLine.DeleteAll(true);
        JobAssignedResource.DeleteAll(true);
        JobTask.DeleteAll(true);
        Job.DeleteAll(true);
        exit('CleanupProjects completed');
    end;

    local procedure GetNextPlanningLineNo(JobNo: Code[20]; JobTaskNo: Code[20]): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        if JobPlanningLine.FindLast() then
            exit(JobPlanningLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure FindAnyCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        if Customer.FindFirst() then
            exit(Customer."No.");
        exit('');
    end;
}