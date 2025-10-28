// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.User;
using System.Environment.Configuration;
using System.Globalization;

page 4315 "Agent Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = Agent;
    Caption = 'Agent Card';
    RefreshOnActivate = true;
    DataCaptionExpression = Rec."User Name";
    InsertAllowed = false;
    DeleteAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Agent Metadata Provider"; Rec."Agent Metadata Provider")
                {
                    ShowMandatory = true;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    Tooltip = 'Specifies the type of the agent.';
                    Editable = false;
                }
                field(UserName; Rec."User Name")
                {
                    ShowMandatory = true;
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    Tooltip = 'Specifies the name of the user that is associated with the agent.';
                    Editable = false;
                }

                field(DisplayName; Rec."Display Name")
                {
                    ShowMandatory = true;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Display Name';
                    Tooltip = 'Specifies the display name of the user that is associated with the agent.';
                    Editable = false;
                }
                group(UserSettingsGroup)
                {
                    ShowCaption = false;
                    field(AgentProfile; ProfileDisplayName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Profile (Role)';
                        ToolTip = 'Specifies the profile that is associated with the agent.';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            Agent: Codeunit Agent;
                        begin
                            if not Confirm(ProfileChangedQst, false) then
                                exit;

                            if Agent.ProfileLookup(UserSettingsRecord) then
                                Agent.SetProfile(UserSettingsRecord."User Security ID", UserSettingsRecord."Profile ID", UserSettingsRecord."App ID");
                        end;
                    }
                    field(Language; Language.GetWindowsLanguageName(UserSettingsRecord."Language ID"))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Language';
                        ToolTip = 'Specifies the display language for the agent.';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            UserSettings: Codeunit "User Settings";
                        begin
                            UserSettings.GetUserSettings(Rec."User Security ID", UserSettingsRecord);
                            Commit();
                            Page.RunModal(Page::"Agent User Settings", UserSettingsRecord);
                            CurrPage.Update(false);
                        end;
                    }
                }
                field(State; Rec.State)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Standard;
                    Caption = 'State';
                    ToolTip = 'Specifies if the agent is enabled or disabled.';

                    trigger OnValidate()
                    begin
                        ChangeState();
                        UpdateControls();
                    end;
                }
            }

            part(Permissions; "User Subform")
            {
                Editable = ControlsEditable;
                ApplicationArea = Basic, Suite;
                Caption = 'Agent Permission Sets';
                SubPageLink = "User Security ID" = field("User Security ID");
            }
            part(UserAccess; "Agent Access Control")
            {
                Editable = ControlsEditable;
                ApplicationArea = Basic, Suite;
                Caption = 'User Access';
                SubPageLink = "Agent User Security ID" = field("User Security ID");
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(AgentSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                ToolTip = 'Set up agent';
                Image = SetupLines;

                trigger OnAction()
                begin
                    OpenSetupPage();
                end;
            }
            action(UserSettingsAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Agent User Settings';
                ToolTip = 'Set up the user settings for the agent.';
                Image = SetupLines;

                trigger OnAction()
                var
                    UserSettings: Codeunit "User Settings";
                begin
                    Rec.TestField("User Security ID");
                    UserSettings.GetUserSettings(Rec."User Security ID", UserSettingsRecord);
                    Commit();
                    Page.RunModal(Page::"Agent User Settings", UserSettingsRecord);
                end;
            }
            action(AgentTasks)
            {
                ApplicationArea = All;
                Caption = 'Agent Tasks';
                ToolTip = 'View agent tasks';
                Image = Log;

                trigger OnAction()
                var
                    AgentTask: Record "Agent Task";
                begin
                    AgentTask.SetRange("Agent User Security ID", Rec."User Security ID");
                    Page.Run(Page::"Agent Task List", AgentTask);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AgentSetup_Promoted; AgentSetup)
                {
                }
                actionref(UserSettings_Promoted; UserSettingsAction)
                {
                }
                actionref(AgentTasks_Promoted; AgentTasks)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentSessionImpl: Codeunit "Agent Session Impl.";
    begin
        AgentSessionImpl.BlockPageFromBeingOpenedByAgent();

        if not Rec.WritePermission() then
            Error(YouDoNotHavePermissionToModifyThisAgentErr);
    end;

    local procedure UpdateControls()
    var
        UserSettings: Codeunit "User Settings";
    begin
        if not IsNullGuid(Rec."User Security ID") then begin
            UserSettings.GetUserSettings(Rec."User Security ID", UserSettingsRecord);
            ProfileDisplayName := UserSettings.GetProfileName(UserSettingsRecord);
        end;

        ControlsEditable := Rec.State = Rec.State::Disabled;
    end;

    local procedure ChangeState()
    var
        ConfirmOpenSetupPage: Boolean;
    begin
        if Rec."Setup Page ID" = 0 then
            exit;

        if Rec.State = Rec.State::Disabled then
            exit;

        ConfirmOpenSetupPage := false;

        if GuiAllowed() then
            ConfirmOpenSetupPage := Confirm(OpenConfigurationPageQst);

        if not ConfirmOpenSetupPage then
            Error(YouCannotEnableAgentWithoutUsingConfigurationPageErr);

        Rec.Find();
        OpenSetupPage();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure OpenSetupPage()
    var
        Agent: Codeunit Agent;
    begin
        Agent.OpenSetupPageId(Rec."Agent Metadata Provider", Rec."User Security ID");
        CurrPage.Update(false);
    end;

    var
        UserSettingsRecord: Record "User Settings";
        Language: Codeunit Language;
        ProfileDisplayName: Text;
        ControlsEditable: Boolean;
        ProfileChangedQst: Label 'Changing the agent''s profile may affect its accuracy and performance. It could also grant access to unexpected fields and actions. Do you want to continue?';
        OpenConfigurationPageQst: Label 'To activate the agent, use the setup page. Would you like to open this page now?';
        YouCannotEnableAgentWithoutUsingConfigurationPageErr: Label 'You can''t activate the agent from this page. Use the action to set up and activate the agent.';
        YouDoNotHavePermissionToModifyThisAgentErr: Label 'You do not have permission to modify this agent. Contact your system administrator to update your permissions or to mark you as one of the administrators for the agent.';
}