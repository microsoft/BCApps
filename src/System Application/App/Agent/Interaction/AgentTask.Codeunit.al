// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4303 "Agent Task"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Check if a task exists for the given agent user and conversation
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="ConversationId">The conversation ID to check.</param>
    /// <returns>True if task exists, false if not.</returns>
    [Scope('OnPrem')]
    procedure TaskExists(AgentUserSecurityId: Guid; ConversationId: Text): Boolean
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.TaskExists(AgentUserSecurityId, ConversationId));
    end;

    /// <summary>
    /// Create a new task for the given agent.
    /// It is possible to add messages to the task with additional details, however agent can run on just a task with a descriptive title.
    /// The task will be started immediately, if it is in the state that it can be started again.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent that will handle the task.</param>
    /// <param name="TaskTitle">The title of the task. Agent will take the title into the consideration. </param>
    /// <returns>The ID of the task that was created.</returns>
    [Scope('OnPrem')]
    procedure CreateTask(AgentUserSecurityID: Guid; TaskTitle: Text[150]): BigInteger
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.CreateTask(AgentUserSecurityID, TaskTitle, '', true));
    end;

    /// <summary>
    /// Create a new task for the given agent.
    /// It is possible to add messages to the task with additional details, however agent can run on just a task with a descriptive title.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent that will handle the task.</param>
    /// <param name="TaskTitle">The title of the task. Agent will take the title into the consideration. </param>
    /// <param name="ExternalID">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <param name="StartTask">If true, the task will be started immediately. The default value is true. </param>
    /// <returns>The ID of the task that was created.</returns>
    [Scope('OnPrem')]
    procedure CreateTask(AgentUserSecurityID: Guid; TaskTitle: Text[150]; ExternalID: Text[2048]; StartTask: Boolean): BigInteger
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.CreateTask(AgentUserSecurityID, TaskTitle, ExternalID, StartTask));
    end;

    /// <summary>
    /// Create a new task for the given agent with one message.
    /// The task will be started immediately, if it is in the state that it can be started again.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent that will handle the task.</param>
    /// <param name="TaskTitle">The title of the task. Agent will take the title into the consideration. </param>
    /// <param name="ExternalID">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <param name="From">The sender of the message. This field is a free text value, it can be an email, phone number, username, etc.</param>
    /// <param name="MessageText">The message text. Agent will use text as additional input.</param>
    /// <returns>The ID of the task that was created.</returns>
    [Scope('OnPrem')]
    procedure CreateTask(AgentSecurityID: Guid; TaskTitle: Text[150]; ExternalId: Text[2048]; From: Text[250]; MessageText: Text): BigInteger
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        NewMessageID: Guid;
    begin
        exit(AgentTaskImpl.CreateTaskWithMessage(AgentSecurityID, TaskTitle, ExternalID, From, MessageText, true, NewMessageID));
    end;

    /// <summary>
    /// Create a new task for the given agent with one message.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent that will handle the task.</param>
    /// <param name="TaskTitle">The title of the task. Agent will take the title into the consideration. </param>
    /// <param name="ExternalID">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <param name="From">The sender of the message. This field is a free text value, it can be an email, phone number, username, etc.</param>
    /// <param name="MessageText">The message text. Agent will use text as additional input.</param>
    /// <param name="StartTask">If true, the task will be started immediately. The default value is true. </param>
    /// <param name="NewMessageID">The ID of the message that was created.</param>
    /// <returns>The ID of the task that was created.</returns>
    [Scope('OnPrem')]
    procedure CreateTask(AgentSecurityID: Guid; TaskTitle: Text[150]; ExternalId: Text[2048]; From: Text[250]; MessageText: Text; StartTask: Boolean; var NewMessageID: Guid): BigInteger
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.CreateTaskWithMessage(AgentSecurityID, TaskTitle, ExternalID, From, MessageText, StartTask, NewMessageID));
    end;

    /// <summary>
    /// Add a message to the task.
    /// The task will be started immediately, if it is in the state that it can be started again.
    /// </summary>
    /// <param name="AgentTaskID">The ID of the task to which the message will be added.</param>
    /// <param name="From">The sender of the message. This field is a free text value, it can be an email, phone number, username, etc.</param> 
    /// <param name="MessageText">The message text. Agent will use text as additional input.</param>
    /// <param name="ExternalId"></param>
    /// <param name="StartTask"></param>
    /// <returns></returns>
    [Scope('OnPrem')]
    procedure AddMessage(AgentTaskID: BigInteger; From: Text[250]; MessageText: Text; ExternalId: Text[2048]): Guid
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.AddMessage(AgentTaskID, From, MessageText, ExternalId, true));
    end;

    /// <summary>
    /// Add a message to the task.
    /// </summary>
    /// <param name="AgentTaskID">The ID of the task to which the message will be added.</param>
    /// <param name="From">The sender of the message. This field is a free text value, it can be an email, phone number, username, etc.</param> 
    /// <param name="MessageText">The message text. Agent will use text as additional input.</param>
    /// <param name="ExternalId"></param>
    /// <param name="StartTask"></param>
    /// <returns></returns>
    [Scope('OnPrem')]
    procedure AddMessage(AgentTaskID: BigInteger; From: Text[250]; MessageText: Text; ExternalId: Text[2048]; StartTask: Boolean): Guid
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.AddMessage(AgentTaskID, From, MessageText, ExternalId, StartTask));
    end;

    /// <summary>
    /// Get the agent task ID related to the current session, if any, -1 otherwise.
    /// </summary>
    /// <returns>The agent task ID, if any, -1 otherwise.</returns>
    procedure GetSessionAgentTaskId(): BigInteger
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        exit(AgentTaskImpl.GetSessionAgentTaskId());
    end;
}