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

codeunit 148331 "Expense Projects API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
    end;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
        ProjectsServiceNameTok: Label 'expenseProjects', Locked = true;
        ProjectFieldsNotEnabledErrTxt: Label 'Project fields are not enabled', Locked = true;
        ScopeRequiredErrTxt: Label 'filter on expenseUserSystemId is required', Locked = true;

    [Test]
    procedure AssignedByPersonResponsibleReturnsWholeProjectViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        OtherResource: Record Resource;
        AssignedJob: Record Job;
        OtherUserJob: Record Job;
        UnassignedJob: Record Job;
        ExpenseUser: Record "Expense User";
        JobTask: Record "Job Task";
        AssignedPostingTask: Record "Job Task";
        AssignedHeadingTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] Assigned-visibility: a project whose Person Responsible matches the
        // user's resource is returned with ALL its posting tasks; other users' projects are excluded.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);
        LibraryResource.CreateResourceNew(OtherResource);

        // [GIVEN] An Open job with Person Responsible = user's resource (posting + heading task).
        LibraryJob.CreateJob(AssignedJob);
        LibraryJob.CreateJobTask(AssignedJob, AssignedPostingTask);
        LibraryJob.CreateJobTask(AssignedJob, AssignedHeadingTask);
        AssignedHeadingTask.Validate("Job Task Type", AssignedHeadingTask."Job Task Type"::Heading);
        AssignedHeadingTask.Modify(true);
        AssignedJob.Validate(Status, AssignedJob.Status::Open);
        AssignedJob.Validate("Person Responsible", UserResource."No.");
        AssignedJob.Modify(true);

        // [GIVEN] A job for another resource and an unassigned job.
        LibraryJob.CreateJob(OtherUserJob);
        LibraryJob.CreateJobTask(OtherUserJob, JobTask);
        OtherUserJob.Validate(Status, OtherUserJob.Status::Open);
        OtherUserJob.Validate("Person Responsible", OtherResource."No.");
        OtherUserJob.Modify(true);

        LibraryJob.CreateJob(UnassignedJob);
        LibraryJob.CreateJobTask(UnassignedJob, JobTask);
        UnassignedJob.Validate(Status, UnassignedJob.Status::Open);
        UnassignedJob.Modify(true);
        Commit();

        // [WHEN] The assigned projects are fetched scoped to the user.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);

        // [THEN] The user's project is present; the others are not.
        Assert.IsTrue(ProjectExists(ResponseText, AssignedJob."No."),
            'Job with matching Person Responsible must be returned.');
        Assert.IsFalse(ProjectExists(ResponseText, OtherUserJob."No."),
            'Job assigned to another resource must not be returned.');
        Assert.IsFalse(ProjectExists(ResponseText, UnassignedJob."No."),
            'Unassigned job must not be returned in assigned visibility.');

        // [THEN] The posting task is present; the heading task is excluded.
        Assert.IsTrue(RowExists(ResponseText, AssignedJob."No.", AssignedPostingTask."Job Task No."),
            'Posting task must be returned for the whole-project assignment.');
        Assert.IsFalse(RowExists(ResponseText, AssignedJob."No.", AssignedHeadingTask."Job Task No."),
            'Heading task must never be returned.');
    end;

    [Test]
    procedure AssignedByProjectManagerReturnsWholeProjectViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        AssignedJob: Record Job;
        OtherJob: Record Job;
        ExpenseUser: Record "Expense User";
        AssignedPostingTask: Record "Job Task";
        OtherTask: Record "Job Task";
        ResponseText: Text;
        UserApprovalId: Code[50];
    begin
        // [SCENARIO] Assigned-visibility: a project whose Project Manager matches the
        // user's User Id For Approvals is returned; a project managed by someone else is excluded.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);
        UserApprovalId := CopyStr(ExpenseUser."No.", 1, MaxStrLen(UserApprovalId));
        ExpenseUser."User Id For Approvals" := UserApprovalId;
        ExpenseUser.Modify();

        // [GIVEN] An Open job managed by the user and one managed by a different user id.
        LibraryJob.CreateJob(AssignedJob);
        LibraryJob.CreateJobTask(AssignedJob, AssignedPostingTask);
        AssignedJob.Validate(Status, AssignedJob.Status::Open);
        AssignedJob."Project Manager" := UserApprovalId;
        AssignedJob.Modify();

        LibraryJob.CreateJob(OtherJob);
        LibraryJob.CreateJobTask(OtherJob, OtherTask);
        OtherJob.Validate(Status, OtherJob.Status::Open);
        OtherJob."Project Manager" := CopyStr(OtherJob."No.", 1, MaxStrLen(UserApprovalId));
        OtherJob.Modify();
        Commit();

        // [WHEN/THEN] Only the user-managed project is returned, with its posting task.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsTrue(ProjectExists(ResponseText, AssignedJob."No."),
            'Job managed by the user must be returned.');
        Assert.IsTrue(RowExists(ResponseText, AssignedJob."No.", AssignedPostingTask."Job Task No."),
            'Whole-project (Project Manager) signal must return all posting tasks.');
        Assert.IsFalse(ProjectExists(ResponseText, OtherJob."No."),
            'Job managed by another user must not be returned.');
    end;

    [Test]
    procedure AssignedByProjectLevelResourceReturnsWholeProjectViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        OtherResource: Record Resource;
        AssignedJob: Record Job;
        OtherJob: Record Job;
        ExpenseUser: Record "Expense User";
        Task1: Record "Job Task";
        Task2: Record "Job Task";
        OtherTask: Record "Job Task";
        JobAssignedResource: Record "Job Assigned Resource";
        ResponseText: Text;
    begin
        // [SCENARIO] Assigned-visibility: a project-level assigned resource (blank task) matching
        // the user returns the whole project; another user's assigned resource does not leak.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);
        LibraryResource.CreateResourceNew(OtherResource);

        LibraryJob.CreateJob(AssignedJob);
        LibraryJob.CreateJobTask(AssignedJob, Task1);
        LibraryJob.CreateJobTask(AssignedJob, Task2);
        AssignedJob.Validate(Status, AssignedJob.Status::Open);
        AssignedJob.Modify(true);
        LibraryJob.CreateJobAssignedResource(AssignedJob."No.", '', UserResource."No.", JobAssignedResource);

        // [GIVEN] Another job assigned (project-level) to a different resource.
        LibraryJob.CreateJob(OtherJob);
        LibraryJob.CreateJobTask(OtherJob, OtherTask);
        OtherJob.Validate(Status, OtherJob.Status::Open);
        OtherJob.Modify(true);
        LibraryJob.CreateJobAssignedResource(OtherJob."No.", '', OtherResource."No.", JobAssignedResource);
        Commit();

        // [WHEN/THEN] Only the user's project is returned, with BOTH posting tasks.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsTrue(ProjectExists(ResponseText, AssignedJob."No."),
            'Project-level assigned resource must return the project.');
        Assert.IsTrue(RowExists(ResponseText, AssignedJob."No.", Task1."Job Task No."), 'Task 1 must be present (whole project).');
        Assert.IsTrue(RowExists(ResponseText, AssignedJob."No.", Task2."Job Task No."), 'Task 2 must be present (whole project).');
        Assert.IsFalse(ProjectExists(ResponseText, OtherJob."No."),
            'Another resource''s assigned project must not be returned.');
    end;

    [Test]
    procedure AssignedByTaskLevelResourceReturnsOnlyThatTaskViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        OtherResource: Record Resource;
        Job: Record Job;
        ExpenseUser: Record "Expense User";
        UserTask: Record "Job Task";
        OtherTask: Record "Job Task";
        JobAssignedResource: Record "Job Assigned Resource";
        ResponseText: Text;
    begin
        // [SCENARIO] Assigned-visibility: a task-level assigned resource returns the project with
        // ONLY the assigned task; a task assigned to another resource on the same project is excluded.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);
        LibraryResource.CreateResourceNew(OtherResource);

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, UserTask);
        LibraryJob.CreateJobTask(Job, OtherTask);
        Job.Validate(Status, Job.Status::Open);
        Job.Modify(true);
        LibraryJob.CreateJobAssignedResource(Job."No.", UserTask."Job Task No.", UserResource."No.", JobAssignedResource);
        LibraryJob.CreateJobAssignedResource(Job."No.", OtherTask."Job Task No.", OtherResource."No.", JobAssignedResource);
        Commit();

        // [WHEN/THEN] The project is returned but only the user's task.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsTrue(ProjectExists(ResponseText, Job."No."),
            'Project with a task-level assignment must be returned.');
        Assert.IsTrue(RowExists(ResponseText, Job."No.", UserTask."Job Task No."),
            'The user''s assigned task must be present.');
        Assert.IsFalse(RowExists(ResponseText, Job."No.", OtherTask."Job Task No."),
            'A task assigned to another resource must not be returned.');
    end;

    [Test]
    procedure AssignedByPlanningLineReturnsOnlyThatTaskViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        OtherResource: Record Resource;
        Job: Record Job;
        ExpenseUser: Record "Expense User";
        UserTask: Record "Job Task";
        OtherTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] Assigned-visibility: a resource planning line returns the project with ONLY the
        // planned task; a task planned for another resource on the same project is excluded.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);
        LibraryResource.CreateResourceNew(OtherResource);

        LibraryJob.CreateJob(Job);
        Job.Validate(Status, Job.Status::Open);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, UserTask);
        CreateResourcePlanningLine(UserTask, UserResource);
        LibraryJob.CreateJobTask(Job, OtherTask);
        CreateResourcePlanningLine(OtherTask, OtherResource);
        Commit();

        // [WHEN/THEN] The project is returned but only the user's planned task.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsTrue(ProjectExists(ResponseText, Job."No."),
            'Project with a resource planning line must be returned.');
        Assert.IsTrue(RowExists(ResponseText, Job."No.", UserTask."Job Task No."),
            'The user''s planned task must be present.');
        Assert.IsFalse(RowExists(ResponseText, Job."No.", OtherTask."Job Task No."),
            'A task planned for another resource must not be returned.');
    end;

    [Test]
    procedure WholeProjectSignalSupersedesTaskLevelViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        Job: Record Job;
        ExpenseUser: Record "Expense User";
        Task1: Record "Job Task";
        Task2: Record "Job Task";
        JobAssignedResource: Record "Job Assigned Resource";
        ResponseText: Text;
    begin
        // [SCENARIO] When the user matches both a whole-project signal (Person Responsible) and a
        // task-level signal on one task, ALL posting tasks are returned (whole-project wins).
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, Task1);
        LibraryJob.CreateJobTask(Job, Task2);
        Job.Validate(Status, Job.Status::Open);
        Job.Validate("Person Responsible", UserResource."No.");
        Job.Modify(true);
        LibraryJob.CreateJobAssignedResource(Job."No.", Task1."Job Task No.", UserResource."No.", JobAssignedResource);
        Commit();

        // [WHEN/THEN] Both posting tasks are returned even though only Task1 has a task-level row.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsTrue(ProjectExists(ResponseText, Job."No."), 'Project must be returned.');
        Assert.IsTrue(RowExists(ResponseText, Job."No.", Task1."Job Task No."), 'Task 1 must be present.');
        Assert.IsTrue(RowExists(ResponseText, Job."No.", Task2."Job Task No."),
            'Task 2 must be present because the whole-project signal supersedes per-task.');
    end;

    [Test]
    procedure OverlappingSignalsForSameResourceAreDeduplicatedViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        Job: Record Job;
        ExpenseUser: Record "Expense User";
        Task1: Record "Job Task";
        Task2: Record "Job Task";
        JobAssignedResource: Record "Job Assigned Resource";
        ResponseText: Text;
        UserApprovalId: Code[50];
    begin
        // [SCENARIO] When the SAME resource is wired to one project through EVERY signal
        // (Person Responsible, Project Manager, project-level and task-level assigned resource,
        // and a planning line), each project/posting-task row appears exactly once.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);
        UserApprovalId := CopyStr(ExpenseUser."No.", 1, MaxStrLen(UserApprovalId));
        ExpenseUser."User Id For Approvals" := UserApprovalId;
        ExpenseUser.Modify();

        // [GIVEN] One Open job with two posting tasks, all signals pointing at the user's resource.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, Task1);
        LibraryJob.CreateJobTask(Job, Task2);
        Job.Validate(Status, Job.Status::Open);
        Job.Validate("Person Responsible", UserResource."No.");
        Job."Project Manager" := UserApprovalId;
        Job.Modify(true);
        LibraryJob.CreateJobAssignedResource(Job."No.", '', UserResource."No.", JobAssignedResource);
        LibraryJob.CreateJobAssignedResource(Job."No.", Task1."Job Task No.", UserResource."No.", JobAssignedResource);
        CreateResourcePlanningLine(Task1, UserResource);
        CreateResourcePlanningLine(Task2, UserResource);
        Commit();

        // [WHEN] The assigned projects are fetched scoped to the user.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);

        // [THEN] Each posting task appears exactly once, and the project has exactly two rows.
        Assert.AreEqual(1, CountRows(ResponseText, Job."No.", Task1."Job Task No."),
            'Task 1 row must appear exactly once despite overlapping signals.');
        Assert.AreEqual(1, CountRows(ResponseText, Job."No.", Task2."Job Task No."),
            'Task 2 row must appear exactly once despite overlapping signals.');
        Assert.AreEqual(2, CountProjectRows(ResponseText, Job."No."),
            'Project must have exactly one row per posting task, no duplicates.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CompletedProjectExcludedEvenWhenAssignedViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        CompletedJob: Record Job;
        ExpenseUser: Record "Expense User";
        JobTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] A Completed project assigned to the user must still be excluded.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);

        LibraryJob.CreateJob(CompletedJob);
        LibraryJob.CreateJobTask(CompletedJob, JobTask);
        CompletedJob.Validate("Person Responsible", UserResource."No.");
        CompletedJob.Validate(Status, CompletedJob.Status::Completed);
        CompletedJob.Modify(true);
        Commit();

        // [WHEN/THEN] The completed project is not returned.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsFalse(ProjectExists(ResponseText, CompletedJob."No."),
            'Completed project must not be returned even when assigned.');
    end;

    [Test]
    procedure EmptyResourceUserMatchesNothingViaAPI()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        UnassignedJob: Record Job;
        JobTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] A user whose Employee has no Resource No. must not match jobs with empty
        // Person Responsible (empty = empty must not join).
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();

        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Resource No.", '');
        Employee.Modify(true);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.SetSkipOverwriteFromEmployee(true);
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser.Modify(true);

        LibraryJob.CreateJob(UnassignedJob);
        LibraryJob.CreateJobTask(UnassignedJob, JobTask);
        UnassignedJob.Validate(Status, UnassignedJob.Status::Open);
        UnassignedJob.Validate("Person Responsible", '');
        UnassignedJob.Modify(true);
        Commit();

        // [WHEN/THEN] Nothing is returned for the empty-resource user.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsFalse(ProjectExists(ResponseText, UnassignedJob."No."),
            'Empty-resource user must not match a job with empty Person Responsible.');
    end;

    [Test]
    procedure BlankUserIdDoesNotMatchBlankProjectManagerViaAPI()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        UnassignedJob: Record Job;
        JobTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] A user with a blank User Id For Approvals must not match a job with a
        // blank Project Manager (empty = empty must not join).
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();

        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Resource No.", '');
        Employee.Modify(true);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.SetSkipOverwriteFromEmployee(true);
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser."User Id For Approvals" := '';
        ExpenseUser.Modify(true);

        LibraryJob.CreateJob(UnassignedJob);
        LibraryJob.CreateJobTask(UnassignedJob, JobTask);
        UnassignedJob.Validate(Status, UnassignedJob.Status::Open);
        UnassignedJob."Project Manager" := '';
        UnassignedJob.Modify();
        Commit();

        // [WHEN/THEN] Nothing is returned for the blank-identity user.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsFalse(ProjectExists(ResponseText, UnassignedJob."No."),
            'Blank User Id must not match a job with a blank Project Manager.');
    end;

    [Test]
    procedure ProjectManagerMatchWithBlankResourceReturnsProjectViaAPI()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        AssignedJob: Record Job;
        PostingTask: Record "Job Task";
        ResponseText: Text;
        UserApprovalId: Code[50];
    begin
        // [SCENARIO] A user with NO resource but a Project Manager match must still get the project;
        // the resource-based signals are skipped gracefully.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();

        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Resource No.", '');
        Employee.Modify(true);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.SetSkipOverwriteFromEmployee(true);
        ExpenseUser.Validate("Employee No.", Employee."No.");
        UserApprovalId := CopyStr(ExpenseUser."No.", 1, MaxStrLen(UserApprovalId));
        ExpenseUser."User Id For Approvals" := UserApprovalId;
        ExpenseUser.Modify(true);

        LibraryJob.CreateJob(AssignedJob);
        LibraryJob.CreateJobTask(AssignedJob, PostingTask);
        AssignedJob.Validate(Status, AssignedJob.Status::Open);
        AssignedJob."Project Manager" := UserApprovalId;
        AssignedJob.Modify();
        Commit();

        // [WHEN/THEN] The project managed by the user is returned even without a resource.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsTrue(ProjectExists(ResponseText, AssignedJob."No."),
            'Project Manager match must return the project even when the user has no resource.');
        Assert.IsTrue(RowExists(ResponseText, AssignedJob."No.", PostingTask."Job Task No."),
            'The posting task must be present for a Project Manager (whole-project) assignment.');
    end;

    [Test]
    procedure TasklessProjectExcludedViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        TasklessJob: Record Job;
        ExpenseUser: Record "Expense User";
        HeadingTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] A project the user is assigned to but which has NO posting task is excluded, because expenses can only post to posting-type tasks.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);

        LibraryJob.CreateJob(TasklessJob);
        LibraryJob.CreateJobTask(TasklessJob, HeadingTask);
        HeadingTask.Validate("Job Task Type", HeadingTask."Job Task Type"::Heading);
        HeadingTask.Modify(true);
        TasklessJob.Validate(Status, TasklessJob.Status::Open);
        TasklessJob.Validate("Person Responsible", UserResource."No.");
        TasklessJob.Modify(true);
        Commit();

        // [WHEN/THEN] The taskless project is not returned.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        Assert.IsFalse(ProjectExists(ResponseText, TasklessJob."No."),
            'A project with no posting task must not be returned even when assigned.');
    end;

    [Test]
    procedure WholeProjectAndTaskLevelAcrossProjectsNoLeakageViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        WholeJob: Record Job;
        TaskJob: Record Job;
        ExpenseUser: Record "Expense User";
        WholeTask1: Record "Job Task";
        WholeTask2: Record "Job Task";
        TaskAssignedTask: Record "Job Task";
        TaskUnassignedTask: Record "Job Task";
        JobAssignedResource: Record "Job Assigned Resource";
        ResponseText: Text;
    begin
        // [SCENARIO] The user is whole-project assigned to project A (Person Responsible) and
        // task-level assigned on ONE task of project B. A returns all its tasks; B returns only the
        // assigned task; no state leaks between projects.
        Initialize();
        EnsureProjectFieldsEnabled();
        SetProjectVisibilityToAssigned();
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);

        LibraryJob.CreateJob(WholeJob);
        LibraryJob.CreateJobTask(WholeJob, WholeTask1);
        LibraryJob.CreateJobTask(WholeJob, WholeTask2);
        WholeJob.Validate(Status, WholeJob.Status::Open);
        WholeJob.Validate("Person Responsible", UserResource."No.");
        WholeJob.Modify(true);

        LibraryJob.CreateJob(TaskJob);
        LibraryJob.CreateJobTask(TaskJob, TaskAssignedTask);
        LibraryJob.CreateJobTask(TaskJob, TaskUnassignedTask);
        TaskJob.Validate(Status, TaskJob.Status::Open);
        TaskJob.Modify(true);
        LibraryJob.CreateJobAssignedResource(TaskJob."No.", TaskAssignedTask."Job Task No.", UserResource."No.", JobAssignedResource);
        Commit();

        // [WHEN/THEN]
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);
        // Whole-project A: both tasks.
        Assert.IsTrue(RowExists(ResponseText, WholeJob."No.", WholeTask1."Job Task No."), 'Whole-project task 1 must be present.');
        Assert.IsTrue(RowExists(ResponseText, WholeJob."No.", WholeTask2."Job Task No."), 'Whole-project task 2 must be present.');
        // Task-level B: only the assigned task.
        Assert.IsTrue(RowExists(ResponseText, TaskJob."No.", TaskAssignedTask."Job Task No."), 'Task-level assigned task must be present.');
        Assert.IsFalse(RowExists(ResponseText, TaskJob."No.", TaskUnassignedTask."Job Task No."),
            'Non-assigned task of the task-level project must not be present.');
    end;

    [Test]
    procedure AllProjectsVisibilityReturnsAllProjectsViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        AssignedJob: Record Job;
        UnassignedJob: Record Job;
        ExpenseUser: Record "Expense User";
        AssignedTask: Record "Job Task";
        UnassignedTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] All-projects visibility: every non-completed project is returned with its
        // posting tasks, regardless of whether the user is assigned to it.
        Initialize();
        EnsureProjectFieldsEnabled(); // sets visibility = All projects
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);

        LibraryJob.CreateJob(AssignedJob);
        LibraryJob.CreateJobTask(AssignedJob, AssignedTask);
        AssignedJob.Validate(Status, AssignedJob.Status::Open);
        AssignedJob.Validate("Person Responsible", UserResource."No.");
        AssignedJob.Modify(true);

        LibraryJob.CreateJob(UnassignedJob);
        LibraryJob.CreateJobTask(UnassignedJob, UnassignedTask);
        UnassignedJob.Validate(Status, UnassignedJob.Status::Open);
        UnassignedJob.Modify(true);
        Commit();

        // [WHEN] Fetch scoped to the user under All-projects visibility.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);

        // [THEN] Both the assigned and the non-assigned project are present with their posting tasks.
        Assert.IsTrue(RowExists(ResponseText, AssignedJob."No.", AssignedTask."Job Task No."),
            'Assigned project (with its task) must be present under All-projects visibility.');
        Assert.IsTrue(RowExists(ResponseText, UnassignedJob."No.", UnassignedTask."Job Task No."),
            'Non-assigned project (with its task) must still be present under All-projects visibility.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AllProjectsVisibilityIncludesActiveStatusesAndPostingTasksViaAPI()
    var
        Employee: Record Employee;
        UserResource: Record Resource;
        PlanningJob: Record Job;
        QuoteJob: Record Job;
        OpenJob: Record Job;
        CompletedJob: Record Job;
        ExpenseUser: Record "Expense User";
        JobTask: Record "Job Task";
        OpenPostingTask: Record "Job Task";
        OpenHeadingTask: Record "Job Task";
        ResponseText: Text;
    begin
        // [SCENARIO] All-projects visibility returns every non-completed project (Planning, Quote,
        // Open), excludes Completed, and exposes only posting-type tasks.
        Initialize();
        EnsureProjectFieldsEnabled(); // sets visibility = All projects
        CreateExpenseUserWithResource(ExpenseUser, Employee, UserResource);

        LibraryJob.CreateJob(PlanningJob);
        LibraryJob.CreateJobTask(PlanningJob, JobTask);
        PlanningJob.Validate(Status, PlanningJob.Status::Planning);
        PlanningJob.Modify(true);

        LibraryJob.CreateJob(QuoteJob);
        LibraryJob.CreateJobTask(QuoteJob, JobTask);
        QuoteJob.Validate(Status, QuoteJob.Status::Quote);
        QuoteJob.Modify(true);

        LibraryJob.CreateJob(OpenJob);
        LibraryJob.CreateJobTask(OpenJob, OpenPostingTask);
        LibraryJob.CreateJobTask(OpenJob, OpenHeadingTask);
        OpenHeadingTask.Validate("Job Task Type", OpenHeadingTask."Job Task Type"::Heading);
        OpenHeadingTask.Modify(true);
        OpenJob.Validate(Status, OpenJob.Status::Open);
        OpenJob.Modify(true);

        LibraryJob.CreateJob(CompletedJob);
        LibraryJob.CreateJobTask(CompletedJob, JobTask);
        CompletedJob.Validate(Status, CompletedJob.Status::Completed);
        CompletedJob.Modify(true);
        Commit();

        // [WHEN] Fetch scoped to the user under All-projects visibility.
        ResponseText := GetProjectsForExpense(ExpenseUser.SystemId);

        // [THEN] All three active jobs are present and the Completed one is excluded.
        Assert.IsTrue(ProjectExists(ResponseText, PlanningJob."No."), 'Planning job must be returned.');
        Assert.IsTrue(ProjectExists(ResponseText, QuoteJob."No."), 'Quote job must be returned.');
        Assert.IsTrue(ProjectExists(ResponseText, OpenJob."No."), 'Open job must be returned.');
        Assert.IsFalse(ProjectExists(ResponseText, CompletedJob."No."), 'Completed job must NOT be returned.');

        // [THEN] The posting task is present but the heading task is excluded.
        Assert.IsTrue(RowExists(ResponseText, OpenJob."No.", OpenPostingTask."Job Task No."),
            'Posting task must be returned.');
        Assert.IsFalse(RowExists(ResponseText, OpenJob."No.", OpenHeadingTask."Job Task No."),
            'Heading task must NOT be returned.');
    end;

    [Test]
    procedure AssignedProjectsRequiresScopeFilterViaAPI()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] The endpoint must error when expenseUserSystemId is missing.
        Initialize();
        EnsureProjectFieldsEnabled();
        Commit();

        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Projects API", ProjectsServiceNameTok);
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.ExpectedError(ScopeRequiredErrTxt);
    end;

    [Test]
    procedure AssignedProjectsBlockedWhenProjectFieldsDisabledViaAPI()
    var
        ExpenseUser: Record "Expense User";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] The endpoint must error when Enable Project Fields = false.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        DisableProjectFields();
        Commit();

        TargetURL := BuildUserScopedProjectsURL(ExpenseUser.SystemId);
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.ExpectedError(ProjectFieldsNotEnabledErrTxt);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Projects API Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Projects API Test");
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Projects API Test");
    end;

    local procedure EnsureProjectFieldsEnabled()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Project Fields" := true;
        ExpenseAgentSetup."Project Visibility" := ExpenseAgentSetup."Project Visibility"::"All projects";
        ExpenseAgentSetup.Modify();
    end;

    local procedure SetProjectVisibilityToAssigned()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Project Fields" := true;
        ExpenseAgentSetup."Project Visibility" := ExpenseAgentSetup."Project Visibility"::"Assigned projects";
        ExpenseAgentSetup.Modify();
    end;

    local procedure DisableProjectFields()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Enable Project Fields" := false;
        ExpenseAgentSetup.Modify();
    end;

    local procedure CreateExpenseUserWithResource(var ExpenseUser: Record "Expense User"; var Employee: Record Employee; var Resource: Record Resource)
    begin
        LibraryResource.CreateResourceNew(Resource);

        LibraryHumanResource.CreateEmployee(Employee);
        Employee.Validate("Resource No.", Resource."No.");
        Employee.Modify(true);

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.SetSkipOverwriteFromEmployee(true);
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser.Modify(true);
    end;

    local procedure CreateResourcePlanningLine(JobTask: Record "Job Task"; Resource: Record Resource)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJobPlanningLine(
            JobTask,
            "Job Planning Line Line Type"::"Both Budget and Billable",
            "Job Planning Line Type"::Resource,
            Resource."No.",
            1,
            JobPlanningLine);
    end;

    local procedure GetProjectsForExpense(UserSystemId: Guid): Text
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        TargetURL := BuildUserScopedProjectsURL(UserSystemId);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        exit(ResponseText);
    end;

    local procedure BuildUserScopedProjectsURL(UserSystemId: Guid): Text
    begin
        // Use user-scoped navigation expenseUsers({id})/expenseProjects. The part's SubPageLink supplies the required scope, so no $filter is appended (which also avoids clashing with the ?tenant=<name> query string on multi-tenant builds).
        exit(
            LibraryGraphMgt.CreateTargetURLWithSubpage(
                Format(UserSystemId),
                Page::"Expense Users API",
                ExpenseUsersServiceNameTok,
                ProjectsServiceNameTok));
    end;

    local procedure ProjectExists(ResponseText: Text; ProjectNo: Text): Boolean
    begin
        exit(CountProjectRows(ResponseText, ProjectNo) > 0);
    end;

    local procedure RowExists(ResponseText: Text; ProjectNo: Text; ProjectTaskNo: Text): Boolean
    var
        RowObj: JsonObject;
    begin
        exit(FindRow(ResponseText, ProjectNo, ProjectTaskNo, RowObj));
    end;

    local procedure CountProjectRows(ResponseText: Text; ProjectNo: Text): Integer
    var
        ValueArr: JsonArray;
        ItemTok: JsonToken;
        PropTok: JsonToken;
        Count: Integer;
    begin
        if not TryGetValueArray(ResponseText, ValueArr) then
            exit(0);
        foreach ItemTok in ValueArr do
            if ItemTok.AsObject().Get('projectNo', PropTok) then
                if PropTok.AsValue().AsText() = ProjectNo then
                    Count += 1;
        exit(Count);
    end;

    local procedure CountRows(ResponseText: Text; ProjectNo: Text; ProjectTaskNo: Text): Integer
    var
        ValueArr: JsonArray;
        ItemTok: JsonToken;
        Obj: JsonObject;
        ProjectTok: JsonToken;
        TaskTok: JsonToken;
        Count: Integer;
    begin
        if not TryGetValueArray(ResponseText, ValueArr) then
            exit(0);
        foreach ItemTok in ValueArr do begin
            Obj := ItemTok.AsObject();
            if Obj.Get('projectNo', ProjectTok) and Obj.Get('projectTaskNo', TaskTok) then
                if (ProjectTok.AsValue().AsText() = ProjectNo) and (TaskTok.AsValue().AsText() = ProjectTaskNo) then
                    Count += 1;
        end;
        exit(Count);
    end;

    local procedure FindRow(ResponseText: Text; ProjectNo: Text; ProjectTaskNo: Text; var RowObj: JsonObject): Boolean
    var
        ValueArr: JsonArray;
        ItemTok: JsonToken;
        Obj: JsonObject;
        ProjectTok: JsonToken;
        TaskTok: JsonToken;
    begin
        Clear(RowObj);
        if not TryGetValueArray(ResponseText, ValueArr) then
            exit(false);
        foreach ItemTok in ValueArr do begin
            Obj := ItemTok.AsObject();
            if Obj.Get('projectNo', ProjectTok) and Obj.Get('projectTaskNo', TaskTok) then
                if (ProjectTok.AsValue().AsText() = ProjectNo) and (TaskTok.AsValue().AsText() = ProjectTaskNo) then begin
                    RowObj := Obj;
                    exit(true);
                end;
        end;
        exit(false);
    end;

    local procedure TryGetValueArray(ResponseText: Text; var ValueArr: JsonArray): Boolean
    var
        Root: JsonObject;
        ValueTok: JsonToken;
    begin
        Root.ReadFrom(ResponseText);
        if not Root.Get('value', ValueTok) then
            exit(false);
        ValueArr := ValueTok.AsArray();
        exit(true);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Swallow informational messages (e.g. "Ending Date is set to ...") raised when
        // a Job's Status is validated to Completed via Job.ChangeJobCompletionStatus.
    end;
}
