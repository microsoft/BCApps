// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Agents;

/// <summary>
/// Implements IAgentTaskExecution for the Shopify Tax Matching Agent.
/// Provides user intervention suggestions and task message analysis.
/// </summary>
codeunit 30471 "Shpfy Tax Agent Task Exec." implements IAgentTaskExecution
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetAgentTaskUserInterventionSuggestions(AgentTaskUserInterventionRequestDetails: Record "Agent User Int Request Details"; var AgentTaskUserInterventionSuggestion: Record "Agent Task User Int Suggestion")
    begin
        Clear(AgentTaskUserInterventionSuggestion);

        AgentTaskUserInterventionSuggestion.Summary := CreateTaxJurisdictionSuggestionLbl;
        AgentTaskUserInterventionSuggestion.Description := CreateTaxJurisdictionDescLbl;
        AgentTaskUserInterventionSuggestion.Instructions := CreateTaxJurisdictionInstrLbl;
        AgentTaskUserInterventionSuggestion.Insert();

        AgentTaskUserInterventionSuggestion.Summary := AssignTaxAreaSuggestionLbl;
        AgentTaskUserInterventionSuggestion.Description := AssignTaxAreaDescLbl;
        AgentTaskUserInterventionSuggestion.Instructions := AssignTaxAreaInstrLbl;
        AgentTaskUserInterventionSuggestion.Insert();
    end;

    procedure GetAgentTaskPageContext(AgentTaskPageContextReq: Record "Agent Task Page Context Req."; var AgentTaskPageContext: Record "Agent Task Page Context")
    begin
        Clear(AgentTaskPageContext);
        AgentTaskPageContext.Insert();
    end;

    procedure AnalyzeAgentTaskMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    begin
        Clear(Annotations);
    end;

    var
        CreateTaxJurisdictionSuggestionLbl: Label 'Create Tax Jurisdiction';
        CreateTaxJurisdictionDescLbl: Label 'Show when the agent cannot find a matching Tax Jurisdiction for a Shopify tax line.', Locked = true;
        CreateTaxJurisdictionInstrLbl: Label 'Create the missing Tax Jurisdiction in Business Central and then confirm so the agent can continue matching.', Locked = true;
        AssignTaxAreaSuggestionLbl: Label 'Assign Tax Area';
        AssignTaxAreaDescLbl: Label 'Show when the agent cannot find or create a Tax Area for the matched jurisdictions.', Locked = true;
        AssignTaxAreaInstrLbl: Label 'Create or identify the correct Tax Area containing the required Tax Jurisdictions, then confirm.', Locked = true;
}
