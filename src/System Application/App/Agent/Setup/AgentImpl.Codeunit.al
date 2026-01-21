// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment;
using System.Environment.Configuration;
using System.Environment.Consumption;
using System.Reflection;
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

    procedure CreateAgent(AgentMetadataProvider: Enum "Agent Metadata Provider"; var UserName: Code[50]; AgentUserDisplayName: Text[80]; var TempAgentAccessControl: Record "Agent Access Control" temporary): Guid
    var
        Agent: Record Agent;
    begin
        Agent."Agent Metadata Provider" := AgentMetadataProvider;
        Agent."User Name" := GenerateUniqueUserName(UserName);
        UserName := Agent."User Name";
        Agent."Display Name" := AgentUserDisplayName;
        Agent.Insert(true);

        if TempAgentAccessControl.IsEmpty() then
            // If no access control is provided, the server is giving access to the user creating the agent.
            GetUserAccess(Agent, TempAgentAccessControl);

        AssignCompany(Agent."User Security ID", CompanyName());
        AssignDefaultProfile(Agent."User Security ID");
        UpdateAgentAccessControl(TempAgentAccessControl, Agent);

        exit(Agent."User Security ID");
    end;

    procedure Activate(AgentUserSecurityID: Guid)
    begin
        ChangeAgentState(AgentUserSecurityID, true);
    end;

    procedure Deactivate(AgentUserSecurityID: Guid)
    begin
        ChangeAgentState(AgentUserSecurityID, false);
    end;

    procedure GetUserAccess(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        GetUserAccess(Agent, TempAgentAccessControl);
    end;

    local procedure GetUserAccess(var Agent: Record Agent; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.DeleteAll();

        AgentAccessControl.SetRange("Agent User Security ID", Agent."User Security ID");
        if AgentAccessControl.IsEmpty() then
            exit;

        AgentAccessControl.FindSet();
        repeat
            TempAgentAccessControl.Copy(AgentAccessControl);
            TempAgentAccessControl.Insert();
        until AgentAccessControl.Next() = 0;
    end;

    procedure PopulateProfileTempRecord(ProfileID: Text[30]; ProfileAppID: Guid; var TempAllProfile: Record "All Profile" temporary)
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

    procedure SetProfile(AgentUserSecurityID: Guid; var AllProfile: Record "All Profile")
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        SetProfile(Agent, AllProfile);
    end;

    procedure SetProfile(AgentUserSecurityID: Guid; ProfileID: Text; ProfileAppID: Guid)
    var
        Agent: Record Agent;
        TempAllProfile: Record "All Profile" temporary;
    begin
        GetAgent(Agent, AgentUserSecurityID);
        PopulateProfileTempRecord(CopyStr(ProfileID, 1, 30), ProfileAppID, TempAllProfile);
        SetProfile(Agent, TempAllProfile);
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

    procedure UpdateLocalizationSettings(AgentUserSecurityID: Guid; LanguageID: Integer; LocaleID: Integer; TimeZone: Text[180])
    var
        TempNewUserSettingsRec: Record "User Settings" temporary;
    begin
        TempNewUserSettingsRec."Language ID" := LanguageID;
        TempNewUserSettingsRec."Locale ID" := LocaleID;
        TempNewUserSettingsRec."Time Zone" := TimeZone;
        this.UpdateLocalizationSettings(AgentUserSecurityID, TempNewUserSettingsRec);
    end;

    procedure UpdateLocalizationSettings(AgentUserSecurityID: Guid; var NewUserSettingsRec: Record "User Settings")
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

    procedure GetUserSettings(AgentUserSecurityID: Guid; var UserSettingsRec: Record "User Settings")
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

    procedure GetUserName(AgentUserSecurityID: Guid): Code[50]
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        exit(Agent."User Name");
    end;

    procedure GetDisplayName(AgentUserSecurityID: Guid): Text[80]
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        exit(Agent."Display Name")
    end;

    procedure SetDisplayName(AgentUserSecurityID: Guid; DisplayName: Text[80])
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        Agent."Display Name" := DisplayName;
        Agent.Modify(true);
    end;

    procedure IsActive(AgentUserSecurityID: Guid): Boolean
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, AgentUserSecurityID);

        exit(Agent.State = Agent.State::Enabled);
    end;

    procedure UpdateAgentAccessControl(AgentUserSecurityID: Guid; var TempAgentAccessControl: Record "Agent Access Control" temporary)
    var
        Agent: Record Agent;
    begin
        if not Agent.Get(AgentUserSecurityID) then
            Error(AgentDoesNotExistErr);

        UpdateAgentAccessControl(TempAgentAccessControl, Agent);
    end;

    # Region TODO: Update System App signatures to use the codeunit 9175 "User Settings Impl."
    procedure UpdateAgentUserSettings(NewUserSettings: Record "User Settings")
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

    procedure CanShowMonetizationData(): Boolean
    var
        DummyUserAIConsumptionData: Record "User AI Consumption Data";
    begin
        exit(DummyUserAIConsumptionData.ReadPermission());
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
    #endregion

    procedure AssignPermissionSets(var UserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        // Calling system codeunit to allow the assignment of permissions to Agents without SUPER or SECURITY.
        // This method ensure that the user has Configure permission for the specified agent in all the companies
        // for which permissions are modified (both removed and added).
        AgentUtilities.UpdateAccessControl(UserSecurityID, TempAccessControlBuffer);
    end;

    procedure GetPermissionSets(AgentUserSecurityID: Guid; var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        AccessControl: Record "Access Control";
    begin
        TempAccessControlBuffer.Reset();
        TempAccessControlBuffer.DeleteAll();
        AccessControl.SetRange("User Security ID", AgentUserSecurityID);
        if AccessControl.FindSet() then
            repeat
                TempAccessControlBuffer.Copy(AccessControl);
                TempAccessControlBuffer.Insert();
            until AccessControl.Next() = 0;
    end;

    procedure GetAgent(var Agent: Record Agent; UserSecurityID: Guid)
    begin
        if not Agent.Get(UserSecurityID) then
            Error(AgentDoesNotExistErr);
    end;

    local procedure ChangeAgentState(UserSecurityID: Guid; Enabled: Boolean)
    var
        Agent: Record Agent;
    begin
        GetAgent(Agent, UserSecurityId);

        if Enabled then begin
            if Agent.State = Agent.State::Enabled then
                exit;

            Agent.State := Agent.State::Enabled
        end else begin
            if Agent.State = Agent.State::Disabled then
                exit;

            Agent.State := Agent.State::Disabled;
        end;

        Agent.Modify();
    end;

    local procedure UpdateAgentAccessControl(var TempAgentAccessControl: Record "Agent Access Control" temporary; var Agent: Record Agent)
    begin
        // We must delete or update the user doing the change the last to avoid removing permissions that are needed to commit the change
        UpdateAgentAccessControlForUsers(TempAgentAccessControl, Agent, '<>%1', UserSecurityId());

        // Update the user at the end
        UpdateAgentAccessControlForUsers(TempAgentAccessControl, Agent, '%1', UserSecurityId());
    end;

    local procedure UpdateAgentAccessControlForUsers(var TempAgentAccessControl: Record "Agent Access Control" temporary; var Agent: Record Agent; UserSecurityIdFilter: Text; UserSecurityIdValue: Guid)
    var
        AgentAccessControl: Record "Agent Access Control";
    begin
        // Delete any existing records that match the filter and are not in the temp table
        AgentAccessControl.SetRange("Agent User Security ID", Agent."User Security ID");
        AgentAccessControl.SetFilter("User Security ID", UserSecurityIdFilter, UserSecurityIdValue);
        if AgentAccessControl.FindSet() then
            repeat
                if not TempAgentAccessControl.Get(AgentAccessControl."Agent User Security ID", AgentAccessControl."User Security ID", AgentAccessControl."Company Name") then
                    AgentAccessControl.Delete(true);
            until AgentAccessControl.Next() = 0;

        // Insert or update all records from temp table that match the filter
        AgentAccessControl.Reset();
        TempAgentAccessControl.Reset();
        TempAgentAccessControl.SetFilter("User Security ID", UserSecurityIdFilter, UserSecurityIdValue);
        if not TempAgentAccessControl.FindSet() then
            exit;

        repeat
            if AgentAccessControl.Get(Agent."User Security ID", TempAgentAccessControl."User Security ID", TempAgentAccessControl."Company Name") then begin
                AgentAccessControl."Can Configure Agent" := TempAgentAccessControl."Can Configure Agent";
                AgentAccessControl.Modify();
            end else begin
                Clear(AgentAccessControl);
                AgentAccessControl."Agent User Security ID" := Agent."User Security ID";
                AgentAccessControl."User Security ID" := TempAgentAccessControl."User Security ID";
                AgentAccessControl."Company Name" := TempAgentAccessControl."Company Name";
                AgentAccessControl."Can Configure Agent" := TempAgentAccessControl."Can Configure Agent";
                AgentAccessControl.Insert();
            end;
        until TempAgentAccessControl.Next() = 0;
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
        NumberIncrement: Integer;
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
        NumberIncrement := User.Count() + 2;
#pragma warning disable AA0139
        UniqueUserName := AgentNamePrefix + Format(NumberIncrement);
#pragma warning restore AA0139
        User.SetRange("User Name", UniqueUserName);

        while not User.IsEmpty() do begin
            NumberIncrement += 1;
            UniqueUserName := AgentNamePrefix + Format(NumberIncrement);
            User.SetRange("User Name", UniqueUserName);
        end;

        exit(UniqueUserName);
    end;

    procedure OpenSetupPageId(AgentMetadataProvider: Enum "Agent Metadata Provider"; AgentUserSecurityID: Guid)
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

        SetupPageRecordRef.Open(PageMetadata.SourceTable, PageMetadata.SourceTableTemporary);

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

    procedure GetAccessControlForSingleCompany(AgentUserSecurityID: Guid; var SingleCompanyName: Text[30]): Boolean
    var
        TempCompany: Record Company temporary;
        UserSettings: Codeunit "User Settings";
    begin
        UserSettings.GetAllowedCompaniesForUser(AgentUserSecurityID, TempCompany);
        if TempCompany.IsEmpty() then begin
#pragma warning disable AA0139
            SingleCompanyName := CompanyName();
#pragma warning restore AA0139
            exit(true);
        end;

        if TempCompany.Count() <> 1 then
            exit(false);

        SingleCompanyName := TempCompany.Name;
        exit(true);
    end;

    var
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