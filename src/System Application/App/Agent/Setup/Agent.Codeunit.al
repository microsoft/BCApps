// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.AccessControl;

codeunit 4321 Agent
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Creates a new agent.
    /// The agent will be in the disabled state, with the users that can interact with the agent setup.
    /// </summary>
    /// <param name="AgentMetadataProvider">The metadata provider of the agent.</param>
    /// <param name="UserName">User name for the agent.</param>
    /// <param name="UserDisplayName">Display name for the agent.</param>
    /// <param name="Instructions">Instructions for the agent that will be used to complete the tasks.</param>
    /// <param name="TempAgentAccessControl">The list of users that can configure or interact with the agent.</param>
    /// <returns>The ID of the agent.</returns>
#pragma warning disable AS0026
    procedure Create(AgentMetadataProvider: Enum "Agent Metadata Provider"; var UserName: Code[50]; UserDisplayName: Text[80]; var TempAgentAccessControl: Record "Agent Access Control" temporary): Guid
#pragma warning restore AS0026
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentImpl.CreateAgent(AgentMetadataProvider, UserName, UserDisplayName, TempAgentAccessControl));
    end;

    /// <summary>
    /// Activates the agent
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    procedure Activate(AgentUserSecurityID: Guid)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.Activate(AgentUserSecurityID);
    end;

    /// <summary>
    /// Deactivates the agent
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    procedure Deactivate(AgentUserSecurityID: Guid)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.Deactivate(AgentUserSecurityID);
    end;

    /// <summary>
    /// Get the display name of the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    procedure GetDisplayName(AgentUserSecurityID: Guid): Text[80]
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentImpl.GetDisplayName(AgentUserSecurityID));
    end;

    /// <summary>
    /// Get the user name of the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    procedure GetUserName(AgentUserSecurityID: Guid): Code[50]
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentImpl.GetUserName(AgentUserSecurityID));
    end;

    /// <summary>
    /// Sets the display name of the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="DisplayName">The display name of the agent.</param>
    procedure SetDisplayName(AgentUserSecurityID: Guid; DisplayName: Text[80])
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.SetDisplayName(AgentUserSecurityID, DisplayName);
    end;

    /// <summary>
    /// Set the instructions which agent will use to complete the tasks.
    /// </summary>
    /// <param name="Agent">The agent which instructions will be set.</param>
    /// <param name="Instructions">Instructions for the agent that will be used to complete the tasks.</param>
    procedure SetInstructions(AgentUserSecurityID: Guid; Instructions: SecretText)
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentUtilities.SetInstructions(AgentUserSecurityID, Instructions);
    end;

    /// <summary>
    /// Checks if the agent is active.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <returns>If the agent is active.</returns>
    procedure IsActive(AgentUserSecurityID: Guid): Boolean
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        exit(AgentImpl.IsActive(AgentUserSecurityID));
    end;

    /// <summary>
    /// Populates the temporary profile record with the specified information.
    /// </summary>
    /// <param name="ProfileID">The profile ID.</param>
    /// <param name="ProfileAppID">The profile App ID.</param>
    /// <param name="TempAllProfile">The profile record.</param>
    procedure PopulateDefaultProfile(ProfileID: Text[30]; ProfileAppID: Guid; var TempAllProfile: Record "All Profile" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.PopulateProfileTempRecord(ProfileID, ProfileAppID, TempAllProfile);
    end;


    /// <summary>
    /// Assigns the profile to the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="ProfileID">The profile ID.</param>
    /// <param name="ProfileAppID">The profile App ID.</param>
    procedure SetProfile(AgentUserSecurityID: Guid; ProfileID: Text; ProfileAppID: Guid)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.SetProfile(AgentUserSecurityID, ProfileID, ProfileAppID);
    end;

    /// <summary>
    /// Updates the Language, Regional Settings and Time Zone for the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="LanguageID">The language ID to set.</param>
    /// <param name="LocaleID">The locale ID to set.</param>
    /// <param name="TimeZone">The time zone to set.</param>
    procedure UpdateLocalizationSettings(AgentUserSecurityID: Guid; LanguageID: Integer; LocaleID: Integer; TimeZone: Text[180])
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.UpdateLocalizationSettings(AgentUserSecurityID, LanguageID, LocaleID, TimeZone);
    end;

    /// <summary>
    /// Gets the user settings for the agent. Few properties are retrieved, like: Profile, Language, Regional Settings and Time Zone.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="UserSettingsRec">The user settings for the agent. If agent is not created yet, it will use the current user settings</param>
    procedure GetUserSettings(AgentUserSecurityID: Guid; var UserSettingsRec: Record "User Settings")
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.GetUserSettings(AgentUserSecurityID, UserSettingsRec);
    end;

    /// <summary>
    /// Assigns one or multiple permission sets to the agent. The assignment overrides any existing permission sets.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="TempAccessControlBuffer">The access controls to assign</param>
    /// <remarks>The values need to be inserted to the temporary record. If none are inserted, all permissions will be removed from the agent.</remarks>
    procedure UpdateAccessControl(AgentUserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.AssignPermissionSets(AgentUserSecurityID, TempAccessControlBuffer);
    end;

    /// <summary>
    /// Gets the permission sets assigned to the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="TempAccessControlBuffer">The access controls assigned to the agent.</param>
    procedure GetAccessControl(AgentUserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.GetPermissionSets(AgentUserSecurityID, TempAccessControlBuffer);
    end;

    /// <summary>
    /// Gets the users that can manage or give tasks to the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">Security ID of the agent.</param>
    /// <param name="TempAgentAccessControl">List of users that can manage or give tasks to the agent.</param>
    procedure GetAgentAccessControl(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.GetUserAccess(AgentUserSecurityID, TempAgentAccessControl);
    end;

    /// <summary>
    /// Sets the users that can manage or give tasks to the agent. Existing set of users will be replaced with a new set.
    /// </summary>
    /// <param name="AgentUserSecurityID">Security ID of the agent.</param>
    /// <param name="TempAgentAccessControl">List of users that can manage or give tasks to the agent.</param>
    procedure UpdateAgentAccessControl(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        FeatureAccessManagement.AgentTaskManagementPreviewEnabled(true);
        AgentImpl.UpdateAgentAccessControl(AgentUserSecurityID, TempAgentAccessControl);
    end;

    #region On-Prem methods

    /// <summary>
    /// Assigns the profile to the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="AllProfile">Profile to set to the agent.</param>
    [Scope('OnPrem')]
    procedure SetProfile(AgentUserSecurityID: Guid; var AllProfile: Record "All Profile")
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.SetProfile(AgentUserSecurityID, AllProfile);
    end;

    /// <summary>
    /// Allows the user to select the new profile for given User Settings for an agent.
    /// </summary>
    /// <param name="UserSettingsRec">User settings to update with the new profile</param>
    [Scope('OnPrem')]
    procedure ProfileLookup(var UserSettingsRec: Record "User Settings"): Boolean
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        exit(AgentImpl.ProfileLookup(UserSettingsRec));
    end;

    /// <summary>
    /// Updates the Language, Regional Settings and Time Zone for the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="NewUserSettings">The new user settings for the agent.</param>
    [Scope('OnPrem')]
    procedure UpdateLocalizationSettings(AgentUserSecurityID: Guid; var NewUserSettings: Record "User Settings")
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.UpdateLocalizationSettings(AgentUserSecurityID, NewUserSettings);
    end;

    /// <summary>
    /// Gets the users that can manage or give tasks to the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">Security ID of the agent.</param>
    /// <param name="TempAgentAccessControl">List of users that can manage or give tasks to the agent.</param>
    [Scope('OnPrem')]
    procedure GetUserAccess(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.GetUserAccess(AgentUserSecurityID, TempAgentAccessControl);
    end;

    /// <summary>
    /// Assigns the permission set to the agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent.</param>
    /// <param name="TempAccessControlBuffer">The access controls to assign</param>
    [Scope('OnPrem')]
    procedure AssignPermissionSet(AgentUserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.AssignPermissionSets(AgentUserSecurityID, TempAccessControlBuffer);
    end;

    /// <summary>
    /// Sets the users that can manage or give tasks to the agent. Existing set of users will be replaced with a new set.
    /// </summary>
    /// <param name="AgentUserSecurityID">Security ID of the agent.</param>
    /// <param name="TempAgentAccessControl">List of users that can manage or give tasks to the agent.</param>
    [Scope('OnPrem')]
    procedure UpdateAccess(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.UpdateAgentAccessControl(AgentUserSecurityID, TempAgentAccessControl);
    end;

    /// <summary>
    /// Opens the setup page for the specified agent.
    /// </summary>
    /// <param name="AgentMetadataProvider">The metadata provider of the agent.</param>
    /// <param name="AgentUserSecurityID">Security ID of the agent.</param>
    [Scope('OnPrem')]
    procedure OpenSetupPageId(AgentMetadataProvider: Enum "Agent Metadata Provider"; AgentUserSecurityID: Guid)
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.OpenSetupPageId(AgentMetadataProvider, AgentUserSecurityID);
    end;

    #endregion

    var
        FeatureAccessManagement: Codeunit "Feature Access Management";
}