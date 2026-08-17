// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using System.Environment;
using System.Environment.Configuration;
using System.Security.Authentication;
using System.Security.Encryption;
using System.Telemetry;
using System.Threading;

page 7200 "CDS Connection Setup"
{
    AccessByPermission = TableData "CDS Connection Setup" = IM;
    ApplicationArea = Suite;
    Caption = 'Dataverse Connection Setup', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ShowFilter = false;
    SourceTable = "CDS Connection Setup";
    UsageCategory = Administration;
    Extensible = false;

    layout
    {
        area(content)
        {
            group(Connection)
            {
                Caption = 'Connection from Dynamics 365 Business Central to the Dataverse environment';
                field("Server Address"; Rec."Server Address")
                {
                    ApplicationArea = Suite;
                    Enabled = IsEditable;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the URL of the Dataverse environment that you want to connect to.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    AssistEdit = true;

                    trigger OnValidate()
                    begin
                        if Rec."Server Address" <> xRec."Server Address" then
                            InitializeDefaultBusinessUnit();
                    end;

                    trigger OnAssistEdit()
                    var
                        CDSEnvironment: Codeunit "CDS Environment";
                    begin
                        CDSEnvironment.SelectTenantEnvironment(Rec, CDSEnvironment.GetGlobalDiscoverabilityToken(), false);

                        if Rec."Server Address" <> xRec."Server Address" then
                            InitializeDefaultBusinessUnit();

                        CurrPage.Update();
                    end;
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsUserNamePasswordVisible;
                    ToolTip = 'Specifies the name of the user that will be used to connect to the Dataverse environment and synchronize data. This must not be the administrator user account.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
                field(Password; UserPassword)
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsUserNamePasswordVisible;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of the user that will be used to connect to the Dataverse environment and synchronize data.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        if not Rec.IsTemporary() then
                            if (UserPassword <> '') and (not EncryptionEnabled()) then
                                if Confirm(EncryptionIsNotActivatedQst) then
                                    PAGE.RunModal(PAGE::"Data Encryption Management");
                        Rec.SetPassword(UserPassword);
                    end;
                }
                field("Client Id"; Rec."Client Id")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsClientIdClientSecretVisible;
                    ToolTip = 'Specifies the ID of the Microsoft Entra application that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                }
                field("Client Secret"; ClientSecret)
                {
                    ApplicationArea = Suite;
                    Caption = 'Client Secret';
                    Editable = IsEditable;
                    Visible = IsClientIdClientSecretVisible;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the secret of the Microsoft Entra application that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';

                    trigger OnValidate()
                    begin
                        if not Rec.IsTemporary() then
                            if (ClientSecret <> '') and (not EncryptionEnabled()) then
                                if Confirm(EncryptionIsNotActivatedQst) then
                                    PAGE.RunModal(PAGE::"Data Encryption Management");
                        Rec.SetClientSecret(ClientSecret);
                    end;
                }
                field("Redirect URL"; Rec."Redirect URL")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    Visible = IsClientIdClientSecretVisible;
                    ToolTip = 'Specifies the Redirect URL of the Microsoft Entra app registration that will be used to connect to the Dataverse environment.', Comment = 'Dataverse and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                }
                field("SDK Version"; Rec."Proxy Version")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    Caption = 'SDK Version';
                    Editable = false;
                    Enabled = IsEditable;
                    ToolTip = 'Specifies the software development kit version that is used to connect to the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnAssistEdit()
                    begin
                        if CDSIntegrationImpl.SelectSDKVersion(Rec) then begin
                            RefreshStatuses := true;
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Is Enabled"; Rec."Is Enabled")
                {
                    ApplicationArea = Suite;
                    Caption = 'Enable Data Synchronization', Comment = 'Name of the check box that shows whether data synchronization with the Dataverse environment is enabled.';
                    ToolTip = 'Specifies whether data synchronization with the Dataverse environment is enabled. When you select this check box, you will be prompted to sign-in with an administrator user account and give consent to the app registration that will be used to connect to Dataverse. The account will be used one time to install and configure components that the integration requires.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    var
                        CRMIntegrationRecord: Record "CRM Integration Record";
                        AuditLog: Codeunit "Audit Log";
                        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                        DataverseEnabledLbl: Label 'Integration to Dataverse has been enabled by UserSecurityId %1.', Locked = true;
                    begin
                        RefreshStatuses := true;
                        CurrPage.Update(true);
                        if Rec."Is Enabled" then begin
                            FeatureTelemetry.LogUptake('0000H7J', 'Dataverse', Enum::"Feature Uptake Status"::"Set up");
                            FeatureTelemetry.LogUptake('0000IIM', 'Dataverse Base Entities', Enum::"Feature Uptake Status"::"Set up");
                            Session.LogMessage('0000CDE', CDSConnEnabledOnPageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                            AuditLog.LogAuditMessage(StrSubstNo(DataverseEnabledLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);

                            if (Rec."Server Address" <> '') and (Rec."Server Address" <> TestServerAddressTok) then
                                if CDSIntegrationImpl.MultipleCompaniesConnected() then
                                    CDSIntegrationImpl.SendMultipleCompaniesNotification();

                            if Rec."Ownership Model" = Rec."Ownership Model"::Person then
                                if Confirm(DoYouWantToMakeSalesPeopleMappingQst, true) then
                                    CDSSetupDefaults.RunCoupleSalespeoplePage();
                        end else begin
                            CRMIntegrationRecord.SetFilter("Table ID", '<>0');
                            if not CRMIntegrationRecord.IsEmpty() then begin
                                if not Confirm(DisableIntegrationQst) then
                                    Error('');
                                Session.LogMessage('0000DRF', CDSConnDisabledOnPageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                            end else
                                Session.LogMessage('0000DRG', CDSConnDisabledOnPageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        end;
                    end;
                }
                field("Business Events Enabled"; BusinessEventsEnabled)
                {
                    ApplicationArea = Suite;
                    Enabled = BusinessEventsSupported;
                    Caption = 'Enable Virtual Tables and Events', Comment = 'Name of the check box that shows whether virtual tables in Dataverse and business events that Business Central sends to the Dataverse environment are enabled.';
                    ToolTip = 'Specifies whether Business Central and Dataverse can synchronize data through virtual tables and events. If you enable virtual tables, you must sign-in with an administrator user account and give consent to the app registration that will be used to connect to Dataverse. The account will be used one time to set up the connection between Dataverse to Business Central.', Comment = 'Business Central and Dataverse are names of Microsoft Services and should not be translated.';

                    trigger OnValidate()
                    begin
                        if BusinessEventsEnabled then begin
                            CDSIntegrationImpl.SetupVirtualTables(Rec, Rec."Virtual Tables Config Id");
                            Rec."Business Events Enabled" := true;
                        end else begin
                            Rec."Business Events Enabled" := false;
                            Clear(Rec."Virtual Tables Config Id");
                        end;
                        IsConfigIdSpecified := not IsNullGuid(Rec."Virtual Tables Config Id");
                        RefreshStatuses := true;
                        CurrPage.Update(true);
                    end;
                }
            }
            group(Status)
            {
                Caption = 'Integration Solution Settings';
                Visible = Rec."Is Enabled";
                field("Solution Version"; SolutionVersion)
                {
                    ApplicationArea = Suite;
                    Caption = 'Solution Version';
                    Editable = false;
                    StyleExpr = SolutionVersionStatusStyleExpr;
                    ToolTip = 'Specifies whether an integration solution is installed and configured in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if SolutionVersionStatus then
                            Message(FavorableSolutionMsg)
                        else
                            Message(UnfavorableSolutionMsg);
                    end;
                }
                field("CDS Version Status"; CDSVersionStatus)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dataverse Version checked';
                    Editable = false;
                    StyleExpr = CDSVersionStatusStyleExpr;
                    ToolTip = 'Specifies whether the version of Dataverse that you are connected to is valid.';

                    trigger OnDrillDown()
                    begin
                        if CDSVersionStatus then
                            Message(FavorableCDSVersionMsg)
                        else
                            Message(UnfavorableCDSVersionMsg);
                    end;
                }
                field("User Status"; UserStatus)
                {
                    ApplicationArea = Suite;
                    Caption = 'User Roles checked';
                    Editable = false;
                    StyleExpr = UserStatusStyleExpr;
                    ToolTip = 'Specifies whether the integration user has the required roles in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if UserStatus then
                            Message(FavorableUserRolesMsg)
                        else
                            Message(UnfavorableUserRolesMsg);
                    end;
                }
                field("Team Status"; TeamStatus)
                {
                    ApplicationArea = Suite;
                    Caption = 'Team Roles checked';
                    Editable = false;
                    StyleExpr = TeamStatusStyleExpr;
                    ToolTip = 'Specifies whether the team that owns the selected business unit has the required roles in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if TeamStatus then
                            Message(FavorableTeamRolesMsg)
                        else
                            Message(UnfavorableTeamRolesMsg);
                    end;
                }
                field("Entities Status"; EntitiesStatus)
                {
                    ApplicationArea = Suite;
                    Caption = 'Entities availability checked';
                    Editable = false;
                    StyleExpr = EntitiesStatusStyleExpr;
                    ToolTip = 'Specifies whether the tables are available in Dataverse. You cannot change this setting.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnDrillDown()
                    begin
                        if EntitiesStatus then
                            Message(FavorableEntitiesMsg)
                        else
                            Message(UnfavorableEntitiesMsg);
                    end;
                }
            }
            group(AuthTypeDetails)
            {
                Caption = 'Authentication Type Details';
                Visible = not SoftwareAsAService;
                field("Authentication Type"; Rec."Authentication Type")
                {
                    ApplicationArea = Advanced;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the authentication type that will be used to authenticate with the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
                field("Connection String"; Rec."Connection String")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Connection String';
                    Editable = IsEditable;
                    ToolTip = 'Specifies the connection string that will be used to connect to the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        CDSIntegrationImpl.SetConnectionString(Rec, Rec."Connection String");
                    end;
                }
            }
            group(Advanced)
            {
                Caption = 'Advanced Settings';

                field("Ownership Model"; Rec."Ownership Model")
                {
                    ApplicationArea = Suite;
                    Editable = IsEditable;
                    ToolTip = 'Specifies the type of owner that will be assigned to any row that is created while synchronizing from Business Central to Dataverse.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnValidate()
                    begin
                        RefreshStatuses := true;
                        CurrPage.Update(true);
                    end;
                }
                field("Business Unit Name"; Rec."Business Unit Name")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    Caption = 'Coupled Business Unit';
                    Editable = false;
                    Enabled = IsEditable;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the business unit that you want to connect to in the Dataverse environment.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                    trigger OnAssistEdit()
                    begin
                        CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                        if CDSIntegrationImpl.SelectBusinessUnit(Rec) then begin
                            RefreshStatuses := true;
                            CurrPage.Update(true);
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Assisted Setup")
            {
                ApplicationArea = Suite;
                Caption = 'Assisted Setup';
                Image = Setup;
                Enabled = (not Rec."Is Enabled") or (not BusinessEventsEnabled);
                ToolTip = 'Start the Dataverse Connection Setup guide.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    GuidedExperienceType: Enum "Guided Experience Type";
                begin
                    CDSIntegrationImpl.RegisterAssistedSetup();
                    Commit(); // Make sure all data is committed before we run the wizard
                    GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"CDS Connection Setup Wizard");
                    CurrPage.Update(false);
                    RefreshStatuses := true;
                end;
            }
            action("Test Connection")
            {
                ApplicationArea = Suite;
                Caption = 'Test Connection', Comment = 'Test is a verb.';
                Image = ValidateEmailLoggingSetup;
                ToolTip = 'Test the connection to Dataverse using the specified settings.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                begin
                    if CDSIntegrationImpl.TestConnection(Rec) then begin
                        Message(ConnectionSuccessMsg);
                        RefreshStatuses := true;
                        CurrPage.Update();
                    end else
                        Message(ConnectionFailedMsg, GetLastErrorText());
                end;
            }
            action("Use Certificate Authentication")
            {
                ApplicationArea = Suite;
                Caption = 'Use Certificate Authentication';
                Image = Certificate;
                Visible = SoftwareAsAService;
                Enabled = Rec."Is Enabled";
                ToolTip = 'Upgrades the connection to Dataverse to use certificate-based OAuth 2.0 service-to-service authentication.';

                trigger OnAction()
                var
                    TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
                    CRMConnectionSetup: Record "CRM Connection Setup";
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                    EmptySecretText: SecretText;
                begin
                    TempCDSConnectionSetup."Server Address" := Rec."Server Address";
                    TempCDSConnectionSetup."User Name" := Rec."User Name";
                    TempCDSConnectionSetup."Proxy Version" := CDSIntegrationImpl.GetLastProxyVersionItem();
                    TempCDSConnectionSetup."Authentication Type" := TempCDSConnectionSetup."Authentication Type"::Office365;
                    TempCDSConnectionSetup.Insert();

                    CDSIntegrationImpl.SetupCertificateAuthentication(TempCDSConnectionSetup);

                    if (TempCDSConnectionSetup."Connection String".IndexOf('{CERTIFICATE}') > 0) and (TempCDSConnectionSetup."User Name" <> Rec."User Name") then begin
                        if CRMConnectionSetup.IsEnabled() then begin
                            CRMConnectionSetup."User Name" := TempCDSConnectionSetup."User Name";
                            CRMConnectionSetup.SetPassword(EmptySecretText);
                            CRMConnectionSetup."Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                            CRMConnectionSetup.SetConnectionString(TempCDSConnectionSetup."Connection String");
                        end;

                        Rec."User Name" := TempCDSConnectionSetup."User Name";
                        Rec.SetPassword(EmptySecretText);
                        Rec."Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                        Rec."Connection String" := TempCDSConnectionSetup."Connection String";
                        Rec.Modify();
                        CurrPage.Update(false);
                        Session.LogMessage('0000FB4', CertificateConnectionSetupTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Message(StrSubstNo(CertificateConnectionSetupMsg, Rec."User Name"));
                    end;
                end;
            }
            action(ResetConfiguration)
            {
                ApplicationArea = Suite;
                Caption = 'Use Default Synchronization Setup';
                Enabled = Rec."Is Enabled";
                Image = ResetStatus;
                ToolTip = 'Resets the integration table mappings and synchronization jobs to the default values for a connection with Dataverse. All current mappings are deleted.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    CDSSetupDefaults: Codeunit "CDS Setup Defaults";
                begin
                    if Confirm(ResetIntegrationTableMappingConfirmQst, false) then begin
                        CDSSetupDefaults.ResetConfiguration(Rec);
                        Message(SetupSuccessfulMsg);
                        RefreshStatuses := true;
                    end;
                end;
            }
            action(CoupleUsers)
            {
                ApplicationArea = Suite;
                Caption = 'Couple Salespeople';
                Enabled = Rec."Is Enabled" and (Rec."Ownership Model" = Rec."Ownership Model"::Person);
                Image = CoupledUsers;
                ToolTip = 'Open the list of users in Dataverse to manually couple them with salespeople in Business Central.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    CRMSystemuserList: Page "CRM Systemuser List";
                begin
                    CRMSystemuserList.Initialize(true);
                    CRMSystemuserList.Run();
                end;
            }
            action(AddUsersToTeam)
            {
                ApplicationArea = Suite;
                Caption = 'Add Coupled Users to Team';
                Enabled = Rec."Is Enabled" and (Rec."Ownership Model" = Rec."Ownership Model"::Person);
                Image = LinkAccount;
                ToolTip = 'Add the coupled Dataverse users to the default owning team.';

                trigger OnAction()
                var
                    Added: Integer;
                begin
                    Added := CDSIntegrationImpl.AddCoupledUsersToDefaultOwningTeam(Rec);
                    Message(UsersAddedToTeamMsg, Added);
                end;
            }
            action(StartInitialSynchAction)
            {
                ApplicationArea = Suite;
                Caption = 'Run Full Synchronization';
                Enabled = Rec."Is Enabled";
                Image = RefreshLines;
                ToolTip = 'Start all of the default integration projects for synchronizing Business Central record types and Dataverse tables. Data is synchronized according to the mappings defined on the Integration Table Mappings page.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"CRM Full Synch. Review");
                end;
            }
            action(SynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize Modified Records';
                Enabled = Rec."Is Enabled";
                Image = Refresh;
                ToolTip = 'Synchronize records that have been modified since the last time they were synchronized.';

                trigger OnAction()
                var
                    IntegrationSynchJobList: Page "Integration Synch. Job List";
                begin
                    if not Confirm(SynchronizeModifiedQst) then
                        exit;

                    Rec.SynchronizeNow(false);
                    Message(SyncNowScheduledMsg, IntegrationSynchJobList.Caption());
                end;
            }
            action(RebuildCouplingTable)
            {
                ApplicationArea = Suite;
                Caption = 'Rebuild Coupling Table';
                Enabled = true;
                Image = Restore;
                ToolTip = 'Rebuilds the coupling table after Cloud Migration from Business Central 2019 Wave 1 (Business Central 14).';

                trigger OnAction()
                var
                    CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
                begin
                    CDSIntegrationImpl.ScheduleRebuildingOfCouplingTable();
                end;
            }
        }
        area(Reporting)
        {
            action("Redeploy Solution")
            {
                ApplicationArea = Suite;
                Caption = 'Redeploy Integration Solution';
                Image = Setup;
                Enabled = not Rec."Is Enabled";
                ToolTip = 'Redeploy and reconfigure the base integration solution.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ImportAndConfigureIntegrationSolution(Rec, true, true);

                    if CDSIntegrationImpl.CheckIntegrationRequirements(Rec, true) then begin
                        Session.LogMessage('0000CDH', SuccessfullyRedeployedSolutionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Message(DeploySucceedMsg)
                    end else begin
                        Session.LogMessage('0000CDI', UnsuccessfullyRedeployedSolutionTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Message(DeployFailedMsg);
                    end;
                    RefreshStatuses := true;
                    CurrPage.Update(true);
                end;
            }
            action("Integration Solutions")
            {
                ApplicationArea = Suite;
                Caption = 'Integration Solutions';
                Image = UserSetup;
                Enabled = Rec."Is Enabled";
                ToolTip = 'View the integration solutions that help business apps synchronize data with Business Central through Dataverse.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    Page.RunModal(PAGE::"CDS Integration Solutions");
                end;
            }
            action("Integration User Roles")
            {
                ApplicationArea = Suite;
                Caption = 'Integration User Roles';
                Image = UserSetup;
                Enabled = Rec."Is Enabled";
                ToolTip = 'View the roles assigned to the integration user. The integration user is the user account in Dataverse that business apps use to synchronize data with Business Central through Dataverse.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    Page.RunModal(PAGE::"CDS Integration User Roles");
                end;
            }
            action("Owning Team Roles")
            {
                ApplicationArea = Suite;
                Caption = 'Owning Team Roles';
                Image = UserSetup;
                Enabled = Rec."Is Enabled";
                ToolTip = 'View the roles assigned to the team in Dataverse that owns the coupled entities. This requires that you are using the Team ownership model.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    Page.RunModal(PAGE::"CDS Owning Team Roles");
                end;
            }
            action("Dataverse Integration User")
            {
                ApplicationArea = Suite;
                Caption = 'Dataverse Integration User';
                Image = UserSetup;
                Enabled = Rec."Is Enabled";
                ToolTip = 'Open the Dataverse integration user.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ShowIntegrationUser(Rec);
                end;
            }
            action("Dataverse Owning Team")
            {
                ApplicationArea = Suite;
                Caption = 'Dataverse Owning Team';
                Image = UserSetup;
                Enabled = Rec."Is Enabled";
                ToolTip = 'Open the Dataverse owning team.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ShowOwningTeam(Rec);
                end;
            }
        }
        area(Navigation)
        {
            action(EncryptionManagement)
            {
                ApplicationArea = Advanced;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
            action(SkippedSynchRecords)
            {
                ApplicationArea = Suite;
                Caption = 'Skipped Synch. Records';
                Enabled = Rec."Is Enabled";
                Image = NegativeLines;
                RunObject = Page "CRM Skipped Records";
                RunPageMode = View;
                ToolTip = 'View the list of records that synchronization will skip.';
            }
            action("Synch. Job Queue Entries")
            {
                ApplicationArea = Suite;
                Caption = 'Synch. Job Queue Entries';
                Image = JobListSetup;
                ToolTip = 'View the job queue entries that manage the scheduled synchronization between Dataverse and Business Central.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.FilterGroup := 2;
                    JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                    JobQueueEntry.SetFilter("Object ID to Run", GetJobQueueEntriesObjectIDToRunFilter());
                    JobQueueEntry.FilterGroup := 0;

                    PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
                end;
            }
            action(IntegrationTableMappings)
            {
                ApplicationArea = Suite;
                Caption = 'Integration Table Mappings';
                Enabled = Rec."Is Enabled";
                Image = MapAccounts;
                ToolTip = 'View the list of integration table mappings.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Integration Table Mapping List");
                end;
            }
            action("Virtual Tables App")
            {
                ApplicationArea = Suite;
                Caption = 'Virtual Tables AppSource App';
                Image = Setup;
                Enabled = BusinessEventsSupported;
                ToolTip = 'Go to Microsoft AppSource to get the Business Central Virtual Tables app. The app will let you create virtual tables for Business Central data in Dataverse';

                trigger OnAction()
                begin
                    Hyperlink(CDSIntegrationImpl.GetVirtualTablesAppSourceLink());
                end;
            }
            action("Virtual Tables Config")
            {
                ApplicationArea = Suite;
                Caption = 'Virtual Tables Config';
                Image = Setup;
                Enabled = BusinessEventsSupported and IsConfigIdSpecified;
                ToolTip = 'View configuration settings for virtual tables.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"CRM BC Virtual Table Config.");
                end;
            }
            action("Available Virtual Tables")
            {
                ApplicationArea = Suite;
                Caption = 'Available Virtual Tables';
                Image = Setup;
                Enabled = BusinessEventsSupported and IsConfigIdSpecified;
                ToolTip = 'View the available virtual tables. You can specify which tables are visible.';
                RunObject = Page "CDS Available Virtual Tables";
            }
            action("Virtual Tables AAD app")
            {
                ApplicationArea = Suite;
                Caption = 'Virtual Tables Microsoft Entra App';
                Image = Setup;
                Enabled = BusinessEventsSupported;
                ToolTip = 'Open the Microsoft Entra Application page to view settings for the application registration for the Business Central Virtual Table app. The application registration is required for using Business Central virtual tables in your Dataverse environment.';

                trigger OnAction()
                var
                    AADApplication: Record "AAD Application";
                    AADApplicationSetup: Codeunit "AAD Application Setup";
                begin
                    AADApplication.Get(AADApplicationSetup.GetD365BCForVEAppId());
                    Page.RunModal(Page::"AAD Application Card", AADApplication);
                end;
            }
            action("Synthetic Relations")
            {
                ApplicationArea = Suite;
                Caption = 'Synthetic Relations';
                Image = Relationship;
                Enabled = BusinessEventsEnabled and Rec."Is Enabled";
                ToolTip = 'View the synthetic relations available.';
                RunObject = Page "Synthetic Relations";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Connection', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Assisted Setup_Promoted"; "Assisted Setup")
                {
                }
                actionref("Test Connection_Promoted"; "Test Connection")
                {
                }
                actionref("Use Certificate Authentication_Promoted"; "Use Certificate Authentication")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Integration', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref(CoupleUsers_Promoted; CoupleUsers)
                {
                }
                actionref(AddUsersToTeam_Promoted; AddUsersToTeam)
                {
                }
                actionref(IntegrationTableMappings_Promoted; IntegrationTableMappings)
                {
                }
                actionref("Redeploy Solution_Promoted"; "Redeploy Solution")
                {
                }
                actionref("Integration Solutions_Promoted"; "Integration Solutions")
                {
                }
                actionref("Integration User Roles_Promoted"; "Integration User Roles")
                {
                }
                actionref("Owning Team Roles_Promoted"; "Owning Team Roles")
                {
                }
                actionref("Dataverse Integration User_Promoted"; "Dataverse Integration User")
                {
                }
                actionref("Dataverse Owning Team_Promoted"; "Dataverse Owning Team")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Encryption', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(EncryptionManagement_Promoted; EncryptionManagement)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Virtual Tables', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Virtual Tables App_Promoted"; "Virtual Tables App")
                {
                }
                actionref("Virtual Tables Config_Promoted"; "Virtual Tables Config")
                {
                }
                actionref("Available Virtual Tables_Promoted"; "Available Virtual Tables")
                {
                }
                actionref("Virtual Tables AAD app_Promoted"; "Virtual Tables AAD app")
                {
                }
                actionref("Synthetic Relations_Promoted"; "Synthetic Relations")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Synchronization', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(StartInitialSynchAction_Promoted; StartInitialSynchAction)
                {
                }
                actionref(SynchronizeNow_Promoted; SynchronizeNow)
                {
                }
                actionref(SkippedSynchRecords_Promoted; SkippedSynchRecords)
                {
                }
                actionref("Synch. Job Queue Entries_Promoted"; "Synch. Job Queue Entries")
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Cloud Migration', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(RebuildCouplingTable_Promoted; RebuildCouplingTable)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshData();
    end;

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        ApplicationAreaMgmtFacade.CheckAppAreaOnlyBasic();
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
        if SoftwareAsAService then
            CDSIntegrationImpl.RegisterAssistedSetup();
        BusinessEventsSupported := CDSIntegrationImpl.GetBusinessEventsSupported();
        SolutionKey := CDSIntegrationImpl.GetBaseSolutionUniqueName();
        SolutionName := CDSIntegrationImpl.GetBaseSolutionDisplayName();
        DefaultBusinessUnitName := CDSIntegrationImpl.GetDefaultBusinessUnitName();
        RefreshStatuses := true;
        SetVisibilityFlags();
    end;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CDSEnvironment: Codeunit "CDS Environment";
    begin
        FeatureTelemetry.LogUptake('0000H7K', 'Dataverse', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000IIN', 'Dataverse Base Entities', Enum::"Feature Uptake Status"::Discovered);
        if not Rec.Get() then begin
            Rec.Init();
            InitializeDefaultAuthenticationType();
            InitializeDefaultProxyVersion();
            InitializeDefaultOwnershipModel();
            InitializeDefaultBusinessUnit();
            InitializeDefaultRedirectUrl();
            CDSEnvironment.SetLinkedDataverseEnvironmentUrl(Rec, CDSEnvironment.GetGlobalDiscoverabilityOnBehalfTokenAsSecretText());
            Rec.Insert();
            Rec.LoadConnectionStringElementsFromCRMConnectionSetup();
        end else begin
            UserPassword := '**********';
            ClientSecret := '**********';
            if Rec."Redirect URL" = '' then
                InitializeDefaultRedirectUrl();
            if (not IsValidAuthenticationType()) or (not IsValidProxyVersion()) or (not IsValidOwnershipModel() or (not IsValidBusinessUnit())) then begin
                CDSIntegrationImpl.UnregisterConnection();
                if not IsValidAuthenticationType() then
                    InitializeDefaultAuthenticationType();
                if not IsValidProxyVersion() then
                    InitializeDefaultProxyVersion();
                if not IsValidOwnershipModel() then
                    InitializeDefaultOwnershipModel();
                if not IsValidBusinessUnit() then
                    InitializeDefaultBusinessUnit();
                Rec.Modify();
            end;
            Rec.LoadConnectionStringElementsFromCRMConnectionSetup();
            if not Rec."Is Enabled" then begin
                CDSIntegrationImpl.UnregisterConnection();
                if Rec."Disable Reason" <> '' then
                    CDSIntegrationImpl.SendConnectionDisabledNotification(Rec."Disable Reason");
            end;
        end;
        BusinessEventsEnabled := Rec."Business Events Enabled";
        IsConfigIdSpecified := not IsNullGuid(Rec."Virtual Tables Config Id");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not Rec."Is Enabled" and not Rec."Business Events Enabled" then
            if not Confirm(StrSubstNo(EnableServiceQst, CurrPage.Caption()), true) then
                exit(false);
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        SolutionKey: Text;
        SolutionName: Text;
        DefaultBusinessUnitName: Text;
        [NonDebuggable]
        UserPassword: Text;
        [NonDebuggable]
        ClientSecret: Text;
        ResetIntegrationTableMappingConfirmQst: Label 'This will restore the default integration table mappings and synchronization jobs for Dataverse. All customizations to mappings and projects will be deleted. The default mappings and projects will be used the next time data is synchronized. Do you want to continue?';
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = This Page Caption (Dataverse Connection Setup)';
        UnfavorableCDSVersionMsg: Label 'This version of Dataverse might not work correctly with the Dataverse Base Integration solution. We recommend you upgrade to a supported version.';
        FavorableCDSVersionMsg: Label 'The version of Dataverse is valid.';
        UnfavorableSolutionMsg: Label 'The base integration solution was not detected in Dataverse.';
        FavorableSolutionMsg: Label 'The base integration solution is installed in Dataverse.';
        UnfavorableUserRolesMsg: Label 'Some base roles are not correctly assigned to the integration user.';
        FavorableEntitiesMsg: Label 'The base entities are available.';
        UnfavorableEntitiesMsg: Label 'Some base entities are not available.';
        FavorableUserRolesMsg: Label 'The base roles are correctly assigned to the integration user.';
        UnfavorableTeamRolesMsg: Label 'The base roles are not correctly assigned to the default owning team.';
        FavorableTeamRolesMsg: Label 'The base roles are correctly assigned to the default owning team.';
        DeploySucceedMsg: Label 'The solution, user roles, and entities have been deployed.';
        DeployFailedMsg: Label 'The deployment of the solution, user roles, and entities failed.';
        ConnectionSuccessMsg: Label 'The connection test was successful. The settings are valid.';
        ConnectionFailedMsg: Label 'The connection test has failed. %1.', Comment = '%1 = Connection test failure error message';
        SynchronizeModifiedQst: Label 'This will synchronize all modified records in all integration table mappings.\The synchronization will run in the background so you can continue with other tasks.\\Do you want to continue?';
        SyncNowScheduledMsg: Label 'Synchronization of modified records is scheduled.\You can view details on the %1 page.', Comment = '%1 = The localized caption of page Integration Synch. Job List';
        SetupSuccessfulMsg: Label 'The default setup for Dataverse synchronization has completed successfully.';
        DoYouWantToMakeSalesPeopleMappingQst: Label 'Do you want to map salespeople to users in Dataverse?';
        UsersAddedToTeamMsg: Label 'Count of users added to the default owning team: %1.', Comment = '%1 - count of users.';
        Office365AuthTxt: Label 'AuthType=Office365', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        DisableIntegrationQst: Label 'You are about to disable your integration with Dataverse, but some records are still coupled. If you will re-enable the integration later, you must remove all couplings before you disable the integration.\\Do you want to continue anyway?';
        CDSConnEnabledOnPageTxt: Label 'Dataverse Connection has been enabled from Dataverse Connection Setup page', Locked = true;
        CDSConnDisabledOnPageTxt: Label 'The connection to Dataverse has been disabled from the Dataverse Connection Setup page', Locked = true;
        SuccessfullyRedeployedSolutionTxt: Label 'The Dataverse solution has been successfully redeployed', Locked = true;
        UnsuccessfullyRedeployedSolutionTxt: Label 'The Dataverse solution has failed to be redeployed', Locked = true;
        CertificateConnectionSetupTelemetryMsg: Label 'User has successfully set up the certificate connection to Dataverse.', Locked = true;
        CertificateConnectionSetupMsg: Label 'You have successfully upgraded the connection to Dataverse to use certificate-based OAuth 2.0 service-to-service authentication. Business Central has auto-generated a new integration user with user name %1 in your Dataverse environment. This user does not require a license.', Comment = '%1 - user name';
        TestServerAddressTok: Label '@@test@@', Locked = true;
        IsEditable: Boolean;
        IsUserNamePasswordVisible: Boolean;
        IsClientIdClientSecretVisible: Boolean;
        SoftwareAsAService: Boolean;
        BusinessEventsSupported: Boolean;
        BusinessEventsEnabled: Boolean;
        IsConfigIdSpecified: Boolean;
        CDSVersion: Text;
        CDSVersionStatus: Boolean;
        SolutionVersion: Text;
        SolutionVersionStatus: Boolean;
        UserStatus: Boolean;
        TeamStatus: Boolean;
        EntitiesStatus: Boolean;
        CDSVersionStatusStyleExpr: Text;
        SolutionVersionStatusStyleExpr: Text;
        UserStatusStyleExpr: Text;
        TeamStatusStyleExpr: Text;
        EntitiesStatusStyleExpr: Text;
        RefreshStatuses: Boolean;

    local procedure RefreshData()
    begin
        UpdateEnableFlags();
        RefreshDataFromCDS();
    end;

    local procedure RefreshDataFromCDS()
    begin
        if not Rec."Is Enabled" then
            exit;

        if not RefreshStatuses then
            exit;

        if CDSIntegrationImpl.TryCheckCredentials(Rec) then
            if CDSIntegrationImpl.GetCDSVersion(Rec, CDSVersion) then
                CDSVersionStatus := CDSIntegrationImpl.IsCDSVersionValid(CDSVersion)
            else
                CDSVersionStatus := false;
        if CDSIntegrationImpl.GetSolutionVersion(Rec, SolutionVersion) then
            SolutionVersionStatus := CDSIntegrationImpl.CheckIntegrationSolutionRequirements(Rec, true)
        else
            SolutionVersionStatus := false;
        UserStatus := CDSIntegrationImpl.CheckIntegrationUserRequirements(Rec, true);
        TeamStatus := CDSIntegrationImpl.CheckOwningTeamRequirements(Rec, true);
        EntitiesStatus := CDSIntegrationImpl.CheckEntitiesAvailability(Rec, true);
        SetStyleExpr();
        RefreshStatuses := false;
        CDSIntegrationImpl.ActivateConnection();
    end;

    local procedure SetStyleExpr()
    begin
        CDSVersionStatusStyleExpr := GetStyleExpr(CDSVersionStatus);
        SolutionVersionStatusStyleExpr := GetStyleExpr(SolutionVersionStatus);
        UserStatusStyleExpr := GetStyleExpr(UserStatus);
        TeamStatusStyleExpr := GetStyleExpr(TeamStatus);
        EntitiesStatusStyleExpr := GetStyleExpr(EntitiesStatus);
    end;

    local procedure GetStyleExpr(Status: Boolean): Text
    begin
        if Status then
            exit('Favorable');
        exit('Unfavorable');
    end;

    local procedure UpdateEnableFlags()
    begin
        BusinessEventsEnabled := Rec."Business Events Enabled";
        IsEditable := (not Rec."Is Enabled") and (not BusinessEventsEnabled);
        IsConfigIdSpecified := not IsNullGuid(Rec."Virtual Tables Config Id");
    end;

    local procedure SetVisibilityFlags()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        IsUserNamePasswordVisible := true;
        IsClientIdClientSecretVisible := not SoftwareAsAService;

        if not CDSConnectionSetup.Get() then begin
            IsUserNamePasswordVisible := false;
            exit;
        end;

        if CDSConnectionSetup."Authentication Type" <> CDSConnectionSetup."Authentication Type"::Office365 then
            IsClientIdClientSecretVisible := false
        else
            if not Rec."Connection String".Contains(Office365AuthTxt) then
                IsUserNamePasswordVisible := false;

        IsConfigIdSpecified := not IsNullGuid(Rec."Virtual Tables Config Id");
    end;

    local procedure InitializeDefaultProxyVersion()
    begin
        Rec.Validate("Proxy Version", CDSIntegrationImpl.GetLastProxyVersionItem());
    end;

    local procedure InitializeDefaultOwnershipModel()
    begin
        Rec.Validate("Ownership Model", Rec."Ownership Model"::Team);
    end;

    local procedure InitializeDefaultBusinessUnit()
    begin
        if Rec."Server Address" = '' then
            Rec."Business Unit Name" := ''
        else
            Rec."Business Unit Name" := CopyStr(DefaultBusinessUnitName, 1, MaxStrLen(Rec."Business Unit Name"));
        Clear(Rec."Business Unit Id");
    end;

    local procedure InitializeDefaultRedirectUrl()
    var
        OAuth2: Codeunit "OAuth2";
        RedirectUrl: Text;
    begin
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);
        Rec."Redirect URL" := CopyStr(RedirectUrl, 1, MaxStrLen(Rec."Redirect URL"));
    end;

    local procedure InitializeDefaultAuthenticationType()
    begin
        Rec.Validate("Authentication Type", Rec."Authentication Type"::Office365);
    end;

    local procedure IsValidAuthenticationType(): Boolean
    begin
        if SoftwareAsAService then
            exit(Rec."Authentication Type" = Rec."Authentication Type"::Office365);
        exit(true);
    end;

    local procedure IsValidBusinessUnit(): Boolean
    begin
        exit(not IsNullGuid(Rec."Business Unit Id") and (Rec."Business Unit Name" <> ''));
    end;

    local procedure IsValidProxyVersion(): Boolean
    begin
        exit(Rec."Proxy Version" <> 0);
    end;

    local procedure IsValidOwnershipModel(): Boolean
    begin
        exit(Rec."Ownership Model" in [Rec."Ownership Model"::Person, Rec."Ownership Model"::Team]);
    end;

    local procedure GetJobQueueEntriesObjectIDToRunFilter(): Text
    begin
        exit(
          StrSubstNo('%1|%2|%3', Codeunit::"Integration Synch. Job Runner", Codeunit::"Int. Uncouple Job Runner", Codeunit::"Int. Coupling Job Runner"));
    end;
}