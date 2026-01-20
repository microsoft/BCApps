// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Feedback;

codeunit 4329 "Agent User Feedback"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentMetadataProviderTok: Label 'Copilot.Agents.AgentTypeId', Locked = true;
        AgentUserSecurityIdTok: Label 'Copilot.Agents.AgentId', Locked = true;
        AgentTaskIdTok: Label 'Copilot.Agents.TaskId', Locked = true;
        AgentTaskLogEntryIdTok: Label 'Copilot.Agents.TaskLogEntryId', Locked = true;
        AgentTaskLogEntryTypeTok: Label 'Copilot.Agents.TaskLogEntryType', Locked = true;
        AgentFeatureAreaTok: Label 'Agents', Locked = true;

    #region Property Tokens

    [Scope('OnPrem')]
    procedure GetAgentMetadataProviderTok(): Text
    begin
        exit(AgentMetadataProviderTok);
    end;

    [Scope('OnPrem')]
    procedure GetAgentUserSecurityIdTok(): Text
    begin
        exit(AgentUserSecurityIdTok);
    end;

    [Scope('OnPrem')]
    procedure GetAgentTaskIdTok(): Text
    begin
        exit(AgentTaskIdTok);
    end;

    [Scope('OnPrem')]
    procedure GetAgentTaskLogEntryIdTok(): Text
    begin
        exit(AgentTaskLogEntryIdTok);
    end;

    [Scope('OnPrem')]
    procedure GetAgentTaskLogEntryTypeTok(): Text
    begin
        exit(AgentTaskLogEntryTypeTok);
    end;

    #endregion

    [Scope('OnPrem')]
    procedure InitializeAgentContext(AgentMetadataProvider: Enum "Agent Metadata Provider"; AgentUserSecurityID: Guid) Context: Dictionary of [Text, Text]
    begin
        Context.Add(AgentMetadataProviderTok, Format(AgentMetadataProvider.AsInteger()));
        Context.Add(AgentUserSecurityIdTok, Format(AgentUserSecurityID));
    end;

    [Scope('OnPrem')]
    procedure InitializeAgentTaskContext(TaskId: BigInteger) Context: Dictionary of [Text, Text]
    var
        Agent: Record Agent;
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        if not (AgentTaskImpl.TryGetAgentRecordFromTaskId(TaskId, Agent)) then
            exit;

        Context := InitializeAgentContext(Agent."Agent Metadata Provider", Agent."User Security ID");
        Context.Add(AgentTaskIdTok, Format(TaskId));
    end;

    procedure RequestFeedback(FeatureName: Text; FeatureDisplayName: Text; ContextProperties: Dictionary of [Text, Text])
    var
        MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
        EmptyContextFiles: Dictionary of [Text, Text];
    begin
        MicrosoftUserFeedback.SetIsAIFeedback(true);
        MicrosoftUserFeedback.RequestFeedback(FeatureName, AgentFeatureAreaTok, FeatureDisplayName, EmptyContextFiles, ContextProperties);
    end;
}