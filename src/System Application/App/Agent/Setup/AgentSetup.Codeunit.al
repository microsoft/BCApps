// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Configuration;
using System.Globalization;

codeunit 4324 "Agent Setup"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [Scope('OnPrem')]
    procedure GetSetupRecord(UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80]; AgentSummary: Text): Record "Agent Setup Buffer"
    var
        AgentSetupBuffer: Record "Agent Setup Buffer";
    begin
        Clear(AgentSetupBuffer);
        AgentSetupBuffer.DeleteAll();

        AgentSetupBuffer."User Security ID" := UserSecurityID;
        AgentSetupBuffer."Agent Metadata Provider" := AgentMetadataProvider;

        UpdateFields(AgentSetupBuffer, UserSecurityID, AgentMetadataProvider, DefaultUserName, DefaultDisplayName);

        AgentSetupBuffer.Insert();
        SetAgentSummary(AgentSummary, AgentSetupBuffer);
        AgentSetupBuffer.Modify();
    end;

    [Scope('OnPrem')]
    procedure SaveValues(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        Agent: Record Agent;
    begin
        if IsNullGuid(AgentSetupBuffer."User Security ID") then begin
            Agent.Get(CreateAgent(AgentSetupBuffer));
            exit;
        end;

        UpdateAgent(AgentSetupBuffer);
    end;

    [Scope('OnPrem')]
    procedure UpdateUserAccessControl(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
    begin
        TempAgentAccessControl := AgentSetupBuffer.GetTempAgentAccessControl();
        if (Page.RunModal(Page::"Select Agent Access Control", TempAgentAccessControl) in [Action::LookupOK, Action::OK]) then begin
            AgentSetupBuffer."Access Updated" := true;
            AgentSetupBuffer."Values Updated" := true;
            AgentSetupBuffer.Modify(true);
            AgentSetupBuffer.SetTempAgentAccessControl(TempAgentAccessControl);
            exit;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetChangesMade(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    begin
        exit(AgentSetupBuffer."Access Updated" or AgentSetupBuffer."Values Updated" or AgentSetupBuffer."User Settings Updated");
    end;

    local procedure UpdateFields(var AgentSetupBuffer: Record "Agent Setup Buffer"; UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50];
                                                                                                                                     DefaultDisplayName: Text[80])
    var
        Agent: Record Agent;
        AgentMetadata: Interface IAgentMetadata;
    begin
        if not IsNullGuid(UserSecurityID) then
            if Agent.Get(UserSecurityID) then begin
                AgentSetupBuffer."User Name" := Agent."User Name";
                AgentSetupBuffer."Display Name" := Agent."Display Name";
                AgentSetupBuffer.State := Agent.State;
                // Question - do initials always win over AgentMetadataProvider?
                AgentSetupBuffer.Initials := Agent.Initials;
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
    procedure SetupLanguageAndRegion(AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    var
        UserSettings: Record "User Settings";
        Language: Codeunit Language;
        AgentUserSettings: Page "Agent User Settings";
    begin
        UserSettings := AgentSetupBuffer.GetUserSettings();
        AgentUserSettings.InitializeTemp(UserSettings);
        if AgentUserSettings.RunModal() in [Action::LookupOK, Action::OK] then begin
            AgentUserSettings.GetRecord(UserSettings);
            AgentSetupBuffer."Access Updated" := true;
#pragma warning disable AA0139
            AgentSetupBuffer."Language Used" := Language.GetWindowsLanguageName(UserSettings."Language ID");
#pragma warning restore AA0139
            AgentSetupBuffer.SetUserSettings(UserSettings);
            AgentSetupBuffer.Modify();
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Gets the Agent Summary as text from the blob field.
    /// </summary>
    /// <returns>The agent summary text content.</returns>
    [Scope('OnPrem')]
    procedure GetAgentSummary(var AgentSetupBuffer: Record "Agent Setup Buffer"): Text
    var
        InStream: InStream;
        SummaryText: Text;
    begin
        AgentSetupBuffer.CalcFields("Agent Summary");
        if not AgentSetupBuffer."Agent Summary".HasValue() then
            exit('');

        AgentSetupBuffer."Agent Summary".CreateInStream(InStream, GetDefaultEncoding());
        InStream.ReadText(SummaryText);
        exit(SummaryText);
    end;

    local procedure CreateAgent(var AgentSetupBuffer: Record "Agent Setup Buffer"): Guid
    var
        AgentRecord: Record Agent;
        NewUserSettings: Record "User Settings";
        TemporaryAgentAccessControl: Record "Agent Access Control" temporary;
        Agent: Codeunit Agent;
    begin
        TemporaryAgentAccessControl := AgentSetupBuffer.GetTempAgentAccessControl();
        AgentRecord.Get(Agent.Create(AgentSetupBuffer."Agent Metadata Provider", AgentSetupBuffer."User Name", AgentSetupBuffer."Display Name", TemporaryAgentAccessControl));
        SetBufferFieldsToAgent(AgentSetupBuffer, AgentRecord);
        NewUserSettings := AgentSetupBuffer.GetUserSettings();
        Agent.UpdateLocalizationSettings(AgentRecord."User Security ID", NewUserSettings);

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
            SetBufferFieldsToAgent(AgentSetupBuffer, AgentRecord);

        if AgentSetupBuffer."User Settings Updated" then begin
            NewUserSettings := AgentSetupBuffer.GetUserSettings();
            Agent.UpdateLocalizationSettings(AgentSetupBuffer."User Security ID", NewUserSettings);
        end;

        if AgentSetupBuffer."Access Updated" then begin
            TemporaryAgentAccessControl := AgentSetupBuffer.GetTempAgentAccessControl();
            Agent.UpdateAccess(AgentSetupBuffer."User Security ID", TemporaryAgentAccessControl);
        end;
    end;

    /// <summary>
    /// Sets the Agent Summary blob field with the provided text.
    /// </summary>
    /// <param name="SummaryText">The text content to store in the agent summary.</param>
    local procedure SetAgentSummary(SummaryText: Text; var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        OutStream: OutStream;
    begin
        AgentSetupBuffer."Agent Summary".CreateOutStream(OutStream, GetDefaultEncoding());
        OutStream.WriteText(SummaryText);
    end;

    local procedure SetBufferFieldsToAgent(var AgentSetupBuffer: Record "Agent Setup Buffer"; var AgentRecord: Record Agent)
    var
        Agent: Codeunit Agent;
    begin
        AgentRecord."Display Name" := AgentSetupBuffer."Display Name";
        AgentRecord."User Name" := AgentSetupBuffer."User Name";
        AgentRecord.Initials := AgentSetupBuffer.Initials;
        AgentRecord.Modify();

        if AgentSetupBuffer.State = AgentSetupBuffer.State::Enabled then
            Agent.Activate(AgentRecord."User Security ID")
        else
            Agent.Deactivate(AgentRecord."User Security ID");
        AgentRecord.Find();
    end;

    local procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;
}