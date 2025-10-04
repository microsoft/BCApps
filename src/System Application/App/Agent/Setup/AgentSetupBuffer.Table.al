// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Configuration;
using System.Globalization;

table 4310 "Agent Setup Buffer"
{
    Caption = 'Agent Setup Buffer';
    DataPerCompany = false;
    DataClassification = SystemMetadata;
    Scope = OnPrem;

    fields
    {
        /// <summary>
        /// The unique security identifier for the user account associated with this agent.
        /// </summary>
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            Tooltip = 'Specifies the unique identifier for the agent user.';
        }
        /// <summary>
        /// The provider that supplies metadata and configuration information for this agent.
        /// </summary>
        field(2; "Agent Metadata Provider"; Enum "Agent Metadata Provider")
        {
            Caption = 'Agent Metadata Provider';
            Tooltip = 'Specifies the provider for the agent metadata.';
        }
        /// <summary>
        /// The user name of the account associated with this agent.
        /// </summary>
        field(3; "User Name"; Code[50])
        {
            Caption = 'User Name';
            Tooltip = 'Specifies the name of the user that is associated with the agent.';
        }
        /// <summary>
        /// The display name shown for this agent in the user interface.
        /// </summary>
        field(4; "Display Name"; Text[80])
        {
            Caption = 'Display Name';
            Tooltip = 'Specifies the display name of the user that is associated with the agent.';
        }
        /// <summary>
        /// The current operational state of the agent (Enabled or Disabled).
        /// </summary>
        field(5; "State"; Option)
        {
            Caption = 'State';
            OptionCaption = 'Active,Inactive';
            OptionMembers = Enabled,Disabled;
            Tooltip = 'Specifies the state of the user that is associated with the agent.';
            InitValue = Disabled;
        }
        /// <summary>
        /// The initials displayed on the agent's icon in the timeline and user interface.
        /// </summary>
        field(15; Initials; Text[4])
        {
            Caption = 'Initials';
            ToolTip = 'Specifies the initials to be displayed on the icon opening the agent''s timeline.';
        }
        /// <summary>
        /// Short summary of the agents capabilities and role.
        /// </summary>
        field(5000; "Agent Summary"; Blob)
        {
            Caption = 'Agent Summary';
            ToolTip = 'Specifies a short summary of the agents capabilities and role.';
        }
        /// <summary>
        /// Specifies the language that is used for task details and outgoing messages unless language is changed by the code
        /// </summary>
        field(5001; "Language Used"; Text[1024])
        {
            Caption = 'Language Used';
            ToolTip = 'Specifies the language that is used for task details and outgoing messages unless language is changed by the code.';
            Editable = false;
        }
    }
    keys
    {
        key(PK; "User Security ID")
        {
            Clustered = true;
        }
    }

    internal procedure GetConfigUpdated(): Boolean
    begin
        exit(ConfigUpdated);
    end;

    internal procedure SetConfigUpdated(NewConfigUpdated: Boolean)
    begin
        ConfigUpdated := NewConfigUpdated;
    end;

    internal procedure GetAccessUpdated(): Boolean
    begin
        exit(AccessUpdated);
    end;

    internal procedure SetAccessUpdated(NewAccessUpdated: Boolean)
    begin
        AccessUpdated := NewAccessUpdated;
    end;

    internal procedure GetUserSettingsUpdated(): Boolean
    begin
        exit(UserSettingsUpdated);
    end;

    internal procedure SetUserSettingsUpdated(NewUserSettingsUpdated: Boolean)
    begin
        UserSettingsUpdated := NewUserSettingsUpdated;
    end;

    /// <summary>
    /// Gets the Agent Summary as text from the blob field.
    /// </summary>
    /// <returns>The agent summary text content.</returns>
    internal procedure GetAgentSummary(): Text
    var
        InStream: InStream;
        SummaryText: Text;
    begin
        Rec.CalcFields("Agent Summary");
        if not Rec."Agent Summary".HasValue() then
            exit('');

        Rec."Agent Summary".CreateInStream(InStream, GetDefaultEncoding());
        InStream.ReadText(SummaryText);
        exit(SummaryText);
    end;

    /// <summary>
    /// Sets the Agent Summary blob field with the provided text.
    /// </summary>
    /// <param name="SummaryText">The text content to store in the agent summary.</param>
    internal procedure SetAgentSummary(SummaryText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Agent Summary".CreateOutStream(OutStream, GetDefaultEncoding());
        OutStream.WriteText(SummaryText);
    end;

    local procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    internal procedure Initialize(UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80]; AgentSummary: Text)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.DeleteAll();

        Rec."User Security ID" := UserSecurityID;
        Rec."Agent Metadata Provider" := AgentMetadataProvider;

        UpdateFiles(UserSecurityID, AgentMetadataProvider, DefaultUserName, DefaultDisplayName);

        Rec.Insert();
        SetAgentSummary(AgentSummary);
        Rec.Modify();
    end;

    internal procedure UpdateUserAccessControl()
    var
        TempBackupAgentAccessControl: Record "Agent Access Control" temporary;
    begin
        Rec.UpdateUserAccessControl();
        CopyTempAgentAccessControl(TempAgentAccessControl, TempBackupAgentAccessControl);
        if (Page.RunModal(Page::"Select Agent Access Control", TempAgentAccessControl) in [Action::LookupOK, Action::OK]) then begin
            Rec.SetAccessUpdated(true);
            Rec.SetConfigUpdated(true);
            exit;
        end;

        CopyTempAgentAccessControl(TempBackupAgentAccessControl, TempAgentAccessControl);
    end;

    internal procedure SetupLanguageAndRegion()
    var
        UserSettings: Record "User Settings";
        Language: Codeunit Language;
        AgentUserSettings: Page "Agent User Settings";
    begin
        AgentUserSettings.InitializeTemp(UserSettings);
        if AgentUserSettings.RunModal() in [Action::LookupOK, Action::OK] then begin
            AgentUserSettings.GetRecord(UserSettings);
            Rec.SetAccessUpdated(true);
            Rec.SetUserSettingsUpdated(true);
#pragma warning disable AA0139
            Rec."Language Used" := Language.GetWindowsLanguageName(UserSettings."Language ID");
#pragma warning restore AA0139
            Rec.Modify();
        end;
    end;

    internal procedure GetChangesMade(): Boolean
    begin
        exit(ConfigUpdated or AccessUpdated or UserSettingsUpdated);
    end;

    local procedure CopyTempAgentAccessControl(var SourceTempAgentAccessControl: Record "Agent Access Control" temporary; var TargetTempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        TargetTempAgentAccessControl.Reset();
        TargetTempAgentAccessControl.DeleteAll();
        if not SourceTempAgentAccessControl.FindSet() then
            exit;

        repeat
            TargetTempAgentAccessControl.TransferFields(SourceTempAgentAccessControl, true);
            TargetTempAgentAccessControl.Insert()
        until SourceTempAgentAccessControl.Next() = 0;
    end;

    local procedure UpdateFiles(UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80])
    var
        Agent: Record Agent;
        AgentMetadata: Interface IAgentMetadata;
    begin
        if not IsNullGuid(UserSecurityID) then
            if Agent.Get(UserSecurityID) then begin
                Rec."User Name" := Agent."User Name";
                Rec."Display Name" := Agent."Display Name";
                Rec.State := Agent.State;
                // Question - do initials always win over AgentMetadataProvider?
                Rec.Initials := Agent.Initials;
                exit;
            end;

        AgentMetadata := AgentMetadataProvider;
        Rec."User Name" := DefaultUserName;
        Rec."Display Name" := DefaultDisplayName;
        Rec.Initials := AgentMetadata.GetInitials(UserSecurityID);
        Rec.State := Rec.State::Disabled;
    end;

    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        ConfigUpdated: Boolean;
        AccessUpdated: Boolean;
        UserSettingsUpdated: Boolean;
}