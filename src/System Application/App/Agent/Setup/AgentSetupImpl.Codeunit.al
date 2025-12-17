// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Configuration;
using System.Globalization;

codeunit 4325 "Agent Setup Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    [Scope('OnPrem')]
    procedure GetSetupRecord(var AgentSetupBuffer: Record "Agent Setup Buffer"; UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80]; AgentSummary: Text)
    var
        TemporaryAgentAccessControl: Record "Agent Access Control" temporary;
        Agent: Codeunit Agent;
    begin
        Clear(AgentSetupBuffer);
        AgentSetupBuffer.DeleteAll();

        AgentSetupBuffer."User Security ID" := UserSecurityID;
        AgentSetupBuffer."Agent Metadata Provider" := AgentMetadataProvider;

        UpdateFields(AgentSetupBuffer, UserSecurityID, AgentMetadataProvider, DefaultUserName, DefaultDisplayName);
        AgentSetupBuffer.Insert();
        SetAgentSummary(AgentSummary, AgentSetupBuffer);
        if not IsNullGuid(UserSecurityID) then begin
            Agent.GetUserAccess(AgentSetupBuffer."User Security ID", TemporaryAgentAccessControl);
            AgentSetupBuffer.SetTempAgentAccessControl(TemporaryAgentAccessControl);
        end;
    end;

    [Scope('OnPrem')]
    procedure SaveChanges(var AgentSetupBuffer: Record "Agent Setup Buffer") "Agent User ID": Guid
    begin
        if IsNullGuid(AgentSetupBuffer."User Security ID") then
            exit(CreateAgent(AgentSetupBuffer));

        UpdateAgent(AgentSetupBuffer);
        exit(AgentSetupBuffer."User Security ID");
    end;

    [Scope('OnPrem')]
    procedure UpdateUserAccessControl(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        SelectAgentAccessControl: Page "Select Agent Access Control";
    begin
        AgentSetupBuffer.GetTempAgentAccessControl(TempAgentAccessControl);
        SelectAgentAccessControl.SetAgentUserSecurityID(AgentSetupBuffer."User Security ID");
        SelectAgentAccessControl.Load(TempAgentAccessControl);
        if (SelectAgentAccessControl.RunModal() in [Action::LookupOK, Action::OK]) then begin
            AgentSetupBuffer."Access Updated" := true;
            AgentSetupBuffer.Modify(true);
            AgentSetupBuffer.SetTempAgentAccessControl(TempAgentAccessControl);
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetChangesMade(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        exit(AgentSetupBuffer."Access Updated" or AgentSetupBuffer."Values Updated" or AgentSetupBuffer."User Settings Updated" or AgentSetupBuffer."State Updated");
    end;

    local procedure UpdateFields(var AgentSetupBuffer: Record "Agent Setup Buffer"; UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80])
    var
        Agent: Record Agent;
        UserSettings: Record "User Settings";
        Language: Codeunit Language;
        AgentMetadata: Interface IAgentMetadata;
    begin
        UserSettings := AgentSetupBuffer.GetUserSettings();
        AgentSetupBuffer."Language Used" := CopyStr(Language.GetWindowsLanguageName(UserSettings."Language ID"), 1, MaxStrLen(AgentSetupBuffer."Language Used"));

        if not IsNullGuid(UserSecurityID) then
            if Agent.Get(UserSecurityID) then begin
                AgentSetupBuffer."User Name" := Agent."User Name";
                AgentSetupBuffer."Display Name" := Agent."Display Name";
                AgentSetupBuffer.State := Agent.State;
                AgentMetadata := Agent."Agent Metadata Provider";
                AgentSetupBuffer.Initials := AgentMetadata.GetInitials(UserSecurityID);
                AgentSetupBuffer."Configured By" := Agent.SystemModifiedBy;
                exit;
            end;

        AgentMetadata := AgentMetadataProvider;
        AgentSetupBuffer."User Name" := DefaultUserName;
        AgentSetupBuffer."Display Name" := DefaultDisplayName;
        AgentSetupBuffer.Initials := AgentMetadata.GetInitials(UserSecurityID);
        AgentSetupBuffer.State := AgentSetupBuffer.State::Disabled;
    end;

    [Scope('OnPrem')]
    procedure SetupLanguageAndRegion(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    var
        UserSettings: Record "User Settings";
        Language: Codeunit Language;
        AgentUserSettings: Page "Agent User Settings";
    begin
        UserSettings := AgentSetupBuffer.GetUserSettings();
        AgentUserSettings.InitializeTemp(UserSettings);
        if AgentUserSettings.RunModal() in [Action::LookupOK, Action::OK] then begin
            AgentUserSettings.GetRecord(UserSettings);
            AgentSetupBuffer."User Settings Updated" := true;
#pragma warning disable AA0139
            AgentSetupBuffer."Language Used" := Language.GetWindowsLanguageName(UserSettings."Language ID");
#pragma warning restore AA0139
            AgentSetupBuffer.SetUserSettings(UserSettings);
            AgentSetupBuffer.Modify();
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetAgentSummary(var AgentSetupBuffer: Record "Agent Setup Buffer"): Text
    var
        SummaryInStream: InStream;
        SummaryText: Text;
        FullSummaryText: TextBuilder;
    begin
        AgentSetupBuffer.CalcFields("Agent Summary");
        if not AgentSetupBuffer."Agent Summary".HasValue() then
            exit('');

        AgentSetupBuffer."Agent Summary".CreateInStream(SummaryInStream, GetDefaultEncoding());

        repeat
            SummaryInStream.ReadText(SummaryText);
            FullSummaryText.Append(SummaryText);
        until SummaryInStream.EOS();

        exit(FullSummaryText.ToText());
    end;

    local procedure CreateAgent(var AgentSetupBuffer: Record "Agent Setup Buffer"): Guid
    var
        AgentRecord: Record Agent;
        NewUserSettings: Record "User Settings";
        TemporaryAgentAccessControl: Record "Agent Access Control" temporary;
        Agent: Codeunit Agent;
    begin
        AgentSetupBuffer.GetTempAgentAccessControl(TemporaryAgentAccessControl);
        AgentSetupBuffer."User Security ID" := Agent.Create(AgentSetupBuffer."Agent Metadata Provider", AgentSetupBuffer."User Name", AgentSetupBuffer."Display Name", TemporaryAgentAccessControl);
        AgentRecord.Get(AgentSetupBuffer."User Security ID");
        NewUserSettings := AgentSetupBuffer.GetUserSettings();
        Agent.UpdateLocalizationSettings(AgentRecord."User Security ID", NewUserSettings);
        UpdateAgentState(AgentSetupBuffer);

        exit(AgentRecord."User Security ID");
    end;

    local procedure UpdateAgent(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        AgentRecord: Record Agent;
        NewUserSettings: Record "User Settings";
        TemporaryAgentAccessControl: Record "Agent Access Control" temporary;
        Agent: Codeunit Agent;
    begin
        AgentRecord.Get(AgentSetupBuffer."User Security ID");

        if AgentSetupBuffer."Values Updated" then
            Agent.SetDisplayName(AgentSetupBuffer."User Security ID", AgentSetupBuffer."Display Name");

        if AgentSetupBuffer."User Settings Updated" then begin
            NewUserSettings := AgentSetupBuffer.GetUserSettings();
            Agent.UpdateLocalizationSettings(AgentSetupBuffer."User Security ID", NewUserSettings);
        end;

        if AgentSetupBuffer."Access Updated" then begin
            AgentSetupBuffer.GetTempAgentAccessControl(TemporaryAgentAccessControl);
            Agent.UpdateAccess(AgentSetupBuffer."User Security ID", TemporaryAgentAccessControl);
        end;

        if AgentSetupBuffer."State Updated" then
            UpdateAgentState(AgentSetupBuffer);
    end;

    local procedure UpdateAgentState(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        Agent: Codeunit Agent;
    begin
        if AgentSetupBuffer.State = AgentSetupBuffer.State::Enabled then
            Agent.Activate(AgentSetupBuffer."User Security ID")
        else
            Agent.Deactivate(AgentSetupBuffer."User Security ID");
    end;

    local procedure SetAgentSummary(SummaryText: Text; var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        SummaryOutStream: OutStream;
    begin
        Clear(AgentSetupBuffer."Agent Summary");
        AgentSetupBuffer."Agent Summary".CreateOutStream(SummaryOutStream, GetDefaultEncoding());
        SummaryOutStream.WriteText(SummaryText);
        AgentSetupBuffer.Modify();
    end;

    local procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;
}