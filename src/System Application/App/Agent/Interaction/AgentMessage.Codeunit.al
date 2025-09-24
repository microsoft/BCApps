// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4307 "Agent Message"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Get the message text for the given agent task message.
    /// </summary>
    /// <param name="AgentTaskMessage">Agent task message.</param>
    /// <returns>The body of the agent task message.</returns>
    [Scope('OnPrem')]
    procedure GetText(var AgentTaskMessage: Record "Agent Task Message"): Text
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        exit(AgentMessageImpl.GetText(AgentTaskMessage));
    end;

    /// <summary>
    /// Updates the message text.
    /// </summary>
    /// <param name="AgentTaskMessage">The message record to update.</param>
    /// <param name="NewMessageText">New message text to set.</param>
    [Scope('OnPrem')]
    procedure UpdateText(var AgentTaskMessage: Record "Agent Task Message"; NewMessageText: Text)
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.UpdateText(AgentTaskMessage, NewMessageText);
    end;

    /// <summary>
    /// Check if it is possible to edit the message.
    /// </summary>
    /// <param name="AgentTaskMessage">Agent task message to verify.</param>
    /// <returns>If it is possible to change the message.</returns>
    [Scope('OnPrem')]
    procedure IsEditable(var AgentTaskMessage: Record "Agent Task Message"): Boolean
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        exit(AgentMessageImpl.IsEditable(AgentTaskMessage));
    end;

    /// <summary>
    /// Sets the message status to sent.
    /// </summary>
    /// <param name="AgentTaskMessage">Agent task message to update status.</param>
    [Scope('OnPrem')]
    procedure SetStatusToSent(var AgentTaskMessage: Record "Agent Task Message")
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.SetStatusToSent(AgentTaskMessage);
    end;

    /// <summary>
    /// Add an attachment to the task message.
    /// </summary>
    /// <param name="FileName">The name of the file to be attached.</param>
    /// <param name="FileMIMEType">The MIME type of the file to be attached.</param>
    /// <param name="Attachment">The attachment stream.</param>
    [Scope('OnPrem')]
    procedure AddAttachment(var AgentTaskMessage: Record "Agent Task Message"; FileName: Text[250]; FileMIMEType: Text[100]; Attachment: InStream)
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.AddAttachment(AgentTaskMessage, FileName, FileMIMEType, Attachment);
    end;

    /// <summary>
    /// Set whether to ignore attachments for the message.
    /// When set to true, attachments will be marked as ignored and will not be processed by the agent.
    /// The default value is false.
    /// </summary>
    /// <param name="IgnoreAttachment">If true, attachments will be marked as ignored when added to a message.</param>
    [Scope('OnPrem')]
    procedure SetIgnoreAttachment(IgnoreAttachment: Boolean)
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.SetIgnoreAttachment(IgnoreAttachment);
    end;

    /// <summary>
    /// Downloads the attachments for a specific message.
    /// </summary>
    /// <param name="AgentTaskMessage">Message to download attachments for.</param>
    [Scope('OnPrem')]
    procedure DownloadAttachments(var AgentTaskMessage: Record "Agent Task Message")
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.DownloadAttachments(AgentTaskMessage);
    end;

    /// <summary>
    /// Shows the attachments for a specific message. If file is not supported to be shown, it will be downloaded.
    /// </summary>
    /// <param name="TaskID">Task ID to download attachments for.</param>
    /// <param name="FileID">File ID to download.</param>
    [Scope('OnPrem')]
    procedure ShowAttachment(TaskID: BigInteger; FileID: BigInteger)
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.ShowOrDownloadAttachment(TaskId, FileID, false);
    end;

    /// <summary>
    /// Shows the attachments for a specific message. If file is not supported to be shown, it will be downloaded.
    /// </summary>
    /// <param name="AgentTaskFile">Agent file to display.</param>
    [Scope('OnPrem')]
    procedure ShowAttachment(var AgentTaskFile: Record "Agent Task File")
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.ShowOrDownloadAttachment(AgentTaskFile, false);
    end;

    /// <summary>
    /// Loads the attachments for a specific message to the temporary buffer.
    /// </summary>  
    /// <param name="TaskID">Task ID to download attachments for.</param>
    /// <param name="MessageID">Message ID to download attachments for.</param>
    /// <param name="TempAgentTaskFile">Temporary buffer to load the attachments.</param>
    [Scope('OnPrem')]
    procedure GetAttachments(TaskID: BigInteger; MessageID: Guid; var TempAgentTaskFile: Record "Agent Task File" temporary)
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        AgentMessageImpl.GetAttachments(TaskID, MessageID, TempAgentTaskFile);
    end;

    /// <summary>
    /// Get the display text for the file size. 
    /// </summary>
    /// <param name="SizeInBytes">The size in bytes.</param>
    /// <returns>The display text for the file size.</returns>
    [Scope('OnPrem')]
    procedure GetFileSizeDisplayText(SizeInBytes: Decimal): Text
    var
        AgentMessageImpl: Codeunit "Agent Message Impl.";
    begin
        exit(AgentMessageImpl.GetFileSizeDisplayText(SizeInBytes));
    end;
}