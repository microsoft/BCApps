// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Feedback;

codeunit 8366 "MCP Config Feedback"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MCPServerFeedbackConfirmQst: Label 'We noticed you no longer have any active MCP configurations. Could you share what made you decide to stop using the MCP server? Your feedback helps us improve the experience.';
        MCPServerFeedbackQst: Label 'What could we do to improve the MCP server experience?';
        NoActiveConfigsFeedbackTxt: Label 'No active configs feedback triggered', Locked = true;
        GeneralFeedbackTxt: Label 'General MCP feedback triggered', Locked = true;

    /// <summary>
    /// Triggers feedback when there are no active MCP configurations remaining.
    /// Used for both deactivation and deletion scenarios.
    /// </summary>
    procedure TriggerNoActiveConfigsFeedback()
    var
        ConfirmMgt: Codeunit "Confirm Management";
        Feedback: Codeunit "Microsoft User Feedback";
    begin
        if not ConfirmMgt.GetResponse(MCPServerFeedbackConfirmQst) then
            exit;

        Feedback.WithCustomQuestion(MCPServerFeedbackQst, MCPServerFeedbackQst).WithCustomQuestionType(Enum::FeedbackQuestionType::Text);
        Feedback.RequestDislikeFeedback('MCP Server Configuration', 'MCPConfig', 'MCP Server Configuration');

        Session.LogMessage('0000RSA', NoActiveConfigsFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
    end;

    /// <summary>
    /// Triggers general feedback for the MCP server configuration feature.
    /// Used for the Give Feedback action.
    /// </summary>
    procedure TriggerGeneralFeedback()
    var
        Feedback: Codeunit "Microsoft User Feedback";
    begin
        Feedback.RequestFeedback('MCP Server Configuration', 'MCPConfig', 'MCP Server Configuration');

        Session.LogMessage('0000RSB', GeneralFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
    end;

    /// <summary>
    /// Checks if there are no active MCP configurations.
    /// </summary>
    /// <returns>True if there are no active MCP configurations.</returns>
    procedure HasNoActiveConfigurations(): Boolean
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        MCPConfiguration.SetRange(Active, true);
        exit(MCPConfiguration.IsEmpty());
    end;
}
