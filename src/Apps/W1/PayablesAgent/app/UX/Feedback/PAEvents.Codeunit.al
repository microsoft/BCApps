// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Environment;

codeunit 3316 "PA Events"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", OnFeedbackEvent, '', false, false)]
    local procedure OnFeedbackEventForPayablesAgentTasks(PageId: Integer; Context: Dictionary of [Text, Text]; var Handled: Boolean)
    begin
        IsAgentTaskFeedbackContext(Context, Handled);
        if Handled then
            exit;
        IsAgentDraftPageFeedbackContext(Context, Handled);
    end;

    // TODOPAV2: Adapt OCV entry points
    local procedure IsAgentDraftPageFeedbackContext(Context: Dictionary of [Text, Text]; var Handled: Boolean)
    var
        PayablesAgentOCV: Codeunit "Payables Agent OCV";
        FeedbackType: Text;
    begin
        // Scenario: Thumbs feedback from E-Document Purchase Draft page (Infotips)
        if not (Context.ContainsKey('FormName') and Context.ContainsKey('Copilot.Feedback.Target')) then
            exit;
        if Context.Get('FormName') <> 'E-Document Purchase Draft' then
            exit;
        if Context.ContainsKey('Feedback.Type') then
            FeedbackType := Context.Get('Feedback.Type');

        Handled := PayablesAgentOCV.TriggerPayableAgentDraftThumbsFeedback(FeedbackType);
    end;

    local procedure IsAgentTaskFeedbackContext(Context: Dictionary of [Text, Text]; var Handled: Boolean)
    var
        PayablesAgentOCV: Codeunit "Payables Agent OCV";
        FeedbackType: Text;
    begin
        // Scenario: Thumbs feedback from Payables Agent Tasks pane
        if not (Context.ContainsKey('Copilot.Agents.AgentTypeId') and Context.ContainsKey('Copilot.Agents.TaskId')) then
            exit;
        if Context.Get('Copilot.Agents.AgentTypeId') <> Format(Enum::"Agent Metadata Provider"::"Payables Agent".AsInteger()) then
            exit;
        if Context.ContainsKey('Feedback.Type') then
            FeedbackType := Context.Get('Feedback.Type');

        Handled := PayablesAgentOCV.TriggerPayablesAgentTaskThumbsFeedback(FeedbackType, Context.Get('Copilot.Agents.TaskId'));
    end;


}