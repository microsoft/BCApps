namespace System.Integration.PowerBI;

using System.Azure.Identity;
using System.Environment;
using System.Telemetry;
using System.Utilities;

page 6327 "Power BI Embed Setup Wizard"
{
    Caption = 'Set Up Power BI Reports in Business Central';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(TopBanner1)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (CurrentStep <> CurrentStep::Done);

                field("<MediaRepositoryStandard>"; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '';
                    Editable = false;
                    ToolTip = 'Specifies an image to be shown on top of the wizard page when the wizard is in progress.';
                }
            }
            group(TopBanner2)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (CurrentStep = CurrentStep::Done);

                field("<MediaRepositoryDone>"; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '';
                    Editable = false;
                    ToolTip = 'Specifies an image to be shown on top of the wizard page when the wizard is finished.';
                }
            }
            group(Intro)
            {
                Caption = 'Intro';
                Visible = CurrentStep = CurrentStep::Intro;

                group("Para0.1")
                {
                    Caption = 'Welcome to Power BI Report Setup';

                    label("Para0.1.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Power BI is a collection of software services, apps, and connectors that work together to turn your unrelated sources of data into coherent, visually immersive, and interactive insights.';
                    }
                    label("Para0.1.2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'This setup helps you configure Business Central to display your existing Power BI reports inside various pages that include a Power BI report part.';
                    }
                    label(EmptySpace1)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Caption = '';
                    }
                }
                group("Para0.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to step through the process of visualizing Power BI reports inside Business Central.';
                }
            }
            group(Step1)
            {
                Caption = 'Connect your Microsoft Entra application';
                Visible = CurrentStep = CurrentStep::OnPremAadSetup;

                group("Para1.1")
                {
                    Caption = 'Connect with Microsoft Entra ID';

                    label("Para1.1.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To display Power BI reports inside Business Central on-premises, you''ll first need a registered application for Business Central in Microsoft Entra ID.';
                    }
                    field("Para1.1.3"; LearnMoreAzureAppTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink(AzureAppLinkTxt);
                        end;
                    }
                    label("Para1.1.2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Once an Microsoft Entra application has been registered, you''re ready to continue with this setup. During setup, you''ll provide information about the Microsoft Entra application. Choose Next to continue.';
                    }
                }
            }
            group(Step2)
            {
                Caption = 'License Check';
                Visible = CurrentStep = CurrentStep::LicenseCheck;

                group("Para2.1")
                {
                    Caption = 'Check your Power BI License';

                    label("Para2.1.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To set up your reports correctly, we need to ensure that you have a license for Power BI. If you don''t have a license yet, you can get one at the following link.';
                    }
                    field("Para2.1.2"; PowerBIHomePageTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        var
                            PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
                        begin
                            Hyperlink(PowerBIUrlMgt.GetLicenseUrl());
                        end;
                    }
                    label(EmptySpace2)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Caption = '';
                    }
                    label("Para2.1.4")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'This feature utilizes Microsoft Power BI. By continuing you are affirming that you understand that the data handling and compliance standards of Microsoft Power BI may not be the same as those provided by Microsoft Dynamics 365 Business Central. Please consult the documentation for Power BI to learn more.';
                    }
                    field("Para2.1.5"; PrivacyStatementTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Hyperlink('https://go.microsoft.com/fwlink/?linkid=831305');
                        end;
                    }
                    label("Para2.1.3")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If you already have a license for Power BI, choose Next to go to the next step.';
                    }
                }
            }
            group(Step3)
            {
                Caption = 'Report Deployment';
                Visible = CurrentStep = CurrentStep::AutoDeployment;

                group("Para3.1")
                {
                    Caption = '';

                    label("Para3.1.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Business Central will now upload a demo report for you to Power BI. This will take a few minutes, so we will do it in the background.';
                    }
                    label("Para3.1.2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'While we upload the report, you can continue your work, and even start using Power BI in Business Central. When the upload has completed, the new report will be available for displaying on pages.';
                    }
                    label(EmptySpace3)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Caption = '';
                    }
                    label("Para3.1.3")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Choose Next to start uploading the demo report.';
                    }
                }
            }
            group(Done)
            {
                Caption = 'Done';
                Visible = CurrentStep = CurrentStep::Done;

                group("Para4.1")
                {
                    Caption = 'That''s it!';

                    group("Para4.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Now you are ready to display your Power BI reports inside Business Central.';
                    }
                    group("Para4.1.2")
                    {
                        Caption = '';
                        Visible = IsDeploying;
                        InstructionalText = 'Your demo report is being uploaded, and you will see it in your Power BI workspace shortly.';
                    }
                    group("Para4.1.4")
                    {
                        Caption = '';
                        InstructionalText = 'Some list pages, such as Items and Customers, allow you to display Power BI reports in the FactBox pane. Personalize the FactBox pane on these pages to show the Power BI Report part. Then, choose the reports you want to display.';
                    }
                    label(EmptySpace4)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Caption = '';
                    }
                    group("Para4.1.3")
                    {
                        Caption = '';
                        InstructionalText = 'Choose Finish to close this setup.';
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
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    GoToNextStep(false);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    GoToNextStep(true);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        LoadTopBanners();

        IsSaaS := EnvironmentInformation.IsSaaSInfrastructure(); // SaaS but not Docker
    end;

    trigger OnOpenPage()
    begin
        Session.LogMessage('0000E1V', StrSubstNo(WizardOpenedForContextTxt, ParentPageContext), Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());

        if not PowerBIServiceMgt.CheckPowerBITablePermissions() then
            Error(NoTablePermissionsErr);

        SetStep(CurrentStep::Intro);
    end;

    var
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CurrentStep: Option Intro,OnPremAadSetup,LicenseCheck,AutoDeployment,Done;
        TopBannerVisible: Boolean;
        NextEnabled: Boolean;
        BackEnabled: Boolean;
        FinishEnabled: Boolean;
        IsSaaS: Boolean;
        IsDeploying: Boolean;
        ParentPageContext: Text[30];
        StepOutOfRangeErr: Label 'Wizard step out of range.';
        NoLicenseErrSaaS: Label 'We could not check your license for Power BI. Make sure you have an active Power BI license for your user account.\\If you just activated a license, it might take a few minutes for Power BI to update.';
        NoLicenseErrOnPrem: Label 'We could not check your license for Power BI. This means you either don''t have an active Power BI license for your user account, or your Entra application is not set up correctly.\\Check that your user has an active Power BI license assigned, and make sure you follow the on-premises setup guide at https://aka.ms/bcpbi.';
#pragma warning disable AA0470
        NoTokenForOnPremErr: Label 'We couldn''t connect to Power BI using your Microsoft Entra application. This typically happens when your Microsoft Entra application is not configured correctly to connect to %1. Run the "Set up Microsoft Entra ID" assisted setup again, and make sure your setup matches the documentation at https://aka.ms/bcpbi.';
#pragma warning restore AA0470
        NoTablePermissionsErr: Label 'You do not have the necessary table permissions to access Power BI. Ask your system administrator for permissions, then run this page again.';
        AzureAppLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2150045', Locked = true;
        StepOutOfRangeTelemetryTxt: Label 'Step out of range from %1, Forward=%2', Locked = true;
        WizardOpenedForContextTxt: Label 'Power BI Wizard opened for context: %1.', Locked = true;
        LearnMoreAzureAppTxt: Label 'Learn more about registering a Microsoft Entra application.';
        PowerBIHomePageTxt: Label 'Go to Power BI home page';
        PrivacyStatementTxt: Label 'Privacy and cookies';

    local procedure SetStep(NewStep: Option)
    begin
        if (NewStep < CurrentStep::Intro) or (NewStep > CurrentStep::Done) then
            Error(StepOutOfRangeErr);

        CurrentStep := NewStep;

        FinishEnabled := CurrentStep = CurrentStep::Done;
        BackEnabled := (CurrentStep > CurrentStep::Intro) and (CurrentStep <> CurrentStep::Done);
        NextEnabled := CurrentStep < CurrentStep::Done;

        CurrPage.Update();
    end;

    local procedure CalculateNextStep(Forward: Boolean) NextStep: Option
    var
        StepValue: Integer;
    begin
        if Forward then
            StepValue := 1
        else
            StepValue := -1;

        // Go to next step, but if that step sould be hidden, jump again. Notice that this works because it's never
        // the case that two subsequent steps are hidden (in which case either forward or backwards will break).
        NextStep := CurrentStep + StepValue;

        if NextStep = CurrentStep::OnPremAadSetup then
            if not ShowOnPremAadSetupStep() then
                NextStep += StepValue;

        if NextStep = CurrentStep::AutoDeployment then
            if not ShowDeploymentStep() then
                NextStep += StepValue;

        if (NextStep < CurrentStep::Intro) or (NextStep > CurrentStep::Done) then begin
            NextStep := CurrentStep;
            Session.LogMessage('0000E1H', StrSubstNo(StepOutOfRangeTelemetryTxt, CurrentStep, Forward), Verbosity::Warning, DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
        end;
    end;

    local procedure GoToNextStep(Forward: Boolean)
    begin
        if Forward then
            PerformOperationAfterStep(CurrentStep);

        SetStep(CalculateNextStep(Forward));
    end;

    local procedure PerformOperationAfterStep(AfterStep: Option)
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
    begin
        case AfterStep of
            CurrentStep::OnPremAadSetup:
                AadOnpremSetup();
            CurrentStep::LicenseCheck:
                if PowerBIServiceMgt.CheckForPowerBILicenseInForeground() then begin
                    FeatureTelemetry.LogUptake('0000L06', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
                    PowerBIContextSettings.CreateOrReadForCurrentUser(ParentPageContext);
                end else
                    if IsSaaS then
                        Error(NoLicenseErrSaaS)
                    else
                        Error(NoLicenseErrOnPrem);
            CurrentStep::AutoDeployment:
                StartAutoDeployment();
        end;
    end;

    local procedure StartAutoDeployment()
    begin
        if ParentPageContext = '' then begin
            IsDeploying := false;
            exit;
        end;

        if not PowerBIReportSynchronizer.UserNeedsToSynchronize(ParentPageContext) then begin
            IsDeploying := false;
            exit;
        end;

        IsDeploying := true;
        PowerBIServiceMgt.SynchronizeReportsInBackground(ParentPageContext);
    end;

    local procedure AadOnpremSetup()
    begin
        if not TryAzureAdMgtGetAccessToken(true) then
            Error(NoTokenForOnPremErr, ProductName.Short());
    end;

    [TryFunction]
    local procedure TryAzureAdMgtGetAccessToken(ShowDialog: Boolean)
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        AccessToken: SecretText;
    begin
        AccessToken := AzureAdMgt.GetAccessTokenAsSecretText(PowerBIServiceMgt.GetPowerBIResourceUrl(), PowerBIServiceMgt.GetPowerBiResourceName(), ShowDialog);

        if AccessToken.IsEmpty() then
            Error('');
    end;

    local procedure ShowDeploymentStep(): Boolean
    begin
        if ParentPageContext = '' then
            exit(false);

        if not PowerBIServiceMgt.IsUserSynchronizingReports() then
            if PowerBIReportSynchronizer.UserNeedsToSynchronize(ParentPageContext) then
                exit(true);

        exit(false);
    end;

    local procedure ShowOnPremAadSetupStep(): Boolean
    begin
        // Show only if OnPrem and the setup is not done
        if not IsSaaS then
            if not TryAzureAdMgtGetAccessToken(false) then
                exit(true);

        exit(false);
    end;

    local procedure LoadTopBanners()
    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    procedure SetContext(NewContext: Text[30])
    begin
        ParentPageContext := NewContext;
    end;
}

