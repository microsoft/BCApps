// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

/// <summary>
/// This codeunit is used to create an agent task message.
/// </summary>
codeunit 4316 "Agent Task Message Builder"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentTaskMsgBuilderImpl: Codeunit "Agent Task Msg. Builder Impl.";

    /// <summary>
    /// Initialize the agent task message builder with the mandatory parameter.
    /// From value will be set to the current user.
    /// </summary>
    /// <param name="MessageText">The text of the message.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure Initialize(MessageText: Text): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.Initialize(MessageText);
        exit(this);
    end;

    /// <summary>
    /// Initialize the agent task message builder with the mandatory parameters.
    /// </summary>
    /// <param name="From">Text indicating the sender of the message.</param>
    /// <param name="MessageText">The text of the message.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure Initialize(From: Text[250]; MessageText: Text): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.Initialize(From, MessageText);
        exit(this);
    end;

    /// <summary>
    /// Set the external ID of the task.    
    /// </summary>
    /// <param name="RequiresReview">Specifies if the user needs to review and approve message before agent starts processing the task. The default value is true.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetRequiresReview(RequiresReview: Boolean): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetRequiresReview(RequiresReview);
        exit(this);
    end;

    /// <summary>
    /// Set the external ID of the task.
    /// </summary>
    /// <param name="ExternalId">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetMessageExternalID(ExternalId: Text[2048]): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetMessageExternalID(ExternalId);
        exit(this);
    end;

    /// <summary>
    /// Set the agent task for which to create the message.
    /// </summary>
    /// <param name="ParentAgentTask">The agent task to set the message to.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTask: Record "Agent Task"): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetAgentTask(ParentAgentTask);
        exit(this);
    end;

    /// <summary>
    /// Set the agent task for which to create the message.
    /// </summary>
    /// <param name="ParentAgentTaskID">The ID of the agent task to set the message to.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTaskID: BigInteger): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.SetAgentTask(ParentAgentTaskID);
        exit(this);
    end;

    /// <summary>
    /// Creates the task message.
    /// Task will be marked as ready and be picked up for processing after message is created.
    /// </summary>
    /// <returns>
    /// The created task message.
    /// </returns>
    /// <remarks>
    /// The builder keeps the state, do not reuse the same instance of the builder to create multiple tasks. 
    /// </remarks>
    [Scope('OnPrem')]
    procedure Create(): Record "Agent Task Message"
    begin
        exit(AgentTaskMsgBuilderImpl.Create());
    end;

    /// <summary>
    /// Creates the task message.
    /// </summary>
    /// <param name="SetTaskStatusToReady">Specifies if the task should be marked as ready for processing after the message is created.
    /// If set to false, the task will not be marked as ready and will not be picked up for processing. 
    /// </param>
    /// <returns>
    /// The created task message.
    /// </returns>
    /// <remarks>
    /// The builder keeps the state, do not reuse the same instance of the builder to create multiple tasks. 
    /// </remarks>
    [Scope('OnPrem')]
    procedure Create(SetTaskStatusToReady: Boolean): Record "Agent Task Message"
    begin
        exit(AgentTaskMsgBuilderImpl.Create(SetTaskStatusToReady));
    end;

    /// <summary>
    /// Get the agent task message record.
    /// </summary>
    /// <returns>
    /// The agent task message that was created.
    /// </returns>
    [Scope('OnPrem')]
    procedure GetAgentTaskMessage(): Record "Agent Task Message"
    begin
        exit(AgentTaskMsgBuilderImpl.GetAgentTaskMessage());
    end;

    /// <summary>
    /// Attach a file to the task message.
    /// The file will be attached when the message is created.
    /// It is possible to attach multiple files to the message.
    /// </summary>
    /// <param name="FileName">The name of the file to attach.</param>
    /// <param name="FileMIMEType">The MIME type of the file to attach.</param>
    /// <param name="InStream">The stream of the file to attach.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure AddAttachment(FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.AddAttachment(FileName, FileMIMEType, InStream);
        exit(this);
    end;

    /// <summary>
    /// Attach a file to the task message.
    /// The file will be attached when the message is created.
    /// It is possible to attach multiple files to the message.
    /// </summary>
    /// <param name="AgentTaskFile">The file to attach.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure AddAttachment(AgentTaskFile: Record "Agent Task File"): codeunit "Agent Task Message Builder"
    begin
        AgentTaskMsgBuilderImpl.AddAttachment(AgentTaskFile);
        exit(this);
    end;

    /// <summary>
    /// Uploads a file to the task message.
    /// The file will be attached when the message is created.
    /// It is possible to attach multiple files to the message.
    /// </summary>
    /// <returns>True if the attachment was uploaded, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure UploadAttachment(): Boolean
    begin
        exit(AgentTaskMsgBuilderImpl.UploadAttachment());
    end;

    /// <summary>
    /// Get the last attachment that was added to the task message.
    /// </summary>
    /// <returns>
    /// The last attachment that was added to the task message.
    /// </returns>
    [Scope('OnPrem')]
    procedure GetLastAttachment(): Record "Agent Task File"
    begin
        exit(AgentTaskMsgBuilderImpl.GetLastAttachment());
    end;
}