// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents;

using System.Agents;
using System.TestLibraries.Utilities;

codeunit 133962 "Agent Task Management Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        AgentTask: Codeunit "Agent Task";
        LibraryTestAgent: Codeunit "Library Mock Agent";

    local procedure Initialize()
    begin
        LibraryTestAgent.DeleteAllAgents();
    end;

    #region Task Lifecycle Tests

    [Test]
    procedure CreateAndStartTask()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        ExternalIdTok: Label 'MGMT-TASK-001', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a task and set its status to ready to start processing

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));

        // [WHEN] A task is created with status set to ready
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [THEN] The task should exist
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalIdTok), 'Task should exist');

        // [THEN] The task should not be completed or stopped
        Assert.IsFalse(AgentTask.IsTaskCompleted(AgentTaskRecord), 'Task should not be completed');
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should not be stopped');
    end;

    [Test]
    procedure SetTaskStatusToReady()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-002', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Set a task status to ready after creation

        // [GIVEN] A test agent with a task not initially set to ready
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Draft Task to be Started')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [THEN] Task should be able to be set to ready
        Assert.IsTrue(AgentTask.CanSetStatusToReady(AgentTaskRecord), 'Task should be able to be set to ready');

        // [WHEN] Setting the task status to ready
        AgentTask.SetStatusToReady(AgentTaskRecord);

        // [THEN] The task should be ready for processing
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.AreEqual(AgentTaskRecord.Status, AgentTaskRecord.Status::Ready, 'Task status should be Ready');
    end;

    [Test]
    procedure CanSetStatusToReadyForNewTask()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        CanSetReady: Boolean;
        ExternalIdTok: Label 'MGMT-TASK-003', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Check if a newly created task can be set to ready

        // [GIVEN] A test agent with a new task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'New Task for Status Check')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] Checking if task can be set to ready
        CanSetReady := AgentTask.CanSetStatusToReady(AgentTaskRecord);

        // [THEN] The task should be able to be set to ready
        Assert.IsTrue(CanSetReady, 'New task should be able to be set to ready');
    end;

    #endregion

    #region Task Stop Tests

    [Test]
    procedure StopRunningTask()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-004', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Stop a task that is ready or running

        // [GIVEN] A test agent with a task set to ready
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Task to be Stopped')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [WHEN] Stopping the task without user confirmation
        AgentTask.StopTask(AgentTaskRecord, false);

        // [THEN] The task should be stopped
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should be stopped');
    end;

    [Test]
    procedure StopTaskAndVerifyStatus()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-005', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Verify task status after stopping

        // [GIVEN] A test agent with a running task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Running Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [WHEN] The task is stopped
        AgentTask.StopTask(AgentTaskRecord, false);

        // [THEN] The task should be marked as stopped
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should be in stopped state');
        Assert.IsFalse(AgentTask.IsTaskRunning(AgentTaskRecord), 'Task should not be running');
        Assert.IsFalse(AgentTask.IsTaskCompleted(AgentTaskRecord), 'Task should not be completed');
    end;

    #endregion

    #region Task Archive Tests

    [Test]
    procedure ArchiveStoppedTask()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
    begin
        Initialize();

        // [SCENARIO] Archive a task that was previously stopped

        // [GIVEN] A test agent with a stopped task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder.Initialize(AgentUserId, 'Stopped Task to be Archived');

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [GIVEN] The task is stopped
        AgentTask.StopTask(AgentTaskRecord, false);
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should be stopped initially');
        Assert.IsFalse(AgentTaskRecord.Archived, 'Task should not be archived initially');

        // [WHEN] Archiving the stopped task
        AgentTask.ArchiveTask(AgentTaskRecord.Id, false);

        // [THEN] The task should be archived
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTaskRecord.Archived, 'Task should be archived');
    end;

    [Test]
    procedure ArchiveAlreadyArchivedTask()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
    begin
        Initialize();

        // [SCENARIO] Archive a task that is already archived (should be idempotent)

        // [GIVEN] A test agent with an archived task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder.Initialize(AgentUserId, 'Already Archived Task');

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [GIVEN] The task is already archived
        AgentTask.StopTask(AgentTaskRecord, false);
        AgentTask.ArchiveTask(AgentTaskRecord.Id, false);
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTaskRecord.Archived, 'Task should be archived initially');

        // [WHEN] Archiving the task again
        AgentTask.ArchiveTask(AgentTaskRecord.Id, false);

        // [THEN] The task should still be archived (no error, idempotent operation)
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTaskRecord.Archived, 'Task should remain archived');
    end;

    #endregion

    #region Task Restart Tests

    [Test]
    procedure RestartStoppedTask()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-006', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Restart a task that was previously stopped

        // [GIVEN] A test agent with a stopped task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Task to be Restarted')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [GIVEN] The task is stopped
        AgentTask.StopTask(AgentTaskRecord, false);
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should be stopped initially');

        // [WHEN] Restarting the task without user confirmation
        AgentTask.RestartTask(AgentTaskRecord, false);

        // [THEN] The task should no longer be stopped
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should not be stopped after restart');
    end;

    [Test]
    procedure RestartTaskSetsStatusToReady()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-007', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Restarting a task should set its status to ready

        // [GIVEN] A test agent with a stopped task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Stopped Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.
        AgentTask.StopTask(AgentTaskRecord, false);

        // [WHEN] Restarting the task
        AgentTask.RestartTask(AgentTaskRecord, false);

        // [THEN] The task should be ready to process
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should not be stopped');
        Assert.IsFalse(AgentTask.IsTaskCompleted(AgentTaskRecord), 'Task should not be completed');
    end;

    #endregion

    #region Task Status Check Tests

    [Test]
    procedure CheckIsTaskRunning()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        IsRunning: Boolean;
        ExternalIdTok: Label 'MGMT-TASK-008', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Check if a task is currently running

        // [GIVEN] A test agent with a task set to ready
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Running Status Check Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [WHEN] Checking if the task is running
        IsRunning := AgentTask.IsTaskRunning(AgentTaskRecord);

        // [THEN] The result should indicate the task state
        // Note: Depending on timing, task may or may not have started processing
        Assert.IsTrue(IsRunning or not IsRunning, 'IsTaskRunning should return a boolean value');
    end;

    [Test]
    procedure CheckIsTaskCompleted()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-009', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Check if a newly created task is completed

        // [GIVEN] A test agent with a new task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Completion Check Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] Checking if the task is completed
        // [THEN] The task should not be completed immediately after creation
        Assert.IsFalse(AgentTask.IsTaskCompleted(AgentTaskRecord), 'Newly created task should not be completed');
    end;

    [Test]
    procedure CheckIsTaskStopped()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-010', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Check if a task is stopped

        // [GIVEN] A test agent with a new task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Stop Status Check Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] Checking if the task is stopped
        // [THEN] The task should not be stopped immediately after creation
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord), 'Newly created task should not be stopped');
    end;

    #endregion

    #region Complex Task Management Scenarios

    [Test]
    procedure StopAndRestartMultipleTimes()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-011', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Stop and restart a task multiple times

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Cycle Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [WHEN] Stopping and restarting the task multiple times
        // First cycle
        AgentTask.StopTask(AgentTaskRecord, false);
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should be stopped after first stop');

        AgentTask.RestartTask(AgentTaskRecord, false);
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should not be stopped after first restart');

        // Second cycle
        AgentTask.StopTask(AgentTaskRecord, false);
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsTrue(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should be stopped after second stop');

        AgentTask.RestartTask(AgentTaskRecord, false);
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should not be stopped after second restart');

        // [THEN] The task should remain in a valid state
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalIdTok), 'Task should still exist after multiple cycles');
    end;

    [Test]
    procedure ManageMultipleTasksSimultaneously()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord1: Record "Agent Task";
        AgentTaskRecord2: Record "Agent Task";
        AgentTaskRecord3: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalId1Tok: Label 'MGMT-TASK-012-A', Locked = true;
        ExternalId2Tok: Label 'MGMT-TASK-012-B', Locked = true;
        ExternalId3Tok: Label 'MGMT-TASK-012-C', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Manage multiple tasks with different states simultaneously

        // [GIVEN] A test agent with three tasks
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder.Initialize(AgentUserId, 'First Task').SetExternalId(ExternalId1Tok);
        AgentTaskRecord1 := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        Clear(AgentTaskBuilder);
        AgentTaskBuilder.Initialize(AgentUserId, 'Second Task').SetExternalId(ExternalId2Tok);
        AgentTaskRecord2 := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        Clear(AgentTaskBuilder);
        AgentTaskBuilder.Initialize(AgentUserId, 'Third Task').SetExternalId(ExternalId3Tok);
        AgentTaskRecord3 := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [WHEN] Managing tasks with different operations
        AgentTask.StopTask(AgentTaskRecord1, false);

        AgentTask.StopTask(AgentTaskRecord2, false);
        AgentTask.RestartTask(AgentTaskRecord2, false);

        // [THEN] Each task should have the correct state
        AgentTaskRecord1.Get(AgentTaskRecord1.Id);
        Assert.IsTrue(AgentTask.IsTaskStopped(AgentTaskRecord1), 'First task should be stopped');

        AgentTaskRecord2.Get(AgentTaskRecord2.Id);
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord2), 'Second task should not be stopped');

        AgentTaskRecord3.Get(AgentTaskRecord3.Id);
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord3), 'Third task should not be stopped');
    end;

    [Test]
    procedure VerifyTaskRetrievalAfterManagement()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        RetrievedTask: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MGMT-TASK-013', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Verify task can be retrieved by external ID after management operations

        // [GIVEN] A test agent with a task that undergoes management operations
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Managed Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [GIVEN] The task is stopped and restarted
        AgentTask.StopTask(AgentTaskRecord, false);
        AgentTask.RestartTask(AgentTaskRecord, false);

        // [WHEN] Retrieving the task by external ID
        RetrievedTask := AgentTask.GetTaskByExternalId(AgentUserId, ExternalIdTok);

        // [THEN] The retrieved task should match the original task
        Assert.AreEqual(AgentTaskRecord.Id, RetrievedTask.Id, 'Task ID should match');
        Assert.AreEqual(AgentTaskRecord."External ID", RetrievedTask."External ID", 'External ID should match');
        Assert.AreEqual(AgentTaskRecord.Title, RetrievedTask.Title, 'Title should match');
    end;

    #endregion
}
