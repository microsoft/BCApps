// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Configuration;
using System.Reflection;
using System.Environment;
using System.Security.AccessControl;

codeunit 4301 "Agent Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = rim,
                  tabledata "All Profile" = r,
                  tabledata Company = r,
                  tabledata "Agent Access Control" = d,
                  tabledata "Application User Settings" = rim,
                  tabledata User = r,
                  tabledata "User Personalization" = rim;

    internal procedure CreateAgent(AgentMetadataProvider: Enum "Agent Metadata Provider"; var UserName: Code[50]; AgentUserDisplayName: Text[80]; var TempAgentAccessControl: Record "Agent Access Control" temporary): Guid
    var
        Agent: Record Agent;
    begin
        Agent."Agent Metadata Provider" := AgentMetadataProvider;
        Agent."User Name" := GenerateUniqueUserName(UserName);
        UserName := Agent."User Name";
        Agent."Display Name" := AgentUserDisplayName;
        Agent.Insert(true);

        if TempAgentAccessControl.IsEmpty() then
            GetUserAccess(Agent, TempAgentAccessControl, true);

        AssignCompany(Agent."User Security ID", CompanyName());
        AssignDefaultProfile(Agent."User Security ID");
        UpdateAgentAccessControl(TempAgentAccessControl, Agent);

        exit(Agent."User Security ID");
    end;

    internal procedure Activate(AgentUserSecurityID: Guid)
    begin
        ChangeAgentState(AgentUserSecurityID, true);
    end;

    internal procedure Deactivate(AgentUserSecurityID: Guid)
    begin
        ChangeAgentState(AgentUserSecurityID, false);
    end;

    [NonDebuggable]
    internal procedure SetInstructions(AgentUserSecurityID: Guid; Instructions: SecretText)
    var
        AgentALFunctions: DotNet AgentALFunctions;
    begin
        AgentALFunctions.SetInstructions(AgentUserSecurityID, Instructions.Unwrap());
    end;

    [NonDebuggable]
    internal procedure GetInstructions(AgentUserSecurityID: Guid): SecretText
    var
        AgentALFunctions: DotNet AgentALFunctions;
        InstructionsAsSecretText: SecretText;
    begin
        if IsNullGuid(AgentUserSecurityID) then
            exit;

        InstructionsAsSecretText := AgentALFunctions.GetInstructions(AgentUserSecurityID);
        exit(InstructionsAsSecretText);
    end;

    internal procedure InsertCurrentOwnerIfNoOwnersDefined(var Agent: Record Agent; var AgentAccessControl: Record "Agent Access Control")
    begin
        SetOwnerFilters(AgentAccessControl);
        AgentAccessControl.SetRange("Agent User Security ID", Agent."User Security ID");
        if not AgentAccessControl.IsEmpty() then
            exit;
        InsertCurrentOwner(Agent."User Security ID", AgentAccessControl);
    end;

    internal procedure InsertCurrentOwner(AgentUserSecurityID: Guid; var AgentAccessControl: Record "Agent Access Control")
    begin
        AgentAccessControl."Can Configure Agent" := true;
        AgentAccessControl."Agent User Security ID" := AgentUserSecurityID;
        AgentAccessControl."User Security ID" := UserSecurityId();
        AgentAccessControl.Insert();
    end;

    internal procedure VerifyOwnerExists(AgentAccessControlModified: Record "Agent Access Control")
    var
        ExistingAgentAccessControl: Record "Agent Access Control";
    begin
        if (AgentAccessControlModified."Can Configure Agent") then
            exit;

        SetOwnerFilters(ExistingAgentAccessControl);
        ExistingAgentAccessControl.SetFilter("User Security ID", '<>%1', AgentAccessControlModified."User Security ID");
        ExistingAgentAccessControl.SetRange("Agent User Security ID", AgentAccessControlModified."Agent User Security ID");

        if ExistingAgentAccessControl.IsEmpty() then
            Error(OneOwnerMustBeDefinedForAgentErr);
    end;

    internal procedure GetUserAccess(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        GetUserAccess(Agent, TempAgentAccessControl, false);
    end;

    local procedure GetUserAccess(var Agent: Record Agent; var TempAgentAccessControl: Record "Agent Access Control" temporary; InsertCurrentUserAsOwner: Boolean)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.DeleteAll();

        AgentAccessControl.SetRange("Agent User Security ID", Agent."User Security ID");
        if AgentAccessControl.IsEmpty() then begin
            if not InsertCurrentUserAsOwner then
                exit;

            InsertCurrentOwnerIfNoOwnersDefined(Agent, TempAgentAccessControl);
            exit;
        end;

        AgentAccessControl.FindSet();
        repeat
            TempAgentAccessControl.Copy(AgentAccessControl);
            TempAgentAccessControl.Insert();
        until AgentAccessControl.Next() = 0;
    end;

    internal procedure PopulateProfileTempRecord(ProfileID: Text[30]; ProfileAppID: Guid; var TempAllProfile: Record "All Profile" temporary)
    begin
        TempAllProfile.Scope := TempAllProfile.Scope::Tenant;
        TempAllProfile."App ID" := ProfileAppID;
        TempAllProfile."Profile ID" := ProfileID;
        TempAllProfile.Insert();
    end;

    local procedure AssignDefaultProfile(AgentUserSecurityID: Guid)
    var
        Agent: Record Agent;
        TempAllProfile: Record "All Profile" temporary;
        AgentFactory: Interface IAgentFactory;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        AgentFactory := Agent."Agent Metadata Provider";
        AgentFactory.GetDefaultProfile(TempAllProfile);
        SetProfile(Agent, TempAllProfile);
    end;

    internal procedure SetProfile(AgentUserSecurityID: Guid; var AllProfile: Record "All Profile")
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        SetProfile(Agent, AllProfile);
    end;

    local procedure SetProfile(Agent: Record Agent; var AllProfile: Record "All Profile")
    var
        UserSettingsRecord: Record "User Settings";
        UserSettings: Codeunit "User Settings";
    begin
        UserSettings.GetUserSettings(Agent."User Security ID", UserSettingsRecord);
        UpdateUserSettingsWithProfile(AllProfile, UserSettingsRecord);
        UpdateAgentUserSettings(UserSettingsRecord);
    end;

    internal procedure UpdateLocalizationSettings(AgentUserSecurityID: Guid; var NewUserSettingsRec: Record "User Settings")
    var
        Agent: Record Agent;
        UserSettingsRecord: Record "User Settings";
        UserSettings: Codeunit "User Settings";
    begin
        GetAgent(Agent, AgentUserSecurityID);

        UserSettings.GetUserSettings(Agent."User Security ID", UserSettingsRecord);
        UserSettingsRecord."Language ID" := NewUserSettingsRec."Language ID";
        UserSettingsRecord."Locale ID" := NewUserSettingsRec."Locale ID";
        UserSettingsRecord."Time Zone" := NewUserSettingsRec."Time Zone";
        UpdateAgentUserSettings(UserSettingsRecord);
    end;

    internal procedure GetUserSettings(AgentUserSecurityID: Guid; var UserSettingsRec: Record "User Settings")
    var
        Agent: Record Agent;
        UserSettings: Codeunit "User Settings";
        UserSecurityID: Guid;
    begin
        UserSecurityID := UserSecurityId();
        if not IsNullGuid(AgentUserSecurityID) then
            if Agent.Get(AgentUserSecurityID) then
                UserSecurityID := Agent."User Security ID";

        UserSettings.GetUserSettings(UserSecurityID, UserSettingsRec);
    end;

    local procedure AssignCompany(AgentUserSecurityID: Guid; CompanyName: Text)
    var
        Agent: Record Agent;
        UserSettingsRecord: Record "User Settings";
        UserSettings: Codeunit "User Settings";
    begin
        GetAgent(Agent, AgentUserSecurityID);

        UserSettings.GetUserSettings(Agent."User Security ID", UserSettingsRecord);
#pragma warning disable AA0139
        UserSettingsRecord.Company := CompanyName;
#pragma warning restore AA0139
        UpdateAgentUserSettings(UserSettingsRecord);
    end;

    internal procedure GetUserName(AgentUserSecurityID: Guid): Code[50]
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        exit(Agent."User Name");
    end;

    internal procedure GetDisplayName(AgentUserSecurityID: Guid): Text[80]
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        exit(Agent."Display Name")
    end;

    internal procedure SetDisplayName(AgentUserSecurityID: Guid; DisplayName: Text[80])
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        Agent."Display Name" := DisplayName;
        Agent.Modify(true);
    end;

    internal procedure IsActive(AgentUserSecurityID: Guid): Boolean
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        exit(Agent.State = Agent.State::Enabled);
    end;

    internal procedure UpdateAgentAccessControl(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        Agent: Record Agent;
    begin
        if not Agent.Get(AgentUserSecurityID) then
            Error(AgentDoesNotExistErr);

        UpdateAgentAccessControl(TempAgentAccessControl, Agent);
    end;

    # Region TODO: Update System App signatures to use the codeunit 9175 "User Settings Impl."
    internal procedure UpdateAgentUserSettings(NewUserSettings: Record "User Settings")
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Get(NewUserSettings."User Security ID");

        UserPersonalization."Language ID" := NewUserSettings."Language ID";
        UserPersonalization."Locale ID" := NewUserSettings."Locale ID";
        UserPersonalization.Company := NewUserSettings.Company;
        UserPersonalization."Time Zone" := NewUserSettings."Time Zone";
        UserPersonalization."Profile ID" := NewUserSettings."Profile ID";
#pragma warning disable AL0432 // All profiles are now in the tenant scope
        UserPersonalization.Scope := NewUserSettings.Scope;
#pragma warning restore AL0432
        UserPersonalization."App ID" := NewUserSettings."App ID";
        UserPersonalization.Modify();
    end;

    procedure ProfileLookup(var UserSettingsRec: Record "User Settings"): Boolean
    var
        TempAllProfile: Record "All Profile" temporary;
    begin
        PopulateProfiles(TempAllProfile);

        if TempAllProfile.Get(UserSettingsRec.Scope, UserSettingsRec."App ID", UserSettingsRec."Profile ID") then;
        if Page.RunModal(Page::Roles, TempAllProfile) = Action::LookupOK then begin
            UpdateUserSettingsWithProfile(TempAllProfile, UserSettingsRec);
            exit(true);
        end;
        exit(false);
    end;

    local procedure UpdateUserSettingsWithProfile(var TempAllProfile: Record "All Profile" temporary; var UserSettingsRec: Record "User Settings")
    begin
        UserSettingsRec."Profile ID" := TempAllProfile."Profile ID";
        UserSettingsRec."App ID" := TempAllProfile."App ID";
        UserSettingsRec.Scope := TempAllProfile.Scope;
    end;

    local procedure PopulateProfiles(var TempAllProfile: Record "All Profile" temporary)
    var
        AllProfile: Record "All Profile";
        DescriptionFilterTxt: Label 'Navigation menu only.';
        UserCreatedAppNameTxt: Label '(User-created)';
    begin
        TempAllProfile.Reset();
        TempAllProfile.DeleteAll();
        AllProfile.SetRange(Enabled, true);
        AllProfile.SetFilter(Description, '<> %1', DescriptionFilterTxt);
        if AllProfile.FindSet() then
            repeat
                TempAllProfile := AllProfile;
                if IsNullGuid(TempAllProfile."App ID") then
                    TempAllProfile."App Name" := UserCreatedAppNameTxt;
                TempAllProfile.Insert();
            until AllProfile.Next() = 0;
    end;

    internal procedure AssignPermissionSets(var UserSID: Guid; PermissionCompanyName: Text; var AggregatePermissionSet: Record "Aggregate Permission Set")
    var
        AccessControl: Record "Access Control";
    begin
        if not AggregatePermissionSet.FindSet() then
            exit;

        repeat
            AccessControl."App ID" := AggregatePermissionSet."App ID";
            AccessControl."User Security ID" := UserSID;
            AccessControl."Role ID" := AggregatePermissionSet."Role ID";
            AccessControl.Scope := AggregatePermissionSet.Scope;
#pragma warning disable AA0139
            AccessControl."Company Name" := PermissionCompanyName;
#pragma warning restore AA0139
            AccessControl.Insert();
        until AggregatePermissionSet.Next() = 0;
    end;
    #endregion

    local procedure GetAgent(var Agent: Record Agent; UserSecurityID: Guid)
    begin
        if not Agent.Get(UserSecurityID) then
            Error(AgentDoesNotExistErr);
    end;

    local procedure ChangeAgentState(UserSecurityID: Guid; Enabled: Boolean)
    var
        Agent: Record Agent;

    begin
        GetAgent(Agent, UserSecurityId);

        if Enabled then
            Agent.State := Agent.State::Enabled
        else
            Agent.State := Agent.State::Disabled;

        Agent.Modify();
    end;

    local procedure UpdateAgentAccessControl(var TempAgentAccessControl: Record "Agent Access Control" temporary; var Agent: Record Agent)
    begin
        // We must delete or update the user doing the change the last to avoid removing permissions that are needed to commit the change
        UpdateUsersOtherThanMainUser(TempAgentAccessControl, Agent);

        // Update the user at the end
        UpdateUserDoingTheChange(TempAgentAccessControl, Agent);
    end;

    local procedure UpdateUsersOtherThanMainUser(var TempAgentAccessControl: Record "Agent Access Control" temporary; var Agent: Record Agent)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        AgentAccessControl.SetRange("Agent User Security ID", Agent."User Security ID");
        AgentAccessControl.SetFilter("User Security ID", '<>%1', UserSecurityId());
        if AgentAccessControl.FindSet() then
            repeat
                if not TempAgentAccessControl.Get(AgentAccessControl."Agent User Security ID", AgentAccessControl."User Security ID") then
                    AgentAccessControl.Delete(true);
            until AgentAccessControl.Next() = 0;

        AgentAccessControl.Reset();
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.SetFilter("User Security ID", '<>%1', UserSecurityId());
        if not TempAgentAccessControl.FindSet() then
            exit;

        repeat
            if AgentAccessControl.Get(Agent."User Security ID", TempAgentAccessControl."User Security ID") then begin
                AgentAccessControl.TransferFields(TempAgentAccessControl, true);
                AgentAccessControl."Agent User Security ID" := Agent."User Security ID";
                AgentAccessControl.Modify();
            end else begin
                AgentAccessControl.TransferFields(TempAgentAccessControl, true);
                AgentAccessControl."Agent User Security ID" := Agent."User Security ID";
                AgentAccessControl.Insert();
            end;
        until TempAgentAccessControl.Next() = 0;
    end;

    local procedure UpdateUserDoingTheChange(var TempAgentAccessControl: Record "Agent Access Control" temporary; var Agent: Record Agent)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        TempAgentAccessControl.SetFilter("User Security ID", UserSecurityId());
        if not TempAgentAccessControl.FindFirst() then begin
            if AgentAccessControl.Get(Agent."User Security ID", UserSecurityId()) then
                AgentAccessControl.Delete();

            exit;
        end;

        if AgentAccessControl.Get(Agent."User Security ID", UserSecurityId()) then begin
            AgentAccessControl.TransferFields(TempAgentAccessControl, true);
            AgentAccessControl."Agent User Security ID" := Agent."User Security ID";
            AgentAccessControl.Modify();
            exit;
        end else begin
            AgentAccessControl.TransferFields(TempAgentAccessControl, true);
            AgentAccessControl."Agent User Security ID" := Agent."User Security ID";
            AgentAccessControl.Insert();
            exit;
        end;
    end;

    procedure SelectAgent(var Agent: Record "Agent")
    begin
        Agent.SetRange(State, Agent.State::Enabled);
        if Agent.Count() = 0 then
            Error(NoActiveAgentsErr);

        if Agent.Count() = 1 then begin
            Agent.FindFirst();
            exit;
        end;

        if not (Page.RunModal(Page::"Agent List", Agent) in [Action::LookupOK, Action::OK]) then
            Error('');
    end;

    local procedure SetOwnerFilters(var AgentAccessControl: Record "Agent Access Control")
    begin
        AgentAccessControl.SetFilter("Can Configure Agent", '%1', true);
    end;

    procedure ShowNoAgentsAvailableNotification()
    var
        NoAgentsNotification: Notification;
    begin
        NoAgentsNotification.Id(NoAgentsAvailableNotificationGuidLbl);
        NoAgentsNotification.Message(NoAgentsAvailableNotificationLbl);
        NoAgentsNotification.Scope(NotificationScope::LocalScope);
        NoAgentsNotification.AddAction(NoAgentsAvailableNotificationLearnMoreLbl, Codeunit::"Agent Impl.", 'OpenNoAgentsLearnMore');

        if NoAgentsNotification.Recall() then;
        NoAgentsNotification.Send();
    end;

    procedure OpenNoAgentsLearnMore(Notification: Notification)
    begin
        Hyperlink(NoAgentsAvailableNotificationLearnMoreUrlLbl);
    end;

    local procedure GenerateUniqueUserName(AgentUserName: Code[50]): Code[50]
    var
        User: Record User;
        UniqueUserName: Text[50];
        AgentNamePrefix: Text[50];
        NumberOfAgentDigits: Integer;
        MaximumPrefixLength: Integer;
        AgentNumberSeparatorTok: Label '-', Locked = true;
    begin
        // Check if the user name is already unique
        User.SetRange("User Name", AgentUserName);
        User.ReadIsolation := IsolationLevel::ReadUncommitted;
        if User.IsEmpty() then
            exit(AgentUserName);

        // If not check if there is a user with digits at the end of the name
        NumberOfAgentDigits := 2;
        MaximumPrefixLength := MaxStrLen(User."User Name") - NumberOfAgentDigits - StrLen(AgentNumberSeparatorTok);
        if StrLen(AgentUserName) < MaximumPrefixLength then
#pragma warning disable AA0139
            AgentNamePrefix := AgentUserName + AgentNumberSeparatorTok
#pragma warning restore AA0139
        else
            AgentNamePrefix := CopyStr(AgentUserName, 1, MaximumPrefixLength) + AgentNumberSeparatorTok;

        // Generate a unique user name by appending digits
        User.SetFilter("User Name", '%1', AgentNamePrefix + '*');
#pragma warning disable AA0139
        UniqueUserName := AgentNamePrefix + Format(User.Count() + 2);
#pragma warning restore AA0139

        exit(UniqueUserName);
    end;

    internal procedure OpenSetupPageId(AgentMetadataProvider: Enum "Agent Metadata Provider"; AgentUserSecurityID: Guid)
    var
        PageMetadata: Record "Page Metadata";
        FieldMetadata: Record Field;
        SetupPageRecordRef: RecordRef;
        UserSecurityIdFieldRef: FieldRef;
        AgentMetadata: Interface IAgentMetadata;
        SourceRecordVariant: Variant;
        SetupPageId: Integer;
        UserSecurityIdTok: Label 'User Security ID', Locked = true;
    begin
        AgentMetadata := AgentMetadataProvider;
        SetupPageId := AgentMetadata.GetSetupPageId(AgentUserSecurityID);

        PageMetadata.Get(SetupPageId);
        if (PageMetadata.SourceTable = 0) then
            Error(SetupPageMissingSourceTableErr, SetupPageId);

        SetupPageRecordRef.Open(PageMetadata.SourceTable);

        FieldMetadata.SetRange(TableNo, PageMetadata.SourceTable);
        FieldMetadata.SetRange(FieldName, UserSecurityIdTok);
        if not FieldMetadata.FindFirst() then
            Error(SetupPageSourceTableMissingFieldErr, SetupPageId, UserSecurityIdTok);

        if (FieldMetadata.Type <> FieldMetadata.Type::Guid) then
            Error(SetupPageSourceTableFieldWrongTypeErr, UserSecurityIdTok, SetupPageId, FieldMetadata.Type::Guid);

        UserSecurityIdFieldRef := SetupPageRecordRef.Field(FieldMetadata."No.");
        UserSecurityIdFieldRef.SetFilter(AgentUserSecurityID);
        SourceRecordVariant := SetupPageRecordRef;
        Page.RunModal(SetupPageId, SourceRecordVariant);
    end;

    var
        OneOwnerMustBeDefinedForAgentErr: Label 'One owner must be defined for the agent.';
        AgentDoesNotExistErr: Label 'Agent does not exist.';
        NoActiveAgentsErr: Label 'There are no active agents setup on the system.';
        NoAgentsAvailableNotificationLbl: Label 'Business Central agents are currently not available in your country.';
        NoAgentsAvailableNotificationGuidLbl: Label 'bde1d653-40e6-4081-b2cf-f21b1a8622d1', Locked = true;
        NoAgentsAvailableNotificationLearnMoreLbl: Label 'Learn more';
        NoAgentsAvailableNotificationLearnMoreUrlLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2303876', Locked = true;
        SetupPageMissingSourceTableErr: Label 'Setup page with ID %1 must specify a source table.', Comment = '%1 = Setup page ID.';
        SetupPageSourceTableMissingFieldErr: Label 'The source table for setup page %1 must include a field named ''%2''.', Comment = '%1 = Setup page ID, %2 = Required field name.';
        SetupPageSourceTableFieldWrongTypeErr: Label 'Field ''%1'' on the source table for setup page %2 must be of type %3.', Comment = '%1 = Field name, %2 = Setup page ID, %3 = Required field type.';
}