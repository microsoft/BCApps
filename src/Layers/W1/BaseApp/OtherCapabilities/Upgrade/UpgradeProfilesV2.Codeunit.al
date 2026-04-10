// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Environment;
using System.Environment.Configuration;
using System.IO;
using System.Reflection;
using System.Upgrade;

codeunit 104040 "Upgrade Profiles V2"
{
    // This codeunit runs upgrade from 14.x to 15.0 to make sure we upgrade profiles from the System scope to the Tenant scope.

    Subtype = Upgrade;

    // Upgrade triggers

    trigger OnUpgradePerCompany()
    var
        TenantProfile: Record "Tenant Profile";
        AppProfile: Record "Profile";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDef: Codeunit "Upgrade Tag Definitions";
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        if UpgradeTag.HasUpgradeTag(UpgradeTagDef.GetUpdateProfileReferencesForCompanyTag(), CompanyName) then
            exit;

        Session.LogMessage('0000A31', StrSubstNo('Per-company upgrade of profile references started. System Profiles: %1. Tenant Profiles: %2.', AppProfile.Count(), TenantProfile.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);

        UpdateConfigSetup();

        Session.LogMessage('0000A32', StrSubstNo('Per-company upgrade of profile references finished. System Profiles: %1. Tenant Profiles: %2.', AppProfile.Count(), TenantProfile.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);

        UpgradeTag.SetUpgradeTag(UpgradeTagDef.GetUpdateProfileReferencesForCompanyTag());
    end;

    trigger OnUpgradePerDatabase()
    begin
        UpgradeProfileReferences();
    end;

    local procedure UpgradeProfileReferences()
    var
        TenantProfile: Record "Tenant Profile";
        AppProfile: Record "Profile";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDef: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDef.GetUpdateProfileReferencesForDatabaseTag()) then
            exit;

        Session.LogMessage('0000A33', StrSubstNo('Per-database upgrade of profile references started. System Profiles: %1. Tenant Profiles: %2.', AppProfile.Count(), TenantProfile.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);

        UpdateApplicationAreaSetup();
        UpdateUserPersonalizations();

        Session.LogMessage('0000A34', StrSubstNo('Per-database upgrade of profile references finished. System Profiles: %1. Tenant Profiles: %2.', AppProfile.Count(), TenantProfile.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);

        UpgradeTag.SetUpgradeTag(UpgradeTagDef.GetUpdateProfileReferencesForDatabaseTag());
    end;

    // Table-specific upgrade functions

    local procedure UpdateConfigSetup()
    var
        TenantProfile: Record "Tenant Profile";
        ConfigSetup: Record "Config. Setup";
        SuccessfulModifications: Integer;
        FailedModifications: Integer;
    begin
        ConfigSetup.SetRange("Your Profile Scope", ConfigSetup."Your Profile Scope"::System);
        ConfigSetup.SetFilter("Your Profile Code", '<>%1', '');

        if ConfigSetup.FindSet(true) then
            repeat
                if FindTenantProfileFromAppProfile(ConfigSetup."Your Profile Code", TenantProfile) then begin
                    ConfigSetup."Your Profile App ID" := TenantProfile."App ID";
                    ConfigSetup."Your Profile Code" := TenantProfile."Profile ID";
                    ConfigSetup."Your Profile Scope" := ConfigSetup."Your Profile Scope"::Tenant;
                    if ConfigSetup.Modify() then
                        SuccessfulModifications += 1
                    else begin
                        SendFailedToUpdateProfileReferenceTag(ConfigSetup.TableName, ConfigSetup."Your Profile Code", TenantProfile);
                        FailedModifications += 1;
                    end;
                end else
                    FailedModifications += 1; // Telemetry already raised as part of FindTenantProfileFromAppProfile
            until ConfigSetup.Next() = 0;

        SendProfileReferenceUpdatedTag(SuccessfulModifications, FailedModifications, ConfigSetup.TableName);
    end;

    local procedure UpdateUserPersonalizations()
    var
        UserPersonalization: Record "User Personalization";
        TenantProfile: Record "Tenant Profile";
        SuccessfulModifications: Integer;
        FailedModifications: Integer;
    begin
        UserPersonalization.SetRange(Scope, UserPersonalization.Scope::System);
        UserPersonalization.SetFilter("Profile ID", '<>%1', '');

        if UserPersonalization.FindSet(true) then
            repeat
                if FindTenantProfileFromAppProfile(UserPersonalization."Profile ID", TenantProfile) then begin
                    UserPersonalization."Profile ID" := TenantProfile."Profile ID";
                    UserPersonalization."App ID" := TenantProfile."App ID";
                    UserPersonalization.Scope := UserPersonalization.Scope::Tenant;
                    if UserPersonalization.Modify() then
                        SuccessfulModifications += 1
                    else begin
                        SendFailedToUpdateProfileReferenceTag(UserPersonalization.TableName, UserPersonalization."Profile ID", TenantProfile);
                        FailedModifications += 1;
                    end;
                end else
                    FailedModifications += 1; // Telemetry already raised as part of FindTenantProfileFromAppProfile
            until UserPersonalization.Next() = 0;

        SendProfileReferenceUpdatedTag(SuccessfulModifications, FailedModifications, UserPersonalization.TableName);
    end;

    local procedure UpdateApplicationAreaSetup()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TenantProfile: Record "Tenant Profile";
        SuccessfulModifications: Integer;
        FailedModifications: Integer;
    begin
        ApplicationAreaSetup.SetFilter("Profile ID", '<>%1', '');
        // No scope for the Application Area Setup, the logic for it is implemented in ShouldUpdateProfileIdForApplicationAreaSetup

        if ApplicationAreaSetup.FindSet(true) then
            repeat
                if ShouldUpdateProfileIdForApplicationAreaSetup(ApplicationAreaSetup."Profile ID") then
                    if FindTenantProfileFromAppProfile(ApplicationAreaSetup."Profile ID", TenantProfile) then begin
                        ApplicationAreaSetup."Profile ID" := TenantProfile."Profile ID";
                        if ApplicationAreaSetup.Modify() then
                            SuccessfulModifications += 1
                        else begin
                            SendFailedToUpdateProfileReferenceTag(ApplicationAreaSetup.TableName, ApplicationAreaSetup."Profile ID", TenantProfile);
                            FailedModifications += 1;
                        end;
                    end else
                        FailedModifications += 1; // Telemetry already raised as part of FindTenantProfileFromAppProfile
            until ApplicationAreaSetup.Next() = 0;

        SendProfileReferenceUpdatedTag(SuccessfulModifications, FailedModifications, ApplicationAreaSetup.TableName);
    end;

    // Profile handling functions

    local procedure FindTenantProfileFromAppProfile(SystemProfileId: Code[30]; var TenantProfile: Record "Tenant Profile"): Boolean
    begin
        Clear(TenantProfile);
        if MatchSystemProfileToBaseAppTenantProfile(SystemProfileId, TenantProfile) then
            // The system profile that we referenced is one of the ones we provided as part of demotool. 
            // Those are now AL profiles, and we can match them.
            exit(true);

        if MatchSystemProfileWithAlreadyCreatedTenantProfile(SystemProfileId, TenantProfile) then
            // There is a user-created profile that matches the App Profile.
            // It might be because the user has created it, or because some per-company upgrade ran before this and created it in the user space.
            exit(true);

        if CreateTenantProfileFromAppProfileId(SystemProfileId, TenantProfile) then
            // This means the profile has been created by some partner extension, and we haven't migrated it as part of some other profile upgrade.
            // So we just migrate it to the Tenant scope.
            exit(true);

        // We could neither match a profile nor create one. Raise a telemetry error, as we might have a broken reference, but do not fail upgrade.
        Session.LogMessage('0000A35', StrSubstNo('Could not handle a system profile reference. ProfileID: %1', SystemProfileId), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);

        exit(false);
    end;

    local procedure MatchSystemProfileToBaseAppTenantProfile(AppProfileId: Code[30]; var TenantProfile: Record "Tenant Profile"): Boolean
    var
        BaseAppGuid: Guid;
        NewProfileId: Code[30];
    begin
        // Accountant Portal is provided by an extension that is not installed at the moment. This will update the reference, and in case the 
        //  extension is installed later, the reference will be pointing to an existing profile. If the extension is never installed back, 
        //  this reference will be broken, but this is by design
        if AppProfileId = UpperCase(AccountantPortalTxt) then begin
            TenantProfile."App ID" := 'd612d720-63b9-4b26-b062-a0c09c4ed433';
            TenantProfile."Profile ID" := AccountantPortalLockedTxt;
            exit(true);
        end;

        case AppProfileId of
            UpperCase(OrderProcessorTxt):
                NewProfileId := OrderProcessorLockedTxt;
            UpperCase(BusinessManagerIDTxt):
                NewProfileId := BusinessManagerIDLockedTxt;
            UpperCase(SecurityAdministratorTxt):
                NewProfileId := SecurityAdministratorLockedTxt;
            UpperCase(AccountantTxt):
                NewProfileId := AccountantLockedTxt;
            UpperCase(SalesRlshpMgrIDTxt):
                NewProfileId := SalesRlshpMgrIDLockedTxt;
            UpperCase(O365SalesTxt):
                NewProfileId := O365SalesLockedTxt;
            UpperCase(ProjectManagerTxt):
                NewProfileId := ProjectManagerLockedTxt;
            UpperCase(TeamMemberTxt):
                NewProfileId := TeamMemberLockedTxt;
            UpperCase(InvoicingTxt):
                NewProfileId := InvoicingLockedTxt;
            UpperCase(AccountingManagerTxt):
                NewProfileId := AccountingManagerLockedTxt;
            UpperCase(AccountingServicesTxt):
                NewProfileId := AccountingServicesLockedTxt;
            UpperCase(APCoordinatorTxt):
                NewProfileId := APCoordinatorLockedTxt;
            UpperCase(ARAdministratorTxt):
                NewProfileId := ARAdministratorLockedTxt;
            UpperCase(BookkeeperTxt):
                NewProfileId := BookkeeperLockedTxt;
            UpperCase(DispatcherTxt):
                NewProfileId := DispatcherLockedTxt;
            UpperCase(ITManagerTxt):
                NewProfileId := ITManagerLockedTxt;
            UpperCase(MachineOperatorTxt):
                NewProfileId := MachineOperatorLockedTxt;
            UpperCase(OutboundTechnicianTxt):
                NewProfileId := OutboundTechnicianLockedTxt;
            UpperCase(PresidentTxt):
                NewProfileId := PresidentLockedTxt;
            UpperCase(PresidentSmallBusTxt):
                NewProfileId := PresidentSmallBusLockedTxt;
            UpperCase(ProductionPlannerTxt):
                NewProfileId := ProductionPlannerLockedTxt;
            UpperCase(PurchasingAgentTxt):
                NewProfileId := PurchasingAgentLockedTxt;
            UpperCase(RapidstartServicesTxt):
                NewProfileId := RapidstartServicesLockedTxt;
            UpperCase(ResourceManagerTxt):
                NewProfileId := ResourceManagerTxt;
            UpperCase(SalesManagerTxt):
                NewProfileId := SalesManagerLockedTxt;
            UpperCase(ShippingAndReceivingTxt):
                NewProfileId := ShippingAndReceivingLockedTxt;
            UpperCase(ShippingAndReceivingWMSTxt):
                NewProfileId := ShippingAndReceivingWMSLockedTxt;
            UpperCase(ShopSupervisorTxt):
                NewProfileId := ShopSupervisorLockedTxt;
            UpperCase(ShopSupervisorFoundTxt):
                NewProfileId := ShopSupervisorFoundLockedTxt;
            UpperCase(WHSWorkerWMSTxt):
                NewProfileId := WHSWorkerWMSLockedTxt;
        end;

        BaseAppGuid := '437DBF0E-84FF-417A-965D-ED2BB9650972';

        if NewProfileId = '' then begin
            Session.LogMessage('0000A36', 'Could not match a profile id.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);
            exit(false);
        end;

        if not TenantProfile.Get(BaseAppGuid, NewProfileId) then begin
            Session.LogMessage('0000A37', StrSubstNo('One hardcoded tenant profile is not present: %1.', NewProfileId), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);
            exit(false);
        end;

        exit(true);
    end;

    local procedure MatchSystemProfileWithAlreadyCreatedTenantProfile(AppProfileId: Code[30]; var TenantProfile: Record "Tenant Profile") GetSuccessful: Boolean
    var
        EmptyGuid: Guid;
    begin
        GetSuccessful := TenantProfile.Get(EmptyGuid, AppProfileId);
        if GetSuccessful then
            Session.LogMessage('0000A38', 'Found a tenant profile with the same Id of an app profile.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);

        exit(GetSuccessful);
    end;

    local procedure CreateTenantProfileFromAppProfileId(AppProfileId: Code[30]; var TenantProfile: Record "Tenant Profile") InsertSuccessful: Boolean
    var
        SystemProfile: Record "Profile";
        EmptyGuid: Guid;
    begin
        if not SystemProfile.Get(AppProfileId) then
            exit(false);

        TenantProfile."App ID" := EmptyGuid;
        TenantProfile."Profile ID" := SystemProfile."Profile ID";
        TenantProfile.Description := SystemProfile.Description;
        TenantProfile."Role Center ID" := SystemProfile."Role Center ID";
        TenantProfile."Default Role Center" := SystemProfile."Default Role Center";
        TenantProfile."Disable Personalization" := SystemProfile."Disable Personalization";
        InsertSuccessful := TenantProfile.Insert();

        Session.LogMessage('0000A39', StrSubstNo('Attempted to insert a new tenant profile copied from a system profile. Result: %1.', Format(InsertSuccessful)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);

        exit(InsertSuccessful);
    end;

    // Miscellaneous

    local procedure SendProfileReferenceUpdatedTag(SuccessfulModifications: Integer; FailedModifications: Integer; TableName: Text)
    begin
        Session.LogMessage('0000A3A', StrSubstNo('Attempted to modify %1 references in table "%2". Successful: %3; Failed: %4.', SuccessfulModifications + FailedModifications, TableName, SuccessfulModifications, FailedModifications), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);
    end;

    local procedure SendFailedToUpdateProfileReferenceTag(SourceTableName: Text; PreviousProfileId: Code[30]; TenantProfile: Record "Tenant Profile")
    begin
        Session.LogMessage('0000A3O', StrSubstNo('Failed to modify Profile reference in table %1. Previous profile ID: %2. New profile key: %3, %4.',
                SourceTableName, PreviousProfileId, TenantProfile."Profile ID", TenantProfile."App ID"), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory);
    end;

    local procedure ShouldUpdateProfileIdForApplicationAreaSetup(ProfileId: Code[30]): Boolean
    var
        AllProfile: Record "All Profile";
        SystemProfile: Record "Profile";
    begin
        if SystemProfile.Get(ProfileId) then
            exit(true); // Partner-created profile: let's update references and move it to the tenant scope.


        // We are interested in updating only the references to something that is no longer there, which is our old BaseApp profiles.
        // If there is another profile with the same ID (IsEmpty returns false) there it means either one of:
        //  1 - The Application Area Setup was referencing a Tenant Profile: do not update it.
        //  2 - The Application Area Setup was referencing both a Tenant Profile and a System Profile (the same Application Area Setup
        //      would apply for both). In this case we do not update, because we do not want to break tenant profiles. This might mean 
        //      that the Application Area Setup is no longer applied to the System Profile.

        // Update only if AllProfile is empty
        AllProfile.SetRange("Profile ID", ProfileId);
        exit(AllProfile.IsEmpty());
    end;

    var
#pragma warning disable AA0074
        TelemetryCategory: Label 'AL Upg Profiles', Locked = true;
#pragma warning restore AA0074

    // Profile IDs that are LOCKED (must match profiles in the Tenant scope added by AL objects)
    var
        AccountantLockedTxt: Label 'Accountant', Locked = true;
        OrderProcessorLockedTxt: Label 'Order Processor', Locked = true;
        SecurityAdministratorLockedTxt: Label 'Security Administrator', Locked = true;
        BusinessManagerIDLockedTxt: Label 'Business Manager', Locked = true;
        SalesRlshpMgrIDLockedTxt: Label 'Sales and Relationship Manager', Locked = true;
        O365SalesLockedTxt: Label 'O365 Sales', Locked = true;
        ProjectManagerLockedTxt: Label 'PROJECT MANAGER', Locked = true;
        TeamMemberLockedTxt: Label 'TEAM MEMBER', Locked = true;
        InvoicingLockedTxt: Label 'Invoicing', Locked = true;
        AccountantPortalLockedTxt: Label 'Accountant Portal', Locked = true;
        AccountingManagerLockedTxt: Label 'Accounting Manager', Locked = true;
        AccountingServicesLockedTxt: Label 'Accounting Services', Locked = true;
        APCoordinatorLockedTxt: Label 'AP Coordinator', Locked = true;
        ARAdministratorLockedTxt: Label 'AR Administrator', Locked = true;
        BookkeeperLockedTxt: Label 'Bookkeeper', Locked = true;
        DispatcherLockedTxt: Label 'Dispatcher', Locked = true;
        ITManagerLockedTxt: Label 'IT Manager', Locked = true;
        MachineOperatorLockedTxt: Label 'Machine Operator', Locked = true;
        OutboundTechnicianLockedTxt: Label 'Outbound Technician', Locked = true;
        PresidentLockedTxt: Label 'President', Locked = true;
        PresidentSmallBusLockedTxt: Label 'President - Small Business', Locked = true;
        ProductionPlannerLockedTxt: Label 'Production Planner', Locked = true;
        PurchasingAgentLockedTxt: Label 'Purchasing Agent', Locked = true;
        RapidstartServicesLockedTxt: Label 'RapidStart Services', Locked = true;
        SalesManagerLockedTxt: Label 'Sales Manager', Locked = true;
        ShippingAndReceivingLockedTxt: Label 'Shipping and Receiving', Locked = true;
        ShippingAndReceivingWMSLockedTxt: Label 'Shipping and Receiving - WMS', Locked = true;
        ShopSupervisorLockedTxt: Label 'Shop Supervisor', Locked = true;
        ShopSupervisorFoundLockedTxt: Label 'Shop Supervisor - Foundation', Locked = true;
        WHSWorkerWMSLockedTxt: Label 'Warehouse Worker - WMS', Locked = true;

    // Same IDs, but not locked (translations must match the app profiles inserted until 14.x)
    var
        AccountantTxt: Label 'Accountant';
        OrderProcessorTxt: Label 'Order Processor';
        SecurityAdministratorTxt: Label 'Security Administrator';
        BusinessManagerIDTxt: Label 'Business Manager';
        SalesRlshpMgrIDTxt: Label 'Sales and Relationship Manager';
        O365SalesTxt: Label 'O365 Sales';
        ProjectManagerTxt: Label 'PROJECT MANAGER';
        TeamMemberTxt: Label 'TEAM MEMBER';
        InvoicingTxt: Label 'Invoicing';
        AccountantPortalTxt: Label 'Accountant Portal';
        AccountingManagerTxt: Label 'Accounting Manager';
        AccountingServicesTxt: Label 'Accounting Services';
        APCoordinatorTxt: Label 'AP Coordinator';
        ARAdministratorTxt: Label 'AR Administrator';
        BookkeeperTxt: Label 'Bookkeeper';
        DispatcherTxt: Label 'Dispatcher';
        ITManagerTxt: Label 'IT Manager';
        MachineOperatorTxt: Label 'Machine Operator';
        OutboundTechnicianTxt: Label 'Outbound Technician';
        PresidentTxt: Label 'President';
        PresidentSmallBusTxt: Label 'President - Small Business';
        ProductionPlannerTxt: Label 'Production Planner';
        PurchasingAgentTxt: Label 'Purchasing Agent';
        RapidstartServicesTxt: Label 'RapidStart Services';
        ResourceManagerTxt: Label 'Resource Manager';
        SalesManagerTxt: Label 'Sales Manager';
        ShippingAndReceivingTxt: Label 'Shipping and Receiving';
        ShippingAndReceivingWMSTxt: Label 'Shipping and Receiving - WMS';
        ShopSupervisorTxt: Label 'Shop Supervisor';
        ShopSupervisorFoundTxt: Label 'Shop Supervisor - Foundation';
        WHSWorkerWMSTxt: Label 'Warehouse Worker - WMS';
}