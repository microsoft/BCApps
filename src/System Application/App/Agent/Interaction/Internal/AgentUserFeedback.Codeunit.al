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

    // The values below align with the existing feature and context properties from the timeline.
    var
        AgentUserSecurityIdTok: Label 'Copilot.Agents.AgentId', Locked = true;
        AgentMetadataProviderTok: Label 'Copilot.Agents.AgentTypeId', Locked = true;
        AgentTaskIdTok: Label 'Copilot.Agents.TaskId', Locked = true;
        AgentFeatureAreaTok: Label 'Copilot', Locked = true;
        AgentFeatureDisplayNameTok: Label 'Copilot', Locked = true;

    // The values below are not used by the timeline.
    var
        AgentTaskLogEntryIdTok: Label 'Copilot.Agents.TaskLogEntryId', Locked = true;
        AgentTaskLogEntryTypeTok: Label 'Copilot.Agents.TaskLogEntryType', Locked = true;


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

    [Scope('OnPrem')]
    procedure RequestFeedback(FeatureName: Text; Context: Dictionary of [Text, Text])
    var
        MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
        EmptyContextFiles: Dictionary of [Text, Text];
        FeedbackType: Text;
        CopilotThumbsUpTok: Label 'Copilot.ThumbsUp', Locked = true;
        CopilotThumbsDownTok: Label 'Copilot.ThumbsDown', Locked = true;
        FeedbackTypeTok: Label 'Feedback.Type', Locked = true;
    begin
        MicrosoftUserFeedback.SetIsAIFeedback(true);

        if Context.ContainsKey(FeedbackTypeTok) then
            FeedbackType := Context.Get(FeedbackTypeTok);

        case FeedbackType of
            CopilotThumbsUpTok:
                MicrosoftUserFeedback.RequestLikeFeedback(FeatureName, AgentFeatureAreaTok, AgentFeatureDisplayNameTok, EmptyContextFiles, Context);
            CopilotThumbsDownTok:
                MicrosoftUserFeedback.RequestDislikeFeedback(FeatureName, AgentFeatureAreaTok, AgentFeatureDisplayNameTok, EmptyContextFiles, Context);
            else
                MicrosoftUserFeedback.RequestFeedback(FeatureName, AgentFeatureAreaTok, AgentFeatureDisplayNameTok, EmptyContextFiles, Context);
        end;
    end;
}