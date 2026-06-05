// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

using System.Agents;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;

/// <summary>
/// Helper methods for Agent SDK testing.
/// </summary>
codeunit 133954 "Library Mock Agent"
{
    Permissions = tabledata "Access Control" = rim,
                  tabledata User = rim;

    procedure GetOrCreateDefaultAgent(var AgentRecord: Record Agent; AgentUserName: Code[50]; DisplayName: Text[80]; Instructions: Text[2048]) AgentId: Guid
    var
        MockAgentSetup: Record "Mock Agent Setup";
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        TempUserSettings: Record "User Settings" temporary;
        Agent: Codeunit Agent;
    begin
        EnsureEnabledSuperUserExists();

        AgentRecord.SetRange("Agent Metadata Provider", AgentRecord."Agent Metadata Provider"::"SDK Mock Agent");
        AgentRecord.SetFilter("User Name", AgentUserName);
        if AgentRecord.FindFirst() then
            exit(AgentRecord."User Security ID");

        AgentId := Agent.Create("Agent Metadata Provider"::"SDK Mock Agent", AgentUserName, DisplayName, TempAgentAccessControl);
        Agent.Activate(AgentId);

        MockAgentSetup."User Security ID" := AgentId;
        MockAgentSetup.Instructions := Instructions;
        MockAgentSetup.Insert();

        TempUserSettings."User Security ID" := AgentId;
        TempUserSettings."Locale ID" := 1033; // English - United States
        TempUserSettings."Language ID" := 1036; // French - France
        TempUserSettings."Time Zone" := 'Central Europe Standard Time';
        TempUserSettings.Insert();

        Agent.UpdateLocalizationSettings(AgentId, TempUserSettings);

        Commit(); // Commit for Access Control assignments to take effect.

        exit(AgentId);
    end;

    procedure DeleteAllAgents()
    var
        AgentRecord: Record Agent;
        MockAgentSetup: Record "Mock Agent Setup";
    begin
        AgentRecord.SetRange("Agent Metadata Provider", AgentRecord."Agent Metadata Provider"::"SDK Mock Agent");
        if AgentRecord.FindSet() then
            repeat
                if MockAgentSetup.Get(AgentRecord."User Security ID") then
                    MockAgentSetup.Delete();

                AgentRecord.Delete();
            until AgentRecord.Next() = 0;
    end;

    procedure EnsureCurrentUserHasSuper()
    begin
        EnsureEnabledSuperUserExists();
    end;

    local procedure EnsureEnabledSuperUserExists()
    var
        User: Record User;
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if HasEnabledSuperUser() then
            exit;

        User.SetRange("User Name", SuperUserNameTok);
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := SuperUserNameTok;
            if not EnvironmentInformation.IsSaaSInfrastructure() then
                User."Windows Security ID" := CopyStr(SID(), 1, MaxStrLen(User."Windows Security ID"));
            User.State := User.State::Enabled;
            User."License Type" := User."License Type"::"Full User";
            User.Insert(true);
        end else begin
            User.State := User.State::Enabled;
            User."License Type" := User."License Type"::"Full User";
            User.Modify(true);
        end;

        AssignSuperPermission(User."User Security ID");
        Commit();
    end;

    local procedure HasEnabledSuperUser(): Boolean
    var
        AccessControl: Record "Access Control";
        User: Record User;
    begin
        SetSuperFilters(AccessControl);
        if AccessControl.FindSet() then
            repeat
                if User.Get(AccessControl."User Security ID") then
                    if User."User Name" = SuperUserNameTok then
                        if IsEnabledBusinessUser(User) then
                            exit(true);
            until AccessControl.Next() = 0;

        exit(false);
    end;

    local procedure IsEnabledBusinessUser(User: Record User): Boolean
    begin
        if User.State <> User.State::Enabled then
            exit(false);

        if User."License Type" = User."License Type"::"External User" then
            exit(false);

        if User."License Type" = User."License Type"::"AAD Group" then
            exit(false);

        if User."License Type" = User."License Type"::"Windows Group" then
            exit(false);

        exit(true);
    end;

    local procedure AssignSuperPermission(UserSecurityId: Guid)
    var
        AccessControl: Record "Access Control";
        NullGuid: Guid;
    begin
        SetSuperFilters(AccessControl);
        AccessControl.SetRange("User Security ID", UserSecurityId);
        if not AccessControl.IsEmpty() then
            exit;

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId;
        AccessControl."Role ID" := SuperRoleIdTok;
        AccessControl."Company Name" := '';
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl."App ID" := NullGuid;
        AccessControl.Insert(true);
    end;

    local procedure SetSuperFilters(var AccessControl: Record "Access Control")
    var
        NullGuid: Guid;
    begin
        AccessControl.SetRange("Role ID", SuperRoleIdTok);
        AccessControl.SetRange("Company Name", '');
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetRange("App ID", NullGuid);
    end;

    var
        SuperRoleIdTok: Label 'SUPER', Locked = true;
        SuperUserNameTok: Label 'AGENTSDKTESTSUPER', Locked = true;
}
