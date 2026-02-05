// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;
using System.Environment.Configuration;

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
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentSetupImpl.GetSetupRecord(AgentSetupBuffer, UserSecurityID, AgentMetadataProvider, DefaultUserName, DefaultDisplayName, AgentSummary);
    end;

    /// <summary>
    /// Saves changes done. If the agent does not exist we will create a new agent otherwise we will update the agent.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>Agent User ID of the created or updated agent.</returns>
    procedure SaveChanges(var AgentSetupBuffer: Record "Agent Setup Buffer") "Agent User ID": Guid
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.SaveChanges(AgentSetupBuffer));
    end;

    /// <summary>
    /// Checks if there are any changes made in the setup buffer that need to be saved. 
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>True if there are changes made, false otherwise.</returns>
    procedure GetChangesMade(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.GetChangesMade(AgentSetupBuffer));
    end;

    /// <summary>
    /// Opens a page where the language and region settings for the agent can be updated.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>True if the language and region settings were updated, false otherwise.</returns>
    procedure OpenLanguageAndRegionPage(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.OpenLanguageAndRegionPage(AgentSetupBuffer));
    end;

    /// <summary>
    /// Retrieves the summary information about the agent.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>Summary information about the agent.</returns>
    procedure GetAgentSummary(var AgentSetupBuffer: Record "Agent Setup Buffer"): Text
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.GetAgentSummary(AgentSetupBuffer));
    end;

    /// <summary>
    /// Opens a page where the user access control settings for the agent can be updated.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>True if the user access control settings were updated, false otherwise.</returns>
    procedure OpenAgentAccessControlPage(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.OpenAgentAccessControlSetup(AgentSetupBuffer));
    end;

    /// <summary>
    /// Allows the user to select a profile out of the list of available profiles.
    /// The user settings record will be updated with the selected profile.
    /// </summary>
    /// <param name="UserSettingsRec">User settings to update with the new profile</param>
    procedure OpenProfileLookup(var UserSettingsRec: Record "User Settings"): Boolean
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.OpenProfileLookup(UserSettingsRec));
    end;

    /// <summary>
    /// Allows the user to select an agent out of the list of enabled agents.
    /// </summary>
    /// <returns>The security ID of the selected agent or the empty guid if none selected.</returns>
    procedure OpenAgentLookup(var AgentUserSecurityId: Guid): Boolean
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.OpenAgentLookup(AgentUserSecurityId));
    end;

    /// <summary>
    /// Allows the user to select an agent out of the list of enabled agents.
    /// </summary>
    /// <param name="AgentType">The type of agent to filter the lookup on.</param>
    /// <returns>The security ID of the selected agent or the empty guid if none selected.</returns>
    procedure OpenAgentLookup(AgentType: Enum "Agent Metadata Provider"; var AgentUserSecurityId: Guid): Boolean
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.OpenAgentLookup(AgentType, AgentUserSecurityId));
    end;

    /// <summary>
    /// Opens the setup page for the agent.
    /// </summary>
    /// <param name="AgentSetupBuffer">A record that should point to the agent.</param>
    procedure OpenSetupPage(var AgentSetupBuffer: Record "Agent Setup Buffer")
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentSetupImpl.OpenSetupPage(AgentSetupBuffer."User Security ID");
    end;

    /// <summary>
    /// Opens the setup page for the agent.
    /// </summary>
    /// <param name="AgentUserSecurityId">The user security ID of the agent.</param>
    procedure OpenSetupPage(AgentUserSecurityId: Guid)
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentSetupImpl.OpenSetupPage(AgentUserSecurityId);
    end;

    /// <summary>
    /// Opens the page where the user access control settings for the agent can be updated.
    /// </summary>
    /// <param name="AgentSetupBuffer"><see cref="AgentSetupBuffer"/> that contains the setup data.</param>
    /// <returns>True if the user access control settings were updated, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure UpdateUserAccessControl(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentSetupImpl.OpenAgentAccessControlSetup(AgentSetupBuffer));
    end;

    var
        AgentSetupImpl: Codeunit "Agent Setup Impl.";
        FeatureAccessManagement: Codeunit "Feature Access Management";
}