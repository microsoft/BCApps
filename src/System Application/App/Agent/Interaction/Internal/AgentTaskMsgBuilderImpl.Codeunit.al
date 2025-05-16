// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

/// <summary>
/// This codeunit is used to create an agent task message.
/// </summary>
codeunit 4311 "Agent Task Msg. Builder Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempAgentTaskFileToAttach: Record "Agent Task File" temporary;
        GlobalAgentTask: Record "Agent Task";
        GlobalAgentTaskMessage: Record "Agent Task Message";
        GlobalFrom: Text[250];
        GlobalMessageExternalID: Text[2048];
        GlobalMessageText: Text;
        GlobalRequiresReview: Boolean;
        GlobalAgentTaskStartAgentTask: Boolean;

    /// <summary>
    /// Check if a task exists for the given agent user and conversation
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="ConversationId">The conversation ID to check.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure Initialize(From: Text[250]; MessageText: Text): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalFrom := From;
        GlobalMessageText := MessageText;
        GlobalRequiresReview := true;
        exit(this);
    end;

    /// <summary>
    /// Set the external ID of the task.    
    /// </summary>
    /// <param name="RequiresReview">Specifies if the user needs to review and approve message before agent starts processing the task. The default value is true.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetRequiresReview(RequiresReview: Boolean): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalRequiresReview := RequiresReview;
        exit(this);
    end;

    /// <summary>
    /// Set the external ID of the task.
    /// </summary>
    /// <param name="ExternalId">The external ID of the task. This field is used to connect to external systems, like Message ID for emails.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetMessageExternalID(ExternalId: Text[2048]): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalMessageExternalID := ExternalId;
        exit(this);
    end;

    /// <summary>
    /// Set the message text of the task.
    /// </summary>
    /// <param name="ParentAgentTask">The agent task to set the message text to.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTask: Record "Agent Task"): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalAgentTask.Copy(ParentAgentTask);
    end;

    /// <summary>
    /// Sets if the task should be started after the message is created. 
    /// Default value is true.
    /// </summary>
    /// <param name="StartAgentTask">If the task should be started after the message is created.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    procedure SetStartAgentTask(StartAgentTask: Boolean): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalAgentTaskStartAgentTask := StartAgentTask;
        exit(this);
    end;

    /// <summary>
    /// Set the message text of the task.
    /// </summary>
    /// <param name="ParentAgentTask">The agent task to set the message text to.</param>
    /// <returns>This instance of the Agent Task Message Builder.</returns>
    [Scope('OnPrem')]
    procedure SetAgentTask(ParentAgentTaskID: BigInteger): codeunit "Agent Task Msg. Builder Impl."
    begin
        GlobalAgentTask.Get(ParentAgentTaskID);
    end;

    /// <summary>
    /// Creates the task message.
    /// </summary>
    /// <returns>
    /// The created task message.
    /// </returns>
    [Scope('OnPrem')]
    procedure Create(): Record "Agent Task Message"
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        VerifyMandatoryFieldsSet();
        GlobalAgentTaskMessage := AgentTaskImpl.AddMessage(GlobalFrom, GlobalMessageText, GlobalMessageExternalID, GlobalAgentTask, GlobalRequiresReview);
        TempAgentTaskFileToAttach.Reset();
        if TempAgentTaskFileToAttach.FindSet() then
            repeat
                AgentMessageImpl.AddAttachment(GlobalAgentTaskMessage, TempAgentTaskFileToAttach);
            until TempAgentTaskFileToAttach.Next() = 0;

        if GlobalAgentTaskStartAgentTask then
            AgentTaskImpl.StartTaskIfPossible(GlobalAgentTask);

        exit(GlobalAgentTaskMessage);
    end;

    /// <summary>
    /// Get the agent task message.
    /// </summary>
    /// <returns>
    /// The agent task message that was created.
    /// </returns>
    procedure GetAgentTaskMessage(): Record "Agent Task Message"
    begin
        exit(GlobalAgentTaskMessage);
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
    procedure AddAttachment(FileName: Text[250]; FileMIMEType: Text[100]; InStream: InStream): codeunit "Agent Task Msg. Builder Impl."
    var
        FileOutStream: OutStream;
    begin
        Clear(TempAgentTaskFileToAttach);
        TempAgentTaskFileToAttach."File Name" := FileName;
        TempAgentTaskFileToAttach."File MIME Type" := FileMIMEType;
        TempAgentTaskFileToAttach.Insert();
        CopyStream(FileOutStream, InStream);
        TempAgentTaskFileToAttach.Content.CreateOutStream(FileOutStream);
        TempAgentTaskFileToAttach.Modify();
        exit(this);
    end;

    local procedure VerifyMandatoryFieldsSet()
    var
        GlobalFromIsMandatoryErr: Label 'The From field is mandatory. Please set it before creating the task message.';
        GlobalMessageTextIsMandatoryErr: Label 'The Message Text field is mandatory. Please set it before creating the task message.';
        GlobalAgentTaskIDErr: Label 'The Agent Task ID field is mandatory. Please set it before creating the task message.';
        CodingErrorInfo: ErrorInfo;
    begin
        if GlobalFrom = '' then
            CodingErrorInfo.Message(GlobalFromIsMandatoryErr);

        if GlobalMessageText = '' then
            CodingErrorInfo.Message(GlobalMessageTextIsMandatoryErr);

        if GlobalAgentTask.ID = 0 then
            CodingErrorInfo.Message(GlobalAgentTaskIDErr);

        if CodingErrorInfo.Message = '' then
            exit;

        CodingErrorInfo.ErrorType := ErrorType::Internal;
        Error(CodingErrorInfo);
    end;
}