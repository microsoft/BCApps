// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using System;
using System.Environment;
using System.Environment.Configuration;
using System.Media;
using System.Reflection;
using System.Telemetry;
using System.Threading;
using System.Utilities;
#if not CLEAN25
using Microsoft.Integration.FieldService;
#endif
using System.Apps;

codeunit 5330 "CRM Integration Management"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Sales Invoice Header" = rm,
                  tabledata "CDS Connection Setup" = r,
                  tabledata "CRM Connection Setup" = r;

    trigger OnRun()
    begin
        CheckOrEnableCRMConnection();
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";

        CachedCoupledToCRMFieldNo: Dictionary of [Integer, Integer];
        CachedDisableEventDrivenSynchJobReschedule: Dictionary of [Integer, Boolean];
        CachedIsCRMIntegrationRecord: Dictionary of [Integer, Boolean];
        CachedDoesJobActOnTable: Dictionary of [Text, Boolean];
        CRMEntityUrlTemplateTxt: Label '%1/main.aspx?pagetype=entityrecord&etn=%2&id=%3', Locked = true;
        NewestUIAppIdParameterTxt: Label '&appid=%1', Locked = true;
        UnableToResolveCRMEntityNameFrmTableIDErr: Label 'The application is not designed to integrate table %1 with %2.', Comment = '%1 = table ID (numeric), %2 = Dataverse service name';
        CouplingNotFoundErr: Label 'The record is not coupled to %1.', Comment = '%1 = Dataverse service name';
        NoCardPageActionDefinedForTableIdErr: Label 'The open page action is not supported for Table %1.', Comment = '%1 = Table ID';
        IntegrationTableMappingNotFoundErr: Label 'No %1 was found for table %2.', Comment = '%1 = Integration Table Mapping caption, %2 = Table caption for the table which is not mapped';
        UpdateNowUniDirectionQst: Label 'Send data update to Dataverse.,Get data update from Dataverse.';
        UpdateNowBiDirectionQst: Label 'Send data update to Dataverse.,Get data update from Dataverse.,Merge data.';
        UpdateOneNowTitleTxt: Label 'Synchronize data for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now.';
        UpdateMultipleNowTitleTxt: Label 'Synchronize data for the selected records?';
        ManageCouplingQst: Label 'The %1 record is not coupled to %2. Do you want to create a coupling?', Comment = '%1=The record caption (type), %2 = Dataverse service name';
        SyncNowFailedMsg: Label 'The synchronization failed.';
        SyncNowScheduledMsg: Label 'The synchronization has been scheduled.';
        SyncNowSkippedMsg: Label 'The synchronization has been skipped.';
        SyncMultipleMsg: Label 'The synchronization has been scheduled for %1 of %4 records. %2 records failed. %3 records were skipped.', Comment = '%1,%2,%3,%4 are numbers of records';
        SyncSkippedMsg: Label 'The record will be skipped for further synchronization due to a repeatable failure.';
        SyncRestoredMsg: Label 'The record has been restored for synchronization.';
        SyncMultipleRestoredMsg: Label '%1 records have been restored for synchronization.', Comment = '%1 - an integer, a count of records.';
        UncoupleFailedMsg: Label 'The uncoupling failed.';
        UncoupleScheduledMsg: Label 'The uncoupling has been scheduled.';
        UncoupleSkippedMsg: Label 'The uncoupling has been skipped.';
        UncoupleMultipleMsg: Label 'The uncoupling has been scheduled for %1 of %4 records. %2 records failed. %3 records were skipped.', Comment = '%1,%2,%3,%4 are numbers of records';
        CouplingFailedMsg: Label 'The coupling failed.';
        CouplingScheduledMsg: Label 'The coupling has been scheduled.';
        CouplingSkippedMsg: Label 'The coupling has been skipped.';
        CouplingMultipleMsg: Label 'The coupling has been scheduled for %1 of %4 records. %2 records failed. %3 records were skipped.', Comment = '%1,%2,%3,%4 are numbers of records';
        DetailsTxt: Label 'Details.';
        UpdateOneNowToCRMQst: Label 'Send data update to %2 for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now., %2 = Dataverse service name';
        UpdateOneNowToModifiedCRMQst: Label 'The %3 record coupled to %1 contains newer data than the %2 record. Do you want to overwrite the data in %3?', Comment = '%1 = Table caption and value for the entity we want to synchronize now. %2 - product name, %3 = Dataverse service name';
        UpdateOneNowFromCRMQst: Label 'Get data update from %2 for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now., %2 = Dataverse service name';
        UpdateOneNowFromOldCRMQst: Label 'The %2 record %1 contains newer data than the %3 record. Get data update from %3, overwriting data in %2?', Comment = '%1 = Table caption and value for the entity we want to synchronize now. %2 - product name, %3 = Dataverse service name';
        UpdateMultipleNowToCRMQst: Label 'Send data update to %1 for the selected records?', Comment = '%1 = Dataverse service name';
        UpdateMultipleNowFromCRMQst: Label 'Get data update from %1 for the selected records?', Comment = '%1 = Dataverse service name';
        AccountStatisticsUpdatedMsg: Label 'The customer statistics have been successfully updated in %1.', Comment = '%1 = Dataverse service name';
        BothRecordsModifiedBiDirectionalConflictMsg: Label 'Both the %1 record and the %3 %2 record have been changed since the last synchronization, or synchronization has never been performed. Bi-directional synchronization is forbidden as a changed bidirectional field was detected, but you can continue continue with uni-derictional synchronization. If you continue, data on one of the records will be lost and replaced with data from the other record.', Comment = '%1 and %2 area captions of tables such as Customer and CRM Account, %3 = Dataverse service name';
        BothRecordsModifiedBiDirectionalNoConflictMsg: Label 'Both the %1 record and the %3 %2 record have been changed since the last synchronization, or synchronization has never been performed. No one changed bidirectional field was detected, therefore you can continue continue with both bi- and uni-directional synchronization. If you continue, data will be updated in accordance with the chosen synchronization direction and fields mapping.', Comment = '%1 and %2 area captions of tables such as Customer and CRM Account, %3 = Dataverse service name';
        BothRecordsModifiedToCRMQst: Label 'Both %1 and the %4 %2 record have been changed since the last synchronization, or synchronization has never been performed. If you continue with synchronization, data in %4 will be overwritten with data from %3. Are you sure you want to synchronize?', Comment = '%1 is a formatted RecordID, such as ''Customer 1234''. %2 is the caption of a Dataverse table. %3 - product name, %4 = Dataverse service name';
        BothRecordsModifiedToNAVQst: Label 'Both %1 and the %4 %2 record have been changed since the last synchronization, or synchronization has never been performed. If you continue with synchronization, data in %3 will be overwritten with data from %4. Are you sure you want to synchronize?', Comment = '%1 is a formatted RecordID, such as ''Customer 1234''. %2 is the caption of a Dataverse table. %3 - product name, %4 = Dataverse service name';
        CRMIntegrationEnabledState: Option " ","Not Enabled",Enabled,"Enabled But Not For Current User";
        CDSIntegrationEnabledState: Option " ","Not Enabled",Enabled,"Enabled But Not For Current User";
#if not CLEAN25
        FSIntegrationEnabledState: Option " ","Not Enabled",Enabled,"Enabled But Not For Current User";
#endif
        NotEnabledForCurrentUserMsg: Label '%3 Integration is enabled.\However, because the %2 Users Must Map to %4 Users field is set, %3 integration is not enabled for %1.', Comment = '%1 = Current User Id %2 - product name, %3 = CRM product name, %4 = Dataverse service name';
        CRMIntegrationEnabledLastError: Text;
        ImportSolutionConnectStringTok: Label '%1api%2/XRMServices/2011/Organization.svc', Locked = true;
        UserDoesNotExistCRMErr: Label 'There is no user with email address %1 in %2. Enter a valid email address.', Comment = '%1 = User email address, %2 = Dataverse service name';
        EmailAndServerAddressEmptyErr: Label 'The Integration User Email and Server Address fields must not be empty.';
        CRMSolutionFileNotFoundErr: Label 'A file for a CRM solution could not be found.';
        MicrosoftDynamicsNavIntegrationTxt: Label 'MicrosoftDynamicsNavIntegration', Locked = true;
#if not CLEAN25
        MicrosoftDynamicsFSIntegrationTxt: Label 'bcbi_FieldServiceIntegration', Locked = true;
#endif
        AdminEmailPasswordWrongErr: Label 'Enter valid %1 administrator credentials.', Comment = '%1 = CRM product name';
        OrganizationServiceFailureErr: Label 'The setup failed due to a generic error. Please sign in to the Dataverse organization with an account that has the System Administrator role. Ensure that no other import or deletion of a PowerApps solution is currently in progress. Additionally, verify that the solution file is not broken and that the specified administrator has sufficient privileges.';
        InvalidUriErr: Label 'The value entered is not a valid URL.';
        MustUseHttpsErr: Label 'The application is set up to support secure connections (HTTPS) to %1 only. You cannot use HTTP.', Comment = '%1 = CRM product name';
        MustUseHttpOrHttpsErr: Label '%1 is not a valid URI scheme for %2 connections. You can only use HTTPS or HTTP as the scheme in the URL.', Comment = '%1 is a URI scheme, such as FTP, HTTP, chrome or file, %2 = CRM product name';
        ReplaceServerAddressQst: Label 'The URL is not valid. Do you want to replace it with the URL suggested below?\\Entered URL: "%1".\Suggested URL: "%2".', Comment = '%1 and %2 are URLs';
        CRMConnectionURLWrongErr: Label 'The URL is incorrect. Enter the URL for the %1 connection.', Comment = '%1 = CRM product name';
        NoOf: Option ,Scheduled,Failed,Skipped,Total;
        NotEnabledMsg: Label 'To perform this action you must be connected to %1. You can set up the connection to %1 from the %2 page. Do you want to open it now?', Comment = '%1 = Dataverse service name, %2 = Assisted Setup page caption.';
        ConnectionStringFormatTok: Label 'Url=%1; UserName=%2; Password=%3; ProxyVersion=%4; %5', Locked = true;
        OAuthConnectionStringFormatTok: Label 'Url=%1; AccessToken=%2; ProxyVersion=%3; %4', Locked = true;
        CRMDisabledErrorReasonNotificationIdTxt: Label 'd82835d9-a005-451a-972b-0d6532de2072';
        ConnectionBrokenMsg: Label 'The connection to Dynamics 365 Sales is disabled due to the following error: %1.\\Please contact your system administrator.', Comment = '%1 = Error text received from D365 for Sales';
        ConnectionDisabledNotificationMsg: Label 'Connection to Dynamics 365 is broken and that it has been disabled due to an error: %1', Comment = '%1 = Error text received from D365 for Sales';
        CRMConnectionSetupTxt: Label 'Set up %1 connection', Comment = '%1 = CRM product name';
        VideoUrlSetupCRMConnectionTxt: Label '', Locked = true;
        ConnectionDisabledReasonTxt: Label 'The connection to %1 was disabled because integration user %2 has insufficient privileges to run the synchronization.', Comment = '%1 = a URL, %2 - an email address';
        CannotAssignRoleToTeamErr: Label 'Cannot assign role %3 to team %1 for business unit %2.', Comment = '%1 = team name, %2 = business unit name, %3 = security role name';
        CannotAssignRoleToTeamTxt: Label 'Cannot assign role to team.', Locked = true;
        IntegrationRoleNotFoundErr: Label 'There is no integration role %1 for business unit %2.', Comment = '%1 = role name, %2 = business unit name';
        TeamNotFoundErr: Label 'Cannot find the default owning team for the coupled business unit %1 selected on page %2. To continue, you can select another business unit or revert to the default business unit that was created during setup.', Comment = '%1 = business unit name, %2 = setup page caption';
        TeamNotFoundTxt: Label 'The team was not found.', Locked = true;
        RoleNotFoundForBusinessUnitTxt: Label 'Integration role is not found for business unit.', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        TimeoutTxt: Label 'timeout', Locked = true;
        RetryAfterTimeoutErr: Label 'The operation timed out. Try again.\\%1', Comment = '%1 - exception message ';
        ConnectionFailureTxt: Label 'Connection failure.', Locked = true;
        DisableIntegrationTxt: Label 'Disable integration.', Locked = true;
        ClearDisabledReasonTxt: Label 'Clear disabled reason.', Locked = true;
        IntegrationDisabledTxt: Label 'Integration is disabled.', Locked = true;
        IntegrationNotConfiguredTxt: Label 'Integration is not configured.', Locked = true;
        NoPermissionsTxt: Label 'No permissions.', Locked = true;
        NotLocalTableTxt: Label 'Table %1 is not local.', Locked = true;
        UpdateConflictHandledFromIntTxt: Label 'Update conflict handled by getting update from Dynamics 365 Sales.', Locked = true;
        UpdateConflictHandledToIntTxt: Label 'Update conflict handled by sending update to Dynamics 365 Sales.', Locked = true;
        UpdateConflictHandledSkipTxt: Label 'Update conflict handled by skipping the updated record.', Locked = true;
        DeletionConflictHandledRemoveCouplingTxt: Label 'Deletion conflict handled by removing the coupling to the deleted record.', Locked = true;
        DeletionConflictHandledRestoreRecordTxt: Label 'Deletion conflict handled by restoring the deleted record.', Locked = true;
        ResetAllCustomIntegrationTableMappingsLbl: Label 'One or more of the selected integration table mappings is custom.\\Restoring the default table mapping for a custom table mapping will restore all custom table mappings to their default.\\Do you want to continue?';
        DeletedRecordWithZeroTableIdTxt: Label 'CRM Integration Record with zero Table ID has been deleted. Integration ID: %1, CRM ID: %2', Locked = true;
        AllRecordsMarkedAsSkippedTxt: Label 'All of selected %1 records are marked as skipped.', Comment = '%1 = table caption';
        RecordMarkedAsSkippedTxt: Label 'The %1 record is marked as skipped.', Comment = '%1 = table caption';
        AllRecordsAlreadyCoupledTxt: Label 'All of the selected records are already coupled.', Comment = '%1 = table caption';
        RecordAlreadyCoupledTxt: Label 'The record is already coupled.', Comment = '%1 = table caption';
        DetailedNotificationMessageTxt: Label '%1 %2', Comment = '%1 - notification message, %2 - details', Locked = true;
        CommonNotificationNameTxt: Label 'Notify the user about scheduled Dataverse synchronization jobs.', Comment = 'Dataverse is a name of a Microsoft service and must not be translated.';
        SkippedRecordsNotificationNameTxt: Label 'Notify the user about records that are skipped during Dataverse synchronization jobs.', Comment = 'Dataverse is a name of a Microsoft service and must not be translated.';
        CommonNotificationDescriptionTxt: Label 'Turns the user''s attention to the Integration Synchronization Jobs page.';
        SkippedRecordsNotificationDescriptionTxt: Label 'Turns the user''s attention to the Coupled Data Synchronization Errors page.';
        UserDisabledNotificationTxt: Label 'The user disabled notification ''%1''.', Locked = true;
        DisableNotificationTxt: Label 'Disable this notification.';
        UserOpenedIntegrationSynchJobListViaNotificationTxt: Label 'User opened Integration Synchronization Pobs via the notification.', Locked = true;
        BrokenCouplingsFoundAndMarkedAsSkippedForMappingTxt: Label 'Broken couplings were found and marked as skipped. Mapping: %1 - %2. Direction: %3. Count: %4.', Locked = true;
        BrokenCouplingsFoundAndMarkedAsSkippedTotalTxt: Label 'Broken couplings were found and marked as skipped. Total count: %1.', Locked = true;
        NoBrokenCouplingsFoundTxt: Label 'No broken couplings were found.', Locked = true;
        AccountRelationshipTypeNotSupportedErr: Label 'Dynamics 365 Sales account should have relationship type of Customer or Vendor.';
        ProductTypeNotSupportedErr: Label 'Dynamics 365 Sales product should have type of Sales Inventory or Services.';
        UpdateUnitGroupMappingJQEDescriptionTxt: Label 'Updating CRM Unit Group Mapping';
        RescheduledTaskTxt: label 'Rescheduled task %1 for Job Queue Entry %2 (%3) to run not before %4', Locked = true;
        SalesProDefaultSettingsPrivilegeNameTxt: label 'prvReadmsdynce_salesprodefaultsettings', Locked = true;
        SalesProIntegrationSolutionImportedTxt: label 'Integration solution for Sales Professional is imported.', Locked = true;
        CompanyParameterTok: label '?company=', Locked = true;
        MultipleCompanyLinkLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2259003', Locked = true;
#if not CLEAN25
        FieldServiceAdministratorProfileIdLbl: label '8d988915-e392-e111-9d8c-000c2959f9b8', Locked = true;
        CannotAssignFieldSecurityProfileToUserTelemetryLbl: Label 'Cannot assign field security profile to integration user.', Locked = true;
        CannotAssignFieldSecurityProfileToUserQst: Label 'To enable the setup, you must sign in to %1 as administrator and assign the column security profile "Field Service - Administrator" to the Business Central integration user. Do you want to open the Business Central integration user card in %1?', Comment = '%1 - Dataverse environment URL';
#endif
        FSIntegrationAppSourceLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2277825', Locked = true;
        FieldServiceIntegrationAppIdLbl: Label '1ba1031e-eae9-4f20-b9d2-d19b6d1e3f29', Locked = true;

    procedure IsCRMIntegrationEnabled(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.ReadPermission() then
            exit(false);

        if CRMIntegrationEnabledState = CRMIntegrationEnabledState::" " then begin
            ClearLastError();
            CRMIntegrationEnabledState := CRMIntegrationEnabledState::"Not Enabled";
            Clear(CRMIntegrationEnabledLastError);
            if CRMConnectionSetup.Get() then begin
                CRMConnectionSetup.RestoreConnection();
                if CRMConnectionSetup."Is Enabled" then begin
                    if not HasTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM)) then
                        CRMConnectionSetup.RegisterConnection();
                    CRMIntegrationEnabledState := CRMIntegrationEnabledState::Enabled;
                    OnAfterCRMIntegrationEnabled();
                end;
            end;
        end;

        exit(CRMIntegrationEnabledState = CRMIntegrationEnabledState::Enabled);
    end;

    procedure IsCDSIntegrationEnabled(): Boolean
    var
        isEnabled: Boolean;
        initConnectionHandled: Boolean;
        ConnectionName: text;
    begin
        OnIsCDSIntegrationEnabled(isEnabled);
        if isEnabled then begin
            OnInitCDSConnection(ConnectionName, initConnectionHandled);
            CDSIntegrationEnabledState := CDSIntegrationEnabledState::Enabled;
        end else
            CDSIntegrationEnabledState := CDSIntegrationEnabledState::"Not Enabled";

        exit(isEnabled);
    end;

    [Scope('OnPrem')]
    procedure IsIntegrationEnabled(): Boolean
    var
        CRMConnectionSentup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSentup.ReadPermission() then
            exit(false);

        if not CRMConnectionSentup.Get() then
            exit(false);

        if not CRMConnectionSentup."Is Enabled" then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCDSIntegrationEnabled(var isEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnInitCDSConnection(var ConnectionName: Text; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetCDSIntegrationUserId(var IntegrationUserId: Guid; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetCDSServerAddress(var CDSServerAddress: Text; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnTestCDSConnection(var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCloseCDSConnection(ConnectionName: Text; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCRMIntegrationEnabled()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenRecordCardPage(RecordID: RecordID; var IsHandled: Boolean)
    begin
    end;

    procedure IsCRMSolutionInstalled(): Boolean
    begin
        if TryTouchCRMSolutionEntities() then
            exit(true);

        ClearLastError();
        exit(false);
    end;

#if not CLEAN25
    internal procedure IsFSSolutionInstalled(): Boolean
    begin
        if TryTouchFSSolutionEntities() then
            exit(true);

        ClearLastError();
        exit(false);
    end;
#endif

    [Scope('OnPrem')]
    procedure CheckSolutionVersionOutdated(): Boolean
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        Version: DotNet Version;
        SolutionVersion: Text;
    begin
        if CDSIntegrationMgt.GetSolutionVersion(MicrosoftDynamicsNavIntegrationTxt, SolutionVersion) then
            if Version.TryParse(SolutionVersion, Version) then
                exit(Version.CompareTo(NavTenantSettingsHelper.GetPlatformVersion()) < 0);
        exit(true);
    end;

    [TryFunction]
    local procedure TryTouchCRMSolutionEntities()
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        CRMAccountStatistics: Record "CRM Account Statistics";
        Cnt: Integer;
    begin
        Cnt := CRMAccountStatistics.Count();
        Cnt := CRMNAVConnection.Count();
        if Cnt > 0 then
            exit;
    end;

#if not CLEAN25
    [TryFunction]
    local procedure TryTouchFSSolutionEntities()
    var
        FSProjectTask: Record "FS Project Task";
        Cnt: Integer;
    begin
        Cnt := FSProjectTask.Count();
        if Cnt > 0 then
            exit;
    end;
#endif

    procedure SetCRMNAVConnectionUrl(WebClientUrl: Text[250])
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        HttpUtility: DotNet HttpUtility;
        NewConnection: Boolean;
    begin
        if StrPos(WebClientUrl, CompanyParameterTok) = 0 then
            WebClientUrl += CompanyParameterTok + HttpUtility.UrlPathEncode(CompanyName());

        CRMNAVConnection.SetRange("Dynamics NAV URL", WebClientUrl);
        if not CRMNAVConnection.FindFirst() then begin
            CRMNAVConnection.Init();
            NewConnection := true;
        end;

        CRMNAVConnection."Dynamics NAV URL" := WebClientUrl;
        CRMNAVConnection.Name := CopyStr(CompanyName(), 1, MaxStrLen(CRMNAVConnection.Name));

        if NewConnection then
            CRMNAVConnection.Insert()
        else
            CRMNAVConnection.Modify();
    end;

    internal procedure RemoveCRMNAVConnectionUrl(WebClientUrl: Text[250]): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Is Enabled" then
                exit(TryRemoveCRMNAVConnectionUrl(CRMConnectionSetup, WebClientUrl));
    end;

    [TryFunction]
    local procedure TryRemoveCRMNAVConnectionUrl(var CRMConnectionSetup: Record "CRM Connection Setup"; WebClientUrl: Text[250])
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        HttpUtility: DotNet HttpUtility;
    begin
        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Is Enabled" then begin
                if not HasTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM)) then
                    CRMConnectionSetup.RegisterConnection();

                if StrPos(WebClientUrl, CompanyParameterTok) = 0 then
                    WebClientUrl += CompanyParameterTok + HttpUtility.UrlPathEncode(CompanyName());

                CRMNAVConnection.SetRange("Dynamics NAV URL", WebClientUrl);
                if not CRMNAVConnection.FindFirst() then
                    exit;

                CRMNAVConnection.Delete();
            end;
    end;

    procedure UpdateMultipleNow(RecVariant: Variant)
    begin
        UpdateMultipleNow(RecVariant, false);
    end;

    procedure UpdateMultipleNow(RecVariant: Variant; IsOption: Boolean)
    var
        RecRef: RecordRef;
        RecordCounter: array[4] of Integer;
    begin
        RecordCounter[NoOf::Total] := GetRecordRef(RecVariant, RecRef);
        if RecordCounter[NoOf::Total] = 0 then
            exit;

        if RecRef.Number = DATABASE::"CRM Integration Record" then
            UpdateCRMIntRecords(RecRef, RecordCounter)
        else
            if IsOption then
                UpdateOptions(RecRef, RecordCounter)
            else
                UpdateRecords(RecRef, RecordCounter);
    end;

    local procedure UpdateCRMIntRecords(var RecRef: RecordRef; var RecordCounter: array[4] of Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceRecRef: RecordRef;
        RecId: RecordId;
        SelectedDirection: Integer;
        Direction: Integer;
        Unused: Boolean;
        LocalTableId: Integer;
        MappingName: Code[20];
        RecordCount: Integer;
        TotalCount: Integer;
        IdFilter: Text;
        IdFilterList: List of [Text];
        LocalTableList: List of [Integer];
        LocalIdList: List of [Guid];
        CRMIdList: List of [Guid];
        MappingDictionary: Dictionary of [Integer, Code[20]];
        LocalIdDictionary: Dictionary of [Code[20], List of [Guid]];
        CRMIdDictionary: Dictionary of [Code[20], List of [Guid]];
        TableCaption: Text;
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            RecRef.SetTable(CRMIntegrationRecord);
            LocalTableId := CRMIntegrationRecord."Table ID";
            CRMIntegrationRecord.FindRecordId(RecId);
            GetIntegrationTableMapping(IntegrationTableMapping, RecId);
            SourceRecRef.Get(RecId);
            SelectedDirection :=
              GetSelectedSingleSyncDirection(IntegrationTableMapping, SourceRecRef, CRMIntegrationRecord."CRM ID", Unused)
        end else begin
            IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
            SelectedDirection := GetSelectedMultipleSyncDirection(IntegrationTableMapping);
        end;
        if SelectedDirection < 0 then
            exit; // The user cancelled

        repeat
            RecRef.SetTable(CRMIntegrationRecord);
            CRMIntegrationRecord.FindRecordId(RecId);
            LocalTableId := CRMIntegrationRecord."Table ID";
            if not MappingDictionary.ContainsKey(LocalTableId) then begin
                GetIntegrationTableMapping(IntegrationTableMapping, RecId);
                MappingDictionary.Add(LocalTableId, IntegrationTableMapping.Name);
            end;
            MappingName := MappingDictionary.Get(LocalTableId);
            if not LocalIdDictionary.ContainsKey(MappingName) then begin
                Clear(LocalIdList);
                LocalIdDictionary.Add(MappingName, LocalIdList);
            end;
            if not CRMIdDictionary.ContainsKey(MappingName) then begin
                Clear(CRMIdList);
                CRMIdDictionary.Add(MappingName, CRMIdList);
            end;
            LocalIdList := LocalIdDictionary.Get(MappingName);
            CRMIdList := CRMIdDictionary.Get(MappingName);
            LocalIdList.Add(CRMIntegrationRecord."Integration ID");
            CRMIdList.Add(CRMIntegrationRecord."CRM ID");
            TotalCount += 1;
        until RecRef.Next() = 0;

        if TotalCount = 0 then begin
            if MappingDictionary.Keys().Count() = 1 then
                TableCaption := GetTableCaption(MappingDictionary.Keys().Get(1));
            if RecordCounter[NoOf::Total] > 1 then
                SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, StrSubstNo(AllRecordsMarkedAsSkippedTxt, TableCaption)))
            else
                SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, StrSubstNo(RecordMarkedAsSkippedTxt, TableCaption)));
            exit;
        end;

        LocalTableList := MappingDictionary.Keys();
        foreach LocalTableId in LocalTableList do begin
            MappingName := MappingDictionary.Get(LocalTableId);
            LocalIdList := LocalIdDictionary.Get(MappingName);
            RecordCount := LocalIdList.Count();
            if RecordCount > 0 then begin
                CRMIdList := CRMIdDictionary.Get(MappingName);
                IntegrationTableMapping.Get(MappingName);
                if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional then
                    Direction := SelectedDirection
                else
                    Direction := IntegrationTableMapping.Direction;
                if EnqueueSyncJob(IntegrationTableMapping, LocalIdList, CRMIdList, Direction, false) then begin
                    IntegrationRecordSynch.GetIdFilterList(LocalIdList, IdFilterList);
                    foreach IdFilter in IdFilterList do
                        if IdFilter <> '' then begin
                            CRMIntegrationRecord.SetFilter("Integration ID", IdFilter);
                            CRMIntegrationRecord.ModifyAll(Skipped, false);
                        end;
                    RecordCounter[NoOf::Scheduled] += RecordCount;
                end else
                    RecordCounter[NoOf::Failed] += RecordCount;
            end;
        end;

        SendSyncNotification(RecordCounter);
    end;

    local procedure UpdateRecords(var LocalRecordRef: RecordRef; var RecordCounter: array[4] of Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SelectedDirection: Integer;
        CRMID: Guid;
        Unused: Boolean;
        Skipped: Boolean;
        RecordCount: Integer;
        LocalId: Guid;
        LocalIdList: List of [Guid];
        CRMIdList: List of [Guid];
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, LocalRecordRef.RecordId());

        if RecordCounter[NoOf::Total] = 1 then
            if GetCoupledCRMID(LocalRecordRef.RecordId(), CRMID) then
                SelectedDirection :=
                  GetSelectedSingleSyncDirection(IntegrationTableMapping, LocalRecordRef, CRMID, Unused)
            else begin
                DefineCouplingIfNotCoupled(LocalRecordRef.RecordId(), CRMID);
                exit;
            end
        else
            SelectedDirection := GetSelectedMultipleSyncDirection(IntegrationTableMapping);
        if SelectedDirection < 0 then
            exit; // The user cancelled

        repeat
            Skipped := false;
            if RecordCounter[NoOf::Total] > 1 then begin
                Skipped := not GetCoupledCRMID(LocalRecordRef.RecordId(), CRMID);
                if not Skipped then
                    Skipped := WasRecordModifiedAfterLastSynch(IntegrationTableMapping, LocalRecordRef, CRMID, SelectedDirection);
            end;
            if not Skipped then
                Skipped := IsRecordSkipped(LocalRecordRef.RecordId());
            if Skipped then
                RecordCounter[NoOf::Skipped] += 1
            else begin
                LocalId := LocalRecordRef.Field((LocalRecordRef.SystemIdNo())).Value();
                LocalIdList.Add(LocalId);
                CRMIdList.Add(CRMID);
            end;
        until LocalRecordRef.Next() = 0;

        RecordCount := LocalIdList.Count();
        if RecordCount = 0 then begin
            if RecordCounter[NoOf::Total] > 1 then
                SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, StrSubstNo(AllRecordsMarkedAsSkippedTxt, GetTableCaption(LocalRecordRef.Number()))))
            else
                SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, StrSubstNo(RecordMarkedAsSkippedTxt, GetTableCaption(LocalRecordRef.Number()))));
            exit;
        end;

        if EnqueueSyncJob(IntegrationTableMapping, LocalIdList, CRMIdList, SelectedDirection, IntegrationTableMapping."Synch. Only Coupled Records") then
            RecordCounter[NoOf::Scheduled] += RecordCount
        else
            RecordCounter[NoOf::Failed] += RecordCount;

        SendSyncNotification(RecordCounter);
    end;

    local procedure UpdateOptions(var RecRef: RecordRef; var RecordCounter: array[4] of Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMOptionMapping: Record "CRM Option Mapping";
        SelectedDirection: Integer;
        CRMOptionId: Integer;
        CRMOptionIds: List of [Integer];
        LocalIds: List of [Guid];
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, RecRef.RecordId());

        if RecordCounter[NoOf::Total] = 1 then
            if not GetMappedCRMOptionId(RecRef.RecordId(), CRMOptionId) then begin
                DefineOptionMappingIfNotMapped(RecRef.RecordId(), CRMOptionId);
                exit;
            end;

        SelectedDirection := GetSelectedMultipleSyncDirection(IntegrationTableMapping);
        if SelectedDirection < 0 then
            exit; // The user cancelled

        if SelectedDirection = IntegrationTableMapping.Direction::FromIntegrationTable then begin
            repeat
                if GetMappedCRMOptionId(RecRef.RecordId(), CRMOptionId) then
                    CRMOptionIds.Add(CRMOptionId)
                else
                    RecordCounter[NoOf::Skipped] += 1
            until RecRef.Next() = 0;


            if EnqueueOptionSyncJobFromIntegrationTable(IntegrationTableMapping, CRMOptionIds, SelectedDirection, true) then
                RecordCounter[NoOf::Scheduled] += CRMOptionIds.Count()
            else
                RecordCounter[NoOf::Failed] += CRMOptionIds.Count();
        end;

        if SelectedDirection = IntegrationTableMapping.Direction::ToIntegrationTable then begin
            repeat
                CRMOptionMapping.SetRange("Record ID", RecRef.RecordId());
                if not CRMOptionMapping.IsEmpty() then
                    LocalIds.Add(RecRef.Field(RecRef.SystemIdNo).Value())
                else
                    RecordCounter[NoOf::Skipped] += 1
            until RecRef.Next() = 0;

            if EnqueueOptionSyncJobToIntegrationTable(IntegrationTableMapping, LocalIds, SelectedDirection, true) then
                RecordCounter[NoOf::Scheduled] += LocalIds.Count()
            else
                RecordCounter[NoOf::Failed] += LocalIds.Count();
        end;

        SendSyncNotification(RecordCounter);
    end;

    procedure UpdateOneNow(RecordID: RecordID)
    begin
        // Extinct method. Kept for backward compatibility.
        UpdateMultipleNow(RecordID)
    end;

    procedure UpdateSkippedNow(var CRMIntegrationRecord: Record "CRM Integration Record")
    begin
        UpdateSkippedNow(CRMIntegrationRecord, false);
    end;

    procedure UpdateSkippedNow(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping")
    begin
        UpdateSkippedNow(CRMIntegrationRecord, CRMOptionMapping, false);
    end;

    procedure UpdateSkippedNow(var CRMIntegrationRecord: Record "CRM Integration Record"; SkipNotification: Boolean)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        UpdateSkippedNow(CRMIntegrationRecord, CRMOptionMapping, SkipNotification);
    end;

    procedure UpdateSkippedNow(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping"; SkipNotification: Boolean)
    var
        RecId: RecordId;
        RecRef: RecordRef;
        RestoredRecCounter: Integer;
    begin
        if CRMIntegrationRecord.FindSet() then
            repeat
                if CRMIntegrationRecord.Skipped then
                    if CRMIntegrationRecord.FindRecordId(RecId) then begin
                        CRMIntegrationRecord.Validate(Skipped, false);
                        CRMIntegrationRecord.Modify();
                        RestoredRecCounter += 1;
                    end;
            until CRMIntegrationRecord.Next() = 0;
        if CRMOptionMapping.FindSet() then
            repeat
                if CRMOptionMapping.Skipped then begin
                    RecRef.Open(CRMOptionMapping."Table ID");
                    if RecRef.Get(CRMOptionMapping."Record ID") then begin
                        CRMOptionMapping.Skipped := false;
                        CRMOptionMapping.Modify();
                        RestoredRecCounter += 1;
                    end;
                end;
            until CRMOptionMapping.Next() = 0;
        if not SkipNotification then
            SendRestoredSyncNotification(RestoredRecCounter);
    end;

    procedure UpdateAllSkippedNow()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMOptionMapping: Record "CRM Option Mapping";
        RestoredRecCounter: Integer;
    begin
        CRMIntegrationRecord.SetRange(Skipped, true);
        CRMOptionMapping.SetRange(Skipped, true);
        RestoredRecCounter := CRMIntegrationRecord.Count() + CRMOptionMapping.Count();
        if CRMIntegrationRecord.Count() > 0 then
            CRMIntegrationRecord.ModifyAll(Skipped, false);
        if CRMOptionMapping.Count() > 0 then
            CRMOptionMapping.ModifyAll(Skipped, false);
        SendRestoredSyncNotification(RestoredRecCounter);
    end;

    local procedure WasRecordModifiedAfterLastSynch(IntegrationTableMapping: Record "Integration Table Mapping"; RecRef: RecordRef; CRMID: Guid; SelectedDirection: Option): Boolean
    var
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        CRMRecordRef: RecordRef;
        RecordModified: Boolean;
        CRMRecordModified: Boolean;
    begin
        RecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
        IntegrationTableMapping.GetRecordRef(CRMID, CRMRecordRef);
        CRMRecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        exit(
          ((SelectedDirection = IntegrationTableMapping.Direction::ToIntegrationTable) and CRMRecordModified) or
          ((SelectedDirection = IntegrationTableMapping.Direction::FromIntegrationTable) and RecordModified))
    end;

    procedure CheckOrEnableCRMConnection()
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        GuidedExperience: Codeunit "Guided Experience";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AssistedSetup: Page "Assisted Setup";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        if IsCDSIntegrationEnabled() then
            exit;

        if IsCRMIntegrationEnabled() then
            exit;

        if CRMIntegrationEnabledLastError <> '' then
            Error(CRMIntegrationEnabledLastError);

        if GuiAllowed then
            if CRMIntegrationEnabledState = CRMIntegrationEnabledState::"Enabled But Not For Current User" then
                Message(NotEnabledForCurrentUserMsg, UserId, PRODUCTNAME.Short(), CRMProductName.SHORT(), CRMProductName.CDSServiceName())
            else begin
                FeatureTelemetry.LogUptake('0000H7D', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::Discovered);
                FeatureTelemetry.LogUptake('0000H7E', 'Dataverse', Enum::"Feature Uptake Status"::Discovered);
                if Confirm(StrSubstNo(NotEnabledMsg, CRMProductName.CDSServiceName(), AssistedSetup.Caption())) then begin
                    CDSIntegrationImpl.RegisterAssistedSetup();
                    GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"CDS Connection Setup Wizard");
                    if IsCDSIntegrationEnabled() then
                        exit;
                end;
            end;

        Error('');
    end;

    local procedure GetRecordRef(RecVariant: Variant; var RecordRef: RecordRef): Integer
    begin
        case true of
            RecVariant.IsRecord:
                RecordRef.GetTable(RecVariant);
            RecVariant.IsRecordId:
                if RecordRef.Get(RecVariant) then
                    RecordRef.SetRecFilter();
            RecVariant.IsRecordRef:
                RecordRef := RecVariant;
            else
                exit(0);
        end;
        if RecordRef.FindSet() then
            exit(RecordRef.Count);
        exit(0);
    end;

    procedure CreateNewRecordsInCRM(RecVariant: Variant)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordRef: RecordRef;
        LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]];
        LocalIdList: List of [Guid];
        LocalId: Guid;
    begin
        if GetRecordRef(RecVariant, RecordRef) = 0 then
            exit;

        GetIntegrationTableMappingFromCRMRecord(IntegrationTableMapping, RecordRef);
        LocalIdListDictionary.Add(IntegrationTableMapping.Name, LocalIdList);

        repeat
            LocalId := RecordRef.Field(RecordRef.SystemIdNo()).Value();
            LocalIdList.Add(LocalId);
        until RecordRef.Next() = 0;

        CreateNewRecordsInCRM(LocalIdListDictionary);
    end;

    procedure CreateNewOptionsInCRM(RecVariant: Variant)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMOptionMapping: Record "CRM Option Mapping";
        RecRef: RecordRef;
        RecordCounter: array[4] of Integer;
        LocalIdList: List of [Guid];
    begin
        if GetRecordRef(RecVariant, RecRef) = 0 then
            exit;

        GetIntegrationTableMapping(IntegrationTableMapping, RecRef.RecordId());
        repeat
            RecordCounter[NoOf::Total] += 1;
            CRMOptionMapping.SetRange("Record ID", RecRef.RecordId());
            if not CRMOptionMapping.IsEmpty() then
                RecordCounter[NoOf::Skipped] += 1
            else
                LocalIdList.Add(RecRef.Field(RecRef.SystemIdNo()).Value());
        until RecRef.Next() = 0;

        if EnqueueOptionSyncJobToIntegrationTable(IntegrationTableMapping, LocalIdList, IntegrationTableMapping.Direction::ToIntegrationTable, false) then
            RecordCounter[NoOf::Scheduled] += LocalIdList.Count()
        else
            RecordCounter[NoOf::Failed] += LocalIdList.Count();

        SendCreateNewNotification(RecordCounter);
    end;

    procedure CreateNewOptionsInCRM(var LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMOptionMapping: Record "CRM Option Mapping";
        LocalRecordRef: RecordRef;
        IntegrationTableMappingName: Code[20];
        LocalId: Guid;
        RecordCounter: array[4] of Integer;
        IntegrationTableMappingNameList: List of [Code[20]];
        LocalIdList: List of [Guid];
        SynchronizeLocalIdList: List of [Guid];
    begin
        IntegrationTableMappingNameList := LocalIdListDictionary.Keys();
        foreach IntegrationTableMappingName in IntegrationTableMappingNameList do begin
            IntegrationTableMapping.Get(IntegrationTableMappingName);
            LocalIdList := LocalIdListDictionary.Get(IntegrationTableMappingName);
            foreach LocalId in LocalIdList do begin
                RecordCounter[NoOf::Total] += 1;
                LocalRecordRef.Open(IntegrationTableMapping."Table ID");
                LocalRecordRef.GetBySystemId(LocalId);
                CRMOptionMapping.SetRange("Record ID", LocalRecordRef.RecordId());
                if not CRMOptionMapping.IsEmpty() then
                    RecordCounter[NoOf::Skipped] += 1
                else
                    SynchronizeLocalIdList.Add(LocalId);
                LocalRecordRef.Close();
            end;
        end;

        if EnqueueOptionSyncJobToIntegrationTable(IntegrationTableMapping, SynchronizeLocalIdList, IntegrationTableMapping.Direction, false) then
            RecordCounter[NoOf::Scheduled] += SynchronizeLocalIdList.Count()
        else
            RecordCounter[NoOf::Failed] += SynchronizeLocalIdList.Count();

        SendCreateNewNotification(RecordCounter);
    end;

    [Scope('OnPrem')]
    procedure CreateNewRecordsInCRM(var LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    var
        CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]];
    begin
        CreateNewRecords(LocalIdListDictionary, CRMIdListDictionary);
    end;

    [Scope('Cloud')]
    procedure CreateNewRecordsFromSelectedCRMOptions(RecVariant: Variant)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMOptionMapping: Record "CRM Option Mapping";
        RecRef: RecordRef;
        RecordCounter: array[4] of Integer;
        CRMOptionIds: List of [Integer];
        CRMOptionId: Integer;
    begin
        if GetRecordRef(RecVariant, RecRef) = 0 then
            exit;

        GetIntegrationTableMappingFromCRMOption(IntegrationTableMapping, RecRef);
        repeat
            RecordCounter[NoOf::Total] += 1;
            CRMOptionId := GetOptionIdFieldRef(RecRef).Value();
            if CRMOptionMapping.FindRecordID(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", CRMOptionId) then
                RecordCounter[NoOf::Skipped] += 1
            else
                CRMOptionIds.Add(CRMOptionId);
        until RecRef.Next() = 0;

        if EnqueueOptionSyncJobFromIntegrationTable(IntegrationTableMapping, CRMOptionIds, IntegrationTableMapping.Direction::FromIntegrationTable, false) then
            RecordCounter[NoOf::Scheduled] += CRMOptionIds.Count()
        else
            RecordCounter[NoOf::Failed] += CRMOptionIds.Count();

        SendCreateNewNotification(RecordCounter);
    end;

    procedure EnqueueOptionSyncJobFromIntegrationTable(IntegrationTableMapping: Record "Integration Table Mapping"; CRMOptionIds: List of [Integer]; Direction: Integer; SynchronizeOnlyCoupledRecords: Boolean): Boolean
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        IntegrationTableMapping.Direction := Direction;
        if Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
            IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForCRMOptionIds(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", CRMOptionIds));
            AddIntegrationTableMapping(IntegrationTableMapping, SynchronizeOnlyCoupledRecords);
            Commit();
            exit(CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping));
        end;
    end;

    procedure EnqueueOptionSyncJobToIntegrationTable(IntegrationTableMapping: Record "Integration Table Mapping"; LocalIdList: List of [Guid]; Direction: Integer; SynchronizeOnlyCoupledRecords: Boolean): Boolean
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
    begin
        IntegrationTableMapping.Direction := Direction;
        if Direction = IntegrationTableMapping.Direction::ToIntegrationTable then begin
            IntegrationTableMapping.SetTableFilter(IntegrationRecordSynch.GetTableViewForSystemIds(IntegrationTableMapping."Table ID", LocalIdList));
            AddIntegrationTableMapping(IntegrationTableMapping, SynchronizeOnlyCoupledRecords);
            Commit();
            exit(CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping));
        end;
    end;

    local procedure EnqueueOptionSyncJob(IntegrationTableMapping: Record "Integration Table Mapping"; RecordId: RecordId; CRMOptionId: Integer; Direction: Integer): Boolean
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
    begin
        IntegrationTableMapping.Direction := Direction;
        IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForCRMOptionId(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", CRMOptionId));
        IntegrationTableMapping.SetTableFilter(IntegrationRecordSynch.GetTableViewForRecordID(RecordId));
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        exit(CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping));
    end;

    procedure CreateNewRecordsFromCRM(RecVariant: Variant)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordRef: RecordRef;
        CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]];
        CRMIdList: List of [Guid];
        CRMID: Guid;
    begin
        if GetRecordRef(RecVariant, RecordRef) = 0 then
            exit;

        GetIntegrationTableMappingFromCRMRecord(IntegrationTableMapping, RecordRef);
        CRMIdListDictionary.Add(IntegrationTableMapping.Name, CRMIdList);

        repeat
            CRMID := RecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
            CRMIdList.Add(CRMID);
        until RecordRef.Next() = 0;

        CreateNewRecordsFromCRM(CRMIdListDictionary);
    end;

    [Scope('OnPrem')]
    procedure CreateNewRecordsFromCRM(var CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    var
        LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]];
    begin
        CreateNewRecords(LocalIdListDictionary, CRMIdListDictionary);
    end;

    [Scope('OnPrem')]
    procedure CreateNewRecords(var LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]]; var CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMRecordRef: RecordRef;
        RecordCounter: array[4] of Integer;
        LocalId: Guid;
        CRMId: Guid;
        LocalIdCount: Integer;
        CRMIdCount: Integer;
        MappingDictionary: Dictionary of [Code[20], Boolean];
        ToCRMMappingList: List of [Code[20]];
        FromCRMMappingList: List of [Code[20]];
        MappingList: List of [Code[20]];
        LocalIdList: List of [Guid];
        CRMIdList: List of [Guid];
        MappingName: Code[20];
        I: Integer;
        J: Integer;
    begin
        ToCRMMappingList := LocalIdListDictionary.Keys();
        FromCRMMappingList := CRMIdListDictionary.Keys();
        MappingList.AddRange(ToCRMMappingList);
        MappingList.AddRange(fromCRMMappingList);
        foreach MappingName in MappingList do
            if not MappingDictionary.ContainsKey(MappingName) then
                MappingDictionary.Add(MappingName, true);
        MappingList := MappingDictionary.Keys();
        foreach MappingName in MappingList do begin
            Clear(LocalIdList);
            Clear(CRMIdList);
            IntegrationTableMapping.Get(MappingName);
            if ToCRMMappingList.Contains(MappingName) then begin
                LocalIdList := LocalIdListDictionary.Get(MappingName);
                LocalIdCount := LocalIdList.Count();
                if LocalIdCount > 0 then begin
                    J := LocalIdCount + 1;
                    for I := 1 to LocalIdCount do begin
                        J -= 1;
                        LocalId := LocalIdList.Get(J);
                        RecordCounter[NoOf::Total] += 1;
                        CRMIntegrationRecord.SetCurrentKey("Integration ID");
                        CRMIntegrationRecord.SetFilter("Integration ID", LocalId);
                        if CRMIntegrationRecord.FindFirst() then begin
                            if CRMIntegrationRecord.GetCRMRecordRef(IntegrationTableMapping."Integration Table ID", CRMRecordRef) then begin
                                RecordCounter[NoOf::Skipped] += 1;
                                LocalIdList.RemoveAt(J);
                            end else
                                if not IsNullGuid(CRMIntegrationRecord."CRM ID") then // found the corrupt coupling
                                    CRMIntegrationRecord.Delete();
                            CRMRecordRef.Close();
                        end;
                    end;
                end;
            end;
            if FromCRMMappingList.Contains(MappingName) then begin
                CRMIdList := CRMIdListDictionary.Get(MappingName);
                CRMIdCount := CRMIdList.Count();
                if CRMIdCount > 0 then begin
                    J := CRMIdCount + 1;
                    for I := 1 to CRMIdCount do begin
                        J -= 1;
                        CRMID := CRMIdList.Get(J);
                        RecordCounter[NoOf::Total] += 1;
                        if CRMIntegrationRecord.FindValidByCRMID(CRMID) then begin
                            RecordCounter[NoOf::Skipped] += 1;
                            CRMIdList.RemoveAt(J);
                        end else
                            if not IsNullGuid(CRMIntegrationRecord."CRM ID") then // found the corrupt coupling
                                CRMIntegrationRecord.Delete();
                    end;
                end;
            end;
            EnqueueCreateNewJob(LocalIdList, CRMIdList, RecordCounter, IntegrationTableMapping);
        end;
        SendCreateNewNotification(RecordCounter);
    end;

    local procedure EnqueueCreateNewJob(var LocalIdList: List of [Guid]; CRMIdList: List of [Guid]; var RecordCounter: array[4] of Integer; var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        LocalIdCount: Integer;
        CRMIdCount: Integer;
        Direction: Option;
    begin
        LocalIdCount := LocalIdList.Count();
        CRMIdCount := CRMIdList.Count();
        if (LocalIdCount > 0) or (CRMIdCount > 0) then begin
            if CRMIdCount = 0 then
                Direction := IntegrationTableMapping.Direction::ToIntegrationTable
            else
                if LocalIdCount = 0 then
                    Direction := IntegrationTableMapping.Direction::FromIntegrationTable
                else
                    Direction := IntegrationTableMapping.Direction;
            if EnqueueSyncJob(IntegrationTableMapping, LocalIdList, CRMIdList, Direction, false) then
                RecordCounter[NoOf::Scheduled] += LocalIdCount + CRMIdCount
            else
                RecordCounter[NoOf::Failed] += LocalIdCount + CRMIdCount;
        end;
    end;

    local procedure SendCreateNewNotification(var RecordCounter: array[4] of Integer)
    begin
        if RecordCounter[NoOf::Total] = RecordCounter[NoOf::Skipped] then begin
            if RecordCounter[NoOf::Total] > 1 then
                SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, AllRecordsAlreadyCoupledTxt))
            else
                SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, RecordAlreadyCoupledTxt));
            exit;
        end;

        SendSyncNotification(RecordCounter);
    end;

    [Scope('OnPrem')]
    procedure CreateNewRecordsFromSelectedCRMRecords(RecVariant: Variant)
    begin
        CreateNewRecordsFromCRM(RecVariant);
    end;

    local procedure PerformInitialSynchronization(RecordID: RecordID; CRMID: Guid; Direction: Option)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordCounter: array[4] of Integer;
    begin
        RecordCounter[NoOf::Total] := 1;
        GetIntegrationTableMapping(IntegrationTableMapping, RecordID);
        if EnqueueSyncJob(IntegrationTableMapping, RecordID, CRMID, Direction) then
            RecordCounter[NoOf::Scheduled] += 1
        else
            RecordCounter[NoOf::Failed] += 1;

        SendSyncNotification(RecordCounter);
    end;

    local procedure PerformInitialOptionSynchronization(RecordId: RecordId; CRMOptionId: Integer; Direction: Option)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordCounter: array[4] of Integer;
    begin
        RecordCounter[NoOf::Total] := 1;
        GetIntegrationTableMapping(IntegrationTableMapping, RecordID.TableNo());
        if EnqueueOptionSyncJob(IntegrationTableMapping, RecordId, CRMOptionId, Direction) then
            RecordCounter[NoOf::Scheduled] += 1
        else
            RecordCounter[NoOf::Failed] += 1;

        SendSyncNotification(RecordCounter);
    end;

    internal procedure MarkLocalDeletedAsSkipped()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        TableFilter: Text;
        Count: Integer;
        TotalCount: Integer;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetFilter(Direction, '<>%1', IntegrationTableMapping.Direction::Bidirectional);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetFilter("Table ID", '<>%1', Database::"Sales Header");
        if not IntegrationTableMapping.FindSet() then
            exit;

        repeat
            Count := 0;
            TableFilter := IntegrationTableMapping.GetTableFilter();
            CRMIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
            CRMIntegrationRecord.SetRange(Skipped, false);
            if CRMIntegrationRecord.FindSet() then
                repeat
                    RecordRef.Open(IntegrationTableMapping."Table ID");
                    RecordRef.SetView(TableFilter);
                    FieldRef := RecordRef.Field(RecordRef.SystemIdNo());
                    FieldRef.SetRange(CRMIntegrationRecord."Integration ID");
                    if RecordRef.IsEmpty() then begin
                        CRMIntegrationRecord.Skipped := true;
                        CRMIntegrationRecord.Modify();
                        Count += 1;
                    end;
                    RecordRef.Close();
                until CRMIntegrationRecord.Next() = 0;
            TotalCount += Count;
            if Count > 0 then
                Session.LogMessage('0000F26', StrSubstNo(BrokenCouplingsFoundAndMarkedAsSkippedForMappingTxt,
                    GetTableCaption(IntegrationTableMapping."Table ID"), GetTableCaption(IntegrationTableMapping."Integration Table ID"), IntegrationTableMapping.Direction, Count),
                    Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        until IntegrationTableMapping.Next() = 0;
        if TotalCount > 0 then
            Session.LogMessage('0000F27', StrSubstNo(BrokenCouplingsFoundAndMarkedAsSkippedTotalTxt, TotalCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok)
        else
            Session.LogMessage('0000F28', NoBrokenCouplingsFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    procedure RepairBrokenCouplings()
    begin
        RepairBrokenCouplings(false);
    end;

    procedure RepairBrokenCouplings(UseLocalRecordsOnly: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        BlankGuid: Guid;
    begin
        CRMIntegrationRecord.SetRange("Table ID", 0);
        if CRMIntegrationRecord.IsEmpty() then
            exit;

        if CRMIntegrationRecord.FindSet() then
            repeat
                if CRMIntegrationRecord."Integration ID" <> BlankGuid then
                    if not CRMIntegrationRecord.RepairTableIdByLocalRecord() then
                        if not UseLocalRecordsOnly then
                            if not CRMIntegrationRecord.RepairTableIdByCRMRecord() then begin
                                CRMIntegrationRecord.Delete();
                                Session.LogMessage('0000DQD', StrSubstNo(DeletedRecordWithZeroTableIdTxt, CRMIntegrationRecord."Integration ID", CRMIntegrationRecord."CRM ID"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                            end;
            until CRMIntegrationRecord.Next() = 0;
    end;

    procedure RemoveCoupling(TableID: Integer; CRMTableID: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, TableID, CRMTableID) then
            ScheduleUncoupling(IntegrationTableMapping, '', '')
        else begin
            RepairBrokenCouplings();
            CRMIntegrationRecord.SetRange("Table ID", TableID);
            CRMIntegrationRecord.DeleteAll();
        end;
    end;

    procedure MatchBasedCoupling(TableID: Integer): Boolean
    begin
        exit(MatchBasedCoupling(TableID, false, false, false));
    end;

    procedure MatchBasedCoupling(TableID: Integer; SkipSettingCriteria: Boolean; IsFullSync: Boolean; InForeground: Boolean): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        ScheduleJob: Boolean;
    begin
        if IsCRMTable(TableID) then begin
            Session.LogMessage('0000EZO', StrSubstNo(NotLocalTableTxt, GetTableCaption(TableID)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(false);
        end;

        if GetIntegrationTableMappingForCoupling(IntegrationTableMapping, TableID) then begin
            if SkipSettingCriteria then
                ScheduleJob := true;

            if not ScheduleJob then begin
                IntegrationFieldMapping.SetMatchBasedCouplingFilters(IntegrationTableMapping);
                ScheduleJob := (Page.RunModal(Page::"Match Based Coupling Criteria", IntegrationFieldMapping) = Action::LookupOK);
            end;

            if not ScheduleJob then
                exit(false);

            if InForeground then
                exit(PerformCoupling(IntegrationTableMapping, '', IsFullSync))
            else
                exit(ScheduleCoupling(IntegrationTableMapping, '', IsFullSync));
        end;

        exit(false);
    end;

    procedure RemoveCoupling(var LocalRecordRef: RecordRef)
    begin
        RemoveCoupling(LocalRecordRef, true);
    end;

    procedure MatchBasedCoupling(var LocalRecordRef: RecordRef)
    var
        CouplingOption: Option None,Background,Foreground;
    begin
        MatchBasedCoupling(LocalRecordRef, CouplingOption::Background);
    end;

    procedure RemoveCoupling(LocalTableID: Integer; var LocalIdList: List of [Guid])
    begin
        RemoveCoupling(LocalTableID, LocalIdList, true);
    end;

    procedure RemoveCoupling(LocalTableID: Integer; var LocalIdList: List of [Guid]; Schedule: Boolean)
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        LocalRecordRef: RecordRef;
        LocalIdFilter: Text;
    begin
        if LocalIdList.Count() = 0 then
            exit;
        LocalIdFilter := IntegrationRecordSynch.JoinIDs(LocalIdList, '|');
        LocalRecordRef.Open(LocalTableId);
        LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).SetFilter(LocalIdFilter);
        RemoveCoupling(LocalRecordRef, Schedule);
    end;

    procedure RemoveCoupling(LocalTableID: Integer; IntegrationTableID: Integer; var IntegrationIdList: List of [Guid])
    begin
        RemoveCoupling(LocalTableID, IntegrationTableID, IntegrationIdList, true);
    end;

    internal procedure RemoveCoupling(var LocalRecordRef: RecordRef; Schedule: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
    begin
        if IsCRMTable(LocalRecordRef.Number()) then begin
            Session.LogMessage('0000DHU', StrSubstNo(NotLocalTableTxt, GetTableCaption(LocalRecordRef.Number())), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        if GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, LocalRecordRef.Number()) then
            if Schedule then
                ScheduleUncoupling(IntegrationTableMapping, IntegrationRecordSynch.GetTableViewForLocalRecords(LocalRecordRef), '')
            else
                PerformUncoupling(IntegrationTableMapping, IntegrationRecordSynch.GetTableViewForLocalRecords(LocalRecordRef), '')
        else
            RemoveCouplingToRecord(LocalRecordRef);
    end;

    procedure RemoveOptionMapping(var RecRef: RecordRef)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        if not RecRef.FindSet() then
            exit;

        repeat
            CRMOptionMapping.SetRange("Record ID", RecRef.RecordId());
            if CRMOptionMapping.FindFirst() then
                CRMOptionMapping.Delete();
        until RecRef.Next() = 0;
    end;

    local procedure RemoveOptionMapping(IntegrationTableId: Integer; IntegrationFieldId: Integer; OptionId: Integer): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping.SetRange("Integration Table ID", IntegrationTableId);
        CRMOptionMapping.SetRange("Integration Field ID", IntegrationFieldId);
        CRMOptionMapping.SetRange("Option Value", OptionId);
        if CRMOptionMapping.FindFirst() then
            exit(CRMOptionMapping.Delete());
    end;

    local procedure RemoveOptionMappingFromRecRef(RecRef: RecordRef): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping.SetRange("Record ID", RecRef.RecordId());
        if not CRMOptionMapping.FindFirst() then
            exit(false);
        exit(CRMOptionMapping.Delete());
    end;

    procedure CreateOptionMapping(RecordID: RecordID; CRMOptionId: Integer; CRMOptionValue: Text[250])
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping.SetRange("Record ID", RecordId);
        if not CRMOptionMapping.FindFirst() then begin
            CRMOptionMapping.AssertCRMOptionIdCanBeMapped(RecordID, CRMOptionId);
            CRMOptionMapping.InsertRecord(RecordID, CRMOptionId, CRMOptionValue);
        end else
            if CRMOptionMapping."Option Value" <> CRMOptionId then begin
                CRMOptionMapping.AssertCRMOptionIdCanBeMapped(RecordID, CRMOptionId);
                CRMOptionMapping."Option Value" := CRMOptionId;
                CRMOptionMapping."Option Value Caption" := CRMOptionValue;
                CRMOptionMapping.Modify(true);
            end;
    end;

    procedure GetMappedCRMOptionId(RecordID: RecordID; var CRMOptionId: Integer): Boolean
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        Found: Boolean;
    begin
        CRMOptionMapping.SetRange("Record ID", RecordId);
        if CRMOptionMapping.FindFirst() then begin
            CRMOptionId := CRMOptionMapping."Option Value";
            Found := true;
        end;
        exit(Found);
    end;

    local procedure MatchBasedCoupling(var LocalRecordRef: RecordRef; CouplingOption: Option None,Background,Foreground)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        CoupledToCRMFieldRef: FieldRef;
    begin
        if IsCRMTable(LocalRecordRef.Number()) then begin
            Session.LogMessage('0000EZP', StrSubstNo(NotLocalTableTxt, GetTableCaption(LocalRecordRef.Number())), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        if GetIntegrationTableMappingForCoupling(IntegrationTableMapping, LocalRecordRef.Number()) then begin
            IntegrationFieldMapping.SetMatchBasedCouplingFilters(IntegrationTableMapping);
            if Page.RunModal(Page::"Match Based Coupling Criteria", IntegrationFieldMapping) = Action::LookupOK then
                if CouplingOption in [CouplingOption::Background, CouplingOption::Foreground] then begin
                    if FindCoupledToCRMField(LocalRecordRef, CoupledToCRMFieldRef) then
                        CoupledToCRMFieldRef.SetRange(false);
                    if CouplingOption = CouplingOption::Background then
                        ScheduleCoupling(IntegrationTableMapping, IntegrationRecordSynch.GetTableViewForLocalRecords(LocalRecordRef), false)
                    else
                        PerformCoupling(IntegrationTableMapping, IntegrationRecordSynch.GetTableViewForLocalRecords(LocalRecordRef), false);
                end;
        end;
    end;

    internal procedure RemoveCoupling(LocalTableID: Integer; IntegrationTableID: Integer; var IntegrationIdList: List of [Guid]; Schedule: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IntegrationIdList.Count() = 0 then
            exit;
        if GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, LocalTableID) then begin
            if Schedule then
                ScheduleUncoupling(IntegrationTableMapping, '', GetTableViewForCRMIDs(IntegrationTableID, IntegrationTableMapping."Integration Table UID Fld. No.", IntegrationIdList))
            else
                PerformUncoupling(IntegrationTableMapping, '', GetTableViewForCRMIDs(IntegrationTableID, IntegrationTableMapping."Integration Table UID Fld. No.", IntegrationIdList))
        end else
            RemoveCouplingToRecord(LocalTableID, IntegrationIdList);
    end;

    local procedure RemoveCouplingToRecord(var LocalRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if LocalRecordRef.FindSet() then
            repeat
                CRMIntegrationRecord.RemoveCouplingToRecord(LocalRecordRef.RecordId());
            until LocalRecordRef.Next() = 0;
    end;

    local procedure RemoveCouplingToRecord(LocalTableID: Integer; var CRMIDList: List of [Guid])
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMID: Guid;
    begin
        foreach CRMID in CRMIDList do
            CRMIntegrationRecord.RemoveCouplingToCRMID(CRMID, LocalTableID);
    end;

    procedure RemoveCoupling(RecordID: RecordID)
    begin
        RemoveCoupling(RecordID, true);
    end;

    internal procedure RemoveCoupling(RecordID: RecordID; Schedule: Boolean): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
    begin
        if IsCRMTable(RecordID.TableNo()) then begin
            Session.LogMessage('0000DHV', StrSubstNo(NotLocalTableTxt, GetTableCaption(RecordID.TableNo())), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(false);
        end;

        if not GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, RecordID.TableNo()) then
            exit(CRMIntegrationRecord.RemoveCouplingToRecord(RecordID));

        if Schedule then
            exit(ScheduleUncoupling(IntegrationTableMapping, IntegrationRecordSynch.GetTableViewForRecordID(RecordID), ''));

        exit(PerformUncoupling(IntegrationTableMapping, IntegrationRecordSynch.GetTableViewForRecordID(RecordID), ''));
    end;

    procedure RemoveCoupling(TableID: Integer; CRMTableID: Integer; CRMID: Guid)
    begin
        RemoveCoupling(TableID, CRMTableID, CRMID, true);
    end;

    internal procedure RemoveCoupling(TableID: Integer; CRMTableID: Integer; CRMID: Guid; Schedule: Boolean): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if not GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, TableID, CRMTableID) then
            exit(CRMIntegrationRecord.RemoveCouplingToCRMID(CRMID, TableID));

        if Schedule then
            exit(ScheduleUncoupling(IntegrationTableMapping, '', GetTableViewForGuid(CRMTableID, IntegrationTableMapping."Integration Table UID Fld. No.", CRMID)));

        exit(PerformUncoupling(IntegrationTableMapping, '', GetTableViewForGuid(CRMTableID, IntegrationTableMapping."Integration Table UID Fld. No.", CRMID)));
    end;

    local procedure ScheduleUncoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IntegrationTableFilter: Text): Boolean
    var
        RecordCounter: array[4] of Integer;
        Scheduled: Boolean;
    begin
        RecordCounter[NoOf::Total] := 1;
        Scheduled := EnqueueUncoupleJob(IntegrationTableMapping, LocalTableFilter, IntegrationTableFilter);
        if Scheduled then
            RecordCounter[NoOf::Scheduled] += 1
        else
            RecordCounter[NoOf::Failed] += 1;
        SendUncoupleNotification(RecordCounter);
        exit(Scheduled);
    end;

    local procedure ScheduleCoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IsFullSync: Boolean): Boolean
    var
        RecordCounter: array[4] of Integer;
        Scheduled: Boolean;
    begin
        IntegrationTableMapping.Find();
        RecordCounter[NoOf::Total] := 1;
        Scheduled := EnqueueCouplingJob(IntegrationTableMapping, LocalTableFilter, IsFullSync);
        if Scheduled then
            RecordCounter[NoOf::Scheduled] += 1
        else
            RecordCounter[NoOf::Failed] += 1;
        SendCouplingNotification(RecordCounter);
        exit(Scheduled);
    end;

    local procedure PerformCoupling(IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IsFullSync: Boolean): Boolean
    var
        CDSIntTableCouple: Codeunit "CDS Int. Table Couple";
    begin
        IntegrationTableMapping.Find();
        if LocalTableFilter <> '' then
            IntegrationTableMapping.SetTableFilter(LocalTableFilter)
        else
            IntegrationTableMapping.CalcFields("Table Filter");
        IntegrationTableMapping.CalcFields("Integration Table Filter");
        IntegrationTableMapping."Full Sync is Running" := IsFullSync;
        AddIntegrationTableMapping(IntegrationTableMapping, true);
        CDSIntTableCouple.PerformScheduledCoupling(IntegrationTableMapping);
        IntegrationTableMapping.Delete(true);
    end;

    local procedure PerformUncoupling(IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IntegrationTableFilter: Text): Boolean
    var
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
        CountFailed: Integer;
    begin
        AddIntegrationTableMapping(IntegrationTableMapping);
        IntegrationTableMapping.SetTableFilter(LocalTableFilter);
        IntegrationTableMapping.SetIntegrationTableFilter(IntegrationTableFilter);
        if LocalTableFilter <> '' then begin
            LocalRecordRef.Open(IntegrationTableMapping."Table ID");
            LocalRecordRef.SetView(LocalTableFilter);
            if LocalRecordRef.FindSet() then
                repeat
                    if not PerformUncoupling(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef) then
                        CountFailed += 1;
                until LocalRecordRef.Next() = 0
        end else begin
            IntegrationRecordRef.Open(IntegrationTableMapping."Integration Table ID");
            IntegrationRecordRef.SetView(IntegrationTableFilter);
            if IntegrationRecordRef.FindSet() then
                repeat
                    if not PerformUncoupling(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef) then
                        CountFailed += 1;
                until IntegrationRecordRef.Next() = 0;
        end;
        IntegrationTableMapping.Delete(true);
        exit(CountFailed = 0);
    end;

    local procedure PerformUncoupling(IntegrationTableMapping: Record "Integration Table Mapping"; LocalRecordRef: RecordRef; IntegrationRecordRef: RecordRef): Boolean
    var
        IntRecUncoupleInvoke: Codeunit "Int. Rec. Uncouple Invoke";
        SynchAction: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple,Couple;
        LocalRecordModified: Boolean;
        IntegrationRecordModified: Boolean;
        JobId: Guid;
    begin
        SynchAction := SynchAction::Uncouple;
        IntRecUncoupleInvoke.SetContext(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, SynchAction, LocalRecordModified, IntegrationRecordModified, JobId, TableConnectionType::CRM);
        IntRecUncoupleInvoke.Run();
        IntRecUncoupleInvoke.GetContext(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, SynchAction, LocalRecordModified, IntegrationRecordModified);
        exit(SynchAction <> SynchAction::Fail);
    end;

    local procedure GetIntegrationTableMappingForUncoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; CRMTableID: Integer): Boolean
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.SetRange("Integration Table ID", CRMTableID);
        exit(IntegrationTableMapping.FindFirst());
    end;

    local procedure GetIntegrationTableMappingForUncoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer): Boolean
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Table ID", TableID);
        exit(IntegrationTableMapping.FindFirst());
    end;

    local procedure GetIntegrationTableMappingForCoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer): Boolean
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetFilter("Coupling Codeunit ID", '%1|%2', Codeunit::"CDS Int. Table Couple", Codeunit::"CDS Int. Option Couple");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Table ID", TableID);
        exit(IntegrationTableMapping.FindFirst());
    end;

    procedure GetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; RecId: RecordId)
    var
        TableId: Integer;
    begin
        TableId := RecId.TableNo();
        OnBeforeGetIntegrationTableMappingWithRecordId(IntegrationTableMapping, RecId, TableId);
        GetIntegrationTableMapping(IntegrationTableMapping, TableId);
    end;

    procedure GetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer)
    begin
        OnBeforeGetIntegrationTableMapping(IntegrationTableMapping, TableId);
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IsCRMTable(TableID) then
            IntegrationTableMapping.SetRange("Integration Table ID", TableID)
        else
            IntegrationTableMapping.SetRange("Table ID", TableID);
        if not IntegrationTableMapping.FindFirst() then
            Error(IntegrationTableMappingNotFoundErr, IntegrationTableMapping.TableCaption(), GetTableCaption(TableID));
    end;

    local procedure GetIntegrationTableMappingFromCRMRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; RecRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        CustomerTypeCodeFieldRef: FieldRef;
        CustomerTypeCode: Text;
    begin
        OnBeforeGetIntegrationTableMappingFromCRMRecord(IntegrationTableMapping, RecRef);
        if RecRef.Number <> Database::"CRM Account" then begin
            GetIntegrationTableMapping(IntegrationTableMapping, RecRef.RecordId());
            exit;
        end;

        CustomerTypeCodeFieldRef := RecRef.Field(CRMAccount.FieldNo(CustomerTypeCode));
        Evaluate(CustomerTypeCode, Format(CustomerTypeCodeFieldRef.Value));
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Integration Table ID", RecRef.Number);
        if CustomerTypeCode = Format(CRMAccount.CustomerTypeCode::Customer) then
            IntegrationTableMapping.SetRange("Table ID", Database::Customer)
        else
            if CustomerTypeCode = Format(CRMAccount.CustomerTypeCode::Vendor) then
                IntegrationTableMapping.SetRange("Table ID", Database::Vendor);

        OnAfterGetIntegrationTableMappingFromCRMRecordBeforeFindRecord(IntegrationTableMapping, RecRef);
        if not IntegrationTableMapping.FindFirst() then
            Error(IntegrationTableMappingNotFoundErr, IntegrationTableMapping.TableCaption(), GetTableCaption(RecRef.Number));
    end;

    local procedure GetIntegrationTableMappingFromCRMOption(var IntegrationTableMapping: Record "Integration Table Mapping"; RecRef: RecordRef)
    var
        TableId: Integer;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", Codeunit::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);

        case RecRef.Number of
            Database::"CRM Payment Terms":
                TableId := Database::"Payment Terms";
            Database::"CRM Freight Terms":
                TableId := Database::"Shipment Method";
            Database::"CRM Shipping Method":
                TableId := Database::"Shipping Agent";
        end;

        OnGetTableIdFromCRMOption(RecRef, TableId);

        IntegrationTableMapping.SetRange("Table ID", TableId);
        if not IntegrationTableMapping.FindFirst() then
            Error(IntegrationTableMappingNotFoundErr, IntegrationTableMapping.TableCaption(), GetTableCaption(TableID));
    end;

    local procedure GetTableCaption(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.Caption);
        exit('');
    end;

    procedure IsCRMTable(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
        CRMTable: Boolean;
        Handled: Boolean;
    begin
        OnIsCRMTable(TableID, CRMTable, Handled);
        if Handled then
            exit(CRMTable);

        if TableID in [Database::"CRM Payment Terms", Database::"CRM Freight Terms", Database::"CRM Shipping Method"] then
            exit(true);

        if TableMetadata.Get(TableID) then
            exit(TableMetadata.TableType = TableMetadata.TableType::CRM);
    end;

    local procedure IsRecordSkipped(RecID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMIntegrationRecord.FindByRecordID(RecID) then
            exit(CRMIntegrationRecord.Skipped);
    end;

    local procedure JoinIntegers(var IdList: List of [Integer]; Delimiter: Text[1]): Text
    var
        IdValue: Integer;
        IdFilter: Text;
    begin
        foreach IdValue in IdList do
            IdFilter += Delimiter + Format(IdValue);
        IdFilter := IdFilter.TrimStart(Delimiter);
        exit(IdFilter);
    end;

    procedure EnqueueFullSyncJob(Name: Code[20]): Guid
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        IntegrationTableMapping.Get(Name);
        IntegrationTableMapping."Full Sync is Running" := true;
        IntegrationTableMapping.CalcFields("Table Filter", "Integration Table Filter");
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        if CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping) then begin
            JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
            if JobQueueEntry.FindFirst() then
                exit(JobQueueEntry.ID);
        end;
    end;

    procedure EnqueueSyncJob(IntegrationTableMapping: Record "Integration Table Mapping"; RecordID: RecordID; CRMID: Guid; Direction: Integer): Boolean
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
    begin
        IntegrationTableMapping.Direction := Direction;
        if Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable] then
            IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForGuid(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", CRMID));
        if Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::ToIntegrationTable] then
            IntegrationTableMapping.SetTableFilter(IntegrationRecordSynch.GetTableViewForRecordIDAndFlowFilters(IntegrationTableMapping, RecordID));
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        exit(CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping));
    end;

    procedure EnqueueSyncJob(IntegrationTableMapping: Record "Integration Table Mapping"; SystemIds: List of [Guid]; CRMIDs: List of [Guid]; Direction: Integer; SynchronizeOnlyCoupledRecords: Boolean): Boolean
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
    begin
        IntegrationTableMapping.Direction := Direction;
        if Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable] then
            IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForCRMIds(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", CRMIDs));
        if Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::ToIntegrationTable] then
            IntegrationTableMapping.SetTableFilter(IntegrationRecordSynch.GetTableViewForSystemIds(IntegrationTableMapping."Table ID", SystemIds));
        AddIntegrationTableMapping(IntegrationTableMapping, SynchronizeOnlyCoupledRecords);
        Commit();
        exit(CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping));
    end;

    local procedure EnqueueUncoupleJob(IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IntegrationTableFilter: Text): Boolean
    var
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        IntegrationTableMapping.SetTableFilter(LocalTableFilter);
        IntegrationTableMapping.SetIntegrationTableFilter(IntegrationTableFilter);
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        exit(CDSSetupDefaults.CreateUncoupleJobQueueEntry(IntegrationTableMapping));
    end;

    local procedure EnqueueCouplingJob(IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IsFullSync: Boolean): Boolean
    var
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        if LocalTableFilter <> '' then
            IntegrationTableMapping.SetTableFilter(LocalTableFilter)
        else
            IntegrationTableMapping.CalcFields("Table Filter");
        IntegrationTableMapping.CalcFields("Integration Table Filter");
        IntegrationTableMapping."Full Sync is Running" := IsFullSync;
        AddIntegrationTableMapping(IntegrationTableMapping, true);

        Commit();
        exit(CDSSetupDefaults.CreateCoupleJobQueueEntry(IntegrationTableMapping));
    end;

    procedure AddIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        AddIntegrationTableMapping(IntegrationTableMapping, false);
    end;

    procedure AddIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; SynchOnlyCoupledRecords: Boolean)
    var
        SourceIntegrationTableMapping: Record "Integration Table Mapping";
        SourceMappingName: Code[20];
    begin
        SourceMappingName := IntegrationTableMapping.GetName();
        IntegrationTableMapping.Name := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(IntegrationTableMapping.Name));
        IntegrationTableMapping."Synch. Only Coupled Records" := SynchOnlyCoupledRecords;
        IntegrationTableMapping."Delete After Synchronization" := true;
        IntegrationTableMapping."Parent Name" := SourceMappingName;
        SourceIntegrationTableMapping.Get(IntegrationTableMapping."Parent Name");
        IntegrationTableMapping."Update-Conflict Resolution" := SourceIntegrationTableMapping."Update-Conflict Resolution";
        IntegrationTableMapping."Deletion-Conflict Resolution" := SourceIntegrationTableMapping."Deletion-Conflict Resolution";
        Clear(IntegrationTableMapping."Synch. Modified On Filter");
        Clear(IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.");
        Clear(IntegrationTableMapping."Last Full Sync Start DateTime");
        IntegrationTableMapping.Insert();

        CloneIntegrationFieldMapping(SourceMappingName, IntegrationTableMapping.Name);
    end;

    procedure CloneIntegrationFieldMapping(SourceMappingName: Code[20]; DestinationMappingName: Code[20])
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        NewIntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", SourceMappingName);
        if IntegrationFieldMapping.FindSet() then
            repeat
                NewIntegrationFieldMapping := IntegrationFieldMapping;
                NewIntegrationFieldMapping."No." := 0; // Autoincrement
                NewIntegrationFieldMapping."Integration Table Mapping Name" := DestinationMappingName;
                NewIntegrationFieldMapping.Insert();
            until IntegrationFieldMapping.Next() = 0;
    end;

    local procedure GetTableViewForGuid(TableNo: Integer; IdFiledNo: Integer; CRMId: Guid) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(IdFiledNo);
        FieldRef.SetRange(CRMId);
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    local procedure GetTableViewForCRMIDs(TableNo: Integer; IdFiledNo: Integer; CRMIds: List of [Guid]) View: Text
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        CRMIdFilter: Text;
    begin
        CRMIdFilter := IntegrationRecordSynch.JoinIDs(CRMIds, '|');
        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(IdFiledNo);
        FieldRef.SetFilter(CRMIdFilter);
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    local procedure GetTableViewForCRMOptionIds(TableNo: Integer; OptionIdFieldNo: Integer; CRMOptionIds: List of [Integer]) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        CRMOptionIdFilter: Text;
    begin
        CRMOptionIdFilter := JoinIntegers(CRMOptionIds, '|');
        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(OptionIdFieldNo);
        FieldRef.SetFilter(CRMOptionIdFilter);
        View := RecordRef.GetView(false);
        RecordRef.Close();
    end;

    local procedure GetTableViewForCRMOptionId(TableNo: Integer; OptionIdFieldNo: Integer; CRMOptionId: Integer) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(OptionIdFieldNo);
        FieldRef.SetRange(CRMOptionId);
        View := RecordRef.GetView(false);
        RecordRef.Close();
    end;

    procedure CreateOrUpdateCRMAccountStatistics(Customer: Record Customer)
    var
        CRMAccount: Record "CRM Account";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
        CRMID: Guid;
    begin
        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit;

        CRMAccount.Get(CRMID);
        CRMStatisticsJob.CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount);
        CRMStatisticsJob.UpdateStatusOfPaidInvoices(Customer."No.");
        Message(StrSubstNo(AccountStatisticsUpdatedMsg, CRMProductName.CDSServiceName()));
    end;

    procedure ShowCRMEntityFromRecordID(RecordID: RecordID)
    var
        CRMID: Guid;
    begin
        if not DefineCouplingIfNotCoupled(RecordID, CRMID) then
            exit;

        HyperLink(GetCRMEntityUrlFromRecordID(RecordID));
    end;

    procedure GetCRMEntityUrlFromRecordID(TargetRecordID: RecordID): Text
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMId: Guid;
    begin
        if not CRMIntegrationRecord.FindIDFromRecordID(TargetRecordID, CRMId) then
            Error(CouplingNotFoundErr, CRMProductName.CDSServiceName());
        CRMIntegrationManagement.GetIntegrationTableMapping(IntegrationTableMapping, TargetRecordID);

        exit(GetCRMEntityUrlFromCRMID(IntegrationTableMapping."Table ID", IntegrationTableMapping."Integration Table ID", CRMId));
    end;

    procedure GetCRMEntityUrlFromCRMID(TableId: Integer; CRMId: Guid): Text
    var
        CRMTableId: Integer;
    begin
        if IsCRMTable(TableId) then begin
            CRMTableId := TableId;
            TableId := 0;
        end;
        exit(GetCRMEntityUrlFromCRMID(TableId, CRMTableId, CRMId));
    end;

    procedure GetCRMEntityUrlFromCRMID(TableId: Integer; CRMTableId: Integer; CRMId: Guid): Text
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMEntityUrl: Text;
        CDSServerAddress: Text;
        IsHandled: Boolean;
    begin
        OnGetCDSServerAddress(CDSServerAddress, IsHandled);
        if IsHandled then
            CRMEntityUrl := StrSubstNo(CRMEntityUrlTemplateTxt, CDSServerAddress, GetCRMEntityTypeName(TableId, CRMTableId), CRMId)
        else begin
            CRMConnectionSetup.Get();
            CRMEntityUrl := StrSubstNo(CRMEntityUrlTemplateTxt, CRMConnectionSetup."Server Address", GetCRMEntityTypeName(TableId, CRMTableId), CRMId);
            if CRMConnectionSetup."Use Newest UI" and (CRMConnectionSetup."Newest UI AppModuleId" <> '') then
                CRMEntityUrl += StrSubstNo(NewestUIAppIdParameterTxt, CRMConnectionSetup."Newest UI AppModuleId")
        end;

        OnAfterGetCRMEntityUrlFromCRMID(CRMEntityUrlTemplateTxt, NewestUIAppIdParameterTxt, TableId, CRMId, CRMEntityUrl, CRMTableId);
        exit(CRMEntityUrl);
    end;

    procedure OpenCoupledNavRecordPage(CRMID: Guid; CRMEntityTypeName: Text): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        RecordId: RecordId;
        BCTableId: Integer;
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenCoupledNavRecordPage(CRMID, CRMEntityTypeName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        // Find the corresponding NAV record and type
        CRMSetupDefaults.GetTableIDCRMEntityNameMapping(TempNameValueBuffer);
        TempNameValueBuffer.SetCurrentKey(Name);
        TempNameValueBuffer.SetRange(Name, LowerCase(CRMEntityTypeName));

        if TempNameValueBuffer.IsEmpty() then
            exit(false);

        FindRecordFromNameValueBuffer(TempNameValueBuffer, CRMID, RecordId, BCTableId, CRMEntityTypeName);
        if RecordId.TableNo = 0 then begin
            GetIntegrationTableMappingFromCRMID(IntegrationTableMapping, BcTableId, CRMID);
            if (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable])
              and (IntegrationTableMapping."Synch. Only Coupled Records" = false) then
                SynchFromIntegrationTable(IntegrationTableMapping, CRMID)
            else
                exit(false);
        end;

        FindRecordFromNameValueBuffer(TempNameValueBuffer, CRMID, RecordId, BCTableId, CRMEntityTypeName);
        if RecordId.TableNo = 0 then
            exit(false);
        OpenRecordCardPage(RecordID);
        exit(true);
    end;

    local procedure FindRecordFromNameValueBuffer(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; CRMID: Guid; var RecordId: RecordId; var BCTableId: Integer; CRMEntityTypeName: Text)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TableId: Integer;
    begin
        TempNameValueBuffer.SetCurrentKey(Name);
        TempNameValueBuffer.SetRange(Name, LowerCase(CRMEntityTypeName));
        if TempNameValueBuffer.FindSet() then
            repeat
                Evaluate(TableId, TempNameValueBuffer.Value);
                if not IsCRMTable(TableId) then
                    BCTableId := TableId;
                if CRMIntegrationRecord.FindRecordIDFromID(CRMID, TableId, RecordId) then
                    break;
            until TempNameValueBuffer.Next() = 0;
    end;

    local procedure SynchFromIntegrationTable(IntegrationTableMapping: Record "Integration Table Mapping"; CRMID: Guid)
    var
        CRMRecordRef: RecordRef;
        CRMFieldRef: FieldRef;
        CRMTableView: Text;
    begin
        CRMRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        CRMRecordRef.SetView(IntegrationTableMapping.GetIntegrationTableFilter());
        CRMFieldRef := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
        CRMFieldRef.SetRange(CRMID);
        CRMTableView := CRMRecordRef.GetView();
        CRMRecordRef.Close();

        IntegrationTableMapping.SetIntegrationTableFilter(CRMTableView);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        Codeunit.Run(IntegrationTableMapping."Synch. Codeunit ID", IntegrationTableMapping);
        IntegrationTableMapping.Delete(true);
        Commit();
    end;

    local procedure OpenRecordCardPage(RecordID: RecordID)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Currency: Record Currency;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
        Resource: Record Resource;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerPriceGroup: Record "Customer Price Group";
        PageManagement: Codeunit "Page Management";
        RecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        // Open the right kind of card page
        OnBeforeOpenRecordCardPage(RecordID, IsHandled);
        if IsHandled then
            exit;

        RecordRef := RecordID.GetRecord();
        case RecordID.TableNo of
            DATABASE::Contact:
                begin
                    RecordRef.SetTable(Contact);
                    PAGE.Run(PAGE::"Contact Card", Contact);
                end;
            DATABASE::Currency:
                begin
                    RecordRef.SetTable(Currency);
                    PAGE.Run(PAGE::"Currency Card", Currency);
                end;
            DATABASE::Customer:
                begin
                    RecordRef.SetTable(Customer);
                    PAGE.Run(PAGE::"Customer Card", Customer);
                end;
            DATABASE::Vendor:
                begin
                    RecordRef.SetTable(Vendor);
                    PAGE.Run(PAGE::"Vendor Card", Vendor);
                end;
            DATABASE::Item:
                begin
                    RecordRef.SetTable(Item);
                    PAGE.Run(PAGE::"Item Card", Item);
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecordRef.SetTable(SalesInvoiceHeader);
                    PageManagement.PageRun(SalesInvoiceHeader);
                end;
            DATABASE::Resource:
                begin
                    RecordRef.SetTable(Resource);
                    PAGE.Run(PAGE::"Resource Card", Resource);
                end;
            DATABASE::"Salesperson/Purchaser":
                begin
                    RecordRef.SetTable(SalespersonPurchaser);
                    PAGE.Run(PAGE::"Salesperson/Purchaser Card", SalespersonPurchaser);
                end;
            DATABASE::"Unit of Measure":
                begin
                    RecordRef.SetTable(UnitOfMeasure);
                    // There is no Unit of Measure card. Open the list, filtered down to this instance.
                    PAGE.Run(PAGE::"Units of Measure", UnitOfMeasure);
                end;
            DATABASE::"Customer Price Group":
                begin
                    RecordRef.SetTable(CustomerPriceGroup);
                    // There is no Customer Price Group card. Open the list, filtered down to this instance.
                    PAGE.Run(PAGE::"Customer Price Groups", CustomerPriceGroup);
                end;
            else
                Error(NoCardPageActionDefinedForTableIdErr, RecordID.TableNo);
        end;
    end;

    procedure GetCRMEntityTypeName(TableId: Integer): Text
    var
        CRMTableId: Integer;
    begin
        if IsCRMTable(TableId) then begin
            CRMTableId := TableId;
            TableId := 0;
        end;
        exit(GetCRMEntityTypeName(TableId, CRMTableId));
    end;

    procedure GetCRMEntityTypeName(TableId: Integer; CRMTableId: Integer): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        CRMSetupDefaults.GetTableIDCRMEntityNameMapping(TempNameValueBuffer);
        if CRMTableId <> 0 then begin
            TempNameValueBuffer.SetRange(Value, Format(CRMTableId));
            if TempNameValueBuffer.FindFirst() then
                exit(TempNameValueBuffer.Name);
        end;
        if TableId <> 0 then begin
            TempNameValueBuffer.SetRange(Value, Format(TableId));
            if TempNameValueBuffer.FindFirst() then
                exit(TempNameValueBuffer.Name);
        end;
        Error(UnableToResolveCRMEntityNameFrmTableIDErr, TableId, CRMProductName.CDSServiceName());
    end;

    local procedure GetCoupledCRMID(RecordID: RecordID; var CRMID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(CRMIntegrationRecord.FindIDFromRecordID(RecordID, CRMID))
    end;

    local procedure DefineCouplingIfNotCoupled(RecordID: RecordID; var CRMID: Guid): Boolean
    var
        RecordRef: RecordRef;
    begin
        if GetCoupledCRMID(RecordID, CRMID) then
            exit(true);

        RecordRef.Open(RecordID.TableNo);
        if Confirm(StrSubstNo(ManageCouplingQst, RecordRef.Caption, CRMProductName.CDSServiceName()), false) then
            if DefineCoupling(RecordID) then
                exit(GetCoupledCRMID(RecordID, CRMID));
        exit(false);
    end;

    procedure DefineCoupling(RecordID: RecordID): Boolean
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CreateNew: Boolean;
        Synchronize: Boolean;
        Direction: Option;
        CRMID: Guid;
    begin
        if CRMCouplingManagement.DefineCoupling(RecordID, CRMID, CreateNew, Synchronize, Direction) then begin
            if CreateNew then
                CreateNewRecordsInCRM(RecordID)
            else
                if Synchronize then
                    PerformInitialSynchronization(RecordID, CRMID, Direction);
            exit(true);
        end;

        exit(false);
    end;

    local procedure DefineOptionMappingIfNotMapped(RecordID: RecordID; var CRMOptionId: Integer): Boolean
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(RecordID.TableNo);
        if Confirm(StrSubstNo(ManageCouplingQst, RecordRef.Caption, CRMProductName.CDSServiceName()), false) then
            if DefineOptionMapping(RecordID) then
                exit(GetMappedCRMOptionId(RecordID, CRMOptionId));
        exit(false);
    end;

    procedure DefineOptionMapping(RecordID: RecordID): Boolean
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CreateNew: Boolean;
        Synchronize: Boolean;
        Direction: Option;
        CRMOptionId: Integer;
    begin
        if CRMCouplingManagement.DefineOptionMapping(RecordID, CRMOptionId, CreateNew, Synchronize, Direction) then begin
            if CreateNew then
                CreateNewOptionsInCRM(RecordID)
            else
                if Synchronize then
                    PerformInitialOptionSynchronization(RecordID, CRMOptionId, Direction);
            exit(true);
        end;

        exit(false);
    end;

    procedure ManageCreateNewRecordFromCRM(TableID: Integer)
    begin
        // Extinct method. Kept for backward compatibility.
        case TableID of
            DATABASE::Contact:
                CreateNewContactFromCRM();
            DATABASE::Customer:
                CreateNewCustomerFromCRM();
        end;
    end;

    procedure CreateNewContactFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, DATABASE::Contact);
        PAGE.RunModal(PAGE::"CRM Contact List");
    end;

    procedure CreateNewCustomerFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, DATABASE::Customer);
        PAGE.RunModal(PAGE::"CRM Account List");
    end;

    procedure CreateNewVendorFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, DATABASE::Vendor);
        PAGE.RunModal(PAGE::"CRM Account List");
    end;

    [Scope('OnPrem')]
    procedure ShowCustomerCRMOpportunities(Customer: Record Customer)
    var
        CRMOpportunity: Record "CRM Opportunity";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled() then
            exit;

        if not DefineCouplingIfNotCoupled(Customer.RecordId, CRMID) then
            exit;

        CRMOpportunity.FilterGroup := 2;
        CRMOpportunity.SetRange(ParentAccountId, CRMID);
        CRMOpportunity.SetRange(StateCode, CRMOpportunity.StateCode::Open);
        CRMOpportunity.FilterGroup := 0;
        PAGE.Run(PAGE::"CRM Opportunity List", CRMOpportunity);
    end;

    [Scope('OnPrem')]
    procedure ShowCustomerCRMQuotes(Customer: Record Customer)
    var
        CRMQuote: Record "CRM Quote";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled() then
            exit;

        if not DefineCouplingIfNotCoupled(Customer.RecordId, CRMID) then
            exit;

        CRMQuote.FilterGroup := 2;
        CRMQuote.SetRange(CustomerId, CRMID);
        CRMQuote.SetRange(StateCode, CRMQuote.StateCode::Active);
        CRMQuote.FilterGroup := 0;
        PAGE.Run(PAGE::"CRM Sales Quote List", CRMQuote);
    end;

    [Scope('OnPrem')]
    procedure ShowCustomerCRMCases(Customer: Record Customer)
    var
        CRMIncident: Record "CRM Incident";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled() then
            exit;

        if not DefineCouplingIfNotCoupled(Customer.RecordId, CRMID) then
            exit;

        CRMIncident.FilterGroup := 2;
        CRMIncident.SetRange(CustomerId, CRMID);
        CRMIncident.SetRange(StateCode, CRMIncident.StateCode::Active);
        CRMIncident.FilterGroup := 2;
        PAGE.Run(PAGE::"CRM Case List", CRMIncident);
    end;

    [Scope('OnPrem')]
    procedure ResetIntTableMappingDefaultConfiguration(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EnqueueJobQueEntries: Boolean;
        IsTeamOwnershipModel: Boolean;
        IsHandled: Boolean;
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");

        if CRMConnectionSetup.Get() then
            EnqueueJobQueEntries := CRMConnectionSetup.DoReadCRMData() and CRMConnectionSetup.IsEnabled();

        IsTeamOwnershipModel := CDSIntegrationMgt.IsTeamOwnershipModelSelected();

        if IntegrationTableMapping.FindSet() then
            repeat
                case IntegrationTableMapping."Table ID" of
                    Database::"Salesperson/Purchaser":
                        CDSSetupDefaults.ResetSalesPeopleSystemUserMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Customer:
                        CDSSetupDefaults.ResetCustomerAccountMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Vendor:
                        CDSSetupDefaults.ResetVendorAccountMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Contact:
                        CDSSetupDefaults.ResetContactContactMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Currency:
                        CDSSetupDefaults.ResetCurrencyTransactionCurrencyMapping(IntegrationTableMapping.Name, true);
                    Database::"Payment Terms":
                        CDSSetupDefaults.ResetPaymentTermsMapping(IntegrationTableMapping.Name);
                    Database::"Shipment Method":
                        CDSSetupDefaults.ResetShipmentMethodMapping(IntegrationTableMapping.Name);
                    Database::"Shipping Agent":
                        CDSSetupDefaults.ResetShippingAgentMapping(IntegrationTableMapping.Name);
                    Database::"Unit of Measure":
                        CRMSetupDefaults.ResetUnitOfMeasureUoMScheduleMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::"Unit Group":
                        CRMSetupDefaults.ResetUnitGroupUoMScheduleMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::"Item Unit of Measure":
                        CRMSetupDefaults.ResetItemUnitOfMeasureUoMMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::"Resource Unit of Measure":
                        CRMSetupDefaults.ResetResourceUnitOfMeasureUoMMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::Item:
                        CRMSetupDefaults.ResetItemProductMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::Resource:
                        if IntegrationTableMapping."Integration Table ID" = Database::"CRM Product" then
                            CRMSetupDefaults.ResetResourceProductMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::"Customer Price Group":
                        CRMSetupDefaults.ResetCustomerPriceGroupPricelevelMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::"Sales Invoice Header":
                        CRMSetupDefaults.ResetSalesInvoiceHeaderInvoiceMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, EnqueueJobQueEntries);
                    Database::"Sales Invoice Line":
                        CRMSetupDefaults.ResetSalesInvoiceLineInvoiceMapping(IntegrationTableMapping.Name);
                    Database::Opportunity:
                        CRMSetupDefaults.ResetOpportunityMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel);
                    Database::"Sales Header":
                        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                            CRMSetupDefaults.ResetBidirectionalSalesOrderMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, EnqueueJobQueEntries);
                            CRMSetupDefaults.RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntries);
                            CRMSetupDefaults.RecreateArchivedSalesOrdersJobQueueEntry(EnqueueJobQueEntries);
                        end else begin
                            CRMSetupDefaults.ResetSalesOrderMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, EnqueueJobQueEntries);
                            CRMSetupDefaults.RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntries);
                            CRMSetupDefaults.RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntries);
                        end;
                    Database::"Sales Line":
                        CRMSetupDefaults.ResetBidirectionalSalesOrderLineMapping(IntegrationTableMapping.Name);
                    else begin
                        OnBeforeHandleCustomIntegrationTableMapping(IsHandled, IntegrationTableMapping.Name, IntegrationTableMapping, EnqueueJobQueEntries);
                        if not IsHandled then begin
                            if Confirm(ResetAllCustomIntegrationTableMappingsLbl) then begin
                                if CDSConnectionSetup.Get() then
                                    CDSSetupDefaults.SetCustomIntegrationsTableMappings(CDSConnectionSetup);
                                if CRMConnectionSetup.Get() then
                                    CRMSetupDefaults.SetCustomIntegrationsTableMappings(CRMConnectionSetup);
                            end;
                            IsHandled := true;
                        end;
                    end;
                end;
                AddExtraFieldMappings(IntegrationTableMapping);
            until IntegrationTableMapping.Next() = 0;
    end;

    internal procedure AddExtraFieldMappings(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Opportunity: Record Opportunity;
        TempCRMAccount: Record "CRM Account" temporary;
        TempCRMContact: Record "CRM Contact" temporary;
        TempCRMSystemUser: Record "CRM Systemuser" temporary;
        TempCRMOpportunity: Record "CRM Opportunity" temporary;
    begin
        case IntegrationTableMapping."Table ID" of
            Database::Customer:
                begin
                    if IntegrationTableMapping."Integration Table ID" <> Database::"CRM Account" then
                        exit;

                    AddFieldMapping(IntegrationTableMapping, Customer.FieldNo("No."), TempCRMAccount.FieldNo(AccountNumber), IntegrationFieldMapping.Direction::ToIntegrationTable, false);
                    AddFieldMapping(IntegrationTableMapping, Customer.FieldNo("Mobile Phone No."), TempCRMAccount.FieldNo(Telephone2), IntegrationFieldMapping.Direction::Bidirectional, false);
                end;
            Database::Vendor:
                begin
                    if IntegrationTableMapping."Integration Table ID" <> Database::"CRM Account" then
                        exit;

                    AddFieldMapping(IntegrationTableMapping, Vendor.FieldNo("No."), TempCRMAccount.FieldNo(AccountNumber), IntegrationFieldMapping.Direction::ToIntegrationTable, false);
                    AddFieldMapping(IntegrationTableMapping, Vendor.FieldNo("Mobile Phone No."), TempCRMAccount.FieldNo(Telephone2), IntegrationFieldMapping.Direction::Bidirectional, false);
                end;
            Database::Contact:
                begin
                    if IntegrationTableMapping."Integration Table ID" <> Database::"CRM Contact" then
                        exit;

                    AddFieldMapping(IntegrationTableMapping, Contact.FieldNo("Salutation Code"), TempCRMContact.FieldNo(Salutation), IntegrationFieldMapping.Direction::Bidirectional, false);
                end;
            Database::"Salesperson/Purchaser":
                begin
                    if IntegrationTableMapping."Integration Table ID" <> Database::"CRM Systemuser" then
                        exit;

                    AddFieldMapping(IntegrationTableMapping, SalespersonPurchaser.FieldNo("Job Title"), TempCRMSystemUser.FieldNo(JobTitle), IntegrationFieldMapping.Direction::Bidirectional, false);
                    AddFieldMapping(IntegrationTableMapping, SalespersonPurchaser.FieldNo("E-Mail 2"), TempCRMSystemUser.FieldNo(PersonalEMailAddress), IntegrationFieldMapping.Direction::Bidirectional, false);
                end;
            Database::Opportunity:
                begin
                    if IntegrationTableMapping."Integration Table ID" <> Database::"CRM Opportunity" then
                        exit;

                    AddFieldMapping(IntegrationTableMapping, Opportunity.FieldNo("Date Closed"), TempCRMOpportunity.FieldNo(ActualCloseDate), IntegrationFieldMapping.Direction::ToIntegrationTable, false);
                    AddFieldMapping(IntegrationTableMapping, Opportunity.FieldNo("Probability %"), TempCRMOpportunity.FieldNo(CloseProbability), IntegrationFieldMapping.Direction::ToIntegrationTable, false);
                    AddFieldMapping(IntegrationTableMapping, Opportunity.FieldNo("Calcd. Current Value (LCY)"), TempCRMOpportunity.FieldNo(ActualValue), IntegrationFieldMapping.Direction::ToIntegrationTable, false);
                end;
        end;
        OnAfterAddExtraFieldMappings(IntegrationTableMapping.Name);
    end;

    local procedure AddFieldMapping(IntegrationTableMapping: Record "Integration Table Mapping"; FieldNo: Integer; IntegrationTableFieldNo: Integer; Direction: Option; Enabled: Boolean);
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Field No.", FieldNo);
        if not IntegrationFieldMapping.IsEmpty() then
            exit;

        IntegrationFieldMapping.SetRange("Field No.");
        IntegrationFieldMapping.SetRange("Integration Table Field No.", IntegrationTableFieldNo);
        if not IntegrationFieldMapping.IsEmpty() then
            exit;

        IntegrationFieldMapping.CreateRecord(IntegrationTableMapping.Name, FieldNo, IntegrationTableFieldNo, Direction, '', true, false, Enabled, '', false);
    end;

    procedure GetNoOfCRMOpportunities(Customer: Record Customer): Integer
    var
        CRMOpportunity: Record "CRM Opportunity";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled() then
            exit(0);

        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit(0);

        CRMOpportunity.SetRange(ParentAccountId, CRMID);
        CRMOpportunity.SetRange(StateCode, CRMOpportunity.StateCode::Open);
        exit(CRMOpportunity.Count);
    end;

    procedure GetNoOfCRMQuotes(Customer: Record Customer): Integer
    var
        CRMQuote: Record "CRM Quote";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled() then
            exit(0);

        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit(0);

        CRMQuote.SetRange(CustomerId, CRMID);
        CRMQuote.SetRange(StateCode, CRMQuote.StateCode::Active);
        exit(CRMQuote.Count);
    end;

    procedure GetNoOfCRMCases(Customer: Record Customer): Integer
    var
        CRMIncident: Record "CRM Incident";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled() then
            exit(0);

        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit(0);

        CRMIncident.SetRange(StateCode, CRMIncident.StateCode::Active);
        CRMIncident.SetRange(CustomerId, CRMID);
        exit(CRMIncident.Count);
    end;

    local procedure GetSelectedMultipleSyncDirection(IntegrationTableMapping: Record "Integration Table Mapping"): Integer
    var
        SynchronizeNowQuestion: Text;
        AllowedDirection: Integer;
        RecommendedDirection: Integer;
        SelectedDirection: Integer;
        IsHandled: Boolean;
    begin
        AllowedDirection := IntegrationTableMapping.Direction;
        RecommendedDirection := AllowedDirection;
        case AllowedDirection of
            IntegrationTableMapping.Direction::Bidirectional:
                begin
                    SelectedDirection := StrMenu(UpdateNowUniDirectionQst, RecommendedDirection, UpdateMultipleNowTitleTxt);
                    if SelectedDirection = 0 then
                        SelectedDirection := -1;
                    exit(SelectedDirection);
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                SynchronizeNowQuestion := StrSubstNo(UpdateMultipleNowFromCRMQst, CRMProductName.CDSServiceName());
            else
                SynchronizeNowQuestion := StrSubstNo(UpdateMultipleNowToCRMQst, CRMProductName.CDSServiceName());
        end;

        IsHandled := false;
        OnBeforeSynchronyzeNowQuestion(AllowedDirection, IsHandled);
        if IsHandled then
            exit(AllowedDirection);

        if Confirm(SynchronizeNowQuestion, true) then
            exit(AllowedDirection);
        exit(-1); // user canceled the process
    end;

    local procedure GetSelectedSingleSyncDirection(IntegrationTableMapping: Record "Integration Table Mapping"; RecordRef: RecordRef; CRMID: Guid; var RecommendedDirectionIgnored: Boolean): Integer
    var
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        CRMRecordRef: RecordRef;
        RecordIDDescr: Text;
        SynchronizeNowQuestion: Text;
        AllowedDirection: Integer;
        RecommendedDirection: Integer;
        SelectedDirection: Integer;
        RecordModified: Boolean;
        CRMRecordModified: Boolean;
        BothModified: Boolean;
        DefaultAnswer: Boolean;
        FieldsModified: Boolean;
        BidirectionalFieldsModified: Boolean;
    begin
        AllowedDirection := IntegrationTableMapping.Direction;

        // Determine which sides were modified since last synch
        IntegrationTableMapping.GetRecordRef(CRMID, CRMRecordRef);
        RecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecordRef);
        CRMRecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        BothModified := RecordModified and CRMRecordModified;
        RecordIDDescr := Format(RecordRef.RecordId, 0, 1);
        if BothModified then
            // Changes on both sides. Bidirectional: warn user. Unidirectional: confirm and exit.
            case AllowedDirection of
                IntegrationTableMapping.Direction::Bidirectional:
                    begin
                        IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, RecordRef, CRMRecordRef, FieldsModified, BidirectionalFieldsModified);
                        if BidirectionalFieldsModified then
                            Message(BothRecordsModifiedBiDirectionalConflictMsg, RecordRef.Caption, CRMRecordRef.Caption, CRMProductName.CDSServiceName())
                        else begin
                            if not FieldsModified then
                                IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, CRMRecordRef, RecordRef, FieldsModified, BidirectionalFieldsModified);
                            if FieldsModified then
                                Message(BothRecordsModifiedBiDirectionalNoConflictMsg, RecordRef.Caption, CRMRecordRef.Caption, CRMProductName.CDSServiceName());
                        end;
                    end;
                IntegrationTableMapping.Direction::ToIntegrationTable:
                    begin
                        IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, RecordRef, CRMRecordRef, FieldsModified, BidirectionalFieldsModified);
                        if not FieldsModified then
                            exit(AllowedDirection);
                        if Confirm(BothRecordsModifiedToCRMQst, false, RecordIDDescr, CRMRecordRef.Caption, PRODUCTNAME.Short(), CRMProductName.CDSServiceName()) then
                            exit(AllowedDirection);
                        exit(-1);
                    end;
                IntegrationTableMapping.Direction::FromIntegrationTable:
                    begin
                        IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, CRMRecordRef, RecordRef, FieldsModified, BidirectionalFieldsModified);
                        if not FieldsModified then
                            exit(AllowedDirection);
                        if Confirm(BothRecordsModifiedToNAVQst, false, RecordIDDescr, CRMRecordRef.Caption, PRODUCTNAME.Short(), CRMProductName.CDSServiceName()) then
                            exit(AllowedDirection);
                        exit(-1);
                    end;
            end;

        // Zero or one side changed. Synch for zero too because dependent objects could have changed.
        case AllowedDirection of
            IntegrationTableMapping.Direction::Bidirectional:
                begin
                    if BothModified and BidirectionalFieldsModified then begin
                        RecommendedDirection := IntegrationTableMapping.Direction::ToIntegrationTable;
                        SelectedDirection := StrMenu(UpdateNowUniDirectionQst, RecommendedDirection, StrSubstNo(UpdateOneNowTitleTxt, RecordIDDescr));
                        if SelectedDirection = 0 then
                            SelectedDirection := -1;
                    end else begin
                        if RecordModified = CRMRecordModified then
                            RecommendedDirection := IntegrationTableMapping.Direction::Bidirectional
                        else
                            if CRMRecordModified then
                                RecommendedDirection := IntegrationTableMapping.Direction::FromIntegrationTable
                            else
                                RecommendedDirection := IntegrationTableMapping.Direction::ToIntegrationTable;
                        SelectedDirection := StrMenu(UpdateNowBiDirectionQst, RecommendedDirection, StrSubstNo(UpdateOneNowTitleTxt, RecordIDDescr));
                        case SelectedDirection of
                            0:
                                SelectedDirection := -1;
                            3:
                                SelectedDirection := IntegrationTableMapping.Direction::Bidirectional;
                        end;
                    end;
                    RecommendedDirectionIgnored := SelectedDirection <> RecommendedDirection;
                    exit(SelectedDirection);
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                if RecordModified then
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowFromOldCRMQst, RecordIDDescr, PRODUCTNAME.Short(), CRMProductName.CDSServiceName())
                else begin
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowFromCRMQst, RecordIDDescr, CRMProductName.CDSServiceName());
                    DefaultAnswer := true;
                end;
            else
                if CRMRecordModified then
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowToModifiedCRMQst, RecordIDDescr, PRODUCTNAME.Short(), CRMProductName.CDSServiceName())
                else begin
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowToCRMQst, RecordIDDescr, CRMProductName.CDSServiceName());
                    DefaultAnswer := true;
                end;
        end;

        if Confirm(SynchronizeNowQuestion, DefaultAnswer) then
            exit(AllowedDirection);

        exit(-1); // user canceled the process
    end;

    local procedure DeleteIntegrationRecordByBCID(var BCRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMIntegrationRecord.FindByRecordID(BCRecordRef.RecordId()) then begin
            CRMIntegrationRecord.Delete();
            Commit();
        end;
    end;

    local procedure DeleteIntegrationRecordByCRMID(var CRMRecordRef: RecordRef; var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMID: Guid;
    begin
        CRMID := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
        if CRMIntegrationRecord.FindByCRMID(CRMID) then begin
            CRMIntegrationRecord.Delete();
            Commit();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnUpdateConflictDetected', '', false, false)]
    local procedure HandleOnUpdateConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var UpdateConflictHandled: Boolean; var SkipRecord: Boolean)
    begin
        if UpdateConflictHandled then
            exit;

        if not (IsCDSIntegrationEnabled() or IsCRMIntegrationEnabled()) then
            exit;

        case IntegrationTableMapping."Update-Conflict Resolution" of
            IntegrationTableMapping."Update-Conflict Resolution"::"Get Update from Integration":
                begin
                    UpdateConflictHandled := true;
                    if SourceRecordRef.Number() = IntegrationTableMapping."Integration Table ID" then begin
                        SkipRecord := false;
                        Session.LogMessage('0000CUC', UpdateConflictHandledFromIntTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end else begin
                        SkipRecord := true;
                        Session.LogMessage('0000D3O', UpdateConflictHandledSkipTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
                end;
            IntegrationTableMapping."Update-Conflict Resolution"::"Send Update to Integration":
                begin
                    UpdateConflictHandled := true;
                    if SourceRecordRef.Number() = IntegrationTableMapping."Table ID" then begin
                        SkipRecord := false;
                        Session.LogMessage('0000CUD', UpdateConflictHandledToIntTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end else begin
                        SkipRecord := true;
                        Session.LogMessage('0000D3P', UpdateConflictHandledSkipTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnDeletionConflictDetected', '', false, false)]
    local procedure HandleOnDeletionConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DeletionConflictHandled: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMID: Guid;
    begin
        if DeletionConflictHandled then
            exit;

        if not (IsCDSIntegrationEnabled() or IsCRMIntegrationEnabled()) then
            exit;

        case IntegrationTableMapping."Deletion-Conflict Resolution" of
            IntegrationTableMapping."Deletion-Conflict Resolution"::"Remove Coupling":
                begin
                    if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then
                        DeletionConflictHandled := RemoveCoupling(SourceRecordRef.RecordId(), false)
                    else begin
                        CRMID := SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
                        DeletionConflictHandled := RemoveCoupling(IntegrationTableMapping."Table ID", IntegrationTableMapping."Integration Table ID", CRMID, false);
                    end;

                    if IntegrationTableMapping."Table ID" = Database::"Sales Line" then
                        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                            if SourceRecordRef.Delete() then;

                    if DeletionConflictHandled then
                        Session.LogMessage('0000CUE', DeletionConflictHandledRemoveCouplingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                end;
            IntegrationTableMapping."Deletion-Conflict Resolution"::"Restore Records":
                begin
                    if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then
                        DeleteIntegrationRecordByBCID(SourceRecordRef)
                    else
                        DeleteIntegrationRecordByCRMID(SourceRecordRef, IntegrationTableMapping);

                    DeletionConflictHandled := true;
                    Session.LogMessage('0000CUF', DeletionConflictHandledRestoreRecordTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleCRMRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        RecRef: RecordRef;
    begin
        if not CRMConnectionSetup.Get() then begin
            if not CRMConnectionSetup.WritePermission then begin
                Session.LogMessage('0000CLV', NoPermissionsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                exit;
            end;
            CRMConnectionSetup.Init();
            CRMConnectionSetup.Insert();
        end;

        RecRef.GetTable(CRMConnectionSetup);
        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        if not CRMConnectionSetup."Is Enabled" then
            ServiceConnection.Status := ServiceConnection.Status::Disabled
        else
            if CRMConnectionSetup.TestConnection() then
                ServiceConnection.Status := ServiceConnection.Status::Connected
            else
                ServiceConnection.Status := ServiceConnection.Status::Error;
        ServiceConnection.InsertServiceConnectionExtended(
          ServiceConnection, RecRef.RecordId, CRMConnectionSetup.TableCaption(), CRMConnectionSetup."Server Address", PAGE::"CRM Connection Setup",
          PAGE::"CRM Connection Setup Wizard");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnGetIntegrationSolutions', '', false, false)]
    local procedure HandleOnGetIntegrationSolutions(var SolutionUniqueNameList: List of [Text])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Is Enabled" then
                SolutionUniqueNameList.Add(CRMProductName.UNIQUE());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnGetIntegrationRequiredRoles', '', false, false)]
    local procedure HandleOnGetIntegrationRequiredRoles(var RequiredRoleIdList: List of [Guid])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Is Enabled" then begin
                RequiredRoleIdList.Add(GetIntegrationAdminRoleID());
                RequiredRoleIdList.Add(GetIntegrationUserRoleID());
            end;
    end;

    procedure ClearState()
    begin
        CRMIntegrationEnabledState := CRMIntegrationEnabledState::" "
    end;

#if not CLEAN25
    [Obsolete('Field Service is moved to Field Service Integration app.', '25.0')]
    procedure ClearFSState()
    begin
        FSIntegrationEnabledState := FSIntegrationEnabledState::" "
    end;
#endif

    [Scope('OnPrem')]
    procedure GetLastErrorMessage(): Text
    var
        ErrorObject: DotNet Exception;
    begin
        ErrorObject := GetLastErrorObject();
        if IsNull(ErrorObject) then
            exit('');
        if StrPos(ErrorObject.GetType().Name, 'NavCrmException') > 0 then
            if not IsNull(ErrorObject.InnerException) then
                exit(ErrorObject.InnerException.Message);
        exit(GetLastErrorText);
    end;

#if not CLEAN25
    [Obsolete('Replaced by ImportCRMSolution procedure with SolutionImportFailed argument and SecretText parameters for AdminUserPassword and AccessToken.', '25.0')]
    [TryFunction]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure ImportCRMSolution(ServerAddress: Text; IntegrationUserEmail: Text; AdminUserEmail: Text; AdminUserPassword: Text; AccessToken: Text; AdminADDomain: Text; ProxyVersion: Integer; ForceRedeploy: Boolean)
    var
        SolutionImportFailed: Boolean;
        SecretAdminUserPassword, SecretAccessToken : SecretText;
    begin
        ImportCRMSolution(ServerAddress, IntegrationUserEmail, AdminUserEmail, SecretAdminUserPassword, SecretAccessToken, AdminADDomain, ProxyVersion, ForceRedeploy, SolutionImportFailed);
    end;
#endif

    [TryFunction]
    [Scope('OnPrem')]
    procedure ImportCRMSolution(ServerAddress: Text; IntegrationUserEmail: Text; AdminUserEmail: Text; AdminUserPassword: SecretText; AccessToken: SecretText; AdminADDomain: Text; ProxyVersion: Integer; ForceRedeploy: Boolean; var SolutionImportFailed: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMRole: Record "CRM Role";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        PageCDSConnectionSetup: Page "CDS Connection Setup";
        CRMHelper: DotNet CrmHelper;
        UserGUID: Guid;
        IntegrationAdminRoleGUID: Guid;
        IntegrationUserRoleGUID: Guid;
        SalesProIntegrationRoleGUID: Guid;
        EmptyGuid: Guid;
        DefaultOwningTeamGUID: Guid;
        TempConnectionString: SecretText;
        TempConnectionStringWithPlaceholders: Text;
        SolutionInstalled: Boolean;
        SolutionOutdated: Boolean;
        ImportSolution: Boolean;
    begin
        CheckConnectRequiredFields(ServerAddress, IntegrationUserEmail);
        CDSConnectionSetup.Get();
        if not AccessToken.IsEmpty() then begin
            TempConnectionStringWithPlaceholders :=
                StrSubstNo(OAuthConnectionStringFormatTok, ServerAddress, '%1', ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup));
            TempConnectionString := SecretStrSubstNo(TempConnectionStringWithPlaceholders, AccessToken);
        end
        else
            if AdminADDomain <> '' then begin
                TempConnectionStringWithPlaceholders := StrSubstNo(
                    ConnectionStringFormatTok, ServerAddress, AdminUserEmail, '%1', ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup, AdminADDomain));
                TempConnectionString := SecretStrSubstNo(TempConnectionStringWithPlaceholders, AdminUserPassword);
            end
            else begin
                TempConnectionStringWithPlaceholders := StrSubstNo(
                    ConnectionStringFormatTok, ServerAddress, AdminUserEmail, '%1', ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup));
                TempConnectionString := SecretStrSubstNo(TempConnectionStringWithPlaceholders, AdminUserPassword)
            end;

        if CDSConnectionSetup."Authentication Type" = CDSConnectionSetup."Authentication Type"::OAuth then
            TempConnectionString := CDSIntegrationImpl.ReplaceUserNamePasswordInConnectionString(CDSConnectionSetup, AdminUserEmail, AdminUserPassword);

        if not InitializeCRMConnection(CRMHelper, TempConnectionString) then
            ProcessConnectionFailures();

        UserGUID := CRMHelper.GetUserId(IntegrationUserEmail);
        if IsNullGuid(UserGUID) then
            Error(UserDoesNotExistCRMErr, IntegrationUserEmail, CRMProductName.CDSServiceName());

        SolutionInstalled := CRMHelper.CheckSolutionPresence(MicrosoftDynamicsNavIntegrationTxt);
        if SolutionInstalled then
            SolutionOutdated := IsSolutionOutdated(TempConnectionString);

        if ForceRedeploy then
            ImportSolution := (not SolutionInstalled) or SolutionOutdated
        else
            ImportSolution := not SolutionInstalled;

        if ImportSolution then begin
            if not ImportDefaultCRMSolution(CRMHelper) then begin
                SolutionImportFailed := true;
                ProcessConnectionFailures();
            end;

            if CrmHelper.GetPrivilegeId(SalesProDefaultSettingsPrivilegeNameTxt) <> EmptyGuid then
                if not ImportDefaultSalesProSolution(CRMHelper) then begin
                    SolutionImportFailed := true;
                    ProcessConnectionFailures();
                end else
                    Session.LogMessage('0000JFP', SalesProIntegrationSolutionImportedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end;

        IntegrationAdminRoleGUID := CRMHelper.GetRoleId(GetIntegrationAdminRoleID());
        IntegrationUserRoleGUID := CRMHelper.GetRoleId(GetIntegrationUserRoleID());
        SalesProIntegrationRoleGUID := CRMHelper.GetRoleId(GetSalesProIntegrationRoleId());
        if not CRMHelper.CheckRoleAssignedToUser(UserGUID, IntegrationAdminRoleGUID) then
            CRMHelper.AssociateUserWithRole(UserGUID, IntegrationAdminRoleGUID);
        if not CRMHelper.CheckRoleAssignedToUser(UserGUID, IntegrationUserRoleGUID) then
            CRMHelper.AssociateUserWithRole(UserGUID, IntegrationUserRoleGUID);
        if SalesProIntegrationRoleGUID <> EmptyGuid then
            if not CRMHelper.CheckRoleAssignedToUser(UserGUID, SalesProIntegrationRoleGUID) then
                CRMHelper.AssociateUserWithRole(UserGUID, SalesProIntegrationRoleGUID);

        if CDSIntegrationImpl.IsIntegrationEnabled() then begin
            CDSIntegrationImpl.RegisterConnection();
            CDSIntegrationImpl.ActivateConnection();
            CDSConnectionSetup.Get();
            DefaultOwningTeamGUID := CDSIntegrationImpl.GetOwningTeamId(CDSConnectionSetup);
            if IsNullGuid(DefaultOwningTeamGUID) then begin
                Session.LogMessage('0000GDK', TeamNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(TeamNotFoundErr, CDSIntegrationImpl.GetDefaultBusinessUnitName(), PageCDSConnectionSetup.Caption);
            end;
            CRMRole.SetRange(ParentRoleId, IntegrationAdminRoleGUID);
            CRMRole.SetRange(BusinessUnitId, CDSIntegrationImpl.GetCoupledBusinessUnitId());
            if not CRMRole.FindFirst() then begin
                Session.LogMessage('0000BKQ', RoleNotFoundForBusinessUnitTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(IntegrationRoleNotFoundErr, GetIntegrationAdminRoleID(), CDSIntegrationImpl.GetDefaultBusinessUnitName());
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                Session.LogMessage('0000BKR', CannotAssignRoleToTeamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
            CRMRole.SetRange(ParentRoleId, IntegrationUserRoleGUID);
            CRMRole.SetRange(BusinessUnitId, CDSIntegrationImpl.GetCoupledBusinessUnitId());
            if not CRMRole.FindFirst() then begin
                Session.LogMessage('0000BKS', RoleNotFoundForBusinessUnitTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(IntegrationRoleNotFoundErr, GetIntegrationUserRoleID(), CDSIntegrationImpl.GetDefaultBusinessUnitName());
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                Session.LogMessage('0000BKT', CannotAssignRoleToTeamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
            if SalesProIntegrationRoleGUID <> EmptyGuid then begin
                CRMRole.SetRange(ParentRoleId, SalesProIntegrationRoleGUID);
                CRMRole.SetRange(BusinessUnitId, CDSIntegrationImpl.GetCoupledBusinessUnitId());
                if not CRMRole.FindFirst() then begin
                    Session.LogMessage('0000JFN', RoleNotFoundForBusinessUnitTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    Error(IntegrationRoleNotFoundErr, SalesProIntegrationRoleGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName());
                end;
                if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                    Session.LogMessage('0000JFO', CannotAssignRoleToTeamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
                end;
            end;
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by ImportFSSolution procedure with SolutionImportFailed argument.', '25.0')]
    [TryFunction]
    [NonDebuggable]
    internal procedure ImportFSSolution(ServerAddress: Text; IntegrationUserEmail: Text; AdminUserEmail: Text; AdminUserPassword: Text; AccessToken: Text; AdminADDomain: Text; ProxyVersion: Integer; ForceRedeploy: Boolean)
    var
        ImportSolutionFailed: Boolean;
    begin
        ImportFSSolution(ServerAddress, IntegrationUserEmail, AdminUserEmail, AdminUserPassword, AccessToken, AdminADDomain, ProxyVersion, ForceRedeploy, ImportSolutionFailed);
    end;

    [TryFunction]
    [NonDebuggable]
    internal procedure ImportFSSolution(ServerAddress: Text; IntegrationUserEmail: Text; AdminUserEmail: Text; AdminUserPassword: SecretText; AccessToken: SecretText; AdminADDomain: Text; ProxyVersion: Integer; ForceRedeploy: Boolean; ImportSolutionFailed: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMRole: Record "CRM Role";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        PageCDSConnectionSetup: Page "CDS Connection Setup";
        CRMHelper: DotNet CrmHelper;
        UserGUID: Guid;
        IntegrationRoleGUID: Guid;
        FieldSecurityProfileGUID: Guid;
        DefaultOwningTeamGUID: Guid;
        TempConnectionStringWithPlaceholders: Text;
        TempConnectionString: SecretText;
        SolutionInstalled: Boolean;
        SolutionOutdated: Boolean;
        ImportSolution: Boolean;
    begin
        CheckConnectRequiredFields(ServerAddress, IntegrationUserEmail);
        CDSConnectionSetup.Get();
        if not AccessToken.IsEmpty() then begin
            TempConnectionStringWithPlaceholders :=
                StrSubstNo(OAuthConnectionStringFormatTok, ServerAddress, '%1', ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup));
            TempConnectionString := SecretStrSubstNo(TempConnectionStringWithPlaceholders, AccessToken);
        end
        else
            if AdminADDomain <> '' then begin
                TempConnectionStringWithPlaceholders := StrSubstNo(
                    ConnectionStringFormatTok, ServerAddress, AdminUserEmail, '%1', ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup, AdminADDomain));
                TempConnectionString := SecretStrSubstNo(TempConnectionStringWithPlaceholders, AdminUserPassword);
            end
            else begin
                TempConnectionStringWithPlaceholders := StrSubstNo(
                    ConnectionStringFormatTok, ServerAddress, AdminUserEmail, '%1', ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup));
                TempConnectionString := SecretStrSubstNo(TempConnectionStringWithPlaceholders, AdminUserPassword);
            end;

        if CDSConnectionSetup."Authentication Type" = CDSConnectionSetup."Authentication Type"::OAuth then
            TempConnectionString := CDSIntegrationImpl.ReplaceUserNamePasswordInConnectionstring(CDSConnectionSetup, AdminUserEmail, AdminUserPassword);

        if not InitializeFSConnection(CRMHelper, TempConnectionString) then
            ProcessConnectionFailures();

        UserGUID := CRMHelper.GetUserId(IntegrationUserEmail);
        if IsNullGuid(UserGUID) then
            Error(UserDoesNotExistCRMErr, IntegrationUserEmail, CRMProductName.CDSServiceName());

        SolutionInstalled := CRMHelper.CheckSolutionPresence(MicrosoftDynamicsFSIntegrationTxt);
        if SolutionInstalled then
            SolutionOutdated := IsSolutionOutdated(TempConnectionString, MicrosoftDynamicsFSIntegrationTxt);

        if ForceRedeploy then
            ImportSolution := (not SolutionInstalled) or SolutionOutdated
        else
            ImportSolution := not SolutionInstalled;

        if ImportSolution then
            if not ImportDefaultFSSolution(CRMHelper) then begin
                ImportSolutionFailed := true;
                ProcessConnectionFailures();
            end;

        IntegrationRoleGUID := CRMHelper.GetRoleId(GetFieldServiceIntegrationRoleID());
        if not CRMHelper.CheckRoleAssignedToUser(UserGUID, IntegrationRoleGUID) then
            CRMHelper.AssociateUserWithRole(UserGUID, IntegrationRoleGUID);

        if CDSIntegrationImpl.IsIntegrationEnabled() then begin
            CDSIntegrationImpl.RegisterConnection();
            CDSIntegrationImpl.ActivateConnection();
            CDSConnectionSetup.Get();
            DefaultOwningTeamGUID := CDSIntegrationImpl.GetOwningTeamId(CDSConnectionSetup);
            if IsNullGuid(DefaultOwningTeamGUID) then begin
                Session.LogMessage('0000M99', TeamNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(TeamNotFoundErr, CDSIntegrationImpl.GetDefaultBusinessUnitName(), PageCDSConnectionSetup.Caption);
            end;
            CRMRole.SetRange(ParentRoleId, IntegrationRoleGUID);
            CRMRole.SetRange(BusinessUnitId, CDSIntegrationImpl.GetCoupledBusinessUnitId());
            if not CRMRole.FindFirst() then begin
                Session.LogMessage('0000M9A', RoleNotFoundForBusinessUnitTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(IntegrationRoleNotFoundErr, IntegrationRoleGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName());
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                Session.LogMessage('0000M9B', CannotAssignRoleToTeamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                Session.LogMessage('0000M9C', CannotAssignRoleToTeamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
        end;

        FieldSecurityProfileGUID := TextToGuid(FieldServiceAdministratorProfileIdLbl);
        if not CRMHelper.CheckFieldSecurityProfileAssignedToUser(UserGUID, FieldSecurityProfileGUID) then
            CRMHelper.AssociateUserWithFieldSecurityProfile(UserGUID, FieldSecurityProfileGUID);

        if not CRMHelper.CheckFieldSecurityProfileAssignedToUser(UserGUID, FieldSecurityProfileGUID) then begin
            Session.LogMessage('0000MEG', CannotAssignFieldSecurityProfileToUserTelemetryLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            if Confirm(StrSubstNo(CannotAssignFieldSecurityProfileToUserQst, CDSConnectionSetup."Server Address")) then
                CDSIntegrationImpl.ShowIntegrationUser(CDSConnectionSetup);
            Error('');
        end
    end;

    local procedure TextToGuid(TextVar: Text): Guid
    var
        GuidVar: Guid;
    begin
        if not Evaluate(GuidVar, TextVar) then;
        exit(GuidVar);
    end;
#endif

    [NonDebuggable]
    local procedure IsSolutionOutdated(TempConnectionString: SecretText): Boolean
    begin
        exit(IsSolutionOutdated(TempConnectionString, MicrosoftDynamicsNavIntegrationTxt));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure IsSolutionOutdated(TempConnectionString: SecretText; SolutionUniqueName: Text[65]): Boolean
    var
        CDSSolution: Record "CDS Solution";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        Version: DotNet Version;
        TempConnectionName: Text;
        SolutionOutdated: Boolean;
    begin
        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        if HasTableConnection(TableConnectionType::CRM, TempConnectionName) then
            UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
        RegisterTableConnection(TableConnectionType::CRM, TempConnectionName, TempConnectionString.Unwrap());
        SetDefaultTableConnection(TableConnectionType::CRM, TempConnectionName, true);
        SolutionOutdated := true;
        CDSSolution.SetRange(UniqueName, SolutionUniqueName);
        if CDSSolution.FindFirst() then
            if Version.TryParse(CDSSolution.Version, Version) then
                SolutionOutdated := Version.CompareTo(NavTenantSettingsHelper.GetPlatformVersion()) < 0;
        UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
        exit(SolutionOutdated);
    end;

    [TryFunction]
    local procedure ImportDefaultCRMSolution(var CRMHelper: DotNet CrmHelper)
    begin
        CRMHelper.ImportDefaultCrmSolution();
    end;

#if not CLEAN25
    [TryFunction]
    local procedure ImportDefaultFSSolution(var CRMHelper: DotNet CrmHelper)
    begin
        CRMHelper.ImportDefaultFieldServiceSolution()
    end;
#endif

    [TryFunction]
    local procedure ImportDefaultSalesProSolution(var CRMHelper: DotNet CrmHelper)
    begin
        CRMHelper.ImportDefaultSalesProSolution();
    end;

    procedure CheckConnectRequiredFields(ServerAddress: Text; IntegrationUserEmail: Text)
    begin
        if (IntegrationUserEmail = '') or (ServerAddress = '') then
            Error(EmailAndServerAddressEmptyErr);
    end;

    procedure CheckModifyCRMConnectionURL(var ServerAddress: Text[250])
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        UriHelper: DotNet Uri;
        UriHelper2: DotNet Uri;
        UriKindHelper: DotNet UriKind;
        UriPartialHelper: DotNet UriPartial;
        ProposedUri: Text[250];
    begin
        if (ServerAddress = '') or (ServerAddress = '@@test@@') then
            exit;

        ServerAddress := DelChr(ServerAddress, '<>');

        if not UriHelper.TryCreate(ServerAddress, UriKindHelper.Absolute, UriHelper2) then
            if not UriHelper.TryCreate('https://' + ServerAddress, UriKindHelper.Absolute, UriHelper2) then
                Error(InvalidUriErr);

        if UriHelper2.Scheme <> 'https' then begin
            if not CRMSetupDefaults.GetAllowNonSecureConnections() then
                Error(MustUseHttpsErr, CRMProductName.SHORT());
            if UriHelper2.Scheme <> 'http' then
                Error(MustUseHttpOrHttpsErr, UriHelper2.Scheme, CRMProductName.SHORT());
        end;

        ProposedUri := UriHelper2.GetLeftPart(UriPartialHelper.Authority);

        // Test that a specific port number is given
        if ((UriHelper2.Port = 443) or (UriHelper2.Port = 80)) and (LowerCase(ServerAddress) <> LowerCase(ProposedUri)) then
            if Confirm(StrSubstNo(ReplaceServerAddressQst, ServerAddress, ProposedUri)) then
                ServerAddress := ProposedUri;
    end;

    procedure GetOrganizationFromUrl(ServerAddress: Text[250]) orgName: Text
    var
        UriHelper: DotNet Uri;
        UriHelper2: DotNet Uri;
        UriKindHelper: DotNet UriKind;
    begin
        // Return the organization name from an OnPremise URL which is in the form
        // http://crm-server:port/organization-name
        // Notice that TryCreate will fail if the port is not a number

        if (ServerAddress = '') or (ServerAddress = '@@test@@') then
            exit('');

        ServerAddress := DelChr(ServerAddress, '<>');

        if not UriHelper.TryCreate(ServerAddress, UriKindHelper.Absolute, UriHelper2) then
            if not UriHelper.TryCreate('https://' + ServerAddress, UriKindHelper.Absolute, UriHelper2) then
                Error(InvalidUriErr);

        orgName := UriHelper2.AbsolutePath;
        if orgName = '/' then
            exit('');

        if (orgName <> '') and (StrLen(orgName) > 1) then
            orgName := CopyStr(orgName, 2);
        exit(orgName);
    end;

    procedure ConstructConnectionStringForSolutionImport(ServerAddress: Text): Text
    var
        FirstPart: Text;
        SecondPart: Text;
        FirstLevel: Integer;
    begin
        FirstLevel := StrPos(ServerAddress, '.');
        if FirstLevel = 0 then
            Error(CRMConnectionURLWrongErr, CRMProductName.SHORT());
        FirstPart := CopyStr(ServerAddress, 1, FirstLevel);
        SecondPart := CopyStr(ServerAddress, FirstLevel);
        exit(StrSubstNo(ImportSolutionConnectStringTok, FirstPart, SecondPart));
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure InitializeCRMConnection(var CRMHelper: DotNet CrmHelper; ConnectionString: SecretText)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if ConnectionString.IsEmpty() then begin
            CRMConnectionSetup.Get();
            CRMHelper := CRMHelper.CrmHelper(CRMConnectionSetup.GetSecretConnectionStringWithCredentials().Unwrap());
        end else
            CRMHelper := CRMHelper.CrmHelper(ConnectionString.Unwrap());
        if not TestCRMConnection(CRMHelper) then
            ProcessConnectionFailures();
    end;

#if not CLEAN25
    [TryFunction]
    [NonDebuggable]
    local procedure InitializeFSConnection(var CRMHelper: DotNet CrmHelper; ConnectionString: SecretText)
    var
        FSConnectionSetup: Record "FS Connection Setup";
    begin
        if ConnectionString.IsEmpty() then begin
            FSConnectionSetup.Get();
            CRMHelper := CRMHelper.CrmHelper(FSConnectionSetup.GetConnectionStringWithCredentials().Unwrap());
        end else
            CRMHelper := CRMHelper.CrmHelper(ConnectionString.Unwrap());
        if not TestCRMConnection(CRMHelper) then
            ProcessConnectionFailures();
    end;
#endif

    [Scope('OnPrem')]
    procedure ProcessConnectionFailures()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        FaultException: DotNet FaultException;
        FileNotFoundException: DotNet FileNotFoundException;
        ArgumentNullException: DotNet ArgumentNullException;
        CRMHelper: DotNet CrmHelper;
        ErrorMessage: Text;
    begin
        DotNetExceptionHandler.Collect();

        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FaultException)) then begin
            Session.LogMessage('0000CLW', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(AdminEmailPasswordWrongErr, CRMProductName.SHORT());
        end;
        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FileNotFoundException)) then begin
            Session.LogMessage('0000CLX', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(CRMSolutionFileNotFoundErr);
        end;
        if DotNetExceptionHandler.TryCastToType(CRMHelper.OrganizationServiceFaultExceptionType()) then begin
            Session.LogMessage('0000CLY', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(OrganizationServiceFailureErr)
        end;
        if DotNetExceptionHandler.TryCastToType(CRMHelper.SystemNetWebException()) then begin
            Session.LogMessage('0000CLZ', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(CRMConnectionURLWrongErr, CRMProductName.SHORT());
        end;
        if DotNetExceptionHandler.CastToType(ArgumentNullException, GetDotNetType(ArgumentNullException)) then
            case ArgumentNullException.ParamName of
                'cred':
                    begin
                        Session.LogMessage('0000CM0', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Error(AdminEmailPasswordWrongErr, CRMProductName.SHORT());
                    end;
                'Organization Name':
                    begin
                        Session.LogMessage('0000CM1', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Error(CRMConnectionURLWrongErr, CRMProductName.SHORT());
                    end;
            end;

        ErrorMessage := DotNetExceptionHandler.GetMessage();
        if ErrorMessage <> '' then
            if ErrorMessage.ToLower().Contains(TimeoutTxt) then begin
                Session.LogMessage('0000EJ7', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(RetryAfterTimeoutErr, ErrorMessage);
            end;

        DotNetExceptionHandler.Rethrow();
    end;

    local procedure GetIntegrationTableMappingFromCRMID(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; CRMID: Guid)
    var
        CRMAccount: Record "CRM Account";
        CRMProduct: Record "CRM Product";
        IsHandled: Boolean;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IsCRMTable(TableID) then
            IntegrationTableMapping.SetRange("Integration Table ID", TableID)
        else begin
            IsHandled := false;
            OnGetIntegrationTableMappingFromCRMIDOnBeforeFindTableID(IntegrationTableMapping, TableID, CRMID, IsHandled);
            if not IsHandled then begin
                if (TableID = Database::Vendor) or (TableID = Database::Customer) then begin
                    CRMAccount.SetRange(AccountId, CRMID);
                    if CRMAccount.FindFirst() then
                        case CRMAccount.CustomerTypeCode of
                            CRMAccount.CustomerTypeCode::Customer:
                                TableID := Database::Customer;
                            CRMAccount.CustomerTypeCode::Vendor:
                                TableID := Database::Vendor;
                            else
                                Error(AccountRelationshipTypeNotSupportedErr);
                        end;
                end;
                if (TableID = Database::Item) or (TableID = Database::Resource) then begin
                    CRMProduct.SetRange(ProductId, CRMID);
                    if CRMProduct.FindFirst() then
                        case CRMProduct.ProductTypeCode of
                            CRMProduct.ProductTypeCode::Services:
                                TableID := Database::Resource;
                            CRMProduct.ProductTypeCode::SalesInventory:
                                TableID := Database::Item;
                            else
                                Error(ProductTypeNotSupportedErr);
                        end;
                end;
            end;
            IntegrationTableMapping.SetRange("Table ID", TableID);
        end;
        if not IntegrationTableMapping.FindFirst() then
            Error(IntegrationTableMappingNotFoundErr, IntegrationTableMapping.TableCaption(), GetTableCaption(TableID));
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState();
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetCommonNotificationID(), CommonNotificationNameTxt, CommonNotificationDescriptionTxt, true);
        MyNotifications.InsertDefault(GetSkippedNotificationID(), SkippedRecordsNotificationNameTxt, SkippedRecordsNotificationDescriptionTxt, true);
    end;

    [Scope('OnPrem')]
    procedure DisableNotification(HostNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Text;
    begin
        NotificationId := HostNotification.GetData('NotificationId');
        if not MyNotifications.Disable(NotificationId) then
            MyNotifications.InsertDefault(NotificationId, GetNotificationName(NotificationId), GetNotificationDescription(NotificationId), false);
        Session.LogMessage('0000F0J', StrSubstNo(UserDisabledNotificationTxt, GetNotificationName(NotificationId)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure GetNotificationName(NotificationId: Guid): Text[128];
    begin
        case NotificationId of
            GetCommonNotificationID():
                exit(CommonNotificationNameTxt);
            GetSkippedNotificationID():
                exit(SkippedRecordsNotificationNameTxt);
        end;
        exit('');
    end;

    local procedure GetNotificationDescription(NotificationId: Guid): Text;
    begin
        case NotificationId of
            GetCommonNotificationID():
                exit(CommonNotificationDescriptionTxt);
            GetSkippedNotificationID():
                exit(SkippedRecordsNotificationDescriptionTxt);
        end;
        exit('');
    end;

#if not CLEAN25
    local procedure GetFieldServiceIntegrationRoleID(): Text
    begin
        exit('c11b4fa8-956b-439d-8b3c-021e8736a78b');
    end;
#endif

    local procedure GetIntegrationAdminRoleID(): Text
    begin
        exit('8c8d4f51-a72b-e511-80d9-3863bb349780');
    end;

    local procedure GetIntegrationUserRoleID(): Text
    begin
        exit('6f960e32-a72b-e511-80d9-3863bb349780');
    end;

    local procedure GetSalesProIntegrationRoleId(): Text
    begin
        exit('2f92fbbd-2d13-461a-895f-27c13f789fdb');
    end;

    procedure GetCommonNotificationID(): Guid
    begin
        exit('63428E33-54E4-42A6-82EE-3EEF268340BA');
    end;

    procedure GetSkippedNotificationID(): Guid
    begin
        exit('B523E8EA-56B3-4E79-837E-F812CFB74DD4');
    end;

    local procedure SendRestoredSyncNotification(Counter: Integer)
    var
        Msg: Text;
    begin
        if Counter = 1 then
            Msg := SyncRestoredMsg
        else
            Msg := StrSubstNo(SyncMultipleRestoredMsg, Counter);
        SendNotification(Msg);
    end;

    procedure SendResultNotification(RecVariant: Variant): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        RecordRef: RecordRef;
        NotificationMessage: Text;
        FailureDatetime: DateTime;
        SuccessDateTime: DateTime;
    begin
        RecordRef.GetTable(RecVariant);
        if CRMIntegrationRecord.FindByRecordID(RecordRef.RecordId()) then begin
            if CRMIntegrationRecord.Skipped then
                exit(SendSkippedSyncNotification(CRMIntegrationRecord."Integration ID"));

            if CRMIntegrationRecord."Last Synch. CRM Result" = CRMIntegrationRecord."Last Synch. CRM Result"::Failure then
                GetNotificationDetailsFromIntegrationSyncJobEntry(
                  CRMIntegrationRecord."Last Synch. CRM Job ID", RecordRef.RecordId, NotificationMessage, FailureDatetime)
            else
                SuccessDateTime := CRMIntegrationRecord."Last Synch. CRM Modified On";

            if CRMIntegrationRecord."Last Synch. Result" = CRMIntegrationRecord."Last Synch. Result"::Failure then
                GetNotificationDetailsFromIntegrationSyncJobEntry(
                  CRMIntegrationRecord."Last Synch. Job ID", RecordRef.RecordId, NotificationMessage, FailureDatetime)
            else
                SuccessDateTime := CRMIntegrationRecord."Last Synch. Modified On";

            if SuccessDateTime > FailureDatetime then
                NotificationMessage := '';
        end else begin
            Clear(IntegrationSynchJob);
            IntegrationSynchJob."Synch. Direction" := IntegrationSynchJob."Synch. Direction"::ToIntegrationTable;
            if IntegrationSynchJob.GetErrorForRecordID(RecordRef.RecordId, IntegrationSynchJobErrors) then
                NotificationMessage := IntegrationSynchJobErrors.Message;
        end;
        if NotificationMessage <> '' then
            exit(SendNotification(NotificationMessage));
    end;

    local procedure SendSkippedSyncNotification(IntegrationID: Guid): Boolean
    var
        MyNotifications: Record "My Notifications";
        SyncNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetSkippedNotificationID()) then
            exit;

        SyncNotification.Id := GetSkippedNotificationID();
        SyncNotification.Recall();
        SyncNotification.Message(SyncSkippedMsg);
        SyncNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        SyncNotification.SetData('IntegrationID', IntegrationID);
        SyncNotification.SetData('NotificationId', GetSkippedNotificationID());
        SyncNotification.AddAction(DetailsTxt, CODEUNIT::"CRM Integration Management", 'ShowSkippedRecords');
        SyncNotification.AddAction(DisableNotificationTxt, Codeunit::"CRM Integration Management", 'DisableNotification');
        SyncNotification.Send();
        exit(true);
    end;

    local procedure SendSyncNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            if RecordCounter[NoOf::Scheduled] = 1 then
                exit(SendNotification(SyncNowScheduledMsg));
            if RecordCounter[NoOf::Skipped] = 1 then
                exit(SendNotification(SyncNowSkippedMsg));
            exit(SendNotification(SyncNowFailedMsg));
        end;
        exit(SendMultipleSyncNotification(RecordCounter));
    end;

    local procedure SendMultipleSyncNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        exit(
          SendNotification(
            StrSubstNo(
              SyncMultipleMsg,
              RecordCounter[NoOf::Scheduled], RecordCounter[NoOf::Failed],
              RecordCounter[NoOf::Skipped], RecordCounter[NoOf::Total])));
    end;

    local procedure SendUncoupleNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            if RecordCounter[NoOf::Scheduled] = 1 then
                exit(SendNotification(UncoupleScheduledMsg));
            if RecordCounter[NoOf::Skipped] = 1 then
                exit(SendNotification(UncoupleSkippedMsg));
            exit(SendNotification(UncoupleFailedMsg));
        end;
        exit(SendMultipleUncoupleNotification(RecordCounter));
    end;

    local procedure SendCouplingNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            if RecordCounter[NoOf::Scheduled] = 1 then
                exit(SendNotification(CouplingScheduledMsg));
            if RecordCounter[NoOf::Skipped] = 1 then
                exit(SendNotification(CouplingSkippedMsg));
            exit(SendNotification(CouplingFailedMsg));
        end;
        exit(SendMultipleCouplingNotification(RecordCounter));
    end;

    local procedure SendMultipleUncoupleNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        exit(
          SendNotification(
            StrSubstNo(
              UncoupleMultipleMsg,
              RecordCounter[NoOf::Scheduled], RecordCounter[NoOf::Failed],
              RecordCounter[NoOf::Skipped], RecordCounter[NoOf::Total])));
    end;

    local procedure SendMultipleCouplingNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        exit(
          SendNotification(
            StrSubstNo(
              CouplingMultipleMsg,
              RecordCounter[NoOf::Scheduled], RecordCounter[NoOf::Failed],
              RecordCounter[NoOf::Skipped], RecordCounter[NoOf::Total])));
    end;

    local procedure SendNotification(Msg: Text): Boolean
    var
        MyNotifications: Record "My Notifications";
        SyncNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetCommonNotificationID()) then
            exit;

        SyncNotification.Id := GetCommonNotificationID();
        SyncNotification.Recall();
        SyncNotification.Message(Msg);
        SyncNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        SyncNotification.AddAction(DetailsTxt, Codeunit::"CRM Integration Management", 'OpenIntegrationSynchronizationJobsFromNotification');
        SyncNotification.SetData('NotificationId', GetCommonNotificationID());
        SyncNotification.AddAction(DisableNotificationTxt, Codeunit::"CRM Integration Management", 'DisableNotification');
        SyncNotification.Send();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure OpenIntegrationSynchronizationJobsFromNotification(HostNotification: Notification)
    var
        IntegrationSynchJobList: Page "Integration Synch. Job List";
    begin
        IntegrationSynchJobList.Run();
        Session.LogMessage('0000F0K', UserOpenedIntegrationSynchJobListViaNotificationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    procedure ShowLog(RecId: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, RecId);
        CRMIntegrationRecord.FindByRecordID(RecId);
        IntegrationTableMapping.ShowLog(CRMIntegrationRecord.GetLatestJobIDFilter());
    end;

    procedure ShowOptionLog(RecId: RecordId)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, RecId);
        CRMOptionMapping.SetRange("Record ID", RecId);
        if CRMOptionMapping.FindFirst() then
            IntegrationTableMapping.ShowLog(CRMOptionMapping.GetLatestJobIDFilter())
        else
            IntegrationTableMapping.ShowLog('');
    end;

    procedure ShowSkippedRecords(SkippedSyncNotification: Notification)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSkippedRecords: Page "CRM Skipped Records";
        IntegrationID: Guid;
    begin
        if Evaluate(IntegrationID, SkippedSyncNotification.GetData('IntegrationID')) then begin
            CRMIntegrationRecord.SetRange("Integration ID", IntegrationID);
            if CRMIntegrationRecord.FindFirst() then
                CRMSkippedRecords.SetRecords(CRMIntegrationRecord);
        end;
        CRMSkippedRecords.Run();
    end;

    procedure CoupleCRMEntity(RecordID: RecordID; CRMID: Guid; var Synchronize: Boolean; var Direction: Option): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CouplingRecordBuffer: Record "Coupling Record Buffer";
    begin
        CouplingRecordBuffer.Initialize(RecordID);
        CouplingRecordBuffer."CRM ID" := CRMID;
        if not CouplingRecordBuffer.Insert() then
            CouplingRecordBuffer.Modify();
        if not IsNullGuid(CouplingRecordBuffer."CRM ID") then begin
            CRMIntegrationRecord.CoupleRecordIdToCRMID(CouplingRecordBuffer."NAV Record ID", CouplingRecordBuffer."CRM ID");
            if CouplingRecordBuffer.GetPerformInitialSynchronization() then begin
                Synchronize := true;
                Direction := CouplingRecordBuffer.GetInitialSynchronizationDirection();
                PerformInitialSynchronization(CouplingRecordBuffer."NAV Record ID", CouplingRecordBuffer."CRM ID", Direction);
            end;
        end else
            exit(false);
        exit(true);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TestCRMConnection(var CRMHelper: DotNet CrmHelper)
    begin
        CRMHelper.CheckCredentials();
        CRMHelper.GetConnectedCrmVersion();
    end;

    [Scope('OnPrem')]
    procedure InitializeProxyVersionList(var TempStack: Record TempStack temporary)
    var
        CRMHelper: DotNet CrmHelper;
        IList: DotNet GenericList1;
        i: Integer;
        ProxyCount: Integer;
    begin
        IList := CRMHelper.GetProxyIdList();
        ProxyCount := IList.Count();
        for i := 0 to ProxyCount - 1 do begin
            TempStack.StackOrder := IList.Item(i);
            TempStack.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLastProxyVersionItem(): Integer
    var
        TempStack: Record TempStack temporary;
    begin
        InitializeProxyVersionList(TempStack);
        TempStack.FindLast();
        exit(TempStack.StackOrder);
    end;

    local procedure GetNotificationDetailsFromIntegrationSyncJobEntry(JobId: Guid; RecRefRecId: RecordID; var NotificationMessage: Text; var FailureDatetime: DateTime)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        if IntegrationSynchJob.Get(JobId) then
            if IntegrationSynchJob.GetErrorForRecordID(RecRefRecId, IntegrationSynchJobErrors) then begin
                NotificationMessage := IntegrationSynchJobErrors.Message;
                FailureDatetime := IntegrationSynchJobErrors."Date/Time";
            end
    end;

    procedure ClearConnectionDisableReason(var CRMConnectionSetup: Record "CRM Connection Setup")
    var
        Notification: Notification;
    begin
        Session.LogMessage('0000CM2', ClearDisabledReasonTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        Notification.Id := GetCRMDisabledErrorReasonNotificationId();
        Notification.Recall();
        Clear(CRMConnectionSetup."Disable Reason");
        CRMConnectionSetup.Modify();
    end;

    procedure GetCRMDisabledErrorReasonNotificationId() CRMDisabledErrorReasonNotificationId: Guid
    begin
        Evaluate(CRMDisabledErrorReasonNotificationId, CRMDisabledErrorReasonNotificationIdTxt);
        exit(CRMDisabledErrorReasonNotificationId);
    end;

    procedure IsWorkingConnection(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        exit(CRMConnectionSetup.TryReadSystemUsers());
    end;

    local procedure DisableConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        LastError: Text;
    begin
        Session.LogMessage('0000CM3', DisableIntegrationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        LastError := GetLastErrorText;
        LastError := CopyStr(LastError, StrPos(Format(LastError), ':') + 1, StrLen(LastError));
        Message(StrSubstNo(ConnectionBrokenMsg, LastError));
        if CRMConnectionSetup.Get() then begin
            CRMConnectionSetup.Validate("Is Enabled", false);
            CRMConnectionSetup.Validate(
              "Disable Reason",
              CopyStr(LastError, 1, MaxStrLen(CRMConnectionSetup."Disable Reason")));
            CRMConnectionSetup.Modify();
            Session.LogMessage('0000CM4', IntegrationDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end else
            Session.LogMessage('0000CM5', IntegrationNotConfiguredTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    procedure SendConnectionDisabledNotification(DisableReason: Text[250])
    var
        Notification: Notification;
    begin
        Notification.Id := GetCRMDisabledErrorReasonNotificationId();
        Notification.Message := StrSubstNo(ConnectionDisabledNotificationMsg, DisableReason);
        Notification.Scope := NOTIFICATIONSCOPE::LocalScope;
        Notification.Send();
    end;

    [Scope('OnPrem')]
    procedure IsItemAvailabilityEnabled(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get() then
            exit(CRMConnectionSetup."Item Availability Enabled");
    end;

    procedure InitializeCRMSynchStatus()
    var
        CRMSynchStatus: Record "CRM Synch Status";
    begin
        if CRMSynchStatus.IsEmpty() then begin
            CRMSynchStatus."Last Update Invoice Entry No." := 0;
            CRMSynchStatus.Insert();
        end;
    end;

    internal procedure InitializeCRMSynchStatus(var CRMSynchStatus: Record "CRM Synch Status")
    begin
        if CRMSynchStatus.IsEmpty() then begin
            CRMSynchStatus."Last Update Invoice Entry No." := 0;
            CRMSynchStatus.Insert();
        end;

        CRMSynchStatus.Get();
    end;

    procedure HasUncoupledSelectedUsers(var SelectedCRMSystemuser: Record "CRM Systemuser"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if SelectedCRMSystemuser.FindSet() then
            repeat
                if not CRMIntegrationRecord.FindRecordIDFromID(SelectedCRMSystemuser.SystemUserId, Database::"Salesperson/Purchaser", RecordID) then
                    exit(true);
            until SelectedCRMSystemuser.Next() = 0;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnIsDataIntegrationEnabled', '', false, false)]
    local procedure IsDataIntegrationEnabled(var IsIntegrationEnabled: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not IsIntegrationEnabled then
            IsIntegrationEnabled := CRMConnectionSetup.IsEnabled();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnAfterLogSynchError', '', false, false)]
    local procedure DisableConnectionOnAfterLongSynchError(IntegrationSynchJobErrors: Record "Integration Synch. Job Errors")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not IntegrationSynchJobErrors.Message.Contains('CrmCreate') then
            exit;

        if not IntegrationSynchJobErrors.Message.Contains('prvCreate') then
            exit;

        DisableConnection();

        if CRMConnectionSetup.Get() then begin
            CRMConnectionSetup."Disable Reason" := StrSubstNo(ConnectionDisabledReasonTxt, CRMConnectionSetup."Server Address", CRMConnectionSetup."User Name");
            CRMConnectionSetup.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnForceSynchronizeDataIntegration', '', false, false)]
    local procedure ForceSynchronizeDataIntegration(LocalRecordID: RecordID; var SynchronizeHandled: Boolean)
    begin
        if SynchronizeHandled then
            exit;

        if not (IsCDSIntegrationEnabled() or IsCRMIntegrationEnabled()) then
            exit;

        UpdateOneNow(LocalRecordID);
        SynchronizeHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnForceSynchronizeRecords', '', false, false)]
    local procedure ForceSynchronizeRecords(var LocalRecordIdList: List of [RecordId]; var SynchronizeHandled: Boolean)
    var
        SelectedCRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationRecord: Record "CRM Integration Record";
        LocalRecordId: RecordId;
    begin
        if SynchronizeHandled then
            exit;

        if not (IsCDSIntegrationEnabled() or IsCRMIntegrationEnabled()) then
            exit;

        foreach LocalRecordId in LocalRecordIdList do
            if CRMIntegrationRecord.FindByRecordID(LocalRecordId) then begin
                SelectedCRMIntegrationRecord."CRM ID" := CRMIntegrationRecord."CRM ID";
                SelectedCRMIntegrationRecord."Integration ID" := CRMIntegrationRecord."Integration ID";
                if SelectedCRMIntegrationRecord.Find() then
                    SelectedCRMIntegrationRecord.Mark(true);
            end;

        SelectedCRMIntegrationRecord.MarkedOnly(true);
        UpdateMultipleNow(SelectedCRMIntegrationRecord);
        SynchronizeHandled := true;
    end;

    [Scope('OnPrem')]
    procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if not GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, PAGE::"CRM Connection Setup Wizard") then
            GuidedExperience.InsertAssistedSetup(
                StrSubstNo(CRMConnectionSetupTxt, CRMProductName.SHORT()), CopyStr(StrSubstNo(CRMConnectionSetupTxt, CRMProductName.SHORT()), 1, 50), '',
                0, ObjectType::Page, PAGE::"CRM Connection Setup Wizard", AssistedSetupGroup::Customize, VideoUrlSetupCRMConnectionTxt, VideoCategory::Customize, '');
    end;

    [Scope('OnPrem')]
    procedure IsCRMIntegrationRecord(TableID: Integer): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        isIntegrationRecord: Boolean;
    begin
        // this is the new event that partners who have integration to custom entities should subscribe to
        OnIsCRMIntegrationRecord(TableID, isIntegrationRecord);
        if isIntegrationRecord then
            exit(true);

        IntegrationTableMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        exit(IntegrationTableMapping.DoesExistForTable(TableID));
    end;

    [Scope('OnPrem')]
    procedure GetDatabaseTableTriggerSetup(TableID: Integer; var Insert: Boolean; var Modify: Boolean; var Delete: Boolean; var Rename: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        Enabled: Boolean;
    begin
        if (Insert and Modify and Rename) then
            exit;

        if CompanyName = '' then
            exit;

        OnEnabledDatabaseTriggersSetup(TableID, Enabled);
        if not Enabled then begin
            if CDSConnectionSetup.ReadPermission() then
                if CDSConnectionSetup.Get() then
                    if CDSConnectionSetup."Is Enabled" then
                        Enabled := IsCRMIntegrationRecord(TableID);
            if not Enabled then
                if CRMConnectionSetup.ReadPermission() then begin
                    CRMConnectionSetup.SetLoadFields("Is Enabled");
                    if CRMConnectionSetup.IsEnabled() then
                        Enabled := IsCRMIntegrationRecord(TableID);
                end;
        end;

        if Enabled then begin
            Insert := true;
            Modify := true;
            Rename := true;
            if not Delete then
                Delete := false;
        end;
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseInsert(RecRef: RecordRef)
    begin
        ReactivateJobForTable(RecRef.Number);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseModify(RecRef: RecordRef)
    begin
        ReactivateJobForTable(RecRef.Number);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseRename(RecRef: RecordRef; XRecRef: RecordRef)
    begin
        ReactivateJobForTable(RecRef.Number);
    end;

    internal procedure ReactivateJobForTable(TableNo: Integer)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryUpdate: Record "Job Queue Entry";
        ScheduledTask: Record "Scheduled Task";
        IntegrationTableMapping: Record "Integration Table Mapping";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        NewEarliestStartDateTime: DateTime;
        Enabled: Boolean;
        IsCRMIntRec: Boolean;
        RescheduleOffsetInMs: Integer;
    begin
        if CDSConnectionSetup.Get() then
            Enabled := CDSConnectionSetup."Is Enabled";

        if not Enabled then
            Enabled := CRMConnectionSetup.IsEnabled();

        if not Enabled then
            exit;

        if not CachedIsCRMIntegrationRecord.ContainsKey(TableNo) then begin
            IsCRMIntRec := IsCRMIntegrationRecord(TableNo);
            CachedIsCRMIntegrationRecord.Add(TableNo, IsCRMIntRec);
            if not IsCRMIntRec then
                exit;
        end;

        if not CachedIsCRMIntegrationRecord.Get(TableNo) then
            exit;

        if not CachedDisableEventDrivenSynchJobReschedule.ContainsKey(TableNo) then begin
            IntegrationTableMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
            if IntegrationTableMapping.FindMappingForTable(TableNo) then begin
                CachedDisableEventDrivenSynchJobReschedule.Add(TableNo, IntegrationTableMapping."Disable Event Job Resch.");
                if IntegrationTableMapping."Disable Event Job Resch." then
                    exit;
            end;
        end;

        if CachedDisableEventDrivenSynchJobReschedule.ContainsKey(TableNo) then
            if CachedDisableEventDrivenSynchJobReschedule.Get(TableNo) then
                exit;

        if DataUpgradeMgt.IsUpgradeInProgress() then
            exit;
        if not UserCanRescheduleJob() then
            exit;

        JobQueueEntryUpdate.ReadIsolation := IsolationLevel::UpdLock;
        JobQueueEntry.Reset();
        JobQueueEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        JobQueueEntry.SetLoadFields(Status, "System Task ID", "Object Type to Run", "Object ID to Run", "Record ID to Process", Description);
        JobQueueEntry.SetFilter(Status, Format(JobQueueEntry.Status::Ready) + '|' + Format(JobQueueEntry.Status::"On Hold with Inactivity Timeout"));
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2|%3|%4|%5', Codeunit::"Integration Synch. Job Runner", Codeunit::"CRM Statistics Job", Codeunit::"Int. Coupling Job Runner",
                                                            Codeunit::"Int. Uncouple Job Runner", Codeunit::"CRM Archived Sales Orders Job");
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetFilter("Parameter String", '%1|%2', '', Format(TableNo));
        JobQueueEntry.SetRange(Scheduled, true);

        if JobQueueEntry.IsEmpty() then
            exit;
        if not JobQueueEntry.FindSet() then
            exit;

        // reschedule the synch job in 30 seconds from now, to give time to the user to make further changes
        RescheduleOffSetInMs := 30000;
        OnBeforeRescheduleJobQueueEntries(TableNo, RescheduleOffSetInMs);
        if RescheduleOffSetInMs < 5000 then
            RescheduleOffSetInMs := 5000;

        ScheduledTask.ReadIsolation := IsolationLevel::ReadUncommitted;
        repeat
            // The rescheduled task might start while the current transaction is not committed yet.
            // Therefore the task will restart with a delay to lower a risk of use of "old" data.
            // If the task is scheduled to run soon (in 60 seconds from now) we don't reschedule
            NewEarliestStartDateTime := CurrentDateTime() + RescheduleOffsetInMs;
            if DoesJobActOnTable(JobQueueEntry, TableNo) then
                if ScheduledTask.Get(JobQueueEntry."System Task ID") then
                    if (NewEarliestStartDateTime + RescheduleOffSetInMs) < ScheduledTask."Not Before" then
                        if TaskScheduler.SetTaskReady(JobQueueEntry."System Task ID", NewEarliestStartDateTime) then begin
                            JobQueueEntryUpdate.ID := JobQueueEntry.ID;
                            if JobQueueEntryUpdate.GetRecLockedExtendedTimeout() then
                                if JobQueueEntryUpdate.Status in [JobQueueEntry.Status::Ready, JobQueueEntry.Status::"On Hold with Inactivity Timeout"] then begin
                                    JobQueueEntryUpdate.Status := JobQueueEntry.Status::Ready;
                                    JobQueueEntryUpdate."Earliest Start Date/Time" := NewEarliestStartDateTime;
                                    JobQueueEntryUpdate."Parameter String" := Format(TableNo);
                                    JobQueueEntryUpdate.Modify();
                                    Session.LogMessage('0000JAV', StrSubstNo(RescheduledTaskTxt, Format(ScheduledTask.ID), Format(JobQueueEntry.ID), JobQueueEntry.Description, Format(ScheduledTask."Not Before")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                                end;
                        end;
        until JobQueueEntry.Next() = 0;
    end;

    local procedure DoesJobActOnTable(JobQueueEntry: Record "Job Queue Entry"; TableNo: Integer): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
        CacheKey: Text;
        ActsOnTable: Boolean;
    begin
        if (JobQueueEntry."Object Type to Run" = JobQueueEntry."Object Type to Run"::Codeunit) and (JobQueueEntry."Object ID to Run" = Codeunit::"CRM Archived Sales Orders Job") then
            exit(TableNo = Database::"Sales Header Archive");

        CacheKey := CompanyName + '$' + Format(JobQueueEntry.ID) + '$' + Format(TableNo);
        if CachedDoesJobActOnTable.ContainsKey(CacheKey) then
            exit(CachedDoesJobActOnTable.Get(CacheKey));

        if JobQueueEntry."Record ID to Process".TableNo = DATABASE::"Integration Table Mapping" then
            if RecRef.Get(JobQueueEntry."Record ID to Process") then begin
                RecRef.SetTable(IntegrationTableMapping);
                if IntegrationTableMapping."Table ID" = Database::"Sales Header" then
                    ActsOnTable := TableNo = Database::"Sales Line"
                else
                    ActsOnTable := IntegrationTableMapping."Table ID" = TableNo;
            end;
        CachedDoesJobActOnTable.Add(CacheKey, ActsOnTable);
        exit(ActsOnTable);
    end;

    [Scope('OnPrem')]
    procedure UserCanRescheduleJob(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyErrorMessageRegister: Record "Error Message Register";
        DummyErrorMessage: Record "Error Message";
    begin
        if not JobQueueEntry.ReadPermission then
            exit(false);
        if not JobQueueEntry.WritePermission then
            exit(false);
        if not DummyErrorMessageRegister.WritePermission then
            exit(false);
        if not DummyErrorMessage.WritePermission then
            exit(false);
        if not TaskScheduler.CanCreateTask() then
            exit(false);
        exit(true);
    end;

    internal procedure FindCoupledToCRMField(var RecRef: RecordRef; var CoupledToCRMFldRef: FieldRef): Boolean
    var
        Field: Record "Field";
        Customer: Record Customer;
        TableNo: Integer;
        FieldNo: Integer;
        IsHandled: Boolean;
        FieldFilterSearchTok: Label '*%1*', Locked = true;
    begin
        TableNo := RecRef.Number();

        IsHandled := false;
        OnBeforeFindCoupledToCRMField(TableNo, IsHandled);
        if IsHandled then
            exit(false);

        if CachedCoupledToCRMFieldNo.ContainsKey(TableNo) then
            FieldNo := CachedCoupledToCRMFieldNo.Get(TableNo)
        else begin
            Field.SetRange(TableNo, TableNo);
            Field.SetRange(Type, Field.Type::Boolean);
            Field.SetRange(FieldName, Customer.FieldName("Coupled to Dataverse"));
            if Field.FindFirst() then
                FieldNo := Field."No."
            else begin
                Field.SetFilter(FieldName, StrSubstNo(FieldFilterSearchTok, Customer.FieldName("Coupled to Dataverse")));
                if Field.FindFirst() then
                    FieldNo := Field."No."
                else
                    FieldNo := 0;
            end;
            CachedCoupledToCRMFieldNo.Add(TableNo, FieldNo);
        end;
        if FieldNo = 0 then
            exit(false);
        CoupledToCRMFldRef := RecRef.Field(FieldNo);
        exit(true);
    end;

    procedure EnableUnitGroupMapping(): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        AdjustUnitGroupCRMConnectionSetup();

        if UserCanRescheduleJob() then begin
            JobQueueEntry.Init();
            JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime() + 1000;
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := Codeunit::"CRM Update Unit Group Mapping";
            JobQueueEntry."Maximum No. of Attempts to Run" := 3;
            JobQueueEntry."Rerun Delay (sec.)" := 60;
            JobQueueEntry."Run in User Session" := false;
            JobQueueEntry.Description := UpdateUnitGroupMappingJQEDescriptionTxt;
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
            exit(JobQueueEntry.ID);
        end;
    end;

    procedure DisableUnitGroupMapping()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMFullSyncReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMIntegrationRecord.SetFilter("Table ID", '%1', Database::"Unit Group");
        if not CRMIntegrationRecord.IsEmpty() then
            CRMIntegrationRecord.DeleteAll();

        CRMIntegrationRecord.SetFilter("Table ID", '%1', Database::"Item Unit of Measure");
        if not CRMIntegrationRecord.IsEmpty() then
            CRMIntegrationRecord.DeleteAll();

        CRMIntegrationRecord.SetFilter("Table ID", '%1', Database::"Resource Unit of Measure");
        if not CRMIntegrationRecord.IsEmpty() then
            CRMIntegrationRecord.DeleteAll();

        if CRMFullSyncReviewLine.Get('UNIT GROUP') then
            CRMFullSyncReviewLine.Delete();

        if CRMFullSyncReviewLine.Get('ITEM UOM') then
            CRMFullSyncReviewLine.Delete();

        if CRMFullSyncReviewLine.Get('RESOURCE UOM') then
            CRMFullSyncReviewLine.Delete();

        RemoveIntegrationTableMapping(Database::"Unit Group", Database::"CRM Uomschedule");
        RemoveIntegrationTableMapping(Database::"Item Unit of Measure", Database::"CRM Uom");
        RemoveIntegrationTableMapping(Database::"Resource Unit of Measure", Database::"CRM Uom");
    end;

    procedure AdjustUnitGroupCRMConnectionSetup()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMFullSyncReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMIntegrationRecord.SetFilter("Table ID", '%1', Database::"Unit of Measure");
        if not CRMIntegrationRecord.IsEmpty() then
            CRMIntegrationRecord.DeleteAll();
        if CRMFullSyncReviewLine.Get('UNIT OF MEASURE') then
            CRMFullSyncReviewLine.Delete();
        RemoveIntegrationTableMapping(Database::"Unit of Measure", Database::"CRM Uomschedule");
    end;

    local procedure RemoveIntegrationTableMapping(TableId: Integer; IntTableId: Integer) JobExisted: Boolean;
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", TableId);
        IntegrationTableMapping.SetRange("Integration Table ID", IntTableId);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindSet() then
            repeat
                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                if not JobQueueEntry.IsEmpty() then begin
                    JobExisted := true;
                    JobQueueEntry.DeleteAll(true);
                end;
                IntegrationTableMapping.Delete(true);
            until IntegrationTableMapping.Next() = 0;
    end;

    procedure UpdateItemUnitGroup()
    var
        Item: Record Item;
        UnitGroup: Record "Unit Group";
        CommitCounter: Integer;
    begin
        Item.SetLoadFields(SystemId, "No.", "Unit Group Exists");
        Item.SetRange("Unit Group Exists", false);
        if Item.FindSet() then
            repeat
                UnitGroup.SetRange("Source Id", Item.SystemId);
                UnitGroup.SetRange("Source Type", UnitGroup."Source Type"::Item);
                if UnitGroup.IsEmpty() then begin
                    UnitGroup.Init();
                    UnitGroup."Source Id" := Item.SystemId;
                    UnitGroup."Source No." := Item."No.";
                    UnitGroup."Source Type" := UnitGroup."Source Type"::Item;
                    UnitGroup.Insert();
                    CommitCounter += 1;
                end;

                if CommitCounter = 1000 then begin
                    Commit();
                    CommitCounter := 0;
                end;
            until Item.Next() = 0;
    end;

    procedure UpdateResourceUnitGroup()
    var
        Resource: Record Resource;
        UnitGroup: Record "Unit Group";
        CommitCounter: Integer;
    begin
        Resource.SetLoadFields(SystemId, "No.", "Unit Group Exists");
        Resource.SetRange("Unit Group Exists", false);
        if Resource.FindSet() then
            repeat
                UnitGroup.SetRange("Source Id", Resource.SystemId);
                UnitGroup.SetRange("Source Type", UnitGroup."Source Type"::Resource);
                if UnitGroup.IsEmpty() then begin
                    UnitGroup.Init();
                    UnitGroup."Source Id" := Resource.SystemId;
                    UnitGroup."Source No." := Resource."No.";
                    UnitGroup."Source Type" := UnitGroup."Source Type"::Resource;
                    UnitGroup.Insert();
                    CommitCounter += 1;
                end;

                if CommitCounter = 1000 then begin
                    Commit();
                    CommitCounter := 0;
                end;
            until Resource.Next() = 0;
    end;

    procedure IsUnitGroupMappingEnabled() FeatureEnabled: Boolean;
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.Get() then
            exit(false);
        exit(CRMConnectionSetup."Unit Group Mapping Enabled");
    end;

    procedure MultipleCompanyLearnMore(var Notification: Notification)
    begin
        HyperLink(MultipleCompanyLinkLbl);
    end;

    procedure IsIntegrationRecordChild(TableID: Integer) ReturnValue: Boolean
    var
        Handled: Boolean;
    begin
        OnIsIntegrationRecordChild(TableID, Handled, ReturnValue);
        if Handled then
            exit(ReturnValue);

        exit(TableID in
          [Database::"Sales Line",
           Database::"Currency Exchange Rate",
           Database::"Sales Invoice Line",
           Database::"Sales Cr.Memo Line",
           Database::"Contact Alt. Address",
           Database::"Contact Profile Answer",
           Database::"Dimension Value",
           Database::"Rlshp. Mgt. Comment Line",
           Database::"Vendor Bank Account"]);
    end;

    local procedure GetOptionIdFieldRef(RecRef: RecordRef): FieldRef
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        KeyRef := RecRef.KeyIndex(1);
        if KeyRef.FieldCount() <> 1 then
            exit(FieldRef);
        FieldRef := RecRef.FieldIndex(1);
        exit(FieldRef);
    end;

    procedure GetFieldServiceIntegrationAppSourceLink(): Text
    begin
        exit(FSIntegrationAppSourceLinkTxt);
    end;

    procedure IsFieldServiceIntegrationAppInstalled(): Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        exit(ExtensionManagement.IsInstalledByAppId(FieldServiceIntegrationAppIdLbl));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Option Synch. Invoke", 'OnDeletionConflictDetected', '', false, false)]
    local procedure HandleOnOptionDeletionConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DeletionConflictHandled: Boolean)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        if DeletionConflictHandled then
            exit;

        if not (IsCDSIntegrationEnabled() or IsCRMIntegrationEnabled()) then
            exit;

        if IntegrationTableMapping."Deletion-Conflict Resolution" in
            [IntegrationTableMapping."Deletion-Conflict Resolution"::"Remove Coupling", IntegrationTableMapping."Deletion-Conflict Resolution"::"Restore Records"] then
            if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then
                DeletionConflictHandled := RemoveOptionMappingFromRecRef(SourceRecordRef)
            else
                DeletionConflictHandled := RemoveOptionMapping(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.", CRMOptionMapping.GetRecordRefOptionId(SourceRecordRef));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetIntegrationTableMappingFromCRMRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleCustomIntegrationTableMapping(var IsHandled: Boolean; IntegrationTableMappingName: Code[20]; var IntegrationTableMapping: Record "Integration Table Mapping"; EnqueueJobQueEntries: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronyzeNowQuestion(var AllowedDirection: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCRMIntegrationRecord(TableID: Integer; var isIntegrationRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnabledDatabaseTriggersSetup(TableID: Integer; var Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTableIdFromCRMOption(RecRef: RecordRef; var TableId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCRMTable(TableID: Integer; var IsCRMTable: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsIntegrationRecordChild(TableID: Integer; var Handled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenCoupledNavRecordPage(CRMID: Guid; CRMEntityTypeName: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindCoupledToCRMField(TableNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCRMEntityUrlFromCRMID(CRMEntityUrlTemplateTxt: Text; NewestUIAppIdParameterTxt: Text; TableId: Integer; CRMId: Guid; var CRMEntityUrl: Text; CRMTableId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetIntegrationTableMappingFromCRMIDOnBeforeFindTableID(var IntegrationTableMapping: Record "Integration Table Mapping"; var TableID: Integer; CRMID: Guid; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetIntegrationTableMappingWithRecordId(var IntegrationTableMapping: Record "Integration Table Mapping"; BCRecordId: RecordId; var TableID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetIntegrationTableMappingFromCRMRecordBeforeFindRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddExtraFieldMappings(IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRescheduleJobQueueEntries(TableNo: Integer; var RescheduleOffSetInMs: Integer)
    begin
    end;
}
