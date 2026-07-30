// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

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
                field(Availability; CopilotAvailabilityTxt)
                {
                    Caption = 'Availability';
                    ToolTip = 'Specifies the availability of the agent.';
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

                            if Agent.ProfileLookup(TempUserSettingsRecord) then
                                Agent.SetProfile(TempUserSettingsRecord."User Security ID", TempUserSettingsRecord."Profile ID", TempUserSettingsRecord."App ID");
                        end;
                    }
                    field(Language; Language.GetWindowsLanguageName(TempUserSettingsRecord."Language ID"))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Language';
                        ToolTip = 'Specifies the display language for the agent.';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            UserSettings: Codeunit "User Settings";
                        begin
                            UserSettings.GetUserSettings(Rec."User Security ID", TempUserSettingsRecord);
                            Commit();
                            Page.RunModal(Page::"Agent User Settings", TempUserSettingsRecord);
                            CurrPage.Update(false);
                        end;
                    }
                }
                field(State; Rec.State)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Standard;
                    Caption = 'State';
                    ToolTip = 'Specifies if the agent is active or inactive.';
                    Editable = StateEditable;

                    trigger OnValidate()
                    begin
                        ChangeState();
                        UpdateControls();
                    end;
                }
                field(Substate; Rec.Substate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Substate';
                    ToolTip = 'Specifies whether the agent is archived.';
                    Editable = false;
                }
            }
            part(Permissions; "View Agent Permissions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Agent Permissions';
                SubPageLink = "User Security ID" = field("User Security ID");
            }
            part(UserAccess; "View Agent Access Control")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Access';
                SubPageLink = "Agent User Security ID" = field("User Security ID");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ArchiveAgent)
            {
                ApplicationArea = All;
                Caption = 'Archive';
                ToolTip = 'Archive the selected agent. The agent and its existing tasks and logs remain available as read-only. Archiving cannot be undone.';
                Image = Archive;
                Enabled = ArchiveActionEnabled;

                trigger OnAction()
                var
                    Agent: Codeunit Agent;
                    ArchiveConfirmation: Page "Agent Archive Confirmation";
                begin
                    if Rec.State <> Rec.State::Disabled then
                        Error(DeactivateBeforeArchivingErr);

                    Rec.TestField("Display Name");
                    ArchiveConfirmation.SetAgentDisplayName(Rec."Display Name");
                    ArchiveConfirmation.RunModal();
                    if not ArchiveConfirmation.IsConfirmed() then
                        exit;

                    Agent.Archive(Rec."User Security ID");
                    Message(AgentArchivedMsg);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(AgentSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Configure';
                ToolTip = 'Configure agent';
                Image = SetupLines;
                Enabled = Rec."Can Curr. User Configure Agent";

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
                Enabled = not AgentIsArchived;

                trigger OnAction()
                var
                    UserSettings: Codeunit "User Settings";
                begin
                    Rec.TestField("User Security ID");
                    UserSettings.GetUserSettings(Rec."User Security ID", TempUserSettingsRecord);
                    Commit();
                    Page.RunModal(Page::"Agent User Settings", TempUserSettingsRecord);
                end;
            }
            action(AgentTasks)
            {
                ApplicationArea = All;
                Caption = 'View tasks';
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
        AgentUtilities: Codeunit "Agent Utilities";
        AgentSystemPermissions: Codeunit "Agent System Permissions";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();

        if not AgentSystemPermissions.CurrentUserCanManageAgent(Rec."User Security ID") then
            Error(YouDoNotHavePermissionToModifyThisAgentErr);
    end;

    local procedure UpdateControls()
    var
        AgentImpl: Codeunit "Agent Impl.";
        UserSettings: Codeunit "User Settings";
    begin
        if not IsNullGuid(Rec."User Security ID") then begin
            UserSettings.GetUserSettings(Rec."User Security ID", TempUserSettingsRecord);
            ProfileDisplayName := UserSettings.GetProfileName(TempUserSettingsRecord);
        end;

        CopilotAvailabilityTxt := AgentImpl.GetCopilotAvailabilityDisplayText(Rec);
        AgentIsArchived := Rec.Substate = Rec.Substate::Archived;
        ArchiveActionEnabled := (not AgentIsArchived) and Rec."Can Curr. User Configure Agent";
        StateEditable := not AgentIsArchived;
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
        SendArchivedNotificationIfNeeded();
    end;

    local procedure SendArchivedNotificationIfNeeded()
    var
        ArchivedNotification: Notification;
    begin
        if not AgentIsArchived then begin
            Clear(LastNotifiedArchivedAgentId);
            exit;
        end;

        if LastNotifiedArchivedAgentId = Rec."User Security ID" then
            exit;

        LastNotifiedArchivedAgentId := Rec."User Security ID";
        ArchivedNotification.Message(AgentArchivedNotificationMsg);
        ArchivedNotification.Scope(NotificationScope::LocalScope);
        ArchivedNotification.Send();
    end;

    local procedure OpenSetupPage()
    var
        Agent: Codeunit Agent;
    begin
        Agent.OpenSetupPageId(Rec."Agent Metadata Provider", Rec."User Security ID");
        CurrPage.Update(false);
    end;

    var
        TempUserSettingsRecord: Record "User Settings";
        Language: Codeunit Language;
        ProfileDisplayName, CopilotAvailabilityTxt : Text;
        ArchiveActionEnabled, AgentIsArchived, StateEditable : Boolean;
        LastNotifiedArchivedAgentId: Guid;
        ProfileChangedQst: Label 'Changing the agent''s profile may affect its accuracy and performance. It could also grant access to unexpected fields and actions.\\Do you want to continue?';
        OpenConfigurationPageQst: Label 'To activate the agent, use the configuration page. Would you like to open this page now?';
        YouCannotEnableAgentWithoutUsingConfigurationPageErr: Label 'You can''t activate the agent from this page. Use the action to configure and activate the agent.';
        YouDoNotHavePermissionToModifyThisAgentErr: Label 'You do not have permission to modify this agent. Contact your system administrator to update your permissions or to mark you as one of the administrators for the agent.';
        DeactivateBeforeArchivingErr: Label 'Deactivate the agent before archiving it.';
        AgentArchivedMsg: Label 'The agent has been archived.';
        AgentArchivedNotificationMsg: Label 'This agent is archived and can no longer be modified. Its tasks and logs remain available for auditing.';
}