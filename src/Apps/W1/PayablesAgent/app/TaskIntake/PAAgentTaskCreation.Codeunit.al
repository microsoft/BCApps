// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

/// <summary>
/// Hands work to the Payables Agent by creating an Agent-framework task. Version agnostic: used by the v2 intake
/// ("PA Task Mgt.".StartAgentTask) and by the v1 e-document pipeline ("PA Draft Based Events"). The caller decides what the task is
/// about (title, sender, message, external id and whether it needs review); this codeunit applies what every agent
/// task needs (the agent, the trial and the billing context).
/// </summary>
codeunit 3326 "PA Agent Task Creation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Gets the Payables Agent if it exists and is not disabled.
    /// </summary>
    internal procedure GetActiveAgent(var Agent: Record Agent): Boolean
    var
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
    begin
        if not PayablesAgentSetup.GetAgent(Agent) then
            exit(false);
        exit(Agent.State <> Agent.State::Disabled);
    end;

    /// <summary>
    /// Creates an agent task for the agent with a single message. While the trial is active the trial invoice count is
    /// incremented and the task is excluded from billing.
    /// </summary>
    /// <returns>The created agent task.</returns>
    internal procedure Create(Agent: Record Agent; Title: Text[150]; From: Text[250]; MessageText: Text; ExternalId: Text[2048]; RequiresReview: Boolean): Record "Agent Task"
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        PATrial: Codeunit "PA Trial";
        TelemetryDictionary: Dictionary of [Text, Text];
        ExcludeBilling: Boolean;
        TrialModeTok: Label 'Agent Task created in trial mode. Skipping billing for invoice.', Locked = true;
    begin
        ExcludeBilling := false;
        if PATrial.IsActive() then begin
            PATrial.IncrementTrialInvoiceCount();
            TelemetryDictionary := PayablesAgent.GetCustomDimensions();
            TelemetryDictionary.Add('TrialInvoiceCount', Format(PATrial.GetTrialInvoiceCount(), 0, 9));
            TelemetryDictionary.Add('TrialInvoiceLimit', Format(PATrial.GetTrialInvoiceLimit(), 0, 9));
            TelemetryDictionary.Add('ExcludeBilling', Format(ExcludeBilling, 0, 9));
            Session.LogMessage('0000SEE', TrialModeTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDictionary);
            ExcludeBilling := true;
        end;

        AgentTaskMessageBuilder
            .Initialize(From, MessageText)
            .SetRequiresReview(RequiresReview)
            .SetMessageExternalID(ExternalId);

        exit(
            AgentTaskBuilder
                .Initialize(Agent."User Security ID", Title)
                .SetExternalId(ExternalId)
                .AddTaskMessage(AgentTaskMessageBuilder)
                .SetBillingContext(ExcludeBilling ? Enum::"Agent Task Billing Context"::Excluded : Enum::"Agent Task Billing Context"::Default)
                .Create());
    end;
}
