// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using System.Environment;
using System.Environment.Configuration;
using System.Telemetry;
using System.Utilities;

page 1817 "CRM Connection Setup Wizard"
{
    Caption = 'Dynamics 365 Sales Integration Setup';
    PageType = NavigatePage;
    SourceTable = "CRM Connection Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(BannerStandard)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and not CredentialsStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(BannerDone)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and CredentialsStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Visible = FirstStepVisible;
                group("Welcome to Dynamics 365 Connection Setup")
                {
                    Caption = 'Welcome to Dynamics 365 Connection Setup';
                    group(Control23)
                    {
                        InstructionalText = 'You can set up a Dynamics 365 Sales connection to enable seamless coupling of data.';
                        ShowCaption = false;
                    }
                    group(Control21)
                    {
                        InstructionalText = 'Start by specifying the URL to your Dynamics 365 Sales solution, such as https://mycrm.crm4.dynamics.com';
                        ShowCaption = false;
                    }
                    field(ServerAddress; Rec."Server Address")
                    {
                        ApplicationArea = Suite;
                        Editable = ConnectionStringFieldsEditable;
                        ToolTip = 'Specifies the URL of the Dynamics 365 Sales server that hosts the Dynamics 365 Sales solution that you want to connect to.';

                        trigger OnValidate()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.CheckModifyCRMConnectionURL(Rec."Server Address");
                        end;
                    }
                    group(Control9)
                    {
                        InstructionalText = 'Once coupled, you can work with and synchronize data types that are common to both services, such as customers, contacts, and sales information, and keep the data up-to-date in both locations.';
                        ShowCaption = false;
                    }
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = CredentialsStepVisible;
                group("Step2.1")
                {
                    Caption = '';
                    InstructionalText = 'Specify the user that will be used for synchronization between the two services.';
                    Visible = IsUserNamePasswordVisible;
                    field(Email; Rec."User Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        ExtendedDatatype = EMail;
                        Editable = ConnectionStringFieldsEditable;
                        ToolTip = 'Specifies the user name of a Dynamics 365 Sales account.';
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Password';
                        ExtendedDatatype = Masked;
                        Editable = ConnectionStringFieldsEditable;
                        ToolTip = 'Specifies the password of a Dynamics 365 Sales user account.';

                        trigger OnValidate()
                        begin
                            PasswordEdited := true;
                        end;
                    }
                }
                group(Control22)
                {
                    InstructionalText = 'This account must be a valid user in Dynamics 365 Sales that does not have the System Administrator role.';
                    ShowCaption = false;
                    Visible = IsUserNamePasswordVisible;
                }
                group("Advanced Settings")
                {
                    Caption = 'Advanced Connection Settings';
                    Visible = ShowAdvancedSettings;
                    field(ImportCRMSolution; ImportSolution)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Import Dynamics 365 Sales Solution';
                        Enabled = ImportCRMSolutionEnabled;
                        ToolTip = 'Specifies that the Dynamics 365 Sales Solution will be imported.';

                        trigger OnValidate()
                        begin
                            OnImportSolutionChange();
                        end;
                    }
                    field(EnableItemAvailability; EnableItemAvailability)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Automatically Synchronize Item Availability';
                        Enabled = PublishItemAvailabilityServiceEnabled;
                        ToolTip = 'Specifies that item availability job queue entry will be scheduled.';
                    }
                    field(EnableSalesOrderIntegration; EnableSalesOrderIntegration)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Legacy Sales Order Integration';
                        Enabled = EnableSalesOrderIntegrationEnabled;
                        ToolTip = 'Specifies that it is possible for Dynamics 365 Sales users to submit sales orders that can then be viewed and imported in Dynamics 365.';

                        trigger OnValidate()
                        begin
                            if EnableSalesOrderIntegration then
                                EnableBidirectionalSalesOrderIntegrationEnabled := false
                            else
                                EnableBidirectionalSalesOrderIntegrationEnabled := true;
                        end;
                    }
                    field(EnableBidirectionalSalesOrderIntegration; EnableBidirectionalSalesOrderIntegration)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Bidirectional Sales Order Integration';
                        Enabled = EnableBidirectionalSalesOrderIntegrationEnabled;
                        ToolTip = 'Specifies that it is possible to synchronize Sales Order bidirectionally. This feature will also enable Archiving Orders.';

                        trigger OnValidate()
                        begin
                            if EnableBidirectionalSalesOrderIntegration then
                                EnableSalesOrderIntegrationEnabled := false
                            else
                                EnableSalesOrderIntegrationEnabled := true;
                        end;
                    }
                    field(EnableCRMConnection; EnableCRMConnection)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Enable Dynamics 365 Sales Connection';
                        Enabled = EnableCRMConnectionEnabled;
                        ToolTip = 'Specifies if the connection to Dynamics 365 Sales will be enabled.';
                    }
                    field(SDKVersion; Rec."Proxy Version")
                    {
                        ApplicationArea = Suite;
                        AssistEdit = true;
                        Caption = 'Dynamics 365 SDK Version';
                        Editable = false;
                        ToolTip = 'Specifies the Microsoft Dynamics 365 (CRM) software development kit version that is used to connect to Dynamics 365 Sales.';

                        trigger OnAssistEdit()
                        var
                            TempStack: Record TempStack temporary;
                        begin
                            if PAGE.RunModal(PAGE::"SDK Version List", TempStack) = ACTION::LookupOK then begin
                                Rec."Proxy Version" := TempStack.StackOrder;
                                CurrPage.Update(true);
                            end;
                        end;
                    }
                }
                group(Control20)
                {
                    InstructionalText = 'To enable the connection, choose Finish. You may be asked to specify an administrative user account in Dynamics 365 Sales.';
                    ShowCaption = false;
                    Visible = FinishActionEnabled;
                }
                group(Control29)
                {
                    InstructionalText = 'To enable the connection, choose Next. You may be asked to specify an administrative user account in Dynamics 365 Sales.';
                    ShowCaption = false;
                    Visible = not FinishActionEnabled;
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = FieldServiceStepVisible;

                group(Control24)
                {
                    Caption = 'OPTIONALLY, SET UP FIELD SERVICE INTEGRATION';
                    InstructionalText = 'Enabling integration to Dynamics 365 Sales is a prerequisite for enabling integration to Dynamics 365 Field Service. If you want to also enable integration to Dynamics 365 Field Service, you can get the Field Service Integration app to integrate Dynamics 365 Field Service with Business Central here. Otherwise, feel free to skip this and choose Finish to complete Dynamics 365 Sales integration only.';
                }
                group(Control25)
                {
                    InstructionalText = 'Use the link below to go to AppSource and get the Field Service Integration app. After you install the app, go to Field Service Integration setup wizard to set up integration.';
                    ShowCaption = false;

                    field(InstallFieldServiceIntegrationApp; FieldServiceIntegrationAppInstallTxt)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        Caption = ' ';
                        ToolTip = 'Get the Field Service Integration app from Microsoft AppSource.';

                        trigger OnDrillDown()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            Hyperlink(CRMIntegrationManagement.GetFieldServiceIntegrationAppSourceLink());
                        end;
                    }
                }
                group(Control26)
                {
                    Visible = FieldServiceIntegrationAppInstalled;
                    ShowCaption = false;

                    field(FieldServiceIntegrationAppInstalledLbl; FieldServiceIntegrationAppInstalledTxt)
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Indicates whether the Field Service Integration app is installed in the Dataverse environment.';
                        Caption = 'The Field Service Integration Table app is installed.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Favorable;
                    }
                }
                group(Control27)
                {
                    Visible = not FieldServiceIntegrationAppInstalled;
                    ShowCaption = false;

                    field(FieldServiceIntegrationAppNotInstalledLbl; FieldServiceIntegrationAppNotInstalledTxt)
                    {
                        ApplicationArea = Suite;
                        Tooltip = 'Indicates that the Field Service Integration app is not installed in the Dataverse environment.';
                        Caption = 'The Field Service Integration app is not installed.';
                        Editable = false;
                        ShowCaption = false;
                        Style = Ambiguous;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if (Step = Step::Start) and (Rec."Server Address" = '') then
                        Error(CRMURLShouldNotBeEmptyErr, CRMProductName.SHORT());
                    NextStep(false);
                end;
            }
            action(ActionAdvanced)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advanced';
                Image = Setup;
                InFooterBar = true;
                Visible = AdvancedActionEnabled;

                trigger OnAction()
                begin
                    ShowAdvancedSettings := true;
                    AdvancedActionEnabled := false;
                    SimpleActionEnabled := true;
                end;
            }
            action(ActionSimple)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Simple';
                Image = Setup;
                InFooterBar = true;
                Visible = SimpleActionEnabled;

                trigger OnAction()
                begin
                    ShowAdvancedSettings := false;
                    AdvancedActionEnabled := true;
                    SimpleActionEnabled := false;
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    if Rec."Authentication Type" = Rec."Authentication Type"::Office365 then
                        if Rec."User Name" = '' then
                            Error(CRMSynchUserCredentialsNeededErr, CRMProductName.SHORT());

                    if not FinalizeSetup() then
                        exit;
                    Page.Run(Page::"CRM Connection Setup");
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"CRM Connection Setup Wizard");
                    Commit();
                    FeatureTelemetry.LogUptake('0000H77', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::"Set up");
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        LoadTopBanners();
        SetVisibilityFlags();
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
    end;

    trigger OnOpenPage()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        CRMConnectionSetup.EnsureCDSConnectionIsEnabled();
        CRMConnectionSetup.LoadConnectionStringElementsFromCDSConnectionSetup();
        FeatureTelemetry.LogUptake('0000H78', 'Dataverse', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000H79', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::Discovered);

        Rec.Init();
        if CRMConnectionSetup.Get() then begin
            Rec."Proxy Version" := CRMConnectionSetup."Proxy Version";
            Rec."Authentication Type" := CRMConnectionSetup."Authentication Type";
            Rec."Server Address" := CRMConnectionSetup."Server Address";
            Rec."User Name" := CRMConnectionSetup."User Name";
            Rec."User Password Key" := CRMConnectionSetup."User Password Key";
            Password := '**********';
            ConnectionStringFieldsEditable := false;
        end else begin
            InitializeDefaultAuthenticationType();
            InitializeDefaultProxyVersion();
        end;
        Rec.Insert();
        Step := Step::Start;
        EnableControls();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"CRM Connection Setup Wizard") then
                if not Confirm(ConnectionNotSetUpQst, false, CRMProductName.SHORT()) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        CRMProductName: Codeunit "CRM Product Name";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Credentials,FieldService;
        TopBannerVisible: Boolean;
        ConnectionStringFieldsEditable: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        FirstStepVisible: Boolean;
        CredentialsStepVisible: Boolean;
        FieldServiceStepVisible: Boolean;
        EnableCRMConnection: Boolean;
        ImportSolution: Boolean;
        EnableCRMConnectionEnabled: Boolean;
        ImportCRMSolutionEnabled: Boolean;
        PublishItemAvailabilityServiceEnabled: Boolean;
        EnableBidirectionalSalesOrderIntegration: Boolean;
        EnableBidirectionalSalesOrderIntegrationEnabled: Boolean;
        EnableSalesOrderIntegration: Boolean;
        EnableSalesOrderIntegrationEnabled: Boolean;
        EnableItemAvailability: Boolean;
        ShowAdvancedSettings: Boolean;
        AdvancedActionEnabled: Boolean;
        SimpleActionEnabled: Boolean;
        IsUserNamePasswordVisible: Boolean;
        PasswordEdited: Boolean;
        SoftwareAsAService: Boolean;
        FieldServiceIntegrationAppInstalled: Boolean;
        [NonDebuggable]
        Password: Text;
        ConnectionNotSetUpQst: Label 'The %1 connection has not been set up.\\Are you sure you want to exit?', Comment = '%1 = CRM product name';
        CRMURLShouldNotBeEmptyErr: Label 'You must specify the URL of your %1 solution.', Comment = '%1 = CRM product name';
        CRMSynchUserCredentialsNeededErr: Label 'You must specify the credentials for the user account for synchronization with %1.', Comment = '%1 = CRM product name';
        Office365AuthTxt: Label 'AuthType=Office365', Locked = true;
        FieldServiceIntegrationAppInstalledTxt: Label 'Field Service Integration app is installed.';
        FieldServiceIntegrationAppNotInstalledTxt: Label 'Field Service Integration app is not installed.';
        FieldServiceIntegrationAppInstallTxt: Label 'Install Field Service Integration app';

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure SetVisibilityFlags()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        IsUserNamePasswordVisible := true;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Authentication Type" = CDSConnectionSetup."Authentication Type"::Office365 then
                if not CDSConnectionSetup."Connection String".Contains(Office365AuthTxt) then
                    IsUserNamePasswordVisible := false;
    end;

    local procedure NextStep(Backward: Boolean)
    begin
        if Backward then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ResetControls()
    begin
        BackActionEnabled := false;
        NextActionEnabled := false;
        FinishActionEnabled := false;
        AdvancedActionEnabled := false;

        FirstStepVisible := false;
        CredentialsStepVisible := false;
        FieldServiceStepVisible := false;

        ImportCRMSolutionEnabled := true;
        PublishItemAvailabilityServiceEnabled := true;
        EnableBidirectionalSalesOrderIntegrationEnabled := true;
    end;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Credentials:
                ShowCredentialsStep();
            Step::FieldService:
                ShowFieldServiceStep();
        end;
    end;

    local procedure ShowStartStep()
    begin
        BackActionEnabled := false;
        NextActionEnabled := true;
        FinishActionEnabled := false;
        FirstStepVisible := true;
        AdvancedActionEnabled := false;
        SimpleActionEnabled := false;
    end;

    local procedure ShowFieldServiceStep()
    begin
        BackActionEnabled := true;
        NextActionEnabled := false;
        FinishActionEnabled := true;
        AdvancedActionEnabled := false;
        SimpleActionEnabled := false;
        FieldServiceStepVisible := true;
    end;

    local procedure ShowCredentialsStep()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        FieldServiceIntegrationAppInstalled := CRMIntegrationManagement.IsFieldServiceIntegrationAppInstalled();
        BackActionEnabled := true;
        NextActionEnabled := SoftwareAsAService and (not FieldServiceIntegrationAppInstalled);
        AdvancedActionEnabled := not ShowAdvancedSettings;
        SimpleActionEnabled := not AdvancedActionEnabled;
        CredentialsStepVisible := true;
        FinishActionEnabled := (not SoftwareAsAService) or FieldServiceIntegrationAppInstalled;

        EnableBidirectionalSalesOrderIntegrationEnabled := ImportCRMSolutionEnabled;
        EnableSalesOrderIntegrationEnabled := ImportCRMSolutionEnabled;
        EnableCRMConnectionEnabled := Rec."Server Address" <> '';
        Rec."Authentication Type" := Rec."Authentication Type"::Office365;
        if CRMConnectionSetup.Get() then begin
            EnableCRMConnection := true;
            EnableCRMConnectionEnabled := not CRMConnectionSetup."Is Enabled";
            EnableBidirectionalSalesOrderIntegration := CRMConnectionSetup."Bidirectional Sales Order Int." or EnableBidirectionalSalesOrderIntegration;
            EnableSalesOrderIntegration := CRMConnectionSetup."Is S.Order Integration Enabled";
            EnableBidirectionalSalesOrderIntegrationEnabled := not CRMConnectionSetup."Bidirectional Sales Order Int." and not CRMConnectionSetup."Is S.Order Integration Enabled";
            EnableSalesOrderIntegrationEnabled := not CRMConnectionSetup."Bidirectional Sales Order Int." and not CRMConnectionSetup."Is S.Order Integration Enabled";
            ImportSolution := true;
            if CRMConnectionSetup."Is CRM Solution Installed" then
                ImportCRMSolutionEnabled := false;
        end else begin
            if ImportCRMSolutionEnabled then
                ImportSolution := true;
            if EnableCRMConnectionEnabled then
                EnableCRMConnection := true;
        end;
    end;

    [NonDebuggable]
    local procedure FinalizeSetup(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        AdminEmail: Text;
        AdminPassword: Text;
        AccessToken: SecretText;
        AdminADDomain: Text;
        ImportSolutionFailed: Boolean;
    begin
        if ImportSolution and ImportCRMSolutionEnabled then begin
            case Rec."Authentication Type" of
                Rec."Authentication Type"::Office365:
                    CDSIntegrationImpl.GetAccessToken(Rec."Server Address", true, AccessToken);
                Rec."Authentication Type"::AD:
                    if not Rec.PromptForCredentials(AdminEmail, AdminPassword, AdminADDomain) then
                        exit(false);
                else
                    if not Rec.PromptForCredentials(AdminEmail, AdminPassword) then
                        exit(false);
            end;
            CRMIntegrationManagement.ImportCRMSolution(Rec."Server Address", Rec."User Name", AdminEmail, AdminPassword, AccessToken, AdminADDomain, Rec."Proxy Version", true, ImportSolutionFailed);
        end;
        if EnableBidirectionalSalesOrderIntegration then
            Rec.Validate("Bidirectional Sales Order Int.", true);
        if EnableSalesOrderIntegration then
            Rec."Is S.Order Integration Enabled" := true;
        if EnableItemAvailability then
            Rec."Item Availability Enabled" := true;

        CRMIntegrationManagement.InitializeCRMSynchStatus();
        if PasswordEdited then
            CRMConnectionSetup.UpdateFromWizard(Rec, Password)
        else
            CRMConnectionSetup.UpdateFromWizard(Rec, CRMConnectionSetup.GetSecretPassword());
        if EnableCRMConnection then
            CRMConnectionSetup.EnableCRMConnectionFromWizard();
        if EnableSalesOrderIntegration and EnableSalesOrderIntegrationEnabled then
            CRMConnectionSetup.SetCRMSOPEnabledWithCredentials(AdminEmail, AdminPassword, true);
        exit(true);
    end;

    local procedure OnImportSolutionChange()
    begin
        PublishItemAvailabilityServiceEnabled := ImportSolution;
    end;

    local procedure InitializeDefaultAuthenticationType()
    begin
        Rec.Validate("Authentication Type", Rec."Authentication Type"::Office365);
    end;

    local procedure InitializeDefaultProxyVersion()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Rec.Validate("Proxy Version", CRMIntegrationManagement.GetLastProxyVersionItem());
    end;
}

