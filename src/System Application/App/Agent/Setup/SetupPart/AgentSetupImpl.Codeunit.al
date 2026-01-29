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
    procedure OpenAgentAccessControlSetup(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        SelectAgentAccessControl: Page "Select Agent Access Control";
    begin
        AgentSetupBuffer.GetTempAgentAccessControl(TempAgentAccessControl);
        SelectAgentAccessControl.Initialize(AgentSetupBuffer."User Security ID", TempAgentAccessControl);
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

    [Scope('OnPrem')]
    procedure OpenProfileLookup(var UserSettingsRec: Record "User Settings"): Boolean
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        exit(AgentImpl.ProfileLookup(UserSettingsRec));
    end;

    /// <summary>
    /// Opens the setup page for the specified agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">Security ID of the agent.</param>
    [Scope('OnPrem')]
    procedure OpenSetupPage(AgentUserSecurityID: Guid)
    var
        Agent: Record Agent;
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.GetAgent(Agent, AgentUserSecurityID);
        AgentImpl.OpenSetupPageId(Agent."Agent Metadata Provider", AgentUserSecurityID);
    end;

    [Scope('OnPrem')]
    procedure OpenAgentLookup(var AgentUserSecurityId: Guid): Boolean
    var
        Agent: Record Agent;
        AgentImpl: Codeunit "Agent Impl.";
    begin
        AgentImpl.SelectAgent(Agent);
        AgentUserSecurityId := Agent."User Security ID";
        exit(not IsNullGuid(AgentUserSecurityId));
    end;

    [Scope('OnPrem')]
    procedure OpenAgentLookup(AgentType: Enum "Agent Metadata Provider"; var AgentUserSecurityId: Guid): Boolean
    var
        Agent: Record Agent;
        AgentImpl: Codeunit "Agent Impl.";
    begin
        Agent.SetRange("Agent Metadata Provider", AgentType);
        AgentImpl.SelectAgent(Agent);
        AgentUserSecurityId := Agent."User Security ID";
        exit(not IsNullGuid(AgentUserSecurityId));
    end;

    local procedure UpdateFields(var AgentSetupBuffer: Record "Agent Setup Buffer"; UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80])
    var
        Agent: Record Agent;
        UserSettings: Record "User Settings";
        Language: Codeunit Language;
        AgentMetadata: Interface IAgentMetadata;
    begin
        AgentSetupBuffer.GetUserSettings(UserSettings);
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
    procedure OpenLanguageAndRegionPage(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    var
        UserSettings: Record "User Settings";
        Language: Codeunit Language;
        AgentUserSettings: Page "Agent User Settings";
    begin
        AgentSetupBuffer.GetUserSettings(UserSettings);
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

    internal procedure AppendAgentSummary(var AgentSetupBuffer: Record "Agent Setup Buffer"; SummaryText: Text): Text
    var
        UserSettings: Record "User Settings";
        Language: Codeunit Language;
        NewSummaryText: Text;
    begin
        NewSummaryText := SummaryText;
        if not NewSummaryText.Contains(ReviewForAccuracyAgentUsesAILbl) then
            NewSummaryText := StrSubstNo(AppendTextToEndTxt, NewSummaryText, ReviewForAccuracyAgentUsesAILbl);

        if not SummaryText.Contains(LanguageUsedLbl) then begin
            AgentSetupBuffer.GetUserSettings(UserSettings);
            NewSummaryText := StrSubstNo(AppendTextToEndTxt, NewSummaryText, StrSubstNo(LanguageUsedLbl, Language.GetWindowsLanguageName(UserSettings."Language ID")));
        end;

        exit(NewSummaryText);
    end;

    internal procedure CopyAgentSetupBuffer(var Target: Record "Agent Setup Buffer"; var Source: Record "Agent Setup Buffer")
    var
        TempUserSettings: Record "User Settings" temporary;
        TempAccessControl: Record "Agent Access Control" temporary;
    begin
        Target.Copy(Source, true);
        Source.GetUserSettings(TempUserSettings);
        Target.SetUserSettings(TempUserSettings);
        Source.GetTempAgentAccessControl(TempAccessControl);
        Target.SetTempAgentAccessControl(TempAccessControl);
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
        AgentSetupBuffer.GetUserSettings(NewUserSettings);
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
            AgentSetupBuffer.GetUserSettings(NewUserSettings);
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

    var
        LanguageUsedLbl: Label 'Language used: %1', Comment = '%1 is the language name, e.g. English (United States).';
        ReviewForAccuracyAgentUsesAILbl: Label 'This agent uses AI - review its actions for accuracy.';
        AppendTextToEndTxt: Label '%1\\%2', Comment = '%1 is the existing summary text, %2 is the text that we are appending to the end';
}