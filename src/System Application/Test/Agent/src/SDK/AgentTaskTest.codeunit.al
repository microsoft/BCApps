// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

using System.Agents;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 133960 "Agent Task Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        AgentTask: Codeunit "Agent Task";
        AgentMessage: Codeunit "Agent Message";
        LibraryTestAgent: Codeunit "Library Mock Agent";

    local procedure Initialize()
    begin
        LibraryTestAgent.DeleteAllAgents();
    end;

    [Test]
    procedure CreateTaskWithoutMessageAndVerify()
    var
        AgentRecord: Record Agent;
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        ExternalIdTok: Label 'EXT-TASK-001', Locked = true;
        ExpectedErrorTxt: Label 'The task cannot be set to ready because it has no messages. Add at least one message to the task before setting it to ready.', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent is created
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [GIVEN] Task details without any message
        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));

        // [WHEN] A task is created without a message and set to ready
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok);

        // [THEN] An error should be raised when trying to create the task
        asserterror AgentTaskBuilder.Create();
        Assert.ExpectedError(ExpectedErrorTxt);
    end;

    [Test]
    procedure CreateTaskWithMessageAndVerify()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        MessageFrom: Text[250];
        MessageText: Text;
        ExternalIdTok: Label 'EXT-TASK-002', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent is created
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [GIVEN] Task and message details
        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));
        MessageFrom := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom)), 1, MaxStrLen(MessageFrom));
        MessageText := Any.AlphanumericText(2048);

        // [WHEN] A task is created with a message
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok)
            .AddTaskMessage(MessageFrom, MessageText);

        AgentTaskRecord := AgentTaskBuilder.Create();
        AgentTaskMessageRecord := AgentTaskBuilder.GetAgentTaskMessageCreated();

        // [THEN] The task should exist
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalIdTok), 'Task should exist');

        // [THEN] The message should be created
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should have valid ID');
        Assert.AreEqual(MessageText, AgentMessage.GetText(AgentTaskMessageRecord), 'Message text should match');
    end;

    [Test]
    procedure CreateTaskWithPermissionsInAllCompaniesAndVerify()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        MessageFrom: Text[250];
        MessageText: Text;
        ExternalIdTok: Label 'EXT-TASK-002-B', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent is created
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [GIVEN] Task and message details
        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));
        MessageFrom := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom)), 1, MaxStrLen(MessageFrom));
        MessageText := Any.AlphanumericText(2048);

        // [GIVEN] Agent access control permissions are modified to apply to all companies
        UpdateAccessControlToSpecifiedCompany(AgentUserId, '');
        Commit();

        // [WHEN] A task is created with a message
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok)
            .AddTaskMessage(MessageFrom, MessageText);

        AgentTaskRecord := AgentTaskBuilder.Create();
        AgentTaskMessageRecord := AgentTaskBuilder.GetAgentTaskMessageCreated();

        // [THEN] The task should exist
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalIdTok), 'Task should exist');

        // [THEN] The message should be created
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should have valid ID');
        Assert.AreEqual(MessageText, AgentMessage.GetText(AgentTaskMessageRecord), 'Message text should match');
    end;

    [Test]
    procedure CreateTaskWithoutPermissionsAndVerify()
    var
        AgentRecord: Record Agent;
        AccessControl: Record "Access Control";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        MessageFrom: Text[250];
        MessageText: Text;
        ExternalIdTok: Label 'EXT-TASK-001-B', Locked = true;
        ExpectedErrorTxt: Label 'The task cannot be set to ready because the agent has no access control permissions in the %1 company. The agent has permissions in the following companies: %2. Grant the agent permissions in this company before setting the task to ready.', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent is created
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [GIVEN] Task and message details
        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));
        MessageFrom := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom)), 1, MaxStrLen(MessageFrom));
        MessageText := Any.AlphanumericText(2048);

        // [GIVEN] Agent access control permissions are temporarily removed
        AccessControl.SetRange("User Security ID", AgentUserId);
        AccessControl.DeleteAll();
        Commit();

        // [WHEN] A task is created with a message and set to ready
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok)
            .AddTaskMessage(MessageFrom, MessageText);

        // [THEN] An error should be raised because agent has no permissions
        asserterror AgentTaskBuilder.Create();
        Assert.ExpectedError(StrSubstNo(ExpectedErrorTxt, CompanyName(), ''));
    end;

    [Test]
    procedure GetTaskByExternalId()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        RetrievedTask: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        ExternalIdTok: Label 'EXT-TASK-003', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));

        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [WHEN] The task is retrieved by external ID
        RetrievedTask := AgentTask.GetTaskByExternalId(AgentUserId, ExternalIdTok);

        // [THEN] The retrieved task should match the created task
        Assert.AreEqual(AgentTaskRecord."Agent User Security ID", RetrievedTask."Agent User Security ID", 'Agent ID should match');
        Assert.AreEqual(AgentTaskRecord."External ID", RetrievedTask."External ID", 'External ID should match');
        Assert.AreEqual(AgentTaskRecord.Title, RetrievedTask.Title, 'Title should match');
    end;

    [Test]
    procedure CreateMultipleTasksWithDifferentExternalIds()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord1: Record "Agent Task";
        AgentTaskRecord2: Record "Agent Task";
        AgentTaskRecord3: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalId1Tok: Label 'EXT-TASK-004-A', Locked = true;
        ExternalId2Tok: Label 'EXT-TASK-004-B', Locked = true;
        ExternalId3Tok: Label 'EXT-TASK-004-C', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Multiple tasks with different external IDs are created
        Clear(AgentTaskBuilder);
        AgentTaskBuilder
            .Initialize(AgentUserId, 'First Task')
            .SetExternalId(ExternalId1Tok);
        AgentTaskRecord1 := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        Clear(AgentTaskBuilder);
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Second Task')
            .SetExternalId(ExternalId2Tok);
        AgentTaskRecord2 := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        Clear(AgentTaskBuilder);
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Third Task')
            .SetExternalId(ExternalId3Tok);
        AgentTaskRecord3 := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [THEN] All tasks should exist
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalId1Tok), 'First task should exist');
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalId2Tok), 'Second task should exist');
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalId3Tok), 'Third task should exist');

        // [THEN] All tasks should have different external IDs
        Assert.AreNotEqual(AgentTaskRecord1."External ID", AgentTaskRecord2."External ID", 'External IDs should be different');
        Assert.AreNotEqual(AgentTaskRecord1."External ID", AgentTaskRecord3."External ID", 'External IDs should be different');
        Assert.AreNotEqual(AgentTaskRecord2."External ID", AgentTaskRecord3."External ID", 'External IDs should be different');
    end;

    [Test]
    procedure CheckTaskStatusAfterCreation()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'EXT-TASK-005', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] A task is created with status ready
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Status Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false); // Allow for tasks without message.

        // [THEN] The task should not be in completed or stopped state
        Assert.IsFalse(AgentTask.IsTaskCompleted(AgentTaskRecord), 'Task should not be completed immediately after creation');
        Assert.IsFalse(AgentTask.IsTaskStopped(AgentTaskRecord), 'Task should not be stopped immediately after creation');
    end;

    [Test]
    procedure CreateTaskWithoutSettingStatusToReady()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'EXT-TASK-006', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] A task is created without setting status to ready
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Draft Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [THEN] The task should exist
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalIdTok), 'Task should exist even when not set to ready');

        // [THEN] The task should not be running
        Assert.IsFalse(AgentTask.IsTaskRunning(AgentTaskRecord), 'Task should not be running when not set to ready');
    end;

    [Test]
    procedure VerifyTaskCanBeSetToReady()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'EXT-TASK-007', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent with a task not set to ready
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Ready Status Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] Checking if task can be set to ready
        // [THEN] The task should be able to transition to ready state
        Assert.IsTrue(AgentTask.CanSetStatusToReady(AgentTaskRecord), 'Task should be able to be set to ready');
    end;

    [Test]
    procedure CreateTaskWithMessageBuilder()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        MessageFrom: Text[250];
        MessageText: Text;
        ExternalIdTok: Label 'EXT-TASK-008', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [GIVEN] A message builder
        MessageFrom := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom)), 1, MaxStrLen(MessageFrom));
        MessageText := Any.AlphanumericText(2048);

        AgentTaskMessageBuilder
            .Initialize(MessageFrom, MessageText);

        // [WHEN] A task is created with the message builder
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Task with Message Builder')
            .SetExternalId(ExternalIdTok)
            .AddTaskMessage(AgentTaskMessageBuilder);

        AgentTaskRecord := AgentTaskBuilder.Create();
        AgentTaskMessageRecord := AgentTaskBuilder.GetAgentTaskMessageCreated();

        // [THEN] The task and message should be created
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalIdTok), 'Task should exist');
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created');
        Assert.AreEqual(MessageText, AgentMessage.GetText(AgentTaskMessageRecord), 'Message text should match');
    end;

    [Test]
    procedure CreateTaskWithMultipleMessages()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder1: Codeunit "Agent Task Message Builder";
        AgentTaskMessageBuilder2: Codeunit "Agent Task Message Builder";
        AgentTaskMessageBuilder3: Codeunit "Agent Task Message Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        MessageFrom1: Text[250];
        MessageText1: Text;
        MessageFrom2: Text[250];
        MessageText2: Text;
        MessageFrom3: Text[250];
        MessageText3: Text;
        MessageCount: Integer;
        ExternalIdTok: Label 'EXT-TASK-009', Locked = true;
    begin
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [GIVEN] Multiple messages
        MessageFrom1 := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom1)), 1, MaxStrLen(MessageFrom1));
        MessageText1 := Any.AlphanumericText(2048);
        MessageFrom2 := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom2)), 1, MaxStrLen(MessageFrom2));
        MessageText2 := Any.AlphanumericText(2048);
        MessageFrom3 := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom3)), 1, MaxStrLen(MessageFrom3));
        MessageText3 := Any.AlphanumericText(2048);

        // [WHEN] A task is created with the first message
        AgentTaskMessageBuilder1.Initialize(MessageFrom1, MessageText1);

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Task with Multiple Messages')
            .SetExternalId(ExternalIdTok)
            .AddTaskMessage(AgentTaskMessageBuilder1);

        AgentTaskRecord := AgentTaskBuilder.Create(false);

        // [WHEN] Additional messages are added to the task
        AgentTaskMessageBuilder2.Initialize(MessageFrom2, MessageText2);
        AgentTaskMessageBuilder2.SetAgentTask(AgentTaskRecord.Id);
        AgentTaskMessage := AgentTaskMessageBuilder2.Create();

        AgentTaskMessageBuilder3.Initialize(MessageFrom3, MessageText3);
        AgentTaskMessageBuilder3.SetAgentTask(AgentTaskRecord.Id);
        AgentTaskMessage := AgentTaskMessageBuilder3.Create();

        // [THEN] The task should exist
        Assert.IsTrue(AgentTask.TaskExists(AgentUserId, ExternalIdTok), 'Task should exist');

        // [THEN] The task should have 3 messages
        AgentTaskMessage.SetRange("Task Id", AgentTaskRecord.Id);
        MessageCount := AgentTaskMessage.Count();
        Assert.AreEqual(3, MessageCount, 'Task should have 3 messages');

        // [THEN] Each message should have the correct content
        AgentTaskMessage.FindSet();
        Assert.AreEqual(MessageText1, AgentMessage.GetText(AgentTaskMessage), 'First message text should match');

        AgentTaskMessage.Next();
        Assert.AreEqual(MessageText2, AgentMessage.GetText(AgentTaskMessage), 'Second message text should match');

        AgentTaskMessage.Next();
        Assert.AreEqual(MessageText3, AgentMessage.GetText(AgentTaskMessage), 'Third message text should match');
    end;

    local procedure UpdateAccessControlToSpecifiedCompany(UserSecurityId: Guid; NewCompanyName: Text[30])
    var
        AccessControl: Record "Access Control";
        TempAccessControl: Record "Access Control" temporary;
    begin
        // Step 1: Collect all records into temp table
        AccessControl.SetRange("User Security ID", UserSecurityId);
        if AccessControl.FindSet() then
            repeat
                TempAccessControl := AccessControl;
                TempAccessControl.Insert();
            until AccessControl.Next() = 0;

        // Step 2: Delete old records
        AccessControl.SetRange("User Security ID", UserSecurityId);
        AccessControl.DeleteAll();

        // Step 3: Insert new records with updated company name
        if TempAccessControl.FindSet() then
            repeat
                Clear(AccessControl);
                AccessControl."User Security ID" := TempAccessControl."User Security ID";
                AccessControl."Role ID" := TempAccessControl."Role ID";
                AccessControl."Company Name" := NewCompanyName;
                AccessControl.Scope := TempAccessControl.Scope;
                AccessControl."App ID" := TempAccessControl."App ID";
                AccessControl.Insert();
            until TempAccessControl.Next() = 0;
    end;

    #region Model ID Tests

    [Test]
    procedure CreateTaskWithModelIdAndVerify()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        ModelId: Code[30];
        RetrievedModelId: Code[30];
        RetrievedModelName: Text[70];
        ExternalIdTok: Label 'EXT-TASK-MODEL-001', Locked = true;
    begin
        // [SCENARIO] Creating a task with a model ID and verifying GetModelId and GetModelName return the expected values
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));
        ModelId := CopyStr(Any.AlphanumericText(MaxStrLen(ModelId)), 1, MaxStrLen(ModelId));

        // [WHEN] A task is created with a model ID
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok)
            .SetModelId(ModelId);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false);

        // [THEN] GetModelId returns the model ID that was set
        RetrievedModelId := AgentTask.GetModelId(AgentTaskRecord.ID);
        Assert.AreEqual(ModelId, RetrievedModelId, 'Model ID should match the one set on the task');

        // [THEN] GetModelName returns empty since the model ID does not exist in the Agent Model table
        RetrievedModelName := AgentTask.GetModelName(AgentTaskRecord.ID);
        Assert.AreEqual('', RetrievedModelName, 'Model name should be empty for a non-existent model');
    end;

    [Test]
    procedure CreateTaskWithoutModelIdAndVerify()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        RetrievedModelId: Code[30];
        RetrievedModelName: Text[70];
        ExternalIdTok: Label 'EXT-TASK-MODEL-002', Locked = true;
    begin
        // [SCENARIO] Creating a task without setting a model ID and verifying GetModelId and GetModelName return empty values
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));

        // [WHEN] A task is created without setting a model ID
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(true, false);

        // [THEN] GetModelId returns empty
        RetrievedModelId := AgentTask.GetModelId(AgentTaskRecord.ID);
        Assert.AreEqual('', RetrievedModelId, 'Model ID should be empty when not set');

        // [THEN] GetModelName returns empty
        RetrievedModelName := AgentTask.GetModelName(AgentTaskRecord.ID);
        Assert.AreEqual('', RetrievedModelName, 'Model name should be empty when model ID is not set');
    end;

    [Test]
    procedure GetModelIdAndNameForNonExistentTaskFails()
    var
        NonExistentTaskId: BigInteger;
    begin
        // [SCENARIO] Calling GetModelId and GetModelName with a non-existent task ID should fail
        Initialize();

        // [GIVEN] A task ID that does not exist
        NonExistentTaskId := 999999999;

        // [WHEN] GetModelId is called with a non-existent task ID
        // [THEN] An error is raised
        asserterror AgentTask.GetModelId(NonExistentTaskId);

        // [WHEN] GetModelName is called with a non-existent task ID
        // [THEN] An error is raised
        asserterror AgentTask.GetModelName(NonExistentTaskId);
    end;

    [Test]
    procedure CreateTaskWithEmptyModelIdAndVerify()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        RetrievedModelId: Code[30];
        ExternalIdTok: Label 'EXT-TASK-MODEL-004', Locked = true;
    begin
        // [SCENARIO] Explicitly setting an empty model ID behaves the same as not setting one
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));

        // [WHEN] A task is created with an explicitly empty model ID
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok)
            .SetModelId('');

        AgentTaskRecord := AgentTaskBuilder.Create(true, false);

        // [THEN] GetModelId returns empty
        RetrievedModelId := AgentTask.GetModelId(AgentTaskRecord.ID);
        Assert.AreEqual('', RetrievedModelId, 'Model ID should be empty when explicitly set to empty');
    end;

    [Test]
    procedure CreateMultipleTasksWithDifferentModelIds()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord1: Record "Agent Task";
        AgentTaskRecord2: Record "Agent Task";
        AgentTaskRecord3: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ModelId1: Code[30];
        ModelId2: Code[30];
        ModelId3: Code[30];
        ExternalId1Tok: Label 'EXT-TASK-MODEL-005-A', Locked = true;
        ExternalId2Tok: Label 'EXT-TASK-MODEL-005-B', Locked = true;
        ExternalId3Tok: Label 'EXT-TASK-MODEL-005-C', Locked = true;
    begin
        // [SCENARIO] Multiple tasks with different model IDs retain their own model ID
        Initialize();

        // [GIVEN] A test agent
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        ModelId1 := CopyStr(Any.AlphanumericText(MaxStrLen(ModelId1)), 1, MaxStrLen(ModelId1));
        ModelId2 := CopyStr(Any.AlphanumericText(MaxStrLen(ModelId2)), 1, MaxStrLen(ModelId2));
        ModelId3 := CopyStr(Any.AlphanumericText(MaxStrLen(ModelId3)), 1, MaxStrLen(ModelId3));

        // [WHEN] Multiple tasks are created with different model IDs
        Clear(AgentTaskBuilder);
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Task Model 1')
            .SetExternalId(ExternalId1Tok)
            .SetModelId(ModelId1);
        AgentTaskRecord1 := AgentTaskBuilder.Create(true, false);

        Clear(AgentTaskBuilder);
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Task Model 2')
            .SetExternalId(ExternalId2Tok)
            .SetModelId(ModelId2);
        AgentTaskRecord2 := AgentTaskBuilder.Create(true, false);

        Clear(AgentTaskBuilder);
        AgentTaskBuilder
            .Initialize(AgentUserId, 'Task Model 3')
            .SetExternalId(ExternalId3Tok)
            .SetModelId(ModelId3);
        AgentTaskRecord3 := AgentTaskBuilder.Create(true, false);

        // [THEN] Each task should have its own model ID
        Assert.AreEqual(ModelId1, AgentTask.GetModelId(AgentTaskRecord1.ID), 'First task model ID should match');
        Assert.AreEqual(ModelId2, AgentTask.GetModelId(AgentTaskRecord2.ID), 'Second task model ID should match');
        Assert.AreEqual(ModelId3, AgentTask.GetModelId(AgentTaskRecord3.ID), 'Third task model ID should match');

        // [THEN] All model IDs should be different from each other
        Assert.AreNotEqual(ModelId1, ModelId2, 'Model IDs should be different');
        Assert.AreNotEqual(ModelId1, ModelId3, 'Model IDs should be different');
        Assert.AreNotEqual(ModelId2, ModelId3, 'Model IDs should be different');
    end;

    [Test]
    procedure CreateTaskWithDefaultModelIdAndVerify()
    var
        AgentRecord: Record Agent;
        AgentModel: Record "Agent Model";
        AgentTaskRecord: Record "Agent Task";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        TaskTitle: Text[150];
        RetrievedModelId: Code[30];
        RetrievedModelName: Text[70];
        ExternalIdTok: Label 'EXT-TASK-MODEL-006', Locked = true;
    begin
        // [SCENARIO] Creating a task with the default Agent Model ID and verifying GetModelId and GetModelName return expected values
        Initialize();

        // [GIVEN] A test agent and the default agent model
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentModel.SetRange("Is Default", true);
        Assert.IsTrue(AgentModel.FindFirst(), 'A default agent model should exist');

        TaskTitle := CopyStr(Any.AlphanumericText(MaxStrLen(TaskTitle)), 1, MaxStrLen(TaskTitle));

        // [WHEN] A task is created with the default model ID
        AgentTaskBuilder
            .Initialize(AgentUserId, TaskTitle)
            .SetExternalId(ExternalIdTok)
            .SetModelId(AgentModel."Model ID");

        AgentTaskRecord := AgentTaskBuilder.Create(true, false);

        // [THEN] GetModelId returns the default model ID
        RetrievedModelId := AgentTask.GetModelId(AgentTaskRecord.ID);
        Assert.AreEqual(AgentModel."Model ID", RetrievedModelId, 'Model ID should match the default model');

        // [THEN] GetModelName returns the default model name
        RetrievedModelName := AgentTask.GetModelName(AgentTaskRecord.ID);
        Assert.AreEqual(AgentModel."Model Name", RetrievedModelName, 'Model name should match the default model name');
    end;

    #endregion
}
