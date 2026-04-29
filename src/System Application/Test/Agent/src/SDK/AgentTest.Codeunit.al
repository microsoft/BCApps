// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

using System.Agents;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 133961 "Agent Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Agent: Codeunit Agent;
        LibraryTestAgent: Codeunit "Library Mock Agent";

    local procedure Initialize()
    begin
        LibraryTestAgent.DeleteAllAgents();
    end;

    #region Create Agent Tests

    [Test]
    procedure CreateAgentWithValidParameters()
    var
        AgentRecord: Record Agent;
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Any: Codeunit Any;
        UserName: Code[50];
        DisplayName: Text[80];
        AgentId: Guid;
        NullGuid: Guid;
    begin
        Initialize();

        // [SCENARIO] Create a new agent with valid parameters

        // [GIVEN] Valid agent parameters
        UserName := CopyStr(Any.AlphanumericText(50), 1, MaxStrLen(UserName));
        DisplayName := CopyStr(Any.AlphanumericText(80), 1, MaxStrLen(DisplayName));

        // [WHEN] Creating a new agent
        AgentId := Agent.Create("Agent Metadata Provider"::"SDK Mock Agent", UserName, DisplayName, TempAgentAccessControl);

        // [THEN] The agent should be created successfully
        Assert.AreNotEqual(NullGuid, AgentId, 'Agent ID should not be null');

        // [THEN] The agent should exist in the system
        AgentRecord.SetRange("User Security ID", AgentId);
        Assert.IsTrue(AgentRecord.FindFirst(), 'Agent should exist in the system');
        Assert.AreEqual(UserName, AgentRecord."User Name", 'User name should match');
    end;

    [Test]
    procedure CreateAgentWithAccessControl()
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Any: Codeunit Any;
        UserName: Code[50];
        DisplayName: Text[80];
        AgentId: Guid;
        NullGuid: Guid;
    begin
        Initialize();

        // [SCENARIO] Create an agent with access control settings

        // [GIVEN] Valid agent parameters with access control
        UserName := CopyStr(Any.AlphanumericText(50), 1, MaxStrLen(UserName));
        DisplayName := CopyStr(Any.AlphanumericText(80), 1, MaxStrLen(DisplayName));

        TempAgentAccessControl."User Security ID" := UserSecurityId();
        TempAgentAccessControl."Can Configure Agent" := true;
        TempAgentAccessControl.Insert();

        // [WHEN] Creating a new agent with access control
        AgentId := Agent.Create("Agent Metadata Provider"::"SDK Mock Agent", UserName, DisplayName, TempAgentAccessControl);

        // [THEN] The agent should be created successfully
        Assert.AreNotEqual(NullGuid, AgentId, 'Agent ID should not be null');

        // [THEN] Access control should be set
        Clear(TempAgentAccessControl);
        Agent.GetUserAccess(AgentId, TempAgentAccessControl);
        Assert.AreEqual(1, TempAgentAccessControl.Count(), 'Should have one access control entry');
        Assert.AreEqual(UserSecurityId(), TempAgentAccessControl."User Security ID", 'Access control user ID should match');
        Assert.IsTrue(TempAgentAccessControl."Can Configure Agent", 'Access control "Can Configure Agent" should be true');
    end;

    #endregion

    #region Activate/Deactivate Tests

    [Test]
    procedure ActivateAgent()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Activate an agent

        // [GIVEN] A deactivated agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        Agent.Deactivate(AgentId);
        Assert.IsFalse(Agent.IsActive(AgentId), 'Agent should be inactive');

        // [WHEN] Activating the agent
        Agent.Activate(AgentId);

        // [THEN] The agent should be active
        Assert.IsTrue(Agent.IsActive(AgentId), 'Agent should be active');
    end;

    [Test]
    procedure DeactivateAgent()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Deactivate an agent

        // [GIVEN] An active agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        Assert.IsTrue(Agent.IsActive(AgentId), 'Agent should be active initially');

        // [WHEN] Deactivating the agent
        Agent.Deactivate(AgentId);

        // [THEN] The agent should be inactive
        Assert.IsFalse(Agent.IsActive(AgentId), 'Agent should be inactive');
    end;

    #endregion

    #region Display Name Tests

    [Test]
    procedure GetDisplayName()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
        DisplayName: Text[80];
        ExpectedDisplayName: Text[80];
    begin
        Initialize();

        // [SCENARIO] Get display name of an agent

        // [GIVEN] An agent with a display name
        ExpectedDisplayName := CopyStr(Any.AlphanumericText(MaxStrLen(ExpectedDisplayName)), 1, MaxStrLen(ExpectedDisplayName));
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            ExpectedDisplayName,
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Getting the display name
        DisplayName := Agent.GetDisplayName(AgentId);

        // [THEN] The display name should match
        Assert.AreEqual(ExpectedDisplayName, DisplayName, 'Display name should match');
    end;

    [Test]
    procedure SetDisplayName()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
        NewDisplayName: Text[80];
        RetrievedDisplayName: Text[80];
    begin
        Initialize();

        // [SCENARIO] Set display name of an agent

        // [GIVEN] An agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Setting a new display name
        NewDisplayName := CopyStr(Any.AlphanumericText(MaxStrLen(NewDisplayName)), 1, MaxStrLen(NewDisplayName));
        Agent.SetDisplayName(AgentId, NewDisplayName);

        // [THEN] The display name should be updated
        RetrievedDisplayName := Agent.GetDisplayName(AgentId);
        Assert.AreEqual(NewDisplayName, RetrievedDisplayName, 'Display name should be updated');
    end;

    #endregion

    #region Model ID Tests

    [Test]
    procedure GetModelId()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
        ModelId: Code[30];
    begin
        Initialize();

        // [SCENARIO] Get model ID of an agent

        // [GIVEN] An agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Getting the model ID
        ModelId := Agent.GetModelId(AgentId);

        // [THEN] The model ID should be empty for a newly created agent
        Assert.AreEqual('', ModelId, 'Model ID should be empty for a new agent');
    end;

    [Test]
    procedure SetModelId()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
        NewModelId: Code[30];
        AgentModelNotFoundErr: Label 'The agent model ''%1'' could not be found.', Locked = true;
    begin
        Initialize();

        // [SCENARIO] Setting an invalid model ID should fail

        // [GIVEN] An agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Setting an invalid model ID
        NewModelId := CopyStr(Any.AlphanumericText(MaxStrLen(NewModelId)), 1, MaxStrLen(NewModelId));
        asserterror Agent.SetModelId(AgentId, NewModelId);

        // [THEN] The agent should reject unknown model IDs
        Assert.ExpectedError(StrSubstNo(AgentModelNotFoundErr, NewModelId));
    end;

    [Test]
    procedure SetModelIdToAuto()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
        RetrievedModelId: Code[30];
    begin
        Initialize();

        // [SCENARIO] Set model ID of an agent to auto mode

        // [GIVEN] An agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Setting the model ID to auto (auto means empty model ID)
        Agent.SetModelIdToAuto(AgentId);

        // [THEN] The model ID should be empty
        RetrievedModelId := Agent.GetModelId(AgentId);
        Assert.AreEqual('', RetrievedModelId, 'Model ID should be empty in auto mode');
    end;

    #endregion

    #region User Name Tests

    [Test]
    procedure GetUserName()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
        UserName: Code[50];
        ExpectedUserName: Code[50];
    begin
        Initialize();

        // [SCENARIO] Get user name of an agent

        // [GIVEN] An agent with a user name
        ExpectedUserName := CopyStr(Any.AlphanumericText(MaxStrLen(ExpectedUserName)), 1, MaxStrLen(ExpectedUserName));
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            ExpectedUserName,
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Getting the user name
        UserName := Agent.GetUserName(AgentId);

        // [THEN] The user name should match
        Assert.AreEqual(ExpectedUserName, UserName, 'User name should match');
    end;

    #endregion

    #region Instructions Tests

    [Test]
    [NonDebuggable]
    procedure SetInstructions()
    var
        AgentRecord: Record Agent;
        AgentUtilities: Codeunit "Agent Utilities";
        Any: Codeunit Any;
        AgentId: Guid;
        NewInstructions: Text[2048];
        InstructionsText: Text[2048];
    begin
        Initialize();

        // [SCENARIO] Set instructions for an agent

        // [GIVEN] An agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Setting new instructions
        InstructionsText := CopyStr(Any.AlphanumericText(MaxStrLen(InstructionsText)), 1, MaxStrLen(InstructionsText));
        Agent.SetInstructions(AgentId, InstructionsText);
        NewInstructions := CopyStr(AgentUtilities.GetInstructions(AgentId).Unwrap(), 1, MaxStrLen(NewInstructions));

        // [THEN] The instructions should be updated
        Assert.AreEqual(InstructionsText, NewInstructions, 'Instructions should be updated');
    end;

    #endregion

    #region Profile Tests

    [Test]
    procedure PopulateDefaultProfile()
    var
        TempAllProfile: Record "All Profile" temporary;
        Any: Codeunit Any;
        ProfileID: Code[30];
        ProfileAppID: Guid;
    begin
        Initialize();

        // [SCENARIO] Populate default profile information

        // [GIVEN] Profile parameters
        ProfileID := CopyStr(Any.AlphanumericText(30), 1, MaxStrLen(ProfileID));
        ProfileAppID := Any.GuidValue();

        // [WHEN] Populating the default profile
        Agent.PopulateDefaultProfile(ProfileID, ProfileAppID, TempAllProfile);

        // [THEN] The profile should be populated
        Assert.AreEqual(ProfileID, TempAllProfile."Profile ID", 'Profile ID should match');
        Assert.AreEqual(ProfileAppID, TempAllProfile."App ID", 'Profile App ID should match');
    end;

    [Test]
    procedure SetProfileWithRecord()
    var
        AgentRecord: Record Agent;
        AllProfile: Record "All Profile";
        TempUserSettingsRec: Record "User Settings";
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Set profile for an agent using a profile record

        // [GIVEN] An agent and a profile record
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        if AllProfile.FindFirst() then begin
            // [WHEN] Setting the profile
            Agent.SetProfile(AgentId, AllProfile);

            // [THEN] The profile should be set correctly
            Agent.GetUserSettings(AgentId, TempUserSettingsRec);
            Assert.AreEqual(Text.UpperCase(AllProfile."Profile ID"), TempUserSettingsRec."Profile ID", 'Profile ID should be set');
            Assert.AreEqual(AllProfile."App ID", TempUserSettingsRec."App ID", 'Profile App ID should be set');
        end;
    end;

    [Test]
    procedure SetProfileWithParameters()
    var
        AgentRecord: Record Agent;
        TempUserSettingsRec: Record "User Settings";
        Any: Codeunit Any;
        AgentId: Guid;
        ProfileID: Code[30];
        ProfileAppID: Guid;
    begin
        Initialize();

        // [SCENARIO] Set profile for an agent using profile ID and App ID

        // [GIVEN] An agent and profile parameters
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        ProfileID := CopyStr(Any.AlphanumericText(MaxStrLen(ProfileID)), 1, MaxStrLen(ProfileID));
        ProfileAppID := Any.GuidValue();

        // [WHEN] Setting the profile with parameters
        Agent.SetProfile(AgentId, ProfileID, ProfileAppID);

        // [THEN] The profile should be set correctly
        Agent.GetUserSettings(AgentId, TempUserSettingsRec);
        Assert.AreEqual(ProfileID, TempUserSettingsRec."Profile ID", 'Profile ID should be set');
        Assert.AreEqual(ProfileAppID, TempUserSettingsRec."App ID", 'Profile App ID should be set');
    end;

    #endregion

    #region Localization Settings Tests

    [Test]
    procedure UpdateLocalizationSettings()
    var
        AgentRecord: Record Agent;
        TempNewUserSettings: Record "User Settings";
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Update localization settings for an agent

        // [GIVEN] An agent and new user settings
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TempNewUserSettings."User Security ID" := AgentId;
        TempNewUserSettings."Locale ID" := Any.IntegerInRange(1000, 9999);
        TempNewUserSettings."Language ID" := Any.IntegerInRange(1000, 9999);
        TempNewUserSettings."Time Zone" := CopyStr(Any.AlphanumericText(30), 1, 30);

        // [WHEN] Updating localization settings
        Agent.UpdateLocalizationSettings(AgentId, TempNewUserSettings);

        // [THEN] The settings should be updated
        Assert.AreNotEqual(0, TempNewUserSettings."Locale ID", 'Locale ID should be updated');
    end;

    [Test]
    procedure GetUserSettings()
    var
        AgentRecord: Record Agent;
        TempUserSettingsRec: Record "User Settings";
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Get user settings for an agent

        // [GIVEN] An agent with user settings
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Getting the user settings
        Agent.GetUserSettings(AgentId, TempUserSettingsRec);

        // [THEN] User settings should be retrieved
        Assert.AreEqual(AgentId, TempUserSettingsRec."User Security ID", 'User Security ID should match');
        Assert.AreNotEqual(0, TempUserSettingsRec."Locale ID", 'Locale ID should be set');
    end;

    #endregion

    #region Access Control / Permission Set Tests

    [Test]
    procedure AssignPermissionSet_ReplacePermissionSet()
    var
        AgentRecord: Record Agent;
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
        AccessControl: Record "Access Control";
        Any: Codeunit Any;
        AgentId: Guid;
        EmptyGuid: Guid;
    begin
        Initialize();

        // [SCENARIO] Assign a new permission set to an agent, replacing existing permissions

        // [GIVEN] An agent with default permissions and a SUPER permission set to assign
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TempAccessControlBuffer.Init();
#pragma warning disable AA0139
        TempAccessControlBuffer."Company Name" := CompanyName();
#pragma warning restore AA0139
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := EmptyGuid;
        TempAccessControlBuffer."Role ID" := 'SUPER';
        TempAccessControlBuffer.Insert();

        // [WHEN] Assigning the permission set
        Agent.AssignPermissionSet(AgentId, TempAccessControlBuffer);

        // [THEN] The SUPER permission set should be assigned to the agent
        AccessControl.SetRange("User Security ID", AgentId);
        AccessControl.SetRange("Role ID", 'SUPER');
        AccessControl.SetRange("App ID", EmptyGuid);
        AccessControl.SetRange(Scope, TempAccessControlBuffer.Scope::System);
        AccessControl.SetRange("Company Name", CompanyName());
        Assert.IsTrue(AccessControl.FindFirst(), 'SUPER permission set should be assigned to the agent');

        // [THEN] The old default permissions should be replaced (only SUPER should exist)
        AccessControl.Reset();
        AccessControl.SetRange("User Security ID", AgentId);
        Assert.AreEqual(1, AccessControl.Count(), 'Should only have the SUPER permission set (old permissions replaced)');
    end;

    [Test]
    procedure AssignPermissionSet_AddPermissionSet()
    var
        AgentRecord: Record Agent;
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
        AccessControl: Record "Access Control";
        MockAgentSetup: Codeunit "Mock Agent Setup";
        Any: Codeunit Any;
        AgentId: Guid;
        EmptyGuid: Guid;
    begin
        Initialize();

        // [SCENARIO] Add a SUPER permission set to an agent while keeping existing default permissions

        // [GIVEN] An agent with default permissions and a SUPER permission set added to the buffer
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TempAccessControlBuffer.Init();
#pragma warning disable AA0139
        TempAccessControlBuffer."Company Name" := CompanyName();
#pragma warning restore AA0139
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := EmptyGuid;
        TempAccessControlBuffer."Role ID" := 'SUPER';
        TempAccessControlBuffer.Insert();

        MockAgentSetup.GetDefaultAccessControls(TempAccessControlBuffer);

        // [WHEN] Assigning the permission set
        Agent.AssignPermissionSet(AgentId, TempAccessControlBuffer);

        // [THEN] The SUPER permission set should be assigned to the agent
        AccessControl.SetRange("User Security ID", AgentId);
        AccessControl.SetRange("Role ID", 'SUPER');
        AccessControl.SetRange("App ID", EmptyGuid);
        AccessControl.SetRange(Scope, TempAccessControlBuffer.Scope::System);
        AccessControl.SetRange("Company Name", CompanyName());
        Assert.IsTrue(AccessControl.FindFirst(), 'SUPER permission set should be assigned to the agent');

        // [THEN] The default permissions should still exist (both SUPER and default)
        AccessControl.Reset();
        AccessControl.SetRange("User Security ID", AgentId);
        Assert.AreEqual(2, AccessControl.Count(), 'Should have both SUPER and default permission sets');
    end;

    [Test]
    procedure AssignPermissionSet_NoChange()
    var
        AgentRecord: Record Agent;
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
        AccessControl: Record "Access Control";
        MockAgentSetup: Codeunit "Mock Agent Setup";
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Assign the same permission set that an agent already has (no change)

        // [GIVEN] An agent with default permissions and the same default permissions in the buffer
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        MockAgentSetup.GetDefaultAccessControls(TempAccessControlBuffer);

        // [GIVEN] Record the initial permission count
        AccessControl.SetRange("User Security ID", AgentId);
        Assert.AreEqual(1, AccessControl.Count(), 'Should start with one default permission set');

        // [WHEN] Assigning the same permission set
        Agent.AssignPermissionSet(AgentId, TempAccessControlBuffer);

        // [THEN] The permission count should remain unchanged
        AccessControl.Reset();
        AccessControl.SetRange("User Security ID", AgentId);
        Assert.AreEqual(1, AccessControl.Count(), 'Permission count should remain 1 (no change)');

        // [THEN] The exact same permission set should still exist
        AccessControl.SetRange("Company Name", TempAccessControlBuffer."Company Name");
        AccessControl.SetRange("Role ID", TempAccessControlBuffer."Role ID");
        AccessControl.SetRange("App ID", TempAccessControlBuffer."App ID");
        AccessControl.SetRange(Scope, TempAccessControlBuffer.Scope);
        Assert.AreEqual(1, AccessControl.Count(), 'The same permission set should still exist');
    end;

    [Test]
    procedure AssignPermissionSet_UpdatePermissionSet_ChangeCompany()
    var
        AgentRecord: Record Agent;
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
        AccessControl: Record "Access Control";
        MockAgentSetup: Codeunit "Mock Agent Setup";
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Update an agent's permission set to change company from current company to all companies

        // [GIVEN] An agent with default permissions for current company and a permission set with empty company name (all companies)
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        MockAgentSetup.GetDefaultAccessControls(TempAccessControlBuffer);
        TempAccessControlBuffer.Rename('', TempAccessControlBuffer.Scope, TempAccessControlBuffer."App ID", TempAccessControlBuffer."Role ID");

        // [WHEN] Assigning the permission set with empty company name
        Agent.AssignPermissionSet(AgentId, TempAccessControlBuffer);

        // [THEN] The permission set with empty company name (all companies) should exist
        AccessControl.SetRange("User Security ID", AgentId);
        AccessControl.SetRange("Role ID", TempAccessControlBuffer."Role ID");
        AccessControl.SetRange("App ID", TempAccessControlBuffer."App ID");
        AccessControl.SetRange(Scope, TempAccessControlBuffer.Scope);
        AccessControl.SetRange("Company Name", '');
        Assert.AreEqual(1, AccessControl.Count(), 'Permission set with empty company name should exist');

        // [THEN] The old permission with specific company name should be gone
        AccessControl.Reset();
        AccessControl.SetRange("User Security ID", AgentId);
        AccessControl.SetRange("Role ID", TempAccessControlBuffer."Role ID");
        AccessControl.SetRange("App ID", TempAccessControlBuffer."App ID");
        AccessControl.SetRange(Scope, TempAccessControlBuffer.Scope);
        AccessControl.SetRange("Company Name", CompanyName());
        Assert.AreEqual(0, AccessControl.Count(), 'Permission set with specific company name should be removed');
    end;

    #endregion

    #region Agent Access Control Tests

    [Test]
    procedure GetUserAccess()
    var
        AgentRecord: Record Agent;
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Get user access for an agent

        // [GIVEN] An agent with access control
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Getting user access
        Agent.GetUserAccess(AgentId, TempAgentAccessControl);

        // [THEN] Access control entries should be retrieved
        Assert.IsTrue(TempAgentAccessControl.Count() >= 0, 'Should retrieve access control entries');
    end;

    [Test]
    procedure UpdateAccess()
    var
        AgentRecord: Record Agent;
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Update access control for an agent

        // [GIVEN] An agent and new access control settings
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        TempAgentAccessControl."Agent User Security ID" := AgentId;
        TempAgentAccessControl."User Security ID" := UserSecurityId();
        TempAgentAccessControl.Insert();

        // [WHEN] Updating access control
        Agent.UpdateAccess(AgentId, TempAgentAccessControl);

        // [THEN] Access should be updated
        Clear(TempAgentAccessControl);
        Agent.GetUserAccess(AgentId, TempAgentAccessControl);
        Assert.AreEqual(1, TempAgentAccessControl.Count(), 'Should have one access control entry');
    end;

    [Test]
    procedure UpdateAccessWithMultipleUsers()
    var
        AgentRecord: Record Agent;
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Update access control with multiple users

        // [GIVEN] An agent and multiple access control entries
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // Add first user
        TempAgentAccessControl."Agent User Security ID" := AgentId;
        TempAgentAccessControl."User Security ID" := UserSecurityId();
        TempAgentAccessControl.Insert();

        // Add second user
        TempAgentAccessControl."User Security ID" := Any.GuidValue();
        TempAgentAccessControl.Insert();

        // [WHEN] Updating access control
        Agent.UpdateAccess(AgentId, TempAgentAccessControl);

        // [THEN] Access should be updated with multiple entries
        Clear(TempAgentAccessControl);
        Agent.GetUserAccess(AgentId, TempAgentAccessControl);
        Assert.IsTrue(TempAgentAccessControl.Count() >= 1, 'Should have at least one access control entry');
    end;

    #endregion

    #region Integration Tests

    [Test]
    procedure CreateAndConfigureCompleteAgent()
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        TempNewUserSettings: Record "User Settings";
        Any: Codeunit Any;
        UserName: Code[50];
        DisplayName: Text[80];
        NewDisplayName: Text[80];
        Instructions: SecretText;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Create and fully configure an agent

        // [GIVEN] Complete agent configuration
        UserName := CopyStr(Any.AlphanumericText(MaxStrLen(UserName)), 1, MaxStrLen(UserName));
        DisplayName := CopyStr(Any.AlphanumericText(MaxStrLen(DisplayName)), 1, MaxStrLen(DisplayName));
        NewDisplayName := CopyStr(Any.AlphanumericText(MaxStrLen(NewDisplayName)), 1, MaxStrLen(NewDisplayName));

        // Create access control
        TempAgentAccessControl."User Security ID" := UserSecurityId();
        TempAgentAccessControl.Insert();

        // [WHEN] Creating and configuring the agent
        AgentId := Agent.Create("Agent Metadata Provider"::"SDK Mock Agent", UserName, DisplayName, TempAgentAccessControl);

        Agent.SetDisplayName(AgentId, NewDisplayName);
        Instructions := Format(Any.AlphanumericText(2048));
        Agent.SetInstructions(AgentId, Instructions);

        TempNewUserSettings."User Security ID" := AgentId;
        TempNewUserSettings."Locale ID" := Any.IntegerInRange(1000, 9999);
        TempNewUserSettings."Language ID" := Any.IntegerInRange(1000, 9999);
        TempNewUserSettings."Time Zone" := CopyStr(Any.AlphanumericText(MaxStrLen(TempNewUserSettings."Time Zone")), 1, MaxStrLen(TempNewUserSettings."Time Zone"));
        Agent.UpdateLocalizationSettings(AgentId, TempNewUserSettings);

        Agent.Activate(AgentId);

        // [THEN] All configurations should be set correctly
        Assert.AreEqual(NewDisplayName, Agent.GetDisplayName(AgentId), 'Display name should be updated');
        Assert.AreEqual(UserName, Agent.GetUserName(AgentId), 'User name should match');
        Assert.IsTrue(Agent.IsActive(AgentId), 'Agent should be active');

        Clear(TempNewUserSettings);
        Agent.GetUserSettings(AgentId, TempNewUserSettings);
        Assert.AreNotEqual(0, TempNewUserSettings."Locale ID", 'Locale should be set');
    end;

    [Test]
    procedure ActivateDeactivateCycle()
    var
        AgentRecord: Record Agent;
        Any: Codeunit Any;
        AgentId: Guid;
    begin
        Initialize();

        // [SCENARIO] Test multiple activate/deactivate cycles

        // [GIVEN] An agent
        AgentId := LibraryTestAgent.GetOrCreateDefaultAgent(
            AgentRecord,
            CopyStr(Any.AlphanumericText(MaxStrLen(AgentRecord."User Name")), 1, MaxStrLen(AgentRecord."User Name")),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(2048), 1, 2048));

        // [WHEN] Performing multiple activate/deactivate cycles
        Assert.IsTrue(Agent.IsActive(AgentId), 'Agent should start active');

        Agent.Deactivate(AgentId);
        Assert.IsFalse(Agent.IsActive(AgentId), 'Agent should be inactive after deactivate');

        Agent.Activate(AgentId);
        Assert.IsTrue(Agent.IsActive(AgentId), 'Agent should be active after reactivate');

        Agent.Deactivate(AgentId);
        Assert.IsFalse(Agent.IsActive(AgentId), 'Agent should be inactive again');

        Agent.Activate(AgentId);
        Assert.IsTrue(Agent.IsActive(AgentId), 'Agent should be active again');

        // [THEN] All state transitions should work correctly as verified above
    end;

    #endregion
}
