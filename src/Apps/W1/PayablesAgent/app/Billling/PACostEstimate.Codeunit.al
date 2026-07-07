// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

codeunit 3319 "PA Cost Estimate"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task Consumption" = r;

    /// <summary>
    /// Computes the total number of Copilot credits consumed by the
    /// current company's Payables Agent.
    /// </summary>
    /// <returns>Total Copilot credits consumed. Zero when nothing has been consumed yet.</returns>
    procedure GetCreditsConsumed(): Decimal
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        PayablesAgentSetup.GetSetup();
        exit(GetCreditsConsumed(PayablesAgentSetup."User Security Id"));
    end;

    /// <summary>
    /// Computes the total number of Copilot credits consumed by a specific agent user.
    /// </summary>
    procedure GetCreditsConsumed(AgentUserSecurityId: Guid): Decimal
    var
        AgentTaskConsumption: Record "Agent Task Consumption";
    begin
        if IsNullGuid(AgentUserSecurityId) then
            exit(0);

        AgentTaskConsumption.SetRange("Agent User Security ID", AgentUserSecurityId);
        AgentTaskConsumption.CalcSums("Copilot Credits");
        exit(AgentTaskConsumption."Copilot Credits");
    end;

    /// <summary>
    /// Formats a number of Copilot credits as "X credits consumed", rounding to whole
    /// credits and using thousand separators (e.g. "123,455 credits consumed").
    /// </summary>
    procedure FormatCreditsConsumed(Credits: Decimal): Text
    begin
        exit(StrSubstNo(CreditsConsumedLbl, Format(Round(Credits, 1), 0, '<Integer Thousand>')));
    end;

    /// <summary>
    /// Returns the URL of the Learn page that explains consumption-based billing for the agent.
    /// </summary>
    procedure GetLearnMoreUrl(): Text
    begin
        exit(LearnMoreCostUrlTxt);
    end;

    var
        CreditsConsumedLbl: Label '%1 credits consumed', Comment = '%1 is the number of Copilot credits consumed, formatted with thousand separators, e.g. "123,455".';
        LearnMoreCostUrlTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=2366503', Locked = true;
}
