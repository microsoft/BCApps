// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Feedback;

codeunit 4329 "Agent User Feedback"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentMetadataProviderTok: Label 'Copilot.Agents.AgentTypeId', Locked = true;
        AgentUserSecurityIdTok: Label 'Copilot.Agents.AgentId', Locked = true;
        AgentTaskIdTok: Label 'Copilot.Agents.TaskId', Locked = true;
        AgentTaskLogEntryIdTok: Label 'Copilot.Agents.TaskLogEntryId', Locked = true;
        AgentTaskLogEntryTypeTok: Label 'Copilot.Agents.TaskLogEntryType', Locked = true;
        CopilotThumbsUpFeedbackTok: Label 'Copilot.ThumbsUp', Locked = true;
        CopilotThumbsDownFeedbackTok: Label 'Copilot.ThumbsDown', Locked = true;
        AgentFeatureNameTok: Label 'Agents', Locked = true;
        AgentFeatureAreaTok: Label 'Agents', Locked = true;
        AgentFeatureAreaDisplayNameLbl: Label 'Agents';

    procedure InitializeAgentContext(AgentMetadataProvider: Enum "Agent Metadata Provider"; AgentUserSecurityID: Guid) Context: Dictionary of [Text, Text]
    begin
        Context.Add(AgentMetadataProviderTok, Format(AgentMetadataProvider.AsInteger()));
        Context.Add(AgentUserSecurityIdTok, Format(AgentUserSecurityID));
    end;

    procedure InitializeAgentTaskContext(TaskId: BigInteger) Context: Dictionary of [Text, Text]
    var
        Agent: Record Agent;
    begin
        if not (TryFindRelatedAgentToTask(TaskId, Agent)) then
            exit;

        Context := InitializeAgentContext(Agent."Agent Metadata Provider", Agent."User Security ID");
        Context.Add(AgentTaskIdTok, Format(TaskId));
    end;

    procedure InitializeAgentTaskLogEntryContext(AgentTaskLogEntry: Record "Agent Task Log Entry") Context: Dictionary of [Text, Text]
    var
        Agent: Record Agent;
    begin
        if not (TryFindRelatedAgentToTask(AgentTaskLogEntry."Task ID", Agent)) then
            exit;

        Context := InitializeAgentContext(Agent."Agent Metadata Provider", Agent."User Security ID");
        Context.Add(AgentTaskIdTok, Format(AgentTaskLogEntry."Task ID"));
        Context.Add(AgentTaskLogEntryIdTok, Format(AgentTaskLogEntry.ID));
        Context.Add(AgentTaskLogEntryTypeTok, Format(AgentTaskLogEntry.Type));
    end;

    procedure RequestFeedback(ContextProperties: Dictionary of [Text, Text])
    var
        MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
        EmptyContextFiles: Dictionary of [Text, Text];
    begin
        MicrosoftUserFeedback.SetIsAIFeedback(true);
        MicrosoftUserFeedback.RequestFeedback(AgentFeatureNameTok, AgentFeatureAreaTok, AgentFeatureAreaDisplayNameLbl, EmptyContextFiles, ContextProperties);
    end;

    #region Property Tokens

    procedure GetAgentMetadataProviderTok(): Text
    begin
        exit(AgentMetadataProviderTok);
    end;

    procedure GetAgentUserSecurityIdTok(): Text
    begin
        exit(AgentUserSecurityIdTok);
    end;

    procedure GetAgentTaskIdTok(): Text
    begin
        exit(AgentTaskIdTok);
    end;

    procedure GetAgentTaskLogEntryIdTok(): Text
    begin
        exit(AgentTaskLogEntryIdTok);
    end;

    procedure GetAgentTaskLogEntryTypeTok(): Text
    begin
        exit(AgentTaskLogEntryTypeTok);
    end;

    procedure GetCopilotThumbsUpFeedbackTok(): Text
    begin
        exit(CopilotThumbsUpFeedbackTok);
    end;

    procedure GetCopilotThumbsDownFeedbackTok(): Text
    begin
        exit(CopilotThumbsDownFeedbackTok);
    end;

    #endregion

    procedure IsAgentTaskFeedback(Context: Dictionary of [Text, Text]): Boolean
    begin
        exit(Context.ContainsKey(AgentMetadataProviderTok)
            and Context.ContainsKey(AgentUserSecurityIdTok)
            and Context.ContainsKey(AgentTaskIdTok));
    end;

    procedure IsAgentTaskMetadataProvider(AgentMetadataProvider: Enum "Agent Metadata Provider"; Context: Dictionary of [Text, Text]): Boolean
    begin
        if not Context.ContainsKey(AgentMetadataProviderTok) then
            exit(false);

        exit(Context.Get(AgentMetadataProviderTok) = Format(AgentMetadataProvider.AsInteger()));
    end;

    local procedure TryFindRelatedAgentToTask(TaskId: Integer; var Agent: Record Agent): Boolean
    var
        Tasks: Record "Agent Task";
    begin
        if not Tasks.Get(TaskId) then
            exit(false);

        if not Agent.Get(Tasks."Agent User Security ID") then
            exit(false);

        exit(true);
    end;
}