// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Configuration;

table 4310 "Agent Setup Buffer"
{
    Caption = 'Agent Setup Buffer';
    TableType = Temporary;
    ReplicateData = false;
    DataClassification = SystemMetadata;

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

            trigger OnValidate()
            begin
                SetValuesUpdated();
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

            trigger OnValidate()
            begin
                SetValuesUpdated();
            end;
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
        field(5002; "Values Updated"; Boolean)
        {
            Caption = 'Config Updated';
            ToolTip = 'Specifies whether the configuration has been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        field(5003; "Access Updated"; Boolean)
        {
            Caption = 'Access Updated';
            ToolTip = 'Specifies whether the access control has been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        field(5004; "User Settings Updated"; Boolean)
        {
            Caption = 'User Settings Updated';
            ToolTip = 'Specifies whether the user settings have been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
        }
        field(5005; "Configured By"; Guid)
        {
            Caption = 'Configured By';
            ToolTip = 'Specifies the user who configured the agent.';
            Editable = false;
        }
        field(5006; "State Updated"; Boolean)
        {
            Caption = 'State Updated';
            ToolTip = 'Specifies whether the state has been updated. Value is changed through code.';
            Editable = false;
            AllowInCustomizations = Never;
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

    internal procedure GetTempAgentAccessControl(): Record "Agent Access Control" temporary
    var
        TempCopiedTempAccessControl: Record "Agent Access Control" temporary;
    begin
        CopyTempAgentAccessControl(TempAgentAccessControl, TempCopiedTempAccessControl);
        exit(TempCopiedTempAccessControl);
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

    internal procedure GetUserSettings(): Record "User Settings"
    var
        Agent: Codeunit Agent;
    begin
        if not UserSettingsSet then
            Agent.GetUserSettings(Rec."User Security ID", GlobalUserSettings);

        exit(GlobalUserSettings);
    end;

    internal procedure SetUserSettings(var UserSettingsRec: Record "User Settings")
    begin
        GlobalUserSettings.Copy(UserSettingsRec);
        UserSettingsSet := true;
    end;

    local procedure SetValuesUpdated()
    begin
        Rec."Values Updated" := true;
    end;

    local procedure SetStateUpdated()
    begin
        Rec."State Updated" := true;
    end;

    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        GlobalUserSettings: Record "User Settings";
        UserSettingsSet: Boolean;
}