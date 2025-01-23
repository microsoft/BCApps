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
        exit(AgentMessageImpl.GetMessageText(AgentTaskMessage));
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
        exit(AgentMessageImpl.IsMessageEditable(AgentTaskMessage));
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
}