// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Configuration;

/// <summary>
/// Setup record used to configure the agents. It should be used together with <see cref="Agent Setup"/> codeunit and <see cref="Agent Setup Part"/> page.
/// </summary>
table 4310 "Agent Setup Buffer"
{
    Caption = 'Agent Setup Buffer';
    TableType = Temporary;
    ReplicateData = false;
    DataClassification = SystemMetadata;
    InherentEntitlements = X;
    InherentPermissions = X;

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
            trigger OnValidate()
            begin
                Rec."Values Updated" := true;
            end;
        }
        /// <summary>
        /// The display name shown for this agent in the user interface.
        /// </summary>
        field(4; "Display Name"; Text[80])
        {
            Caption = 'Display Name';
            Tooltip = 'Specifies the display name of the user that is associated with the agent.';

            trigger OnValidate()
            begin
                Rec."Values Updated" := true;
            end;
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

            trigger OnValidate()
            begin
                SetStateUpdated();
            end;
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
            ToolTip = 'Specifies a short summary of the agents capabilities and role. Value is changed through code.';
        }
        /// <summary>
        /// Specifies the language that is used for task details and outgoing messages unless language is changed by the code
        /// </summary>
        field(5001; "Language Used"; Text[1024])
        {
            Caption = 'Language Used';
            ToolTip = 'Specifies the language that is used for task details and outgoing messages unless language is changed by the code. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        /// <summary>
        /// Specifies whether the values are updated. Example of the fields that are tracked are - user name, user display name, initials. Value is changed through code.
        /// </summary>
        field(5002; "Values Updated"; Boolean)
        {
            Caption = 'Config Updated';
            ToolTip = 'Specifies whether the configuration has been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        /// <summary>
        /// Specifies whether the access control to the agent is updated. This means that the settings on who can access the agent were changed. 
        /// </summary>
        field(5003; "Access Updated"; Boolean)
        {
            Caption = 'Access Updated';
            ToolTip = 'Specifies whether the access control has been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        /// <summary>
        /// Specifies whether the user settings (language, regional settings, time zone) have been updated. 
        /// </summary>
        field(5004; "User Settings Updated"; Boolean)
        {
            Caption = 'User Settings Updated';
            ToolTip = 'Specifies whether the user settings (language, regional settings, time zone) have been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        /// <summary>
        /// Specifies whether the state (Active or Inactive) was updated.
        /// </summary>
        field(5005; "State Updated"; Boolean)
        {
            Caption = 'State Updated';
            ToolTip = 'Specifies whether the state has been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        /// <summary>
        /// Specifies the last user who configured the agent.
        /// </summary>
        field(5020; "Configured By"; Guid)
        {
            Caption = 'Configured By';
            ToolTip = 'Specifies the last user who configured the agent.';
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

    internal procedure SetTempAgentAccessControl(var NewTempAgentAccessControl: Record "Agent Access Control" temporary)
    begin
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.DeleteAll();
        CopyTempAgentAccessControl(NewTempAgentAccessControl, TempAgentAccessControl);
    end;

    internal procedure GetTempAgentAccessControl(var TempCopiedTempAccessControl: Record "Agent Access Control" temporary)
    begin
        CopyTempAgentAccessControl(TempAgentAccessControl, TempCopiedTempAccessControl);
        TempCopiedTempAccessControl.Reset();
    end;

    internal procedure CopyTempAgentAccessControl(var SourceTempAgentAccessControl: Record "Agent Access Control" temporary; var TargetTempAgentAccessControl: Record "Agent Access Control" temporary)
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

    internal procedure GetUserSettings(var TempNewUserSetting: Record "User Settings" temporary)
    var
        UserSettings: Record "User Settings";
        Agent: Codeunit Agent;
    begin
        if not TempUserSettings.FindFirst() then begin
            Agent.GetUserSettings(Rec."User Security ID", UserSettings);
            TempUserSettings.Copy(UserSettings);
        end;

        TempNewUserSetting.Copy(TempUserSettings, true);
    end;

    internal procedure SetUserSettings(var UserSettingsRec: Record "User Settings")
    begin
        TempUserSettings.Reset();
        TempUserSettings.DeleteAll();
        TempUserSettings.Copy(UserSettingsRec);
        TempUserSettings.Insert();
    end;

    local procedure SetStateUpdated()
    begin
        Rec."State Updated" := true;
    end;

    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        TempUserSettings: Record "User Settings" temporary;
}