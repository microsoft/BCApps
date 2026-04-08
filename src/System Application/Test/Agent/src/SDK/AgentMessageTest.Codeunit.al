// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

using System.Agents;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 133963 "Agent Message Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        AgentTask: Codeunit "Agent Task";
        AgentMessage: Codeunit "Agent Message";
        LibraryTestAgent: Codeunit "Library Mock Agent";

    local procedure Initialize()
    begin
        LibraryTestAgent.DeleteAllAgents();
    end;

    #region Agent Message Tests

    [Test]
    procedure GetTextFromMessage()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        MessageText: Text;
        RetrievedText: Text;
        ExternalIdTok: Label 'MSG-TEST-001', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get text from an agent task message

        // [GIVEN] A test agent with a task and message
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        MessageText := Any.AlphanumericText(2048);

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Get Text Test Task')
            .SetExternalId(ExternalIdTok)
            .AddTaskMessage('Test User', MessageText);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.
        AgentTaskMessageRecord := AgentTaskBuilder.GetAgentTaskMessageCreated();

        // [WHEN] GetText is called on the message
        RetrievedText := AgentMessage.GetText(AgentTaskMessageRecord);

        // [THEN] The retrieved text should match the original message
        Assert.AreEqual(MessageText, RetrievedText, 'Message text should match');
    end;

    [Test]
    procedure GetTextFromEmptyMessage()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        RetrievedText: Text;
        ExternalIdTok: Label 'MSG-TEST-002', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get text from an empty message

        // [GIVEN] A test agent with a task and empty message
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Empty Message Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.
        AgentTaskMessageRecord := AgentTaskBuilder.GetAgentTaskMessageCreated();

        // [WHEN] GetText is called on the empty message
        RetrievedText := AgentMessage.GetText(AgentTaskMessageRecord);

        // [THEN] The retrieved text should be empty
        Assert.AreEqual('', RetrievedText, 'Empty message should return empty text');
    end;

    [Test]
    procedure GetFileSizeDisplayText_Bytes()
    var
        Any: Codeunit Any;
        DisplayText: Text;
    begin
        Initialize();

        // [SCENARIO] Get display text for file size in bytes

        // [WHEN] GetFileSizeDisplayText is called with byte values
        DisplayText := AgentMessage.GetFileSizeDisplayText(Any.IntegerInRange(100, 999));

        // [THEN] The display text should be formatted correctly
        Assert.AreNotEqual('', DisplayText, 'Display text should not be empty');
    end;

    [Test]
    procedure GetFileSizeDisplayText_Kilobytes()
    var
        Any: Codeunit Any;
        DisplayText: Text;
    begin
        Initialize();

        // [SCENARIO] Get display text for file size in kilobytes

        // [WHEN] GetFileSizeDisplayText is called with KB values
        DisplayText := AgentMessage.GetFileSizeDisplayText(Any.IntegerInRange(1024, 10240));

        // [THEN] The display text should be formatted correctly
        Assert.AreNotEqual('', DisplayText, 'Display text should not be empty for KB');
    end;

    [Test]
    procedure GetFileSizeDisplayText_Megabytes()
    var
        Any: Codeunit Any;
        DisplayText: Text;
    begin
        Initialize();

        // [SCENARIO] Get display text for file size in megabytes

        // [WHEN] GetFileSizeDisplayText is called with MB values
        DisplayText := AgentMessage.GetFileSizeDisplayText(Any.IntegerInRange(1048576, 10485760));

        // [THEN] The display text should be formatted correctly
        Assert.AreNotEqual('', DisplayText, 'Display text should not be empty for MB');
    end;

    [Test]
    procedure GetAttachmentsFromMessageWithNoAttachments()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        TempAgentTaskFile: Record "Agent Task File" temporary;
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSG-TEST-004', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get attachments from a message with no attachments

        // [GIVEN] A test agent with a message without attachments
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'No Attachments Test Task')
            .SetExternalId(ExternalIdTok)
            .AddTaskMessage('Test User', 'Message without attachments');

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.
        AgentTaskMessageRecord := AgentTaskBuilder.GetAgentTaskMessageCreated();

        // [WHEN] GetAttachments is called
        AgentMessage.GetAttachments(AgentTaskRecord.Id, AgentTaskMessageRecord.Id, TempAgentTaskFile);

        // [THEN] No attachments should be returned
        Assert.IsTrue(TempAgentTaskFile.IsEmpty(), 'No attachments should exist');
    end;

    #endregion

    #region Agent Task Message Builder Tests

    [Test]
    procedure CreateMessageWithInitializeFromOnly()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        MessageText: Text;
        ExternalIdTok: Label 'MSGBLD-TEST-001', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a message using Initialize with message text only

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        MessageText := Any.AlphanumericText(2048);

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Message Builder Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created using Initialize with text only
        AgentTaskMessageBuilder
            .Initialize(MessageText)
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be created with the correct text
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created');
        Assert.AreEqual(MessageText, AgentMessage.GetText(AgentTaskMessageRecord), 'Message text should match');
    end;

    [Test]
    procedure CreateMessageWithFromAndText()
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
        ExternalIdTok: Label 'MSGBLD-TEST-002', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a message using Initialize with From and MessageText

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        MessageFrom := CopyStr(Any.AlphanumericText(MaxStrLen(MessageFrom)), 1, MaxStrLen(MessageFrom));
        MessageText := Any.AlphanumericText(2048);

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Message Builder From Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created using Initialize with From and Text
        AgentTaskMessageBuilder
            .Initialize(MessageFrom, MessageText)
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be created with the correct properties
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created');
        Assert.AreEqual(MessageFrom, AgentTaskMessageRecord.From, 'From should match');
        Assert.AreEqual(MessageText, AgentMessage.GetText(AgentTaskMessageRecord), 'Message text should match');
    end;

    [Test]
    procedure CreateMessageWithExternalId()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        MessageExternalId: Text[2048];
        ExternalIdTok: Label 'MSGBLD-TEST-003', Locked = true;
        MsgExternalIdTok: Label 'MSG-EXT-ID-12345', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a message with an external ID

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        MessageExternalId := MsgExternalIdTok;

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Message External ID Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created with an external ID
        AgentTaskMessageBuilder
            .Initialize(CopyStr(Any.AlphanumericText(250), 1, 250), Any.AlphanumericText(2048))
            .SetAgentTask(AgentTaskRecord)
            .SetMessageExternalID(MessageExternalId);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be created with the external ID
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created');
        Assert.AreEqual(MessageExternalId, AgentTaskMessageRecord."External ID", 'External ID should match');
    end;

    [Test]
    procedure CreateMessageWithIgnoreAttachment()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSGBLD-TEST-004', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a message with ignored attachments flag

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Ignore Attachment Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created with SetIgnoreAttachment(true)
        AgentTaskMessageBuilder
            .Initialize(CopyStr(Any.AlphanumericText(250), 1, 250), Any.AlphanumericText(2048))
            .SetAgentTask(AgentTaskRecord)
            .SetIgnoreAttachment(true);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be created successfully
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created with ignore attachment flag');
    end;

    [Test]
    procedure CreateMessageAndSetTaskToReady()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSGBLD-TEST-005', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a message and set task status to ready

        // [GIVEN] A test agent with a task not ready
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Set Ready Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created with SetTaskStatusToReady = true
        AgentTaskMessageBuilder
            .Initialize(CopyStr(Any.AlphanumericText(250), 1, 250), Any.AlphanumericText(2048))
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(true);

        // [THEN] The message should be created
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created');
    end;

    [Test]
    procedure CreateMessageWithoutSettingTaskToReady()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        Any: Codeunit Any;
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSGBLD-TEST-006', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a message without setting task to ready

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Not Ready Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created with SetTaskStatusToReady = false
        AgentTaskMessageBuilder
            .Initialize(CopyStr(Any.AlphanumericText(250), 1, 250), Any.AlphanumericText(2048))
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be created and task should not be running
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created');
        AgentTaskRecord.Get(AgentTaskRecord.Id);
        Assert.IsFalse(AgentTask.IsTaskRunning(AgentTaskRecord), 'Task should not be running');
    end;

    [Test]
    procedure GetAgentTaskMessageAfterCreate()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        RetrievedMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSGBLD-TEST-007', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get agent task message after creation using GetAgentTaskMessage

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT07',
            'Message Builder Test Agent 07',
            'You are a test agent for get message testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Get Message Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created and retrieved via GetAgentTaskMessage
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message to retrieve')
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);
        RetrievedMessageRecord := AgentTaskMessageBuilder.GetAgentTaskMessage();

        // [THEN] Both records should be the same
        Assert.AreEqual(AgentTaskMessageRecord.Id, RetrievedMessageRecord.Id, 'Message IDs should match');
    end;

    [Test]
    procedure SetAgentTaskByRecord()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSGBLD-TEST-008', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Set agent task using the Record overload

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT08',
            'Message Builder Test Agent 08',
            'You are a test agent for set task by record testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Set Task By Record Test')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] SetAgentTask is called with a Record
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message with task set by record')
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be linked to the task
        Assert.AreEqual(AgentTaskRecord.Id, AgentTaskMessageRecord."Task Id", 'Task ID should match');
    end;

    [Test]
    procedure SetAgentTaskById()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSGBLD-TEST-009', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Set agent task using the BigInteger ID overload

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT09',
            'Message Builder Test Agent 09',
            'You are a test agent for set task by ID testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Set Task By ID Test')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] SetAgentTask is called with a BigInteger ID
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message with task set by ID')
            .SetAgentTask(AgentTaskRecord.Id);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be linked to the task
        Assert.AreEqual(AgentTaskRecord.Id, AgentTaskMessageRecord."Task Id", 'Task ID should match');
    end;

    [Test]
    procedure CreateMultipleMessagesOnSameTask()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder1: Codeunit "Agent Task Message Builder";
        AgentTaskMessageBuilder2: Codeunit "Agent Task Message Builder";
        AgentTaskMessageBuilder3: Codeunit "Agent Task Message Builder";
        AgentUserId: Guid;
        MessageCount: Integer;
        ExternalIdTok: Label 'MSGBLD-TEST-010', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create multiple messages on the same task

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT10',
            'Message Builder Test Agent 10',
            'You are a test agent for multiple messages testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Multiple Messages Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] Multiple messages are created for the same task
        AgentTaskMessageBuilder1
            .Initialize('User 1', 'First message')
            .SetAgentTask(AgentTaskRecord);
        AgentTaskMessageBuilder1.Create(false);

        AgentTaskMessageBuilder2
            .Initialize('Agent', 'Second message - agent response')
            .SetAgentTask(AgentTaskRecord);
        AgentTaskMessageBuilder2.Create(false);

        AgentTaskMessageBuilder3
            .Initialize('User 1', 'Third message - follow up')
            .SetAgentTask(AgentTaskRecord);
        AgentTaskMessageBuilder3.Create(false);

        // [THEN] The task should have 3 messages
        AgentTaskMessage.SetRange("Task Id", AgentTaskRecord.Id);
        MessageCount := AgentTaskMessage.Count();
        Assert.AreEqual(3, MessageCount, 'Task should have 3 messages');
    end;

    [Test]
    procedure VerifyMessageFromFieldIsSet()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUserId: Guid;
        ExpectedFrom: Text[250];
        ExternalIdTok: Label 'MSGBLD-TEST-011', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Verify the From field is correctly set on the message

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT11',
            'Message Builder Test Agent 11',
            'You are a test agent for From field testing.');

        ExpectedFrom := 'john.doe@contoso.com';

        AgentTaskBuilder
            .Initialize(AgentUserId, 'From Field Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message is created with a specific From value
        AgentTaskMessageBuilder
            .Initialize(ExpectedFrom, 'Test message content')
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The From field should match
        Assert.AreEqual(ExpectedFrom, AgentTaskMessageRecord.From, 'From field should match the expected value');
    end;

    [Test]
    procedure CreateMessageWithLongText()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUserId: Guid;
        LongMessageText: Text;
        RetrievedText: Text;
        i: Integer;
        ExternalIdTok: Label 'MSGBLD-TEST-012', Locked = true;
        ParagraphLbl: Label 'This is paragraph %1 of the long message content. ', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Create a message with long text content

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT12',
            'Message Builder Test Agent 12',
            'You are a test agent for long message testing.');

        // Create a long message text
        LongMessageText := 'Start of long message. ';
        for i := 1 to 100 do
            LongMessageText += StrSubstNo(ParagraphLbl, i);
        LongMessageText += 'End of long message.';

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Long Message Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] A message with long text is created
        AgentTaskMessageBuilder
            .Initialize('Sender', LongMessageText)
            .SetAgentTask(AgentTaskRecord);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [THEN] The message should be created and text should match
        Assert.AreNotEqual(0, AgentTaskMessageRecord.Id, 'Message should be created');
        RetrievedText := AgentMessage.GetText(AgentTaskMessageRecord);
        Assert.AreEqual(LongMessageText, RetrievedText, 'Long message text should be preserved');
    end;

    [Test]
    procedure GetAttachmentsFromBuilderNoAttachments()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        TempAgentTaskFile: Record "Agent Task File" temporary;
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUserId: Guid;
        ExternalIdTok: Label 'MSGBLD-TEST-013', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get attachments from the message builder when no attachments added

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT13',
            'Message Builder Test Agent 13',
            'You are a test agent for get attachments testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Get Attachments Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [WHEN] GetAttachments is called on the builder before adding any
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message without attachments')
            .SetAgentTask(AgentTaskRecord);


        AgentTaskMessageBuilder.GetAttachments(TempAgentTaskFile);

        // [THEN] No attachments should be returned
        Assert.IsTrue(TempAgentTaskFile.IsEmpty(), 'No attachments should exist');
    end;

    [Test]
    procedure GetAttachmentsFromMessageWithAttachments()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        TempAgentTaskFile: Record "Agent Task File" temporary;
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        TempBlob: Codeunit "Temp Blob";
        AgentUserId: Guid;
        AttachmentInStream: InStream;
        AttachmentOutStream: OutStream;
        FileName: Text[250];
        FileMimeType: Text[100];
        AttachmentCount: Integer;
        ExternalIdTok: Label 'MSGBLD-TEST-014', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get attachments from a message with attachments

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT14',
            'Message Builder Test Agent 14',
            'You are a test agent for get attachments with files testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Get Attachments With Files Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [GIVEN] An attachment to add
        FileName := 'test-document.txt';
        FileMimeType := 'text/plain';
        TempBlob.CreateOutStream(AttachmentOutStream, TextEncoding::UTF8);
        AttachmentOutStream.WriteText('This is test file content for the attachment.');
        TempBlob.CreateInStream(AttachmentInStream, TextEncoding::UTF8);

        // [WHEN] A message is created with an attachment
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message with attachment')
            .SetAgentTask(AgentTaskRecord)
            .AddAttachment(FileName, FileMimeType, AttachmentInStream);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [WHEN] GetAttachments is called on the message
        AgentMessage.GetAttachments(AgentTaskRecord.Id, AgentTaskMessageRecord.Id, TempAgentTaskFile);

        // [THEN] One attachment should be returned
        AttachmentCount := TempAgentTaskFile.Count();
        Assert.AreEqual(1, AttachmentCount, 'One attachment should exist');

        // [THEN] The attachment should have the correct file name
        TempAgentTaskFile.FindFirst();
        Assert.AreEqual(FileName, TempAgentTaskFile."File Name", 'File name should match');
    end;

    [Test]
    procedure GetAttachmentsFromMessageWithMultipleAttachments()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        TempAgentTaskFile: Record "Agent Task File" temporary;
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        TempBlob1: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        TempBlob3: Codeunit "Temp Blob";
        AgentUserId: Guid;
        AttachmentInStream1: InStream;
        AttachmentOutStream1: OutStream;
        AttachmentInStream2: InStream;
        AttachmentOutStream2: OutStream;
        AttachmentInStream3: InStream;
        AttachmentOutStream3: OutStream;
        AttachmentCount: Integer;
        ExternalIdTok: Label 'MSGBLD-TEST-015', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get multiple attachments from a message

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT15',
            'Message Builder Test Agent 15',
            'You are a test agent for multiple attachments testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Multiple Attachments Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [GIVEN] Multiple attachments to add
        TempBlob1.CreateOutStream(AttachmentOutStream1, TextEncoding::UTF8);
        AttachmentOutStream1.WriteText('Content of first file.');
        TempBlob1.CreateInStream(AttachmentInStream1, TextEncoding::UTF8);

        TempBlob2.CreateOutStream(AttachmentOutStream2, TextEncoding::UTF8);
        AttachmentOutStream2.WriteText('Content of second file.');
        TempBlob2.CreateInStream(AttachmentInStream2, TextEncoding::UTF8);

        TempBlob3.CreateOutStream(AttachmentOutStream3, TextEncoding::UTF8);
        AttachmentOutStream3.WriteText('Content of third file.');
        TempBlob3.CreateInStream(AttachmentInStream3, TextEncoding::UTF8);

        // [WHEN] A message is created with multiple attachments
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message with multiple attachments')
            .SetAgentTask(AgentTaskRecord)
            .AddAttachment('document1.txt', 'text/plain', AttachmentInStream1)
            .AddAttachment('document2.pdf', 'application/pdf', AttachmentInStream2)
            .AddAttachment('image.png', 'image/png', AttachmentInStream3);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [WHEN] GetAttachments is called on the message
        AgentMessage.GetAttachments(AgentTaskRecord.Id, AgentTaskMessageRecord.Id, TempAgentTaskFile);

        // [THEN] Three attachments should be returned
        AttachmentCount := TempAgentTaskFile.Count();
        Assert.AreEqual(3, AttachmentCount, 'Three attachments should exist');
    end;

    [Test]
    procedure AddAttachmentWithIgnoredFlag()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        AgentTaskMessageRecord: Record "Agent Task Message";
        TempAgentTaskFile: Record "Agent Task File" temporary;
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        TempBlob: Codeunit "Temp Blob";
        AgentUserId: Guid;
        AttachmentInStream: InStream;
        AttachmentOutStream: OutStream;
        ExternalIdTok: Label 'MSGBLD-TEST-016', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Add an attachment with the ignored flag set to true

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT16',
            'Message Builder Test Agent 16',
            'You are a test agent for ignored attachment testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Ignored Attachment Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [GIVEN] An attachment to add with ignored flag
        TempBlob.CreateOutStream(AttachmentOutStream, TextEncoding::UTF8);
        AttachmentOutStream.WriteText('This attachment should be ignored by the agent.');
        TempBlob.CreateInStream(AttachmentInStream, TextEncoding::UTF8);

        // [WHEN] A message is created with an ignored attachment
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message with ignored attachment')
            .SetAgentTask(AgentTaskRecord)
            .AddAttachment('ignored-file.txt', 'text/plain', AttachmentInStream, true);

        AgentTaskMessageRecord := AgentTaskMessageBuilder.Create(false);

        // [WHEN] GetAttachments is called on the message
        AgentMessage.GetAttachments(AgentTaskRecord.Id, AgentTaskMessageRecord.Id, TempAgentTaskFile);

        // [THEN] The attachment should exist
        Assert.IsFalse(TempAgentTaskFile.IsEmpty(), 'Attachment should exist');

        // [THEN] The attachment file name should match
        TempAgentTaskFile.FindFirst();
        Assert.AreEqual('ignored-file.txt', TempAgentTaskFile."File Name", 'Attachment file name should match');
    end;

    [Test]
    procedure GetLastAttachmentFromBuilder()
    var
        AgentRecord: Record Agent;
        AgentTaskRecord: Record "Agent Task";
        LastAttachment: Record "Agent Task File";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        TempBlob1: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        AgentUserId: Guid;
        AttachmentInStream1: InStream;
        AttachmentOutStream1: OutStream;
        AttachmentInStream2: InStream;
        AttachmentOutStream2: OutStream;
        ExternalIdTok: Label 'MSGBLD-TEST-017', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Get the last attachment added to the message builder

        // [GIVEN] A test agent with a task
        AgentUserId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            'MSGBLDAGENT17',
            'Message Builder Test Agent 17',
            'You are a test agent for get last attachment testing.');

        AgentTaskBuilder
            .Initialize(AgentUserId, 'Get Last Attachment Test Task')
            .SetExternalId(ExternalIdTok);

        AgentTaskRecord := AgentTaskBuilder.Create(false, false); // Allow for tasks without message.

        // [GIVEN] Multiple attachments to add
        TempBlob1.CreateOutStream(AttachmentOutStream1, TextEncoding::UTF8);
        AttachmentOutStream1.WriteText('First file content.');
        TempBlob1.CreateInStream(AttachmentInStream1, TextEncoding::UTF8);

        TempBlob2.CreateOutStream(AttachmentOutStream2, TextEncoding::UTF8);
        AttachmentOutStream2.WriteText('Second file content - this is the last one.');
        TempBlob2.CreateInStream(AttachmentInStream2, TextEncoding::UTF8);

        // [WHEN] Multiple attachments are added to the builder
        AgentTaskMessageBuilder
            .Initialize('Sender', 'Message with attachments')
            .SetAgentTask(AgentTaskRecord)
            .AddAttachment('first-file.txt', 'text/plain', AttachmentInStream1)
            .AddAttachment('last-file.txt', 'text/plain', AttachmentInStream2);

        // [WHEN] GetLastAttachment is called
        LastAttachment := AgentTaskMessageBuilder.GetLastAttachment();

        // [THEN] The last attachment should be returned
        Assert.AreEqual('last-file.txt', LastAttachment."File Name", 'Last attachment file name should match');
    end;

    #endregion
}
