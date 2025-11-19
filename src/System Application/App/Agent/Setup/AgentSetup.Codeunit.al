// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

/// <summary>
/// Used for setting up new agents and configuring existing agents.
/// </summary>
codeunit 4324 "Agent Setup"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Gets the setup record for existing agents or initializes a new setup record for new agents.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <param name="UserSecurityID">Agent User Security ID, should be null for new agents</param>
    /// <param name="AgentMetadataProvider">Type of the agent that is being initialized</param>
    /// <param name="DefaultUserName">Default user name for new agents</param>
    /// <param name="DefaultDisplayName">Default display name for new agents</param>
    /// <param name="AgentSummary">Summary information about the agent</param>
    procedure GetSetupRecord(var AgentSetupBuffer: Record "Agent Setup Buffer"; UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80]; AgentSummary: Text)
    begin
        AgentSetupImpl.GetSetupRecord(AgentSetupBuffer, UserSecurityID, AgentMetadataProvider, DefaultUserName, DefaultDisplayName, AgentSummary);
    end;

    /// <summary>
    /// Saves changes done. If the agent does not exist we will create a new agent otherwise we will update the agent.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>Agent User ID of the created or updated agent.</returns>
    procedure SaveChanges(var AgentSetupBuffer: Record "Agent Setup Buffer") "Agent User ID": Guid
    begin
        exit(AgentSetupImpl.SaveChanges(AgentSetupBuffer));
    end;

    /// <summary>
    /// Checks if there are any changes made in the setup buffer that need to be saved. 
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>True if there are changes made, false otherwise.</returns>
    procedure GetChangesMade(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        exit(AgentSetupBuffer."Values Updated" or AgentSetupBuffer."State Updated" or AgentSetupBuffer."Access Updated");
    end;

    /// <summary>
    /// Updates the language and region settings for the agent.
    /// This action is automatically done by the <see cref="SaveChanges"/> method. You may call this method to update the settings separately.
    /// </summary>
    /// <param name="AgentSetupBuffer"></param>
    /// <returns></returns>
    [Scope('OnPrem')]
    procedure SetupLanguageAndRegion(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        exit(AgentSetupImpl.SetupLanguageAndRegion(AgentSetupBuffer));
    end;

    /// <summary>
    /// Retrieves the summary information about the agent.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>Summary information about the agent.</returns>
    [Scope('OnPrem')]
    procedure GetAgentSummary(var AgentSetupBuffer: Record "Agent Setup Buffer"): Text
    begin
        exit(AgentSetupImpl.GetAgentSummary(AgentSetupBuffer));
    end;

    /// <summary>
    /// Updates the user access control settings for the agent.
    /// This action is automatically done by the <see cref="SaveChanges"/> method. You may call this method to update the settings separately.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>True if the user access control settings were updated, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure UpdateUserAccessControl(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        exit(AgentSetupImpl.UpdateUserAccessControl(AgentSetupBuffer));
    end;

    var
        AgentSetupImpl: Codeunit "Agent Setup Impl.";
}