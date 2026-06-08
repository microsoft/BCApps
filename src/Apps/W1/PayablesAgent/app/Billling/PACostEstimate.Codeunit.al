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
    Permissions = tabledata "Agent Task" = r,
                  tabledata "Agent Task Consumption" = r;

    /// <summary>
    /// Computes the estimated cost per processed invoice in US dollars for the
    /// current company's Payables Agent.
    /// </summary>
    /// <param name="InvoiceCount">Out: number of completed agent tasks (documents the agent has processed).</param>
    /// <returns>Estimated cost per invoice in USD. Zero when no invoices have been processed yet.</returns>
    procedure GetCostEstimatePerInvoiceUSD(var InvoiceCount: Integer): Decimal
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        PayablesAgentSetup.GetSetup();
        exit(GetCostEstimatePerInvoiceUSD(PayablesAgentSetup."User Security Id", InvoiceCount));
    end;

    /// <summary>
    /// Computes the estimated cost per processed invoice in US dollars for a specific agent user.
    /// Average = (total Copilot credits consumed * $0.01) / number of completed agent tasks.
    /// </summary>
    procedure GetCostEstimatePerInvoiceUSD(AgentUserSecurityId: Guid; var InvoiceCount: Integer): Decimal
    var
        AgentTask: Record "Agent Task";
        AgentTaskConsumption: Record "Agent Task Consumption";
        CreditsConsumed: Decimal;
    begin
        InvoiceCount := 0;
        if IsNullGuid(AgentUserSecurityId) then
            exit(0);

        AgentTask.SetRange("Agent User Security ID", AgentUserSecurityId);
        InvoiceCount := AgentTask.Count();
        if InvoiceCount = 0 then
            exit(0);

        AgentTaskConsumption.SetRange("Agent User Security ID", AgentUserSecurityId);
        AgentTaskConsumption.CalcSums("Copilot Credits");
        CreditsConsumed := AgentTaskConsumption."Copilot Credits";

        exit((CreditsConsumed * CreditToUsdRate()) / InvoiceCount);
    end;

    /// <summary>
    /// Formats a USD amount as "$X.XX" using invariant culture so all
    /// localizations render the same dollar value.
    /// </summary>
    procedure FormatCostPerInvoiceUSD(CostUSD: Decimal): Text
    begin
        exit(StrSubstNo(CostPerInvoiceLbl, Format(CostUSD, 0, '<Precision,2:2><Standard Format,9>')));
    end;

    /// <summary>
    /// Returns the URL of the Learn page that explains consumption-based billing for the agent.
    /// </summary>
    procedure GetLearnMoreUrl(): Text
    begin
        exit(LearnMoreCostUrlTxt);
    end;

    local procedure CreditToUsdRate(): Decimal
    begin
        // One Copilot credit is billed at $0.01 USD.
        exit(0.01);
    end;

    var
        CostPerInvoiceLbl: Label '$%1 per invoice', Comment = '%1 is the USD amount formatted as e.g. "0.80". The dollar sign is intentional and not localized.';
        LearnMoreCostUrlTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=2366503', Locked = true;
}
